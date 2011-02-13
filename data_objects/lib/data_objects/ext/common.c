#include <ruby.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <time.h>

#include "common.h"

/*
 * Common variables ("globals")
 */

// To store rb_intern values
ID ID_NEW;
ID ID_NEW_DATE;
ID ID_CONST_GET;
ID ID_RATIONAL;
ID ID_ESCAPE;
ID ID_STRFTIME;
ID ID_LOG;

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
VALUE eConnectionError;
VALUE eDataError;

// References to Ruby classes that we'll need
VALUE rb_cDate;
VALUE rb_cDateTime;
VALUE rb_cBigDecimal;

/*
 * Common Functions
 */

void data_objects_debug(VALUE connection, VALUE string, struct timeval *start) {
  struct timeval stop;
  VALUE message;

  gettimeofday(&stop, NULL);
  do_int64 duration = (stop.tv_sec - start->tv_sec) * 1000000 + stop.tv_usec - start->tv_usec;

  message = rb_funcall(cDO_Logger_Message, ID_NEW, 3, string, rb_time_new(start->tv_sec, start->tv_usec), INT2NUM(duration));

  rb_funcall(connection, ID_LOG, 1, message);
}

char *get_uri_option(VALUE query_hash, const char *key) {
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

void assert_file_exists(char *file, const char *message) {
  if (file == NULL) { return; }
  if (rb_funcall(rb_cFile, rb_intern("exist?"), 1, rb_str_new2(file)) == Qfalse) {
    rb_raise(rb_eArgError, "%s", message);
  }
}

VALUE build_query_from_args(VALUE klass, int count, VALUE *args) {
  int i;
  VALUE array = rb_ary_new();
  for (i = 0; i < count; i++) {
    rb_ary_push(array, (VALUE)args[i]);
  }

  return rb_funcall(klass, ID_ESCAPE, 1, array);
}

// Find the greatest common denominator and reduce the provided numerator and denominator.
// This replaces calles to Rational.reduce! which does the same thing, but really slowly.
void reduce(do_int64 *numerator, do_int64 *denominator) {
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
int jd_from_date(int year, int month, int day) {
  int a, b;

  if (month <= 2) {
    year  -= 1;
    month += 12;
  }

  a = year / 100;
  b = 2 - a + (a / 4);

  return (int) (floor(365.25 * (year + 4716)) + floor(30.6001 * (month + 1)) + day + b - 1524);
}

VALUE seconds_to_offset(long seconds_offset) {
  do_int64 num = seconds_offset, den = 86400;
  reduce(&num, &den);
  return rb_funcall(rb_mKernel, ID_RATIONAL, 2, rb_ll2inum(num), rb_ll2inum(den));
}

VALUE timezone_to_offset(int hour_offset, int minute_offset) {
  do_int64 seconds = 0;

  seconds += hour_offset * 3600;
  seconds += minute_offset * 60;

  return seconds_to_offset(seconds);
}

VALUE parse_date(const char *date) {
  static char const *const _fmt_date = "%4d-%2d-%2d";
  int year, month, day;
  int jd, ajd;
  VALUE rational;

  sscanf(date, _fmt_date, &year, &month, &day);

  jd       = jd_from_date(year, month, day);
  ajd      = jd * 2 - 1;        // Math from Date.jd_to_ajd
  rational = rb_funcall(rb_mKernel, ID_RATIONAL, 2, INT2NUM(ajd), INT2NUM(2));

  return rb_funcall(rb_cDate, ID_NEW_DATE, 3, rational, INT2NUM(0), INT2NUM(2299161));
}

VALUE parse_time(const char *date) {
  static char const* const _fmt_datetime = "%4d-%2d-%2d %2d:%2d:%2d.%6d";
  int year, month, day, hour = 0, min = 0, sec = 0, usec = 0;

  if (*date == '\0')
    return Qnil;

  sscanf(date, _fmt_datetime, &year, &month, &day, &hour, &min, &sec, &usec);

  /* Mysql TIMESTAMPS can default to 0 */
  if (year + month + day + hour + min + sec + usec == 0)
    return Qnil;

  return rb_funcall(rb_cTime, rb_intern("local"), 7, INT2NUM(year), INT2NUM(month), INT2NUM(day), INT2NUM(hour), INT2NUM(min), INT2NUM(sec), INT2NUM(usec));
}

VALUE parse_date_time(const char *date) {
  static char const* const _fmt_datetime_tz_normal = "%4d-%2d-%2d %2d:%2d:%2d%3d:%2d";
  static char const* const _fmt_datetime_tz_subsec = "%4d-%2d-%2d %2d:%2d:%2d.%*d%3d:%2d";
  unsigned int tokens_read;
  const char *fmt_datetime;

  VALUE ajd, offset;

  int year, month, day, hour, min, sec, hour_offset, minute_offset, jd;
  do_int64 num, den;

  struct tm timeinfo;
  time_t target_time;
  time_t gmt_offset;
  int dst_adjustment;

  if (*date == '\0')
    return Qnil;

  /*
   * We handle the following cases:
   *   - Date (default to midnight) [3 tokens, missing 5]
   *   - DateTime [6 tokens, missing 2]
   *   - DateTime with hour, possibly minute TZ offset [7-8 tokens]
   */

  fmt_datetime = strchr(date, '.') ? _fmt_datetime_tz_subsec : _fmt_datetime_tz_normal;
  tokens_read  = sscanf(date, fmt_datetime, &year, &month, &day, &hour, &min, &sec, &hour_offset, &minute_offset);

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
      rb_raise(eDataError, "Couldn't parse date: %s", date);
  }

  jd = jd_from_date(year, month, day);

  /*
   * Generate ajd with fractional days for the time.
   * Extracted from Date#jd_to_ajd, Date#day_fraction_to_time, and Rational#+ and #-.
   *
   * TODO: These are 64bit numbers; is reduce() really necessary?
   */

  num = (hour * 1440) + (min * 24);
  num -= (hour_offset * 1440) + (minute_offset * 24);
  den = (24 * 1440);
  reduce(&num, &den);

  num = (num * 86400) + (sec * den);
  den = den * 86400;
  reduce(&num, &den);

  num += jd * den;

  num = (num * 2) - den;
  den *= 2;
  reduce(&num, &den);

  ajd = rb_funcall(rb_mKernel, ID_RATIONAL, 2, rb_ull2inum(num), rb_ull2inum(den));
  offset = timezone_to_offset(hour_offset, minute_offset);

  return rb_funcall(rb_cDateTime, ID_NEW_DATE, 3, ajd, offset, INT2NUM(2299161));
}

VALUE cConnection_character_set(VALUE self) {
  return rb_iv_get(self, "@encoding");
}

VALUE cConnection_is_using_socket(VALUE self) {
  return rb_iv_get(self, "@using_socket");
}

VALUE cConnection_ssl_cipher(VALUE self) {
  return rb_iv_get(self, "@ssl_cipher");
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

/*
 * Accepts an array of Ruby types (Fixnum, Float, String, etc...) and turns them
 * into Ruby-strings so we can easily typecast later
 */
VALUE cCommand_set_types(int argc, VALUE *argv, VALUE self) {
  VALUE type_strings = rb_ary_new();
  VALUE array = rb_ary_new();

  int i, j;

  for (i = 0; i < argc; i++) {
    rb_ary_push(array, argv[i]);
  }

  for (i = 0; i < RARRAY_LEN(array); i++) {
    VALUE entry = rb_ary_entry(array, i);
    if (TYPE(entry) == T_CLASS) {
      rb_ary_push(type_strings, entry);
    } else if (TYPE(entry) == T_ARRAY) {
      for (j = 0; j < RARRAY_LEN(entry); j++) {
        VALUE sub_entry = rb_ary_entry(entry, j);
        if (TYPE(sub_entry) == T_CLASS) {
          rb_ary_push(type_strings, sub_entry);
        } else {
          rb_raise(rb_eArgError, "Invalid type given");
        }
      }
    } else {
      rb_raise(rb_eArgError, "Invalid type given");
    }
  }

  rb_iv_set(self, "@field_types", type_strings);

  return array;
}

VALUE cReader_values(VALUE self) {
  VALUE state = rb_iv_get(self, "@opened");
  if ( state == Qnil || state == Qfalse ) {
    rb_raise(eDataError, "Reader is not initialized");
  }
  return rb_iv_get(self, "@values");
}

VALUE cReader_fields(VALUE self) {
  return rb_iv_get(self, "@fields");
}

VALUE cReader_field_count(VALUE self) {
  return rb_iv_get(self, "@field_count");
}

void common_init(void) {
  rb_require("bigdecimal");
  rb_require("rational");
  rb_require("date");
  rb_require("data_objects");

  ID_CONST_GET = rb_intern("const_get");

  // Get references classes needed for Date/Time parsing
  rb_cDate = CONST_GET(rb_mKernel, "Date");
  rb_cDateTime = CONST_GET(rb_mKernel, "DateTime");
  rb_cBigDecimal = CONST_GET(rb_mKernel, "BigDecimal");

  ID_NEW = rb_intern("new");
#ifdef RUBY_LESS_THAN_186
  ID_NEW_DATE = rb_intern("new0");
#else
  ID_NEW_DATE = rb_intern("new!");
#endif
  ID_CONST_GET = rb_intern("const_get");
  ID_RATIONAL = rb_intern("Rational");
  ID_ESCAPE = rb_intern("escape_sql");
  ID_STRFTIME = rb_intern("strftime");
  ID_LOG = rb_intern("log");

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
  cDO_Logger = CONST_GET(mDO, "Logger");
  cDO_Logger_Message = CONST_GET(cDO_Logger, "Message");

  eConnectionError = CONST_GET(mDO, "ConnectionError");
  eDataError = CONST_GET(mDO, "DataError");

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

  rb_global_variable(&eConnectionError);
  rb_global_variable(&eDataError);

  tzset();
}
