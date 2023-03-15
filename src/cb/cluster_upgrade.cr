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
end

abstract class CB::UpgradeAction < CB::Upgrade
  bool_setter? ha
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

# Action to create a cluster maintenance.
class CB::UpgradeMaintenanceCreate < CB::UpgradeAction
  def validate
    super
    raise Error.new "Maintenance can't change ha, postgres_version or storage." if !ha.nil? || postgres_version || storage || plan
    true
  end

  def run
    validate

    c = client.get_cluster cluster_id
    confirm_action("create maintenance", "cluster", c.name) unless confirmed

    client.upgrade_cluster self
    output.puts "  Maintenance created for Cluster #{c.id.colorize.t_id}."
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

    if maintenance_only
      operations = operations.select { |op| op.flavor != CB::Model::Operation::Flavor::HAChange }
    end

    output_default(operations, c.maintenance_window_start)
  end

  def output_default(operations, maintenance_window)
    table = Table::TableBuilder.new(border: :none) do
      if !operations.empty?
        operations.each do |op|
          from = " (Starting from: #{op.starting_from})" if op.starting_from
          row ["#{op.flavor.colorize.bold}:", "#{op.state}#{from}"]
        end
      else
        row ["operations:", "no operations in progress".colorize.bold]
      end

      row ["maintenance window:", MaintenanceWindow.new(maintenance_window).explain]
    end

    output << table.render << '\n'
  end
end
