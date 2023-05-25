# TODO (abrightwell): We had to explicitly qualify this class name as an
# `Action` due to conflicts with the below `Token` struct.  Would be great to
# potentially namespace actions under `CB::Action` or something. Something
# perhaps worth considering.
module CB
  class Token < APIAction
    bool_setter with_header
    format_setter? format

    def validate
      raise Error.new "Cannot use -H with --format." if with_header && format
    end

    def run
      validate

      @format = CB::Format::Header if with_header

      access_token = @client.get_access_token

      case @format
      when CB::Format::Header
        output_header(access_token)
      when CB::Format::JSON
        output_json(access_token)
      else
        output << access_token.access_token << '\n'
      end
    end

    def output_json(access_token : CB::Model::AccessToken)
      output << {
        "access_token": access_token.access_token,
        "expires_at":   access_token.expires_at,
        "token_type":   access_token.token_type,
      }.to_pretty_json << '\n'
    end

    def output_header(access_token : CB::Model::AccessToken)
      output << "Authorization: Bearer #{access_token.access_token}"
    end
  end
end
