#include <ruby.h>

#ifdef _WIN32
#define cCommand_execute cCommand_execute_sync
#define do_int64 signed __int64
#else
#define cCommand_execute cCommand_execute_async
#define do_int64 signed long long int
#endif

#define CONST_GET(scope, constant) (rb_funcall(scope, ID_CONST_GET, 1, rb_str_new2(constant)))

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

// To store rb_intern values
extern ID ID_NEW;
extern ID ID_NEW_DATE;
extern ID ID_CONST_GET;
extern ID ID_RATIONAL;
extern ID ID_ESCAPE;
extern ID ID_STRFTIME;
extern ID ID_LOG;

// Reference to Extlib module
extern VALUE mExtlib;
extern VALUE rb_cByteArray;

// References to DataObjects base classes
extern VALUE mDO;
extern VALUE mEncoding;
extern VALUE cDO_Quoting;
extern VALUE cDO_Connection;
extern VALUE cDO_Command;
extern VALUE cDO_Result;
extern VALUE cDO_Reader;
extern VALUE cDO_Logger;
extern VALUE cDO_Logger_Message;
extern VALUE cDO_Extension;
extern VALUE eConnectionError;
extern VALUE eDataError;

// References to Ruby classes that we'll need
extern VALUE rb_cDate;
extern VALUE rb_cDateTime;
extern VALUE rb_cBigDecimal;

extern void data_objects_debug(VALUE connection, VALUE string, struct timeval *start);
extern char *get_uri_option(VALUE query_hash, const char *key);
extern void assert_file_exists(char *file, const char *message);
extern VALUE build_query_from_args(VALUE klass, int count, VALUE *args);

extern void reduce(do_int64 *numerator, do_int64 *denominator);
extern int jd_from_date(int year, int month, int day);
extern VALUE seconds_to_offset(long seconds_offset);
extern VALUE timezone_to_offset(int hour_offset, int minute_offset);

extern VALUE parse_date(const char *date);
extern VALUE parse_time(const char *date);
extern VALUE parse_date_time(const char *date);

extern VALUE cConnection_character_set(VALUE self);
extern VALUE cConnection_is_using_socket(VALUE self);
extern VALUE cConnection_ssl_cipher(VALUE self);
extern VALUE cConnection_quote_time(VALUE self, VALUE value);
extern VALUE cConnection_quote_date_time(VALUE self, VALUE value);
extern VALUE cConnection_quote_date(VALUE self, VALUE value);

extern VALUE cCommand_set_types(int argc, VALUE *argv, VALUE self);

extern VALUE cReader_values(VALUE self);
extern VALUE cReader_fields(VALUE self);
extern VALUE cReader_field_count(VALUE self);

extern void common_init(void);
