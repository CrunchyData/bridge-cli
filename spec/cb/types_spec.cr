require "../spec_helper"
include CB

Spectator.describe CB::Role do
  describe "#initialize" do
    subject { described_class }
    it "creates default as 'user'" do
      expect(&.new.name).to eq "user"
    end

    sample CB::Role::VALID_CLUSTER_ROLES do |name|
      it "creates with valid name" do
        expect(&.new(name)).to_not be_nil
      end
    end

    it "allows u_<id> name" do
      expect(&.new("u_t7c5psndzrfzrgjvkiuty5cd4e")).to_not be_nil
    end

    it "errors with invalid name" do
      expect(&.new("invalid")).to raise_error Program::Error, /invalid role: 'invalid'/
      expect(&.new("u_abc")).to raise_error Program::Error, /invalid role: 'u_abc'/
    end
  end
end
