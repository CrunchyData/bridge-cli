require "./action"

module CB
  TEAM_ROLE_MEMBER  = "member"
  TEAM_ROLE_MANAGER = "manager"
  TEAM_ROLE_ADMIN   = "admin"

  # Valid team member roles.
  VALID_TEAM_ROLES = Set{
    TEAM_ROLE_ADMIN,
    TEAM_ROLE_MANAGER,
    TEAM_ROLE_MEMBER,
  }
end

# Superclass for all TeamMember related `Action`s}.
#
# Provides common properties and functionality specific to team member managment
# actions.
abstract class CB::TeamMemberAction < CB::Action
  eid_setter team_id
  eid_setter account_id
  property email : String?

  private def validate_account_email
    check_required_args do |missing|
      missing << "team" unless team_id
      missing << "account" unless account_id || email
    end

    raise Error.new "Must only use '--account' or '--email' but not both." if account_id && email
  end

  private def get_member_by_email(team_id, email)
    members = client.list_team_members(team_id)
    members.find { |tm| tm.email == email }
  end

  private def team_member_details(tm : CB::Client::TeamMember) : String
    String.build do |str|
      str << "Email:     \t" << tm.email.colorize.t_name << '\n'
      str << "Team ID:   \t" << tm.team_id.colorize.t_id << '\n'
      str << "Account ID:\t" << tm.account_id.colorize.t_id << '\n'
      str << "Role:      \t" << tm.role.titleize
    end
  end
end

# Action to add an account to a team as a member.
class CB::TeamMemberAdd < CB::TeamMemberAction
  property role : String = TEAM_ROLE_MEMBER

  def validate
    valid = check_required_args do |missing|
      missing << "team" unless team_id
      missing << "email" unless email
      missing << "role" if role.empty?
    end

    raise Error.new("invalid role '#{@role}'") unless VALID_TEAM_ROLES.includes? @role

    return valid
  end

  def run
    validate

    team_member = client.create_team_member(
      @team_id,
      Client::TeamMemberCreateParams.new(email.to_s, role),
    )

    output << "Added " << team_member.email.colorize.green
    output << " to team " << team_member.team_id.colorize.t_id
    output << " as role '" << team_member.role.colorize.t_name
    output << "'.\n"
  end
end

# Action to list the current members of a team.
class CB::TeamMemberList < CB::TeamMemberAction
  def validate
    check_required_args do |missing|
      missing << "team" unless team_id
    end
  end

  def run
    validate

    team_members = client.list_team_members(team_id)
    email_max = team_members.map(&.email.size).max? || 0

    # Only personal teams can be without members. So, it should be safe to
    # assume that if the request returns an empty list that it is 'personal'
    # team.  However, not wanting umptions to shoulder this one alone in the
    # case that we are wrong, we'll just simply respond that the requested team
    # doesn't have any members. Making no claims to it being personal or
    # otherwise.  Which should be good enough in all cases, however unlikely
    # they might be.
    unless team_members.empty?
      team_members.each do |member|
        output << member.account_id.colorize.t_id << '\t'
        output << member.email.ljust(email_max).colorize.t_name << '\t'
        output << member.role.titleize << '\n'
      end
    else
      output << "Team #{team_id.colorize.t_id} has no team members.\n"
    end
  end
end

# Action to show information detail about a specific team member.
#
# Allows for both account ID and email of the team member to be provided,
# however, the account ID will take precedence over the email. Therefore, if
# supplying both will raise a validation error.
class CB::TeamMemberInfo < CB::TeamMemberAction
  def run
    validate_account_email

    unless @account_id.nil?
      tm = client.get_team_member(team_id, @account_id)
    else
      tm = get_member_by_email(team_id, email)
    end

    unless tm.nil?
      output << team_member_details(tm) << '\n'
    else
      # TODO (abrightwell): move this to an error above, similar to update.
      output << "Unknown team member.\n"
    end
  end
end

# Action to update a team member.
#
# Allows for both account ID and email of the team member to be provided,
# however, the account ID will take precedence over the email. Therefore, if
# supplying both will raise a validation error.
class CB::TeamMemberUpdate < CB::TeamMemberAction
  setter role : String?

  def run
    validate_account_email

    unless @role.nil?
      raise Error.new("invalid role '#{@role.to_s}'") unless VALID_TEAM_ROLES.includes? @role
    end

    if account_id.nil?
      tm = get_member_by_email(team_id, @email) if account_id.nil?
      raise Error.new "Unknown team member '#{@email}'." if tm.nil?
      @account_id = tm.account_id
    end

    updated = client.update_team_member(team_id, @account_id, @role)
    output << team_member_details(updated) << '\n' unless updated.nil?
  end
end

# Action to remove a user as member from a team.
#
# Allows for both account ID and email of the team member to be provided,
# however, the account ID will take precedence over the email. Therefore, if
# supplying both will raise a validation error.
class CB::TeamMemberRemove < CB::TeamMemberAction
  def run
    validate_account_email

    if account_id.nil?
      tm = get_member_by_email(team_id, @email) if account_id.nil?
      raise Error.new "Unknown team member '#{@email}'." if tm.nil?
      @account_id = tm.account_id
    end

    removed = client.remove_team_member(team_id, account_id)
    team = client.get_team(team_id)
    output << "Removed #{removed.email.colorize.t_name} from team #{team.to_s}.\n" unless removed.nil?
  end
end
