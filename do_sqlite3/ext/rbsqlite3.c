#include <string.h>
#include <math.h>
#include <ruby.h>
#include <sqlite3.h>

#define ID_CONST_GET rb_intern("const_get")

#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))
#define SQLITE3_CLASS(klass, parent) (rb_define_class_under(mSqlite3, klass, parent))

VALUE mDO;
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


void Init_rbsqlite3() {
	
	// Get references classes needed for Date/Time parsing 
	rb_cDate = CONST_GET(rb_mKernel, "Date");
	rb_cDateTime = CONST_GET(rb_mKernel, "DateTime");
	rb_cTime = CONST_GET(rb_mKernel, "Time");
	rb_cRational = CONST_GET(rb_mKernel, "Rational");
	
	// Get references to the DataObjects module and its classes
	mDO = CONST_GET(rb_mKernel, "DataObjects");
	cDO_Connection = CONST_GET(mDO, "Connection");
	cDO_Command = CONST_GET(mDO, "Command");
	cDO_Result = CONST_GET(mDO, "Result");
	cDO_Reader = CONST_GET(mDO, "Reader");
	
	// Initialize the DataObjects::Sqlite3 module, and define its classes
	mSqlite3 = rb_define_module_under(mDO, "Sqlite3");
	cConnection = SQLITE3_CLASS("Connection", cDO_Connection);
	cCommand = SQLITE3_CLASS("Command", cDO_Command);
	cResult = SQLITE3_CLASS("Result", cDO_Result);
	cReader = SQLITE3_CLASS("Reader", cDO_Reader);
	
}