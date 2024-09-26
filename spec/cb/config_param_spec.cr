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
      action.args = ["postgres:max_connections"]

      expect(client).to receive(:get_configuration_parameter).and_return(Factory.configuration_parameter)

      action.call

      expected = <<-EXPECTED
        Component   Name              Value
        postgres    max_connections   100
      EXPECTED

      expect(&.output).to look_like expected
    end

    it "lists no parameters when none are set" do
      expect(client).to receive(:list_configuration_parameters).and_return([] of CB::Model::ConfigurationParameter)

      action.call

      expected = <<-EXPECTED
        Component   Name   Value
      EXPECTED

      expect(&.output).to look_like expected
    end

    it "outputs default format" do
      expect(client).to receive(:list_configuration_parameters).and_return([Factory.configuration_parameter, Factory.configuration_parameter])

      action.call

      expected = <<-EXPECTED
        Component   Name              Value
        postgres    max_connections   100
        postgres    max_connections   100
      EXPECTED

      expect(&.output).to look_like expected
    end

    it "outputs json format" do
      action.format = Format::JSON

      expect(client).to receive(:list_configuration_parameters).and_return([Factory.configuration_parameter])

      action.call

      expected = <<-EXPECTED
      {
        "parameters": [
          {
            "component": "postgres",
            "enum": [],
            "min_value": "100",
            "max_value": "2000",
            "name": "postgres:max_connections",
            "parameter_name": "max_connections",
            "requires_restart": false,
            "value": "100"
          }
        ]
      }
      EXPECTED

      expect(&.output).to look_like expected
    end
  end
end

Spectator.describe ConfigurationParameterListSupported do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(client) { Client.new TEST_TOKEN }
  let(cluster) { Factory.cluster }

  mock_client

  describe "#call" do
    before_each {
      expect(client).to receive(:list_supported_configuration_parameters).and_return [
        Factory.configuration_parameter(value: nil),
        Factory.configuration_parameter(
          component: "pgbouncer",
          name: "pgbouncer:auth_type",
          parameter_name: "auth_type",
          value: nil,
          min_value: nil,
          max_value: nil,
          enum: ["cert", "md5", "trust"]
        ),
        Factory.configuration_parameter(
          component: "pgbouncer",
          name: "pgbouncer:fake",
          parameter_name: "fake",
          value: nil,
          min_value: nil,
          max_value: nil,
          enum: [] of String
        ),
      ]
    }

    it "outputs all" do
      action.call

      expected = <<-EXPECTED
        Component   Name              Requires Restart   Constraints
        postgres    max_connections   no                 min: 100, max: 2000
        pgbouncer   auth_type         no                 enum: cert, md5, trust
        pgbouncer   fake              no
      EXPECTED

      expect(&.output).to look_like expected
    end

    it "outputs specific component" do
      action.args = ["postgres"]
      action.call

      expected = <<-EXPECTED
        Component   Name              Requires Restart   Constraints
        postgres    max_connections   no                 min: 100, max: 2000
      EXPECTED

      expect(&.output).to look_like expected
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
      action.args = [
        "postgres:max_connections=100",
      ]

      action.cluster_id = cluster.id
    }

    it "outputs default" do
      expect(client).to receive(:update_configuration_parameters).and_return [Factory.configuration_parameter]

      action.call

      expected = <<-EXPECTED
        Component   Name              Value
        postgres    max_connections   100
      EXPECTED

      expect(&.output).to look_like expected
    end

    it "outputs json format" do
      action.format = Format::JSON

      expect(client).to receive(:update_configuration_parameters).and_return([Factory.configuration_parameter])

      action.call

      expected = <<-EXPECTED
        {
          "parameters": [
            {
              "component": "postgres",
              "enum": [],
              "min_value": "100",
              "max_value": "2000",
              "name": "postgres:max_connections",
              "parameter_name": "max_connections",
              "requires_restart": false,
              "value": "100"
            }
          ]
        }
        EXPECTED

      expect(&.output).to look_like expected
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

      expect(client).to receive(:update_configuration_parameters).and_return [Factory.configuration_parameter]
    }

    it "resets parameters" do
      action.args = ["postgres:max_connections"]

      action.call

      expected = <<-EXPECTED
        Component   Name              Value
        postgres    max_connections   100
      EXPECTED

      expect(&.output).to look_like expected
    end

    it "outputs default" do
      action.call

      expected = <<-EXPECTED
        Component   Name              Value
        postgres    max_connections   100
      EXPECTED

      expect(&.output).to look_like expected
    end

    it "outputs json format" do
      action.format = Format::JSON

      action.call

      expected = <<-EXPECTED
        {
          "parameters": [
            {
              "component": "postgres",
              "enum": [],
              "min_value": "100",
              "max_value": "2000",
              "name": "postgres:max_connections",
              "parameter_name": "max_connections",
              "requires_restart": false,
              "value": "100"
            }
          ]
        }
        EXPECTED

      expect(&.output).to look_like expected
    end
  end
end
