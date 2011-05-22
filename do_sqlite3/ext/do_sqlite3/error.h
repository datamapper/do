#ifndef _DO_SQLITE3_ERROR_H_
#define _DO_SQLITE3_ERROR_H_

#include "do_common.h"

static struct errcodes do_sqlite3_errors[] = {
#ifdef SQLITE_ERROR
  ERRCODE(SQLITE_ERROR, "SyntaxError"),
#endif
#ifdef SQLITE_INTERNAL
  ERRCODE(SQLITE_INTERNAL, "SQLError"),
#endif
#ifdef SQLITE_PERM
  ERRCODE(SQLITE_PERM, "ConnectionError"),
#endif
#ifdef SQLITE_ABORT
  ERRCODE(SQLITE_ABORT, "ConnectionError"),
#endif
#ifdef SQLITE_BUSY
  ERRCODE(SQLITE_BUSY, "ConnectionError"),
#endif

#ifdef SQLITE_LOCKED
  ERRCODE(SQLITE_LOCKED, "ConnectionError"),
#endif
#ifdef SQLITE_NOMEM
  ERRCODE(SQLITE_NOMEM, "ConnectionError"),
#endif
#ifdef SQLITE_READONLY
  ERRCODE(SQLITE_READONLY, "ConnectionError"),
#endif
#ifdef SQLITE_INTERRUPT
  ERRCODE(SQLITE_INTERRUPT, "ConnectionError"),
#endif
#ifdef SQLITE_IOERR
  ERRCODE(SQLITE_IOERR, "ConnectionError"),
#endif
#ifdef SQLITE_CORRUPT
  ERRCODE(SQLITE_CORRUPT, "ConnectionError"),
#endif
#ifdef SQLITE_FULL
  ERRCODE(SQLITE_FULL, "ConnectionError"),
#endif
#ifdef SQLITE_CANTOPEN
  ERRCODE(SQLITE_CANTOPEN, "ConnectionError"),
#endif
#ifdef SQLITE_EMPTY
  ERRCODE(SQLITE_EMPTY, "ConnectionError"),
#endif
#ifdef SQLITE_SCHEMA
  ERRCODE(SQLITE_SCHEMA, "DataError"),
#endif
#ifdef SQLITE_TOOBIG
  ERRCODE(SQLITE_TOOBIG, "DataError"),
#endif
#ifdef SQLITE_MISMATCH
  ERRCODE(SQLITE_MISMATCH, "DataError"),
#endif
#ifdef SQLITE_CONSTRAINT
  ERRCODE(SQLITE_CONSTRAINT, "IntegrityError"),
#endif
#ifdef SQLITE_MISUSE
  ERRCODE(SQLITE_MISUSE, "SQLError"),
#endif

#ifdef SQLITE_NOLFS
  ERRCODE(SQLITE_NOLFS, "ConnectionError"),
#endif
#ifdef SQLITE_FORMAT
  ERRCODE(SQLITE_FORMAT, "SyntaxError"),
#endif
#ifdef SQLITE_RANGE
  ERRCODE(SQLITE_RANGE, "DataError"),
#endif
#ifdef SQLITE_NOTADB
  ERRCODE(SQLITE_NOTADB, "ConnectionError"),
#endif

#ifdef SQLITE_ROW
  ERRCODE(SQLITE_ROW, "SyntaxError"),
#endif
  {0, NULL, NULL}
};

#endif
