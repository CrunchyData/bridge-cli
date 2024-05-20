require "../spec_helper"

Spectator.describe FirewallRuleAdd do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(network) { Factory.network }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.network_id = network.id
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.rule = "0.0.0.0/0"
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each {
      action.output = IO::Memory.new
      action.network_id = network.id
      action.rule = Factory.firewall_rule.rule

      expect(client).to receive(:create_firewall_rule).and_return Factory.firewall_rule
    }

    it "outputs table with header" do
      action.call

      expected = <<-EXPECTED
        ID                           Rule         Description
        shofthj3fzaipie44lt6a5i3de   1.2.3.0/24   Example Description
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs table without header" do
      action.no_header = true
      action.call

      expected = <<-EXPECTED
        shofthj3fzaipie44lt6a5i3de   1.2.3.0/24   Example Description
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs json" do
      action.format = Format::JSON
      action.call

      expected = <<-EXPECTED
      {
        "firewall_rules": [
          {
            "id": "shofthj3fzaipie44lt6a5i3de",
            "description": "Example Description",
            "rule": "1.2.3.0/24"
          }
        ]
      }
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end
  end
end

Spectator.describe FirewallRuleList do
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
    before_each {
      action.output = IO::Memory.new
      action.network_id = network.id

      expect(client).to receive(:get_firewall_rules).and_return [Factory.firewall_rule]
    }

    it "outputs table with header" do
      action.call

      expected = <<-EXPECTED
        ID                           Rule         Description
        shofthj3fzaipie44lt6a5i3de   1.2.3.0/24   Example Description
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs table without header" do
      action.no_header = true
      action.call

      expected = <<-EXPECTED
        shofthj3fzaipie44lt6a5i3de   1.2.3.0/24   Example Description
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs json" do
      action.format = Format::JSON
      action.call

      expected = <<-EXPECTED
      {
        "firewall_rules": [
          {
            "id": "shofthj3fzaipie44lt6a5i3de",
            "description": "Example Description",
            "rule": "1.2.3.0/24"
          }
        ]
      }
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end
  end
end

Spectator.describe FirewallRuleRemove do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(network) { Factory.network }
  let(firewall_rule) { Factory.firewall_rule }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.network_id = network.id
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.firewall_rule_id = firewall_rule.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each {
      action.output = IO::Memory.new
      action.network_id = network.id
      action.firewall_rule_id = firewall_rule.id

      expect(client).to receive(:destroy_firewall_rule).and_return Factory.firewall_rule
    }

    it "outputs table with header" do
      action.call

      expected = <<-EXPECTED
        ID                           Rule         Description
        shofthj3fzaipie44lt6a5i3de   1.2.3.0/24   Example Description
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs table without header" do
      action.no_header = true
      action.call

      expected = <<-EXPECTED
        shofthj3fzaipie44lt6a5i3de   1.2.3.0/24   Example Description
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs json" do
      action.format = Format::JSON
      action.call

      expected = <<-EXPECTED
      {
        "firewall_rules": [
          {
            "id": "shofthj3fzaipie44lt6a5i3de",
            "description": "Example Description",
            "rule": "1.2.3.0/24"
          }
        ]
      }
      EXPECTED

      expect(&.output.to_s).to look_like expected
    end
  end
end

Spectator.describe FirewallRuleUpdate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(network) { Factory.network }
  let(firewall_rule) { Factory.firewall_rule }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.network_id = network.id
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.firewall_rule_id = firewall_rule.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each {
      action.output = IO::Memory.new
      action.network_id = network.id
      action.firewall_rule_id = firewall_rule.id
      action.rule = Factory.firewall_rule.rule

      expect(client).to receive(:update_firewall_rule).and_return Factory.firewall_rule
    }

    it "outputs table with header" do
      action.call

      expected = <<-EXPECTED
      ID                           Rule         Description
      shofthj3fzaipie44lt6a5i3de   1.2.3.0/24   Example Description
    EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs table without header" do
      action.no_header = true
      action.call

      expected = <<-EXPECTED
      shofthj3fzaipie44lt6a5i3de   1.2.3.0/24   Example Description
    EXPECTED

      expect(&.output.to_s).to look_like expected
    end

    it "outputs json" do
      action.format = Format::JSON
      action.call

      expected = <<-EXPECTED
    {
      "firewall_rules": [
        {
          "id": "shofthj3fzaipie44lt6a5i3de",
          "description": "Example Description",
          "rule": "1.2.3.0/24"
        }
      ]
    }
    EXPECTED

      expect(&.output.to_s).to look_like expected
    end
  end
end
