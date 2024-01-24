SELECT
    cache_rates.schemaname,
    sizes.name AS "Table Name",
    cache_rates.ratio AS "Cache Hit Ratio",
    indexes.ratio AS "Index Hit Ratio",
    CASE WHEN total_reads.cache_reads > 0 THEN ROUND((cache_rates.cache_reads/total_reads.cache_reads * 100), 2) ELSE 0 END AS "Read Percentage",
    CASE WHEN rowcount.estimate = -1 THEN 0 ELSE rowcount.estimate END AS "Row Count",
    CASE WHEN size = 8192 THEN '0 bytes' ELSE pg_size_pretty(size) END AS "Size"
FROM (
    SELECT
        n.nspname AS schemaname,
        c.relname AS name,
        pg_table_size(c.oid) AS size
    FROM pg_class c
    LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
        AND n.nspname !~ '^pg_toast'
        AND c.relkind='r'
) AS sizes
INNER JOIN (
    SELECT
        schemaname,
        relname,
        (sum(heap_blks_hit) / nullif(sum(heap_blks_hit) + sum(heap_blks_read), 0) * 100)::int AS ratio,
        sum(heap_blks_read) AS cache_reads
    FROM pg_statio_user_tables
    GROUP BY relname, schemaname) AS cache_rates ON sizes.name = cache_rates.relname
        AND sizes.schemaname = cache_rates.schemaname
    INNER JOIN (
        SELECT sum(heap_blks_read) AS cache_reads
        FROM pg_statio_user_tables
    ) AS total_reads ON 1 = 1
    LEFT JOIN (
        SELECT
            schemaname,
            relname,
            (sum(idx_blks_hit) / nullif(sum(idx_blks_hit + idx_blks_read),0) * 100)::int AS ratio
        FROM pg_statio_user_indexes
        GROUP BY schemaname,relname
    ) AS indexes ON sizes.name = indexes.relname
        AND sizes.schemaname = indexes.schemaname
    LEFT JOIN (
        SELECT
            reltuples AS estimate,
            c.relname AS name,
            n.nspname AS schemaname
        FROM pg_class c
        LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
        WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
            AND n.nspname !~ '^pg_toast'
            AND c.relkind='r'
    ) AS rowcount ON sizes.name = rowcount.name
         AND sizes.schemaname = rowcount.schemaname
ORDER BY size DESC