module Epiphy
  module Schema
    # Create a collection storage in database.
    #
    def create_collection
      query do |r|
        r.table_create(self.collection)
      end
    end

    # Drop a collection storage in database
    #
    def drop_collection
      query do |r|
        r.table_drop(self.collection)
      end
    end
  end
end
