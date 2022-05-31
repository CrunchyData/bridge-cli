require "./action"

class CB::WhoAmI < CB::APIAction
  def run
    output << "user id: ".colorize.t_id << client.token.user_id << "\n"
    output << "   name: ".colorize.t_id << client.token.name << "\n"
    output << "   host: ".colorize.t_id << client.host << "\n"
  end
end
