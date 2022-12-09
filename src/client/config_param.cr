require "./client"

module CB
  class Client
    jrecord ConfigurationParameter,
      component : String? = nil,
      name : String = "",
      parameter_name : String? = nil,
      value : String = "" do
      @[JSON::Field(key: "parameter_name", emit_null: false)]
      def to_s(io : IO)
        io << name.colorize.t_name << '=' << value
      end
    end

    # Get configuration parameter value
    def get_configuration_parameter(id : Identifier, name : String)
      resp = get "/clusters/#{id}/configuration-parameters/#{name}"
      ConfigurationParameter.from_json resp.body
    end

    # Get configuration parameter values.
    def get_all_configuration_parameters(id : Identifier)
      resp = get "/clusters/#{id}/configuration-parameters"
      Array(ConfigurationParameter).from_json resp.body, root: "parameters"
    end

    # Set configuration parameter values.
    def set_configuration_parameters(id, parameters)
      resp = put "/clusters/#{id}/configuration-parameters", {"parameters": parameters}
      Array(ConfigurationParameter).from_json resp.body, root: "parameters"
    end

    # Reset configuration parameter value.
    def reset_configuration_parameter(id, name)
      resp = delete "/clusters/#{id}/configuration-parameters/#{name}"
      ConfigurationParameter.from_json resp.body
    end

    # Reset configuration parameters values.
    def reset_all_configuration_parameters(id)
      resp = delete "/clusters/#{id}/configuration-parameters"
      Array(ConfigurationParameter).from_json resp.body, root: "parameters"
    end
  end
end
