#include <ruby.h>
#include <version.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <mysql.h>
#include <errmsg.h>
#include <mysqld_error.h>
 
#define RUBY_CLASS(name) rb_const_get(rb_cObject, rb_intern(name))
#define RUBY_STRING(char_ptr) rb_str_new2(char_ptr)
#define TAINTED_STRING(name) rb_tainted_str_new2(name)
#define DRIVER_CLASS(klass, parent) (rb_define_class_under(mDOMysql, klass, parent))
#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))
#define CHECK_AND_RAISE(mysql_result_value) if (0 != mysql_result_value) { raise_mysql_error(db, mysql_result_value); }

#ifdef _WIN32
#define do_int64 unsigned __int64
#else
#define do_int64 unsigned long long int
#endif

// To store rb_intern values
static ID ID_TO_I;
static ID ID_TO_F;
static ID ID_TO_S;
static ID ID_PARSE;
static ID ID_TO_TIME;
static ID ID_NEW;
static ID ID_NEW_RATIONAL;
static ID ID_NEW_DATE;
static ID ID_CONST_GET;
static ID ID_UTC;
static ID ID_ESCAPE_SQL;
static ID ID_STRFTIME;

// References to DataObjects base classes
static VALUE mDO;
static VALUE cDO_Quoting;
static VALUE cDO_Connection;
static VALUE cDO_Command;
static VALUE cDO_Result;
static VALUE cDO_Reader;

// References to Ruby classes that we'll need
static VALUE rb_cDate;
static VALUE rb_cDateTime;
static VALUE rb_cRational;
static VALUE rb_cBigDecimal;
static VALUE rb_cURI;
static VALUE rb_cCGI;

// Classes that we'll build in Init
static VALUE mDOMysql;
static VALUE cConnection;
static VALUE cCommand;
static VALUE cResult;
static VALUE cReader;
static VALUE eMysqlError;
 
// Figures out what we should cast a given mysql field type to
static char * ruby_type_from_mysql_type(MYSQL_FIELD *field) {
 
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
static void reduce( do_int64 *numerator, do_int64 *denominator ) {
  do_int64 a, b, c;
  a = *numerator;
  b = *denominator;
  while ( a != 0 ) {
    c = a; a = b % a; b = c;
  }
  *numerator = *numerator / b;
  *denominator = *denominator / b;
}
 
// Generate the date integer which Date.civil_to_jd returns
static int jd_from_date(int year, int month, int day) {
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
static VALUE cast_mysql_value_to_ruby_value(const char* data, char* ruby_class_name) {
	VALUE ruby_value = Qnil;
	VALUE rational, ajd_value;

	int year, month, day, hour, min, sec;
	int jd, ajd;

	do_int64 num, den;

	if (NULL == data)
		return Qnil;

	if (0 == strcmp("Fixnum", ruby_class_name)) {
		ruby_value = (0 == strlen(data) ? Qnil : LL2NUM(atol(data)));
	} else if (0 == strcmp("Bignum", ruby_class_name)) {
		ruby_value = (0 == strlen(data) ? Qnil : rb_int2big(atol(data)));
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
		sscanf(data, "%4d-%2d-%2d", &year, &month, &day);

		jd = jd_from_date(year, month, day);

		// Math from Date.jd_to_ajd
		ajd = jd * 2 - 1;
		rational = rb_funcall(rb_cRational, ID_NEW_RATIONAL, 2, INT2NUM(ajd), INT2NUM(2));
		ruby_value = rb_funcall(rb_cDate, ID_NEW_DATE, 3, rational, INT2NUM(0), INT2NUM(2299161));
	} else if (0 == strcmp("DateTime", ruby_class_name)) {
		sscanf(data, "%4d-%2d-%2d %2d:%2d:%2d", &year, &month, &day, &hour, &min, &sec);

		jd = jd_from_date(year, month, day);

		// Generate ajd with fractional days for the time
		// Extracted from Date#jd_to_ajd, Date#day_fraction_to_time, and Rational#+ and #-
		num = (hour * 1440) + (min * 24);
		den = (24 * 1440);
		reduce(&num, &den);

		num = (num * 86400) + (sec * den);
		den = den * 86400;
		reduce(&num, &den);

		num = (jd * den) + num;

		num = num * 2;
		num = num - den;
		den = den * 2;

		reduce(&num, &den);

		ajd_value = rb_funcall(rb_cRational, ID_NEW_RATIONAL, 2, rb_ull2inum(num), rb_ull2inum(den));
		ruby_value = rb_funcall(rb_cDateTime, ID_NEW_DATE, 3, ajd_value, INT2NUM(0), INT2NUM(2299161));
	} else if (0 == strcmp("Time", ruby_class_name)) {
		sscanf(data, "%4d-%2d-%2d %2d:%2d:%2d", &year, &month, &day, &hour, &min, &sec);

		ruby_value = rb_funcall(rb_cTime, ID_UTC, 6, INT2NUM(year), INT2NUM(month), INT2NUM(day), INT2NUM(hour), INT2NUM(min), INT2NUM(sec));
	} else {
		ruby_value = TAINTED_STRING(data);
	}

	return ruby_value;
}

static void raise_mysql_error(MYSQL *db, int mysql_error_code) {
	char *error_message = (char *)mysql_error(db);
	// char *extra = "";

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
	
	rb_raise(eMysqlError, error_message);
}

// Pull an option out of a querystring-formmated option list using CGI::parse
static char * get_uri_option(VALUE querystring, char * key) {
	VALUE options_hash, option_value;

	char * value = NULL;

	// Ensure that we're dealing with a string
	querystring = rb_funcall(querystring, ID_TO_S, 0);

	options_hash = rb_funcall(rb_cCGI, ID_PARSE, 1, querystring);

	// TODO: rb_hash_aref always returns an array?
	option_value = rb_ary_entry(rb_hash_aref(options_hash, RUBY_STRING(key)), 0);

	if (Qnil != option_value) {
		value = StringValuePtr(option_value);
	}

	return value;
}

static VALUE cConnection_initialize(VALUE self, VALUE uri) {
	VALUE r_host, r_user, r_password, r_path, r_options, r_port;

	char *host = "localhost", *user = NULL, *password = NULL, *path;
	char *database = "", *socket = NULL;
	char *charset = NULL;

	int port = 3306;
	unsigned long client_flags = 0;
	int charset_error;

	MYSQL *db = 0, *result;
	db = (MYSQL *)mysql_init(NULL);

	rb_iv_set(self, "@using_socket", Qfalse);

	r_host = rb_funcall(uri, rb_intern("host"), 0);
	if (Qnil != r_host) {
		host = StringValuePtr(r_host);
	}
	
	r_user = rb_funcall(uri, rb_intern("user"), 0);
	if (Qnil != r_user) {
		user = StringValuePtr(r_user);
	}

	r_password = rb_funcall(uri, rb_intern("password"), 0);
	if (Qnil != r_password) {
		password = StringValuePtr(r_password);
	}

	r_path = rb_funcall(uri, rb_intern("path"), 0);
	path = StringValuePtr(r_path);
	if (Qnil != r_path) {
		database = strtok(path, "/");
	}

	if (NULL == database || 0 == strlen(database)) {
		rb_raise(eMysqlError, "Database must be specified");
	}

	// Pull the querystring off the URI
	r_options = rb_funcall(uri, rb_intern("query"), 0);

	// Check to see if we're on the db machine.  If so, try to use the socket
	if (0 == strcasecmp(host, "localhost")) {
		// TODO: Read the socket path from my.conf [client]
		// char *options = NULL;
		// options = mysql_options(db, MYSQL_READ_DEFAULT_GROUP, "client");
		// parse the socket=<path> line here.

		socket = get_uri_option(r_options, "socket");
		if (NULL != socket) {
			rb_iv_set(self, "@using_socket", Qtrue);
		}
	}

	r_port = rb_funcall(uri, rb_intern("port"), 0);
	if (Qnil != r_port) {
		port = NUM2INT(r_port);
	}

	charset = get_uri_option(r_options, "charset");

	// If ssl? {
	//   mysql_ssl_set(db, key, cert, ca, capath, cipher)
	// }

	result = (MYSQL *)mysql_real_connect(
		db,
		host,
		user,
		password,
		database,
		port,
		socket,
		client_flags
	);

	if (NULL == result) {
		raise_mysql_error(db, -1);
	}

	if (NULL == charset) {
		charset = (char*)calloc(4, sizeof(char));
		strcpy(charset, "utf8");
	}

	// Set the connections character set
	charset_error = mysql_set_character_set(db, charset);
	if (0 != charset_error) {
		raise_mysql_error(db, charset_error);
	}

	rb_iv_set(self, "@uri", uri);
	rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));

	// free(host);
	// free(user);
	// free(socket);
	// free(charset);

	return Qtrue;
}

static VALUE cConnection_character_set(VALUE self) {
	VALUE connection_container = rb_iv_get(self, "@connection");
	MYSQL *db;

	const char *charset;

	if (Qnil == connection_container)
		return Qfalse;

	db = DATA_PTR(connection_container);

	charset = mysql_character_set_name(db);

	return RUBY_STRING(charset);
}

static VALUE cConnection_is_using_socket(VALUE self) {
	return rb_iv_get(self, "@using_socket");
}

static VALUE cConnection_real_close(VALUE self) {
	VALUE connection_container = rb_iv_get(self, "@connection");

	MYSQL *db;

	if (Qnil == connection_container)
		return Qfalse;

	db = DATA_PTR(connection_container);

	if (NULL == db)
		return Qfalse;

	mysql_close(db);
	rb_iv_set(self, "@connection", Qnil);

	return Qtrue;
}

// Spec me
// VALUE cCommand_quote_time(VALUE self, VALUE value) {
//  	// TIMESTAMP() used for both time and datetime columns
// 	return rb_funcall(value, ID_STRFTIME, 1, RUBY_STRING("TIMESTAMP(\"%Y-%m-%d %H:%M:%S\")"));
// }
// 
// VALUE cCommand_quote_datetime(VALUE self, VALUE value) {
//   // "TIMESTAMP('#{value.strftime("%Y-%m-%d %H:%M:%S")}')"
// 	return rb_funcall(value, ID_STRFTIME, 1, RUBY_STRING("TIMESTAMP(\"%Y-%m-%d %H:%M:%S\")"));
// }
// 
// VALUE cCommand_quote_date(VALUE self, VALUE value) {
//   // "DATE('#{value.strftime("%Y-%m-%d")}')"
// 	return rb_funcall(value, ID_STRFTIME, 1, RUBY_STRING("TIMESTAMP(\"%Y-%m-%d\")"));
// }

// Accepts an array of Ruby types (Fixnum, Float, String, etc...) and turns them
// into Ruby-strings so we can easily typecast later
static VALUE cCommand_set_types(VALUE self, VALUE array) {
	VALUE type_strings = rb_ary_new();
	int i;

	for (i = 0; i < RARRAY(array)->len; i++) {
		rb_ary_push(type_strings, rb_str_new2(rb_class2name(rb_ary_entry(array, i))));
	}

	rb_iv_set(self, "@field_types", type_strings);

	return array;
}

static VALUE cCommand_quote_string(VALUE self, VALUE string) {
	MYSQL *db = DATA_PTR(rb_iv_get(rb_iv_get(self, "@connection"), "@connection"));
	const char *source = StringValuePtr(string);
	char *escaped;
	char *with_quotes;
	
	int quoted_length = 0;

	// Allocate space for the escaped version of 'string'.  Use + 3 allocate space for null term.
	// and the leading and trailing single-quotes.
	// Thanks to http://www.browardphp.com/mysql_manual_en/manual_MySQL_APIs.html#mysql_real_escape_string	
	escaped = (char *)calloc(strlen(source) * 3 + 1, sizeof(char));

	// Escape 'source' using the current charset in use on the conection 'db'
	quoted_length = mysql_real_escape_string(db, escaped, source, strlen(source));

	// Allocate space for the final version of the quoted string.
	with_quotes = (char *)calloc(quoted_length + 3, sizeof(char));
	// Wrap the escaped string in single-quotes, this is DO's convention
	sprintf(with_quotes, "'%s'", escaped);

	// free(escaped);
	return RUBY_STRING(with_quotes);
}

static VALUE cCommand_execute_non_query(int argc, VALUE *argv, VALUE self) {
	VALUE query, array;

	MYSQL_RES *response = 0;
	int query_result = 0;
	int i;

	my_ulonglong affected_rows;

	MYSQL *db = DATA_PTR(rb_iv_get(rb_iv_get(self, "@connection"), "@connection"));

	query = rb_iv_get(self, "@text");

	if ( argc > 0 ) {
		array = rb_ary_new();
		for ( i = 0; i < argc; i++ ) {
			rb_ary_push(array, argv[i]);
		}
		query = rb_funcall(self, ID_ESCAPE_SQL, 1, array);
	}

	query_result = mysql_query(db, StringValuePtr(query));
	CHECK_AND_RAISE(query_result);

	response = (MYSQL_RES *)mysql_store_result(db);
	affected_rows = mysql_affected_rows(db);
	mysql_free_result(response);

	if (-1 == affected_rows)
		return Qnil;

	return rb_funcall(cResult, ID_NEW, 3, self, INT2NUM(affected_rows), INT2NUM(mysql_insert_id(db)));
}

static VALUE cCommand_execute_reader(int argc, VALUE *argv, VALUE self) {
	VALUE query, reader;
	VALUE field_names, field_types;
	VALUE array;

	int query_result = 0;
	int field_count;
	int i;

	char guess_default_field_types = 0;

	MYSQL *db = DATA_PTR(rb_iv_get(rb_iv_get(self, "@connection"), "@connection"));

	MYSQL_RES *response = 0;
	MYSQL_FIELD *field;

	query = rb_iv_get(self, "@text");

	if ( argc > 0 ) {
		array = rb_ary_new();
		for (i = 0; i < argc; i++ ) {
			rb_ary_push(array, argv[i]);
		}
		query = rb_funcall(self, ID_ESCAPE_SQL, 1, array);
	}

	query_result = mysql_query(db, StringValuePtr(query));
	CHECK_AND_RAISE(query_result);

	response = (MYSQL_RES *)mysql_use_result(db);

	if (!response) {
		return Qnil;
	}
	
	field_count = (int)mysql_field_count(db);
	
	reader = rb_funcall(cReader, ID_NEW, 0);
	rb_iv_set(reader, "@reader", Data_Wrap_Struct(rb_cObject, 0, 0, response));
	rb_iv_set(reader, "@opened", Qtrue);
	rb_iv_set(reader, "@field_count", INT2NUM(field_count));

	field_names = rb_ary_new();
	field_types = rb_iv_get(self, "@field_types");

	if ( field_types == Qnil || 0 == RARRAY(field_types)->len ) {
		field_types = rb_ary_new();
		guess_default_field_types = 1;
	}

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

// This should be called to ensure that the internal result reader is freed
static VALUE cReader_close(VALUE self) {
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
static VALUE cReader_next(VALUE self) {
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

static VALUE cReader_values(VALUE self) {
	VALUE state = rb_iv_get(self, "@state");
	if ( state == Qnil || state == Qfalse ) {
		rb_raise(rb_eException, "Reader is not initialized");
	}
	else {
		return rb_iv_get(self, "@values");
	}
}

static VALUE cReader_fields(VALUE self) {
	return rb_iv_get(self, "@fields");
}

void Init_do_mysql() {
	rb_require("rubygems");
	rb_require("bigdecimal");
  rb_require("date");
  rb_require("cgi");

  rb_funcall(rb_mKernel, rb_intern("require"), 1, rb_str_new2("data_objects"));
	
	ID_TO_I = rb_intern("to_i");
	ID_TO_F = rb_intern("to_f");
	ID_TO_S = rb_intern("to_s");
	ID_PARSE = rb_intern("parse");
	ID_TO_TIME = rb_intern("to_time");
	ID_NEW = rb_intern("new");
	ID_NEW_RATIONAL = rb_intern("new!");
	ID_NEW_DATE = RUBY_VERSION_CODE < 186 ? rb_intern("new0") : rb_intern("new!");
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
	rb_cCGI = RUBY_CLASS("CGI");
	
	// Get references to the DataObjects module and its classes
	mDO = CONST_GET(rb_mKernel, "DataObjects");
	cDO_Quoting = CONST_GET(mDO, "Quoting");
	cDO_Connection = CONST_GET(mDO, "Connection");
	cDO_Command = CONST_GET(mDO, "Command");
	cDO_Result = CONST_GET(mDO, "Result");
	cDO_Reader = CONST_GET(mDO, "Reader");

	// Top Level Module that all the classes live under
	mDOMysql = rb_define_module_under(mDO, "Mysql");
	
	eMysqlError = rb_define_class("MysqlError", rb_eStandardError);
	
	cConnection = DRIVER_CLASS("Connection", cDO_Connection);
	rb_define_method(cConnection, "initialize", cConnection_initialize, 1);
	rb_define_method(cConnection, "using_socket?", cConnection_is_using_socket, 0);
	rb_define_method(cConnection, "character_set", cConnection_character_set , 0);
	rb_define_method(cConnection, "real_close", cConnection_real_close, 0);
	
	cCommand = DRIVER_CLASS("Command", cDO_Command);
	rb_include_module(cCommand, cDO_Quoting);
	rb_define_method(cCommand, "set_types", cCommand_set_types, 1);
	rb_define_method(cCommand, "execute_non_query", cCommand_execute_non_query, -1);
	rb_define_method(cCommand, "execute_reader", cCommand_execute_reader, -1);
	rb_define_method(cCommand, "quote_string", cCommand_quote_string, 1);
	// These need to be specced
	// rb_define_method(cCommand, "quote_time", cCommand_quote_time, 1);
	// rb_define_method(cCommand, "quote_datetime", cCommand_quote_datetime, 1);
	// rb_define_method(cCommand, "quote_date", cCommand_quote_date, 1);

	// Non-Query result
	cResult = DRIVER_CLASS("Result", cDO_Result);
	
	// Query result
	cReader = DRIVER_CLASS("Reader", cDO_Reader);
	rb_define_method(cReader, "close", cReader_close, 0);
	rb_define_method(cReader, "next!", cReader_next, 0);
	rb_define_method(cReader, "values", cReader_values, 0);
	rb_define_method(cReader, "fields", cReader_fields, 0);
}
