UPDATE mbm_aps_product_order_route
SET direct_manual_time_unit   = 'H',
    indirect_manual_time_unit = 'H',
    depreciate_time_unit      = 'H',
    energy_time_unit          = 'H',
    other_time_unit           = 'H',
    update_date               = now()
WHERE delete_flag != '1'
  AND product_order_id in (SELECT id
                           FROM mbm_aps_product_order
                           WHERE number in (SELECT DISTINCT p.number AS orderNumber
                                            FROM mbm_mes_proc_exec_employee e
                                                     JOIN mbm_mes_proc_exe_history h
                                                          ON h.id = e.process_execute_history_id
                                                              AND h.delete_flag != '1'
                                                     LEFT JOIN mbm_aps_product_order p
                                                               ON p.id = h.product_order_id
                                                                   AND p.delete_flag != '1'
                                                     LEFT JOIN mbm_aps_process_tech_order o
                                                               ON o.id = h.process_tech_order_id
                                                                   AND o.delete_flag != '1'
                                                     LEFT JOIN mbm_aps_product_order_route oru
                                                               ON oru.id = o.product_order_route_id
                                                                   AND oru.delete_flag != '1'
                                            WHERE e.delete_flag = '0'
                                              AND e.employee_id IS NOT NULL
                                              AND e.completed_qty IS NOT NULL
                                              AND oru.id IS NOT NULL
                                              AND oru.direct_manual_time_unit IS NULL
                                            ORDER BY p.number)
                             AND delete_flag != '1')
  AND direct_manual_time_unit IS NULL;
