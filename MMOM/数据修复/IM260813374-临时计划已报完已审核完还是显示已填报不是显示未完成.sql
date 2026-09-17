-- 环境：重型(一期生产)  PostgreSQL
-- 0. 执行前留档（务必先跑并留存结果，作为回滚对账依据）
SELECT 'OC_BEFORE' AS tag, id, split_state, approval_state, finish_date,
       delete_flag, update_user, update_date
FROM mbm_product_temporary_order_demand_operation_content
WHERE id IN ('05zokfpnbm8qv','05zosa40fs2fq');

SELECT 'WH_BEFORE' AS tag, id, temporary_order_operation_id, state, approval_state,
       finish_time, delete_flag, update_user, update_date
FROM mbm_product_temporary_order_work_hours
WHERE id IN ('05zolvcb53h7y','05zot613jbpk2');
-- 期望：OC 两行 split_state='3' 且 finish_date IS NULL；WH 两行 state='2'；delete_flag 均为 '0'
-- 与期望不符请停止执行

BEGIN;

-- 1.1 工段任务：置已完工，finish_time 该列不更新（保留 18:30:53 / 19:24:22 各自原值）
UPDATE mbm_product_temporary_order_work_hours
SET state       = '3',
    update_user = '055ygj9hi0mai',
    update_date = now()
WHERE id IN ('05zolvcb53h7y','05zot613jbpk2')
  AND delete_flag = '0'
  AND state = '2';
-- 预期：UPDATE 2

-- 1.2 产线任务：置已完工，finish_date 按每条任务各自的实际终审完成时刻回填
--     05zokfpnbm8qv -> 2026-06-30 19:41:11.006
--     05zosa40fs2fq -> 2026-06-30 19:40:48.446
UPDATE mbm_product_temporary_order_demand_operation_content oc
SET split_state = '4',
    finish_date = COALESCE((
        SELECT MAX(wu.approval_time)
        FROM mbm_product_temporary_order_work_hours wh
        JOIN mbm_product_temporary_order_work_hour_user_new wu
          ON wu.temporary_order_work_hour_id = wh.id
         AND wu.delete_flag = '0'
         AND wu.handle_level = '6'
         AND wu.approval_state = '1'
        WHERE wh.temporary_order_operation_id = oc.id
          AND wh.delete_flag = '0'
    ), now()),
    update_user = '055ygj9hi0mai',
    update_date = now()
WHERE oc.id IN ('05zokfpnbm8qv','05zosa40fs2fq')
  AND oc.delete_flag = '0'
  AND oc.split_state = '3';
-- 预期：UPDATE 2

-- 复核
SELECT id, split_state, finish_date, update_date FROM mbm_product_temporary_order_demand_operation_content
WHERE id IN ('05zokfpnbm8qv','05zosa40fs2fq');
SELECT id, state, finish_time, update_date FROM mbm_product_temporary_order_work_hours
WHERE id IN ('05zolvcb53h7y','05zot613jbpk2');
/*
[
  {
    "id": "05zolvcb53h7y",
    "state": "2",
    "finish_time": "2026-06-30 18:30:53.000000",
    "update_date": "2026-08-28 16:53:49.052000"
  },
  {
    "id": "05zot613jbpk2",
    "state": "2",
    "finish_time": "2026-06-30 19:24:22.000000",
    "update_date": "2026-08-28 16:50:43.046000"
  }
]
*/

COMMIT;


-- 3. 回滚（需要时执行；finish_time 原值未变更，无需回滚）
-- BEGIN;
-- UPDATE mbm_product_temporary_order_demand_operation_content
-- SET split_state='3', finish_date=NULL, update_user='055ygj9hi0mai', update_date=now()
-- WHERE id IN ('05zokfpnbm8qv','05zosa40fs2fq');
-- UPDATE mbm_product_temporary_order_work_hours
-- SET state='2', update_user='055ygj9hi0mai', update_date=now()
-- WHERE id IN ('05zolvcb53h7y','05zot613jbpk2');
-- COMMIT;


BEGIN;

UPDATE mbm_product_temporary_order_work_hours
SET state = '3', update_user = '055ygj9hi0mai', update_date = now()
WHERE id IN ('05zolvcb53h7y','05zot613jbpk2')
  AND delete_flag = '0' AND state = '2';          -- 期望 UPDATE 2

UPDATE mbm_product_temporary_order_demand_operation_content oc
SET split_state = '4',
    finish_date = COALESCE((
        SELECT MAX(wu.approval_time)
        FROM mbm_product_temporary_order_work_hours wh
        JOIN mbm_product_temporary_order_work_hour_user_new wu
          ON wu.temporary_order_work_hour_id = wh.id
         AND wu.delete_flag = '0' AND wu.handle_level = '6' AND wu.approval_state = '1'
        WHERE wh.temporary_order_operation_id = oc.id AND wh.delete_flag = '0'
    ), now()),
    update_user = '055ygj9hi0mai', update_date = now()
WHERE oc.id IN ('05zokfpnbm8qv','05zosa40fs2fq')
  AND oc.delete_flag = '0' AND oc.split_state = '3';   -- 期望 UPDATE 2

COMMIT;    -- 关键：这一句必须执行成功
SELECT id, split_state, finish_date, update_date FROM mbm_product_temporary_order_demand_operation_content
WHERE id IN ('05zokfpnbm8qv','05zosa40fs2fq');
SELECT id, state, finish_time, update_date FROM mbm_product_temporary_order_work_hours
WHERE id IN ('05zolvcb53h7y','05zot613jbpk2');