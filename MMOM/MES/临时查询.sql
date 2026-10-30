-- Oracle查询：人员基础信息及其可上岗工作中心（人类可读格式）
SELECT
    ri."NUMBER" AS "工号",
    ri.name AS "姓名",
    CASE e.state
        WHEN '0' THEN '在职'
        WHEN '1' THEN '离职'
        ELSE e.state
    END AS "在职状态",
    hr_org.org_short_name AS "所属部门",
    wam."NUMBER" AS "工作中心编码",
    wam.name AS "工作中心名称",
    CASE
        WHEN ec.is_qualified = '1' THEN '是'
        WHEN ec.is_qualified = '0' THEN '否'
        WHEN ec.is_qualified IS NULL THEN '未设置'
        ELSE '未知'
    END AS "是否胜任",
    CASE ec.certification_type
        WHEN '0' THEN '有效期认证'
        WHEN '1' THEN '永久认证'
        ELSE ec.certification_type
    END AS "认证类型",
    TO_CHAR(ec.certification_date, 'YYYY-MM-DD') AS "认证日期",
    TO_CHAR(ec.expiration_date, 'YYYY-MM-DD') AS "失效日期",
    CASE
        WHEN ec.is_resident = '1' THEN '是'
        WHEN ec.is_resident = '0' THEN '否'
        ELSE '未知'
    END AS "是否常驻",
    CASE ec.shift
        WHEN '0' THEN '白班'
        WHEN '1' THEN '中班'
        WHEN '2' THEN '夜班'
        WHEN '3' THEN '中夜'
        ELSE ec.shift
    END AS "班别"

FROM mbm_mdm_employee e
LEFT JOIN mbm_mdm_resource_instance ri ON e.resource_instance_id = ri.id
LEFT JOIN mbm_mdm_hr_organization hr_org ON e.department_id = hr_org.id
LEFT JOIN mbm_mdm_employee_certification ec ON e.id = ec.employee_id AND ec.delete_flag = '0'
LEFT JOIN mbm_mdm_work_area_version wav ON ec.work_center_id = wav.id
LEFT JOIN mbm_mdm_work_area_master wam ON wav.work_area_master_id = wam.id
WHERE e.delete_flag = '0'
ORDER BY ri."NUMBER", ec.certification_date DESC;