class CB::Completion
  def self.parse(client, commandline)
    new(client, commandline).parse
  end

  getter commandline : String
  getter args : Array(String)
  getter full_flags : Set(Symbol)

  def initialize(@client : Client, @commandline : String)
    @args = @commandline.split(/\s+/)[1..-1]
    @full_flags = find_full_flags
  end

  def parse : Array(String)
    if args.size < 2
      return top_level
    else
      case args.first
      when "info"
        return info
      when "create"
        return create
      else
        STDERR.puts
        STDERR.puts commandline.inspect
        STDERR.puts args.inspect
        [] of String
      end
    end
  end

  def top_level
    [
      "--version\tShow version information",
      "login\tStore API key",
      "token\tGet current API token",
      "clusters\tList clusters",
      "teams\tList teams",
      "info\tDetailed cluster info",
      "create\tProvision a new cluster",
    ]
  end

  def info
    teams = @client.get_teams
    @client.get_clusters.map do |c|
      team_name = teams.find { |t| t.id == c.team_id }.try(&.name) || "unknown_team"
      "#{c.id}\t#{team_name}/#{c.name}"
    end
  end

  def teams
    @client.get_teams.map { |t| "#{t.id}\t#{t.name}" }
  end

  def create
    if args.includes? "--help"
      return [] of String
    end

    if last_arg? "-p", "--platform"
      return ["aws\tAmazon Web Services", "gcp\tGoogle Cloud Platform", "azr\tMicrosoft Azure"]
    end

    if last_arg? "-n", "--name"
      return [] of String
    end

    if last_arg? "aws", "gcp", "azr"
      return ["--region", "--plan"]
    end

    platform = find_platform

    if last_arg? "-r", "--region"
      return platform ? region(platform) : [] of String
    end

    if last_arg? "--plan"
      return platform ? plan(platform) : [] of String
    end

    if has_full_flag? :platform
      if has_full_flag?(:region) && !has_full_flag?(:plan)
        return ["--plan"]
      elsif !has_full_flag?(:region) && has_full_flag?(:plan)
        return ["--region"]
      end
    end

    if last_arg? "--storage", "-s"
      return [100, 256, 512, 1024].map { |s| "#{s}\t#{s} GiB" }
    end

    if last_arg? "--team", "-t"
      return teams
    end

    if last_arg? "--ha"
      return ["false", "true"]
    end

    # return missing args
    suggest = [] of String
    suggest << "--help\tshow help" if args.size == 2
    suggest << "--platform\tcloud provider" unless has_full_flag? :platform
    suggest << "--team\tcrunchy bridge team" unless has_full_flag? :team
    suggest << "--storage\tstorage size in GiB" unless has_full_flag? :storage
    suggest << "--ha\thigh availability" unless has_full_flag? :ha
    suggest << "--name\tcluster name" unless has_full_flag? :name
    return suggest
  end

  def find_platform : String?
    platform_idx = @args.index("--platform") || @args.index("-p")
    platform = platform_idx ? @args[platform_idx + 1] : nil
    platform = "azure" if platform == "azr"
    platform
  rescue IndexError
    nil
  end

  def region(platform)
    platform = @client.get_providers.find { |p| p.id == platform }
    return [] of String unless platform
    platform.regions.map { |r| "#{r.id}\t#{r.display_name} [#{r.location}]" }
  end

  def plan(platform)
    platform = @client.get_providers.find { |p| p.id == platform }
    return [] of String unless platform
    platform.plans.map { |r| "#{r.id}\t#{r.display_name}" }
  end

  # only return the long version, but search for long and short
  def find_full_flags
    full = Set(Symbol).new
    full << :ha if has_full_flag? "--ha"
    full << :plan if has_full_flag? "--plan"
    full << :name if has_full_flag? "--name", "-n"
    full << :team if has_full_flag? "--team", "-t"
    full << :region if has_full_flag? "--region", "-r"
    full << :storage if has_full_flag? "--storage", "-s"
    full << :platform if has_full_flag? "--platform", "-p"
    return full
  end

  def has_full_flag?(arg1 : String, arg2 : String? = nil) : Bool
    idx = @args.index(arg1) || @args.index(arg2)
    return false unless idx
    return !@args[idx + 1]?.nil?
  end

  def has_full_flag?(*names : Symbol) : Bool
    names.all? { |n| @full_flags.includes? n }
  end

  def last_arg?(*args) : Bool
    last = @args[-2]
    args.includes? last
  end
end
