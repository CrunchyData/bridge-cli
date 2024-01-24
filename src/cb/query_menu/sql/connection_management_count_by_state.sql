SELECT
    usename AS user_name,
    state,
    count(*) AS connection_count
FROM pg_stat_activity
WHERE usename NOT IN ('crunchy_replication', 'crunchy_superuser')
GROUP BY usename, state
ORDER BY 3 DESC;