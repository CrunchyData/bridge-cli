require "./client"

module CB
  class Client
    jrecord Plan, id : String, display_name : String

    jrecord Region, id : String, display_name : String, location : String

    jrecord Provider, id : String,
      display_name : String,
      regions : Array(Region),
      plans : Array(Plan)

    # List available providers.
    #
    # https://crunchybridgeapi.docs.apiary.io/#reference/0/providers/list-providers
    def get_providers
      resp = get "providers"
      Array(Provider).from_json resp.body, root: "providers"
    end
  end
end
