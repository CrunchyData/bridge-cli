SELECT
    (mean_exec_time + mean_plan_time)::int AS average_time,
    mean_exec_time::int AS average_execution_time,
    mean_plan_time::int AS average_planning_time,
    calls,
    query
FROM pg_stat_statements
WHERE calls > 1
    AND query != '<insufficient privilege>'
ORDER BY average_time DESC
LIMIT 50;