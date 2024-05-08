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
    property no_header : Bool = false

    # List of configuration parameter argments for the action.
    property args : Array(String) = [] of String

    def validate
      check_required_args do |missing|
        missing << "cluster" if @cluster_id.empty?
      end
    end

    def run
      validate
    end

    protected def display(parameters : Array(Model::ConfigurationParameter))
      case @format
      when Format::Default
        output_default(parameters)
      when Format::JSON
        output_json(parameters)
      end
    end

    protected def output_default(parameters : Array(Model::ConfigurationParameter))
      table = Table::TableBuilder.new(border: :none) do
        columns do
          add "Component"
          add "Name"
          add "Value"
        end

        header unless no_header

        rows parameters.map { |p| [p.component, p.parameter_name, p.value_str] }
      end

      output << table.render << '\n'
    end

    protected def output_json(parameters : Array(Model::ConfigurationParameter))
      output << {
        "parameters": parameters,
      }.to_pretty_json << '\n'
    end
  end

  # Action for getting configuration parameters.
  class ConfigurationParameterGet < ConfigurationParameterAction
    def validate
      raise Error.new "Too many arguments provided. Ensure that only one configuration parameter is given or none." unless @args.size <= 1
      super
    end

    def run
      validate

      if @args.empty?
        parameters = client.list_configuration_parameters(cluster_id[:cluster])
      else
        name = @args.try &.first
        parameters = [client.get_configuration_parameter(cluster_id[:cluster], name)]
      end

      display(parameters)
    end
  end

  class ConfigurationParameterListSupported < ConfigurationParameterAction
    def run
      parameters = client.list_supported_configuration_parameters
      parameters = parameters.select { |p| @args.includes? p.component.to_s } unless args.empty?

      case @format
      when Format::Default, Format::Table
        table = Table::TableBuilder.new(border: :none) do
          columns do
            add "Component"
            add "Name"
            add "Requires Restart"
          end

          header unless no_header

          rows parameters.map { |p| [p.component, p.parameter_name, p.requires_restart ? "yes" : "no"] }
        end

        output << table.render << '\n'
      when Format::JSON
        output << {
          "parameters": parameters.map do |p|
            {
              "component":       p.component,
              "name":            p.name,
              "parameter_name":  p.parameter_name,
              "require_restart": p.requires_restart,
            }
          end,
        }.to_pretty_json
      else
        raise Error.new("Format '#{@format}' is not supported for this command.")
      end
    end
  end

  # Action for setting configuration parameters.
  class ConfigurationParameterSet < ConfigurationParameterAction
    bool_setter allow_restart

    def run
      super

      updated_parameters = @args.map do |arg|
        parts = arg.split(separator: '=', limit: 2)
        {"name" => parts[0], "value" => parts[1]}
      rescue IndexError
        raise Error.new("Invalid argument: #{arg}). Make sure that it has the following format <component>:<name>=<value>.")
      end

      begin
        parameters = client.update_configuration_parameters(
          cluster_id[:cluster],
          parameters: updated_parameters,
          allow_restart: @allow_restart
        )
      rescue e : CB::Client::Error
        raise Error.new(e.message)
      end

      display(parameters)
    end
  end

  # Action for resetting configuration parameters.
  class ConfigurationParameterReset < ConfigurationParameterAction
    bool_setter allow_restart

    def run
      super

      parameters = client.update_configuration_parameters(
        cluster_id[:cluster],
        parameters: @args.map { |arg| {name: arg, "value": nil} },
        allow_restart: @allow_restart,
      )

      display(parameters)
    end
  end
end
