require "./action"

require "./dirs"
require "ssh2"

module CB
  class Logs < APIAction
    cluster_identifier_setter cluster_id

    def validate
      check_required_args do |missing|
        missing << "cluster" if cluster_id.empty?
      end
    end

    def run
      validate

      tk = Tempkey.for_cluster cluster_id, client: client

      host = "p.#{cluster_id}.db.postgresbridge.com"
      socket = TCPSocket.new(host, 22, connect_timeout: 1)
      ssh = SSH2::Session.new(socket)
      ssh.login_with_data("cormorant", tk.private_key, tk.public_key)

      ch = ssh.open_session
      ch.shell
      ch.write "logs\n".to_slice

      buffer = uninitialized UInt8[4096]
      while (read_bytes = ch.read(buffer.to_slice)) > 0
        output.write buffer.to_slice[0, read_bytes]
      end
    rescue e
      raise Program::Error.new(cause: e)
    end
  end
end
