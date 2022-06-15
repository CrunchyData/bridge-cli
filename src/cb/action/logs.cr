require "./action"

require "../dirs"
require "ssh2"

module CB::Action
  class Logs < APIAction
    eid_setter cluster_id

    def run
      tk = CB::Tempkey.for_cluster cluster_id, client: client

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
      raise CB::Program::Error.new(cause: e)
    end
  end
end
