require "../spec_helper"

Spectator.describe PeeringCreate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(network) { Factory.network }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.network_id = network.id
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.platform = "aws"
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.aws_account_id = "abc"
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.aws_vpc_id = "abc"
      expect(&.validate).to be_true
    end

    it "ensures aws parameters" do
      action.network_id = network.id
      action.platform = "aws"
      action.aws_account_id = "0123456789"
      action.aws_vpc_id = "vpc-12345"

      action.gcp_project_id = "gcp-project"
      expect(&.validate).to raise_error Program::Error, /Cannot use '--gcp-project-id'/

      action.gcp_project_id = nil
      action.gcp_vpc_name = "gcp-vpc"
      expect(&.validate).to raise_error Program::Error, /Cannot use '--gcp-project-id'/
    end

    it "ensure gcp parameters" do
      action.network_id = network.id
      action.platform = "gcp"
      action.gcp_project_id = "gcp-project"
      action.gcp_vpc_name = "gcp-vpc"

      action.aws_account_id = "0123456789"
      expect(&.validate).to raise_error Program::Error, /Cannot use '--aws-account-id'/

      action.aws_account_id = nil
      action.aws_vpc_id = "vpc-12345"
      expect(&.validate).to raise_error Program::Error, /Cannot use '--aws-account-id'/
    end
  end

  describe "#call" do
    before_each {
      action.output.flush
      action.network_id = network.id
      action.platform = "aws"
      action.aws_account_id = "aws123"
      action.aws_vpc_id = "vpc123"

      expect(client).to receive(:get_network).and_return network
      expect(client).to receive(:create_peering).and_return Factory.peering
    }

    it "outputs table with header" do
      action.call

      expected = <<-EXPECTED
        ID                           Name              Network ID                                            Peer ID                                               CIDR          Status
        yydi4alkebgsfldibaoo4kliii   Example Peering   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   10.0.0.0/24   active
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs table without header" do
      action.no_header = true
      action.call

      expected = <<-EXPECTED
          yydi4alkebgsfldibaoo4kliii   Example Peering   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   10.0.0.0/24   active
        EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs json" do
      action.format = Format::JSON
      action.call

      expected = <<-EXPECTED
      {
        "peerings": [
          {
            "id": "yydi4alkebgsfldibaoo4kliii",
            "cidr4": "10.0.0.0/24",
            "name": "Example Peering",
            "network_id": "oap3kavluvgm7cwtzgaaixzfoi",
            "network_identifier": "arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789",
            "peer_identifier": "arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789",
            "status": "active"
          }
        ]
      }
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs list" do
      action.format = Format::List
      action.call

      expected = <<-EXPECTED
      -- Peering #1 --
        ID:           yydi4alkebgsfldibaoo4kliii
        Name:         Example Peering
        Network ID:   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789
        Peer ID:      arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789
        CIDR:         10.0.0.0/24
        Status:       active
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end
  end

  describe "#make_peer_identifier" do
    it "generates AWS ARN" do
      action.platform = "aws"
      action.aws_account_id = "0123456789"
      action.aws_vpc_id = "vcp-12345"

      expect(client).to receive(:get_network).and_return network

      expect(&.make_peer_identifier).to eq "arn:aws:ec2:us-east-1:0123456789:vpc/vcp-12345"
    end

    it "generates GCP URL" do
      action.platform = "gcp"
      action.gcp_project_id = "0123456789"
      action.gcp_vpc_name = "example-vpc"

      expect(&.make_peer_identifier).to eq "https://www.googleapis.com/compute/v1/projects/0123456789/global/networks/example-vpc"
    end
  end
end

Spectator.describe PeeringDelete do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(network) { Factory.network }
  let(peering) { Factory.peering }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.network_id = network.id
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.peering_id = peering.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each {
      action.output = IO::Memory.new
      action.network_id = network.id
      action.peering_id = peering.id

      expect(client).to receive(:delete_peering).and_return peering
    }

    it "outputs table with header" do
      action.call

      expected = <<-EXPECTED
          ID                           Name              Network ID                                            Peer ID                                               CIDR          Status
          yydi4alkebgsfldibaoo4kliii   Example Peering   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   10.0.0.0/24   active
        EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs table without header" do
      action.no_header = true
      action.call

      expected = <<-EXPECTED
            yydi4alkebgsfldibaoo4kliii   Example Peering   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   10.0.0.0/24   active
          EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs json" do
      action.format = Format::JSON
      action.call

      expected = <<-EXPECTED
        {
          "peerings": [
            {
              "id": "yydi4alkebgsfldibaoo4kliii",
              "cidr4": "10.0.0.0/24",
              "name": "Example Peering",
              "network_id": "oap3kavluvgm7cwtzgaaixzfoi",
              "network_identifier": "arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789",
              "peer_identifier": "arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789",
              "status": "active"
            }
          ]
        }
        EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs list" do
      action.format = Format::List
      action.call

      expected = <<-EXPECTED
        -- Peering #1 --
          ID:           yydi4alkebgsfldibaoo4kliii
          Name:         Example Peering
          Network ID:   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789
          Peer ID:      arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789
          CIDR:         10.0.0.0/24
          Status:       active
        EXPECTED

      expect(&.output.to_s).to look_like expected
    end
  end
end

Spectator.describe PeeringGet do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(network) { Factory.network }
  let(peering) { Factory.peering }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.network_id = network.id
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.peering_id = peering.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each {
      action.output = IO::Memory.new
      action.network_id = network.id
      action.peering_id = peering.id

      expect(client).to receive(:get_peering).and_return peering
    }

    it "outputs table with header" do
      action.call

      expected = <<-EXPECTED
            ID                           Name              Network ID                                            Peer ID                                               CIDR          Status
            yydi4alkebgsfldibaoo4kliii   Example Peering   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   10.0.0.0/24   active
          EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs table without header" do
      action.no_header = true
      action.call

      expected = <<-EXPECTED
              yydi4alkebgsfldibaoo4kliii   Example Peering   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   10.0.0.0/24   active
            EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs json" do
      action.format = Format::JSON
      action.call

      expected = <<-EXPECTED
      {
        "peerings": [
          {
            "id": "yydi4alkebgsfldibaoo4kliii",
            "cidr4": "10.0.0.0/24",
            "name": "Example Peering",
            "network_id": "oap3kavluvgm7cwtzgaaixzfoi",
            "network_identifier": "arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789",
            "peer_identifier": "arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789",
            "status": "active"
          }
        ]
      }
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs list" do
      action.format = Format::List
      action.call

      expected = <<-EXPECTED
        -- Peering #1 --
        ID:           yydi4alkebgsfldibaoo4kliii
        Name:         Example Peering
        Network ID:   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789
        Peer ID:      arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789
        CIDR:         10.0.0.0/24
        Status:       active
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end
  end
end

Spectator.describe PeeringList do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(network) { Factory.network }
  let(peering) { Factory.peering }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.network_id = network.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each {
      action.output = IO::Memory.new
      action.network_id = network.id

      expect(client).to receive(:list_peerings).and_return [peering]
    }

    it "outputs table with header" do
      action.call

      expected = <<-EXPECTED
        ID                           Name              Network ID                                            Peer ID                                               CIDR          Status
        yydi4alkebgsfldibaoo4kliii   Example Peering   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   10.0.0.0/24   active
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs table without header" do
      action.no_header = true
      action.call

      expected = <<-EXPECTED
        yydi4alkebgsfldibaoo4kliii   Example Peering   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789   10.0.0.0/24   active
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs json" do
      action.format = Format::JSON
      action.call

      expected = <<-EXPECTED
      {
        "peerings": [
          {
            "id": "yydi4alkebgsfldibaoo4kliii",
            "cidr4": "10.0.0.0/24",
            "name": "Example Peering",
            "network_id": "oap3kavluvgm7cwtzgaaixzfoi",
            "network_identifier": "arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789",
            "peer_identifier": "arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789",
            "status": "active"
          }
        ]
      }
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs list" do
      action.format = Format::List
      action.call

      expected = <<-EXPECTED
        -- Peering #1 --
        ID:           yydi4alkebgsfldibaoo4kliii
        Name:         Example Peering
        Network ID:   arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789
        Peer ID:      arn:aws:ec2:us-east-1:0123456789:vpc/vpc-0123456789
        CIDR:         10.0.0.0/24
        Status:       active
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end
  end
end
