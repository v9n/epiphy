module Epiphy
  module Adapter
    module Helper
      def where(*filter)
        @current_rql.filter(filter)  
      end

      def desc(key)
        @current_rql.order_by(r.desc(key))
      end
      private :where, :desc#, :exlude
    end
  end
end

