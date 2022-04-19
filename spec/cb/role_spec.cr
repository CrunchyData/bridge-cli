require "../spec_helper"

private class RoleTestClient < CB::Client
  ACCOUNT = Account.new(
    id: "123",
    name: "user",
  )

  ROLE = Role.new(
    name: "u_" + ACCOUNT.id,
    password: "secret",
    uri: URI.parse "postgres://u_123:secret@localhost:5432/postgres"
  )

  def get_account
    ACCOUNT
  end

  def create_role(id : String)
    ROLE
  end

  def update_role(id : String, name : String, opts)
    ROLE
  end

  def delete_role(id : String, name : String)
    ROLE
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
