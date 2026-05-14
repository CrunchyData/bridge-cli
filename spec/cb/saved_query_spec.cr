require "../spec_helper"

Spectator.describe CB::SavedQueryList do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(saved_queries) { [Factory.saved_query, Factory.saved_query(id: "sqpvoqooxzdrriu6w3bhqo55c4", name: "Other Query")] }

  describe "#validate" do
    it "validates that required arguments are present" do
      expect_missing_arg_error
      action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
      expect(&.validate).to be_true
    end
  end

  describe "#run" do
    before_each do
      action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    end

    it "displays empty message when no queries" do
      expect(client).to receive(:get_saved_queries).and_return([] of CB::Model::SavedQuery)
      action.call
      expect(&.output.to_s).to eq "no saved queries\n"
    end

    it "outputs table format" do
      expect(client).to receive(:get_saved_queries).and_return(saved_queries)
      action.call
      expect(&.output.to_s).to contain "Test Query"
    end

    it "outputs json format" do
      action.format = CB::Format::JSON
      expect(client).to receive(:get_saved_queries).and_return(saved_queries)
      action.call
      expect(&.output.to_s).to contain "\"name\":"
    end
  end
end

Spectator.describe CB::SavedQueryExport do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(saved_query) { Factory.saved_query }

  describe "#validate" do
    it "validates that required arguments are present" do
      expect_missing_arg_error
      action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
      expect_missing_arg_error
      action.query_id = "sqpvoqooxzdrriu6w3bhqo55c4"
      expect(&.validate).to be_true
    end
  end

  describe "#run" do
    before_each do
      action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
      action.query_id = "sqpvoqooxzdrriu6w3bhqo55c4"
    end

    it "exports to specified file" do
      action.file = "/tmp/test_export.sql"
      expect(client).to receive(:get_saved_query).and_return(saved_query)
      action.call
      expect(File.read("/tmp/test_export.sql")).to eq "SELECT 1"
      expect(&.output.to_s).to contain "exported"
      File.delete("/tmp/test_export.sql")
    end

    it "uses sanitized name as default filename" do
      expect(client).to receive(:get_saved_query).and_return(saved_query)
      action.call
      expect(File.exists?("Test_Query.sql")).to be_true
      expect(&.output.to_s).to contain "Test_Query.sql"
      File.delete("Test_Query.sql")
    end
  end
end

Spectator.describe CB::SavedQueryImport do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(saved_query) { Factory.saved_query }

  describe "#validate" do
    it "validates that required arguments are present" do
      expect_missing_arg_error
      action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
      expect_missing_arg_error
      action.file = "/tmp/test_import.sql"
      expect_missing_arg_error
      action.name = "My Query"
      expect(&.validate).to be_true
    end
  end

  describe "#run" do
    before_each do
      action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
      action.file = "/tmp/test_import.sql"
      action.name = "My Query"
      File.write("/tmp/test_import.sql", "SELECT 42")
    end

    after_each do
      File.delete("/tmp/test_import.sql") if File.exists?("/tmp/test_import.sql")
    end

    it "imports from file and prints confirmation" do
      expect(client).to receive(:create_saved_query).and_return(saved_query)
      action.call
      expect(&.output.to_s).to contain "created saved query"
    end
  end
end

Spectator.describe CB::SavedQueryDestroy do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  describe "#validate" do
    it "validates that required arguments are present" do
      expect_missing_arg_error
      action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
      expect_missing_arg_error
      action.query_id = "sqpvoqooxzdrriu6w3bhqo55c4"
      expect(&.validate).to be_true
    end
  end

  describe "#run" do
    before_each do
      action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
      action.query_id = "sqpvoqooxzdrriu6w3bhqo55c4"
    end

    it "destroys and prints confirmation" do
      expect(client).to receive(:destroy_saved_query).and_return("")
      action.call
      expect(&.output.to_s).to eq "saved query destroyed\n"
    end
  end
end
