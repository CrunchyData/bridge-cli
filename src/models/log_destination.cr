module CB::Model
  jrecord LogDestination,
    id : String,
    host : String,
    port : Int32,
    template : String,
    description : String
end
