require "./client"

module CB
  class Client
    # Create a Tailscale OAuth client for a team.
    #
    # POST /teams/{team_id}/tailscale-oauth-clients
    def create_tailscale_oauth_client(team_id : String, *, client_id : String, client_secret : String, name : String, tags : Array(String))
      resp = post "teams/#{team_id}/tailscale-oauth-clients", {
        client_id:     client_id,
        client_secret: client_secret,
        name:          name,
        tags:          tags,
      }
      Model::TailscaleOAuthClient.from_json resp.body
    end

    # List Tailscale OAuth clients for a team, following pagination.
    #
    # GET /teams/{team_id}/tailscale-oauth-clients
    def get_tailscale_oauth_clients(team_id : String)
      clients = [] of Model::TailscaleOAuthClient
      query = Hash(String, String).new
      query["order_field"] = "id"

      loop do
        resp = get "teams/#{team_id}/tailscale-oauth-clients?#{HTTP::Params.encode(query)}"
        page = TailscaleOAuthClientListResponse.from_json resp.body
        clients.concat page.clients
        break unless page.has_more
        query["cursor"] = page.next_cursor.to_s
      end

      clients
    end

    # Delete a Tailscale OAuth client.
    #
    # DELETE /teams/{team_id}/tailscale-oauth-clients/{id}
    def destroy_tailscale_oauth_client(team_id : String, client_id : String)
      resp = delete "teams/#{team_id}/tailscale-oauth-clients/#{client_id}"
      Model::TailscaleOAuthClient.from_json resp.body
    end

    struct TailscaleOAuthClientListResponse
      include JSON::Serializable
      pagination_properties
      property clients : Array(Model::TailscaleOAuthClient)
    end
  end
end
