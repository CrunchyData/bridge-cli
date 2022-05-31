require "./action"

module CB
  class LogDestinationList < Action
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
      end
    end

    def display_pipe(dests)
      dests.each do |d|
        output << d.id << "\t"
        output << d.description << "\t"
        output << d.host << "\t"
        output << d.port << "\t"
        output << d.template << "\n"
      end
    end
  end
end
