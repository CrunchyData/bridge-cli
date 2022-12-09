require "tallboy"

module CB::Table
  class TableBuilder < Tallboy::TableBuilder
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
      "edge_top"            => "─",
      "edge_right"          => "",
      "edge_bottom"         => "",
      "edge_left"           => "",
      "tee_top"             => "", # no effect
      "tee_right"           => "─",
      "tee_bottom"          => "",
      "tee_left"            => "─",
      "divider_vertical"    => "", # nope
      "divider_horizontal"  => "", # no effect
      "joint_horizontal"    => "", # no effect
      "joint_vertical"      => "",
      "cross"               => "─",
      "content"             => "",
    }
  end
end
