module CB
  EID_PATTERN = /\A[a-z0-9]{25}[4aeimquy]\z/

  VERSION       = {{ `shards version "#{__DIR__}"`.chomp.stringify }}
  BUILD_RELEASE = {{ flag?(:release) }}
  BUILD_DATE    = {{ `date -u +"%Y%m%d%H%M"`.chomp.stringify }}
  BUILD_ID = begin
    {% begin %}
      %(#{BUILD_DATE}#{"-dev" unless BUILD_RELEASE})
    {% end %}
  end
end

require "./stdlib_ext"
require "./cb/*"
