require "./action"

module CB
  # API action for configuration parameters.
  #
  # All configuration parameter actions must inherit this action.
  abstract class ConfigurationParameterAction < APIAction
    # The cluster ID.
    cluster_identifier_setter cluster_id

    # The output format. The default format is table format.
    format_setter format

    # Flag to indicate whether the output should include a header. This only
    # has an effect when the output format is a table.
    property with_header : Bool = true

    # Result of api calls.
    property parameters : Array(Client::ConfigurationParameter) = [] of Client::ConfigurationParameter

    def validate
      check_required_args do |missing|
        missing << "cluster" if @cluster_id.empty?
      end
    end

    def run
      validate
    end

    protected def output_default
      table = Table::TableBuilder.new(border: :none) do
        columns do
          add "Component"
          add "Name"
          add "Value"
        end

        header if with_header

        @parameters.each do |p|
          row [p.component, p.parameter_name, p.value]
        end
      end

      output << table.render << '\n'
    end

    protected def output_json
      output << {
        "parameters": @parameters,
      }.to_pretty_json << '\n'
    end
  end

  # Action for getting configuration parameters.
  class ConfigurationParameterGet < ConfigurationParameterAction
    # The name of the configuration parameter to get.
    property name : String? = nil

    def run
      super

      if @name
        @parameters = [client.get_configuration_parameter(cluster_id[:cluster], @name.as(String))]
      else
        @parameters = client.get_all_configuration_parameters cluster_id[:cluster]
      end

      case @format
      when Format::Default
        output_default
      when Format::JSON
        output_json
      end
    end
  end

  # Action for setting configuration parameters.
  class ConfigurationParameterSet < ConfigurationParameterAction
    # The list of configuration parameters to set and their values.
    property args : Array(String) = [] of String

    def run
      super

      parameters : Array(Hash(String, String)) = [] of Hash(String, String)

      @args.each do |arg|
        parts = arg.split('=')
        parameters << {"name" => parts[0], "value" => parts[1]}
      end

      @parameters = client.set_configuration_parameters(cluster_id[:cluster], parameters)

      case @format
      when Format::Default
        output_default
      when Format::JSON
        output_json
      end
    end
  end

  # Action for resetting configuration parameters.
  class ConfigurationParameterReset < ConfigurationParameterAction
    # The name of the parameter to reset.
    property name : String? = nil

    def run
      super

      if @name
        @parameters = [client.reset_configuration_parameter(cluster_id[:cluster], @name.as(String))]
      else
        @parameters = client.reset_all_configuration_parameters cluster_id[:cluster]
      end

      case @format
      when Format::Default
        output_default
      when Format::JSON
        output_json
      end
    end
  end
end
