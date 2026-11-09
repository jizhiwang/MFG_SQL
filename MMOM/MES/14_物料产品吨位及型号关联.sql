/*
分类下物料清单：各个吨位关联哪些物料、各个型号关联哪些物料。
每条分类与物料版本的关联一行，不按物料汇总、不拼接分类、不将吨位和型号配对。
不添加租户筛选或租户关联条件，也不加日期限制。
物料编码/名称来自页面使用的物料版本；维度来自分类root_node引用的分类集。
同一物料出现在不同分类下是正常的，保留关联ID以核对重复维护。
只查询有当前有效物料版本的关联，不输出无物料分类或孤立版本引用。
删除条件为<> '1'，NULL不纳入；不复制页面当前用户的工厂/分片权限。
无JSON、无聚合、无最终全量排序；字段依据本地源码，目标库尚未执行验证。
*/
SELECT s.number AS dimension_code,
       s.name AS dimension_name,
       c.id AS classification_id,
       c.number AS classification_code,
       c.name AS tonnage_or_model,
       c.parent_node AS parent_classification_id,
       l.id AS classification_part_link_id,
       v.id AS part_version_id,
       v.part_master_id,
       v.site_id,
       v.part_number,
       v.part_name,
       v.version AS part_version,
       v.specification_model,
       v.enabled AS part_enabled
FROM public.mbm_mdm_classification_set s
JOIN public.mbm_mdm_classification c
  ON c.root_node = s.id AND c.delete_flag <> '1'
JOIN public.mbm_mdm_classification_part_link l
  ON l.classification_id = c.id AND l.delete_flag <> '1'
JOIN public.mbm_mdm_part_version v
  ON v.id = l.part_version_id AND v.delete_flag <> '1'
WHERE s.number IN ('product_tonnage', 'product_model')
  AND s.delete_flag <> '1';
