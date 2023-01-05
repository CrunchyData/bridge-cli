require "./action"

abstract class CB::TeamAction < CB::APIAction
  eid_setter team_id

  format_setter format

  private def output_team_details(t : CB::Client::Team)
    table = Table::TableBuilder.new(border: :none) do
      row ["ID:", t.id.colorize.t_id]
      row ["Name:", t.name.colorize.t_name]
      row ["Role:", t.role.to_s.titleize]
      row ["Billing Email:", t.billing_email]
      row ["Enforce SSO:", (t.enforce_sso.nil? ? "disabled" : t.enforce_sso)]
    end

    output << table.render << '\n'
  end
end

class CB::TeamCreate < CB::TeamAction
  name_setter name

  def run
    check_required_args do |missing|
      missing << "name" if name.empty?
    end

    team = client.create_team name
    output << "Created team #{team}\n"
  end
end

class CB::TeamList < CB::TeamAction
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

class CB::TeamInfo < CB::TeamAction
  def run
    team = client.get_team team_id

    case @format
    when Format::Default, Format::List
      output_team_details(team)
    end
  end
end

class CB::TeamUpdate < CB::TeamAction
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
      confirm_action("update", "team", t.name)
    end

    team = client.update_team team_id, {
      "billing_email" => billing_email,
      "enforce_sso"   => enforce_sso,
      "name"          => name,
    }

    output_team_details(team)
  end
end

class CB::TeamDestroy < CB::TeamAction
  bool_setter confirmed

  def run
    check_required_args do |missing|
      missing << "team" unless team_id
    end

    unless confirmed
      t = client.get_team team_id
      confirm_action("destroy", "team", t.name)
    end

    team = client.destroy_team team_id
    output << "Deleted team #{team}\n"
  end
end
