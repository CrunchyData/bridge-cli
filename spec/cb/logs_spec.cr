require "../spec_helper"

Spectator.describe CB::Logs do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(cluster) { Factory.cluster }

  describe "#validate" do
    it "ensures required arguments are present" do
      expect(&.validate).to raise_error Program::Error, /Missing required argument/

      action.cluster_id = cluster.id
      expect(&.validate).to be_true
    end
  end

  describe "#call" do
    # TODO (abrightwell): Testing #call for this action requires a considerable
    # amount of mocking and adavanced setup given the call out to SSH2 libs and
    # the nature of those. Also, before taking that on, it would be nice to update
    # Spectator to the latest version. So, as to not make this changeset any
    # noiser than necessary, we'll follow up on this one in a future PR.

    it "reraises error from tempkey" do
      action.cluster_id = cluster.id
      expect(client).to receive(:get_tempkey).and_raise(CB::Client::Error.new("method", "path", HTTP::Client::Response.new(403)))

      expect_raises(CB::Client::Error) do
        action.call
      end
    end
  end
end
