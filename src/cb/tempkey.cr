module CB
  record Tempkey, private_key : String, public_key : String, cluster_id : String, team_id : String, expires_at : Time do
    include Cacheable
    def self.suffix
      "tempkey"
    end

    def key
      cluster_id
    end

    def self.for_cluster(cluster_id, client) : Tempkey
      tk = fetch? cluster_id
      return tk if tk
      client.get_tempkey(cluster_id).store
    end
  end
end

