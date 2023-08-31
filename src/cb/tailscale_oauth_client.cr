require "./action"

module CB
  # API action for Tailscale OAuth clients.
  #
  # All Tailscale Oauth client actions must inherit this action.
  abstract class TailscaleOAuthClientAction < APIAction
    # The output format. The default format is `table` format.
    format_setter format

    # The unique ID of which the team the Tailscale OAuth client is assocated.
    identifier_setter team_id

    # Flag to indicate whether the output should include a header. This only
    # has an effect when the output format is a table.
    property no_header : Bool = false

    def validate
      check_required_args do |missing|
        missing << "team" unless @team_id
      end
    end

    abstract def run

    protected def display(clients : Array(Model::TailscaleOAuthClient))
      case @format
      when Format::Default, Format::Table
        output_table(clients)
      when Format::JSON
        output_json(clients)
      end
    end

    protected def output_json(clients : Array(Model::TailscaleOAuthClient))
    end

    protected def output_table(clients : Array(Model::TailscaleOAuthClient))
      table = Table::TableBuilder.new(border: :none) do
        columns do
          add "ID"
          add "Name"
        end

        header unless no_header

        rows clients.map { |c| [c.id, c.name] }
      end
      output << table.render << '\n'
    end
  end

  # Action for creating a new Tailscale OAuth client.
  class TailscaleOAuthClientCreate < TailscaleOAuthClientAction
    # The OAuth client id provided by Tailscale.
    property client_id : String = ""

    # The OAuth client secret provided by Tailscale.
    property client_secret : String = ""

    # The user defined name for the client.
    property name : String = ""

    # The list of tags that were specified when the client was created in
    # Tailscale.
    property tags : Array(String) = [] of String

    def validate
      check_required_args do |missing|
        missing << "client-id" if @client_id.empty?
        missing << "client-secret" if @client_secret.empty?
        missing << "name" if @name.empty?
        missing << "tags" if @tags.empty?
      end
    end

    def run
      validate

      params = CB::Client::TailscaleOAuthClientCreateParams.new(
        client_id: @client_id,
        client_secret: @client_secret,
        name: @name,
        tags: @tags,
        team_id: @team_id.to_s
      )

      c = client.tailscale_oauth_client_create(params)
      display([c])
    end
  end

  # Action for destroying an existing Tailscale OAuth client.
  class TailscaleOAuthClientDestroy < TailscaleOAuthClientAction
    # The client id provided by Tailscale.
    property client_id : String = ""

    def validate
      check_required_args do |missing|
        missing << "client-id" if @client_id.empty?
      end
    end

    def run
      validate

      params = CB::Client::TailscaleOAuthClientDeleteParams.new(
        tailscale_oauth_client_id: @client_id,
        team_id: @team_id.to_s
      )
      c = client.tailscale_oauth_client_delete(params)
      display([c])
    end
  end

  # Action for listing the available Tailscale OAuth clients for a team.
  class TailscaleOAuthClientList < TailscaleOAuthClientAction
    def run
      validate

      clients = client.tailscale_oauth_client_list(@team_id.to_s)
      display(clients)
    end
  end
end
