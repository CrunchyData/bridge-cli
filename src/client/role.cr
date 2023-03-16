require "./client"

module CB
  class Client
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridroles/create-role
    def create_role(cluster_id)
      resp = post "clusters/#{cluster_id}/roles", "{}"
      CB::Model::Role.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridrolesrolename/get-role
    def get_role(cluster_id : Identifier, role_name : String)
      return get_role(cluster_id.to_s, role_name) if cluster_id.eid?
      c = get_cluster_by_name(cluster_id)
      get_role(c.id, role_name)
    end

    def get_role(cluster_id, role_name)
      resp = get "clusters/#{cluster_id}/roles/#{role_name}"
      CB::Model::Role.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridroles/list-roles
    def list_roles(cluster_id)
      resp = get "clusters/#{cluster_id}/roles"
      Array(CB::Model::Role).from_json resp.body, root: "roles"
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridrolesrolename/update-role
    def update_role(cluster_id, role_name, ur)
      resp = put "clusters/#{cluster_id}/roles/#{role_name}", ur
      CB::Model::Role.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridrolesrolename/delete-role
    def delete_role(cluster_id, role_name)
      resp = delete "clusters/#{cluster_id}/roles/#{role_name}"
      CB::Model::Role.from_json resp.body
    end
  end
end
