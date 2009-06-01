static struct errcodes {
  int  error_no;
  const char *error_name;
  const char *exception;
} errors [] = {
#ifdef SQLITE_ERROR
  {    SQLITE_ERROR,
      "SQLITE_ERROR", "SyntaxError"},
#endif
#ifdef SQLITE_INTERNAL
  {    SQLITE_INTERNAL,
      "SQLITE_INTERNAL", "SQLError"},
#endif
#ifdef SQLITE_PERM
  {    SQLITE_PERM,
      "SQLITE_PERM", "ConnectionError"},
#endif
#ifdef SQLITE_ABORT
  {    SQLITE_ABORT,
      "SQLITE_ABORT", "ConnectionError"},
#endif
#ifdef SQLITE_BUSY
  {    SQLITE_BUSY,
      "SQLITE_BUSY", "ConnectionError"},
#endif

#ifdef SQLITE_LOCKED
  {    SQLITE_LOCKED,
      "SQLITE_LOCKED", "ConnectionError"},
#endif
#ifdef SQLITE_NOMEM
  {    SQLITE_NOMEM,
      "SQLITE_NOMEM", "ConnectionError"},
#endif
#ifdef SQLITE_READONLY
  {    SQLITE_READONLY,
      "SQLITE_READONLY", "ConnectionError"},
#endif
#ifdef SQLITE_INTERRUPT
  {    SQLITE_INTERRUPT,
      "SQLITE_INTERRUPT", "ConnectionError"},
#endif
#ifdef SQLITE_IOERR
  {    SQLITE_IOERR,
      "SQLITE_IOERR", "ConnectionError"},
#endif
#ifdef SQLITE_CORRUPT
  {    SQLITE_CORRUPT,
      "SQLITE_CORRUPT", "ConnectionError"},
#endif
#ifdef SQLITE_FULL
  {    SQLITE_FULL,
      "SQLITE_FULL", "ConnectionError"},
#endif
#ifdef SQLITE_CANTOPEN
  {    SQLITE_CANTOPEN,
      "SQLITE_CANTOPEN", "ConnectionError"},
#endif
#ifdef SQLITE_EMPTY
  {    SQLITE_EMPTY,
      "SQLITE_EMPTY", "ConnectionError"},
#endif
#ifdef SQLITE_SCHEMA
  {    SQLITE_SCHEMA,
      "SQLITE_SCHEMA", "DataError"},
#endif
#ifdef SQLITE_TOOBIG
  {    SQLITE_TOOBIG,
      "SQLITE_TOOBIG", "DataError"},
#endif
#ifdef SQLITE_MISMATCH
  {    SQLITE_MISMATCH,
      "SQLITE_MISMATCH", "DataError"},
#endif
#ifdef SQLITE_CONSTRAINT
  {    SQLITE_CONSTRAINT,
      "SQLITE_CONSTRAINT", "IntegrityError"},
#endif
#ifdef SQLITE_MISUSE
  {    SQLITE_MISUSE,
      "SQLITE_MISUSE", "SQLError"},
#endif

#ifdef SQLITE_NOLFS
  {    SQLITE_NOLFS,
      "SQLITE_NOLFS", "ConnectionError"},
#endif
#ifdef SQLITE_FORMAT
  {    SQLITE_FORMAT,
      "SQLITE_FORMAT", "SyntaxError"},
#endif
#ifdef SQLITE_RANGE
  {    SQLITE_RANGE,
      "SQLITE_RANGE", "DataError"},
#endif
#ifdef SQLITE_NOTADB
  {    SQLITE_NOTADB,
      "SQLITE_NOTADB", "ConnectionError"},
#endif

#ifdef SQLITE_ROW
  {    SQLITE_ROW,
      "SQLITE_ROW", "SyntaxError"},
#endif
  {0, NULL, NULL}
};
