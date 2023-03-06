require "./action"
require "./table"

abstract class CB::RoleAction < CB::APIAction
  eid_setter cluster_id
end

# Action to create a cluster role for the calling user.
class CB::RoleCreate < CB::RoleAction
  def validate
    check_required_args do |missing|
      missing << "cluster" unless cluster_id
    end
  end

  def run
    validate

    role = client.create_role @cluster_id
    output << "Role #{role.name} created on cluster #{@cluster_id}.\n"
  end
end

class CB::RoleList < CB::RoleAction
  format_setter format

  bool_setter? no_header

  private property cluster : CB::Model::Cluster?

  private property roles : Array(Hash(String, String)) = [] of Hash(String, String)

  private property team : CB::Model::Team?

  def validate
    check_required_args do |missing|
      missing << "cluster" unless cluster_id
    end
  end

  def run
    validate

    @cluster = client.get_cluster @cluster_id
    @team = client.get_team @cluster.try &.team_id

    r = client.list_roles @cluster_id

    r.each do |role|
      @roles << {
        "role"    => role.name,
        "account" => role.name.starts_with?("u_") ? role.account_email.to_s : "system",
      }
    end

    case @format
    when CB::Format::JSON
      output_json
    when CB::Format::Default, CB::Format::Table
      output_default
    end
  end

  def output_default
    table = Table::TableBuilder.new(border: :none) do
      columns do
        add "Role"
        add "Account"
      end

      header unless no_header

      @roles.each do |role|
        row [role["role"], role["account"]]
      end
    end

    output << table.render << '\n'
  end

  def output_json
    output << {
      "cluster": @cluster.try &.name,
      "team":    @team.try &.name,
      "roles":   @roles,
    }.to_pretty_json << '\n'
  end
end

# Action to update a cluster role.
class CB::RoleUpdate < CB::RoleAction
  role_setter? role
  bool_setter? read_only
  bool_setter? rotate_password

  def validate
    check_required_args do |missing|
      missing << "cluster" unless cluster_id
      missing << "name" unless role
    end
  end

  def run
    validate

    if @role == "user"
      @role = Role.new "u_" + client.get_account.id
    end

    flavor = read_only ? "read" : "write" unless read_only.nil?

    role = client.update_role @cluster_id, @role, {flavor: flavor, rotate_password: rotate_password}

    output << "Role #{role.name} updated on cluster #{@cluster_id}.\n"
  end
end

class CB::RoleDelete < CB::RoleAction
  role_setter? role

  def validate
    check_required_args do |missing|
      missing << "cluster" unless cluster_id
      missing << "name" unless role
    end
  end

  def run
    validate

    if @role == "user"
      @role = Role.new "u_" + client.get_account.id
    end

    role = client.delete_role @cluster_id, @role
    output << "Role #{role.name} deleted from cluster #{@cluster_id}.\n"
  end
end
