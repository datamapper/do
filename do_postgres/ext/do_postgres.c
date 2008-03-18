#include <string.h>
#include <math.h>
#include <ruby.h>
#include <libpq-fe.h>

#define ID_CONST_GET rb_intern("const_get")
#define ID_PATH rb_intern("path")
#define ID_NEW rb_intern("new")
#define ID_ESCAPE rb_intern("escape_sql")

#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))
#define POSTGRES_CLASS(klass, parent) (rb_define_class_under(mPostgres, klass, parent))

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

VALUE mPostgres;
VALUE cConnection;
VALUE cCommand;
VALUE cResult;
VALUE cReader;

VALUE ePostgresError;

VALUE cConnection_initialize(VALUE self, VALUE uri) {
	
	PGconn *db;
	
	VALUE r_host = rb_funcall(uri, rb_intern("host"), 0);
	char *host = "localhost";
	if ( Qnil != r_host ) {
		host = StringValuePtr(r_host);
	}
	
	VALUE r_user = rb_funcall(uri, rb_intern("user"), 0);
	char * user = "postgres";
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

VALUE cConnection_real_close(VALUE self) {
	PGconn *db;
	Data_Get_Struct(rb_iv_get(self, "@connection"), PGconn, db);
	PQfinish(db);
	return Qtrue;
}

VALUE cCommand_set_types(VALUE self, VALUE array) {
	rb_iv_set(self, "@field_types", array);
	return array;
}

VALUE cCommand_execute_non_query(int argc, VALUE *argv[], VALUE self) {
	return Qtrue;
}

VALUE cCommand_execute_reader(int argc, VALUE *argv[], VALUE self) {
	return Qtrue;
}

VALUE cReader_close(VALUE self) {
	return Qtrue;
}

VALUE cReader_next(VALUE self) {
	return Qtrue;
}

VALUE cReader_values(VALUE self) {
	return Qtrue;
}

VALUE cReader_fields(VALUE self) {
	return Qtrue;
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
	// rb_define_method(cConnection, "begin_transaction", cConnection_begin_transaction, 0);
	
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