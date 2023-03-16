require "./client"

module CB
  class Client
    # List available providers.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/providers/list-providers
    def get_providers
      resp = get "providers"
      Array(CB::Model::Provider).from_json resp.body, root: "providers"
    end
  end
end
