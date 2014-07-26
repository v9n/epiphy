require 'helper'

describe Epiphy::Adapter::Rethinkdb do
  let (:a) { Epiphy::Adapter::Rethinkdb}
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

  describe ".query" do
          

  end

end
