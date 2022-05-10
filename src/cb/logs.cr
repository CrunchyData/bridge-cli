require "./action"

require "./dirs"
require "ssh2"

module CB
  class Logs < Action
    eid_setter cluster_id
    property subdomain : String?

    def run
      tk = Tempkey.for_cluster cluster_id, client: client

      host = "p.#{cluster_id}.#{subdomain}.pgbridgedev.com"
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
    end
  end
end
