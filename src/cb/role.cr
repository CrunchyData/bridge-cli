require "./action"

module CB
  # Valid cluster role names.
  VALID_CLUSTER_ROLES = Set{"application", "default", "postgres", "user"}
end

abstract class CB::RoleAction < CB::APIAction
  eid_setter cluster_id
  property role_name : String?
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

# Action to update a cluster role.
class CB::RoleUpdate < CB::RoleAction
  bool_setter? read_only
  bool_setter? rotate_password

  def validate
    check_required_args do |missing|
      missing << "cluster" unless cluster_id
      missing << "name" unless role_name
    end
  end

  def run
    validate

    # Ensure the role name
    @role_name = "default" unless @role_name
    raise Error.new("invalid role '#{@role_name}'") unless VALID_CLUSTER_ROLES.includes? @role_name
    if @role_name == "user"
      @role_name = "u_" + client.get_account.id
    end

    flavor = read_only ? "read" : "write" unless read_only.nil?

    role = client.update_role @cluster_id, @role_name, {flavor: flavor, rotate_password: rotate_password}

    output << "Role #{role.name} updated on cluster #{@cluster_id}.\n"
  end
end

class CB::RoleDelete < CB::RoleAction
  def run
    check_required_args do |missing|
      missing << "cluster" unless cluster_id
      missing << "name" unless role_name
    end

    # Ensure the role name
    @role_name = "default" unless @role_name
    raise Error.new("invalid role '#{@role_name}'") unless VALID_CLUSTER_ROLES.includes? @role_name
    if @role_name == "user"
      @role_name = "u_" + client.get_account.id
    end

    role = client.delete_role @cluster_id, @role_name
    output << "Role #{role.name} deleted from cluster #{@cluster_id}.\n"
  end
end
