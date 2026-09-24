-- 结构外协进度报表
WITH BOM_F_COUNT AS (SELECT BOM.PRODUCT_ORDER_ID,
                            COUNT(*) AS F_PROCUREMENT_COUNT
                     FROM MBM_APS_PRODUCT_ORDER_BOM BOM
                              INNER JOIN MBM_MDM_PART_VERSION PV_BOM
                                         ON BOM.PART_VERSION_ID = PV_BOM.ID
                                             AND (PV_BOM.DELETE_FLAG <> '1' OR PV_BOM.DELETE_FLAG IS NULL)
                                             AND PV_BOM.PROCUREMENT_TYPE = 'F'
                     WHERE (BOM.DELETE_FLAG <> '1' OR BOM.DELETE_FLAG IS NULL)
                     GROUP BY BOM.PRODUCT_ORDER_ID),
     CLASSIFICATION_DETAIL AS (SELECT DISTINCT CPL.PART_VERSION_ID,
                                               CPL.PART_MASTER_ID,
                                               T1.ID        AS T1_ID,
                                               T1.NAME      AS T1_NAME,
                                               T1.ROOT_NODE AS T1_ROOT_NODE,
                                               T2.ID        AS T2_ID,
                                               T2.NAME      AS T2_NAME,
                                               T2.ROOT_NODE AS T2_ROOT_NODE
                               FROM MBM_MDM_CLASSIFICATION_PART_LINK CPL
                                        INNER JOIN MBM_MDM_CLASSIFICATION T2
                                                   ON T2.ID = CPL.CLASSIFICATION_ID
                                                       AND (T2.DELETE_FLAG <> '1' OR T2.DELETE_FLAG IS NULL)
                                        INNER JOIN MBM_MDM_CLASSIFICATION T1
                                                   ON T1.ID = T2.PARENT_NODE
                                                       AND (T1.DELETE_FLAG <> '1' OR T1.DELETE_FLAG IS NULL)
                               WHERE (CPL.DELETE_FLAG <> '1' OR CPL.DELETE_FLAG IS NULL)),
     ONLINE_COUNT AS (SELECT PO.BATCH_NO,
                             PM."NUMBER" AS PART_NUMBER,
                             COUNT(*)    AS ONLINE_COUNT
                      FROM MBM_MES_PROCESS_TECH_ORDER_ID T

                               LEFT JOIN MBM_APS_PROCESS_TECH_ORDER PTO
                                         ON T.MES_PROCESS_TECH_ORDER_ID = PTO.ID
                                             AND (PTO.DELETE_FLAG <> '1' OR PTO.DELETE_FLAG IS NULL)

                               LEFT JOIN MBM_APS_PRODUCT_ORDER PO
                                         ON PTO.PRODUCT_ORDER_ID = PO.ID
                                             AND (PO.DELETE_FLAG <> '1' OR PO.DELETE_FLAG IS NULL)

                               LEFT JOIN MBM_MDM_PART_VERSION PV
                                         ON T.PART_VERSION_ID = PV.ID
                                             AND (PV.DELETE_FLAG <> '1' OR PV.DELETE_FLAG IS NULL)

                               LEFT JOIN MBM_MDM_WORK_AREA_VERSION WAV_BF
                                         ON PTO.BRANCH_FACTORY_ID = WAV_BF.ID
                                             AND (WAV_BF.DELETE_FLAG <> '1' OR WAV_BF.DELETE_FLAG IS NULL)

                               LEFT JOIN MBM_MDM_WORK_AREA_MASTER WAM_BF
                                         ON WAV_BF.WORK_AREA_MASTER_ID = WAM_BF.ID
                                             AND (WAM_BF.DELETE_FLAG <> '1' OR WAM_BF.DELETE_FLAG IS NULL)

                               LEFT JOIN MBM_MDM_PART_MASTER PM
                                         ON PV.PART_MASTER_ID = PM.ID
                                             AND (PM.DELETE_FLAG <> '1' OR PM.DELETE_FLAG IS NULL)

                      WHERE WAM_BF.NAME = '涂装分厂'
                        AND PTO.WHETHER_REPORTING_POINT_WHEN_GENERATE = '1'
                        AND T.PRODUCTION_STATUS = '20'
                        AND PV.PRODUCTION_MANAGEMENT_MODE = '10'

                        AND (PO.AUXILIARY_TYPE <> 'C' OR PO.AUXILIARY_TYPE IS NULL)

                        AND (
                          PO.KD_ORDER <> 'X'
                              OR PO.KD_ORDER IS NULL
                              OR (PO.AUXILIARY_TYPE <> 'A' OR PO.AUXILIARY_TYPE IS NULL)
                          )

                        AND (T.DELETE_FLAG <> '1' OR T.DELETE_FLAG IS NULL)

                      GROUP BY PO.BATCH_NO,
                               PM."NUMBER")

SELECT T.BATCH_NO                               AS 批次号,
       T.MODELS                                 AS 机型型号,
       T.QTY                                    AS 台套,

       SUBSTR(
               T.BATCH_NO,
               INSTR(T.BATCH_NO, '/', -1) + 1
       )                                        AS 累计,

       COALESCE(
               BFC.F_PROCUREMENT_COUNT,
               0
       )                                        AS 外协,

       TO_NUMBER(
               SUBSTR(
                       T.BATCH_NO,
                       INSTR(T.BATCH_NO, '/', -1) + 1
               )
       ) + COALESCE(BFC.F_PROCUREMENT_COUNT, 0) AS 产出,


       COALESCE(
               OC.ONLINE_COUNT,
               0
       )                                        AS 上线,

    /*
     * 一级分类
     */
       CD.T1_ID                                 AS 一级分类ID,
       CD.T1_NAME                               AS 一级分类名称,
       CD.T1_ROOT_NODE                          AS 一级分类ROOT_NODE,

    /*
     * 二级分类
     */
       CD.T2_ID                                 AS 二级分类ID,
       CD.T2_NAME                               AS 二级分类名称,
       CD.T2_ROOT_NODE                          AS 二级分类ROOT_NODE,

       T."NUMBER"                               AS "订单号",

       COUNT(T."NUMBER") OVER (
           PARTITION BY T.BATCH_NO
           )                                    AS "计划",

    /*
     * 根
     */
       CD.T2_ROOT_NODE                          AS 根,

       BF_WAM.NAME                              AS 分厂,
       WS_WAM.NAME                              AS 产线,

       PM."NUMBER"                              AS 物料号,
       PM.NAME                                  AS 物料名称,

       T.COMPLETE_QTY                           AS 完工数,
       T.ORDER_STATE                            AS 订单状态,
       T.LOGISTICS_STATUS                       AS 配盘状态,

       T.SUGGEST_START                          AS SCP计划开始,
       T.SUGGEST_END                            AS SCP计划结束,

       T.PLAN_START                             AS MES计划开始,
       T.PLAN_END                               AS MES计划结束,

       T.ACTUAL_START                           AS 实际开始,
       T.ACTUAL_END                             AS 实际结束,

       T.AUXILIARY_TYPE                         AS AUXILIARYTYPE,

       FAC_WAM.SOURCE_SYSTEM_NUMBER             AS 工厂代码,
       BF_WAM.SOURCE_SYSTEM_NUMBER              AS 分厂编码,
       WS_WAM.SOURCE_SYSTEM_NUMBER              AS 产线编码,

       FAC_WAM.NAME                             AS 工厂名称,

       T.WBS                                    AS WBS,

       PV.SPECIFICATION_MODEL                   AS 机型

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

         LEFT JOIN CLASSIFICATION_DETAIL CD
                   ON CD.PART_VERSION_ID = PV.ID
                       AND CD.PART_MASTER_ID = PM.ID
         LEFT JOIN ONLINE_COUNT OC
                   ON OC.BATCH_NO = T.BATCH_NO
                       AND OC.PART_NUMBER = PM."NUMBER"

         LEFT JOIN MBM_MDM_WORK_AREA_VERSION FAC
                   ON T.FACTORY_ID = FAC.ID
                       AND (FAC.DELETE_FLAG <> '1' OR FAC.DELETE_FLAG IS NULL)

         LEFT JOIN MBM_MDM_WORK_AREA_MASTER FAC_WAM
                   ON FAC.WORK_AREA_MASTER_ID = FAC_WAM.ID
                       AND (FAC_WAM.DELETE_FLAG <> '1' OR FAC_WAM.DELETE_FLAG IS NULL)

WHERE (T.DELETE_FLAG <> '1' OR T.DELETE_FLAG IS NULL)
  AND CD.T1_NAME IN ('塔机', '升降机');


-- 钢结构配套报表
WITH BOM_F_COUNT AS (SELECT BOM.PRODUCT_ORDER_ID,
                            COUNT(*) AS F_PROCUREMENT_COUNT
                     FROM MBM_APS_PRODUCT_ORDER_BOM BOM
                              INNER JOIN MBM_MDM_PART_VERSION PV_BOM
                                         ON BOM.PART_VERSION_ID = PV_BOM.ID
                                             AND (PV_BOM.DELETE_FLAG <> '1' OR PV_BOM.DELETE_FLAG IS NULL)
                                             AND PV_BOM.PROCUREMENT_TYPE = 'F'
                     WHERE (BOM.DELETE_FLAG <> '1' OR BOM.DELETE_FLAG IS NULL)
                     GROUP BY BOM.PRODUCT_ORDER_ID),

     CLASSIFICATION_DETAIL AS (SELECT DISTINCT CPL.PART_VERSION_ID,
                                               CPL.PART_MASTER_ID,

                                               T1.ID        AS T1_ID,
                                               T1.NAME      AS T1_NAME,
                                               T1.ROOT_NODE AS T1_ROOT_NODE,

                                               T2.ID        AS T2_ID,
                                               T2.NAME      AS T2_NAME,
                                               T2.ROOT_NODE AS T2_ROOT_NODE

                               FROM MBM_MDM_CLASSIFICATION_PART_LINK CPL

                                        INNER JOIN MBM_MDM_CLASSIFICATION T2
                                                   ON T2.ID = CPL.CLASSIFICATION_ID
                                                       AND (T2.DELETE_FLAG <> '1' OR T2.DELETE_FLAG IS NULL)

                                        INNER JOIN MBM_MDM_CLASSIFICATION T1
                                                   ON T1.ID = T2.PARENT_NODE
                                                       AND (T1.DELETE_FLAG <> '1' OR T1.DELETE_FLAG IS NULL)

                               WHERE (CPL.DELETE_FLAG <> '1' OR CPL.DELETE_FLAG IS NULL)),

/* 成品接收 */
     FINISHED_RECEIVE_COUNT AS (SELECT PO_D.BATCH_NO,
                                       PM_D."NUMBER" AS PART_NUMBER,
                                       COUNT(*)      AS FINISHED_RECEIVE_COUNT

                                FROM MBM_WMS_ASN_COMPONENT_DELIVERY_ORDER D

                                         LEFT JOIN MBM_MDM_PART_VERSION PV_D
                                                   ON D.PART_VERSION_ID = PV_D.ID
                                                       AND (
                                                          PV_D.DELETE_FLAG <> '1'
                                                              OR PV_D.DELETE_FLAG IS NULL
                                                          )

                                         LEFT JOIN MBM_MDM_PART_MASTER PM_D
                                                   ON PV_D.PART_MASTER_ID = PM_D.ID
                                                       AND (
                                                          PM_D.DELETE_FLAG <> '1'
                                                              OR PM_D.DELETE_FLAG IS NULL
                                                          )

                                         LEFT JOIN MBM_APS_PRODUCT_ORDER PO_D
                                                   ON D.PRODUCT_ORDER_ID = PO_D.ID
                                                       AND (
                                                          PO_D.DELETE_FLAG <> '1'
                                                              OR PO_D.DELETE_FLAG IS NULL
                                                          )

                                WHERE D.STATE = '5'
                                  AND (
                                    D.DELETE_FLAG <> '1'
                                        OR D.DELETE_FLAG IS NULL
                                    )

                                GROUP BY PO_D.BATCH_NO,
                                         PM_D."NUMBER")

SELECT T.BATCH_NO                               AS 批次号,
       T.MODELS                                 AS 机型型号,
       T.QTY                                    AS 台套,

       SUBSTR(
               T.BATCH_NO,
               INSTR(T.BATCH_NO, '/', -1) + 1
       )                                        AS 累计,

       COALESCE(
               BFC.F_PROCUREMENT_COUNT,
               0
       )                                        AS 外协,

       TO_NUMBER(
               SUBSTR(
                       T.BATCH_NO,
                       INSTR(T.BATCH_NO, '/', -1) + 1
               )
       ) + COALESCE(BFC.F_PROCUREMENT_COUNT, 0) AS 产出,


    /* 成品接收 */
       COALESCE(
               FRC.FINISHED_RECEIVE_COUNT,
               0
       )                                        AS 成品接收,

    /*
     * 一级分类
     */
       CD.T1_ID                                 AS 一级分类ID,
       CD.T1_NAME                               AS 一级分类名称,
       CD.T1_ROOT_NODE                          AS 一级分类ROOT_NODE,

    /*
     * 二级分类
     */
       CD.T2_ID                                 AS 二级分类ID,
       CD.T2_NAME                               AS 二级分类名称,
       CD.T2_ROOT_NODE                          AS 二级分类ROOT_NODE,

       T."NUMBER"                               AS "订单号",

       COUNT(T."NUMBER") OVER (
           PARTITION BY T.BATCH_NO
           )                                    AS "计划",

    /*
     * 根
     */
       CD.T2_ROOT_NODE                          AS 根,

       BF_WAM.NAME                              AS 分厂,
       WS_WAM.NAME                              AS 产线,

       PM."NUMBER"                              AS 物料号,
       PM.NAME                                  AS 物料名称,

       T.COMPLETE_QTY                           AS 完工数,
       T.ORDER_STATE                            AS 订单状态,
       T.LOGISTICS_STATUS                       AS 配盘状态,

       T.SUGGEST_START                          AS SCP计划开始,
       T.SUGGEST_END                            AS SCP计划结束,

       T.PLAN_START                             AS MES计划开始,
       T.PLAN_END                               AS MES计划结束,

       T.ACTUAL_START                           AS 实际开始,
       T.ACTUAL_END                             AS 实际结束,

       T.AUXILIARY_TYPE                         AS AUXILIARYTYPE,

       FAC_WAM.SOURCE_SYSTEM_NUMBER             AS 工厂代码,
       BF_WAM.SOURCE_SYSTEM_NUMBER              AS 分厂编码,
       WS_WAM.SOURCE_SYSTEM_NUMBER              AS 产线编码,

       FAC_WAM.NAME                             AS 工厂名称,

       T.WBS                                    AS WBS,

       PV.SPECIFICATION_MODEL                   AS 机型

FROM MBM_APS_PRODUCT_ORDER T

         INNER JOIN MBM_MDM_PART_VERSION PV
                    ON T.PART_VERSION_ID = PV.ID
                        AND (PV.DELETE_FLAG <> '1' OR PV.DELETE_FLAG IS NULL)

         INNER JOIN MBM_MDM_PART_MASTER PM
                    ON PV.PART_MASTER_ID = PM.ID
                        AND (PM.DELETE_FLAG <> '1' OR PM.DELETE_FLAG IS NULL)

         INNER JOIN CLASSIFICATION_DETAIL CD
                    ON CD.PART_VERSION_ID = PV.ID
                        AND CD.PART_MASTER_ID = PM.ID
                        AND CD.T1_NAME IN ('塔机', '升降机')

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


    /* 成品接收 */
         LEFT JOIN FINISHED_RECEIVE_COUNT FRC
                   ON FRC.BATCH_NO = T.BATCH_NO
                       AND FRC.PART_NUMBER = PM."NUMBER"

         LEFT JOIN MBM_MDM_WORK_AREA_VERSION FAC
                   ON T.FACTORY_ID = FAC.ID
                       AND (FAC.DELETE_FLAG <> '1' OR FAC.DELETE_FLAG IS NULL)

         LEFT JOIN MBM_MDM_WORK_AREA_MASTER FAC_WAM
                   ON FAC.WORK_AREA_MASTER_ID = FAC_WAM.ID
                       AND (FAC_WAM.DELETE_FLAG <> '1' OR FAC_WAM.DELETE_FLAG IS NULL)

WHERE (T.DELETE_FLAG <> '1' OR T.DELETE_FLAG IS NULL)

ORDER BY T.BATCH_NO, T."NUMBER";








WITH BOM_F_COUNT AS (SELECT BOM.PRODUCT_ORDER_ID,
                            COUNT(*) AS F_PROCUREMENT_COUNT
                     FROM MBM_APS_PRODUCT_ORDER_BOM BOM
                              INNER JOIN MBM_MDM_PART_VERSION PV_BOM
                                         ON BOM.PART_VERSION_ID = PV_BOM.ID
                                             AND (PV_BOM.DELETE_FLAG <> '1' OR PV_BOM.DELETE_FLAG IS NULL)
                                             AND PV_BOM.PROCUREMENT_TYPE = 'F'
                     WHERE (BOM.DELETE_FLAG <> '1' OR BOM.DELETE_FLAG IS NULL)
                     GROUP BY BOM.PRODUCT_ORDER_ID),

     CLASSIFICATION_DETAIL AS (SELECT DISTINCT CPL.PART_VERSION_ID,
                                               CPL.PART_MASTER_ID,
                                               T1.ID        AS T1_ID,
                                               T1.NAME      AS T1_NAME,
                                               T1.ROOT_NODE AS T1_ROOT_NODE,
                                               T2.ID        AS T2_ID,
                                               T2.NAME      AS T2_NAME,
                                               T2.ROOT_NODE AS T2_ROOT_NODE
                               FROM MBM_MDM_CLASSIFICATION_PART_LINK CPL
                                        INNER JOIN MBM_MDM_CLASSIFICATION T2
                                                   ON T2.ID = CPL.CLASSIFICATION_ID
                                                       AND (T2.DELETE_FLAG <> '1' OR T2.DELETE_FLAG IS NULL)
                                        INNER JOIN MBM_MDM_CLASSIFICATION T1
                                                   ON T1.ID = T2.PARENT_NODE
                                                       AND (T1.DELETE_FLAG <> '1' OR T1.DELETE_FLAG IS NULL)
                               WHERE (CPL.DELETE_FLAG <> '1' OR CPL.DELETE_FLAG IS NULL)),

     ONLINE_COUNT AS (SELECT WAM_BF.NAME AS BRANCH_FACTORY_NAME,
                             PO.BATCH_NO,
                             PM."NUMBER" AS PART_NUMBER,
                             COUNT(*)    AS ONLINE_COUNT
                      FROM MBM_MES_PROCESS_TECH_ORDER_ID T
                               INNER JOIN MBM_APS_PROCESS_TECH_ORDER PTO
                                          ON T.MES_PROCESS_TECH_ORDER_ID = PTO.ID
                                              AND (PTO.DELETE_FLAG <> '1' OR PTO.DELETE_FLAG IS NULL)
                               INNER JOIN MBM_APS_PRODUCT_ORDER PO
                                          ON PTO.PRODUCT_ORDER_ID = PO.ID
                                              AND (PO.DELETE_FLAG <> '1' OR PO.DELETE_FLAG IS NULL)
                               INNER JOIN MBM_MDM_PART_VERSION PV
                                          ON T.PART_VERSION_ID = PV.ID
                                              AND (PV.DELETE_FLAG <> '1' OR PV.DELETE_FLAG IS NULL)
                               INNER JOIN MBM_MDM_WORK_AREA_VERSION WAV_BF
                                          ON PTO.BRANCH_FACTORY_ID = WAV_BF.ID
                                              AND (WAV_BF.DELETE_FLAG <> '1' OR WAV_BF.DELETE_FLAG IS NULL)
                               INNER JOIN MBM_MDM_WORK_AREA_MASTER WAM_BF
                                          ON WAV_BF.WORK_AREA_MASTER_ID = WAM_BF.ID
                                              AND (WAM_BF.DELETE_FLAG <> '1' OR WAM_BF.DELETE_FLAG IS NULL)
                               INNER JOIN MBM_MDM_PART_MASTER PM
                                          ON PV.PART_MASTER_ID = PM.ID
                                              AND (PM.DELETE_FLAG <> '1' OR PM.DELETE_FLAG IS NULL)
                      WHERE WAM_BF.NAME = '涂装分厂'
                        AND PTO.WHETHER_REPORTING_POINT_WHEN_GENERATE = '1'
                        AND T.PRODUCTION_STATUS = '20'
                        AND PV.PRODUCTION_MANAGEMENT_MODE = '10'
                        AND (PO.AUXILIARY_TYPE <> 'C' OR PO.AUXILIARY_TYPE IS NULL)
                        AND (PO.KD_ORDER <> 'X' OR PO.KD_ORDER IS NULL
                          OR (PO.AUXILIARY_TYPE <> 'A' OR PO.AUXILIARY_TYPE IS NULL))
                        AND (T.DELETE_FLAG <> '1' OR T.DELETE_FLAG IS NULL)
                      GROUP BY WAM_BF.NAME, PO.BATCH_NO, PM."NUMBER")

SELECT T.BATCH_NO                               AS 批次号,
       T.MODELS                                 AS 机型型号,
       T.QTY                                    AS 台套,

       SUBSTR(
               T.BATCH_NO,
               INSTR(T.BATCH_NO, '/', -1) + 1
       )                                        AS 累计,

       COALESCE(BFC.F_PROCUREMENT_COUNT, 0)     AS 外协,

       TO_NUMBER(
               SUBSTR(
                       T.BATCH_NO,
                       INSTR(T.BATCH_NO, '/', -1) + 1
               )
       ) + COALESCE(BFC.F_PROCUREMENT_COUNT, 0) AS 产出,

       COALESCE(OC.ONLINE_COUNT, 0)             AS 上线,

       CD.T1_ID                                 AS 一级分类ID,
       CD.T1_NAME                               AS 一级分类名称,
       CD.T1_ROOT_NODE                          AS 一级分类ROOT_NODE,

       CD.T2_ID                                 AS 二级分类ID,
       CD.T2_NAME                               AS 二级分类名称,
       CD.T2_ROOT_NODE                          AS 二级分类ROOT_NODE,

       T."NUMBER"                               AS "订单号",

       COUNT(T."NUMBER") OVER (
           PARTITION BY T.BATCH_NO
           )                                    AS "计划",

       CD.T2_ROOT_NODE                          AS 根,

       BF_WAM.NAME                              AS 分厂,
       WS_WAM.NAME                              AS 产线,

       PM."NUMBER"                              AS 物料号,
       PM.NAME                                  AS 物料名称,

       T.COMPLETE_QTY                           AS 完工数,
       T.ORDER_STATE                            AS 订单状态,
       T.LOGISTICS_STATUS                       AS 配盘状态,

       T.SUGGEST_START                          AS SCP计划开始,
       T.SUGGEST_END                            AS SCP计划结束,

       T.PLAN_START                             AS MES计划开始,
       T.PLAN_END                               AS MES计划结束,

       T.ACTUAL_START                           AS 实际开始,
       T.ACTUAL_END                             AS 实际结束,

       T.AUXILIARY_TYPE                         AS AUXILIARYTYPE,

       FAC_WAM.SOURCE_SYSTEM_NUMBER             AS 工厂代码,
       BF_WAM.SOURCE_SYSTEM_NUMBER              AS 分厂编码,
       WS_WAM.SOURCE_SYSTEM_NUMBER              AS 产线编码,

       FAC_WAM.NAME                             AS 工厂名称,

       T.WBS                                    AS WBS,

       PV.SPECIFICATION_MODEL                   AS 机型

FROM MBM_APS_PRODUCT_ORDER T

         INNER JOIN MBM_MDM_PART_VERSION PV
                    ON T.PART_VERSION_ID = PV.ID
                        AND (PV.DELETE_FLAG <> '1' OR PV.DELETE_FLAG IS NULL)

         INNER JOIN MBM_MDM_PART_MASTER PM
                    ON PV.PART_MASTER_ID = PM.ID
                        AND (PM.DELETE_FLAG <> '1' OR PM.DELETE_FLAG IS NULL)

         INNER JOIN CLASSIFICATION_DETAIL CD
                    ON CD.PART_VERSION_ID = PV.ID
                        AND CD.PART_MASTER_ID = PM.ID
                        AND CD.T1_NAME IN ('塔机', '升降机')

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

         LEFT JOIN ONLINE_COUNT OC
                   ON OC.BATCH_NO = T.BATCH_NO
                       AND OC.PART_NUMBER = PM."NUMBER"
                       AND OC.BRANCH_FACTORY_NAME = BF_WAM.NAME

         LEFT JOIN MBM_MDM_WORK_AREA_VERSION FAC
                   ON T.FACTORY_ID = FAC.ID
                       AND (FAC.DELETE_FLAG <> '1' OR FAC.DELETE_FLAG IS NULL)

         LEFT JOIN MBM_MDM_WORK_AREA_MASTER FAC_WAM
                   ON FAC.WORK_AREA_MASTER_ID = FAC_WAM.ID
                       AND (FAC_WAM.DELETE_FLAG <> '1' OR FAC_WAM.DELETE_FLAG IS NULL)

WHERE (T.DELETE_FLAG <> '1' OR T.DELETE_FLAG IS NULL)

ORDER BY T.BATCH_NO, T."NUMBER";
