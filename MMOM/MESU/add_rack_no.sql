ALTER TABLE mbm_mes_process_tech_order_id ADD COLUMN rack_no varchar(100) DEFAULT NULL;
COMMENT ON COLUMN mbm_mes_process_tech_order_id.rack_no IS '架位';