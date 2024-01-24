SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query_id::text,
    query
FROM pg_stat_activity
WHERE pg_stat_activity.query <> ''::text
    AND state <> 'idle'
    AND now() - pg_stat_activity.query_start > interval '1 minute'
    AND usesysid not in (SELECT usesysid FROM pg_user WHERE usename like 'crunchy_%')
ORDER BY now() - pg_stat_activity.query_start DESC;