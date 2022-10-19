require "../spec_helper"
include CB

Spectator.describe CB::BackupCapture do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(client) { Client.new TEST_TOKEN }
  let(cluster) { Factory.cluster }

  mock Client do
    stub get_cluster(id : Identifier)
    stub backup_start(id : Identifier)
    stub get_cluster_by_name(name : Identifier)
  end

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = cluster.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    it "confirms backup requested" do
      action.cluster_id = cluster.id

      expect(client).to receive(:get_cluster).and_return(cluster)
      expect(client).to receive(:backup_start).and_return(CB::Client::Message.new)
      action.call

      expect(&.output.to_s).to match /requested backup capture of /
    end
  end
end

Spectator.describe CB::BackupList do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(client) { Client.new TEST_TOKEN }
  let(cluster) { Factory.cluster }

  mock Client do
    stub backup_list(id : Identifier)
  end

  describe "#validate" do
    it "ensures required arguments are presentt" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = cluster.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    it "says when there are no backups" do
      action.cluster_id = cluster.id

      expect(client).to receive(:backup_list).and_return([] of CB::Client::Backup)

      action.call

      expect(&.output.to_s).to eq "no backups yet"
    end

    it "prints info when there are backups" do
      action.cluster_id = cluster.id

      expect(client).to receive(:backup_list).and_return([Factory.backup])

      action.call

      expected = <<-EXPECTED
      a backup\t                 123\t2022-01-01T00:00:00Z\t2022-02-01T00:00:00Z\t1/a      \t2/b\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end

Spectator.describe CB::BackupToken do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(client) { Client.new TEST_TOKEN }
  let(cluster) { Factory.cluster }

  mock Client do
    stub backup_token(id : Identifier)
  end

  describe "#validate" do
    it "ensures required arguments are presentt" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = cluster.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each {
      action.cluster_id = cluster.id
    }

    it "outputs aws backup token" do
      expect(client).to receive(:backup_token).and_return(Factory.backup_token_aws)
      action.call
      expect(&.output.to_s).to match /Type:.*s3.*/
    end

    it "ouputs azr backup token" do
      expect(client).to receive(:backup_token).and_return(Factory.backup_token_azr)
      action.call
      expect(&.output.to_s).to match /Type:.*azure.*/
    end
  end
end
