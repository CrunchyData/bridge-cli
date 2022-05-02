# return a default cert path if necessary to do so like when static linking and
# the burnt in path has a chance of being, otherwise return nil and use
# whatever the linked openssl is configured to use
private def find_default_path : String?
  {% if flag?(:darwin) %}
    # workaround: Can't easily build for arm macs, so they use the
    # statically linked x86 under rosetta. This however seems to hardcode
    # the homebrew location of the tls certs, which will fail unless they
    # have happened to install openssl with homebrew
    return "/private/etc/ssl/cert.pem"
  {% end %}

  {% if flag?(:linux) && flag?(:static) %}
    # when statically linking for linux, it hardcodes the path and different
    # distros put them in different places.

    # Possible certificate files; stop after finding one.
    return [
      "/etc/ssl/certs/ca-certificates.crt",                # Debian/Ubuntu/Gentoo etc.
      "/etc/pki/tls/certs/ca-bundle.crt",                  # Fedora/RHEL 6
      "/etc/ssl/ca-bundle.pem",                            # OpenSUSE
      "/etc/pki/tls/cacert.pem",                           # OpenELEC
      "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem", # CentOS/RHEL 7
      "/etc/ssl/cert.pem",                                 # Alpine Linux
    ].find { |path| File.exists? path }
  {% end %}

  nil
end

module CB
  # Allow manually overriding the cert file location
  SSL_CERT_FILE = ENV["SSL_CERT_FILE"]? || find_default_path
end
