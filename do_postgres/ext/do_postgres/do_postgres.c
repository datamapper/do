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
#endif

#ifdef _WIN32
#define do_postgres_cCommand_execute do_postgres_cCommand_execute_sync
#else
#define do_postgres_cCommand_execute do_postgres_cCommand_execute_async
#endif


#ifndef HAVE_RB_THREAD_FD_SELECT
#define rb_fdset_t fd_set
#define rb_fd_isset(n, f) FD_ISSET(n, f)
#define rb_fd_init(f) FD_ZERO(f)
#define rb_fd_zero(f)  FD_ZERO(f)
#define rb_fd_set(n, f)  FD_SET(n, f)
#define rb_fd_clr(n, f) FD_CLR(n, f)
#define rb_fd_term(f)
#define rb_thread_fd_select rb_thread_select
#endif


#include <ruby.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <time.h>
#ifndef _WIN32
#include <sys/time.h>
#endif
#include "error.h"
#include "compat.h"

#include "do_common.h"

VALUE mDO_Postgres;
VALUE mDO_PostgresEncoding;
VALUE cDO_PostgresConnection;
VALUE cDO_PostgresCommand;
VALUE cDO_PostgresResult;
VALUE cDO_PostgresReader;

void do_postgres_full_connect(VALUE self, PGconn *db);

/* ===== Typecasting Functions ===== */

VALUE do_postgres_infer_ruby_type(Oid type) {
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

VALUE do_postgres_typecast(const char *value, long length, const VALUE type, int encoding) {
  if (type == rb_cTrueClass) {
    return *value == 't' ? Qtrue : Qfalse;
  }
  else if (type == rb_cByteArray) {
    size_t new_length = 0;
    char *unescaped = (char *)PQunescapeBytea((unsigned char*)value, &new_length);
    VALUE byte_array = rb_funcall(rb_cByteArray, DO_ID_NEW, 1, rb_str_new(unescaped, new_length));

    PQfreemem(unescaped);
    return byte_array;
  }
  else {
    return data_objects_typecast(value, length, type, encoding);
  }
}

void do_postgres_raise_error(VALUE self, PGresult *result, VALUE query) {
  VALUE message = rb_str_new2(PQresultErrorMessage(result));
  char *sql_state = PQresultErrorField(result, PG_DIAG_SQLSTATE);
  int postgres_errno = MAKE_SQLSTATE(sql_state[0], sql_state[1], sql_state[2], sql_state[3], sql_state[4]);
  VALUE str = rb_str_new2(sql_state);

  PQclear(result);

  data_objects_raise_error(self, do_postgres_errors, postgres_errno, message, query, str);
}

/* ====== Public API ======= */

VALUE do_postgres_cConnection_dispose(VALUE self) {
  VALUE connection_container = rb_iv_get(self, "@connection");

  if (connection_container == Qnil) {
    return Qfalse;
  }

  PGconn *db = DATA_PTR(connection_container);

  if (!db) {
    return Qfalse;
  }

  PQfinish(db);
  rb_iv_set(self, "@connection", Qnil);
  return Qtrue;
}

VALUE do_postgres_cConnection_quote_string(VALUE self, VALUE string) {
  PGconn *db = DATA_PTR(rb_iv_get(self, "@connection"));
  const char *source = rb_str_ptr_readonly(string);
  int error = 0;
  long source_len  = rb_str_len(string);
  long buffer_len  = source_len * 2 + 3;

  // Overflow check
  if(buffer_len <= source_len) {
    rb_raise(rb_eArgError, "Input string is too large to be safely quoted");
  }

  char *escaped;

  // Allocate space for the escaped version of 'string'
  // http://www.postgresql.org/docs/8.3/static/libpq-exec.html#LIBPQ-EXEC-ESCAPE-STRING
  if (!(escaped = calloc(buffer_len, sizeof(char)))) {
    rb_memerror();
  }

  long quoted_length;
  VALUE result;

  // Escape 'source' using the current charset in use on the conection 'db'
  quoted_length = PQescapeStringConn(db, escaped + 1, source, source_len, &error);

  if(error) {
    rb_raise(eDO_DataError, "%s", PQerrorMessage(db));
  }

  // Wrap the escaped string in single-quotes, this is DO's convention
  escaped[0] = escaped[quoted_length + 1] = '\'';

  result = DATA_OBJECTS_STR_NEW(escaped, quoted_length + 2, FIX2INT(rb_iv_get(self, "@encoding_id")), NULL);

  free(escaped);
  return result;
}

VALUE do_postgres_cConnection_quote_byte_array(VALUE self, VALUE string) {
  PGconn *db = DATA_PTR(rb_iv_get(self, "@connection"));
  const unsigned char *source = (unsigned char *)rb_str_ptr_readonly(string);
  size_t source_len = rb_str_len(string);

  unsigned char *escaped;
  unsigned char *escaped_quotes;
  size_t quoted_length = 0;
  VALUE result;

  // Allocate space for the escaped version of 'string'
  // http://www.postgresql.org/docs/8.3/static/libpq-exec.html#LIBPQ-EXEC-ESCAPE-STRING
  escaped = PQescapeByteaConn(db, source, source_len, &quoted_length);

  if(!escaped) {
    rb_memerror();
  }

  if (!(escaped_quotes = calloc(quoted_length + 1, sizeof(unsigned char)))) {
    rb_memerror();
  }

  memcpy(escaped_quotes + 1, escaped, quoted_length * sizeof(unsigned char));

  // Wrap the escaped string in single-quotes, this is DO's convention (replace trailing \0)
  escaped_quotes[0] = escaped_quotes[quoted_length] = '\'';

  result = rb_str_new((const char *)escaped_quotes, quoted_length + 1);
  PQfreemem(escaped);
  free(escaped_quotes);
  return result;
}

#ifdef _WIN32
PGresult * do_postgres_cCommand_execute_sync(VALUE self, VALUE connection, PGconn *db, VALUE query) {
  char *str = StringValuePtr(query);
  PGresult *response;

  while ((response = PQgetResult(db))) {
    PQclear(response);
  }

  struct timeval start;

  gettimeofday(&start, NULL);
  response = PQexec(db, str);

  if (!response) {
    if (PQstatus(db) != CONNECTION_OK) {
      PQreset(db);

      if (PQstatus(db) == CONNECTION_OK) {
        response = PQexec(db, str);
      }
      else {
        do_postgres_full_connect(connection, db);
        response = PQexec(db, str);
      }
    }

    if(!response) {
      rb_raise(eDO_ConnectionError, PQerrorMessage(db));
    }
  }

  data_objects_debug(connection, query, &start);
  return response;
}
#else
PGresult * do_postgres_cCommand_execute_async(VALUE self, VALUE connection, PGconn *db, VALUE query) {
  PGresult *response;
  char* str = StringValuePtr(query);

  while ((response = PQgetResult(db))) {
    PQclear(response);
  }

  struct timeval start;
  int retval;

  gettimeofday(&start, NULL);
  retval = PQsendQuery(db, str);

  if (!retval) {
    if (PQstatus(db) != CONNECTION_OK) {
      PQreset(db);

      if (PQstatus(db) == CONNECTION_OK) {
        retval = PQsendQuery(db, str);
      }
      else {
        do_postgres_full_connect(connection, db);
        retval = PQsendQuery(db, str);
      }
    }

    if (!retval) {
      rb_raise(eDO_ConnectionError, "%s", PQerrorMessage(db));
    }
  }

  int socket_fd = PQsocket(db);
  rb_fdset_t rset;
  rb_fd_init(&rset);
  rb_fd_set(socket_fd, &rset);

  while (1) {
    retval = rb_thread_fd_select(socket_fd + 1, &rset, NULL, NULL, NULL);

    if (retval < 0) {
      rb_fd_term(&rset);
      rb_sys_fail(0);
    }

    if (retval == 0) {
      continue;
    }

    if (PQconsumeInput(db) == 0) {
      rb_fd_term(&rset);
      rb_raise(eDO_ConnectionError, "%s", PQerrorMessage(db));
    }

    if (PQisBusy(db) == 0) {
      break;
    }
  }

  rb_fd_term(&rset);
  data_objects_debug(connection, query, &start);
  return PQgetResult(db);
}
#endif

VALUE do_postgres_cConnection_initialize(VALUE self, VALUE uri) {
  rb_iv_set(self, "@using_socket", Qfalse);

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
    r_port = rb_funcall(r_port, rb_intern("to_s"), 0);
    rb_iv_set(self, "@port", r_port);
  }

  // Pull the querystring off the URI
  VALUE r_query = rb_funcall(uri, rb_intern("query"), 0);

  rb_iv_set(self, "@query", r_query);

  const char *encoding = data_objects_get_uri_option(r_query, "encoding");

  if (!encoding) {
    encoding = data_objects_get_uri_option(r_query, "charset");

    if (!encoding) {
      encoding = "UTF-8";
    }
  }

  rb_iv_set(self, "@encoding", rb_str_new2(encoding));

  PGconn *db = NULL;

  do_postgres_full_connect(self, db);
  rb_iv_set(self, "@uri", uri);
  return Qtrue;
}

void do_postgres_full_connect(VALUE self, PGconn *db) {
  VALUE r_host;
  char *host = NULL;

  if ((r_host = rb_iv_get(self, "@host")) != Qnil) {
    host = StringValuePtr(r_host);
  }

  VALUE r_user;
  char *user = NULL;

  if ((r_user = rb_iv_get(self, "@user")) != Qnil) {
    user = StringValuePtr(r_user);
  }

  VALUE r_password;
  char *password = NULL;

  if ((r_password = rb_iv_get(self, "@password")) != Qnil) {
    password = StringValuePtr(r_password);
  }

  VALUE r_port;
  const char *port = "5432";

  if ((r_port = rb_iv_get(self, "@port")) != Qnil) {
    port = StringValuePtr(r_port);
  }

  VALUE r_path;
  char *path = NULL;
  char *database = NULL;

  if ((r_path = rb_iv_get(self, "@path")) != Qnil) {
    path = StringValuePtr(r_path);
    database = strtok(path, "/");
  }

  if (!database || !*database) {
    database = NULL;
  }

  VALUE r_query = rb_iv_get(self, "@query");
  const char *search_path = data_objects_get_uri_option(r_query, "search_path");

  db = PQsetdbLogin(
    host,
    port,
    NULL,
    NULL,
    database,
    user,
    password
  );

  if (PQstatus(db) == CONNECTION_BAD) {
    rb_raise(eDO_ConnectionError, "%s", PQerrorMessage(db));
  }

  PGresult *result;

  if (search_path) {
    char *search_path_query;

    if (!(search_path_query = calloc(256, sizeof(char)))) {
      rb_memerror();
    }

    snprintf(search_path_query, 256, "set search_path to %s;", search_path);

    r_query = rb_str_new2(search_path_query);
    result = do_postgres_cCommand_execute(Qnil, self, db, r_query);

    if (PQresultStatus(result) != PGRES_COMMAND_OK) {
      free(search_path_query);
      do_postgres_raise_error(self, result, r_query);
    }

    free(search_path_query);
  }

  const char *backslash_off = "SET backslash_quote = off";
  const char *standard_strings_on = "SET standard_conforming_strings = on";
  const char *warning_messages = "SET client_min_messages = warning";
  const char *date_format = "SET datestyle = ISO";
  VALUE r_options;

  r_options = rb_str_new2(backslash_off);
  result = do_postgres_cCommand_execute(Qnil, self, db, r_options);

  if (PQresultStatus(result) != PGRES_COMMAND_OK) {
    rb_warn("%s", PQresultErrorMessage(result));
  }

  r_options = rb_str_new2(standard_strings_on);
  result = do_postgres_cCommand_execute(Qnil, self, db, r_options);

  if (PQresultStatus(result) != PGRES_COMMAND_OK) {
    rb_warn("%s", PQresultErrorMessage(result));
  }

  r_options = rb_str_new2(warning_messages);
  result = do_postgres_cCommand_execute(Qnil, self, db, r_options);

  if (PQresultStatus(result) != PGRES_COMMAND_OK) {
    rb_warn("%s", PQresultErrorMessage(result));
  }

  r_options = rb_str_new2(date_format);
  result = do_postgres_cCommand_execute(Qnil, self, db, r_options);

  if (PQresultStatus(result) != PGRES_COMMAND_OK) {
    rb_warn("%s", PQresultErrorMessage(result));
  }

  VALUE encoding = rb_iv_get(self, "@encoding");
#ifdef HAVE_PQSETCLIENTENCODING
  VALUE pg_encoding = rb_hash_aref(data_objects_const_get(mDO_PostgresEncoding, "MAP"), encoding);

  if (pg_encoding != Qnil) {
    if (PQsetClientEncoding(db, rb_str_ptr_readonly(pg_encoding))) {
      rb_raise(eDO_ConnectionError, "Couldn't set encoding: %s", rb_str_ptr_readonly(encoding));
    }
    else {
#ifdef HAVE_RUBY_ENCODING_H
      rb_iv_set(self, "@encoding_id", INT2FIX(rb_enc_find_index(rb_str_ptr_readonly(encoding))));
#endif
      rb_iv_set(self, "@pg_encoding", pg_encoding);
    }
  }
  else {
    rb_warn("Encoding %s is not a known Ruby encoding for PostgreSQL\n", rb_str_ptr_readonly(encoding));

    rb_iv_set(self, "@encoding", rb_str_new2("UTF-8"));
#ifdef HAVE_RUBY_ENCODING_H
    rb_iv_set(self, "@encoding_id", INT2FIX(rb_enc_find_index("UTF-8")));
#endif
    rb_iv_set(self, "@pg_encoding", rb_str_new2("UTF8"));
  }
#endif

  rb_iv_set(self, "@connection", Data_Wrap_Struct(rb_cObject, 0, 0, db));
}

VALUE do_postgres_cCommand_execute_non_query(int argc, VALUE *argv, VALUE self) {
  VALUE connection = rb_iv_get(self, "@connection");
  VALUE postgres_connection = rb_iv_get(connection, "@connection");

  if (postgres_connection == Qnil) {
    rb_raise(eDO_ConnectionError, "This connection has already been closed.");
  }

  VALUE query = data_objects_build_query_from_args(self, argc, argv);
  PGconn *db = DATA_PTR(postgres_connection);
  PGresult *response;
  int status;

  response = do_postgres_cCommand_execute(self, connection, db, query);
  status = PQresultStatus(response);

  VALUE affected_rows = Qnil;
  VALUE insert_id = Qnil;

  if (status == PGRES_TUPLES_OK) {
    if (PQgetlength(response, 0, 0) == 0) {
      insert_id = Qnil;
    }
    else {
      insert_id = INT2NUM(atoi(PQgetvalue(response, 0, 0)));
    }

    affected_rows = INT2NUM(atoi(PQcmdTuples(response)));
  }
  else if (status == PGRES_COMMAND_OK) {
    insert_id = Qnil;
    affected_rows = INT2NUM(atoi(PQcmdTuples(response)));
  }
  else {
    do_postgres_raise_error(self, response, query);
  }

  PQclear(response);
  return rb_funcall(cDO_PostgresResult, DO_ID_NEW, 3, self, affected_rows, insert_id);
}

VALUE do_postgres_cCommand_execute_reader(int argc, VALUE *argv, VALUE self) {
  VALUE connection = rb_iv_get(self, "@connection");
  VALUE postgres_connection = rb_iv_get(connection, "@connection");

  if (postgres_connection == Qnil) {
    rb_raise(eDO_ConnectionError, "This connection has already been closed.");
  }

  VALUE query = data_objects_build_query_from_args(self, argc, argv);
  PGconn *db = DATA_PTR(postgres_connection);
  PGresult *response = do_postgres_cCommand_execute(self, connection, db, query);

  int status = PQresultStatus(response);
  if(status != PGRES_TUPLES_OK && status != PGRES_COMMAND_OK) {
    do_postgres_raise_error(self, response, query);
  }

  int field_count = PQnfields(response);
  VALUE reader = rb_funcall(cDO_PostgresReader, DO_ID_NEW, 0);

  rb_iv_set(reader, "@connection", connection);
  rb_iv_set(reader, "@reader", Data_Wrap_Struct(rb_cObject, 0, 0, response));
  rb_iv_set(reader, "@opened", Qfalse);
  rb_iv_set(reader, "@field_count", INT2NUM(field_count));
  rb_iv_set(reader, "@row_count", INT2NUM(PQntuples(response)));

  VALUE field_names = rb_ary_new();
  VALUE field_types = rb_iv_get(self, "@field_types");
  int infer_types = 0;

  if (field_types == Qnil || 0 == RARRAY_LEN(field_types)) {
    field_types = rb_ary_new();
    infer_types = 1;
  } else if (RARRAY_LEN(field_types) != field_count) {
    // Whoops...  wrong number of types passed to set_types.  Close the reader and raise
    // and error
    rb_funcall(reader, rb_intern("close"), 0);
    rb_raise(rb_eArgError, "Field-count mismatch. Expected %ld fields, but the query yielded %d", RARRAY_LEN(field_types), field_count);
  }

  int i;

  for (i = 0; i < field_count; i++) {
    rb_ary_push(field_names, rb_str_new2(PQfname(response, i)));

    if (infer_types == 1) {
      rb_ary_push(field_types, do_postgres_infer_ruby_type(PQftype(response, i)));
    }
  }

  rb_iv_set(reader, "@position", INT2NUM(0));
  rb_iv_set(reader, "@fields", field_names);
  rb_iv_set(reader, "@field_types", field_types);
  return reader;
}

VALUE do_postgres_cReader_close(VALUE self) {
  VALUE reader_container = rb_iv_get(self, "@reader");

  if (reader_container == Qnil) {
    return Qfalse;
  }

  PGresult *reader = DATA_PTR(reader_container);

  if (!reader) {
    return Qfalse;
  }

  PQclear(reader);

  rb_iv_set(self, "@reader", Qnil);
  rb_iv_set(self, "@opened", Qfalse);
  return Qtrue;
}

VALUE do_postgres_cReader_next(VALUE self) {

  VALUE reader = rb_iv_get(self, "@reader");

  if(reader == Qnil) {
    rb_raise(eDO_ConnectionError, "This result set has already been closed.");
    return Qfalse;
  }

  PGresult *pg_reader = DATA_PTR(reader);

  int row_count = NUM2INT(rb_iv_get(self, "@row_count"));
  int field_count = NUM2INT(rb_iv_get(self, "@field_count"));
  VALUE field_types = rb_iv_get(self, "@field_types");
  int position = NUM2INT(rb_iv_get(self, "@position"));

  if (position > (row_count - 1)) {
    rb_iv_set(self, "@values", Qnil);
    return Qfalse;
  }

  rb_iv_set(self, "@opened", Qtrue);

  int enc = -1;
#ifdef HAVE_RUBY_ENCODING_H
  VALUE encoding_id = rb_iv_get(rb_iv_get(self, "@connection"), "@encoding_id");

  if (encoding_id != Qnil) {
    enc = FIX2INT(encoding_id);
  }
#endif

  VALUE array = rb_ary_new();
  VALUE field_type;
  VALUE value;
  int i;

  for (i = 0; i < field_count; i++) {
    field_type = rb_ary_entry(field_types, i);

    // Always return nil if the value returned from Postgres is null
    if (!PQgetisnull(pg_reader, position, i)) {
      value = do_postgres_typecast(PQgetvalue(pg_reader, position, i), PQgetlength(pg_reader, position, i), field_type, enc);
    }
    else {
      value = Qnil;
    }

    rb_ary_push(array, value);
  }

  rb_iv_set(self, "@values", array);
  rb_iv_set(self, "@position", INT2NUM(position+1));
  return Qtrue;
}

void Init_do_postgres() {
  data_objects_common_init();

  mDO_Postgres = rb_define_module_under(mDO, "Postgres");
  mDO_PostgresEncoding = rb_define_module_under(mDO_Postgres, "Encoding");

  cDO_PostgresConnection = rb_define_class_under(mDO_Postgres, "Connection", cDO_Connection);
  rb_define_method(cDO_PostgresConnection, "initialize", do_postgres_cConnection_initialize, 1);
  rb_define_method(cDO_PostgresConnection, "dispose", do_postgres_cConnection_dispose, 0);
  rb_define_method(cDO_PostgresConnection, "character_set", data_objects_cConnection_character_set , 0);
  rb_define_method(cDO_PostgresConnection, "quote_string", do_postgres_cConnection_quote_string, 1);
  rb_define_method(cDO_PostgresConnection, "quote_byte_array", do_postgres_cConnection_quote_byte_array, 1);

  cDO_PostgresCommand = rb_define_class_under(mDO_Postgres, "Command", cDO_Command);
  rb_define_method(cDO_PostgresCommand, "set_types", data_objects_cCommand_set_types, -1);
  rb_define_method(cDO_PostgresCommand, "execute_non_query", do_postgres_cCommand_execute_non_query, -1);
  rb_define_method(cDO_PostgresCommand, "execute_reader", do_postgres_cCommand_execute_reader, -1);

  cDO_PostgresResult = rb_define_class_under(mDO_Postgres, "Result", cDO_Result);

  cDO_PostgresReader = rb_define_class_under(mDO_Postgres, "Reader", cDO_Reader);
  rb_define_method(cDO_PostgresReader, "close", do_postgres_cReader_close, 0);
  rb_define_method(cDO_PostgresReader, "next!", do_postgres_cReader_next, 0);
  rb_define_method(cDO_PostgresReader, "values", data_objects_cReader_values, 0);
  rb_define_method(cDO_PostgresReader, "fields", data_objects_cReader_fields, 0);
  rb_define_method(cDO_PostgresReader, "field_count", data_objects_cReader_field_count, 0);

  rb_global_variable(&cDO_PostgresResult);
  rb_global_variable(&cDO_PostgresReader);

  data_objects_define_errors(mDO_Postgres, do_postgres_errors);
}
