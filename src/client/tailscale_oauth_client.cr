require "./client"

module CB
  class Client
    struct TailscaleOAuthClientCreateParams
      include JSON::Serializable

      property client_id : String
      property client_secret : String
      property name : String
      property tags : Array(String)

      @[JSON::Field(key: team_id, ignore: true)]
      property team_id : String

      def initialize(
        @client_id,
        @client_secret,
        @name,
        @tags,
        @team_id
      )
      end
    end

    def tailscale_oauth_client_create(params : TailscaleOAuthClientCreateParams)
      resp = post "teams/#{params.team_id}/tailscale-oauth-clients", params
      CB::Model::TailscaleOAuthClient.from_json resp.body
    end

    struct TailscaleOAuthClientDeleteParams
      property tailscale_oauth_client_id : String
      property team_id : String

      def initialize(@team_id, @tailscale_oauth_client_id)
      end
    end

    def tailscale_oauth_client_delete(params : TailscaleOAuthClientDeleteParams)
      resp = delete "teams/#{params.team_id}/tailscale-oauth-clients/#{params.tailscale_oauth_client_id}"
      CB::Model::TailscaleOAuthClient.from_json resp.body
    end

    def tailscale_oauth_client_list(team_id : String)
      resp = get "teams/#{team_id}/tailscale-oauth-clients"
      Array(CB::Model::TailscaleOAuthClient).from_json resp.body, root: "clients"
    end
  end
end
