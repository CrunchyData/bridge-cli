require "../spec_helper"

private class ClusterCreateTestClient < CB::Client
  def create_cluster(arg)
    Cluster.new("abc", "def", "my cluster")
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

    cc.storage.should eq 100

    expect_cb_error(msg) { cc.storage = "hi" }
    expect_cb_error(msg) { cc.storage = "" }
    expect_cb_error(msg) { cc.storage = "-20" }
    expect_cb_error(msg) { cc.storage = -20 }
    expect_cb_error(msg) { cc.storage = "0" }
    expect_cb_error(msg) { cc.storage = 0 }
    expect_cb_error(msg) { cc.storage = "123mb" }
    expect_cb_error(msg) { cc.storage = "100000" }

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

  it "checks name input" do
    cc = make_cc
    msg = /Invalid name/
    cc.name.should_not be_nil

    expect_cb_error(msg) { cc.name = "../ok" }
    expect_cb_error(msg) { cc.name = "<what" }

    cc.name = "A new Cluster 3"
    cc.name.should eq "A new Cluster 3"
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
end
