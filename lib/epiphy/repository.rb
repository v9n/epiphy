require 'lotus/utils/class_attribute'
require 'epiphy/repository/configuration'

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
  # Epiphy::Model is shipped with two adapters:
  #
  #   * SqlAdapter
  #   * MemoryAdapter
  #
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
        @config
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
      #config = self.get_config
      config = Epiphy::Repository.get_config
      base.class_eval do
        extend ClassMethods
        include Lotus::Utils::ClassAttribute

        class_attribute :collection
        self.adapter=(config.adapter)
        self.collection=(get_name) if self.collection.nil?
      end
    end

    module ClassMethods
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
      # If already persisted (`id` present) it does nothing.
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
        unless entity.id
          result = @adapter.create(collection, to_document(entity))
          entity.id = result
        end
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
          @adapter.delete(collection, entity)
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
        @adapter.all(collection)
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
        result = @adapter.find(collection, id).tap do |record|
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
      def first
        @adapter.first(collection)
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
      def last
        @adapter.last(collection)
      end

      # Deletes all the records from the current collection.
      #
      # If used with a SQL database it executes a `DELETE FROM <table>`.
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
      # IMPORTANT: This feature works only with the Sql adapter.
      #
      # A repository is storage independent.
      # All the queries are delegated to the current adapter, which is
      # responsible to implement a querying API.
      #
      # Epiphy::Model is shipped with two adapters:
      #
      #   * SqlAdapter, which yields a Epiphy::Model::Adapters::Sql::Query
      #   * MemoryAdapter, which yields a Epiphy::Model::Adapters::Memory::Query
      #
      # @param blk [Proc] a block of code that is executed in the context of a
      #   query
      #
      # @return a query, the type depends on the current adapter
      #
      # @api public
      # @since 0.1.0
      #
      # @see Epiphy::Model::Adapters::Sql::Query
      # @see Epiphy::Model::Adapters::Memory::Query
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
      def query(&blk)
        @adapter.query(collection, self, &blk)
      end

      # Negates the filtering conditions of a given query with the logical
      # opposite operator.
      #
      # This is only supported by the SqlAdapter.
      #
      # @param query [Object] a query
      #
      # @return a negated query, the type depends on the current adapter
      #
      # @api public
      # @since 0.1.0
      #
      # @see Epiphy::Model::Adapters::Sql::Query#negate!
      #
      # @example
      #   require 'epiphy/model'
      #
      #   class ProjectRepository
      #     include Epiphy::Repository
      #
      #     def self.cool
      #       query do
      #         where(language: 'ruby')
      #       end
      #     end
      #
      #     def self.not_cool
      #       exclude cool
      #     end
      #   end
      def exclude(query)
        query.negate!
        query
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
          e = Object.const_get('User').new
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
