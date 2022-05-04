require "../spec_helper"

private class CompletionTestClient < CB::Client
  def get_clusters
    [Cluster.new("abc", "def", "my cluster", [] of Cluster)]
  end

  def get_teams
    [Team.new("def", "my team", false, "manager")]
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

  %w[info rename destroy logs].each do |cmd|
    it "#{cmd} is included in top level suggestions" do
      result = parse("cb ")
      result.any?(&.starts_with?(cmd)).should be_true
    end

    it "#{cmd} suggests clusters" do
      result = parse("cb #{cmd} ")
      result.should eq ["abc\tmy team/my cluster"]

      result = parse("cb #{cmd} abc ")
      result.should be_empty
    end
  end

  it "create" do
    result = parse("cb create ")
    result.should have_option "--platform"
    result.should have_option "--fork"
    result.should have_option "--replica"
    result.should have_option "--help"
    result.should have_option "--network"
    result.should have_option "--version"

    result = parse("cb create --fork ")
    result.should have_option "abc"

    result = parse("cb create --fork abc ")
    result.should have_option "--at"
    result.should have_option "--platform"
    result.should_not have_option "--team"
    result.should_not have_option "--fork"
    result.should_not have_option "--replica"
    result.should_not have_option "--version"

    result = parse("cb create --fork abc --at ")
    result.should eq([] of String)

    result = parse("cb create --replica ")
    result.should have_option "abc"

    result = parse("cb create --replica abc ")
    result.should have_option "--platform"
    result.should_not have_option "--at"
    result.should_not have_option "--team"
    result.should_not have_option "--fork"
    result.should_not have_option "--replica"
    result.should_not have_option "--version"

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

    result = parse("cb create --network ")
    result.should eq([] of String)

    result = parse("cb create --region ")
    result.should eq([] of String)

    result = parse("cb create --plan ")
    result.should eq([] of String)

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
    result.should eq([] of String)

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

    result = parse("cb create --version ")
    result.should eq [] of String

    result = parse("cb create -v ")
    result.should eq [] of String

    result = parse("cb create --version 14 ")
    result.should_not be_empty
    result.should_not have_option "--version"
    result.should_not have_option "-v"

    result = parse("cb create -v 14 ")
    result.should_not be_empty
    result.should_not have_option "--version"
    result.should_not have_option "-v"
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
    result.should have_option "--database"

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

    result = parse("cb scope --cluster abc --database ")
    result.should_not have_option "--database"
  end

  it "completes restart" do
    result = parse("cb restart ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb restart abc ")
    result.should_not have_option "abc"

    result = parse("cb restart abc ")
    result.should have_option "--confirm"
    result.should have_option "--full"

    result = parse("cb restart abc --full ")
    result.should have_option "--confirm"

    result = parse("cb restart abc --full --confirm ")
    result.empty?.should be_true
  end

  it "completes detach" do
    result = parse("cb detach ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb detach abc ")
    result.should have_option "--confirm"

    result = parse "cb detach abc --confirm "
    result.empty?.should be_true
  end

  it "completes role" do
    # cb role
    result = parse("cb role ")
    result.should have_option "create"
    result.should have_option "update"
    result.should have_option "destroy"

    # cb role create
    result = parse("cb role create ")
    result.should have_option "--cluster"

    result = parse("cb role create --cluster ")
    result.should eq ["abc\tmy team/my cluster"]

    # cb role update
    result = parse("cb role update ")
    result.should have_option "--cluster"
    result.should_not have_option "--name"
    result.should_not have_option "--read-only"
    result.should_not have_option "--rotate-password"

    result = parse("cb role update --cluster ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb role update --cluster abc ")
    result.should_not have_option "--cluster"
    result.should have_option "--name"
    result.should have_option "--read-only"
    result.should have_option "--rotate-password"

    # cb role destroy
    result = parse("cb role destroy ")
    result.should have_option "--cluster"
    result.should_not have_option "--name"

    result = parse("cb role destroy --cluster ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb role destroy --cluster abc ")
    result.should_not have_option "--cluster"
    result.should have_option "--name"

    result = parse("cb role destroy --name ")
    result.should_not have_option "--name"
    result.should eq CB::VALID_CLUSTER_ROLES.to_a
  end

  it "completes uri" do
    result = parse("cb uri ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb uri abc ")
    result.should have_option "--role"

    result = parse("cb uri abc --role ")
    result.should eq CB::VALID_CLUSTER_ROLES.to_a
  end

  it "completes team" do
    # cb teams
    #
    # NOTE:
    #  `cb teams` is deprecated. However, completion should:
    #     1. Rewrite to `cb team`
    #     2. Return the same suggestions as `cb team`.
    result = parse("cb teams ")
    result.should have_option "create"
    result.should have_option "list"
    result.should have_option "info"
    result.should have_option "update"
    result.should have_option "destroy"

    # cb team
    result = parse("cb team ")
    result.should have_option "create"
    result.should have_option "list"
    result.should have_option "info"
    result.should have_option "update"
    result.should have_option "destroy"

    # cb team create
    result = parse("cb team create ")
    result.should have_option "--name"

    # cb team list
    result = parse("cb team list ")
    result.should eq [] of String

    # cb team info
    result = parse("cb team info ")
    result.should eq ["def\tmy team"]

    result = parse("cb team info def ")
    result.should eq [] of String

    # cb team update
    result = parse("cb team update ")
    result.should eq ["def\tmy team"]

    result = parse("cb team update def ")
    result.should have_option "--billing-email"
    result.should have_option "--enforce-sso"
    result.should have_option "--name"

    result = parse("cb team update def --enforce-sso ")
    result.should eq ["false", "true"]

    result = parse("cb team update def --enforce-sso true ")
    result.should_not have_option "--enforce-sso"
    result.should have_option "--billing-email"
    result.should have_option "--name"

    # cb team destroy
    result = parse("cb team destroy ")
    result.should eq ["def\tmy team"]

    result = parse("cb team destroy def ")
    result.should eq [] of String
  end

  it "completes team-member" do
    # cb team-member
    result = parse("cb team-member ")
    result.should have_option "add"
    result.should have_option "info"
    result.should have_option "list"
    result.should have_option "update"
    result.should have_option "remove"

    # cb team-member add
    result = parse("cb team-member add ")
    result.should have_option "--team"
    result.should have_option "--email"
    result.should have_option "--role"

    result = parse("cb team-member add --team ")
    result.should eq ["def\tmy team"]

    result = parse("cb team-member add --email ")
    result.should eq [] of String

    result = parse("cb team-member add --role ")
    result.should eq ["admin", "manager", "member"]

    # cb team-member info
    result = parse("cb team-member info ")
    result.should have_option "--team"
    result.should have_option "--account"
    result.should have_option "--email"

    result = parse("cb team-member info --team ")
    result.should eq ["def\tmy team"]

    result = parse("cb team-member info --account ")
    result.should eq [] of String

    result = parse("cb team-member info --account abc ")
    result.should have_option "--team"
    result.should_not have_option "--account"
    result.should_not have_option "--email"

    result = parse("cb team-member info --email test@example.com ")
    result.should have_option "--team"
    result.should_not have_option "--account"
    result.should_not have_option "--email"

    # cb team-member list
    result = parse("cb team-member list ")
    result.should have_option "--team"

    result = parse("cb team-member list --team ")
    result.should eq ["def\tmy team"]

    result = parse("cb team-member list --team def ")
    result.should eq [] of String

    # cb team-member update
    result = parse("cb team-member update ")
    result.should have_option "--team"
    result.should have_option "--account"
    result.should have_option "--email"
    result.should have_option "--role"

    result = parse("cb team-member update --team ")
    result.should eq ["def\tmy team"]

    result = parse("cb team-member update --account ")
    result.should eq [] of String

    result = parse("cb team-member update --account abc ")
    result.should_not have_option "--account"
    result.should_not have_option "--email"
    result.should have_option "--team"
    result.should have_option "--role"

    result = parse("cb team-member update --email ")
    result.should eq [] of String

    result = parse("cb team-member update --email test@example.com ")
    result.should_not have_option "--account"
    result.should_not have_option "--email"
    result.should have_option "--team"
    result.should have_option "--role"

    result = parse("cb team-member update --role ")
    result.should eq ["admin", "manager", "member"]

    # cb team-member remove
    result = parse("cb team-member remove ")
    result.should have_option "--team"
    result.should have_option "--account"
    result.should have_option "--email"

    result = parse("cb team-member remove --team ")
    result.should eq ["def\tmy team"]

    result = parse("cb team-member remove --account ")
    result.should eq [] of String

    result = parse("cb team-member remove --account abc ")
    result.should have_option "--team"
    result.should_not have_option "--account"
    result.should_not have_option "--email"

    result = parse("cb team-member remove --email ")
    result.should eq [] of String

    result = parse("cb team-member remove --email test@example.com ")
    result.should have_option "--team"
    result.should_not have_option "--account"
    result.should_not have_option "--email"
  end

  it "completes upgrade" do
    # cb upgrade
    result = parse("cb upgrade ")
    result.should have_option "start"
    result.should have_option "status"
    result.should have_option "cancel"

    result = parse("cb upgrade sta")
    result.should have_option "start"
    result.should have_option "status"

    # cb upgrade start
    result = parse("cb upgrade start ")
    result.should have_option "--cluster"
    result.should have_option "--ha"
    result.should have_option "--plan"
    result.should have_option "--storage"
    result.should have_option "--version"

    result = parse("cb upgrade start --cluster ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb upgrade start --cluster abc ")
    result.should_not have_option "--cluster"
    result.should have_option "--ha"
    result.should have_option "--plan"
    result.should have_option "--storage"
    result.should have_option "--version"

    result = parse("cb upgrade start --ha true ")
    result.should have_option "--cluster"
    result.should_not have_option "--ha"

    # cb upgrade cancel
    result = parse("cb upgrade c")
    result.should have_option "cancel"

    result = parse("cb upgrade cancel ")
    result.should have_option "--cluster"

    result = parse("cb upgrade cancel --cluster ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb upgrade cancel --cluster abc ")
    result.should eq [] of String

    # cb upgrade status
    result = parse("cb upgrade status ")
    result.should have_option "--cluster"

    result = parse("cb upgrade status --cluster ")
    result.should eq ["abc\tmy team/my cluster"]

    result = parse("cb upgrade status --cluster abc ")
    result.should eq [] of String
  end
end
