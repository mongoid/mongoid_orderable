# frozen_string_literal: true

module Mongoid
module Orderable
module Handlers
  # Executes a block within the context of a MongoDB transaction.
  class Transaction
    THREAD_KEY = :__mongoid_orderable_in_txn
    RETRY_SLEEP = 0.001

    attr_reader :doc

    def initialize(doc)
      @doc = doc
    end

    def with_transaction(&block)
      query_cache.uncached do
        if Thread.current[THREAD_KEY]
          yield
        else
          Thread.current[THREAD_KEY] = true
          retries = transaction_max_retries
          begin
            do_transaction(&block)
          rescue Mongo::Error::OperationFailure => e
            sleep(RETRY_SLEEP)
            retries -= 1
            retry if retries >= 0
            raise Mongoid::Orderable::Errors::TransactionFailed.new(e)
          ensure
            Thread.current[THREAD_KEY] = nil
          end
        end
      end
    end

    private

    def do_transaction(&_block)
      doc.class.with_session(session_opts) do |session|
        doc.class.with(persistence_opts) do
          session.start_transaction(transaction_opts)
          yield
          session.commit_transaction
        end
      end
    end

    def session_opts
      { read: { mode: :primary },
        causal_consistency: true }
    end

    def persistence_opts
      { read: { mode: :primary } }
    end

    def transaction_opts
      { read: { mode: :primary },
        read_concern: { level: 'majority' },
        write_concern: { w: 'majority' } }
    end

    def transaction_max_retries
      doc.orderable_keys.map {|k| doc.class.orderable_configs.dig(k, :transaction_max_retries) }.compact.max
    end

    def query_cache
      defined?(Mongo::QueryCache) ? Mongo::QueryCache : Mongoid::QueryCache
    end
  end
end
end
end
