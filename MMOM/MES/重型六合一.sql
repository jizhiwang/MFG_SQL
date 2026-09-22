/*
查询逻辑：查询订单SCP计划开始日期/SCP计划完成日期在查询日期范围内，且物料描述包含
（伸臂结构：基本臂结构
转台结构：转台结构
车架结构：车架（排除包含座圈、后段的）
底盘装配：底盘
整机装配：装调）
*/
select suggest_start, suggest_end
from mbm_aps_product_order
limit 10;

--mbm_aps_product_order
--假设查询SCP开始结束时间为 2025-10-27 00:00:00-2025-11-14 00:00:00的数据且物料描述包含
--（伸臂结构：基本臂结构
--转台结构：转台结构
--车架结构：车架（排除包含座圈、后段的）
--底盘装配：底盘
--整机装配：装调）
/*
需要的表
mbm_aps_product_order:
batch_no:批次号
number:订单号
qty:台套数量
mbm_mdm_part_version：
part_number:物料编码
mbm_mdm_part_master：
name:物料描述
mbm_aps_order_config:
order_type:订单类型

mbm_mdm_classification_part_link：
classification_id:分类id
mbm_mdm_classification:
name:吨位
mbm_mdm_work_area_version:

mbm_mdm_work_area_master:
name:产线名称
SOURCE_SYSTEM_NUMBER:分厂编码



*/



select mbm_aps_product_order.number,--生产订单号
       mbm_aps_product_order.batch_no,--批次号
       mbm_aps_product_order.qty,--台套数量
       mbm_mdm_part_master.name,--物料描述
       mbm_aps_order_config.order_type,--订单类型
       mbm_mdm_classification.name,--吨位
       mbm_mdm_part_version.part_number,--物料号
       mbm_mdm_classification.name,--吨位

       -- 新增类型标记列
       CASE
           -- 备件计划：order_type为Z004
           WHEN mbm_aps_order_config.order_type = 'Z004' THEN '备件计划'
           -- 轮胎吊：order_type为Z001或Z002，且产线名称包含"轮胎吊"
           WHEN mbm_aps_order_config.order_type in ('Z001', 'Z002')
               AND mbm_mdm_work_area_master.name like '%轮胎吊%' THEN '轮胎吊'
           -- 添加吨位分类逻辑（只对order_type为Z001和Z002的非轮胎吊记录生效）
           WHEN mbm_aps_order_config.order_type in ('Z001', 'Z002') THEN
               CASE
                   -- 使用CAST将字符串转换为数值进行比较
                   WHEN CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) >= 5
                       AND CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) < 60 THEN '中小吨位'
                   WHEN CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) >= 60
                       AND CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) <= 130 THEN '中大吨位'
                   WHEN CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) > 130
                       AND CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) <= 500 THEN '大吨位'
                   WHEN CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) > 500 THEN '超大吨位'
                   -- 吨位数值不在范围内的情况
                   ELSE '未知吨位'
                   END
           -- 其他情况：可以根据需要设置默认值
           ELSE NULL -- 或设置为空字符串''
           END AS plan_type,
       -- 新增产品类型列
       CASE
           -- 基本臂结构 → 伸臂结构
           WHEN mbm_mdm_part_master.name LIKE '%基本臂结构%' THEN '伸臂结构'
           -- 转台结构 → 转台结构
           WHEN mbm_mdm_part_master.name LIKE '%转台结构%' THEN '转台结构'
           -- 车架且排除座圈和后段 → 车架结构
           WHEN mbm_mdm_part_master.name LIKE '%车架%'
               AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
               AND mbm_mdm_part_master.name NOT LIKE '%后段%' THEN '车架结构'
           -- 底盘 → 底盘装配
           WHEN mbm_mdm_part_master.name LIKE '%底盘%' THEN '底盘装配'
           -- 装调 → 整机装配
           WHEN mbm_mdm_part_master.name LIKE '%装调%' THEN '整机装配'
           -- 其他情况
           ELSE NULL
           END AS product_type
from mbm_aps_product_order
         left join
     mbm_mdm_part_version
     on
         mbm_aps_product_order.part_version_id = mbm_mdm_part_version.id
         left join
     mbm_aps_order_config
     on
         mbm_aps_product_order.order_config_id = mbm_aps_order_config.id
         left join
     mbm_mdm_work_area_version
     on
         mbm_aps_product_order.work_segment_id = mbm_mdm_work_area_version.id
         left join
     mbm_mdm_part_master
     on
         mbm_mdm_part_version.part_master_id = mbm_mdm_part_master.id
         left join
     mbm_mdm_work_area_master
     on
         mbm_mdm_work_area_version.work_area_master_id = mbm_mdm_work_area_master.id
         left join
     mbm_mdm_classification_part_link
     on
         mbm_mdm_part_master.id = mbm_mdm_classification_part_link.part_master_id
             and mbm_mdm_part_version.id = mbm_mdm_classification_part_link.part_version_id
         left join
     mbm_mdm_classification
     on
         mbm_mdm_classification_part_link.classification_id = mbm_mdm_classification.id
where mbm_aps_product_order.suggest_start between '2025-10-27 00:00:00' and '2025-11-14 00:00:00'
  and mbm_aps_product_order.suggest_end between '2025-10-27 00:00:00' and '2025-11-14 00:00:00'
  and (mbm_mdm_part_master.name like '%基本臂结构%'
    or mbm_mdm_part_master.name like '%转台结构%'
    or (mbm_mdm_part_master.name like '%车架%'
        and mbm_mdm_part_master.name not like '%座圈%'
        and mbm_mdm_part_master.name not like '%后段%')
    or mbm_mdm_part_master.name like '%底盘%'
    or mbm_mdm_part_master.name like '%装调%')
  and mbm_mdm_classification.root_node = 'product_tonnage';



select mbm_aps_product_order.number,     --生产订单号
       mbm_aps_product_order.batch_no,   --批次号
       mbm_aps_product_order.qty,        --台套数量
       mbm_mdm_part_master.name,         --物料描述
       mbm_aps_order_config.order_type,  --订单类型
       mbm_mdm_classification.name,      --吨位
       mbm_mdm_part_version.part_number, --物料号
       -- 新增类型标记列
       CASE
           -- 备件计划：order_type为Z004
           WHEN mbm_aps_order_config.order_type = 'Z004' THEN '备件计划'
           -- 轮胎吊：order_type为Z001或Z002，且产线名称包含"轮胎吊"
           WHEN mbm_aps_order_config.order_type in ('Z001', 'Z002')
               AND mbm_mdm_work_area_master.name like '%轮胎吊%' THEN '轮胎吊'
           -- 添加吨位分类逻辑（只对order_type为Z001和Z002的非轮胎吊记录生效）
           WHEN mbm_aps_order_config.order_type in ('Z001', 'Z002') THEN
               CASE
                   -- 使用CAST将字符串转换为数值进行比较
                   WHEN CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) >= 5
                       AND CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) < 60 THEN '中小吨位'
                   WHEN CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) >= 60
                       AND CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) <= 130 THEN '中大吨位'
                   WHEN CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) > 130
                       AND CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) <= 500 THEN '大吨位'
                   WHEN CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) > 500 THEN '超大吨位'
                   -- 吨位数值不在范围内的情况
                   ELSE '未知吨位'
                   END
           -- 其他情况：可以根据需要设置默认值
           ELSE NULL -- 或设置为空字符串''
           END AS plan_type,
       -- 新增产品类型列
       CASE
           -- 基本臂结构 → 伸臂结构
           WHEN mbm_mdm_part_master.name LIKE '%基本臂结构%' THEN '伸臂结构'
           -- 转台结构 → 转台结构
           WHEN mbm_mdm_part_master.name LIKE '%转台结构%' THEN '转台结构'
           -- 车架且排除座圈和后段 → 车架结构
           WHEN mbm_mdm_part_master.name LIKE '%车架%'
               AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
               AND mbm_mdm_part_master.name NOT LIKE '%后段%' THEN '车架结构'
           -- 底盘 → 底盘装配
           WHEN mbm_mdm_part_master.name LIKE '%底盘%' THEN '底盘装配'
           -- 装调 → 整机装配
           WHEN mbm_mdm_part_master.name LIKE '%装调%' THEN '整机装配'
           -- 其他情况
           ELSE NULL
           END AS product_type,
       -- 新增：提取物料号前缀（.前的字符串）- 通用替代方案
       CASE
           WHEN CASE
                    WHEN mbm_mdm_part_master.name LIKE '%基本臂结构%' THEN '伸臂结构'
                    WHEN mbm_mdm_part_master.name LIKE '%转台结构%' THEN '转台结构'
                    WHEN mbm_mdm_part_master.name LIKE '%车架%'
                        AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
                        AND mbm_mdm_part_master.name NOT LIKE '%后段%' THEN '车架结构'
                    WHEN mbm_mdm_part_master.name LIKE '%底盘%' THEN '底盘装配'
                    WHEN mbm_mdm_part_master.name LIKE '%装调%' THEN '整机装配'
                    ELSE NULL
                    END = '整机装配'
               THEN
               -- 通用方案：使用字符串位置函数替代SUBSTRING_INDEX
               CASE
                   -- 检查是否包含.
                   WHEN POSITION('.' IN mbm_mdm_part_version.part_number) > 0 THEN
                       -- 截取.前的部分
                       SUBSTRING(mbm_mdm_part_version.part_number
                                 FROM 1
                                 FOR POSITION('.' IN mbm_mdm_part_version.part_number) - 1)
                   ELSE
                       -- 如果没有.，返回整个字符串
                       mbm_mdm_part_version.part_number
                   END
           ELSE NULL
           END AS material_code,
       -- 新增：产品型号（仅当product_type为整机装配时）
       xcmg_product.product_model
from mbm_aps_product_order
         left join
     mbm_mdm_part_version
     on
         mbm_aps_product_order.part_version_id = mbm_mdm_part_version.id
         left join
     mbm_aps_order_config
     on
         mbm_aps_product_order.order_config_id = mbm_aps_order_config.id
         left join
     mbm_mdm_work_area_version
     on
         mbm_aps_product_order.work_segment_id = mbm_mdm_work_area_version.id
         left join
     mbm_mdm_part_master
     on
         mbm_mdm_part_version.part_master_id = mbm_mdm_part_master.id
         left join
     mbm_mdm_work_area_master
     on
         mbm_mdm_work_area_version.work_area_master_id = mbm_mdm_work_area_master.id
         left join
     mbm_mdm_classification_part_link
     on
         mbm_mdm_part_master.id = mbm_mdm_classification_part_link.part_master_id
             and mbm_mdm_part_version.id = mbm_mdm_classification_part_link.part_version_id
         left join
     mbm_mdm_classification
     on
         mbm_mdm_classification_part_link.classification_id = mbm_mdm_classification.id
         -- 新增：连接mbm_mdm_xcmg_product表
         left join
     mbm_mdm_xcmg_product xcmg_product
     on
         -- 只在product_type为整机装配时才进行表连接
         CASE
             WHEN mbm_mdm_part_master.name LIKE '%基本臂结构%' THEN '伸臂结构'
             WHEN mbm_mdm_part_master.name LIKE '%转台结构%' THEN '转台结构'
             WHEN mbm_mdm_part_master.name LIKE '%车架%'
                 AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
                 AND mbm_mdm_part_master.name NOT LIKE '%后段%' THEN '车架结构'
             WHEN mbm_mdm_part_master.name LIKE '%底盘%' THEN '底盘装配'
             WHEN mbm_mdm_part_master.name LIKE '%装调%' THEN '整机装配'
             ELSE NULL
             END = '整机装配'
             AND xcmg_product.material_number =
             -- 使用相同的通用方案提取前缀
                 CASE
                     WHEN POSITION('.' IN mbm_mdm_part_version.part_number) > 0 THEN
                         SUBSTRING(mbm_mdm_part_version.part_number
                                   FROM 1
                                   FOR POSITION('.' IN mbm_mdm_part_version.part_number) - 1)
                     ELSE
                         mbm_mdm_part_version.part_number
                     END
where mbm_aps_product_order.suggest_start between '2025-10-27 00:00:00' and '2025-11-14 00:00:00'
  and mbm_aps_product_order.suggest_end between '2025-10-27 00:00:00' and '2025-11-14 00:00:00'
  and (mbm_mdm_part_master.name like '%基本臂结构%'
    or mbm_mdm_part_master.name like '%转台结构%'
    or (mbm_mdm_part_master.name like '%车架%'
        and mbm_mdm_part_master.name not like '%座圈%'
        and mbm_mdm_part_master.name not like '%后段%')
    or mbm_mdm_part_master.name like '%底盘%'
    or mbm_mdm_part_master.name like '%装调%')
  and mbm_mdm_classification.root_node = 'product_tonnage';


-- 使用CTE预计算常用字段，提高可读性和性能
WITH base_data AS (SELECT mbm_aps_product_order.number  AS production_order_number,
                          mbm_aps_product_order.batch_no,
                          mbm_aps_product_order.qty,
                          mbm_mdm_part_master.name      AS material_description,
                          mbm_aps_order_config.order_type,
                          mbm_mdm_classification.name   AS tonnage,
                          mbm_mdm_part_version.part_number,
                          mbm_mdm_work_area_master.name AS work_area_name,
                          -- 预先计算产品类型，避免重复计算
                          CASE
                              WHEN mbm_mdm_part_master.name LIKE '%基本臂结构%' THEN '伸臂结构'
                              WHEN mbm_mdm_part_master.name LIKE '%转台结构%' THEN '转台结构'
                              WHEN mbm_mdm_part_master.name LIKE '%车架%'
                                  AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
                                  AND mbm_mdm_part_master.name NOT LIKE '%后段%' THEN '车架结构'
                              WHEN mbm_mdm_part_master.name LIKE '%底盘%' THEN '底盘装配'
                              WHEN mbm_mdm_part_master.name LIKE '%装调%' THEN '整机装配'
                              ELSE NULL
                              END                       AS product_type,
                          -- 预先提取物料前缀，避免重复计算
                          CASE
                              WHEN POSITION('.' IN mbm_mdm_part_version.part_number) > 0 THEN
                                  SUBSTRING(mbm_mdm_part_version.part_number
                                            FROM 1
                                            FOR POSITION('.' IN mbm_mdm_part_version.part_number) - 1)
                              ELSE
                                  mbm_mdm_part_version.part_number
                              END                       AS material_prefix
                   FROM mbm_aps_product_order
                            LEFT JOIN mbm_mdm_part_version
                                      ON mbm_aps_product_order.part_version_id = mbm_mdm_part_version.id
                            LEFT JOIN mbm_aps_order_config
                                      ON mbm_aps_product_order.order_config_id = mbm_aps_order_config.id
                            LEFT JOIN mbm_mdm_work_area_version
                                      ON mbm_aps_product_order.work_segment_id = mbm_mdm_work_area_version.id
                            LEFT JOIN mbm_mdm_part_master
                                      ON mbm_mdm_part_version.part_master_id = mbm_mdm_part_master.id
                            LEFT JOIN mbm_mdm_work_area_master
                                      ON mbm_mdm_work_area_version.work_area_master_id = mbm_mdm_work_area_master.id
                            LEFT JOIN mbm_mdm_classification_part_link
                                      ON mbm_mdm_part_master.id = mbm_mdm_classification_part_link.part_master_id
                                          AND mbm_mdm_part_version.id = mbm_mdm_classification_part_link.part_version_id
                            LEFT JOIN mbm_mdm_classification
                                      ON mbm_mdm_classification_part_link.classification_id = mbm_mdm_classification.id
                   WHERE mbm_aps_product_order.suggest_start BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
                     AND mbm_aps_product_order.suggest_end BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
                     AND mbm_mdm_classification.root_node = 'product_tonnage'
                     AND (
                       mbm_mdm_part_master.name LIKE '%基本臂结构%'
                           OR mbm_mdm_part_master.name LIKE '%转台结构%'
                           OR (mbm_mdm_part_master.name LIKE '%车架%'
                           AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
                           AND mbm_mdm_part_master.name NOT LIKE '%后段%')
                           OR mbm_mdm_part_master.name LIKE '%底盘%'
                           OR mbm_mdm_part_master.name LIKE '%装调%'
                       ))
SELECT base_data.production_order_number,
       base_data.batch_no,
       base_data.qty,
       base_data.material_description,
       base_data.order_type,
       base_data.tonnage,
       base_data.part_number,
       -- 优化后的plan_type计算
       CASE
           WHEN base_data.order_type = 'Z004' THEN '备件计划'
           WHEN base_data.order_type IN ('Z001', 'Z002')
               AND base_data.work_area_name LIKE '%轮胎吊%' THEN '轮胎吊'
           WHEN base_data.order_type IN ('Z001', 'Z002') THEN
               CASE
                   WHEN base_data.tonnage ~ '^[0-9]+(\.[0-9]+)?$' THEN -- 验证是否为数字
                       CASE
                           WHEN CAST(base_data.tonnage AS DECIMAL(10, 2)) >= 5
                               AND CAST(base_data.tonnage AS DECIMAL(10, 2)) < 60 THEN '中小吨位'
                           WHEN CAST(base_data.tonnage AS DECIMAL(10, 2)) >= 60
                               AND CAST(base_data.tonnage AS DECIMAL(10, 2)) <= 130 THEN '中大吨位'
                           WHEN CAST(base_data.tonnage AS DECIMAL(10, 2)) > 130
                               AND CAST(base_data.tonnage AS DECIMAL(10, 2)) <= 500 THEN '大吨位'
                           WHEN CAST(base_data.tonnage AS DECIMAL(10, 2)) > 500 THEN '超大吨位'
                           ELSE '未知吨位'
                           END
                   ELSE '无效吨位格式'
                   END
           ELSE NULL
           END AS plan_type,
       base_data.product_type,
       -- 简化的material_code计算
       CASE
           WHEN base_data.product_type = '整机装配' THEN base_data.material_prefix
           ELSE NULL
           END AS material_code,
       -- 产品型号连接
       mbm_mdm_xcmg_product.product_model
FROM base_data
         LEFT JOIN mbm_mdm_xcmg_product
                   ON base_data.product_type = '整机装配'
                       AND mbm_mdm_xcmg_product.material_number = base_data.material_prefix;


--嵌套查询
SELECT base_data.production_order_number,
       base_data.batch_no,
       base_data.qty,
       base_data.material_description,
       base_data.order_type,
       base_data.tonnage,
       base_data.part_number,
       -- 优化后的plan_type计算
       CASE
           WHEN base_data.order_type = 'Z004' THEN '备件计划'
           WHEN base_data.order_type IN ('Z001', 'Z002')
               AND base_data.work_area_name LIKE '%轮胎吊%' THEN '轮胎吊'
           WHEN base_data.order_type IN ('Z001', 'Z002') THEN
               CASE
                   WHEN base_data.tonnage ~ '^[0-9]+(\.[0-9]+)?$' THEN -- 验证是否为数字
                       CASE
                           WHEN CAST(base_data.tonnage AS DECIMAL(10, 2)) >= 5
                               AND CAST(base_data.tonnage AS DECIMAL(10, 2)) < 60 THEN '中小吨位'
                           WHEN CAST(base_data.tonnage AS DECIMAL(10, 2)) >= 60
                               AND CAST(base_data.tonnage AS DECIMAL(10, 2)) <= 130 THEN '中大吨位'
                           WHEN CAST(base_data.tonnage AS DECIMAL(10, 2)) > 130
                               AND CAST(base_data.tonnage AS DECIMAL(10, 2)) <= 500 THEN '大吨位'
                           WHEN CAST(base_data.tonnage AS DECIMAL(10, 2)) > 500 THEN '超大吨位'
                           ELSE '未知吨位'
                           END
                   ELSE '无效吨位格式'
                   END
           ELSE NULL
           END AS plan_type,
       base_data.product_type,
       -- 简化的material_code计算
       CASE
           WHEN base_data.product_type = '整机装配' THEN base_data.material_prefix
           ELSE NULL
           END AS material_code,
       -- 产品型号连接
       mbm_mdm_xcmg_product.product_model
FROM (SELECT mbm_aps_product_order.number  AS production_order_number,
             mbm_aps_product_order.batch_no,
             mbm_aps_product_order.qty,
             mbm_mdm_part_master.name      AS material_description,
             mbm_aps_order_config.order_type,
             mbm_mdm_classification.name   AS tonnage,
             mbm_mdm_part_version.part_number,
             mbm_mdm_work_area_master.name AS work_area_name,
             -- 预先计算产品类型，避免重复计算
             CASE
                 WHEN mbm_mdm_part_master.name LIKE '%基本臂结构%' THEN '伸臂结构'
                 WHEN mbm_mdm_part_master.name LIKE '%转台结构%' THEN '转台结构'
                 WHEN mbm_mdm_part_master.name LIKE '%车架%'
                     AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
                     AND mbm_mdm_part_master.name NOT LIKE '%后段%' THEN '车架结构'
                 WHEN mbm_mdm_part_master.name LIKE '%底盘%' THEN '底盘装配'
                 WHEN mbm_mdm_part_master.name LIKE '%装调%' THEN '整机装配'
                 ELSE NULL
                 END                       AS product_type,
             -- 预先提取物料前缀，避免重复计算
             CASE
                 WHEN POSITION('.' IN mbm_mdm_part_version.part_number) > 0 THEN
                     SUBSTRING(mbm_mdm_part_version.part_number
                               FROM 1
                               FOR POSITION('.' IN mbm_mdm_part_version.part_number) - 1)
                 ELSE
                     mbm_mdm_part_version.part_number
                 END                       AS material_prefix
      FROM mbm_aps_product_order
               LEFT JOIN mbm_mdm_part_version
                         ON mbm_aps_product_order.part_version_id = mbm_mdm_part_version.id
               LEFT JOIN mbm_aps_order_config
                         ON mbm_aps_product_order.order_config_id = mbm_aps_order_config.id
               LEFT JOIN mbm_mdm_work_area_version
                         ON mbm_aps_product_order.work_segment_id = mbm_mdm_work_area_version.id
               LEFT JOIN mbm_mdm_part_master
                         ON mbm_mdm_part_version.part_master_id = mbm_mdm_part_master.id
               LEFT JOIN mbm_mdm_work_area_master
                         ON mbm_mdm_work_area_version.work_area_master_id = mbm_mdm_work_area_master.id
               LEFT JOIN mbm_mdm_classification_part_link
                         ON mbm_mdm_part_master.id = mbm_mdm_classification_part_link.part_master_id
                             AND mbm_mdm_part_version.id = mbm_mdm_classification_part_link.part_version_id
               LEFT JOIN mbm_mdm_classification
                         ON mbm_mdm_classification_part_link.classification_id = mbm_mdm_classification.id
      WHERE mbm_aps_product_order.suggest_start BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
        AND mbm_aps_product_order.suggest_end BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
        AND mbm_mdm_classification.root_node = 'product_tonnage'
        AND (
          mbm_mdm_part_master.name LIKE '%基本臂结构%'
              OR mbm_mdm_part_master.name LIKE '%转台结构%'
              OR (mbm_mdm_part_master.name LIKE '%车架%'
              AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
              AND mbm_mdm_part_master.name NOT LIKE '%后段%')
              OR mbm_mdm_part_master.name LIKE '%底盘%'
              OR mbm_mdm_part_master.name LIKE '%装调%'
          )) AS base_data
         LEFT JOIN mbm_mdm_xcmg_product
                   ON base_data.product_type = '整机装配'
                       AND mbm_mdm_xcmg_product.material_number = base_data.material_prefix;


--原始版本
SELECT mbm_aps_product_order.number,
       mbm_aps_product_order.batch_no,
       mbm_aps_product_order.qty,
       mbm_aps_product_order.suggest_start,
       mbm_aps_product_order.suggest_end,
       mbm_aps_product_order.actual_start,
       mbm_aps_product_order.actual_end,
       mbm_mdm_part_master.name,
       mbm_aps_order_config.order_type,
       mbm_mdm_classification.name,
       mbm_mdm_part_version.part_number,
       mbm_mdm_work_area_master.SOURCE_SYSTEM_NUMBER,


       CASE
           WHEN mbm_aps_order_config.order_type = 'Z004' THEN '备件计划'
           WHEN mbm_aps_order_config.order_type IN ('Z001', 'Z002')
               AND mbm_mdm_work_area_master.name LIKE '%轮胎吊%' THEN '轮胎吊'
           WHEN mbm_aps_order_config.order_type IN ('Z001', 'Z002') THEN
               CASE
                   WHEN mbm_mdm_classification.name ~ '^[0-9]+(\.[0-9]+)?$' THEN
                       CASE
                           WHEN CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) >= 5
                               AND CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) < 60 THEN '中小吨位'
                           WHEN CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) >= 60
                               AND CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) <= 130 THEN '中大吨位'
                           WHEN CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) > 130
                               AND CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) <= 500 THEN '大吨位'
                           WHEN CAST(mbm_mdm_classification.name AS DECIMAL(10, 2)) > 500 THEN '超大吨位'
                           ELSE '未知吨位'
                           END
                   ELSE '无效吨位格式'
                   END
           ELSE NULL
           END AS plan_type,
       CASE
           WHEN mbm_mdm_part_master.name LIKE '%基本臂结构%' THEN '伸臂结构'
           WHEN mbm_mdm_part_master.name LIKE '%转台结构%' THEN '转台结构'
           WHEN mbm_mdm_part_master.name LIKE '%车架%'
               AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
               AND mbm_mdm_part_master.name NOT LIKE '%后段%' THEN '车架结构'
           WHEN mbm_mdm_part_master.name LIKE '%底盘%' THEN '底盘装配'
           WHEN mbm_mdm_part_master.name LIKE '%装调%' THEN '整机装配'
           ELSE NULL
           END AS product_type,
       CASE
           WHEN CASE
                    WHEN mbm_mdm_part_master.name LIKE '%基本臂结构%' THEN '伸臂结构'
                    WHEN mbm_mdm_part_master.name LIKE '%转台结构%' THEN '转台结构'
                    WHEN mbm_mdm_part_master.name LIKE '%车架%'
                        AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
                        AND mbm_mdm_part_master.name NOT LIKE '%后段%' THEN '车架结构'
                    WHEN mbm_mdm_part_master.name LIKE '%底盘%' THEN '底盘装配'
                    WHEN mbm_mdm_part_master.name LIKE '%装调%' THEN '整机装配'
                    ELSE NULL
                    END = '整机装配'
               THEN
               CASE
                   WHEN POSITION('.' IN mbm_mdm_part_version.part_number) > 0 THEN
                       SUBSTRING(mbm_mdm_part_version.part_number
                                 FROM 1
                                 FOR POSITION('.' IN mbm_mdm_part_version.part_number) - 1)
                   ELSE
                       mbm_mdm_part_version.part_number
                   END
           ELSE NULL
           END AS material_code,
       mbm_mdm_xcmg_product.product_model
FROM mbm_aps_product_order
         LEFT JOIN mbm_mdm_part_version
                   ON mbm_aps_product_order.part_version_id = mbm_mdm_part_version.id
         LEFT JOIN mbm_aps_order_config
                   ON mbm_aps_product_order.order_config_id = mbm_aps_order_config.id
         LEFT JOIN mbm_mdm_work_area_version
                   ON mbm_aps_product_order.work_segment_id = mbm_mdm_work_area_version.id
         LEFT JOIN mbm_mdm_part_master
                   ON mbm_mdm_part_version.part_master_id = mbm_mdm_part_master.id
         LEFT JOIN mbm_mdm_work_area_master
                   ON mbm_mdm_work_area_version.work_area_master_id = mbm_mdm_work_area_master.id
         LEFT JOIN mbm_mdm_classification_part_link
                   ON mbm_mdm_part_master.id = mbm_mdm_classification_part_link.part_master_id
                       AND mbm_mdm_part_version.id = mbm_mdm_classification_part_link.part_version_id
         LEFT JOIN mbm_mdm_classification
                   ON mbm_mdm_classification_part_link.classification_id = mbm_mdm_classification.id
         LEFT JOIN mbm_mdm_xcmg_product
                   ON CASE
                          WHEN mbm_mdm_part_master.name LIKE '%基本臂结构%' THEN '伸臂结构'
                          WHEN mbm_mdm_part_master.name LIKE '%转台结构%' THEN '转台结构'
                          WHEN mbm_mdm_part_master.name LIKE '%车架%'
                              AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
                              AND mbm_mdm_part_master.name NOT LIKE '%后段%' THEN '车架结构'
                          WHEN mbm_mdm_part_master.name LIKE '%底盘%' THEN '底盘装配'
                          WHEN mbm_mdm_part_master.name LIKE '%装调%' THEN '整机装配'
                          ELSE NULL
                          END = '整机装配'
                       AND mbm_mdm_xcmg_product.material_number =
                           CASE
                               WHEN POSITION('.' IN mbm_mdm_part_version.part_number) > 0 THEN
                                   SUBSTRING(mbm_mdm_part_version.part_number
                                             FROM 1
                                             FOR POSITION('.' IN mbm_mdm_part_version.part_number) - 1)
                               ELSE
                                   mbm_mdm_part_version.part_number
                               END
WHERE mbm_aps_product_order.suggest_start BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
  AND mbm_aps_product_order.suggest_end BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
  AND mbm_mdm_classification.root_node = 'product_tonnage'
  AND (
    mbm_mdm_part_master.name LIKE '%基本臂结构%'
        OR mbm_mdm_part_master.name LIKE '%转台结构%'
        OR (mbm_mdm_part_master.name LIKE '%车架%'
        AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
        AND mbm_mdm_part_master.name NOT LIKE '%后段%')
        OR mbm_mdm_part_master.name LIKE '%底盘%'
        OR mbm_mdm_part_master.name LIKE '%装调%'
    );





--去除where 条件
WITH base_data AS (SELECT mbm_aps_product_order.number  AS production_order_number,
                          mbm_aps_product_order.batch_no,
                          mbm_aps_product_order.qty,
                          mbm_aps_product_order.suggest_start,
                          mbm_aps_product_order.suggest_end,
                          mbm_aps_product_order.actual_start,
                          mbm_aps_product_order.actual_end,
                          mbm_mdm_part_master.name      AS material_description,
                          mbm_aps_order_config.order_type,
                          mbm_mdm_classification.name   AS tonnage,
                          mbm_mdm_part_version.part_number,
                          mbm_mdm_work_area_master.SOURCE_SYSTEM_NUMBER,
                          mbm_mdm_work_area_master.name AS work_area_name,

                          -- 预先计算产品类型，避免重复计算
                          CASE
                              WHEN mbm_mdm_part_master.name LIKE '%基本臂结构%' THEN '伸臂结构'
                              WHEN mbm_mdm_part_master.name LIKE '%转台结构%' THEN '转台结构'
                              WHEN mbm_mdm_part_master.name LIKE '%车架%'
                                  AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
                                  AND mbm_mdm_part_master.name NOT LIKE '%后段%' THEN '车架结构'
                              WHEN mbm_mdm_part_master.name LIKE '%底盘%' THEN '底盘装配'
                              WHEN mbm_mdm_part_master.name LIKE '%装调%' THEN '整机装配'
                              ELSE NULL
                              END                       AS product_type,

                          -- 预先提取物料前缀，避免重复计算
                          CASE
                              WHEN POSITION('.' IN mbm_mdm_part_version.part_number) > 0 THEN
                                  SUBSTRING(mbm_mdm_part_version.part_number
                                            FROM 1
                                            FOR POSITION('.' IN mbm_mdm_part_version.part_number) - 1)
                              ELSE
                                  mbm_mdm_part_version.part_number
                              END                       AS material_prefix
                   FROM mbm_aps_product_order
                            LEFT JOIN mbm_mdm_part_version
                                      ON mbm_aps_product_order.part_version_id = mbm_mdm_part_version.id
                            LEFT JOIN mbm_aps_order_config
                                      ON mbm_aps_product_order.order_config_id = mbm_aps_order_config.id
                            LEFT JOIN mbm_mdm_work_area_version
                                      ON mbm_aps_product_order.work_segment_id = mbm_mdm_work_area_version.id
                            LEFT JOIN mbm_mdm_part_master
                                      ON mbm_mdm_part_version.part_master_id = mbm_mdm_part_master.id
                            LEFT JOIN mbm_mdm_work_area_master
                                      ON mbm_mdm_work_area_version.work_area_master_id = mbm_mdm_work_area_master.id
                            LEFT JOIN mbm_mdm_classification_part_link
                                      ON mbm_mdm_part_master.id = mbm_mdm_classification_part_link.part_master_id
                                          AND mbm_mdm_part_version.id = mbm_mdm_classification_part_link.part_version_id
                            LEFT JOIN mbm_mdm_classification
                                      ON mbm_mdm_classification_part_link.classification_id = mbm_mdm_classification.id
                   WHERE mbm_mdm_classification.root_node = 'product_tonnage'
                     AND (
                       mbm_mdm_part_master.name LIKE '%基本臂结构%'
                           OR mbm_mdm_part_master.name LIKE '%转台结构%'
                           OR (mbm_mdm_part_master.name LIKE '%车架%'
                           AND mbm_mdm_part_master.name NOT LIKE '%座圈%'
                           AND mbm_mdm_part_master.name NOT LIKE '%后段%')
                           OR mbm_mdm_part_master.name LIKE '%底盘%'
                           OR mbm_mdm_part_master.name LIKE '%装调%'
                       ))
SELECT base_data.production_order_number,
       base_data.batch_no,
       base_data.qty,
       base_data.suggest_start,
       base_data.suggest_end,
       base_data.actual_start,
       base_data.actual_end,
       base_data.material_description,
       base_data.order_type,
       base_data.tonnage,
       base_data.part_number,
       base_data.SOURCE_SYSTEM_NUMBER,
       CASE
           WHEN base_data.order_type = 'Z004' THEN '备件计划'
           WHEN base_data.order_type IN ('Z001', 'Z002')
               AND base_data.work_area_name LIKE '%轮胎吊%' THEN '轮胎吊'
           WHEN base_data.order_type IN ('Z001', 'Z002') THEN
               CASE
                   WHEN base_data.tonnage ~ '^[0-9]+(\.[0-9]+)?$' THEN -- 验证是否为数字
                       CASE
                           WHEN CAST(base_data.tonnage AS DECIMAL(10, 2)) >= 5
                               AND CAST(base_data.tonnage AS DECIMAL(10, 2)) < 60 THEN '中小吨位'
                           WHEN CAST(base_data.tonnage AS DECIMAL(10, 2)) >= 60
                               AND CAST(base_data.tonnage AS DECIMAL(10, 2)) <= 130 THEN '中大吨位'
                           WHEN CAST(base_data.tonnage AS DECIMAL(10, 2)) > 130
                               AND CAST(base_data.tonnage AS DECIMAL(10, 2)) <= 500 THEN '大吨位'
                           WHEN CAST(base_data.tonnage AS DECIMAL(10, 2)) > 500 THEN '超大吨位'
                           ELSE '未知吨位'
                           END
                   ELSE '无效吨位格式'
                   END
           ELSE NULL
           END AS plan_type,
       base_data.product_type,
       CASE
           WHEN base_data.product_type = '整机装配' THEN base_data.material_prefix
           ELSE NULL
           END AS material_code,

       -- 产品型号连接（优化后）
       mbm_mdm_xcmg_product.product_model
FROM base_data
         LEFT JOIN mbm_mdm_xcmg_product
                   ON base_data.product_type = '整机装配'
                       AND mbm_mdm_xcmg_product.material_number = base_data.material_prefix;



--新逻辑
--查询-------产品类型-------数据




WITH product_type_cte AS (
    SELECT
        mbm_aps_product_order.number,
        mbm_mdm_classification.name AS product_type_name
    FROM mbm_aps_product_order
    LEFT JOIN mbm_mdm_part_version
        ON mbm_aps_product_order.part_version_id = mbm_mdm_part_version.id
    LEFT JOIN mbm_mdm_part_master
        ON mbm_mdm_part_version.part_master_id = mbm_mdm_part_master.id
    LEFT JOIN mbm_mdm_classification_part_link
        ON mbm_mdm_part_master.id = mbm_mdm_classification_part_link.part_master_id
            AND mbm_mdm_part_version.id = mbm_mdm_classification_part_link.part_version_id
    LEFT JOIN mbm_mdm_classification
        ON mbm_mdm_classification_part_link.classification_id = mbm_mdm_classification.id
    WHERE mbm_aps_product_order.suggest_start BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
        AND mbm_mdm_classification.root_node = '05km49fd79sgg'
),
tonnage_cte AS (
    SELECT
        mbm_aps_product_order.number,
        mbm_mdm_classification.name AS tonnage_name
    FROM mbm_aps_product_order
    LEFT JOIN mbm_mdm_part_version
        ON mbm_aps_product_order.part_version_id = mbm_mdm_part_version.id
    LEFT JOIN mbm_mdm_part_master
        ON mbm_mdm_part_version.part_master_id = mbm_mdm_part_master.id
    LEFT JOIN mbm_mdm_classification_part_link
        ON mbm_mdm_part_master.id = mbm_mdm_classification_part_link.part_master_id
            AND mbm_mdm_part_version.id = mbm_mdm_classification_part_link.part_version_id
    LEFT JOIN mbm_mdm_classification
        ON mbm_mdm_classification_part_link.classification_id = mbm_mdm_classification.id
    WHERE mbm_aps_product_order.suggest_start BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
        AND mbm_mdm_classification.root_node = 'product_tonnage'
),
base_info AS (
    SELECT
        po.number,
        po.batch_no,
        po.qty,
        pm.name AS material_name,
        oc.order_type
    FROM mbm_aps_product_order po
    LEFT JOIN mbm_aps_order_config oc
        ON po.order_config_id = oc.id
    LEFT JOIN mbm_mdm_part_version pv
        ON po.part_version_id = pv.id
    LEFT JOIN mbm_mdm_part_master pm
        ON pv.part_master_id = pm.id
    WHERE po.suggest_start BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
)
SELECT
    bi.number AS 生产订单号,
    bi.batch_no AS 批次号,
    bi.qty AS 台套数量,
    bi.material_name AS 物料描述,
    bi.order_type AS 订单类型,
    ptc.product_type_name AS 产品类型,
    tc.tonnage_name AS 产品吨位
FROM base_info bi
LEFT JOIN product_type_cte ptc
    ON bi.number = ptc.number
LEFT JOIN tonnage_cte tc
    ON bi.number = tc.number
ORDER BY bi.number;



WITH product_category AS (
    SELECT
        mbm_aps_product_order.number,                          -- 生产订单号
        mbm_aps_product_order.batch_no,                        -- 批次号
        mbm_aps_product_order.qty,                             -- 台套数量
        mbm_mdm_part_master.name AS material_name,             -- 物料描述
        mbm_mdm_classification.name AS product_type_name,      -- 产品类别名称
        mbm_aps_order_config.order_type,                       -- 订单类型
        mbm_mdm_part_master.id AS part_master_id,              -- 保存物料ID
        mbm_mdm_part_version.id AS part_version_id             -- 保存物料版本ID
    FROM mbm_aps_product_order
    LEFT JOIN mbm_aps_order_config
        ON mbm_aps_product_order.order_config_id = mbm_aps_order_config.id
    LEFT JOIN mbm_mdm_part_version
        ON mbm_aps_product_order.part_version_id = mbm_mdm_part_version.id
    LEFT JOIN mbm_mdm_part_master
        ON mbm_mdm_part_version.part_master_id = mbm_mdm_part_master.id
    LEFT JOIN mbm_mdm_classification_part_link
        ON mbm_mdm_part_master.id = mbm_mdm_classification_part_link.part_master_id
            AND mbm_mdm_part_version.id = mbm_mdm_classification_part_link.part_version_id
    LEFT JOIN mbm_mdm_classification
        ON mbm_mdm_classification_part_link.classification_id = mbm_mdm_classification.id
    LEFT JOIN mbm_mdm_classification_set
        ON mbm_mdm_classification_set.id = mbm_mdm_classification.root_node
    WHERE mbm_aps_product_order.suggest_start BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
        AND mbm_mdm_classification.root_node = '05km49fd79sgg'
)
SELECT
    product_category.number,
    product_category.batch_no,
    product_category.qty,
    product_category.material_name,
    product_category.product_type_name,
    product_category.order_type,
    tonnage_classification.name AS tonnage_name
FROM product_category
LEFT JOIN mbm_mdm_classification_part_link AS tonnage_link
    ON product_category.part_master_id = tonnage_link.part_master_id
        AND product_category.part_version_id = tonnage_link.part_version_id
LEFT JOIN mbm_mdm_classification AS tonnage_classification
    ON tonnage_link.classification_id = tonnage_classification.id
        AND tonnage_classification.root_node = 'product_tonnage'
ORDER BY product_category.number;



WITH product_type_cte AS (
    SELECT DISTINCT ON (mbm_aps_product_order.number)
        mbm_aps_product_order.number,
        mbm_mdm_classification.name AS product_type_name
    FROM mbm_aps_product_order
    LEFT JOIN mbm_mdm_part_version
        ON mbm_aps_product_order.part_version_id = mbm_mdm_part_version.id
    LEFT JOIN mbm_mdm_part_master
        ON mbm_mdm_part_version.part_master_id = mbm_mdm_part_master.id
    LEFT JOIN mbm_mdm_classification_part_link
        ON mbm_mdm_part_master.id = mbm_mdm_classification_part_link.part_master_id
            AND mbm_mdm_part_version.id = mbm_mdm_classification_part_link.part_version_id
    LEFT JOIN mbm_mdm_classification
        ON mbm_mdm_classification_part_link.classification_id = mbm_mdm_classification.id
    WHERE mbm_aps_product_order.suggest_start BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
        AND mbm_mdm_classification.root_node = '05km49fd79sgg'
    ORDER BY mbm_aps_product_order.number, mbm_mdm_classification.name
),
tonnage_cte AS (
    SELECT DISTINCT ON (mbm_aps_product_order.number)
        mbm_aps_product_order.number,
        mbm_mdm_classification.name AS tonnage_name
    FROM mbm_aps_product_order
    LEFT JOIN mbm_mdm_part_version
        ON mbm_aps_product_order.part_version_id = mbm_mdm_part_version.id
    LEFT JOIN mbm_mdm_part_master
        ON mbm_mdm_part_version.part_master_id = mbm_mdm_part_master.id
    LEFT JOIN mbm_mdm_classification_part_link
        ON mbm_mdm_part_master.id = mbm_mdm_classification_part_link.part_master_id
            AND mbm_mdm_part_version.id = mbm_mdm_classification_part_link.part_version_id
    LEFT JOIN mbm_mdm_classification
        ON mbm_mdm_classification_part_link.classification_id = mbm_mdm_classification.id
    WHERE mbm_aps_product_order.suggest_start BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
        AND mbm_mdm_classification.root_node = 'product_tonnage'
    ORDER BY mbm_aps_product_order.number, mbm_mdm_classification.name
),
base_info AS (
    SELECT DISTINCT ON (mbm_aps_product_order.number)
        mbm_aps_product_order.number,
        mbm_aps_product_order.batch_no,
        mbm_aps_product_order.qty,
        mbm_mdm_part_master.name AS material_name,
        mbm_aps_order_config.order_type
    FROM mbm_aps_product_order
    LEFT JOIN mbm_aps_order_config
        ON mbm_aps_product_order.order_config_id = mbm_aps_order_config.id
    LEFT JOIN mbm_mdm_part_version
        ON mbm_aps_product_order.part_version_id = mbm_mdm_part_version.id
    LEFT JOIN mbm_mdm_part_master
        ON mbm_mdm_part_version.part_master_id = mbm_mdm_part_master.id
    WHERE mbm_aps_product_order.suggest_start BETWEEN '2025-10-27 00:00:00' AND '2025-11-14 00:00:00'
    ORDER BY mbm_aps_product_order.number
)
SELECT
    base_info.number AS 生产订单号,
    base_info.batch_no AS 批次号,
    base_info.qty AS 台套数量,
    base_info.material_name AS 物料描述,
    base_info.order_type AS 订单类型,
    product_type_cte.product_type_name AS 产品类型,
    tonnage_cte.tonnage_name AS 产品吨位
FROM base_info
LEFT JOIN product_type_cte
    ON base_info.number = product_type_cte.number
LEFT JOIN tonnage_cte
    ON base_info.number = tonnage_cte.number
ORDER BY base_info.number;



select po.number,                 -- 生产订单号
       po.batch_no,               -- 批次号
       po.qty,                    -- 台套数量
       pm.name  as material_name, -- 物料描述
       oc.order_type,

       -- 第一类分类
       max(case
               when c.name in ('伸臂结构', '转台结构', '车架结构', '底盘装配', '整机装配')
                   then c.name
           end) as 产品类型,

       -- 第二类分类
       max(case
               when c.root_node = 'product_tonnage'
                   then c.name
           end) as 产品吨位

from mbm_aps_product_order po

         left join mbm_aps_order_config oc
                   on po.order_config_id = oc.id

         left join mbm_mdm_part_version pv
                   on po.part_version_id = pv.id

         left join mbm_mdm_part_master pm
                   on pv.part_master_id = pm.id

         left join mbm_mdm_classification_part_link cpl
                   on pm.id = cpl.part_master_id
                       and pv.id = cpl.part_version_id

         left join mbm_mdm_classification c
                   on cpl.classification_id = c.id

where po.suggest_start between
          '2025-10-27 00:00:00'
          and '2025-11-14 00:00:00'

group by po.number,
         po.batch_no,
         po.qty,
         pm.name,
         oc.order_type

order by po.number;




---产品类型的id  存在于mbm_mdm_classification.root_node
--产品类型名称 存在于mbm_mdm_classification.name


WITH structure_cte AS (SELECT DISTINCT ON (po.number) po.number,
                                                      c.name AS structure_name
                       FROM mbm_aps_product_order po
                                LEFT JOIN mbm_mdm_part_version pv
                                          ON po.part_version_id = pv.id
                                LEFT JOIN mbm_mdm_part_master pm
                                          ON pv.part_master_id = pm.id
                                LEFT JOIN mbm_mdm_classification_part_link cpl
                                          ON pm.id = cpl.part_master_id
                                              AND pv.id = cpl.part_version_id
                                LEFT JOIN mbm_mdm_classification c
                                          ON cpl.classification_id = c.id
                       WHERE po.suggest_start BETWEEN '2025-10-27 00:00:00'
                           AND '2025-11-14 00:00:00'
                         AND c.name IN ('伸臂结构', '转台结构', '车架结构', '底盘装配', '整机装配')
                       ORDER BY po.number),

     tonnage_cte AS (SELECT DISTINCT ON (po.number) po.number,
                                                    c.name AS tonnage_name
                     FROM mbm_aps_product_order po
                              LEFT JOIN mbm_mdm_part_version pv
                                        ON po.part_version_id = pv.id
                              LEFT JOIN mbm_mdm_part_master pm
                                        ON pv.part_master_id = pm.id
                              LEFT JOIN mbm_mdm_classification_part_link cpl
                                        ON pm.id = cpl.part_master_id
                                            AND pv.id = cpl.part_version_id
                              LEFT JOIN mbm_mdm_classification c
                                        ON cpl.classification_id = c.id
                     WHERE po.suggest_start BETWEEN '2025-10-27 00:00:00'
                         AND '2025-11-14 00:00:00'
                       AND c.root_node = 'product_tonnage'
                     ORDER BY po.number)

SELECT po.number,
       po.batch_no,
       po.qty,
       pm.name                      AS material_name,
       oc.order_type,
       structure_cte.structure_name AS 结构类型,
       tonnage_cte.tonnage_name     AS 产品吨位
FROM mbm_aps_product_order po
         LEFT JOIN mbm_aps_order_config oc
                   ON po.order_config_id = oc.id
         LEFT JOIN mbm_mdm_part_version pv
                   ON po.part_version_id = pv.id
         LEFT JOIN mbm_mdm_part_master pm
                   ON pv.part_master_id = pm.id
         LEFT JOIN structure_cte
                   ON po.number = structure_cte.number
         LEFT JOIN tonnage_cte
                   ON po.number = tonnage_cte.number
WHERE po.suggest_start BETWEEN '2025-10-27 00:00:00'
          AND '2025-11-14 00:00:00'
ORDER BY po.number;



select
    po.number,                 -- 生产订单号
    po.batch_no,               -- 批次号
    po.qty,                    -- 台套数量
    pm.name as material_name,  -- 物料描述
    oc.order_type,             -- 订单类型

    -- 产品类别分类
    max(case
            when c.root_node = '05km49fd79sgg'
            then c.name
        end) as 产品类型,

    -- 吨位分类（修正为正确的root_node）
    max(case
            when c.root_node = 'product_tonnage'
            then c.name
        end) as 产品吨位

from mbm_aps_product_order po

left join mbm_aps_order_config oc
       on po.order_config_id = oc.id

left join mbm_mdm_part_version pv
       on po.part_version_id = pv.id

left join mbm_mdm_part_master pm
       on pv.part_master_id = pm.id

left join mbm_mdm_classification_part_link cpl
       on pm.id = cpl.part_master_id
      and pv.id = cpl.part_version_id

left join mbm_mdm_classification c
       on cpl.classification_id = c.id

where po.suggest_start between
      '2025-10-27 00:00:00'
      and '2025-11-14 00:00:00'

group by
    po.number,
    po.batch_no,
    po.qty,
    pm.name,
    oc.order_type

order by po.number;










WITH base_data AS (SELECT po.number AS production_order_number,
                          po.batch_no,
                          po.qty,
                          po.suggest_start,
                          po.suggest_end,
                          po.actual_start,
                          po.actual_end,
                          pm.name   AS material_description,
                          oc.order_type,
                          pv.part_number,
                          wam.source_system_number,
                          wam.name  AS work_area_name,

                          -- 吨位
                          MAX(c.name) FILTER (
                              WHERE c.root_node = 'product_tonnage'
                              )     AS tonnage,

                          -- 结构类型（直接来自 classification）
                          MAX(c.name) FILTER (
                              WHERE c.name IN ('伸臂结构', '转台结构', '车架结构', '底盘装配', '整机装配')
                              )     AS product_type,

                          -- 物料前缀
                          CASE
                              WHEN POSITION('.' IN pv.part_number) > 0 THEN
                                  SUBSTRING(pv.part_number FROM 1
                                            FOR POSITION('.' IN pv.part_number) - 1)
                              ELSE pv.part_number
                              END   AS material_prefix

                   FROM mbm_aps_product_order po

                            LEFT JOIN mbm_mdm_part_version pv
                                      ON po.part_version_id = pv.id

                            LEFT JOIN mbm_mdm_part_master pm
                                      ON pv.part_master_id = pm.id

                            LEFT JOIN mbm_aps_order_config oc
                                      ON po.order_config_id = oc.id

                            LEFT JOIN mbm_mdm_work_area_version wav
                                      ON po.work_segment_id = wav.id

                            LEFT JOIN mbm_mdm_work_area_master wam
                                      ON wav.work_area_master_id = wam.id

                            LEFT JOIN mbm_mdm_classification_part_link cpl
                                      ON pm.id = cpl.part_master_id
                                          AND pv.id = cpl.part_version_id

                            LEFT JOIN mbm_mdm_classification c
                                      ON cpl.classification_id = c.id

                   WHERE po.suggest_start BETWEEN
                             '2025-10-27 00:00:00'
                             AND '2025-11-14 00:00:00'

                   GROUP BY po.number,
                            po.batch_no,
                            po.qty,
                            po.suggest_start,
                            po.suggest_end,
                            po.actual_start,
                            po.actual_end,
                            pm.name,
                            oc.order_type,
                            pv.part_number,
                            wam.source_system_number,
                            wam.name)

SELECT base_data.*,

       CASE
           WHEN base_data.order_type = 'Z004' THEN '备件计划'
           WHEN base_data.order_type IN ('Z001', 'Z002')
               AND base_data.work_area_name LIKE '%轮胎吊%' THEN '轮胎吊'
           WHEN base_data.order_type IN ('Z001', 'Z002')
               AND base_data.tonnage ~ '^[0-9]+(\.[0-9]+)?$'
               THEN
               CASE
                   WHEN base_data.tonnage::numeric >= 5
                       AND base_data.tonnage::numeric < 60 THEN '中小吨位'
                   WHEN base_data.tonnage::numeric >= 60
                       AND base_data.tonnage::numeric <= 130 THEN '中大吨位'
                   WHEN base_data.tonnage::numeric > 130
                       AND base_data.tonnage::numeric <= 500 THEN '大吨位'
                   WHEN base_data.tonnage::numeric > 500 THEN '超大吨位'
                   ELSE '未知吨位'
                   END
           ELSE NULL
           END AS plan_type,

       CASE
           WHEN base_data.product_type = '整机装配'
               THEN base_data.material_prefix
           ELSE NULL
           END AS material_code,

       xp.product_model

FROM base_data

         LEFT JOIN mbm_mdm_xcmg_product xp
                   ON base_data.product_type = '整机装配'
                       AND xp.material_number = base_data.material_prefix;



SELECT po.number
FROM mbm_aps_product_order po
LEFT JOIN mbm_mdm_part_version pv ON po.part_version_id = pv.id
LEFT JOIN mbm_mdm_part_master pm ON pv.part_master_id = pm.id
LEFT JOIN mbm_mdm_classification_part_link cpl
       ON pm.id = cpl.part_master_id
      AND pv.id = cpl.part_version_id
LEFT JOIN mbm_mdm_classification c ON cpl.classification_id = c.id
WHERE po.suggest_start >= TIMESTAMP '2025-10-27 00:00:00'
  AND po.suggest_start < TIMESTAMP '2025-11-15 00:00:00'
GROUP BY po.number
HAVING MAX(CASE WHEN c.name IN ('伸臂结构', '转台结构', '车架结构', '底盘装配', '整机装配') THEN 1 ELSE 0 END) = 0;


WITH classification_agg AS (
    -- 对物料分类提前聚合
    SELECT
        cpl.part_master_id,
        cpl.part_version_id,
        MAX(CASE WHEN c.root_node = 'product_tonnage' THEN c.name END) AS tonnage,
        MAX(CASE WHEN c.name IN ('伸臂结构','转台结构','车架结构','底盘装配','整机装配') THEN c.name END) AS product_type
    FROM mbm_mdm_classification_part_link cpl
    JOIN mbm_mdm_classification c ON cpl.classification_id = c.id
    WHERE c.root_node = 'product_tonnage'
       OR c.name IN ('伸臂结构','转台结构','车架结构','底盘装配','整机装配')
    GROUP BY cpl.part_master_id, cpl.part_version_id
)

SELECT
    po.number AS production_order_number,
    po.batch_no,
    po.qty,
    po.suggest_start,
    po.suggest_end,
    po.actual_start,
    po.actual_end,
    pm.name AS material_description,
    oc.order_type,
    pv.part_number,
    split_part(wam.source_system_number, '-', 1) AS source_system_number,
    wam.name AS work_area_name,
    ca.tonnage,
    ca.product_type,
    split_part(pv.part_number, '.', 1) AS material_prefix,

    -- 计划类型
    CASE
        WHEN oc.order_type = 'Z004' THEN '备件计划'
        WHEN oc.order_type IN ('Z001','Z002') AND wam.name LIKE '%轮胎吊%' THEN '轮胎吊'
        WHEN oc.order_type IN ('Z001','Z002') AND ca.tonnage ~ '^[0-9]+(\.[0-9]+)?$' THEN
            CASE
                WHEN ca.tonnage::numeric >= 5 AND ca.tonnage::numeric < 60 THEN '中小吨位'
                WHEN ca.tonnage::numeric >= 60 AND ca.tonnage::numeric <= 130 THEN '中大吨位'
                WHEN ca.tonnage::numeric > 130 AND ca.tonnage::numeric <= 500 THEN '大吨位'
                WHEN ca.tonnage::numeric > 500 THEN '超大吨位'
                ELSE '未知吨位'
            END
        ELSE NULL
    END AS plan_type,

    -- 整机装配物料代码
    CASE
        WHEN ca.product_type = '整机装配' THEN split_part(pv.part_number, '.', 1)
        ELSE NULL
    END AS material_code,

    xp.product_model

FROM mbm_aps_product_order po
LEFT JOIN mbm_mdm_part_version pv ON po.part_version_id = pv.id
LEFT JOIN mbm_mdm_part_master pm ON pv.part_master_id = pm.id
LEFT JOIN mbm_aps_order_config oc ON po.order_config_id = oc.id
LEFT JOIN mbm_mdm_work_area_version wav ON po.work_segment_id = wav.id
LEFT JOIN mbm_mdm_work_area_master wam ON wav.work_area_master_id = wam.id
LEFT JOIN classification_agg ca
       ON pm.id = ca.part_master_id
      AND pv.id = ca.part_version_id
LEFT JOIN mbm_mdm_xcmg_product xp
       ON ca.product_type = '整机装配'
      AND xp.material_number = split_part(pv.part_number, '.', 1)

WHERE po.suggest_start >= TIMESTAMP '2025-10-27 00:00:00'
  AND po.suggest_start < TIMESTAMP '2025-11-15 00:00:00'

ORDER BY po.number;





WITH classification_agg AS (
    -- 对物料分类提前聚合，减少 JOIN 重复
    SELECT
        cpl.part_master_id,
        cpl.part_version_id,
        MAX(CASE WHEN c.root_node = 'product_tonnage' THEN c.name END) AS tonnage,
        MAX(CASE WHEN c.name IN ('伸臂结构','转台结构','车架结构','底盘装配','整机装配') THEN c.name END) AS product_type
    FROM mbm_mdm_classification_part_link cpl
    JOIN mbm_mdm_classification c
        ON cpl.classification_id = c.id
    WHERE c.root_node = 'product_tonnage'
       OR c.name IN ('伸臂结构','转台结构','车架结构','底盘装配','整机装配')
    GROUP BY cpl.part_master_id, cpl.part_version_id
)

SELECT
    po.number AS production_order_number,
    po.batch_no,
    po.qty,
    po.suggest_start,
    po.suggest_end,
    po.actual_start,
    po.actual_end,

    pm.name AS material_description,

    -- 新增物料分类字段
    CASE
        WHEN pm.name LIKE '%转台主体%' THEN 1
        WHEN pm.name LIKE '%基本臂结构%' THEN 2
        WHEN pm.name LIKE '%车架%' AND pm.name NOT LIKE '%车架后端%' THEN 3
        ELSE NULL
    END AS material_category,

    oc.order_type,
    pv.part_number,

    -- 优化 source_system_number
    split_part(wam.source_system_number, '-', 1) AS source_system_number,
    wam.name AS work_area_name,

    ca.tonnage,
    ca.product_type,

    -- 物料前缀
    split_part(pv.part_number, '.', 1) AS material_prefix,

    -- 计划类型
    CASE
        WHEN oc.order_type = 'Z004' THEN '备件计划'
        WHEN oc.order_type IN ('Z001','Z002') AND wam.name LIKE '%轮胎吊%' THEN '轮胎吊'
        WHEN oc.order_type IN ('Z001','Z002') AND ca.tonnage ~ '^[0-9]+(\.[0-9]+)?$' THEN
            CASE
                WHEN ca.tonnage::numeric >= 5 AND ca.tonnage::numeric < 60 THEN '中小吨位'
                WHEN ca.tonnage::numeric >= 60 AND ca.tonnage::numeric <= 130 THEN '中大吨位'
                WHEN ca.tonnage::numeric > 130 AND ca.tonnage::numeric <= 500 THEN '大吨位'
                WHEN ca.tonnage::numeric > 500 THEN '超大吨位'
                ELSE '未知吨位'
            END
        ELSE NULL
    END AS plan_type,

    -- 整机装配物料代码
    CASE
        WHEN ca.product_type = '整机装配' THEN split_part(pv.part_number, '.', 1)
        ELSE NULL
    END AS material_code,

    xp.product_model

FROM mbm_aps_product_order po
LEFT JOIN mbm_mdm_part_version pv
       ON po.part_version_id = pv.id
LEFT JOIN mbm_mdm_part_master pm
       ON pv.part_master_id = pm.id
LEFT JOIN mbm_aps_order_config oc
       ON po.order_config_id = oc.id
LEFT JOIN mbm_mdm_work_area_version wav
       ON po.work_segment_id = wav.id
LEFT JOIN mbm_mdm_work_area_master wam
       ON wav.work_area_master_id = wam.id
LEFT JOIN classification_agg ca
       ON pm.id = ca.part_master_id
      AND pv.id = ca.part_version_id
LEFT JOIN mbm_mdm_xcmg_product xp
       ON ca.product_type = '整机装配'
      AND xp.material_number = split_part(pv.part_number, '.', 1)

WHERE po.suggest_start >= TIMESTAMP '2025-10-27 00:00:00'
  AND po.suggest_start < TIMESTAMP '2025-11-15 00:00:00'

ORDER BY po.number;



select *
from mbm_mdm_classification
    where root_node = 'process-zj'
;
select *
from mbm_mdm_classification
    where name IN ('伸臂结构','转台结构','车架结构','底盘装配','整机装配')
;


select *
from mbm_mdm_classification_set
where id = 'process';