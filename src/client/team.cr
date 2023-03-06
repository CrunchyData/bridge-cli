require "./client"

module CB
  class Client
    # Create a new team.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teams/create-team
    def create_team(name : String)
      resp = post "teams", {name: name}
      CB::Model::Team.from_json resp.body
    end

    # List available teams.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teams/list-teams
    def get_teams
      resp = get "teams"
      Array(CB::Model::Team).from_json resp.body, root: "teams"
    end

    # Update a team.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamid/update-team
    def update_team(id, options)
      # TODO: (abrightwell) would it be better to have options bound to a type?
      # Seems like it would be the 'safer' option maybe. Thoughts are around
      # perhaps something like `TeamUpdateOptions`.
      resp = patch "teams/#{id}", options
      CB::Model::Team.from_json resp.body
    end

    # Retrieve details about a team.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamid/get-team
    def get_team(id)
      resp = get "teams/#{id}"
      CB::Model::Team.from_json resp.body
    end

    private def get_team_by_name(name : Identifier)
      team = get_teams.find { |t| name == t.name }
      raise Program::Error.new "team #{name.colorize.t_name} does not exist." unless team
      team
    end

    # Delete a team.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamid/destroy-team
    def destroy_team(id)
      resp = delete "teams/#{id}"
      CB::Model::Team.from_json resp.body
    end

    def get_team_cert(id)
      resp = get "teams/#{id}.pem"
      resp.body
    end
  end
end
