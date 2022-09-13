module Factory
  extend self

  def cluster(**params)
    params = {
      id:            "pkdpq6yynjgjbps4otxd7il2u4",
      host:          "p.pkdpq6yynjgjbps4otxd7il2u4.example.com",
      team_id:       "l2gnkxjv3beifk6abkraerv7de",
      name:          "abc",
      state:         "na",
      created_at:    Time.utc(2016, 2, 15, 10, 20, 30),
      is_ha:         false,
      major_version: 12,
      plan_id:       "memory-4",
      cpu:           4,
      memory:        111,
      oldest_backup: nil,
      provider_id:   "aws",
      region_id:     "us-east-2",
      network_id:    "nfpvoqooxzdrriu6w3bhqo55c4",
      storage:       1234,
    }.merge(params)

    CB::Client::ClusterDetail.new **params
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
end
