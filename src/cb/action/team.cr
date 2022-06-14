require "./action"

module CB::Action
  abstract class TeamAction < APIAction
    eid_setter team_id

    private def team_details(t : CB::Client::Team) : String
      String.build do |str|
        str << "ID:           \t" << t.id.colorize.t_id << "\n"
        str << "Name:         \t" << t.name.colorize.t_name << "\n"
        str << "Role:         \t" << t.role.to_s.titleize << "\n"
        str << "Billing Email:\t" << t.billing_email << "\n"
        str << "Enforce SSO:  \t" << (t.enforce_sso.nil? ? "disabled" : t.enforce_sso)
      end
    end
  end

  class TeamCreate < TeamAction
    property name : String = ""

    def run
      check_required_args do |missing|
        missing << "name" if name.empty?
      end

      team = client.create_team name
      output << "Created team #{team}\n"
    end
  end

  class TeamList < TeamAction
    def run
      teams = client.get_teams
      name_max = teams.map(&.name.size).max? || 0

      teams.each do |team|
        output << team.id.colorize.t_id << "\t"
        output << team.name.ljust(name_max).colorize.t_name << "\t"
        output << team.role.to_s.titleize << "\n"
      end
    end
  end

  class TeamInfo < TeamAction
    def run
      team = client.get_team team_id
      output << team_details(team) << "\n"
    end
  end

  class TeamUpdate < TeamAction
    ident_setter name

    # TODO: (abrightwell) - would be really nice to have some validation on this
    # property. I briefly looked into implementing a macro for it, but it an email
    # regex is non-trivial. Need to determine what would be 'good enough' for our
    # purposes here. So I'm going to come back to this one in a future update. For
    # now, we'll rely on the API validation of the field.
    property billing_email : String?
    bool_setter? enforce_sso
    bool_setter confirmed

    def run
      check_required_args do |missing|
        missing << "team" unless team_id
      end

      unless confirmed
        t = client.get_team team_id

        output.printf "About to %s team %s.\n", "update".colorize.t_warn, t.name.colorize.t_name
        output.printf "  Type the team's name to confirm: "
        response = input.gets

        raise Error.new "Response did not match, did not update the team" unless response == t.name
      end

      team = client.update_team team_id, {
        "billing_email" => billing_email,
        "enforce_sso"   => enforce_sso,
        "name"          => name,
      }

      output << team_details(team) << "\n"
    end
  end

  class TeamDestroy < TeamAction
    bool_setter confirmed

    def run
      check_required_args do |missing|
        missing << "team" unless team_id
      end

      unless confirmed
        t = client.get_team team_id

        output.printf "About to %s team %s.\n", "delete".colorize.t_warn, t.name.colorize.t_name
        output.printf "  Type the team's name to confirm: "
        response = input.gets

        raise Error.new "Response did not match, did not delete the team." unless response == t.name
      end

      team = client.destroy_team team_id
      output << "Deleted team #{team}\n"
    end
  end
end
