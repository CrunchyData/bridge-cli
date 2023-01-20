require "../spec_helper"

Spectator.describe CB::UpgradeStart do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(cluster) { Factory.cluster }

  it "validates that required arguments are present" do
    expect_missing_arg_error

    action.cluster_id = cluster.id
    action.validate.should eq true
  end

  it "#run prints cluster upgrade started" do
    action.cluster_id = cluster.id
    action.confirmed = true

    expect(client).to receive(:get_cluster).and_return(cluster)
    expect(client).to receive(:upgrade_cluster).and_return([] of CB::Client::Operation)

    action.call

    expect(&.output.to_s).to eq "  Cluster #{action.cluster_id} upgrade started.\n"
  end
end

Spectator.describe CB::UpgradeMaintenanceCreate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(cluster) { Factory.cluster }

  mock_client

  describe "#validate" do
    it "raises if non-mainennace options are set" do
      action.cluster_id = cluster.id
      action.postgres_version = 14
      expect {
        action.validate
      }.to raise_error Program::Error, "Maintenance can't change ha, postgres_version or storage."
    end
  end

  describe "#run" do
    it "makes an api call" do
      action.cluster_id = cluster.id
      action.now = true
      action.confirmed = true

      expect(client).to receive(:get_cluster).and_return(cluster)
      expect(client).to receive(:upgrade_cluster).and_return([] of CB::Client::Operation)

      action.call

      expect(&.output.to_s).to eq "  Maintenance created for Cluster #{action.cluster_id}.\n"
    end
  end
end

Spectator.describe CB::UpgradeStatus do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(cluster) { Factory.cluster }
  let(team) { Factory.team }

  it "validates that required arguments are present" do
    expect_missing_arg_error

    action.cluster_id = cluster.id
    action.validate.should eq true
  end

  it "#run no upgrades" do
    action.cluster_id = cluster.id

    expect(client).to receive(:get_cluster).and_return(cluster)
    expect(client).to receive(:get_team).and_return(team)
    expect(client).to receive(:upgrade_cluster_status).and_return([] of CB::Client::Operation)

    action.call

    expected = <<-EXPECTED
    #{team.name}/#{cluster.name}
      no operations in progress
      maintenance window: no window set. Default to: 00:00-23:59\n
    EXPECTED

    expect(&.output.to_s).to eq expected
  end

  it "#run display ha operation by default" do
    action.cluster_id = cluster.id

    expect(client).to receive(:get_cluster).and_return(cluster)
    expect(client).to receive(:get_team).and_return(team)
    expect(client).to receive(:upgrade_cluster_status).and_return([CB::Client::Operation.new("ha_change", "fake", nil)])

    action.call

    expected = <<-EXPECTED
    #{team.name}/#{cluster.name}
      maintenance window: no window set. Default to: 00:00-23:59
               ha_change: fake\n
    EXPECTED

    expect(&.output.to_s).to eq expected
  end

  it "#run display failover windown starting if there is one" do
    action.cluster_id = cluster.id

    expect(client).to receive(:get_cluster).and_return(cluster)
    expect(client).to receive(:get_team).and_return(team)
    expect(client).to receive(:upgrade_cluster_status).and_return([CB::Client::Operation.new("resize", "fake", "2022-01-01T00:00:00Z")])

    action.call

    expected = <<-EXPECTED
  #{team.name}/#{cluster.name}
    maintenance window: no window set. Default to: 00:00-23:59
                resize: fake (Starting from: 2022-01-01T00:00:00Z)\n
  EXPECTED

    expect(&.output.to_s).to eq expected
  end

  it "#run filter ha operation if told so" do
    action.cluster_id = cluster.id
    action.maintenance_only = true

    expect(client).to receive(:get_cluster).and_return(cluster)
    expect(client).to receive(:get_team).and_return(team)
    expect(client).to receive(:upgrade_cluster_status).and_return([CB::Client::Operation.new("ha_change", "fake", nil)])

    action.call

    expected = <<-EXPECTED
    #{team.name}/#{cluster.name}
      no maintenance operations in progress
      maintenance window: no window set. Default to: 00:00-23:59\n
    EXPECTED

    expect(&.output.to_s).to eq expected
  end
end

Spectator.describe CB::UpgradeCancel do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(cluster) { Factory.cluster }
  let(team) { Factory.team }

  it "validates that required arguments are present" do
    expect_missing_arg_error
    action.cluster_id = cluster.id
    action.validate.should eq true
  end

  it "#run " do
    action.cluster_id = cluster.id

    expect(client).to receive(:get_cluster).and_return(cluster)
    expect(client).to receive(:get_team).and_return(team)
    expect(client).to receive(:upgrade_cluster_cancel).and_return(HTTP::Client::Response.new(204))

    action.call

    expected = <<-EXPECTED
    #{team.name}/#{cluster.name}
      operation cancelled\n
    EXPECTED

    expect(&.output.to_s).to eq expected
  end
end
