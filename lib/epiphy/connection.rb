module Epiphy
  module Connection
    
    include RethinkDB::Shortcuts
    # Create a RethinkDB connection.
    #
    # @param Hash [host, port, db, auth]
    # @return RethinkDB::Connection a connection to RethinkDB
    #
    # @api public
    # @since 0.0.1
    def self.create(opts = {})
      r.connect opts  
    end

  end
end
