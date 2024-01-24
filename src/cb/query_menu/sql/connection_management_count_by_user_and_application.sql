SELECT
    usename as user_name,
    application_name,
    count(*) as connection_count
FROM pg_stat_activity
WHERE usename NOT IN ('crunchy_replication', 'crunchy_superuser')
GROUP BY usename, application_name
ORDER BY 3 DESC;