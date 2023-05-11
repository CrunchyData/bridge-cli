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
      @starting_from = Time.utc
    end

    raise Error.new "'--starting-from' should be in less than 72 hours" if (start = @starting_from) && start > (Time.utc + Time::Span.new(hours: 72))

    raise Error.new "--ha is not valid with any other modifications such as '--storage' or '--version'" if !ha.nil? && (postgres_version || storage || starting_from)
    true
  end
end

# Action to start cluster upgrade.
class CB::UpgradeStart < CB::UpgradeAction
  def run
    validate

    c = client.get_cluster cluster_id
    confirm_action("upgrade", "cluster", c.name) unless confirmed
    if !ha.nil?
      wanted = ""
      operation = nil
      if ha
        wanted = "enabled"
        operation = client.enable_ha(Identifier.new c.id)
      else
        wanted = "disabled"
        operation = client.disable_ha(Identifier.new c.id)
      end

      case operation.try &.state
      when nil
        output.puts "  High availability already #{wanted} on cluster #{c.id.colorize.t_id}."
      when CB::Model::Operation::State::DisablingHA
        output.puts "  Disabling high availability on cluster #{c.id.colorize.t_id}."
      when CB::Model::Operation::State::EnablingHA, CB::Model::Operation::State::WaitingForHAStandby
        output.puts "  Enabling high availability on cluster #{c.id.colorize.t_id}."
      else
        output.puts "  Operation not recognized: #{operation.inspect}"
      end
    else
      client.upgrade_cluster self
      output.puts "  Cluster #{c.id.colorize.t_id} upgrade started."
    end
  end
end

# Action to create a cluster maintenance.
class CB::MaintenanceCreate < CB::UpgradeAction
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

# Action to cancel cluster maintenance.
class CB::MaintenanceCancel < CB::Upgrade
  def run
    validate

    c = client.get_cluster cluster_id
    print_team_slash_cluster c

    operations = client.upgrade_cluster_status cluster_id
    all_upgrades = operations.select { |op| op.flavor != CB::Model::Operation::Flavor::HAChange }
    maintenance = all_upgrades.find { |op| op.flavor == CB::Model::Operation::Flavor::Maintenance }
    unless maintenance
      output.puts "  there is no pending maintenance."
      if pending_upgrade = all_upgrades.first?
        output.puts "  use '#{"cb upgrade cancel".colorize.bold}' to cancel the pending #{pending_upgrade.flavor.colorize.bold}."
      end
      return
    end

    client.upgrade_cluster_cancel cluster_id
    output << "  #{maintenance.flavor.colorize.bold} operation cancelled\n"
  end
end

# Action to cancel cluster upgrade.
class CB::UpgradeCancel < CB::Upgrade
  def run
    validate

    c = client.get_cluster cluster_id
    print_team_slash_cluster c

    operations = client.upgrade_cluster_status cluster_id
    all_upgrades = operations.select { |op| op.flavor != CB::Model::Operation::Flavor::HAChange }
    operation = all_upgrades.find { |op| op.flavor != CB::Model::Operation::Flavor::Maintenance }
    unless operation
      output.puts "  there is no pending operation."
      if pending_maintenance = all_upgrades.first?
        output.puts "  use '#{"cb maintenance cancel".colorize.bold}' to cancel the pending #{pending_maintenance.flavor.colorize.bold}."
      end
      return
    end

    client.upgrade_cluster_cancel cluster_id
    output << "  #{operation.flavor.colorize.bold} operation cancelled\n"
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

abstract class CB::UpdateUpgradeAction < CB::Upgrade
  bool_setter now
  i32_setter postgres_version
  i32_setter storage
  time_setter starting_from
  bool_setter? use_cluster_maintenance_window

  property plan : String?

  def validate
    super

    if {starting_from, now, use_cluster_maintenance_window}.each.count { |x| x } > 1
      raise Error.new "Must use only one option between '--starting-from', '--now' and '--use-cluster-maintenance-window'."
    end

    if now
      @starting_from = Time.utc
    end

    raise Error.new "'--starting-from' should be in less than 72 hours" if (start = @starting_from) && start > (Time.utc + Time::Span.new(hours: 72))
    true
  end
end

# Action to update a pending cluster maintenance.
class CB::MaintenanceUpdate < CB::UpdateUpgradeAction
  def validate
    super
    raise Error.new "Maintenance can't change plan, postgres_version or storage." if postgres_version || storage || plan
    true
  end

  def run
    validate

    c = client.get_cluster cluster_id
    print_team_slash_cluster c

    operations = client.upgrade_cluster_status cluster_id
    all_upgrades = operations.select { |op| op.flavor != CB::Model::Operation::Flavor::HAChange }
    maintenance = all_upgrades.find { |op| op.flavor == CB::Model::Operation::Flavor::Maintenance }
    unless maintenance
      output.puts "  there is no pending maintenance."
      if pending_upgrade = all_upgrades.first?
        output.puts "  use '#{"cb upgrade update".colorize.bold}' to update the pending #{pending_upgrade.flavor.colorize.bold}."
      end
      return
    end

    confirm_action("update pending maintenance", "cluster", c.name) unless confirmed

    client.update_upgrade_cluster self
    output.puts "  maintenance updated."
  end
end

# Action to update a pending cluster upgrade.
class CB::UpgradeUpdate < CB::UpdateUpgradeAction
  def run
    validate

    c = client.get_cluster cluster_id
    print_team_slash_cluster c

    operations = client.upgrade_cluster_status cluster_id
    all_upgrades = operations.select { |op| op.flavor != CB::Model::Operation::Flavor::HAChange }
    operation = all_upgrades.find { |op| op.flavor != CB::Model::Operation::Flavor::Maintenance }
    unless operation
      output.puts "  there is no pending upgrade."
      if pending_maintenance = all_upgrades.first?
        output.puts "  use '#{"cb maintenance update".colorize.bold}' to update the pending #{pending_maintenance.flavor.colorize.bold}."
      end
      return
    end

    confirm_action("update pending upgrade", "cluster", c.name) unless confirmed

    client.update_upgrade_cluster self
    output.puts "  upgrade updated."
  end
end
