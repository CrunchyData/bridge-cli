require "../spec_helper"

Spectator.describe ConfigurationParameterGet do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(client) { Client.new TEST_TOKEN }
  let(cluster) { Factory.cluster }

  mock_client

  describe "#validate" do
    it "validates that required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = cluster.id

      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each {
      action.cluster_id = cluster.id
    }

    it "gets by name" do
      action.name = "postgres:max_connections"

      expect(client).to receive(:get_configuration_parameter).and_return(Factory.configuration_parameter)

      action.call

      expected = <<-EXPECTED
        Component   Name              Value  
      ───────────────────────────────────────
        postgres    max_connections   100    \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs default format" do
      expect(client).to receive(:get_all_configuration_parameters).and_return([Factory.configuration_parameter, Factory.configuration_parameter])

      action.call

      expected = <<-EXPECTED
        Component   Name              Value  
      ───────────────────────────────────────
        postgres    max_connections   100    
        postgres    max_connections   100    \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs json format" do
      action.format = Format::JSON

      expect(client).to receive(:get_all_configuration_parameters).and_return([Factory.configuration_parameter])

      action.call

      expected = <<-EXPECTED
      {
        "parameters": [
          {
            "component": "postgres",
            "name": "postgres:max_connections",
            "parameter_name": "max_connections",
            "value": "100"
          }
        ]
      }\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end

Spectator.describe ConfigurationParameterSet do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(client) { Client.new TEST_TOKEN }
  let(cluster) { Factory.cluster }

  mock_client

  describe "#call" do
    before_each {
      action.args = ["postgres:max_connections=100"]
      action.cluster_id = cluster.id
    }

    it "outputs default" do
      expect(client).to receive(:set_configuration_parameters).and_return [Factory.configuration_parameter]

      action.call

      expected = <<-EXPECTED
        Component   Name              Value  
      ───────────────────────────────────────
        postgres    max_connections   100    \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs json format" do
      action.format = Format::JSON

      expect(client).to receive(:set_configuration_parameters).and_return([Factory.configuration_parameter])

      action.call

      expected = <<-EXPECTED
        {
          "parameters": [
            {
              "component": "postgres",
              "name": "postgres:max_connections",
              "parameter_name": "max_connections",
              "value": "100"
            }
          ]
        }\n
        EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end

Spectator.describe ConfigurationParameterReset do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(client) { Client.new TEST_TOKEN }
  let(cluster) { Factory.cluster }

  mock_client

  describe "#call" do
    before_each {
      action.cluster_id = cluster.id
    }

    it "resets single parameters" do
      action.name = "postgres:max_connections"

      expect(client).to receive(:reset_configuration_parameter).and_return Factory.configuration_parameter

      action.call

      expected = <<-EXPECTED
        Component   Name              Value  
      ───────────────────────────────────────
        postgres    max_connections   100    \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs default" do
      expect(client).to receive(:reset_all_configuration_parameters).and_return [Factory.configuration_parameter]

      action.call

      expected = <<-EXPECTED
        Component   Name              Value  
      ───────────────────────────────────────
        postgres    max_connections   100    \n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "outputs json format" do
      action.format = Format::JSON

      expect(client).to receive(:reset_all_configuration_parameters).and_return([Factory.configuration_parameter])

      action.call

      expected = <<-EXPECTED
        {
          "parameters": [
            {
              "component": "postgres",
              "name": "postgres:max_connections",
              "parameter_name": "max_connections",
              "value": "100"
            }
          ]
        }\n
        EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end
