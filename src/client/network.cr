require "./client"

module CB
  class Client
    # Get a network by id or name.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/networksnetworkid
    def get_network(id : Identifier)
      return get_network id.to_s if id.eid?
      get_network_by_name(id)
    end

    def get_network(id : String?)
      resp = get "networks/#{id}"
      CB::Model::Network.from_json resp.body
    end

    struct NetworkListResponse
      include JSON::Serializable
      pagination_properties
      property networks : Array(CB::Model::Network)
    end

    # Get all networks for a team.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/networks/list-networks
    def get_networks(team : Identifier?)
      networks = [] of CB::Model::Network
      query_params = Hash(String, String | Array(String)).new.tap do |params|
        params["order_field"] = "id"
        params["team_id"] = team.eid? ? team.to_s : get_team_by_name(team).id if team
      end

      loop do
        resp = get "networks?#{HTTP::Params.encode(query_params)}"
        data = NetworkListResponse.from_json resp.body
        networks.concat(data.networks)
        break unless data.has_more
        query_params["cursor"] = data.next_cursor.to_s
      end

      networks
    end

    def get_networks(teams : Array(CB::Model::Team))
      networks = [] of CB::Model::Network
      teams.each { |team| networks.concat get_networks(Identifier.new team.id.to_s) }
      networks
    end

    private def get_network_by_name(id : Identifier)
      network = get_networks(nil).find { |n| id == n.name }
      raise Program::Error.new "network #{id.to_s.colorize.t_name} does not exist." unless network
      network
    end
  end
end
