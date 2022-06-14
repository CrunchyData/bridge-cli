require "../spec_helper"

private class RestartTestClient < CB::Client
  def get_cluster(id : String)
    ClusterDetail.new(
      id: id,
      team_id: "teamid",
      name: "source cluster",
      state: "na",
      created_at: Time.utc(2016, 2, 15, 10, 20, 30),
      is_ha: false,
      major_version: 12,
      plan_id: "memory-4",
      cpu: 4,
      memory: 111,
      oldest_backup: nil,
      provider_id: "aws",
      region_id: "us-east-2",
      network_id: "nfpvoqooxzdrriu6w3bhqo55c4",
      storage: 1234
    )
  end

  def restart_cluster(id, service : String)
  end
end

describe CB::Action::Restart do
  it "validates that required arguments are present" do
    action = CB::Action::Restart.new(RestartTestClient.new(TEST_TOKEN))

    msg = /Missing required argument/
    expect_cb_error(msg) { action.validate }

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.validate.should eq true
  end

  it "#run prints confirmation" do
    action = CB::Action::Restart.new(RestartTestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.confirmed = true

    action.call

    action.output.to_s.should eq "Cluster #{action.cluster_id} restarted.\n"
  end
end
