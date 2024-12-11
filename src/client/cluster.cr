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

    struct ClusterListResponse
      include JSON::Serializable
      pagination_properties
      property clusters : Array(CB::Model::Cluster) = [] of CB::Model::Cluster
    end

    def get_clusters(team_id)
      clusters : Array(CB::Model::Cluster) = [] of CB::Model::Cluster
      query_params = Hash(String, String | Array(String)).new.tap do |params|
        params["team_id"] = team_id.to_s
        params["order_field"] = "name"
      end

      loop do
        resp = get "clusters?#{HTTP::Params.encode(query_params)}"
        data = ClusterListResponse.from_json resp.body
        clusters.concat(data.clusters)
        break unless data.has_more
        query_params["cursor"] = data.next_cursor.to_s
      end

      clusters
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

    @[JSON::Serializable::Options(emit_nulls: false)]
    abstract struct CommonCreateParams
      include JSON::Serializable
      property name : String
      property network_id : String?
      property plan_id : String?
      property provider_id : String?
      property region_id : String?

      def initialize(
        @name,
        @network_id = nil,
        @plan_id = nil,
        @provider_id = nil,
        @region_id = nil
      )
      end
    end

    struct ClusterCreateParams < CommonCreateParams
      property environment : String?
      property is_ha : Bool?
      property postgres_version_id : Int32?
      property storage : Int32?
      property team_id : String

      def initialize(
        @name, @plan_id, @provider_id, @region_id, @team_id,
        @environment = nil,
        @is_ha = nil,
        @postgres_version_id = nil,
        @storage = nil,
        @network_id = nil
      )
      end
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clusters/post
    def create_cluster(params : ClusterCreateParams)
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

    struct ForkCreateParams < CommonCreateParams
      @[JSON::Field(ignore: true)]
      property cluster_id : String
      property is_ha : Bool?
      property storage : Int32?
      property target_time : Time?

      def initialize(
        @cluster_id, @name,
        @is_ha = nil,
        @network_id = nil,
        @plan_id = nil,
        @provider_id = nil,
        @region_id = nil,
        @storage = nil,
        @target_time = nil
      )
      end
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridforks/post
    def create_fork(params : ForkCreateParams)
      resp = post "clusters/#{params.cluster_id}/forks", params
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

    struct ReplicaCreateParams < CommonCreateParams
      @[JSON::Field(ignore: true)]
      property cluster_id : String

      def initialize(
        @cluster_id,
        @name,
        @network_id = nil,
        @plan_id = nil,
        @provider_id = nil,
        @region_id = nil
      )
      end
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridreplicas/create-cluster-replica
    def create_replica(params : ReplicaCreateParams)
      resp = post "clusters/#{params.cluster_id}/replicas", params
      CB::Model::Cluster.from_json resp.body
    end

    def destroy_cluster(id : String)
      destroy_cluster Identifier.new(id)
    end

    def destroy_cluster(id : Identifier)
      resp = delete "clusters/#{id}"
      CB::Model::Cluster.from_json resp.body
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridactionsdisable-ha/disable-high-availability
    def disable_ha(id : Identifier) : CB::Model::Operation?
      resp = put "clusters/#{id}/actions/disable-ha"
      json = JSON.parse(resp.body)
      return CB::Model::Operation.from_json resp.body if (flavor = json["flavor"]?) && !flavor.as_s.empty?
      nil
    end

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridactionsenable-ha/enable-high-availability
    def enable_ha(id : Identifier) : CB::Model::Operation?
      resp = put "clusters/#{id}/actions/enable-ha"
      json = JSON.parse(resp.body)
      return CB::Model::Operation.from_json resp.body if (flavor = json["flavor"]?) && !flavor.as_s.empty?
      nil
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
