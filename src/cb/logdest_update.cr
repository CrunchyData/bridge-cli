require "./action"

module CB
  class LogDestinationUpdate < APIAction
    eid_setter cluster_id
    eid_setter logdest_id
    i32_setter port
    property host : String?
    property template : String?
    property description : String?
    bool_setter? tls_verify_disabled
    bool_setter? forward_connection_logs

    def run
      validate
      cid = cluster_id
      lid = logdest_id
      raise Error.new "Missing required arguments: cluster, logdest" if cid.nil? || lid.nil?

      existing = client.get_log_destinations(cid).find { |d| d.id == lid }
      unless existing
        raise Program::Error.new "log destination #{lid.colorize.t_id} was not found for this cluster."
      end

      client.update_log_destination(cid, lid, update_body(existing))

      output << "updated log destination "
      output << "#{logdest_id}".colorize.t_id << " for "
      output << "#{cluster_id}".colorize.t_id << '\n'
    end

    def validate
      check_required_args do |missing|
        missing << "cluster" unless cluster_id
        missing << "logdest" unless logdest_id
      end
    end

    private def merged_bool(override : Bool?, existing : Bool) : Bool
      override.nil? ? existing : override
    end

    private def update_body(existing : CB::Model::LogDestination) : Hash(String, String | Int32 | Bool)
      eff_host = host || existing.host
      eff_port = port || existing.port
      eff_template = template || existing.template
      eff_description = description || existing.description

      body = {} of String => String | Int32 | Bool
      body["host"] = eff_host
      body["port"] = eff_port
      body["template"] = eff_template
      body["description"] = eff_description
      body["tls_verify_disabled"] = merged_bool(tls_verify_disabled, existing.tls_verify_disabled)
      body["forward_connection_logs"] = merged_bool(forward_connection_logs, existing.forward_connection_logs)
      body
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
