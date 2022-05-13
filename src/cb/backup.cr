require "./action"

module CB
  class Client
    jrecord Backup, name : String, started_at : Time, finished_at : Time, start_lsn : String, end_lsn : String, size_bytes : UInt64

    def backup_list(id)
      resp = get "clusters/#{id}/backups"
      Array(Backup).from_json resp.body
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
      start_lsn_max = {backups.map(&.start_lsn.size).max, 9}.max

      if output.tty?
        output << "backup".ljust(name_max) << "\tsize    \tstarted at          \tfinished at          \t" << "start lsn".ljust(start_lsn_max) << "\tend lsn\n"
      end

      backups.each do |bk|
        output << bk.name.ljust(name_max).colorize.t_name << '\t'
        output << (output.tty? ? bk.size_bytes.humanize_bytes.ljust(8) : bk.size_bytes.to_s.rjust(20)) << '\t'
        output << bk.started_at.to_rfc3339 << '\t'
        output << bk.finished_at.to_rfc3339.colorize.bold << '\t'
        output << bk.start_lsn.ljust(start_lsn_max) << '\t'
        output << bk.end_lsn.colorize.bold << '\n'
      end
    end
  end
end
