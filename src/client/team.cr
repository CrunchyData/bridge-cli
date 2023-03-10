require "./client"

module CB
  class Client
    # A team is a small organizational unit in Bridge used to group multiple users
    # at varying levels of privilege.

    jrecord Team,
      id : String,
      name : String,
      is_personal : Bool,
      role : String?,
      enforce_sso : Bool,
      billing_email : String? = nil do
      def name
        is_personal ? "personal" : @name
      end

      def enforce_sso
        @enforce_sso ? "enabled" : "disabled"
      end

      def to_s(io : IO)
        io << id.colorize.t_id << " (" << name.colorize.t_name << ")"
      end
    end

    # Create a new team.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teams/create-team
    def create_team(name : String)
      resp = post "teams", {name: name}
      Team.from_json resp.body
    end

    # List available teams.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teams/list-teams
    def get_teams
      resp = get "teams"
      Array(Team).from_json resp.body, root: "teams"
    end

    # Update a team.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamid/update-team
    def update_team(id, options)
      # TODO: (abrightwell) would it be better to have options bound to a type?
      # Seems like it would be the 'safer' option maybe. Thoughts are around
      # perhaps something like `TeamUpdateOptions`.
      resp = patch "teams/#{id}", options
      Team.from_json resp.body
    end

    # Retrieve details about a team.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamid/get-team
    def get_team(id)
      resp = get "teams/#{id}"
      Team.from_json resp.body
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
      Team.from_json resp.body
    end

    def get_team_cert(id)
      resp = get "teams/#{id}.pem"
      resp.body
    end
  end
end
