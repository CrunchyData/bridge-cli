module CB::Model
  jrecord TailscaleOAuthClient,
    id : String,
    created_at : Time,
    name : String,
    team_id : String,
    updated_at : Time
end
