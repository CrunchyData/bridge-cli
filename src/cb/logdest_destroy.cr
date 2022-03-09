require "./action"

module CB
  class LogdestDestroy < Action
    eid_setter cluster_id
    eid_setter logdest_id

    def run
      check_required_args do |missing|
        missing << "cluster" unless cluster_id
        missing << "logdest" unless logdest_id
      end

      client.destroy_logdest cluster_id, logdest_id
      output.puts "log destination destroyed"
    end
  end
end
