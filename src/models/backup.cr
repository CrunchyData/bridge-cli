module CB::Model
  jrecord Backup,
    name : String,
    started_at : Time,
    finished_at : Time,
    lsn_start : String,
    lsn_stop : String,
    size_bytes : UInt64

  jrecord BackupToken,
    type : String,
    repo_path : String,
    stanza : String,
    aws : AWSBackrestCredential? = nil,
    azure : AzureBackrestCredential? = nil

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
end
