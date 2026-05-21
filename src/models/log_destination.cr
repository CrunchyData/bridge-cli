module CB::Model
  jrecord LogDestination,
    id : String,
    host : String,
    port : Int32,
    template : String,
    description : String,
    tls_verify_disabled : Bool = false,
    forward_connection_logs : Bool = false
end
