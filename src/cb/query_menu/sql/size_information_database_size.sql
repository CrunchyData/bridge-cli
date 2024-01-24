WITH data AS (
    SELECT
        d.oid,
        (SELECT spcname FROM pg_tablespace WHERE oid = dattablespace) AS tblspace,
        d.datname AS database_name,
        pg_catalog.pg_get_userbyid(d.datdba) AS owner,
        has_database_privilege(d.datname, 'connect') AS has_access,
        pg_database_size(d.datname) AS size,
        blks_hit,
        blks_read,
        temp_files,
        temp_bytes
    FROM pg_catalog.pg_database d
    JOIN pg_stat_database s on s.datid = d.oid
    WHERE d.datname not in ('template1', 'crunchy_monitoring', 'template0')
), data2 AS (
    SELECT
        NULL::oid AS oid,
        NULL AS tblspace,
        '*** TOTAL ***' AS database_name,
        NULL AS owner,
        true AS has_access,
        sum(size) AS size,
        sum(blks_hit) AS blks_hit,
        sum(blks_read) AS blks_read,
        sum(temp_files) AS temp_files,
        sum(temp_bytes) AS temp_bytes
    FROM data
    UNION all
    SELECT NULL::oid, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL
    UNION all
    SELECT
        oid,
        tblspace,
        database_name,
        owner,
        has_access,
        size,
        blks_hit,
        blks_read,
        temp_files,
        temp_bytes
    FROM data
)
SELECT
    database_name || coalesce(' [' || nullif(tblspace, 'pg_default') || ']', '') AS "Database",
    CASE WHEN has_access THEN
        pg_size_pretty(size) || ' (' || round(
            100 * size::numeric / nullif(sum(size) over (partition by (oid is NULL)), 0),
            2
        )::text || '%)'
    ELSE 'no access'
    END AS "Size",
    CASE WHEN blks_hit + blks_read > 0 THEN
        (round(blks_hit * 100::numeric / (blks_hit + blks_read), 2))::text || '%'
    ELSE NULL
    END AS "Cache eff.",
    temp_files::text || coalesce(' (' || pg_size_pretty(temp_bytes) || ')', '') AS "Temp. Files"
FROM data2
ORDER BY oid is NULL DESC, size DESC NULLS LAST;