require "./action"

module CB
  class Logout < Action
    def run
      Credentials.destroy
    end
  end
end
