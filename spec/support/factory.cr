module Factory
  extend self

  def access_token(**params)
    params = {
      id:           "ap25elveknc5rinrcohder4lwe",
      access_token: "cbats_secret",
      account_id:   "mijrfkkuqvhernzfqcbqf7b6me",
      api_key_id:   "ick5hebsvbconguw4fkguebmzm",
      created_at:   Time.utc(2023, 5, 25, 0, 0, 0),
      expires_at:   Time.utc(2023, 5, 25, 1, 0, 0),
      expires_in:   3600,
      token_type:   "bearer",
    }.merge(params)
    CB::Model::AccessToken.new **params
  end

  def account(**params)
    params = {
      id:    "mijrfkkuqvhernzfqcbqf7b6me",
      name:  "user",
      email: "user@example.com",
    }.merge(params)
    CB::Model::Account.new **params
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

    CB::Model::Backup.new **params
  end

  def backup_token_aws(**params)
    params = {
      type:      "s3",
      repo_path: "/the-path",
      stanza:    "h3zwxm6bafaq3mqbgou5zj56su",
      aws:       CB::Model::AWSBackrestCredential.new(
        s3_key: "key",
        s3_key_secret: "secret",
        s3_token: "token",
        s3_region: "us-west-1",
        s3_bucket: "the-bucket",
      ),
    }.merge(params)

    CB::Model::BackupToken.new **params
  end

  def backup_token_azr(**params)
    params = {
      type:      "azure",
      repo_path: "/",
      stanza:    "h3zwxm6bafaq3mqbgou5zj56su",
      azure:     CB::Model::AzureBackrestCredential.new(
        azure_account: "test_account",
        azure_key: "test_token",
        azure_key_type: "sas",
        azure_container: "test_container",
      ),
    }.merge(params)

    CB::Model::BackupToken.new **params
  end

  def cluster(**params)
    params = {
      id:                       "pkdpq6yynjgjbps4otxd7il2u4",
      host:                     "p.pkdpq6yynjgjbps4otxd7il2u4.example.com",
      team_id:                  "l2gnkxjv3beifk6abkraerv7de",
      name:                     "abc",
      created_at:               Time.utc(2016, 2, 15, 10, 20, 30),
      is_ha:                    false,
      major_version:            12,
      plan_id:                  "memory-4",
      cpu:                      4.0,
      memory:                   111.0,
      provider_id:              "aws",
      region_id:                "us-east-2",
      maintenance_window_start: nil,
      network_id:               "nfpvoqooxzdrriu6w3bhqo55c4",
      storage:                  1234,
    }.merge(params)

    CB::Model::Cluster.new **params
  end

  def cluster_status(**params)
    params = {
      oldest_backup_at: nil,
      state:            CB::Model::ClusterStatus::State::Ready,
    }.merge(params)

    CB::Model::ClusterStatus.new **params
  end

  def configuration_parameter(**params)
    params = {
      component:        "postgres",
      name:             "postgres:max_connections",
      parameter_name:   "max_connections",
      requires_restart: false,
      value:            "100",
    }.merge(params)

    CB::Model::ConfigurationParameter.new **params
  end

  def firewall_rule(**params)
    params = {
      id:   "shofthj3fzaipie44lt6a5i3de",
      rule: "1.2.3.0/24",
    }.merge(params)
    CB::Model::FirewallRule.new **params
  end

  def log_destination(**params)
    params = {
      id:          "pxbcigcufjdqje6drled4rj6p4",
      host:        "host",
      port:        2020,
      template:    "template",
      description: "logdest descr",
    }.merge(params)

    CB::Model::LogDestination.new **params
  end

  def network(**params)
    params = {
      cidr4:       "192.168.0.0/24",
      id:          "oap3kavluvgm7cwtzgaaixzfoi",
      name:        "Default Network",
      provider_id: "aws",
      region_id:   "us-east-1",
      team_id:     "l2gnkxjv3beifk6abkraerv7de",
    }.merge(params)

    CB::Model::Network.new **params
  end

  def operation(**params) : CB::Model::Operation
    params = {
      flavor:        CB::Model::Operation::Flavor::Resize,
      state:         CB::Model::Operation::State::InProgress,
      starting_from: nil,
    }.merge(params)

    CB::Model::Operation.new **params
  end

  def plan(**params)
    params = {
      id:           "jkon7qbrzzccrgwn346w3niloe",
      display_name: "Example Plan",
    }.merge(params)

    CB::Model::Plan.new **params
  end

  def provider(**params)
    params = {
      id:           "xujafqpecfcwpa4rmemogvin7m",
      display_name: "Example Provider",
      regions:      [] of CB::Model::Region,
      plans:        [] of CB::Model::Plan,
    }.merge(params)

    CB::Model::Provider.new **params
  end

  def region(**params)
    params = {
      id:           "jyhs4gzfszhqpnmmlnneyzodfa",
      display_name: "Central America 1",
      location:     "Isla Nublar",
    }.merge(params)
    CB::Model::Region.new **params
  end

  def role_system(**params)
    params = {
      name:     "application",
      password: "secret",
      uri:      URI.parse "postgres://application:secret@example.com:5432/postgres",
    }.merge(params)

    CB::Model::Role.new **params
  end

  def role_user(**params)
    params = {
      account_email: "user@example.com",
      name:          "u_mijrfkkuqvhernzfqcbqf7b6me",
      password:      "secret",
      uri:           URI.parse "postgres://u_mijrfkkuqvhernzfqcbqf7b6me:secret@example.com:5432/postgres",
    }.merge(params)

    CB::Model::Role.new **params
  end

  def session(**params)
    params = {
      id:     "lgsfa35anjcbzju43wxe4ohbgi",
      secret: "cbst_session_secret",
    }.merge(params)

    CB::Model::Session.new **params
  end

  def session_intent(**params)
    params = {
      id:         "rruyc6hukvcorh2jnspm232s4m",
      agent_name: "cb",
      code:       "cbsic_code",
      expires_at: Time::ZERO,
      secret:     nil,
      session:    nil,
    }.merge(params)

    CB::Model::SessionIntent.new **params
  end

  def team(**params)
    params = {
      id:            "l2gnkxjv3beifk6abkraerv7de",
      name:          "Test Team",
      is_personal:   false,
      role:          "admin",
      billing_email: "test@example.com",
      enforce_sso:   nil,
    }.merge(params)

    CB::Model::Team.new **params
  end

  def team_member(**params)
    params = {
      id:         "abc",
      team_id:    "pkdpq6yynjgjbps4otxd7il2u4",
      account_id: "4pfqoxothfagnfdryk2og7noei",
      role:       "member",
      email:      "test@example.com",
    }.merge(params)

    CB::Model::TeamMember.new **params
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
