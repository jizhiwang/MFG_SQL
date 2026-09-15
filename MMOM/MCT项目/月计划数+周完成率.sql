WITH win AS (
    SELECT DATE_TRUNC('month', CURRENT_DATE) AS month_start,
           DATE_TRUNC('week',  CURRENT_DATE) AS week_start,
           CURRENT_DATE + INTERVAL '1 day'   AS day_end_excl
),

plan AS (
    SELECT om.number AS operation_number, MAX(om.name) AS operation_name,
           SUM(CASE WHEN sr.plan_date >= win.month_start AND sr.plan_date < win.day_end_excl
                    THEN sr.daily_qty ELSE 0 END) AS month_scheduled_qty,
           SUM(CASE WHEN sr.plan_date >= win.week_start  AND sr.plan_date < win.day_end_excl
                    THEN sr.daily_qty ELSE 0 END) AS week_scheduled_qty
    FROM mbm_aps_schedule_report sr
             INNER JOIN mbm_aps_process_tech_order  pto ON sr.process_task_id = pto.id
             INNER JOIN mbm_mdm_operation_version   ov  ON pto.process_tech_id = ov.id
             INNER JOIN mbm_mdm_operation_master    om  ON ov.operation_master_id = om.id
             CROSS JOIN win
    WHERE om.number IN ('79081','79101')

      AND sr.plan_date >= LEAST(win.month_start, win.week_start)
      AND sr.plan_date <  win.day_end_excl
    GROUP BY om.number
),

done AS (
    SELECT om.number AS operation_number, MAX(om.name) AS operation_name,
           SUM(peh.qty) AS week_completed_qty
    FROM mbm_mes_proc_exe_history peh
             INNER JOIN mbm_aps_process_tech_order  pto ON peh.process_tech_order_id = pto.id
             INNER JOIN mbm_mdm_operation_version   ov  ON pto.process_tech_id = ov.id
             INNER JOIN mbm_mdm_operation_master    om  ON ov.operation_master_id = om.id
             CROSS JOIN win
    WHERE om.number IN ('79081','79101')
      AND peh.complete_time IS NOT NULL
      AND (peh.delete_flag IS NULL OR peh.delete_flag <> '1')
      AND peh.create_date >= win.week_start
      AND peh.create_date <  win.day_end_excl
    GROUP BY om.number
),
merged AS (
    SELECT COALESCE(pl.operation_number, dn.operation_number) AS operation_number,
           COALESCE(pl.operation_name, dn.operation_name)     AS operation_name,
           COALESCE(pl.month_scheduled_qty, 0)                AS month_scheduled_qty,
           COALESCE(pl.week_scheduled_qty, 0)                 AS week_scheduled_qty,
           COALESCE(dn.week_completed_qty, 0)                 AS week_completed_qty
    FROM plan pl
             FULL JOIN done dn ON dn.operation_number = pl.operation_number
)
SELECT CASE WHEN GROUPING(m.operation_number) = 1 THEN '合计' ELSE m.operation_number END AS "标准工序代码",
       CASE WHEN GROUPING(m.operation_number) = 1 THEN ''   ELSE MAX(m.operation_name) END AS "工序名称",
       COALESCE(SUM(m.month_scheduled_qty), 0) AS "当月排产量",
       COALESCE(SUM(m.week_scheduled_qty), 0)  AS "本周排产量",
       COALESCE(SUM(m.week_completed_qty), 0)  AS "本周完成量",
       ROUND(COALESCE(SUM(m.week_completed_qty), 0)
                 / NULLIF(COALESCE(SUM(m.week_scheduled_qty), 0), 0) * 100, 2) AS completion_rate  -- 本周完成率
FROM merged m
GROUP BY ROLLUP (m.operation_number)
ORDER BY m.operation_number NULLS LAST;
