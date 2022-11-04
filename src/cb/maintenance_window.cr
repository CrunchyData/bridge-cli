struct CB::MaintenanceWindow
  getter start : Int32?

  def initialize(@start = nil)
    raise Program::Error.new("start should either be nil or between 0 and 23") if (s = start) && (s < 0 || s > 23)
  end

  def explain(now : Time? = nil)
    return "no window set. Default to: 00:00-23:59" unless valid_start = start

    now ||= Time.local
    window_start = Time.utc(now.year, now.month, now.day, valid_start, 0, 0)
    default_window_duration = Time::Span.new(hours: 3)
    window_end = window_start + default_window_duration

    maintenance_window = "#{window_start.to_s("%H:%M")} - #{window_end.to_s("%H:%M")} UTC."

    next_window = window_start - now
    if next_window.negative?
      # we are after window start
      next_window = next_window + Time::Span.new(hours: 24)
    end

    during_window = nil
    if next_window > Time::Span.new(hours: 24) - default_window_duration
      during_window = " Currently in the maintenance window."
    end

    next_in = " Next window is in #{next_window.hours} hours and #{next_window.minutes} minutes"

    "#{maintenance_window}#{during_window}#{next_in}"
  end

  def update_cluster(client, id)
    client.update_cluster id, {"maintenance_window_start" => start || -1}
  end
end
