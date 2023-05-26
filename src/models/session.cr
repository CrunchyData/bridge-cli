module CB::Model
  jrecord Session,
    id : String,
    account_id : String = "",
    expires_at : Time = Time::ZERO,
    is_sso : Bool? = nil,
    login_url : String? = nil,
    one_time_token : String? = nil,
    secret : String? = nil
end
