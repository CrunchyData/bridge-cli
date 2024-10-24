require "../spec_helper"

Spectator.describe CB::ClusterInfo do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(team) { Factory.team }
  let(cluster) { Factory.cluster }
  let(cluster_status) { Factory.cluster_status }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = cluster.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    it "outputs default format" do
      action.output = IO::Memory.new
      action.cluster_id = team.id + "/" + cluster.id

      expect(client).to receive(:get_cluster).with(action.cluster_id[:cluster]).and_return cluster
      expect(client).to receive(:get_cluster_status).and_return cluster_status
      expect(client).to receive(:get_team).with(cluster.team_id).and_return team
      expect(client).to receive(:get_firewall_rules).with(cluster.network_id).and_return [] of CB::Model::FirewallRule

      action.call

      expected = <<-EXPECTED
      Test Team/abc
                     state: ready
                      host: p.pkdpq6yynjgjbps4otxd7il2u4.example.com
                   created: 2016-02-15T10:20:30Z
                      plan: memory-4 (111GiB ram, 4vCPU)
                   version: 12
                   storage: 1234GiB
                        ha: off
                  platform: aws
                    region: us-east-2
        maintenance window: no window set. Default to: 00:00-23:59
          tailscale active: false
                   network: nfpvoqooxzdrriu6w3bhqo55c4
                  firewall: no rules\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end
