require 'pg_export/services/ftp_adapter'
require 'ftp_mock'

RSpec.describe PgExport::FtpAdapter do
  let(:params) { { host: 'ftp.example.com', user: 'user', password: 'password' } }
  let(:mock) { FtpMock.new }

  before(:each) { allow(Net::FTP).to receive(:new).with(*params.values).and_return(mock) }

  subject { PgExport::FtpAdapter.new(connection: mock) }

  it { expect(subject).to respond_to(:list) }
  it { expect(subject).to respond_to(:delete) }
  it { expect(subject).to respond_to(:upload_file) }
end
