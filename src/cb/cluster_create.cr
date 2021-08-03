require "./action"

class CB::ClusterCreate < CB::Action
  property ha : Bool = false
  property name : String?
  property plan : String?
  property platform : String?
  property region : String?
  property storage : Int32?
  property team : String?
  property fork : String?
  property at : Time?

  property output : IO

  def initialize(@client : Client, @output = STDOUT)
  end

  def pre_validate
    if fork
      source = client.get_cluster fork

      self.name ||= "Fork of #{source.name}"
      self.platform ||= source.provider_id
      self.region ||= source.region_id
      self.storage ||= source.storage
      self.plan ||= source.plan_id
    else
      self.storage ||= 100
      self.name ||= "Cluster #{Time.utc.to_s("%F %H_%M_%S")}"
    end
  end

  def call
    validate
    cluster = if fork
                @client.fork_cluster self
              else
                @client.create_cluster self
              end
    @output.puts %(Created cluster #{cluster.id.colorize.t_id} "#{cluster.name.colorize.t_name}")
  end

  def validate
    pre_validate
    check_required_args do |missing|
      missing << "ha" if ha.nil?
      missing << "name" unless name
      missing << "plan" unless plan
      missing << "platform" unless platform
      missing << "region" unless region
      missing << "storage" unless storage
      missing << "team" unless team || fork
    end
  end

  def ha=(str : String)
    case str.downcase
    when "true"
      self.ha = true
    when "false"
      self.ha = false
    else
      raise_arg_error "ha", str
    end
  end

  def at=(str : String)
    self.at = Time.parse_rfc3339(str).to_utc
  rescue Time::Format::Error
    raise_arg_error "at (not RFC3339)", str
  end

  def plan=(str : String)
    raise_arg_error "plan", str unless str =~ /\A[a-z0-9\-]+\z/
    @plan = str
  end

  def platform=(str : String)
    str = str.downcase
    str = "azure" if str == "azr"
    raise_arg_error "platform", str unless str == "azure" || str == "gcp" || str == "aws"
    @platform = str
  end

  def region=(str : String)
    raise_arg_error "region", str unless str =~ /\A[a-z0-9\-]+\z/
    @region = str
  end

  def storage=(str : String)
    self.storage = str.to_i_cb
  rescue ArgumentError
    raise_arg_error "storage", str
  end

  def team=(str : String)
    raise_arg_error "team id", str unless str =~ EID_PATTERN
    @team = str
  end
end
