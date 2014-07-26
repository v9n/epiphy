require 'lotus/utils/class_attribute'

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
   
    # Configuration class for a Repository. 
    # 
    # Storing Epiphy::Adapter::RethinkDB instance
    #
    # @api private
    # @since 0.0.1 
    #
    class Configuration
      attr_accessor :adapter
    end

    class <<self
      attr_write :configuration

      def self.configure
        raise(ArgumentError, 'Missing config block') unless block_given?
        @config ||= Configuration.new
        yield(@config)
      end

      def self.get_config
        @config
      end
    end

    # Inject the public API into the hosting class.
    #
    # @since 0.1.0
    #
    # @example
    #   require 'epiphy/model'
    #
    #   class UserRepository
    #     include Epiphy::Repository
    #   end
    def self.included(base)
      config = self.get_config
      base.class_eval do
        extend ClassMethods
        include Lotus::Utils::ClassAttribute

        class_attribute :collection
        adapter=(config.adapter)
      end
    end

    module ClassMethods
      # Assigns an adapter.
      #
      # Epiphy::Model is shipped with two adapters:
      #
      #   * SqlAdapter
      #   * MemoryAdapter
      #
      # @param adapter [Object] an object that implements
      #   `Epiphy::Model::Adapters::Abstract` interface
      #
      # @since 0.1.0
      #
      # @see Epiphy::Model::Adapters::SqlAdapter
      # @see Epiphy::Model::Adapters::MemoryAdapter
      #
      # @example Memory adapter
      #   require 'epiphy/model'
      #   require 'epiphy/model/adapters/memory_adapter'
      #
      #   mapper = Epiphy::Model::Mapper.new do
      #     # ...
      #   end
      #
      #   adapter = Epiphy::Model::Adapters::MemoryAdapter.new(mapper)
      #
      #   class UserRepository
      #     include Epiphy::Repository
      #   end
      #
      #   UserRepository.adapter = adapter
      #
      #
      #
      # @example SQL adapter with a Sqlite database
      #   require 'sqlite3'
      #   require 'epiphy/model'
      #   require 'epiphy/model/adapters/sql_adapter'
      #
      #   mapper = Epiphy::Model::Mapper.new do
      #     # ...
      #   end
      #
      #   adapter = Epiphy::Model::Adapters::SqlAdapter.new(mapper, 'sqlite://path/to/database.db')
      #
      #   class UserRepository
      #     include Epiphy::Repository
      #   end
      #
      #   UserRepository.adapter = adapter
      #
      #
      #
      # @example SQL adapter with a Postgres database
      #   require 'pg'
      #   require 'epiphy/model'
      #   require 'epiphy/model/adapters/sql_adapter'
      #
      #   mapper = Epiphy::Model::Mapper.new do
      #     # ...
      #   end
      #
      #   adapter = Epiphy::Model::Adapters::SqlAdapter.new(mapper, 'postgres://host:port/database')
      #
      #   class UserRepository
      #     include Epiphy::Repository
      #   end
      #
      #   UserRepository.adapter = adapter
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
      #   require 'epiphy/model'
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
      #   require 'epiphy/model'
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
        @adapter.persist(collection, entity)
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
          @adapter.create(collection, entity)
        end

        entity
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
          @adapter.update(collection, entity)
        else
          raise Epiphy::Model::NonPersistedEntityError
        end

        entity
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
        @adapter.find(collection, id).tap do |record|
          raise Epiphy::Model::EntityNotFound.new unless record
        end
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
      #       query do
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
    end
  end
end
