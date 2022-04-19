require "../spec_helper"

private class TeamMemberTestClient < CB::Client
  MEMBERS = [
    CB::Client::TeamMember.new(
      id: "abc",
      team_id: "pkdpq6yynjgjbps4otxd7il2u4",
      account_id: "4pfqoxothfagnfdryk2og7noei",
      role: "member",
      email: "test@example.com",
    ),
  ]

  def get_team(team_id)
    Team.new(
      id: "pkdpq6yynjgjbps4otxd7il2u4",
      name: "Test Team",
      is_personal: false,
      role: nil,
      billing_email: nil,
      enforce_sso: nil,
    )
  end

  def create_team_member(team_id, params : TeamMemberCreateParams)
    TeamMember.new(
      id: "",
      team_id: team_id.to_s,
      account_id: "abc123",
      role: params.role,
      email: params.email,
    )
  end

  def get_team_member(team_id, account_id)
    MEMBERS[0]
  end

  def list_team_members(team_id)
    MEMBERS
  end

  def update_team_member(team_id, account_id, role)
    MEMBERS[0]
  end

  def remove_team_member(team_id, account_id)
    MEMBERS[0]
  end
end

describe CB::TeamMemberAdd do
  it "validates that required arguments are present" do
    action = CB::TeamMemberAdd.new(TeamMemberTestClient.new(TEST_TOKEN))

    msg = /Missing required argument/
    expect_cb_error(msg) { action.validate }

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.email = "test@example.com"
    action.validate.should eq true

    action.role = "some role"
    msg = /invalid role '#{action.role}'/
    expect_cb_error(msg) { action.validate }
  end

  it "#run prints confirmation" do
    action = CB::TeamMemberAdd.new(TeamMemberTestClient.new(TEST_TOKEN))
    action.output = output = IO::Memory.new

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.email = "test@example.com"

    action.call

    output.to_s.should eq "Added #{action.email} to team #{action.team_id} as role 'member'.\n"
  end
end

describe CB::TeamMemberInfo do
  it "validates that required arguments are present" do
    action = CB::TeamMemberInfo.new(TeamMemberTestClient.new(TEST_TOKEN))

    msg = /Missing required argument/
    expect_cb_error(msg) { action.call }
  end

  it "#run prints unknown member" do
    action = CB::TeamMemberInfo.new(TeamMemberTestClient.new(TEST_TOKEN))
    action.output = output = IO::Memory.new

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.email = "unknown@example.com"

    action.call

    expected = "Unknown team member.\n"
    output.to_s.should eq expected
  end
end

describe CB::TeamMemberList do
  it "validates that required arguments are present" do
    action = CB::TeamMemberList.new(TeamMemberTestClient.new(TEST_TOKEN))

    msg = /Missing required argument/
    expect_cb_error(msg) { action.call }
  end

  it "#run" do
    action = CB::TeamMemberList.new(TeamMemberTestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.call.should be nil
    action.output.to_s.should_not eq ""
  end
end

describe CB::TeamMemberUpdate do
  it "validates that required arguments are present" do
    action = CB::TeamMemberUpdate.new(TeamMemberTestClient.new(TEST_TOKEN))

    msg = /Missing required argument/
    expect_cb_error(msg) { action.call }
  end

  it "validates argument conflicts" do
    action = CB::TeamMemberUpdate.new(TeamMemberTestClient.new(TEST_TOKEN))

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.account_id = "4pfqoxothfagnfdryk2og7noei"
    action.email = "test@example.com"

    msg = /Must only use '--account' or '--email' but not both./
    expect_cb_error(msg) { action.call }
  end

  it "#run" do
    action = CB::TeamMemberUpdate.new(TeamMemberTestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    # TODO (abrightwell): There's got to be a better way to test the output. For
    # instance, more intelligently checking the value of the content, instead of
    # just doing a simple string comparison. Perhaps revisiting this at some
    # point would be appropriate?
    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.account_id = "4pfqoxothfagnfdryk2og7noei"
    action.call.should_not be nil
    action.output.to_s.should_not eq ""

    action = CB::TeamMemberUpdate.new(TeamMemberTestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.email = "test@example.com"
    action.call.should_not be nil
    action.output.to_s.should_not eq ""
  end

  it "#run unknown team member" do
    action = CB::TeamMemberUpdate.new(TeamMemberTestClient.new(TEST_TOKEN))

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.email = "unknown@example.com"

    msg = /Unknown team member/
    expect_cb_error(msg) { action.call }
  end
end

describe CB::TeamMemberRemove do
  it "validates that required arguments are present" do
    action = CB::TeamMemberRemove.new(TeamMemberTestClient.new(TEST_TOKEN))

    msg = /Missing required argument/
    expect_cb_error(msg) { action.call }
  end

  it "validates argument conflicts" do
    action = CB::TeamMemberRemove.new(TeamMemberTestClient.new(TEST_TOKEN))

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.account_id = "4pfqoxothfagnfdryk2og7noei"
    action.email = "test@example.com"

    msg = /Must only use '--account' or '--email' but not both./
    expect_cb_error(msg) { action.call }
  end

  it "#run" do
    action = CB::TeamMemberRemove.new(TeamMemberTestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.account_id = "4pfqoxothfagnfdryk2og7noei"
    action.call.should_not be nil
    action.output.to_s.should_not eq ""

    action = CB::TeamMemberRemove.new(TeamMemberTestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.email = "test@example.com"
    action.call.should_not be nil
    action.output.to_s.should_not eq ""
  end

  it "#run unknown team member" do
    action = CB::TeamMemberRemove.new(TeamMemberTestClient.new(TEST_TOKEN))

    action.team_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.email = "unknown@example.com"

    msg = /Unknown team member/
    expect_cb_error(msg) { action.call }
  end
end
