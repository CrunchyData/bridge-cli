require "./action"

class CB::ClusterFork < CB::Action
  property cluster_id : String?
  property at : Time?
  property name : String?
  property plan : String?
  property platform : String?
  property region : String?
  property storage : Int32?
  property ha : Bool = false

  def call
    pre_validate
    validate
    resp = client.post "clusters/#{cluster_id}/forks", {
      name:        name,
      plan_id:     plan,
      storage:     storage,
      provider_id: platform,
      region_id:   region,
      target_time: at.try(&.to_rfc3339),
      is_ha:       ha,
    }
    pp! resp
  end

  def pre_validate
    check_required_args { |missing| missing << "cluster" unless cluster_id }
    source = client.get_cluster cluster_id

    self.name ||= "Fork of #{source.name}"
    self.platform ||= source.provider_id
    self.region ||= source.region_id
    self.storage ||= source.storage
    self.plan ||= source.plan_id
  end

  def validate
    check_required_args do |missing|
      missing << "cluster" unless cluster_id
      missing << "name" unless name
      missing << "plan" unless plan
      missing << "platform" unless platform
      missing << "region" unless region
      missing << "storage" unless storage
    end
  end

  def at=(str : String)
    self.at = Time.parse_rfc3339(str).to_utc
  rescue Time::Format::Error
    raise_arg_error "at (not RFC3339)", str
  end

  # all below copied from create cluster, TODO: remove dupe
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

  def name=(str : String)
    raise_arg_error "name", str unless str =~ /\A[ \w_]+\z/
    @name = str
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

  def storage=(i : Int32)
    raise_arg_error "storage", i unless 25 <= i < 100_000
    @storage = i
  end
end
