require "./client"

module CB
  class Client
    def backup_list(id : Identifier)
      cluster_id = id.eid? ? id.to_s : get_cluster_by_name(id).id
      resp = get "clusters/#{cluster_id}/backups"
      Array(CB::Model::Backup).from_json resp.body, root: "backups"
    end

    def backup_token(id : Identifier)
      cluster_id = id.eid? ? id.to_s : get_cluster_by_name(id).id
      resp = post "clusters/#{cluster_id}/backup-tokens"
      CB::Model::BackupToken.from_json resp.body
    end

    def backup_start(id : Identifier)
      cluster_id = id.eid? ? id.to_s : get_cluster_by_name(id).id
      resp = put "clusters/#{cluster_id}/actions/start-backup"
      Message.from_json resp.body
    end
  end
end
