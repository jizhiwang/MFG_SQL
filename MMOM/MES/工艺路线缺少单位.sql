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
                          WHERE number in (
                                           '10000644312',
                                           '10000644311',
                                           '10000644618',
                                           '10000644301',
                                           '10000644616',
                                           '10000644354',
                                           '10000644523'
                              )
                            AND delete_flag != '1')
  AND direct_manual_time_unit IS NULL;
