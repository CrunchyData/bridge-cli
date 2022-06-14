require "./action"

module CB::Action
  class ClusterSuspend < APIAction
    eid_setter cluster_id

    def run
      client.put "clusters/#{cluster_id}/actions/suspend"
      c = client.get_cluster cluster_id
      output << "suspended cluster " << c.name.colorize.t_name << "\n"
    end
  end

  class ClusterResume < APIAction
    eid_setter cluster_id

    def run
      client.put "clusters/#{cluster_id}/actions/resume"
      c = client.get_cluster cluster_id
      output << "resumed cluster " << c.name.colorize.t_name << "\n"
    end
  end
end
