require "json"

require "./client"

module CB
  class Client
    jrecord PeeringCreateParams,
      peer_identifier : String

    def create_peering(network_id, params : PeeringCreateParams)
      resp = post "networks/#{network_id}/peerings", params
      CB::Model::Peering.from_json resp.body
    end

    def delete_peering(network_id, peering_id)
      resp = delete "networks/#{network_id}/peerings/#{peering_id}"
      CB::Model::Peering.from_json resp.body
    end

    def get_peering(network_id, peering_id)
      resp = get "networks/#{network_id}/peerings/#{peering_id}"
      CB::Model::Peering.from_json resp.body
    end

    def list_peerings(network_id)
      resp = get "networks/#{network_id}/peerings"
      Array(CB::Model::Peering).from_json resp.body, root: "peerings"
    end
  end
end
