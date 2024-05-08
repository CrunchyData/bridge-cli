require "./action"

class CB::ClusterURI < CB::APIAction
  cluster_identifier_setter cluster_id
  role_setter role
  i32_setter port
  property database : String?

  def validate
    check_required_args do |missing|
      missing << "cluster" if @cluster_id.empty?
    end
  end

  def run
    validate

    client.create_role(@cluster_id[:cluster]) if @role == "user"
    role = client.get_role(@cluster_id[:cluster], @role.to_s)

    uri = role.uri
    raise Error.new "There is no URI available for this cluster." unless uri

    uri.port = port if port
    uri.path = database.to_s if database

    # Redact the password from the result. Redaction is handled by coloring the
    # foreground and background the same color. This benfits the user by not
    # allowing their password to be inadvertently exposed in a TTY session. But
    # it still allows for it to be copied and pasted without requiring any
    # special action from the user.
    redacted_uri = uri.to_s
    unless role.password.nil?
      pw = role.password
      redacted_uri = redacted_uri.gsub(pw, pw.colorize.black.on_black.to_s) if pw
    end

    output << redacted_uri
  rescue e : Client::Error
    msg = "unknown client error."
    case
    when e.bad_request?
      msg = "invalid input."
    when e.forbidden?
      msg = "not allowed."
    when e.not_found?
      msg = "role '#{@role}' does not exist."
    end

    raise Error.new msg
  end
end
