module Epiphy
  module Entity
    
    # Add created_at and updated_at field to an entity.
    #   
    #
    module Timestamp
      def self.included(base)
        base.send :attr_accessor, :created_at
      end
    end

  end
end
