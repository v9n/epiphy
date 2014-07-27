require 'helper'

describe Epiphy::Adapter::Rethinkdb do
  let (:a) { Epiphy::Adapter::Rethinkdb}
  let (:movie1) { {id: 100, title: 'Test'}}
  before do
    @adapter = Epiphy::Adapter::Rethinkdb.new Epiphy::Connection.create
  end
  
  it "throw error without passing a connection" do 
    err = -> { Epiphy::Adapter::Rethinkdb.new }.must_raise ArgumentError
    err.message.must_match /wrong number of arguments/
  end
  
  it "accept a connection" do
    @adapter.must_be_instance_of Epiphy::Adapter::Rethinkdb
  end  

  describe ".execute" do
    
    it 'throw error if not passing RethinkDB::RQL' do
      q = Object.new
      err = -> { @adapter.query "test", self}.must_raise ArgumentError
      err.message.must_match /Missing/
      
      err = -> { @adapter.query}.must_raise ArgumentError
      err.message.must_match /wrong number of argument/
    end

    it "run query" do
      table = "testxpii"

      @adapter.query table, self do |r|
        r.table_create(table)
      end
        
      @adapter.query table, self do |r|
        r.insert(movie1)
      end

      m = @adapter.query table, self do |r|
        r.get(100)
      end
      m["title"].must_equal "Test"

      @adapter.execute table, self do |r|
        r.table_drop table
      end
    end


  end

end
