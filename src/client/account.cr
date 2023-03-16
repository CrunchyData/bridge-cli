require "./client"

module CB
  class Client
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/account/get-account
    def get_account
      resp = get "account"
      CB::Model::Account.from_json resp.body
    end
  end
end
