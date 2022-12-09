module Factory
  extend self

  def account(**params)
    params = {
      id:    "mijrfkkuqvhernzfqcbqf7b6me",
      name:  "user",
      email: "user@example.com",
    }.merge(params)
    CB::Client::Account.new **params
  end

  def backup(**params)
    params = {
      name:        "a backup",
      started_at:  Time.utc(2022, 1, 1, 0, 0, 0),
      finished_at: Time.utc(2022, 2, 1, 0, 0, 0),
      lsn_start:   "1/a",
      lsn_stop:    "2/b",
      size_bytes:  123.to_u64,
    }.merge(params)

    CB::Client::Backup.new **params
  end

  def backup_token_aws(**params)
    params = {
      type:      "s3",
      repo_path: "/the-path",
      stanza:    "h3zwxm6bafaq3mqbgou5zj56su",
      aws:       CB::Client::AWSBackrestCredential.new(
        s3_key: "key",
        s3_key_secret: "secret",
        s3_token: "token",
        s3_region: "us-west-1",
        s3_bucket: "the-bucket",
      ),
    }.merge(params)

    CB::Client::BackupToken.new **params
  end

  def backup_token_azr(**params)
    params = {
      type:      "azure",
      repo_path: "/",
      stanza:    "h3zwxm6bafaq3mqbgou5zj56su",
      azure:     CB::Client::AzureBackrestCredential.new(
        azure_account: "test_account",
        azure_key: "test_token",
        azure_key_type: "sas",
        azure_container: "test_container",
      ),
    }.merge(params)

    CB::Client::BackupToken.new **params
  end

  def cluster(**params)
    params = {
      id:                       "pkdpq6yynjgjbps4otxd7il2u4",
      host:                     "p.pkdpq6yynjgjbps4otxd7il2u4.example.com",
      team_id:                  "l2gnkxjv3beifk6abkraerv7de",
      name:                     "abc",
      state:                    "na",
      created_at:               Time.utc(2016, 2, 15, 10, 20, 30),
      is_ha:                    false,
      major_version:            12,
      plan_id:                  "memory-4",
      cpu:                      4.0,
      memory:                   111.0,
      oldest_backup:            nil,
      provider_id:              "aws",
      region_id:                "us-east-2",
      maintenance_window_start: nil,
      network_id:               "nfpvoqooxzdrriu6w3bhqo55c4",
      storage:                  1234,
    }.merge(params)

    CB::Client::ClusterDetail.new **params
  end

  def configuration_parameter(**params)
    params = {
      component:      "postgres",
      name:           "postgres:max_connections",
      parameter_name: "max_connections",
      value:          "100",
    }.merge(params)

    CB::Client::ConfigurationParameter.new **params
  end

  def user_role(**params)
    params = {
      account_email: "user@example.com",
      name:          "u_mijrfkkuqvhernzfqcbqf7b6me",
      password:      "secret",
      uri:           URI.parse "postgres://u_mijrfkkuqvhernzfqcbqf7b6me:secret@example.com:5432/postgres",
    }.merge(params)

    CB::Client::Role.new **params
  end

  def system_role(**params)
    params = {
      name:     "application",
      password: "secret",
      uri:      URI.parse "postgres://application:secret@example.com:5432/postgres",
    }.merge(params)

    CB::Client::Role.new **params
  end

  def team(**params)
    params = {
      id:            "l2gnkxjv3beifk6abkraerv7de",
      name:          "Test Team",
      is_personal:   false,
      role:          nil,
      billing_email: nil,
      enforce_sso:   nil,
    }.merge(params)

    CB::Client::Team.new **params
  end

  def team_member(**params)
    params = {
      id:         "abc",
      team_id:    "pkdpq6yynjgjbps4otxd7il2u4",
      account_id: "4pfqoxothfagnfdryk2og7noei",
      role:       "member",
      email:      "test@example.com",
    }.merge(params)

    CB::Client::TeamMember.new **params
  end

  def tempkey(**params)
    params = {
      private_key: "private_key",
      public_key:  "public_key",
      cluster_id:  "pkdpq6yynjgjbps4otxd7il2u4",
      team_id:     "l2gnkxjv3beifk6abkraerv7de",
      expires_at:  Time.utc,
    }.merge(params)

    CB::Tempkey.new **params
  end
end
