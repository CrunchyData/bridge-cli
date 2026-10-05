require "./action"
require "./table"

abstract class CB::TailscaleAction < CB::APIAction
  eid_setter cluster_id

  def validate
    check_required_args { |missing| missing << "cluster" unless cluster_id }
  end
end

# Action to connect a cluster to a tailscale network
class CB::TailscaleConnect < CB::TailscaleAction
  property auth_key : String?
  eid_setter client_id, "client"

  def validate
    super
    raise Error.new "Specify either authkey or client, not both." if auth_key && client_id
    check_required_args { |missing| missing << "authkey or client" unless auth_key || client_id }
  end

  def run
    validate

    body = Hash(String, String).new
    if id = client_id
      body["tailscale_oauth_client_id"] = id
    elsif key = auth_key
      body["auth_key"] = key
    end

    response = client.put "clusters/#{cluster_id}/actions/tailscale-connect", body
    output.puts JSON.parse(response.body)["message"]
  end
end

# Action to remove a cluster to a tailscale network
class CB::TailscaleDisconnect < CB::TailscaleAction
  def run
    validate

    response = client.put "clusters/#{cluster_id}/actions/tailscale-disconnect"
    output.puts JSON.parse(response.body)["message"]
  end
end

abstract class CB::TailscaleClientAction < CB::APIAction
  eid_setter team_id

  def validate
    check_required_args { |missing| missing << "team" unless team_id }
  end

  def self.render(output : IO, clients : Array(CB::Model::TailscaleOAuthClient), format : Format, no_header : Bool)
    case format
    when Format::Default, Format::Table
      table = Table::TableBuilder.new(border: :none) do
        columns do
          add "ID"
          add "Team"
          add "Name"
        end

        header unless no_header

        clients.each do |client|
          row [client.id, client.team_id, client.name]
        end
      end

      output << table.render << '\n'
    when Format::JSON
      output << {clients: clients}.to_pretty_json << '\n'
    end
  end
end

class CB::TailscaleClientCreate < CB::TailscaleClientAction
  property tailscale_client_id : String?
  property tailscale_client_secret : String?
  property name : String?
  property tags : Array(String) = [] of String

  def validate
    super
    check_required_args do |missing|
      missing << "tailscale-client-id" unless tailscale_client_id
      missing << "tailscale-client-secret" unless tailscale_client_secret
      missing << "name" unless name
      missing << "tag" if tags.empty?
    end
  end

  def run
    validate

    created = client.create_tailscale_oauth_client(
      team_id.not_nil!,
      client_id: tailscale_client_id.not_nil!,
      client_secret: tailscale_client_secret.not_nil!,
      name: name.not_nil!,
      tags: tags,
    )
    self.class.render(output, [created], Format::Table, false)
  end
end

class CB::TailscaleClientList < CB::TailscaleClientAction
  format_setter format
  property no_header : Bool = false

  def run
    validate
    clients = client.get_tailscale_oauth_clients team_id.not_nil!
    self.class.render(output, clients, @format, no_header)
  end
end

class CB::TailscaleClientDestroy < CB::TailscaleClientAction
  eid_setter client_id, "client"

  def validate
    super
    check_required_args { |missing| missing << "client" unless client_id }
  end

  def run
    validate
    destroyed = client.destroy_tailscale_oauth_client(team_id.not_nil!, client_id.not_nil!)
    output.puts "Destroyed Tailscale OAuth client #{destroyed.id} (#{destroyed.name})."
  end
end
