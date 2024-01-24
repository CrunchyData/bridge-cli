WITH RECURSIVE pg_inherit(inhrelid, inhparent) AS (
    SELECT inhrelid, inhparent
    FROM pg_inherits
    UNION
    SELECT child.inhrelid, parent.inhparent
    FROM pg_inherit child, pg_inherits parent
    WHERE child.inhparent = parent.inhrelid
),
pg_inherit_short AS (
    SELECT *
    FROM pg_inherit
    WHERE inhparent NOT IN (SELECT inhrelid FROM pg_inherit)
)
SELECT
    table_schema
    , TABLE_NAME
    , CASE WHEN row_estimate = -1 THEN 0 ELSE row_estimate END
    , CASE WHEN total_bytes = 8192 THEN '0 bytes' ELSE pg_size_pretty(total_bytes) END as "Total"
    , CASE WHEN index_bytes = 8192 THEN '0 bytes' ELSE pg_size_pretty(index_bytes) END as "Index"
    , CASE WHEN toast_bytes = 8192 THEN '0 bytes' ELSE pg_size_pretty(toast_bytes) END as "Toast"
    , CASE WHEN table_bytes = 8192 THEN '0 bytes' ELSE pg_size_pretty(table_bytes) END as "Table"
FROM (
    SELECT *
    , total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
    FROM (
        SELECT c.oid
            , nspname AS table_schema
            , relname AS TABLE_NAME
            , SUM(c.reltuples) OVER (partition BY parent) AS row_estimate
            , SUM(pg_total_relation_size(c.oid)) OVER (partition BY parent) AS total_bytes
            , SUM(pg_indexes_size(c.oid)) OVER (partition BY parent) AS index_bytes
            , SUM(pg_total_relation_size(reltoastrelid)) OVER (partition BY parent) AS toast_bytes
            , parent
        FROM (
            SELECT
                pg_class.oid
                , reltuples
                , relname
                , relnamespace
                , pg_class.reltoastrelid
                , COALESCE(inhparent, pg_class.oid) parent
            FROM pg_class
            LEFT JOIN pg_inherit_short ON inhrelid = oid
            WHERE relkind IN ('r', 'p')
        ) c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE NOT nspname in ('pg_catalog', 'information_schema')
    ) a
    WHERE oid = parent
) a
ORDER BY total_bytes DESC;