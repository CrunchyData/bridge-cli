require "./check"

module Scope
  @[Meta(name: "Index Hit Rate", flag: "index-hit", desc: "Calculate index hit rate")]
  class IndexHit < Check
    def query
      <<-SQL
        SELECT relname,
           CASE idx_scan
             WHEN 0 THEN 'Insufficient data'
             ELSE (100 * idx_scan / (seq_scan + idx_scan))::text
           END AS "percent of times index used",
           n_live_tup AS "rows in table"
         FROM
           pg_stat_user_tables
         ORDER BY
           n_live_tup DESC;
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
