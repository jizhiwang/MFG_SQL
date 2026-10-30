-- 重型生产周期报表（按物料）主查询
SELECT mmpm.number,
       mapo.batch_no,
       mmpv.specification_model   as MachineModel,--产品型号
       mmxp.product_specification as Tonnage,--产品规格
       mmxp.product_model,
       mapo.work_segment_id,
       mmxp.material_number
FROM mbm_aps_product_order mapo
         JOIN mbm_aps_order_config maoc ON
    mapo.order_config_id = maoc.id
         LEFT JOIN mbm_mdm_part_version mmpv ON
    mapo.part_version_id = mmpv.id
        AND (mmpv.delete_flag = '0'
        OR mmpv.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_part_master mmpm ON
    mmpv.part_master_id = mmpm.id
        AND (mmpm.delete_flag = '0'
        OR mmpm.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_xcmg_product mmxp ON
    SPLIT_PART(mmpm.number, '.', 1) = mmxp.material_number
        AND (mmxp.delete_flag = '0'
        OR mmxp.delete_flag IS NULL)
WHERE mapo.auxiliary_type = 'A'
  AND maoc.order_type = 'Z001'
  AND mapo.actual_end >= TO_DATE('2026-09-01', 'yyyy-MM-dd')
  AND mapo.actual_end < TO_DATE('2026-09-20', 'yyyy-MM-dd')
  AND EXISTS (SELECT 'x'
              FROM mbm_aps_product_order_id_number mapoin
              WHERE mapoin.product_order_id = mapo.id
                AND mapoin.tenant_id = mapo.tenant_id
                AND (mapoin.delete_flag = '0'
                  OR mapoin.delete_flag IS NULL)
                AND mapoin.number NOT SIMILAR TO '[0-9]%');



SELECT mapo.batch_no,
       SPLIT_PART(mmpm.number, '.', 1) AS material_number,
       mmxp.product_specification,
       mmxp.product_model,
       mapo.work_segment_id
FROM mbm_aps_product_order mapo
         JOIN mbm_aps_order_config maoc ON
    mapo.order_config_id = maoc.id
         LEFT JOIN mbm_mdm_part_version mmpv ON
    mapo.part_version_id = mmpv.id
        AND (mmpv.delete_flag = '0'
        OR mmpv.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_part_master mmpm ON
    mmpv.part_master_id = mmpm.id
        AND (mmpm.delete_flag = '0'
        OR mmpm.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_xcmg_product mmxp ON
    SPLIT_PART(mmpm.number, '.', 1) = mmxp.material_number
        AND (mmxp.delete_flag = '0'
        OR mmxp.delete_flag IS NULL)
WHERE mapo.auxiliary_type = 'A'
  AND maoc.order_type = 'Z001'
  AND mapo.actual_end >= TO_DATE('2026-09-01', 'yyyy-MM-dd')
  AND mapo.actual_end < TO_DATE('2026-09-20', 'yyyy-MM-dd')
  AND EXISTS (SELECT 'x'
              FROM mbm_aps_product_order_id_number mapoin
              WHERE mapoin.product_order_id = mapo.id
                AND mapoin.tenant_id = mapo.tenant_id
                AND (mapoin.delete_flag = '0'
                  OR mapoin.delete_flag IS NULL)
                AND mapoin.number NOT SIMILAR TO '[0-9]%');


-- 下料分厂数据
SELECT mmpm.number
FROM mbm_aps_product_order mapo
         JOIN mbm_aps_process_tech_order mapto ON
    mapo.id = mapto.product_order_id
        AND (mapto.delete_flag = '0'
        OR mapto.delete_flag IS NULL)
        AND mapo.tenant_id = mapto.tenant_id
         LEFT JOIN mbm_mdm_part_version mmpv ON
    mapo.part_version_id = mmpv.id
        AND (mmpv.delete_flag = '0'
        OR mmpv.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_part_master mmpm ON
    mmpv.part_master_id = mmpm.id
        AND (mmpm.delete_flag = '0'
        OR mmpm.delete_flag IS NULL)
WHERE mapo.work_segment_id = '053xl60hp9w8k'
  AND mapto.work_segment_id = '053xl60hp9w8k'
  AND (mapo.delete_flag = '0'
    OR mapo.delete_flag IS NULL)

  AND mmpm.number IN (
                      '112109833',
                      '115514414',
                      '114011266',
                      '111210213',
                      '117001953',
                      '119202850',
                      '110902844',
                      '111209418',
                      '115508338',
                      '112110424',
                      '116107157',
                      '111209990',
                      '115512953',
                      '115810415',
                      '119205773',
                      '115810870',
                      '112113419',
                      '115512034',
                      '114102859',
                      '122804533',
                      '112107420',
                      '112113182',
                      '110207962',
                      '115510707',
                      '116109721'
    )
GROUP BY mapo.work_segment_id, mmpm.number;

select *
from mbm_mdm_work_area_master m
         left join
     mbm_mdm_work_area_version v on m.id = v.work_area_master_id
where v.id = '053xl60hp9w8k';



SELECT T.BATCH_NO                   AS 批次号,
       T.MODELS                     AS 机型型号,
       T.QTY                        AS 台套,
       T.NUMBER                     AS "订单号",
       BF_WAM.NAME                  AS 分厂,
       WS_WAM.NAME                  AS 产线,
       T.BATCH_NUMBER2              AS BATCHNUMBER2,
       T.MRP_CONTROLLER             AS MRP控制,
       PM.NUMBER                    AS 物料号,
       PM.NAME                      AS 物料名称,
       T.COMPLETE_QTY               AS 完工数,
       T.ORDER_STATE                AS 订单状态,
       T.LOGISTICS_STATUS           AS 配盘状态,
       T.SUSPENDED                  AS SUSPENDED,
       T.IS_PRIORITY_ORDER          AS ISPRIORITYORDER,
       T.SUGGEST_START              AS SCP计划开始,
       T.SUGGEST_END                AS SCP计划结束,
       T.PLAN_START                 AS MES计划开始,
       T.PLAN_END                   AS MES计划结束,
       T.ACTUAL_START               AS 实际开始,
       T.ACTUAL_END                 AS 实际结束,
       OC.TYPE_DESC                 AS ORDERTYPEDESC,
       T.AUXILIARY_TYPE             AS AUXILIARYTYPE,
       T.PRODUCT_VERSION            AS PRODUCTVERSION,
       T.SCHEDULE_FLAG              AS SCHEDULEFLAG,
       T.IS_SYNCED_DS_AS            AS ISSYNCEDDSAS,
       T.SALE_AREA_BOM_ID           AS SALEAREABOMID,
       FAC_WAM.SOURCE_SYSTEM_NUMBER AS 工厂代码,
       BF_WAM.SOURCE_SYSTEM_NUMBER  AS 分厂编码,
       WS_WAM.SOURCE_SYSTEM_NUMBER  AS 产线编码,
       FAC_WAM.NAME                 AS 工厂名称,
       T.WBS                        AS WBS,
       T.MATERIAL_GROUP             AS MATERIALGROUP,
       T.REQUIRE_DELIVERY           AS REQUIREDELIVERY,
       T.PRIORITY                   AS PRIORITY,
       T.TOP_ORDER_ID               AS TOPORDER,
       T.DATA_SOURCE                AS DATASOURCE,
       PV.SPECIFICATION_MODEL       AS 机型,
       T.ERP_PROCESS_ROUTE          AS ERPPROCESSROUTE
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
         LEFT JOIN MBM_APS_ORDER_CONFIG OC
                   ON T.ORDER_CONFIG_ID = OC.ID
         LEFT JOIN MBM_MDM_WORK_AREA_VERSION FAC
                   ON T.FACTORY_ID = FAC.ID
                       AND (FAC.DELETE_FLAG <> '1' OR FAC.DELETE_FLAG IS NULL)
         LEFT JOIN MBM_MDM_WORK_AREA_MASTER FAC_WAM
                   ON FAC.WORK_AREA_MASTER_ID = FAC_WAM.ID
                       AND (FAC_WAM.DELETE_FLAG <> '1' OR FAC_WAM.DELETE_FLAG IS NULL)
WHERE (T.DELETE_FLAG <> '1' OR T.DELETE_FLAG IS NULL)
  AND T.AUXILIARY_TYPE = 'A';



SELECT mapo.batch_no,
       SPLIT_PART(mmpm.number, '.', 1) AS material_number,
       mmxp.product_specification,
       mmxp.product_model,
       mmpv.specification_model,
       mapo.work_segment_id
FROM mbm_aps_product_order mapo
         JOIN mbm_aps_order_config maoc ON
    mapo.order_config_id = maoc.id
         LEFT JOIN mbm_mdm_part_version mmpv ON
    mapo.part_version_id = mmpv.id
        AND (mmpv.delete_flag = '0'
        OR mmpv.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_part_master mmpm ON
    mmpv.part_master_id = mmpm.id
        AND (mmpm.delete_flag = '0'
        OR mmpm.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_xcmg_product mmxp ON
    SPLIT_PART(mmpm.number, '.', 1) = mmxp.material_number
        AND (mmxp.delete_flag = '0'
        OR mmxp.delete_flag IS NULL)
WHERE mapo.auxiliary_type = 'A'
  AND maoc.order_type = 'Z001'
  AND mapo.actual_end >= TO_DATE('2026-09-01', 'yyyy-MM-dd')
  AND mapo.actual_end < TO_DATE('2026-09-20', 'yyyy-MM-dd')
  AND EXISTS (SELECT 'x'
              FROM mbm_aps_product_order_id_number mapoin
              WHERE mapoin.product_order_id = mapo.id
                AND mapoin.tenant_id = mapo.tenant_id
                AND (mapoin.delete_flag = '0'
                  OR mapoin.delete_flag IS NULL)
                AND mapoin.number NOT SIMILAR TO '[0-9]%');