require "./action"
require "./scope_checks/*"

class CB::Scope < CB::Action
  property cluster_id : String?
  property checks : Array(::Scope::Check.class) = [] of ::Scope::Check.class
  property suite : String?

  def run
    check_required_args { |missing| missing << "cluster" unless cluster_id }

    uri = client.get_cluster_default_role(cluster_id).uri

    self.suite = "quick" if checks.empty? && suite.nil?

    case suite
    when "all"
      self.checks = ::Scope::Check.all.map(&.type) - [::Scope::Mandelbrot]
    when "quick"
      self.checks += [::Scope::TableInfo, ::Scope::IndexHit, ::Scope::Blocking]
    when nil
    else
      raise Error.new("unknown suite '#{suite.inspect}'")
    end

    to_run = checks.uniq.sort_by(&.name)

    DB.open(uri) do |db|
      to_run.map(&.new(db)).each do |c|
        @output << c << "\n"
      end
    end
  end
end
