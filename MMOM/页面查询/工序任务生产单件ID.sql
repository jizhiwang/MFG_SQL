SELECT "t"."production_status"                                           AS "productionStatus",
       "t"."self_inspection_status"                                      AS "selfInspectionStatus",
       "t"."special_inspection_status"                                   AS "specialInspectionStatus",
       "t__processTechOrder__branchFactory__workAreaMaster"."name"       AS "branchFactoryName",
       "t__processTechOrder__workSegment__workAreaMaster"."name"         AS "workSegmentName",
       "t__processTechOrder__workCenter"."id"                            AS "workCenterId",
       "t__processTechOrder__workCenter__workAreaMaster"."name"          AS "workCenterName",
       "t__processTechOrder__workSection__rbacOrganization"."name"       AS "workSectionName",
       "t__processTechOrder"."node_number"                               AS "nodeNumber",
       "t__processTechOrder"."process_control"                           AS "processControl",
       "t__processTechOrder__operationVersion__operationMaster"."number" AS "operationNumber",
       "t__processTechOrder"."process_description"                       AS "processDescription",
       "t__processTechOrder"."number"                                    AS "processTechOrderNumber",
       "t__processTechOrder__productOrder"."number"                      AS "orderNumber",
       "t__processTechOrder__productOrder"."batch_no"                    AS "batchNo",
       "t__singlePieceId"."sn"                                           AS "sn",
       "t__singlePieceId__mbmInternalVehicleCode"."internal_vehicle_no"  AS "internalVehicleNo",
       "t__partVersion__partMaster"."number"                             AS "partNumber",
       "t__partVersion__partMaster"."name"                               AS "partName",
       "t__processTechOrder"."plan_start"                                AS "planStart",
       "t__processTechOrder"."plan_end"                                  AS "planEnd",
       "t__processTechOrder"."ds_plan_start"                             AS "dsPlanStart",
       "t__processTechOrder"."ds_plan_end"                               AS "dsPlanEnd",
       "t"."online_time"                                                 AS "onlineTime",
       "t"."offline_time"                                                AS "offlineTime",
       "t__processTechOrder"."qty"                                       AS "processTechOrderQty",
       "t__processTechOrder"."completed_qty"                             AS "processTechOrderReportedQty",
       "t"."printed_qty"                                                 AS "printedQty",
       "t__processTechOrder__productOrderRoute"."direct_manual_time"     AS "directManualTime",
       "t"."is_out"                                                      AS "isOut",
       "t"."id"                                                          AS "id"
FROM "mbm_mes_process_tech_order_id" "t"
         LEFT JOIN "mbm_aps_process_tech_order" "t__processTechOrder"
                   ON "t"."mes_process_tech_order_id" = "t__processTechOrder"."id" AND
                      ("t__processTechOrder"."delete_flag" != '1' OR "t__processTechOrder"."delete_flag" IS NULL)
         LEFT JOIN "mbm_aps_product_order" "t__processTechOrder__productOrder"
                   ON "t__processTechOrder"."product_order_id" = "t__processTechOrder__productOrder"."id" AND
                      ("t__processTechOrder__productOrder"."delete_flag" != '1' OR "t__processTechOrder__productOrder"."delete_flag" IS NULL)
         LEFT JOIN "mbm_mdm_part_version" "t__partVersion" ON "t"."part_version_id" = "t__partVersion"."id" AND
                                                              ("t__partVersion"."delete_flag" != '1' OR "t__partVersion"."delete_flag" IS NULL)
         LEFT JOIN "mbm_mdm_work_area_version" "t__processTechOrder__branchFactory"
                   ON "t__processTechOrder"."branch_factory_id" = "t__processTechOrder__branchFactory"."id" AND
                      ("t__processTechOrder__branchFactory"."delete_flag" != '1' OR "t__processTechOrder__branchFactory"."delete_flag" IS NULL)
         LEFT JOIN "mbm_mdm_work_area_master" "t__processTechOrder__branchFactory__workAreaMaster"
                   ON "t__processTechOrder__branchFactory"."work_area_master_id" =
                      "t__processTechOrder__branchFactory__workAreaMaster"."id" AND
                      ("t__processTechOrder__branchFactory__workAreaMaster"."delete_flag" != '1' OR "t__processTechOrder__branchFactory__workAreaMaster"."delete_flag" IS NULL)
         LEFT JOIN "mbm_mdm_work_area_version" "t__processTechOrder__workSegment"
                   ON "t__processTechOrder"."work_segment_id" = "t__processTechOrder__workSegment"."id" AND
                      ("t__processTechOrder__workSegment"."delete_flag" != '1' OR "t__processTechOrder__workSegment"."delete_flag" IS NULL)
         LEFT JOIN "mbm_mdm_work_area_master" "t__processTechOrder__workSegment__workAreaMaster"
                   ON "t__processTechOrder__workSegment"."work_area_master_id" =
                      "t__processTechOrder__workSegment__workAreaMaster"."id" AND
                      ("t__processTechOrder__workSegment__workAreaMaster"."delete_flag" != '1' OR "t__processTechOrder__workSegment__workAreaMaster"."delete_flag" IS NULL)
         LEFT JOIN "mbm_mdm_work_area_version" "t__processTechOrder__workCenter"
                   ON "t__processTechOrder"."work_center_id" = "t__processTechOrder__workCenter"."id" AND
                      ("t__processTechOrder__workCenter"."delete_flag" != '1' OR "t__processTechOrder__workCenter"."delete_flag" IS NULL)
         LEFT JOIN "mbm_mdm_work_area_master" "t__processTechOrder__workCenter__workAreaMaster"
                   ON "t__processTechOrder__workCenter"."work_area_master_id" =
                      "t__processTechOrder__workCenter__workAreaMaster"."id" AND
                      ("t__processTechOrder__workCenter__workAreaMaster"."delete_flag" != '1' OR "t__processTechOrder__workCenter__workAreaMaster"."delete_flag" IS NULL)
         LEFT JOIN "mbm_mdm_hr_organization" "t__processTechOrder__workSection"
                   ON "t__processTechOrder"."work_section_id" = "t__processTechOrder__workSection"."id" AND
                      ("t__processTechOrder__workSection"."delete_flag" != '1' OR "t__processTechOrder__workSection"."delete_flag" IS NULL)
         LEFT JOIN "rbac_organization" "t__processTechOrder__workSection__rbacOrganization"
                   ON "t__processTechOrder__workSection"."rbac_organization_id" =
                      "t__processTechOrder__workSection__rbacOrganization"."id"
         LEFT JOIN "mbm_mdm_operation_version" "t__processTechOrder__operationVersion"
                   ON "t__processTechOrder"."process_tech_id" = "t__processTechOrder__operationVersion"."id" AND
                      ("t__processTechOrder__operationVersion"."delete_flag" != '1' OR "t__processTechOrder__operationVersion"."delete_flag" IS NULL)
         LEFT JOIN "mbm_mdm_operation_master" "t__processTechOrder__operationVersion__operationMaster"
                   ON "t__processTechOrder__operationVersion"."operation_master_id" =
                      "t__processTechOrder__operationVersion__operationMaster"."id" AND
                      ("t__processTechOrder__operationVersion__operationMaster"."delete_flag" != '1' OR "t__processTechOrder__operationVersion__operationMaster"."delete_flag" IS NULL)
         LEFT JOIN "mbm_mes_single_piece_id" "t__singlePieceId" ON "t"."single_piece_id" = "t__singlePieceId"."id" AND
                                                                   ("t__singlePieceId"."delete_flag" != '1' OR "t__singlePieceId"."delete_flag" IS NULL)
         LEFT JOIN "mbm_mdm_internal_vehicle_code" "t__singlePieceId__mbmInternalVehicleCode"
                   ON "t__singlePieceId"."sn" = "t__singlePieceId__mbmInternalVehicleCode"."vin_code" AND
                      ("t__singlePieceId__mbmInternalVehicleCode"."delete_flag" != '1' OR "t__singlePieceId__mbmInternalVehicleCode"."delete_flag" IS NULL)
         LEFT JOIN "mbm_mdm_part_master" "t__partVersion__partMaster"
                   ON "t__partVersion"."part_master_id" = "t__partVersion__partMaster"."id" AND
                      ("t__partVersion__partMaster"."delete_flag" != '1' OR "t__partVersion__partMaster"."delete_flag" IS NULL)
         LEFT JOIN "mbm_aps_product_order_route" "t__processTechOrder__productOrderRoute"
                   ON "t__processTechOrder"."product_order_route_id" = "t__processTechOrder__productOrderRoute"."id" AND
                      ("t__processTechOrder__productOrderRoute"."delete_flag" != '1' OR "t__processTechOrder__productOrderRoute"."delete_flag" IS NULL)
WHERE "t__processTechOrder"."whether_reporting_point_when_generate" = '1'
  AND "t"."production_status" IN ('10', '20')
  AND "t__partVersion"."production_management_mode" = '10'
  AND ("t__processTechOrder__productOrder"."auxiliary_type" != 'C' OR "t__processTechOrder__productOrder"."auxiliary_type" IS NULL)
  AND ("t__processTechOrder__productOrder"."kd_order" != 'X' OR "t__processTechOrder__productOrder"."kd_order" IS NULL OR ("t__processTechOrder__productOrder"."auxiliary_type" != 'A' OR "t__processTechOrder__productOrder"."auxiliary_type" IS NULL))
  AND ("t"."delete_flag" != '1' OR "t"."delete_flag" IS NULL)
ORDER BY "t__processTechOrder"."plan_start", "t__processTechOrder"."product_order_id",
         "t__processTechOrder"."node_number" LIMIT 31
OFFSET 0
