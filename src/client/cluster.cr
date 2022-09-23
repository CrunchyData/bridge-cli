require "./client"

module CB
  class Client
    jrecord Cluster, id : String, team_id : String, name : String,
      replicas : Array(Cluster)?

    # Upgrade operation.
    jrecord Operation, flavor : String, state : String

    def get_clusters
      get_clusters(get_teams)
    end

    def get_clusters(teams : Array(Team))
      Promise.map(teams) { |t| get_clusters t.id }.get.flatten.sort_by!(&.name)
    end

    def get_clusters(team_id : String)
      resp = get "clusters?team_id=#{team_id}"
      team_clusters = Array(Cluster).from_json resp.body, root: "clusters"
      replicas = Array(Cluster).new
      team_clusters.map(&.replicas).reject(Nil).each { |rs| replicas += rs }

      team_clusters + replicas
    end

    jrecord ClusterDetail,
      id : String,
      team_id : String,
      name : String,
      state : String?,
      created_at : Time,
      cpu : Float64,
      host : String,
      is_ha : Bool,
      plan_id : String,
      major_version : Int32,
      memory : Float64,
      oldest_backup : Time?,
      provider_id : String,
      network_id : String,
      region_id : String,
      storage : Int32 do
      @[JSON::Field(key: "cluster_id")]
      getter source_cluster_id : String?
    end

    # Retrieve the cluster by id or by name.
    def get_cluster(id : Identifier)
      return get_cluster id.to_s if id.eid?
      get_cluster_by_name(id)
    end

    private def get_cluster_by_name(id : Identifier)
      cluster = get_clusters.find { |c| id == c.name }
      raise Program::Error.new "cluster #{id.to_s.colorize.t_name} does not exist." unless cluster
      get_cluster cluster.id
    end

    # TODO (abrightwell): track down why this must be nilable. Seems reasonable
    # that it shouldn't require it to be.
    def get_cluster(id : String?)
      resp = get "clusters/#{id}"
      ClusterDetail.from_json resp.body
    rescue e : Error
      raise e unless e.resp.status == HTTP::Status::FORBIDDEN
      raise Program::Error.new "cluster #{id.colorize.t_id} does not exist, or you do not have access to it"
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clusters/post
    def create_cluster(cc)
      body = {
        is_ha:               cc.ha,
        name:                cc.name,
        plan_id:             cc.plan,
        provider_id:         cc.platform,
        postgres_version_id: cc.postgres_version,
        region_id:           cc.region,
        storage:             cc.storage,
        team_id:             cc.team,
        network_id:          cc.network,
      }
      resp = post "clusters", body
      Cluster.from_json resp.body
    end

    def detach_cluster(id)
      put "clusters/#{id}/detach", ""
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
      Cluster.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridupgrade/upgrade-cluster
    def upgrade_cluster(uc)
      resp = post "clusters/#{uc.cluster_id}/upgrade", {
        is_ha:               uc.ha,
        plan_id:             uc.plan,
        postgres_version_id: uc.postgres_version,
        storage:             uc.storage,
      }
      Array(Operation).from_json resp.body, root: "operations"
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridupgrade/get-upgrade-status
    def upgrade_cluster_status(id)
      resp = get "clusters/#{id}/upgrade"
      Array(Operation).from_json resp.body, root: "operations"
    end

    def upgrade_cluster_cancel(id)
      delete "clusters/#{id}/upgrade"
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusterid/update-cluster
    def update_cluster(cluster_id, body)
      resp = patch "clusters/#{cluster_id}", body
      ClusterDetail.from_json resp.body
    end

    def replicate_cluster(cc)
      resp = post "clusters/#{cc.replica}/replicas", {
        name:        cc.name,
        plan_id:     cc.plan,
        provider_id: cc.platform,
        region_id:   cc.region,
      }
      Cluster.from_json resp.body
    end

    def destroy_cluster(id)
      delete "clusters/#{id}"
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridrestart/restart-cluster
    def restart_cluster(id, service : String)
      resp = put "clusters/#{id}/restart", {service: service}
      ClusterDetail.from_json resp.body
    end

    jrecord Message, message : String = ""

    def get_tempkey(cluster_id)
      resp = post "clusters/#{cluster_id}/tempkeys"
      Tempkey.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridactionssuspend/suspend-cluster
    def suspend_cluster(id : Identifier)
      resp = put "clusters/#{id}/actions/suspend"
      ClusterDetail.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridactionsresume/resume-cluster
    def resume_cluster(id : Identifier)
      resp = put "clusters/#{id}/actions/resume"
      ClusterDetail.from_json resp.body
    end
  end
end
