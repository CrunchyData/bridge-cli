require "./action"

module CB
  class LogdestAdd < Action
    eid_setter cluster_id
    i32_setter port
    property host : String?
    property template : String?
    property desc : String?

    def run
      validate
      logdest = client.add_logdest self
      output.puts "added new log destination"
    end

    def validate
      check_required_args do |missing|
        missing << "cluster" unless cluster_id
        missing << "port" unless port
        missing << "desc" unless desc
        missing << "host" unless host
        missing << "template" unless template
      end
    end

    def port=(i : Int32)
      raise_arg_error "port", i unless 1 <= i < 65_535
      @port = i
    end

    def host=(str : String)
      unless @desc
        @desc = str.split('.').last(2).first
      end
      @host = str
    end
  end
end
