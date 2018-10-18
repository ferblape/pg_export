# frozen_string_literal: true

require_relative '../plain_listener'

class PgExport
  module Listeners
    class Plain
      class EncryptDump < PlainListener
        def on_step_succeeded(step_name:, args:, value:)
          logger.info("Encrypt #{value[:dump]}")
        end
      end
    end
  end
end
