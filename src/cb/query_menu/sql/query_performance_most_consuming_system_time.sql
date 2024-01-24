SELECT
    (total_exec_time + total_plan_time)::int AS total_time,
    total_exec_time::int AS total_execution_time,
    total_plan_time::int AS total_planning_time,
    mean_exec_time::int AS average_execution_time,
    calls,
    query
FROM pg_stat_statements
WHERE query != '<insufficient privilege>'
ORDER BY total_time DESC
LIMIT 50;