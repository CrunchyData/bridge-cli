require "./action"

class CB::Psql < CB::Action
  property cluster_id : String?

  def call
    c = client.get_cluster cluster_id
    uri = client.get_cluster_default_role(cluster_id).uri

    output << "connecting to "
    team_name = Display.new(client).print_team_slash_cluster c, output

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
      "PGSSLMODE"     => "verify-ca",
      "PGSSLROOTCERT" => cert_path,
    })
  end

  def cluster_id=(str : String)
    raise_arg_error "cluster id", str unless str =~ EID_PATTERN
    @cluster_id = str
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

    psqlrc = File.tempfile(c.id, "pslrc")
    File.copy("~/.psqlrc", psqlrc.path) if File.exists?("~/.psqlrc")
    File.open(psqlrc.path, "a") do |f|
      f.puts "\\set ON_ERROR_ROLLBACK interactive"
      f.puts "\\set x auto"
      f.puts "\\set PROMPT1 '#{psqlpromptname}/%[%033[33;1m%]%x%x%x%[%033[0m%]%[%033[1m%]%/%[%033[0m%]%R%# '"
    end

    psqlrc.path.to_s
  end
end
