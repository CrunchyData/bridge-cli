module CB::Model
  jrecord TailscaleOAuthClient,
    id : String,
    name : String,
    team_id : String,
    created_at : Time = Time::ZERO,
    updated_at : Time = Time::ZERO
end
