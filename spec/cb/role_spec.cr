require "../spec_helper"

private class RoleTestClient < CB::Client
  ACCOUNT = Account.new(
    id: "123",
    name: "user",
    email: "test@example.com"
  )

  CLUSTER = ClusterDetail.new(
    id: "pkdpq6yynjgjbps4otxd7il2u4",
    team_id: "teamid",
    name: "abc",
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

  SYSTEM_ROLE = Role.new(
    name: "application",
    uri: URI.parse "postgres://application:secret@localhost:5432/postgres"
  )

  USER_ROLE = Role.new(
    account_email: ACCOUNT.email,
    account_id: ACCOUNT.id,
    name: "u_" + ACCOUNT.id,
    password: "secret",
    uri: URI.parse "postgres://u_123:secret@localhost:5432/postgres"
  )

  TEAM = Team.new(
    id: "ijpjdc2a4vhphhels3krggqhyu",
    name: "Test Team",
    is_personal: false,
    role: "admin",
  )

  def get_account
    ACCOUNT
  end

  def get_cluster(id)
    CLUSTER
  end

  def get_team(id)
    TEAM
  end

  def create_role(id : String)
    USER_ROLE
  end

  def list_roles(id : String)
    [SYSTEM_ROLE, USER_ROLE]
  end

  def update_role(id : String, name : String, opts)
    USER_ROLE
  end

  def delete_role(id : String, name : String)
    USER_ROLE
  end
end

describe CB::RoleCreate do
  it "validates that required arguments are present" do
    action = CB::RoleCreate.new(RoleTestClient.new(TEST_TOKEN))

    msg = /Missing required argument/

    expect_cb_error(msg) { action.validate }
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.validate.should eq true
  end

  it "#run prints confirmation" do
    action = CB::RoleCreate.new(RoleTestClient.new(TEST_TOKEN))
    action.output = output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"

    action.call

    output.to_s.should eq "Role u_123 created on cluster #{action.cluster_id}.\n"
  end
end

describe CB::RoleList do
  it "validates that required arguments are present" do
    action = CB::RoleCreate.new(RoleTestClient.new(TEST_TOKEN))

    msg = /Missing required argument/

    expect_cb_error(msg) { action.validate }
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.validate.should eq true
  end

  it "outputs default" do
    client = RoleTestClient.new(TEST_TOKEN)

    action = CB::RoleList.new(client)
    action.output = output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"

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

    output.to_s.should eq expected
  end

  it "outputs json" do
    client = RoleTestClient.new(TEST_TOKEN)

    action = CB::RoleList.new(client)
    action.format = CB::RoleList::Format::JSON
    action.output = output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"

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

    output.to_s.should eq expected
  end
end

describe CB::RoleUpdate do
  it "validates that required arguments are present" do
    action = CB::RoleUpdate.new(RoleTestClient.new(TEST_TOKEN))

    msg = /Missing required argument/

    expect_cb_error(msg) { action.validate }
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.role_name = "user"
    action.validate.should eq true
  end

  it "#run errors on invalid role" do
    action = CB::RoleUpdate.new(RoleTestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.role_name = "invalid"

    msg = /invalid role '#{action.role_name}'/

    expect_cb_error(msg) { action.call }
  end

  it "#run translates 'user' role" do
    action = CB::RoleUpdate.new(RoleTestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.role_name = "user"

    action.call

    action.role_name.should eq "u_123"
  end

  it "#run prints confirmation" do
    action = CB::RoleUpdate.new(RoleTestClient.new(TEST_TOKEN))
    action.output = output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.role_name = "user"

    action.call

    output.to_s.should eq "Role u_123 updated on cluster #{action.cluster_id}.\n"
  end
end

describe CB::RoleDelete do
  it "validate that required arguments are present" do
    action = CB::RoleDelete.new(RoleTestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.role_name = "user"
  end

  it "#run errors on invalid role" do
    action = CB::RoleDelete.new(RoleTestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.role_name = "invalid"

    expect_raises(CB::Program::Error, "invalid role '#{action.role_name}'") { action.call }
  end

  it "#run translates 'user' role" do
    action = CB::RoleDelete.new(RoleTestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.role_name = "user"

    action.call

    action.role_name.should eq "u_123"
  end

  it "#run prints confirmation" do
    action = CB::RoleDelete.new(RoleTestClient.new(TEST_TOKEN))
    action.output = output = IO::Memory.new

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.role_name = "user"

    action.call

    output.to_s.should eq "Role u_123 deleted from cluster #{action.cluster_id}.\n"
  end
end
