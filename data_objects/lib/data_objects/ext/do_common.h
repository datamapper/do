#ifndef _DO_COMMON_H_
#define _DO_COMMON_H_

#include <ruby.h>

// Needed for defining error.h
struct errcodes {
  int error_no;
  const char *error_name;
  const char *exception;
};

#define ERRCODE(name,message)   {name, #name, message}

#ifdef _WIN32
typedef signed __int64 do_int64;
#else
typedef signed long long int do_int64;
#endif

#ifdef HAVE_RUBY_ENCODING_H
#include <ruby/encoding.h>
#define DATA_OBJECTS_STR_NEW2(str, encoding, internal_encoding) \
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

#define DATA_OBJECTS_STR_NEW(str, len, encoding, internal_encoding) \
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

#define DATA_OBJECTS_STR_NEW2(str, encoding, internal_encoding) \
  rb_str_new2((const char *)str)

#define DATA_OBJECTS_STR_NEW(str, len, encoding, internal_encoding) \
  rb_str_new((const char *)str, (long)len)
#endif

// To store rb_intern values
extern ID DO_ID_NEW;
extern ID DO_ID_NEW_DATE;
extern ID DO_ID_CONST_GET;
extern ID DO_ID_RATIONAL;
extern ID DO_ID_ESCAPE;
extern ID DO_ID_STRFTIME;
extern ID DO_ID_LOG;

// Reference to Extlib module
extern VALUE mExtlib;
extern VALUE rb_cByteArray;

// References to DataObjects base classes
extern VALUE mDO;
extern VALUE cDO_Quoting;
extern VALUE cDO_Connection;
extern VALUE cDO_Command;
extern VALUE cDO_Result;
extern VALUE cDO_Reader;
extern VALUE cDO_Logger;
extern VALUE cDO_Logger_Message;
extern VALUE cDO_Extension;
extern VALUE eDO_ConnectionError;
extern VALUE eDO_DataError;

// References to Ruby classes that we'll need
extern VALUE rb_cDate;
extern VALUE rb_cDateTime;
extern VALUE rb_cBigDecimal;

extern void data_objects_debug(VALUE connection, VALUE string, struct timeval *start);
extern char *data_objects_get_uri_option(VALUE query_hash, const char *key);
extern void data_objects_assert_file_exists(char *file, const char *message);
extern VALUE data_objects_build_query_from_args(VALUE klass, int count, VALUE *args);

extern void data_objects_reduce(do_int64 *numerator, do_int64 *denominator);
extern int data_objects_jd_from_date(int year, int month, int day);
extern VALUE data_objects_seconds_to_offset(long seconds_offset);
extern VALUE data_objects_timezone_to_offset(int hour_offset, int minute_offset);

extern VALUE data_objects_parse_date(const char *date);
extern VALUE data_objects_parse_time(const char *date);
extern VALUE data_objects_parse_date_time(const char *date);

extern VALUE data_objects_cConnection_character_set(VALUE self);
extern VALUE data_objects_cConnection_is_using_socket(VALUE self);
extern VALUE data_objects_cConnection_ssl_cipher(VALUE self);
extern VALUE data_objects_cConnection_quote_time(VALUE self, VALUE value);
extern VALUE data_objects_cConnection_quote_date_time(VALUE self, VALUE value);
extern VALUE data_objects_cConnection_quote_date(VALUE self, VALUE value);

extern VALUE data_objects_cCommand_set_types(int argc, VALUE *argv, VALUE self);

extern VALUE data_objects_cReader_values(VALUE self);
extern VALUE data_objects_cReader_fields(VALUE self);
extern VALUE data_objects_cReader_field_count(VALUE self);

extern void data_objects_common_init(void);

extern VALUE data_objects_const_get(VALUE scope, const char *constant);

static inline void data_objects_define_errors(VALUE scope, const struct errcodes *errors) {
  const struct errcodes *e;

  for (e = errors; e->error_name; e++) {
    rb_const_set(scope, rb_intern(e->error_name), INT2NUM(e->error_no));
  }
}

extern void data_objects_raise_error(VALUE self, const struct errcodes *errors, int errnum, VALUE message, VALUE query, VALUE state);

extern VALUE data_objects_typecast(const char *value, long length, const VALUE type, int encoding);

#define RSTRING_NOT_MODIFIED

#endif
