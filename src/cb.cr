module CB
  VERSION     = "0.2.0"
  EID_PATTERN = /\A[a-z0-9]{25}[4aeimquy]\z/
end

require "./stdlib_ext"
require "./cb/*"
