require "../spec_helper"

Spectator.describe CB::TeamMemberAdd do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  it "validates that required arguments are present" do
    expect_missing_arg_error

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.email = "test@example.com"
    expect(&.validate).to be_true

    action.role = "some role"
    msg = /invalid role '#{action.role}'/
    expect(&.validate).to raise_error(Program::Error, msg)
  end

  it "#run prints confirmation" do
    expect(client).to receive(:create_team_member).and_return(Factory.team_member)

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.email = "test@example.com"

    action.call

    expect(&.output.to_s).to eq "Added #{action.email} to team #{action.team_id} as role 'member'.\n"
  end
end

Spectator.describe CB::TeamMemberInfo do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  it "validates that required arguments are present" do
    msg = /Missing required argument/
    expect(&.call).to raise_error(Program::Error, msg)
  end

  it "#run prints unknown member" do
    expect(client).to receive(:list_team_members).and_return([Factory.team_member])

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.email = "unknown@example.com"

    action.call

    expected = "Unknown team member.\n"
    expect(&.output.to_s).to eq expected
  end
end

Spectator.describe CB::TeamMemberList do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  it "validates that required arguments are present" do
    msg = /Missing required argument/
    expect(&.call).to raise_error(Program::Error, msg)
  end

  it "#run" do
    expect(client).to receive(:list_team_members).and_return([Factory.team_member])

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.call.should be nil
    action.output.to_s.should_not eq ""
  end
end

Spectator.describe CB::TeamMemberUpdate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  it "validates that required arguments are present" do
    msg = /Missing required argument/
    expect(&.call).to raise_error(Program::Error, msg)
  end

  it "validates argument conflicts" do
    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.account_id = "4pfqoxothfagnfdryk2og7noei"
    action.email = "test@example.com"

    msg = /Must only use '--account' or '--email' but not both./
    expect(&.call).to raise_error(Program::Error, msg)
  end

  describe "#run" do
    before_each {
      expect(client).to receive(:update_team_member).and_return(Factory.team_member)
    }

    it "#updates with account id" do
      action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
      action.account_id = "4pfqoxothfagnfdryk2og7noei"
      action.call.should_not be nil
      action.output.to_s.should_not eq ""
    end

    it "updates with acount email" do
      expect(client).to receive(:list_team_members).and_return([Factory.team_member])
      action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
      action.email = "test@example.com"
      action.call.should_not be nil
      action.output.to_s.should_not eq ""
    end
  end

  it "#run unknown team member" do
    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.email = "unknown@example.com"

    expect(client).to receive(:list_team_members).and_return([Factory.team_member])

    msg = /Unknown team member/
    expect(&.call).to raise_error(Program::Error, msg)
  end
end

Spectator.describe CB::TeamMemberRemove do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  it "validates that required arguments are present" do
    msg = /Missing required argument/
    expect(&.call).to raise_error(Program::Error, msg)
  end

  it "validates argument conflicts" do
    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.account_id = "4pfqoxothfagnfdryk2og7noei"
    action.email = "test@example.com"

    msg = /Must only use '--account' or '--email' but not both./
    expect(&.call).to raise_error(Program::Error, msg)
  end

  describe "#run" do
    before_each {
      expect(client).to receive(:remove_team_member).and_return(Factory.team_member)
      expect(client).to receive(:get_team).and_return(Factory.team)

      action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    }

    it "removes with account id" do
      action.account_id = "4pfqoxothfagnfdryk2og7noei"
      action.call.should_not be nil
      action.output.to_s.should_not eq ""
    end

    it "removes with account email" do
      expect(client).to receive(:list_team_members).and_return([Factory.team_member])

      action.email = "test@example.com"
      action.call.should_not be nil
      action.output.to_s.should_not eq ""
    end
  end

  it "#run unknown team member" do
    expect(client).to receive(:list_team_members).and_return([Factory.team_member])

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.email = "unknown@example.com"

    msg = /Unknown team member/
    expect(&.call).to raise_error(Program::Error, msg)
  end
end
