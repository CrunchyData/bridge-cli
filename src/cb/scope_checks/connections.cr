require "./check"

module Scope
  @[Meta(name: "Connections", desc: "Connection counts per role")]
  class Connections < Check
    def query
      <<-SQL
        SELECT count(*), usename AS name
        FROM pg_stat_activity
        WHERE usename IS NOT NULL
        GROUP by 2
        ORDER by 1 DESC
      SQL
    end
  end
end
