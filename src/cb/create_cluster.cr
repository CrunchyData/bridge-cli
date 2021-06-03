class CB::CreateCluster
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

  def run
    validate
    cluster = @client.create_cluster self
    @output.puts %(Created cluster #{cluster.id.colorize.light_cyan} "#{cluster.name.colorize.cyan}")
  end

  def validate
    missing = [] of String
    missing << "ha" if ha.nil?
    missing << "name" unless name
    missing << "plan" unless plan
    missing << "platform" unless platform
    missing << "region" unless region
    missing << "storage" unless storage
    missing << "team" unless team

    unless missing.empty?
      raise Error.new "Missing required argument: #{missing.map(&.colorize.red).join(", ")}"
    end

    return true
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
    i = str.to_i(base: 10, whitespace: true, underscore: true, prefix: false, strict: true, leading_zero_is_octal: false)

    self.storage = i
  rescue ArgumentError
    raise_arg_error "storage", str
  end

  def storage=(i : Int32)
    raise_arg_error "storage", i unless 25 <= i < 100_000
    @storage = i
  end

  def team=(str : String)
    raise_arg_error "team id", str unless str =~ /\A[a-z0-9]{25}[4aeimquy]\z/
    @team = str
  end

  private def raise_arg_error(field, value)
    raise Error.new "Invalid #{field.colorize.bold}: '#{value.to_s.colorize.red}'"
  end
end
