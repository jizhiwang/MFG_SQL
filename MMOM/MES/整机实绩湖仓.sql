--
INSERT OVERWRITE TABLE dwr_mfg.dwr_mfg_base_order_zjsj_d_f
SELECT t.*
FROM dwd_mfg.dwd_mfg_mes_mbm_aps_product_order_zjsj_d_f t
LEFT SEMI JOIN (
    SELECT product_order_id
    FROM dwd_mfg.dwd_mfg_mes_mbm_mes_single_piece_id_zjsj_d_f
    WHERE sn RLIKE '^[A-Za-z]'
) s ON t.id = s.product_order_id
WHERE t.auxiliary_type = 'A'
  AND COALESCE(t.delete_flag, '0') <> '1';
--
INSERT OVERWRITE TABLE dwr_mfg.dwr_mfg_mes_inbound_zjsj_d_f
SELECT
    machine_number          AS sn,
    MIN(t.update_date)       AS first_inbound_time,
    MAX(t.update_date)       AS last_inbound_time,
    MIN(u.name)             AS first_inbound_user,
    MAX(u.name)             AS last_inbound_user,
    t.fc
FROM dwd_mfg.dwd_mfg_mes_mbm_wms_asn_delivery_order_zjsj_d_f t
LEFT JOIN dwd_mfg.dwd_mfg_mes_mbm_mdm_warehouse_zjsj_d_f w
    ON t.warehouse_id = w.id AND t.fc = w.fc
LEFT JOIN dwd_mfg.dwd_mfg_mes_rbac_user_zjsj_d_f u
    ON t.update_user = u.id
WHERE COALESCE(w.is_virtual, '0') = '0'
  AND t.order_type = '1'
  AND COALESCE(t.delete_flag, '0') <> '1'
GROUP BY machine_number, t.fc;

--
INSERT OVERWRITE TABLE `dwr_mfg`.`dwr_mfg_mes_mbm_qms_qpc_insp_model_result_zjsj_d_f`
SELECT
    id, orgnization_id, unaccepted_quantity, production_order_number,
    inspection_person_name, result, inspect_point, inspection_date_time,
    process_task, unqualified_code, accepted_quantity, task_code,
    part_serial_number, mes_id, inspection_person, site_id, source_id,
    tenant_id, create_user, create_date, update_user, update_date,
    unqualified_doc_number, sup_organization, hr_organization,
    work_center_id, product_group, is_inspected, order_type,
    is_finished_product, section_id, branch_id, repair, inspect_stage,
    production_stage, branch_factory_id, load_dt,
    fc
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY fc, production_order_number
               ORDER BY CASE WHEN inspection_date_time IS NULL THEN 1 ELSE 0 END,
                        inspection_date_time DESC
           ) AS rn
    FROM dwd_mfg.dwd_mfg_mes_mbm_qms_qpc_insp_model_result_zjsj_d_f
) t
WHERE rn = 1;




--
INSERT OVERWRITE TABLE dwr_mfg.dwr_mfg_mes_order_sn_zjsj_d_f
SELECT
    product_order_id,
    sn,
    fc
FROM (
    SELECT
        product_order_id,
        number AS sn,
        fc,
        ROW_NUMBER() OVER (PARTITION BY fc, product_order_id, number ORDER BY id DESC) AS rn
    FROM dwd_mfg.dwd_mfg_mes_mbm_aps_product_order_id_number_zjsj_d_f
    WHERE number IS NOT NULL
) t
WHERE rn = 1;

--
INSERT OVERWRITE TABLE dwr_mfg.dwr_mfg_mes_stage_time_zjsj_d_f
SELECT
    m.sn,
    MAX(CASE WHEN log.production_stage IN ('10','15') THEN log.online_time END) AS online_start_time,
    MAX(CASE WHEN log.production_stage IN ('20','25') THEN log.offline_time END) AS offline_end_time,
    MAX(CASE WHEN log.production_stage IN ('40','35') THEN log.offline_time END) AS qc_end_time,
    MAX(CASE WHEN log.production_stage IN ('50','55') THEN log.online_time END) AS debug_start_time,
    MAX(CASE WHEN log.production_stage IN ('55','60') THEN log.offline_time END) AS debug_finish_end,
    MAX(CASE WHEN log.production_stage IN ('340','350') THEN log.online_time END) AS paint_start_time,
    MAX(CASE WHEN log.production_stage IN ('350','360') THEN log.offline_time END) AS paint_check_end,
    MAX(CASE WHEN log.production_stage IN ('10','15') THEN log.execute_worker_ids END) AS online_worker_ids,
    MAX(CASE WHEN log.production_stage IN ('20','25') THEN log.execute_worker_ids END) AS offline_worker_ids,
    MAX(CASE WHEN log.production_stage IN ('40','35') THEN log.execute_worker_ids END) AS qc_worker_ids,
    MAX(CASE WHEN log.production_stage IN ('50','55') THEN log.execute_worker_ids END) AS debug_worker_ids,
    MAX(CASE WHEN log.production_stage IN ('55','60') THEN log.execute_worker_ids END) AS debug_finish_worker_ids,
    MAX(CASE WHEN log.production_stage IN ('340','350') THEN log.execute_worker_ids END) AS paint_worker_ids,
    MAX(CASE WHEN log.production_stage IN ('350','360') THEN log.execute_worker_ids END) AS paint_check_worker_ids,
    m.fc
FROM dwd_mfg.dwd_mfg_mes_mbm_mes_single_piece_id_production_stage_log_zjsj_d_f log
JOIN dwd_mfg.dwd_mfg_mes_mbm_mes_single_piece_id_zjsj_d_f m
    ON log.single_piece_id = m.id AND log.fc = m.fc
WHERE m.sn IS NOT NULL
GROUP BY m.sn, m.fc;

--
INSERT OVERWRITE TABLE dwr_mfg.dwr_mfg_mes_worker_exploded_zjsj_d_f
SELECT sn, 'online' AS type, worker_id, fc
FROM dwr_mfg.dwr_mfg_mes_stage_time_zjsj_d_f
LATERAL VIEW explode(split(online_worker_ids, ',')) t AS worker_id
WHERE online_worker_ids IS NOT NULL
UNION ALL
SELECT sn, 'offline', worker_id, fc
FROM dwr_mfg.dwr_mfg_mes_stage_time_zjsj_d_f
LATERAL VIEW explode(split(offline_worker_ids, ',')) t AS worker_id
WHERE offline_worker_ids IS NOT NULL
UNION ALL
SELECT sn, 'qc', worker_id, fc
FROM dwr_mfg.dwr_mfg_mes_stage_time_zjsj_d_f
LATERAL VIEW explode(split(qc_worker_ids, ',')) t AS worker_id
WHERE qc_worker_ids IS NOT NULL
UNION ALL
SELECT sn, 'debug', worker_id, fc
FROM dwr_mfg.dwr_mfg_mes_stage_time_zjsj_d_f
LATERAL VIEW explode(split(debug_worker_ids, ',')) t AS worker_id
WHERE debug_worker_ids IS NOT NULL
UNION ALL
SELECT sn, 'debug_finish', worker_id, fc
FROM dwr_mfg.dwr_mfg_mes_stage_time_zjsj_d_f
LATERAL VIEW explode(split(debug_finish_worker_ids, ',')) t AS worker_id
WHERE debug_finish_worker_ids IS NOT NULL
UNION ALL
SELECT sn, 'paint', worker_id, fc
FROM dwr_mfg.dwr_mfg_mes_stage_time_zjsj_d_f
LATERAL VIEW explode(split(paint_worker_ids, ',')) t AS worker_id
WHERE paint_worker_ids IS NOT NULL
UNION ALL
SELECT sn, 'paint_check', worker_id, fc
FROM dwr_mfg.dwr_mfg_mes_stage_time_zjsj_d_f
LATERAL VIEW explode(split(paint_check_worker_ids, ',')) t AS worker_id
WHERE paint_check_worker_ids IS NOT NULL;

--
INSERT OVERWRITE TABLE dwr_mfg.dwr_mfg_mes_worker_zjsj_d_f
SELECT
    we.sn,
    we.type,
    concat_ws(',', collect_set(u.name)) AS worker_names,
    we.fc
FROM dwr_mfg.dwr_mfg_mes_worker_exploded_zjsj_d_f we
LEFT JOIN dwd_mfg.dwd_mfg_mes_mbm_mdm_employee_zjsj_d_f e
    ON e.id = we.worker_id AND e.fc = we.fc
LEFT JOIN dwd_mfg.dwd_mfg_mes_rbac_user_zjsj_d_f u
    ON u.id = e.user_id
GROUP BY we.sn, we.fc, we.type;

--
INSERT OVERWRITE TABLE dwr_mfg.dwr_mfg_mes_latest_achievement_d_f
SELECT
    sn,
    last_achievement,
    COALESCE(t.offline_time, t.online_time) AS last_achievement_time,
    fc
FROM
    (
        SELECT
            sn,
            production_stage AS last_achievement,
            online_time,
            offline_time,
            fc,
            ROW_NUMBER() OVER (
                PARTITION BY sn
                ORDER BY CAST(production_stage AS INT) DESC
            ) AS rn
        FROM dwd_mfg.dwd_mfg_mes_mbm_mes_single_piece_id_production_stage_log_zjsj_d_f
        WHERE COALESCE(delete_flag, '0') != '1'
          AND sn IS NOT NULL
    ) AS t
WHERE
    rn = 1;

--
INSERT OVERWRITE TABLE `dwr_mfg`.`dwr_mfg_single_piece_zjsj_d_f`
SELECT
    a.id,
    a.online_time,
    a.item_number,
    a.chassis_number,
    a.storage_mark,
    a.encoder_rule_id,
    a.offline_mark,
    a.base_model,
    a.online_mark,
    a.last_achievement_time,
    a.production_status,
    a.storage_time,
    a.is_assembled,
    a.offline_time,
    a.engine_number,
    a.sn,
    a.old_single_piece_id,
    a.belong_date,
    a.single_piece_id_source,
    a.supp_name,
    a.is_update,
    a.last_achievement,
    a.supp_code,
    a.gps_number,
    a.product_order_id,
    a.modifier_id,
    a.site_id,
    a.source_id,
    a.tenant_id,
    a.create_user,
    a.create_date,
    a.update_user,
    a.update_date,
    a.delete_flag,
    a.wait_stored_tag,
    a.use_batch_no,
    a.inventory_location,
    a.inventory_location_name,
    a.old_chassis_number,
    a.chassis_number_modifier_id,
    a.painted_sn,
    a.debug_end_time,
    a.paint_start_time,
    a.debug_start_time,
    a.paint_end_time,
    a.load_dt,
    a.fc
FROM
    `dwd_mfg`.`dwd_mfg_mes_mbm_mes_single_piece_id_zjsj_d_f` a
    JOIN `dwd_mfg`.`dwd_mfg_mes_mbm_aps_product_order_zjsj_d_f` b
        ON a.product_order_id = b.id
    LEFT SEMI JOIN `dwd_mfg`.`dwd_mfg_mes_mbm_mes_single_piece_id_zjsj_d_f` msp
        ON msp.product_order_id = b.id
       AND msp.sn RLIKE '^[A-Za-z]'
WHERE a.delete_flag != '1'
  AND b.auxiliary_type = 'A';
--

INSERT OVERWRITE TABLE dwr_mfg.dwr_mfg_mes_complete_machine_performance_repart_d_f
SELECT
     os.sn,
    t.fc                               AS branch_factory_code,
    t.number                           AS production_order_no,
    bf.name                            AS branch_factory_name,
    ws.name                            AS work_segment_name,
    t.batch_no,
    t__partVersion__partMaster.number  AS item_number,
    t__partVersion__partMaster.name    AS item_name,
    t.models                           AS product_model,
    sp.chassis_number,
    sp.engine_number,
    t.sale_no,
    la.last_achievement,
    la.last_achievement_time,
    st.online_start_time,
    wn_online.worker_names             AS online_worker,
    st.offline_end_time,
    wn_offline.worker_names            AS offline_worker,
    st.qc_end_time,
    wn_qc.worker_names                 AS qc_worker,
    st.debug_start_time,
    wn_debug.worker_names              AS debug_start_worker,
    st.debug_finish_end,
    wn_debug_finish.worker_names       AS debug_finish_worker,
    st.paint_start_time,
    wn_paint.worker_names              AS paint_worker,
    st.paint_check_end,
    wn_paint_check.worker_names        AS paint_check_worker,
    inb.first_inbound_time,
    inb.first_inbound_user,
    inb.last_inbound_time,
    inb.last_inbound_user,
    qms_latest.inspection_date_time,
    t.fc
FROM `dwr_mfg`.`dwr_mfg_base_order_zjsj_d_f` t
LEFT JOIN dwr_mfg.dwr_mfg_mes_order_sn_zjsj_d_f os
    ON t.id = os.product_order_id AND t.fc = os.fc
LEFT JOIN `dwr_mfg`.`dwr_mfg_single_piece_zjsj_d_f` sp
    ON os.sn = sp.sn AND os.fc = sp.fc
LEFT JOIN dwr_mfg.dwr_mfg_mes_stage_time_zjsj_d_f st
    ON os.sn = st.sn AND os.fc = st.fc
LEFT JOIN dwr_mfg.dwr_mfg_mes_latest_achievement_d_f la
    ON os.sn = la.sn AND os.fc = la.fc
LEFT JOIN dwd_mfg.dwd_mfg_mes_mbm_mdm_work_area_version_zjsj_d_f bf_v
    ON t.branch_factory_id = bf_v.id AND t.fc = bf_v.fc AND COALESCE(bf_v.delete_flag,'0') <> '1'
LEFT JOIN dwd_mfg.dwd_mfg_mes_mbm_mdm_work_area_master_zjsj_d_f bf
    ON bf_v.work_area_master_id = bf.id AND t.fc = bf.fc AND COALESCE(bf.delete_flag,'0') <> '1'
LEFT JOIN dwd_mfg.dwd_mfg_mes_mbm_mdm_work_area_version_zjsj_d_f ws_v
    ON t.work_segment_id = ws_v.id AND t.fc = ws_v.fc AND COALESCE(ws_v.delete_flag,'0') <> '1'
LEFT JOIN dwd_mfg.dwd_mfg_mes_mbm_mdm_work_area_master_zjsj_d_f ws
    ON ws_v.work_area_master_id = ws.id AND t.fc = ws.fc AND COALESCE(ws.delete_flag,'0') <> '1'
LEFT JOIN dwd_mfg.dwd_mfg_mes_mbm_mdm_part_version_zjsj_d_f t__partVersion
    ON t.part_version_id = t__partVersion.id AND t.fc = t__partVersion.fc
    AND (t__partVersion.delete_flag <> '1' OR t__partVersion.delete_flag IS NULL)
LEFT JOIN dwd_mfg.dwd_mfg_mes_mbm_mdm_part_master_zjsj_d_f t__partVersion__partMaster
    ON t__partVersion.part_master_id = t__partVersion__partMaster.id AND t.fc = t__partVersion__partMaster.fc
    AND (t__partVersion__partMaster.delete_flag <> '1' OR t__partVersion__partMaster.delete_flag IS NULL)
LEFT JOIN dwr_mfg.dwr_mfg_mes_worker_zjsj_d_f wn_online
    ON wn_online.sn = os.sn AND wn_online.fc = os.fc AND wn_online.type = 'online'
LEFT JOIN dwr_mfg.dwr_mfg_mes_worker_zjsj_d_f wn_offline
    ON wn_offline.sn = os.sn AND wn_offline.fc = os.fc AND wn_offline.type = 'offline'
LEFT JOIN dwr_mfg.dwr_mfg_mes_worker_zjsj_d_f wn_qc
    ON wn_qc.sn = os.sn AND wn_qc.fc = os.fc AND wn_qc.type = 'qc'
LEFT JOIN dwr_mfg.dwr_mfg_mes_worker_zjsj_d_f wn_debug
    ON wn_debug.sn = os.sn AND wn_debug.fc = os.fc AND wn_debug.type = 'debug'
LEFT JOIN dwr_mfg.dwr_mfg_mes_worker_zjsj_d_f wn_debug_finish
    ON wn_debug_finish.sn = os.sn AND wn_debug_finish.fc = os.fc AND wn_debug_finish.type = 'debug_finish'
LEFT JOIN dwr_mfg.dwr_mfg_mes_worker_zjsj_d_f wn_paint
    ON wn_paint.sn = os.sn AND wn_paint.fc = os.fc AND wn_paint.type = 'paint'
LEFT JOIN dwr_mfg.dwr_mfg_mes_worker_zjsj_d_f wn_paint_check
    ON wn_paint_check.sn = os.sn AND wn_paint_check.fc = os.fc AND wn_paint_check.type = 'paint_check'
LEFT JOIN dwr_mfg.dwr_mfg_mes_inbound_zjsj_d_f inb
    ON inb.sn = os.sn AND inb.fc = os.fc
LEFT JOIN `dwr_mfg`.`dwr_mfg_mes_mbm_qms_qpc_insp_model_result_zjsj_d_f` qms_latest
    ON qms_latest.production_order_number = t.number AND qms_latest.fc = t.fc
WHERE 1 = 1
ORDER BY la.last_achievement_time DESC;