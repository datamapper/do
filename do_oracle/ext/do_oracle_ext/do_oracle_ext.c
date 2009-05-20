// #ifdef _WIN32
// #define cCommand_execute cCommand_execute_sync
// #define do_int64 signed __int64
// #else
// #define cCommand_execute cCommand_execute_async
// #define do_int64 signed long long int
// #endif

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

static ID ID_NAME;

static ID ID_NUMBER;
static ID ID_VARCHAR2;
static ID ID_CHAR;
static ID ID_DATE;
static ID ID_TIMESTAMP;
static ID ID_TIMESTAMP_TZ;
static ID ID_TIMESTAMP_LTZ;
static ID ID_CLOB;
static ID ID_BLOB;
static ID ID_LONG;
static ID ID_RAW;
static ID ID_LONG_RAW;
static ID ID_BFILE;
static ID ID_BINARY_FLOAT;
static ID ID_BINARY_DOUBLE;

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
static VALUE cOCI8_Cursor;

static VALUE mOracle;
static VALUE cConnection;
static VALUE cCommand;
static VALUE cResult;
static VALUE cReader;

static VALUE eArgumentError;
static VALUE eOracleError;

/* ===== Typecasting Functions ===== */

static VALUE infer_ruby_type(VALUE type, VALUE scale) {
  ID type_id = SYM2ID(type);
  
  if (type_id == ID_NUMBER)
    return scale != Qnil && NUM2INT(scale) == 0 ? rb_cInteger : rb_cBigDecimal;
  else if (type_id == ID_VARCHAR2 || type_id == ID_CHAR || type_id == ID_CLOB || type_id == ID_LONG)
    return rb_cString;
  else if (type_id == ID_DATE)
    return rb_cDateTime;
  else if (type_id == ID_TIMESTAMP || type_id == ID_TIMESTAMP_TZ || type_id == ID_TIMESTAMP_LTZ)
    return rb_cDateTime;
  else if (type_id == ID_BLOB || type_id == ID_RAW || type_id == ID_LONG_RAW || type_id == ID_BFILE)
    return rb_cByteArray;
  else if (type_id == ID_BINARY_FLOAT || type_id == ID_BINARY_DOUBLE)
    return rb_cFloat;
  else
    return rb_cString;
}

static VALUE typecast(VALUE value, const VALUE type) {

  return value;
  // if (type == rb_cInteger) {
  //   return rb_cstr2inum(value, 10);
  // } else if (type == rb_cString) {
  //   return TAINTED_STRING(value, length);
  // } else if (type == rb_cFloat) {
  //   return rb_float_new(rb_cstr_to_dbl(value, Qfalse));
  // } else if (type == rb_cBigDecimal) {
  //   return rb_funcall(rb_cBigDecimal, ID_NEW, 1, TAINTED_STRING(value, length));
  // } else if (type == rb_cDate) {
  //   return parse_date(value);
  // } else if (type == rb_cDateTime) {
  //   return parse_date_time(value);
  // } else if (type == rb_cTime) {
  //   return parse_time(value);
  // } else if (type == rb_cTrueClass) {
  //   return *value == 't' ? Qtrue : Qfalse;
  // } else if (type == rb_cByteArray) {
  //   size_t new_length = 0;
  //   char* unescaped = (char *)PQunescapeBytea((unsigned char*)value, &new_length);
  //   VALUE byte_array = rb_funcall(rb_cByteArray, ID_NEW, 1, TAINTED_STRING(unescaped, new_length));
  //   PQfreemem(unescaped);
  //   return byte_array;
  // } else if (type == rb_cClass) {
  //   return rb_funcall(rb_cObject, rb_intern("full_const_get"), 1, TAINTED_STRING(value, length));
  // } else if (type == rb_cObject) {
  //   return rb_marshal_load(rb_str_new2(value));
  // } else if (type == rb_cNilClass) {
  //   return Qnil;
  // } else {
  //   return TAINTED_STRING(value, length);
  // }

}

/* ====== Public API ======= */
static VALUE cConnection_dispose(VALUE self) {
  VALUE oci8_conn = rb_iv_get(self, "@connection");

  if (Qnil == oci8_conn)
    return Qfalse;

  rb_funcall(oci8_conn, rb_intern("logoff"), 0);

  rb_iv_set(self, "@connection", Qnil);

  return Qtrue;
}

static VALUE cCommand_set_types(int argc, VALUE *argv, VALUE self) {
  VALUE type_strings = rb_ary_new();
  VALUE array = rb_ary_new();

  int i, j;

  for ( i = 0; i < argc; i++) {
    rb_ary_push(array, argv[i]);
  }

  for (i = 0; i < RARRAY_LEN(array); i++) {
    VALUE entry = rb_ary_entry(array, i);
    if(TYPE(entry) == T_CLASS) {
      rb_ary_push(type_strings, entry);
    } else if (TYPE(entry) == T_ARRAY) {
      for (j = 0; j < RARRAY_LEN(entry); j++) {
        VALUE sub_entry = rb_ary_entry(entry, j);
        if(TYPE(sub_entry) == T_CLASS) {
          rb_ary_push(type_strings, sub_entry);
        } else {
          rb_raise(eArgumentError, "Invalid type given");
        }
      }
    } else {
      rb_raise(eArgumentError, "Invalid type given");
    }
  }

  rb_iv_set(self, "@field_types", type_strings);

  return array;
}


static VALUE cCommand_execute(VALUE oci8_conn, VALUE sql, int argc, VALUE *argv[]) {
  // Count number of ? in sql and replace them with :n as needed by OCI8
  // compare number of ? with argc
  
  VALUE replaced_sql = rb_funcall(cConnection, rb_intern("replace_argument_placeholders"), 2, sql, INT2NUM(argc));
  
  // Construct argument list for OCI8#exec method
  VALUE *args = (VALUE *)calloc(argc + 1, sizeof(VALUE));
  args[0] = replaced_sql;
  int i;
  for ( i = 0; i < argc; i++) {
    // replace nil value with '' as otherwise OCI8 cannot get bind variable type
    // '' will be inserted as NULL by Oracle
    args[i + 1] = NIL_P(argv[i]) ? RUBY_STRING("") : (VALUE)argv[i];
  }

  VALUE affected_rows = Qnil;
  affected_rows = rb_funcall2(oci8_conn, rb_intern("exec"), argc + 1, args);

  free(args);
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

  // Enable non-blocking mode
  rb_funcall(oci8_conn, rb_intern("non_blocking="), 1, Qtrue);
  
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

static VALUE cCommand_execute_reader(int argc, VALUE *argv[], VALUE self) {
  VALUE reader, query;
  VALUE field_names, field_types;
  VALUE column_metadata, column;
  
  int i;
  int field_count;
  int infer_types = 0;

  VALUE connection = rb_iv_get(self, "@connection");
  VALUE oci8_conn = rb_iv_get(connection, "@connection");
  if (Qnil == oci8_conn) {
    rb_raise(eOracleError, "This connection has already been closed.");
  }

  query = rb_iv_get(self, "@text");

  VALUE cursor = cCommand_execute(oci8_conn, query, argc, argv);

  if (rb_obj_class(cursor) != cOCI8_Cursor) {
    rb_raise(eOracleError, "\"%s\" is invalid SELECT query", StringValuePtr(query));
  }

  column_metadata = rb_funcall(cursor, rb_intern("column_metadata"), 0);
  field_count = RARRAY_LEN(column_metadata);

  reader = rb_funcall(cReader, ID_NEW, 0);
  rb_iv_set(reader, "@reader", cursor);
  rb_iv_set(reader, "@field_count", INT2NUM(field_count));
  // TODO: what should be stored in @row_count? After execute we don't know total row_count
  // rb_iv_set(reader, "@row_count", INT2NUM(rb_funcall(cursor, rb_intern("row_count"), 0));
  // rb_iv_set(reader, "@row_count", INT2NUM(0));

  field_names = rb_ary_new();
  field_types = rb_iv_get(self, "@field_types");

  if ( field_types == Qnil || 0 == RARRAY_LEN(field_types) ) {
    field_types = rb_ary_new();
    infer_types = 1;
  } else if (RARRAY_LEN(field_types) != field_count) {
    // Whoops...  wrong number of types passed to set_types.  Close the reader and raise
    // and error
    rb_funcall(reader, rb_intern("close"), 0);
    rb_raise(eArgumentError, "Field-count mismatch. Expected %ld fields, but the query yielded %d", RARRAY_LEN(field_types), field_count);
  }

  for ( i = 0; i < field_count; i++ ) {
    column = rb_ary_entry(column_metadata, i);
    // TODO: should field names be in downcase (as returned from Oracle) or in upcase?
    rb_ary_push(field_names, rb_funcall(column, ID_NAME, 0));
    if ( infer_types == 1 ) {
      rb_ary_push(field_types,
        infer_ruby_type(rb_iv_get(column, "@data_type"), rb_iv_get(column, "@scale"))
      );
    }
  }

  rb_iv_set(reader, "@position", INT2NUM(0));
  rb_iv_set(reader, "@fields", field_names);
  rb_iv_set(reader, "@field_types", field_types);

  rb_iv_set(reader, "@last_row", Qfalse);

  return reader;
}

static VALUE cReader_close(VALUE self) {
  VALUE cursor = rb_iv_get(self, "@reader");

  if (Qnil == cursor)
    return Qfalse;

  rb_funcall(cursor, rb_intern("close"), 0);

  rb_iv_set(self, "@reader", Qnil);
  return Qtrue;
}

static VALUE cReader_next(VALUE self) {
  VALUE cursor = rb_iv_get(self, "@reader");

  int field_count;
  int i;

  if (Qnil == cursor || Qtrue == rb_iv_get(self, "@last_row"))
    return Qfalse;

  VALUE row = rb_ary_new();
  VALUE field_types, field_type;
  VALUE value;

  VALUE fetch_result = rb_funcall(cursor, rb_intern("fetch"), 0);
  
  if (Qnil == fetch_result) {
    rb_iv_set(self, "@values", Qnil);
    rb_iv_set(self, "@last_row", Qtrue);
    return Qfalse;
  }

  field_count = NUM2INT(rb_iv_get(self, "@field_count"));
  field_types = rb_iv_get(self, "@field_types");

  for ( i = 0; i < field_count; i++ ) {
    field_type = rb_ary_entry(field_types, i);
    value = rb_ary_entry(fetch_result, i);
    // Always return nil if the value returned from Oracle is null
    if (Qnil != value) {
      value = typecast(value, field_type);
    }

    rb_ary_push(row, value);
  }

  rb_iv_set(self, "@values", row);
  return Qtrue;
}

static VALUE cReader_values(VALUE self) {

  VALUE values = rb_iv_get(self, "@values");
  if(values == Qnil) {
    rb_raise(eOracleError, "Reader not initialized");
    return Qnil;
  } else {
    return values;
  }
}

static VALUE cReader_fields(VALUE self) {
  return rb_iv_get(self, "@fields");
}

static VALUE cReader_field_count(VALUE self) {
  return rb_iv_get(self, "@field_count");
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

  ID_NAME = rb_intern("name");

  ID_NUMBER = rb_intern("number");
  ID_VARCHAR2 = rb_intern("varchar2");
  ID_CHAR = rb_intern("char");
  ID_DATE = rb_intern("date");
  ID_TIMESTAMP = rb_intern("timestamp");
  ID_TIMESTAMP_TZ = rb_intern("timestamp_tz");
  ID_TIMESTAMP_LTZ = rb_intern("timestamp_ltz");
  ID_CLOB = rb_intern("clob");
  ID_BLOB = rb_intern("blob");
  ID_LONG = rb_intern("long");
  ID_RAW = rb_intern("raw");
  ID_LONG_RAW = rb_intern("long_raw");
  ID_BFILE = rb_intern("bfile");
  ID_BINARY_FLOAT = rb_intern("binary_float");
  ID_BINARY_DOUBLE = rb_intern("binary_double");


  // Get references to the Extlib module
  mExtlib = CONST_GET(rb_mKernel, "Extlib");
  rb_cByteArray = CONST_GET(mExtlib, "ByteArray");

  // Get reference to OCI8 class
  cOCI8 = CONST_GET(rb_mKernel, "OCI8");
  cOCI8_Cursor = CONST_GET(cOCI8, "Cursor");

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
  rb_define_method(cCommand, "set_types", cCommand_set_types, -1);
  rb_define_method(cCommand, "execute_non_query", cCommand_execute_non_query, -1);
  rb_define_method(cCommand, "execute_reader", cCommand_execute_reader, -1);

  cResult = ORACLE_CLASS("Result", cDO_Result);

  cReader = ORACLE_CLASS("Reader", cDO_Reader);
  rb_define_method(cReader, "close", cReader_close, 0);
  rb_define_method(cReader, "next!", cReader_next, 0);
  rb_define_method(cReader, "values", cReader_values, 0);
  rb_define_method(cReader, "fields", cReader_fields, 0);
  rb_define_method(cReader, "field_count", cReader_field_count, 0);

}
