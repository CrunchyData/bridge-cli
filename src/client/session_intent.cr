module CB
  class Client
    jrecord SessionIntentCreateParams,
      agent_name : String

    def create_session_intent(params : SessionIntentCreateParams)
      @headers.delete("Authorization")
      resp = post "session-intents", params
      CB::Model::SessionIntent.from_json resp.body
    end

    jrecord SessionIntentGetParams,
      secret : String,
      session_intent_id : String

    def get_session_intent(params : SessionIntentGetParams)
      @headers["Authorization"] = "Bearer #{params.secret}"
      resp = get "session-intents/#{params.session_intent_id}"
      CB::Model::SessionIntent.from_json resp.body
    end
  end
end
