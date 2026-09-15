-- 整机
    WITH wc AS (
    SELECT wc_ver.id                      AS work_center_id,
           wc_master.source_system_number AS wc_no,
           wc_master.name                 AS wc_name
    FROM mbm_mdm_work_area_version wc_ver
    INNER JOIN mbm_mdm_work_area_master wc_master
            ON wc_master.id = wc_ver.work_area_master_id
           AND (wc_master.delete_flag <> '1' OR wc_master.delete_flag IS NULL)
    WHERE (wc_ver.delete_flag <> '1' OR wc_ver.delete_flag IS NULL)
      AND wc_master.source_system_number IN ('7651','7652','7653','7654','7655','7656','7657','7658')
),
base AS (
    SELECT spi.sn,
           wc.wc_no,
           wc.wc_name,
           mpto.production_status,
           CASE mpto.production_status
                WHEN '20' THEN '已开工(在制)'
                WHEN '30' THEN '已完工'
                ELSE mpto.production_status
           END                                                             AS status_name,
           mpto.online_time,
           mpto.offline_time,
           mpto.update_date,
           COALESCE(mpto.offline_time, mpto.online_time, mpto.update_date) AS pass_time,
           po.number        AS order_number,
           po.batch_no,
           po.models,
           po.product_version
    FROM mbm_mes_process_tech_order_id mpto
    INNER JOIN mbm_mes_single_piece_id spi
            ON spi.id = mpto.single_piece_id
           AND (spi.delete_flag <> '1' OR spi.delete_flag IS NULL)
    INNER JOIN mbm_aps_process_tech_order pto
            ON pto.id = mpto.mes_process_tech_order_id
           AND (pto.delete_flag <> '1' OR pto.delete_flag IS NULL)
    INNER JOIN wc
            ON wc.work_center_id = pto.work_center_id
    LEFT JOIN mbm_aps_product_order po
            ON po.id = pto.product_order_id
           AND (po.delete_flag <> '1' OR po.delete_flag IS NULL)
    WHERE (mpto.delete_flag <> '1' OR mpto.delete_flag IS NULL)
      AND mpto.production_status IN ('20','30')
      AND spi.sn IS NOT NULL
),
ranked AS (
    SELECT base.*,
           ROW_NUMBER() OVER (
               PARTITION BY sn
               ORDER BY CASE production_status WHEN '20' THEN 1 WHEN '30' THEN 2 ELSE 3 END,
                        pass_time DESC NULLS LAST,
                        update_date DESC NULLS LAST
           ) AS rn
    FROM base
)
SELECT sn, wc_no, wc_name, production_status, status_name,
       online_time, offline_time, pass_time,
       order_number, batch_no, models, product_version
FROM ranked
WHERE rn = 1
ORDER BY production_status, wc_no, pass_time DESC;



-- 底盘
WITH wc AS (
    SELECT wc_ver.id                      AS work_center_id,
           wc_master.source_system_number AS wc_no,
           wc_master.name                 AS wc_name
    FROM mbm_mdm_work_area_version wc_ver
    INNER JOIN mbm_mdm_work_area_master wc_master
            ON wc_master.id = wc_ver.work_area_master_id
           AND (wc_master.delete_flag <> '1' OR wc_master.delete_flag IS NULL)
    WHERE (wc_ver.delete_flag <> '1' OR wc_ver.delete_flag IS NULL)
      AND wc_master.source_system_number IN ('7221','7222','7223','7224','7225','7226',
                                             '7227','7228','7229','7230','7231','7232')
),
base AS (
    SELECT spi.sn,
           wc.wc_no,
           wc.wc_name,
           mpto.production_status,
           CASE mpto.production_status
                WHEN '20' THEN '已开工(在制)'
                WHEN '30' THEN '已完工'
                ELSE mpto.production_status
           END                                                             AS status_name,
           mpto.online_time,
           mpto.offline_time,
           mpto.update_date,
           COALESCE(mpto.offline_time, mpto.online_time, mpto.update_date) AS pass_time,
           po.number        AS order_number,
           po.batch_no,
           po.models,
           po.product_version
    FROM mbm_mes_process_tech_order_id mpto
    INNER JOIN mbm_mes_single_piece_id spi
            ON spi.id = mpto.single_piece_id
           AND (spi.delete_flag <> '1' OR spi.delete_flag IS NULL)
    INNER JOIN mbm_aps_process_tech_order pto
            ON pto.id = mpto.mes_process_tech_order_id
           AND (pto.delete_flag <> '1' OR pto.delete_flag IS NULL)
    INNER JOIN wc
            ON wc.work_center_id = pto.work_center_id
    LEFT JOIN mbm_aps_product_order po
            ON po.id = pto.product_order_id
           AND (po.delete_flag <> '1' OR po.delete_flag IS NULL)
    WHERE (mpto.delete_flag <> '1' OR mpto.delete_flag IS NULL)
      AND mpto.production_status IN ('20','30')
      AND spi.sn IS NOT NULL
),
ranked AS (
    SELECT base.*,
           ROW_NUMBER() OVER (
               PARTITION BY sn
               ORDER BY CASE production_status WHEN '20' THEN 1 WHEN '30' THEN 2 ELSE 3 END,
                        pass_time DESC NULLS LAST,
                        update_date DESC NULLS LAST
           ) AS rn
    FROM base
)
SELECT sn, wc_no, wc_name, production_status, status_name,
       online_time, offline_time, pass_time,
       order_number, batch_no, models, product_version
FROM ranked
WHERE rn = 1
ORDER BY production_status, wc_no, pass_time DESC;




-- 100-350 吨装配产线
WITH wc AS (
    SELECT wc_ver.id                      AS work_center_id,
           wc_master.source_system_number AS wc_no,
           wc_master.name                 AS wc_name
    FROM mbm_mdm_work_area_version wc_ver
    INNER JOIN mbm_mdm_work_area_master wc_master
            ON wc_master.id = wc_ver.work_area_master_id
           AND (wc_master.delete_flag <> '1' OR wc_master.delete_flag IS NULL)
    WHERE (wc_ver.delete_flag <> '1' OR wc_ver.delete_flag IS NULL)
      AND wc_master.source_system_number IN ('7221', '7232', '7651', '7657')
),
base AS (
    SELECT spi.sn,
           wc.wc_no,
           wc.wc_name,
           mpto.production_status,
           '已开工(在制)'                                          AS status_name,
           mpto.online_time,
           mpto.offline_time,
           mpto.update_date,
           COALESCE(mpto.offline_time, mpto.online_time, mpto.update_date) AS pass_time,
           po.number        AS order_number,
           po.batch_no,
           po.models,
           po.product_version
    FROM mbm_mes_process_tech_order_id mpto
    INNER JOIN mbm_mes_single_piece_id spi
            ON spi.id = mpto.single_piece_id
           AND (spi.delete_flag <> '1' OR spi.delete_flag IS NULL)
    INNER JOIN mbm_aps_process_tech_order pto
            ON pto.id = mpto.mes_process_tech_order_id
           AND (pto.delete_flag <> '1' OR pto.delete_flag IS NULL)
    INNER JOIN wc
            ON wc.work_center_id = pto.work_center_id
    LEFT JOIN mbm_aps_product_order po
            ON po.id = pto.product_order_id
           AND (po.delete_flag <> '1' OR po.delete_flag IS NULL)
    WHERE (mpto.delete_flag <> '1' OR mpto.delete_flag IS NULL)
      AND mpto.production_status = '20'
      AND spi.sn IS NOT NULL
),
ranked AS (
    SELECT base.*,
           ROW_NUMBER() OVER (
               PARTITION BY sn
               ORDER BY pass_time DESC NULLS LAST,
                        update_date DESC NULLS LAST
           ) AS rn
    FROM base
)
SELECT sn, wc_no, wc_name, production_status, status_name,
       online_time, offline_time, pass_time,
       order_number, batch_no, models, product_version
FROM ranked
WHERE rn = 1
ORDER BY wc_no, pass_time DESC;






-- 400-1000吨装配产线




WITH wc AS (
    SELECT wc_ver.id                      AS work_center_id,
           wc_master.source_system_number AS wc_no,
           wc_master.name                 AS wc_name
    FROM mbm_mdm_work_area_version wc_ver
    INNER JOIN mbm_mdm_work_area_master wc_master
            ON wc_master.id = wc_ver.work_area_master_id
           AND (wc_master.delete_flag <> '1' OR wc_master.delete_flag IS NULL)
    WHERE (wc_ver.delete_flag <> '1' OR wc_ver.delete_flag IS NULL)
      AND wc_master.source_system_number IN ('7071' ,'7078', '7681', '7685')
),
base AS (
    SELECT spi.sn,
           wc.wc_no,
           wc.wc_name,
           mpto.production_status,
           '已开工(在制)'                                          AS status_name,
           mpto.online_time,
           mpto.offline_time,
           mpto.update_date,
           COALESCE(mpto.offline_time, mpto.online_time, mpto.update_date) AS pass_time,
           po.number        AS order_number,
           po.batch_no,
           po.models,
           po.product_version
    FROM mbm_mes_process_tech_order_id mpto
    INNER JOIN mbm_mes_single_piece_id spi
            ON spi.id = mpto.single_piece_id
           AND (spi.delete_flag <> '1' OR spi.delete_flag IS NULL)
    INNER JOIN mbm_aps_process_tech_order pto
            ON pto.id = mpto.mes_process_tech_order_id
           AND (pto.delete_flag <> '1' OR pto.delete_flag IS NULL)
    INNER JOIN wc
            ON wc.work_center_id = pto.work_center_id
    LEFT JOIN mbm_aps_product_order po
            ON po.id = pto.product_order_id
           AND (po.delete_flag <> '1' OR po.delete_flag IS NULL)
    WHERE (mpto.delete_flag <> '1' OR mpto.delete_flag IS NULL)
      AND mpto.production_status = '20'
      AND spi.sn IS NOT NULL
),
ranked AS (
    SELECT base.*,
           ROW_NUMBER() OVER (
               PARTITION BY sn
               ORDER BY pass_time DESC NULLS LAST,
                        update_date DESC NULLS LAST
           ) AS rn
    FROM base
)
SELECT sn, wc_no, wc_name, production_status, status_name,
       online_time, offline_time, pass_time,
       order_number, batch_no, models, product_version
FROM ranked
WHERE rn = 1
ORDER BY wc_no, pass_time DESC;



-- 千吨级装配产线
WITH wc AS (
    SELECT wc_ver.id                      AS work_center_id,
           wc_master.source_system_number AS wc_no,
           wc_master.name                 AS wc_name
    FROM mbm_mdm_work_area_version wc_ver
    INNER JOIN mbm_mdm_work_area_master wc_master
            ON wc_master.id = wc_ver.work_area_master_id
           AND (wc_master.delete_flag <> '1' OR wc_master.delete_flag IS NULL)
    WHERE (wc_ver.delete_flag <> '1' OR wc_ver.delete_flag IS NULL)
      AND wc_master.source_system_number IN ('7064' ,'7689')
),
base AS (
    SELECT spi.sn,
           wc.wc_no,
           wc.wc_name,
           mpto.production_status,
           '已开工(在制)'                                          AS status_name,
           mpto.online_time,
           mpto.offline_time,
           mpto.update_date,
           COALESCE(mpto.offline_time, mpto.online_time, mpto.update_date) AS pass_time,
           po.number        AS order_number,
           po.batch_no,
           po.models,
           po.product_version
    FROM mbm_mes_process_tech_order_id mpto
    INNER JOIN mbm_mes_single_piece_id spi
            ON spi.id = mpto.single_piece_id
           AND (spi.delete_flag <> '1' OR spi.delete_flag IS NULL)
    INNER JOIN mbm_aps_process_tech_order pto
            ON pto.id = mpto.mes_process_tech_order_id
           AND (pto.delete_flag <> '1' OR pto.delete_flag IS NULL)
    INNER JOIN wc
            ON wc.work_center_id = pto.work_center_id
    LEFT JOIN mbm_aps_product_order po
            ON po.id = pto.product_order_id
           AND (po.delete_flag <> '1' OR po.delete_flag IS NULL)
    WHERE (mpto.delete_flag <> '1' OR mpto.delete_flag IS NULL)
      AND mpto.production_status = '20'
      AND spi.sn IS NOT NULL
),
ranked AS (
    SELECT base.*,
           ROW_NUMBER() OVER (
               PARTITION BY sn
               ORDER BY pass_time DESC NULLS LAST,
                        update_date DESC NULLS LAST
           ) AS rn
    FROM base
)
SELECT sn, wc_no, wc_name, production_status, status_name,
       online_time, offline_time, pass_time,
       order_number, batch_no, models, product_version
FROM ranked
WHERE rn = 1
ORDER BY wc_no, pass_time DESC;




