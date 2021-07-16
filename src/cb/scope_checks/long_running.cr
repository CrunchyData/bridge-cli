require "./check"

module Scope
  @[Meta(name: "Long Running Queries", flag: "long-running", desc: "Queries running for more than five minutes")]
  class LongRunning < Check
    def query
      <<-SQL
        SELECT
          pid,
          (now() - pg_stat_activity.query_start)::text AS duration,
          query AS query
        FROM
          pg_stat_activity
        WHERE
          pg_stat_activity.query <> ''::text
          AND state <> 'idle'
          AND now() - pg_stat_activity.query_start > interval '5 minutes'
        ORDER BY
          now() - pg_stat_activity.query_start DESC;
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
