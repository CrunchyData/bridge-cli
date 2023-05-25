require "../spec_helper"

Spectator.describe Token do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  describe "#validate" do
    it "raises error on conflicting options" do
      action.with_header = true
      action.format = CB::Format::Header

      expect(&.validate).to raise_error
    end
  end

  describe "#run" do
    before_each {
      expect(client).to receive(:get_access_token).and_return(Factory.access_token)
    }

    it "outputs token" do
      action.call
      expect(&.output.to_s).to eq "cbats_secret\n"
    end

    it "outputs token with header (-H)" do
      action.with_header = true
      action.call

      expect(&.output.to_s).to eq "Authorization: Bearer cbats_secret"
    end

    it "outputs token with header (--format=header)" do
      action.format = CB::Format::Header
      action.call

      expect(&.output.to_s).to eq "Authorization: Bearer cbats_secret"
    end

    it "outputs json" do
      action.format = CB::Format::JSON
      action.call

      expected = <<-EXPECTED
      {
        "access_token": "cbats_secret",
        "expires_at": "2023-05-25T01:00:00Z",
        "token_type": "bearer"
      }\n
      EXPECTED

      expect(&.output.to_s).to eq expected
    end
  end
end
