# frozen_string_literal: true

require 'pg_export/version'
require 'pg_export/configuration'
require 'pg_export/boot_container'
require 'dry/transaction'

require 'cli_spinnable'
require 'pg_export/roles/colourable_string'

class PgExport
  module Transactions
    class ImportDumpInteractively
      include Dry::Transaction
      include CliSpinnable
      using Roles::ColourableString

      attr_accessor :container

      tee  :info
      tee  :initialize_connection
      step :select_dump
      step :download_dump
      step :import

      private

      def info
        puts 'Interactive mode, for restoring dump into database.'.green
      end

      def initialize_connection
        with_spinner do |cli|
          cli.print 'Connecting to FTP'
          container[:ftp_connection].ftp
          cli.tick
        end
      end

      def select_dump(database_name:, keep_dumps: nil)
        dumps = container[:ftp_repository].all
        dumps.each.with_index(1) do |name, i|
          print "(#{i}) "
          puts name.to_s.gray
        end

        puts 'Which dump would you like to import?'
        number = loop do
          print "Type from 1 to #{dumps.count} (1): "
          number = gets.chomp.to_i
          break number if (1..dumps.count).cover?(number)

          puts 'Invalid number. Please try again.'.red
        end

        selected_dump = dumps.fetch(number - 1)

        Success(database_name: database_name, selected_dump: selected_dump)
      end

      def download_dump(database_name:, selected_dump:)
        dump = nil

        with_spinner do |cli|
          cli.print "Downloading dump #{selected_dump}"
          encrypted_dump = container[:ftp_repository].get(selected_dump)
          cli.print " (#{encrypted_dump.size_human})"
          cli.tick
          cli.print "Decrypting dump #{selected_dump}"
          dump = container[:decryptor].call(encrypted_dump)
          cli.print " (#{dump.size_human})"
          cli.tick
        end

        Success(dump: dump, database_name: database_name)
      rescue OpenSSL::Cipher::CipherError => e
        return Failure(message: "Problem decrypting dump file: #{e}. Try again.".red)
      end

      def import(dump:, database_name:)
        t = Thread.new { container[:ftp_connection].close }
        puts 'To which database you would like to restore the downloaded dump?'
        if database_name.nil?
          print 'Enter a local database name: '
        else
          print "Enter a local database name (#{database_name}): "
        end

        name = loop do
          db_name = gets.chomp
          db_name = db_name.empty? ? database_name : db_name

          break db_name unless db_name.nil?
          print 'Enter a local database name: '
        end

        ret = nil
        with_spinner do |cli|
          cli.print "Restoring dump to #{name} database"
          ret = container[:bash_repository].persist(dump, name)
          cli.tick

        end
        t.join

        ret
      end
    end
  end
end
