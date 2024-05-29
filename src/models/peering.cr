module CB::Model
  jrecord Peering,
    id : String,
    cidr4 : String,
    name : String?,
    network_id : String,
    network_identifier : String,
    peer_identifier : String,
    status : String
end
