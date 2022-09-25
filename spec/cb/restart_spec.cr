require "../spec_helper"

Spectator.describe CB::Restart do
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
    it "confirms restart requested" do
      action.cluster_id = cluster.id
      action.confirmed = true

      expect(client).to receive(:get_cluster).and_return(cluster)
      expect(client).to receive(:restart_cluster).and_return(cluster)

      action.call

      expect(&.output.to_s).to eq "Cluster #{cluster.id} restarted.\n"
    end
  end
end
