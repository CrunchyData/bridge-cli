require "./client"

module CB
  class Client
    def get_clusters
      get_clusters(get_teams)
    end

    def get_clusters(teams : Array(CB::Model::Team), flatten : Bool = false)
      result = Promise.map(teams) { |t| get_clusters t.id }.get.flatten
      result = flatten_clusters(result) if flatten
      result
    end

    def flatten_clusters(clusters : Array(CB::Model::Cluster)?, result = [] of CB::Model::Cluster)
      clusters.try &.each do |cluster|
        result << cluster
        flatten_clusters(cluster.replicas, result)
        cluster.replicas = nil
      end
      result
    end

    def get_clusters(team_id)
      resp = get "clusters?team_id=#{team_id}"
      Array(CB::Model::Cluster).from_json resp.body, root: "clusters"
    end

    # Retrieve the cluster by id or by name.
    def get_cluster(id : Identifier)
      return get_cluster id.to_s if id.eid?
      get_cluster_by_name(id)
    end

    private def get_cluster_by_name(id : Identifier)
      cluster = get_clusters(get_teams, true).find { |c| id == c.name }
      raise Program::Error.new "cluster #{id.to_s.colorize.t_name} does not exist." unless cluster
      get_cluster cluster.id
    end

    # TODO (abrightwell): track down why this must be nilable. Seems reasonable
    # that it shouldn't require it to be.
    def get_cluster(id : String?)
      resp = get "clusters/#{id}"
      CB::Model::Cluster.from_json resp.body
    rescue e : Error
      raise e unless e.resp.status == HTTP::Status::FORBIDDEN
      raise Program::Error.new "cluster #{id.colorize.t_id} does not exist, or you do not have access to it"
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clusters/post
    def create_cluster(params)
      # body = {
      #   is_ha:               cc.ha,
      #   name:                cc.name,
      #   plan_id:             cc.plan,
      #   provider_id:         cc.platform,
      #   postgres_version_id: cc.postgres_version,
      #   region_id:           cc.region,
      #   storage:             cc.storage,
      #   team_id:             cc.team,
      #   network_id:          cc.network,
      # }
      resp = post "clusters", params
      CB::Model::Cluster.from_json resp.body
    end

    def get_cluster_status(cluster_id)
      resp = get "clusters/#{cluster_id}/status"
      CB::Model::ClusterStatus.from_json resp.body
    end

    def detach_cluster(id : Identifier)
      cluster_id = id.eid? ? id : get_cluster_by_name(id).id
      resp = put "clusters/#{cluster_id}/actions/detach"
      CB::Model::Cluster.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridforks/post
    def fork_cluster(cc)
      resp = post "clusters/#{cc.fork}/forks", {
        name:        cc.name,
        plan_id:     cc.plan,
        storage:     cc.storage,
        provider_id: cc.platform,
        target_time: cc.at.try(&.to_rfc3339),
        region_id:   cc.region,
        is_ha:       cc.ha,
        network_id:  cc.network,
      }
      CB::Model::Cluster.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridupgrade/upgrade-cluster
    def upgrade_cluster(uc)
      resp = post "clusters/#{uc.cluster_id}/upgrade", {
        is_ha:               uc.ha,
        plan_id:             uc.plan,
        postgres_version_id: uc.postgres_version,
        storage:             uc.storage,
        starting_from:       uc.starting_from,
      }
      Array(CB::Model::Operation).from_json resp.body, root: "operations"
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridupgrade/update-upgrade-cluster
    def update_upgrade_cluster(uc)
      resp = put "clusters/#{uc.cluster_id}/upgrade", {
        plan_id:                        uc.plan,
        postgres_version_id:            uc.postgres_version,
        storage:                        uc.storage,
        starting_from:                  uc.starting_from,
        use_cluster_maintenance_window: uc.use_cluster_maintenance_window,
      }
      Array(CB::Model::Operation).from_json resp.body, root: "operations"
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridupgrade/get-upgrade-status
    def upgrade_cluster_status(id)
      resp = get "clusters/#{id}/upgrade"
      Array(CB::Model::Operation).from_json resp.body, root: "operations"
    end

    def upgrade_cluster_cancel(id)
      delete "clusters/#{id}/upgrade"
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusterid/update-cluster
    def update_cluster(cluster_id, body)
      resp = patch "clusters/#{cluster_id}", body
      CB::Model::Cluster.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridreplicas/create-cluster-replica
    def replicate_cluster(cc)
      resp = post "clusters/#{cc.replica}/replicas", {
        name:        cc.name,
        plan_id:     cc.plan,
        provider_id: cc.platform,
        region_id:   cc.region,
        network_id:  cc.network,
      }
      CB::Model::Cluster.from_json resp.body
    end

    def destroy_cluster(id : String)
      destroy_cluster Identifier.new(id)
    end

    def destroy_cluster(id : Identifier)
      resp = delete "clusters/#{id}"
      CB::Model::Cluster.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridrestart/restart-cluster
    def restart_cluster(id, service : String)
      resp = put "clusters/#{id}/actions/restart", {service: service}
      CB::Model::Cluster.from_json resp.body
    end

    jrecord Message, message : String = ""

    def get_tempkey(id : Identifier)
      cluster_id = id.eid? ? id.to_s : get_cluster_by_name(id).id
      resp = post "clusters/#{cluster_id}/tempkeys"
      Tempkey.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridactionssuspend/suspend-cluster
    def suspend_cluster(id : Identifier)
      resp = put "clusters/#{id}/actions/suspend"
      CB::Model::Cluster.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridactionsresume/resume-cluster
    def resume_cluster(id : Identifier)
      resp = put "clusters/#{id}/actions/resume"
      CB::Model::Cluster.from_json resp.body
    end
  end
end
