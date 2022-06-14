require "./action"

module CB::Action
  class Psql < APIAction
    eid_setter cluster_id
    property database : String?

    def run
      c = client.get_cluster cluster_id
      uri = client.get_role(cluster_id, "default").uri
      raise Error.new "null uri" if uri.nil?

      database.tap { |db| uri.path = db if db }

      output << "connecting to "
      team_name = print_team_slash_cluster c

      cert_path = ensure_cert c.team_id
      psqlrc_path = build_psqlrc c, team_name

      args = ARGV.skip 1

      Process.exec("psql", args, env: {
        "PGHOST"        => uri.hostname,
        "PGUSER"        => uri.user,
        "PGPASSWORD"    => uri.password,
        "PGDATABASE"    => uri.path.lchop('/'),
        "PGPORT"        => uri.port.to_s,
        "PSQLRC"        => psqlrc_path,
        "PGSSLCERT"     => "dontuse",
        "PGSSLKEY"      => "dontuse",
        "PGSSLMODE"     => "verify-ca",
        "PGSSLROOTCERT" => cert_path,
      })
    rescue e : File::NotFoundError
      raise Error.new "The local psql command could not be found"
    end

    def database=(str : String)
      @database = str
    end

    private def ensure_cert(team_id) : String
      cert_dir = CB::Creds::CONFIG / "certs"
      path = cert_dir / "#{team_id}.pem"
      unless File.exists? path
        Dir.mkdir_p cert_dir
        File.open(path, "w", perm: 0o600) do |f|
          f << client.get("teams/#{team_id}.pem").body
        end
      end

      path.to_s
    end

    private def build_psqlrc(c, team_name) : String
      psqlpromptname = String.build do |s|
        s << "%[%033[32m%]#{team_name}%[%033m%]" << "/" if team_name
        s << "%[%033[36m%]#{c.name}%[%033m%]"
      end

      psqlrc = File.tempfile(c.id, "psqlrc")
      File.copy("~/.psqlrc", psqlrc.path) if File.exists?("~/.psqlrc")
      File.open(psqlrc.path, "a") do |f|
        f.puts "\\set ON_ERROR_ROLLBACK interactive"
        f.puts "\\set x auto"
        f.puts "\\set PROMPT1 '#{psqlpromptname}/%[%033[33;1m%]%x%x%x%[%033[0m%]%[%033[1m%]%/%[%033[0m%]%R%# '"
      end

      psqlrc.path.to_s
    end
  end
end
