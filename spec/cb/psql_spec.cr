require "../spec_helper"
include CB

Spectator.describe CB::Psql do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client do
    def get_team_cert(team : String)
      ""
    end
  end

  let(cluster) { Factory.cluster }
  let(role) { Factory.role_user }
  let(team) { Factory.team }

  describe "#initialize" do
    it "ensures 'default' if role not specified" do
      action.cluster_id = cluster.id
      expect(&.role.to_s).to eq "default"
    end
  end

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = cluster.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    before_each {
      # Let's not REALLY call psql.
      #
      # TODO (abrightwell): It would be nice if we didn't have to do it this
      # way. However, it's not evident to me at the time how it's possible to
      # use `expect(Process).to receive(:exec) ...` for this purpose with
      # Spectator. Something that perhaps should be followed up on in future
      # updates.
      action.psql = Proc(Enumerable(String), Process::Env, NoReturn?).new { nil }
    }

    # This test gets us through to the point at which the `psql` command is
    # called.  For obvious reasons we can't go past that, so if we can at least
    # get to the 'connecting to' message, then we can assert that things up to
    # that point have been successful and by extension the execution of the
    # command.
    it "outputs 'connecting to message'" do
      action.cluster_id = cluster.id

      expect(client).to receive(:get_cluster).and_return(cluster)
      expect(client).to receive(:get_role).and_return(role)
      expect(client).to receive(:get_team).and_return(team)

      action.call

      expected = <<-EXPECTED
      connecting to #{team.name}/#{cluster.name}\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end
