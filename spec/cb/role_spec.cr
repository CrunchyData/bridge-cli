require "../spec_helper"
include CB

private TEST_ROLE = Client::Role.new(
  account_email: "test@example.com",
  name: "u_123",
  password: "secret",
  uri: URI.parse "postgres://u_123@foo.com",
)

private SYSTEM_ROLE = Client::Role.new(
  name: "application",
  password: "secret",
  uri: URI.parse "postgres://application@foo.com",
)

Spectator.describe RoleCreate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }
  let(role) { TEST_ROLE }

  mock Client do
    stub create_role(id)
  end

  it "validates that required arguments are present" do
    expect(&.validate).to raise_error Program::Error, /Missing required argument/

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    expect(&.validate).to be_true
  end

  it "#run prints confirmation" do
    action.output = IO::Memory.new
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"

    expect(client).to receive(:create_role).with(action.cluster_id).and_return role
    action.call

    expect(&.output.to_s).to eq "Role u_123 created on cluster #{action.cluster_id}.\n"
  end
end

Spectator.describe RoleList do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(client) { Client.new TEST_TOKEN }
  let(roles) { [SYSTEM_ROLE, TEST_ROLE] }
  let(team) { Factory.team }
  let(cluster) { Factory.cluster }

  mock Client do
    stub list_roles(id)
    stub get_cluster(id : String?)
    stub get_team(id)
  end

  it "validates that required arguments are present" do
    expect(&.validate).to raise_error Program::Error, /Missing required argument/

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    expect(&.validate).to be_true
  end

  it "outputs default" do
    action.output = IO::Memory.new
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"

    expect(client).to receive(:get_cluster).with(action.cluster_id).and_return cluster
    expect(client).to receive(:get_team).with(cluster.team_id).and_return team
    expect(client).to receive(:list_roles).with(action.cluster_id).and_return roles

    action.call

    expected = <<-EXPECTED
    +-------------------------------------+
    | Cluster: abc                        |
    | Team:    Test Team                  |
    +------------------+------------------+
    | Role             | Account          |
    +------------------+------------------+
    | application      | system           |
    | u_123            | test@example.com |
    +------------------+------------------+\n
    EXPECTED

    expect(&.output.to_s).to eq expected
  end

  it "outputs json" do
    action.output = IO::Memory.new
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.format = CB::RoleList::Format::JSON

    expect(client).to receive(:get_cluster).with(action.cluster_id).and_return cluster
    expect(client).to receive(:get_team).with(cluster.team_id).and_return team
    expect(client).to receive(:list_roles).with(action.cluster_id).and_return roles

    action.call

    expected = <<-EXPECTED
     {
       "cluster": "abc",
       "team": "Test Team",
       "roles": [
         {
           "role": "application",
           "account": "system"
         },
         {
           "role": "u_123",
           "account": "test@example.com"
         }
       ]
     }\n
     EXPECTED

    expect(&.output.to_s).to eq expected
  end
end

Spectator.describe RoleUpdate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }

  mock Client do
    stub get_account { Client::Account.new id: "123", name: "accounty mcaccounterson", email: "mcaccounterson@example.com" }
    stub update_role(cluster_id, role_name, ur) { TEST_ROLE }
  end

  before_each do
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.role_name = "user"
  end

  it "validates that required arguments are present" do
    action.cluster_id = nil
    expect(&.validate).to raise_error Program::Error, /Missing required argument/

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.role_name = "user"
    expect(&.validate).to be_true
  end

  it "#run errors on invalid role" do
    action.role_name = "invalid"

    expect(&.call).to raise_error Program::Error, /invalid role: '#{action.role_name}'/
  end

  it "#run translates 'user' role" do
    action.role_name = "user"
    action.call

    expect(&.role_name).to eq "u_123"
  end

  it "#run prints confirmation" do
    action.call

    expect(&.output.to_s).to eq "Role u_123 updated on cluster #{action.cluster_id}.\n"
  end
end

Spectator.describe RoleDelete do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }

  mock Client do
    stub delete_role(cluster_id, role_name) { TEST_ROLE }
  end

  before_each do
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.role_name = "user"
  end

  it "validate that required arguments are present" do
    action.cluster_id = nil
    expect(&.run).to raise_error Program::Error, /Missing required argument/

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.role_name = "user"
    expect(&.run).to_not raise_error
  end

  it "#run errors on invalid role" do
    action.role_name = "invalid"

    expect(&.call).to raise_error Program::Error, /invalid role: '#{action.role_name}'/
  end

  it "#run translates 'user' role" do
    action.role_name = "user"

    action.call

    expect(&.role_name).to eq "u_123"
  end

  it "#run prints confirmation" do
    action.call

    expect(&.output.to_s).to eq "Role u_123 deleted from cluster #{action.cluster_id}.\n"
  end
end
