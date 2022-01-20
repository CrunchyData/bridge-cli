require "../spec_helper"

private class ClusterCreateTestClient < CB::Client
  def create_cluster(arg)
    Cluster.new("abc", "def", "my cluster", [] of Cluster)
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

private def make_cc
  CB::ClusterCreate.new(ClusterCreateTestClient.new(TEST_TOKEN))
end

describe CB::ClusterCreate do
  it "#run prints info about the cluster that was created" do
    cc = make_cc
    cc.output = output = IO::Memory.new
    cc.plan = "hobby-2"
    cc.platform = "aws"
    cc.region = "east"
    cc.team = "afpvoqooxzdrriu6w3bhqo55c4"

    cc.call
    output.to_s.should eq "Created cluster abc \"my cluster\"\n"
  end

  it "validates that required arguments are present" do
    cc = make_cc
    msg = /Missing required argument/

    expect_cb_error(msg) { cc.validate }
    cc.name = "some cluster"
    expect_cb_error(msg) { cc.validate }
    cc.plan = "plan"
    expect_cb_error(msg) { cc.validate }
    cc.platform = "aws"
    expect_cb_error(msg) { cc.validate }
    cc.region = "us-east-1"
    expect_cb_error(msg) { cc.validate }
    cc.team = "afpvoqooxzdrriu6w3bhqo55c4"
    cc.validate.should eq true
  end

  it "checks storage input" do
    cc = make_cc
    msg = /Invalid storage/

    expect_cb_error(msg) { cc.storage = "hi" }
    expect_cb_error(msg) { cc.storage = "" }
    expect_cb_error(msg) { cc.storage = "123mb" }

    cc.storage = "101"
    cc.storage.should eq 101
    cc.storage = "1_024"
    cc.storage.should eq 1024
    cc.storage = "01234"
    cc.storage.should eq 1234
  end

  it "checks ha input" do
    cc = make_cc
    msg = /Invalid ha/

    cc.ha.should eq false

    expect_cb_error(msg) { cc.ha = "yes" }
    expect_cb_error(msg) { cc.ha = "no" }
    expect_cb_error(msg) { cc.ha = "34" }
    expect_cb_error(msg) { cc.ha = "" }

    cc.ha = "true"
    cc.ha.should eq true
    cc.ha = "false"
    cc.ha.should eq false
    cc.ha = "TRUE"
    cc.ha.should eq true
  end

  it "checks team input" do
    cc = make_cc
    msg = /Invalid team id/

    expect_cb_error(msg) { cc.team = "yes" }
    expect_cb_error(msg) { cc.team = "afpvoqooxzdrriu6w3bhqo55c3" }
    expect_cb_error(msg) { cc.team = "aafpvoqooxzdrriu6w3bhqo55c4" }
    expect_cb_error(msg) { cc.team = "fpvoqooxzdrriu6w3bhqo55c4" }

    cc.team.should eq nil
    cc.team = "afpvoqooxzdrriu6w3bhqo55c4"
    cc.team.should eq "afpvoqooxzdrriu6w3bhqo55c4"
  end

  it "checks network input" do
    cc = make_cc
    msg = /Invalid network id/

    expect_cb_error(msg) { cc.network = "yes" }
    expect_cb_error(msg) { cc.network = "afpvoqooxzdrriu6w3bhqo55c3" }
    expect_cb_error(msg) { cc.network = "aafpvoqooxzdrriu6w3bhqo55c4" }
    expect_cb_error(msg) { cc.network = "fpvoqooxzdrriu6w3bhqo55c4" }

    cc.network.should eq nil
    cc.network = "afpvoqooxzdrriu6w3bhqo55c4"
    cc.network.should eq "afpvoqooxzdrriu6w3bhqo55c4"
  end

  it "checks provider input" do
    cc = make_cc
    msg = /Invalid platform/

    expect_cb_error(msg) { cc.platform = "idk" }
    expect_cb_error(msg) { cc.platform = "<ok" }

    cc.platform.should eq nil
    cc.platform = "aws"
    cc.platform.should eq "aws"
    cc.platform = "azr"
    cc.platform.should eq "azure"
    cc.platform = "gcp"
    cc.platform.should eq "gcp"
    cc.platform = "azure"
    cc.platform.should eq "azure"
    cc.platform = "AWS"
    cc.platform.should eq "aws"
  end

  it "checks region input" do
    cc = make_cc
    msg = /Invalid region/

    expect_cb_error(msg) { cc.region = "<ok" }

    cc.region = "thing-place3"
    cc.region.should eq "thing-place3"
  end

  it "checks plan input" do
    cc = make_cc
    msg = /Invalid plan/

    expect_cb_error(msg) { cc.plan = "<ok" }

    cc.plan = "my-plan3"
    cc.plan.should eq "my-plan3"
  end

  it "checks postgres_version input" do
    cc = make_cc
    msg = /Invalid postgres_version/

    expect_cb_error(msg) { cc.postgres_version = "<ok" }

    cc.postgres_version = 14
    cc.postgres_version.should eq 14
  end

  context "fork" do
    it "fills in defaults from the source cluster" do
      cc = make_cc

      cc.name.should be_nil
      cc.platform.should be_nil
      cc.region.should be_nil
      cc.storage.should be_nil
      cc.plan.should be_nil

      cc.fork = "afpvoqooxzdrriu6w3bhqo55c4"
      cc.pre_validate

      cc.name.should eq "Fork of source cluster"
      cc.platform.should eq "aws"
      cc.region.should eq "us-east-2"
      cc.storage.should eq 1234
      cc.plan.should eq "memory-4"

      cc.validate.should eq true
    end

    it "does not overwrite values given with defaults from source cluster" do
      cc = make_cc
      cc.fork = "afpvoqooxzdrriu6w3bhqo55c4"

      cc.name = "given name"
      cc.platform = "gcp"
      cc.region = "centralus"
      cc.plan = "cpu-100"
      cc.storage = 4321

      cc.pre_validate

      cc.name.should eq "given name"
      cc.platform.should eq "gcp"
      cc.region.should eq "centralus"
      cc.plan.should eq "cpu-100"
      cc.storage.should eq 4321
    end

    it "can set the target time" do
      cc = make_cc
      msg = /Invalid at/

      expect_cb_error(msg) { cc.at = "hi" }
      expect_cb_error(msg) { cc.at = "" }
      expect_cb_error(msg) { cc.at = "2021-03-06T00:00:00" }

      cc.at = "2021-03-06T00:00:00Z"
      cc.at.should eq Time.utc(2021, 3, 6)

      cc.at = "2021-03-06T00:00:00+08:00"
      cc.at.should eq Time.utc(2021, 3, 5, 16)
    end
  end
end
