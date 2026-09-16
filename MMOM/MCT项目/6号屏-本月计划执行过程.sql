-- 本月计划执行过程 - 明细
-- 状态：待总装 / 待上架 / 调试中 / 涂装中 / 交库中

WITH target_order AS (
    -- ========================================================
    -- 1. 当前月份装配二分厂整机生产订单
    -- ========================================================
    SELECT
        po.id                       AS product_order_id,   -- 产品订单ID
        po.batch_no                 AS batch_no,           -- 生产批次
        COALESCE(po.qty, 0)         AS plan_qty            -- 产品订单计划数量
    FROM mbm_aps_product_order po
        JOIN mbm_mdm_work_area_version bf_v
            ON po.branch_factory_id = bf_v.id
        JOIN mbm_mdm_work_area_master bf
            ON bf_v.work_area_master_id = bf.id
    WHERE COALESCE(po.delete_flag, '0') <> '1'
      AND COALESCE(bf_v.delete_flag, '0') <> '1'
      AND COALESCE(bf.delete_flag, '0') <> '1'
      AND po.auxiliary_type = 'A'
      AND bf.name = '装配二分厂'

      -- 当前月份
      AND po.plan_end >= DATE_TRUNC('month', CURRENT_DATE)
      AND po.plan_end < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'

      -- 只取包含总装工段的整机订单
      AND EXISTS (
          SELECT 1
          FROM mbm_aps_process_tech_order t
          WHERE t.product_order_id = po.id
            AND COALESCE(t.delete_flag, '0') <> '1'
            AND t.production_stage = '10'
      )
),

machine AS (
    SELECT
        mpi.single_piece_id      AS single_piece_id,
        pto.product_order_id     AS product_order_id,

        -- 总装是否已开工（在制 20 或已完工 30）
        MAX(CASE WHEN pto.production_stage = '10'
                  AND mpi.production_status IN ('20', '30')
                 THEN 1 ELSE 0 END) AS asm_started,

        -- 总装是否完工
        MAX(CASE WHEN pto.production_stage = '10'
                  AND mpi.production_status = '30'
                 THEN 1 ELSE 0 END) AS asm_done,

        -- 调试是否已推进到（在制或已完工）
        MAX(CASE WHEN pto.production_stage = '30'
                  AND mpi.production_status IN ('20', '30')
                 THEN 1 ELSE 0 END) AS dbg_reached,

        -- 涂装是否已推进到
        MAX(CASE WHEN pto.production_stage = '40'
                  AND mpi.production_status IN ('20', '30')
                 THEN 1 ELSE 0 END) AS paint_reached,

        -- 交库是否已推进到
        MAX(CASE WHEN pto.production_stage = '50'
                  AND mpi.production_status IN ('20', '30')
                 THEN 1 ELSE 0 END) AS wh_reached,

        -- 交库是否已完工
        MAX(CASE WHEN pto.production_stage = '50'
                  AND mpi.production_status = '30'
                 THEN 1 ELSE 0 END) AS wh_done

    FROM target_order o
        JOIN mbm_aps_process_tech_order pto
            ON o.product_order_id = pto.product_order_id
        JOIN mbm_mes_process_tech_order_id mpi
            ON pto.id = mpi.mes_process_tech_order_id
    WHERE COALESCE(pto.delete_flag, '0') <> '1'
      AND COALESCE(mpi.delete_flag, '0') <> '1'
      AND pto.production_stage IN ('10', '30', '40', '50')
    GROUP BY
        mpi.single_piece_id,
        pto.product_order_id
),

target_batch AS (
    -- ========================================================
    -- 3. 当前月份涉及的生产批次
    -- ========================================================
    SELECT DISTINCT
        batch_no
    FROM target_order
    WHERE batch_no IS NOT NULL
),

chassis AS (
    -- ========================================================
    -- 4. 判断同批次底盘订单是否存在未完工
    --    has_unfinished_chassis = 1：存在未完工底盘
    --    has_unfinished_chassis = 0：底盘全部完工
    -- ========================================================
    SELECT
        po2.batch_no AS batch_no,

        MAX(
            CASE
                WHEN po2.actual_end IS NULL
                THEN 1
                ELSE 0
            END
        ) AS has_unfinished_chassis

    FROM mbm_aps_product_order po2
        JOIN target_batch tb
            ON po2.batch_no = tb.batch_no
    WHERE COALESCE(po2.delete_flag, '0') <> '1'
      AND po2.auxiliary_type = 'A'

      -- 底盘订单：包含110或120工段
      AND EXISTS (
          SELECT 1
          FROM mbm_aps_process_tech_order t
          WHERE t.product_order_id = po2.id
            AND COALESCE(t.delete_flag, '0') <> '1'
            AND t.production_stage IN ('110', '120')
      )
    GROUP BY
        po2.batch_no
),

machine_status AS (
    SELECT
        m.single_piece_id   AS single_piece_id,
        o.product_order_id  AS product_order_id,
        o.batch_no          AS batch_no,

        CASE
            -- 交库已完工
            WHEN COALESCE(m.wh_done, 0) = 1
                THEN '已交库'

            -- 已进入交库
            WHEN COALESCE(m.wh_reached, 0) = 1
                THEN '交库中'

            -- 已进入涂装
            WHEN COALESCE(m.paint_reached, 0) = 1
                THEN '涂装中'

            -- 已进入调试
            WHEN COALESCE(m.dbg_reached, 0) = 1
                THEN '调试中'

            -- 总装已完成
            WHEN COALESCE(m.asm_done, 0) = 1
                THEN '待上架'

            -- 总装尚未开工，同时底盘已完工
            WHEN COALESCE(m.asm_started, 0) = 0
             AND COALESCE(c.has_unfinished_chassis, 0) = 0
                THEN '待总装'

            ELSE NULL
        END AS stage_group

    FROM machine m
        JOIN target_order o
            ON m.product_order_id = o.product_order_id
        LEFT JOIN chassis c
            ON o.batch_no = c.batch_no
),

machine_qty AS (
    -- ========================================================
    -- 6. 每个产品订单已经生成多少台整机实例
    -- ========================================================
    SELECT
        o.product_order_id                                  AS product_order_id,  -- 产品订单ID
        o.batch_no                                          AS batch_no,           -- 生产批次
        o.plan_qty                                          AS plan_qty,           -- 计划数量
        COUNT(DISTINCT m.single_piece_id)                   AS instance_qty,       -- 已生成整机实例数量
        COALESCE(c.has_unfinished_chassis, 0)               AS has_unfinished_chassis
    FROM target_order o
        LEFT JOIN machine m
            ON o.product_order_id = m.product_order_id
        LEFT JOIN chassis c
            ON o.batch_no = c.batch_no
    GROUP BY
        o.product_order_id,
        o.batch_no,
        o.plan_qty,
        c.has_unfinished_chassis
),

instantiated_detail AS (
    -- ========================================================
    -- 7. 已生成整机实例的状态数量
    -- ========================================================
    SELECT
        product_order_id,       -- 产品订单ID
        batch_no,               -- 生产批次
        stage_group,            -- 当前生产状态
        COUNT(*) AS qty         -- 数量
    FROM machine_status
    WHERE stage_group IS NOT NULL
    GROUP BY
        product_order_id,
        batch_no,
        stage_group
),

uninstantiated_detail AS (
    -- ========================================================
    -- 8. 尚未生成 single_piece_id 的计划数量
    --
    --    计划数量 - 已生成整机数量 = 尚未实例化数量
    --
    --    当底盘已完成时，这部分计入“待总装”
    -- ========================================================
    SELECT
        product_order_id,                           -- 产品订单ID
        batch_no,                                   -- 生产批次
        '待总装' AS stage_group,                    -- 当前生产状态
        GREATEST(plan_qty - instance_qty, 0) AS qty -- 待总装数量
    FROM machine_qty
    WHERE has_unfinished_chassis = 0
      AND plan_qty > instance_qty
),

status_detail AS (
    -- ========================================================
    -- 9. 合并已实例化状态和未实例化待总装数量
    -- ========================================================
    SELECT
        product_order_id,
        batch_no,
        stage_group,
        qty
    FROM instantiated_detail

    UNION ALL

    SELECT
        product_order_id,
        batch_no,
        stage_group,
        qty
    FROM uninstantiated_detail
)

-- ============================================================
-- 10. 大屏最终明细
-- ============================================================
SELECT
    stage_group AS "stageGroup",   -- 计划执行状态
    batch_no    AS "batchNo",      -- 生产批次
    SUM(qty)    AS "qty"           -- 当前状态数量/台
FROM status_detail
WHERE qty > 0
GROUP BY
    stage_group,
    batch_no
ORDER BY
    CASE stage_group
        WHEN '待总装' THEN 1
        WHEN '待上架' THEN 2
        WHEN '调试中' THEN 3
        WHEN '涂装中' THEN 4
        WHEN '交库中' THEN 5
        ELSE 99
    END,
    batch_no DESC;







-- 整机工段状态统计（装配二分厂 / 本月计划完工）
-- 判定口径：取每台整机「已开工未完工」的工序中 node_number 最大的那条，
--           用它的 production_stage 作为当前所处工段。
-- 兜底口径：若不存在任何「已开工未完工」工序（工序间空档期），
--           则取未完工工序中 node_number 最小的那条（下一个待做工序）的工段。
-- 注：node_number 为字符型，用 LPAD 补位后排序，避免位数不同导致字典序错乱；
--     追加 pto.id 作为稳定排序键，避免同一节点多行时结果抖动。

WITH target_order AS (
    SELECT po.id AS product_order_id,
           po.batch_no AS batch_no,
           COALESCE(po.qty, 0) AS plan_qty
    FROM mbm_aps_product_order po
        JOIN mbm_mdm_work_area_version bf_v ON po.branch_factory_id = bf_v.id
        JOIN mbm_mdm_work_area_master bf ON bf_v.work_area_master_id = bf.id
    WHERE COALESCE(po.delete_flag, '0') <> '1'
      AND COALESCE(bf_v.delete_flag, '0') <> '1'
      AND COALESCE(bf.delete_flag, '0') <> '1'
      AND po.auxiliary_type = 'A'
      AND bf.name = '装配二分厂'
      AND po.plan_end >= DATE_TRUNC('month', CURRENT_DATE)
      AND po.plan_end < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
      AND EXISTS (
          SELECT 1 FROM mbm_aps_process_tech_order t
          WHERE t.product_order_id = po.id
            AND COALESCE(t.delete_flag, '0') <> '1'
            AND t.production_stage = '10'
      )
),

-- 每台整机的工序明细（仅 10 总装 / 30 调试 / 40 涂装 / 50 发运）
stage_node AS (
    SELECT mpi.single_piece_id  AS single_piece_id,
           pto.product_order_id AS product_order_id,
           pto.id               AS pto_id,
           pto.production_stage AS production_stage,
           LPAD(COALESCE(pto.node_number, '0'), 10, '0') AS node_sort,
           pto.actual_start     AS actual_start,
           pto.actual_end       AS actual_end
    FROM target_order o
        JOIN mbm_aps_process_tech_order pto
            ON o.product_order_id = pto.product_order_id
        JOIN mbm_mes_process_tech_order_id mpi
            ON pto.id = mpi.mes_process_tech_order_id
    WHERE COALESCE(pto.delete_flag, '0') <> '1'
      AND COALESCE(mpi.delete_flag, '0') <> '1'
      AND pto.production_stage IN ('10', '30', '40', '50')
),

-- 主判据：已开工未完工 中 节点号最大者
wip_node AS (
    SELECT single_piece_id, product_order_id, production_stage,
           ROW_NUMBER() OVER (
               PARTITION BY single_piece_id, product_order_id
               ORDER BY node_sort DESC, pto_id DESC
           ) AS rn
    FROM stage_node
    WHERE actual_start IS NOT NULL
      AND actual_end IS NULL
),
cur_stage AS (
    SELECT single_piece_id, product_order_id, production_stage
    FROM wip_node WHERE rn = 1
),

-- 兜底判据：所有未完工工序中 节点号最小者（下一个待做工序）
next_node AS (
    SELECT single_piece_id, product_order_id, production_stage,
           ROW_NUMBER() OVER (
               PARTITION BY single_piece_id, product_order_id
               ORDER BY node_sort ASC, pto_id ASC
           ) AS rn
    FROM stage_node
    WHERE actual_end IS NULL
),
nx_stage AS (
    SELECT single_piece_id, product_order_id, production_stage
    FROM next_node WHERE rn = 1
),

machine AS (
    SELECT single_piece_id,
           product_order_id,
           MAX(CASE WHEN actual_start IS NOT NULL THEN 1 ELSE 0 END) AS any_started,
           MIN(CASE WHEN actual_end IS NULL THEN 0 ELSE 1 END) AS all_finished,
           MIN(CASE WHEN production_stage = '10'
                    THEN CASE WHEN actual_end IS NULL THEN 0 ELSE 1 END
                    ELSE 1 END) AS asm_all_done,
           MAX(CASE WHEN production_stage IN ('30', '40', '50')
                     AND actual_start IS NOT NULL THEN 1 ELSE 0 END) AS post_started
    FROM stage_node
    GROUP BY single_piece_id, product_order_id
),

target_batch AS (
    SELECT DISTINCT batch_no FROM target_order WHERE batch_no IS NOT NULL
),

-- 底盘（110/120 工段）是否仍有未完工订单
chassis AS (
    SELECT po2.batch_no AS batch_no,
           MAX(CASE WHEN po2.actual_end IS NULL THEN 1 ELSE 0 END) AS has_unfinished_chassis
    FROM mbm_aps_product_order po2
        JOIN target_batch tb ON po2.batch_no = tb.batch_no
    WHERE COALESCE(po2.delete_flag, '0') <> '1'
      AND po2.auxiliary_type = 'A'
      AND EXISTS (
          SELECT 1 FROM mbm_aps_process_tech_order t
          WHERE t.product_order_id = po2.id
            AND COALESCE(t.delete_flag, '0') <> '1'
            AND t.production_stage IN ('110', '120')
      )
    GROUP BY po2.batch_no
),

machine_status AS (
    SELECT m.single_piece_id  AS single_piece_id,
           o.product_order_id AS product_order_id,
           o.batch_no         AS batch_no,
           CASE
               -- 1. 有在制工序：按最大在制节点的工段判定
               WHEN cs.production_stage = '50' THEN '交库中'
               WHEN cs.production_stage = '40' THEN '涂装中'
               WHEN cs.production_stage = '30' THEN '调试中'
               WHEN cs.production_stage = '10' THEN '总装中'
               -- 2. 总装已全部完工、后续工段未开工 -> 待上架
               WHEN m.asm_all_done = 1 AND COALESCE(m.post_started, 0) = 0 THEN '待上架'
               -- 3. 无在制工序（工序间空档）：按下一个待做工序的工段判定
               WHEN COALESCE(m.any_started, 0) = 1 AND nx.production_stage = '50' THEN '交库中'
               WHEN COALESCE(m.any_started, 0) = 1 AND nx.production_stage = '40' THEN '涂装中'
               WHEN COALESCE(m.any_started, 0) = 1 AND nx.production_stage = '30' THEN '调试中'
               WHEN COALESCE(m.any_started, 0) = 1 AND nx.production_stage = '10' THEN '总装中'
               -- 4. 全部工序完工
               WHEN m.all_finished = 1 THEN '已交库'
               -- 5. 尚未开工且底盘已齐套
               WHEN COALESCE(m.any_started, 0) = 0
                AND COALESCE(c.has_unfinished_chassis, 0) = 0 THEN '待总装'
               ELSE NULL
           END AS stage_group
    FROM machine m
        JOIN target_order o ON m.product_order_id = o.product_order_id
        LEFT JOIN cur_stage cs
            ON cs.single_piece_id = m.single_piece_id
           AND cs.product_order_id = m.product_order_id
        LEFT JOIN nx_stage nx
            ON nx.single_piece_id = m.single_piece_id
           AND nx.product_order_id = m.product_order_id
        LEFT JOIN chassis c ON o.batch_no = c.batch_no
),

machine_qty AS (
    SELECT o.product_order_id AS product_order_id,
           o.batch_no         AS batch_no,
           o.plan_qty         AS plan_qty,
           COUNT(DISTINCT m.single_piece_id) AS instance_qty,
           COALESCE(c.has_unfinished_chassis, 0) AS has_unfinished_chassis
    FROM target_order o
        LEFT JOIN machine m ON o.product_order_id = m.product_order_id
        LEFT JOIN chassis c ON o.batch_no = c.batch_no
    GROUP BY o.product_order_id, o.batch_no, o.plan_qty, c.has_unfinished_chassis
),

instantiated_detail AS (
    SELECT product_order_id, batch_no, stage_group, COUNT(*) AS qty
    FROM machine_status
    WHERE stage_group IS NOT NULL
    GROUP BY product_order_id, batch_no, stage_group
),

uninstantiated_detail AS (
    SELECT product_order_id, batch_no, '待总装' AS stage_group,
           GREATEST(plan_qty - instance_qty, 0) AS qty
    FROM machine_qty
    WHERE has_unfinished_chassis = 0 AND plan_qty > instance_qty
),

status_detail AS (
    SELECT product_order_id, batch_no, stage_group, qty FROM instantiated_detail
    UNION ALL
    SELECT product_order_id, batch_no, stage_group, qty FROM uninstantiated_detail
)

SELECT stage_group AS stageGroup,
       batch_no    AS batchNo,
       SUM(qty)    AS qty
FROM status_detail
WHERE qty > 0
GROUP BY stage_group, batch_no
ORDER BY CASE stage_group
             WHEN '待总装' THEN 1
             WHEN '总装中' THEN 2
             WHEN '待上架' THEN 3
             WHEN '调试中' THEN 4
             WHEN '涂装中' THEN 5
             WHEN '交库中' THEN 6
             WHEN '已交库' THEN 7
             ELSE 99
         END,
         batch_no DESC;











