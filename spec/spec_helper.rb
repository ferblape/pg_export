$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pg_export'
require 'pg'
require 'simplecov'
SimpleCov.start

PgExport::Logging.logger.formatter = ->(*) {}

class FtpMock
  def passive=(*) end

  def close; end
end
