module Epiphy
  module Repository

    # Configuration class for repository. 
    # 
    # Storing Epiphy::Adapter::RethinkDB instance, and RethinkDB run
    # option.
    #
    # @example
    #   adapter = Epiphy::Adapter::Rethinkdb.new connection
    #   Epiphy::Repository.configure do |config|
    #     config.adapter = adapter
    #   end
    # @api private
    # @since 0.0.1 
    #
    class Configuration
      attr_accessor :adapter
      attr_accessor :run_option

      def initalize
        @run_option = {
          use_outdated: false,
          time_format: 'native',
          profile: false,
          durability: 'hard',
          group_format: 'native',
          no_reply: false
        }
      end
    end
  end
end
