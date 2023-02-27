require "../spec_helper"
require "../../src/types/tree"

Spectator.describe CB::Tree::Renderer do
  describe "#render" do
    it "renders a single level tree" do
      tree = CB::Types::Tree.new("root")
      tree << ["first", "second", "third"]

      subject = described_class.new(tree)
      output = IO::Memory.new

      expected = <<-EXPECTED
      root
      ├── first
      ├── second
      └── third\n
      EXPECTED

      output << subject.render

      expect(output.to_s).to eq expected
    end

    it "renders a multi-level tree" do
      tree = CB::Types::Tree.new("root", [
        CB::Types::TreeNode.new("first", [
          CB::Types::TreeNode.new("child 1", [
            CB::Types::TreeNode.new("grandchild 1"),
          ]),
          CB::Types::TreeNode.new("child 2"),
        ]),
        CB::Types::TreeNode.new("second"),
        CB::Types::TreeNode.new("third", [
          CB::Types::TreeNode.new("child 1"),
        ]),
      ])

      subject = described_class.new(tree)

      output = IO::Memory.new

      expected = <<-EXPECTED
      root
      ├── first
      │   ├── child 1
      │   │   └── grandchild 1
      │   └── child 2
      ├── second
      └── third
          └── child 1\n
      EXPECTED

      output << subject.render

      expect(output.to_s).to eq expected
    end
  end
end
