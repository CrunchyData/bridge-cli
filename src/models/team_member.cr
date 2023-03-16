module CB::Model
  # A team member is a association of a bridge user to a bridge team.
  jrecord TeamMember,
    id : String,
    team_id : String,
    account_id : String,
    role : String,
    email : String
end
