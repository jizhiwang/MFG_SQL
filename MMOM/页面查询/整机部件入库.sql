SELECT *
FROM (SELECT ROWNUM AS RN, PageTab.*
      FROM (SELECT "T"."NUMBER"                               AS "number",
                   "T"."STATE"                                AS "state",
                   "T"."RECEIPT_LARGE_CATEGORY_ID"            AS "receiptLargeCategory",
                   "T__PARTVERSION__PARTMASTER"."NUMBER"      AS "partNumber",
                   "T__PARTVERSION__PARTMASTER"."NAME"        AS "partName",
                   "T"."QTY"                                  AS "qty",
                   "T"."SN"                                   AS "sn",
                   "T__PRODUCTORDER"."NUMBER"                 AS "productionOrderNo",
                   "T__PRODUCTORDER"."BATCH_NO"               AS "productionBatchNumber",
                   "T__WAREHOUSE__STORAGEAREA"."NUMBER"       AS "warehouseNumber",
                   "T__WAREHOUSE__STORAGEAREA"."NAME"         AS "warehouseName",
                   "T__STORAGEZONE__STORAGEAREA"."NUMBER"     AS "storageZoneNumber",
                   "T__STORAGEZONE__STORAGEAREA"."NAME"       AS "storageZoneName",
                   "T__STORAGELOCATION__STORAGEAREA"."NUMBER" AS "storageLocationNumber",
                   "T__STORAGELOCATION__STORAGEAREA"."NAME"   AS "storageLocationName",
                   "T"."SAP_WAREHOUSE_OUT"                    AS "sapWarehouseOut",
                   "T"."SAP_WAREHOUSE_IN_CODE"                AS "sapWarehouseInCode",
                   "T"."INBOUND_DATE"                         AS "inboundDate",
                   "T"."LATITUDE_AND_LONGITUDE"               AS "latitudeAndLongitude",
                   "T__DELIVERYPRODUCTORDER"."NUMBER"         AS "deliveryOrderNo",
                   "T__DELIVERYPRODUCTORDER"."BATCH_NO"       AS "deliveryBatchNumber",
                   "T"."MACHINE_NUMBER"                       AS "machineNumber",
                   "T"."SAP_INBOUND_STATE"                    AS "sapInboundState",
                   "T"."ID"                                   AS "id",
                   "T__RECEIPTLARGECATEGORY"."ID"             AS "receiptLargeCategory.id",
                   "T__RECEIPTLARGECATEGORY"."NAME"           AS "receiptLargeCategory.name"
            FROM "MBM_WMS_ASN_COMPONENT_DELIVERY_ORDER" "T"
                     LEFT JOIN "MBM_MDM_PART_VERSION" "T__PARTVERSION"
                               ON "T"."PART_VERSION_ID" = "T__PARTVERSION"."ID" AND
                                  ("T__PARTVERSION"."DELETE_FLAG" != '1' OR "T__PARTVERSION"."DELETE_FLAG" IS NULL)
                     LEFT JOIN "MBM_MDM_PART_MASTER" "T__PARTVERSION__PARTMASTER"
                               ON "T__PARTVERSION"."PART_MASTER_ID" = "T__PARTVERSION__PARTMASTER"."ID" AND
                                  ("T__PARTVERSION__PARTMASTER"."DELETE_FLAG" != '1' OR "T__PARTVERSION__PARTMASTER"."DELETE_FLAG" IS NULL)
                     LEFT JOIN "MBM_APS_PRODUCT_ORDER" "T__PRODUCTORDER"
                               ON "T"."PRODUCT_ORDER_ID" = "T__PRODUCTORDER"."ID" AND
                                  ("T__PRODUCTORDER"."DELETE_FLAG" != '1' OR "T__PRODUCTORDER"."DELETE_FLAG" IS NULL)
                     LEFT JOIN "MBM_MDM_WAREHOUSE" "T__WAREHOUSE" ON "T"."WAREHOUSE_ID" = "T__WAREHOUSE"."ID" AND
                                                                     ("T__WAREHOUSE"."DELETE_FLAG" != '1' OR "T__WAREHOUSE"."DELETE_FLAG" IS NULL)
                     LEFT JOIN "MBM_MDM_STORAGE_AREA" "T__WAREHOUSE__STORAGEAREA"
                               ON "T__WAREHOUSE"."STORE_AREA_ID" = "T__WAREHOUSE__STORAGEAREA"."ID" AND
                                  ("T__WAREHOUSE__STORAGEAREA"."DELETE_FLAG" != '1' OR "T__WAREHOUSE__STORAGEAREA"."DELETE_FLAG" IS NULL)
                     LEFT JOIN "MBM_MDM_STORAGE_ZONE" "T__STORAGEZONE"
                               ON "T"."STORAGE_ZONE_ID" = "T__STORAGEZONE"."ID" AND
                                  ("T__STORAGEZONE"."DELETE_FLAG" != '1' OR "T__STORAGEZONE"."DELETE_FLAG" IS NULL)
                     LEFT JOIN "MBM_MDM_STORAGE_AREA" "T__STORAGEZONE__STORAGEAREA"
                               ON "T__STORAGEZONE"."STORE_AREA_ID" = "T__STORAGEZONE__STORAGEAREA"."ID" AND
                                  ("T__STORAGEZONE__STORAGEAREA"."DELETE_FLAG" != '1' OR "T__STORAGEZONE__STORAGEAREA"."DELETE_FLAG" IS NULL)
                     LEFT JOIN "MBM_MDM_STORAGE_LOCATION" "T__STORAGELOCATION"
                               ON "T"."STORAGE_LOCATION_ID" = "T__STORAGELOCATION"."ID" AND
                                  ("T__STORAGELOCATION"."DELETE_FLAG" != '1' OR "T__STORAGELOCATION"."DELETE_FLAG" IS NULL)
                     LEFT JOIN "MBM_MDM_STORAGE_AREA" "T__STORAGELOCATION__STORAGEAREA"
                               ON "T__STORAGELOCATION"."STORE_AREA_ID" = "T__STORAGELOCATION__STORAGEAREA"."ID" AND
                                  ("T__STORAGELOCATION__STORAGEAREA"."DELETE_FLAG" != '1' OR "T__STORAGELOCATION__STORAGEAREA"."DELETE_FLAG" IS NULL)
                     LEFT JOIN "MBM_APS_PRODUCT_ORDER" "T__DELIVERYPRODUCTORDER"
                               ON "T"."DELIVERY_PRODUCT_ORDER_ID" = "T__DELIVERYPRODUCTORDER"."ID" AND
                                  ("T__DELIVERYPRODUCTORDER"."DELETE_FLAG" != '1' OR "T__DELIVERYPRODUCTORDER"."DELETE_FLAG" IS NULL)
                     LEFT JOIN "MBM_WMS_RECEIPT_LARGE_CATEGORY" "T__RECEIPTLARGECATEGORY"
                               ON "T"."RECEIPT_LARGE_CATEGORY_ID" = "T__RECEIPTLARGECATEGORY"."ID"
            WHERE ("T"."TENANT_ID" IN ('T2130', 'rbac_tenant_root', 'root') OR "T"."TENANT_ID" IS NULL)
              AND "T"."SITE_ID" IN ('2130')
              AND ("T"."DELETE_FLAG" != '1' OR "T"."DELETE_FLAG" IS NULL)
            ORDER BY "T"."UPDATE_DATE" DESC) PageTab
      WHERE ROWNUM <= 31)
WHERE RN > 0
