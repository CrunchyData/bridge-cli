require "./action"

module CB
  class BackupCapture < Action
    eid_setter cluster_id

    def run
      check_required_args do |missing|
        missing << "cluster id" unless cluster_id
      end

      client.put "clusters/#{cluster_id}/actions/start-backup"
      c = client.get_cluster cluster_id
      output << "requested backup capture of " << c.name.colorize.t_name << "\n"
    end
  end

  class Client
    jrecord Backup,
      name : String,
      started_at : Time,
      finished_at : Time,
      lsn_start : String,
      lsn_stop : String,
      size_bytes : UInt64

    def backup_list(id)
      resp = get "clusters/#{id}/backups"
      Array(Backup).from_json resp.body, root: "backups"
    end
  end

  class BackupList < Action
    eid_setter cluster_id

    def run
      check_required_args do |missing|
        missing << "cluster id" unless cluster_id
      end

      backups = client.backup_list cluster_id

      if backups.empty?
        output << "no backups yet"
        return
      end

      name_max = {backups.map(&.name.size).max, 6}.max
      lsn_start_max = {backups.map(&.lsn_start.size).max, 9}.max

      if output.tty?
        output << "backup".ljust(name_max) << "\tsize    \tstarted at          \tfinished at          \t" << "lsn start".ljust(lsn_start_max) << "\tlsn stop\n"
      end

      backups.each do |bk|
        output << bk.name.ljust(name_max).colorize.t_name << '\t'
        output << (output.tty? ? bk.size_bytes.humanize_bytes.ljust(8) : bk.size_bytes.to_s.rjust(20)) << '\t'
        output << bk.started_at.to_rfc3339 << '\t'
        output << bk.finished_at.to_rfc3339.colorize.bold << '\t'
        output << bk.lsn_start.ljust(lsn_start_max) << '\t'
        output << bk.lsn_stop.colorize.bold << '\n'
      end
    end
  end
end
