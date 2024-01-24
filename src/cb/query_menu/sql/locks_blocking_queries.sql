WITH sos AS (
	SELECT array_cat(array_agg(pid),
           array_agg((pg_blocking_pids(pid))[array_length(pg_blocking_pids(pid),1)])) pids
	FROM pg_locks
	WHERE NOT granted
)
SELECT a.pid, a.usename, a.datname, a.state,
	   a.wait_event_type || ': ' || a.wait_event AS wait_event,
       current_timestamp-a.state_change time_in_state,
       current_timestamp-a.xact_start time_in_xact,
       l.relation::regclass relname,
       l.locktype, l.mode, l.page, l.tuple,
       pg_blocking_pids(l.pid) blocking_pids,
       (pg_blocking_pids(l.pid))[array_length(pg_blocking_pids(l.pid),1)] last_session,
       COALESCE((pg_blocking_pids(l.pid))[1]||'.'||COALESCE(CASE WHEN locktype='transactionid' THEN 1 ELSE array_length(pg_blocking_pids(l.pid),1)+1 END,0),a.pid||'.0') lock_depth,
       a.query
FROM pg_stat_activity a
     JOIN sos s ON (a.pid = any(s.pids))
     LEFT OUTER JOIN pg_locks l on (a.pid = l.pid and not l.granted)
ORDER BY lock_depth;