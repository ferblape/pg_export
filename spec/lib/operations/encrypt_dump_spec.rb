# frozen_string_literal: true

require 'null_logger'
require 'pg_export/lib/pg_export/factories/cipher_factory'
require 'pg_export/lib/pg_export/operations/encrypt_dump'
require 'pg_export/lib/pg_export/value_objects/dump_file'

RSpec.describe PgExport::Operations::EncryptDump do
  let(:encrypt_dump) { PgExport::Operations::EncryptDump.new(cipher_factory: cipher_factory, logger: NullLogger) }
  let(:cipher_factory) { PgExport::Factories::CipherFactory.new(config: OpenStruct.new(dump_encryption_key: encryption_key)) }
  let(:encryption_key) { '1234567890abcdef' }

  let(:plain_dump) do
    file = PgExport::ValueObjects::DumpFile.new
    file.write { |f| f << 'abc' }
    file.rewind
    PgExport::Entities::Dump.new(name: 'datbase_20180101_121212', database: 'database', file: file, type: :plain)
  end

  describe '#call' do
    subject { encrypt_dump.call(database_name: 'x', dump: plain_dump) }

    it { expect(subject.success[:dump].name).to eq('datbase_20180101_121212') }
    it { expect(subject.success[:dump].file.read).to eq("\u0000\x8A0\xF1\ecW,-\xA1\xFA\xD6{\u0018\xEBf") }
  end
end
