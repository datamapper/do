#include <ruby.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <time.h>

#include <mysql.h>
#include <errmsg.h>
#include <mysqld_error.h>

#include "compat.h"
#include "error.h"
#define RUBY_CLASS(name) rb_const_get(rb_cObject, rb_intern(name))
#define DRIVER_CLASS(klass, parent) (rb_define_class_under(mDOMysql, klass, parent))
#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))
#define CHECK_AND_RAISE(mysql_result_value, query) if (0 != mysql_result_value) { raise_error(self, db, query); }

#ifdef _WIN32
#define cCommand_execute cCommand_execute_sync
#define do_int64 signed __int64
#else
#define cCommand_execute cCommand_execute_async
#define do_int64 signed long long int
#endif

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


// To store rb_intern values
static ID ID_TO_I;
static ID ID_TO_F;
static ID ID_TO_S;
static ID ID_TO_TIME;
static ID ID_NEW;
static ID ID_NEW_DATE;
static ID ID_CONST_GET;
static ID ID_RATIONAL;
static ID ID_UTC;
static ID ID_ESCAPE_SQL;
static ID ID_STRFTIME;
static ID ID_LOGGER;
static ID ID_DEBUG;
static ID ID_LEVEL;

// Reference to Extlib module
static VALUE mExtlib;

// References to DataObjects base classes
static VALUE mDO;
static VALUE mEncoding;
static VALUE cDO_Quoting;
static VALUE cDO_Connection;
static VALUE cDO_Command;
static VALUE cDO_Result;
static VALUE cDO_Reader;

// References to Ruby classes that we'll need
static VALUE rb_cDate;
static VALUE rb_cDateTime;
static VALUE rb_cBigDecimal;
static VALUE rb_cByteArray;

// Classes that we'll build in Init
static VALUE mDOMysql;
static VALUE cConnection;
static VALUE cCommand;
static VALUE cResult;
static VALUE cReader;
static VALUE eArgumentError;
static VALUE eConnectionError;
static VALUE eDataError;

// Figures out what we should cast a given mysql field type to
static VALUE infer_ruby_type(MYSQL_FIELD *field) {
  switch(field->type) {
    case MYSQL_TYPE_NULL:
      return Qnil;
    case MYSQL_TYPE_TINY:
      return rb_cTrueClass;
    case MYSQL_TYPE_BIT:
    case MYSQL_TYPE_SHORT:
    case MYSQL_TYPE_LONG:
    case MYSQL_TYPE_INT24:
    case MYSQL_TYPE_LONGLONG:
    case MYSQL_TYPE_YEAR:
      return rb_cInteger;
    case MYSQL_TYPE_NEWDECIMAL:
    case MYSQL_TYPE_DECIMAL:
      return rb_cBigDecimal;
    case MYSQL_TYPE_FLOAT:
    case MYSQL_TYPE_DOUBLE:
      return rb_cFloat;
    case MYSQL_TYPE_TIMESTAMP:
    case MYSQL_TYPE_DATETIME:
      return rb_cDateTime;
    case MYSQL_TYPE_DATE:
    case MYSQL_TYPE_NEWDATE:
      return rb_cDate;
    case MYSQL_TYPE_TINY_BLOB:
    case MYSQL_TYPE_MEDIUM_BLOB:
    case MYSQL_TYPE_LONG_BLOB:
    case MYSQL_TYPE_BLOB:
      return rb_cByteArray;
    default:
      return rb_cString;
  }
}

// Find the greatest common denominator and reduce the provided numerator and denominator.
// This replaces calles to Rational.reduce! which does the same thing, but really slowly.
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

static VALUE seconds_to_offset(long seconds_offset) {
  do_int64 num = seconds_offset, den = 86400;
  reduce(&num, &den);
  return rb_funcall(rb_mKernel, ID_RATIONAL, 2, rb_ll2inum(num), rb_ll2inum(den));
}

static VALUE timezone_to_offset(int hour_offset, int minute_offset) {
  do_int64 seconds = 0;

  seconds += hour_offset * 3600;
  seconds += minute_offset * 60;

  return seconds_to_offset(seconds);
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

static VALUE parse_time(const char *date) {

  int year, month, day, hour, min, sec, usec, tokens;
  char subsec[7];

  if (0 != strchr(date, '.')) {
    // right padding usec with 0. e.g. '012' will become 12000 microsecond, since Time#local use microsecond
    sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d.%s", &year, &month, &day, &hour, &min, &sec, subsec);
    sscanf(subsec, "%d", &usec);
  } else {
    tokens = sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d", &year, &month, &day, &hour, &min, &sec);
    if (tokens == 3) {
      hour = 0;
      min  = 0;
      sec  = 0;
    }
    usec = 0;
  }

  if ( year + month + day + hour + min + sec + usec == 0 ) { // Mysql TIMESTAMPS can default to 0
    return Qnil;
  }

  return rb_funcall(rb_cTime, rb_intern("local"), 7, INT2NUM(year), INT2NUM(month), INT2NUM(day), INT2NUM(hour), INT2NUM(min), INT2NUM(sec), INT2NUM(usec));
}

static VALUE parse_date_time(const char *date) {
  VALUE ajd, offset;

  int year, month, day, hour, min, sec, usec, hour_offset, minute_offset;
  int jd;
  do_int64 num, den;


  time_t gmt_offset;
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

// Convert C-string to a Ruby instance of Ruby type "type"
static VALUE typecast(const char *value, long length, const VALUE type, int encoding) {

  if(NULL == value) {
    return Qnil;
  }

  if (type == rb_cInteger) {
    return rb_cstr2inum(value, 10);
  } else if (type == rb_cString) {
    return DO_STR_NEW(value, length, encoding);
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
    return (0 == value || 0 == strcmp("0", value)) ? Qfalse : Qtrue;
  } else if (type == rb_cByteArray) {
    return rb_funcall(rb_cByteArray, ID_NEW, 1, rb_str_new(value, length));
  } else if (type == rb_cClass) {
    return rb_funcall(mDO, rb_intern("full_const_get"), 1, rb_str_new(value, length));
  } else if (type == rb_cObject) {
    return rb_marshal_load(rb_str_new(value, length));
  } else if (type == rb_cNilClass) {
    return Qnil;
  } else {
    return DO_STR_NEW(value, length, encoding);
  }

}

static void data_objects_debug(VALUE string, struct timeval* start) {
  struct timeval stop;
  char *message;

  const char *query = rb_str_ptr_readonly(string);
  size_t length     = rb_str_len(string);
  char total_time[32];
  do_int64 duration = 0;

  VALUE logger = rb_funcall(mDOMysql, ID_LOGGER, 0);
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

static void raise_error(VALUE self, MYSQL *db, VALUE query) {
  VALUE exception;
  const char *exception_type = "SQLError";
  char *mysql_error_message = (char *)mysql_error(db);
  int mysql_error_code = mysql_errno(db);

  struct errcodes *errs;

  for (errs = errors; errs->error_name; errs++) {
    if(errs->error_no == mysql_error_code) {
      exception_type = errs->exception;
      break;
    }
  }

  VALUE uri = rb_funcall(rb_iv_get(self, "@connection"), rb_intern("to_s"), 0);

  exception = rb_funcall(CONST_GET(mDO, exception_type), ID_NEW, 5,
                         rb_str_new2(mysql_error_message),
                         INT2NUM(mysql_error_code),
                         rb_str_new2(mysql_sqlstate(db)),
                         query,
                         uri);
  rb_exc_raise(exception);
}

static char * get_uri_option(VALUE query_hash, const char * key) {
  VALUE query_value;
  char * value = NULL;

  if(!rb_obj_is_kind_of(query_hash, rb_cHash)) { return NULL; }

  query_value = rb_hash_aref(query_hash, rb_str_new2(key));

  if (Qnil != query_value) {
    value = StringValuePtr(query_value);
  }

  return value;
}

static void assert_file_exists(char * file, const char * message) {
  if (file == NULL) { return; }
  if (rb_funcall(rb_cFile, rb_intern("exist?"), 1, rb_str_new2(file)) == Qfalse) {
    rb_raise(eArgumentError, "%s", message);
  }
}

static void full_connect(VALUE self, MYSQL *db);

#ifdef _WIN32
static MYSQL_RES* cCommand_execute_sync(VALUE self, MYSQL* db, VALUE query) {
  int retval;
  struct timeval start;
  const char* str = rb_str_ptr_readonly(query);
  int len         = rb_str_len(query);

  if(mysql_ping(db) && mysql_errno(db) == CR_SERVER_GONE_ERROR) {
    // Ok, we do one more try here by doing a full connect
    VALUE connection = rb_iv_get(self, "@connection");
    full_connect(connection, db);
  }
  gettimeofday(&start, NULL);
  retval = mysql_real_query(db, str, len);
  data_objects_debug(query, &start);

  CHECK_AND_RAISE(retval, query);

  return mysql_store_result(db);
}
#else
static MYSQL_RES* cCommand_execute_async(VALUE self, MYSQL* db, VALUE query) {
  int socket_fd;
  int retval;
  fd_set rset;
  struct timeval start;
  const char* str = rb_str_ptr_readonly(query);
  size_t len      = rb_str_len(query);

  if((retval = mysql_ping(db)) && mysql_errno(db) == CR_SERVER_GONE_ERROR) {
    VALUE connection = rb_iv_get(self, "@connection");
    full_connect(connection, db);
  }
  retval = mysql_send_query(db, str, len);

  CHECK_AND_RAISE(retval, query);
  gettimeofday(&start, NULL);

  socket_fd = db->net.fd;

  data_objects_debug(query, &start);

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

    if (db->status == MYSQL_STATUS_READY) {
      break;
    }
  }

  retval = mysql_read_query_result(db);
  CHECK_AND_RAISE(retval, query);

  return mysql_store_result(db);
}
#endif


static void full_connect(VALUE self, MYSQL* db) {
  // Check to see if we're on the db machine.  If so, try to use the socket
  VALUE r_host, r_user, r_password, r_path, r_query, r_port;

  const char *host = "localhost", *user = "root"; 
  char *database = NULL, *socket = NULL, *password = NULL, *path = NULL;
  VALUE encoding = Qnil;

  MYSQL *result;

  int port = 3306;
  unsigned long client_flags = 0;
  int encoding_error;

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
    port = NUM2INT(r_port);
  }

  if((r_path = rb_iv_get(self, "@path")) != Qnil) {
    path = StringValuePtr(r_path);
    database = strtok(path, "/");
  }

  if (NULL == database || 0 == strlen(database)) {
    rb_raise(eConnectionError, "Database must be specified");
  }

  r_query        = rb_iv_get(self, "@query");

  if (0 == strcasecmp(host, "localhost")) {
    socket = get_uri_option(r_query, "socket");
    if (NULL != socket) {
      rb_iv_set(self, "@using_socket", Qtrue);
    }
  }

#ifdef HAVE_MYSQL_SSL_SET
  char *ssl_client_key, *ssl_client_cert, *ssl_ca_cert, *ssl_ca_path, *ssl_cipher;
  VALUE r_ssl;

  if(rb_obj_is_kind_of(r_query, rb_cHash)) {
    r_ssl = rb_hash_aref(r_query, rb_str_new2("ssl"));

    if(rb_obj_is_kind_of(r_ssl, rb_cHash)) {
      ssl_client_key  = get_uri_option(r_ssl, "client_key");
      ssl_client_cert = get_uri_option(r_ssl, "client_cert");
      ssl_ca_cert     = get_uri_option(r_ssl, "ca_cert");
      ssl_ca_path     = get_uri_option(r_ssl, "ca_path");
      ssl_cipher      = get_uri_option(r_ssl, "cipher");

      assert_file_exists(ssl_client_key,  "client_key doesn't exist");
      assert_file_exists(ssl_client_cert, "client_cert doesn't exist");
      assert_file_exists(ssl_ca_cert,     "ca_cert doesn't exist");

      mysql_ssl_set(db, ssl_client_key, ssl_client_cert, ssl_ca_cert, ssl_ca_path, ssl_cipher);
    } else if(r_ssl != Qnil) {
      rb_raise(eArgumentError, "ssl must be passed a hash");
    }
  }
#endif

  result = (MYSQL *)mysql_real_connect(
    db,
    host,
    user,
    password,
    database,
    port,
    socket,
    client_flags
  );

  if (NULL == result) {
    raise_error(self, db, Qnil);
  }

#ifdef HAVE_MYSQL_SSL_SET
  const char *ssl_cipher_used = mysql_get_ssl_cipher(db);

  if (NULL != ssl_cipher_used) {
    rb_iv_set(self, "@ssl_cipher", rb_str_new2(ssl_cipher_used));
  }
#endif

#ifdef MYSQL_OPT_RECONNECT
  my_bool reconnect = 1;
  mysql_options(db, MYSQL_OPT_RECONNECT, &reconnect);
#endif

  // Set the connections character set
  encoding = rb_iv_get(self, "@encoding");

  VALUE my_encoding = rb_hash_aref(CONST_GET(mEncoding, "MAP"), encoding);
  if(my_encoding != Qnil) {
    encoding_error = mysql_set_character_set(db, rb_str_ptr_readonly(my_encoding));
    if (0 != encoding_error) {
      raise_error(self, db, Qnil);
    } else {
#ifdef HAVE_RUBY_ENCODING_H
      rb_iv_set(self, "@encoding_id", INT2FIX(rb_enc_find_index(rb_str_ptr_readonly(encoding))));
#endif
      rb_iv_set(self, "@my_encoding", my_encoding);
    }
  } else {
    rb_warn("Encoding %s is not a known Ruby encoding for MySQL\n", rb_str_ptr_readonly(encoding));
    rb_iv_set(self, "@encoding", rb_str_new2("UTF-8"));
#ifdef HAVE_RUBY_ENCODING_H
    rb_iv_set(self, "@encoding_id", INT2FIX(rb_enc_find_index("UTF-8")));
#endif
    rb_iv_set(self, "@my_encoding", rb_str_new2("utf8"));
  }

  // Disable sql_auto_is_null
  cCommand_execute(self, db, rb_str_new2("SET sql_auto_is_null = 0"));
  // removed NO_AUTO_VALUE_ON_ZERO because of MySQL bug http://bugs.mysql.com/bug.php?id=42270
  // added NO_BACKSLASH_ESCAPES so that backslashes should not be escaped as in other databases
  cCommand_execute(self, db, rb_str_new2("SET SESSION sql_mode = 'ANSI,NO_BACKSLASH_ESCAPES,NO_DIR_IN_CREATE,NO_ENGINE_SUBSTITUTION,NO_UNSIGNED_SUBTRACTION,TRADITIONAL'"));

  rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));
}

static VALUE cConnection_initialize(VALUE self, VALUE uri) {
  VALUE r_host, r_user, r_password, r_path, r_query, r_port;

  MYSQL *db = 0;
  db = (MYSQL *)mysql_init(NULL);

  rb_iv_set(self, "@using_socket", Qfalse);
  rb_iv_set(self, "@ssl_cipher", Qnil);

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

static VALUE cConnection_character_set(VALUE self) {
  return rb_iv_get(self, "@encoding");
}

static VALUE cConnection_is_using_socket(VALUE self) {
  return rb_iv_get(self, "@using_socket");
}

static VALUE cConnection_ssl_cipher(VALUE self) {
  return rb_iv_get(self, "@ssl_cipher");
}

static VALUE cConnection_dispose(VALUE self) {
  VALUE connection_container = rb_iv_get(self, "@connection");

  MYSQL *db;

  if (Qnil == connection_container)
    return Qfalse;

  db = DATA_PTR(connection_container);

  if (NULL == db)
    return Qfalse;

  mysql_close(db);
  rb_iv_set(self, "@connection", Qnil);

  return Qtrue;
}

/*
Accepts an array of Ruby types (Fixnum, Float, String, etc...) and turns them
into Ruby-strings so we can easily typecast later
*/
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

VALUE cConnection_quote_time(VALUE self, VALUE value) {
  return rb_funcall(value, ID_STRFTIME, 1, rb_str_new2("'%Y-%m-%d %H:%M:%S'"));
}


VALUE cConnection_quote_date_time(VALUE self, VALUE value) {
  // TODO: Support non-local dates. we need to call #new_offset on the date to be
  // quoted and pass in the current locale's date offset (self.new_offset((hours * 3600).to_r / 86400)
  return rb_funcall(value, ID_STRFTIME, 1, rb_str_new2("'%Y-%m-%d %H:%M:%S'"));
}

VALUE cConnection_quote_date(VALUE self, VALUE value) {
  return rb_funcall(value, ID_STRFTIME, 1, rb_str_new2("'%Y-%m-%d'"));
}

static VALUE cConnection_quote_string(VALUE self, VALUE string) {
  MYSQL *db = DATA_PTR(rb_iv_get(self, "@connection"));
  const char *source = rb_str_ptr_readonly(string);
  size_t source_len  = rb_str_len(string);
  char *escaped;
  VALUE result;

  size_t quoted_length = 0;

  // Allocate space for the escaped version of 'string'.  Use + 3 allocate space for null term.
  // and the leading and trailing single-quotes.
  // Thanks to http://www.browardphp.com/mysql_manual_en/manual_MySQL_APIs.html#mysql_real_escape_string
  escaped = (char *)calloc(source_len * 2 + 3, sizeof(char));

  // Escape 'source' using the current encoding in use on the conection 'db'
  quoted_length = mysql_real_escape_string(db, escaped + 1, source, source_len);

  // Wrap the escaped string in single-quotes, this is DO's convention
  escaped[0] = escaped[quoted_length + 1] = '\'';
  result = DO_STR_NEW(escaped, quoted_length + 2, FIX2INT(rb_iv_get(self, "@encoding_id")));

  free(escaped);
  return result;
}

static VALUE build_query_from_args(VALUE klass, int count, VALUE *args) {
  VALUE query = rb_iv_get(klass, "@text");

  int i;
  VALUE array = rb_ary_new();
  for ( i = 0; i < count; i++) {
    rb_ary_push(array, (VALUE)args[i]);
  }
  query = rb_funcall(klass, ID_ESCAPE_SQL, 1, array);

  return query;
}

static VALUE cCommand_execute_non_query(int argc, VALUE *argv, VALUE self) {
  VALUE query;

  MYSQL_RES *response = 0;

  my_ulonglong affected_rows;
  VALUE connection = rb_iv_get(self, "@connection");
  VALUE mysql_connection = rb_iv_get(connection, "@connection");
  if (Qnil == mysql_connection) {
    rb_raise(eConnectionError, "This connection has already been closed.");
  }

  MYSQL *db = DATA_PTR(mysql_connection);
  query = build_query_from_args(self, argc, argv);

  response = cCommand_execute(self, db, query);

  affected_rows = mysql_affected_rows(db);
  mysql_free_result(response);

  if ((my_ulonglong)-1 == affected_rows)
    return Qnil;

  return rb_funcall(cResult, ID_NEW, 3, self, INT2NUM(affected_rows), INT2NUM(mysql_insert_id(db)));
}

static VALUE cCommand_execute_reader(int argc, VALUE *argv, VALUE self) {
  VALUE query, reader;
  VALUE field_names, field_types;

  unsigned int field_count;
  unsigned int i;

  char guess_default_field_types = 0;
  VALUE connection = rb_iv_get(self, "@connection");
  VALUE mysql_connection = rb_iv_get(connection, "@connection");
  if (Qnil == mysql_connection) {
    rb_raise(eConnectionError, "This connection has already been closed.");
  }

  MYSQL *db = DATA_PTR(mysql_connection);

  MYSQL_RES *response = 0;
  MYSQL_FIELD *field;

  query = build_query_from_args(self, argc, argv);

  response = cCommand_execute(self, db, query);

  if (!response) {
    return Qnil;
  }

  field_count = mysql_field_count(db);

  reader = rb_funcall(cReader, ID_NEW, 0);
  rb_iv_set(reader, "@connection", connection);
  rb_iv_set(reader, "@reader", Data_Wrap_Struct(rb_cObject, 0, 0, response));
  rb_iv_set(reader, "@opened", Qfalse);
  rb_iv_set(reader, "@field_count", INT2NUM(field_count));

  field_names = rb_ary_new();
  field_types = rb_iv_get(self, "@field_types");

  if ( field_types == Qnil || 0 == RARRAY_LEN(field_types) ) {
    field_types = rb_ary_new();
    guess_default_field_types = 1;
  } else if (RARRAY_LEN(field_types) != field_count) {
    // Whoops...  wrong number of types passed to set_types.  Close the reader and raise
    // and error
    rb_funcall(reader, rb_intern("close"), 0);
    rb_raise(eArgumentError, "Field-count mismatch. Expected %ld fields, but the query yielded %d", RARRAY_LEN(field_types), field_count);
  }

  for(i = 0; i < field_count; i++) {
    field = mysql_fetch_field_direct(response, i);
    rb_ary_push(field_names, rb_str_new2(field->name));

    if (1 == guess_default_field_types) {
      rb_ary_push(field_types, infer_ruby_type(field));
    }
  }

  rb_iv_set(reader, "@fields", field_names);
  rb_iv_set(reader, "@field_types", field_types);

  if (rb_block_given_p()) {
    rb_yield(reader);
    rb_funcall(reader, rb_intern("close"), 0);
  }

  return reader;
}

// This should be called to ensure that the internal result reader is freed
static VALUE cReader_close(VALUE self) {
  // Get the reader from the instance variable, maybe refactor this?
  VALUE reader_container = rb_iv_get(self, "@reader");

  MYSQL_RES *reader;

  if (Qnil == reader_container)
    return Qfalse;

  reader = DATA_PTR(reader_container);

  // The Meat
  if (NULL == reader)
    return Qfalse;

  mysql_free_result(reader);
  rb_iv_set(self, "@reader", Qnil);
  rb_iv_set(self, "@opened", Qfalse);

  return Qtrue;
}

// Retrieve a single row
static VALUE cReader_next(VALUE self) {
  // Get the reader from the instance variable, maybe refactor this?
  VALUE reader_container = rb_iv_get(self, "@reader");
  VALUE field_types, field_type, row;

  MYSQL_RES *reader;
  MYSQL_ROW result;
  unsigned long *lengths;

  unsigned int i;

  if (Qnil == reader_container) {
    return Qfalse;
  }

  reader = DATA_PTR(reader_container);

  // The Meat
  field_types = rb_iv_get(self, "@field_types");
  row = rb_ary_new();
  result = mysql_fetch_row(reader);
  lengths = mysql_fetch_lengths(reader);

  rb_iv_set(self, "@opened", result ? Qtrue : Qfalse);

  if (!result) {
    return Qfalse;
  }

  int enc = -1;
#ifdef HAVE_RUBY_ENCODING_H
  VALUE encoding_id = rb_iv_get(rb_iv_get(self, "@connection"), "@encoding_id");
  if (encoding_id != Qnil) {
    enc = FIX2INT(encoding_id);
  }
#endif

  for (i = 0; i < reader->field_count; i++) {
    // The field_type data could be cached in a c-array
    field_type = rb_ary_entry(field_types, i);
    rb_ary_push(row, typecast(result[i], lengths[i], field_type, enc));
  }

  rb_iv_set(self, "@values", row);

  return Qtrue;
}

static VALUE cReader_values(VALUE self) {
  VALUE state = rb_iv_get(self, "@opened");
  if ( state == Qnil || state == Qfalse ) {
    rb_raise(eDataError, "Reader is not initialized");
  }
  return rb_iv_get(self, "@values");
}

static VALUE cReader_fields(VALUE self) {
  return rb_iv_get(self, "@fields");
}

static VALUE cReader_field_count(VALUE self) {
  return rb_iv_get(self, "@field_count");
}

void Init_do_mysql() {
  rb_require("bigdecimal");
  rb_require("date");

  rb_funcall(rb_mKernel, rb_intern("require"), 1, rb_str_new2("data_objects"));

  ID_TO_I = rb_intern("to_i");
  ID_TO_F = rb_intern("to_f");
  ID_TO_S = rb_intern("to_s");
  ID_TO_TIME = rb_intern("to_time");
  ID_NEW = rb_intern("new");
#ifdef RUBY_LESS_THAN_186
  ID_NEW_DATE = rb_intern("new0");
#else
  ID_NEW_DATE = rb_intern("new!");
#endif
  ID_CONST_GET = rb_intern("const_get");
  ID_RATIONAL = rb_intern("Rational");
  ID_UTC = rb_intern("utc");
  ID_ESCAPE_SQL = rb_intern("escape_sql");
  ID_STRFTIME = rb_intern("strftime");
  ID_LOGGER = rb_intern("logger");
  ID_DEBUG = rb_intern("debug");
  ID_LEVEL = rb_intern("level");

  // Store references to a few helpful clases that aren't in Ruby Core
  rb_cDate = RUBY_CLASS("Date");
  rb_cDateTime = RUBY_CLASS("DateTime");
  rb_cBigDecimal = RUBY_CLASS("BigDecimal");

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

  // Top Level Module that all the classes live under
  mDOMysql = rb_define_module_under(mDO, "Mysql");

  eArgumentError = CONST_GET(rb_mKernel, "ArgumentError");
  eConnectionError = CONST_GET(mDO, "ConnectionError");
  eDataError = CONST_GET(mDO, "DataError");
  mEncoding = rb_define_module_under(mDOMysql, "Encoding");

  cConnection = DRIVER_CLASS("Connection", cDO_Connection);
  rb_define_method(cConnection, "initialize", cConnection_initialize, 1);
  rb_define_method(cConnection, "using_socket?", cConnection_is_using_socket, 0);
  rb_define_method(cConnection, "ssl_cipher", cConnection_ssl_cipher, 0);
  rb_define_method(cConnection, "character_set", cConnection_character_set , 0);
  rb_define_method(cConnection, "dispose", cConnection_dispose, 0);
  rb_define_method(cConnection, "quote_string", cConnection_quote_string, 1);
  rb_define_method(cConnection, "quote_date", cConnection_quote_date, 1);
  rb_define_method(cConnection, "quote_time", cConnection_quote_time, 1);
  rb_define_method(cConnection, "quote_datetime", cConnection_quote_date_time, 1);

  cCommand = DRIVER_CLASS("Command", cDO_Command);
  rb_define_method(cCommand, "set_types", cCommand_set_types, -1);
  rb_define_method(cCommand, "execute_non_query", cCommand_execute_non_query, -1);
  rb_define_method(cCommand, "execute_reader", cCommand_execute_reader, -1);

  // Non-Query result
  cResult = DRIVER_CLASS("Result", cDO_Result);

  // Query result
  cReader = DRIVER_CLASS("Reader", cDO_Reader);
  rb_define_method(cReader, "close", cReader_close, 0);
  rb_define_method(cReader, "next!", cReader_next, 0);
  rb_define_method(cReader, "values", cReader_values, 0);
  rb_define_method(cReader, "fields", cReader_fields, 0);
  rb_define_method(cReader, "field_count", cReader_field_count, 0);

  struct errcodes *errs;

  for (errs = errors; errs->error_name; errs++) {
    rb_const_set(mDOMysql, rb_intern(errs->error_name), INT2NUM(errs->error_no));
  }
}
