require "./action"

module CB
  class LogDestinationAdd < APIAction
    eid_setter cluster_id
    i32_setter port
    property host : String?
    property template : String?
    property description : String?
    bool_setter tls_verify_disabled
    bool_setter forward_connection_logs

    def run
      validate
      client.add_log_destination(cluster_id, {
        "host":                      host,
        "port":                      port,
        "template":                  template,
        "description":               description,
        "tls_verify_disabled":       tls_verify_disabled,
        "forward_connection_logs":   forward_connection_logs,
      })

      output << "added new log destination for "
      output << "#{cluster_id}".colorize.t_id << '\n'
    end

    def validate
      check_required_args do |missing|
        missing << "cluster" unless cluster_id
        missing << "port" unless port
        missing << "desc" unless description
        missing << "host" unless host
        missing << "template" unless template
      end
    end

    def port=(i : Int32)
      raise_arg_error "port", i unless 1 <= i < 65_535
      @port = i
    end

    def host=(str : String)
      unless @description
        @description = str.split('.').last(2).first
      end
      @host = str
    end
  end
end
