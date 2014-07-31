module Epiphy
  module Repository
    # Not configure exception
    #
    # This error will be raised when the repository didn't get configured yet.
    # @since 0.2.0
    # @api public
    class NotConfigureError < ::StandardError

    end
    class MissingAdapterError < ::StandardError

    end

  end
end
