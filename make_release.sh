#!/bin/sh
mkdir -p pkg

cd data_objects
rake package
cp pkg/*.gem ../pkg/
cd ..

cd do_mysql
rake package
cp pkg/*.gem ../pkg/
cd ..

cd do_sqlite3
rake package
cp pkg/*.gem ../pkg/
cd ..

cd do_postgres
rake package
cp pkg/*.gem ../pkg/
cd ..
