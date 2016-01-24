#include <ruby.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <time.h>
#ifndef _WIN32
#include <sys/time.h>
#endif

#include "do_common.h"

/*
 * Common variables ("globals")
 */

// To store rb_intern values
ID DO_ID_NEW;
ID DO_ID_NEW_DATE;
ID DO_ID_CONST_GET;
ID DO_ID_RATIONAL;
ID DO_ID_ESCAPE;
ID DO_ID_STRFTIME;
ID DO_ID_LOG;

// Reference to Extlib module
VALUE mExtlib;
VALUE rb_cByteArray;

// References to DataObjects base classes
VALUE mDO;
VALUE cDO_Quoting;
VALUE cDO_Connection;
VALUE cDO_Command;
VALUE cDO_Result;
VALUE cDO_Reader;
VALUE cDO_Logger;
VALUE cDO_Logger_Message;
VALUE cDO_Extension;
VALUE eDO_ConnectionError;
VALUE eDO_DataError;

// References to Ruby classes that we'll need
VALUE rb_cDate;
VALUE rb_cDateTime;
VALUE rb_cBigDecimal;

/*
 * Common Functions
 */


VALUE data_objects_const_get(VALUE scope, const char *constant) {
  return rb_funcall(scope, DO_ID_CONST_GET, 1, rb_str_new2(constant));
}

void data_objects_debug(VALUE connection, VALUE string, struct timeval *start) {
  struct timeval stop;
  VALUE message;
  do_int64 duration;

  gettimeofday(&stop, NULL);
  duration = (stop.tv_sec - start->tv_sec) * 1000000 + stop.tv_usec - start->tv_usec;

  message = rb_funcall(cDO_Logger_Message, DO_ID_NEW, 3, string, rb_time_new(start->tv_sec, start->tv_usec), INT2NUM(duration));

  rb_funcall(connection, DO_ID_LOG, 1, message);
}

void data_objects_raise_error(VALUE self, const struct errcodes *errors, int errnum, VALUE message, VALUE query, VALUE state) {
  const char *exception_type = "SQLError";
  const struct errcodes *e;
  VALUE uri, exception;

  for (e = errors; e->error_name; e++) {
    if (e->error_no == errnum) {
      // return the exception type for the matching error
      exception_type = e->exception;
      break;
    }
  }

  uri = rb_funcall(rb_iv_get(self, "@connection"), rb_intern("to_s"), 0);

  exception = rb_funcall(
    data_objects_const_get(mDO, exception_type),
    DO_ID_NEW,
    5,
    message,
    INT2NUM(errnum),
    state,
    query,
    uri
  );

  rb_exc_raise(exception);
}

char *data_objects_get_uri_option(VALUE query_hash, const char *key) {
  VALUE query_value;
  char *value = NULL;

  if (!rb_obj_is_kind_of(query_hash, rb_cHash)) {
    return NULL;
  }

  query_value = rb_hash_aref(query_hash, rb_str_new2(key));

  if (Qnil != query_value) {
    value = StringValuePtr(query_value);
  }

  return value;
}

void data_objects_assert_file_exists(char *file, const char *message) {
  if (file) {
    if (rb_funcall(rb_cFile, rb_intern("exist?"), 1, rb_str_new2(file)) == Qfalse) {
      rb_raise(rb_eArgError, "%s", message);
    }
  }
}

VALUE data_objects_build_query_from_args(VALUE klass, int count, VALUE *args) {
  int i;
  VALUE array = rb_ary_new();

  for (i = 0; i < count; i++) {
    rb_ary_push(array, args[i]);
  }

  return rb_funcall(klass, DO_ID_ESCAPE, 1, array);
}

// Find the greatest common denominator and reduce the provided numerator and denominator.
// This replaces calles to Rational.reduce! which does the same thing, but really slowly.
void data_objects_reduce(do_int64 *numerator, do_int64 *denominator) {
  do_int64 a = *numerator, b = *denominator, c;

  while (a != 0) {
    c = a;
    a = b % a;
    b = c;
  }

  *numerator   /= b;
  *denominator /= b;
}

// Generate the date integer which Date.civil_to_jd returns
int data_objects_jd_from_date(int year, int month, int day) {
  int a, b;

  if (month <= 2) {
    year  -= 1;
    month += 12;
  }

  a = year / 100;
  b = 2 - a + (a / 4);

  return (int)(floor(365.25 * (year + 4716)) + floor(30.6001 * (month + 1)) + day + b - 1524);
}

VALUE data_objects_seconds_to_offset(long seconds_offset) {
  do_int64 num = seconds_offset;
  do_int64 den = 86400;

  data_objects_reduce(&num, &den);
  return rb_funcall(rb_mKernel, DO_ID_RATIONAL, 2, rb_ll2inum(num), rb_ll2inum(den));
}

VALUE data_objects_timezone_to_offset(int hour_offset, int minute_offset) {
  do_int64 seconds = 0;

  seconds += hour_offset * 3600;
  seconds += minute_offset * 60;

  return data_objects_seconds_to_offset(seconds);
}

VALUE data_objects_parse_date(const char *date) {
  static char const *const _fmt_date = "%4d-%2d-%2d";
  int year = 0, month = 0, day = 0;

  switch (sscanf(date, _fmt_date, &year, &month, &day)) {
    case 0:
    case EOF:
      return Qnil;
  }

  if(!year && !month && !day) {
    return Qnil;
  }

  return rb_funcall(rb_cDate, DO_ID_NEW, 3, INT2NUM(year), INT2NUM(month), INT2NUM(day));
}

VALUE data_objects_parse_time(const char *date) {
  static char const* const _fmt_datetime = "%4d-%2d-%2d%*c%2d:%2d:%2d%7lf";
  int year = 0, month = 0, day = 0, hour = 0, min = 0, sec = 0, usec = 0;
  double subsec = 0;

  switch (sscanf(date, _fmt_datetime, &year, &month, &day, &hour, &min, &sec, &subsec)) {
    case 0:
    case EOF:
      return Qnil;
  }

  usec = (int) (subsec * 1000000);

  /* Mysql TIMESTAMPS can default to 0 */
  if ((year + month + day + hour + min + sec + usec) == 0) {
    return Qnil;
  }

  return rb_funcall(rb_cTime, rb_intern("local"), 7, INT2NUM(year), INT2NUM(month), INT2NUM(day), INT2NUM(hour), INT2NUM(min), INT2NUM(sec), INT2NUM(usec));
}

VALUE data_objects_parse_date_time(const char *date) {
  static char const* const _fmt_datetime_tz_normal = "%4d-%2d-%2d%*c%2d:%2d:%2d%3d:%2d";
  static char const* const _fmt_datetime_tz_subsec = "%4d-%2d-%2d%*c%2d:%2d:%2d.%*d%3d:%2d";
  int tokens_read;
  const char *fmt_datetime;

  VALUE offset;

  int year, month, day, hour, min, sec, hour_offset, minute_offset;

  struct tm timeinfo;
  time_t target_time;
  time_t gmt_offset;
  int dst_adjustment;

  if (*date == '\0') {
    return Qnil;
  }

  /*
   * We handle the following cases:
   *   - Date (default to midnight) [3 tokens, missing 5]
   *   - DateTime [6 tokens, missing 2]
   *   - DateTime with hour, possibly minute TZ offset [7-8 tokens]
   */
  fmt_datetime = strchr(date, '.') ? _fmt_datetime_tz_subsec : _fmt_datetime_tz_normal;
  tokens_read  = sscanf(date, fmt_datetime, &year, &month, &day, &hour, &min, &sec, &hour_offset, &minute_offset);

  if(!year && !month && !day && !hour && !min && !sec) {
    return Qnil;
  }

  switch (tokens_read) {
    case 8:
      minute_offset *= hour_offset < 0 ? -1 : 1;
      break;

    case 7: /* Only got TZ hour offset, so assume 0 for minute */
      minute_offset = 0;
      break;

    case 3: /* Only got Date */
      hour = 0;
      min  = 0;
      sec  = 0;
      /* Fall through */

    case 6: /* Only got DateTime */
      /*
       * Interpret the DateTime from the local system TZ.  If target date would
       * end up in DST, assume adjustment of a 1 hour shift.
       *
       * FIXME: The DST adjustment calculation won't be accurate for timezones
       * that observe fractional-hour shifts.  But that's a real minority for
       * now..
       */
      timeinfo.tm_year  = year - 1900;
      timeinfo.tm_mon   = month - 1;    // 0 - 11
      timeinfo.tm_mday  = day;
      timeinfo.tm_hour  = hour;
      timeinfo.tm_min   = min;
      timeinfo.tm_sec   = sec;
      timeinfo.tm_isdst = -1;

      target_time    = mktime(&timeinfo);
      dst_adjustment = timeinfo.tm_isdst ? 3600 : 0;

      /*
       * Now figure out seconds from UTC.  For that we need a UTC/GMT-adjusted
       * time_t, which we get from mktime(gmtime(current_time)).
       *
       * NOTE: Some modern libc's have tm_gmtoff in struct tm, but we can't count
       * on that.
       */
#ifdef HAVE_GMTIME_R
      gmtime_r(&target_time, &timeinfo);
#else
      timeinfo = *gmtime(&target_time);
#endif

      gmt_offset    = target_time - mktime(&timeinfo) + dst_adjustment;
      hour_offset   = ((int)gmt_offset / 3600);
      minute_offset = ((int)gmt_offset % 3600 / 60);
      break;

    default: /* Any other combo of missing tokens and we can't do anything */
      rb_raise(eDO_DataError, "Couldn't parse date: %s", date);
  }

  offset = data_objects_timezone_to_offset(hour_offset, minute_offset);
  return rb_funcall(rb_cDateTime, DO_ID_NEW, 7, INT2NUM(year), INT2NUM(month), INT2NUM(day),
                                             INT2NUM(hour), INT2NUM(min), INT2NUM(sec), offset);
}

VALUE data_objects_cConnection_character_set(VALUE self) {
  return rb_iv_get(self, "@encoding");
}

VALUE data_objects_cConnection_is_using_socket(VALUE self) {
  return rb_iv_get(self, "@using_socket");
}

VALUE data_objects_cConnection_ssl_cipher(VALUE self) {
  return rb_iv_get(self, "@ssl_cipher");
}

VALUE data_objects_cConnection_quote_time(VALUE self, VALUE value) {
  return rb_funcall(value, DO_ID_STRFTIME, 1, rb_str_new2("'%Y-%m-%d %H:%M:%S'"));
}

VALUE data_objects_cConnection_quote_date_time(VALUE self, VALUE value) {
  // TODO: Support non-local dates. we need to call #new_offset on the date to be
  // quoted and pass in the current locale's date offset (self.new_offset((hours * 3600).to_r / 86400)
  return rb_funcall(value, DO_ID_STRFTIME, 1, rb_str_new2("'%Y-%m-%d %H:%M:%S'"));
}

VALUE data_objects_cConnection_quote_date(VALUE self, VALUE value) {
  return rb_funcall(value, DO_ID_STRFTIME, 1, rb_str_new2("'%Y-%m-%d'"));
}

/*
 * Accepts an array of Ruby types (Fixnum, Float, String, etc...) and turns them
 * into Ruby-strings so we can easily typecast later
 */
VALUE data_objects_cCommand_set_types(int argc, VALUE *argv, VALUE self) {
  VALUE entry, sub_entry;
  int i, j;
  VALUE type_strings = rb_ary_new();
  VALUE array = rb_ary_new();

  for (i = 0; i < argc; i++) {
    rb_ary_push(array, argv[i]);
  }

  for (i = 0; i < RARRAY_LEN(array); i++) {
    entry = rb_ary_entry(array, i);

    if (TYPE(entry) == T_CLASS) {
      rb_ary_push(type_strings, entry);
    }
    else if (TYPE(entry) == T_ARRAY) {
      for (j = 0; j < RARRAY_LEN(entry); j++) {
        sub_entry = rb_ary_entry(entry, j);

        if (TYPE(sub_entry) == T_CLASS) {
          rb_ary_push(type_strings, sub_entry);
        }
    else {
          rb_raise(rb_eArgError, "Invalid type given");
        }
      }
    }
    else {
      rb_raise(rb_eArgError, "Invalid type given");
    }
  }

  rb_iv_set(self, "@field_types", type_strings);
  return array;
}

VALUE data_objects_cReader_values(VALUE self) {
  VALUE state = rb_iv_get(self, "@opened");
  VALUE values = rb_iv_get(self, "@values");

  if (state == Qnil || state == Qfalse || values == Qnil) {
    rb_raise(eDO_DataError, "Reader is not initialized");
  }

  return rb_iv_get(self, "@values");
}

VALUE data_objects_cReader_fields(VALUE self) {
  return rb_iv_get(self, "@fields");
}

VALUE data_objects_cReader_field_count(VALUE self) {
  return rb_iv_get(self, "@field_count");
}

void data_objects_common_init(void) {
  rb_require("bigdecimal");
  rb_require("rational");
  rb_require("date");
  rb_require("data_objects");

  // Needed by data_objects_const_get
  DO_ID_CONST_GET = rb_intern("const_get");

  // Get references classes needed for Date/Time parsing
  rb_cDate = data_objects_const_get(rb_mKernel, "Date");
  rb_cDateTime = data_objects_const_get(rb_mKernel, "DateTime");
  rb_cBigDecimal = data_objects_const_get(rb_mKernel, "BigDecimal");

  DO_ID_NEW = rb_intern("new");
#ifdef RUBY_LESS_THAN_186
  DO_ID_NEW_DATE = rb_intern("new0");
#else
  DO_ID_NEW_DATE = rb_intern("new!");
#endif
  DO_ID_CONST_GET = rb_intern("const_get");
  DO_ID_RATIONAL = rb_intern("Rational");
  DO_ID_ESCAPE = rb_intern("escape_sql");
  DO_ID_STRFTIME = rb_intern("strftime");
  DO_ID_LOG = rb_intern("log");

  // Get references to the Extlib module
  mExtlib = data_objects_const_get(rb_mKernel, "Extlib");
  rb_cByteArray = data_objects_const_get(mExtlib, "ByteArray");

  // Get references to the DataObjects module and its classes
  mDO = data_objects_const_get(rb_mKernel, "DataObjects");
  cDO_Quoting = data_objects_const_get(mDO, "Quoting");
  cDO_Connection = data_objects_const_get(mDO, "Connection");
  cDO_Command = data_objects_const_get(mDO, "Command");
  cDO_Result = data_objects_const_get(mDO, "Result");
  cDO_Reader = data_objects_const_get(mDO, "Reader");
  cDO_Logger = data_objects_const_get(mDO, "Logger");
  cDO_Logger_Message = data_objects_const_get(cDO_Logger, "Message");
  cDO_Extension = data_objects_const_get(mDO, "Extension");

  eDO_ConnectionError = data_objects_const_get(mDO, "ConnectionError");
  eDO_DataError = data_objects_const_get(mDO, "DataError");

  rb_global_variable(&DO_ID_NEW_DATE);
  rb_global_variable(&DO_ID_RATIONAL);
  rb_global_variable(&DO_ID_CONST_GET);
  rb_global_variable(&DO_ID_ESCAPE);
  rb_global_variable(&DO_ID_LOG);
  rb_global_variable(&DO_ID_NEW);

  rb_global_variable(&rb_cDate);
  rb_global_variable(&rb_cDateTime);
  rb_global_variable(&rb_cBigDecimal);
  rb_global_variable(&rb_cByteArray);

  rb_global_variable(&mDO);
  rb_global_variable(&cDO_Logger_Message);

  rb_global_variable(&eDO_ConnectionError);
  rb_global_variable(&eDO_DataError);

  tzset();
}

/*
 * Common typecasting logic that can be used or overriden by Adapters.
 */
extern VALUE data_objects_typecast(const char *value, long length, const VALUE type, int encoding) {
#ifdef HAVE_RUBY_ENCODING_H
  rb_encoding *internal_encoding = rb_default_internal_encoding();
#else
  void *internal_encoding = NULL;
#endif

  if (type == rb_cInteger) {
    return rb_cstr2inum(value, 10);
  }
  else if (type == rb_cString) {
    return DATA_OBJECTS_STR_NEW(value, length, encoding, internal_encoding);
  }
  else if (type == rb_cFloat) {
    return rb_float_new(rb_cstr_to_dbl(value, Qfalse));
  }
  else if (type == rb_cBigDecimal) {
    return rb_funcall(rb_cBigDecimal, DO_ID_NEW, 1, rb_str_new(value, length));
  }
  else if (type == rb_cDate) {
    return data_objects_parse_date(value);
  }
  else if (type == rb_cDateTime) {
    return data_objects_parse_date_time(value);
  }
  else if (type == rb_cTime) {
    return data_objects_parse_time(value);
  }
  else if (type == rb_cTrueClass) {
    return (!value || strcmp("0", value) == 0) ? Qfalse : Qtrue;
  }
  else if (type == rb_cByteArray) {
    return rb_funcall(rb_cByteArray, DO_ID_NEW, 1, rb_str_new(value, length));
  }
  else if (type == rb_cClass) {
    return rb_funcall(mDO, rb_intern("full_const_get"), 1, rb_str_new(value, length));
  }
  else if (type == rb_cNilClass) {
    return Qnil;
  }
  else {
    return DATA_OBJECTS_STR_NEW(value, length, encoding, internal_encoding);
  }
}
