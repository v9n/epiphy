module Epiphy
  module Entity
    
    # Add created_at and updated_at field to an entity.
    #   
    #
    module Timestamp
      def self.included(base)
        base.send :attr_accessor, :_ts
      end
    end

  end
end
