WITH
/* 保留分类维度；同一物料的不同分类不任意合并。 */
    CLASSIFICATION_DETAIL AS (SELECT DISTINCT CPL.PART_VERSION_ID,
                                              CPL.PART_MASTER_ID,
                                              C1.ID        AS T1_ID,
                                              C1.NAME      AS T1_NAME,
                                              C1.ROOT_NODE AS T1_ROOT_NODE,
                                              C2.ID        AS T2_ID,
                                              C2.NAME      AS T2_NAME,
                                              C2.ROOT_NODE AS T2_ROOT_NODE
                              FROM MBM_MDM_CLASSIFICATION C1
                                       JOIN MBM_MDM_CLASSIFICATION C2
                                            ON C2.PARENT_NODE = C1.ID
                                                AND (C2.DELETE_FLAG <> '1' OR C2.DELETE_FLAG IS NULL)
                                       JOIN MBM_MDM_CLASSIFICATION_PART_LINK CPL
                                            ON CPL.CLASSIFICATION_ID = C2.ID
                                                AND (CPL.DELETE_FLAG <> '1' OR CPL.DELETE_FLAG IS NULL)
                              WHERE C1.NAME IN ('塔机', '升降机')
                                AND (C1.DELETE_FLAG <> '1' OR C1.DELETE_FLAG IS NULL)),
    FILTERED_ORDERS AS (SELECT T.ID,
                               T.BATCH_NO,
                               T.MODELS,
                               T.QTY,
                               T."NUMBER"  AS ORDER_NUMBER,
                               T.COMPLETE_QTY,
                               T.ORDER_STATE,
                               T.LOGISTICS_STATUS,
                               T.SUGGEST_START,
                               T.SUGGEST_END,
                               T.PLAN_START,
                               T.PLAN_END,
                               T.ACTUAL_START,
                               T.ACTUAL_END,
                               T.AUXILIARY_TYPE,
                               T.FACTORY_ID,
                               T.BRANCH_FACTORY_ID,
                               T.WORK_SEGMENT_ID,
                               T.WBS,
                               PM."NUMBER" AS PART_NUMBER,
                               PM.NAME     AS PART_NAME,
                               PV.SPECIFICATION_MODEL,
                               CD.T1_ID,
                               CD.T1_NAME,
                               CD.T1_ROOT_NODE,
                               CD.T2_ID,
                               CD.T2_NAME,
                               CD.T2_ROOT_NODE
                        FROM MBM_APS_PRODUCT_ORDER T
                                 JOIN MBM_MDM_PART_VERSION PV
                                      ON PV.ID = T.PART_VERSION_ID
                                          AND (PV.DELETE_FLAG <> '1' OR PV.DELETE_FLAG IS NULL)
                                 JOIN MBM_MDM_PART_MASTER PM
                                      ON PM.ID = PV.PART_MASTER_ID
                                          AND (PM.DELETE_FLAG <> '1' OR PM.DELETE_FLAG IS NULL)
                                 JOIN CLASSIFICATION_DETAIL CD
                                      ON CD.PART_VERSION_ID = PV.ID
                                          AND CD.PART_MASTER_ID = PM.ID
                        WHERE (T.DELETE_FLAG <> '1' OR T.DELETE_FLAG IS NULL)
                          AND (T.BATCH_NO IS NULL OR TRIM(T.BATCH_NO) NOT LIKE '%LS')
--                           AND (
--                             TRIM('@plan_month') IS NULL
--                                 OR (
--                                 T.PLAN_START >= TO_DATE(TRIM('@plan_month'), 'YYYY-MM')
--                                     AND T.PLAN_START < ADD_MONTHS(
--                                         TO_DATE(TRIM('@plan_month'), 'YYYY-MM'), 1
--                                                        )
--                                 )
--                             )
                        ),
/* 必须在分页前计算计划，避免计划变成当前页行数。 */
    PAGE_ORDERS AS (SELECT F.*,
                           COUNT(F.ORDER_NUMBER) OVER (
               PARTITION BY F.BATCH_NO
           ) AS PLAN_COUNT
                    FROM FILTERED_ORDERS F
                    ORDER BY F.BATCH_NO, F.ORDER_NUMBER, F.ID, F.T1_ID, F.T2_ID
--                     OFFSET @pageOffset ROWS FETCH NEXT @pageSize ROWS ONLY
                    ),
    PAGE_VALUES AS (SELECT P.*,
                           SUBSTR(P.BATCH_NO, INSTR(P.BATCH_NO, '/', -1) + 1)
                               AS BATCH_SUFFIX
                    FROM PAGE_ORDERS P),
/*
 * 只为当前页计算外协和接收；COUNT(*) 无匹配时返回 0。
 * 接收保留“批次+物料、STATE=5、记录数”的原口径，
 * 同批次其他月份的订单仍参与接收统计。
 */
    PAGE_CALC AS (SELECT P.*,
                         CASE
                             WHEN REGEXP_LIKE(P.BATCH_SUFFIX, '^[0-9]+$')
                                 THEN P.BATCH_SUFFIX
                             END                                                       AS CUMULATIVE_TEXT,
                         (SELECT COUNT(*)
                          FROM MBM_APS_PRODUCT_ORDER_BOM BOM
                                   JOIN MBM_MDM_PART_VERSION PV_BOM
                                        ON PV_BOM.ID = BOM.PART_VERSION_ID
                                            AND PV_BOM.PROCUREMENT_TYPE = 'F'
                                            AND (PV_BOM.DELETE_FLAG <> '1' OR PV_BOM.DELETE_FLAG IS NULL)
                          WHERE BOM.PRODUCT_ORDER_ID = P.ID
                            AND (BOM.DELETE_FLAG <> '1' OR BOM.DELETE_FLAG IS NULL))   AS F_PROCUREMENT_COUNT,
                         (SELECT COUNT(*)
                          FROM MBM_APS_PRODUCT_ORDER PO_D
                                   JOIN MBM_WMS_ASN_COMPONENT_DELIVERY_ORDER D
                                        ON D.PRODUCT_ORDER_ID = PO_D.ID
                                            AND D.STATE = '5'
                                            AND (D.DELETE_FLAG <> '1' OR D.DELETE_FLAG IS NULL)
                                   JOIN MBM_MDM_PART_VERSION PV_D
                                        ON PV_D.ID = D.PART_VERSION_ID
                                            AND (PV_D.DELETE_FLAG <> '1' OR PV_D.DELETE_FLAG IS NULL)
                                   JOIN MBM_MDM_PART_MASTER PM_D
                                        ON PM_D.ID = PV_D.PART_MASTER_ID
                                            AND PM_D."NUMBER" = P.PART_NUMBER
                                            AND (PM_D.DELETE_FLAG <> '1' OR PM_D.DELETE_FLAG IS NULL)
                          WHERE PO_D.BATCH_NO = P.BATCH_NO
                            AND (PO_D.DELETE_FLAG <> '1' OR PO_D.DELETE_FLAG IS NULL)) AS FINISHED_RECEIVE_COUNT
                  FROM PAGE_VALUES P)
SELECT P.BATCH_NO                   AS 批次号,
       P.MODELS                     AS 机型型号,
       P.QTY                        AS 台套,
       P.CUMULATIVE_TEXT            AS 累计,
       P.F_PROCUREMENT_COUNT        AS 外协,
       COALESCE(TO_NUMBER(P.CUMULATIVE_TEXT), 0)
           + P.F_PROCUREMENT_COUNT  AS 产出,
       P.FINISHED_RECEIVE_COUNT     AS 成品接收,
       P.T1_ID                      AS 一级分类ID,
       P.T1_NAME                    AS 一级分类名称,
       P.T1_ROOT_NODE               AS 一级分类ROOT_NODE,
       P.T2_ID                      AS 二级分类ID,
       P.T2_NAME                    AS 二级分类名称,
       P.T2_ROOT_NODE               AS 二级分类ROOT_NODE,
       P.ORDER_NUMBER               AS "订单号",
       P.PLAN_COUNT                 AS "计划",
       P.T2_ROOT_NODE               AS 根,
       BF_WAM.NAME                  AS 分厂,
       WS_WAM.NAME                  AS 产线,
       P.PART_NUMBER                AS 物料号,
       P.PART_NAME                  AS 物料名称,
       P.COMPLETE_QTY               AS 完工数,
       P.ORDER_STATE                AS 订单状态,
       P.LOGISTICS_STATUS           AS 配盘状态,
       P.SUGGEST_START              AS SCP计划开始,
       P.SUGGEST_END                AS SCP计划结束,
       P.PLAN_START                 AS MES计划开始,
       P.PLAN_END                   AS MES计划结束,
       P.ACTUAL_START               AS 实际开始,
       P.ACTUAL_END                 AS 实际结束,
       P.AUXILIARY_TYPE             AS AUXILIARYTYPE,
       FAC_WAM.SOURCE_SYSTEM_NUMBER AS 工厂代码,
       BF_WAM.SOURCE_SYSTEM_NUMBER  AS 分厂编码,
       WS_WAM.SOURCE_SYSTEM_NUMBER  AS 产线编码,
       FAC_WAM.NAME                 AS 工厂名称,
       P.WBS                        AS WBS,
       P.SPECIFICATION_MODEL        AS 机型
FROM PAGE_CALC P
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION BF
                   ON BF.ID = P.BRANCH_FACTORY_ID
                       AND (BF.DELETE_FLAG <> '1' OR BF.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER BF_WAM
                   ON BF_WAM.ID = BF.WORK_AREA_MASTER_ID
                       AND (BF_WAM.DELETE_FLAG <> '1' OR BF_WAM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION WS
                   ON WS.ID = P.WORK_SEGMENT_ID
                       AND (WS.DELETE_FLAG <> '1' OR WS.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER WS_WAM
                   ON WS_WAM.ID = WS.WORK_AREA_MASTER_ID
                       AND (WS_WAM.DELETE_FLAG <> '1' OR WS_WAM.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION FAC
                   ON FAC.ID = P.FACTORY_ID
                       AND (FAC.DELETE_FLAG <> '1' OR FAC.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER FAC_WAM
                   ON FAC_WAM.ID = FAC.WORK_AREA_MASTER_ID
                       AND (FAC_WAM.DELETE_FLAG <> '1' OR FAC_WAM.DELETE_FLAG IS NULL)
ORDER BY P.BATCH_NO, P.ORDER_NUMBER, P.ID, P.T1_ID, P.T2_ID;

