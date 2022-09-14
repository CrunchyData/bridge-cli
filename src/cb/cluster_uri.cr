require "./action"

class CB::ClusterURI < CB::APIAction
  cluster_identifier_setter cluster_id
  role_setter role

  def validate
    check_required_args do |missing|
      missing << "cluster" if @cluster_id.empty?
    end
  end

  def run
    validate

    if @role == "user"
      @role = Role.new "u_#{client.get_account.id}"
    end

    # Fetch the role.
    role = client.get_role(@cluster_id[:cluster], @role.to_s)

    # Redact the password from the result. Redaction is handled by coloring the
    # foreground and background the same color. This benfits the user by not
    # allowing their password to be inadvertently exposed in a TTY session. But
    # it still allows for it to be copied and pasted without requiring any
    # special action from the user.
    uri = role.uri.to_s
    unless role.password.nil?
      pw = role.password
      uri = uri.gsub(pw, pw.colorize.black.on_black.to_s) if pw
    end

    output << uri
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
