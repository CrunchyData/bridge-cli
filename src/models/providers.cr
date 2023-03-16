module CB::Model
  jrecord Plan,
    id : String,
    display_name : String

  jrecord Provider, id : String,
    display_name : String,
    regions : Array(Region),
    plans : Array(Plan)

  jrecord Region,
    id : String,
    display_name : String,
    location : String
end
