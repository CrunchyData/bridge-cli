require "./action"

abstract class CB::Upgrade < CB::APIAction
  eid_setter cluster_id
  property confirmed : Bool = false

  abstract def run

  def validate
    check_required_args do |missing|
      missing << "cluster" unless cluster_id
    end
  end

  def display_operations(c_id, operations, maintenance_only : Bool)
    details = {
      "maintenance window" => MaintenanceWindow.new(c_id.maintenance_window_start).explain,
    }

    operation_kind = "operations"
    if maintenance_only
      operation_kind = "maintenance operations"
      operations = operations.select { |op| op.flavor != "ha_change" }
    end

    operations.each do |op|
      details[op.flavor] = op.one_line_state_display
    end

    if operations.empty?
      output << "  no #{operation_kind} in progress\n".colorize.bold
    end

    pad = (details.keys.map(&.size).max || 8) + 2
    details.each do |k, v|
      output << k.rjust(pad).colorize.bold << ": "
      output << v << '\n'
    end
  end
end

abstract class CB::UpgradeAction < CB::Upgrade
  bool_setter ha
  i32_setter postgres_version
  i32_setter storage
  time_setter starting_from
  bool_setter now

  property plan : String?

  def validate
    super

    raise Error.new "Must use '--starting-from' or '--now' but not both." if starting_from && now

    if now
      starting_from = Time.utc
    end

    raise Error.new "'--starting-from' should be in less than a week" if (start = starting_from) && start > (Time.utc + Time::Span.new(days: 7))
    true
  end
end

# Action to start cluster upgrade.
class CB::UpgradeStart < CB::UpgradeAction
  def run
    validate

    c = client.get_cluster cluster_id
    confirm_action("upgrade", "cluster", c.name) unless confirmed

    client.upgrade_cluster self
    output.puts "  Cluster #{c.id.colorize.t_id} upgrade started."
  end
end

# Action to cancel cluster upgrade.
class CB::UpgradeCancel < CB::Upgrade
  def run
    validate

    c = client.get_cluster cluster_id
    print_team_slash_cluster c

    client.upgrade_cluster_cancel cluster_id
    output << "  operation cancelled\n".colorize.bold
  end
end

# Action to get the cluster upgrade status.
class CB::UpgradeStatus < CB::Upgrade
  property maintenance_only : Bool = false

  def run
    validate

    c = client.get_cluster cluster_id
    print_team_slash_cluster c

    operations = client.upgrade_cluster_status cluster_id
    display_operations(c, operations, maintenance_only)
  end
end
