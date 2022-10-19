require "./action"

module CB
  class BackupCapture < APIAction
    cluster_identifier_setter cluster_id

    def validate
      check_required_args do |missing|
        missing << "cluster id" if cluster_id.empty?
      end
    end

    def run
      validate

      client.backup_start cluster_id[:cluster]
      c = client.get_cluster cluster_id[:cluster]
      output << "requested backup capture of " << c.name.colorize.t_name << "\n"
    end
  end

  class BackupList < APIAction
    cluster_identifier_setter cluster_id

    def validate
      check_required_args do |missing|
        missing << "cluster id" if cluster_id.empty?
      end
    end

    def run
      backups = client.backup_list cluster_id[:cluster]

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

  class BackupToken < APIAction
    cluster_identifier_setter cluster_id
    eid_setter stanza
    ident_setter format

    def validate
      check_required_args do |missing|
        missing << "cluster id" if cluster_id.empty?
      end
    end

    def run
      token = client.backup_token cluster_id[:cluster]
      raise Error.new("backup token not created") if token.nil?

      cred = case
             when !token.aws.nil?
               token.aws
             when !token.azure.nil?
               token.azure
             else
               "No Credentials"
             end

      case @format
      when nil, "default"
        output_default(token, cred)
      when "pgbackrest"
        output_pgbackrest(token, cred)
      else
        raise Error.new("invalid format #{@format}")
      end
    end

    def output_default(token, cred)
      output << "Type:".colorize.bold << "            #{token.type}\n"
      output << "Repo Path:".colorize.bold << "       #{token.repo_path}\n"
      output << "Stanza:".colorize.bold << "          #{token.stanza}\n"
      if cred.is_a?(Client::AWSBackrestCredential)
        output << "S3 Bucket:".colorize.bold << "       #{cred.s3_bucket}\n"
        output << "S3 Key:".colorize.bold << "          #{cred.s3_key}\n"
        output << "S3 Key Secret:".colorize.bold << "   #{cred.s3_key_secret}\n"
        output << "S3 Region:".colorize.bold << "       #{cred.s3_region}\n"
        output << "S3 Token:".colorize.bold << "        #{cred.s3_token}\n"
      elsif cred.is_a?(Client::AzureBackrestCredential)
        output << "Azure Account:".colorize.bold << "   #{cred.azure_account}\n"
        output << "Azure Container:".colorize.bold << " #{cred.azure_container}\n"
        output << "Azure Key:".colorize.bold << "       #{cred.azure_key}\n"
        output << "Azure Key Type:".colorize.bold << "  #{cred.azure_key_type}\n"
      else
        output << cred << '\n'
      end
    end

    def output_pgbackrest(token, cred)
      output << "[#{token.stanza}]\n"
      output << "repo1-type=#{token.type}\n"
      output << "repo1-path=#{token.repo_path}\n"
      if cred.is_a?(Client::AWSBackrestCredential)
        output << <<-AWS
repo1-s3-bucket=#{cred.s3_bucket}
repo1-s3-key=#{cred.s3_key}
repo1-s3-key-secret=#{cred.s3_key_secret}
repo1-s3-token=#{cred.s3_token}
repo1-s3-endpoint=s3.dualstack.#{cred.s3_region}.amazonaws.com
repo1-s3-region=#{cred.s3_region}
AWS
      elsif cred.is_a?(Client::AzureBackrestCredential)
        output << <<-AZURE
repo1-azure-account=#{cred.azure_account}
repo1-azure-container=#{cred.azure_container}
repo1-azure-key-type=#{cred.azure_key_type}
repo1-azure-key=#{cred.azure_key}
AZURE
      else
        output << cred << '\n'
      end
    end
  end
end
