#ifndef RUBY_COMPAT_H
#define RUBY_COMPAT_H

/*
 * Rules for better ruby C extensions:
 *
 * Never use the R<TYPE> macros directly, always use R<TYPE>_<FIELD>
 *
 * Never compare with RBASIC(obj)->klass, always use
 *   rb_obj_is_instance_of()
 *
 * Never use RHASH(obj)->tbl or RHASH_TBL().
 *
 */


// Array
#ifndef RARRAY_PTR
#define RARRAY_PTR(obj) RARRAY(obj)->ptr
#endif

#ifndef RARRAY_LEN
#define RARRAY_LEN(obj) RARRAY(obj)->len
#endif

// String
#ifndef RSTRING_PTR
#define RSTRING_PTR(obj) RSTRING(obj)->ptr
#endif

#ifndef RSTRING_LEN
#define RSTRING_LEN(obj) RSTRING(obj)->len
#endif

#ifndef rb_str_ptr
#define rb_str_ptr(str) RSTRING_PTR(str)
#endif

#ifndef rb_str_ptr_readonly
#define rb_str_ptr_readonly(str) RSTRING_PTR(str)
#endif

#ifndef rb_str_flush
#define rb_str_flush(str)
#endif

#ifndef rb_str_update
#define rb_str_update(str)
#endif

#ifndef rb_str_len
#define rb_str_len(str) RSTRING_LEN(str)
#endif

#endif
