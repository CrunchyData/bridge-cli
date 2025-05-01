require "./action"

class CB::ClusterCreate < CB::APIAction
  bool_setter ha
  name_setter? name
  ident_setter plan
  property platform : String?
  i32_setter postgres_version
  ident_setter region
  i32_setter storage
  eid_setter team, "team id"
  eid_setter network, "network id"
  eid_setter replica, "replica id"
  eid_setter fork, "fork id"
  property at : Time?
  i32_setter maintenance_window_start

  private def validate_fork_and_replica
    raise Error.new "Cannot use both '--fork' and '--replica' at the same time." if fork && replica
  end

  private def validate_maintenance_window_with_fork_or_replica
    raise Error.new "Cannot use '--maintenance-window-start' with '--fork' or '--replica'" if maintenance_window_start && (fork || replica)
  end

  private def validate_maintenance_window_range
    raise Error.new "Invalid value for '--maintenance-window-start', valid values: 0 - 23" if (start = maintenance_window_start) && !start.in?(0..23)
  end

  def pre_validate
    validate_fork_and_replica
    validate_maintenance_window_with_fork_or_replica
    validate_maintenance_window_range

    if id = fork || replica
      source = client.get_cluster id
      @name ||= "#{fork ? "Fork" : "Replica"} of #{source.name}"
    else
      @storage ||= 100
      @name ||= "Cluster #{Time.utc.to_s("%F %H_%M_%S")}"
    end
  end

  def validate
    pre_validate

    check_required_args do |missing|
      missing << "name" unless name
      missing << "platform" unless replica || platform || network
      missing << "plan" unless replica || plan || platform
      missing << "region" unless replica || region || network
      missing << "team" unless team || fork || replica
    end
  end

  def run
    validate

    params = {
      name:        @name.to_s,
      network_id:  @network,
      plan_id:     @plan,
      provider_id: @platform,
      region_id:   @region,
    }

    if @network
      network = @client.get_network @network
      raise Error.new "Must also specify '--region' for a 'gcp' based network." if network.provider_id == "gcp" && !region
      raise Error.new "Cannot use '--network' with '--platform' or '--region'" if network.provider_id != "gcp" && (platform || region)
    end

    cluster = if fork
                @client.create_fork CB::Client::ForkCreateParams.new(**params.merge(
                  cluster_id: @fork.to_s,
                  is_ha: @ha,
                  storage: @storage,
                  target_time: @at,
                ))
              elsif replica
                @client.create_replica CB::Client::ReplicaCreateParams.new(**params.merge(
                  cluster_id: @replica.to_s,
                ))
              else
                @client.create_cluster CB::Client::ClusterCreateParams.new(**params.merge(
                  is_ha: @ha,
                  maintenance_window_start: @maintenance_window_start,
                  postgres_version_id: @postgres_version,
                  storage: @storage,
                  team_id: @team.to_s,
                ))
              end

    @output << "Created cluster #{cluster.id.colorize.t_id} \"#{cluster.name.colorize.t_name}\"\n"
  end

  def at=(str : String)
    @at = Time.parse_rfc3339(str).to_utc
  rescue Time::Format::Error
    raise_arg_error "at (not RFC3339)", str
  end

  def platform=(str : String)
    str = str.downcase
    str = "azure" if str == "azr"
    raise_arg_error "platform", str unless str == "azure" || str == "gcp" || str == "aws"
    @platform = str
  end
end
