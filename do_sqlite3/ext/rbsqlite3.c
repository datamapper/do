#include <string.h>
#include <math.h>
#include <ruby.h>
#include <sqlite3.h>

#define ID_TO_S rb_intern("to_s")
#define ID_TO_I rb_intern("to_i")
#define ID_TO_F rb_intern("to_f")
#define ID_PARSE rb_intern("parse")
#define ID_TO_TIME rb_intern("to_time")
#define ID_NEW rb_intern("new")
#define ID_CIVIL rb_intern("civil")
#define ID_CONST_GET rb_intern("const_get")

VALUE mRbSqlite3;
VALUE cConnection;
VALUE cResult;
VALUE rb_cDate;
VALUE rb_cDateTime;
VALUE rb_cTime;
VALUE rb_cRational;

VALUE cConnection_initialize(VALUE self, VALUE filename) {
	sqlite3 *db;
	sqlite3_open(StringValuePtr(filename), &db);
	rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));
	return Qtrue;
}

VALUE cConnection_last_error(VALUE self) {
	return rb_iv_get(self, "@last_error");
}

VALUE cConnection_execute_non_query(VALUE self, VALUE query) {
	sqlite3 *db;
	char *errmsg;
	int ret;
	int affected_rows;
	int last_insert_id;
	VALUE reader = Qnil;
	
	Data_Get_Struct(rb_iv_get(self, "@connection"), sqlite3, db);
	
	ret = sqlite3_exec(db, StringValuePtr(query), 0, 0, &errmsg);
	
	if ( ret != SQLITE_OK ) {
		rb_iv_set(self, "@last_error", rb_str_new2(errmsg));
		return Qnil;
	}
	
	affected_rows = sqlite3_changes(db);
	last_insert_id = sqlite3_last_insert_rowid(db);
	
	reader = rb_funcall(cResult, ID_NEW, 0);
	rb_iv_set(reader, "@affected_rows", INT2NUM(affected_rows));
	rb_iv_set(reader, "@reader", Qnil);
	rb_iv_set(reader, "@inserted_id", INT2NUM(last_insert_id));
	
	return reader;
}

VALUE cConnection_execute_reader(VALUE self, VALUE query) {
	sqlite3 *db;
	sqlite3_stmt *reader;
	int ret;
	int field_count;
	int i;
	VALUE result = Qnil;
	
	Data_Get_Struct(rb_iv_get(self, "@connection"), sqlite3, db);
	
	ret = sqlite3_prepare_v2(db, StringValuePtr(query), -1, &reader, 0);
	
	if ( ret != SQLITE_OK ) {
		rb_iv_set(self, "@last_error", rb_str_new2(sqlite3_errmsg(db)));
		return Qnil;
	}
	
	field_count = sqlite3_column_count(reader);
	
	result = rb_funcall(cResult, ID_NEW, 0);
	rb_iv_set(result, "@reader", Data_Wrap_Struct(rb_cObject, 0, 0, reader));
	rb_iv_set(result, "@affected_rows", Qnil);
	rb_iv_set(result, "@field_count", INT2NUM(field_count));
	
	VALUE field_names = rb_ary_new();
	VALUE field_types = rb_ary_new();
	
	for ( i = 0; i < field_count; i++ ) {
		rb_ary_push(field_names, rb_str_new2(sqlite3_column_name(reader, i)));
		// TODO figure out how to get the field types before sqlite3_step() is called
		// rb_ary_push(field_types, INT2NUM(sqlite3_column_type(reader, i)));
	}
	
	rb_iv_set(result, "@field_names", field_names);
	rb_iv_set(result, "@field_types", field_types);
	
	return result;
}

VALUE cConnection_close(VALUE self) {
	sqlite3 *db;
	Data_Get_Struct(rb_iv_get(self, "@connection"), sqlite3, db);
	sqlite3_close(db);
	return Qtrue;
}

VALUE cResult_close(VALUE self) {
	VALUE reader_value = rb_iv_get(self, "@reader");
	
	if ( reader_value != Qnil ) {
		sqlite3_stmt *reader;
		Data_Get_Struct(reader_value, sqlite3_stmt, reader);
		sqlite3_finalize(reader);
		rb_iv_set(self, "@reader", Qnil);
		return Qtrue;
	}
	else {
		return Qfalse;
	}
}

VALUE cResult_set_types(VALUE self, VALUE array) {
	rb_iv_set(self, "@field_types", array);
	return array;
}


// Add rescue handling for null, etc.
VALUE native_typecast(sqlite3_value *value, int type) {
	VALUE ruby_value = Qnil;
	switch(type) {
		case SQLITE_NULL: {
			ruby_value = Qnil;
			break;
		}
		case SQLITE_INTEGER: {
			ruby_value = INT2NUM(sqlite3_value_int(value));
			break;
		}
		case SQLITE3_TEXT: {
			ruby_value = rb_str_new2(sqlite3_value_text(value));
			break;
		}
		case SQLITE_FLOAT: {
			ruby_value = rb_float_new(sqlite3_value_double(value));
			break;
		}
	}
	return ruby_value;
}

// Add rescue handling for null, etc.
VALUE ruby_typecast(sqlite3_value *value, char *type) {
	VALUE ruby_value = Qnil;
	if ( strcmp(type, "Fixnum") == 0 ) {
		ruby_value = INT2NUM(sqlite3_value_int(value));
	}
	else if ( strcmp(type, "String") == 0 ) {
		ruby_value = rb_str_new2(sqlite3_value_text(value));
	}
	else if ( strcmp(type, "Float") == 0 ) {
		ruby_value = rb_float_new(sqlite3_value_double(value));
	}
	else if ( strcmp(type, "Date") == 0 ) {
		int year, month, day;
		char *date = sqlite3_value_text(value);
		
		// Used by math pulled out of Date.civil_to_jd and jd_to_ajd
		int a, b, jd, ajd;
		VALUE rational;
		
		sscanf(date, "%4d-%2d-%2d", &year, &month, &day);
		
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
		rational = rb_funcall(rb_cRational, rb_intern("new!"), 2, INT2NUM(ajd), INT2NUM(2));
		
		// Original (slooooow) Date [~5.8 seconds / 1000.times]:
		//		ruby_value = rb_funcall(rb_cDate, ID_PARSE, 1, rb_str_new2(sqlite3_value_text(value)));
		// Faster Date [~2.2 seconds / 1000.times]: 
		// 		ruby_value = rb_funcall(rb_cDate, ID_CIVIL, 3, INT2NUM(year), INT2NUM(month), INT2NUM(day));
		
		// Super fastest Date creation! [~0.25 seconds / 1000.times]
		// Yeah, that's 23 times faster than Date.parse
		ruby_value = rb_funcall(rb_cDate, rb_intern("new!"), 3, rational, INT2NUM(0), INT2NUM(2299161));
	}
	else if ( strcmp(type, "DateTime") == 0 ) {
		int a, b, jd;
		int y, m, d, h, min, s;
		char *date = sqlite3_value_text(value);
		
		sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d", &y, &m, &d, &h, &min, &s);
		
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
	}
	else if ( strcmp(type, "Time") == 0 ) {
		int y, m, d, h, min, s;
		char *date = sqlite3_value_text(value);
		
		sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d", &y, &m, &d, &h, &min, &s);
		
		ruby_value = rb_funcall(rb_cTime, rb_intern("utc"), 6, INT2NUM(y), INT2NUM(m), INT2NUM(d), INT2NUM(h), INT2NUM(min), INT2NUM(s));
	}
	return ruby_value;
}



VALUE cResult_fetch_row(VALUE self) {
	sqlite3_stmt *reader;
	int field_count;
	int result;
	int i;
	int ft_length;
	VALUE arr = rb_ary_new();
	VALUE field_types;
	VALUE value;
	
	Data_Get_Struct(rb_iv_get(self, "@reader"), sqlite3_stmt, reader);
	field_count = NUM2INT(rb_iv_get(self, "@field_count"));
	
	field_types = rb_iv_get(self, "@field_types");
	ft_length = RARRAY(field_types)->len;
	
	result = sqlite3_step(reader);
	
	if ( result != SQLITE_ROW ) {
		return Qnil;
	}
	
	for ( i = 0; i < field_count; i++ ) {
		if ( ft_length == 0 ) {
			value = native_typecast(sqlite3_column_value(reader, i), sqlite3_column_type(reader, i));
		}
		else {
			value = ruby_typecast(sqlite3_column_value(reader, i), rb_class2name(RARRAY(field_types)->ptr[i]));
		}
		rb_ary_push(arr, value);
	}
	
	return arr;
}

void Init_rbsqlite3() {
	// Get references to Date and DateTime
	rb_cDate = rb_funcall(rb_mKernel, ID_CONST_GET, 1, rb_str_new2("Date"));
	rb_cDateTime = rb_funcall(rb_mKernel, ID_CONST_GET, 1, rb_str_new2("DateTime"));
	rb_cTime = rb_funcall(rb_mKernel, ID_CONST_GET, 1, rb_str_new2("Time"));
	rb_cRational = rb_funcall(rb_mKernel, ID_CONST_GET, 1, rb_str_new2("Rational"));
	
	// Top Level Module
	mRbSqlite3 = rb_define_module("RbSqlite3");
	
	cConnection = rb_define_class_under(mRbSqlite3, "Connection", rb_cObject);
	rb_define_method(cConnection, "initialize", cConnection_initialize, 1);
	rb_define_method(cConnection, "execute_reader", cConnection_execute_reader, 1);
	rb_define_method(cConnection, "execute_non_query", cConnection_execute_non_query, 1);
	rb_define_method(cConnection, "last_error", cConnection_last_error, 0);
	rb_define_method(cConnection, "close", cConnection_close, 0);
	
	cResult = rb_define_class_under(mRbSqlite3, "Result", rb_cObject);
	rb_define_attr(cResult, "affected_rows", 1, 0);
	rb_define_attr(cResult, "field_count", 1, 0);
	rb_define_attr(cResult, "field_names", 1, 0);
	rb_define_attr(cResult, "field_types", 1, 0);
	rb_define_attr(cResult, "inserted_id", 1, 0);
	
	rb_define_method(cResult, "set_types", cResult_set_types, 1);
	rb_define_method(cResult, "fetch_row", cResult_fetch_row, 0);
	rb_define_method(cResult, "close", cResult_close, 0);
}