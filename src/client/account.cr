require "./client"

module CB
  class Client
    # Get the account for the currently logged in user.
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/account/get-account
    def get_account(secret : String? = nil)
      @headers["Authorization"] = "Bearer #{secret}" if secret
      resp = get "account"
      CB::Model::Account.from_json resp.body
    end
  end
end
