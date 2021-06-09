require "../spec_helper"

private class CompletionTestClient < CB::Client
  def get_clusters
    [Cluster.new("abc", "def", "my cluster")]
  end

  def get_teams
    [Team.new("def", "my team", false, [1])]
  end

  def get_firewall_rules(id)
    [FirewallRule.new("f1", "1.2.3.4/32"), FirewallRule.new("f2", "4.5.6.7/24")]
  end

  def get_providers
    [
      Provider.new(
        "aws", "AWS",
        plans: [Plan.new("memory-16", "Memory-16")],
        regions: [Region.new("us-west-2", "US West 2", "Oregon")]
      ),
      Provider.new(
        "gcp", "GCP",
        plans: [Plan.new("standard-128", "Standard-128")],
        regions: [Region.new("us-central1", "US Central 1", "Iowa")]
      ),
    ]
  end
end

module Spec
  struct ContainOptionExpectation(T)
    def initialize(@expected_value : T)
    end

    def match(actual_value)
      actual_value.any?(&.starts_with?(@expected_value))
    end

    def failure_message(actual_value)
      "Expected:   #{actual_value.inspect}\nto include option: #{@expected_value.inspect}"
    end

    def negative_failure_message(actual_value)
      "Expected: value #{actual_value.inspect}\nto not include option: #{@expected_value.inspect}"
    end
  end

  module Expectations
    def have_option(expected)
      Spec::ContainOptionExpectation.new(expected)
    end
  end
end

private def parse(str)
  CB::Completion.new(CompletionTestClient.new(TEST_TOKEN), str).parse
end

describe CB::Completion do
  it "returns suggestions for top level commands" do
    result = parse("cb ")
    result.any?(&.starts_with?("login")).should be_true
  end

  it "info suggests clusters" do
    result = parse("cb info ")
    result.should eq ["abc\tmy team/my cluster"]
  end

  it "create" do
    result = parse("cb create ")
    result.should have_option "--platform"
    result.should have_option "--help"

    result = parse("cb create -p ")
    result.should_not have_option "--platform"
    result.should have_option "aws"
    result.should have_option "azr"
    result.should have_option "gcp"

    result = parse("cb create --platform ")
    result.should_not have_option "--platform"
    result.should have_option "aws"
    result.should have_option "azr"
    result.should have_option "gcp"

    result = parse("cb create --platform aws ")
    result.should_not have_option "aws"
    result.should_not have_option "--platform"
    result.should have_option "--region"
    result.should have_option "--plan"

    result = parse("cb create --region ")
    result.should eq ([] of String)

    result = parse("cb create --plan ")
    result.should eq ([] of String)

    result = parse("cb create --platform aws --region ")
    result.should_not have_option "--plan"
    result.should_not have_option "us-central1"
    result.should have_option "us-west-2"

    result = parse("cb create --platform gcp --region ")
    result.should_not have_option "--plan"
    result.should_not have_option "us-west-2"
    result.should have_option "us-central1"

    result = parse("cb create --platform gcp -r ")
    result.should_not have_option "--plan"
    result.should_not have_option "us-west-2"
    result.should have_option "us-central1"

    result = parse("cb create --platform lol --region ")
    result.should eq ([] of String)

    result = parse("cb create --platform aws -r us-west-2 ")
    result.should have_option "--plan"

    result = parse("cb create --platform aws --plan ")
    result.should_not have_option "--plan"
    result.should_not have_option "standard-128"
    result.should have_option "memory-16"

    result = parse("cb create --platform gcp --plan ")
    result.should_not have_option "--plan"
    result.should_not have_option "memory-16"
    result.should have_option "standard-128"

    result = parse("cb create --platform aws --plan hobby-4 ")
    result.should_not have_option "--plan"
    result.should have_option "--region"

    result = parse("cb create --storage ")
    result.should have_option "100"
    result.should have_option "512"

    result = parse("cb create -s ")
    result.should have_option "100"
    result.should have_option "512"

    result = parse("cb create --team ")
    result.should have_option "def"

    result = parse("cb create -t ")
    result.should have_option "def"

    result = parse("cb create --ha ")
    result.should have_option "true"
    result.should have_option "false"

    parse("cb create --ha false -p") # no space at end, test for IndexError

    result = parse("cb create --help ")
    result.should eq [] of String

    result = parse("cb create --name ")
    result.should eq [] of String

    result = parse("cb create --name \"some name\" ")
    result.should_not be_empty
    result.should_not have_option "--name"

    result = parse("cb create --name \"some name\" -s  ")
    result.should have_option "512"
  end

  it "firewall" do
    result = parse("cb firewall ")
    result.should have_option "--cluster"
    result.should_not have_option "--add"
    result.should_not have_option "--remove"

    result = parse("cb firewall --cluster abc ")
    result.should_not have_option "--cluster"
    result.should have_option "--add"
    result.should have_option "--remove"

    result = parse("cb firewall --cluster ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb firewall --cluster abc --cluster ")
    result.should eq [] of String

    result = parse("cb firewall --cluster abc --add 1.2.3/4 --remove 1.2.3.4/5 ")
    result.should_not have_option "--cluster"
    result.should have_option "--add"
    result.should have_option "--remove"

    result = parse("cb firewall --add ")
    result.should eq [] of String

    result = parse("cb firewall --cluster abc --add ")
    result.should eq [] of String

    result = parse("cb firewall --remove ")
    result.should eq [] of String

    result = parse("cb firewall --cluster abc --remove ")
    result.should eq ["1.2.3.4/32", "4.5.6.7/24"]

    result = parse("cb firewall --cluster abc --remove 4.5.6.7/24 --remove ")
    result.should eq ["1.2.3.4/32"]

    result = parse("cb firewall --cluster abc --remove 4.5.6.7/24 --remove 1.2.3.4/32 ")
    result.should have_option "--add"
    result.should_not have_option "--remove"

    result = parse("cb firewall --cluster abc --remove 4.5.6.7/24 --remove 1.2.3.4/32 --remove ")
    result.should eq [] of String
  end
end
