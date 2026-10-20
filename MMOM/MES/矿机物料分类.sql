WITH src(set_name, cls_name, cls_number, part_number) AS (
    VALUES
      ('产品类别', '大挖机型',    NULL,   '316604270'),
      ('产品型号', 'XE990F.00II', NULL,   '316604270'),
      ('产品型号', 'XE990F.00II', NULL,   '316604270.10'),
      ('产品型号', 'XE990F.00II', NULL,   '316604270.20'),
      ('产品型号', 'XE990F.00II', NULL,   '316604270.30'),
      ('库存类别', 'HALB 半成品', 'HALB', '316604270.30'),
      ('库存类别', 'HALB 半成品', 'HALB', '316604270.20'),
      ('库存类别', 'FERT 成品',   'FERT', '316604270.10'),
      ('库存类别', 'FERT 成品',   'FERT', '316604270'),
      ('产品吨位', '95',          NULL,   '316604270'),
      ('产品吨位', '95',          NULL,   '316604270.10'),
      ('产品吨位', '95',          NULL,   '316604270.20'),
      ('产品吨位', '95',          NULL,   '316604270.30')
)
SELECT s.set_name,
       EXISTS (SELECT 1 FROM mbm_mdm_classification_set cs
                WHERE cs.name = s.set_name AND cs.delete_flag = '0')          AS set_exists,
       s.cls_name,
       EXISTS (SELECT 1 FROM mbm_mdm_classification c
                 JOIN mbm_mdm_classification_set cs ON cs.id = c.root_node
                WHERE cs.name = s.set_name AND c.name = s.cls_name
                  AND c.business_type = '0' AND c.delete_flag = '0')           AS cls_exists,
       s.part_number,
       EXISTS (SELECT 1 FROM mbm_mdm_part_version pv
                WHERE pv.part_number = s.part_number AND pv.delete_flag = '0') AS part_exists
FROM (SELECT DISTINCT set_name, cls_name, part_number FROM src) s
ORDER BY 1, 3, 5;
/*
[
  {
    "set_name": "产品吨位",
    "set_exists": true,
    "cls_name": "95",
    "cls_exists": true,
    "part_number": "316604270",
    "part_exists": true
  },
  {
    "set_name": "产品吨位",
    "set_exists": true,
    "cls_name": "95",
    "cls_exists": true,
    "part_number": "316604270.10",
    "part_exists": true
  },
  {
    "set_name": "产品吨位",
    "set_exists": true,
    "cls_name": "95",
    "cls_exists": true,
    "part_number": "316604270.20",
    "part_exists": true
  },
  {
    "set_name": "产品吨位",
    "set_exists": true,
    "cls_name": "95",
    "cls_exists": true,
    "part_number": "316604270.30",
    "part_exists": true
  },
  {
    "set_name": "产品型号",
    "set_exists": true,
    "cls_name": "XE990F.00II",
    "cls_exists": false,
    "part_number": "316604270",
    "part_exists": true
  },
  {
    "set_name": "产品型号",
    "set_exists": true,
    "cls_name": "XE990F.00II",
    "cls_exists": false,
    "part_number": "316604270.10",
    "part_exists": true
  },
  {
    "set_name": "产品型号",
    "set_exists": true,
    "cls_name": "XE990F.00II",
    "cls_exists": false,
    "part_number": "316604270.20",
    "part_exists": true
  },
  {
    "set_name": "产品型号",
    "set_exists": true,
    "cls_name": "XE990F.00II",
    "cls_exists": false,
    "part_number": "316604270.30",
    "part_exists": true
  },
  {
    "set_name": "产品类别",
    "set_exists": true,
    "cls_name": "大挖机型",
    "cls_exists": true,
    "part_number": "316604270",
    "part_exists": true
  },
  {
    "set_name": "库存类别",
    "set_exists": true,
    "cls_name": "FERT 成品",
    "cls_exists": true,
    "part_number": "316604270",
    "part_exists": true
  },
  {
    "set_name": "库存类别",
    "set_exists": true,
    "cls_name": "FERT 成品",
    "cls_exists": true,
    "part_number": "316604270.10",
    "part_exists": true
  },
  {
    "set_name": "库存类别",
    "set_exists": true,
    "cls_name": "HALB 半成品",
    "cls_exists": true,
    "part_number": "316604270.20",
    "part_exists": true
  },
  {
    "set_name": "库存类别",
    "set_exists": true,
    "cls_name": "HALB 半成品",
    "cls_exists": true,
    "part_number": "316604270.30",
    "part_exists": true
  }
]*/


WITH src(set_name, cls_name, cls_number, part_number) AS (
    VALUES
      ('产品类别', '大挖机型',    NULL,   '316604270'),
      ('产品型号', 'XE990F.00II', NULL,   '316604270'),
      ('产品型号', 'XE990F.00II', NULL,   '316604270.10'),
      ('产品型号', 'XE990F.00II', NULL,   '316604270.20'),
      ('产品型号', 'XE990F.00II', NULL,   '316604270.30'),
      ('库存类别', 'HALB 半成品', 'HALB', '316604270.30'),
      ('库存类别', 'HALB 半成品', 'HALB', '316604270.20'),
      ('库存类别', 'FERT 成品',   'FERT', '316604270.10'),
      ('库存类别', 'FERT 成品',   'FERT', '316604270'),
      ('产品吨位', '95',          NULL,   '316604270'),
      ('产品吨位', '95',          NULL,   '316604270.10'),
      ('产品吨位', '95',          NULL,   '316604270.20'),
      ('产品吨位', '95',          NULL,   '316604270.30')
),
new_cls AS (                          -- 去重后的待建分类
    SELECT DISTINCT set_name, cls_name, cls_number FROM src
),
ctx AS (                              -- 租户 / 操作人，取自现网数据
    SELECT (SELECT tenant_id FROM mbm_mdm_classification
             WHERE delete_flag = '0' AND tenant_id IS NOT NULL LIMIT 1) AS tenant_id,
           (SELECT create_user FROM mbm_mdm_classification
             WHERE create_user IS NOT NULL LIMIT 1)                  AS operator
),
b AS (                                -- 当天 WLFL 编码流水基准
    SELECT COALESCE(MAX(right(number, 4)::int), 0) AS seq
    FROM mbm_mdm_classification
    WHERE number ~ ('^WLFL' || to_char(current_date, 'YYYYMMDD') || '\d{4}$')
),
ins_cls AS (                          -- ① 只插入缺失的分类
    INSERT INTO mbm_mdm_classification (
        id, number, name, type, business_type, instantiable, enabled, single_container_flag,
        parent_node, root_node, classification_level, site_id, factory_code, sort,
        tenant_id, delete_flag, create_user, create_date, update_user, update_date)
    SELECT
        substr(md5(random()::text || clock_timestamp()::text || n.set_name || n.cls_name), 1, 13),
        COALESCE(NULLIF(n.cls_number, ''),
                 'WLFL' || to_char(current_date, 'YYYYMMDD') ||
                 lpad((b.seq + row_number() OVER (ORDER BY n.set_name, n.cls_name))::text, 4, '0')),
        n.cls_name,
        '0',                          -- type：类
        '0',                          -- business_type：物料
        '1',                          -- instantiable
        '1',                          -- enabled
        '0',                          -- single_container_flag
        NULL,                         -- parent_node：挂在分类维度下
        cs.id,                        -- root_node = 分类维度
        NULL, NULL, NULL,
        0,                            -- ⚠ sort 必须是数值 0
        COALESCE(cs.tenant_id, ctx.tenant_id),
        '0', ctx.operator, now(), ctx.operator, now()
    FROM new_cls n
    JOIN mbm_mdm_classification_set cs
      ON cs.name = n.set_name AND cs.delete_flag = '0'
    CROSS JOIN ctx
    CROSS JOIN b
    WHERE NOT EXISTS (
        SELECT 1 FROM mbm_mdm_classification c
        WHERE c.delete_flag = '0' AND c.root_node = cs.id
          AND c.name = n.cls_name AND c.business_type = '0')
    RETURNING id, name, root_node
),
all_cls AS (                          -- ② 已有分类 + 本次新建分类
    SELECT c.id, c.name, c.root_node
    FROM mbm_mdm_classification c
    JOIN mbm_mdm_classification_set cs ON cs.id = c.root_node
    JOIN new_cls n ON n.set_name = cs.name AND n.cls_name = c.name
    WHERE c.business_type = '0' AND c.delete_flag = '0'
    UNION
    SELECT id, name, root_node FROM ins_cls
)
INSERT INTO mbm_mdm_classification_part_link (   -- ③ 建“分类-物料”关系
    id, part_master_id, part_version_id, classification_id, site_id, factory_code, tenant_id,
    delete_flag, create_user, create_date, update_user, update_date)
SELECT
    substr(md5(random()::text || clock_timestamp()::text || pv.id || a.id), 1, 13),
    pv.part_master_id,
    pv.id,
    a.id,
    NULL,
    pv.factory_code,
    COALESCE(NULLIF(pv.tenant_id, ''), 'root'),
    '0', ctx.operator, now(), ctx.operator, now()
FROM (SELECT DISTINCT set_name, cls_name, part_number FROM src) s
JOIN mbm_mdm_classification_set cs
  ON cs.name = s.set_name AND cs.delete_flag = '0'
JOIN all_cls a
  ON a.root_node = cs.id AND a.name = s.cls_name
JOIN mbm_mdm_part_version pv
  ON pv.part_number = s.part_number AND pv.delete_flag = '0'
CROSS JOIN ctx
WHERE NOT EXISTS (
    SELECT 1 FROM mbm_mdm_classification_part_link l
    WHERE l.delete_flag = '0'
      AND l.classification_id = a.id
      AND l.part_version_id = pv.id)
RETURNING id AS link_id, classification_id, part_version_id, factory_code;
/*
[
  {
    "link_id": "9156a1d15aa35",
    "classification_id": "057mzaw1s7njk",
    "part_version_id": "05smq84kvda1b",
    "factory_code": "2200"
  },
  {
    "link_id": "17562f9a7828b",
    "classification_id": "6531b4b30df4d",
    "part_version_id": "05smq84kvda1b",
    "factory_code": "2200"
  },
  {
    "link_id": "eb15b08731ad8",
    "classification_id": "057mzaw1s7njk",
    "part_version_id": "0637unn14qckk",
    "factory_code": "2200"
  },
  {
    "link_id": "d62869f375e37",
    "classification_id": "6531b4b30df4d",
    "part_version_id": "0637unn14qckk",
    "factory_code": "2200"
  },
  {
    "link_id": "a5ee755ca1a74",
    "classification_id": "6531b4b30df4d",
    "part_version_id": "0637unmw2frt3",
    "factory_code": "2200"
  },
  {
    "link_id": "1d2d5828665fc",
    "classification_id": "057mzaw1s7njk",
    "part_version_id": "0637unmw2frt3",
    "factory_code": "2200"
  },
  {
    "link_id": "1a3b2db573c94",
    "classification_id": "6531b4b30df4d",
    "part_version_id": "0637unn0nxlf5",
    "factory_code": "2200"
  },
  {
    "link_id": "9313322ff7079",
    "classification_id": "057mzaw1s7njk",
    "part_version_id": "0637unn0nxlf5",
    "factory_code": "2200"
  }
]*/
WITH src(set_name, cls_name, cls_number, part_number) AS (
    VALUES
      ('产品类别', '大挖机型',    NULL,   '316604270'),
      ('产品型号', 'XE990F.00II', NULL,   '316604270'),
      ('产品型号', 'XE990F.00II', NULL,   '316604270.10'),
      ('产品型号', 'XE990F.00II', NULL,   '316604270.20'),
      ('产品型号', 'XE990F.00II', NULL,   '316604270.30'),
      ('库存类别', 'HALB 半成品', 'HALB', '316604270.30'),
      ('库存类别', 'HALB 半成品', 'HALB', '316604270.20'),
      ('库存类别', 'FERT 成品',   'FERT', '316604270.10'),
      ('库存类别', 'FERT 成品',   'FERT', '316604270'),
      ('产品吨位', '95',          NULL,   '316604270'),
      ('产品吨位', '95',          NULL,   '316604270.10'),
      ('产品吨位', '95',          NULL,   '316604270.20'),
      ('产品吨位', '95',          NULL,   '316604270.30')
)
SELECT s.set_name, s.cls_name,
       c.number AS cls_number, c.id AS cls_id,
       s.part_number, pv.id AS part_version_id, l.id AS link_id
FROM (SELECT DISTINCT set_name, cls_name, part_number FROM src) s
LEFT JOIN mbm_mdm_classification_set cs
       ON cs.name = s.set_name AND cs.delete_flag = '0'
LEFT JOIN mbm_mdm_classification c
       ON c.root_node = cs.id AND c.name = s.cls_name
      AND c.business_type = '0' AND c.delete_flag = '0'
LEFT JOIN mbm_mdm_part_version pv
       ON pv.part_number = s.part_number AND pv.delete_flag = '0'
LEFT JOIN mbm_mdm_classification_part_link l
       ON l.classification_id = c.id AND l.part_version_id = pv.id AND l.delete_flag = '0'
ORDER BY 1, 2, 5;
/*
[
  {
    "set_name": "产品吨位",
    "cls_name": "95",
    "cls_number": "WLFL202509200028",
    "cls_id": "057mzaw1s7njk",
    "part_number": "316604270",
    "part_version_id": "05smq84kvda1b",
    "link_id": "9156a1d15aa35"
  },
  {
    "set_name": "产品吨位",
    "cls_name": "95",
    "cls_number": "WLFL202509200028",
    "cls_id": "057mzaw1s7njk",
    "part_number": "316604270.10",
    "part_version_id": "0637unn14qckk",
    "link_id": "eb15b08731ad8"
  },
  {
    "set_name": "产品吨位",
    "cls_name": "95",
    "cls_number": "WLFL202509200028",
    "cls_id": "057mzaw1s7njk",
    "part_number": "316604270.20",
    "part_version_id": "0637unn0nxlf5",
    "link_id": "9313322ff7079"
  },
  {
    "set_name": "产品吨位",
    "cls_name": "95",
    "cls_number": "WLFL202509200028",
    "cls_id": "057mzaw1s7njk",
    "part_number": "316604270.30",
    "part_version_id": "0637unmw2frt3",
    "link_id": "1d2d5828665fc"
  },
  {
    "set_name": "产品型号",
    "cls_name": "XE990F.00II",
    "cls_number": "WLFL202610200001",
    "cls_id": "6531b4b30df4d",
    "part_number": "316604270",
    "part_version_id": "05smq84kvda1b",
    "link_id": "17562f9a7828b"
  },
  {
    "set_name": "产品型号",
    "cls_name": "XE990F.00II",
    "cls_number": "WLFL202610200001",
    "cls_id": "6531b4b30df4d",
    "part_number": "316604270.10",
    "part_version_id": "0637unn14qckk",
    "link_id": "d62869f375e37"
  },
  {
    "set_name": "产品型号",
    "cls_name": "XE990F.00II",
    "cls_number": "WLFL202610200001",
    "cls_id": "6531b4b30df4d",
    "part_number": "316604270.20",
    "part_version_id": "0637unn0nxlf5",
    "link_id": "1a3b2db573c94"
  },
  {
    "set_name": "产品型号",
    "cls_name": "XE990F.00II",
    "cls_number": "WLFL202610200001",
    "cls_id": "6531b4b30df4d",
    "part_number": "316604270.30",
    "part_version_id": "0637unmw2frt3",
    "link_id": "a5ee755ca1a74"
  },
  {
    "set_name": "产品类别",
    "cls_name": "大挖机型",
    "cls_number": "DW",
    "cls_id": "05sndnfjdb9ie",
    "part_number": "316604270",
    "part_version_id": "05smq84kvda1b",
    "link_id": "06anroqnbaek9"
  },
  {
    "set_name": "库存类别",
    "cls_name": "FERT 成品",
    "cls_number": "FERT",
    "cls_id": "053qylbk1x4i4",
    "part_number": "316604270",
    "part_version_id": "05smq84kvda1b",
    "link_id": "064lqt721wsrc"
  },
  {
    "set_name": "库存类别",
    "cls_name": "FERT 成品",
    "cls_number": "FERT",
    "cls_id": "053qylbk1x4i4",
    "part_number": "316604270.10",
    "part_version_id": "0637unn14qckk",
    "link_id": "064lqt6p2xt8r"
  },
  {
    "set_name": "库存类别",
    "cls_name": "HALB 半成品",
    "cls_number": "HALB",
    "cls_id": "053qylb90v9ol",
    "part_number": "316604270.20",
    "part_version_id": "0637unn0nxlf5",
    "link_id": "064lqs94sjzxe"
  },
  {
    "set_name": "库存类别",
    "cls_name": "HALB 半成品",
    "cls_number": "HALB",
    "cls_id": "053qylb90v9ol",
    "part_number": "316604270.30",
    "part_version_id": "0637unmw2frt3",
    "link_id": "064lqsau921a7"
  }
]*/


WITH src(set_name, cls_name, cls_number) AS (
    VALUES ('产品型号', 'XE990F.00II', '316604270')
),
ctx AS (
    SELECT (SELECT tenant_id FROM mbm_mdm_classification
             WHERE delete_flag = '0' AND tenant_id IS NOT NULL LIMIT 1) AS tenant_id,
           (SELECT create_user FROM mbm_mdm_classification
             WHERE create_user IS NOT NULL LIMIT 1)                  AS operator
),
b AS (
    SELECT COALESCE(MAX(right(number, 4)::int), 0) AS seq
    FROM mbm_mdm_classification
    WHERE number ~ ('^WLFL' || to_char(current_date, 'YYYYMMDD') || '\d{4}$')
)
INSERT INTO mbm_mdm_classification (
    id, number, name, type, business_type, instantiable, enabled, single_container_flag,
    parent_node, root_node, classification_level, site_id, factory_code, sort,
    tenant_id, delete_flag, create_user, create_date, update_user, update_date)
SELECT
    substr(md5(random()::text || clock_timestamp()::text || t.set_name || t.cls_name), 1, 13),
    COALESCE(NULLIF(t.cls_number, ''),
             'WLFL' || to_char(current_date, 'YYYYMMDD') ||
             lpad((b.seq + row_number() OVER (ORDER BY t.set_name, t.cls_name))::text, 4, '0')),
    t.cls_name, '0', '0', '1', '1', '0',
    NULL, cs.id, NULL, NULL, NULL,
    0,
    COALESCE(cs.tenant_id, ctx.tenant_id),
    '0', ctx.operator, now(), ctx.operator, now()
FROM src t
JOIN mbm_mdm_classification_set cs
  ON cs.name = t.set_name AND cs.delete_flag = '0'
CROSS JOIN ctx
CROSS JOIN b
WHERE NOT EXISTS (
    SELECT 1 FROM mbm_mdm_classification c
    WHERE c.delete_flag = '0' AND c.root_node = cs.id
      AND c.name = t.cls_name AND c.business_type = '0')
RETURNING id AS cls_id, number, name, root_node;





WITH src(set_name, cls_name, cls_number) AS (
    VALUES ('产品型号', 'XE990F.00II', '316604270')
)
SELECT t.set_name, t.cls_name, t.cls_number,
       c.id AS cls_id, c.number AS cls_number_actual, c.root_node, c.enabled, c.sort
FROM src t
LEFT JOIN mbm_mdm_classification_set cs
       ON cs.name = t.set_name AND cs.delete_flag = '0'
LEFT JOIN mbm_mdm_classification c
       ON c.root_node = cs.id AND c.name = t.cls_name
      AND c.business_type = '0' AND c.delete_flag = '0';
