module CB::Model
  jrecord AccessToken,
    access_token = "",
    account_id = "",
    api_key_id = "",
    created_at = Time::ZERO,
    expires_at = Time::ZERO,
    expires_in = 0,
    id = "",
    token_type = "bearer"
end
