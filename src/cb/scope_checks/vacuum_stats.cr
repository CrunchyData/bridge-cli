require "./check"

module Scope
  @[Meta(name: "Vacuum Stats", desc: "dead rows and whether an automatic vacuum info")]
  class VacuumStats < Check
    def query
      <<-SQL
        WITH table_opts AS (
          SELECT
            pg_class.oid, relname, nspname, array_to_string(reloptions, '') AS relopts
          FROM
             pg_class INNER JOIN pg_namespace ns ON relnamespace = ns.oid
        ), vacuum_settings AS (
          SELECT
            oid, relname, nspname,
            CASE
              WHEN relopts LIKE '%autovacuum_vacuum_threshold%'
                THEN substring(relopts, '.*autovacuum_vacuum_threshold=([0-9.]+).*')::integer
                ELSE current_setting('autovacuum_vacuum_threshold')::integer
              END AS autovacuum_vacuum_threshold,
            CASE
              WHEN relopts LIKE '%autovacuum_vacuum_scale_factor%'
                THEN substring(relopts, '.*autovacuum_vacuum_scale_factor=([0-9.]+).*')::real
                ELSE current_setting('autovacuum_vacuum_scale_factor')::real
              END AS autovacuum_vacuum_scale_factor
          FROM
            table_opts
        )
        SELECT
          vacuum_settings.nspname AS schema,
          vacuum_settings.relname AS table,
          to_char(psut.last_vacuum, 'YYYY-MM-DD HH24:MI') AS "last vacuum",
          to_char(psut.last_autovacuum, 'YYYY-MM-DD HH24:MI') AS "last autovacuum",
          to_char(psut.n_dead_tup, '9G999G999G999') AS "dead rowcount",
          to_char(pg_class.reltuples, '9G999G999G999') AS rowcount,
          to_char(autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples), '9G999G999G999') AS "autovacuum threshold",
          CASE
            WHEN autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples) < psut.n_dead_tup
            THEN 'yes'
          END AS "expect autovacuum"
        FROM
          pg_stat_user_tables psut INNER JOIN pg_class ON psut.relid = pg_class.oid
            INNER JOIN vacuum_settings ON pg_class.oid = vacuum_settings.oid
        ORDER BY 1
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
