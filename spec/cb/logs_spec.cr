require "../spec_helper"

Spectator.describe CB::Logs do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(client) { Client.new TEST_TOKEN }
  let(cluster) { Factory.cluster }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = cluster.id
      expect(&.validate).to be_true
    end
  end

  describe "#call", skip: "Not implemented yet" do
    # TODO (abrightwell): Testing #call for this action requires a considerable
    # amount of mocking and adavanced setup given the call out to SSH2 libs and
    # the nature of those. Also, before taking that on, it would be nice to update
    # Spectator to the latest version. So, as to not make this changeset any
    # noiser than necessary, we'll follow up on this one in a future PR.
  end
end
