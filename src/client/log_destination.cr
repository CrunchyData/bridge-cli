require "./client"

module CB
  class Client
    # List existing loggers for a cluster.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridloggers/list-loggers
    def get_log_destinations(cluster_id)
      resp = get "clusters/#{cluster_id}/loggers"
      Array(CB::Model::LogDestination).from_json resp.body, root: "loggers"
    end

    # Add a logger to a cluster.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridloggers/create-logger
    def add_log_destination(cluster_id, ld)
      resp = post "clusters/#{cluster_id}/loggers", ld
      resp.body
    end

    # Remove a logger from a cluster.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridloggersloggerid/destroy-logger
    def destroy_log_destination(cluster_id, logdest_id)
      resp = delete "clusters/#{cluster_id}/loggers/#{logdest_id}"
      resp.body
    end
  end
end
