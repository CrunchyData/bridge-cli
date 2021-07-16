require "./check"

module Scope
  @[Meta(name: "Locks", desc: "Queries with active locks")]
  class Locks < Check
    def query
      <<-SQL
        SELECT
          pg_stat_activity.pid,
          pg_class.relname,
          pg_locks.transactionid AS "transaction id",
          pg_locks.granted,
          CASE WHEN length(pg_stat_activity.query) <= 60 THEN pg_stat_activity.query ELSE substr(pg_stat_activity.query, 0, 59) || '…' END as "query snippet",
          age(now(),pg_stat_activity.query_start)::text AS "age"
        FROM pg_stat_activity,pg_locks left
        OUTER JOIN pg_class
          ON (pg_locks.relation = pg_class.oid)
        WHERE pg_stat_activity.query <> '<insufficient privilege>'
          AND pg_locks.pid = pg_stat_activity.pid
          AND pg_locks.mode = 'ExclusiveLock'
          AND pg_stat_activity.pid <> pg_backend_pid() order by query_start;
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
