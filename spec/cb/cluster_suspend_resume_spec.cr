require "../spec_helper"

Spectator.describe CB::ClusterSuspend do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(cluster) { Factory.cluster }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = cluster.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    it "confirms suspend requested" do
      action.cluster_id = cluster.id

      expect(client).to receive(:suspend_cluster).and_return(cluster)

      action.call

      expect(&.output.to_s).to eq "suspended cluster #{cluster.name}\n"
    end
  end
end

Spectator.describe CB::ClusterResume do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(cluster) { Factory.cluster }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = cluster.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    it "confirms resume requested" do
      action.cluster_id = cluster.id

      expect(client).to receive(:resume_cluster).and_return(cluster)

      action.call

      expect(&.output.to_s).to eq "resumed cluster #{cluster.name}\n"
    end
  end
end
