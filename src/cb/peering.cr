require "./action"

module CB
  abstract class PeeringAction < APIAction
    format_setter format
    eid_setter network_id
    property? no_header : Bool = false

    abstract def run

    def validate
      check_required_args do |missing|
        missing << "network" unless @network_id
      end
    end

    def display(peerings : Array(Model::Peering))
      case @format
      when Format::Default, Format::Table
        output_table(peerings)
      when Format::List
        output_list(peerings)
      when Format::JSON
        output_json(peerings)
      end
    end

    def output_json(peerings : Array(Model::Peering))
      output << {
        "peerings": peerings,
      }.to_pretty_json << '\n'
    end

    def output_list(peerings : Array(Model::Peering))
      if peerings.empty?
        output << "No peerings exist for network #{@network_id.colorize.t_id}.\n"
        return
      end

      peerings.each_with_index(offset: 1) do |peering, index|
        output << "-- Peering ##{index} --\n"
        table = Table::TableBuilder.new(border: :none) do
          row ["ID:", peering.id.colorize.t_id]
          row ["Name:", peering.name.colorize.t_name]
          row ["Network ID:", peering.network_identifier]
          row ["Peer ID:", peering.peer_identifier]
          row ["CIDR:", peering.cidr4]
          row ["Status:", peering.status]
        end
        output << table.render << '\n'
      end
    end

    def output_table(peerings : Array(Model::Peering))
      if peerings.empty?
        output << "No peerings exist for network #{@network_id.colorize.t_id}.\n"
        return
      end

      table = Table::TableBuilder.new(border: :none) do
        columns do
          add "ID"
          add "Name"
          add "Network ID"
          add "Peer ID"
          add "CIDR"
          add "Status"
        end

        header unless @no_header

        rows peerings.map { |p|
          [
            p.id,
            p.name,
            p.network_identifier,
            p.peer_identifier,
            p.cidr4,
            p.status,
          ]
        }
      end

      output << table.render << '\n'
    end
  end

  class PeeringCreate < PeeringAction
    property platform : String?
    property aws_account_id : String?
    property aws_vpc_id : String?
    property gcp_project_id : String?
    property gcp_vpc_name : String?

    def validate
      super

      raise Program::Error.new("Cannot use '--gcp-project-id' or '--gcp-vpc-name' if '--platform' is #{"aws".colorize.t_name}") if @platform == "aws" && (gcp_project_id || gcp_vpc_name)
      raise Program::Error.new("Cannot use '--aws-account-id' or '--aws-vpc-id' if '--platform' is #{"gcp".colorize.t_name}") if @platform == "gcp" && (aws_account_id || aws_vpc_id)

      check_required_args do |missing|
        case platform
        when "aws"
          missing << "aws-account-id" unless aws_account_id
          missing << "aws-vpc-id" unless aws_vpc_id
        when "gcp"
          missing << "gcp-project-id" unless gcp_project_id
          missing << "gcp-vpc-name" unless gcp_vpc_name
        when nil
          missing << "platform" unless platform
        end
      end
    end

    def run
      validate

      peer_identifier = make_peer_identifier.to_s
      params = CB::Client::PeeringCreateParams.new peer_identifier: peer_identifier
      peering = client.create_peering(@network_id, params)

      display([peering])
    end

    def make_peer_identifier
      case @platform
      when "aws"
        region = client.get_network(@network_id).region_id
        "arn:aws:ec2:#{region}:#{@aws_account_id}:vpc/#{@aws_vpc_id}"
      when "gcp"
        "https://www.googleapis.com/compute/v1/projects/#{gcp_project_id}/global/networks/#{gcp_vpc_name}"
      end
    end
  end

  class PeeringDelete < PeeringAction
    eid_setter peering_id

    def validate
      check_required_args do |missing|
        missing << "peering" unless peering_id
      end
    end

    def run
      validate

      peering = client.delete_peering(@network_id, @peering_id)
      display([peering])
    end
  end

  class PeeringGet < PeeringAction
    eid_setter peering_id

    def validate
      check_required_args do |missing|
        missing << "peering" unless peering_id
      end
    end

    def run
      validate

      peering = client.get_peering(@network_id, @peering_id)
      display([peering])
    end
  end

  class PeeringList < PeeringAction
    def run
      validate

      peerings = client.list_peerings(@network_id)
      display(peerings)
    end
  end
end
