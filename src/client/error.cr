module CB
  class Client::Error < ::Exception
    Log = ::Log.for("client")

    property method : String
    property path : String
    property resp : HTTP::Client::Response

    def initialize(@method, @path, @resp)
    end

    def to_s(io : IO)
      io.puts "#{"error".colorize.red.bold}: #{resp.status.code.colorize.cyan} #{resp.status.description.colorize.red}"
      indent = "       "
      io.puts "#{indent}#{method.upcase.colorize.green} to /#{path.colorize.green}"

      begin
        JSON.parse(resp.body).as_h.each do |k, v|
          io.puts "#{indent}#{"#{k}:".colorize.light_cyan} #{v}"
        end
      rescue JSON::ParseException
        io.puts "#{indent}#{resp.body}" unless resp.body == ""
      end
    end

    def message
      JSON.parse(resp.body).as_h["message"].to_s
    rescue JSON::ParseException
      resp.body unless resp.body == ""
    end

    def bad_request?
      resp.status == HTTP::Status::BAD_REQUEST
    end

    def forbidden?
      resp.status == HTTP::Status::FORBIDDEN
    end

    def not_found?
      resp.status == HTTP::Status::NOT_FOUND
    end

    def unauthorized?
      resp.status == HTTP::Status::UNAUTHORIZED
    end
  end
end
