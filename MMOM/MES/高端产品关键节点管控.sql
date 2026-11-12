    SELECT
        l.part_master_id,
        l.part_version_id,
--         MAX(CASE WHEN c.root_node = 'product_tonnage' THEN c.name END) AS tonnage,
        MAX(CASE
            WHEN c.name IN ('伸臂结构', '转台结构', '车架结构', '底盘装配', '整机装配') THEN c.name
        END) AS product_type
    FROM mbm_mdm_classification_part_link l
    JOIN mbm_mdm_classification c ON l.classification_id = c.id
    WHERE c.root_node = 'product_tonnage'
       OR c.name IN ('伸臂结构', '转台结构', '车架结构', '底盘装配', '整机装配')
          AND l.delete_flag = '0'

    GROUP BY l.part_master_id, l.part_version_id