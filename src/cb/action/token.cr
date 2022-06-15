require "./action"

module CB::Action
  class Token < Action
    enum Format
      Default
      Header
    end

    property token : CB::Token
    property format : Format = Format::Default

    def initialize(@token, @input, @output)
    end

    def run
      case @format
      when "header"
        output << "Authorization: Bearer #{token.token}"
      when "default"
        output << token.token
      end
    end
  end
end
