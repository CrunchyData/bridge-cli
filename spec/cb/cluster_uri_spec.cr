require "../spec_helper"
include CB

Spectator.describe CB::ClusterURI do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(account) { Factory.account }
  let(cluster) { Factory.cluster }
  let(role) { Factory.role_user }

  describe "#initialize" do
    it "ensures 'default' if role not specified" do
      action.cluster_id = cluster.id
      expect(&.role.to_s).to eq "default"
    end
  end

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = cluster.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    it "output default format" do
      action.cluster_id = cluster.id
      action.role = "user"

      expect(client).to receive(:get_account).and_return(account)
      expect(client).to receive(:get_role).and_return(role)

      action.call

      expected = <<-EXPECTED
      postgres://u_mijrfkkuqvhernzfqcbqf7b6me:secret@example.com:5432/postgres
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end
