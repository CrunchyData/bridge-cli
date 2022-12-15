require "./action"

abstract class CB::MaintenanceAction < CB::APIAction
  cluster_identifier_setter cluster_id

  def validate
    check_required_args { |missing| missing << "cluster" if @cluster_id.empty? }
  end
end

# Action to update cluster maintenance window
class CB::MaintenanceWindowUpdate < CB::MaintenanceAction
  i32_setter window_start
  bool_setter unset

  def validate
    super

    raise Error.new "Must use '--window-start' or '--unset' but not both." if window_start && unset
    raise Error.new "'--window-start' should be between 0 and 23" if (start = window_start) && (start < 0 || start > 23)
    check_required_args { |missing| missing << "window-start" unless window_start || unset }
  end

  def run
    validate

    new_c = MaintenanceWindow.new(window_start).update_cluster(client, cluster_id[:cluster])

    output << "maintenance window updated to " << MaintenanceWindow.new(new_c.maintenance_window_start).explain << "\n"
  end
end
