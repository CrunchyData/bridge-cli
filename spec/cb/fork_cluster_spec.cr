require "../spec_helper"

private class ClusterForkTestClient < CB::Client
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
      storage: 1234
    )
  end
end

private def make_cf
  CB::ClusterFork.new(ClusterForkTestClient.new(TEST_TOKEN))
end

private def expect_validation_err(cf, part)
  expect_cb_error(/Missing required argument.+#{part}/) { cf.validate }
end

describe CB::ClusterFork do
  it "validates that required arguments are present" do
    cf = make_cf
    msg = /Missing required argument/

    expect_validation_err cf, "cluster"
    cf.cluster_id = "afpvoqooxzdrriu6w3bhqo55c4"
    expect_validation_err cf, "name"
    cf.name = "my fork"
    expect_validation_err cf, "plan"
    cf.plan = "hobby-2"
    expect_validation_err cf, "platform"
    cf.platform = "aws"
    expect_validation_err cf, "region"
    cf.region = "us-east-2"
    expect_validation_err cf, "storage"
    cf.storage = 1_000

    cf.validate.should eq true
  end

  it "fills in defaults from the source cluster" do
    cf = make_cf

    cf.name.should be_nil
    cf.platform.should be_nil
    cf.region.should be_nil
    cf.storage.should be_nil
    cf.plan.should be_nil

    cf.cluster_id = "afpvoqooxzdrriu6w3bhqo55c4"
    cf.pre_validate

    cf.name.should eq "Fork of source cluster"
    cf.platform.should eq "aws"
    cf.region.should eq "us-east-2"
    cf.storage.should eq 1234
    cf.plan.should eq "memory-4"
  end

  it "does not overwrite values given with defaults from source cluster" do
    cf = make_cf
    cf.cluster_id = "afpvoqooxzdrriu6w3bhqo55c4"

    cf.name = "given name"
    cf.platform = "gcp"
    cf.region = "centralus"
    cf.plan = "cpu-100"
    cf.storage = 4321

    cf.pre_validate

    cf.name.should eq "given name"
    cf.platform.should eq "gcp"
    cf.region.should eq "centralus"
    cf.plan.should eq "cpu-100"
    cf.storage.should eq 4321
  end

  it "can set the target time" do
    cf = make_cf
    msg = /Invalid at/

    expect_cb_error(msg) { cf.at = "hi" }
    expect_cb_error(msg) { cf.at = "" }
    expect_cb_error(msg) { cf.at = "2021-03-06T00:00:00" }

    cf.at = "2021-03-06T00:00:00Z"
    cf.at.should eq Time.utc(2021, 3, 6)

    cf.at = "2021-03-06T00:00:00+08:00"
    cf.at.should eq Time.utc(2021, 3, 5, 16)
  end

  # all below copied from create cluster, TODO: remove dupe

  it "checks ha input" do
    cf = make_cf
    msg = /Invalid ha/

    cf.ha.should eq false

    expect_cb_error(msg) { cf.ha = "yes" }
    expect_cb_error(msg) { cf.ha = "no" }
    expect_cb_error(msg) { cf.ha = "34" }
    expect_cb_error(msg) { cf.ha = "" }

    cf.ha = "true"
    cf.ha.should eq true
    cf.ha = "false"
    cf.ha.should eq false
    cf.ha = "TRUE"
    cf.ha.should eq true
  end

  it "checks storage input" do
    cf = make_cf
    msg = /Invalid storage/

    cf.storage.should be_nil

    expect_cb_error(msg) { cf.storage = "hi" }
    expect_cb_error(msg) { cf.storage = "" }
    expect_cb_error(msg) { cf.storage = "-20" }
    expect_cb_error(msg) { cf.storage = -20 }
    expect_cb_error(msg) { cf.storage = "0" }
    expect_cb_error(msg) { cf.storage = 0 }
    expect_cb_error(msg) { cf.storage = "123mb" }
    expect_cb_error(msg) { cf.storage = "100000" }

    cf.storage = "101"
    cf.storage.should eq 101
    cf.storage = "1_024"
    cf.storage.should eq 1024
    cf.storage = "01234"
    cf.storage.should eq 1234
  end

  it "checks name input" do
    cf = make_cf
    msg = /Invalid name/
    cf.name.should be_nil

    expect_cb_error(msg) { cf.name = "../ok" }
    expect_cb_error(msg) { cf.name = "<what" }

    cf.name = "A new Cluster 3"
    cf.name.should eq "A new Cluster 3"
  end

  it "checks provider input" do
    cf = make_cf
    msg = /Invalid platform/

    expect_cb_error(msg) { cf.platform = "idk" }
    expect_cb_error(msg) { cf.platform = "<ok" }

    cf.platform.should eq nil
    cf.platform = "aws"
    cf.platform.should eq "aws"
    cf.platform = "azr"
    cf.platform.should eq "azure"
    cf.platform = "gcp"
    cf.platform.should eq "gcp"
    cf.platform = "azure"
    cf.platform.should eq "azure"
    cf.platform = "AWS"
    cf.platform.should eq "aws"
  end

  it "checks region input" do
    cf = make_cf
    msg = /Invalid region/

    expect_cb_error(msg) { cf.region = "<ok" }

    cf.region = "thing-place3"
    cf.region.should eq "thing-place3"
  end

  it "checks plan input" do
    cf = make_cf
    msg = /Invalid plan/

    expect_cb_error(msg) { cf.plan = "<ok" }

    cf.plan = "my-plan3"
    cf.plan.should eq "my-plan3"
  end
end
