require 'epiphy/adapter/error'
#require 'epiphy/adapter/helper'
module Epiphy
  module Adapter
    class Rethinkdb
      include RethinkDB::Shortcuts
      # Create an adapter object, with the option to pass a connection
      # object as dependency.
      #
      # Without the dattabase string, Epiphy will assumes a `test`
      # database just as RethinkDB do by default.
      #
      # @example
      #   connection = Epiphy::Connection.create  
      #   adapter = Epiphy::Adapter::Rethinkdb.new(connection,
      #   default_database)
      #    
      # @param connection [RethinkDB::Connection]
      # @param database   [String] database name
      #
      # @api public
      # @since 0.0.1
      #
      #
      def initialize(conn, database: 'test')
        self.connection=(conn)
        self.database=(database) unless database.nil?
      end

      # Assign a RethinkDB connection for this adapter.
      # 
      # @param connection [RethinkDB::Connection]
      # @return [Object] the current adapter. enable us to continue
      # chain it
      #
      # @api public
      # @since 0.1.0
      def connection= (connection)
        @connection = connection
      end
      
      # Set the current, default database for this connection. 
      #
      # At, any time, you can re-set this to change the database. 
      # Doing so will trigger the adapter to switch to the new 
      # database.
      # 
      # At RethinkDB level, this is similar with what we do with 
      # r.db('foo')
      #
      # @example
      #   adapter.database("test")
      #   # Subsequent query will be run on `test` database
      #   adapter.database("foo")
      #   # Subsequent query will be run on `foo` database
      #
      #
      def database= (db)
        @database = db 
      end

      # Execute a ReQL query. The database and table is passed as
      # parameter and the query is build by a block.
      #
      # The table param can be omitted so we can run the drop, create
      # table
      #
      # With a valid database param, only this query will be run on it. To set
      # a persitent different database for subsequent queries, consider
      # set a different database.
      #
      # The block is passed 2 object. The first is the ReQL at the
      # table() level. The second is the ReQL at top name space level
      #
      # @see Epiphy::Adapter::Rethinkdb#database=
      #
      # @example
      #   # To create a table
      #   adapter.query do |r, rt|
      #     r.table_create('table_name')
      #   end  
      #
      #   # To filter
      #   adapter.query table: 'movie' do |r|
      #     r.filter({category: 'romantic'})
      #   end
      #
      #   # To Drop a database
      #   adapter.query do |t, r|
      #     r.db_drop 'dbname'
      #   end
      #
      # @param collection [Epiphy::Repository]
      # @param table [String]
      # @param database [String] 
      #
      # @return query result of RethinkDB::run
      # 
      # @since 0.0.1
      # @api private 
      def query(table: nil, database: nil)
        raise ArgumentError, 'Missing query block' unless block_given? 
        if block_given?
          rql = get_table(table, database)
          rql = yield(rql, r)
        end
        rql.run(@connection)
      end
      
      # Creates or updates a record in the database for the given entity.
      #
      # @param collection [Symbol] the target collection (it must be mapped).
      # @param entity [#id, #id=] the entity to persist
      #
      # @return [Object] the entity
      #
      # @api private
      # @since 0.1.0
      def persist(collection, entity)
        if entity["id"]
          update(collection, entity)
        else
          create(collection, entity)
        end
      end
      
      # Insert a document.
      # @param collection [Symbol the target collection
      # @param entity [#id, #id=] the entity to create
      # @return [Object] the entity 
      #
      # @api private
      # @since 0.0.1
      def create(collection, entity)
        puts entity.inspect
        result = query table: collection do |r|
          r.insert(entity)
        end
      end

      # Insert a document.
      # @param collection [Symbol the target collection
      # @param entity [#id, #id=] the entity to create
      # @return [Object] the entity 
      #
      # @api private
      # @since 0.0.1
      def update(collection, entity)
        result = query table: collection do |r|
          r.get(entity[id]).update(entity)
        end
      end


      # Returns all the records for the given collection
      #
      # @param collection [Symbol] the target collection (it must be mapped).
      #
      # @return [Array] all the records
      #
      # @api private
      # @since 0.1.0
      def all(collection)
        # TODO consider to make this lazy (aka remove #all)
        #query(collection).all
        query table: collection do |r|
          r
        end
      end

      # Returns an unique record from the given collection, with the given
      # id.
      #
      # @param collection [Symbol] the target collection (it must be mapped).
      # @param id [Object] the identity of the object.
      #
      # @return [Object] the entity
      #
      # @api private
      # @since 0.1.0
      def find(collection, id)
        query table:collection do |r|
          r.get(id)
        end
      end

      # Returns the first record in the given collection.
      #
      # @param collection [Symbol] the target collection (it must be mapped).
      #
      # @return [Object] the first entity
      #
      # @api private
      # @since 0.1.0
      def first(collection)
        _first(
          query(collection).asc(_identity(collection))
        )
      end

      # Returns the last record in the given collection.
      #
      # @param collection [Symbol] the target collection (it must be mapped).
      #
      # @return [Object] the last entity
      #
      # @api private
      # @since 0.1.0
      def last(collection)
        _first(
          query(collection).desc(_identity(collection))
        )
      end

      private
      def _collection(name)
        raise NotImplementedError
      end

      def _mapped_collection(name)
        @mapper.collection(name)
      end

      def _find(collection, id)
        identity = _identity(collection)
        query(collection).where(identity => _id(collection, identity, id))
      end

      def _first(query)
        query.limit(1).first
      end

      def _identity(collection)
        _mapped_collection(collection).identity
      end

      def _id(collection, column, value)
        _mapped_collection(collection).deserialize_attribute(column, value)
      end

      protected

      # Return a ReQL wrapper of a table to start query chaining.
      # 
      # This is just a lighweight wrapper of `r.db().table()`
      # @see
      # @param database [string]. default to current database
      # @param table [string]
      # @api private
      # @since 0.0.1
      def get_table(table, database=nil)
        database = @database if database.nil?
        raise Epiphy::Adapter::MissingDatabaseError "Missing a default database name"  if database.nil?
        rql = r.db(database)
        rql = rql.table(table) unless table.nil?
        rql
      end


    end    
  end
end
