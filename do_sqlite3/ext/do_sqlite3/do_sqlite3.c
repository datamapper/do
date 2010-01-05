#include <ruby.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <locale.h>
#include <sqlite3.h>
#include "compat.h"
#include "error.h"

#ifdef HAVE_RUBY_ENCODING_H
#include <ruby/encoding.h>

#define DO_STR_NEW2(str, encoding) \
  ({ \
    VALUE _string = rb_str_new2((const char *)str); \
    if(encoding != -1) { \
      rb_enc_associate_index(_string, encoding); \
    } \
    _string; \
  })

#define DO_STR_NEW(str, len, encoding) \
  ({ \
    VALUE _string = rb_str_new((const char *)str, (long)len); \
    if(encoding != -1) { \
      rb_enc_associate_index(_string, encoding); \
    } \
    _string; \
  })

#else

#define DO_STR_NEW2(str, encoding) \
  rb_str_new2((const char *)str)

#define DO_STR_NEW(str, len, encoding) \
  rb_str_new((const char *)str, (long)len)
#endif


#define ID_CONST_GET rb_intern("const_get")
#define ID_PATH rb_intern("path")
#define ID_NEW rb_intern("new")
#define ID_ESCAPE rb_intern("escape_sql")
#define ID_QUERY rb_intern("query")

#define RUBY_CLASS(name) rb_const_get(rb_cObject, rb_intern(name))
#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))
#define SQLITE3_CLASS(klass, parent) (rb_define_class_under(mSqlite3, klass, parent))

#ifdef _WIN32
#define do_int64 signed __int64
#else
#define do_int64 signed long long int
#endif

#ifndef HAVE_SQLITE3_PREPARE_V2
#define sqlite3_prepare_v2 sqlite3_prepare
#endif

// To store rb_intern values
static ID ID_NEW_DATE;
static ID ID_RATIONAL;
static ID ID_LOGGER;
static ID ID_DEBUG;
static ID ID_LEVEL;

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

static VALUE mSqlite3;
static VALUE cConnection;
static VALUE cCommand;
static VALUE cResult;
static VALUE cReader;

static VALUE eArgumentError;
static VALUE eConnectionError;
static VALUE eDataError;

static VALUE OPEN_FLAG_READONLY;
static VALUE OPEN_FLAG_READWRITE;
static VALUE OPEN_FLAG_CREATE;
static VALUE OPEN_FLAG_NO_MUTEX;
static VALUE OPEN_FLAG_FULL_MUTEX;

// Find the greatest common denominator and reduce the provided numerator and denominator.
// This replaces calles to Rational.reduce! which does the same thing, but really slowly.
static void reduce( do_int64 *numerator, do_int64 *denominator ) {
  do_int64 a, b, c = 0;
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
  return (int) (floor(365.25 * (year + 4716)) + floor(30.6001 * (month + 1)) + day + b - 1524);
}

static void data_objects_debug(VALUE string, struct timeval* start) {
  struct timeval stop;
  char *message;

  const char *query = rb_str_ptr_readonly(string);
  size_t length     = rb_str_len(string);
  char total_time[32];
  do_int64 duration = 0;

  VALUE logger = rb_funcall(mSqlite3, ID_LOGGER, 0);
  int log_level = NUM2INT(rb_funcall(logger, ID_LEVEL, 0));

  if (0 == log_level) {
    gettimeofday(&stop, NULL);

    duration = (stop.tv_sec - start->tv_sec) * 1000000 + stop.tv_usec - start->tv_usec;

    snprintf(total_time, 32, "%.6f", duration / 1000000.0);
    message = (char *)calloc(length + strlen(total_time) + 4, sizeof(char));
    snprintf(message, length + strlen(total_time) + 4, "(%s) %s", total_time, query);
    rb_funcall(logger, ID_DEBUG, 1, rb_str_new(message, length + strlen(total_time) + 3));
  }
}

static void raise_error(VALUE self, sqlite3 *result, VALUE query) {
  VALUE exception;
  const char *message = sqlite3_errmsg(result);
  const char *exception_type = "SQLError";
  int sqlite3_errno = sqlite3_errcode(result);

  struct errcodes *errs;

  for (errs = errors; errs->error_name; errs++) {
    if(errs->error_no == sqlite3_errno) {
      exception_type = errs->exception;
      break;
    }
  }


  VALUE uri = rb_funcall(rb_iv_get(self, "@connection"), rb_intern("to_s"), 0);

  exception = rb_funcall(CONST_GET(mDO, exception_type), ID_NEW, 5,
                         rb_str_new2(message),
                         INT2NUM(sqlite3_errno),
                         rb_str_new2(""),
                         query,
                         uri);
  rb_exc_raise(exception);
}

static VALUE parse_date(char *date) {
  int year, month, day;
  int jd, ajd;
  VALUE rational;

  sscanf(date, "%4d-%2d-%2d", &year, &month, &day);

  jd = jd_from_date(year, month, day);

  // Math from Date.jd_to_ajd
  ajd = jd * 2 - 1;
  rational = rb_funcall(rb_mKernel, ID_RATIONAL, 2, INT2NUM(ajd), INT2NUM(2));
  return rb_funcall(rb_cDate, ID_NEW_DATE, 3, rational, INT2NUM(0), INT2NUM(2299161));
}

// Creates a Rational for use as a Timezone offset to be passed to DateTime.new!
static VALUE seconds_to_offset(do_int64 num) {
  do_int64 den = 86400;
  reduce(&num, &den);
  return rb_funcall(rb_mKernel, ID_RATIONAL, 2, rb_ll2inum(num), rb_ll2inum(den));
}

static VALUE timezone_to_offset(int hour_offset, int minute_offset) {
  do_int64 seconds = 0;

  seconds += hour_offset * 3600;
  seconds += minute_offset * 60;

  return seconds_to_offset(seconds);
}

static VALUE parse_date_time(char *date) {
  VALUE ajd, offset;

  int year, month, day, hour, min, sec, usec, hour_offset, minute_offset;
  int jd;
  do_int64 num, den;

  long int gmt_offset;
  int is_dst;

  time_t rawtime;
  struct tm * timeinfo;

  int tokens_read, max_tokens;

  if ( strcmp(date, "") == 0 ) {
    return Qnil;
  }

  if (0 != strchr(date, '.')) {
    // This is a datetime with sub-second precision
    tokens_read = sscanf(date, "%4d-%2d-%2d%*c%2d:%2d:%2d.%d%3d:%2d", &year, &month, &day, &hour, &min, &sec, &usec, &hour_offset, &minute_offset);
    max_tokens = 9;
  } else {
    // This is a datetime second precision
    tokens_read = sscanf(date, "%4d-%2d-%2d%*c%2d:%2d:%2d%3d:%2d", &year, &month, &day, &hour, &min, &sec, &hour_offset, &minute_offset);
    max_tokens = 8;
  }

  if (max_tokens == tokens_read) {
    // We read the Date, Time, and Timezone info
    minute_offset *= hour_offset < 0 ? -1 : 1;
  } else if ((max_tokens - 1) == tokens_read) {
    // We read the Date and Time, but no Minute Offset
    minute_offset = 0;
  } else if (tokens_read == 3 || tokens_read >= (max_tokens - 3)) {
    if (tokens_read == 3) {
      hour = 0;
      min = 0;
      hour_offset = 0;
      minute_offset = 0;
      sec = 0;
    }
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

    hour_offset = -((int)gmt_offset / 3600);
    minute_offset = -((int)gmt_offset % 3600 / 60);

  } else {
    // Something went terribly wrong
    rb_raise(eDataError, "Couldn't parse date: %s", date);
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

  ajd = rb_funcall(rb_mKernel, ID_RATIONAL, 2, rb_ull2inum(num), rb_ull2inum(den));
  offset = timezone_to_offset(hour_offset, minute_offset);

  return rb_funcall(rb_cDateTime, ID_NEW_DATE, 3, ajd, offset, INT2NUM(2299161));
}

static VALUE parse_time(char *date) {

  int year, month, day, hour, min, sec, usec, tokens, hour_offset, minute_offset;

  if (0 != strchr(date, '.')) {
    // This is a datetime with sub-second precision
    tokens = sscanf(date, "%4d-%2d-%2d%*c%2d:%2d:%2d.%d%3d:%2d", &year, &month, &day, &hour, &min, &sec, &usec, &hour_offset, &minute_offset);
  } else {
    // This is a datetime second precision
    tokens = sscanf(date, "%4d-%2d-%2d%*c%2d:%2d:%2d%3d:%2d", &year, &month, &day, &hour, &min, &sec, &hour_offset, &minute_offset);
    usec = 0;
    if(tokens == 3) {
      hour = 0;
      min = 0;
      sec = 0;
      hour_offset = 0;
      minute_offset = 0;
    }
  }

  return rb_funcall(rb_cTime, rb_intern("local"), 7, INT2NUM(year), INT2NUM(month), INT2NUM(day), INT2NUM(hour), INT2NUM(min), INT2NUM(sec), INT2NUM(usec));
}

static VALUE typecast(sqlite3_stmt *stmt, int i, VALUE type, int encoding) {
  VALUE ruby_value = Qnil;
  int original_type = sqlite3_column_type(stmt, i);
  int length        = sqlite3_column_bytes(stmt, i);
  if ( original_type == SQLITE_NULL ) {
    return ruby_value;
  }

  if(type == Qnil) {
    switch(original_type) {
      case SQLITE_INTEGER: {
        type = rb_cInteger;
        break;
      }
      case SQLITE_FLOAT: {
        type = rb_cFloat;
        break;
      }
      case SQLITE_BLOB: {
        type = rb_cByteArray;
        break;
      }
      default: {
        type = rb_cString;
        break;
      }
    }
  }

  if (type == rb_cInteger) {
    return LL2NUM(sqlite3_column_int64(stmt, i));
  } else if (type == rb_cString) {
    return DO_STR_NEW((char*)sqlite3_column_text(stmt, i), length, encoding);
  } else if (type == rb_cFloat) {
    return rb_float_new(sqlite3_column_double(stmt, i));
  } else if (type == rb_cBigDecimal) {
    return rb_funcall(rb_cBigDecimal, ID_NEW, 1, rb_str_new((char*)sqlite3_column_text(stmt, i), length));
  } else if (type == rb_cDate) {
    return parse_date((char*)sqlite3_column_text(stmt, i));
  } else if (type == rb_cDateTime) {
    return parse_date_time((char*)sqlite3_column_text(stmt, i));
  } else if (type == rb_cTime) {
    return parse_time((char*)sqlite3_column_text(stmt, i));
  } else if (type == rb_cTrueClass) {
    return strcmp((char*)sqlite3_column_text(stmt, i), "t") == 0 ? Qtrue : Qfalse;
  } else if (type == rb_cByteArray) {
    return rb_funcall(rb_cByteArray, ID_NEW, 1, rb_str_new((char*)sqlite3_column_blob(stmt, i), length));
  } else if (type == rb_cClass) {
    return rb_funcall(mDO, rb_intern("full_const_get"), 1, rb_str_new((char*)sqlite3_column_text(stmt, i), length));
  } else if (type == rb_cObject) {
    return rb_marshal_load(rb_str_new((char*)sqlite3_column_text(stmt, i), length));
  } else if (type == rb_cNilClass) {
    return Qnil;
  } else {
    return DO_STR_NEW((char*)sqlite3_column_text(stmt, i), length, encoding);
  }
}

#ifdef HAVE_SQLITE3_OPEN_V2

#define FLAG_PRESENT(query_values, flag) !NIL_P(rb_hash_aref(query_values, flag))

static int flags_from_uri(VALUE uri) {
  VALUE query_values = rb_funcall(uri, ID_QUERY, 0);

  int flags = 0;

  if (!NIL_P(query_values) && TYPE(query_values) == T_HASH) {
    /// scan for flags
#ifdef SQLITE_OPEN_READONLY
    if (FLAG_PRESENT(query_values, OPEN_FLAG_READONLY)) {
      flags |= SQLITE_OPEN_READONLY;
    } else {
      flags |= SQLITE_OPEN_READWRITE;
    }
#endif
#ifdef SQLITE_OPEN_NOMUTEX
    if (FLAG_PRESENT(query_values, OPEN_FLAG_NO_MUTEX)) {
      flags |= SQLITE_OPEN_NOMUTEX;
    }
#endif
#ifdef SQLITE_OPEN_FULLMUTEX
    if (FLAG_PRESENT(query_values, OPEN_FLAG_FULL_MUTEX)) {
      flags |= SQLITE_OPEN_FULLMUTEX;
    }
#endif
    flags |= SQLITE_OPEN_CREATE;
  } else {
    flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE;
  }

  return flags;
}

#endif

/****** Public API ******/

static VALUE cConnection_initialize(VALUE self, VALUE uri) {
  int ret;
  VALUE path;
  sqlite3 *db;

  path = rb_funcall(uri, ID_PATH, 0);

#ifdef HAVE_SQLITE3_OPEN_V2
  ret = sqlite3_open_v2(rb_str_ptr_readonly(path), &db, flags_from_uri(uri), 0);
#else
  ret = sqlite3_open(rb_str_ptr_readonly(path), &db);
#endif

  if ( ret != SQLITE_OK ) {
    raise_error(self, db, Qnil);
  }

  rb_iv_set(self, "@uri", uri);
  rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));
  // Sqlite3 only supports UTF-8, so this is the standard encoding
  rb_iv_set(self, "@encoding", rb_str_new2("UTF-8"));
#ifdef HAVE_RUBY_ENCODING_H
  rb_iv_set(self, "@encoding_id", INT2FIX(rb_enc_find_index("UTF-8")));
#endif

  return Qtrue;
}

static VALUE cConnection_dispose(VALUE self) {
  VALUE connection_container = rb_iv_get(self, "@connection");

  sqlite3 *db;

  if (Qnil == connection_container)
    return Qfalse;

  db = DATA_PTR(connection_container);

  if (NULL == db)
    return Qfalse;

  sqlite3_close(db);
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

static VALUE cConnection_quote_boolean(VALUE self, VALUE value) {
  return rb_str_new2(value == Qtrue ? "'t'" : "'f'");
}

static VALUE cConnection_quote_string(VALUE self, VALUE string) {
  const char *source = rb_str_ptr_readonly(string);
  char *escaped_with_quotes;
  VALUE result;

  // Wrap the escaped string in single-quotes, this is DO's convention
  escaped_with_quotes = sqlite3_mprintf("%Q", source);

  result = rb_str_new2(escaped_with_quotes);
#ifdef HAVE_RUBY_ENCODING_H
  rb_enc_associate_index(result, FIX2INT(rb_iv_get(self, "@encoding_id")));
#endif
  sqlite3_free(escaped_with_quotes);
  return result;
}

static VALUE cConnection_quote_byte_array(VALUE self, VALUE string) {
  VALUE source = StringValue(string);
  VALUE array = rb_funcall(source, rb_intern("unpack"), 1, rb_str_new2("H*"));
  rb_ary_unshift(array, rb_str_new2("X'"));
  rb_ary_push(array, rb_str_new2("'"));
  return rb_ary_join(array, Qnil);
}

static VALUE cConnection_character_set(VALUE self) {
  return rb_iv_get(self, "@encoding");
}

static VALUE build_query_from_args(VALUE klass, int count, VALUE *args) {
  VALUE query = rb_iv_get(klass, "@text");
  int i;
  VALUE array = rb_ary_new();
  for ( i = 0; i < count; i++) {
    rb_ary_push(array, (VALUE)args[i]);
  }
  query = rb_funcall(klass, ID_ESCAPE, 1, array);
  return query;
}

static VALUE cCommand_execute_non_query(int argc, VALUE *argv, VALUE self) {
  sqlite3 *db;
  char *error_message;
  int status;
  int affected_rows;
  do_int64 insert_id;
  VALUE connection, sqlite3_connection;
  VALUE query;
  struct timeval start;

  query = build_query_from_args(self, argc, argv);

  connection = rb_iv_get(self, "@connection");
  sqlite3_connection = rb_iv_get(connection, "@connection");
  if (Qnil == sqlite3_connection) {
    rb_raise(eConnectionError, "This connection has already been closed.");
  }

  Data_Get_Struct(sqlite3_connection, sqlite3, db);

  gettimeofday(&start, NULL);
  status = sqlite3_exec(db, rb_str_ptr_readonly(query), 0, 0, &error_message);

  if ( status != SQLITE_OK ) {
    raise_error(self, db, query);
  }
  data_objects_debug(query, &start);

  affected_rows = sqlite3_changes(db);
  insert_id = sqlite3_last_insert_rowid(db);

  return rb_funcall(cResult, ID_NEW, 3, self, INT2NUM(affected_rows), INT2NUM(insert_id));
}

static VALUE cCommand_execute_reader(int argc, VALUE *argv, VALUE self) {
  sqlite3 *db;
  sqlite3_stmt *sqlite3_reader;
  int status;
  int field_count;
  int i;
  VALUE reader;
  VALUE connection, sqlite3_connection;
  VALUE query;
  VALUE field_names, field_types;
  struct timeval start;

  connection = rb_iv_get(self, "@connection");
  sqlite3_connection = rb_iv_get(connection, "@connection");
  if (Qnil == sqlite3_connection) {
    rb_raise(eConnectionError, "This connection has already been closed.");
  }

  Data_Get_Struct(sqlite3_connection, sqlite3, db);

  query = build_query_from_args(self, argc, argv);

  gettimeofday(&start, NULL);
  status = sqlite3_prepare_v2(db, rb_str_ptr_readonly(query), -1, &sqlite3_reader, 0);
  data_objects_debug(query, &start);

  if ( status != SQLITE_OK ) {
    raise_error(self, db, query);
  }

  field_count = sqlite3_column_count(sqlite3_reader);
  reader = rb_funcall(cReader, ID_NEW, 0);

  rb_iv_set(reader, "@reader", Data_Wrap_Struct(rb_cObject, 0, 0, sqlite3_reader));
  rb_iv_set(reader, "@field_count", INT2NUM(field_count));
  rb_iv_set(reader, "@connection", connection);

  field_names = rb_ary_new();
  field_types = rb_iv_get(self, "@field_types");

  if ( field_types == Qnil || 0 == RARRAY_LEN(field_types) ) {
    field_types = rb_ary_new();
  } else if (RARRAY_LEN(field_types) != field_count) {
    // Whoops...  wrong number of types passed to set_types.  Close the reader and raise
    // and error
    rb_funcall(reader, rb_intern("close"), 0);
    rb_raise(eArgumentError, "Field-count mismatch. Expected %ld fields, but the query yielded %d", RARRAY_LEN(field_types), field_count);
  }

  for ( i = 0; i < field_count; i++ ) {
    rb_ary_push(field_names, rb_str_new2((char *)sqlite3_column_name(sqlite3_reader, i)));
  }

  rb_iv_set(reader, "@fields", field_names);
  rb_iv_set(reader, "@field_types", field_types);

  return reader;
}

static VALUE cReader_close(VALUE self) {
  VALUE reader_obj = rb_iv_get(self, "@reader");

  if ( reader_obj != Qnil ) {
    sqlite3_stmt *reader;
    Data_Get_Struct(reader_obj, sqlite3_stmt, reader);
    sqlite3_finalize(reader);
    rb_iv_set(self, "@reader", Qnil);
    return Qtrue;
  }
  else {
    return Qfalse;
  }
}

static VALUE cReader_next(VALUE self) {
  sqlite3_stmt *reader;
  int field_count;
  int result;
  int i;
  size_t ft_length;
  VALUE arr = rb_ary_new();
  VALUE field_types;
  VALUE field_type;
  VALUE value;

  Data_Get_Struct(rb_iv_get(self, "@reader"), sqlite3_stmt, reader);
  field_count = NUM2INT(rb_iv_get(self, "@field_count"));

  field_types = rb_iv_get(self, "@field_types");
  ft_length = RARRAY_LEN(field_types);

  result = sqlite3_step(reader);

  rb_iv_set(self, "@state", INT2NUM(result));

  if ( result != SQLITE_ROW ) {
    rb_iv_set(self, "@values", Qnil);
    return Qfalse;
  }

  int enc = -1;
#ifdef HAVE_RUBY_ENCODING_H
  VALUE encoding_id = rb_iv_get(rb_iv_get(self, "@connection"), "@encoding_id");
  if (encoding_id != Qnil) {
    enc = FIX2INT(encoding_id);
  }
#endif


  for ( i = 0; i < field_count; i++ ) {
    field_type = rb_ary_entry(field_types, i);
    value = typecast(reader, i, field_type, enc);
    rb_ary_push(arr, value);
  }

  rb_iv_set(self, "@values", arr);

  return Qtrue;
}

static VALUE cReader_values(VALUE self) {
  VALUE state = rb_iv_get(self, "@state");
  if ( state == Qnil || NUM2INT(state) != SQLITE_ROW ) {
    rb_raise(eDataError, "Reader is not initialized");
    return Qnil;
  }
  else {
    return rb_iv_get(self, "@values");
  }
}

static VALUE cReader_fields(VALUE self) {
  return rb_iv_get(self, "@fields");
}

static VALUE cReader_field_count(VALUE self) {
  return rb_iv_get(self, "@field_count");
}

void Init_do_sqlite3() {
  rb_require("bigdecimal");
  rb_require("date");

  // Get references classes needed for Date/Time parsing
  rb_cDate = RUBY_CLASS("Date");
  rb_cDateTime = RUBY_CLASS( "DateTime");
  rb_cBigDecimal = RUBY_CLASS("BigDecimal");

  rb_funcall(rb_mKernel, rb_intern("require"), 1, rb_str_new2("data_objects"));

#ifdef RUBY_LESS_THAN_186
  ID_NEW_DATE = rb_intern("new0");
#else
  ID_NEW_DATE = rb_intern("new!");
#endif
  ID_RATIONAL = rb_intern("Rational");
  ID_LOGGER = rb_intern("logger");
  ID_DEBUG = rb_intern("debug");
  ID_LEVEL = rb_intern("level");

  // Get references to the Extlib module
  mExtlib = CONST_GET(rb_mKernel, "Extlib");
  rb_cByteArray = CONST_GET(mExtlib, "ByteArray");

  // Get references to the DataObjects module and its classes
  mDO = CONST_GET(rb_mKernel, "DataObjects");
  cDO_Quoting = CONST_GET(mDO, "Quoting");
  cDO_Connection = CONST_GET(mDO, "Connection");
  cDO_Command = CONST_GET(mDO, "Command");
  cDO_Result = CONST_GET(mDO, "Result");
  cDO_Reader = CONST_GET(mDO, "Reader");

  // Initialize the DataObjects::Sqlite3 module, and define its classes
  mSqlite3 = rb_define_module_under(mDO, "Sqlite3");

  eArgumentError = CONST_GET(rb_mKernel, "ArgumentError");
  eConnectionError = CONST_GET(mDO, "ConnectionError");
  eDataError = CONST_GET(mDO, "DataError");

  cConnection = SQLITE3_CLASS("Connection", cDO_Connection);
  rb_define_method(cConnection, "initialize", cConnection_initialize, 1);
  rb_define_method(cConnection, "dispose", cConnection_dispose, 0);
  rb_define_method(cConnection, "quote_boolean", cConnection_quote_boolean, 1);
  rb_define_method(cConnection, "quote_string", cConnection_quote_string, 1);
  rb_define_method(cConnection, "quote_byte_array", cConnection_quote_byte_array, 1);
  rb_define_method(cConnection, "character_set", cConnection_character_set, 0);

  cCommand = SQLITE3_CLASS("Command", cDO_Command);
  rb_define_method(cCommand, "set_types", cCommand_set_types, -1);
  rb_define_method(cCommand, "execute_non_query", cCommand_execute_non_query, -1);
  rb_define_method(cCommand, "execute_reader", cCommand_execute_reader, -1);

  cResult = SQLITE3_CLASS("Result", cDO_Result);

  cReader = SQLITE3_CLASS("Reader", cDO_Reader);
  rb_define_method(cReader, "close", cReader_close, 0);
  rb_define_method(cReader, "next!", cReader_next, 0);
  rb_define_method(cReader, "values", cReader_values, 0);
  rb_define_method(cReader, "fields", cReader_fields, 0);
  rb_define_method(cReader, "field_count", cReader_field_count, 0);

  OPEN_FLAG_READONLY = rb_str_new2("read_only");
  rb_global_variable(&OPEN_FLAG_READONLY);
  OPEN_FLAG_READWRITE = rb_str_new2("read_write");
  rb_global_variable(&OPEN_FLAG_READWRITE);
  OPEN_FLAG_CREATE = rb_str_new2("create");
  rb_global_variable(&OPEN_FLAG_CREATE);
  OPEN_FLAG_NO_MUTEX = rb_str_new2("no_mutex");
  rb_global_variable(&OPEN_FLAG_NO_MUTEX);
  OPEN_FLAG_FULL_MUTEX = rb_str_new2("full_mutex");
  rb_global_variable(&OPEN_FLAG_FULL_MUTEX);

}
