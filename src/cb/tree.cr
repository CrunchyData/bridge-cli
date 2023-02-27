require "../types/tree"

module CB::Tree
  class Renderer
    def initialize(@tree : CB::Types::TreeNode(String))
    end

    def render(io = IO::Memory.new)
      io << @tree.value << '\n'
      render_node(io, @tree)
    end

    private def render_node(io : IO, node : CB::Types::TreeNode(String), indent = "")
      node.children.each do |n|
        if n.last_child?
          io << "#{indent}└── #{n.value}\n"
          render_node(io, n, indent + "    ")
        else
          io << "#{indent}├── #{n.value}\n"
          render_node(io, n, indent + "│   ")
        end
      end
      io
    end
  end
end
