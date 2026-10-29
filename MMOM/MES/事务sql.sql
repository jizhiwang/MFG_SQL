SELECT now()                   AS sampled_at,
       a.pid,
       a.application_name,
       a.state,
       a.wait_event_type,
       a.wait_event,
       pg_blocking_pids(a.pid) AS blocking_pids,
       now() - a.xact_start    AS transaction_age,
       CASE
           WHEN a.state = 'active'
               THEN now() - a.query_start
           END                 AS active_query_age,
       CASE
           WHEN a.state LIKE 'idle in transaction%'
               THEN now() - a.state_change
           END                 AS idle_transaction_age,
       a.xact_start,
       a.query_start,
       a.query
FROM pg_stat_activity a
WHERE a.datname = current_database()
  AND a.pid <> pg_backend_pid()
  AND (
    a.state = 'active'
        OR a.state LIKE 'idle in transaction%'
    )
ORDER BY (cardinality(pg_blocking_pids(a.pid)) > 0) DESC,
         a.xact_start ASC NULLS LAST,
         a.query_start ASC NULLS LAST,
         a.pid
LIMIT 50;