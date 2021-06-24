require "./action"

class CB::CreateCluster < CB::Action
  Error = Program::Error

  property ha : Bool
  property name : String?
  property plan : String?
  property platform : String?
  property region : String?
  property storage : Int32
  property team : String?

  property output : IO

  def initialize(@client : Client, @output = STDOUT)
    @ha = false
    @storage = 100
    @name = "Cluster #{Time.utc.to_s("%F %H_%M_%S")}"
  end

  def call
    validate
    cluster = @client.create_cluster self
    @output.puts %(Created cluster #{cluster.id.colorize.t_id} "#{cluster.name.colorize.t_name}")
  end

  def validate
    check_required_args do |missing|
      missing << "ha" if ha.nil?
      missing << "name" unless name
      missing << "plan" unless plan
      missing << "platform" unless platform
      missing << "region" unless region
      missing << "storage" unless storage
      missing << "team" unless team
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

  def team=(str : String)
    raise_arg_error "team id", str unless str =~ EID_PATTERN
    @team = str
  end
end
