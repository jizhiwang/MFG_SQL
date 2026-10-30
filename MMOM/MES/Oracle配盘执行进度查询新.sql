WITH filtered_demand AS (SELECT t.id,
                                t.delivery_plan_no,
                                t.delivery_plan_line_no,
                                t.external_receive_location,
                                t.delivery_plan_detail_no,
                                t.part_version_id,
                                t.delivery_type,
                                t.process_task_no,
                                t.requirement_date,
                                t.quantity,
                                t.create_status,
                                t.supplier_id,
                                t.branch_factory_id,
                                t.work_segment_id,
                                t.work_center_id,
                                t.po_sa_no,
                                t.purchase_group,
                                t.purchase_group_desc,
                                t.production_order_no,
                                t.production_batch_no,
                                t.supply_type,
                                t.line_status,
                                t.order_type,
                                t.delete_flag
                         FROM mbm_logistics_pe_distribution_demand t
                         WHERE t.delete_flag = '0')
        ,
     candidates AS (SELECT *
                    FROM (SELECT t.id                                       AS demand_id,
                                 t.delivery_plan_no                         AS delivery_plan_no,
                                 t.delivery_plan_line_no                    AS delivery_plan_line_no,
                                 t.external_receive_location                AS external_receive_location,
                                 t.delivery_plan_detail_no                  AS delivery_plan_detail_no,
                                 ds.distribution_order_no                   AS distribution_order_no,
                                 ds.distribution_line_number                AS distribution_line_number,
                                 point_area.number                          AS distribution_point_code,
                                 point_area.name                            AS distribution_point_name,
                                 master_factory.name                        AS branch_factory_name,
                                 master_section.name                        AS work_segment_name,
                                 master_work.name                           AS work_center_name,
                                 pm.number                                  AS part_number,
                                 pm.name                                    AS part_name,
                                 t.part_version_id                          AS part_version_id,
                                 t.delivery_type                            AS delivery_type,
                                 t.process_task_no                          AS process_task_no,
                                 t.requirement_date                         AS requirement_date,
                                 ds.release_time                            AS release_date,
                                 release_user.name                          AS release_person_name,
                                 t.quantity                                 AS require_qty,
                                 ds.required_quantity                       AS distribution_qty,
                                 CASE
                                     WHEN ds.status = '1' THEN ds.required_quantity
                                     ELSE 0
                                     END                                    AS release_qty,
                                 CASE
                                     WHEN t.create_status = '0' OR ds.status IS NULL THEN '1'
                                     WHEN ds.status = '0' OR ds.status = '3' THEN '2'
                                     ELSE '3'
                                     END                                    AS distribution_status,
                                 s.number                                   AS supp_code,
                                 s.name                                     AS supp_name,
                                 t.po_sa_no                                 AS po_sa_no,
                                 t.purchase_group                           AS purchase_group,
                                 t.purchase_group_desc                      AS purchase_group_desc,
                                 t.production_order_no                      AS production_order_no,
                                 t.production_batch_no                      AS production_batch_no,
                                 t.supply_type                              AS supply_type,
                                 CASE
                                     WHEN t.line_status = '0' THEN '0'
                                     ELSE '1'
                                     END                                    AS line_status,
                                 t.order_type                               AS order_type,
                                 (SELECT mc.number
                                  FROM mbm_mdm_classification_part_link pl
                                           JOIN mbm_mdm_classification mc ON pl.classification_id = mc.id
                                  WHERE pl.part_version_id = t.part_version_id
                                    AND mc.root_node = 'logistics' LIMIT 1) AS logistics_type,
                                 CASE
                                     WHEN ds.id IS NULL THEN t.id
                                     ELSE ds.id
                                     END                                    AS id
                          FROM filtered_demand t
                                   LEFT JOIN mbm_mdm_part_version pv ON t.part_version_id = pv.id
                                   LEFT JOIN mbm_mdm_part_master pm ON pv.part_master_id = pm.id
                                   LEFT JOIN mbm_mdm_csm_supplier s ON t.supplier_id = s.id
                                   LEFT JOIN mbm_mdm_work_area_version version_factory
                                             ON t.branch_factory_id = version_factory.id
                                   LEFT JOIN mbm_mdm_work_area_master master_factory
                                             ON version_factory.work_area_master_id = master_factory.id
                                   LEFT JOIN mbm_mdm_work_area_version version_section
                                             ON t.work_segment_id = version_section.id
                                   LEFT JOIN mbm_mdm_work_area_master master_section
                                             ON version_section.work_area_master_id = master_section.id
                                   LEFT JOIN mbm_mdm_work_area_version version_work
                                             ON t.work_center_id = version_work.id
                                   LEFT JOIN mbm_mdm_work_area_master master_work
                                             ON version_work.work_area_master_id = master_work.id
                                   LEFT JOIN mbm_logistics_pe_distribution_sheet ds
                                             ON t.id = ds.distribution_demand_id AND ds.delete_flag = '0' AND
                                                ds.distribution_type = '1'
                                   LEFT JOIN mbm_mdm_storage_location point_location
                                             ON ds.storage_location_id = point_location.id
                                   LEFT JOIN mbm_mdm_storage_area point_area
                                             ON point_location.store_area_id = point_area.id
                                   LEFT JOIN rbac_user release_user ON ds.release_person = release_user.id
                          WHERE 1 = 1) t
                    ORDER BY t.delivery_plan_no, t.delivery_plan_line_no, t.distribution_line_number DESC, t.id LIMIT 20
                    OFFSET 0),
     latest_release AS (SELECT ds.distribution_demand_id,
                               ds.storage_location_id,
                               ROW_NUMBER() OVER (PARTITION BY ds.distribution_demand_id ORDER BY ds.release_time DESC, ds.id DESC) AS rn
                        FROM mbm_logistics_pe_distribution_sheet ds
                        WHERE ds.delete_flag = '0'
                          AND ds.distribution_type = '1'
                          AND ds.status IN ('1', '4')
                          AND ds.release_time IS NOT NULL
                          AND EXISTS (SELECT 1 FROM candidates c WHERE c.demand_id = ds.distribution_demand_id)),
     base AS (SELECT *
              FROM (SELECT t.delivery_plan_no,
                           t.delivery_plan_line_no,
                           t.external_receive_location,
                           t.delivery_plan_detail_no,
                           t.distribution_order_no,
                           t.distribution_line_number,
                           t.distribution_point_code,
                           t.distribution_point_name,
                           t.branch_factory_name,
                           t.work_segment_name,
                           t.work_center_name,
                           t.part_number,
                           t.part_name,
                           t.part_version_id,
                           t.delivery_type,
                           t.process_task_no,
                           t.requirement_date,
                           t.release_date,
                           t.release_person_name,
                           t.require_qty,
                           t.distribution_qty,
                           t.release_qty,
                           t.distribution_status,
                           t.supp_code,
                           t.supp_name,
                           t.po_sa_no,
                           t.purchase_group,
                           t.purchase_group_desc,
                           t.production_order_no,
                           t.production_batch_no,
                           t.supply_type,
                           t.line_status,
                           t.order_type,
                           t.logistics_type,
                           t.id,
                           released_area.name AS released_distribution_point
                    FROM candidates t
                             LEFT JOIN latest_release lr ON lr.distribution_demand_id = t.demand_id AND lr.rn = 1
                             LEFT JOIN mbm_mdm_storage_location released_location
                                       ON lr.storage_location_id = released_location.id
                             LEFT JOIN mbm_mdm_storage_area released_area
                                       ON released_location.store_area_id = released_area.id) t)
        ,
     th_summary AS (SELECT palletizing_order_number,
                           LTRIM(palletizing_order_line_number, '0')                                             AS palletizing_order_line_number_key,
                           part_version_id,
                           MAX(status)                                                                           AS wms_status,
                           MAX(clogin_status)                                                                    AS clogin_status,
                           MAX(transit_status)                                                                   AS transit_status,
                           MAX(lottable07)                                                                       AS quality_status,
                           MAX(data_source)                                                                      AS data_source,
                           SUM(CASE
                                   WHEN status NOT IN ('9', '11') AND clogin_status = '0' THEN
                                       CASE
                                           WHEN data_source = '1' THEN
                                               CASE
                                                   WHEN status = '20' OR qty_expected IS NULL THEN 0
                                                   ELSE qty_expected - COALESCE(qty_received, 0) END
                                           ELSE COALESCE(transit_quantity, 0) END
                                   ELSE 0 END)                                                                   AS transit_qty,
                           SUM(CASE
                                   WHEN status IN ('9', '11') THEN COALESCE(qty_received, 0)
                                   WHEN status NOT IN ('9', '11') AND CAST(clogin_status AS NUMERIC) >= 1 THEN
                                       CASE
                                           WHEN data_source = '1' THEN
                                               CASE
                                                   WHEN status = '20' OR qty_expected IS NULL THEN 0
                                                   ELSE qty_expected - COALESCE(qty_received, 0) END
                                           ELSE COALESCE(transit_quantity, 0) END
                                   ELSE 0 END)                                                                   AS arrive_qty,
                           SUM(CASE
                                   WHEN status IN ('9', '11') THEN COALESCE(qty_received, 0)
                                   ELSE 0 END)                                                                   AS receipt_qty,
                           SUM(CASE
                                   WHEN ext_udf_lkup10 IN ('5', '9') THEN COALESCE(qty_expected, 0)
                                   ELSE 0 END)                                                                   AS erp_receipt_qty
                    FROM mbm_logistics_asn_delivery_info
                    WHERE delete_flag = '0'
                      AND EXISTS (SELECT 1
                                  FROM base b
                                  WHERE b.distribution_order_no = palletizing_order_number
                                    AND
                                      LTRIM(b.distribution_line_number, '0') = LTRIM(palletizing_order_line_number, '0')
                                    AND b.part_version_id = mbm_logistics_asn_delivery_info.part_version_id)
                    GROUP BY palletizing_order_number,
                             LTRIM(palletizing_order_line_number, '0'),
                             part_version_id)
SELECT *
FROM (SELECT t.*,
             CASE

                 WHEN COALESCE(th.receipt_qty, 0) <> 0
                      AND COALESCE(th.receipt_qty, 0) = COALESCE(t.distribution_qty, 0)
                     THEN '3'


                 WHEN COALESCE(th.receipt_qty, 0) <> 0
                      AND COALESCE(th.receipt_qty, 0) <> COALESCE(t.distribution_qty, 0)
                     THEN '4'


                 WHEN COALESCE(th.arrive_qty, 0) <> 0
                      AND COALESCE(th.receipt_qty, 0) = 0
                     THEN '2'


                 WHEN COALESCE(th.transit_qty, 0) <> 0
                      AND COALESCE(th.arrive_qty, 0) = 0
                      AND COALESCE(th.receipt_qty, 0) = 0
                     THEN '1'


                 WHEN COALESCE(th.transit_qty, 0) = 0
                      AND COALESCE(th.arrive_qty, 0) = 0
                      AND COALESCE(th.receipt_qty, 0) = 0
                     THEN '0'

                 ELSE '0'
             END AS delivery_status,
             COALESCE(th.transit_qty, 0)     AS transit_qty,
             COALESCE(th.arrive_qty, 0)      AS arrive_qty,
             COALESCE(th.receipt_qty, 0)     AS receipt_qty,
             COALESCE(th.erp_receipt_qty, 0) AS erp_receipt_qty,
             th.wms_status                   AS wms_status,
             th.clogin_status                AS clogin_status,
             th.transit_status               AS transit_status,
             th.quality_status               AS quality_status,
             th.data_source                  AS data_source
      FROM base t
               LEFT JOIN th_summary th ON t.distribution_order_no = th.palletizing_order_number
          AND LTRIM(t.distribution_line_number, '0') = th.palletizing_order_line_number_key
          AND t.part_version_id = th.part_version_id) t
ORDER BY t.delivery_plan_no, t.delivery_plan_line_no, t.distribution_line_number DESC, t.id