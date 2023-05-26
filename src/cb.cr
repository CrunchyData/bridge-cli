module CB
  # Global application constants.

  EID_PATTERN = /\A[a-z0-9]{25}[4aeimquy]\z/

  # For simple identifiers such as region names, or plan names where we
  # expect only lowercase, numbers, and -
  IDENT_PATTERN = /\A[a-z0-9\-]+\z/

  # For user specified API resource names such as cluster and team names.
  API_NAME_PATTERN = /\A[\p{L}\p{So}][\p{L}\p{N}\p{So}\/\-_ ']{3,48}[\p{L}\p{N}\p{So}]\z/

  HOST = ENV["CB_HOST"]? || "api.crunchybridge.com"

  # Release constants.
  BUILD_RELEASE  = {{ flag?(:release) }}
  SHARDS_VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}
  BUILD_SHA      = {{ env("GIT_SHA") || `git describe --match=NeVeRmAtCh --always --dirty 2> /dev/null || echo "unknown sha"`.chomp.stringify }}
  VERSION        = begin
    {% begin %}
      %(#{SHARDS_VERSION}#{"-unrelease" unless BUILD_RELEASE})
    {% end %}
  end

  VERSION_STR = "cb v#{CB::VERSION} (#{CB::BUILD_SHA})"
end

require "./ext/stdlib_ext"
require "./openssl_cert"
require "./cb/*"
require "./client/*"
require "./lib/*"
require "./models/*"
require "./ui/*"
