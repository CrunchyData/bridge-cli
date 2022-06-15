require "./action"

module CB
  class Logout < Action
    def run
      Creds.delete(CB::HOST)
      Token.delete(CB::HOST)
    end
  end
end
