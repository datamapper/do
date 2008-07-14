#include <ruby.h>
#include <version.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <locale.h>
#include <libpq-fe.h>
#include "type-oids.h"

#define ID_CONST_GET rb_intern("const_get")
#define ID_PATH rb_intern("path")
#define ID_NEW rb_intern("new")
#define ID_ESCAPE rb_intern("escape_sql")

#define RUBY_STRING(char_ptr) rb_str_new2(char_ptr)
#define TAINTED_STRING(name) rb_tainted_str_new2(name)
#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))
#define POSTGRES_CLASS(klass, parent) (rb_define_class_under(mPostgres, klass, parent))
#define DEBUG(value) data_objects_debug(value)

#ifdef _WIN32
#define do_int64 signed __int64
#else
#define do_int64 signed long long int
#endif

// To store rb_intern values
static ID ID_NEW_DATE;
static ID ID_LOGGER;
static ID ID_DEBUG;
static ID ID_LEVEL;

static VALUE mDO;
static VALUE cDO_Quoting;
static VALUE cDO_Connection;
static VALUE cDO_Command;
static VALUE cDO_Result;
static VALUE cDO_Reader;

static VALUE rb_cDate;
static VALUE rb_cDateTime;
static VALUE rb_cRational;
static VALUE rb_cBigDecimal;

static VALUE mPostgres;
static VALUE cConnection;
static VALUE cCommand;
static VALUE cResult;
static VALUE cReader;

static VALUE ePostgresError;

static void data_objects_debug(VALUE string) {
	VALUE logger = rb_funcall(mPostgres, ID_LOGGER, 0);
	int log_level = NUM2INT(rb_funcall(logger, ID_LEVEL, 0));

	if (0 == log_level) {
		rb_funcall(logger, ID_DEBUG, 1, string);
	}
}

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

static VALUE parse_date(const char *date) {
	int year, month, day;
	int jd, ajd;
	VALUE rational;

	sscanf(date, "%4d-%2d-%2d", &year, &month, &day);

	jd = jd_from_date(year, month, day);

	// Math from Date.jd_to_ajd
	ajd = jd * 2 - 1;
	rational = rb_funcall(rb_cRational, rb_intern("new!"), 2, INT2NUM(ajd), INT2NUM(2));

	return rb_funcall(rb_cDate, ID_NEW_DATE, 3, rational, INT2NUM(0), INT2NUM(2299161));
}

// Creates a Rational for use as a Timezone offset to be passed to DateTime.new!
static VALUE seconds_to_offset(do_int64 num) {
	do_int64 den = 86400;
	reduce(&num, &den);
	return rb_funcall(rb_cRational, rb_intern("new!"), 2, rb_ll2inum(num), rb_ll2inum(den));
}

static VALUE timezone_to_offset(int hour_offset, int minute_offset) {
	do_int64 seconds = 0;

	seconds += hour_offset * 3600;
	seconds += minute_offset * 60;

	return seconds_to_offset(seconds);
}

static VALUE parse_date_time(const char *date) {
	VALUE ajd, offset;

	int year, month, day, hour, min, sec, usec, hour_offset, minute_offset;
	int jd;
	do_int64 num, den;

	long int gmt_offset;
	int is_dst;

	time_t rawtime;
	struct tm * timeinfo;

	int tokens_read, max_tokens;

	if (0 != strchr(date, '.')) {
		// This is a datetime with sub-second precision
		tokens_read = sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d.%d%3d:%2d", &year, &month, &day, &hour, &min, &sec, &usec, &hour_offset, &minute_offset);
		max_tokens = 9;
	} else {
		// This is a datetime second precision
		tokens_read = sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d%3d:%2d", &year, &month, &day, &hour, &min, &sec, &hour_offset, &minute_offset);
		max_tokens = 8;
	}

	if (max_tokens == tokens_read) {
		// We read the Date, Time, and Timezone info
		minute_offset *= hour_offset < 0 ? -1 : 1;
	} else if ((max_tokens - 1) == tokens_read) {
		// We read the Date and Time, but no Minute Offset
		minute_offset = 0;
	} else if (tokens_read == 3) {
		return parse_date(date);
	} else if (tokens_read >= (max_tokens - 3)) {
		// We read the Date and Time, default to the current locale's offset

		// Get localtime
		time(&rawtime);
		timeinfo = localtime(&rawtime);

		is_dst = timeinfo->tm_isdst * 3600;

		// Reset to GM Time
		timeinfo = gmtime(&rawtime);

		gmt_offset = mktime(timeinfo) - rawtime;

		if ( is_dst > 0 )
			gmt_offset -= is_dst;

		hour_offset = -(gmt_offset / 3600);
		minute_offset = -(gmt_offset % 3600 / 60);

	} else {
		// Something went terribly wrong
		rb_raise(ePostgresError, "Couldn't parse date: %s", date);
	}

	jd = jd_from_date(year, month, day);

	// Generate ajd with fractional days for the time
	// Extracted from Date#jd_to_ajd, Date#day_fraction_to_time, and Rational#+ and #-
	num = (hour * 1440) + (min * 24);

	// Modify the numerator so when we apply the timezone everything works out
	num -= (hour_offset * 1440) + (minute_offset * 24);

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

	ajd = rb_funcall(rb_cRational, rb_intern("new!"), 2, rb_ull2inum(num), rb_ull2inum(den));
	offset = timezone_to_offset(hour_offset, minute_offset);

	return rb_funcall(rb_cDateTime, ID_NEW_DATE, 3, ajd, offset, INT2NUM(2299161));
}

static VALUE parse_time(char *date) {

	int year, month, day, hour, min, sec, usec;
	char subsec[7];

	if (0 != strchr(date, '.')) {
		// right padding usec with 0. e.g. '012' will become 12000 microsecond, since Time#local use microsecond
	  sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d.%s", &year, &month, &day, &hour, &min, &sec, subsec);
      usec = atoi(subsec);
      usec *= pow(10, (6 - strlen(subsec)));
	} else {
		sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d", &year, &month, &day, &hour, &min, &sec);
		usec = 0;
	}

	return rb_funcall(rb_cTime, rb_intern("local"), 7, INT2NUM(year), INT2NUM(month), INT2NUM(day), INT2NUM(hour), INT2NUM(min), INT2NUM(sec), INT2NUM(usec));
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
		// case TIMETZOID
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

	if ( strcmp(type, "Class") == 0) {
	  return rb_funcall(mDO, rb_intern("find_const"), 1, TAINTED_STRING(value));
	} else if ( strcmp(type, "Integer") == 0 || strcmp(type, "Fixnum") == 0 || strcmp(type, "Bignum") == 0 ) {
		return rb_cstr2inum(value, 10);
	} else if ( strcmp(type, "Float") == 0 ) {
		return rb_float_new(rb_cstr_to_dbl(value, Qfalse));
	} else if (0 == strcmp("BigDecimal", type) ) {
		return rb_funcall(rb_cBigDecimal, ID_NEW, 1, TAINTED_STRING(value));
	} else if ( strcmp(type, "TrueClass") == 0 ) {
		return *value == 't' ? Qtrue : Qfalse;
	} else if ( strcmp(type, "Date") == 0 ) {
		return parse_date(value);
	} else if ( strcmp(type, "DateTime") == 0 ) {
		return parse_date_time(value);
	} else if ( strcmp(type, "Time") == 0 ) {
		return parse_time(value);
	} else {
		return TAINTED_STRING(value);
	}

}

/* ====== Public API ======= */

static VALUE cConnection_initialize(VALUE self, VALUE uri) {
	VALUE r_host, r_user, r_password, r_path, r_port;
	char *host = NULL, *user = NULL, *password = NULL, *path;
	char *database = "", *port = "5432";

	PGconn *db;

	r_host = rb_funcall(uri, rb_intern("host"), 0);
	if ( Qnil != r_host && "localhost" != StringValuePtr(r_host) ) {
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
		rb_raise(ePostgresError, "Database must be specified");
	}

	r_port = rb_funcall(uri, rb_intern("port"), 0);
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
		rb_raise(ePostgresError, PQerrorMessage(db));
	}

	rb_iv_set(self, "@uri", uri);
	rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));

	return Qtrue;
}

static VALUE cConnection_dispose(VALUE self) {
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

static VALUE cCommand_quote_string(VALUE self, VALUE string) {
	PGconn *db = DATA_PTR(rb_iv_get(rb_iv_get(self, "@connection"), "@connection"));

	size_t length;
	const char *source = StringValuePtr(string);
	char *escaped;
	int quoted_length = 0;
	VALUE result;

	length = strlen(source);

	// Allocate space for the escaped version of 'string'
	// http://www.postgresql.org/docs/8.3/static/libpq-exec.html#LIBPQ-EXEC-ESCAPE-STRING
	escaped = (char *)calloc(strlen(source) * 2 + 3, sizeof(char));

	// Escape 'source' using the current charset in use on the conection 'db'
	quoted_length = PQescapeStringConn(db, escaped + 1, source, length, NULL);

	// Wrap the escaped string in single-quotes, this is DO's convention
	escaped[quoted_length + 1] = escaped[0] = '\'';

	result = rb_str_new(escaped, quoted_length + 2);
	free(escaped);
	return result;
}

static VALUE cCommand_execute_non_query(int argc, VALUE *argv[], VALUE self) {
	PGconn *db = DATA_PTR(rb_iv_get(rb_iv_get(self, "@connection"), "@connection"));
	PGresult *response;
	int status;

	int affected_rows;
	int insert_id;

	VALUE query = build_query_from_args(self, argc, argv);
	data_objects_debug(query);

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
	VALUE reader, query;
	VALUE field_names, field_types;

	int i;
	int field_count;
	int infer_types = 0;

	PGconn *db = DATA_PTR(rb_iv_get(rb_iv_get(self, "@connection"), "@connection"));
	PGresult *response;

	query = build_query_from_args(self, argc, argv);
	data_objects_debug(query);

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

	field_names = rb_ary_new();
	field_types = rb_iv_get(self, "@field_types");

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

	PGresult *reader;

	if (Qnil == reader_container)
		return Qfalse;

	reader = DATA_PTR(reader_container);

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

	char *type = "";

	VALUE array = rb_ary_new();
	VALUE field_types, ruby_type;
	VALUE value;

	row_count = NUM2INT(rb_iv_get(self, "@row_count"));
	field_count = NUM2INT(rb_iv_get(self, "@field_count"));
	field_types = rb_iv_get(self, "@field_types");
	position = NUM2INT(rb_iv_get(self, "@position"));

	if ( position > (row_count-1) ) {
		return Qnil;
	}

	for ( i = 0; i < field_count; i++ ) {
		ruby_type = RARRAY(field_types)->ptr[i];

		if ( TYPE(ruby_type) == T_STRING ) {
			type = RSTRING(ruby_type)->ptr;
		}
		else {
			type = rb_class2name(ruby_type);
		}

		// Always return nil if the value returned from Postgres is null
		if (!PQgetisnull(reader, position, i)) {
			value = typecast(PQgetvalue(reader, position, i), type);
		} else {
			value = Qnil;
		}

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

void Init_do_postgres_ext() {
	rb_require("rubygems");
	rb_require("date");
	rb_require("bigdecimal");

	// Get references classes needed for Date/Time parsing
	rb_cDate = CONST_GET(rb_mKernel, "Date");
	rb_cDateTime = CONST_GET(rb_mKernel, "DateTime");
	rb_cTime = CONST_GET(rb_mKernel, "Time");
	rb_cRational = CONST_GET(rb_mKernel, "Rational");
	rb_cBigDecimal = CONST_GET(rb_mKernel, "BigDecimal");

	rb_funcall(rb_mKernel, rb_intern("require"), 1, rb_str_new2("data_objects"));

	ID_NEW_DATE = RUBY_VERSION_CODE < 186 ? rb_intern("new0") : rb_intern("new!");
	ID_LOGGER = rb_intern("logger");
	ID_DEBUG = rb_intern("debug");
	ID_LEVEL = rb_intern("level");

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
	rb_define_method(cConnection, "dispose", cConnection_dispose, 0);

	cCommand = POSTGRES_CLASS("Command", cDO_Command);
	rb_include_module(cCommand, cDO_Quoting);
	rb_define_method(cCommand, "set_types", cCommand_set_types, 1);
	rb_define_method(cCommand, "execute_non_query", cCommand_execute_non_query, -1);
	rb_define_method(cCommand, "execute_reader", cCommand_execute_reader, -1);
	rb_define_method(cCommand, "quote_string", cCommand_quote_string, 1);

	cResult = POSTGRES_CLASS("Result", cDO_Result);

	cReader = POSTGRES_CLASS("Reader", cDO_Reader);
	rb_define_method(cReader, "close", cReader_close, 0);
	rb_define_method(cReader, "next!", cReader_next, 0);
	rb_define_method(cReader, "values", cReader_values, 0);
	rb_define_method(cReader, "fields", cReader_fields, 0);

}

