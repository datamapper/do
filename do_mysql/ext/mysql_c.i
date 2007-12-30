%module mysql_c
%{
 #include <mysql.h>
 #include <errmsg.h>
 #include <mysqld_error.h>

 VALUE mysql_c_fetch_field_names(MYSQL_RES *reader, int count) {
   VALUE arr = rb_ary_new();
   int i;
   for(i = 0; i < count; i++) {
     rb_ary_push(arr, rb_str_new2(mysql_fetch_field_direct(reader, i)->name));
   }
   return arr;
 }

 VALUE mysql_c_fetch_field_types(MYSQL_RES *reader, int count) {
   VALUE arr = rb_ary_new();
   int i;
   for(i = 0; i < count; i++) {
     rb_ary_push(arr, INT2NUM(mysql_fetch_field_direct(reader, i)->type));
   }
   return arr;
 }

 VALUE mysql_c_fetch_row(MYSQL_RES *reader) {
   VALUE arr = rb_ary_new();
   MYSQL_ROW result = (MYSQL_ROW)mysql_fetch_row(reader);
   if(!result) return Qnil;
   int i;
   
   for(i = 0; i < reader->field_count; i++) {
     if(result[i] == NULL) rb_ary_push(arr, Qnil);
     else rb_ary_push(arr, rb_str_new2(result[i]));
   }
   return arr;
 }

%}

%ignore st_mysql_options;
%include "/usr/local/mysql-5.0.45-osx10.4-i686/include/mysql.h"

VALUE mysql_c_fetch_field_names(MYSQL_RES *reader, int count);
VALUE mysql_c_fetch_field_types(MYSQL_RES *reader, int count);
VALUE mysql_c_fetch_row(MYSQL_RES *reader);

enum enum_field_types { MYSQL_TYPE_DECIMAL, MYSQL_TYPE_TINY,
			MYSQL_TYPE_SHORT,  MYSQL_TYPE_LONG,
			MYSQL_TYPE_FLOAT,  MYSQL_TYPE_DOUBLE,
			MYSQL_TYPE_NULL,   MYSQL_TYPE_TIMESTAMP,
			MYSQL_TYPE_LONGLONG,MYSQL_TYPE_INT24,
			MYSQL_TYPE_DATE,   MYSQL_TYPE_TIME,
			MYSQL_TYPE_DATETIME, MYSQL_TYPE_YEAR,
			MYSQL_TYPE_NEWDATE, MYSQL_TYPE_VARCHAR,
			MYSQL_TYPE_BIT,
                        MYSQL_TYPE_NEWDECIMAL=246,
			MYSQL_TYPE_ENUM=247,
			MYSQL_TYPE_SET=248,
			MYSQL_TYPE_TINY_BLOB=249,
			MYSQL_TYPE_MEDIUM_BLOB=250,
			MYSQL_TYPE_LONG_BLOB=251,
			MYSQL_TYPE_BLOB=252,
			MYSQL_TYPE_VAR_STRING=253,
			MYSQL_TYPE_STRING=254,
			MYSQL_TYPE_GEOMETRY=255

};