select mmpm.*
from mbm_aps_process_tech_order mapto
left join mbm_mdm_part_version mmpv on mapto.part_version_id = mmpv.id
left join mbm_mdm_part_master mmpm on mmpv.part_master_id = mmpm.id
limit 1;


SELECT
       t.number                                              AS number,
       t__partVersion__partMaster.number                     AS itemNumber,
       t__factory__workAreaMaster.source_system_number       AS factoryNumber,
       t__branchFactory__workAreaMaster.source_system_number AS branchFactoryNumber,
       t__workSegment__workAreaMaster.source_system_number   AS workSegmentNumber,
       t__factory__workAreaMaster.name                       AS factoryName,
       pto.work_center_id                                    AS workCenterId,
       m.number                                              AS workCenterNumber
FROM
        mbm_aps_process_tech_order pto
        left join mbm_mdm_work_area_version mmwav on pto.work_center_id = mmwav.id and mmwav.delete_flag != '1'
        left join public.mbm_mdm_work_area_master m on mmwav.work_area_master_id = m.id and m.delete_flag != '1'
        LEFT JOIN mbm_aps_product_order t on pto.product_order_id = t.id and t.delete_flag != '1'
         -- 分支工厂 (version → master)
         LEFT JOIN mbm_mdm_work_area_version t__branchFactory
                   ON t.branch_factory_id = t__branchFactory.id
                      AND (t__branchFactory.delete_flag != '1' OR t__branchFactory.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_work_area_master t__branchFactory__workAreaMaster
                   ON t__branchFactory.work_area_master_id = t__branchFactory__workAreaMaster.id
                      AND (t__branchFactory__workAreaMaster.delete_flag != '1' OR t__branchFactory__workAreaMaster.delete_flag IS NULL)
         -- 工段 (version → master)
         LEFT JOIN mbm_mdm_work_area_version t__workSegment
                   ON t.work_segment_id = t__workSegment.id
                      AND (t__workSegment.delete_flag != '1' OR t__workSegment.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_work_area_master t__workSegment__workAreaMaster
                   ON t__workSegment.work_area_master_id = t__workSegment__workAreaMaster.id
                      AND (t__workSegment__workAreaMaster.delete_flag != '1' OR t__workSegment__workAreaMaster.delete_flag IS NULL)
         -- 物料版本 → 物料主数据
         LEFT JOIN mbm_mdm_part_version t__partVersion
                   ON t.part_version_id = t__partVersion.id
                      AND (t__partVersion.delete_flag != '1' OR t__partVersion.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_part_master t__partVersion__partMaster
                   ON t__partVersion.part_master_id = t__partVersion__partMaster.id
                      AND (t__partVersion__partMaster.delete_flag != '1' OR t__partVersion__partMaster.delete_flag IS NULL)
         -- 工厂 (version → master)
         LEFT JOIN mbm_mdm_work_area_version t__factory
                   ON t.factory_id = t__factory.id
                      AND (t__factory.delete_flag != '1' OR t__factory.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_work_area_master t__factory__workAreaMaster
                   ON t__factory.work_area_master_id = t__factory__workAreaMaster.id
                      AND (t__factory__workAreaMaster.delete_flag != '1' OR t__factory__workAreaMaster.delete_flag IS NULL)
WHERE 1 = 1
  AND (t.delete_flag != '1' OR t.delete_flag IS NULL);



select m.*
from mbm_aps_process_tech_order pto
left join mbm_mdm_work_area_version mmwav on pto.work_center_id = mmwav.id
left join mbm_mdm_operation_master m on mmwav.work_area_master_id = m.id
;

select
    *
from mbm_mdm_work_area_master



WITH batch_conditions (branch_factory_number, work_segment_number, work_center_number) AS (VALUES ('LBJ', 'LBJ-01',
                                                                                                   '1A01'),
                                                                                                  ('LBJ', 'LBJ-01',
                                                                                                   '1A02'),
                                                                                                  ('LBJ', 'LBJ-01',
                                                                                                   '1A03'),
                                                                                                  ('LBJ', 'LBJ-01',
                                                                                                   '1A10'),
                                                                                                  ('LBJ', 'LBJ-01',
                                                                                                   '1A11'),
                                                                                                  ('LBJ', 'LBJ-01',
                                                                                                   '1A30'),
                                                                                                  ('JG1', 'JG1-01',
                                                                                                   '1C80'),
                                                                                                  ('JG1', 'JG1-02',
                                                                                                   '1C84'),
                                                                                                  ('JG1', 'JG1-03',
                                                                                                   '1CD6'),
                                                                                                  ('JG1', 'JG1-04',
                                                                                                   '1C46'),
                                                                                                  ('JG1', 'JG1-05',
                                                                                                   '1C06'),
                                                                                                  ('JG1', 'JG1-06',
                                                                                                   '1CE6'),
                                                                                                  ('JG1', 'JG1-07',
                                                                                                   '1CE5'),
                                                                                                  ('JG1', 'JG1-08',
                                                                                                   '1C92'),
                                                                                                  ('JG1', 'JG1-09',
                                                                                                   '1C21'),
                                                                                                  ('JG1', 'JG1-09',
                                                                                                   '1C24'),
                                                                                                  ('JG1', 'JG1-10',
                                                                                                   '1C25'),
                                                                                                  ('JG1', 'JG1-10',
                                                                                                   '1C28'),
                                                                                                  ('JG1', 'JG1-11',
                                                                                                   '1CC5'),
                                                                                                  ('JG1', 'JG1-12',
                                                                                                   '1C89'),
                                                                                                  ('JG1', 'JG1-13',
                                                                                                   '1CG4'),
                                                                                                  ('JG1', 'JG1-15',
                                                                                                   '1CJQ'),
                                                                                                  ('JG1', 'JG1-16',
                                                                                                   '1CHL'),
                                                                                                  ('TZ', 'TZ-03',
                                                                                                   '1F03'),
                                                                                                  ('TZ', 'TZ-04',
                                                                                                   '1F04'),
                                                                                                  ('TZ', 'TZ-05',
                                                                                                   '1F04'),
                                                                                                  ('TZ', 'TZ-06',
                                                                                                   '1F13'),
                                                                                                  ('ZP1', 'ZP1-01',
                                                                                                   '7100'),
                                                                                                  ('ZP1', 'ZP1-02',
                                                                                                   '7200'),
                                                                                                  ('ZP1', 'ZP1-03',
                                                                                                   '5100'),
                                                                                                  ('ZP1', 'ZP1-05',
                                                                                                   '7400'),
                                                                                                  ('ZP1', 'ZP1-06',
                                                                                                   '7500'),
                                                                                                  ('ZP1', 'ZP1-08',
                                                                                                   '7700'),
                                                                                                  ('ZP1', 'ZP1-09',
                                                                                                   '7800')),
-- ✅ 优化1: 提前过滤工艺路线，减少后续JOIN的数据量
     filtered_pto AS (SELECT pto.id, pto.work_center_id, pto.product_order_id, pto.is_end_node
                      FROM mbm_aps_process_tech_order pto
                      WHERE pto.is_end_node = '1'
                        AND (pto.delete_flag != '1' OR pto.delete_flag IS NULL))
SELECT t.number                         AS number,
       mspt.sn                          AS sn,
       pm.number                        AS itemNumber,
       factory_wam.source_system_number AS factoryNumber,
       branch_wam.source_system_number  AS branchFactoryNumber,
       segment_wam.source_system_number AS workSegmentNumber,
       factory_wam.name                 AS factoryName,
       fp.work_center_id                AS workCenterId,
       wc_m.number                      AS workCenterNumber,
       fp.is_end_node                   AS isEndNode
FROM filtered_pto fp
         -- ✅ 优化2: 工作中心主数据提前关联并过滤
         INNER JOIN mbm_mdm_work_area_version wc_v
                    ON fp.work_center_id = wc_v.id
                        AND (wc_v.delete_flag != '1' OR wc_v.delete_flag IS NULL)
         INNER JOIN mbm_mdm_work_area_master wc_m
                    ON wc_v.work_area_master_id = wc_m.id
                        AND (wc_m.delete_flag != '1' OR wc_m.delete_flag IS NULL)
    -- ✅ 优化3: 生产订单提前关联并过滤
         INNER JOIN mbm_aps_product_order t
                    ON fp.product_order_id = t.id
                        AND (t.delete_flag != '1' OR t.delete_flag IS NULL)
    -- ✅ 优化4: 批量条件尽早过滤，大幅减少后续LEFT JOIN的行数

    -- 以下LEFT JOIN仅对已过滤的小数据集执行
         LEFT JOIN mbm_mes_process_tech_order_id mpto
                   ON fp.id = mpto.mes_process_tech_order_id
         LEFT JOIN mbm_mes_single_piece_id mspt
                   ON mpto.single_piece_id = mspt.id
    -- 分支工厂
         LEFT JOIN mbm_mdm_work_area_version branch_v
                   ON t.branch_factory_id = branch_v.id
                       AND (branch_v.delete_flag != '1' OR branch_v.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_work_area_master branch_wam
                   ON branch_v.work_area_master_id = branch_wam.id
                       AND (branch_wam.delete_flag != '1' OR branch_wam.delete_flag IS NULL)
                       AND branch_wam.source_system_number = bc.branch_factory_number -- ✅ 冗余条件帮助优化器
    -- 工段
         LEFT JOIN mbm_mdm_work_area_version segment_v
                   ON t.work_segment_id = segment_v.id
                       AND (segment_v.delete_flag != '1' OR segment_v.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_work_area_master segment_wam
                   ON segment_v.work_area_master_id = segment_wam.id
                       AND (segment_wam.delete_flag != '1' OR segment_wam.delete_flag IS NULL)
                       AND segment_wam.source_system_number = bc.work_segment_number -- ✅ 冗余条件帮助优化器
    -- 物料
         LEFT JOIN mbm_mdm_part_version pv
                   ON t.part_version_id = pv.id
                       AND (pv.delete_flag != '1' OR pv.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_part_master pm
                   ON pv.part_master_id = pm.id
                       AND (pm.delete_flag != '1' OR pm.delete_flag IS NULL)
    -- 工厂
         LEFT JOIN mbm_mdm_work_area_version factory_v
                   ON t.factory_id = factory_v.id
                       AND (factory_v.delete_flag != '1' OR factory_v.delete_flag IS NULL)
         LEFT JOIN mbm_mdm_work_area_master factory_wam
                   ON factory_v.work_area_master_id = factory_wam.id
                       AND (factory_wam.delete_flag != '1' OR factory_wam.delete_flag IS NULL)
         INNER JOIN batch_conditions bc
                    ON wc_m.number = bc.work_center_number
                        and bc.work_segment_number = segment_wam.source_system_number
                        and bc.branch_factory_number = branch_wam.source_system_number;



select *
from mbm_mdm_work_area_version




WITH batch_conditions (branch_factory_number, work_segment_number, work_center_number) AS (
    VALUES
        ('LBJ', 'LBJ-01', '1A01'), ('LBJ', 'LBJ-01', '1A02'), ('LBJ', 'LBJ-01', '1A03'),
        ('LBJ', 'LBJ-01', '1A10'), ('LBJ', 'LBJ-01', '1A11'), ('LBJ', 'LBJ-01', '1A30'),
        ('JG1', 'JG1-01', '1C80'), ('JG1', 'JG1-02', '1C84'), ('JG1', 'JG1-03', '1CD6'),
        ('JG1', 'JG1-04', '1C46'), ('JG1', 'JG1-05', '1C06'), ('JG1', 'JG1-06', '1CE6'),
        ('JG1', 'JG1-07', '1CE5'), ('JG1', 'JG1-08', '1C92'), ('JG1', 'JG1-09', '1C21'),
        ('JG1', 'JG1-09', '1C24'), ('JG1', 'JG1-10', '1C25'), ('JG1', 'JG1-10', '1C28'),
        ('JG1', 'JG1-11', '1CC5'), ('JG1', 'JG1-12', '1C89'), ('JG1', 'JG1-13', '1CG4'),
        ('JG1', 'JG1-15', '1CJQ'), ('JG1', 'JG1-16', '1CHL'),
        ('TZ',  'TZ-03',  '1F03'), ('TZ',  'TZ-04',  '1F04'), ('TZ',  'TZ-05',  '1F04'),
        ('TZ',  'TZ-06',  '1F13'),
        ('ZP1', 'ZP1-01', '7100'), ('ZP1', 'ZP1-02', '7200'), ('ZP1', 'ZP1-03', '5100'),
        ('ZP1', 'ZP1-05', '7400'), ('ZP1', 'ZP1-06', '7500'), ('ZP1', 'ZP1-08', '7700'),
        ('ZP1', 'ZP1-09', '7800')
),
filtered_pto AS (
    SELECT pto.id, pto.work_center_id, pto.product_order_id, pto.is_end_node
    FROM mbm_aps_process_tech_order pto
    WHERE pto.is_end_node = '1'
      AND (pto.delete_flag != '1' OR pto.delete_flag IS NULL)
)
SELECT
    t.number                                              AS number,
    mspt.sn                                               AS sn,
    pm.number                                             AS itemNumber,
    factory_wam.source_system_number                      AS factoryNumber,
    branch_wam.source_system_number                       AS branchFactoryNumber,
    segment_wam.source_system_number                      AS workSegmentNumber,
    factory_wam.name                                      AS factoryName,
    fp.work_center_id                                     AS workCenterId,
    wc_m.number                                           AS workCenterNumber,
    fp.is_end_node                                        AS isEndNode
FROM filtered_pto fp
    -- 1. 工作中心
    INNER JOIN mbm_mdm_work_area_version wc_v
        ON fp.work_center_id = wc_v.id
       AND (wc_v.delete_flag != '1' OR wc_v.delete_flag IS NULL)
    INNER JOIN mbm_mdm_work_area_master wc_m
        ON wc_v.work_area_master_id = wc_m.id
       AND (wc_m.delete_flag != '1' OR wc_m.delete_flag IS NULL)
    -- 2. 生产订单
    INNER JOIN mbm_aps_product_order t
        ON fp.product_order_id = t.id
       AND (t.delete_flag != '1' OR t.delete_flag IS NULL)
    -- ✅ 3. 批量条件提前到这里（解决报错 + 尽早收敛数据）
    INNER JOIN batch_conditions bc
        ON wc_m.number = bc.work_center_number
    -- 4. 以下 LEFT JOIN 仅对已过滤的小数据集执行
    LEFT JOIN mbm_mes_process_tech_order_id mpto
        ON fp.id = mpto.mes_process_tech_order_id
    LEFT JOIN mbm_mes_single_piece_id mspt
        ON mpto.single_piece_id = mspt.id
    -- 分支工厂
    LEFT JOIN mbm_mdm_work_area_version branch_v
        ON t.branch_factory_id = branch_v.id
       AND (branch_v.delete_flag != '1' OR branch_v.delete_flag IS NULL)
    LEFT JOIN mbm_mdm_work_area_master branch_wam
        ON branch_v.work_area_master_id = branch_wam.id
       AND (branch_wam.delete_flag != '1' OR branch_wam.delete_flag IS NULL)
       AND branch_wam.source_system_number = bc.branch_factory_number
    -- 工段
    LEFT JOIN mbm_mdm_work_area_version segment_v
        ON t.work_segment_id = segment_v.id
       AND (segment_v.delete_flag != '1' OR segment_v.delete_flag IS NULL)
    LEFT JOIN mbm_mdm_work_area_master segment_wam
        ON segment_v.work_area_master_id = segment_wam.id
       AND (segment_wam.delete_flag != '1' OR segment_wam.delete_flag IS NULL)
       AND segment_wam.source_system_number = bc.work_segment_number
    -- 物料
    LEFT JOIN mbm_mdm_part_version pv
        ON t.part_version_id = pv.id
       AND (pv.delete_flag != '1' OR pv.delete_flag IS NULL)
    LEFT JOIN mbm_mdm_part_master pm
        ON pv.part_master_id = pm.id
       AND (pm.delete_flag != '1' OR pm.delete_flag IS NULL)
    -- 工厂
    LEFT JOIN mbm_mdm_work_area_version factory_v
        ON t.factory_id = factory_v.id
       AND (factory_v.delete_flag != '1' OR factory_v.delete_flag IS NULL)
    LEFT JOIN mbm_mdm_work_area_master factory_wam
        ON factory_v.work_area_master_id = factory_wam.id
       AND (factory_wam.delete_flag != '1' OR factory_wam.delete_flag IS NULL);





WITH batch_conditions (branch_factory_number, work_segment_number, work_center_number) AS (
    VALUES
        ('LBJ', 'LBJ-01', '1A01'), ('LBJ', 'LBJ-01', '1A02'), ('LBJ', 'LBJ-01', '1A03'),
        ('LBJ', 'LBJ-01', '1A10'), ('LBJ', 'LBJ-01', '1A11'), ('LBJ', 'LBJ-01', '1A30'),
        ('JG1', 'JG1-01', '1C80'), ('JG1', 'JG1-02', '1C84'), ('JG1', 'JG1-03', '1CD6'),
        ('JG1', 'JG1-04', '1C46'), ('JG1', 'JG1-05', '1C06'), ('JG1', 'JG1-06', '1CE6'),
        ('JG1', 'JG1-07', '1CE5'), ('JG1', 'JG1-08', '1C92'), ('JG1', 'JG1-09', '1C21'),
        ('JG1', 'JG1-09', '1C24'), ('JG1', 'JG1-10', '1C25'), ('JG1', 'JG1-10', '1C28'),
        ('JG1', 'JG1-11', '1CC5'), ('JG1', 'JG1-12', '1C89'), ('JG1', 'JG1-13', '1CG4'),
        ('JG1', 'JG1-15', '1CJQ'), ('JG1', 'JG1-16', '1CHL'),
        ('TZ',  'TZ-03',  '1F03'), ('TZ',  'TZ-04',  '1F04'), ('TZ',  'TZ-05',  '1F04'),
        ('TZ',  'TZ-06',  '1F13'),
        ('ZP1', 'ZP1-01', '7100'), ('ZP1', 'ZP1-02', '7200'), ('ZP1', 'ZP1-03', '5100'),
        ('ZP1', 'ZP1-05', '7400'), ('ZP1', 'ZP1-06', '7500'), ('ZP1', 'ZP1-08', '7700'),
        ('ZP1', 'ZP1-09', '7800')
),
filtered_pto AS (
    SELECT pto.id, pto.work_center_id, pto.product_order_id, pto.is_end_node
    FROM mbm_aps_process_tech_order pto
    WHERE pto.is_end_node = '1'
      AND (pto.delete_flag != '1' OR pto.delete_flag IS NULL)
)
SELECT
    t.number                                              AS number,
    mspt.sn                                               AS sn,
    pm.number                                             AS itemNumber,
    factory_wam.source_system_number                      AS factoryNumber,
    branch_wam.source_system_number                       AS branchFactoryNumber,
    segment_wam.source_system_number                      AS workSegmentNumber,
    factory_wam.name                                      AS factoryName,
    fp.work_center_id                                     AS workCenterId,
    wc_m.number                                           AS workCenterNumber,
    fp.is_end_node                                        AS isEndNode
FROM filtered_pto fp
    -- 1. 工作中心
    INNER JOIN mbm_mdm_work_area_version wc_v
        ON fp.work_center_id = wc_v.id
       AND (wc_v.delete_flag != '1' OR wc_v.delete_flag IS NULL)
    INNER JOIN mbm_mdm_work_area_master wc_m
        ON wc_v.work_area_master_id = wc_m.id
       AND (wc_m.delete_flag != '1' OR wc_m.delete_flag IS NULL)
    -- 2. 生产订单
    INNER JOIN mbm_aps_product_order t
        ON fp.product_order_id = t.id
       AND (t.delete_flag != '1' OR t.delete_flag IS NULL)
    -- ✅ 3. 分支工厂 & 工段 提前到 bc 之前（解决引用顺序问题）
    LEFT JOIN mbm_mdm_work_area_version branch_v
        ON t.branch_factory_id = branch_v.id
       AND (branch_v.delete_flag != '1' OR branch_v.delete_flag IS NULL)
    LEFT JOIN mbm_mdm_work_area_master branch_wam
        ON branch_v.work_area_master_id = branch_wam.id
       AND (branch_wam.delete_flag != '1' OR branch_wam.delete_flag IS NULL)
    LEFT JOIN mbm_mdm_work_area_version segment_v
        ON t.work_segment_id = segment_v.id
       AND (segment_v.delete_flag != '1' OR segment_v.delete_flag IS NULL)
    LEFT JOIN mbm_mdm_work_area_master segment_wam
        ON segment_v.work_area_master_id = segment_wam.id
       AND (segment_wam.delete_flag != '1' OR segment_wam.delete_flag IS NULL)
    -- ✅ 4. 三个条件统一在 INNER JOIN 中完成精确过滤
    INNER JOIN batch_conditions bc
        ON  wc_m.number                  = bc.work_center_number
        AND branch_wam.source_system_number = bc.branch_factory_number
        AND segment_wam.source_system_number = bc.work_segment_number
    -- 5. 其余 LEFT JOIN（仅对已过滤的小数据集执行）
    LEFT JOIN mbm_mes_process_tech_order_id mpto
        ON fp.id = mpto.mes_process_tech_order_id
    LEFT JOIN mbm_mes_single_piece_id mspt
        ON mpto.single_piece_id = mspt.id
    -- 物料
    LEFT JOIN mbm_mdm_part_version pv
        ON t.part_version_id = pv.id
       AND (pv.delete_flag != '1' OR pv.delete_flag IS NULL)
    LEFT JOIN mbm_mdm_part_master pm
        ON pv.part_master_id = pm.id
       AND (pm.delete_flag != '1' OR pm.delete_flag IS NULL)
    -- 工厂
    LEFT JOIN mbm_mdm_work_area_version factory_v
        ON t.factory_id = factory_v.id
       AND (factory_v.delete_flag != '1' OR factory_v.delete_flag IS NULL)
    LEFT JOIN mbm_mdm_work_area_master factory_wam
        ON factory_v.work_area_master_id = factory_wam.id
       AND (factory_wam.delete_flag != '1' OR factory_wam.delete_flag IS NULL);
