module Epiphy
  module Repository
    class Cursor
      include Enumerable  
      attr_reader :cursor, :transform
      
      def initialize(cursor, &transform)
        @person = cursor  
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
