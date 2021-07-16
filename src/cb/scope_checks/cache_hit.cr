require "./check"

module Scope
  @[Meta(name: "Cache Hit Rate", flag: "cache-hit", desc: "Index and table cache hit rate")]
  class CacheHit < Check
    def query
      <<-SQL
        SELECT
          'index hit rate' AS name,
          (sum(idx_blks_hit)) / nullif(sum(idx_blks_hit + idx_blks_read),0)::float AS ratio
        FROM pg_statio_user_indexes
        UNION ALL
        SELECT
         'table hit rate' AS name,
          sum(heap_blks_hit) / nullif(sum(heap_blks_hit) + sum(heap_blks_read),0)::float AS ratio
        FROM pg_statio_user_tables;
      SQL
    end
  end
end

# SQL modified from https://github.com/heroku/heroku-pg-extras/releases/tag/v1.2.3
#
# The MIT License (MIT)
#
# Copyright © Heroku 2008 - 2014
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
