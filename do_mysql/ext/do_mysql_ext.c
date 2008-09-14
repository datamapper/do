#include <ruby.h>
#include <version.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <time.h>
#include <my_global.h>
#include <mysql.h>
#include <errmsg.h>
#include <mysqld_error.h>

#define RUBY_CLASS(name) rb_const_get(rb_cObject, rb_intern(name))
#define RUBY_STRING(char_ptr) rb_str_new2(char_ptr)
#define TAINTED_STRING(name) rb_tainted_str_new2(name)
#define DRIVER_CLASS(klass, parent) (rb_define_class_under(mDOMysql, klass, parent))
#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))
#define CHECK_AND_RAISE(mysql_result_value) if (0 != mysql_result_value) { raise_mysql_error(connection, db, mysql_result_value); }
#define PUTS(string) rb_funcall(rb_mKernel, rb_intern("puts"), 1, RUBY_STRING(string))

#ifndef RSTRING_PTR
#define RSTRING_PTR(s) (RSTRING(s)->ptr)
#endif

#ifndef RSTRING_LEN
#define RSTRING_LEN(s) (RSTRING(s)->len)
#endif

#ifdef _WIN32
#define do_int64 signed __int64
#else
#define do_int64 signed long long int
#endif

// To store rb_intern values
static ID ID_TO_I;
static ID ID_TO_F;
static ID ID_TO_S;
static ID ID_PARSE;
static ID ID_TO_TIME;
static ID ID_NEW;
static ID ID_NEW_RATIONAL;
static ID ID_NEW_DATE;
static ID ID_CONST_GET;
static ID ID_UTC;
static ID ID_ESCAPE_SQL;
static ID ID_STRFTIME;
static ID ID_LOGGER;
static ID ID_DEBUG;
static ID ID_LEVEL;

// References to DataObjects base classes
static VALUE mDO;
static VALUE cDO_Quoting;
static VALUE cDO_Connection;
static VALUE cDO_Command;
static VALUE cDO_Result;
static VALUE cDO_Reader;

// References to Ruby classes that we'll need
static VALUE rb_cDate;
static VALUE rb_cDateTime;
static VALUE rb_cRational;
static VALUE rb_cBigDecimal;
static VALUE rb_cCGI;

// Classes that we'll build in Init
static VALUE mDOMysql;
static VALUE cConnection;
static VALUE cCommand;
static VALUE cResult;
static VALUE cReader;
static VALUE eMysqlError;

// Figures out what we should cast a given mysql field type to
static char * ruby_type_from_mysql_type(MYSQL_FIELD *field) {

  char* ruby_type_name;

  switch(field->type) {
    case MYSQL_TYPE_NULL: {
      ruby_type_name = NULL;
      break;
    }
    case MYSQL_TYPE_TINY: {
      ruby_type_name = "TrueClass";
      break;
    }
    case MYSQL_TYPE_SHORT:
    case MYSQL_TYPE_LONG:
    case MYSQL_TYPE_INT24:
    case MYSQL_TYPE_LONGLONG:
    case MYSQL_TYPE_YEAR: {
      ruby_type_name = "Fixnum";
      break;
    }
    case MYSQL_TYPE_DECIMAL:
    case MYSQL_TYPE_FLOAT:
    case MYSQL_TYPE_DOUBLE: {
      ruby_type_name = "BigDecimal";
      break;
    }
    case MYSQL_TYPE_TIMESTAMP:
    case MYSQL_TYPE_DATETIME: {
      ruby_type_name = "DateTime";
      break;
    }
    case MYSQL_TYPE_TIME: {
      ruby_type_name = "DateTime";
      break;
    }
    case MYSQL_TYPE_DATE: {
      ruby_type_name = "Date";
      break;
    }
    default: {
      // printf("Falling to default: %s - %d\n", field->name, field->type);
      ruby_type_name = "String";
    }
  }

  return ruby_type_name;
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
  return floor(365.25 * (year + 4716)) + floor(30.6001 * (month + 1)) + day + b - 1524;
}

static VALUE seconds_to_offset(long seconds_offset) {
  do_int64 num = seconds_offset, den = 86400;
  reduce(&num, &den);
  return rb_funcall(rb_cRational, rb_intern("new!"), 2, rb_ll2inum(num), rb_ll2inum(den));
}

static VALUE parse_date(const char *date) {
  int year, month, day;
  int jd, ajd;
  VALUE rational;

  sscanf(date, "%4d-%2d-%2d", &year, &month, &day);

  jd = jd_from_date(year, month, day);

  // Math from Date.jd_to_ajd
  ajd = jd * 2 - 1;
  rational = rb_funcall(rb_cRational, ID_NEW_RATIONAL, 2, INT2NUM(ajd), INT2NUM(2));
  return rb_funcall(rb_cDate, ID_NEW_DATE, 3, rational, INT2NUM(0), INT2NUM(2299161));
}

static VALUE parse_time(const char *date) {

  int year, month, day, hour, min, sec, usec;
  char subsec[7];

  if (0 != strchr(date, '.')) {
    // right padding usec with 0. e.g. '012' will become 12000 microsecond, since Time#local use microsecond
    sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d.%s", &year, &month, &day, &hour, &min, &sec, subsec);
    sscanf(subsec, "%d", &usec);
  } else {
    sscanf(date, "%4d-%2d-%2d %2d:%2d:%2d", &year, &month, &day, &hour, &min, &sec);
    usec = 0;
  }

  if ( year + month + day + hour + min + sec + usec == 0 ) { // Mysql TIMESTAMPS can default to 0
    return Qnil;
  }

  return rb_funcall(rb_cTime, rb_intern("local"), 7, INT2NUM(year), INT2NUM(month), INT2NUM(day), INT2NUM(hour), INT2NUM(min), INT2NUM(sec), INT2NUM(usec));
}

static VALUE parse_date_time(const char *date_time) {
  VALUE ajd, offset;

  int year, month, day, hour, min, sec;
  int jd;
  do_int64 num, den;

  time_t rawtime;
  struct tm * timeinfo;

  // Mysql date format: 2008-05-03 14:43:00
  sscanf(date_time, "%4d-%2d-%2d %2d:%2d:%2d", &year, &month, &day, &hour, &min, &sec);

  jd = jd_from_date(year, month, day);

  // Generate ajd with fractional days for the time
  // Extracted from Date#jd_to_ajd, Date#day_fraction_to_time, and Rational#+ and #-
  num = ((hour) * 1440) + ((min) * 24); // (Hour * Minutes in a day) + (minutes * 24)

  // Get localtime
  time(&rawtime);
  timeinfo = localtime(&rawtime);

  // TODO: Refactor the following few lines to do the calculation with the *seconds*
  // value instead of having to do the hour/minute math
  int hour_offset = abs(timeinfo->tm_gmtoff) / 3600;
  int minute_offset = abs(timeinfo->tm_gmtoff) % 3600 / 60;

  // Modify the numerator so when we apply the timezone everything works out
  if (timeinfo->tm_gmtoff < 0) {
    // If the Timezone is behind UTC, we need to add the time offset
    num += (hour_offset * 1440) + (minute_offset * 24);
  } else {
    // If the Timezone is ahead of UTC, we need to subtract the time offset
    num -= (hour_offset * 1440) + (minute_offset * 24);
  }

  den = (24 * 1440);
  reduce(&num, &den);

  num = (num * 86400) + (sec * den);
  den = den * 86400;
  reduce(&num, &den);

  num = (jd * den) + num;

  num = num * 2 - den;
  den = den * 2;
  reduce(&num, &den);

  ajd = rb_funcall(rb_cRational, rb_intern("new!"), 2, rb_ull2inum(num), rb_ull2inum(den));

  // Calculate the offset using the seconds from GMT
  offset = seconds_to_offset(timeinfo->tm_gmtoff);

  return rb_funcall(rb_cDateTime, ID_NEW_DATE, 3, ajd, offset, INT2NUM(2299161));
}

// Convert C-string to a Ruby instance of Ruby type "type"
static VALUE typecast(const char* value, char* type) {
  if (NULL == value)
    return Qnil;

  if ( strcmp(type, "Class") == 0) {
    return rb_funcall(mDO, rb_intern("find_const"), 1, TAINTED_STRING(value));
  } else if ( strcmp(type, "Integer") == 0 || strcmp(type, "Fixnum") == 0 || strcmp(type, "Bignum") == 0 ) {
    return rb_cstr2inum(value, 10);
  } else if (0 == strcmp("String", type)) {
    return TAINTED_STRING(value);
  } else if (0 == strcmp("Float", type) ) {
    return rb_float_new(rb_cstr_to_dbl(value, Qfalse));
  } else if (0 == strcmp("BigDecimal", type) ) {
    return rb_funcall(rb_cBigDecimal, ID_NEW, 1, TAINTED_STRING(value));
  } else if (0 == strcmp("TrueClass", type) || 0 == strcmp("FalseClass", type)) {
    return (0 == value || 0 == strcmp("0", value)) ? Qfalse : Qtrue;
  } else if (0 == strcmp("Date", type)) {
    return parse_date(value);
  } else if (0 == strcmp("DateTime", type)) {
    return parse_date_time(value);
  } else if (0 == strcmp("Time", type)) {
    return parse_time(value);
  } else {
    return TAINTED_STRING(value);
  }
}

static void data_objects_debug(VALUE string) {
  VALUE logger = rb_funcall(mDOMysql, ID_LOGGER, 0);
  int log_level = NUM2INT(rb_funcall(logger, ID_LEVEL, 0));

  if (0 == log_level) {
    rb_funcall(logger, ID_DEBUG, 1, string);
  }
}

static void flush_pool(VALUE connection) {
  data_objects_debug(rb_funcall(connection, rb_intern("inspect"), 0));
  if ( Qnil != connection ) {
    VALUE pool = rb_iv_get(connection, "@__pool");
    rb_funcall(pool, rb_intern("flush!"), 0);
    rb_funcall(pool, rb_intern("delete"), 1, connection);
    rb_funcall(connection, rb_intern("dispose"), 0);
  }
}

// We can add custom information to error messages using this function
// if we think it matters
static void raise_mysql_error(VALUE connection, MYSQL *db, int mysql_error_code) {
  char *mysql_error_message = (char *)mysql_error(db);
  int length = strlen(mysql_error_message) + 25; // length of " (mysql_error_code=0000)"
  char *error_message = (char *)calloc(length, sizeof(char));

  sprintf(error_message, "%s (mysql_error_code=%04d)", mysql_error_message, mysql_error_code);

  data_objects_debug(rb_str_new2(error_message));

  switch(mysql_error_code) {
    case CR_UNKNOWN_ERROR:
    case CR_SOCKET_CREATE_ERROR:
    case CR_CONNECTION_ERROR:
    case CR_CONN_HOST_ERROR:
    case CR_IPSOCK_ERROR:
    case CR_UNKNOWN_HOST:
    case CR_SERVER_GONE_ERROR:
    case CR_VERSION_ERROR:
    case CR_OUT_OF_MEMORY:
    case CR_WRONG_HOST_INFO:
    case CR_LOCALHOST_CONNECTION:
    case CR_TCP_CONNECTION:
    case CR_SERVER_HANDSHAKE_ERR:
    case CR_SERVER_LOST:
    case CR_COMMANDS_OUT_OF_SYNC:
    case CR_NAMEDPIPE_CONNECTION:
    case CR_NAMEDPIPEWAIT_ERROR:
    case CR_NAMEDPIPEOPEN_ERROR:
    case CR_NAMEDPIPESETSTATE_ERROR:
    case CR_CANT_READ_CHARSET:
    case CR_NET_PACKET_TOO_LARGE:
    case CR_EMBEDDED_CONNECTION:
    case CR_PROBE_SLAVE_STATUS:
    case CR_PROBE_SLAVE_HOSTS:
    case CR_PROBE_SLAVE_CONNECT:
    case CR_PROBE_MASTER_CONNECT:
    case CR_SSL_CONNECTION_ERROR:
    case CR_MALFORMED_PACKET:
    case CR_WRONG_LICENSE:
    case CR_NULL_POINTER:
    case CR_NO_PREPARE_STMT:
    case CR_PARAMS_NOT_BOUND:
    case CR_DATA_TRUNCATED:
    case CR_NO_PARAMETERS_EXISTS:
    case CR_INVALID_PARAMETER_NO:
    case CR_INVALID_BUFFER_USE:
    case CR_UNSUPPORTED_PARAM_TYPE:
    case CR_SHARED_MEMORY_CONNECTION:
    case CR_SHARED_MEMORY_CONNECT_REQUEST_ERROR:
    case CR_SHARED_MEMORY_CONNECT_ANSWER_ERROR:
    case CR_SHARED_MEMORY_CONNECT_FILE_MAP_ERROR:
    case CR_SHARED_MEMORY_CONNECT_MAP_ERROR:
    case CR_SHARED_MEMORY_FILE_MAP_ERROR:
    case CR_SHARED_MEMORY_MAP_ERROR:
    case CR_SHARED_MEMORY_EVENT_ERROR:
    case CR_SHARED_MEMORY_CONNECT_ABANDONED_ERROR:
    case CR_SHARED_MEMORY_CONNECT_SET_ERROR:
    case CR_CONN_UNKNOW_PROTOCOL:
    case CR_INVALID_CONN_HANDLE:
    case CR_SECURE_AUTH:
    case CR_FETCH_CANCELED:
    case CR_NO_DATA:
    case CR_NO_STMT_METADATA:
#if MYSQL_VERSION_ID >= 50000
    case CR_NO_RESULT_SET:
    case CR_NOT_IMPLEMENTED:
#endif
    {
      break;
    }
    default: {
      // Hmmm
      break;
    }
  }

  flush_pool(connection);
  rb_raise(eMysqlError, error_message);
}

// Pull an option out of a querystring-formmated option list using CGI::parse
static char * get_uri_option(VALUE querystring, char * key) {
  VALUE options_hash, option_value;

  char * value = NULL;

  // Ensure that we're dealing with a string
  querystring = rb_funcall(querystring, ID_TO_S, 0);

  options_hash = rb_funcall(rb_cCGI, ID_PARSE, 1, querystring);

  // TODO: rb_hash_aref always returns an array?
  option_value = rb_ary_entry(rb_hash_aref(options_hash, RUBY_STRING(key)), 0);

  if (Qnil != option_value) {
    value = StringValuePtr(option_value);
  }

  return value;
}

static VALUE cConnection_initialize(VALUE self, VALUE uri) {
  VALUE r_host, r_user, r_password, r_path, r_options, r_port;

  char *host = "localhost", *user = "root", *password = NULL, *path;
  char *database = "", *socket = NULL;
  char *charset = NULL;

  int port = 3306;
  unsigned long client_flags = 0;
  int charset_error;

  MYSQL *db = 0, *result;
  db = (MYSQL *)mysql_init(NULL);

  rb_iv_set(self, "@using_socket", Qfalse);

  r_host = rb_funcall(uri, rb_intern("host"), 0);
  if (Qnil != r_host) {
    host = StringValuePtr(r_host);
  }

  r_user = rb_funcall(uri, rb_intern("user"), 0);
  if (Qnil != r_user) {
    user = StringValuePtr(r_user);
  }

  r_password = rb_funcall(uri, rb_intern("password"), 0);
  if (Qnil != r_password) {
    password = StringValuePtr(r_password);
  }


  r_path = rb_funcall(uri, rb_intern("path"), 0);
  path = StringValuePtr(r_path);
  if (Qnil != r_path) {
    database = strtok(path, "/");
  }

  if (NULL == database || 0 == strlen(database)) {
    rb_raise(eMysqlError, "Database must be specified");
  }

  // Pull the querystring off the URI
  r_options = rb_funcall(uri, rb_intern("query"), 0);

  // Check to see if we're on the db machine.  If so, try to use the socket
  if (0 == strcasecmp(host, "localhost")) {
    socket = get_uri_option(r_options, "socket");
    if (NULL != socket) {
      rb_iv_set(self, "@using_socket", Qtrue);
    }
  }

  r_port = rb_funcall(uri, rb_intern("port"), 0);
  if (Qnil != r_port) {
    port = NUM2INT(r_port);
  }

  charset = get_uri_option(r_options, "charset");

  // If ssl? {
  //   mysql_ssl_set(db, key, cert, ca, capath, cipher)
  // }

  my_bool reconnect = 1;
  mysql_options(db, MYSQL_OPT_RECONNECT, &reconnect);

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
    raise_mysql_error(Qnil, db, -1);
  }

  if (NULL == charset) {
    charset = (char*)calloc(5, sizeof(char));
    strcpy(charset, "utf8");
  }

  // Set the connections character set
  charset_error = mysql_set_character_set(db, charset);
  if (0 != charset_error) {
    raise_mysql_error(Qnil, db, charset_error);
  }

  rb_iv_set(self, "@uri", uri);
  rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));

  return Qtrue;
}

static VALUE cConnection_character_set(VALUE self) {
  VALUE connection_container = rb_iv_get(self, "@connection");
  MYSQL *db;

  const char *charset;

  if (Qnil == connection_container)
    return Qfalse;

  db = DATA_PTR(connection_container);

  charset = mysql_character_set_name(db);

  return RUBY_STRING(charset);
}

static VALUE cConnection_is_using_socket(VALUE self) {
  return rb_iv_get(self, "@using_socket");
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
static VALUE cCommand_set_types(VALUE self, VALUE array) {
  VALUE type_strings = rb_ary_new();
  int i;

  for (i = 0; i < RARRAY(array)->len; i++) {
    rb_ary_push(type_strings, RUBY_STRING(rb_class2name(rb_ary_entry(array, i))));
  }

  rb_iv_set(self, "@field_types", type_strings);

  return array;
}

VALUE cCommand_quote_time(VALUE self, VALUE value) {
  return rb_funcall(value, ID_STRFTIME, 1, RUBY_STRING("'%Y-%m-%d %H:%M:%S'"));
}


VALUE cCommand_quote_date_time(VALUE self, VALUE value) {
  // TODO: Support non-local dates. we need to call #new_offset on the date to be
  // quoted and pass in the current locale's date offset (self.new_offset((hours * 3600).to_r / 86400)
  return rb_funcall(value, ID_STRFTIME, 1, RUBY_STRING("'%Y-%m-%d %H:%M:%S'"));
}

VALUE cCommand_quote_date(VALUE self, VALUE value) {
  return rb_funcall(value, ID_STRFTIME, 1, RUBY_STRING("'%Y-%m-%d'"));
}

static VALUE cCommand_quote_string(VALUE self, VALUE string) {
  MYSQL *db = DATA_PTR(rb_iv_get(rb_iv_get(self, "@connection"), "@connection"));
  const char *source = StringValuePtr(string);
  char *escaped;
  VALUE result;

  int quoted_length = 0;

  // Allocate space for the escaped version of 'string'.  Use + 3 allocate space for null term.
  // and the leading and trailing single-quotes.
  // Thanks to http://www.browardphp.com/mysql_manual_en/manual_MySQL_APIs.html#mysql_real_escape_string
  escaped = (char *)calloc(strlen(source) * 3 + 3, sizeof(char));

  // Escape 'source' using the current charset in use on the conection 'db'
  quoted_length = mysql_real_escape_string(db, escaped + 1, source, strlen(source));

  // Wrap the escaped string in single-quotes, this is DO's convention
  escaped[0] = escaped[quoted_length + 1] = '\'';
  result = rb_str_new(escaped, quoted_length + 2);
  free(escaped);
  return result;
}

static VALUE build_query_from_args(VALUE klass, int count, VALUE *args) {
  VALUE query = rb_iv_get(klass, "@text");
  if ( count > 0 ) {
    int i;
    VALUE array = rb_ary_new();
    for ( i = 0; i < count; i++) {
      rb_ary_push(array, (VALUE)args[i]);
    }
    query = rb_funcall(klass, ID_ESCAPE_SQL, 1, array);
  }
  return query;
}

static MYSQL_RES* cCommand_execute_async(VALUE self, MYSQL* db, VALUE query) {
  int socket_fd;
  int retval;
  fd_set rset;
  char* str = RSTRING_PTR(query);
  int len   = RSTRING_LEN(query);

  VALUE connection = rb_iv_get(self, "@connection");

  retval = mysql_send_query(db, str, len);
  data_objects_debug(query);
  CHECK_AND_RAISE(retval);

  socket_fd = db->net.fd;

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
  CHECK_AND_RAISE(retval);

  return mysql_store_result(db);
}

static VALUE cCommand_execute_non_query(int argc, VALUE *argv, VALUE self) {
  VALUE query;

  MYSQL_RES *response = 0;

  my_ulonglong affected_rows;
  VALUE connection = rb_iv_get(self, "@connection");
  VALUE mysql_connection = rb_iv_get(connection, "@connection");
  if (Qnil == mysql_connection)
    rb_raise(eMysqlError, "This connection has already been closed.");

  MYSQL *db = DATA_PTR(mysql_connection);
  query = build_query_from_args(self, argc, argv);

  response = cCommand_execute_async(self, db, query);

  affected_rows = mysql_affected_rows(db);
  mysql_free_result(response);

  if (-1 == affected_rows)
    return Qnil;

  return rb_funcall(cResult, ID_NEW, 3, self, INT2NUM(affected_rows), INT2NUM(mysql_insert_id(db)));
}

static VALUE cCommand_execute_reader(int argc, VALUE *argv, VALUE self) {
  VALUE query, reader;
  VALUE field_names, field_types;

  int field_count;
  int i;

  char guess_default_field_types = 0;
  VALUE connection = rb_iv_get(self, "@connection");
  VALUE mysql_connection = rb_iv_get(connection, "@connection");
  if (Qnil == mysql_connection)
    rb_raise(eMysqlError, "This connection has already been closed.");

  MYSQL *db = DATA_PTR(mysql_connection);

  MYSQL_RES *response = 0;
  MYSQL_FIELD *field;

  query = build_query_from_args(self, argc, argv);

  response = cCommand_execute_async(self, db, query);

  if (!response) {
    return Qnil;
  }

  field_count = (int)mysql_field_count(db);

  reader = rb_funcall(cReader, ID_NEW, 0);
  rb_iv_set(reader, "@reader", Data_Wrap_Struct(rb_cObject, 0, 0, response));
  rb_iv_set(reader, "@opened", Qtrue);
  rb_iv_set(reader, "@field_count", INT2NUM(field_count));

  field_names = rb_ary_new();
  field_types = rb_iv_get(self, "@field_types");

  if ( field_types == Qnil || 0 == RARRAY(field_types)->len ) {
    field_types = rb_ary_new();
    guess_default_field_types = 1;
  } else if (RARRAY(field_types)->len != field_count) {
    // Whoops...  wrong number of types passed to set_types.  Close the reader and raise
    // and error
    rb_funcall(reader, rb_intern("close"), 0);
    flush_pool(connection);
    rb_raise(eMysqlError, "Field-count mismatch. Expected %d fields, but the query yielded %d", RARRAY(field_types)->len, field_count);
  }

  for(i = 0; i < field_count; i++) {
    field = mysql_fetch_field_direct(response, i);
    rb_ary_push(field_names, RUBY_STRING(field->name));

    if (1 == guess_default_field_types) {
      VALUE field_ruby_type_name = RUBY_STRING(ruby_type_from_mysql_type(field));
      rb_ary_push(field_types, field_ruby_type_name);
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

  return Qtrue;
}

// Retrieve a single row
static VALUE cReader_next(VALUE self) {
  // Get the reader from the instance variable, maybe refactor this?
  VALUE reader_container = rb_iv_get(self, "@reader");
  VALUE ruby_field_type_strings, row;

  MYSQL_RES *reader;
  MYSQL_ROW result;

  int i;
  char *field_type;

  if (Qnil == reader_container)
    return Qfalse;

  reader = DATA_PTR(reader_container);

  // The Meat
  ruby_field_type_strings = rb_iv_get(self, "@field_types");
  row = rb_ary_new();
  result = (MYSQL_ROW)mysql_fetch_row(reader);

  rb_iv_set(self, "@state", result ? Qtrue : Qfalse);

  if (!result)
    return Qnil;

  for (i = 0; i < reader->field_count; i++) {
    // The field_type data could be cached in a c-array
    field_type = RSTRING(rb_ary_entry(ruby_field_type_strings, i))->ptr;
    rb_ary_push(row, typecast(result[i], field_type));
  }

  rb_iv_set(self, "@values", row);

  return Qtrue;
}

static VALUE cReader_values(VALUE self) {
  VALUE state = rb_iv_get(self, "@state");
  if ( state == Qnil || state == Qfalse ) {
    rb_raise(eMysqlError, "Reader is not initialized");
  }
  else {
    return rb_iv_get(self, "@values");
  }
}

static VALUE cReader_fields(VALUE self) {
  return rb_iv_get(self, "@fields");
}

void Init_do_mysql_ext() {
  rb_require("rubygems");
  rb_require("bigdecimal");
  rb_require("date");
  rb_require("cgi");

  rb_funcall(rb_mKernel, rb_intern("require"), 1, RUBY_STRING("data_objects"));

  ID_TO_I = rb_intern("to_i");
  ID_TO_F = rb_intern("to_f");
  ID_TO_S = rb_intern("to_s");
  ID_PARSE = rb_intern("parse");
  ID_TO_TIME = rb_intern("to_time");
  ID_NEW = rb_intern("new");
  ID_NEW_RATIONAL = rb_intern("new!");
  ID_NEW_DATE = RUBY_VERSION_CODE < 186 ? rb_intern("new0") : rb_intern("new!");
  ID_CONST_GET = rb_intern("const_get");
  ID_UTC = rb_intern("utc");
  ID_ESCAPE_SQL = rb_intern("escape_sql");
  ID_STRFTIME = rb_intern("strftime");
  ID_LOGGER = rb_intern("logger");
  ID_DEBUG = rb_intern("debug");
  ID_LEVEL = rb_intern("level");

  // Store references to a few helpful clases that aren't in Ruby Core
  rb_cDate = RUBY_CLASS("Date");
  rb_cDateTime = RUBY_CLASS("DateTime");
  rb_cRational = RUBY_CLASS("Rational");
  rb_cBigDecimal = RUBY_CLASS("BigDecimal");
  rb_cCGI = RUBY_CLASS("CGI");

  // Get references to the DataObjects module and its classes
  mDO = CONST_GET(rb_mKernel, "DataObjects");
  cDO_Quoting = CONST_GET(mDO, "Quoting");
  cDO_Connection = CONST_GET(mDO, "Connection");
  cDO_Command = CONST_GET(mDO, "Command");
  cDO_Result = CONST_GET(mDO, "Result");
  cDO_Reader = CONST_GET(mDO, "Reader");

  // Top Level Module that all the classes live under
  mDOMysql = rb_define_module_under(mDO, "Mysql");

  eMysqlError = rb_define_class("MysqlError", rb_eStandardError);

  cConnection = DRIVER_CLASS("Connection", cDO_Connection);
  rb_define_method(cConnection, "initialize", cConnection_initialize, 1);
  rb_define_method(cConnection, "using_socket?", cConnection_is_using_socket, 0);
  rb_define_method(cConnection, "character_set", cConnection_character_set , 0);
  rb_define_method(cConnection, "dispose", cConnection_dispose, 0);

  cCommand = DRIVER_CLASS("Command", cDO_Command);
  rb_include_module(cCommand, cDO_Quoting);
  rb_define_method(cCommand, "set_types", cCommand_set_types, 1);
  rb_define_method(cCommand, "execute_non_query", cCommand_execute_non_query, -1);
  rb_define_method(cCommand, "execute_reader", cCommand_execute_reader, -1);
  rb_define_method(cCommand, "quote_string", cCommand_quote_string, 1);
  rb_define_method(cCommand, "quote_date", cCommand_quote_date, 1);
  rb_define_method(cCommand, "quote_time", cCommand_quote_time, 1);
  rb_define_method(cCommand, "quote_datetime", cCommand_quote_date_time, 1);

  // Non-Query result
  cResult = DRIVER_CLASS("Result", cDO_Result);

  // Query result
  cReader = DRIVER_CLASS("Reader", cDO_Reader);
  rb_define_method(cReader, "close", cReader_close, 0);
  rb_define_method(cReader, "next!", cReader_next, 0);
  rb_define_method(cReader, "values", cReader_values, 0);
  rb_define_method(cReader, "fields", cReader_fields, 0);
}
