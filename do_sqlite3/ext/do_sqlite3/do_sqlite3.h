#ifndef DO_SQLITE3_H
#define DO_SQLITE3_H

#include <ruby.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <locale.h>
#include <sqlite3.h>
#include "compat.h"

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

void Init_do_sqlite3_extension();

#endif