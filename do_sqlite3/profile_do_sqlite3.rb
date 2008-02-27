require 'rubygems'
require 'ruby-prof'
require 'date'
require 'rbsqlite3'


connection = RbSqlite3::Connection.new("/usr/local/projects/do_svn/trunk/do_sqlite3/profile.db")
result = RubyProf.profile do
  1000.times do
    result = connection.execute_reader("SELECT * FROM users")
    result.set_types [Fixnum, Fixnum, String, DateTime]
    until (row = result.fetch_row).nil?
      row
      # puts row[3]
    end
    result.close
  end
end  
connection.close

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT, 0)