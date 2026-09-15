# ======================任务===============================
SELECT
    t.id,
    -- 提取 IM 工单号，没有则返回 NULL
    REGEXP_SUBSTR(t.name, '^IM[0-9]+') AS ticket_no,
    -- 去除开头的 "IM数字-" 后的纯净标题
    COALESCE(
        NULLIF(TRIM(REGEXP_REPLACE(t.name, '^IM[0-9]+-[[:space:]]*', '')), ''),
        t.name
    ) AS title,
    COALESCE(
        NULLIF(TRIM(REGEXP_REPLACE(
            REGEXP_SUBSTR(t.`desc`, '模块[:：][[:space:]]*[^<[:space:]]+'),
            '^模块[:：][[:space:]]*', ''
        )), ''),
        '-'
    ) AS module_name,
    CASE WHEN t.status = 'cancel' THEN '已取消'
         WHEN t.status = 'wait'   THEN '未开始'
         WHEN t.status = 'doing'  THEN '进行中'
         WHEN t.status = 'done'   THEN '已完成'
         WHEN t.status = 'pause'  THEN '已暂停'
         WHEN t.status = 'closed' THEN '已关闭'
         ELSE t.status END AS status,
    CASE WHEN t.status IN ('done', 'closed') THEN t.finishedBy ELSE t.assignedTo END AS owner,
    t.openedDate,
    t.finishedDate,
    ua.realname AS owner_name
FROM zt_task t
LEFT JOIN zt_user ua ON ua.account =
    CASE WHEN t.status IN ('done', 'closed') THEN t.finishedBy ELSE t.assignedTo END
    AND ua.deleted = '0'
WHERE t.deleted = '0'
  AND t.status IN ('wait', 'doing', 'done', 'pause', 'cancel', 'closed')
  AND t.execution = 1202
  AND (
      t.openedDate   >= DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY)
      OR t.finishedDate >= DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY)
  )
ORDER BY t.openedDate DESC;

-- =======================BUG===========================
SELECT
    b.id,
    -- 提取 IM 工单号，没有则返回 NULL
    REGEXP_SUBSTR(b.title, '^IM[0-9]+') AS ticket_no,
    -- 去除开头的 "IM数字-" 后的纯净标题
    COALESCE(
        NULLIF(TRIM(REGEXP_REPLACE(b.title, '^IM[0-9]+-[[:space:]]*', '')), ''),
        b.title
    ) AS title,
    COALESCE(
        NULLIF(TRIM(REGEXP_REPLACE(
            REGEXP_SUBSTR(b.steps, '模块[:：][[:space:]]*[^<[:space:]]+'),
            '^模块[:：][[:space:]]*', ''
        )), ''),
        '-'
    ) AS module_name,
    CASE WHEN b.status = 'active'   THEN '激活'
         WHEN b.status = 'resolved' THEN '已解决'
         WHEN b.status = 'closed'   THEN '已关闭'
         ELSE b.status END AS status,
    CASE WHEN b.status IN ('resolved', 'closed') THEN b.resolvedBy ELSE b.assignedTo END AS owner,
    b.openedDate,
    b.resolvedDate,
    ua.realname AS owner_name
FROM zt_bug b
LEFT JOIN zt_user ua ON ua.account =
    CASE WHEN b.status IN ('resolved', 'closed') THEN b.resolvedBy ELSE b.assignedTo END
    AND ua.deleted = '0'
WHERE b.deleted = '0'
  AND b.status IN ('active', 'resolved', 'closed')
  AND b.execution = 1202
  AND (
      b.openedDate   >= DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY)
      OR b.resolvedDate >= DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY)
  )
ORDER BY b.openedDate DESC;