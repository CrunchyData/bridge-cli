require "../spec_helper"

Spectator.describe CB::List do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(team) { Factory.team }

  describe "#call" do
    before_each {
      expect(client).to receive(:get_teams).and_return [team]
    }

    it "outputs table format" do
      action.format = CB::Format::Table

      # Cluster results should be flattened.
      expect(client).to receive(:get_clusters)
        .with(Array(CB::Client::Team), Bool)
        .and_return(
          [
            CB::Client::Cluster.new("abc", team.id, "my cluster", nil),
            CB::Client::Cluster.new("replica-id", team.id, "my replica", nil),
          ])

      action.call

      expected = <<-EXPECTED
        ID           Name         Team       
        abc          my cluster   Test Team  
        replica-id   my replica   Test Team  \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs tree format" do
      action.format = CB::Format::Tree

      expect(client).to receive(:get_clusters)
        .with(Array(CB::Client::Team), Bool)
        .and_return(
          [
            CB::Client::Cluster.new("abc", team.id, "my cluster", [
              CB::Client::Cluster.new("replica-id", team.id, "my replica", nil),
            ]),
          ])

      action.call

      expected = <<-EXPECTED
      Test Team
      └── my cluster (abc)
          └── my replica (replica-id)\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end
