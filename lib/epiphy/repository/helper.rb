module Epiphy
  module Repository
    module Helper

      # Find the first record matching the 
      #
      # @param Keyword argument [field_name: value] 
      # @return Entity [Object]
      # @raise Epiphy::Model::EntityNotFound if not found
      #
      # @api public
      # @since 0.2.0
      def find_by(**option)
        begin
          query do |r|
            r.filter(option).nth(0)
          end
        rescue RethinkDB::RqlRuntimeError => e
          #raise RethinkDB::RqlRuntimeError
          raise Epiphy::Model::EntityNotFound if e.message.include?("Index out of bounds")
        end
      end
      
      #private :where, :desc#, :exlude
    end
  end
end

