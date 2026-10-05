require "../spec_helper"

Spectator.describe CB::Model::TailscaleOAuthClient do
  it "parses the fields the API returns" do
    json = %({
      "id": "pkdpq6yynjgjbps4otxd7il2u4",
      "name": "production",
      "team_id": "p5jflp7w3zhe7bu7c4s2t4e2wq",
      "created_at": "2026-10-05T00:00:00Z",
      "updated_at": "2026-10-05T01:00:00Z"
    })

    client = CB::Model::TailscaleOAuthClient.from_json(json)

    expect(client.id).to eq "pkdpq6yynjgjbps4otxd7il2u4"
    expect(client.name).to eq "production"
    expect(client.team_id).to eq "p5jflp7w3zhe7bu7c4s2t4e2wq"
    expect(client.created_at).to eq Time.utc(2026, 10, 5)
    expect(client.updated_at).to eq Time.utc(2026, 10, 5, 1)
  end
end

private class RecordingTailscaleClient < CB::Client
  getter calls = [] of Tuple(String, String, String?)
  property responses = [] of String

  def exec(method, path, body : String? = nil)
    calls << {method, path, body}
    HTTP::Client::Response.new(200, body: responses.shift)
  end
end

Spectator.describe CB::Client do
  let(client) { RecordingTailscaleClient.new }
  let(resource) do
    %({
      "id": "pkdpq6yynjgjbps4otxd7il2u4",
      "name": "production",
      "team_id": "p5jflp7w3zhe7bu7c4s2t4e2wq",
      "created_at": "2026-10-05T00:00:00Z",
      "updated_at": "2026-10-05T00:00:00Z"
    })
  end

  it "posts a Tailscale OAuth client create body" do
    client.responses << resource

    created = client.create_tailscale_oauth_client(
      "p5jflp7w3zhe7bu7c4s2t4e2wq",
      client_id: "k123456CNTRL",
      client_secret: "tskey-client-example",
      name: "production",
      tags: ["tag:production"],
    )

    expect(created.id).to eq "pkdpq6yynjgjbps4otxd7il2u4"
    method, path, body = client.calls.first
    expect(method).to eq "POST"
    expect(path).to eq "teams/p5jflp7w3zhe7bu7c4s2t4e2wq/tailscale-oauth-clients"
    payload = JSON.parse(body.not_nil!)
    expect(payload["client_id"]).to eq "k123456CNTRL"
    expect(payload["client_secret"]).to eq "tskey-client-example"
    expect(payload["name"]).to eq "production"
    expect(payload["tags"]).to eq ["tag:production"]
  end

  it "pages the Tailscale OAuth client list" do
    client.responses << %({"clients":[#{resource}],"has_more":true,"next_cursor":"cursor-2"})
    client.responses << %({"clients":[],"has_more":false})

    listed = client.get_tailscale_oauth_clients("p5jflp7w3zhe7bu7c4s2t4e2wq")

    expect(listed.map(&.id)).to eq ["pkdpq6yynjgjbps4otxd7il2u4"]
    expect(client.calls.map(&.[1])).to eq [
      "teams/p5jflp7w3zhe7bu7c4s2t4e2wq/tailscale-oauth-clients?order_field=id",
      "teams/p5jflp7w3zhe7bu7c4s2t4e2wq/tailscale-oauth-clients?order_field=id&cursor=cursor-2",
    ]
    expect(client.calls.map(&.[0])).to eq ["GET", "GET"]
  end

  it "deletes a Tailscale OAuth client by team and id" do
    client.responses << resource

    destroyed = client.destroy_tailscale_oauth_client(
      "p5jflp7w3zhe7bu7c4s2t4e2wq",
      "pkdpq6yynjgjbps4otxd7il2u4",
    )

    expect(destroyed.id).to eq "pkdpq6yynjgjbps4otxd7il2u4"
    method, path, body = client.calls.first
    expect(method).to eq "DELETE"
    expect(path).to eq "teams/p5jflp7w3zhe7bu7c4s2t4e2wq/tailscale-oauth-clients/pkdpq6yynjgjbps4otxd7il2u4"
    expect(body).to be_nil
  end
end
