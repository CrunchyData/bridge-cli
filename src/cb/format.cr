module CB
  enum Format
    Default
    Header
    JSON
    List
    Table
    Tree

    def to_s(io : IO)
      io << self.to_s.downcase
    end
  end
end
