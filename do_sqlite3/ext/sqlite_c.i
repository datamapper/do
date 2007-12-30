%module sqlite3_c
%include "typemaps.i"
%{
#include <sqlite3.h>
typedef void BLOB;
typedef void VALBLOB;
%}

%typemap(in,numinputs=0) sqlite3 **OUTPUT(sqlite3 *) { 
  $1 = (sqlite3**)malloc( sizeof( sqlite3* ) ); 
};
%typemap(argout,fragment="output_helper") sqlite3 **OUTPUT (sqlite3 *) {
  $result = output_helper($result, SWIG_NewPointerObj( *$1, SWIGTYPE_p_sqlite3, 0 ));
}
%typemap(freearg) sqlite3 ** {
  free((sqlite3 *)$1);
}

%typemap(in,numinputs=0) sqlite3_stmt **OUTPUT(sqlite3_stmt *) { 
  $1 = (sqlite3_stmt**)malloc( sizeof( sqlite3_stmt* ) ); 
};
%typemap(argout,fragment="output_helper") sqlite3_stmt **OUTPUT (sqlite3_stmt *) {
  $result = output_helper($result, SWIG_NewPointerObj( *$1, SWIGTYPE_p_sqlite3_stmt, 0 ));
}
%typemap(freearg) sqlite3_stmt ** {
  free((sqlite3_stmt *)$1);
}

%typemap(in,numinputs=0) char **OUTPUT(char *) { 
  $1 = (char**)malloc( sizeof( char* ) ); 
};
%typemap(argout,fragment="output_helper") char **OUTPUT (char *) {
  $result = output_helper($result, rb_str_new2(*$1));
}
%typemap(freearg) char ** {
  free((char *)$1);
}

%typemap(out) sqlite_int64 {
  $result = LONG2NUM(result);
}

const char *sqlite3_libversion(void);
int sqlite3_close(sqlite3*);

sqlite_int64 sqlite3_last_insert_rowid(sqlite3*);

int sqlite3_changes(sqlite3*);
int sqlite3_total_changes(sqlite3*);
void sqlite3_interrupt(sqlite3*);

int sqlite3_complete(const char*);
int sqlite3_complete16(const void *str);

int sqlite3_busy_handler(sqlite3*, int(*)(void*,int), void*);
int sqlite3_busy_timeout(sqlite3*,int);
int sqlite3_set_authorizer(sqlite3*, int(*)(void*,int,const char*,const char*,const char*,const char*), void*);
int sqlite3_trace(sqlite3*, void(*)(void*,const char*), void*);

int sqlite3_open(const char *filename, sqlite3 **OUTPUT);
int sqlite3_open16(const void *filename, sqlite3 **);

int sqlite3_errcode(sqlite3*);
const char *sqlite3_errmsg(sqlite3*);
const void *sqlite3_errmsg16(sqlite3*);

int sqlite3_prepare(sqlite3*,const char* sql,int,sqlite3_stmt**OUTPUT,const char**OUTPUT);
int sqlite3_prepare_v2(sqlite3*,const char* sql,int,sqlite3_stmt**OUTPUT,const char**OUTPUT);
int sqlite3_prepare16(sqlite3*,const void* sql,int,sqlite3_stmt**,const void**);

int sqlite3_bind_blob(sqlite3_stmt*,int,const void *blob,int,void(*free)(void*));
int sqlite3_bind_double(sqlite3_stmt*,int,double);
int sqlite3_bind_int(sqlite3_stmt*,int,int);
int sqlite3_bind_int64(sqlite3_stmt*,int,sqlite_int64);
int sqlite3_bind_null(sqlite3_stmt*,int);
int sqlite3_bind_text(sqlite3_stmt*,int,const char*text,int,void(*free)(void*));
int sqlite3_bind_text16(sqlite3_stmt*,int,const void*utf16,int,void(*free)(void*));

int sqlite3_bind_parameter_count(sqlite3_stmt*);
const char *sqlite3_bind_parameter_name(sqlite3_stmt*,int);
int sqlite3_bind_parameter_index(sqlite3_stmt*,const char*);

int sqlite3_column_count(sqlite3_stmt*);
const char *sqlite3_column_name(sqlite3_stmt*,int);
const void *sqlite3_column_name16(sqlite3_stmt*,int);
const char *sqlite3_column_decltype(sqlite3_stmt*,int);
const void *sqlite3_column_decltype16(sqlite3_stmt*,int);

int sqlite3_step(sqlite3_stmt*);

int sqlite3_data_count(sqlite3_stmt*);

const BLOB *sqlite3_column_blob(sqlite3_stmt*,int);
int sqlite3_column_bytes(sqlite3_stmt*,int);
int sqlite3_column_bytes16(sqlite3_stmt*,int);
double sqlite3_column_double(sqlite3_stmt*,int);
double sqlite3_column_int(sqlite3_stmt*,int);
sqlite_int64 sqlite3_column_int64(sqlite3_stmt*,int);
const char *sqlite3_column_text(sqlite3_stmt*,int);
const void *sqlite3_column_text16(sqlite3_stmt*,int);
int sqlite3_column_type(sqlite3_stmt*,int);

int sqlite3_finalize(sqlite3_stmt*);
int sqlite3_reset(sqlite3_stmt*);

int sqlite3_create_function(sqlite3*,const char*str,int,int,void*,void(*func)(sqlite3_context*,int,sqlite3_value**),void(*step)(sqlite3_context*,int,sqlite3_value**),void(*final)(sqlite3_context*));

int sqlite3_create_function16(sqlite3*,const void*str,int,int,void*,void(*func)(sqlite3_context*,int,sqlite3_value**),void(*step)(sqlite3_context*,int,sqlite3_value**),void(*final)(sqlite3_context*));

int sqlite3_aggregate_count(sqlite3_context*);

const VALBLOB *sqlite3_value_blob(sqlite3_value*);
int sqlite3_value_bytes(sqlite3_value*);
int sqlite3_value_bytes16(sqlite3_value*);
double sqlite3_value_double(sqlite3_value*);
int sqlite3_value_int(sqlite3_value*);
sqlite_int64 sqlite3_value_int64(sqlite3_value*);
const char *sqlite3_value_text(sqlite3_value*);
const void *sqlite3_value_text16(sqlite3_value*);
const void *sqlite3_value_text16le(sqlite3_value*);
const void *sqlite3_value_text16be(sqlite3_value*);
int sqlite3_value_type(sqlite3_value*);

void sqlite3_result_blob(sqlite3_context*,const void *blob,int,void(*free)(void*));
void sqlite3_result_double(sqlite3_context*,double);
void sqlite3_result_error(sqlite3_context*,const char *text,int);
void sqlite3_result_error16(sqlite3_context*,const void *blob,int);
void sqlite3_result_int(sqlite3_context*,int);
void sqlite3_result_int64(sqlite3_context*,sqlite_int64);
void sqlite3_result_text(sqlite3_context*,const char* text,int,void(*free)(void*));
void sqlite3_result_text16(sqlite3_context*,const void* utf16,int,void(*free)(void*));
void sqlite3_result_text16le(sqlite3_context*,const void* utf16,int,void(*free)(void*));
void sqlite3_result_text16be(sqlite3_context*,const void* utf16,int,void(*free)(void*));
void sqlite3_result_value(sqlite3_context*,sqlite3_value*);

VALUE *sqlite3_aggregate_context(sqlite3_context*,int data_size);

#define SQLITE_OK           0   /* Successful result */
/* beginning-of-error-codes */
#define SQLITE_ERROR        1   /* SQL error or missing database */
#define SQLITE_INTERNAL     2   /* NOT USED. Internal logic error in SQLite */
#define SQLITE_PERM         3   /* Access permission denied */
#define SQLITE_ABORT        4   /* Callback routine requested an abort */
#define SQLITE_BUSY         5   /* The database file is locked */
#define SQLITE_LOCKED       6   /* A table in the database is locked */
#define SQLITE_NOMEM        7   /* A malloc() failed */
#define SQLITE_READONLY     8   /* Attempt to write a readonly database */
#define SQLITE_INTERRUPT    9   /* Operation terminated by sqlite3_interrupt()*/
#define SQLITE_IOERR       10   /* Some kind of disk I/O error occurred */
#define SQLITE_CORRUPT     11   /* The database disk image is malformed */
#define SQLITE_NOTFOUND    12   /* NOT USED. Table or record not found */
#define SQLITE_FULL        13   /* Insertion failed because database is full */
#define SQLITE_CANTOPEN    14   /* Unable to open the database file */
#define SQLITE_PROTOCOL    15   /* NOT USED. Database lock protocol error */
#define SQLITE_EMPTY       16   /* Database is empty */
#define SQLITE_SCHEMA      17   /* The database schema changed */
#define SQLITE_TOOBIG      18   /* String or BLOB exceeds size limit */
#define SQLITE_CONSTRAINT  19   /* Abort due to constraint violation */
#define SQLITE_MISMATCH    20   /* Data type mismatch */
#define SQLITE_MISUSE      21   /* Library used incorrectly */
#define SQLITE_NOLFS       22   /* Uses OS features not supported on host */
#define SQLITE_AUTH        23   /* Authorization denied */
#define SQLITE_FORMAT      24   /* Auxiliary database format error */
#define SQLITE_RANGE       25   /* 2nd parameter to sqlite3_bind out of range */
#define SQLITE_NOTADB      26   /* File opened that is not a database file */
#define SQLITE_ROW         100  /* sqlite3_step() has another row ready */
#define SQLITE_DONE        101  /* sqlite3_step() has finished executing */
/* end-of-error-codes */