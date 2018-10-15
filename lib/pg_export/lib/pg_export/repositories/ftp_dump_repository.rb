# frozen_string_literal: true

require 'open3'
require 'pg_export/import'
require 'pg_export/lib/pg_export/entities/dump'
require 'pg_export/lib/pg_export/value_objects/dump_file'

class PgExport
  module Repositories
    class FtpDumpRepository
      def get(name, ftp_adapter:)
        file = ValueObjects::DumpFile.new
        ftp_adapter.get(file, name)

        Entities::Dump.new(
          name: name,
          database: '???',
          file: file,
          type: :encrypted
        )
      end

      def all(ftp_adapter:)
        ftp_adapter.list('*')
      end
    end
  end
end
