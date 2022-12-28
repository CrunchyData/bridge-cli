require "./client"

module CB
  class Client
    jrecord Network,
      cidr4 : String,
      id : String,
      name : String,
      provider_id : String,
      region_id : String,
      team_id : String

    # Get a network by id or name.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/networksnetworkid
    def get_network(id : Identifier)
      return get_network id.to_s if id.eid?
      get_network_by_name(id)
    end

    def get_network(id : String?)
      resp = get "networks/#{id}"
      Network.from_json resp.body
    end

    # Get all networks for a team.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/networks/list-networks
    def get_networks(team : Identifier?)
      resp = if team
               team_id = team.eid? ? team.to_s : get_team_by_name(team).id
               get "networks?team_id=#{team_id}"
             else
               get "networks"
             end

      Array(Network).from_json resp.body, root: "networks"
    end

    private def get_network_by_name(id : Identifier)
      network = get_networks(nil).find { |n| id == n.name }
      raise Program::Error.new "network #{id.to_s.colorize.t_name} does not exist." unless network
      network
    end
  end
end
