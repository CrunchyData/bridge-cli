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
      Provider.new(
        "azure", "Azure",
        plans: [Plan.new("standard-64", "Standard-64")],
        regions: [Region.new("westus", "West US", "California")]
      ),
    ]
  end

  def get_logdests(id)
    [Logdest.new("logid", "host", 2020, "template", "logdest descr")]
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
    result.should have_option "--fork"
    result.should have_option "--help"

    result = parse("cb create --fork ")
    result.should have_option "abc"

    result = parse("cb create --fork abc ")
    result.should have_option "--at"
    result.should have_option "--platform"
    result.should_not have_option "--team"

    result = parse("cb create --fork abc --at ")
    result.should eq ([] of String)

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

    result = parse("cb create --platform azr -r ")
    result.should_not have_option "--plan"
    result.should_not have_option "us-west-2"
    result.should have_option "westus"

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

    result = parse("cb create --platform azr --plan ")
    result.should_not have_option "--plan"
    result.should_not have_option "memory-16"
    result.should have_option "standard-64"

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

  it "logdest" do
    result = parse("cb logdest ")
    result.should have_option "list"
    result.should have_option "destroy"
    result.should have_option "add"

    result = parse("cb logdest l")
    result.should have_option "list"

    result = parse("cb logdest list ")
    result.should have_option "--cluster"

    result = parse("cb logdest list --cluster ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb logdest list --cluster abc ")
    result.should eq [] of String

    result = parse("cb logdest list --cluster abc --cluster ")
    result.should eq [] of String

    result = parse("cb logdest d")
    result.should have_option "destroy"

    result = parse("cb logdest destroy ")
    result.should have_option "--cluster"

    result = parse("cb logdest destroy --cluster ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb logdest destroy --cluster abc ")
    result.should have_option "--logdest"

    result = parse("cb logdest destroy --cluster abc --logdest ")
    result.should eq ["logid\tlogdest descr"]

    result = parse("cb logdest destroy --cluster abc --logdest logid ")
    result.should eq [] of String

    result = parse("cb logdest add ")
    result.should have_option "--cluster"
    result.should have_option "--port"
    result.should have_option "--desc"
    result.should have_option "--template"
    result.should have_option "--host"

    result = parse("cb logdest add --cluster ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb logdest add --cluster abc ")
    result.should_not have_option "--cluster"
    result.should have_option "--port"
    result.should have_option "--desc"
    result.should have_option "--template"
    result.should have_option "--host"

    result = parse("cb logdest add --port 3 ")
    result.should_not have_option "--port"
    result.should have_option "--cluster"

    result = parse("cb logdest add --desc 'some name' ")
    result.should_not have_option "--desc"
    result.should have_option "--cluster"

    result = parse("cb logdest add --template 'some template' ")
    result.should_not have_option "--template"
    result.should have_option "--cluster"

    result = parse("cb logdest add --host something.com ")
    result.should_not have_option "--host"
    result.should have_option "--cluster"
  end

  it "completes scope" do
    result = parse("cb scope ")
    result.should have_option "--cluster"

    result = parse("cb scope --cluster ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb scope --cluster a")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb scope --cluster abc ")
    result.should have_option "--suite"
    result.should have_option "--mandelbrot"
    result.should have_option "--tables"

    result = parse("cb scope --cluster abc --suite ")
    result.should have_option "all"
    result.should have_option "quick"
    result.should_not have_option "--mandelbrot"

    result = parse("cb scope --cluster abc --suite quick ")
    result.should_not have_option "--suite"
    result.should have_option "--tables"

    result = parse("cb scope --cluster abc --mandelbrot ")
    result.should have_option "--tables"
    result.should_not have_option "--mandelbrot"
  end
end
