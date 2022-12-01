require "../spec_helper"

Spectator.describe CB::ClusterCreate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(cluster) { Factory.cluster }
  let(team) { Factory.team }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect_missing_arg_error
      action.name = "some cluster"
      expect_missing_arg_error
      action.plan = "plan"
      expect_missing_arg_error
      action.platform = "aws"
      expect_missing_arg_error
      action.region = "us-east-1"
      expect_missing_arg_error
      action.team = team.id

      expect(&.validate).to be_true
    end
  end

  describe "#at=" do
    sample ["", "hi", "2021-03-06T00:00:00"] do |at|
      it "does not allow invalid values" do
        expect(&.at = at).to raise_error(Program::Error, /Invalid at/)
      end
    end

    it "allows valid values" do
      expect(&.at = "2021-03-06T00:00:00Z").to eq Time.utc(2021, 3, 6)
      expect(&.at = "2021-03-06T00:00:00+08:00").to eq Time.utc(2021, 3, 5, 16)
    end
  end

  describe "#storage=" do
    sample ["hi", "", "123mb"] do |storage|
      it "does not allow invalid values" do
        expect(&.storage = storage).to raise_error(Program::Error, /Invalid storage/)
      end
    end

    sample ["101", "1_024", "01234"] do |storage|
      it "allows valid values" do
        expect(&.storage = storage).to_not raise_error
      end
    end
  end

  describe "#ha=" do
    sample ["yes", "no", "34", ""] do |ha|
      it "does not allow invalid values" do
        expect(&.ha = ha).to raise_error(Program::Error, /Invalid ha/)
      end
    end
  end

  describe "#team=" do
    sample invalid_ids do |team|
      it "does not allow invalid values" do
        expect(&.team = team).to raise_error(Program::Error, /Invalid team id/)
      end
    end
  end

  describe "#network=" do
    sample invalid_ids do |network|
      it "does not allow invalid values" do
        expect(&.network = network).to raise_error(Program::Error, /Invalid network id/)
      end
    end
  end

  describe "#platform" do
    sample ["idk", "<ok"] do |platform|
      it "does not allow invalid values" do
        expect(&.platform = platform).to raise_error(Program::Error, /Invalid platform/)
      end
    end

    sample ["aws", "azr", "azure", "gcp"] do |platform|
      it "allows valid values" do
        expect(&.platform = platform).to_not raise_error
      end
    end
  end

  describe "#region=" do
    it "does not allow invalid values" do
      expect(&.region = "<ok").to raise_error(Program::Error, /Invalid region/)
    end
  end

  describe "#plan=" do
    it "does not allow invalid values" do
      expect(&.plan = "<ok").to raise_error(Program::Error, /Invalid plan/)
    end
  end

  describe "#postgres_version=" do
    it "does not allow invalid values" do
      expect(&.postgres_version = "<ok").to raise_error(Program::Error, /Invalid postgres_version/)
    end
  end

  describe "#call" do
    it "#prints info about the cluster that was created" do
      action.plan = "hobby-2"
      action.platform = "aws"
      action.region = "east"
      action.team = team.id

      expect(client).to receive(:create_cluster).and_return(CB::Client::Cluster.new("abc", "def", "my cluster", [] of CB::Client::Cluster))

      action.call

      expect(&.output.to_s).to eq "Created cluster abc \"my cluster\"\n"
    end
  end

  describe "#call - replica" do
    before_each {
      expect(client).to receive(:get_cluster).and_return(cluster)
    }

    it "fills in defaults from the source cluster" do
      expect(&.name).to be_nil
      expect(&.platform).to be_nil
      expect(&.region).to be_nil
      expect(&.storage).to be_nil
      expect(&.plan).to be_nil
      expect(&.network).to be_nil

      action.fork = cluster.id
      expect(&.pre_validate).to_not raise_error

      expect(&.name).to eq "Fork of abc"
      expect(&.platform).to eq "aws"
      expect(&.region).to eq "us-east-2"
      expect(&.storage).to eq 1234
      expect(&.plan).to eq "memory-4"
      expect(&.network).to eq cluster.network_id

      expect(&.validate).to be_true
    end

    it "does not overwrite values given with defaults from source cluster" do
      action.fork = cluster.id
      action.name = "given name"
      action.platform = "gcp"
      action.region = "centralus"
      action.plan = "cpu-100"
      action.storage = 4321
      action.network = "cywdcbebozfczpsnl2ha643m3e"

      expect(&.pre_validate).to_not raise_error

      expect(&.name).to eq "given name"
      expect(&.platform).to eq "gcp"
      expect(&.region).to eq "centralus"
      expect(&.plan).to eq "cpu-100"
      expect(&.storage).to eq 4321
      expect(&.network).to eq "cywdcbebozfczpsnl2ha643m3e"

      expect(&.validate).to be_true
    end
  end

  describe "#call - fork" do
    before_each {
      expect(client).to receive(:get_cluster).and_return(cluster)
    }

    it "fills in defaults from the source cluster" do
      expect(&.name).to be_nil
      expect(&.platform).to be_nil
      expect(&.region).to be_nil
      expect(&.storage).to be_nil
      expect(&.plan).to be_nil

      action.fork = cluster.id
      expect(&.pre_validate).to_not raise_error

      expect(&.name).to eq "Fork of abc"
      expect(&.platform).to eq "aws"
      expect(&.region).to eq "us-east-2"
      expect(&.storage).to eq 1234
      expect(&.plan).to eq "memory-4"

      expect(&.validate).to be_true
    end

    it "does not overwrite values given with defaults from source cluster" do
      action.fork = cluster.id
      action.name = "given name"
      action.platform = "gcp"
      action.region = "centralus"
      action.plan = "cpu-100"
      action.storage = 4321

      expect(&.pre_validate).to_not raise_error

      expect(&.name).to eq "given name"
      expect(&.platform).to eq "gcp"
      expect(&.region).to eq "centralus"
      expect(&.plan).to eq "cpu-100"
      expect(&.storage).to eq 4321

      expect(&.validate).to be_true
    end
  end
end
