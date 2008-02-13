#include <ruby.h>
#include <mysql.h>
#include <errmsg.h>
#include <mysqld_error.h>

#define ID_TO_I rb_intern("to_i")
#define ID_TO_F rb_intern("to_f")
#define ID_PARSE rb_intern("parse")
#define ID_TO_TIME rb_intern("to_time")
#define ID_NEW rb_intern("new")
#define ID_CONST_GET rb_intern("const_get")

VALUE mRbMysql;
VALUE cConnection;
VALUE cResult;
VALUE rb_cDate;
VALUE rb_cDateTime;

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
	
	rb_iv_set(self, "@connection", Data_Wrap_Struct(cConnection, 0, free, db));
	
	return Qtrue;
}

VALUE cConnection_last_error(VALUE self) {
	MYSQL *db;
	Data_Get_Struct(rb_iv_get(self, "@connection"), MYSQL, db);
	
	char *error_message = (char *)mysql_error(db);
	
	return rb_str_new(error_message, strlen(error_message));
}

VALUE cConnection_execute_non_query(VALUE self, VALUE query) {
	MYSQL *db;
	Data_Get_Struct(rb_iv_get(self, "@connection"), MYSQL, db);
	
	int query_result = 0;
	MYSQL_RES *response = 0;
	VALUE reader = Qnil;
	
	query_result = mysql_query(db, StringValuePtr(query));
	
	response = (MYSQL_RES *)mysql_store_result(db);
	
	// if (!response)
	// 		return Qnil;
	
	// Create a reader and populate the affected rows and field count
	// reader = Data_Wrap_Struct(cResult, 0, free, response);
	reader = rb_funcall(cResult, ID_NEW, 0);
	// int field_count = (int)mysql_field_count(db);
	
	rb_iv_set(reader, "@affected_rows", INT2NUM(mysql_affected_rows(db)));
	rb_iv_set(reader, "@inserted_id", INT2NUM(mysql_insert_id(db)));
	
	return reader;
}

VALUE cConnection_execute_reader(VALUE self, VALUE query) {
	MYSQL *db;
	Data_Get_Struct(rb_iv_get(self, "@connection"), MYSQL, db);
	
	int query_result = 0;
	MYSQL_RES *response = 0;
	VALUE reader = Qnil;
	
	query_result = mysql_query(db, StringValuePtr(query));
	
	response = (MYSQL_RES *)mysql_use_result(db);
	
	if (!response)
	    return Qnil;

	// Create a reader and populate the affected rows and field count
	reader = Data_Wrap_Struct(cResult, 0, free, response);
	int field_count = (int)mysql_field_count(db);

	rb_iv_set(reader, "@affected_rows", INT2NUM(mysql_affected_rows(db)));
	rb_iv_set(reader, "@field_count", INT2NUM(field_count));

	VALUE field_names = rb_ary_new();
  VALUE field_types = rb_ary_new();

	// Allocate an array of pointers to MYSQL_FIELD structs so
	// we can typecast later without having to use
	MYSQL_FIELD **field_ptr;
	field_ptr = malloc(field_count * sizeof(MYSQL_FIELD *));
		
	int i;
  for(i = 0; i < field_count; i++) {
		field_ptr[i] = mysql_fetch_field_direct(response, i);;
		
		rb_ary_push(field_names, rb_str_new2(field_ptr[i]->name));
		rb_ary_push(field_types, INT2NUM(field_ptr[i]->type));
  }

	rb_iv_set(reader, "@field_names", field_names);
	rb_iv_set(reader, "@field_types", field_types);
	
	// So we can typecast in fetch_row
	VALUE native_field_types = Data_Wrap_Struct(rb_cObject, 0, free, field_ptr);
	rb_iv_set(reader, "@native_field_types", native_field_types);

	return reader;
}

VALUE cConnection_close(VALUE self) {
	MYSQL *db;
	Data_Get_Struct(rb_iv_get(self, "@connection"), MYSQL, db);
	
	mysql_close(db);

	return Qtrue;
}

VALUE cResult_close(VALUE self) {
	MYSQL_RES *reader;
	Data_Get_Struct(self, MYSQL_RES, reader);
	
	mysql_free_result(reader);
	
	return Qtrue;
}

VALUE typecast(const char* data, MYSQL_FIELD * field) {

  // when "NULL"
  //   nil
  // when "TINY"
  //   val != "0"
  // when "BIT"
  //   val.to_i(2)
  // when "SHORT", "LONG", "INT24", "LONGLONG"
  //   val == '' ? nil : val.to_i
  // when "DECIMAL", "NEWDECIMAL", "FLOAT", "DOUBLE", "YEAR"
  //   val.to_f
  // when "TIMESTAMP", "DATETIME"
  //   DateTime.parse(val) rescue nil
  // when "TIME"
  //   DateTime.parse(val).to_time rescue nil
  // when "DATE"
  //   Date.parse(val) rescue nil
  // else
  //   val

	VALUE ruby_value = rb_str_new2(data);

	switch(field->type) {
		case MYSQL_TYPE_NULL: {
			ruby_value = Qnil;
			break;
		}
		case MYSQL_TYPE_TINY: {
			ruby_value = "0" == data ? Qfalse : Qtrue;
			break;
		}
		case MYSQL_TYPE_BIT: {
			ruby_value = rb_funcall(ruby_value, ID_TO_I, 1, 2);
			break;
		}
		case MYSQL_TYPE_SHORT:
		case MYSQL_TYPE_LONG:
		case MYSQL_TYPE_INT24:
		case MYSQL_TYPE_LONGLONG: {
			ruby_value = "" == data ? Qnil : rb_funcall(ruby_value, ID_TO_I, 0);
			break;
		}
		case MYSQL_TYPE_DECIMAL:
		case MYSQL_TYPE_NEWDECIMAL:
		case MYSQL_TYPE_FLOAT:
		case MYSQL_TYPE_DOUBLE:
		case MYSQL_TYPE_YEAR: {
			ruby_value = rb_funcall(ruby_value, ID_TO_F, 0); break;
		}
		case MYSQL_TYPE_TIMESTAMP:
		case MYSQL_TYPE_DATETIME: {
			// TODO: Add rescue handling to return Qnil;
			ruby_value = rb_funcall(rb_cDateTime, ID_PARSE, 1, ruby_value);
			break;
		}
		case MYSQL_TYPE_TIME: {
			// TODO: Add rescue handling to return Qnil;
			VALUE dt_value = rb_funcall(rb_cDateTime, ID_PARSE, 1, ruby_value);
			ruby_value = rb_funcall(dt_value, ID_TO_TIME, 0);
			break;
		}
		case MYSQL_TYPE_DATE: {
			// TODO: Add rescue handling to return Qnil;
			ruby_value = rb_funcall(rb_cDate, ID_PARSE, 1, ruby_value); 
			break;
		}
	}

	return ruby_value;
}

VALUE cResult_fetch_row(VALUE self) {
	MYSQL_RES *reader;
	Data_Get_Struct(self, MYSQL_RES, reader);
	
	// There's got to be a better/faster way to do this.
	MYSQL_FIELD **field_ptr;
	Data_Get_Struct(rb_iv_get(self, "@native_field_types"), MYSQL_FIELD *, field_ptr);

  VALUE arr = rb_ary_new();
  MYSQL_ROW result = (MYSQL_ROW)mysql_fetch_row(reader);

  if (!result)
		return Qnil;

  int i;  
  for (i = 0; i < reader->field_count; i++) {
    if (result[i] == NULL) {
			rb_ary_push(arr, Qnil);
    } else {
			rb_ary_push(arr, typecast(result[i], field_ptr[i]));
		}
  }
  
	return arr;
}

void Init_rbmysql() {
	mysql_init(NULL);

	// Get references to Date and DateTime
	rb_cDate = rb_funcall(rb_mKernel, ID_CONST_GET, 1, rb_str_new2("Date"));
	rb_cDateTime = rb_funcall(rb_mKernel, ID_CONST_GET, 1, rb_str_new2("DateTime"));

	// Top Level Module that all the classes live under
	mRbMysql = rb_define_module("RbMysql");
	
	cResult = rb_define_class_under(mRbMysql, "Result", rb_cObject);
	rb_define_attr(cResult, "affected_rows", 1, 0);
	rb_define_attr(cResult, "field_count", 1, 0);
	rb_define_attr(cResult, "field_names", 1, 0);
	rb_define_attr(cResult, "field_types", 1, 0);
	rb_define_attr(cResult, "inserted_id", 1, 0);
	rb_define_method(cResult, "close", cResult_close, 0);
	rb_define_method(cResult, "fetch_row", cResult_fetch_row, 0);

	cConnection = rb_define_class_under(mRbMysql, "Connection", rb_cObject);
	rb_define_method(cConnection, "initialize", cConnection_initialize, 7);
	rb_define_method(cConnection, "execute_reader", cConnection_execute_reader, 1);
	rb_define_method(cConnection, "execute_non_query", cConnection_execute_non_query, 1);
	rb_define_method(cConnection, "close", cConnection_close, 0);

  // rb_define_singleton_method(RbMysql, "mysql_port", mysql_port_get, 0);
  // rb_define_singleton_method(RbMysql, "mysql_port=", mysql_port_set, 1);
  // rb_define_singleton_method(RbMysql, "mysql_unix_port", mysql_unix_port_get, 0);
  // rb_define_singleton_method(RbMysql, "mysql_unix_port=", mysql_unix_port_set, 1);
  // rb_define_const(RbMysql, "CLIENT_NET_READ_TIMEOUT", INT2NUM(365*24*3600));
  // rb_define_const(RbMysql, "CLIENT_NET_WRITE_TIMEOUT", INT2NUM(365*24*3600));
}