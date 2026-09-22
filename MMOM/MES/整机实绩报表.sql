WITH base_order AS (
    -- 基础订单：辅助类型为 A、未删除、且存在以字母开头的 SN（整机号）
    SELECT t.*
    FROM mbm_aps_product_order t
    WHERE t.auxiliary_type = 'A'
      AND COALESCE(t.delete_flag, '0') <> '1'
      AND EXISTS (
        SELECT 1
        FROM mbm_mes_single_piece_id msp
        WHERE msp.product_order_id = t.id
          AND msp.sn ~ '^[A-Za-z]'
      )
),
order_sn AS (
    -- 订单对应的最新整机号（同 order_id+number 取 id 最大的一条）
    SELECT product_order_id, sn
    FROM (
        SELECT product_order_id,
               number AS sn,
               ROW_NUMBER() OVER (PARTITION BY product_order_id, number ORDER BY id DESC) rn
        FROM mbm_aps_product_order_id_number
        WHERE number IS NOT NULL
    ) t
    WHERE rn = 1
),
single_piece AS (
    -- 单件流档案：仅保留辅助类型 A 且存在字母 SN 的整机
    SELECT s.*
    FROM mbm_mes_single_piece_id s
    LEFT JOIN mbm_aps_product_order t ON s.product_order_id = t.id
    WHERE s.delete_flag != '1'
      AND t.auxiliary_type = 'A'
      AND EXISTS (
        SELECT 1
        FROM mbm_mes_single_piece_id msp
        WHERE msp.product_order_id = t.id
          AND msp.sn ~ '^[A-Za-z]'
      )
),
latest_achievement AS (
    -- 每台整机最新一次生产阶段（按 production_stage 数值倒序取第一条）
    SELECT sn,
           last_achievement,
           COALESCE(offline_time, online_time) AS last_achievement_time
    FROM (
        SELECT sn,
               production_stage AS last_achievement,
               online_time,
               offline_time,
               ROW_NUMBER() OVER (PARTITION BY sn ORDER BY production_stage::integer DESC NULLS LAST) AS rn
        FROM mbm_mes_single_piece_id_production_stage_log
        WHERE COALESCE(delete_flag, '0') != '1' AND sn IS NOT NULL
    ) t
    WHERE rn = 1
),
stage_time AS (
    -- 按 SN 汇总各阶段的时间与执行人 ID（行转列，用 MAX(CASE WHEN ...)）
    SELECT m.sn,
           MAX(CASE WHEN log.production_stage IN ('10', '15') THEN log.online_time END)          AS online_start_time,
           MAX(CASE WHEN log.production_stage IN ('20', '15') THEN log.offline_time END)         AS offline_end_time,
           MAX(CASE WHEN log.production_stage IN ('40', '35') THEN log.offline_time END)         AS qc_end_time,
           MAX(CASE WHEN log.production_stage IN ('50', '55') THEN log.online_time END)          AS debug_start_time,
           MAX(CASE WHEN log.production_stage IN ('55', '60') THEN log.offline_time END)         AS debug_finish_end,
           MAX(CASE WHEN log.production_stage IN ('340', '350') THEN log.online_time END)        AS paint_start_time,
           MAX(CASE WHEN log.production_stage IN ('350', '360') THEN log.offline_time END)       AS paint_check_end,
           MAX(CASE WHEN log.production_stage IN ('10', '15') THEN log.execute_worker_ids END)   AS online_worker_ids,
           MAX(CASE WHEN log.production_stage IN ('20', '15') THEN log.execute_worker_ids END)   AS offline_worker_ids,
           MAX(CASE WHEN log.production_stage IN ('40', '35') THEN log.execute_worker_ids END)   AS qc_worker_ids,
           MAX(CASE WHEN log.production_stage IN ('50', '55') THEN log.execute_worker_ids END)   AS debug_worker_ids,
           MAX(CASE WHEN log.production_stage IN ('55', '60') THEN log.execute_worker_ids END)   AS debug_finish_worker_ids,
           MAX(CASE WHEN log.production_stage IN ('340', '350') THEN log.execute_worker_ids END) AS paint_worker_ids,
           MAX(CASE WHEN log.production_stage IN ('350', '360') THEN log.execute_worker_ids END) AS paint_check_worker_ids
    FROM mbm_mes_single_piece_id_production_stage_log log
    JOIN mbm_mes_single_piece_id m ON log.single_piece_id = m.id
    WHERE m.sn IS NOT NULL
    GROUP BY m.sn
),
inbound AS (
    -- 整机出入库记录：order_type='1' 且仓库非虚拟仓，聚合首/末入库时间与人
    SELECT machine_number    AS sn,
           MIN(t.update_date) AS first_inbound_time,
           MAX(t.update_date) AS last_inbound_time,
           MIN(u.name)       AS first_inbound_user,
           MAX(u.name)       AS last_inbound_user
    FROM mbm_wms_asn_delivery_order t
    LEFT JOIN mbm_mdm_warehouse w ON t.warehouse_id = w.id
    LEFT JOIN rbac_user u ON t.update_user = u.id
    WHERE COALESCE(w.is_virtual, '0') = '0'
      AND t.order_type = '1'
      AND COALESCE(t.delete_flag, '0') <> '1'
    GROUP BY machine_number
),
qms_latest AS (
    -- 每个生产订单最新的整机检验记录
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY production_order_number ORDER BY inspection_date_time DESC NULLS LAST) rn
        FROM mbm_qms_qpc_insp_model_result
    ) t
    WHERE rn = 1
)
SELECT os.sn,
       t.number                          AS production_order_no,
       bf.name                           AS branch_factory_name,
       ws.name                           AS work_segment_name,
       t.batch_no,
       t__partVersion__partMaster.number AS item_number,
       t__partVersion__partMaster.name   AS item_name,
       t.models                          AS product_model,
       sp.chassis_number,
       sp.engine_number,
       la.last_achievement,
       la.last_achievement_time,

       st.online_start_time,
       -- 将逗号分隔的 worker_ids 拆分后关员工/用户表聚合出姓名
       (SELECT string_agg(DISTINCT u.name, ',')
          FROM unnest(string_to_array(st.online_worker_ids, ',')) AS wid
          LEFT JOIN mbm_mdm_employee e ON e.id::text = wid
          LEFT JOIN rbac_user u ON u.id = e.user_id) AS online_worker,
       st.offline_end_time,
       (SELECT string_agg(DISTINCT u.name, ',') FROM unnest(string_to_array(st.offline_worker_ids, ',')) AS wid LEFT JOIN mbm_mdm_employee e ON e.id::text = wid LEFT JOIN rbac_user u ON u.id = e.user_id) AS offline_worker,
       st.qc_end_time,
       (SELECT string_agg(DISTINCT u.name, ',') FROM unnest(string_to_array(st.qc_worker_ids, ',')) AS wid LEFT JOIN mbm_mdm_employee e ON e.id::text = wid LEFT JOIN rbac_user u ON u.id = e.user_id) AS qc_worker,
       st.debug_start_time,
       (SELECT string_agg(DISTINCT u.name, ',') FROM unnest(string_to_array(st.debug_worker_ids, ',')) AS wid LEFT JOIN mbm_mdm_employee e ON e.id::text = wid LEFT JOIN rbac_user u ON u.id = e.user_id) AS debug_start_worker,
       st.debug_finish_end,
       (SELECT string_agg(DISTINCT u.name, ',') FROM unnest(string_to_array(st.debug_finish_worker_ids, ',')) AS wid LEFT JOIN mbm_mdm_employee e ON e.id::text = wid LEFT JOIN rbac_user u ON u.id = e.user_id) AS debug_finish_worker,
       st.paint_start_time,
       (SELECT string_agg(DISTINCT u.name, ',') FROM unnest(string_to_array(st.paint_worker_ids, ',')) AS wid LEFT JOIN mbm_mdm_employee e ON e.id::text = wid LEFT JOIN rbac_user u ON u.id = e.user_id) AS paint_worker,
       st.paint_check_end,
       (SELECT string_agg(DISTINCT u.name, ',') FROM unnest(string_to_array(st.paint_check_worker_ids, ',')) AS wid LEFT JOIN mbm_mdm_employee e ON e.id::text = wid LEFT JOIN rbac_user u ON u.id = e.user_id) AS paint_check_worker,

       inbound.first_inbound_time,
       inbound.first_inbound_user,
       inbound.last_inbound_time,
       inbound.last_inbound_user,
       qms_latest.inspection_date_time
FROM base_order t
         LEFT JOIN order_sn os ON t.id = os.product_order_id
         LEFT JOIN single_piece sp ON os.sn = sp.sn
         LEFT JOIN latest_achievement la ON os.sn = la.sn
         LEFT JOIN stage_time st ON os.sn = st.sn
         LEFT JOIN mbm_mdm_work_area_version bf_v ON t.branch_factory_id = bf_v.id AND COALESCE(bf_v.delete_flag, '0') != '1'
         LEFT JOIN mbm_mdm_work_area_master bf ON bf_v.work_area_master_id = bf.id AND COALESCE(bf.delete_flag, '0') != '1'
         LEFT JOIN mbm_mdm_work_area_version ws_v ON t.work_segment_id = ws_v.id AND COALESCE(ws_v.delete_flag, '0') != '1'
         LEFT JOIN mbm_mdm_work_area_master ws ON ws_v.work_area_master_id = ws.id AND COALESCE(ws.delete_flag, '0') != '1'
         LEFT JOIN mbm_mdm_part_version t__partVersion ON t.part_version_id = t__partVersion.id AND (t__partVersion.delete_flag != '1' OR t__partVersion.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_part_master t__partVersion__partMaster ON t__partVersion.part_master_id = t__partVersion__partMaster.id AND (t__partVersion__partMaster.delete_flag != '1' OR t__partVersion__partMaster.delete_flag IS NULL)
         LEFT JOIN inbound ON inbound.sn = os.sn
         LEFT JOIN qms_latest ON qms_latest.production_order_number = t.number
WHERE 1 = 1
--   {distributionWhere}
ORDER BY sp.last_achievement_time DESC NULLS LAST
--   {limitClause};