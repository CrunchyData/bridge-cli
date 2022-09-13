require "../spec_helper"

Spectator.describe CB::Identifier do
  describe "#initialize" do
    subject { described_class.new(id) }
    provided id: "pkdpq6yynjgjbps4otxd7il2u4" do
      expect(&.to_s).to eq id
      expect(&.eid?).to be_true
      expect(&.api_name?).to be_false
    end

    provided id: "test-cluster" do
      expect(&.to_s).to eq id
      expect(&.eid?).to be_false
      expect(&.api_name?).to be_true
    end

    provided id: "abc" do
      expect { described_class.new(id) }.to raise_error CB::Program::Error, /invalid identifier/
    end

    provided id: "" do
      expect { described_class.new(id) }.to raise_error CB::Program::Error, /invalid identifier/
    end
  end
end
