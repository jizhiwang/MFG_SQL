SELECT t1.source_system_number AS compony_code,
       t1.name                 AS compony_name,
       t2.source_system_number AS factory_code,
       t2.name                 AS factory_name,
       t3.source_system_number AS branch_factory_code,
       t3.name                 AS branch_factory_name,
       t4.source_system_number AS work_segment_code,
       t4.name                 AS work_segment_name,
       t5.source_system_number AS work_center_code,
       t5.name                 AS work_center_name,
       t6.source_system_number AS work_station_code,
       t6.name                 AS work_station_name
FROM mbm_mdm_work_area_master t1
         LEFT JOIN mbm_mdm_work_area_master t2
                   ON t2.parent_work_area_master_id = t1.id
                       AND t2.delete_flag = '0'
                       AND t2.type = '1'
         LEFT JOIN mbm_mdm_work_area_master t3
                   ON t3.parent_work_area_master_id = t2.id
                       AND t3.delete_flag = '0'
                       AND t3.type = '2'
         LEFT JOIN mbm_mdm_work_area_master t4
                   ON t4.parent_work_area_master_id = t3.id
                       AND t4.delete_flag = '0'
                       AND t4.type = '33'
         LEFT JOIN mbm_mdm_work_area_master t5
                   ON t5.parent_work_area_master_id = t4.id
                       AND t5.delete_flag = '0'
                       AND t5.type = '3'
         LEFT JOIN mbm_mdm_work_area_master t6
                   ON t6.parent_work_area_master_id = t5.id
                       AND t6.delete_flag = '0'
                       AND t6.type = '4'
WHERE t1.delete_flag = '0'
  AND t1.type = '11'
ORDER BY t1.source_system_number,
         t2.source_system_number,
         t3.source_system_number,
         t4.source_system_number,
         t5.source_system_number,
         t6.source_system_number;