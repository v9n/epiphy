module Epiphy
  module Repository
    # Custom enumetable on top of RethinkDB cursor so we can convert the hash
    # to the Entity object.
    #
    # For the ReQL that returns a cursor, we won't grab the array and convet the
    # hash into Entity object. Instead, we will use aan enumerable and the
    # Repository leverage it to convert the hash to entity object.
    #
    # @example
    #   cursor = r.table()...
    #   all = Epiphy::Repository::Cursor.new(cursor) do |item|
    #     item = transform_item_with_something_if_need
    #   end
    #
    # @since 0.1.0
    # @api public
    #
    class Cursor
      include Enumerable  
      attr_reader :cursor, :transform
      
      def initialize(cursor, &transform)
        @cursor = cursor  
        @transform = transform 
      end
      
      def each
        raise ArgumentError, 'Missing a block to enumate cursor' unless block_given?
        @cursor.each do |item|
          item = @transform.call item
          yield item
          #if block_given?
            #block.call person
          #else  
            #yield person
          #end
        end  
      end
    end
  end
end
