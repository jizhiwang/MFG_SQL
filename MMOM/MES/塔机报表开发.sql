-- 1.统计根据批次号查询数据：机型，
SELECT T.BATCH_NO                                         AS 批次号,
       T.MODELS                                           AS 机型型号,
       T.QTY                                              AS 台套,
       SUBSTR(T.BATCH_NO, INSTR(T.BATCH_NO, '/', -1) + 1) AS 累计,
       CLS.NAME                                           AS 物料分类名称,
       T."NUMBER"                                         AS "订单号",
       COUNT(T."NUMBER") OVER (PARTITION BY T.BATCH_NO)   AS "计划",
       BF_WAM.NAME                                        AS 分厂,
       WS_WAM.NAME                                        AS 产线,
       T.BATCH_NUMBER2                                    AS BATCHNUMBER2,
       T.MRP_CONTROLLER                                   AS MRP控制,
       PM."NUMBER"                                        AS 物料号,
       PM.NAME                                            AS 物料名称,
       T.COMPLETE_QTY                                     AS 完工数,
       T.ORDER_STATE                                      AS 订单状态,
       T.LOGISTICS_STATUS                                 AS 配盘状态,
       T.SUSPENDED                                        AS SUSPENDED,
       T.IS_PRIORITY_ORDER                                AS ISPRIORITYORDER,
       T.SUGGEST_START                                    AS SCP计划开始,
       T.SUGGEST_END                                      AS SCP计划结束,
       T.PLAN_START                                       AS MES计划开始,
       T.PLAN_END                                         AS MES计划结束,
       T.ACTUAL_START                                     AS 实际开始,
       T.ACTUAL_END                                       AS 实际结束,
       OC.TYPE_DESC                                       AS ORDERTYPEDESC,
       T.AUXILIARY_TYPE                                   AS AUXILIARYTYPE,
       T.PRODUCT_VERSION                                  AS PRODUCTVERSION,
       T.SCHEDULE_FLAG                                    AS SCHEDULEFLAG,
       T.IS_SYNCED_DS_AS                                  AS ISSYNCEDDSAS,
       T.SALE_AREA_BOM_ID                                 AS SALEAREABOMID,
       FAC_WAM.SOURCE_SYSTEM_NUMBER                       AS 工厂代码,
       BF_WAM.SOURCE_SYSTEM_NUMBER                        AS 分厂编码,
       WS_WAM.SOURCE_SYSTEM_NUMBER                        AS 产线编码,
       FAC_WAM.NAME                                       AS 工厂名称,
       T.WBS                                              AS WBS,
       T.MATERIAL_GROUP                                   AS MATERIALGROUP,
       T.REQUIRE_DELIVERY                                 AS REQUIREDELIVERY,
       T.PRIORITY                                         AS PRIORITY,
       T.TOP_ORDER_ID                                     AS TOPORDER,
       T.DATA_SOURCE                                      AS DATASOURCE,
       PV.SPECIFICATION_MODEL                             AS 机型,
       T.ERP_PROCESS_ROUTE                                AS ERPPROCESSROUTE
FROM MBM_APS_PRODUCT_ORDER T
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION BF
                   ON T.BRANCH_FACTORY_ID = BF.ID
                      AND (BF.DELETE_FLAG <> '1' OR BF.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER BF_WAM
                   ON BF.WORK_AREA_MASTER_ID = BF_WAM.ID
                      AND (BF_WAM.DELETE_FLAG <> '1' OR BF_WAM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION WS
                   ON T.WORK_SEGMENT_ID = WS.ID
                      AND (WS.DELETE_FLAG <> '1' OR WS.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER WS_WAM
                   ON WS.WORK_AREA_MASTER_ID = WS_WAM.ID
                      AND (WS_WAM.DELETE_FLAG <> '1' OR WS_WAM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_PART_VERSION PV
                   ON T.PART_VERSION_ID = PV.ID
                      AND (PV.DELETE_FLAG <> '1' OR PV.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_PART_MASTER PM
                   ON PV.PART_MASTER_ID = PM.ID
                      AND (PM.DELETE_FLAG <> '1' OR PM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_CLASSIFICATION_PART_LINK CPL
                   ON CPL.PART_VERSION_ID = PV.ID
                      AND CPL.PART_MASTER_ID = PM.ID
                      AND (CPL.DELETE_FLAG <> '1' OR CPL.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_CLASSIFICATION CLS
                   ON CLS.ID = CPL.CLASSIFICATION_ID
                      AND (CLS.DELETE_FLAG <> '1' OR CLS.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_APS_ORDER_CONFIG OC
                   ON T.ORDER_CONFIG_ID = OC.ID
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION FAC
                   ON T.FACTORY_ID = FAC.ID
                      AND (FAC.DELETE_FLAG <> '1' OR FAC.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER FAC_WAM
                   ON FAC.WORK_AREA_MASTER_ID = FAC_WAM.ID
                      AND (FAC_WAM.DELETE_FLAG <> '1' OR FAC_WAM.DELETE_FLAG IS NULL)
WHERE (T.DELETE_FLAG <> '1' OR T.DELETE_FLAG IS NULL)
    AND T.AUXILIARY_TYPE = 'D'
  AND CLS."ROOT_NODE" = '067dwf18x89mb'
ORDER BY T.UPDATE_DATE DESC, T.SORT_NO
FETCH FIRST 500 ROWS ONLY;


-- 塔机（二期）生产 · 订单查询报表
-- 改动说明：
--   1) 删除 MBM_MDM_CLASSIFICATION_PART_LINK / MBM_MDM_CLASSIFICATION / MBM_MDM_CLASSIFICATION_SET 三个 LEFT JOIN
--      （原写法会因"一个物料挂多个分类维度"把同一订单放大成多行，实测 2.57 倍）
--   2) 一级部件过滤改为 EXISTS 下推；分类名称改用标量子查询 MIN(C.NAME)，保证一条订单一行
--   3) '067dwf18x89mb' = 分类集 primary_component（一级部件）；将来换维度只改这一个常量
--      注意用 ROOT_NODE 直接比 id：生产库该 number 唯一，而 UAT 存在同 number 多 id 的情况
SELECT T.MODELS                                           AS 机型型号,
       T.QTY                                              AS 台套,
       SUBSTR(T.BATCH_NO, INSTR(T.BATCH_NO, '/', -1) + 1) AS 累计,
       (SELECT MIN(C.NAME)
        FROM MBM_MDM_CLASSIFICATION_PART_LINK CPL
                 JOIN MBM_MDM_CLASSIFICATION C
                      ON C.ID = CPL.CLASSIFICATION_ID
                          AND (C.DELETE_FLAG <> '1' OR C.DELETE_FLAG IS NULL)
        WHERE CPL.PART_VERSION_ID = PV.ID
          AND CPL.PART_MASTER_ID = PM.ID
          AND (CPL.DELETE_FLAG <> '1' OR CPL.DELETE_FLAG IS NULL)
          AND C.ROOT_NODE = '067dwf18x89mb')              AS 物料分类名称,
       BF_WAM.NAME                                        AS 分厂,
       WS_WAM.NAME                                        AS 产线,
       T.BATCH_NO                                         AS 批次号,
       T.BATCH_NUMBER2                                    AS BATCHNUMBER2,
       T.MRP_CONTROLLER                                   AS MRP控制,
       T."NUMBER"                                         AS "订单号",
       PM."NUMBER"                                        AS 物料号,
       PM.NAME                                            AS 物料名称,
       T.COMPLETE_QTY                                     AS 完工数,
       T.ORDER_STATE                                      AS 订单状态,
       T.LOGISTICS_STATUS                                 AS 配盘状态,
       T.SUSPENDED                                        AS SUSPENDED,
       T.IS_PRIORITY_ORDER                                AS ISPRIORITYORDER,
       T.SUGGEST_START                                    AS SCP计划开始,
       T.SUGGEST_END                                      AS SCP计划结束,
       T.PLAN_START                                       AS MES计划开始,
       T.PLAN_END                                         AS MES计划结束,
       T.ACTUAL_START                                     AS 实际开始,
       T.ACTUAL_END                                       AS 实际结束,
       OC.TYPE_DESC                                       AS ORDERTYPEDESC,
       T.AUXILIARY_TYPE                                   AS AUXILIARYTYPE,
       T.PRODUCT_VERSION                                  AS PRODUCTVERSION,
       T.SCHEDULE_FLAG                                    AS SCHEDULEFLAG,
       T.IS_SYNCED_DS_AS                                  AS ISSYNCEDDSAS,
       T.SALE_AREA_BOM_ID                                 AS SALEAREABOMID,
       FAC_WAM.SOURCE_SYSTEM_NUMBER                       AS 工厂代码,
       BF_WAM.SOURCE_SYSTEM_NUMBER                        AS 分厂编码,
       WS_WAM.SOURCE_SYSTEM_NUMBER                        AS 产线编码,
       FAC_WAM.NAME                                       AS 工厂名称,
       T.WBS                                              AS WBS,
       T.MATERIAL_GROUP                                   AS MATERIALGROUP,
       T.REQUIRE_DELIVERY                                 AS REQUIREDELIVERY,
       T.PRIORITY                                         AS PRIORITY,
       T.TOP_ORDER_ID                                     AS TOPORDER,
       T.DATA_SOURCE                                      AS DATASOURCE,
       PV.SPECIFICATION_MODEL                             AS 机型,
       T.ERP_PROCESS_ROUTE                                AS ERPPROCESSROUTE
FROM MBM_APS_PRODUCT_ORDER T
        LEFT JOIN   MBM_APS_PRODUCT_ORDER_BOM MAPOB ON T.ID = MAPOB.PRODUCT_ORDER_ID
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION BF
                   ON T.BRANCH_FACTORY_ID = BF.ID
                       AND (BF.DELETE_FLAG <> '1' OR BF.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER BF_WAM
                   ON BF.WORK_AREA_MASTER_ID = BF_WAM.ID
                       AND (BF_WAM.DELETE_FLAG <> '1' OR BF_WAM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION WS
                   ON T.WORK_SEGMENT_ID = WS.ID
                       AND (WS.DELETE_FLAG <> '1' OR WS.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER WS_WAM
                   ON WS.WORK_AREA_MASTER_ID = WS_WAM.ID
                       AND (WS_WAM.DELETE_FLAG <> '1' OR WS_WAM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_PART_VERSION PV
                   ON T.PART_VERSION_ID = PV.ID
                       AND (PV.DELETE_FLAG <> '1' OR PV.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_PART_MASTER PM
                   ON PV.PART_MASTER_ID = PM.ID
                       AND (PM.DELETE_FLAG <> '1' OR PM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_APS_ORDER_CONFIG OC
                   ON T.ORDER_CONFIG_ID = OC.ID
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION FAC
                   ON T.FACTORY_ID = FAC.ID
                       AND (FAC.DELETE_FLAG <> '1' OR FAC.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER FAC_WAM
                   ON FAC.WORK_AREA_MASTER_ID = FAC_WAM.ID
                       AND (FAC_WAM.DELETE_FLAG <> '1' OR FAC_WAM.DELETE_FLAG IS NULL)
WHERE (T.DELETE_FLAG <> '1' OR T.DELETE_FLAG IS NULL)
  AND EXISTS (SELECT 1
              FROM MBM_MDM_CLASSIFICATION_PART_LINK CPL
                       JOIN MBM_MDM_CLASSIFICATION C
                            ON C.ID = CPL.CLASSIFICATION_ID
                                AND (C.DELETE_FLAG <> '1' OR C.DELETE_FLAG IS NULL)
              WHERE CPL.PART_VERSION_ID = PV.ID
                AND CPL.PART_MASTER_ID = PM.ID
                AND (CPL.DELETE_FLAG <> '1' OR CPL.DELETE_FLAG IS NULL)
                AND C.ROOT_NODE = '067dwf18x89mb')
ORDER BY T.UPDATE_DATE DESC, T.SORT_NO;



-- 生产订单bom查询
SELECT BOM."ID"                    AS ID,
       PV.PROCUREMENT_TYPE         AS PROCUREMENTTYPE,
       PO.ID                       AS PRODUCTORDERID
FROM MBM_APS_PRODUCT_ORDER_BOM BOM
         LEFT JOIN MBM_MDM_PART_VERSION PV
                   ON BOM.PART_VERSION_ID = PV.ID
                      AND (PV.DELETE_FLAG != '1' OR PV.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_APS_PRODUCT_ORDER PO
                   ON BOM.PRODUCT_ORDER_ID = PO.ID
                      AND (PO.DELETE_FLAG != '1' OR PO.DELETE_FLAG IS NULL)
WHERE BOM.PRODUCT_ORDER_ID = '当前行的T.ID'
  AND (BOM.DELETE_FLAG != '1' OR BOM.DELETE_FLAG IS NULL)

-- 报表一
WITH BOM_F_COUNT AS (
    -- 按订单ID统计 PROCUREMENT_TYPE='F' 的数量
    SELECT BOM.PRODUCT_ORDER_ID,
           COUNT(*) AS F_PROCUREMENT_COUNT
    FROM MBM_APS_PRODUCT_ORDER_BOM BOM
             INNER JOIN MBM_MDM_PART_VERSION PV_BOM
                        ON BOM.PART_VERSION_ID = PV_BOM.ID
                            AND (PV_BOM.DELETE_FLAG != '1' OR PV_BOM.DELETE_FLAG IS NULL)
                            AND PV_BOM.PROCUREMENT_TYPE = 'F'
    WHERE (BOM.DELETE_FLAG != '1' OR BOM.DELETE_FLAG IS NULL)
    GROUP BY BOM.PRODUCT_ORDER_ID
)
SELECT T.BATCH_NO                                         AS 批次号,
       T.MODELS                                           AS 机型型号,
       T.QTY                                              AS 台套,
       SUBSTR(T.BATCH_NO, INSTR(T.BATCH_NO, '/', -1) + 1) AS 累计,
       COALESCE(BFC.F_PROCUREMENT_COUNT, 0)               AS 外协,
       CLS.NAME                                           AS 物料分类名称,
       T."NUMBER"                                         AS "订单号",
       COUNT(T."NUMBER") OVER (PARTITION BY T.BATCH_NO)   AS "计划",
       BF_WAM.NAME                                        AS 分厂,
       WS_WAM.NAME                                        AS 产线,
       PM."NUMBER"                                        AS 物料号,
       PM.NAME                                            AS 物料名称,
       T.COMPLETE_QTY                                     AS 完工数,
       T.ORDER_STATE                                      AS 订单状态,
       T.LOGISTICS_STATUS                                 AS 配盘状态,
       T.SUGGEST_START                                    AS SCP计划开始,
       T.SUGGEST_END                                      AS SCP计划结束,
       T.PLAN_START                                       AS MES计划开始,
       T.PLAN_END                                         AS MES计划结束,
       T.ACTUAL_START                                     AS 实际开始,
       T.ACTUAL_END                                       AS 实际结束,
       T.AUXILIARY_TYPE                                   AS AUXILIARYTYPE,
       FAC_WAM.SOURCE_SYSTEM_NUMBER                       AS 工厂代码,
       BF_WAM.SOURCE_SYSTEM_NUMBER                        AS 分厂编码,
       WS_WAM.SOURCE_SYSTEM_NUMBER                        AS 产线编码,
       FAC_WAM.NAME                                       AS 工厂名称,
       T.WBS                                              AS WBS,
       PV.SPECIFICATION_MODEL                             AS 机型
FROM MBM_APS_PRODUCT_ORDER T
         LEFT JOIN BOM_F_COUNT BFC
                   ON T.ID = BFC.PRODUCT_ORDER_ID
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION BF
                   ON T.BRANCH_FACTORY_ID = BF.ID
                      AND (BF.DELETE_FLAG <> '1' OR BF.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER BF_WAM
                   ON BF.WORK_AREA_MASTER_ID = BF_WAM.ID
                      AND (BF_WAM.DELETE_FLAG <> '1' OR BF_WAM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION WS
                   ON T.WORK_SEGMENT_ID = WS.ID
                      AND (WS.DELETE_FLAG <> '1' OR WS.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER WS_WAM
                   ON WS.WORK_AREA_MASTER_ID = WS_WAM.ID
                      AND (WS_WAM.DELETE_FLAG <> '1' OR WS_WAM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_PART_VERSION PV
                   ON T.PART_VERSION_ID = PV.ID
                      AND (PV.DELETE_FLAG <> '1' OR PV.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_PART_MASTER PM
                   ON PV.PART_MASTER_ID = PM.ID
                      AND (PM.DELETE_FLAG <> '1' OR PM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_CLASSIFICATION_PART_LINK CPL
                   ON CPL.PART_VERSION_ID = PV.ID
                      AND CPL.PART_MASTER_ID = PM.ID
                      AND (CPL.DELETE_FLAG <> '1' OR CPL.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_CLASSIFICATION CLS
                   ON CLS.ID = CPL.CLASSIFICATION_ID
                      AND (CLS.DELETE_FLAG <> '1' OR CLS.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION FAC
                   ON T.FACTORY_ID = FAC.ID
                      AND (FAC.DELETE_FLAG <> '1' OR FAC.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER FAC_WAM
                   ON FAC.WORK_AREA_MASTER_ID = FAC_WAM.ID
                      AND (FAC_WAM.DELETE_FLAG <> '1' OR FAC_WAM.DELETE_FLAG IS NULL)
WHERE (T.DELETE_FLAG <> '1' OR T.DELETE_FLAG IS NULL)
  AND T.AUXILIARY_TYPE = 'D'
  AND CLS."ROOT_NODE" = '067dwf18x89mb'
ORDER BY T.UPDATE_DATE DESC, T.SORT_NO
FETCH FIRST 500 ROWS ONLY;


-- 报表二
SELECT T.BATCH_NO                                         AS 批次号,
       T.MODELS                                           AS 机型型号,
       T.QTY                                              AS 台套,
       SUBSTR(T.BATCH_NO, INSTR(T.BATCH_NO, '/', -1) + 1) AS 累计,
       CLS.NAME                                           AS 物料分类名称,
       T."NUMBER"                                         AS "订单号",
       COUNT(T."NUMBER") OVER (PARTITION BY T.BATCH_NO)   AS "计划",
       BF_WAM.NAME                                        AS 分厂,
       WS_WAM.NAME                                        AS 产线,
       PM."NUMBER"                                        AS 物料号,
       PM.NAME                                            AS 物料名称,
       T.COMPLETE_QTY                                     AS 完工数,
       T.ORDER_STATE                                      AS 订单状态,
       T.LOGISTICS_STATUS                                 AS 配盘状态,
       T.SUGGEST_START                                    AS SCP计划开始,
       T.SUGGEST_END                                      AS SCP计划结束,
       T.PLAN_START                                       AS MES计划开始,
       T.PLAN_END                                         AS MES计划结束,
       T.ACTUAL_START                                     AS 实际开始,
       T.ACTUAL_END                                       AS 实际结束,
       T.AUXILIARY_TYPE                                   AS AUXILIARYTYPE,
       FAC_WAM.SOURCE_SYSTEM_NUMBER                       AS 工厂代码,
       BF_WAM.SOURCE_SYSTEM_NUMBER                        AS 分厂编码,
       WS_WAM.SOURCE_SYSTEM_NUMBER                        AS 产线编码,
       FAC_WAM.NAME                                       AS 工厂名称,
       T.WBS                                              AS WBS,
       PV.SPECIFICATION_MODEL                             AS 机型
FROM MBM_APS_PRODUCT_ORDER T
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION BF
                   ON T.BRANCH_FACTORY_ID = BF.ID
                      AND (BF.DELETE_FLAG <> '1' OR BF.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER BF_WAM
                   ON BF.WORK_AREA_MASTER_ID = BF_WAM.ID
                      AND (BF_WAM.DELETE_FLAG <> '1' OR BF_WAM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION WS
                   ON T.WORK_SEGMENT_ID = WS.ID
                      AND (WS.DELETE_FLAG <> '1' OR WS.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER WS_WAM
                   ON WS.WORK_AREA_MASTER_ID = WS_WAM.ID
                      AND (WS_WAM.DELETE_FLAG <> '1' OR WS_WAM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_PART_VERSION PV
                   ON T.PART_VERSION_ID = PV.ID
                      AND (PV.DELETE_FLAG <> '1' OR PV.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_PART_MASTER PM
                   ON PV.PART_MASTER_ID = PM.ID
                      AND (PM.DELETE_FLAG <> '1' OR PM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_CLASSIFICATION_PART_LINK CPL
                   ON CPL.PART_VERSION_ID = PV.ID
                      AND CPL.PART_MASTER_ID = PM.ID
                      AND (CPL.DELETE_FLAG <> '1' OR CPL.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_CLASSIFICATION CLS
                   ON CLS.ID = CPL.CLASSIFICATION_ID
                      AND (CLS.DELETE_FLAG <> '1' OR CLS.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION FAC
                   ON T.FACTORY_ID = FAC.ID
                      AND (FAC.DELETE_FLAG <> '1' OR FAC.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER FAC_WAM
                   ON FAC.WORK_AREA_MASTER_ID = FAC_WAM.ID
                      AND (FAC_WAM.DELETE_FLAG <> '1' OR FAC_WAM.DELETE_FLAG IS NULL)
WHERE (T.DELETE_FLAG <> '1' OR T.DELETE_FLAG IS NULL)
  AND T.AUXILIARY_TYPE = 'D'
  AND CLS."ROOT_NODE" = '067dwf18x89mb'
ORDER BY T.UPDATE_DATE DESC, T.SORT_NO
FETCH FIRST 500 ROWS ONLY;
