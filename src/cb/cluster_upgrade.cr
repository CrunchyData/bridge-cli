require "./action"

abstract class CB::Upgrade < CB::Action
  property cluster_id : String?
  property confirmed : Bool = false

  abstract def run

  def validate
    check_required_args do |missing|
      missing << "cluster" unless cluster_id
    end
  end

  def cluster_id=(str : String)
    raise_arg_error "cluster id", str unless str =~ EID_PATTERN
    @cluster_id = str
  end
end

# Action to start cluster upgrade.
class CB::UpgradeStart < CB::Upgrade
  property ha : Bool?
  property postgres_version : Int32?
  property storage : Int32?
  property plan : String?

  def run
    validate

    c = client.get_cluster cluster_id

    unless confirmed
      output << "About to " << "upgrade".colorize.t_warn << " cluster " << c.name.colorize.t_name
      output << ".\n  Type the cluster's name to confirm: "
      response = input.gets

      if c.name == response
        confirmed = true
      else
        raise Error.new "Response did not match, did not upgrade the cluster"
      end
    end

    client.upgrade_cluster self
    output.puts "  Cluster #{c.id.colorize.t_id} upgrade started."
  end

  def ha=(str : String)
    case str.downcase
    when "true"
      self.ha = true
    when "false"
      self.ha = false
    else
      raise_arg_error "ha", str
    end
  end

  def postgres_version=(str : String)
    self.postgres_version = str.to_i_cb
  rescue ArgumentError
    raise_arg_error "postgres_version", str
  end

  def storage=(str : String)
    self.storage = str.to_i_cb
  rescue ArgumentError
    raise_arg_error "storage", str
  end
end

# Action to cancel cluster upgrade.
class CB::UpgradeCancel < CB::Upgrade
  def run
    c = client.get_cluster cluster_id
    print_team_slash_cluster c, output

    client.upgrade_cluster_cancel cluster_id
    output << "  upgrade cancelled\n".colorize.bold
  end
end

# Action to get the cluster upgrade status.
class CB::UpgradeStatus < CB::Upgrade
  def run
    c = client.get_cluster cluster_id
    print_team_slash_cluster c, output

    operations = client.upgrade_cluster_status cluster_id

    if operations.empty?
      output << "  no upgrades in progress\n".colorize.bold
    else
      pad = (operations.map(&.flavor.size).max || 8) + 2
      operations.each do |op|
        output << op.flavor.rjust(pad).colorize.bold << ": "
        output << op.state << "\n"
      end
    end
  end
end
