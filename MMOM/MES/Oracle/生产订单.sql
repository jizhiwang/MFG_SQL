SELECT "T"."ERP_PROCESS_ROUTE"                                   AS "erpProcessRoute",
       "T"."LEVEL"                                               AS "level",
       "T"."ERP_CREATE_DATE"                                     AS "erpCreateDate",
       "T"."CREATE_DATE"                                         AS "createDate",
       "T__PARTVERSION__PARTMASTER"."NUMBER"                     AS "itemNumber",
       "T"."SALE_LINE_NO"                                        AS "saleLineNo",
       "T"."ACTUAL_START"                                        AS "actualStart",
       "T"."IS_PRIORITY_ORDER"                                   AS "isPriorityOrder",
       "T"."TRADE_HANDBOOK"                                      AS "tradeHandbook",
       "T"."ERP_INPUT_VERSION"                                   AS "erpInputVersion",
       "T"."SCHEDULE_FLAG"                                       AS "scheduleFlag",
       "T__FACTORY__WORKAREAMASTER"."NAME"                       AS "factoryName",
       "T"."TEMPORARY_CHANGE_NO"                                 AS "temporaryChangeNo",
       "T"."IS_BIND_ASSEMBLY_ORDER"                              AS "isBindAssemblyOrder",
       "T__CUSTOMER"."NUMBER"                                    AS "customerNo",
       "T"."QTY"                                                 AS "qty",
       "T"."MRP_CONTROLLER"                                      AS "mrpController",
       "T__PARTVERSION"."ID"                                     AS "partVersionId",
       "T"."PRODUCT_VERSION"                                     AS "productVersion",
       "T"."LOGISTICS_STATUS"                                    AS "logisticsStatus",
       "T"."PLAN_START"                                          AS "planStart",
       "T"."QUALITY_CATEGORY"                                    AS "qualityCategory",
       "T"."REFORM_INSTRUCTIONS"                                 AS "reformInstructions",
       "T"."ERP_CREATE_USER"                                     AS "erpCreateUser",
       "T"."ASSEMBLY_ORDER_NO"                                   AS "assemblyOrderNo",
       "T"."BATCH_NUMBER2"                                       AS "batchNumber2",
       "T__BRANCHFACTORY__WORKAREAMASTER"."NAME"                 AS "branchFactoryName",
       "T"."ACTUAL_END"                                          AS "actualEnd",
       "T__TOPORDER"."ID"                                        AS "topOrderId",
       "T"."ITEM_EXT_PROP_NAME"                                  AS "itemExtPropName",
       "T__CUSTOMER"."NAME"                                      AS "customerName",
       "T"."DATA_SOURCE"                                         AS "dataSource",
       "T__PROCESSVERSION"."ID"                                  AS "processVersionId",
       "T"."MATERIAL_GROUP"                                      AS "materialGroup",
       "T"."ERP_WORK_FLOW_VERSION"                               AS "erpWorkFlowVersion",
       "T"."COUNTRY"                                             AS "country",
       "T__TOPORDER"."NUMBER"                                    AS "topOrderCode",
       "T"."SALE_AREA_BOM_ID"                                    AS "saleAreaBomId",
       "T__BRANCHFACTORY"."ID"                                   AS "branchFactoryId",
       "T"."PRIORITY"                                            AS "priority",
       "T"."EXPAND_STATUS"                                       AS "expandStatus",
       "T"."IS_DECIMAL_BOM"                                      AS "isDecimalBom",
       "T"."REGION_MARK"                                         AS "regionMark",
       "T"."PRODUCT_MODEL"                                       AS "productModel",
       "T"."WBS"                                                 AS "wbs",
       "T__BRANCHFACTORY__WORKAREAMASTER"."SOURCE_SYSTEM_NUMBER" AS "branchFactoryNumber",
       "T__ORDERTYPE"."ORDER_TYPE"                               AS "orderTypeCode",
       "T__PARTVERSION__PARTMASTER"."ID"                         AS "itemId",
       "T"."OBLIGATE_NO"                                         AS "obligateNo",
       "T"."UNIT"                                                AS "unit",
       "T__FACTORY__WORKAREAMASTER"."SOURCE_SYSTEM_NUMBER"       AS "factoryNumber",
       "T__PROCESSVERSION__PROCESSMASTER"."NAME"                 AS "processName",
       "T__UPDATE_USER"."NAME"                                   AS "updateUserName",
       "T"."REQUIRE_DELIVERY"                                    AS "requireDelivery",
       "T"."HOME_INTERNATIONAL_MARK"                             AS "homeInternationalMark",
       "T__CUSTOMER"."ID"                                        AS "customerId",
       "T"."SP_CONF_NOTES"                                       AS "spConfNotes",
       "T"."SUGGEST_START"                                       AS "suggestStart",
       "T"."TRADE_ORDER"                                         AS "tradeOrder",
       "T"."IS_EXIST_BATCH_REL"                                  AS "isExistBatchRel",
       "T"."QUALITY_SPECIAL_REQUIREMENT"                         AS "qualitySpecialRequirement",
       "T__ORDERTYPE"."PRODUCT_TYPE"                             AS "productType",
       "T"."COMPLETE_QTY"                                        AS "completeQty",
       "T__WORKSEGMENT__WORKAREAMASTER"."SOURCE_SYSTEM_NUMBER"   AS "workSegmentNumber",
       "T"."ORDER_STATE"                                         AS "orderState",
       "T"."SHIPPING_ANNOUNCEMENT_NUMBER"                        AS "shippingAnnouncementNumber",
       "T"."DELAY_TIME"                                          AS "delayTime",
       "T"."IS_DELAY"                                            AS "isDelay",
       "T"."ERP_UPDATE_USER"                                     AS "erpUpdateUser",
       "T"."ERP_RELATION_READY"                                  AS "erpRelationReady",
       "T"."MODELS"                                              AS "models",
       "T__PROCESSVERSION"."VERSION"                             AS "processVersionVersion",
       "T"."KD_ORDER"                                            AS "kdOrder",
       "T__WORKSEGMENT"."ID"                                     AS "workSegmentId",
       "T"."SUGGEST_END"                                         AS "suggestEnd",
       "T"."NUMBER"                                              AS "number",
       "T"."PLAN_END"                                            AS "planEnd",
       "T"."IS_SYNCED_DS_AS"                                     AS "isSyncedDsAs",
       "T"."ERP_TASK_ID"                                         AS "erpTaskId",
       "T"."WAIT_STORED_TAG"                                     AS "waitStoredTag",
       "T__PROCESSVERSION__PROCESSMASTER"."ID"                   AS "processId",
       "T__WORKSEGMENT__WORKAREAMASTER"."NAME"                   AS "workSegmentName",
       "T"."AUXILIARY_TYPE"                                      AS "auxiliaryType",
       "T"."SALE_NO"                                             AS "saleNo",
       "T__FACTORY"."ID"                                         AS "factoryId",
       "T__ORDERTYPE"."ID"                                       AS "orderTypeId",
       "T__PARTVERSION__PARTMASTER"."NAME"                       AS "itemName",
       "T"."ERP_CONTENT_DIGEST"                                  AS "erpContentDigest",
       "T"."CONFIG_BARCODE"                                      AS "configBarcode",
       "T"."SORT_NO"                                             AS "sortNo",
       "T"."SUSPENDED"                                           AS "suspended",
       "T"."UPDATE_DATE"                                         AS "updateDate",
       "T__CREATE_USER"."NAME"                                   AS "createUserName",
       "T"."INVENTORY_LOCATION"                                  AS "inventoryLocation",
       "T__PARTVERSION"."PRODUCTION_MANAGEMENT_MODE"             AS "productionManagementMode",
       "T"."ERP_UPDATE_DATE"                                     AS "erpUpdateDate",
       "T__PARTVERSION"."SPECIFICATION_MODEL"                    AS "specificationModel",
       "T"."BATCH_NO"                                            AS "batchNo",
       "T"."ORDER_GRAPH_ID"                                      AS "orderGraphId",
       "T__ORDERTYPE"."TYPE_DESC"                                AS "orderTypeDesc",
       "T"."WORK_SEGMENT_ID"                                     AS "workSegment",
       "T"."TOP_ORDER_ID"                                        AS "topOrder",
       "T"."FACTORY_ID"                                          AS "factory",
       "T"."BRANCH_FACTORY_ID"                                   AS "branchFactory",
       "T"."ORDER_CONFIG_ID"                                     AS "orderType",
       "T"."CUSTOMER_ID"                                         AS "customer",
       "T"."PART_VERSION_ID"                                     AS "partVersion",
       "T"."PROCESS_VERSION_ID"                                  AS "processVersion",
       "T"."SITE_ID"                                             AS "siteId",
       "T"."SOURCE_ID"                                           AS "sourceId",
       "T"."ID"                                                  AS "id",
       "T"."TENANT_ID"                                           AS "tenant_id",
       "T"."CREATE_USER"                                         AS "create_user",
       "T"."CREATE_DATE"                                         AS "create_date",
       "T"."UPDATE_USER"                                         AS "update_user",
       "T"."UPDATE_DATE"                                         AS "update_date",
       "T"."DELETE_FLAG"                                         AS "delete_flag"
FROM "MBM_APS_PRODUCT_ORDER" "T"
         LEFT JOIN "MBM_MDM_PART_VERSION" "T__PARTVERSION"
                   ON "T"."PART_VERSION_ID" = "T__PARTVERSION"."ID"
                       AND ("T__PARTVERSION"."DELETE_FLAG" != '1' OR "T__PARTVERSION"."DELETE_FLAG" IS NULL)
         LEFT JOIN "MBM_MDM_PART_MASTER" "T__PARTVERSION__PARTMASTER"
                   ON "T__PARTVERSION"."PART_MASTER_ID" = "T__PARTVERSION__PARTMASTER"."ID"
                       AND
                      ("T__PARTVERSION__PARTMASTER"."DELETE_FLAG" != '1' OR
                       "T__PARTVERSION__PARTMASTER"."DELETE_FLAG" IS NULL)
         LEFT JOIN "MBM_MDM_WORK_AREA_VERSION" "T__FACTORY"
                   ON "T"."FACTORY_ID" = "T__FACTORY"."ID"
                       AND ("T__FACTORY"."DELETE_FLAG" != '1' OR "T__FACTORY"."DELETE_FLAG" IS NULL)
         LEFT JOIN "MBM_MDM_WORK_AREA_MASTER" "T__FACTORY__WORKAREAMASTER"
                   ON "T__FACTORY"."WORK_AREA_MASTER_ID" = "T__FACTORY__WORKAREAMASTER"."ID"
                       AND
                      ("T__FACTORY__WORKAREAMASTER"."DELETE_FLAG" != '1' OR
                       "T__FACTORY__WORKAREAMASTER"."DELETE_FLAG" IS NULL)
         LEFT JOIN "MBM_MDM_CSM_CUSTOMER" "T__CUSTOMER"
                   ON "T"."CUSTOMER_ID" = "T__CUSTOMER"."ID"
                       AND ("T__CUSTOMER"."DELETE_FLAG" != '1' OR "T__CUSTOMER"."DELETE_FLAG" IS NULL)
         LEFT JOIN "MBM_MDM_WORK_AREA_VERSION" "T__BRANCHFACTORY"
                   ON "T"."BRANCH_FACTORY_ID" = "T__BRANCHFACTORY"."ID"
                       AND ("T__BRANCHFACTORY"."DELETE_FLAG" != '1' OR "T__BRANCHFACTORY"."DELETE_FLAG" IS NULL)
         LEFT JOIN "MBM_MDM_WORK_AREA_MASTER" "T__BRANCHFACTORY__WORKAREAMASTER"
                   ON "T__BRANCHFACTORY"."WORK_AREA_MASTER_ID" = "T__BRANCHFACTORY__WORKAREAMASTER"."ID"
                       AND
                      ("T__BRANCHFACTORY__WORKAREAMASTER"."DELETE_FLAG" != '1' OR
                       "T__BRANCHFACTORY__WORKAREAMASTER"."DELETE_FLAG" IS NULL)
         LEFT JOIN "MBM_APS_PRODUCT_ORDER" "T__TOPORDER"
                   ON "T"."TOP_ORDER_ID" = "T__TOPORDER"."ID"
                       AND ("T__TOPORDER"."DELETE_FLAG" != '1' OR "T__TOPORDER"."DELETE_FLAG" IS NULL)
         LEFT JOIN "MBM_MDM_PROCESS_VERSION" "T__PROCESSVERSION"
                   ON "T"."PROCESS_VERSION_ID" = "T__PROCESSVERSION"."ID"
                       AND ("T__PROCESSVERSION"."DELETE_FLAG" != '1' OR "T__PROCESSVERSION"."DELETE_FLAG" IS NULL)
         LEFT JOIN "MBM_APS_ORDER_CONFIG" "T__ORDERTYPE"
                   ON "T"."ORDER_CONFIG_ID" = "T__ORDERTYPE"."ID"
         LEFT JOIN "MBM_MDM_PROCESS_MASTER" "T__PROCESSVERSION__PROCESSMASTER"
                   ON "T__PROCESSVERSION"."PROCESS_MASTER_ID" = "T__PROCESSVERSION__PROCESSMASTER"."ID"
                       AND
                      ("T__PROCESSVERSION__PROCESSMASTER"."DELETE_FLAG" != '1' OR
                       "T__PROCESSVERSION__PROCESSMASTER"."DELETE_FLAG" IS NULL)
         LEFT JOIN "RBAC_USER" "T__UPDATE_USER"
                   ON "T"."UPDATE_USER" = "T__UPDATE_USER"."ID"
         LEFT JOIN "MBM_MDM_WORK_AREA_VERSION" "T__WORKSEGMENT"
                   ON "T"."WORK_SEGMENT_ID" = "T__WORKSEGMENT"."ID"
                       AND ("T__WORKSEGMENT"."DELETE_FLAG" != '1' OR "T__WORKSEGMENT"."DELETE_FLAG" IS NULL)
         LEFT JOIN "MBM_MDM_WORK_AREA_MASTER" "T__WORKSEGMENT__WORKAREAMASTER"
                   ON "T__WORKSEGMENT"."WORK_AREA_MASTER_ID" = "T__WORKSEGMENT__WORKAREAMASTER"."ID"
                       AND
                      ("T__WORKSEGMENT__WORKAREAMASTER"."DELETE_FLAG" != '1' OR
                       "T__WORKSEGMENT__WORKAREAMASTER"."DELETE_FLAG" IS NULL)
         LEFT JOIN "RBAC_USER" "T__CREATE_USER"
                   ON "T"."CREATE_USER" = "T__CREATE_USER"."ID"
WHERE "T"."NUMBER" = :orderNo
  AND (
    ("T"."TENANT_ID" IN ('T2130', 'rbac_tenant_root', 'root') OR "T"."TENANT_ID" IS NULL)
        AND ("T"."SITE_ID" IN (:siteId) OR "T"."SITE_ID" IN (:siteId) OR "T"."SITE_ID" IN (:siteId))
    )
  AND ("T"."DELETE_FLAG" != '1' OR "T"."DELETE_FLAG" IS NULL)
ORDER BY "T"."ID" DESC;
