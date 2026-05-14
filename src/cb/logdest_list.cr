require "./action"

module CB
  class LogDestinationList < APIAction
    eid_setter cluster_id

    def run
      check_required_args { |missing| missing << "cluster" unless cluster_id }
      dests = client.get_log_destinations cluster_id

      output.tty? ? display_tty(dests) : display_pipe(dests)
    end

    def display_tty(dests)
      if dests.empty?
        output.puts "no log destinations"
        return
      end

      dests.each do |d|
        output.puts d.id.colorize.t_id
        output << "  " << d.description.colorize.t_name
        output << " (" << d.host << ":" << d.port << ")\n"
        output << "  " << d.template << "\n"
        output << "  " << "TLS verify disabled: " << yes_no(d.tls_verify_disabled) << "\n"
        output << "  " << "Forward connection logs: " << yes_no(d.forward_connection_logs) << "\n"
      end
    end

    def display_pipe(dests)
      dests.each do |d|
        output << d.id << "\t"
        output << d.description << "\t"
        output << d.host << "\t"
        output << d.port << "\t"
        output << d.template << "\t"
        output << d.tls_verify_disabled << "\t"
        output << d.forward_connection_logs << "\n"
      end
    end

    private def yes_no(value : Bool) : String
      value ? "yes" : "no"
    end
  end
end
