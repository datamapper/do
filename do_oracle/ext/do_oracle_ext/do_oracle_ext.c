// #include <oci.h>

#ifdef _WIN32
#define cCommand_execute cCommand_execute_sync
#define do_int64 signed __int64
#else
#define cCommand_execute cCommand_execute_async
#define do_int64 signed long long int
#endif

#include <ruby.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <time.h>

#define ID_CONST_GET rb_intern("const_get")
#define ID_PATH rb_intern("path")
#define ID_NEW rb_intern("new")
#define ID_ESCAPE rb_intern("escape_sql")

#define RUBY_STRING(char_ptr) rb_str_new2(char_ptr)
#define TAINTED_STRING(name, length) rb_tainted_str_new(name, length)
#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))
#define ORACLE_CLASS(klass, parent) (rb_define_class_under(mOracle, klass, parent))
#define DEBUG(value) data_objects_debug(value)
#define RUBY_CLASS(name) rb_const_get(rb_cObject, rb_intern(name))

#ifndef RSTRING_PTR
#define RSTRING_PTR(s) (RSTRING(s)->ptr)
#endif

#ifndef RSTRING_LEN
#define RSTRING_LEN(s) (RSTRING(s)->len)
#endif

#ifndef RARRAY_LEN
#define RARRAY_LEN(a) RARRAY(a)->len
#endif


// To store rb_intern values
static ID ID_NEW_DATE;
static ID ID_LOGGER;
static ID ID_DEBUG;
static ID ID_LEVEL;
static ID ID_TO_S;
static ID ID_RATIONAL;

static VALUE mExtlib;
static VALUE mDO;
static VALUE cDO_Quoting;
static VALUE cDO_Connection;
static VALUE cDO_Command;
static VALUE cDO_Result;
static VALUE cDO_Reader;

static VALUE rb_cDate;
static VALUE rb_cDateTime;
static VALUE rb_cBigDecimal;
static VALUE rb_cByteArray;

static VALUE cOCI8;

static VALUE mOracle;
static VALUE cConnection;
static VALUE cCommand;
static VALUE cResult;
static VALUE cReader;

static VALUE eArgumentError;
static VALUE eOracleError;

/* ====== Public API ======= */
static VALUE cConnection_dispose(VALUE self) {
  VALUE oci8_conn = rb_iv_get(self, "@connection");

  if (Qnil == oci8_conn)
    return Qfalse;

  rb_funcall(oci8_conn, rb_intern("logoff"), 0);

  rb_iv_set(self, "@connection", Qnil);

  return Qtrue;
}


static VALUE cCommand_execute(VALUE oci8_conn, VALUE sql, int argc, VALUE *argv[]) {
  // Construct argument list for OCI8#exec method
  VALUE *args = (VALUE *)calloc(argc + 1, sizeof(VALUE));
  args[0] = sql;
  int i;
  for ( i = 0; i < argc; i++) {
    args[i + 1] = *argv[i];
  }

  VALUE affected_rows = rb_funcall2(oci8_conn, rb_intern("exec"), argc + 1, args);

  return affected_rows;
}


static VALUE cConnection_initialize(VALUE self, VALUE uri) {
  VALUE r_host, r_port, r_path, r_user, r_password;
  // VALUE r_query, r_options;
  char *host = "localhost", *port = "1521", *path = NULL;
  // char *user = NULL, *password = NULL;
  char *connect_string;
  int connect_string_length;
  VALUE oci8_conn;

  r_user = rb_funcall(uri, rb_intern("user"), 0);
  r_password = rb_funcall(uri, rb_intern("password"), 0);

  r_host = rb_funcall(uri, rb_intern("host"), 0);
  if ( Qnil != r_host && RSTRING_LEN(r_host) > 0) {
    host = StringValuePtr(r_host);
  }
  
  r_port = rb_funcall(uri, rb_intern("port"), 0);
  if ( Qnil != r_port ) {
    r_port = rb_funcall(r_port, rb_intern("to_s"), 0);
    port = StringValuePtr(r_port);
  }
  
  r_path = rb_funcall(uri, rb_intern("path"), 0);
  path = StringValuePtr(r_path);

  // If just host name is specified then use it as TNS names alias
  if ((r_host != Qnil && RSTRING_LEN(r_host) > 0) &&
      (r_port == Qnil) &&
      (r_path == Qnil || RSTRING_LEN(r_path) == 0)) {
    connect_string = host;
  // If database name is specified in path (in format "/database")
  } else if (strlen(path) > 1) {
    connect_string_length = strlen(host) + strlen(port) + strlen(path) + 4;
    connect_string = (char *)calloc(connect_string_length, sizeof(char));
    snprintf(connect_string, connect_string_length, "//%s:%s%s", host, port, path);
  } else {
    rb_raise(eOracleError, "Database must be specified");
  }

  oci8_conn = rb_funcall(cOCI8, ID_NEW, 3, r_user, r_password, RUBY_STRING(connect_string));
  
  cCommand_execute(oci8_conn,
      RUBY_STRING("alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS'"),
      0, NULL);
  cCommand_execute(oci8_conn,
      RUBY_STRING("alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS.FF'"),
      0, NULL);
  cCommand_execute(oci8_conn,
      RUBY_STRING("alter session set nls_timestamp_tz_format = 'YYYY-MM-DD HH24:MI:SS.FF'"),
      0, NULL);

  rb_iv_set(self, "@uri", uri);
  rb_iv_set(self, "@connection", oci8_conn);

  return Qtrue;
}

static VALUE cCommand_execute_non_query(int argc, VALUE *argv[], VALUE self) {
  VALUE connection = rb_iv_get(self, "@connection");
  VALUE oci8_conn = rb_iv_get(connection, "@connection");
  if (Qnil == oci8_conn) {
    rb_raise(eOracleError, "This connection has already been closed.");
  }

  VALUE query = rb_iv_get(self, "@text");

  VALUE affected_rows = Qnil;
  VALUE insert_id = Qnil;

  affected_rows = cCommand_execute(oci8_conn, query, argc, argv);

  return rb_funcall(cResult, ID_NEW, 3, self, affected_rows, insert_id);
}



void Init_do_oracle_ext() {
  // rb_require("oci8");
  rb_require("date");
  rb_require("bigdecimal");

  // Get references classes needed for Date/Time parsing
  rb_cDate = CONST_GET(rb_mKernel, "Date");
  rb_cDateTime = CONST_GET(rb_mKernel, "DateTime");
  rb_cBigDecimal = CONST_GET(rb_mKernel, "BigDecimal");

  rb_funcall(rb_mKernel, rb_intern("require"), 1, rb_str_new2("data_objects"));

#ifdef RUBY_LESS_THAN_186
  ID_NEW_DATE = rb_intern("new0");
#else
  ID_NEW_DATE = rb_intern("new!");
#endif
  ID_LOGGER = rb_intern("logger");
  ID_DEBUG = rb_intern("debug");
  ID_LEVEL = rb_intern("level");
  ID_TO_S = rb_intern("to_s");
  ID_RATIONAL = rb_intern("Rational");

  // Get references to the Extlib module
  mExtlib = CONST_GET(rb_mKernel, "Extlib");
  rb_cByteArray = CONST_GET(mExtlib, "ByteArray");

  // Get reference to OCI8 class
  cOCI8 = CONST_GET(rb_mKernel, "OCI8");

  // Get references to the DataObjects module and its classes
  mDO = CONST_GET(rb_mKernel, "DataObjects");
  cDO_Quoting = CONST_GET(mDO, "Quoting");
  cDO_Connection = CONST_GET(mDO, "Connection");
  cDO_Command = CONST_GET(mDO, "Command");
  cDO_Result = CONST_GET(mDO, "Result");
  cDO_Reader = CONST_GET(mDO, "Reader");

  eArgumentError = CONST_GET(rb_mKernel, "ArgumentError");
  mOracle = rb_define_module_under(mDO, "Oracle");
  eOracleError = rb_define_class("OracleError", rb_eStandardError);

  cConnection = ORACLE_CLASS("Connection", cDO_Connection);
  rb_define_method(cConnection, "initialize", cConnection_initialize, 1);
  rb_define_method(cConnection, "dispose", cConnection_dispose, 0);
  // rb_define_method(cConnection, "character_set", cConnection_character_set , 0);
  // rb_define_method(cConnection, "quote_string", cConnection_quote_string, 1);
  // rb_define_method(cConnection, "quote_byte_array", cConnection_quote_byte_array, 1);

  cCommand = ORACLE_CLASS("Command", cDO_Command);
  // rb_define_method(cCommand, "set_types", cCommand_set_types, -1);
  rb_define_method(cCommand, "execute_non_query", cCommand_execute_non_query, -1);
  // rb_define_method(cCommand, "execute_reader", cCommand_execute_reader, -1);

  cResult = ORACLE_CLASS("Result", cDO_Result);

  cReader = ORACLE_CLASS("Reader", cDO_Reader);
  // rb_define_method(cReader, "close", cReader_close, 0);
  // rb_define_method(cReader, "next!", cReader_next, 0);
  // rb_define_method(cReader, "values", cReader_values, 0);
  // rb_define_method(cReader, "fields", cReader_fields, 0);
  // rb_define_method(cReader, "field_count", cReader_field_count, 0);

  // // Initialize global OCI Environment
  // oci_make_envhp();
  // oci_make_errhp();
}
