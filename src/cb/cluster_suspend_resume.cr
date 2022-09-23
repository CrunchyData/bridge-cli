require "./action"

module CB
  class ClusterSuspend < APIAction
    cluster_identifier_setter cluster_id

    def validate
      check_required_args do |missing|
        missing << "cluster" if cluster_id.empty?
      end
    end

    def run
      validate

      c = client.suspend_cluster cluster_id[:cluster]
      output << "suspended cluster " << c.name.colorize.t_name << "\n"
    end
  end

  class ClusterResume < APIAction
    cluster_identifier_setter cluster_id

    def validate
      check_required_args do |missing|
        missing << "cluster" if cluster_id.empty?
      end
    end

    def run
      validate

      c = client.resume_cluster cluster_id[:cluster]
      output << "resumed cluster " << c.name.colorize.t_name << "\n"
    end
  end
end
