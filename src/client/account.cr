require "./client"

module CB
  class Client
    jrecord Account,
      id : String,
      name : String,
      email : String

    # https://crunchybridgeapi.docs.apiary.io/#reference/0/account/get-account
    def get_account
      resp = get "account"
      Account.from_json resp.body
    end
  end
end
