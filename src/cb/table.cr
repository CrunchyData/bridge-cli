require "tallboy"

module CB::Table
  class TableBuilder < Tallboy::TableBuilder
    def header
      header(@columns.map(&.name.colorize.bold.underline))
    end

    def header(arr : Array)
      row(arr, :none)
    end

    def render(io = IO::Memory.new)
      DefaultRenderer.new(self.build).render(io)
    end
  end

  class DefaultRenderer < Tallboy::Renderer
    @@border_style = {
      "corner_top_left"     => "",
      "corner_top_right"    => "",
      "corner_bottom_right" => "",
      "corner_bottom_left"  => "",
      "edge_top"            => "",
      "edge_right"          => "",
      "edge_bottom"         => "",
      "edge_left"           => "",
      "tee_top"             => "",
      "tee_right"           => "",
      "tee_bottom"          => "",
      "tee_left"            => "",
      "divider_vertical"    => "",
      "divider_horizontal"  => "",
      "joint_horizontal"    => "",
      "joint_vertical"      => "",
      "cross"               => "",
      "content"             => "",
    }
  end
end
