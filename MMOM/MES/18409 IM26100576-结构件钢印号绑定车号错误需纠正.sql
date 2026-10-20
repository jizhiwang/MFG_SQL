-- 4/13 改码(97->107)按号码全局替换, 误改了 4/11 已完工整车 XUGB2151ATKA11155
-- (J260301-XE215LC-2/11155) 的车架钢印号记录. 本脚本只把该台改回 97, 其余保持 107.

-- STEP 0 只读校验: 期望命中 1 条, batch_number 当前为 J00210EV2260107
select id, sn, key_component_barcode, root_barcode, batch_number, create_date, update_date
from mbm_mes_proc_exe_kcp
where sn = 'XUGB2151ATKA11155'
   or root_barcode = 'XUGB2151ATKA11155';

-- 确认 97 是有效在用的单件ID: 期望 status=30 已完工, delete_flag=0
select id, sn, old_single_piece_id, product_order_id, production_status, is_assembled, delete_flag
from mbm_mes_single_piece_id
where id = '05rrj4p2js35z';

-- STEP 1 修正: 按 id 定点改回 97(不以号码为条件, 避免误伤其他台车)
-- 期望影响行数 = 1; 若为 0 请立即回滚并核对 STEP 0
begin;

update mbm_mes_proc_exe_kcp
   set batch_number = 'J00210EV2260097',
       update_date  = now()
 where id           = '05rrj4ot45vv7'
   and sn           = 'XUGB2151ATKA11155'
   and batch_number = 'J00210EV2260107';

commit;

-- STEP 2 只读回看: 期望 batch_number = J00210EV2260097
select id, sn, key_component_barcode, root_barcode, batch_number, create_date, update_date
from mbm_mes_proc_exe_kcp
where id = '05rrj4ot45vv7';

-- 全局确认 97 / 107 当前挂接情况
select id, sn, key_component_barcode, root_barcode, batch_number, update_date
from mbm_mes_proc_exe_kcp
where sn                    in ('J00210EV2260097', 'J00210EV2260107')
   or key_component_barcode in ('J00210EV2260097', 'J00210EV2260107')
   or root_barcode          in ('J00210EV2260097', 'J00210EV2260107')
   or batch_number          in ('J00210EV2260097', 'J00210EV2260107')
order by update_date;

-- 附: 以下默认不执行, 业务确认后按需启用

-- (A) 若 4/8 两条(05rfbuu6aeqas / 05rfbuobck2q3, 现 sn=root_barcode=107)
--     核实也属于 11155 这台车, 则一并改回 97
-- update mbm_mes_proc_exe_kcp
--    set sn           = 'J00210EV2260097',
--        root_barcode = 'J00210EV2260097',
--        update_date  = now()
--  where id in ('05rfbuu6aeqas', '05rfbuobck2q3')
--    and sn = 'J00210EV2260107';

-- (B) 冻结 97, 防止再次被回收后重复发放
-- update mbm_mes_single_piece_id_pool set can_use = 0 where sn = 'J00210EV2260097';
