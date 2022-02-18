module CB
  EID_PATTERN = /\A[a-z0-9]{25}[4aeimquy]\z/

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

require "./stdlib_ext"
require "./cb/*"
