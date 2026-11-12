-- 修复前备份原值：source_master_id 原为 '056jblxpn8gb2'(314039793)
BEGIN;

UPDATE mbm_wms_stock_attr
SET source_master_id = '056jblg0nmk0o',      -- 314024202 XE600G.00Ⅳ
    update_date      = CURRENT_TIMESTAMP
WHERE id              = '0591ibz7w31ur'       -- 该整车唯一库存批次
  AND lot_att05       = 'XUGB6001HRKA01050'
  AND source_master_id = '056jblxpn8gb2';     -- 幂等保护：仅当前值正确时才改

-- 预期影响行数 = 1，确认无误后 COMMIT；否则 ROLLBACK
COMMIT;



SELECT sa2.lot_att05, pm.number AS stock_part, pm.name, sa.qty, sa.id AS atom_id
FROM mbm_wms_stock_atom sa
JOIN mbm_wms_stock_attr sa2 ON sa2.id = sa.stock_attr_id
JOIN mbm_mdm_part_master pm ON pm.id = sa2.source_master_id
WHERE sa2.lot_att05 = 'XUGB6001HRKA01050' AND sa.qty > 0;
-- 预期：stock_part = 314024202，qty = 1，atom_id = 0640psicdky4e



BEGIN;

UPDATE mbm_wms_stock_atom
SET source_master_id = '056jblg0nmk0o',            -- 314024202 XE600G.00Ⅳ
    update_date      = CURRENT_TIMESTAMP
WHERE stock_attr_id  = '0591ibz7w31ur'             -- 该整车唯一库存批次（6条原子，合计qty=1）
  AND source_master_id = '056jblxpn8gb2';          -- 幂等保护：仅仍为314039793时才改

-- 预期影响行数 = 6，确认后 COMMIT；否则 ROLLBACK
COMMIT;




SELECT sa.id, pm.number AS atom_part, sa.qty
FROM mbm_wms_stock_atom sa
JOIN mbm_mdm_part_master pm ON pm.id = sa.source_master_id
WHERE sa.stock_attr_id = '0591ibz7w31ur';
-- 预期 6 行全部 atom_part = 314024202




BEGIN;

UPDATE mbm_biz_pack_label
SET part_number      = '314024202',        -- 直存编码字段
    source_master_id = '056jblg0nmk0o',    -- 物料主数据 → 314024202
    source_version_id = '056jblg0nmk0p',   -- 物料版本（314024202唯一版本，与通知单一致）
    update_date      = CURRENT_TIMESTAMP
WHERE id             = '0591ic9xaf1we'
  AND lot_att05      = 'XUGB6001HRKA01050'
  AND source_master_id = '056jblcvq7t9p';  -- 幂等保护：仅当前值正确时才改

-- 预期影响行数 = 1，确认后 COMMIT；否则 ROLLBACK
COMMIT;
