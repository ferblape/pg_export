# frozen_string_literal: true

require 'forwardable'
require 'tempfile'

require 'pg_export/roles/human_readable'

class PgExport
  module Entities
    class Dump
      TIMESTAMP = '_%Y%m%d_%H%M%S'

      extend Forwardable
      include Roles::HumanReadable

      CHUNK_SIZE = (2**16).freeze

      def_delegators :file, :path, :read, :write, :<<, :rewind, :close, :size, :eof?

      attr_reader :name, :db_name

      def initialize(name:, db_name:)
        @name, @db_name = name, db_name
        @timestamp = Time.now.strftime(TIMESTAMP)
      end

      def ext
        ''
      end

      def open(operation_type, &block)
        case operation_type.to_sym
        when :read then File.open(path, 'r', &block)
        when :write then File.open(path, 'w', &block)
        else raise ArgumentError, 'Operation type can be only :read or :write'
        end
      end

      def each_chunk
        open(:read) do |file|
          yield file.read(CHUNK_SIZE) until file.eof?
        end
      end

      def timestamped_name
        db_name + timestamp + ext
      end

      def copy(name:, cipher:)
        cipher.reset
        new_dump = self.class.new(name: name, db_name: db_name)
        new_dump.open(:write) do |f|
          each_chunk do |chunk|
            f << cipher.update(chunk)
          end
          f << cipher.final
        end

        new_dump
      end

      def to_s
        "#{name} (#{size_human})"
      end

      private

      attr_reader :timestamp

      def file
        @file ||= Tempfile.new(file_name)
      end

      def file_name
        name.downcase.gsub(/[^0-9a-z]/, '_')
      end
    end
  end
end