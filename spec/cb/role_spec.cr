require "../spec_helper"
include CB

private TEST_ROLE = Client::Role.new name: "u_123", password: "secret", uri: URI.parse "postgres://u_123@foo.com"

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

Spectator.describe RoleUpdate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }

  mock Client do
    stub get_account { Client::Account.new id: "123", name: "accounty mcaccounterson" }
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

    expect(&.call).to raise_error Program::Error, /invalid role '#{action.role_name}'/
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

    expect(&.call).to raise_error Program::Error, /invalid role '#{action.role_name}'/
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
