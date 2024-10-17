require "./action"
require "./dirs"
require "./query_menu/*"

module CB
  class Psql < APIAction
    cluster_identifier_setter cluster_id
    role_setter role
    property database : String?
    setter database

    # Here we're making it so that we can override the call out to `psql`. This
    # is for testing purposes only. There should be no need outside of tests to
    # do this.
    @psql : Proc(Enumerable(String), Process::Env, NoReturn?)
    setter psql

    def initialize(@client, @input = STDIN, @output = STDOUT)
      @psql = ->(args : Enumerable(String), env : Process::Env) { Process.exec("psql", args, env: env) }
    end

    def validate
      check_required_args do |missing|
        missing << "cluster" if @cluster_id.empty?
      end
    end

    def run
      validate

      c = client.get_cluster cluster_id[:cluster]
      team = client.get_team c.team_id

      client.create_role(cluster_id[:cluster]) if @role == "user"
      uri = client.get_role(cluster_id[:cluster], @role.to_s).uri
      raise Error.new "unable to obtain uri for cluster" if uri.nil?

      database.tap { |db| uri.path = db if db }

      output << "connecting to "
      output << team.name.colorize.t_alt << "/" if team.name
      output << c.name.colorize.t_name << "\n"

      cert_path = ensure_cert c.team_id
      psqlrc_path = build_psqlrc c, team.name

      args = ARGV.skip 1

      @psql.call(args, {
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

    private def ensure_cert(team_id) : String
      cert_dir = CB::Dirs::CERTS_DIR
      path = cert_dir / "#{team_id}.pem"
      unless File.exists? path
        Dir.mkdir_p cert_dir
        File.open(path, "w", perm: 0o600) do |f|
          f << client.get_team_cert team_id
        end
      end

      path.to_s
    end

    private def escape(str) : String
      String.build do |build|
        str.each_char do |char|
          case char
          when '\''
            build << "\\'"
          else
            build << char
          end
        end
      end
    end

    private def build_psqlrc(c : Model::Cluster, team_name : String) : String
      psqlpromptname = String.build do |s|
        s << "%[%033[32m%]#{escape(team_name)}%[%033m%]" << "/" if team_name
        s << "%[%033[36m%]#{c.name}%[%033m%]"
      end

      psqlrc = File.tempfile(c.id, "psqlrc")
      File.copy(CB::PSQLRC, psqlrc.path) if File.exists?(CB::PSQLRC)
      File.open(psqlrc.path, "a") do |f|
        f.puts "\\set ON_ERROR_ROLLBACK interactive"
        f.puts "\\set PROMPT1 '#{psqlpromptname}/%[%033[33;1m%]%x%x%x%[%033[0m%]%[%033[1m%]%/%[%033[0m%]%R%# '"
        f.puts QueryMenu::Menu.new.render(cluster: c)
        f.puts "\\echo 'Use #{":menu".colorize.bold} to list available queries.'"
      end

      psqlrc.path.to_s
    end
  end
end
