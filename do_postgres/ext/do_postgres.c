#include <string.h>
#include <math.h>
#include <ruby.h>
#include <libpq-fe.h>
#include "type-oids.h"

#define ID_CONST_GET rb_intern("const_get")
#define ID_PATH rb_intern("path")
#define ID_NEW rb_intern("new")
#define ID_ESCAPE rb_intern("escape_sql")

#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))
#define POSTGRES_CLASS(klass, parent) (rb_define_class_under(mPostgres, klass, parent))

#ifdef _WIN32
#define do_int64 unsigned __int64
#else
#define do_int64 unsigned long long int
#endif

static VALUE mDO;
static VALUE cDO_Quoting;
static VALUE cDO_Connection;
static VALUE cDO_Command;
static VALUE cDO_Result;
static VALUE cDO_Reader;

static VALUE rb_cDate;
static VALUE rb_cDateTime;
static VALUE rb_cRational;

static VALUE mPostgres;
static VALUE cConnection;
static VALUE cCommand;
static VALUE cResult;
static VALUE cReader;

static VALUE ePostgresError;

/* ====== Time/Date Parsing Helper Functions ====== */
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

static VALUE parse_date(char *date) {
	int year, month, day;
	int jd, ajd;
	VALUE rational;
	
	sscanf(date, "%4d-%2d-%2d", &year, &month, &day);
	
	jd = jd_from_date(year, month, day);
	
	// Math from Date.jd_to_ajd
	ajd = jd * 2 - 1;
	rational = rb_funcall(rb_cRational, rb_intern("new!"), 2, INT2NUM(ajd), INT2NUM(2));
	
	return rb_funcall(rb_cDate, rb_intern("new!"), 3, rational, INT2NUM(0), INT2NUM(2299161));
}

static VALUE parse_date_time(char *date) {
	int y, m, d, h, min, s;
	int jd;
	VALUE ajd;
	sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d", &y, &m, &d, &h, &min, &s);
	
	jd = jd_from_date(y, m, d);
	
	// Generate ajd with fractional days for the time
	// Extracted from Date#jd_to_ajd, Date#day_fraction_to_time, and Rational#+ and #-
	do_int64 num, den;
	
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
	
	ajd = rb_funcall(rb_cRational, rb_intern("new!"), 2, rb_ull2inum(num), rb_ull2inum(den));
	return rb_funcall(rb_cDateTime, rb_intern("new!"), 3, ajd, INT2NUM(0), INT2NUM(2299161));
}

static VALUE parse_time(char *date) {	
	int seconds, h, min, s;
	sscanf(date, "%2d:%2d:%2d", &h, &min, &s);
	
	seconds = h * 3600 + min * 60 + s;
	seconds += 6 * 3600; // Epoch begins at 6pm, so this gets our times fixed up
	
	return rb_funcall(rb_cTime, rb_intern("at"), 1, INT2NUM(seconds));
}

/* ===== Typecasting Functions ===== */

static VALUE infer_ruby_type(Oid type) {
	char *ruby_type = "String";
	switch(type) {
		case INT2OID:
		case INT4OID:
		case INT8OID: {
			ruby_type = "Fixnum";
			break;
		}
		case FLOAT4OID:
		case FLOAT8OID: {
			ruby_type = "Float";
			break;
		}
		case BOOLOID: {
			ruby_type = "TrueClass";
			break;
		}
		case TIMESTAMPOID: {
			ruby_type = "DateTime";
			break;
		}
		// case TIMESTAMPTZOID
		// case TIMETXOID
		case TIMEOID: {
			ruby_type = "Time";
			break;
		}
		case DATEOID: {
			ruby_type = "Date";
			break;
		}
	}
	return rb_str_new2(ruby_type);
}

static VALUE typecast(char *value, char *type) {
	if ( strcmp(value, "") == 0 ) {
		return Qnil;
	}
	else if ( strcmp(type, "Fixnum") == 0 || strcmp(type, "Integer") == 0 || strcmp(type, "Bignum") == 0 ) {
		return rb_cstr2inum(value, 10);
	}
	else if ( strcmp(type, "Float") == 0 ) {
		return rb_float_new(rb_cstr_to_dbl(value, Qfalse));
	}
	else if ( strcmp(type, "TrueClass") == 0 ) {
		return *value == 't' ? Qtrue : Qfalse;
	}
	else if ( strcmp(type, "Date") == 0 ) {
		return parse_date(value);
	}
	else if ( strcmp(type, "DateTime") == 0 ) {
		return parse_date_time(value);
	}
	else if ( strcmp(type, "Time") == 0 ) {
		return parse_time(value);
	}
	else {
		return rb_tainted_str_new2(value);
	}
}

/* ====== Public API ======= */

static VALUE cConnection_initialize(VALUE self, VALUE uri) {
	
	PGconn *db;
	
	VALUE r_host = rb_funcall(uri, rb_intern("host"), 0);
	char *host = "localhost";
	if ( Qnil != r_host ) {
		host = StringValuePtr(r_host);
	}
	
	VALUE r_user = rb_funcall(uri, rb_intern("user"), 0);
	char * user = NULL;
	if (Qnil != r_user) {
		user = StringValuePtr(r_user);
	}
	
	VALUE r_password = rb_funcall(uri, rb_intern("password"), 0);
	char * password = NULL;
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
		rb_raise(ePostgresError, "Database must be specified");
	}
	
	VALUE r_port = rb_funcall(uri, rb_intern("port"), 0);
	char *port = "5432";
	if (Qnil != r_port) {
		r_port = rb_funcall(r_port, rb_intern("to_s"), 0);
		port = StringValuePtr(r_port);
	}
	
	db = PQsetdbLogin(
		host, 
		port, 
		NULL, 
		NULL, 
		database, 
		user, 
		password
	);
	
	
	if ( PQstatus(db) == CONNECTION_BAD ) {
		rb_raise(rb_eException, PQerrorMessage(db));
	}
	
	rb_iv_set(self, "@uri", uri);
	rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));
	
	return Qtrue;
}

static VALUE cConnection_real_close(VALUE self) {
	PGconn *db = DATA_PTR(rb_iv_get(self, "@connection"));
	PQfinish(db);
	return Qtrue;
}

static VALUE cCommand_set_types(VALUE self, VALUE array) {
	rb_iv_set(self, "@field_types", array);
	return array;
}

static VALUE build_query_from_args(VALUE klass, int count, VALUE *args[]) {
	VALUE query = rb_iv_get(klass, "@text");
	if ( count > 0 ) {
		int i;
		VALUE array = rb_ary_new();
		for ( i = 0; i < count; i++) {
			rb_ary_push(array, (VALUE)args[i]);
		}
		query = rb_funcall(klass, ID_ESCAPE, 1, array);
	}
	return query;
}

static VALUE cCommand_execute_non_query(int argc, VALUE *argv[], VALUE self) {
	PGconn *db = DATA_PTR(rb_iv_get(rb_iv_get(self, "@connection"), "@connection"));
	PGresult *response;
	int status;
	
	int affected_rows;
	int insert_id;
	
	VALUE query = build_query_from_args(self, argc, argv);
	
	response = PQexec(db, StringValuePtr(query));
	
	status = PQresultStatus(response);
	
	if ( status == PGRES_TUPLES_OK ) {
		insert_id = atoi(PQgetvalue(response, 0, 0));
		affected_rows = 1;
	}
	else if ( status == PGRES_COMMAND_OK ) {
		insert_id = 0;
		affected_rows = atoi(PQcmdTuples(response));
	}
	else {
		char *message = PQresultErrorMessage(response);
		PQclear(response);
		rb_raise(ePostgresError, message);
	}
	
	PQclear(response);
	
	return rb_funcall(cResult, ID_NEW, 3, self, INT2NUM(affected_rows), INT2NUM(insert_id));
}

static VALUE cCommand_execute_reader(int argc, VALUE *argv[], VALUE self) {
	PGconn *db = DATA_PTR(rb_iv_get(rb_iv_get(self, "@connection"), "@connection"));
	PGresult *response;
	
	int i;
	int field_count;
	
	VALUE reader;
	VALUE query = build_query_from_args(self, argc, argv);
	
	response = PQexec(db, StringValuePtr(query));
	
	if ( PQresultStatus(response) != PGRES_TUPLES_OK ) {
		char *message = PQresultErrorMessage(response);
		PQclear(response);
		rb_raise(ePostgresError, message);
	}
	
	field_count = PQnfields(response);
	
	reader = rb_funcall(cReader, ID_NEW, 0);
	rb_iv_set(reader, "@reader", Data_Wrap_Struct(rb_cObject, 0, 0, response));
	rb_iv_set(reader, "@field_count", INT2NUM(field_count));
	rb_iv_set(reader, "@row_count", INT2NUM(PQntuples(response)));
	
	VALUE field_names = rb_ary_new();
	VALUE field_types = rb_iv_get(self, "@field_types");
	int infer_types = 0;
	
	if ( field_types == Qnil || RARRAY(field_types)->len == 0 ) {
		field_types = rb_ary_new();
		infer_types = 1;
	}
	
	for ( i = 0; i < field_count; i++ ) {
		rb_ary_push(field_names, rb_str_new2(PQfname(response, i)));
		if ( infer_types == 1 ) {
			rb_ary_push(field_types, infer_ruby_type(PQftype(response, i)));
		}
	}
	
	rb_iv_set(reader, "@position", INT2NUM(0));
	rb_iv_set(reader, "@fields", field_names);
	rb_iv_set(reader, "@field_types", field_types);
	
	return reader;
}

static VALUE cReader_close(VALUE self) {
	
	VALUE reader_container = rb_iv_get(self, "@reader");
	
	if (Qnil == reader_container)
		return Qfalse;
		
	PGresult *reader = DATA_PTR(reader_container);
		
	if (NULL == reader)
		return Qfalse;
		
	PQclear(reader);
	rb_iv_set(self, "@reader", Qnil);
	return Qtrue;
}

static VALUE cReader_next(VALUE self) {
	PGresult *reader = DATA_PTR(rb_iv_get(self, "@reader"));
	
	int field_count;
	int row_count;
	int i;
	int position;
	
	VALUE array = rb_ary_new();
	VALUE field_types;
	VALUE value;
	
	row_count = NUM2INT(rb_iv_get(self, "@row_count"));
	field_count = NUM2INT(rb_iv_get(self, "@field_count"));
	field_types = rb_iv_get(self, "@field_types");
	position = NUM2INT(rb_iv_get(self, "@position"));
	
	if ( position > (row_count-1) ) {
		return Qnil;
	}
	
	VALUE ruby_type;
	char *type = "";
	
	for ( i = 0; i < field_count; i++ ) {
		ruby_type = RARRAY(field_types)->ptr[i];
		
		if ( TYPE(ruby_type) == T_STRING ) {
			type = RSTRING(ruby_type)->ptr;
		}
		else {
			type = rb_class2name(ruby_type);
		}
		
		value = typecast(PQgetvalue(reader, position, i), type);
		rb_ary_push(array, value);
	}
	
	rb_iv_set(self, "@values", array);
	rb_iv_set(self, "@position", INT2NUM(position+1));
	
	return Qtrue;
}

static VALUE cReader_values(VALUE self) {
	
	int position = rb_iv_get(self, "@position");
	int row_count = NUM2INT(rb_iv_get(self, "@row_count"));
	
	if ( position == Qnil || NUM2INT(position) > row_count ) {
		rb_raise(ePostgresError, "Reader not initialized");
	}
	else {
		return rb_iv_get(self, "@values");
	}
}

static VALUE cReader_fields(VALUE self) {
	return rb_iv_get(self, "@fields");
}

void Init_do_postgres() {
	rb_require("rubygems");
	rb_require("date");
	
	// Get references classes needed for Date/Time parsing 
	rb_cDate = CONST_GET(rb_mKernel, "Date");
	rb_cDateTime = CONST_GET(rb_mKernel, "DateTime");
	rb_cTime = CONST_GET(rb_mKernel, "Time");
	rb_cRational = CONST_GET(rb_mKernel, "Rational");
	
	rb_funcall(rb_mKernel, rb_intern("require"), 1, rb_str_new2("data_objects"));
	
	// Get references to the DataObjects module and its classes
	mDO = CONST_GET(rb_mKernel, "DataObjects");
	cDO_Quoting = CONST_GET(mDO, "Quoting");
	cDO_Connection = CONST_GET(mDO, "Connection");
	cDO_Command = CONST_GET(mDO, "Command");
	cDO_Result = CONST_GET(mDO, "Result");
	cDO_Reader = CONST_GET(mDO, "Reader");
	
	mPostgres = rb_define_module_under(mDO, "Postgres");
	ePostgresError = rb_define_class("PostgresError", rb_eStandardError);
	
	cConnection = POSTGRES_CLASS("Connection", cDO_Connection);
	rb_define_method(cConnection, "initialize", cConnection_initialize, 1);
	rb_define_method(cConnection, "real_close", cConnection_real_close, 0);
	
	cCommand = POSTGRES_CLASS("Command", cDO_Command);
	rb_include_module(cCommand, cDO_Quoting);
	rb_define_method(cCommand, "set_types", cCommand_set_types, 1);
	rb_define_method(cCommand, "execute_non_query", cCommand_execute_non_query, -1);
	rb_define_method(cCommand, "execute_reader", cCommand_execute_reader, -1);
	
	cResult = POSTGRES_CLASS("Result", cDO_Result);
	
	cReader = POSTGRES_CLASS("Reader", cDO_Reader);
	rb_define_method(cReader, "close", cReader_close, 0);
	rb_define_method(cReader, "next!", cReader_next, 0);
	rb_define_method(cReader, "values", cReader_values, 0);
	rb_define_method(cReader, "fields", cReader_fields, 0);
	
}
