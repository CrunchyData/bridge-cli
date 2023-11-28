require "../spec_helper"

Spectator.describe TeamInfo do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(team) { Factory.team }

  describe "#call" do
    it "outputs as list" do
      action.team_id = team.id

      expect(client).to receive(:get_team).and_return team

      action.call

      expected = <<-EXPECTED
        ID:              l2gnkxjv3beifk6abkraerv7de
        Name:            Test Team
        Role:            Admin
        Billing Email:   test@example.com
        Enforce SSO:     disabled
      EXPECTED

      expect(&.output).to look_like expected
    end
  end
end
