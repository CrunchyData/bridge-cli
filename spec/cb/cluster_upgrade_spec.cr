require "../spec_helper"

private class ClusterUpgradeTestClient < CB::Client
  def upgrade_cluster(arg)
  end

  def upgrade_cluster_cancel(id : String)
  end

  def upgrade_cluster_status(id : String)
    Array(Operation).from_json "{\"operations\":[]}", root: "operations"
  end

  def get_teams
    teams = [] of Team
    teams << Team.new(
      id: "teamid",
      name: "",
      is_personal: true,
      role: "admin",
    )
  end

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
end

describe CB::UpgradeStart do
  it "validates that required arguments are present" do
    action = CB::UpgradeStart.new(ClusterUpgradeTestClient.new(TEST_TOKEN))

    msg = /Missing required argument/

    expect_cb_error(msg) { action.validate }
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.validate.should eq true
  end

  it "#run prints cluster upgrade started" do
    action = CB::UpgradeStart.new(ClusterUpgradeTestClient.new(TEST_TOKEN))
    action.output = output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.confirmed = true

    action.call

    output.to_s.should eq "  Cluster #{action.cluster_id} upgrade started.\n"
  end
end

describe CB::UpgradeStatus do
  it "validates that required arguments are present" do
    action = CB::UpgradeStatus.new(ClusterUpgradeTestClient.new(TEST_TOKEN))

    msg = /Missing required argument/

    expect_cb_error(msg) { action.validate }
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.validate.should eq true
  end

  it "#run no upgrades" do
    action = CB::UpgradeStatus.new(ClusterUpgradeTestClient.new(TEST_TOKEN))
    action.output = output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"

    action.call

    output.to_s.should eq "personal/source cluster\n  no upgrades in progress\n"
  end
end

describe CB::UpgradeCancel do
  it "validates that required arguments are present" do
    action = CB::UpgradeCancel.new(ClusterUpgradeTestClient.new(TEST_TOKEN))

    msg = /Missing required argument/

    expect_cb_error(msg) { action.validate }
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.validate.should eq true
  end

  it "#run " do
    action = CB::UpgradeCancel.new(ClusterUpgradeTestClient.new(TEST_TOKEN))
    action.output = output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"

    action.call

    expected = "personal/source cluster\n"
    expected += "  upgrade cancelled\n"

    output.to_s.should eq expected
  end
end
