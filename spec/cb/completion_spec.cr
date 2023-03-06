require "../spec_helper"

private class CompletionTestClient < CB::Client
  def get_clusters(teams : Array(CB::Client::Team)? = nil)
    [Factory.cluster]
  end

  def get_teams
    [Factory.team(name: "my team", role: "manager")]
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

  def get_log_destinations(id)
    [LogDestination.new("logid", "host", 2020, "template", "logdest descr")]
  end
end

module Spectator::Matchers
  struct HaveOptionMatcher(ExpectedType) < Matcher
    def initialize(@expected : Value(ExpectedType))
    end

    def description : String
      "have_option option #{@expected}"
    end

    def match(actual : Expression(T)) : MatchData forall T
      has_option = actual.value.any?(&.starts_with?(@expected.value))
      if has_option
        SuccessfulMatchData.new(match_data_description(actual.label))
      else
        FailedMatchData.new(match_data_description(actual.label),
          "#{actual.label} does not have #{@expected.label}",
          expected: @expected.value.inspect,
          actual: actual.value.inspect,
        )
      end
    end

    def negated_match(actual : Spectator::Expression(T)) : MatchData forall T
      has_option = actual.value.any?(&.starts_with?(@expected.value))
      if has_option
        FailedMatchData.new(match_data_description(actual.label),
          "#{actual.label} should not have #{@expected.label}",
          expected: @expected.value.inspect,
          actual: actual.value.inspect,
        )
      else
        SuccessfulMatchData.new(match_data_description(actual.label))
      end
    end
  end
end

# The DSL portion of the matcher.
# This captures the test expression and creates an instance of the matcher.
macro have_option(expected)
  %value = Spectator::Value.new({{expected}}, {{expected.stringify}})
  Spectator::Matchers::HaveOptionMatcher.new(%value)
end

private def parse(str)
  CB::Completion.new(CompletionTestClient.new(TEST_TOKEN), str).parse
end

Spectator.describe CB::Completion do
  subject(result) { parse(command) }

  let(expected_cluster_suggestion) { ["pkdpq6yynjgjbps4otxd7il2u4\tmy team/abc"] }
  let(expected_team_suggestion) { ["l2gnkxjv3beifk6abkraerv7de\tmy team"] }

  provided command: "cb " { expect(result).to have /^login/ }

  sample %w[info rename destroy logs suspend resume].each do |cmd|
    provided command: "cb #{cmd} " { expect(result).to eq expected_cluster_suggestion }
    provided command: "cb #{cmd} abc " { expect(result).to be_empty }
  end

  it "create" do
    result = parse("cb create ")
    expect(result).to have_option "--platform"
    expect(result).to have_option "--fork"
    expect(result).to have_option "--replica"
    expect(result).to have_option "--help"
    expect(result).to have_option "--network"
    expect(result).to have_option "--version"

    result = parse("cb create --fork ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb create --fork abc ")
    expect(result).to have_option "--at"
    expect(result).to have_option "--platform"
    expect(result).to_not have_option "--team"
    expect(result).to_not have_option "--fork"
    expect(result).to_not have_option "--replica"
    expect(result).to_not have_option "--version"

    result = parse("cb create --fork abc --at ")
    expect(result).to eq([] of String)

    result = parse("cb create --replica ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb create --replica abc ")
    expect(result).to have_option "--platform"
    expect(result).to_not have_option "--at"
    expect(result).to_not have_option "--team"
    expect(result).to_not have_option "--fork"
    expect(result).to_not have_option "--replica"
    expect(result).to_not have_option "--version"

    result = parse("cb create -p ")
    expect(result).to_not have_option "--platform"
    expect(result).to have_option "aws"
    expect(result).to have_option "azr"
    expect(result).to have_option "gcp"

    result = parse("cb create --platform ")
    expect(result).to_not have_option "--platform"
    expect(result).to have_option "aws"
    expect(result).to have_option "azr"
    expect(result).to have_option "gcp"

    result = parse("cb create --platform aws ")
    expect(result).to_not have_option "aws"
    expect(result).to_not have_option "--platform"
    expect(result).to have_option "--region"
    expect(result).to have_option "--plan"

    result = parse("cb create --network ")
    expect(result).to eq([] of String)

    result = parse("cb create --region ")
    expect(result).to eq([] of String)

    result = parse("cb create --plan ")
    expect(result).to eq([] of String)

    result = parse("cb create --platform aws --region ")
    expect(result).to_not have_option "--plan"
    expect(result).to_not have_option "us-central1"
    expect(result).to have_option "us-west-2"

    result = parse("cb create --platform gcp --region ")
    expect(result).to_not have_option "--plan"
    expect(result).to_not have_option "us-west-2"
    expect(result).to have_option "us-central1"

    result = parse("cb create --platform gcp -r ")
    expect(result).to_not have_option "--plan"
    expect(result).to_not have_option "us-west-2"
    expect(result).to have_option "us-central1"

    result = parse("cb create --platform azr -r ")
    expect(result).to_not have_option "--plan"
    expect(result).to_not have_option "us-west-2"
    expect(result).to have_option "westus"

    result = parse("cb create --platform lol --region ")
    expect(result).to eq([] of String)

    result = parse("cb create --platform aws -r us-west-2 ")
    expect(result).to have_option "--plan"

    result = parse("cb create --platform aws --plan ")
    expect(result).to_not have_option "--plan"
    expect(result).to_not have_option "standard-128"
    expect(result).to have_option "memory-16"

    result = parse("cb create --platform gcp --plan ")
    expect(result).to_not have_option "--plan"
    expect(result).to_not have_option "memory-16"
    expect(result).to have_option "standard-128"

    result = parse("cb create --platform azr --plan ")
    expect(result).to_not have_option "--plan"
    expect(result).to_not have_option "memory-16"
    expect(result).to have_option "standard-64"

    result = parse("cb create --platform aws --plan hobby-4 ")
    expect(result).to_not have_option "--plan"
    expect(result).to have_option "--region"

    result = parse("cb create --storage ")
    expect(result).to have_option "100"
    expect(result).to have_option "512"

    result = parse("cb create -s ")
    expect(result).to have_option "100"
    expect(result).to have_option "512"

    result = parse("cb create --team ")
    expect(result).to eq expected_team_suggestion

    result = parse("cb create -t ")
    expect(result).to eq expected_team_suggestion

    result = parse("cb create --ha ")
    expect(result).to have_option "true"
    expect(result).to have_option "false"

    parse("cb create --ha false -p") # no space at end, test for IndexError

    result = parse("cb create --help ")
    expect(result).to eq [] of String

    result = parse("cb create --name ")
    expect(result).to eq [] of String

    result = parse("cb create --name \"some name\" ")
    result.should_not be_empty
    expect(result).to_not have_option "--name"

    result = parse("cb create --name \"some name\" -s  ")
    expect(result).to have_option "512"

    result = parse("cb create --version ")
    expect(result).to eq [] of String

    result = parse("cb create -v ")
    expect(result).to eq [] of String

    result = parse("cb create --version 14 ")
    result.should_not be_empty
    expect(result).to_not have_option "--version"
    expect(result).to_not have_option "-v"

    result = parse("cb create -v 14 ")
    result.should_not be_empty
    expect(result).to_not have_option "--version"
    expect(result).to_not have_option "-v"
  end

  it "firewall" do
    result = parse("cb firewall ")
    expect(result).to have_option "--cluster"
    expect(result).to_not have_option "--add"
    expect(result).to_not have_option "--remove"

    result = parse("cb firewall --cluster abc ")
    expect(result).to_not have_option "--cluster"
    expect(result).to have_option "--add"
    expect(result).to have_option "--remove"

    result = parse("cb firewall --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb firewall --cluster abc --add 1.2.3/4 --remove 1.2.3.4/5 ")
    expect(result).to_not have_option "--cluster"
    expect(result).to have_option "--add"
    expect(result).to have_option "--remove"

    result = parse("cb firewall --add ")
    expect(result).to eq [] of String

    result = parse("cb firewall --cluster abc --add ")
    expect(result).to eq [] of String

    result = parse("cb firewall --remove ")
    expect(result).to eq [] of String

    result = parse("cb firewall --cluster abc --remove ")
    expect(result).to eq ["1.2.3.4/32", "4.5.6.7/24"]

    result = parse("cb firewall --cluster abc --remove 4.5.6.7/24 --remove ")
    expect(result).to eq ["1.2.3.4/32"]

    result = parse("cb firewall --cluster abc --remove 4.5.6.7/24 --remove 1.2.3.4/32 ")
    expect(result).to have_option "--add"
    expect(result).to_not have_option "--remove"

    result = parse("cb firewall --cluster abc --remove 4.5.6.7/24 --remove 1.2.3.4/32 --remove ")
    expect(result).to eq [] of String
  end

  it "logdest" do
    result = parse("cb logdest ")
    expect(result).to have_option "list"
    expect(result).to have_option "destroy"
    expect(result).to have_option "add"

    result = parse("cb logdest l")
    expect(result).to have_option "list"

    result = parse("cb logdest list ")
    expect(result).to have_option "--cluster"

    result = parse("cb logdest list --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb logdest list --cluster abc ")
    expect(result).to eq [] of String

    result = parse("cb logdest list --cluster abc --cluster ")
    expect(result).to eq [] of String

    result = parse("cb logdest d")
    expect(result).to have_option "destroy"

    result = parse("cb logdest destroy ")
    expect(result).to have_option "--cluster"

    result = parse("cb logdest destroy --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb logdest destroy --cluster abc ")
    expect(result).to have_option "--logdest"

    result = parse("cb logdest destroy --cluster abc --logdest ")
    expect(result).to eq ["logid\tlogdest descr"]

    result = parse("cb logdest destroy --cluster abc --logdest logid ")
    expect(result).to eq [] of String

    result = parse("cb logdest add ")
    expect(result).to have_option "--cluster"
    expect(result).to have_option "--port"
    expect(result).to have_option "--desc"
    expect(result).to have_option "--template"
    expect(result).to have_option "--host"

    result = parse("cb logdest add --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb logdest add --cluster abc ")
    expect(result).to_not have_option "--cluster"
    expect(result).to have_option "--port"
    expect(result).to have_option "--desc"
    expect(result).to have_option "--template"
    expect(result).to have_option "--host"

    result = parse("cb logdest add --port 3 ")
    expect(result).to_not have_option "--port"
    expect(result).to have_option "--cluster"

    result = parse("cb logdest add --desc 'some name' ")
    expect(result).to_not have_option "--desc"
    expect(result).to have_option "--cluster"

    result = parse("cb logdest add --template 'some template' ")
    expect(result).to_not have_option "--template"
    expect(result).to have_option "--cluster"

    result = parse("cb logdest add --host something.com ")
    expect(result).to_not have_option "--host"
    expect(result).to have_option "--cluster"
  end

  it "completes psql" do
    result = parse("cb psql ")
    result.should eq expected_cluster_suggestion

    result = parse("cb psql abc ")
    result.should have_option "--database"
    result.should have_option "--role"

    result = parse("cb psql abc --database ")
    result.empty?.should be_true

    result = parse("cb psql abc --role ")
    result.should eq CB::Role::VALID_CLUSTER_ROLES.to_a
  end

  it "completes scope" do
    result = parse("cb scope ")
    expect(result).to have_option "--cluster"

    result = parse("cb scope --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb scope --cluster a")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb scope --cluster abc ")
    expect(result).to have_option "--suite"
    expect(result).to have_option "--mandelbrot"
    expect(result).to have_option "--tables"
    expect(result).to have_option "--database"

    result = parse("cb scope --cluster abc --suite ")
    expect(result).to have_option "all"
    expect(result).to have_option "quick"
    expect(result).to_not have_option "--mandelbrot"

    result = parse("cb scope --cluster abc --suite quick ")
    expect(result).to_not have_option "--suite"
    expect(result).to have_option "--tables"

    result = parse("cb scope --cluster abc --mandelbrot ")
    expect(result).to have_option "--tables"
    expect(result).to_not have_option "--mandelbrot"

    result = parse("cb scope --cluster abc --database ")
    expect(result).to_not have_option "--database"
  end

  it "completes restart" do
    result = parse("cb restart ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb restart abc ")
    expect(result).to_not have_option "abc"

    result = parse("cb restart abc ")
    expect(result).to have_option "--confirm"
    expect(result).to have_option "--full"

    result = parse("cb restart abc --full ")
    expect(result).to have_option "--confirm"

    result = parse("cb restart abc --full --confirm ")
    result.empty?.should be_true
  end

  it "completes backup" do
    result = parse("cb backup ")
    expect(result).to have_option "list"
    expect(result).to have_option "capture"
    expect(result).to have_option "token"

    result = parse("cb backup list ")
    expect(result).to eq expected_cluster_suggestion
    result = parse("cb backup list abc ")
    expect(result).to_not have_option "abc"

    result = parse("cb backup capture ")
    expect(result).to eq expected_cluster_suggestion
    result = parse("cb backup capture abc ")
    expect(result).to_not have_option "abc"

    result = parse("cb backup token ")
    expect(result).to eq expected_cluster_suggestion
    result = parse("cb backup token abc ")
    expect(result).to_not have_option "abc"
    expect(result).to have_option "--format"
    result = parse("cb backup token abc --format ")
    expect(result).to eq ["default", "pgbackrest"]
  end

  it "completes detach" do
    result = parse("cb detach ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb detach abc ")
    expect(result).to have_option "--confirm"

    result = parse "cb detach abc --confirm "
    result.empty?.should be_true
  end

  it "completes tailscale" do
    result = parse("cb ")
    expect(result).to have_option "tailscale"

    result = parse("cb tailscale ")
    expect(result).to have_option "connect"
    expect(result).to have_option "disconnect"

    result = parse("cb tailscale connect ")
    expect(result).to have_option "--cluster"
    expect(result).to have_option "--authkey"

    result = parse("cb tailscale connect --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb tailscale connect --authkey ")
    result.should be_empty

    result = parse "cb tailscale disconnect "
    expect(result).to have_option "--cluster"

    result = parse("cb tailscale disconnect --cluster ")
    expect(result).to eq expected_cluster_suggestion
  end

  it "completes maintenance" do
    result = parse("cb ")
    expect(result).to have_option "maintenance"

    result = parse("cb maintenance ")
    expect(result).to have_option "info"
    expect(result).to have_option "set"
    expect(result).to have_option "cancel"
    expect(result).to have_option "create"

    result = parse("cb maintenance info ")
    expect(result).to have_option "--cluster"

    result = parse("cb maintenance info --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb maintenance cancel ")
    expect(result).to have_option "--cluster"

    result = parse("cb maintenance cancel --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse "cb maintenance set "
    expect(result).to have_option "--cluster"
    expect(result).to have_option "--window-start"
    expect(result).to have_option "--unset"

    result = parse("cb maintenance set --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb maintenance set --window-start ")
    result.should be_empty

    result = parse("cb maintenance set --cluster xx --unset ")
    result.should be_empty

    result = parse "cb maintenance create"
    expect(result).to have_option "--cluster"
    expect(result).to have_option "--starting-from"
    expect(result).to have_option "--now"
  end

  it "completes network" do
    result = parse("cb ")
    expect(result).to have_option "network"

    result = parse("cb network ")
    expect(result).to have_option "info"
    expect(result).to have_option "list"

    result = parse("cb network info ")
    expect(result).to have_option "--network"
    expect(result).to have_option "--format"

    result = parse("cb network info --network ")
    expect(result).to be_empty

    result = parse("cb network info --format ")
    expect(result).to have_option "table"
    expect(result).to have_option "json"

    result = parse("cb network list ")
    expect(result).to have_option "--team"
    expect(result).to have_option "--format"

    result = parse("cb network list --team ")
    expect(result).to eq expected_team_suggestion

    result = parse("cb network list --format ")
    expect(result).to have_option "table"
    expect(result).to have_option "json"
  end

  it "completes role" do
    # cb role
    result = parse("cb role ")
    expect(result).to have_option "create"
    expect(result).to have_option "update"
    expect(result).to have_option "destroy"

    # cb role create
    result = parse("cb role create ")
    expect(result).to have_option "--cluster"

    result = parse("cb role create --cluster ")
    expect(result).to eq expected_cluster_suggestion

    # cb role list
    result = parse("cb role list ")
    expect(result).to have_option "--cluster"

    result = parse("cb role list --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb role list --cluster abc ")
    expect(result).to have_option "--format"
    expect(result).to have_option "--no-header"

    result = parse("cb role list --cluster abc --format ")
    expect(result).to eq ["table", "json"]

    result = parse("cb role list --cluster abc --format table ")
    expect(result).to have_option "--no-header"

    result = parse("cb role list --cluster abc --format table --no-header ")
    expect(result).to eq [] of String

    # cb role update
    result = parse("cb role update ")
    expect(result).to have_option "--cluster"
    expect(result).to_not have_option "--name"
    expect(result).to_not have_option "--read-only"
    expect(result).to_not have_option "--rotate-password"

    result = parse("cb role update --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb role update --cluster abc ")
    expect(result).to_not have_option "--cluster"
    expect(result).to have_option "--name"
    expect(result).to have_option "--read-only"
    expect(result).to have_option "--rotate-password"

    # cb role destroy
    result = parse("cb role destroy ")
    expect(result).to have_option "--cluster"
    expect(result).to_not have_option "--name"

    result = parse("cb role destroy --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb role destroy --cluster abc ")
    expect(result).to_not have_option "--cluster"
    expect(result).to have_option "--name"

    result = parse("cb role destroy --name ")
    expect(result).to_not have_option "--name"
    expect(result).to eq CB::Role::VALID_CLUSTER_ROLES.to_a
  end

  it "completes uri" do
    result = parse("cb uri ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb uri abc ")
    expect(result).to have_option "--role"

    result = parse("cb uri abc --role ")
    expect(result).to eq CB::Role::VALID_CLUSTER_ROLES.to_a
  end

  it "completes team" do
    # cb team
    result = parse("cb team ")
    expect(result).to have_option "create"
    expect(result).to have_option "list"
    expect(result).to have_option "info"
    expect(result).to have_option "update"
    expect(result).to have_option "destroy"

    # cb team create
    result = parse("cb team create ")
    expect(result).to have_option "--name"

    # cb team list
    result = parse("cb team list ")
    expect(result).to eq [] of String

    # cb team info
    result = parse("cb team info ")
    expect(result).to eq expected_team_suggestion

    result = parse("cb team info def ")
    expect(result).to eq [] of String

    # cb team update
    result = parse("cb team update ")
    expect(result).to eq expected_team_suggestion

    result = parse("cb team update def ")
    expect(result).to have_option "--billing-email"
    expect(result).to have_option "--enforce-sso"
    expect(result).to have_option "--name"

    result = parse("cb team update def --enforce-sso ")
    expect(result).to eq ["false", "true"]

    result = parse("cb team update def --enforce-sso true ")
    expect(result).to_not have_option "--enforce-sso"
    expect(result).to have_option "--billing-email"
    expect(result).to have_option "--name"

    # cb team destroy
    result = parse("cb team destroy ")
    expect(result).to eq expected_team_suggestion

    result = parse("cb team destroy def ")
    expect(result).to eq [] of String
  end

  it "completes team-member" do
    # cb team-member
    result = parse("cb team-member ")
    expect(result).to have_option "add"
    expect(result).to have_option "info"
    expect(result).to have_option "list"
    expect(result).to have_option "update"
    expect(result).to have_option "remove"

    # cb team-member add
    result = parse("cb team-member add ")
    expect(result).to have_option "--team"
    expect(result).to have_option "--email"
    expect(result).to have_option "--role"

    result = parse("cb team-member add --team ")
    expect(result).to eq expected_team_suggestion

    result = parse("cb team-member add --email ")
    expect(result).to eq [] of String

    result = parse("cb team-member add --role ")
    expect(result).to eq ["admin", "manager", "member"]

    # cb team-member info
    result = parse("cb team-member info ")
    expect(result).to have_option "--team"
    expect(result).to have_option "--account"
    expect(result).to have_option "--email"

    result = parse("cb team-member info --team ")
    expect(result).to eq expected_team_suggestion

    result = parse("cb team-member info --account ")
    expect(result).to eq [] of String

    result = parse("cb team-member info --account abc ")
    expect(result).to have_option "--team"
    expect(result).to_not have_option "--account"
    expect(result).to_not have_option "--email"

    result = parse("cb team-member info --email test@example.com ")
    expect(result).to have_option "--team"
    expect(result).to_not have_option "--account"
    expect(result).to_not have_option "--email"

    # cb team-member list
    result = parse("cb team-member list ")
    expect(result).to have_option "--team"

    result = parse("cb team-member list --team ")
    expect(result).to eq expected_team_suggestion

    result = parse("cb team-member list --team def ")
    expect(result).to eq [] of String

    # cb team-member update
    result = parse("cb team-member update ")
    expect(result).to have_option "--team"
    expect(result).to have_option "--account"
    expect(result).to have_option "--email"
    expect(result).to have_option "--role"

    result = parse("cb team-member update --team ")
    expect(result).to eq expected_team_suggestion

    result = parse("cb team-member update --account ")
    expect(result).to eq [] of String

    result = parse("cb team-member update --account abc ")
    expect(result).to_not have_option "--account"
    expect(result).to_not have_option "--email"
    expect(result).to have_option "--team"
    expect(result).to have_option "--role"

    result = parse("cb team-member update --email ")
    expect(result).to eq [] of String

    result = parse("cb team-member update --email test@example.com ")
    expect(result).to_not have_option "--account"
    expect(result).to_not have_option "--email"
    expect(result).to have_option "--team"
    expect(result).to have_option "--role"

    result = parse("cb team-member update --role ")
    expect(result).to eq ["admin", "manager", "member"]

    # cb team-member remove
    result = parse("cb team-member remove ")
    expect(result).to have_option "--team"
    expect(result).to have_option "--account"
    expect(result).to have_option "--email"

    result = parse("cb team-member remove --team ")
    expect(result).to eq expected_team_suggestion

    result = parse("cb team-member remove --account ")
    expect(result).to eq [] of String

    result = parse("cb team-member remove --account abc ")
    expect(result).to have_option "--team"
    expect(result).to_not have_option "--account"
    expect(result).to_not have_option "--email"

    result = parse("cb team-member remove --email ")
    expect(result).to eq [] of String

    result = parse("cb team-member remove --email test@example.com ")
    expect(result).to have_option "--team"
    expect(result).to_not have_option "--account"
    expect(result).to_not have_option "--email"
  end

  it "completes upgrade" do
    # cb upgrade
    result = parse("cb upgrade ")
    expect(result).to have_option "start"
    expect(result).to have_option "status"
    expect(result).to have_option "cancel"

    result = parse("cb upgrade sta")
    expect(result).to have_option "start"
    expect(result).to have_option "status"

    # cb upgrade start
    result = parse("cb upgrade start ")
    expect(result).to have_option "--cluster"
    expect(result).to have_option "--ha"
    expect(result).to have_option "--plan"
    expect(result).to have_option "--storage"
    expect(result).to have_option "--starting-from"
    expect(result).to have_option "--now"
    expect(result).to have_option "--version"

    result = parse("cb upgrade start --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb upgrade start --cluster abc ")
    expect(result).to_not have_option "--cluster"
    expect(result).to have_option "--ha"
    expect(result).to have_option "--plan"
    expect(result).to have_option "--storage"
    expect(result).to have_option "--version"
    expect(result).to have_option "--starting-from"
    expect(result).to have_option "--now"

    result = parse("cb upgrade start --ha true ")
    expect(result).to have_option "--cluster"
    expect(result).to_not have_option "--ha"

    # cb upgrade cancel
    result = parse("cb upgrade c")
    expect(result).to have_option "cancel"

    result = parse("cb upgrade cancel ")
    expect(result).to have_option "--cluster"

    result = parse("cb upgrade cancel --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb upgrade cancel --cluster abc ")
    expect(result).to eq [] of String

    # cb upgrade status
    result = parse("cb upgrade status ")
    expect(result).to have_option "--cluster"

    result = parse("cb upgrade status --cluster ")
    expect(result).to eq expected_cluster_suggestion

    result = parse("cb upgrade status --cluster abc ")
    expect(result).to eq [] of String
  end
end
