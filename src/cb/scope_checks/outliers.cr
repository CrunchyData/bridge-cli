require "./check"

module Scope
  @[Meta(name: "Outliers", desc: "Queries with the longest running time in aggregate")]
  class Outliers < Check
    def query
      <<-SQL
        SELECT
          (interval '1 millisecond' * total_exec_time)::text AS "total exec time",
          to_char((total_exec_time/sum(total_exec_time) OVER()) * 100, 'FM90D0') || '%' AS "prop exec time",
          to_char(calls, 'FM999G999G999G990') AS ncalls,
          (interval '1 millisecond' * (blk_read_time + blk_write_time))::text AS "sync io time",
          CASE WHEN length(query) <= 60 THEN query ELSE substr(query, 0, 59) || '…' END AS query
        FROM pg_stat_statements
        -- WHERE userid = (SELECT usesysid FROM pg_user WHERE usename = current_user LIMIT 1)
        ORDER BY 1 DESC
        LIMIT 10
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
