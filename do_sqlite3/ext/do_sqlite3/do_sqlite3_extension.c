#include "do_sqlite3.h"

static VALUE ID_CONST_GET;
static VALUE mDO;
static VALUE mSqlite3;
static VALUE eConnectionError;
static VALUE cDO_Extension;
static VALUE cExtension;

/*****************************************************/
/* File used for providing extensions on the default */
/* API that are driver specific.                     */
/*****************************************************/
static VALUE cExtension_enable_load_extension(VALUE self, VALUE on) {
  VALUE id_connection = rb_intern("connection");

  VALUE connection = rb_funcall(self, id_connection, 0);
  sqlite3 *db;
  int status;

  if (connection == Qnil) { return Qfalse; }

  // Retrieve the actual connection from the
  connection = rb_iv_get(self, "@connection");

  if (connection == Qnil) { return Qfalse; }

  db = DATA_PTR(connection);

  if(db == NULL) { return Qfalse; }

  status = sqlite3_enable_load_extension(db, on == Qtrue ? 1 : 0);

  if ( status != SQLITE_OK ) {
    rb_raise(eConnectionError, "Couldn't enable extension loading");
  }
  return Qtrue;
}

static VALUE cExtension_load_extension(VALUE self, VALUE path) {
  VALUE id_connection = rb_intern("connection");

  VALUE connection = rb_funcall(self, id_connection, 0);
  sqlite3 *db;
  const char *extension_path  = rb_str_ptr_readonly(path);
  char* errmsg = sqlite3_malloc(1024);
  int status;

  if (connection == Qnil) { return Qfalse; }

  // Retrieve the actual connection from the
  connection = rb_iv_get(self, "@connection");

  if (connection == Qnil) { return Qfalse; }

  db = DATA_PTR(connection);

  if(db == NULL) { return Qfalse; }

  status = sqlite3_load_extension(db, extension_path, 0, &errmsg);

  if ( status != SQLITE_OK ) {
    VALUE errexp = rb_exc_new2(eConnectionError, errmsg);
    sqlite3_free(errmsg);
    rb_exc_raise(errexp);
  }
  return Qtrue;
}

void Init_do_sqlite3_extension() {
  ID_CONST_GET = rb_intern("const_get");
  mDO = CONST_GET(rb_mKernel, "DataObjects");
  cDO_Extension = CONST_GET(mDO, "Extension");
  mSqlite3 = rb_define_module_under(mDO, "Sqlite3");
  cExtension = DRIVER_CLASS("Extension", cDO_Extension);
  rb_define_method(cExtension, "load_extension", cExtension_load_extension, 1);
  rb_define_method(cExtension, "enable_load_extension", cExtension_enable_load_extension, 1);
}