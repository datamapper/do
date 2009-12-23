static struct errcodes {
  int  error_no;
  const char *error_name;
  const char *exception;
} errors [] = {
#ifdef ER_ABORTING_CONNECTION
  {    ER_ABORTING_CONNECTION,
      "ER_ABORTING_CONNECTION", "ConnectionError"},
#endif
#ifdef ER_NET_PACKET_TOO_LARGE
  {    ER_NET_PACKET_TOO_LARGE,
      "ER_NET_PACKET_TOO_LARGE", "ConnectionError"},
#endif
#ifdef ER_NET_READ_ERROR_FROM_PIPE
  {    ER_NET_READ_ERROR_FROM_PIPE,
      "ER_NET_READ_ERROR_FROM_PIPE", "ConnectionError"},
#endif
#ifdef ER_NET_FCNTL_ERROR
  {    ER_NET_FCNTL_ERROR,
      "ER_NET_FCNTL_ERROR", "ConnectionError"},
#endif
#ifdef ER_NET_PACKETS_OUT_OF_ORDER
  {    ER_NET_PACKETS_OUT_OF_ORDER,
      "ER_NET_PACKETS_OUT_OF_ORDER", "ConnectionError"},
#endif
#ifdef ER_NET_UNCOMPRESS_ERROR
  {    ER_NET_UNCOMPRESS_ERROR,
      "ER_NET_UNCOMPRESS_ERROR", "ConnectionError"},
#endif
#ifdef ER_NET_READ_ERROR
  {    ER_NET_READ_ERROR,
      "ER_NET_READ_ERROR", "ConnectionError"},
#endif
#ifdef ER_NET_READ_INTERRUPTED
  {    ER_NET_READ_INTERRUPTED,
      "ER_NET_READ_INTERRUPTED", "ConnectionError"},
#endif
#ifdef ER_NET_WRITE_INTERRUPTED
  {    ER_NET_WRITE_INTERRUPTED,
      "ER_NET_WRITE_INTERRUPTED", "ConnectionError"},
#endif
#ifdef ER_CON_COUNT_ERROR
  {    ER_CON_COUNT_ERROR,
      "ER_CON_COUNT_ERROR", "ConnectionError"},
#endif
#ifdef ER_BAD_HOST_ERROR
  {    ER_BAD_HOST_ERROR,
      "ER_BAD_HOST_ERROR", "ConnectionError"},
#endif
#ifdef ER_HANDSHAKE_ERROR
  {    ER_HANDSHAKE_ERROR,
      "ER_HANDSHAKE_ERROR", "ConnectionError"},
#endif
#ifdef ER_DBACCESS_DENIED_ERROR
  {    ER_DBACCESS_DENIED_ERROR,
      "ER_DBACCESS_DENIED_ERROR", "ConnectionError"},
#endif
#ifdef ER_ACCESS_DENIED_ERROR
  {    ER_ACCESS_DENIED_ERROR,
      "ER_ACCESS_DENIED_ERROR", "ConnectionError"},
#endif
#ifdef ER_UNKNOWN_COM_ERROR
  {    ER_UNKNOWN_COM_ERROR,
      "ER_UNKNOWN_COM_ERROR", "ConnectionError"},
#endif
#ifdef ER_SERVER_SHUTDOWN
  {    ER_SERVER_SHUTDOWN,
      "ER_SERVER_SHUTDOWN", "ConnectionError"},
#endif
#ifdef ER_FORCING_CLOSE
  {    ER_FORCING_CLOSE,
      "ER_FORCING_CLOSE", "ConnectionError"},
#endif
#ifdef ER_IPSOCK_ERROR
  {    ER_IPSOCK_ERROR,
      "ER_IPSOCK_ERROR", "ConnectionError"},
#endif

#ifdef ER_INVALID_USE_OF_NULL
  {    ER_INVALID_USE_OF_NULL,
      "ER_INVALID_USE_OF_NULL", "DataError"},
#endif
#ifdef ER_DIVISION_BY_ZERO
  {    ER_DIVISION_BY_ZERO,
      "ER_DIVISION_BY_ZERO", "DataError"},
#endif
#ifdef ER_ILLEGAL_VALUE_FOR_TYPE
  {    ER_ILLEGAL_VALUE_FOR_TYPE,
      "ER_ILLEGAL_VALUE_FOR_TYPE", "DataError"},
#endif
#ifdef ER_WARN_NULL_TO_NOTNULL
  {    ER_WARN_NULL_TO_NOTNULL,
      "ER_WARN_NULL_TO_NOTNULL", "DataError"},
#endif
#ifdef ER_WARN_DATA_OUT_OF_RANGE
  {    ER_WARN_DATA_OUT_OF_RANGE,
      "ER_WARN_DATA_OUT_OF_RANGE", "DataError"},
#endif
#ifdef ER_WARN_TOO_MANY_RECORDS
  {    ER_WARN_TOO_MANY_RECORDS,
      "ER_WARN_TOO_MANY_RECORDS", "DataError"},
#endif
#ifdef ER_WARN_TOO_FEW_RECORDS
  {    ER_WARN_TOO_FEW_RECORDS,
      "ER_WARN_TOO_FEW_RECORDS", "DataError"},
#endif
#ifdef ER_TRUNCATED_WRONG_VALUE
  {    ER_TRUNCATED_WRONG_VALUE,
      "ER_TRUNCATED_WRONG_VALUE", "DataError"},
#endif
#ifdef ER_DATETIME_FUNCTION_OVERFLOW
  {    ER_DATETIME_FUNCTION_OVERFLOW,
      "ER_DATETIME_FUNCTION_OVERFLOW", "DataError"},
#endif
#ifdef ER_DATA_TOO_LONG
  {    ER_DATA_TOO_LONG,
      "ER_DATA_TOO_LONG", "DataError"},
#endif
#ifdef ER_UNKNOWN_TIME_ZONE
  {    ER_UNKNOWN_TIME_ZONE,
      "ER_UNKNOWN_TIME_ZONE", "DataError"},
#endif
#ifdef ER_INVALID_CHARACTER_STRING
  {    ER_INVALID_CHARACTER_STRING,
      "ER_INVALID_CHARACTER_STRING", "DataError"},
#endif
#ifdef ER_WARN_INVALID_TIMESTAMP
  {    ER_WARN_INVALID_TIMESTAMP,
      "ER_WARN_INVALID_TIMESTAMP", "DataError"},
#endif
#ifdef ER_CANT_CREATE_GEOMETRY_OBJECT
  {    ER_CANT_CREATE_GEOMETRY_OBJECT,
      "ER_CANT_CREATE_GEOMETRY_OBJECT", "DataError"},
#endif

#ifdef ER_BAD_NULL_ERROR
  {    ER_BAD_NULL_ERROR,
      "ER_BAD_NULL_ERROR", "IntegrityError"},
#endif
#ifdef ER_NON_UNIQ_ERROR
  {    ER_NON_UNIQ_ERROR,
      "ER_NON_UNIQ_ERROR", "IntegrityError"},
#endif
#ifdef ER_DUP_KEY
  {    ER_DUP_KEY,
      "ER_DUP_KEY", "IntegrityError"},
#endif
#ifdef ER_DUP_ENTRY
  {    ER_DUP_ENTRY,
      "ER_DUP_ENTRY", "IntegrityError"},
#endif
#ifdef ER_DUP_UNIQUE
  {    ER_DUP_UNIQUE,
      "ER_DUP_UNIQUE", "IntegrityError"},
#endif
#ifdef ER_NO_REFERENCED_ROW
  {    ER_NO_REFERENCED_ROW,
      "ER_NO_REFERENCED_ROW", "IntegrityError"},
#endif
#ifdef ER_NO_REFERENCED_ROW_2
  {    ER_NO_REFERENCED_ROW_2,
      "ER_NO_REFERENCED_ROW_2", "IntegrityError"},
#endif
#ifdef ER_ROW_IS_REFERENCED
  {    ER_ROW_IS_REFERENCED,
      "ER_ROW_IS_REFERENCED", "IntegrityError"},
#endif
#ifdef ER_ROW_IS_REFERENCED_2
  {    ER_ROW_IS_REFERENCED_2,
      "ER_ROW_IS_REFERENCED_2", "IntegrityError"},
#endif

#ifdef ER_BLOB_KEY_WITHOUT_LENGTH
  {    ER_BLOB_KEY_WITHOUT_LENGTH,
      "ER_BLOB_KEY_WITHOUT_LENGTH", "SyntaxError"},
#endif
#ifdef ER_PRIMARY_CANT_HAVE_NULL
  {    ER_PRIMARY_CANT_HAVE_NULL,
      "ER_PRIMARY_CANT_HAVE_NULL", "SyntaxError"},
#endif
#ifdef ER_TOO_MANY_ROWS
  {    ER_TOO_MANY_ROWS,
      "ER_TOO_MANY_ROWS", "SyntaxError"},
#endif
#ifdef ER_REQUIRES_PRIMARY_KEY
  {    ER_REQUIRES_PRIMARY_KEY,
      "ER_REQUIRES_PRIMARY_KEY", "SyntaxError"},
#endif
#ifdef ER_CHECK_NO_SUCH_TABLE
  {    ER_CHECK_NO_SUCH_TABLE,
      "ER_CHECK_NO_SUCH_TABLE", "SyntaxError"},
#endif
#ifdef ER_CHECK_NOT_IMPLEMENTED
  {    ER_CHECK_NOT_IMPLEMENTED,
      "ER_CHECK_NOT_IMPLEMENTED", "SyntaxError"},
#endif
#ifdef ER_TOO_MANY_USER_CONNECTIONS
  {    ER_TOO_MANY_USER_CONNECTIONS,
      "ER_TOO_MANY_USER_CONNECTIONS", "SyntaxError"},
#endif
#ifdef ER_NO_PERMISSION_TO_CREATE_USER
  {    ER_NO_PERMISSION_TO_CREATE_USER,
      "ER_NO_PERMISSION_TO_CREATE_USER", "SyntaxError"},
#endif
#ifdef ER_USER_LIMIT_REACHED
  {    ER_USER_LIMIT_REACHED,
      "ER_USER_LIMIT_REACHED", "SyntaxError"},
#endif
#ifdef ER_SPECIFIC_ACCESS_DENIED_ERROR
  {    ER_SPECIFIC_ACCESS_DENIED_ERROR,
      "ER_SPECIFIC_ACCESS_DENIED_ERROR", "SyntaxError"},
#endif
#ifdef ER_NO_DEFAULT
  {    ER_NO_DEFAULT,
      "ER_NO_DEFAULT", "SyntaxError"},
#endif
#ifdef ER_WRONG_VALUE_FOR_VAR
  {    ER_WRONG_VALUE_FOR_VAR,
      "ER_WRONG_VALUE_FOR_VAR", "SyntaxError"},
#endif
#ifdef ER_WRONG_TYPE_FOR_VAR
  {    ER_WRONG_TYPE_FOR_VAR,
      "ER_WRONG_TYPE_FOR_VAR", "SyntaxError"},
#endif
#ifdef ER_CANT_USE_OPTION_HERE
  {    ER_CANT_USE_OPTION_HERE,
      "ER_CANT_USE_OPTION_HERE", "SyntaxError"},
#endif
#ifdef ER_NOT_SUPPORTED_YET
  {    ER_NOT_SUPPORTED_YET,
      "ER_NOT_SUPPORTED_YET", "SyntaxError"},
#endif
#ifdef ER_WRONG_FK_DEF
  {    ER_WRONG_FK_DEF,
      "ER_WRONG_FK_DEF", "SyntaxError"},
#endif
#ifdef ER_ILLEGAL_REFERENCE
  {    ER_ILLEGAL_REFERENCE,
      "ER_ILLEGAL_REFERENCE", "SyntaxError"},
#endif
#ifdef ER_DERIVED_MUST_HAVE_ALIAS
  {    ER_DERIVED_MUST_HAVE_ALIAS,
      "ER_DERIVED_MUST_HAVE_ALIAS", "SyntaxError"},
#endif
#ifdef ER_TABLENAME_NOT_ALLOWED_HERE
  {    ER_TABLENAME_NOT_ALLOWED_HERE,
      "ER_TABLENAME_NOT_ALLOWED_HERE", "SyntaxError"},
#endif
#ifdef ER_SPATIAL_CANT_HAVE_NULL
  {    ER_SPATIAL_CANT_HAVE_NULL,
      "ER_SPATIAL_CANT_HAVE_NULL", "SyntaxError"},
#endif
#ifdef ER_COLLATION_CHARSET_MISMATCH
  {    ER_COLLATION_CHARSET_MISMATCH,
      "ER_COLLATION_CHARSET_MISMATCH", "SyntaxError"},
#endif
#ifdef ER_WRONG_NAME_FOR_INDEX
  {    ER_WRONG_NAME_FOR_INDEX,
      "ER_WRONG_NAME_FOR_INDEX", "SyntaxError"},
#endif
#ifdef ER_WRONG_NAME_FOR_CATALOG
  {    ER_WRONG_NAME_FOR_CATALOG,
      "ER_WRONG_NAME_FOR_CATALOG", "SyntaxError"},
#endif
#ifdef ER_UNKNOWN_STORAGE_ENGINE
  {    ER_UNKNOWN_STORAGE_ENGINE,
      "ER_UNKNOWN_STORAGE_ENGINE", "SyntaxError"},
#endif
#ifdef ER_SP_ALREADY_EXISTS
  {    ER_SP_ALREADY_EXISTS,
      "ER_SP_ALREADY_EXISTS", "SyntaxError"},
#endif
#ifdef ER_SP_DOES_NOT_EXIST
  {    ER_SP_DOES_NOT_EXIST,
      "ER_SP_DOES_NOT_EXIST", "SyntaxError"},
#endif
#ifdef ER_SP_LILABEL_MISMATCH
  {    ER_SP_LILABEL_MISMATCH,
      "ER_SP_LILABEL_MISMATCH", "SyntaxError"},
#endif
#ifdef ER_SP_LABEL_REDEFINE
  {    ER_SP_LABEL_REDEFINE,
      "ER_SP_LABEL_REDEFINE", "SyntaxError"},
#endif
#ifdef ER_SP_LABEL_MISMATCH
  {    ER_SP_LABEL_MISMATCH,
      "ER_SP_LABEL_MISMATCH", "SyntaxError"},
#endif
#ifdef ER_SP_BADRETURN
  {    ER_SP_BADRETURN,
      "ER_SP_BADRETURN", "SyntaxError"},
#endif
#ifdef ER_SP_WRONG_NO_OF_ARGS
  {    ER_SP_WRONG_NO_OF_ARGS,
      "ER_SP_WRONG_NO_OF_ARGS", "SyntaxError"},
#endif
#ifdef ER_SP_COND_MISMATCH
  {    ER_SP_COND_MISMATCH,
      "ER_SP_COND_MISMATCH", "SyntaxError"},
#endif
#ifdef ER_SP_NORETURN
  {    ER_SP_NORETURN,
      "ER_SP_NORETURN", "SyntaxError"},
#endif
#ifdef ER_SP_BAD_CURSOR_QUERY
  {    ER_SP_BAD_CURSOR_QUERY,
      "ER_SP_BAD_CURSOR_QUERY", "SyntaxError"},
#endif
#ifdef ER_SP_BAD_CURSOR_SELECT
  {    ER_SP_BAD_CURSOR_SELECT,
      "ER_SP_BAD_CURSOR_SELECT", "SyntaxError"},
#endif
#ifdef ER_SP_CURSOR_MISMATCH
  {    ER_SP_CURSOR_MISMATCH,
      "ER_SP_CURSOR_MISMATCH", "SyntaxError"},
#endif
#ifdef ER_SP_UNDECLARED_VAR
  {    ER_SP_UNDECLARED_VAR,
      "ER_SP_UNDECLARED_VAR", "SyntaxError"},
#endif
#ifdef ER_SP_DUP_PARAM
  {    ER_SP_DUP_PARAM,
      "ER_SP_DUP_PARAM", "SyntaxError"},
#endif
#ifdef ER_SP_DUP_VAR
  {    ER_SP_DUP_VAR,
      "ER_SP_DUP_VAR", "SyntaxError"},
#endif
#ifdef ER_SP_DUP_COND
  {    ER_SP_DUP_COND,
      "ER_SP_DUP_COND", "SyntaxError"},
#endif
#ifdef ER_SP_DUP_CURS
  {    ER_SP_DUP_CURS,
      "ER_SP_DUP_CURS", "SyntaxError"},
#endif
#ifdef ER_SP_VARCOND_AFTER_CURSHNDLR
  {    ER_SP_VARCOND_AFTER_CURSHNDLR,
      "ER_SP_VARCOND_AFTER_CURSHNDLR", "SyntaxError"},
#endif
#ifdef ER_SP_CURSOR_AFTER_HANDLER
  {    ER_SP_CURSOR_AFTER_HANDLER,
      "ER_SP_CURSOR_AFTER_HANDLER", "SyntaxError"},
#endif
#ifdef ER_SP_CASE_NOT_FOUND
  {    ER_SP_CASE_NOT_FOUND,
      "ER_SP_CASE_NOT_FOUND", "SyntaxError"},
#endif
#ifdef ER_PROCACCESS_DENIED_ERROR
  {    ER_PROCACCESS_DENIED_ERROR,
      "ER_PROCACCESS_DENIED_ERROR", "SyntaxError"},
#endif
#ifdef ER_NONEXISTING_PROC_GRANT
  {    ER_NONEXISTING_PROC_GRANT,
      "ER_NONEXISTING_PROC_GRANT", "SyntaxError"},
#endif
#ifdef ER_SP_BAD_SQLSTATE
  {    ER_SP_BAD_SQLSTATE,
      "ER_SP_BAD_SQLSTATE", "SyntaxError"},
#endif
#ifdef ER_CANT_CREATE_USER_WITH_GRANT
  {    ER_CANT_CREATE_USER_WITH_GRANT,
      "ER_CANT_CREATE_USER_WITH_GRANT", "SyntaxError"},
#endif
#ifdef ER_SP_DUP_HANDLER
  {    ER_SP_DUP_HANDLER,
      "ER_SP_DUP_HANDLER", "SyntaxError"},
#endif
#ifdef ER_SP_NOT_VAR_ARG
  {    ER_SP_NOT_VAR_ARG,
      "ER_SP_NOT_VAR_ARG", "SyntaxError"},
#endif
#ifdef ER_TOO_BIG_SCALE
  {    ER_TOO_BIG_SCALE,
      "ER_TOO_BIG_SCALE", "SyntaxError"},
#endif
#ifdef ER_TOO_BIG_PRECISION
  {    ER_TOO_BIG_PRECISION,
      "ER_TOO_BIG_PRECISION", "SyntaxError"},
#endif
#ifdef ER_M_BIGGER_THAN_D
  {    ER_M_BIGGER_THAN_D,
      "ER_M_BIGGER_THAN_D", "SyntaxError"},
#endif
#ifdef ER_TOO_LONG_BODY
  {    ER_TOO_LONG_BODY,
      "ER_TOO_LONG_BODY", "SyntaxError"},
#endif
#ifdef ER_TOO_BIG_DISPLAYWIDTH
  {    ER_TOO_BIG_DISPLAYWIDTH,
      "ER_TOO_BIG_DISPLAYWIDTH", "SyntaxError"},
#endif
#ifdef ER_SP_BAD_VAR_SHADOW
  {    ER_SP_BAD_VAR_SHADOW,
      "ER_SP_BAD_VAR_SHADOW", "SyntaxError"},
#endif
#ifdef ER_SP_WRONG_NAME
  {    ER_SP_WRONG_NAME,
      "ER_SP_WRONG_NAME", "SyntaxError"},
#endif
#ifdef ER_SP_NO_AGGREGATE
  {    ER_SP_NO_AGGREGATE,
      "ER_SP_NO_AGGREGATE", "SyntaxError"},
#endif
#ifdef ER_MAX_PREPARED_STMT_COUNT_REACHED
  {    ER_MAX_PREPARED_STMT_COUNT_REACHED,
      "ER_MAX_PREPARED_STMT_COUNT_REACHED", "SyntaxError"},
#endif
#ifdef ER_NON_GROUPING_FIELD_USED
  {    ER_NON_GROUPING_FIELD_USED,
      "ER_NON_GROUPING_FIELD_USED", "SyntaxError"},
#endif
#ifdef ER_BAD_DB_ERROR
  {    ER_BAD_DB_ERROR,
      "ER_BAD_DB_ERROR", "SyntaxError"},
#endif
#ifdef ER_TABLE_EXISTS_ERROR
  {    ER_TABLE_EXISTS_ERROR,
      "ER_TABLE_EXISTS_ERROR", "SyntaxError"},
#endif
#ifdef ER_BAD_TABLE_ERROR
  {    ER_BAD_TABLE_ERROR,
      "ER_BAD_TABLE_ERROR", "SyntaxError"},
#endif
#ifdef ER_NO_SUCH_TABLE
  {    ER_NO_SUCH_TABLE,
      "ER_NO_SUCH_TABLE", "SyntaxError"},
#endif
#ifdef ER_NONEXISTING_TABLE_GRANT
  {    ER_NONEXISTING_TABLE_GRANT,
      "ER_NONEXISTING_TABLE_GRANT", "SyntaxError"},
#endif
#ifdef ER_GRANT_WRONG_HOST_OR_USER
  {    ER_GRANT_WRONG_HOST_OR_USER,
      "ER_GRANT_WRONG_HOST_OR_USER", "SyntaxError"},
#endif
#ifdef ER_ILLEGAL_GRANT_FOR_TABLE
  {    ER_ILLEGAL_GRANT_FOR_TABLE,
      "ER_ILLEGAL_GRANT_FOR_TABLE", "SyntaxError"},
#endif
#ifdef ER_COLUMNACCESS_DENIED_ERROR
  {    ER_COLUMNACCESS_DENIED_ERROR,
      "ER_COLUMNACCESS_DENIED_ERROR", "SyntaxError"},
#endif
#ifdef ER_TABLEACCESS_DENIED_ERROR
  {    ER_TABLEACCESS_DENIED_ERROR,
      "ER_TABLEACCESS_DENIED_ERROR", "SyntaxError"},
#endif
#ifdef ER_NONEXISTING_GRANT
  {    ER_NONEXISTING_GRANT,
      "ER_NONEXISTING_GRANT", "SyntaxError"},
#endif
#ifdef ER_MIX_OF_GROUP_FUNC_AND_FIELDS
  {    ER_MIX_OF_GROUP_FUNC_AND_FIELDS,
      "ER_MIX_OF_GROUP_FUNC_AND_FIELDS", "SyntaxError"},
#endif
#ifdef ER_REGEXP_ERROR
  {    ER_REGEXP_ERROR,
      "ER_REGEXP_ERROR", "SyntaxError"},
#endif
#ifdef ER_NOT_ALLOWED_COMMAND
  {    ER_NOT_ALLOWED_COMMAND,
      "ER_NOT_ALLOWED_COMMAND", "SyntaxError"},
#endif
#ifdef ER_SYNTAX_ERROR
  {    ER_SYNTAX_ERROR,
      "ER_SYNTAX_ERROR", "SyntaxError"},
#endif
#ifdef ER_WRONG_NUMBER_OF_COLUMNS_IN_SELECT
  {    ER_WRONG_NUMBER_OF_COLUMNS_IN_SELECT,
      "ER_WRONG_NUMBER_OF_COLUMNS_IN_SELECT", "SyntaxError"},
#endif

#ifdef ER_CANT_DO_THIS_DURING_AN_TRANSACTION
  {    ER_CANT_DO_THIS_DURING_AN_TRANSACTION,
      "ER_CANT_DO_THIS_DURING_AN_TRANSACTION", "TransactionError"},
#endif
#ifdef ER_ERROR_DURING_COMMIT
  {    ER_ERROR_DURING_COMMIT,
      "ER_ERROR_DURING_COMMIT", "TransactionError"},
#endif
#ifdef ER_ERROR_DURING_ROLLBACK
  {    ER_ERROR_DURING_ROLLBACK,
      "ER_ERROR_DURING_ROLLBACK", "TransactionError"},
#endif
#ifdef ER_ERROR_DURING_CHECKPOINT
  {    ER_ERROR_DURING_CHECKPOINT,
      "ER_ERROR_DURING_CHECKPOINT", "TransactionError"},
#endif
#ifdef ER_LOCK_DEADLOCK
  {    ER_LOCK_DEADLOCK,
      "ER_LOCK_DEADLOCK", "TransactionError"},
#endif
#ifdef ER_XAER_NOTA
  {    ER_XAER_NOTA,
      "ER_XAER_NOTA", "TransactionError"},
#endif
#ifdef ER_XAER_INVAL
  {    ER_XAER_INVAL,
      "ER_XAER_INVAL", "TransactionError"},
#endif
#ifdef ER_XAER_RMFAIL
  {    ER_XAER_RMFAIL,
      "ER_XAER_RMFAIL", "TransactionError"},
#endif
#ifdef ER_XAER_OUTSIDE
  {    ER_XAER_OUTSIDE,
      "ER_XAER_OUTSIDE", "TransactionError"},
#endif
#ifdef ER_XAER_RMERR
  {    ER_XAER_RMERR,
      "ER_XAER_RMERR", "TransactionError"},
#endif
#ifdef ER_XA_RBROLLBACK
  {    ER_XA_RBROLLBACK,
      "ER_XA_RBROLLBACK", "TransactionError"},
#endif
#ifdef ER_XA_RBTIMEOUT
  {    ER_XA_RBTIMEOUT,
      "ER_XA_RBTIMEOUT", "TransactionError"},
#endif
#ifdef ER_XA_RBDEADLOCK
  {    ER_XA_RBDEADLOCK,
      "ER_XA_RBDEADLOCK", "TransactionError"},
#endif
  {0, NULL, NULL}
};
