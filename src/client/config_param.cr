require "./client"

module CB
  class Client
    # Get configuration parameter value
    def get_configuration_parameter(id : Identifier, name : String)
      resp = get "clusters/#{id}/configuration-parameters/#{name}"
      Model::ConfigurationParameter.from_json resp.body
    end

    # List configuration parameter values.
    def list_configuration_parameters(id : Identifier)
      resp = get "clusters/#{id}/configuration-parameters"
      Array(Model::ConfigurationParameter).from_json resp.body, root: "parameters"
    end

    # List support configuration parameters
    def list_supported_configuration_parameters
      resp = get "configuration-parameters"
      Array(Model::ConfigurationParameter).from_json resp.body, root: "parameters"
    end

    # Update configuration parameter values.
    def update_configuration_parameters(id, parameters, allow_restart : Bool = false)
      resp = put "clusters/#{id}/configuration-parameters", {"parameters": parameters, "allow_restart": allow_restart}
      Array(Model::ConfigurationParameter).from_json resp.body, root: "parameters"
    end
  end
end
