require "../spec_helper"

Spectator.describe NetworkInfo do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(network) { Factory.network }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.network_id = network.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
  end
end

Spectator.describe NetworkList do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(networks) { [Factory.network] }
  let(team) { Factory.team }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to be_true

      action.team_id = team.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each {
      action.output = IO::Memory.new
      action.team_id = team.id

      expect(client).to receive(:get_networks).and_return networks
    }

    it "outputs table with header" do
      action.call

      expected = <<-EXPECTED
        ID                           Team                         Name              CIDR4            Provider   Region     
        oap3kavluvgm7cwtzgaaixzfoi   l2gnkxjv3beifk6abkraerv7de   Default Network   192.168.0.0/24   aws        us-east-1  \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs table without header" do
      action.no_header = true
      action.call

      expected = <<-EXPECTED
        oap3kavluvgm7cwtzgaaixzfoi   l2gnkxjv3beifk6abkraerv7de   Default Network   192.168.0.0/24   aws   us-east-1  \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs json" do
      action.format = Format::JSON
      action.call

      expected = <<-EXPECTED
      {
        "networks": [
          {
            "cidr4": "192.168.0.0/24",
            "id": "oap3kavluvgm7cwtzgaaixzfoi",
            "name": "Default Network",
            "provider_id": "aws",
            "region_id": "us-east-1",
            "team_id": "l2gnkxjv3beifk6abkraerv7de"
          }
        ]
      }\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end
