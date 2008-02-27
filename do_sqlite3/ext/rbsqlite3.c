#include <string.h>
#include <math.h>
#include <ruby.h>
#include <sqlite3.h>

#define ID_CONST_GET rb_intern("const_get")
#define ID_PATH rb_intern("path")
#define ID_NEW rb_intern("new")

#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))
#define SQLITE3_CLASS(klass, parent) (rb_define_class_under(mSqlite3, klass, parent))

VALUE mDO;
VALUE cDO_Quoting;
VALUE cDO_Connection;
VALUE cDO_Command;
VALUE cDO_Result;
VALUE cDO_Reader;

VALUE rb_cDate;
VALUE rb_cDateTime;
VALUE rb_cTime;
VALUE rb_cRational;

VALUE mSqlite3;
VALUE cConnection;
VALUE cCommand;
VALUE cResult;
VALUE cReader;

VALUE cConnection_initialize(VALUE self, VALUE uri) {
	VALUE path;
	sqlite3 *db;
	
	path = rb_funcall(uri, ID_PATH, 0);
	sqlite3_open(RSTRING(path)->ptr, &db);
	
	rb_iv_set(self, "@uri", uri);
	rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));
	
	return Qtrue;
}

VALUE cConnection_real_close(VALUE self) {
	sqlite3 *db;
	Data_Get_Struct(rb_iv_get(self, "@connection"), sqlite3, db);
	sqlite3_close(db);
	return Qtrue;
}

VALUE cCommand_set_types(VALUE self, VALUE array) {
	rb_iv_set(self, "@field_types", array);
	return array;
}

VALUE cCommand_execute_non_query(int argc, VALUE *argv) {
	sqlite3 *db;
	char *error_message;
	int status;
	int affected_rows;
	int insert_id;
	VALUE self = argv[0];
	VALUE query = rb_iv_get(self, "@text");
	
	Data_Get_Struct(rb_iv_get(self, "@connection"), sqlite3, db);
	
	status = sqlite3_exec(db, RSTRING(query)->ptr, 0, 0, &error_message);
	
	if ( status != SQLITE_OK ) {
		rb_iv_set(self, "@last_error", rb_str_new2(error_message));
	}
	
	affected_rows = sqlite3_changes(db);
	insert_id = sqlite3_last_insert_rowid(db);
	
	return rb_funcall(cResult, ID_NEW, 3, self, affected_rows, insert_id);
}

VALUE cCommand_execute_reader(VALUE self, VALUE query) {
	return Qnil;
}

VALUE cReader_close(VALUE self) {
	return Qnil;
}

VALUE cReader_eof(VALUE self) {
	return Qnil;
}

VALUE cReader_next(VALUE self) {
	return Qnil;
}

VALUE cReader_values(VALUE self) {
	return Qnil;
}

VALUE cReader_fields(VALUE self) {
	return Qnil;
}

void Init_rbsqlite3() {
	
	// Get references classes needed for Date/Time parsing 
	rb_cDate = CONST_GET(rb_mKernel, "Date");
	rb_cDateTime = CONST_GET(rb_mKernel, "DateTime");
	rb_cTime = CONST_GET(rb_mKernel, "Time");
	rb_cRational = CONST_GET(rb_mKernel, "Rational");
	
	// Get references to the DataObjects module and its classes
	mDO = CONST_GET(rb_mKernel, "DataObjects");
	cDO_Quoting = CONST_GET(mDO, "Quoting");
	cDO_Connection = CONST_GET(mDO, "Connection");
	cDO_Command = CONST_GET(mDO, "Command");
	cDO_Result = CONST_GET(mDO, "Result");
	cDO_Reader = CONST_GET(mDO, "Reader");
	
	// Initialize the DataObjects::Sqlite3 module, and define its classes
	mSqlite3 = rb_define_module_under(mDO, "Sqlite3");
	
	cConnection = SQLITE3_CLASS("Connection", cDO_Connection);
	rb_define_method(cConnection, "initialize", cConnection_initialize, 1);
	rb_define_method(cConnection, "real_close", cConnection_real_close, 0);
	// rb_define_method(cConnection, "begin_transaction", cConnection_begin_transaction, 0);
	
	cCommand = SQLITE3_CLASS("Command", cDO_Command);
	rb_define_method(cCommand, "set_types", cCommand_set_types, 1);
	rb_define_method(cCommand, "execute_non_query", cCommand_execute_non_query, 0);
	rb_define_method(cCommand, "execute_reader", cCommand_execute_reader, 1);
	
	cResult = SQLITE3_CLASS("Result", cDO_Result);
	
	cReader = SQLITE3_CLASS("Reader", cDO_Reader);
	rb_define_method(cReader, "close", cReader_close, 0);
	rb_define_method(cReader, "eof?", cReader_eof, 0);
	rb_define_method(cReader, "next!", cReader_next, 0);
	rb_define_method(cReader, "values", cReader_values, 0);
	rb_define_method(cReader, "fields", cReader_fields, 0);
	
}