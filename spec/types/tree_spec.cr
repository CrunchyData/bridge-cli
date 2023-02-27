# require "../spec_helper"
require "spectator"

require "../../src/types/tree"

Spectator.describe CB::Types::TreeNode do
  subject(root) { described_class.new("root") }

  describe "#<<(T)" do
    it "should add a new node" do
      expect(&.has_children?).to be_false
      root << "child"
      expect(&.has_children?).to be_true
    end
  end

  describe "#<<(TreeNode(T))" do
    it "should add a new node" do
      expect(&.has_children?).to be_false
      root << CB::Types::TreeNode.new("child")
      expect(&.has_children?).to be_true
    end
  end

  describe "#<<(Array)" do
    it "should add a single node" do
      expect(&.has_children?).to be_false
      root << ["child"]
      expect(&.children.size).to eq 1
    end

    it "should add multiple nodes" do
      expect(&.has_children?).to be_false
      root << ["child", "another child"]
      expect(&.children.size).to eq 2
    end
  end

  describe "#each_value" do
    it "should interate over the values all nodes" do
      root << ["child 1", "child 2", "child 3"]

      actual = [] of String
      root.each_value { |value| actual << value }

      expected = ["root", "child 1", "child 2", "child 3"]

      expect(actual).to eq expected
    end
  end

  describe "#each" do
    it "should interate over all nodes depth first" do
      root << [
        CB::Types::TreeNode.new("first", [
          CB::Types::TreeNode.new("child 1", [
            CB::Types::TreeNode.new("grandchild 1"),
          ]),
          CB::Types::TreeNode.new("child 2"),
        ]),
        CB::Types::TreeNode.new("second"),
        CB::Types::TreeNode.new("third"),
      ]

      expected = [
        "Value: root - Level: 0",
        "Value: first - Level: 1",
        "Value: child 1 - Level: 2",
        "Value: grandchild 1 - Level: 3",
        "Value: child 2 - Level: 2",
        "Value: second - Level: 1",
        "Value: third - Level: 1",
      ]

      actual = [] of String
      root.each { |node, level| actual << "Value: #{node.value} - Level: #{level}" }

      expect(actual).to eq expected
    end
  end

  describe "#find" do
    it "finds" do
      root << ["child 1", "child 2", "child 3"]
      value = root.find { |v| v == "child 2" }
      expect(value).to eq "child 2"
    end

    it "doesn't find" do
      value = root.find { |v| v == "dne" }
      expect(value).to be_nil
    end
  end

  describe "#last_child?" do
    it "returns true if node is last child" do
      root << ["first", "second", "third"]

      third = root.children[2]

      expect(third.value).to eq "third"
      expect(third.last_child?).to be_true
    end

    it "returns false if node is not last child" do
      root << ["first", "second", "third"]

      second = root.children[1]

      expect(second.value).to eq "second"
      expect(second.last_child?).to be_false
    end
  end
end
