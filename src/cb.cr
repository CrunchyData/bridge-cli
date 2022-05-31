module CB
  # Global application constants.
  EID_PATTERN = /\A[a-z0-9]{25}[4aeimquy]\z/
  HOST        = ENV["CB_HOST"]? || "api.crunchybridge.com"

  # Release constants.
  BUILD_RELEASE  = {{ flag?(:release) }}
  SHARDS_VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}
  BUILD_DATE     = {{ `date -u +"%Y%m%d%H%M"`.chomp.stringify }}
  VERSION        = begin
    {% begin %}
      %(#{SHARDS_VERSION}#{"-unrelease" unless BUILD_RELEASE})
    {% end %}
  end
  VERSION_STR = "cb v#{CB::VERSION} (#{CB::BUILD_DATE})"
end

require "./ext/stdlib_ext"
require "./openssl_cert"
require "./cb/*"
