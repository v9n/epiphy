require 'lotus/utils/class_attribute'
require 'epiphy/repository/configuration'
require 'epiphy/repository/cursor'
require 'epiphy/repository/helper'

module Epiphy
  # Mediates between the entities and the persistence layer, by offering an API
  # to query and execute commands on a database.
  #
  #
  #
  # By default, a repository is named after an entity, by appending the
  # `Repository` suffix to the entity class name.
  #
  # @example
  #   
  #   # Configuration and initalize the necessary config. Can be put in Rails
  #   # config file.
  #   connection = Epiphy::Connection.create  
  #   adapter = Epiphy::Adapter::Rethinkdb.new(connection)
  #   Epiphy::Repository.configure do |c|
  #     c.adapter = adapter
  #   end
  #
  #   
  #   require 'epiphy/model'
  #
  #   class Article
  #     include Epiphy::Entity
  #   end
  #
  #   # valid
  #   class ArticleRepository
  #     include Epiphy::Repository
  #   end
  #
  #   # not valid for Article
  #   class PostRepository
  #     include Epiphy::Repository
  #   end
  #
  # Repository for an entity can be configured by setting # the `#repository`
  # on the mapper.
  #
  # @example
  #   # PostRepository is repository for Article
  #   mapper = Epiphy::Model::Mapper.new do
  #     collection :articles do
  #       entity Article
  #       repository PostRepository
  #     end
  #   end
  #
  # A repository is storage independent.
  # All the queries and commands are delegated to the current adapter.
  #
  # This architecture has several advantages:
  #
  #   * Applications depend on an abstract API, instead of low level details
  #     (Dependency Inversion principle)
  #
  #   * Applications depend on a stable API, that doesn't change if the
  #     storage changes
  #
  #   * Developers can postpone storage decisions
  #
  #   * Isolates the persistence logic at a low level
  #
  # Epiphy::Model is shipped with adapter:
  #
  #   * RethinkDB
  #
  #
  # All the queries and commands are private.
  # This decision forces developers to define intention revealing API, instead
  # leak storage API details outside of a repository.
  #
  # @example
  #   require 'epiphy/model'
  #
  #   # This is bad for several reasons:
  #   #
  #   #  * The caller has an intimate knowledge of the internal mechanisms
  #   #      of the Repository.
  #   #
  #   #  * The caller works on several levels of abstraction.
  #   #
  #   #  * It doesn't express a clear intent, it's just a chain of methods.
  #   #
  #   #  * The caller can't be easily tested in isolation.
  #   #
  #   #  * If we change the storage, we are forced to change the code of the
  #   #    caller(s).
  #
  #   ArticleRepository.where(author_id: 23).order(:published_at).limit(8)
  #
  #
  #
  #   # This is a huge improvement:
  #   #
  #   #  * The caller doesn't know how the repository fetches the entities.
  #   #
  #   #  * The caller works on a single level of abstraction.
  #   #    It doesn't even know about records, only works with entities.
  #   #
  #   #  * It expresses a clear intent.
  #   #
  #   #  * The caller can be easily tested in isolation.
  #   #    It's just a matter of stub this method.
  #   #
  #   #  * If we change the storage, the callers aren't affected.
  #
  #   ArticleRepository.most_recent_by_author(author)
  #
  #   class ArticleRepository
  #     include Epiphy::Repository
  #
  #     def self.most_recent_by_author(author, limit = 8)
  #       query do
  #         where(author_id: author.id).
  #           order(:published_at)
  #       end.limit(limit)
  #     end
  #   end
  #
  # @since 0.1.0
  #
  # @see Epiphy::Entity
  # @see http://martinfowler.com/eaaCatalog/repository.html
  # @see http://en.wikipedia.org/wiki/Dependency_inversion_principle
  module Repository 

    # Configure repository class by using a block. By default, all Repisitory
    # will be initlized with same configuration in an instance of the 
    # `Configuration` # class. 
    #
    # Each Repository holds a reference to an `Epiphy::Adapter::Rethinkdb` 
    # object. This adapter is set when a new Repository is defined.
    #
    # @see Epiphy::Repository::Configuration class for configuration option
    #
    # The adapter can be chaged later if needed with
    # `Epiphy::Repository#adapter=` method
    #
    # @see Epiphy::Repository#adapter=
    # 
    # @example
    #   adapter = Epiphy::Adapter::Rethinkdb.new connection
    #   Epiphy::Repository.configure do |config|
    #     config.adapter = adapter
    #   end
    # @since 0.0.1
    #
    class <<self
      def configure
        raise(ArgumentError, 'Missing config block') unless block_given?
        @config ||= Configuration.new
        yield(@config)
      end

      def get_config
        if @config.nil?
          auto_config
        end
        @config
      end
      
      # Auto configure with default RethinkDB setting. 127.0.0.1, 28015, plain
      # auth key.
      #
      # With this design, people can just drop in and start using it without
      # worry about setting up and configure.
      # @since 0.3.0
      # @api private 
      def auto_config
        Epiphy::Repository.configure do |config|
          config.adapter = Epiphy::Adapter::Rethinkdb.new connection, database: 'test'
        end
      end
    end

    # Inject the public API into the hosting class.
    #
    # Also setup the repository. Collection name, Adapter will be set
    # automatically at this step. By changing adapter, you can force the
    # Repository to be read/written from somewhere else. 
    #
    # In a master/slave environment, the adapter can be change depend on the
    # repository. 
    # 
    # The name of table to hold this collection in database can be change with 
    # self.collection= method
    #
    # @since 0.1.0
    # @see self#collection
    #
    # @example
    #   require 'epiphy/model'
    # 
    #   class UserRepository
    #     include Epiphy::Repository
    #   end
    #
    #   UserRepository.collection #=> User
    #
    #   class MouseRepository
    #     include Epiphy::Repository
    #
    #   end
    #   MouseRepository.collection = 'Mice'
    #   MouseRepository.collection #=> Mice
    #
    #   class FilmRepository
    #     include Epiphy::Repository
    #     collection = 'Movie'
    #   end
    #   FilmRepository.collection = 'Movie'
    #
    def self.included(base)
      config = Epiphy::Repository.get_config
      
      raise Epiphy::Repository::NotConfigureError if config.nil?
      raise Epiphy::Repository::MissingAdapterError if config.adapter.nil?

      base.class_eval do
        extend ClassMethods
        include Lotus::Utils::ClassAttribute

        class_attribute :collection
        self.adapter=(config.adapter)
        self.collection=(get_name) if self.collection.nil?
      end
    end

    module ClassMethods
      include Epiphy::Repository::Helper
      # Assigns an adapter.
      #
      # Epiphy::Repository is shipped with an adapters:
      #
      #   * Rethinkdb
      #
      # @param adapter [Object] an object that implements
      #   `Epiphy::Model::Adapters::Abstract` interface
      #
      # @since 0.1.0
      #
      # @see Epiphy::Adapter::Rethinkdb
      #
      # @example 
      #
      #   class UserRepository
      #     include Epiphy::Repository
      #   end
      #   
      #   # Adapter is set by a shared adapter by default. Unless you want 
      #   to change, you shoul not need this
      #   adapter = Epiphy::Adapter::Rethinkdb.new aconnection, adb
      #   UserRepository.adapter = adapter
      #
      def adapter=(adapter)
        @adapter = adapter
      end

      # Creates or updates a record in the database for the given entity.
      #
      # @param entity [#id, #id=] the entity to persist
      #
      # @return [Object] the entity
      #
      # @since 0.1.0
      #
      # @see Epiphy::Repository#create
      # @see Epiphy::Repository#update
      #
      # @example With a non persisted entity
      #   require 'epiphy'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   article = Article.new(title: 'Introducing Epiphy::Model')
      #   article.id # => nil
      #
      #   ArticleRepository.persist(article) # creates a record
      #   article.id # => 23
      #
      # @example With a persisted entity
      #   require 'epiphy'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   article = ArticleRepository.find(23)
      #   article.id # => 23
      #
      #   article.title = 'Launching Epiphy::Model'
      #   ArticleRepository.persist(article) # updates the record
      #
      #   article = ArticleRepository.find(23)
      #   article.title # => "Launching Epiphy::Model"
      def persist(entity)
        @adapter.persist(collection, to_document(entity))
      end

      # Creates a record in the database for the given entity.
      # It assigns the `id` attribute, in case of success.
      #
      # If already persisted (`id` present), it will try to insert use that id
      # and will raise an error if the `id` is already exist
      #
      # @param entity [#id,#id=] the entity to create
      #
      # @return [Object] the entity
      #
      # @since 0.1.0
      #
      # @see Epiphy::Repository#persist
      #
      # @example
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   article = Article.new(title: 'Introducing Epiphy::Model')
      #   article.id # => nil
      #
      #   ArticleRepository.create(article) # creates a record
      #   article.id # => 23
      #
      #   ArticleRepository.create(article) # no-op
      def create(entity)
        #unless entity.id
        begin
          result = @adapter.create(collection, to_document(entity))
          entity.id = result
        rescue Epiphy::Model::EntityExisted => e
          raise e
        rescue RethinkDB::RqlRuntimeError => e
          raise Epiphy::Model::RuntimeError, e.message
        end
        #end
      end

      # Updates a record in the database corresponding to the given entity.
      #
      # If not already persisted (`id` present) it raises an exception.
      #
      # @param entity [#id] the entity to update
      #
      # @return [Object] the entity
      #
      # @raise [Epiphy::Model::NonPersistedEntityError] if the given entity
      #   wasn't already persisted.
      #
      # @since 0.1.0
      #
      # @see Epiphy::Repository#persist
      # @see Epiphy::Model::NonPersistedEntityError
      #
      # @example With a persisted entity
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   article = ArticleRepository.find(23)
      #   article.id # => 23
      #   article.title = 'Launching Epiphy::Model'
      #
      #   ArticleRepository.update(article) # updates the record
      #
      #
      #
      # @example With a non persisted entity
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   article = Article.new(title: 'Introducing Epiphy::Model')
      #   article.id # => nil
      #
      #   ArticleRepository.update(article) # raises Epiphy::Model::NonPersistedEntityError
      def update(entity)
        if entity.id
          @adapter.update(collection, to_document(entity))
        else
          raise Epiphy::Model::NonPersistedEntityError
        end
      end

      # Deletes a record in the database corresponding to the given entity.
      #
      # If not already persisted (`id` present) it raises an exception.
      #
      # @param entity [#id] the entity to delete
      #
      # @return [Object] the entity
      #
      # @raise [Epiphy::Model::NonPersistedEntityError] if the given entity
      #   wasn't already persisted.
      #
      # @since 0.1.0
      #
      # @see Epiphy::Model::NonPersistedEntityError
      #
      # @example With a persisted entity
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   article = ArticleRepository.find(23)
      #   article.id # => 23
      #
      #   ArticleRepository.delete(article) # deletes the record
      #
      #
      #
      # @example With a non persisted entity
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   article = Article.new(title: 'Introducing Epiphy::Model')
      #   article.id # => nil
      #
      #   ArticleRepository.delete(article) # raises Epiphy::Model::NonPersistedEntityError
      def delete(entity)
        if entity.id
          @adapter.delete(collection, entity.id)
        else
          raise Epiphy::Model::NonPersistedEntityError
        end

        entity
      end

      # Returns all the persisted entities.
      #
      # @return [Array<Object>] the result of the query
      #
      # @since 0.1.0
      #
      # @example
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   ArticleRepository.all # => [ #<Article:0x007f9b19a60098> ]
      def all
        all_row = @adapter.all(collection)
        cursor = Epiphy::Repository::Cursor.new all_row do |item|
          to_entity(item)
        end
        cursor.to_a
      end

      # Finds an entity by its identity.
      #
      # If used with a SQL database, it corresponds to the primary key.
      #
      # @param id [Object] the identity of the entity
      #
      # @return [Object] the result of the query
      #
      # @raise [Epiphy::Model::EntityNotFound] if the entity cannot be found.
      #
      # @since 0.1.0
      #
      # @see Epiphy::Model::EntityNotFound
      #
      # @example With a persisted entity
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   ArticleRepository.find(9) # => raises Epiphy::Model::EntityNotFound
      def find(id)
        entity_id = id
        if id.is_a? Epiphy::Entity
          raise TypeError, "Expecting an string, primitve value"
        end

        if !id.is_a? String
          raise Epiphy::Model::EntityIdNotFound, "Missing entity id" if !id.respond_to?(:to_s)
          entity_id = id.to_s
        end
        #if !id.is_a? String
          #entity_id = id.to_i
        #end
        result = @adapter.find(collection, entity_id).tap do |record|
          raise Epiphy::Model::EntityNotFound.new unless record
        end
        to_entity(result)
      end

      # Returns the first entity in the database.
      #
      # @return [Object,nil] the result of the query
      #
      # @since 0.1.0
      #
      # @see Epiphy::Repository#last
      #
      # @example With at least one persisted entity
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   ArticleRepository.first # => #<Article:0x007f8c71d98a28>
      #
      # @example With an empty collection
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   ArticleRepository.first # => nil
      def first(order_by=:id)
        result = @adapter.first(collection, order_by: order_by)
        if result
          to_entity result
        else
          result
        end
      end

      # Returns the last entity in the database.
      #
      # @return [Object,nil] the result of the query
      #
      # @since 0.1.0
      #
      # @see Epiphy::Repository#last
      #
      # @example With at least one persisted entity
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   ArticleRepository.last # => #<Article:0x007f8c71d98a28>
      #
      # @example With an empty collection
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   ArticleRepository.last # => nil
      def last(order_by=:id)
        if result = @adapter.last(collection, order_by: order_by)
          to_entity result
        else
          nil
        end
      end

      # Deletes all the records from the current collection.
      #
      # Execute a `r.table().delete()` on RethinkDB level.
      #
      # @since 0.1.0
      #
      # @example
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #   end
      #
      #   ArticleRepository.clear # deletes all the records
      def clear
        @adapter.clear(collection)
      end 

      # Count the entity in this collection
      #
      # @param void
      # @return Interget 
      # @api public
      # @since 0.2.0
      def count
        @adapter.count(collection)
      end

      private
      # Fabricates a query and yields the given block to access the low level
      # APIs exposed by the query itself.
      #
      # This is a Ruby private method, because we wanted to prevent outside
      # objects to query directly the database. However, this is a public API
      # method, and this is the only way to filter entities.
      #
      # The returned query SHOULD be lazy: the entities should be fetched by
      # the database only when needed.
      #
      # The returned query SHOULD refer to the entire collection by default.
      #
      # Queries can be reused and combined together. See the example below.
      #
      # A repository is storage independent.
      # All the queries are delegated to the current adapter, which is
      # responsible to implement a querying API.
      #
      # Epiphy::Model is shipped with adapter:
      #
      #   * RethinkDB: which yields a RethinkDB::ReQL class.
      #
      # By default, all return items will be convert into its entity. The
      # behavious can change by alter `to_entity` parameter 
      #
      # @param to_entity [Boolean][Optional] to convert the result back to a
      # entity class or not. 
      #       
      # @param blk [Proc] a block of code that is executed in the context of a
      #   query.
      #   The block will be passed two parameters. First parameter is the `reql`
      #   which is building. the second parameter is th `r` top name space of
      #   RethinkDB. By doing this, Repository doesn't have to include
      #   RethinkDB::Shortcuts
      # 
      # @return a query, the type depends on the current adapter
      #
      # @api public
      # @since 0.1.0
      #
      # @see Epiphy::Adapters::Rethinkdb
      #
      # @example
      #   require 'epiphy/model'
      #
      #   class ArticleRepository
      #     include Epiphy::Repository
      #
      #     def self.most_recent_by_author(author, limit = 8)
      #       query do |r|
      #         where(author_id: author.id).
      #           desc(:published_at).
      #           limit(limit)
      #       end
      #     end
      #
      #     def self.most_recent_published_by_author(author, limit = 8)
      #       # combine .most_recent_published_by_author and .published queries
      #       most_recent_by_author(author, limit).published
      #     end
      #
      #     def self.published
      #       query do
      #         where(published: true)
      #       end
      #     end
      #
      #     def self.rank
      #       # reuse .published, which returns a query that respond to #desc
      #       published.desc(:comments_count)
      #     end
      #
      #     def self.best_article_ever
      #       # reuse .published, which returns a query that respond to #limit
      #       rank.limit(1)
      #     end
      #
      #     def self.comments_average
      #       query.average(:comments_count)
      #     end
      #   end
      def query(to_entity: true, &blk)
        result = @adapter.query(table: collection, &blk)
        require 'pp'
        if result.is_a? RethinkDB::Cursor
          return Epiphy::Repository::Cursor.new result do |item|
            to_entity(item)
          end
        end

        if result.is_a? Array
          result.map! do |item|
            to_entity(item)
          end
        end

        if result.is_a? Hash
          return to_entity(result)
        end
        result
      end
      

      # Determine colleciton/table name of this repository. Note that the
      # repository name has to be the model name, appending Repository
      #
      # @return [Symbol] collection name
      # 
      # @api public
      # @since 0.1.0
      #
      # @see Epiphy::Adapter::Rethinkdb#get_table
      def get_name
        name = self.to_s.split('::').last
        #end = Repository.length + 1
        if name.nil?
          return nil
        end
        name = name[0..-11].downcase.to_sym
      end
      
      # Determine entity name for this repository
      # @return [String] entity name
      #
      # @api public
      # @since 0.1.0
      #
      # @see self#get_name
      def entity_name
        name = self.to_s.split('::').last
        if name.nil?
          return nil
        end
        name[0..-11]
      end
      
      # Convert a hash into the entity object. 
      #
      # Note that we require a Entity class same name with Repository class,
      # only different is the suffix Repository.
      #
      # @param [Hash] value object  
      # @return [Epiphy::Entity] Entity  
      # @api public
      # @since 0.1.0
      def to_entity ahash
        begin 
          name = entity_name
          e = Object.const_get(name).new
          ahash.each do |k,v|
            e.send("#{k}=", v)
          end
        rescue
          raise Epiphy::Model::EntityClassNotFound
        end
        e
      end

      # Convert all value of the entity into a document
      #
      # @param [Epiphy::Entity] Entity
      # @return [Hash] hash object of entity value, except the nil value
      # 
      # @api public
      # @since 0.1.0
      #
      def to_document entity
        document = {}
        entity.instance_variables.each {|var| document[var.to_s.delete("@")] = entity.instance_variable_get(var) unless entity.instance_variable_get(var).nil? }
        document
      end

    end
  end
end
