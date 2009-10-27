do_oracle
=========

An Oracle driver for DataObjects

install oracle jdbc driver in maven
===================================

$ mvn install
will produce an error and give you message like (maybe with a different version). please follow these instructions to install the 

  Try downloading the file manually from: 
      http://www.oracle.com/technology/software/tech/java/sqlj_jdbc/index.html

  Then, install it using the command: 
      mvn install:install-file -DgroupId=com.oracle -DartifactId=ojdbc14 -Dversion=10.2.0.3.0 -Dpackaging=jar -Dfile=/path/to/file

  Alternatively, if you host your own repository you can deploy the file there: 
      mvn deploy:deploy-file -DgroupId=com.oracle -DartifactId=ojdbc14 -Dversion=10.2.0.3.0 -Dpackaging=jar -Dfile=/path/to/file -Durl=[url] -DrepositoryId=[id]

