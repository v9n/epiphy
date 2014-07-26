require 'helper'

include RethinkDB::Shortcuts
describe Epiphy::Connection do
  describe ".create" do
    let (:local_con) { r.connect }
    let (:custom_con) { r.connect(:host => 'localhost', :port => 28015, :db => 'test')}  

    before do
    end

    after do
    end
    
    it "return a connection without param" do
      connection = Epiphy::Connection.create
      connection.must_be_instance_of RethinkDB::Connection
    end

    it "return a connection" do
    end

    it "throw error if no port listen" do
      err = ->{ Epiphy::Connection.create(:host => '127.0.0.1', :port => 2901) }.must_raise Errno::ECONNREFUSED
      err.message.must_match /Connection refused/
    end

  end
end
