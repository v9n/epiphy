module Epiphy
  module Connection
    
    include RethinkDB::Shortcuts
    # Create a RethinkDB connection.
    #
    # @param Hash [host, port, db, auth]
    #
    # @api public
    # @since 0.0.1
    def self.create(opts = {})
      begin
        r.connect opts  
      rescue err
        puts err.inspect
      end
    end

  end
end
