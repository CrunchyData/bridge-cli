require "../spec_helper"

private class BackupTestClient < CB::Client
  def backup_list(id)
    if id.try &.starts_with? 'z'
      [Backup.new(name: "a backup", started_at: Time.utc, finished_at: Time.utc, start_lsn: "1/a", end_lsn: "2/b", size_bytes: 123)]
    else
      [] of Backup
    end
  end
end

private def make_bl
  CB::BackupList.new(BackupTestClient.new(TEST_TOKEN))
end

describe CB::BackupList do
  it "validates that cluster_id is correct" do
    bl = make_bl
    bl.cluster_id = "afpvoqooxzdrriu6w3bhqo55c4"
    expect_cb_error(/cluster id/) { bl.cluster_id = "notaneid" }
  end

  it "says when there is no backups" do
    bl = make_bl
    bl.cluster_id = "afpvoqooxzdrriu6w3bhqo55c4"
    bl.output = output = IO::Memory.new

    bl.call
    output.to_s.should eq "no backups yet"
  end

  it "prints bap info when there are backups" do
    bl = make_bl
    bl.cluster_id = "zzzzzzzzzzzzriu6w3bhqo55c4"
    bl.output = output = IO::Memory.new

    bl.call
    output.to_s.should match /a backup/
  end
end
