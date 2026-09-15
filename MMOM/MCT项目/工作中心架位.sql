WITH wc AS (
    SELECT v.id                   AS work_center_id,
           m.source_system_number AS wc_no,
           m.name                 AS wc_name
    FROM mbm_mdm_work_area_version v
             INNER JOIN mbm_mdm_work_area_master m
                        ON m.id = v.work_area_master_id
                            AND (m.delete_flag <> '1' OR m.delete_flag IS NULL)
    WHERE (v.delete_flag <> '1' OR v.delete_flag IS NULL)
      AND m.source_system_number IN ('7903', '7909')),
     r AS (
         SELECT wc.work_center_id,
                wc.wc_no,
                wc.wc_name,
                mpto.production_status,
                mpto.online_time,
                mpto.offline_time,
                mpto.rack_no,
                spi.id               AS single_piece_id,
                spi.sn               AS sn,
                spi.product_order_id AS product_order_id
         FROM mbm_mes_process_tech_order_id mpto
                  INNER JOIN mbm_aps_process_tech_order pto
                             ON pto.id = mpto.mes_process_tech_order_id
                                 AND (pto.delete_flag <> '1' OR pto.delete_flag IS NULL)
                  INNER JOIN mbm_mes_single_piece_id spi
                             ON spi.id = mpto.single_piece_id
                                 AND (spi.delete_flag <> '1' OR spi.delete_flag IS NULL)
                  INNER JOIN wc ON wc.work_center_id = pto.work_center_id
         WHERE (mpto.delete_flag <> '1' OR mpto.delete_flag IS NULL)
           AND mpto.production_status IN ('20', '30')
           AND spi.sn IS NOT NULL),
     d AS (
         SELECT r.*,
                row_number() OVER (
                    PARTITION BY r.single_piece_id, r.work_center_id
                    ORDER BY CASE WHEN r.production_status = '20' THEN 0 ELSE 1 END,
                        COALESCE(r.offline_time, r.online_time) DESC
                    ) AS rn_car
         FROM r),
     p AS (
         SELECT d.*,
                CASE WHEN d.production_status = '20' THEN '当前在制' ELSE '最后完工' END AS kind,
                row_number() OVER (
                    PARTITION BY d.wc_no
                    ORDER BY CASE WHEN d.production_status = '20' THEN 0 ELSE 1 END,
                        COALESCE(d.offline_time, d.online_time) DESC
                    )                                                                    AS rn
         FROM d
         WHERE d.rn_car = 1),
     picked AS (SELECT *
                FROM p
                WHERE production_status = '20' OR rn = 1),
     -- ★ 方案B-1：一辆车只保留一个架位（在制优先，其次时间最近）
     cand AS (
         SELECT picked.*,
                row_number() OVER (
                    PARTITION BY picked.sn
                    ORDER BY CASE WHEN picked.production_status = '20' THEN 0 ELSE 1 END,
                        COALESCE(picked.offline_time, picked.online_time) DESC
                    ) AS rk_car
         FROM picked
         WHERE picked.rack_no IS NOT NULL
           AND picked.rack_no <> ''),
     -- ★ 方案B-2：同一架位若仍有多条，在制优先、其次时间最近
     one AS (
         SELECT cand.*,
                row_number() OVER (
                    PARTITION BY cand.rack_no
                    ORDER BY CASE WHEN cand.production_status = '20' THEN 0 ELSE 1 END,
                        COALESCE(cand.offline_time, cand.online_time) DESC
                    ) AS rk_rack
         FROM cand
         WHERE cand.rk_car = 1),
     car AS (
         SELECT one.*,
                -- 从 '架位12' 里取出数字，兼容纯数字写法
                NULLIF(regexp_replace(one.rack_no, '[^0-9]', '', 'g'), '')::int AS slot_no
         FROM one
         WHERE one.rk_rack = 1),
     -- ★ 1~29 架位骨架
     slot AS (
         SELECT v.n AS slot_no
         FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10),
                      (11), (12), (13), (14), (15), (16), (17), (18), (19), (20),
                      (21), (22), (23), (24), (25), (26), (27), (28), (29)) AS v(n))
SELECT slot.slot_no                                 AS slot_no,
       ('架位' || slot.slot_no)                     AS rack_no,
       car.sn                                       AS sn,
       po.batch_no                                  AS batch_no,
       po.number                                    AS order_number,
       po.suggest_start,
       po.suggest_end,
       po.plan_start,
       po.plan_end,
       po.actual_start,
       po.actual_end,
       f_master.name                                AS factory_name,
       f_master.source_system_number                AS factory_number,
       bf_master.name                               AS branch_factory_name,
       bf_master.source_system_number               AS branch_factory_number,
       ws_master.name                               AS work_segment_name,
       ws_master.source_system_number               AS work_segment_number,
       car.wc_name                                  AS work_center_name,
       car.wc_no                                    AS work_center_number,
       car.kind                                     AS kind,
       car.online_time                              AS online_time,
       car.offline_time                             AS offline_time
FROM slot
         LEFT JOIN car ON car.slot_no = slot.slot_no
         LEFT JOIN mbm_aps_product_order po
                   ON po.id = car.product_order_id
                       AND (po.delete_flag <> '1' OR po.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_work_area_version f_ver
                   ON f_ver.id = po.factory_id AND (f_ver.delete_flag <> '1' OR f_ver.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_work_area_master f_master
                   ON f_master.id = f_ver.work_area_master_id AND
                      (f_master.delete_flag <> '1' OR f_master.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_work_area_version bf_ver
                   ON bf_ver.id = po.branch_factory_id AND (bf_ver.delete_flag <> '1' OR bf_ver.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_work_area_master bf_master
                   ON bf_master.id = bf_ver.work_area_master_id AND
                      (bf_master.delete_flag <> '1' OR bf_master.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_work_area_version ws_ver
                   ON ws_ver.id = po.work_segment_id AND (ws_ver.delete_flag <> '1' OR ws_ver.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_work_area_master ws_master
                   ON ws_master.id = ws_ver.work_area_master_id AND
                      (ws_master.delete_flag <> '1' OR ws_master.delete_flag IS NULL)
ORDER BY slot.slot_no;
