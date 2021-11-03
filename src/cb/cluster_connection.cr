require "./client"
require "./program"

module CB
  class ClusterConnection
    Error = Program::Error

    property id : String
    property client : Client

    def initialize(@id, @client)
    end

    def open(dbname = "postgres")
      uri = client.get_cluster_default_role(id).uri
      uri.path == dbname

      # disable non-channel binding scram
      uri.query = "auth_methods=scram-sha-256-plus"

      DB.open(uri) { |c| yield c }
    rescue e : DB::ConnectionRefused
      raise Error.new("Could not connect to database: #{e.cause}")
    end

    def db_names
      names = [] of String
      open do |db|
        pp! db.query_one("select array_agg(datname) from pg_database", &.read(Array(String)))
      end
    end
  end
end
