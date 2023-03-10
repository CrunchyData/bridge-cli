require "../spec_helper"

Spectator.describe TeamCreate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(team) { Factory.team }

  describe "#validate" do
    it "ensures required arguments are presents" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.name = team.name
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each {
      action.name = team.name
      expect(client).to receive(:create_team).and_return team
    }

    it "confirms team created (default output)" do
      action.call
      expect(&.output.to_s).to eq "Created team #{team.id} (#{team.name})\n"
    end

    it "outputs json" do
      action.format = Format::JSON
      action.call

      expected = <<-EXPECTED
      {
        "id": "l2gnkxjv3beifk6abkraerv7de",
        "name": "Test Team",
        "is_personal": false,
        "role": "admin",
        "enforce_sso": false,
        "billing_email": "test@example.com"
      }\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "raises invalid output format error" do
      action.format = Format::Table
      expect(&.call).to raise_error Program::Error, /Invalid format: table/
    end
  end
end

Spectator.describe TeamDestroy do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(team) { Factory.team }

  describe "#validate" do
    it "ensures required arguments are presents" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.team_id = team.id
      expect(&.validate).to be_true
    end
  end
end

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
        Enforce SSO:     disabled                    \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs as json" do
    end
  end
end

Spectator.describe TeamList do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(team) { Factory.team }

  describe "#call" do
    before_each {
      expect(client).to receive(:get_teams).and_return [team]
    }

    it "outputs table" do
      action.call

      expected = <<-EXPECTED
        ID                           Name        Role    Billing Email      Enforce SSO  
        l2gnkxjv3beifk6abkraerv7de   Test Team   Admin   test@example.com   disabled     \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs table without header" do
      action.show_header = false
      action.call

      expected = <<-EXPECTED
        l2gnkxjv3beifk6abkraerv7de   Test Team   Admin   test@example.com   disabled  \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs json" do
      action.format = Format::JSON
      action.call

      expected = <<-EXPECTED
      {
        "teams": [
          {
            "id": "l2gnkxjv3beifk6abkraerv7de",
            "name": "Test Team",
            "is_personal": false,
            "role": "admin",
            "enforce_sso": false,
            "billing_email": "test@example.com"
          }
        ]
      }\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end

Spectator.describe TeamUpdate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(team) { Factory.team }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.team_id = team.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each {
      action.team_id = team.id
      action.confirmed = true
      action.enforce_sso = true

      expect(client).to receive(:update_team).and_return Factory.team(**{"enforce_sso": true})
    }

    it "outputs list" do
      action.call

      expected = <<-EXPECTED
        ID:              l2gnkxjv3beifk6abkraerv7de  
        Name:            Test Team                   
        Role:            Admin                       
        Billing Email:   test@example.com            
        Enforce SSO:     enabled                     \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs table" do
      action.format = Format::Table
      action.call

      expected = <<-EXPECTED
        ID                           Name        Role    Billing Email      Enforce SSO  
        l2gnkxjv3beifk6abkraerv7de   Test Team   Admin   test@example.com   enabled      \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs table without header" do
      action.format = Format::Table
      action.show_header = false
      action.call

      expected = <<-EXPECTED
        l2gnkxjv3beifk6abkraerv7de   Test Team   Admin   test@example.com   enabled  \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs json" do
      action.format = Format::JSON
      action.call

      expected = <<-EXPECTED
      {
        "id": "l2gnkxjv3beifk6abkraerv7de",
        "name": "Test Team",
        "is_personal": false,
        "role": "admin",
        "enforce_sso": true,
        "billing_email": "test@example.com"
      }\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end
