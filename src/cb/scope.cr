require "./action"
require "./cluster_connection"
require "./scope_checks/*"

class CB::Scope < CB::Action
  property cluster_id : String?
  property checks : Array(::Scope::Check.class) = [] of ::Scope::Check.class
  property suite : String?

  def run
    cid = cluster_id
    check_required_args { |missing| missing << "cluster" unless cid }
    cid = cid.not_nil!

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

    ClusterConnection.new(cid, client).db_names
    ClusterConnection.new(cid, client).open do |db|
      to_run.map(&.new(db)).each do |c|
        @output << c << "\n"
      end
    end
  end
end
