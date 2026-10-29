SELECT
    l.pid AS 进程ID,
    l.mode AS 锁模式,
    l.granted AS 是否持有,
    a.query AS 当前SQL,
    a.state AS 会话状态,
    a.xact_start AS 事务开始时间,
    a.query_start AS 查询开始时间,
    age(now(), a.xact_start) AS 事务已存在时间,
    age(now(), a.query_start) AS 查询已执行时间
FROM
    pg_locks l
JOIN
    pg_stat_activity a ON l.pid = a.pid
JOIN
    pg_class c ON l.relation = c.oid
ORDER BY
    age(now(), a.query_start) DESC;  -- 按查询已执行时间倒序
-- 可选：LIMIT 20;                     -- 仅查看最长的前N个




SELECT
  pg_terminate_backend (pid)
FROM
  pg_stat_activity
WHERE
  pid IN (2782869,2794032,2799560,2799576,2799621,2799901,2800191,2803499,2806229);



SELECT DISTINCT l.pid AS 进程ID
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE a.xact_start IS NOT NULL
  AND a.xact_start < now() - interval '50 minutes'
  AND l.pid <> pg_backend_pid()
ORDER BY l.pid;




