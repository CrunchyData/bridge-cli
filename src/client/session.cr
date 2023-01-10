module CB
  class Client
    jrecord Session,
      id : String,
      one_time_token : String

    jrecord SessionCreateParams, generate_one_time_token : Bool

    # https://crunchybridgeapiinternal.docs.apiary.io/#reference/0/sessions/create-session
    def create_session(params : SessionCreateParams)
      resp = post "sessions", params
      Session.from_json resp.body
    end
  end
end
