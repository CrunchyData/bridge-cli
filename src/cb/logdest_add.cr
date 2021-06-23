require "./action"

module CB
  class LogdestAdd < Action
    property cluster_id : String?
    property host : String?
    property port : Int32?
    property template : String?
    property desc : String?

    def call
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

    def cluster_id=(str : String)
      raise_arg_error "cluster id", str unless str =~ EID_PATTERN
      @cluster_id = str
    end

    def port=(str : String)
      i = str.to_i_cb
      self.port = i
    rescue ArgumentError
      raise_arg_error "port", str
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
