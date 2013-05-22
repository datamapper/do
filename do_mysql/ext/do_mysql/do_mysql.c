#include <ruby.h>
#include <time.h>
#include <string.h>

#include <mysql.h>
#include <errmsg.h>
#include <mysqld_error.h>

#include "mysql_compat.h"
#include "compat.h"

#include "error.h"
#include "do_common.h"

#ifndef HAVE_CONST_MYSQL_TYPE_STRING
#define HAVE_OLD_MYSQL_VERSION
#endif

#ifdef _WIN32
#define do_mysql_cCommand_execute do_mysql_cCommand_execute_sync
#else
#define do_mysql_cCommand_execute do_mysql_cCommand_execute_async
#endif

#define CHECK_AND_RAISE(mysql_result_value, query) if (0 != mysql_result_value) { do_mysql_raise_error(self, db, query); }

void do_mysql_full_connect(VALUE self, MYSQL *db);

// Classes that we'll build in Init
VALUE mDO_Mysql;
VALUE mDO_MysqlEncoding;
VALUE cDO_MysqlConnection;
VALUE cDO_MysqlCommand;
VALUE cDO_MysqlResult;
VALUE cDO_MysqlReader;

// Figures out what we should cast a given mysql field type to
VALUE do_mysql_infer_ruby_type(const MYSQL_FIELD *field) {
  switch (field->type) {
    case MYSQL_TYPE_NULL:
      return Qnil;
    case MYSQL_TYPE_TINY:
      return rb_cTrueClass;
#ifdef HAVE_CONST_MYSQL_TYPE_BIT
    case MYSQL_TYPE_BIT:
#endif
    case MYSQL_TYPE_SHORT:
    case MYSQL_TYPE_LONG:
    case MYSQL_TYPE_INT24:
    case MYSQL_TYPE_LONGLONG:
    case MYSQL_TYPE_YEAR:
      return rb_cInteger;
#ifdef HAVE_CONST_MYSQL_TYPE_NEWDECIMAL
    case MYSQL_TYPE_NEWDECIMAL:
#endif
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
    case MYSQL_TYPE_STRING:
    case MYSQL_TYPE_VAR_STRING:
    case MYSQL_TYPE_TINY_BLOB:
    case MYSQL_TYPE_MEDIUM_BLOB:
    case MYSQL_TYPE_LONG_BLOB:
    case MYSQL_TYPE_BLOB:
#ifdef HAVE_ST_CHARSETNR
      if (field->charsetnr == 63) {
        return rb_cByteArray;
      }
      else {
        return rb_cString;
      }
#else
      // We assume a string here if we don't have a specific charset
      return rb_cString;
#endif
    default:
      return rb_cString;
  }
}

// Convert C-string to a Ruby instance of Ruby type "type"
VALUE do_mysql_typecast(const char *value, long length, const VALUE type, int encoding) {
  if (!value) {
    return Qnil;
  }

  if (type == rb_cTrueClass) {
    return (value == 0 || strcmp("0", value) == 0) ? Qfalse : Qtrue;
  }
  else if (type == rb_cByteArray) {
    return rb_funcall(rb_cByteArray, DO_ID_NEW, 1, rb_str_new(value, length));
  }
  else {
    return data_objects_typecast(value, length, type, encoding);
  }
}

void do_mysql_raise_error(VALUE self, MYSQL *db, VALUE query) {
  int errnum = mysql_errno(db);
  const char *message = mysql_error(db);
  VALUE sql_state = Qnil;

#ifdef HAVE_MYSQL_SQLSTATE
  sql_state = rb_str_new2(mysql_sqlstate(db));
#endif

  data_objects_raise_error(self, do_mysql_errors, errnum, message, query, sql_state);
}

#ifdef _WIN32
MYSQL_RES *do_mysql_cCommand_execute_sync(VALUE self, VALUE connection, MYSQL *db, VALUE query) {
  int retval;
  struct timeval start;
  const char *str = rb_str_ptr_readonly(query);
  long len = rb_str_len(query);

  if (mysql_ping(db) && mysql_errno(db) == CR_SERVER_GONE_ERROR) {
    // Ok, we do one more try here by doing a full connect
    VALUE connection = rb_iv_get(self, "@connection");
    do_mysql_full_connect(connection, db);
  }

  gettimeofday(&start, NULL);
  retval = mysql_real_query(db, str, len);
  data_objects_debug(connection, query, &start);

  CHECK_AND_RAISE(retval, query);

  return mysql_store_result(db);
}
#else
MYSQL_RES *do_mysql_cCommand_execute_async(VALUE self, VALUE connection, MYSQL *db, VALUE query) {
  int retval;

  if ((retval = mysql_ping(db)) && mysql_errno(db) == CR_SERVER_GONE_ERROR) {
    do_mysql_full_connect(connection, db);
  }

  struct timeval start;
  const char *str = rb_str_ptr_readonly(query);
  long len = rb_str_len(query);

  gettimeofday(&start, NULL);
  retval = mysql_send_query(db, str, len);

  CHECK_AND_RAISE(retval, query);

  int socket_fd = db->net.fd;
  fd_set rset;

  while (1) {
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
  data_objects_debug(connection, query, &start);

  MYSQL_RES *result = mysql_store_result(db);

  if (!result) {
    CHECK_AND_RAISE(mysql_errno(db), query);
  }

  return result;
}
#endif

void do_mysql_full_connect(VALUE self, MYSQL *db) {
  VALUE r_host = rb_iv_get(self, "@host");
  const char *host = "localhost";

  if (r_host != Qnil) {
    host = StringValuePtr(r_host);
  }

  VALUE r_user = rb_iv_get(self, "@user");
  const char *user = "root";

  if (r_user != Qnil) {
    user = StringValuePtr(r_user);
  }

  VALUE r_password = rb_iv_get(self, "@password");
  char *password = NULL;

  if (r_password != Qnil) {
    password = StringValuePtr(r_password);
  }

  VALUE r_port = rb_iv_get(self, "@port");
  int port = 3306;

  if (r_port != Qnil) {
    port = NUM2INT(r_port);
  }

  VALUE r_path = rb_iv_get(self, "@path");
  char *path = NULL;
  char *database = NULL;

  if (r_path != Qnil) {
    path = StringValuePtr(r_path);
    database = strtok(path, "/"); // not threadsafe
  }

  if (!database || !*database) {
    database = NULL;
  }

  VALUE r_query = rb_iv_get(self, "@query");
  char *socket = NULL;

  // Check to see if we're on the db machine.  If so, try to use the socket
  if (strcasecmp(host, "localhost") == 0) {
    socket = data_objects_get_uri_option(r_query, "socket");

    if (socket) {
      rb_iv_set(self, "@using_socket", Qtrue);
    }
  }

#ifdef HAVE_MYSQL_SSL_SET
  char *ssl_client_key, *ssl_client_cert, *ssl_ca_cert, *ssl_ca_path, *ssl_cipher;
  VALUE r_ssl;

  if (rb_obj_is_kind_of(r_query, rb_cHash)) {
    r_ssl = rb_hash_aref(r_query, rb_str_new2("ssl"));

    if (rb_obj_is_kind_of(r_ssl, rb_cHash)) {
      ssl_client_key  = data_objects_get_uri_option(r_ssl, "client_key");
      ssl_client_cert = data_objects_get_uri_option(r_ssl, "client_cert");
      ssl_ca_cert     = data_objects_get_uri_option(r_ssl, "ca_cert");
      ssl_ca_path     = data_objects_get_uri_option(r_ssl, "ca_path");
      ssl_cipher      = data_objects_get_uri_option(r_ssl, "cipher");

      data_objects_assert_file_exists(ssl_client_key,  "client_key doesn't exist");
      data_objects_assert_file_exists(ssl_client_cert, "client_cert doesn't exist");
      data_objects_assert_file_exists(ssl_ca_cert,     "ca_cert doesn't exist");

      mysql_ssl_set(db, ssl_client_key, ssl_client_cert, ssl_ca_cert, ssl_ca_path, ssl_cipher);
    }
    else if (r_ssl != Qnil) {
      rb_raise(rb_eArgError, "ssl must be passed a hash");
    }
  }
#endif

  unsigned long client_flags = 0;

  MYSQL *result = mysql_real_connect(
    db,
    host,
    user,
    password,
    database,
    port,
    socket,
    client_flags
  );

  if (!result) {
    do_mysql_raise_error(self, db, Qnil);
  }

#ifdef HAVE_MYSQL_GET_SSL_CIPHER
  const char *ssl_cipher_used = mysql_get_ssl_cipher(db);

  if (ssl_cipher_used) {
    rb_iv_set(self, "@ssl_cipher", rb_str_new2(ssl_cipher_used));
  }
#endif

#ifdef MYSQL_OPT_RECONNECT
  my_bool reconnect = 1;
  mysql_options(db, MYSQL_OPT_RECONNECT, &reconnect);
#endif

  // We only support encoding for MySQL versions providing mysql_set_character_set.
  // Without this function there are potential issues with mysql_real_escape_string
  // since that doesn't take the character set into consideration when setting it
  // using a SET CHARACTER SET query. Since we don't want to stimulate these possible
  // issues we simply ignore it and assume the user has configured this correctly.

#ifdef HAVE_MYSQL_SET_CHARACTER_SET
  // Set the connections character set
  VALUE encoding = rb_iv_get(self, "@encoding");
  VALUE my_encoding = rb_hash_aref(data_objects_const_get(mDO_MysqlEncoding, "MAP"), encoding);

  if (my_encoding != Qnil) {
    int encoding_error = mysql_set_character_set(db, rb_str_ptr_readonly(my_encoding));

    if (encoding_error != 0) {
      do_mysql_raise_error(self, db, Qnil);
    }
    else {
#ifdef HAVE_RUBY_ENCODING_H
      rb_iv_set(self, "@encoding_id", INT2FIX(rb_enc_find_index(rb_str_ptr_readonly(encoding))));
#endif

      rb_iv_set(self, "@my_encoding", my_encoding);
    }
  }
  else {
    rb_warn("Encoding %s is not a known Ruby encoding for MySQL\n", rb_str_ptr_readonly(encoding));
    rb_iv_set(self, "@encoding", rb_str_new2("UTF-8"));
#ifdef HAVE_RUBY_ENCODING_H
    rb_iv_set(self, "@encoding_id", INT2FIX(rb_enc_find_index("UTF-8")));
#endif
    rb_iv_set(self, "@my_encoding", rb_str_new2("utf8"));
  }
#endif

  // Disable sql_auto_is_null
  do_mysql_cCommand_execute(Qnil, self, db, rb_str_new2("SET sql_auto_is_null = 0"));
  // removed NO_AUTO_VALUE_ON_ZERO because of MySQL bug http://bugs.mysql.com/bug.php?id=42270
  // added NO_BACKSLASH_ESCAPES so that backslashes should not be escaped as in other databases

// For really anscient MySQL versions we don't attempt any strictness
#ifdef HAVE_MYSQL_GET_SERVER_VERSION
  //4.0 does not support sql_mode at all, while later 4.x versions do not support certain session parameters
  if (mysql_get_server_version(db) >= 50000) {
    do_mysql_cCommand_execute(Qnil, self, db, rb_str_new2("SET SESSION sql_mode = 'ANSI,NO_BACKSLASH_ESCAPES,NO_DIR_IN_CREATE,NO_ENGINE_SUBSTITUTION,NO_UNSIGNED_SUBTRACTION,TRADITIONAL'"));
  }
  else if (mysql_get_server_version(db) >= 40100) {
    do_mysql_cCommand_execute(Qnil, self, db, rb_str_new2("SET SESSION sql_mode = 'ANSI,NO_DIR_IN_CREATE,NO_UNSIGNED_SUBTRACTION'"));
  }
#endif

  rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));
}

VALUE do_mysql_cConnection_initialize(VALUE self, VALUE uri) {
  rb_iv_set(self, "@using_socket", Qfalse);
  rb_iv_set(self, "@ssl_cipher", Qnil);

  VALUE r_host = rb_funcall(uri, rb_intern("host"), 0);

  if (r_host != Qnil) {
    rb_iv_set(self, "@host", r_host);
  }

  VALUE r_user = rb_funcall(uri, rb_intern("user"), 0);

  if (r_user != Qnil) {
    rb_iv_set(self, "@user", r_user);
  }

  VALUE r_password = rb_funcall(uri, rb_intern("password"), 0);

  if (r_password != Qnil) {
    rb_iv_set(self, "@password", r_password);
  }

  VALUE r_path = rb_funcall(uri, rb_intern("path"), 0);

  if (r_path != Qnil) {
    rb_iv_set(self, "@path", r_path);
  }

  VALUE r_port = rb_funcall(uri, rb_intern("port"), 0);

  if (r_port != Qnil) {
    rb_iv_set(self, "@port", r_port);
  }

  // Pull the querystring off the URI
  VALUE r_query = rb_funcall(uri, rb_intern("query"), 0);

  rb_iv_set(self, "@query", r_query);

  const char *encoding = data_objects_get_uri_option(r_query, "encoding");

  if (!encoding) {
    encoding = data_objects_get_uri_option(r_query, "charset");

    if (!encoding) { encoding = "UTF-8"; }
  }

  rb_iv_set(self, "@encoding", rb_str_new2(encoding));

  MYSQL *db = mysql_init(NULL);

  do_mysql_full_connect(self, db);
  rb_iv_set(self, "@uri", uri);
  return Qtrue;
}

VALUE do_mysql_cConnection_dispose(VALUE self) {
  VALUE connection_container = rb_iv_get(self, "@connection");

  MYSQL *db;

  if (connection_container == Qnil) {
    return Qfalse;
  }

  db = DATA_PTR(connection_container);

  if (!db) {
    return Qfalse;
  }

  mysql_close(db);
  rb_iv_set(self, "@connection", Qnil);
  return Qtrue;
}

VALUE do_mysql_cConnection_quote_string(VALUE self, VALUE string) {

  MYSQL *db = DATA_PTR(rb_iv_get(self, "@connection"));
  const char *source = rb_str_ptr_readonly(string);
  long source_len = rb_str_len(string);
  long buffer_len = source_len * 2 + 3;

  // Overflow check
  if(buffer_len <= source_len) {
    rb_raise(rb_eArgError, "Input string is too large to be safely quoted");
  }

  // Allocate space for the escaped version of 'string'.  Use + 3 allocate space for null term.
  // and the leading and trailing single-quotes.
  // Thanks to http://www.browardphp.com/mysql_manual_en/manual_MySQL_APIs.html#mysql_real_escape_string
  char *escaped = calloc(buffer_len, sizeof(char));

  if (!escaped) {
    rb_memerror();
  }

  unsigned long quoted_length;
  VALUE result;

  // Escape 'source' using the current encoding in use on the conection 'db'
  quoted_length = mysql_real_escape_string(db, escaped + 1, source, source_len);

  // Wrap the escaped string in single-quotes, this is DO's convention
  escaped[0] = escaped[quoted_length + 1] = '\'';
  // We don't want to use the internal encoding, because this needs
  // to go into the database in the connection encoding

  result = DATA_OBJECTS_STR_NEW(escaped, quoted_length + 2, FIX2INT(rb_iv_get(self, "@encoding_id")), NULL);

  free(escaped);

  return result;
}

VALUE do_mysql_cCommand_execute_non_query(int argc, VALUE *argv, VALUE self) {
  VALUE connection = rb_iv_get(self, "@connection");
  VALUE mysql_connection = rb_iv_get(connection, "@connection");

  if (mysql_connection == Qnil) {
    rb_raise(eDO_ConnectionError, "This connection has already been closed.");
  }

  MYSQL *db = DATA_PTR(mysql_connection);
  VALUE query = data_objects_build_query_from_args(self, argc, argv);
  MYSQL_RES *response = do_mysql_cCommand_execute(self, connection, db, query);

  my_ulonglong affected_rows = mysql_affected_rows(db);
  my_ulonglong insert_id = mysql_insert_id(db);

  mysql_free_result(response);

  if (((my_ulonglong)-1) == affected_rows) {
    return Qnil;
  }

  return rb_funcall(cDO_MysqlResult, DO_ID_NEW, 3, self, INT2NUM(affected_rows), insert_id == 0 ? Qnil : ULL2NUM(insert_id));
}

VALUE do_mysql_cCommand_execute_reader(int argc, VALUE *argv, VALUE self) {
  VALUE connection = rb_iv_get(self, "@connection");
  VALUE mysql_connection = rb_iv_get(connection, "@connection");

  if (mysql_connection == Qnil) {
    rb_raise(eDO_ConnectionError, "This result set has already been closed.");
  }

  VALUE query = data_objects_build_query_from_args(self, argc, argv);
  MYSQL *db = DATA_PTR(mysql_connection);
  MYSQL_RES *response = do_mysql_cCommand_execute(self, connection, db, query);

  unsigned int field_count = mysql_field_count(db);
  VALUE reader = rb_funcall(cDO_MysqlReader, DO_ID_NEW, 0);

  rb_iv_set(reader, "@connection", connection);
  rb_iv_set(reader, "@reader", Data_Wrap_Struct(rb_cObject, 0, 0, response));
  rb_iv_set(reader, "@opened", Qfalse);
  rb_iv_set(reader, "@field_count", INT2NUM(field_count));

  VALUE field_names = rb_ary_new();
  VALUE field_types = rb_iv_get(self, "@field_types");

  char guess_default_field_types = 0;

  if (field_types == Qnil || RARRAY_LEN(field_types) == 0) {
    field_types = rb_ary_new();
    guess_default_field_types = 1;
  }
  else if (RARRAY_LEN(field_types) != field_count) {
    // Whoops... wrong number of types passed to set_types. Close the reader and raise
    // and error
    rb_funcall(reader, rb_intern("close"), 0);
    rb_raise(rb_eArgError, "Field-count mismatch. Expected %ld fields, but the query yielded %d", RARRAY_LEN(field_types), field_count);
  }

  MYSQL_FIELD *field;
  unsigned int i;

  for(i = 0; i < field_count; i++) {
    field = mysql_fetch_field_direct(response, i);
    rb_ary_push(field_names, rb_str_new2(field->name));

    if (guess_default_field_types == 1) {
      rb_ary_push(field_types, do_mysql_infer_ruby_type(field));
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
VALUE do_mysql_cReader_close(VALUE self) {
  // Get the reader from the instance variable, maybe refactor this?
  VALUE reader_container = rb_iv_get(self, "@reader");

  if (reader_container == Qnil) {
    return Qfalse;
  }

  MYSQL_RES *reader = DATA_PTR(reader_container);

  // The Meat
  if (!reader) {
    return Qfalse;
  }

  mysql_free_result(reader);
  rb_iv_set(self, "@reader", Qnil);
  rb_iv_set(self, "@opened", Qfalse);
  return Qtrue;
}

// Retrieve a single row
VALUE do_mysql_cReader_next(VALUE self) {
  // Get the reader from the instance variable, maybe refactor this?
  VALUE reader_container = rb_iv_get(self, "@reader");

  if (reader_container == Qnil) {
    return Qfalse;
  }

  MYSQL_RES *reader = DATA_PTR(reader_container);
  if(!reader) {
    return Qfalse;
  }
  MYSQL_ROW result = mysql_fetch_row(reader);

  // The Meat
  VALUE field_types = rb_iv_get(self, "@field_types");
  VALUE row = rb_ary_new();
  unsigned long *lengths = mysql_fetch_lengths(reader);

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

  VALUE field_type;
  unsigned int i;

  for (i = 0; i < reader->field_count; i++) {
    // The field_type data could be cached in a c-array
    field_type = rb_ary_entry(field_types, i);
    rb_ary_push(row, do_mysql_typecast(result[i], lengths[i], field_type, enc));
  }

  rb_iv_set(self, "@values", row);
  return Qtrue;
}

void Init_do_mysql() {
  data_objects_common_init();

  // Top Level Module that all the classes live under
  mDO_Mysql    = rb_define_module_under(mDO, "Mysql");
  mDO_MysqlEncoding = rb_define_module_under(mDO_Mysql, "Encoding");

  cDO_MysqlConnection = rb_define_class_under(mDO_Mysql, "Connection", cDO_Connection);
  rb_define_method(cDO_MysqlConnection, "initialize", do_mysql_cConnection_initialize, 1);
  rb_define_method(cDO_MysqlConnection, "using_socket?", data_objects_cConnection_is_using_socket, 0);
  rb_define_method(cDO_MysqlConnection, "ssl_cipher", data_objects_cConnection_ssl_cipher, 0);
  rb_define_method(cDO_MysqlConnection, "character_set", data_objects_cConnection_character_set , 0);
  rb_define_method(cDO_MysqlConnection, "dispose", do_mysql_cConnection_dispose, 0);
  rb_define_method(cDO_MysqlConnection, "quote_string", do_mysql_cConnection_quote_string, 1);
  rb_define_method(cDO_MysqlConnection, "quote_date", data_objects_cConnection_quote_date, 1);
  rb_define_method(cDO_MysqlConnection, "quote_time", data_objects_cConnection_quote_time, 1);
  rb_define_method(cDO_MysqlConnection, "quote_datetime", data_objects_cConnection_quote_date_time, 1);

  cDO_MysqlCommand = rb_define_class_under(mDO_Mysql, "Command", cDO_Command);
  rb_define_method(cDO_MysqlCommand, "set_types", data_objects_cCommand_set_types, -1);
  rb_define_method(cDO_MysqlCommand, "execute_non_query", do_mysql_cCommand_execute_non_query, -1);
  rb_define_method(cDO_MysqlCommand, "execute_reader", do_mysql_cCommand_execute_reader, -1);

  // Non-Query result
  cDO_MysqlResult = rb_define_class_under(mDO_Mysql, "Result", cDO_Result);

  // Query result
  cDO_MysqlReader = rb_define_class_under(mDO_Mysql, "Reader", cDO_Reader);
  rb_define_method(cDO_MysqlReader, "close", do_mysql_cReader_close, 0);
  rb_define_method(cDO_MysqlReader, "next!", do_mysql_cReader_next, 0);
  rb_define_method(cDO_MysqlReader, "values", data_objects_cReader_values, 0);
  rb_define_method(cDO_MysqlReader, "fields", data_objects_cReader_fields, 0);
  rb_define_method(cDO_MysqlReader, "field_count", data_objects_cReader_field_count, 0);

  rb_global_variable(&cDO_MysqlResult);
  rb_global_variable(&cDO_MysqlReader);

  data_objects_define_errors(mDO_Mysql, do_mysql_errors);
}
