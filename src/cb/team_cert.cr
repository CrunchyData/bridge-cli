require "./action"

class CB::TeamCert < CB::Action
  eid_setter team_id

  def run
    cert = client.get("teams/#{team_id}.pem").body
    output.puts cert
  rescue e : Client::Error
    if e.not_found?
      STDERR << "error".colorize.t_warn << ": No public cert found.\n"
    else
      raise e
    end
  end
end
