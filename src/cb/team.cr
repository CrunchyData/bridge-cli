require "./action"

abstract class CB::TeamAction < CB::APIAction
  eid_setter team_id

  format_setter format

  bool_setter show_header, true

  private def output_json(team : CB::Client::Team)
    output << team.to_pretty_json << '\n'
  end

  private def output_json(teams : Array(CB::Client::Team))
    output << {
      "teams": teams,
    }.to_pretty_json << '\n'
  end

  private def output_list(team : CB::Client::Team)
    table = Table::TableBuilder.new(border: :none) do
      row ["ID:", team.id.colorize.t_id]
      row ["Name:", team.name.colorize.t_name]
      row ["Role:", team.role.to_s.titleize]
      row ["Billing Email:", team.billing_email]
      row ["Enforce SSO:", team.enforce_sso]
    end

    output << table.render << '\n'
  end

  private def output_table(team : CB::Client::Team)
    output_table [team]
  end

  private def output_table(teams : Array(CB::Client::Team))
    table = Table::TableBuilder.new(border: :none) do
      columns(header: show_header) do
        add "ID"
        add "Name"
        add "Role"
        add "Billing Email"
        add "Enforce SSO"
      end

      teams.each do |team|
        row [
          team.id.colorize.t_id,
          team.name.colorize.t_name,
          team.role.to_s.titleize,
          team.billing_email,
          team.enforce_sso,
        ]
      end
    end

    output << table.render << '\n'
  end
end

class CB::TeamCreate < CB::TeamAction
  name_setter name

  def validate
    check_required_args do |missing|
      missing << "name" if name.empty?
    end
  end

  def run
    validate

    team = client.create_team name

    case @format
    when Format::Default
      output << "Created team #{team}\n"
    when Format::JSON
      output_json team
    else
      raise_invalid_format @format
    end
  end
end

class CB::TeamList < CB::TeamAction
  def run
    teams = client.get_teams

    case @format
    when Format::Default, Format::Table
      output_table teams
    when Format::JSON
      output_json teams
    else
      raise_invalid_format @format
    end
  end
end

class CB::TeamInfo < CB::TeamAction
  def validate
  end

  def run
    validate

    team = client.get_team team_id

    case @format
    when Format::Default, Format::List
      output_list team
    when Format::JSON
      output_json team
    when Format::Table
      output_json team
    else
      raise_invalid_format @format
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

  def validate
    check_required_args do |missing|
      missing << "team" unless team_id
    end
  end

  def run
    unless confirmed
      t = client.get_team team_id
      confirm_action("update", "team", t.name)
    end

    team = client.update_team team_id, {
      "billing_email" => billing_email,
      "enforce_sso"   => enforce_sso,
      "name"          => name,
    }

    case @format
    when Format::Default, Format::List
      output_list team
    when Format::JSON
      output_json team
    when Format::Table
      output_table team
    else
      raise_invalid_format @format
    end
  end
end

class CB::TeamDestroy < CB::TeamAction
  bool_setter confirmed

  def validate
    check_required_args do |missing|
      missing << "team" unless team_id
    end
  end

  def run
    validate

    unless confirmed
      t = client.get_team team_id
      confirm_action("destroy", "team", t.name)
    end

    team = client.destroy_team team_id

    case @format
    when Format::Default
      output << "Deleted team #{team}\n"
    else
      raise_invalid_format @format
    end
  end
end
