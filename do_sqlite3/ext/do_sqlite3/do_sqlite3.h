#ifndef DO_SQLITE3_H
#define DO_SQLITE3_H

#include <ruby.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <locale.h>
#include <sqlite3.h>
#include "compat.h"

#ifndef HAVE_SQLITE3_PREPARE_V2
#define sqlite3_prepare_v2 sqlite3_prepare
#endif

extern VALUE mSqlite3;
extern void Init_do_sqlite3_extension();

#endif
