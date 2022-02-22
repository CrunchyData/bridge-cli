require "./action"

class CB::Detach < CB::Action
  property cluster_id : String?
  property confirmed : Bool = false

  def run
    validate

    c = client.get_cluster cluster_id

    unless confirmed
      output << "About to " << "detach".colorize.t_warn << " cluster " << c.name.colorize.t_name
      output << ".\n  Type the cluster's name to confirm: "
      response = input.gets

      if !(c.name == response)
        raise Error.new "Response did not match, did not detach the cluster"
      end
    end

    client.detach_cluster cluster_id
    output.puts "Cluster #{c.id.colorize.t_id} detached."
  end

  def validate
    check_required_args do |missing|
      missing << "cluster" unless cluster_id
    end
  end

  def cluster_id=(str : String)
    raise_arg_error "cluster_id", str unless str =~ EID_PATTERN
    @cluster_id = str
  end
end
