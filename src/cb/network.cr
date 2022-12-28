require "./action"

module CB
  # API action for network management.
  #
  # All network management actions must inherit this action.
  abstract class NetworkAction < APIAction
    # The output format. The default format is `table` format.
    format_setter format

    # Result of API calls.
    property networks : Array(Client::Network) = [] of Client::Network

    # Flag to indicate whether the output should include a header. This only
    # has an effect when the output format is `table`.
    property no_header : Bool = false

    def run
      validate

      yield

      case @format
      when Format::Default, Format::Table
        output_table
      when Format::JSON
        output_json
      end
    end

    def validate
      true
    end

    protected def output_json
      output << {
        "networks": @networks,
      }.to_pretty_json << '\n'
    end

    protected def output_table
      table = Table::TableBuilder.new(border: :none) do
        columns do
          add "ID"
          add "Team"
          add "Name"
          add "CIDR4"
          add "Provider"
          add "Region"
        end

        header unless no_header

        @networks.each do |n|
          row [
            n.id,
            n.team_id,
            n.name,
            n.cidr4,
            n.provider_id,
            n.region_id,
          ]
        end
      end

      output << table.render << '\n'
    end
  end

  class NetworkInfo < NetworkAction
    identifier_setter network_id

    def validate
      check_required_args do |missing|
        missing << "network" unless network_id
      end
    end

    def run
      super { @networks << client.get_network @network_id }
    end
  end

  class NetworkList < NetworkAction
    identifier_setter team_id

    def run
      super { @networks = client.get_networks @team_id }
    end
  end
end
