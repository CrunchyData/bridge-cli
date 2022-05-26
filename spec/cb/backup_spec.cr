require "../spec_helper"

private class BackupTestClient < CB::Client
  def backup_list(id)
    if id.try &.starts_with? 'z'
      [Backup.new(name: "a backup", started_at: Time.utc, finished_at: Time.utc, lsn_start: "1/a", lsn_stop: "2/b", size_bytes: 123)]
    else
      [] of Backup
    end
  end

  def backup_token(id)
    if id.try &.starts_with? "aws"
      BackupToken.new(
        type: "s3",
        repo_path: "/the-path",
        stanza: "h3zwxm6bafaq3mqbgou5zj56su",
        aws: AWSBackrestCredential.new(
          s3_key: "key",
          s3_key_secret: "secret",
          s3_token: "token",
          s3_region: "us-west-1",
          s3_bucket: "the-bucket",
        )
      )
    elsif id.try &.starts_with? "azr"
      BackupToken.new(
        type: "azure",
        repo_path: "/",
        stanza: "h3zwxm6bafaq3mqbgou5zj56su",
        azure: AzureBackrestCredential.new(
          azure_account: "test_account",
          azure_key: "test_token",
          azure_key_type: "sas",
          azure_container: "test_container",
        )
      )
    else
      nil
    end
  end
end

private def make_ba
  CB::BackupCapture.new(BackupTestClient.new(TEST_TOKEN))
end

private def make_bl
  CB::BackupList.new(BackupTestClient.new(TEST_TOKEN))
end

private def make_bt
  CB::BackupToken.new(BackupTestClient.new(TEST_TOKEN))
end

describe CB::BackupCapture do
  it "validates that cluster_id is correct" do
    ba = make_ba
    ba.cluster_id = "afpvoqooxzdrriu6w3bhqo55c4"
    expect_cb_error(/cluster id/) { ba.cluster_id = "notaneid" }
  end
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

describe CB::BackupToken do
  it "validates that cluster_id is correct" do
    bt = make_bt
    bt.cluster_id = "afpvoqooxzdrriu6w3bhqo55c4"
    expect_cb_error(/cluster id/) { bt.cluster_id = "notaneid" }
  end

  it "says when there are no backups" do
    bt = make_bt
    bt.cluster_id = "awszzzzzzzzzriu6w3bhqo55c4"
    bt.output = output = IO::Memory.new

    bt.call
    output.to_s.should match /Type:.*s3.*/

    bt = make_bt
    bt.cluster_id = "azrzzzzzzzzzriu6w3bhqo55c4"
    bt.output = output = IO::Memory.new

    bt.call
    output.to_s.should match /Type:.*azure.*/
  end

  it "prints token when available" do
  end
end
