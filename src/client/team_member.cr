require "./client"

module CB
  class Client
    # Parameters required for adding a user to a team.
    jrecord TeamMemberCreateParams, email : String, role : String

    # Create (add) a team member.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamidmembers/create-team-member
    def create_team_member(team_id, params : TeamMemberCreateParams)
      resp = post "teams/#{team_id}/members", params
      CB::Model::TeamMember.from_json resp.body
    end

    struct TeamMemberListResponse
      include JSON::Serializable
      pagination_properties
      property team_members : Array(CB::Model::TeamMember)
    end

    # List the memebers of a team.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamidmembers/list-team-members
    def list_team_members(team_id)
      team_members = [] of CB::Model::TeamMember
      query_params = Hash(String, String | Array(String)).new.tap do |params|
        params["order_field"] = "email"
      end

      loop do
        resp = get "teams/#{team_id}/members?#{HTTP::Params.encode(query_params)}"
        data = TeamMemberListResponse.from_json resp.body
        team_members.concat(data.team_members)
        break unless data.has_more
        query_params["cursor"] = data.next_cursor.to_s
      end

      team_members
    end

    # Retrieve details about a team member.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamidmembersaccountid/get-team-member
    def get_team_member(team_id, account_id)
      resp = get "teams/#{team_id}/members/#{account_id}"
      CB::Model::TeamMember.from_json resp.body
    end

    # Update a team member.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamidmembersaccountid/update-team-member
    def update_team_member(team_id, account_id, role)
      resp = put "teams/#{team_id}/members/#{account_id}", {role: role}
      CB::Model::TeamMember.from_json resp.body
    end

    # Remove a team member from a team.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamidmembersaccountid/remove-team-member
    def remove_team_member(team_id, account_id)
      resp = delete "teams/#{team_id}/members/#{account_id}"
      CB::Model::TeamMember.from_json resp.body
    end
  end
end
