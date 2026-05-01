module CB::Model
  jrecord SavedQuery,
    id : String,
    name : String,
    sql : String? = nil,
    cluster_id : String = "",
    team_id : String = "",
    saved_query_folder_id : String? = nil,
    created_at : Time = Time::ZERO,
    updated_at : Time = Time::ZERO
end
