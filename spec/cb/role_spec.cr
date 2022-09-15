require "../spec_helper"
include CB

Spectator.describe RoleCreate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }

  let(user_role) { Factory.user_role }

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

    expect(client).to receive(:create_role).with(action.cluster_id).and_return user_role

    action.call

    expect(&.output.to_s).to eq "Role #{user_role.name} created on cluster #{action.cluster_id}.\n"
  end
end

Spectator.describe RoleList do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(client) { Client.new TEST_TOKEN }
  let(roles) { [Factory.system_role, Factory.user_role] }
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
    +-------------------------------------------------+
    | Cluster: abc                                    |
    | Team:    Test Team                              |
    +------------------------------+------------------+
    | Role                         | Account          |
    +------------------------------+------------------+
    | application                  | system           |
    | u_mijrfkkuqvhernzfqcbqf7b6me | user@example.com |
    +------------------------------+------------------+\n
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
           "role": "u_mijrfkkuqvhernzfqcbqf7b6me",
           "account": "user@example.com"
         }
       ]
     }\n
     EXPECTED

    expect(&.output.to_s).to eq expected
  end
end

Spectator.describe RoleUpdate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(account) { Factory.account }
  let(client) { Client.new TEST_TOKEN }

  mock Client do
    stub get_account { Factory.account }
    stub update_role(cluster_id, role_name, ur) { Factory.user_role }
  end

  describe "#validate" do
    it "validates that required arguments are present" do
      action.cluster_id = nil
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.role = "user"
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each do
      action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
      action.role = "user"
    end

    it "prints confirmation" do
      expect(client).to receive(:get_account).and_return account
      action.call
      expect(&.output.to_s).to eq "Role #{action.role} updated on cluster #{action.cluster_id}.\n"
    end
  end
end

Spectator.describe RoleDelete do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(account) { Factory.account }
  let(client) { Client.new TEST_TOKEN }

  mock Client do
    stub delete_role(cluster_id, role_name) { Factory.user_role }
    stub get_account
  end

  describe "#validate" do
    it "ensures required arguments are present" do
      action.cluster_id = nil
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.role = Role.new
      expect(&.validate).to_not raise_error
    end
  end

  describe "#call" do
    before_each do
      action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
      action.role = "user"
    end

    it "prints confirmation" do
      expect(client).to receive(:get_account).and_return account

      action.call

      expect(&.output.to_s).to eq "Role #{action.role} deleted from cluster #{action.cluster_id}.\n"
    end
  end
end
