require "./client"

module CB
  class Client
    jrecord Backup,
      name : String,
      started_at : Time,
      finished_at : Time,
      lsn_start : String,
      lsn_stop : String,
      size_bytes : UInt64

    def backup_list(id)
      resp = get "clusters/#{id}/backups"
      Array(Backup).from_json resp.body, root: "backups"
    end

    jrecord AWSBackrestCredential,
      s3_key : String,
      s3_key_secret : String,
      s3_token : String,
      s3_region : String,
      s3_bucket : String

    jrecord AzureBackrestCredential,
      azure_account : String,
      azure_container : String,
      azure_key : String,
      azure_key_type : String

    jrecord BackupToken,
      type : String,
      repo_path : String,
      stanza : String,
      aws : AWSBackrestCredential? = nil,
      azure : AzureBackrestCredential? = nil

    def backup_token(id : Identifier)
      cluster_id = id.eid? ? id.to_s : get_cluster_by_name(id).id
      resp = post "clusters/#{cluster_id}/backup-tokens"
      BackupToken.from_json resp.body
    end

    def backup_start(id : Identifier)
      cluster_id = id.eid? ? id.to_s : get_cluster_by_name(id).id
      resp = put "clusters/#{cluster_id}/actions/start-backup"
      Message.from_json resp.body
    end
  end
end
