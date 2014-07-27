require 'helper'
require 'helper_rethink'

describe Epiphy::Adapter::Rethinkdb do
  let (:a) { Epiphy::Adapter::Rethinkdb}
  let (:movie1) { {id: 100, title: 'Test'}}
  before do
    @adapter = Epiphy::Adapter::Rethinkdb.new Epiphy::Connection.create, database: RETHINKDB_DB_TEST
  end
  
  it "throw error without passing a connection" do 
    err = -> { Epiphy::Adapter::Rethinkdb.new }.must_raise ArgumentError
    err.message.must_match /wrong number of arguments/
  end
  
  it "accept a connection" do
    @adapter.must_be_instance_of Epiphy::Adapter::Rethinkdb
  end  

  describe ".query" do
    
    it 'throw error if not passing RethinkDB::RQL' do
      err = -> { @adapter.query}.must_raise ArgumentError
      err.message.must_match(/Missing/)
    end

    it "run query" do
      table = "testxpii"
      
      @adapter.query do |r|
        r.table_create(table)
      end
        
      @adapter.query table: table do |r|
        r.insert(movie1)
      end

      m = @adapter.query table: table do |r|
        r.get(100)
      end
      m["title"].must_equal "Test"

      @adapter.query do |r|
        r.table_drop table
      end

      @adapter.query do |t, r|
        r.db_drop RETHINKDB_DB_TEST
      end
    end


  end

end
