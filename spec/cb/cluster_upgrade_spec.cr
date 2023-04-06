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
    expect(client).to receive(:upgrade_cluster).and_return([] of CB::Model::Operation)

    action.call

    expect(&.output.to_s).to eq "  Cluster #{action.cluster_id} upgrade started.\n"
  end
end

Spectator.describe CB::MaintenanceCreate do
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
      expect(client).to receive(:upgrade_cluster).and_return([] of CB::Model::Operation)

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
    expect(client).to receive(:upgrade_cluster_status).and_return([] of CB::Model::Operation)

    action.call

    expected = <<-EXPECTED
    #{team.name}/#{cluster.name}
      operations:           no operations in progress               
      maintenance window:   no window set. Default to: 00:00-23:59  \n
    EXPECTED

    expect(&.output.to_s).to eq expected
  end

  it "#run display ha operation by default" do
    action.cluster_id = cluster.id

    expect(client).to receive(:get_cluster).and_return(cluster)
    expect(client).to receive(:get_team).and_return(team)
    expect(client).to receive(:upgrade_cluster_status).and_return([Factory.operation(flavor: CB::Model::Operation::Flavor::HAChange)])

    action.call

    expected = <<-EXPECTED
    #{team.name}/#{cluster.name}
      ha change:            in progress                             
      maintenance window:   no window set. Default to: 00:00-23:59  \n
    EXPECTED

    expect(&.output.to_s).to eq expected
  end

  it "#run display failover windown starting if there is one" do
    action.cluster_id = cluster.id

    expect(client).to receive(:get_cluster).and_return(cluster)
    expect(client).to receive(:get_team).and_return(team)
    expect(client).to receive(:upgrade_cluster_status).and_return([Factory.operation(starting_from: "2022-01-01T00:00:00Z")])

    action.call

    expected = <<-EXPECTED
    #{team.name}/#{cluster.name}
      resize:               in progress (Starting from: 2022-01-01T00:00:00Z)  
      maintenance window:   no window set. Default to: 00:00-23:59             \n
    EXPECTED

    expect(&.output.to_s).to eq expected
  end

  it "#run filter ha operation if told so" do
    action.cluster_id = cluster.id
    action.maintenance_only = true

    expect(client).to receive(:get_cluster).and_return(cluster)
    expect(client).to receive(:get_team).and_return(team)
    expect(client).to receive(:upgrade_cluster_status).and_return([] of CB::Model::Operation)

    action.call

    expected = <<-EXPECTED
    #{team.name}/#{cluster.name}
      operations:           no operations in progress               
      maintenance window:   no window set. Default to: 00:00-23:59  \n
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
  describe "#run" do
    it "does not cancel maintenance" do
      action.cluster_id = cluster.id

      expect(client).to receive(:get_cluster).and_return(cluster)
      expect(client).to receive(:get_team).and_return(team)
      expect(client).to receive(:upgrade_cluster_status).and_return([Factory.operation(flavor: CB::Model::Operation::Flavor::Maintenance)])

      action.call

      expected = <<-EXPECTED
      #{team.name}/#{cluster.name}
        there is no pending operation.
        use 'cb maintenance cancel' to cancel the pending maintenance.\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "cancel other operations" do
      action.cluster_id = cluster.id

      expect(client).to receive(:get_cluster).and_return(cluster)
      expect(client).to receive(:get_team).and_return(team)
      expect(client).to receive(:upgrade_cluster_status).and_return([Factory.operation(flavor: CB::Model::Operation::Flavor::Resize)])
      expect(client).to receive(:upgrade_cluster_cancel).and_return(HTTP::Client::Response.new(204))

      action.call

      expected = <<-EXPECTED
      #{team.name}/#{cluster.name}
        resize operation cancelled\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end

Spectator.describe CB::MaintenanceCancel do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(cluster) { Factory.cluster }
  let(team) { Factory.team }

  it "validates that required arguments are present" do
    expect_missing_arg_error
    action.cluster_id = cluster.id
    action.validate.should eq true
  end

  describe "#run" do
    it "does not cancel resize" do
      action.cluster_id = cluster.id

      expect(client).to receive(:get_cluster).and_return(cluster)
      expect(client).to receive(:get_team).and_return(team)
      expect(client).to receive(:upgrade_cluster_status).and_return([Factory.operation(flavor: CB::Model::Operation::Flavor::Resize)])

      action.call

      expected = <<-EXPECTED
      #{team.name}/#{cluster.name}
        there is no pending maintenance.
        use 'cb upgrade cancel' to cancel the pending resize.\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "cancels maintenance" do
      action.cluster_id = cluster.id

      expect(client).to receive(:get_cluster).and_return(cluster)
      expect(client).to receive(:get_team).and_return(team)
      expect(client).to receive(:upgrade_cluster_status).and_return([Factory.operation(flavor: CB::Model::Operation::Flavor::Maintenance)])
      expect(client).to receive(:upgrade_cluster_cancel).and_return(HTTP::Client::Response.new(204))

      action.call

      expected = <<-EXPECTED
      #{team.name}/#{cluster.name}
        maintenance operation cancelled\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end

Spectator.describe CB::MaintenanceUpdate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(cluster) { Factory.cluster }
  let(team) { Factory.team }

  it "validates that required arguments are present" do
    expect_missing_arg_error
    action.cluster_id = cluster.id
    action.validate.should eq true
  end

  describe "#run" do
    it "does not update resize" do
      action.cluster_id = cluster.id
      action.confirmed = true

      expect(client).to receive(:get_cluster).and_return(cluster)
      expect(client).to receive(:get_team).and_return(team)
      expect(client).to receive(:upgrade_cluster_status).and_return([Factory.operation(flavor: CB::Model::Operation::Flavor::Resize)])

      action.call

      expected = <<-EXPECTED
      #{team.name}/#{cluster.name}
        there is no pending maintenance.
        use 'cb upgrade update' to update the pending resize.\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "updates maintenance" do
      action.cluster_id = cluster.id
      action.confirmed = true
      action.now = true

      expect(client).to receive(:get_cluster).and_return(cluster)
      expect(client).to receive(:get_team).and_return(team)
      expect(client).to receive(:upgrade_cluster_status).and_return([Factory.operation(flavor: CB::Model::Operation::Flavor::Maintenance)])
      expect(client).to receive(:update_upgrade_cluster).and_return([Factory.operation(flavor: CB::Model::Operation::Flavor::Maintenance)])

      action.call

      expected = <<-EXPECTED
      #{team.name}/#{cluster.name}
        maintenance updated.\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end

Spectator.describe CB::UpgradeUpdate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(cluster) { Factory.cluster }
  let(team) { Factory.team }

  describe "#run" do
    it "does not update maintenance" do
      action.cluster_id = cluster.id
      action.confirmed = true

      expect(client).to receive(:get_cluster).and_return(cluster)
      expect(client).to receive(:get_team).and_return(team)
      expect(client).to receive(:upgrade_cluster_status).and_return([Factory.operation(flavor: CB::Model::Operation::Flavor::Maintenance)])

      action.call

      expected = <<-EXPECTED
      #{team.name}/#{cluster.name}
        there is no pending upgrade.
        use 'cb maintenance update' to update the pending maintenance.\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end

    it "updates resize" do
      action.cluster_id = cluster.id
      action.confirmed = true
      action.now = true

      expect(client).to receive(:get_cluster).and_return(cluster)
      expect(client).to receive(:get_team).and_return(team)
      expect(client).to receive(:upgrade_cluster_status).and_return([Factory.operation(flavor: CB::Model::Operation::Flavor::Resize)])
      expect(client).to receive(:update_upgrade_cluster).and_return([Factory.operation(flavor: CB::Model::Operation::Flavor::Resize)])

      action.call

      expected = <<-EXPECTED
      #{team.name}/#{cluster.name}
        upgrade updated.\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end
