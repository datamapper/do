#include <libpq-fe.h>
#include <postgres.h>
#include <mb/pg_wchar.h>
#include <catalog/pg_type.h>
#include <utils/errcodes.h>

/* Undefine constants Postgres also defines */
#undef PACKAGE_BUGREPORT
#undef PACKAGE_NAME
#undef PACKAGE_STRING
#undef PACKAGE_TARNAME
#undef PACKAGE_VERSION

#ifdef _WIN32
/* On Windows this stuff is also defined by Postgres, but we don't
   want to use Postgres' version actually */
#undef fsync
#undef ftruncate
#undef fseeko
#undef ftello
#undef stat
#undef vsnprintf
#undef snprintf
#undef sprintf
#undef printf
#define query_execute query_execute_sync
#define do_int64 signed __int64
#else
#define query_execute query_execute_async
#define do_int64 signed long long int
#endif

#include <ruby.h>
#include <st.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <time.h>
#include "error.h"
#include "compat.h"

#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))
#define DRIVER_CLASS(klass, parent) (rb_define_class_under(mPostgres, klass, parent))

#ifdef HAVE_RUBY_ENCODING_H
#include <ruby/encoding.h>

#define DO_STR_NEW2(str, encoding, internal_encoding) \
  ({ \
    VALUE _string = rb_str_new2((const char *)str); \
    if(encoding != -1) { \
      rb_enc_associate_index(_string, encoding); \
    } \
    if(internal_encoding) { \
      _string = rb_str_export_to_enc(_string, internal_encoding); \
    } \
    _string; \
  })

#define DO_STR_NEW(str, len, encoding, internal_encoding) \
  ({ \
    VALUE _string = rb_str_new((const char *)str, (long)len); \
    if(encoding != -1) { \
      rb_enc_associate_index(_string, encoding); \
    } \
    if(internal_encoding) { \
      _string = rb_str_export_to_enc(_string, internal_encoding); \
    } \
    _string; \
  })

#else

#define DO_STR_NEW2(str, encoding, internal_encoding) \
  rb_str_new2((const char *)str)

#define DO_STR_NEW(str, len, encoding, internal_encoding) \
  rb_str_new((const char *)str, (long)len)
#endif

typedef struct {
  VALUE* values;
  VALUE columns;
  VALUE types;
  VALUE encoding_id;
  VALUE column_hash;
  int column_count;
  int* lengths;
  char* raw;
} pg_row;

typedef struct {
  VALUE columns;
  VALUE types;
  VALUE query;
  VALUE connection;
  VALUE column_hash;
  int column_count;
  int row_count;
  PGresult* result;
} pg_reader;

// To store rb_intern values
static ID ID_NEW_DATE;
static ID ID_RATIONAL;
static ID ID_CONST_GET;
static ID ID_NEW;
static ID ID_ESCAPE;
static ID ID_LOG;

static VALUE mDO;
static VALUE mEncoding;
static VALUE cDO_Quoting;
static VALUE cDO_Connection;
static VALUE cDO_Result;
static VALUE cDO_Reader;
static VALUE cDO_Row;
static VALUE cDO_Logger;
static VALUE cDO_Logger_Message;

static VALUE rb_cDate;
static VALUE rb_cDateTime;
static VALUE rb_cBigDecimal;
static VALUE rb_cByteArray;

static VALUE mPostgres;
static VALUE cConnection;
static VALUE cResult;
static VALUE cReader;
static VALUE cRow;

static VALUE eConnectionError;
static VALUE eDataError;

static void data_objects_debug(VALUE connection, VALUE string, struct timeval* start) {
  struct timeval stop;
  VALUE message;

  gettimeofday(&stop, NULL);
  do_int64 duration = (stop.tv_sec - start->tv_sec) * 1000000 + stop.tv_usec - start->tv_usec;

  message = rb_funcall(cDO_Logger_Message, ID_NEW, 3, string, rb_time_new(start->tv_sec, start->tv_usec), INT2NUM(duration));

  rb_funcall(connection, ID_LOG, 1, message);
}

static const char * get_uri_option(VALUE query_hash, const char * key) {
  VALUE query_value;
  const char * value = NULL;

  if(!rb_obj_is_kind_of(query_hash, rb_cHash)) { return NULL; }

  query_value = rb_hash_aref(query_hash, rb_str_new2(key));

  if (Qnil != query_value) {
    value = StringValuePtr(query_value);
  }

  return value;
}

/* ====== Time/Date Parsing Helper Functions ====== */
static void reduce( do_int64 *numerator, do_int64 *denominator ) {
  do_int64 a, b, c;
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

static VALUE parse_date(const char *date) {
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

static VALUE parse_date_time(const char *date) {
  VALUE ajd, offset;

  int year, month, day, hour, min, sec, usec, hour_offset, minute_offset;
  int jd;
  do_int64 num, den;

  long int gmt_offset;
  int is_dst;

  time_t rawtime;
  struct tm * timeinfo;

  int tokens_read, max_tokens;

  if (0 != strchr(date, '.')) {
    // This is a datetime with sub-second precision
    tokens_read = sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d.%d%3d:%2d", &year, &month, &day, &hour, &min, &sec, &usec, &hour_offset, &minute_offset);
    max_tokens = 9;
  } else {
    // This is a datetime second precision
    tokens_read = sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d%3d:%2d", &year, &month, &day, &hour, &min, &sec, &hour_offset, &minute_offset);
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

static VALUE parse_time(const char *date) {

  int year, month, day, hour, min, sec, usec, tokens;
  char subsec[7];

  if (0 != strchr(date, '.')) {
    // right padding usec with 0. e.g. '012' will become 12000 microsecond, since Time#local use microsecond
    sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d.%s", &year, &month, &day, &hour, &min, &sec, subsec);
    usec   = atoi(subsec);
    usec  *= (int) pow(10, (6 - strlen(subsec)));
  } else {
    tokens = sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d", &year, &month, &day, &hour, &min, &sec);
    if (tokens == 3) {
      hour = 0;
      min  = 0;
      sec  = 0;
    }
    usec = 0;
  }

  return rb_funcall(rb_cTime, rb_intern("local"), 7, INT2NUM(year), INT2NUM(month), INT2NUM(day), INT2NUM(hour), INT2NUM(min), INT2NUM(sec), INT2NUM(usec));
}

/* ===== Typecasting Functions ===== */

static VALUE infer_ruby_type(Oid type) {
  switch(type) {
    case BITOID:
    case VARBITOID:
    case INT2OID:
    case INT4OID:
    case INT8OID:
      return rb_cInteger;
    case FLOAT4OID:
    case FLOAT8OID:
      return rb_cFloat;
    case NUMERICOID:
    case CASHOID:
      return rb_cBigDecimal;
    case BOOLOID:
      return rb_cTrueClass;
    case TIMESTAMPTZOID:
    case TIMESTAMPOID:
      return rb_cDateTime;
    case DATEOID:
      return rb_cDate;
    case BYTEAOID:
      return rb_cByteArray;
    default:
      return rb_cString;
  }
}

static VALUE typecast(const char *value, long length, const VALUE type, int encoding) {

#ifdef HAVE_RUBY_ENCODING_H
  rb_encoding * internal_encoding = rb_default_internal_encoding();
#else
  void * internal_encoding = NULL;
#endif

  if (type == rb_cInteger) {
    return rb_cstr2inum(value, 10);
  } else if (type == rb_cString) {
    return DO_STR_NEW(value, length, encoding, internal_encoding);
  } else if (type == rb_cFloat) {
    return rb_float_new(rb_cstr_to_dbl(value, Qfalse));
  } else if (type == rb_cBigDecimal) {
    return rb_funcall(rb_cBigDecimal, ID_NEW, 1, rb_str_new(value, length));
  } else if (type == rb_cDate) {
    return parse_date(value);
  } else if (type == rb_cDateTime) {
    return parse_date_time(value);
  } else if (type == rb_cTime) {
    return parse_time(value);
  } else if (type == rb_cTrueClass) {
    return *value == 't' ? Qtrue : Qfalse;
  } else if (type == rb_cByteArray) {
    size_t new_length = 0;
    char* unescaped = (char *)PQunescapeBytea((unsigned char*)value, &new_length);
    VALUE byte_array = rb_funcall(rb_cByteArray, ID_NEW, 1, rb_str_new(unescaped, new_length));
    PQfreemem(unescaped);
    return byte_array;
  } else if (type == rb_cClass) {
    return rb_funcall(mDO, rb_intern("full_const_get"), 1, rb_str_new(value, length));
  } else if (type == rb_cNilClass) {
    return Qnil;
  } else {
    return DO_STR_NEW(value, length, encoding, internal_encoding);
  }

}

static void raise_error(VALUE self, int status, PGresult *result, VALUE query) {
  VALUE exception;
  char *message;
  char *sqlstate;
  int postgres_errno;

  message  = PQresultErrorMessage(result);
  sqlstate = PQresultErrorField(result, PG_DIAG_SQLSTATE);
  if(status == PGRES_EMPTY_QUERY) {
    message = (char*)"Empty query";
    postgres_errno = ERRCODE_SYNTAX_ERROR;
    sqlstate = (char*) "";
  } else if(sqlstate) {
    postgres_errno = MAKE_SQLSTATE(sqlstate[0], sqlstate[1], sqlstate[2], sqlstate[3], sqlstate[4]);
  } else {
    sqlstate = (char*) "";
    postgres_errno = -1;
  }

  const char *exception_type = "SQLError";

  struct errcodes *errs;

  for (errs = errors; errs->error_name; errs++) {
    if(errs->error_no == postgres_errno) {
      exception_type = errs->exception;
      break;
    }
  }

  VALUE uri = rb_funcall(rb_iv_get(self, "@connection"), rb_intern("to_s"), 0);

  exception = rb_funcall(CONST_GET(mDO, exception_type), ID_NEW, 5,
                         rb_str_new2(message),
                         INT2NUM(postgres_errno),
                         rb_str_new2(sqlstate),
                         query,
                         uri);
  rb_exc_raise(exception);
}


/* ====== Public API ======= */
static VALUE cConnection_dispose(VALUE self) {
  VALUE connection_container = rb_iv_get(self, "@connection");

  PGconn *db;

  if (Qnil == connection_container)
    return Qfalse;

  db = DATA_PTR(connection_container);

  if (NULL == db)
    return Qfalse;

  PQfinish(db);
  rb_iv_set(self, "@connection", Qnil);

  return Qtrue;
}

static VALUE cReader_set_types(int argc, VALUE *argv, VALUE self) {
  VALUE type_strings = rb_ary_new();
  VALUE array = rb_ary_new();

  int i, j;

  pg_reader * reader;
  Data_Get_Struct(self, pg_reader, reader);

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
          rb_raise(rb_eArgError, "Invalid type given");
        }
      }
    } else {
      rb_raise(rb_eArgError, "Invalid type given");
    }
  }

  reader->types = type_strings;

  return array;
}

static VALUE build_query_from_args(VALUE klass, int count, VALUE args[]) {

  if(count < 1) {
    rb_raise(rb_eArgError, "No arguments given");
  }

  VALUE query = args[0];

  int i;
  VALUE array = rb_ary_new();
  for ( i = 1; i < count; i++) {
    rb_ary_push(array, args[i]);
  }
  query = rb_funcall(klass, ID_ESCAPE, 2, query, array);

  return query;
}

static VALUE cConnection_quote_string(VALUE self, VALUE string) {
  PGconn *db = DATA_PTR(rb_iv_get(self, "@connection"));

  const char *source = rb_str_ptr_readonly(string);
  size_t source_len  = rb_str_len(string);

  char *escaped;
  size_t quoted_length = 0;
  VALUE result;

  // Allocate space for the escaped version of 'string'
  // http://www.postgresql.org/docs/8.3/static/libpq-exec.html#LIBPQ-EXEC-ESCAPE-STRING
  escaped = (char *)calloc(source_len * 2 + 3, sizeof(char));

  // Escape 'source' using the current charset in use on the conection 'db'
  quoted_length = PQescapeStringConn(db, escaped + 1, source, source_len, NULL);

  // Wrap the escaped string in single-quotes, this is DO's convention
  escaped[quoted_length + 1] = escaped[0] = '\'';

  result = DO_STR_NEW(escaped, quoted_length + 2, FIX2INT(rb_iv_get(self, "@encoding_id")), NULL);

  free(escaped);
  return result;
}

static VALUE cConnection_quote_byte_array(VALUE self, VALUE string) {
  PGconn *db = DATA_PTR(rb_iv_get(self, "@connection"));

  const unsigned char *source = (unsigned char*) rb_str_ptr_readonly(string);
  size_t source_len     = rb_str_len(string);

  unsigned char *escaped;
  unsigned char *escaped_quotes;
  size_t quoted_length = 0;
  VALUE result;

  // Allocate space for the escaped version of 'string'
  // http://www.postgresql.org/docs/8.3/static/libpq-exec.html#LIBPQ-EXEC-ESCAPE-STRING
  escaped = PQescapeByteaConn(db, source, source_len, &quoted_length);
  escaped_quotes = (unsigned char *)calloc(quoted_length + 1, sizeof(unsigned char));
  memcpy(escaped_quotes + 1, escaped, quoted_length);

  // Wrap the escaped string in single-quotes, this is DO's convention (replace trailing \0)
  escaped_quotes[quoted_length] = escaped_quotes[0] = '\'';

  result = rb_str_new((const char *)escaped_quotes, quoted_length + 1);
  PQfreemem(escaped);
  free(escaped_quotes);
  return result;
}

static void full_connect(VALUE self, PGconn *db);

#ifdef _WIN32
static PGresult* query_execute_sync(VALUE self, VALUE connection, PGconn *db, VALUE query) {
  PGresult *response;
  struct timeval start;
  char* str = StringValuePtr(query);

  while ((response = PQgetResult(db)) != NULL) {
    PQclear(response);
  }

  gettimeofday(&start, NULL);

  response = PQexec(db, str);

  if (response == NULL) {
    if(PQstatus(db) != CONNECTION_OK) {
      PQreset(db);
      if (PQstatus(db) == CONNECTION_OK) {
        response = PQexec(db, str);
      } else {
        full_connect(connection, db);
        response = PQexec(db, str);
      }
    }

    if(response == NULL) {
      rb_raise(eConnectionError, PQerrorMessage(db));
    }
  }

  data_objects_debug(connection, query, &start);

  return response;
}
#else
static PGresult* query_execute_async(VALUE connection, PGconn *db, VALUE query) {
  int socket_fd;
  int retval;
  fd_set rset;
  PGresult *response;
  struct timeval start;
  char* str = StringValuePtr(query);

  while ((response = PQgetResult(db)) != NULL) {
    PQclear(response);
  }

  gettimeofday(&start, NULL);

  retval = PQsendQuery(db, str);

  if (!retval) {
    if(PQstatus(db) != CONNECTION_OK) {
      PQreset(db);
      if (PQstatus(db) == CONNECTION_OK) {
        retval = PQsendQuery(db, str);
      } else {
        full_connect(connection, db);
        retval = PQsendQuery(db, str);
      }
    }

    if(!retval) {
      rb_raise(eConnectionError, "%s", PQerrorMessage(db));
    }
  }

  socket_fd = PQsocket(db);

  for(;;) {
      FD_ZERO(&rset);
      FD_SET(socket_fd, &rset);
      retval = rb_thread_select(socket_fd + 1, &rset, NULL, NULL, NULL);
      if (retval < 0) {
          rb_sys_fail(0);
      }

      if (retval == 0) {
          continue;
      }

      if (PQconsumeInput(db) == 0) {
          rb_raise(eConnectionError, "%s", PQerrorMessage(db));
      }

      if (PQisBusy(db) == 0) {
          break;
      }
  }

  data_objects_debug(connection, query, &start);

  return PQgetResult(db);
}
#endif

static VALUE cConnection_initialize(VALUE self, VALUE uri) {
  VALUE r_host, r_user, r_password, r_path, r_query, r_port;

  PGconn *db = NULL;

  rb_iv_set(self, "@using_socket", Qfalse);

  r_host = rb_funcall(uri, rb_intern("host"), 0);
  if (Qnil != r_host) {
    rb_iv_set(self, "@host", r_host);
  }

  r_user = rb_funcall(uri, rb_intern("user"), 0);
  if (Qnil != r_user) {
    rb_iv_set(self, "@user", r_user);
  }

  r_password = rb_funcall(uri, rb_intern("password"), 0);
  if (Qnil != r_password) {
    rb_iv_set(self, "@password", r_password);
  }

  r_path = rb_funcall(uri, rb_intern("path"), 0);
  if (Qnil != r_path) {
    rb_iv_set(self, "@path", r_path);
  }

  r_port = rb_funcall(uri, rb_intern("port"), 0);
  if (Qnil != r_port) {
    r_port = rb_funcall(r_port, rb_intern("to_s"), 0);
    rb_iv_set(self, "@port", r_port);
  }

  // Pull the querystring off the URI
  r_query = rb_funcall(uri, rb_intern("query"), 0);
  rb_iv_set(self, "@query", r_query);

  const char* encoding = get_uri_option(r_query, "encoding");
  if (!encoding) { encoding = get_uri_option(r_query, "charset"); }
  if (!encoding) { encoding = "UTF-8"; }

  rb_iv_set(self, "@encoding", rb_str_new2(encoding));

  full_connect(self, db);

  rb_iv_set(self, "@uri", uri);

  return Qtrue;
}

static void full_connect(VALUE self, PGconn *db) {

  PGresult *result = NULL;
  VALUE r_host, r_user, r_password, r_path, r_port, r_query, r_options;
  char *host = NULL, *user = NULL, *password = NULL, *path = NULL, *database = NULL;
  const char *port = "5432";
  VALUE encoding = Qnil;
  int status;
  const char *search_path = NULL;
  char *search_path_query = NULL;
  const char *backslash_off = "SET backslash_quote = off";
  const char *standard_strings_on = "SET standard_conforming_strings = on";
  const char *warning_messages = "SET client_min_messages = warning";

  if((r_host = rb_iv_get(self, "@host")) != Qnil) {
    host     = StringValuePtr(r_host);
  }

  if((r_user = rb_iv_get(self, "@user")) != Qnil) {
    user     = StringValuePtr(r_user);
  }

  if((r_password = rb_iv_get(self, "@password")) != Qnil) {
    password = StringValuePtr(r_password);
  }

  if((r_port = rb_iv_get(self, "@port")) != Qnil) {
    port = StringValuePtr(r_port);
  }

  if((r_path = rb_iv_get(self, "@path")) != Qnil) {
    path = StringValuePtr(r_path);
    database = strtok(path, "/");
  }

  if (NULL == database || 0 == strlen(database)) {
    rb_raise(eConnectionError, "Database must be specified");
  }

  r_query        = rb_iv_get(self, "@query");

  search_path = get_uri_option(r_query, "search_path");

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
    rb_raise(eConnectionError, "%s", PQerrorMessage(db));
  }

  if (search_path != NULL) {
    search_path_query = (char *)calloc(256, sizeof(char));
    snprintf(search_path_query, 256, "set search_path to %s;", search_path);
    r_query = rb_str_new2(search_path_query);
    result = query_execute(self, db, r_query);

    if ((status = PQresultStatus(result)) != PGRES_COMMAND_OK) {
      free((void *)search_path_query);
      raise_error(self, status, result, r_query);
    }

    free((void *)search_path_query);
  }

  r_options = rb_str_new2(backslash_off);
  result = query_execute(self, db, r_options);

  if (PQresultStatus(result) != PGRES_COMMAND_OK) {
    rb_warn("%s", PQresultErrorMessage(result));
  }

  r_options = rb_str_new2(standard_strings_on);
  result = query_execute(self, db, r_options);

  if (PQresultStatus(result) != PGRES_COMMAND_OK) {
    rb_warn("%s", PQresultErrorMessage(result));
  }

  r_options = rb_str_new2(warning_messages);
  result = query_execute(self, db, r_options);

  if (PQresultStatus(result) != PGRES_COMMAND_OK) {
    rb_warn("%s", PQresultErrorMessage(result));
  }

  encoding = rb_iv_get(self, "@encoding");

#ifdef HAVE_PQSETCLIENTENCODING
  VALUE pg_encoding = rb_hash_aref(CONST_GET(mEncoding, "MAP"), encoding);
  if(pg_encoding != Qnil) {
    if(PQsetClientEncoding(db, rb_str_ptr_readonly(pg_encoding))) {
      rb_raise(eConnectionError, "Couldn't set encoding: %s", rb_str_ptr_readonly(encoding));
    } else {
#ifdef HAVE_RUBY_ENCODING_H
      rb_iv_set(self, "@encoding_id", INT2FIX(rb_enc_find_index(rb_str_ptr_readonly(encoding))));
#endif
    }
  } else {
    rb_warn("Encoding %s is not a known Ruby encoding for PostgreSQL\n", rb_str_ptr_readonly(encoding));
    rb_iv_set(self, "@encoding", rb_str_new2("UTF-8"));
#ifdef HAVE_RUBY_ENCODING_H
    rb_iv_set(self, "@encoding_id", INT2FIX(rb_enc_find_index("UTF-8")));
#endif
  }
#endif
  rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));
}

static VALUE cConnection_character_set(VALUE self) {
  return rb_iv_get(self, "@encoding");
}

static VALUE cConnection_execute(int argc, VALUE argv[], VALUE self) {
  VALUE postgres_connection = rb_iv_get(self, "@connection");
  if (Qnil == postgres_connection) {
    rb_raise(eConnectionError, "This connection has already been closed.");
  }

  PGconn *db = DATA_PTR(postgres_connection);
  PGresult *response;
  int status;

  VALUE affected_rows = Qnil;
  VALUE insert_id = Qnil;

  VALUE query = build_query_from_args(self, argc, argv);

  response = query_execute(self, db, query);

  status = PQresultStatus(response);

  if ( status == PGRES_TUPLES_OK ) {
    if (PQgetlength(response, 0, 0) == 0)  {
      insert_id = Qnil;
    } else {
      insert_id = INT2NUM(atoi(PQgetvalue(response, 0, 0)));
    }
    affected_rows = INT2NUM(atoi(PQcmdTuples(response)));
  }
  else if ( status == PGRES_COMMAND_OK ) {
    insert_id = Qnil;
    affected_rows = INT2NUM(atoi(PQcmdTuples(response)));
  }
  else {
    raise_error(self, status, response, query);
  }

  PQclear(response);

  return rb_funcall(cResult, ID_NEW, 2, affected_rows, insert_id);
}


static void cReader_mark(void * raw_reader) {
  pg_reader* reader = (pg_reader*) raw_reader;
  if(reader) {
    rb_gc_mark(reader->connection);
    rb_gc_mark(reader->query);
    rb_gc_mark(reader->columns);
    rb_gc_mark(reader->column_hash);
    rb_gc_mark(reader->types);
  }
}

static void cReader_free(void * raw_reader) {
  pg_reader* reader = (pg_reader*) raw_reader;
  if(reader && reader->result) {
    PQclear(reader->result);
  }
}

static VALUE cConnection_query(int argc, VALUE argv[], VALUE self) {
  pg_reader * raw_reader;
  VALUE reader = Data_Make_Struct(cReader, pg_reader, cReader_mark, cReader_free, raw_reader);

  VALUE query = build_query_from_args(self, argc, argv);

  raw_reader->query = query;
  raw_reader->connection = self;
  raw_reader->columns = Qnil;
  raw_reader->types = Qnil;
  raw_reader->column_hash = rb_hash_new();
  raw_reader->result = NULL;

  return reader;
}

static void cRow_mark(void * raw_row) {
  pg_row * row = (pg_row*) raw_row;
  if(row) {
    int i = 0;
    for(; i < row->column_count; ++i) {
      rb_gc_mark(row->values[i]);
    }
    rb_gc_mark(row->encoding_id);
    rb_gc_mark(row->columns);
    rb_gc_mark(row->column_hash);
    rb_gc_mark(row->types);
  }
}

static void cRow_free(void * raw_row) {
  pg_row * row = (pg_row*) raw_row;
  if(row) {
    ruby_xfree(row->values);
    ruby_xfree(row->lengths);
    ruby_xfree(row->raw);
    ruby_xfree(row);
  }
}

static VALUE cRow_populate(pg_reader* reader, VALUE encoding_id, int position) {

  pg_row * raw_row;
  VALUE row = Data_Make_Struct(cRow, pg_row, cRow_mark, cRow_free, raw_row);

  // Pointer used during storing raw data
  char *p   = NULL;

  raw_row->columns      = reader->columns;
  raw_row->column_hash  = reader->column_hash;
  raw_row->types        = reader->types;
  raw_row->column_count = reader->column_count;
  raw_row->encoding_id  = encoding_id;
  // Pointers for initialized values
  raw_row->values      = ruby_xmalloc(reader->column_count * sizeof(VALUE));
  // Data lengths of each entry
  raw_row->lengths     = ruby_xmalloc(reader->column_count * sizeof(int));

  int raw_length     = 0;
  int i              = 0;

  for (; i < reader->column_count; i++ ) {
    // Always return nil if the value returned from Postgres is null
    if (!PQgetisnull(reader->result, position, i)) {
      raw_row->values[i]      = 0;
      // We make room here for the potential trailing NULL character
      // PQgetlength reports the length without a trailing NULL
      // character, even if PQgetvalue will add it.
      raw_row->lengths[i]     = PQgetlength(reader->result, position, i) + 1;
      raw_length             += raw_row->lengths[i];
    } else {
      raw_row->values[i]      = Qnil;
      raw_row->lengths[i]     = 0;
    }
  }

  raw_row->raw = ruby_xmalloc(raw_length + reader->column_count);
  p = raw_row->raw;

  for ( i = 0; i < reader->column_count; i++ ) {
    if(!raw_row->values[i]) {
      memcpy(p, PQgetvalue(reader->result, position, i), raw_row->lengths[i]);
      p += raw_row->lengths[i];
    }
  }
  return row;
}

static void cReader_kick(VALUE self) {
  int status, i;
  int infer_types = 0;
  pg_reader * reader;
  Data_Get_Struct(self, pg_reader, reader);
  // Return if we already initialized
  if(reader->result) {
    return;
  }

  VALUE postgres_connection = rb_iv_get(reader->connection, "@connection");

  if (Qnil == postgres_connection) {
    rb_raise(eConnectionError, "This connection has already been closed.");
  }

  PGconn *db = DATA_PTR(postgres_connection);

  reader->result = query_execute(reader->connection, db, reader->query);

  if ((status = PQresultStatus(reader->result)) != PGRES_TUPLES_OK ) {
    raise_error(self, status, reader->result, reader->query);
  }

  reader->column_count = PQnfields(reader->result);
  reader->row_count   = PQntuples(reader->result);
  reader->columns = rb_ary_new2(reader->column_count);

  if(reader->types == Qnil) {
    reader->types = rb_ary_new2(reader->column_count);
    infer_types = 1;
  } else if (RARRAY_LEN(reader->types) != reader->column_count) {
    // Whoops...  wrong number of types passed to set_types.  Close the reader and raise
    // and error
    rb_raise(rb_eArgError, "Column count mismatch. Expected %ld columns, but the query yielded %d", RARRAY_LEN(reader->types), reader->column_count);
  }

  for ( i = 0; i < reader->column_count; ++i ) {
    rb_ary_store(reader->columns, i, rb_str_new2(PQfname(reader->result, i)));
    if ( infer_types ) {
      rb_ary_store(reader->types, i, infer_ruby_type(PQftype(reader->result, i)));
    }
  }
}


static VALUE cReader_each(VALUE self) {
  if (!rb_block_given_p()) {
    rb_raise(rb_eLocalJumpError, "no block given");
  }

  int i;
  pg_reader * reader;
  VALUE encoding_id;
  Data_Get_Struct(self, pg_reader, reader);

  cReader_kick(self);

#ifdef HAVE_RUBY_ENCODING_H
  encoding_id = rb_iv_get(reader->connection, "@encoding_id");
#endif

  for (i = 0; i < reader->row_count; ++i) {
    VALUE row = cRow_populate(reader, encoding_id, i);
    rb_yield(row);
  }

  return self;
}

static VALUE cReader_columns(VALUE self) {
  pg_reader * reader;
  Data_Get_Struct(self, pg_reader, reader);
  cReader_kick(self);
  return reader->columns;
}

static VALUE cReader_types(VALUE self) {
  pg_reader * reader;
  Data_Get_Struct(self, pg_reader, reader);
  cReader_kick(self);
  return reader->types;
}

static VALUE cReader_column_count(VALUE self) {
  pg_reader * reader;
  Data_Get_Struct(self, pg_reader, reader);
  cReader_kick(self);
  return INT2NUM(reader->column_count);
}

static VALUE cReader_row_count(VALUE self) {
  pg_reader * reader;
  Data_Get_Struct(self, pg_reader, reader);
  cReader_kick(self);
  return INT2NUM(reader->row_count);
}

static VALUE cRow_entry(VALUE self, int idx) {
  pg_row * row;
  Data_Get_Struct(self, pg_row, row);

  if(idx < 0) {
    rb_raise(rb_eArgError, "Negative index used for row");
  }
  if(idx >= row->column_count) {
    rb_raise(rb_eArgError, "Index larger than row size");
  }

  if(!row->values[idx]) {
    // Ok, we need to initialize the data here.
    // Retrieve the right piece of data

    VALUE column_type  = rb_ary_entry(row->types, idx);

    int enc = -1;
#ifdef HAVE_RUBY_ENCODING_H
    if (row->encoding_id != Qnil) {
      enc = FIX2INT(row->encoding_id);
    }
#endif

    int offset = 0;
    int i      = 0;
    for(; i < idx; ++i) {
      offset += row->lengths[i];
    }
    // We have to subtract 1 to the length here, since we
    // made room for it because it can contain a trailing NULL byte
    row->values[idx] = typecast(row->raw + offset, row->lengths[idx] - 1, column_type, enc);
  }
  return row->values[idx];

}

static VALUE cRow_aref(int argc, VALUE* argv, VALUE self) {

  if(argc == 1) {
    if(FIXNUM_P(argv[0])) {
      int idx = NUM2INT(argv[0]);
      return cRow_entry(self, idx);
    } else {
      VALUE sidx = StringValue(argv[0]);
      // Initialize the shared column => index hash
      pg_row * row;
      Data_Get_Struct(self, pg_row, row);
      if(RHASH_SIZE(row->column_hash) == 0) {
        int i = 0;
        for(; i < row->column_count; ++i) {
          rb_hash_aset(row->column_hash, rb_ary_entry(row->columns, i), INT2NUM(i));
        }
      }
      int idx = NUM2INT(rb_hash_aref(row->column_hash, sidx));
      return cRow_entry(self, idx);
    }
  } else if(argc == 2) {
    // Ok, syntax here is that we have a start / end
    rb_raise(rb_eArgError, "Not yet supported");
  }
  return Qnil;
}

static VALUE cRow_each(VALUE self) {
  if (!rb_block_given_p()) {
    rb_raise(rb_eLocalJumpError, "no block given");
  }

  pg_row * row;
  Data_Get_Struct(self, pg_row, row);
  int i = 0;

  for(; i < row->column_count; ++i) {
    VALUE field = cRow_entry(self, i);
    rb_yield(field);
  }
  return self;
}

static VALUE cRow_size(VALUE self) {
  pg_row * row;
  Data_Get_Struct(self, pg_row, row);
  return INT2NUM(row->column_count);
}

void Init_do_postgres() {
  rb_require("date");
  rb_require("rational");
  rb_require("bigdecimal");
  rb_require("data_objects");

  ID_CONST_GET = rb_intern("const_get");

  // Get references classes needed for Date/Time parsing
  rb_cDate = CONST_GET(rb_mKernel, "Date");
  rb_cDateTime = CONST_GET(rb_mKernel, "DateTime");
  rb_cBigDecimal = CONST_GET(rb_mKernel, "BigDecimal");

#ifdef RUBY_LESS_THAN_186
  ID_NEW_DATE = rb_intern("new0");
#else
  ID_NEW_DATE = rb_intern("new!");
#endif
  ID_RATIONAL = rb_intern("Rational");
  ID_NEW = rb_intern("new");
  ID_ESCAPE = rb_intern("escape_sql");
  ID_LOG = rb_intern("log");


  // Get references to the DataObjects module and its classes
  mDO = CONST_GET(rb_mKernel, "DataObjects");
  cDO_Quoting = CONST_GET(mDO, "Quoting");
  cDO_Connection = CONST_GET(mDO, "Connection");
  cDO_Result = CONST_GET(mDO, "Result");
  cDO_Reader = CONST_GET(mDO, "Reader");
  cDO_Row    = CONST_GET(mDO, "Row");
  cDO_Logger = CONST_GET(mDO, "Logger");
  cDO_Logger_Message = CONST_GET(cDO_Logger, "Message");

  rb_cByteArray = CONST_GET(mDO, "ByteArray");
  mPostgres = rb_define_module_under(mDO, "Postgres");
  eConnectionError = CONST_GET(mDO, "ConnectionError");
  eDataError = CONST_GET(mDO, "DataError");
  mEncoding = rb_define_module_under(mPostgres, "Encoding");

  cConnection = DRIVER_CLASS("Connection", cDO_Connection);
  rb_define_method(cConnection, "initialize", cConnection_initialize, 1);
  rb_define_method(cConnection, "dispose", cConnection_dispose, 0);
  rb_define_method(cConnection, "character_set", cConnection_character_set , 0);
  rb_define_method(cConnection, "quote_string", cConnection_quote_string, 1);
  rb_define_method(cConnection, "quote_byte_array", cConnection_quote_byte_array, 1);
  rb_define_method(cConnection, "execute", cConnection_execute, -1);
  rb_define_method(cConnection, "query", cConnection_query, -1);

  cResult = DRIVER_CLASS("Result", cDO_Result);

  cReader = DRIVER_CLASS("Reader", cDO_Reader);
  rb_define_method(cReader, "set_types", cReader_set_types, -1);
  rb_define_method(cReader, "types", cReader_types, 0);
  rb_define_method(cReader, "columns", cReader_columns, 0);
  rb_define_method(cReader, "each", cReader_each, 0);
  rb_define_method(cReader, "column_count", cReader_column_count, 0);
  rb_define_method(cReader, "row_count", cReader_row_count, 0);

  cRow = DRIVER_CLASS("Row", cDO_Row);

  rb_define_method(cRow, "[]", cRow_aref, -1);
  rb_define_method(cRow, "each", cRow_each, 0);
  rb_define_method(cRow, "size", cRow_size, 0);

  rb_global_variable(&ID_NEW_DATE);
  rb_global_variable(&ID_RATIONAL);
  rb_global_variable(&ID_CONST_GET);
  rb_global_variable(&ID_ESCAPE);
  rb_global_variable(&ID_LOG);
  rb_global_variable(&ID_NEW);

  rb_global_variable(&rb_cDate);
  rb_global_variable(&rb_cDateTime);
  rb_global_variable(&rb_cBigDecimal);
  rb_global_variable(&rb_cByteArray);

  rb_global_variable(&mDO);
  rb_global_variable(&cDO_Logger_Message);

  rb_global_variable(&cResult);
  rb_global_variable(&cReader);
  rb_global_variable(&cRow);

  rb_global_variable(&eConnectionError);
  rb_global_variable(&eDataError);

  struct errcodes *errs;

  for (errs = errors; errs->error_name; errs++) {
    rb_const_set(mPostgres, rb_intern(errs->error_name), INT2NUM(errs->error_no));
  }

}
