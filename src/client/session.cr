module CB
  class Client
    jrecord SessionCreateParams,
      generate_one_time_token : Bool,
      redirect_url : String?

    # https://crunchybridgeapiinternal.docs.apiary.io/#reference/0/sessions/create-session
    def create_session(params : SessionCreateParams)
      resp = post "sessions", params
      CB::Model::Session.from_json resp.body
    end
  end
end
