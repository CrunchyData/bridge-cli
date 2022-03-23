require "./action"

class CB::ClusterURI < CB::Action
  eid_setter cluster_id
  property role_name : String = "default"

  def run
    # Ensure the role name
    raise Error.new("invalid role: '#{@role_name}'") unless VALID_CLUSTER_ROLES.includes? @role_name
    if @role_name == "user"
      @role_name = "u_" + client.get_account.id
    end

    # Fetch the role.
    role = client.get_role(cluster_id, @role_name)

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
      msg = "role '#{@role_name}' does not exist."
    end

    raise Error.new "invalid input."
  end
end
