require 'rethinkdb'
include RethinkDB::Shortcuts

RETHINKDB_DB_TEST = 'epiphy_test_v001'
# Cleanup and Reset the database before testing
puts 'clean up'
connection = r.connect
begin
  r.db_drop(RETHINKDB_DB_TEST).run connection
rescue
end

begin 
  r.db_create(RETHINKDB_DB_TEST).run connection
rescue 
  puts "Fail to creating database. Fix this and return"
  exit
ensure
  connection.close
end
puts 'Start test'
