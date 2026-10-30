WITH th_summary AS (SELECT palletizing_order_number,
                           LTRIM(palletizing_order_line_number, '0')                                 AS palletizing_order_line_number_key,
                           part_version_id,
                           MAX(status)                                                               AS wms_status,
                           MAX(clogin_status)                                                        AS clogin_status,
                           MAX(transit_status)                                                       AS transit_status,
                           MAX(lottable07)                                                           AS quality_status,
                           MAX(data_source)                                                          AS data_source,
                           SUM(CASE
                                   WHEN status NOT IN ('9', '11') AND clogin_status = '0' THEN
                                       CASE
                                           WHEN data_source = '1' THEN
                                               CASE
                                                   WHEN status = '20' OR qty_expected IS NULL THEN 0
                                                   ELSE qty_expected - NVL(qty_received, 0) END
                                           ELSE NVL(transit_quantity, 0) END
                                   ELSE 0 END)                                                       AS transit_qty,
                           SUM(CASE
                                   WHEN status IN ('9', '11') THEN NVL(qty_received, 0)
                                   WHEN status NOT IN ('9', '11') AND TO_NUMBER(clogin_status) >= 1 THEN
                                       CASE
                                           WHEN data_source = '1' THEN
                                               CASE
                                                   WHEN status = '20' OR qty_expected IS NULL THEN 0
                                                   ELSE qty_expected - NVL(qty_received, 0) END
                                           ELSE NVL(transit_quantity, 0) END
                                   ELSE 0 END)                                                       AS arrive_qty,
                           SUM(CASE WHEN status IN ('9', '11') THEN NVL(qty_received, 0) ELSE 0 END) AS receipt_qty,
                           SUM(CASE
                                   WHEN ext_udf_lkup10 IN ('5', '9') THEN NVL(qty_expected, 0)
                                   ELSE 0 END)                                                       AS erp_receipt_qty
                    FROM mbm_logistics_asn_delivery_info
                    WHERE delete_flag = '0'
                    GROUP BY palletizing_order_number,
                             LTRIM(palletizing_order_line_number, '0'),
                             part_version_id)
SELECT *
FROM (SELECT t.delivery_plan_no           AS delivery_plan_no,
             t.delivery_plan_line_no      AS delivery_plan_line_no,
             t.external_receive_location  AS external_receive_location,
             t.delivery_plan_detail_no    AS delivery_plan_detail_no,
             ds.distribution_order_no     AS distribution_order_no,
             ds.distribution_line_number  AS distribution_line_number,
             point_area."NUMBER"          AS distribution_point_code,
             point_area.name              AS distribution_point_name,
             released_area.name           AS released_distribution_point,
             master_factory.name          AS branch_factory_name,
             master_section.name          AS work_segment_name,
             master_work.name             AS work_center_name,
             pm."NUMBER"                  AS part_number,
             pm.name                      AS part_name,
             t.part_version_id            AS part_version_id,
             t.delivery_type              AS delivery_type,
             t.process_task_no            AS process_task_no,
             t.requirement_date           AS requirement_date,
             ds.release_time              AS release_date,
             release_user.name            AS release_person_name,
             t.quantity                   AS require_qty,
             ds.required_quantity         AS distribution_qty,
             CASE
                 WHEN NVL(th.receipt_qty, 0) <> 0
                     AND NVL(th.receipt_qty, 0) = NVL(ds.required_quantity, 0)
                     THEN '3'
                 WHEN NVL(th.receipt_qty, 0) <> 0
                     AND NVL(th.receipt_qty, 0) <> NVL(ds.required_quantity, 0)
                     THEN '4'
                 WHEN NVL(th.arrive_qty, 0) <> 0
                     AND NVL(th.receipt_qty, 0) = 0
                     THEN '2'
                 WHEN NVL(th.transit_qty, 0) <> 0
                     AND NVL(th.arrive_qty, 0) = 0
                     AND NVL(th.receipt_qty, 0) = 0
                     THEN '1'
                 WHEN NVL(th.transit_qty, 0) = 0
                     AND NVL(th.arrive_qty, 0) = 0
                     AND NVL(th.receipt_qty, 0) = 0
                     THEN '0'
                 ELSE '0'
                 END                      AS delivery_status,
             NVL(th.transit_qty, 0)       AS transit_qty,--在途数量
             NVL(th.arrive_qty, 0)        AS arrive_qty,--登到数量
             NVL(th.receipt_qty, 0)       AS receipt_qty,--入库数量
             NVL(th.erp_receipt_qty, 0)   AS erp_receipt_qty,--ERP入库数量
             th.wms_status                AS wms_status,
             th.clogin_status             AS clogin_status,
             th.transit_status            AS transit_status,
             th.quality_status            AS quality_status,
             th.data_source               AS data_source,
             s."NUMBER"                   AS supp_code,
             s.name                       AS supp_name,
             t.po_sa_no                   AS po_sa_no,
             t.purchase_group             AS purchase_group,
             t.purchase_group_desc        AS purchase_group_desc,
             t.production_order_no        AS production_order_no,
             t.production_batch_no        AS production_batch_no,
             t.supply_type                AS supply_type,
             CASE
                 WHEN t.line_status = '0' THEN '0'
                 ELSE '1'
                 END                      AS line_status,
             t.order_type                 AS order_type,
             (SELECT mc."NUMBER"
              FROM mbm_mdm_classification_part_link pl
                       JOIN mbm_mdm_classification mc ON pl.classification_id = mc.id
              WHERE pl.part_version_id = t.part_version_id
                AND mc.root_node = 'logistics'
                  FETCH FIRST 1 ROW ONLY) AS logistics_type,
             CASE
                 WHEN ds.id IS NULL THEN t.id
                 ELSE ds.id
                 END                      AS id
      FROM mbm_logistics_pe_distribution_demand t
               LEFT JOIN mbm_mdm_part_version pv ON t.part_version_id = pv.id
               LEFT JOIN mbm_mdm_part_master pm ON pv.part_master_id = pm.id
               LEFT JOIN mbm_mdm_csm_supplier s ON t.supplier_id = s.id
               LEFT JOIN mbm_mdm_work_area_version version_factory ON t.branch_factory_id = version_factory.id
               LEFT JOIN mbm_mdm_work_area_master master_factory
                         ON version_factory.work_area_master_id = master_factory.id
               LEFT JOIN mbm_mdm_work_area_version version_section ON t.work_segment_id = version_section.id
               LEFT JOIN mbm_mdm_work_area_master master_section
                         ON version_section.work_area_master_id = master_section.id
               LEFT JOIN mbm_mdm_work_area_version version_work ON t.work_center_id = version_work.id
               LEFT JOIN mbm_mdm_work_area_master master_work ON version_work.work_area_master_id = master_work.id
               LEFT JOIN mbm_logistics_pe_distribution_sheet ds
                         ON t.id = ds.distribution_demand_id AND ds.delete_flag = '0' AND ds.distribution_type = '1'
               LEFT JOIN mbm_mdm_storage_location point_location ON ds.storage_location_id = point_location.id
               LEFT JOIN mbm_mdm_storage_area point_area ON point_location.store_area_id = point_area.id
               LEFT JOIN (SELECT distribution_demand_id,
                                 storage_location_id,
                                 ROW_NUMBER() OVER (PARTITION BY distribution_demand_id ORDER BY release_time DESC, id DESC) AS rn
                          FROM mbm_logistics_pe_distribution_sheet
                          WHERE delete_flag = '0'
                            AND distribution_type = '1'
                            AND status IN ('1', '4')
                            AND release_time IS NOT NULL) latest_release
                         ON latest_release.distribution_demand_id = t.id AND latest_release.rn = 1
               LEFT JOIN mbm_mdm_storage_location released_location
                         ON latest_release.storage_location_id = released_location.id
               LEFT JOIN mbm_mdm_storage_area released_area ON released_location.store_area_id = released_area.id
               LEFT JOIN rbac_user release_user ON ds.release_person = release_user.id
               LEFT JOIN th_summary th ON ds.distribution_order_no = th.palletizing_order_number
          AND LTRIM(ds.distribution_line_number, '0') = th.palletizing_order_line_number_key
          AND t.part_version_id = th.part_version_id
      WHERE t.delete_flag = '0') t
ORDER BY t.delivery_plan_no, t.delivery_plan_line_no, t.distribution_line_number DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
-- 在途数量 transitQty
-- 登到数量 arriveQty
-- 入库数量 receiptQty
-- ERP入库数量 erpReceiptQty


