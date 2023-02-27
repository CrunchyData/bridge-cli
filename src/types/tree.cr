module CB::Types
  alias Tree = TreeNode

  class TreeNode(T)
    include Enumerable(Tuple(TreeNode(T), Int32))

    property children : Array(TreeNode(T)) = [] of TreeNode(T)
    property parent : TreeNode(T)? = nil
    property value : T

    def initialize(@value : T, children = [] of TreeNode(T))
      children.each { |child| self << child }
    end

    def <<(value : T)
      node = TreeNode(T).new(value: value)
      node.parent = self
      @children << node
    end

    def <<(node : TreeNode(T))
      node.parent = self
      @children << node
    end

    def <<(arr : Array)
      arr.each { |elem| self << elem }
    end

    def each_value(&block : T ->)
      yield value

      self.children.each do |child|
        child.each_value(&block)
      end
    end

    def each(&block : Tuple(TreeNode(T), Int32) ->)
      each_with_level(self, 0, &block)
    end

    private def each_with_level(node : TreeNode(T), level : Int32, &block : Tuple(TreeNode(T), Int32) ->)
      yield({node, level})
      node.children.each do |child|
        each_with_level(child, level + 1, &block)
      end
    end

    def find(&block : T -> Bool)
      return value if yield value

      @children.each do |child|
        result = child.find(&block)
        return result if result
      end
    end

    def has_children?
      !@children.empty?
    end

    def last_child?
      @parent.try &.children.last? == self
    end
  end
end
