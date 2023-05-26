require "./action"

module CB
  class Logout < Action
    def run
      Credentials.destroy(host: CB::HOST)
    end
  end
end
