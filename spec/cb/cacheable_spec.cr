require "../spec_helper"

private struct Hi
  include CB::Cacheable
  CACHE_DIR = Path[Dir.tempdir]
  property key : String
  property expires_at : Time

  def initialize(@key, @expires_at)
  end
end

# to make sure nothing on the fs leakes between tests
def key
  Random.rand(0x100000000).to_s(36)
end

Spectator.describe CB::Cacheable, ".fetch?" do
  it "returns nil if the file does not exist" do
    Hi.fetch?(key).should eq nil
  end

  it "can store and retreive an unexpired object" do
    k = key
    t = Time.utc + 100.seconds
    h = Hi.new(k, t)
    h.store

    fetched = Hi.fetch?(k)
    fetched.should_not eq nil
    fetched.try(&.key).should eq k
    fetched.try(&.expires_at.to_unix).should eq t.to_unix
  end

  it "reutnrs nil for expired objects" do
    k = key
    t = Time.utc - 100.seconds
    h = Hi.new(k, t)
    h.store

    fetched = Hi.fetch?(k)
    fetched.should eq nil
  end
end
