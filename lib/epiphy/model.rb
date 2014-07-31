require 'epiphy/version'
require 'epiphy/entity'
require 'epiphy/connection'
require 'epiphy/adapter/rethinkdb'
require 'epiphy/repository'

module Epiphy

  
  # Model
  #
  # @since 0.1.0
  module Model
    class RuntimeError < RethinkDB::RqlRuntimeError

    end
    # Error for not found entity
    #
    # @since 0.1.0
    #
    # @see epiphy::Repository.find
    class EntityNotFound < ::StandardError
    end

    class EntityClassNotFound < ::StandardError

    end
    
    class EntityIdNotFound < ::ArgumentError

    end

    # Error for non persisted entity
    # It's raised when we try to update or delete a non persisted entity.
    #
    # @since 0.1.0
    #
    # @see epiphy::Repository.update
    class NonPersistedEntityError < ::StandardError
    end

    class EntityExisted < ::StandardError

    end
  end
end
