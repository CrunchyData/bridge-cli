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
      no upgrades in progress\n
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
      upgrade cancelled\n
    EXPECTED

    expect(&.output.to_s).to eq expected
  end
end
