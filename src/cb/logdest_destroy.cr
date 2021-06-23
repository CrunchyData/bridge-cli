require "./action"

module CB
  class LogdestDestroy < Action
    property cluster_id : String?
    property logdest_id : String?

    def call
      check_required_args do |missing|
        missing << "cluster" unless cluster_id
        missing << "logdest" unless logdest_id
      end

      client.destroy_logdest cluster_id, logdest_id
      output.puts "log destination destroyed"
    end

    def cluster_id=(str : String)
      raise_arg_error "cluster id", str unless str =~ EID_PATTERN
      @cluster_id = str
    end

    def logdest=(str : String)
      raise_arg_error "logdest id", str unless str =~ EID_PATTERN
      @logdest_id = str
    end
  end
end
