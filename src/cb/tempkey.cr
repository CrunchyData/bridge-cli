module CB
  record Tempkey, host : String, private_key : String, public_key : String, cluster_id : String, team_id : String, expires_at : Time do
    Cacheable.include key: cluster_id

    def self.for_cluster(cluster_id : Identifier, client) : Tempkey
      tk = fetch? cluster_id
      return tk if tk
      client.get_tempkey(cluster_id).store
    end
  end
end
