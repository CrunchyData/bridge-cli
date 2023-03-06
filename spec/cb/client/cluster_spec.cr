require "../../spec_helper"

require "../../../src/client/*"

Spectator.describe CB::Client do
  subject(client) { described_class.new TEST_TOKEN }

  describe "#flatten_clusters" do
    it "handles no clusters" do
      clusters = [] of CB::Model::Cluster
      expect(&.flatten_clusters(clusters)).to be_empty
    end

    it "handles clusters without replicas" do
      clusters = [CB::Model::Cluster.new(
        id: "pkdpq6yynjgjbps4otxd7il2u4",
        team_id: "l2gnkxjv3beifk6abkraerv7de",
        name: "abc",
        replicas: nil,
      )]

      result = client.flatten_clusters(clusters)
      expect(result.size).to eq 1
    end

    it "handles clusters with replicas" do
      clusters = [CB::Model::Cluster.new(
        id: "pkdpq6yynjgjbps4otxd7il2u4",
        team_id: "l2gnkxjv3beifk6abkraerv7de",
        name: "abc",
        replicas: [
          CB::Model::Cluster.new(
            id: "replica_id",
            team_id: "l2gnkxjv3beifk6abkraerv7de",
            name: "replica of abc",
            replicas: [
              CB::Model::Cluster.new(
                id: "replica_of_replica_id",
                team_id: "l2gnkxjv3beifk6abkraerv7de",
                name: "replica of replica",
                replicas: nil),
            ]),
        ],
      )]

      result = client.flatten_clusters(clusters)
      expect(result.size).to eq 3
    end
  end
end
