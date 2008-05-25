#!/bin/sh
mkdir -p pkg

cd data_objects
rake gem
cp pkg/*.gem ../pkg/
cd ..

cd do_mysql
rake gem
cp pkg/*.gem ../pkg/
cd ..

cd do_sqlite3
rake gem
cp pkg/*.gem ../pkg/
cd ..

cd do_postgres
rake gem
cp pkg/*.gem ../pkg/
cd ..
