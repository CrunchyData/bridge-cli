module CB::Model
  jrecord SessionIntent,
    id : String,
    agent_name : String = "cb",
    code : String = "cbsic_code",
    expires_at : Time = Time::ZERO,
    secret : String? = nil,
    session : Session? = nil
end
