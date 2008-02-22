#include <ruby.h>
#include <string.h>
#include <math.h>
#include <mysql.h>
#include <errmsg.h>
#include <mysqld_error.h>
 
#define RUBY_CLASS(name) rb_const_get(rb_cObject, rb_intern(name))
#define CHAR_TO_STRING(name) rb_str_new2(name)
#define TAINTED_STRING(name) rb_tainted_str_new2(name)

static ID ID_TO_I;
static ID ID_TO_F;
static ID ID_PARSE;
static ID ID_TO_TIME;
static ID ID_NEW;
static ID ID_NEW_BANG;
static ID ID_CONST_GET;

static VALUE rb_cDate;
static VALUE rb_cDateTime;
static VALUE rb_cRational;
 
VALUE mRbMysql;
VALUE cConnection;
VALUE cResult;
 
// Figures out what we should cast a given mysql field type to
VALUE ruby_type_from_mysql_type(MYSQL_FIELD *field) {
 
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
		case MYSQL_TYPE_LONGLONG: {
			ruby_type_name = "FixNum";
			break;
		}
		case MYSQL_TYPE_DECIMAL:
		case MYSQL_TYPE_NEWDECIMAL:
		case MYSQL_TYPE_FLOAT:
		case MYSQL_TYPE_DOUBLE:
		case MYSQL_TYPE_YEAR: {
			ruby_type_name = "Float"; break;
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
			ruby_type_name = "String";
		}
	}
 
	return CHAR_TO_STRING(ruby_type_name);
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
	} else if (0 == strcmp("TrueClass", ruby_class_name) || 0 == strcmp("FalseClass", ruby_class_name)) {
		ruby_value = (NULL == data || 0 == data || 0 == strcmp("0", data)) ? Qfalse : Qtrue;
	} else if (0 == strcmp("Date", ruby_class_name)) {

		int year, month, day;

		// Used by math pulled out of Date.civil_to_jd and jd_to_ajd
		int a, b, jd, ajd;
		VALUE rational;

		sscanf(data, "%4d-%2d-%2d", &year, &month, &day);

		// Math from Date.civil_to_jd
		if ( month <= 2 ) {
			year -= 1;
			month += 12;
		}
		a = year / 100;
		b = 2 - a + (a / 4);
		jd = floor(365.25 * (year + 4716)) + floor(30.6001 * (month + 1)) + day + b - 1524;

		// Math from Date.jd_to_ajd
		ajd = jd * 2 - 1;
		rational = rb_funcall(rb_cRational, ID_NEW_BANG, 2, INT2NUM(ajd), INT2NUM(2));

		// Original (slooooow) Date [~5.8 seconds / 1000.times]:
		//		ruby_value = rb_funcall(rb_cDate, ID_PARSE, 1, rb_str_new2(sqlite3_value_text(value)));
		// Faster Date [~2.2 seconds / 1000.times]: 
		// 		ruby_value = rb_funcall(rb_cDate, ID_CIVIL, 3, INT2NUM(year), INT2NUM(month), INT2NUM(day));

		// Super fastest Date creation! [~0.25 seconds / 1000.times]
		// Yeah, that's 23 times faster than Date.parse
		ruby_value = rb_funcall(rb_cDate, ID_NEW_BANG, 3, rational, INT2NUM(0), INT2NUM(2299161));
	} else if (0 == strcmp("DateTime", ruby_class_name)) {
		int a, b, jd;
				int y, m, d, h, min, s;

				sscanf(data, "%4d-%2d-%2d %2d:%2d:%2d", &y, &m, &d, &h, &min, &s);

				// Original (slooooow) DateTime [~12 seconds / 1000.times]
				// 		ruby_value = rb_funcall(rb_cDateTime, ID_PARSE, 1, rb_str_new2(sqlite3_value_text(value)));

				// Faster DateTime [ ~7.3 seconds / 1000.times]
				// 		ruby_value = rb_funcall(rb_cDateTime, ID_CIVIL, 6, INT2NUM(y), INT2NUM(m), INT2NUM(d), INT2NUM(h), INT2NUM(min), INT2NUM(s));

				// Somewhat Faster [~6.3 seconds / 1000.times ]

				if ( m <= 2 ) {
					y -= 1;
					m += 12;
				}
				a = y / 100;
				b = 2 - a + (a / 4);
				jd = floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + d + b - 1524;

				VALUE fraction = rb_funcall(rb_cDate, rb_intern("time_to_day_fraction"), 3, INT2NUM(h), INT2NUM(min), INT2NUM(s));
				VALUE ajd = rb_funcall(rb_cDate, rb_intern("jd_to_ajd"), 2, INT2NUM(jd), fraction);
				ruby_value = rb_funcall(rb_cDateTime, rb_intern("new!"), 3, ajd, INT2NUM(0), INT2NUM(2299161));
	} else {
		ruby_value = TAINTED_STRING(data);
	}
 
	return ruby_value;
}
 
VALUE cConnection_initialize(VALUE self, VALUE host, VALUE user, VALUE password, VALUE database, VALUE port, VALUE unix_socket, VALUE client_flag) {
  MYSQL *db = 0 ;
  db = (MYSQL *)mysql_init(NULL);
 
	mysql_real_connect(
		db,
		StringValuePtr(host),
		StringValuePtr(user),
		StringValuePtr(password),
		StringValuePtr(database),
		3306,
		NULL,
		0
	);
 
	rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));
 
	return Qtrue;
}
 
VALUE cConnection_last_error(VALUE self) {
	MYSQL *db = DATA_PTR(rb_iv_get(self, "@connection"));
 
	char *error_message = (char *)mysql_error(db);
 
	return rb_str_new(error_message, strlen(error_message));
}
 
VALUE cConnection_execute_non_query(VALUE self, VALUE query) {
	MYSQL *db = DATA_PTR(rb_iv_get(self, "@connection"));
 
	int query_result = 0;
	MYSQL_RES *response = 0;
	VALUE reader = Qnil;
 
	query_result = mysql_query(db, StringValuePtr(query));
 
	response = (MYSQL_RES *)mysql_store_result(db);
 
	my_ulonglong affected_rows = mysql_affected_rows(db);
 
	if (-1 == affected_rows)
		return Qnil;
 
	reader = rb_funcall(cResult, ID_NEW, 0);
	rb_iv_set(reader, "@connection", self);
	rb_iv_set(reader, "@affected_rows", INT2NUM(affected_rows));
	rb_iv_set(reader, "@reader", Qnil);
 
	mysql_free_result(response);
 
	rb_iv_set(reader, "@inserted_id", INT2NUM(mysql_insert_id(db)));
 
	return reader;
}
 
VALUE cConnection_execute_reader(VALUE self, VALUE query) {
	MYSQL *db = DATA_PTR(rb_iv_get(self, "@connection"));
 
	int query_result = 0;
	MYSQL_RES *response = 0;
	VALUE result = Qnil;
 
	query_result = mysql_query(db, StringValuePtr(query));
 
	response = (MYSQL_RES *)mysql_use_result(db);
 
	if (!response) {
		return Qnil;
	}
 
	result = rb_funcall(cResult, ID_NEW, 0);
	rb_iv_set(result, "@connection", self);	
	rb_iv_set(result, "@reader", Data_Wrap_Struct(rb_cObject, 0, 0, response));
 
	int field_count = (int)mysql_field_count(db);
 
	rb_iv_set(result, "@affected_rows", Qnil);
	rb_iv_set(result, "@field_count", INT2NUM(field_count));
 
	VALUE field_names = rb_ary_new();
  VALUE field_types = rb_ary_new();
 
	MYSQL_FIELD *field;
 
	int i;
  for(i = 0; i < field_count; i++) {
		field = mysql_fetch_field_direct(response, i);;
		rb_ary_push(field_names, rb_str_new2(field->name));
		rb_ary_push(field_types, ruby_type_from_mysql_type(field));
  }
 
	rb_iv_set(result, "@field_names", field_names);
	rb_iv_set(result, "@field_types", field_types);
 
	return result;
}
 
VALUE cConnection_close(VALUE self) {
	MYSQL *db = DATA_PTR(rb_iv_get(self, "@connection"));
 
	if (NULL == db)
		return Qfalse;
 
	mysql_close(db);
	free(db);
 
	rb_iv_set(self, "@connection", Qnil);
 
	return Qtrue;
}
 
VALUE cConnection_is_opened(VALUE self) {
	return Qnil == rb_iv_get(self, "@connection") ? Qfalse : Qtrue;
}
 
// Accepts an array of Ruby types (Fixnum, Float, String, etc...) and turns them
// into Ruby-strings so we can easily typecast later
VALUE cResult_set_types(VALUE self, VALUE array) {
 
	int i;
 
	VALUE type_strings = rb_ary_new();
 
	for (i = 0; i < RARRAY(array)->len; i++) {
		rb_ary_push(type_strings, rb_str_new2(rb_class2name(rb_ary_entry(array, i))));
	}
 
	rb_iv_set(self, "@field_types", type_strings);
 
	return array;
}
 
// Retrieve a single row
VALUE cResult_fetch_row(VALUE self) {
	MYSQL_RES *reader = DATA_PTR(rb_iv_get(self, "@reader"));
	VALUE ruby_field_type_strings = rb_iv_get(self, "@field_types");
 
  VALUE row = rb_ary_new();
  MYSQL_ROW result = (MYSQL_ROW)mysql_fetch_row(reader);
 
  // TODO: there's probably something more specific we need to do here.
	if (!result)
		return Qnil;
 
  int i;
 
	for (i = 0; i < reader->field_count; i++) {
		// The field_type data could be cached
		char* field_type = RSTRING(rb_ary_entry(ruby_field_type_strings, i))->ptr;
		rb_ary_push(row, cast_mysql_value_to_ruby_value(result[i], field_type));
  }
 
	return row;
}
 
// This should be called to ensure that the internal result reader is freed
VALUE cResult_close(VALUE self) {
	MYSQL_RES *reader = DATA_PTR(rb_iv_get(self, "@reader"));
 
	if (NULL == reader)
		return Qfalse;
 
	mysql_free_result(reader);		
	rb_iv_set(self, "@reader", Qnil);
 
	return Qtrue;
}
 
 
void Init_rbmysql() {
	ID_TO_I = rb_intern("to_i");
	ID_TO_F = rb_intern("to_f");
	ID_PARSE = rb_intern("parse");
	ID_TO_TIME = rb_intern("to_time");
	ID_NEW = rb_intern("new");
	ID_NEW_BANG = rb_intern("new!");
	ID_CONST_GET = rb_intern("const_get");

	// Store references to a few helpful clases that aren't in Ruby Core
	rb_cDate = RUBY_CLASS("Date");
	rb_cDateTime = RUBY_CLASS("DateTime");
	rb_cRational = RUBY_CLASS("Rational");
 
	// Top Level Module that all the classes live under
	mRbMysql = rb_define_module("RbMysql");
 
	// Build the RBMysql::Connection Class
	cConnection = rb_define_class_under(mRbMysql, "Connection", rb_cObject);
	rb_define_method(cConnection, "initialize", cConnection_initialize, 7);
	rb_define_method(cConnection, "execute_reader", cConnection_execute_reader, 1);
	rb_define_method(cConnection, "execute_non_query", cConnection_execute_non_query, 1);
	rb_define_method(cConnection, "last_error", cConnection_last_error, 0);
	rb_define_method(cConnection, "close", cConnection_close, 0);
	rb_define_method(cConnection, "opened?", cConnection_is_opened, 0);
 
	// Build the RBMysql::Result Class
	cResult = rb_define_class_under(mRbMysql, "Result", rb_cObject);
	rb_define_attr(cResult, "connection", 1, 0);
	rb_define_attr(cResult, "affected_rows", 1, 0);
	rb_define_attr(cResult, "field_count", 1, 0);
	rb_define_attr(cResult, "field_names", 1, 0);
	rb_define_attr(cResult, "field_types", 1, 1);
	rb_define_attr(cResult, "inserted_id", 1, 0);
	rb_define_method(cResult, "fetch_row", cResult_fetch_row, 0);
	rb_define_method(cResult, "close", cResult_close, 0);
	rb_define_method(cResult, "set_types", cResult_set_types, 1);
}