# frozen_string_literal: true

require 'open3'

class PgExport
  module Repositories
    class BashRepository
      class PgPersistError < StandardError; end
      class PgDumpError < StandardError; end

      def get(path, db_name)
        popen("pg_dump -Fc --file #{path} #{db_name}") do |errors|
          raise PgDumpError, errors unless errors.empty?
        end
      end

      def persist(path, db_name)
        popen("pg_restore -c -d #{db_name} #{path}") do |errors|
          raise PgPersistError, errors if /FATAL/ =~ errors
        end
      end

      private

      def popen(command)
        Open3.popen3(command) do |_, _, err|
          errors = err.read
          yield errors
        end

        self
      end
    end
  end
end