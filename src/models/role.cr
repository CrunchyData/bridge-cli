module CB::Model
  jrecord Role,
    account_id : String? = nil,
    account_email : String? = nil,
    name : String = "",
    password : String? = nil,
    uri : URI? = nil
end
