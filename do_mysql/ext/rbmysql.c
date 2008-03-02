#include <ruby.h>
#include <string.h>
#include <math.h>
#include <mysql.h>
#include <errmsg.h>
#include <mysqld_error.h>
 
#define RUBY_CLASS(name) rb_const_get(rb_cObject, rb_intern(name))
#define RUBY_STRING(char_ptr) rb_str_new2(char_ptr)
#define TAINTED_STRING(name) rb_tainted_str_new2(name)
#define DRIVER_CLASS(klass, parent) (rb_define_class_under(mRbMysql, klass, parent))
#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))
#define CHECK_AND_RAISE(mysql_result_value) if (0 != mysql_result_value) { raise_mysql_error(db, mysql_result_value); }

// To store rb_intern values
ID ID_TO_I;
ID ID_TO_F;
ID ID_PARSE;
ID ID_TO_TIME;
ID ID_NEW;
ID ID_NEW_BANG;
ID ID_CONST_GET;
ID ID_UTC;
ID ID_ESCAPE_SQL;
ID ID_STRFTIME;

// References to DataObjects base classes
VALUE mDO;
VALUE cDO_Quoting;
VALUE cDO_Connection;
VALUE cDO_Command;
VALUE cDO_Transaction;
VALUE cDO_Result;
VALUE cDO_Reader;

// References to Ruby classes that we'll need
VALUE rb_cDate;
VALUE rb_cDateTime;
VALUE rb_cRational;
VALUE rb_cBigDecimal;
VALUE rb_cURI;

VALUE rb_do_eLengthMismatchError; 
VALUE mRbMysql;
VALUE cConnection;
VALUE cCommand;
VALUE cTransaction;
VALUE cResult;
VALUE cReader;
 
// Figures out what we should cast a given mysql field type to
char * ruby_type_from_mysql_type(MYSQL_FIELD *field) {
 
	char* ruby_type_name;
	
	switch(field->type) {
		case MYSQL_TYPE_NULL: {
			ruby_type_name = NULL;
			break;
		}
		case MYSQL_TYPE_TINY: {
			ruby_type_name = "TrueClass";
			break;
		}
		case MYSQL_TYPE_BIT:
		case MYSQL_TYPE_SHORT:
		case MYSQL_TYPE_LONG:
		case MYSQL_TYPE_INT24:
		case MYSQL_TYPE_LONGLONG:
		case MYSQL_TYPE_YEAR: {
			ruby_type_name = "Fixnum";
			break;
		}
		case MYSQL_TYPE_DECIMAL:
		case MYSQL_TYPE_NEWDECIMAL:
		case MYSQL_TYPE_FLOAT:
		case MYSQL_TYPE_DOUBLE: {
			ruby_type_name = "BigDecimal";
			break;
		}
		case MYSQL_TYPE_TIMESTAMP:
		case MYSQL_TYPE_DATETIME: {
			ruby_type_name = "DateTime";
			break;
		}
		case MYSQL_TYPE_TIME: {
			ruby_type_name = "DateTime";
			break;
		}
		case MYSQL_TYPE_DATE: {
			ruby_type_name = "Date";
			break;
		}
		default: {
			// printf("Falling to default: %s - %d\n", field->name, field->type);
			ruby_type_name = "String";
		}
	}
 
	return ruby_type_name;
}

// Find the greatest common denominator and reduce the provided numerator and denominator.
// This replaces calles to Rational.reduce! which does the same thing, but really slowly.
void reduce( unsigned long long int *numerator, unsigned long long int *denominator ) {
  unsigned long long int a, b, c;
  a = *numerator;
  b = *denominator;
  while ( a != 0 ) {
    c = a; a = b % a; b = c;
  }
  *numerator = *numerator / b;
  *denominator = *denominator / b;
}
 
// Generate the date integer which Date.civil_to_jd returns
int jd_from_date(int year, int month, int day) {
  int a, b;
  if ( month <= 2 ) {
    year -= 1;
    month += 12;
  }
  a = year / 100;
  b = 2 - a + (a / 4);
  return floor(365.25 * (year + 4716)) + floor(30.6001 * (month + 1)) + day + b - 1524;
}

// Convert C-string to a Ruby instance of type "ruby_class_name"
VALUE cast_mysql_value_to_ruby_value(const char* data, char* ruby_class_name) {
  if (NULL == data)
		return Qnil;
 
	VALUE ruby_value = Qnil;
 
	if (0 == strcmp("Fixnum", ruby_class_name) || 0 == strcmp("Bignum", ruby_class_name)) {
		ruby_value = (0 == strlen(data) ? Qnil : LL2NUM(atoi(data)));
	} else if (0 == strcmp("String", ruby_class_name)) {
		ruby_value = TAINTED_STRING(data);
	} else if (0 == strcmp("Float", ruby_class_name) ) {
		ruby_value = rb_float_new(strtod(data, NULL));
	} else if (0 == strcmp("BigDecimal", ruby_class_name) ) {
		// There's a much faster way to do this I'm sure...
		ruby_value = rb_funcall(rb_cBigDecimal, ID_NEW, 1, TAINTED_STRING(data));
	} else if (0 == strcmp("TrueClass", ruby_class_name) || 0 == strcmp("FalseClass", ruby_class_name)) {
		ruby_value = (NULL == data || 0 == data || 0 == strcmp("0", data)) ? Qfalse : Qtrue;
	} else if (0 == strcmp("Date", ruby_class_name)) {
		int year, month, day;
    int jd, ajd;
    VALUE rational;

    sscanf(data, "%4d-%2d-%2d", &year, &month, &day);

    jd = jd_from_date(year, month, day);

    // Math from Date.jd_to_ajd
    ajd = jd * 2 - 1;
    rational = rb_funcall(rb_cRational, ID_NEW_BANG, 2, INT2NUM(ajd), INT2NUM(2));
    ruby_value = rb_funcall(rb_cDate, ID_NEW_BANG, 3, rational, INT2NUM(0), INT2NUM(2299161));
	} else if (0 == strcmp("DateTime", ruby_class_name)) {
	 int jd;
   int y, m, d, h, min, s;

   sscanf(data, "%4d-%2d-%2d %2d:%2d:%2d", &y, &m, &d, &h, &min, &s);

   jd = jd_from_date(y, m, d);

   // Generate ajd with fractional days for the time
   // Extracted from Date#jd_to_ajd, Date#day_fraction_to_time, and Rational#+ and #-
   unsigned long long int num, den;

   num = (h * 1440) + (min * 24);
   den = (24 * 1440);
   reduce(&num, &den);

   num = (num * 86400) + (s * den);
   den = den * 86400;
   reduce(&num, &den);

   num = (jd * den) + num;

   num = num * 2;
   num = num - den;
   den = den * 2;

   reduce(&num, &den);

   VALUE ajd = rb_funcall(rb_cRational, ID_NEW_BANG, 2, rb_ull2inum(num), rb_ull2inum(den));
   ruby_value = rb_funcall(rb_cDateTime, ID_NEW_BANG, 3, ajd, INT2NUM(0), INT2NUM(2299161));
	} else if (0 == strcmp("Time", ruby_class_name)) {
	  int y, m, d, h, min, s;
	  sscanf(data, "%4d-%2d-%2d %2d:%2d:%2d", &y, &m, &d, &h, &min, &s);

	  ruby_value = rb_funcall(rb_cTime, ID_UTC, 6, INT2NUM(y), INT2NUM(m), INT2NUM(d), INT2NUM(h), INT2NUM(min), INT2NUM(s));
	} else {
		ruby_value = TAINTED_STRING(data);
	}
 
	return ruby_value;
}

void raise_mysql_error(MYSQL *db, int mysql_error_code) {
	char *error_message = (char *)mysql_error(db);
	char *extra = "";

	switch(mysql_error_code) {
		case CR_UNKNOWN_ERROR: 
		case CR_SOCKET_CREATE_ERROR: 
		case CR_CONNECTION_ERROR: 
		case CR_CONN_HOST_ERROR: 
		case CR_IPSOCK_ERROR: 
		case CR_UNKNOWN_HOST: 
		case CR_SERVER_GONE_ERROR: 
		case CR_VERSION_ERROR: 
		case CR_OUT_OF_MEMORY: 
		case CR_WRONG_HOST_INFO: 
		case CR_LOCALHOST_CONNECTION: 
		case CR_TCP_CONNECTION: 
		case CR_SERVER_HANDSHAKE_ERR: 
		case CR_SERVER_LOST: 
		case CR_COMMANDS_OUT_OF_SYNC: 
		case CR_NAMEDPIPE_CONNECTION: 
		case CR_NAMEDPIPEWAIT_ERROR: 
		case CR_NAMEDPIPEOPEN_ERROR: 
		case CR_NAMEDPIPESETSTATE_ERROR: 
		case CR_CANT_READ_CHARSET: 
		case CR_NET_PACKET_TOO_LARGE: 
		case CR_EMBEDDED_CONNECTION: 
		case CR_PROBE_SLAVE_STATUS: 
		case CR_PROBE_SLAVE_HOSTS: 
		case CR_PROBE_SLAVE_CONNECT: 
		case CR_PROBE_MASTER_CONNECT: 
		case CR_SSL_CONNECTION_ERROR: 
		case CR_MALFORMED_PACKET: 
		case CR_WRONG_LICENSE: 
		case CR_NULL_POINTER: 
		case CR_NO_PREPARE_STMT: 
		case CR_PARAMS_NOT_BOUND: 
		case CR_DATA_TRUNCATED: 
		case CR_NO_PARAMETERS_EXISTS: 
		case CR_INVALID_PARAMETER_NO: 
		case CR_INVALID_BUFFER_USE: 
		case CR_UNSUPPORTED_PARAM_TYPE: 
		case CR_SHARED_MEMORY_CONNECTION: 
		case CR_SHARED_MEMORY_CONNECT_REQUEST_ERROR: 
		case CR_SHARED_MEMORY_CONNECT_ANSWER_ERROR: 
		case CR_SHARED_MEMORY_CONNECT_FILE_MAP_ERROR: 
		case CR_SHARED_MEMORY_CONNECT_MAP_ERROR: 
		case CR_SHARED_MEMORY_FILE_MAP_ERROR: 
		case CR_SHARED_MEMORY_MAP_ERROR: 
		case CR_SHARED_MEMORY_EVENT_ERROR: 
		case CR_SHARED_MEMORY_CONNECT_ABANDONED_ERROR: 
		case CR_SHARED_MEMORY_CONNECT_SET_ERROR: 
		case CR_CONN_UNKNOW_PROTOCOL: 
		case CR_INVALID_CONN_HANDLE: 
		case CR_SECURE_AUTH: 
		case CR_FETCH_CANCELED: 
		case CR_NO_DATA: 
		case CR_NO_STMT_METADATA: 
		case CR_NO_RESULT_SET: 
		case CR_NOT_IMPLEMENTED: {
			break;
		}
		default: {
			// Hmmm
			break;
		}
	}
	
	rb_raise(rb_eException, error_message);
}

VALUE cConnection_initialize(VALUE self, VALUE uri) {
  MYSQL *db = 0 ;
  db = (MYSQL *)mysql_init(NULL);

	VALUE r_host = rb_funcall(uri, rb_intern("host"), 0);
	char * host = "localhost";
	if (Qnil != r_host) {
		host = StringValuePtr(r_host);
	}
	
	VALUE r_user = rb_funcall(uri, rb_intern("user"), 0);
	char * user = "root";
	if (Qnil != r_user) {
		user = StringValuePtr(r_user);
	}

	VALUE r_password = rb_funcall(uri, rb_intern("password"), 0);
	char * password = "";
	if (Qnil != r_password) {
		password = StringValuePtr(r_password);
	}

	VALUE r_path = rb_funcall(uri, rb_intern("path"), 0);
	char * path = StringValuePtr(r_path);
	char * database = "";
	if (Qnil != r_path) {
		database = strtok(path, "/");
	}

	if (NULL == database || 0 == strlen(database)) {
		rb_raise(rb_eException, "Database must be specified");
	}

	VALUE r_port = rb_funcall(uri, rb_intern("port"), 0);
	int port = 3306;
	if (Qnil != r_port) {
		port = NUM2INT(r_port);
	}
	
	// If ssl? {
	//   mysql_ssl_set(db, key, cert, ca, capath, cipher)
	// }
 
	int result;
	
	result = mysql_real_connect(
		db,
		host,
		user,
		password,
		database,
		port,
		NULL,
		0
	);
	
	if (NULL == result) {
		raise_mysql_error(db, -1);
	}
	
	rb_iv_set(self, "@uri", uri);
	rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));
 
	return Qtrue;
}

VALUE cConnection_begin_transaction(VALUE self) {
	return rb_funcall(cTransaction, rb_intern("new"), 1, self);
}

VALUE cConnection_real_close(VALUE self) {
	VALUE connection_container = rb_iv_get(self, "@connection");
	
	if (Qnil == connection_container)
		return Qfalse;
		
	MYSQL *db = DATA_PTR(connection_container);
 
	if (NULL == db)
		return Qfalse;
 
	mysql_close(db);
	// free(db);
 
	rb_iv_set(self, "@connection", Qnil);
 
	return Qtrue;
}

// VALUE cCommand_set_types(VALUE self, VALUE array) {
// 	rb_iv_set(self, "@field_types", array);
// 	return array;
// }

VALUE cCommand_quote_time(VALUE self, VALUE value) {
 	// TIMESTAMP() used for both time and datetime columns
	return rb_funcall(value, ID_STRFTIME, 1, RUBY_STRING("TIMESTAMP(\"%Y-%m-%d %H:%M:%S\")"));
}

VALUE cCommand_quote_datetime(VALUE self, VALUE value) {
  // "TIMESTAMP('#{value.strftime("%Y-%m-%d %H:%M:%S")}')"
	return rb_funcall(value, ID_STRFTIME, 1, RUBY_STRING("TIMESTAMP(\"%Y-%m-%d %H:%M:%S\")"));
}

VALUE cCommand_quote_date(VALUE self, VALUE value) {
  // "DATE('#{value.strftime("%Y-%m-%d")}')"
	return rb_funcall(value, ID_STRFTIME, 1, RUBY_STRING("TIMESTAMP(\"%Y-%m-%d\")"));
}

// Accepts an array of Ruby types (Fixnum, Float, String, etc...) and turns them
// into Ruby-strings so we can easily typecast later
VALUE cCommand_set_types(VALUE self, VALUE array) {
	// VALUE field_count = rb_iv_get(self, "@field_count");
	// Check_Type(field_count, T_FIXNUM);
	VALUE type_strings = rb_ary_new();
	
	// if (RARRAY(array)->len != NUM2INT(field_count)) {
	// 	rb_raise(rb_do_eLengthMismatchError, "Result#set_type expected %d fields, but received %d", NUM2INT(field_count), RARRAY(array)->len);
	// }

	int i;
 
	for (i = 0; i < RARRAY(array)->len; i++) {
		rb_ary_push(type_strings, rb_str_new2(rb_class2name(rb_ary_entry(array, i))));
	}
 
	rb_iv_set(self, "@field_types", type_strings);
 
	return array;
}

VALUE cCommand_execute_non_query(int argc, VALUE *argv, VALUE self) {
	MYSQL *db = DATA_PTR(rb_iv_get(rb_iv_get(self, "@connection"), "@connection"));
 
	int query_result = 0;
	MYSQL_RES *response = 0;
	VALUE reader = Qnil;
	
	VALUE query = rb_iv_get(self, "@text");
	
	if ( argc > 0 ) {
		int i;
		VALUE array = rb_ary_new();
		for ( i = 0; i < argc; i++ ) {
			rb_ary_push(array, argv[i]);
		}
		query = rb_funcall(self, ID_ESCAPE_SQL, 1, array);
	}
	
	query_result = mysql_query(db, StringValuePtr(query));
	CHECK_AND_RAISE(query_result);
	
	response = (MYSQL_RES *)mysql_store_result(db);
	my_ulonglong affected_rows = mysql_affected_rows(db);
 	mysql_free_result(response);

	if (-1 == affected_rows)
		return Qnil;
	
	return rb_funcall(cResult, ID_NEW, 3, self, INT2NUM(affected_rows), INT2NUM(mysql_insert_id(db)));
}

VALUE cCommand_execute_reader(int argc, VALUE *argv, VALUE self) {
	MYSQL *db = DATA_PTR(rb_iv_get(rb_iv_get(self, "@connection"), "@connection"));
 
	int query_result = 0;
	MYSQL_RES *response = 0;
	VALUE result = Qnil;
	VALUE query;
	VALUE reader;

	query = rb_iv_get(self, "@text");
	
	if ( argc > 0 ) {
		int i;
		VALUE array = rb_ary_new();
		for ( i = 0; i < argc; i++ ) {
			rb_ary_push(array, argv[i]);
		}
		query = rb_funcall(self, ID_ESCAPE_SQL, 1, array);
	}
 
	query_result = mysql_query(db, StringValuePtr(query));
 
	response = (MYSQL_RES *)mysql_use_result(db);
 
	if (!response) {
		return Qnil;
	}
	
	int field_count = (int)mysql_field_count(db);
	
	reader = rb_funcall(cReader, ID_NEW, 0);
	rb_iv_set(reader, "@reader", Data_Wrap_Struct(rb_cObject, 0, 0, response));
	rb_iv_set(reader, "@opened", Qtrue);
	rb_iv_set(reader, "@field_count", INT2NUM(field_count));
 
	VALUE field_names = rb_ary_new();
	VALUE field_types = rb_iv_get(self, "@field_types");

	char guess_default_field_types = 0;

	if ( field_types == Qnil || 0 == RARRAY(field_types)->len ) {
		field_types = rb_ary_new();
 		guess_default_field_types = 1;
	}

	MYSQL_FIELD *field;

	int i;
  for(i = 0; i < field_count; i++) {
		field = mysql_fetch_field_direct(response, i);
		rb_ary_push(field_names, rb_str_new2(field->name));
		
		if (1 == guess_default_field_types) {
			VALUE field_ruby_type_name = RUBY_STRING(ruby_type_from_mysql_type(field));
			rb_ary_push(field_types, field_ruby_type_name);
		}
  }
 
	rb_iv_set(reader, "@fields", field_names);
	rb_iv_set(reader, "@field_types", field_types);
	
	if (rb_block_given_p()) {
		rb_yield(reader);
		rb_funcall(reader, rb_intern("close"), 0);
	}

	return reader;
}

VALUE cTransaction_initialize(VALUE self, VALUE connection) {
	if (Qnil != rb_iv_get(connection, "@transaction")) {
		rb_raise(rb_eException, "There is already a transaction active on this connection");
	}
	
	rb_iv_set(self, "@connection", connection);
	VALUE command = rb_funcall(connection, rb_intern("create_command"), 1, RUBY_STRING("BEGIN"));
	rb_funcall(command, rb_intern("execute_non_query"), 0);
	
	rb_iv_set(connection, "@transaction", self);
	
	return Qtrue;
}

VALUE cTransaction_commit(VALUE self) {
	VALUE connection = rb_iv_get(self, "@connection");
	VALUE command = rb_funcall(connection, rb_intern("create_command"), 1, "COMMIT");
	VALUE result = rb_funcall(command, rb_intern("execute_non_query"), 0);

	rb_iv_set(connection, "@transaction", Qnil);

	return result;
}

VALUE cTransaction_rollback(int argc, VALUE *argv, VALUE self) {
	VALUE savepoint;
	
	// 1 Optional arg
	rb_scan_args(argc, argv, "1", &savepoint);
	if (Qnil != savepoint) {
		rb_raise(rb_eException, "MySQL does not support savepoints");
	}
	
	VALUE connection = rb_iv_get(self, "@connection");
	VALUE command = rb_funcall(connection, rb_intern("create_command"), 1, "COMMIT");
	VALUE result = rb_funcall(command, rb_intern("execute_non_query"), 0);

	rb_iv_set(connection, "@transaction", Qnil);

	return result;
}

VALUE cTransaction_save(VALUE self) {
	rb_raise(rb_eException, "MySQL does not support savepoints");
}

VALUE cTransaction_create_command(int argc, VALUE *argv, VALUE self) {
	VALUE connection = rb_iv_get(self, "@connection");
	return rb_funcall2(connection, rb_intern("create_command"), argc, argv);
}

// This should be called to ensure that the internal result reader is freed
VALUE cReader_close(VALUE self) {
	// Get the reader from the instance variable, maybe refactor this?
	VALUE reader_container = rb_iv_get(self, "@reader");
	
	if (Qnil == reader_container)
		return Qfalse;

	MYSQL_RES *reader = DATA_PTR(reader_container);

	// The Meat
	if (NULL == reader)
		return Qfalse;
 	
	mysql_free_result(reader);		
	rb_iv_set(self, "@reader", Qnil);
 
	return Qtrue;
}
 
// Retrieve a single row
VALUE cReader_next(VALUE self) {
	// Get the reader from the instance variable, maybe refactor this?
	VALUE reader_container = rb_iv_get(self, "@reader");
	
	if (Qnil == reader_container)
		return Qfalse;
		
	MYSQL_RES *reader = DATA_PTR(reader_container);
	
	// The Meat
	VALUE ruby_field_type_strings = rb_iv_get(self, "@field_types");
  VALUE row = rb_ary_new();
  MYSQL_ROW result = (MYSQL_ROW)mysql_fetch_row(reader);

	rb_iv_set(self, "@state", result ? Qtrue : Qfalse);

	if (!result)
		return Qnil;

  int i;
 
	for (i = 0; i < reader->field_count; i++) {
		// The field_type data could be cached in a c-array
		char* field_type = RSTRING(rb_ary_entry(ruby_field_type_strings, i))->ptr;
		rb_ary_push(row, cast_mysql_value_to_ruby_value(result[i], field_type));
  }

	rb_iv_set(self, "@values", row);
	
	return Qtrue;
}

VALUE cReader_values(VALUE self) {
	VALUE state = rb_iv_get(self, "@state");
	if ( state == Qnil || state == Qfalse ) {
		rb_raise(rb_eException, "Reader is not initialized");
	}
	else {
		return rb_iv_get(self, "@values");
	}
}

VALUE cReader_fields(VALUE self) {
	return rb_iv_get(self, "@fields");
}

void Init_rbmysql() {
	rb_require("bigdecimal");
	
	ID_TO_I = rb_intern("to_i");
	ID_TO_F = rb_intern("to_f");
	ID_PARSE = rb_intern("parse");
	ID_TO_TIME = rb_intern("to_time");
	ID_NEW = rb_intern("new");
	ID_NEW_BANG = rb_intern("new!");
	ID_CONST_GET = rb_intern("const_get");
	ID_UTC = rb_intern("utc");
	ID_ESCAPE_SQL = rb_intern("escape_sql");
	ID_STRFTIME = rb_intern("strftime");
	
	// Store references to a few helpful clases that aren't in Ruby Core
	rb_cDate = RUBY_CLASS("Date");
	rb_cDateTime = RUBY_CLASS("DateTime");
	rb_cRational = RUBY_CLASS("Rational");
	rb_cBigDecimal = RUBY_CLASS("BigDecimal");
	rb_cURI = RUBY_CLASS("URI");
	
	// Get references to the DataObjects module and its classes
	mDO = CONST_GET(rb_mKernel, "DataObjects");
	cDO_Quoting = CONST_GET(mDO, "Quoting");
	cDO_Connection = CONST_GET(mDO, "Connection");
	cDO_Command = CONST_GET(mDO, "Command");
	cDO_Transaction = CONST_GET(mDO, "Transaction");
	cDO_Result = CONST_GET(mDO, "Result");
	cDO_Reader = CONST_GET(mDO, "Reader");
	
	// Store references to Errors we'll use
	// rb_do_eLengthMismatchError = DO_CLASS("LengthMismatchError");

	// Top Level Module that all the classes live under
	mRbMysql = rb_define_module_under(mDO, "Mysql");
	
	cConnection = DRIVER_CLASS("Connection", cDO_Connection);
	rb_define_method(cConnection, "initialize", cConnection_initialize, 1);
	rb_define_method(cConnection, "real_close", cConnection_real_close, 0);
	rb_define_method(cConnection, "begin_transaction", cConnection_begin_transaction, 0);
	
	cCommand = DRIVER_CLASS("Command", cDO_Command);
	rb_include_module(cCommand, cDO_Quoting);
	rb_define_method(cCommand, "set_types", cCommand_set_types, 1);
	rb_define_method(cCommand, "execute_non_query", cCommand_execute_non_query, -1);
	rb_define_method(cCommand, "execute_reader", cCommand_execute_reader, -1);

	cTransaction = DRIVER_CLASS("Transaction", cDO_Transaction);
	rb_define_method(cTransaction, "initialize", cTransaction_initialize, 1);
	rb_define_method(cTransaction, "commit", cTransaction_commit, 0);
	rb_define_method(cTransaction, "rollback", cTransaction_rollback, 1);
	rb_define_method(cTransaction, "save", cTransaction_save, 1);
	rb_define_method(cTransaction, "create_command", cTransaction_create_command, -1);
	
	// Non-Query result
	cResult = DRIVER_CLASS("Result", cDO_Result);
	
	// Query result
	cReader = DRIVER_CLASS("Reader", cDO_Reader);
	rb_define_method(cReader, "close", cReader_close, 0);
	rb_define_method(cReader, "next!", cReader_next, 0);
	rb_define_method(cReader, "values", cReader_values, 0);
	rb_define_method(cReader, "fields", cReader_fields, 0);
}