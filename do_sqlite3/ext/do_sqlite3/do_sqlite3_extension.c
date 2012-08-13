#include <ruby.h>
#include "do_common.h"
#include "do_sqlite3.h"

VALUE cSqlite3Extension;

/*****************************************************/
/* File used for providing extensions on the default */
/* API that are driver specific.                     */
/*****************************************************/
VALUE do_sqlite3_cExtension_enable_load_extension(VALUE self, VALUE on) {
#ifdef HAVE_SQLITE3_ENABLE_LOAD_EXTENSION
  VALUE id_connection = rb_intern("connection");
  VALUE connection = rb_funcall(self, id_connection, 0);

  if (connection == Qnil) { return Qfalse; }

  // Retrieve the actual connection from the
  VALUE sqlite3_connection = rb_iv_get(connection, "@connection");

  if (sqlite3_connection == Qnil) { return Qfalse; }

  sqlite3 *db;

  Data_Get_Struct(sqlite3_connection, sqlite3, db);


  if (!(db = DATA_PTR(connection))) {
    return Qfalse;
  }

  int status = sqlite3_enable_load_extension(db, on == Qtrue ? 1 : 0);

  if (status != SQLITE_OK) {
    rb_raise(eConnectionError, "Couldn't enable extension loading");
  }

  return Qtrue;
#else
  return Qfalse;
#endif
}

VALUE do_sqlite3_cExtension_load_extension(VALUE self, VALUE path) {
#ifdef HAVE_SQLITE3_ENABLE_LOAD_EXTENSION
  VALUE connection = rb_iv_get(self, "@connection");

  if (connection == Qnil) { return Qfalse; }

  // Retrieve the actual connection from the object
  VALUE sqlite3_connection = rb_iv_get(connection, "@connection");

  if (sqlite3_connection == Qnil) { return Qfalse; }

  sqlite3 *db;

  Data_Get_Struct(sqlite3_connection, sqlite3, db);

  const char *extension_path  = rb_str_ptr_readonly(path);
  char *errmsg = sqlite3_malloc(1024);

  if (!errmsg) {
    return Qfalse;
  }

  int status = sqlite3_load_extension(db, extension_path, 0, &errmsg);

  if (status != SQLITE_OK) {
    VALUE errexp = rb_exc_new2(eConnectionError, errmsg);

    sqlite3_free(errmsg);
    rb_exc_raise(errexp);
  }

  sqlite3_free(errmsg);
  return Qtrue;
#else
  return Qfalse;
#endif
}

void Init_do_sqlite3_extension() {
  cSqlite3Extension = rb_define_class_under(mSqlite3, "Extension", cDO_Extension);
  rb_define_method(cSqlite3Extension, "load_extension", do_sqlite3_cExtension_load_extension, 1);
  rb_define_method(cSqlite3Extension, "enable_load_extension", do_sqlite3_cExtension_enable_load_extension, 1);
}
