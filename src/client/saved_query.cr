require "./client"

module CB
  class Client
    struct SavedQueryListResponse
      include JSON::Serializable
      pagination_properties
      property saved_queries : Array(CB::Model::SavedQuery) = [] of CB::Model::SavedQuery
    end

    def get_saved_queries(cluster_id)
      saved_queries = [] of CB::Model::SavedQuery
      query_params = Hash(String, String).new
      query_params["cluster_id"] = cluster_id.to_s
      query_params["order_field"] = "name"

      loop do
        resp = get "saved-queries?#{HTTP::Params.encode(query_params)}"
        data = SavedQueryListResponse.from_json resp.body
        saved_queries.concat(data.saved_queries)
        break unless data.has_more
        query_params["cursor"] = data.next_cursor.to_s
      end

      saved_queries
    end

    def get_saved_query(saved_query_id)
      resp = get "saved-queries/#{saved_query_id}"
      CB::Model::SavedQuery.from_json resp.body
    end

    def create_saved_query(params)
      resp = post "saved-queries", params
      CB::Model::SavedQuery.from_json resp.body
    end

    def destroy_saved_query(saved_query_id)
      resp = delete "saved-queries/#{saved_query_id}"
      resp.body
    end
  end
end
