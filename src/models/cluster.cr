require "json"

module CB::Model
  struct Cluster
    include JSON::Serializable

    property cpu : Float64

    property id : String

    property created_at : Time

    property host : String

    property is_ha : Bool

    property maintenance_window_start : Int32?

    property major_version : Int32

    property memory : Float64

    property name : String

    property network_id : String

    property plan_id : String

    property provider_id : String

    property region_id : String

    property replicas : Array(Cluster)?

    @[JSON::Field(key: "cluster_id")]
    property source_cluster_id : String?

    property storage : Int32

    property tailscale_active : Bool

    property team_id : String

    def initialize(@id, @name, @team_id,
                   @cpu = 0.0,
                   @created_at = Time::ZERO,
                   @host = "",
                   @is_ha = false,
                   @maintenance_window_start = nil,
                   @major_version = 0,
                   @memory = 0,
                   @network_id = "",
                   @plan_id = "",
                   @provider_id = "",
                   @region_id = "",
                   @replicas = nil,
                   @source_cluster_id = nil,
                   @storage = 0,
                   @tailscale_active = false)
    end
  end
end
