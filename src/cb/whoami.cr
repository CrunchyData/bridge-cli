require "./action"

class CB::WhoAmI < CB::APIAction
  def run
    account = client.get_account

    output << "user id: ".colorize.t_id << account.id << "\n"
    output << "   name: ".colorize.t_id << account.name << "\n"
    output << "   host: ".colorize.t_id << CB::HOST << "\n"
  end
end
