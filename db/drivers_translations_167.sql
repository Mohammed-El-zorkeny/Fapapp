-- =============================================================
-- APEX TRANSLATIONS FOR DRIVERS TABLE (APPLICATION ID: 167)
-- =============================================================

-- ========================================
-- 1. التحقق من الترجمات الموجودة في التطبيق 167
-- ========================================
SELECT * 
FROM apex_application_translations 
WHERE application_id = 167 
AND translatable_message IN (
    'DRIVERS_MANAGEMENT',
    'DRIVER_NAME',
    'PHONE_NUMBER',
    'LICENSE_NUMBER',
    'VEHICLE_NUMBER',
    'VEHICLE_TYPE',
    'CBM',
    'STATUS',
    'CREATED',
    'CREATED_BY',
    'UPDATED',
    'UPDATED_BY',
    'ACTIONS'
);

-- ========================================
-- 2. إنشاء الترجمات الجديدة للتطبيق 167
-- ========================================
BEGIN
    -- DRIVERS_MANAGEMENT (عنوان الشاشة / التقرير)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'DRIVERS_MANAGEMENT',
        p_language          => 'en',
        p_message_text      => 'Drivers Management',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'DRIVERS_MANAGEMENT',
        p_language          => 'ar',
        p_message_text      => 'إدارة السائقين',
        p_used_in_javascript => FALSE
    );

    -- DRIVER_NAME (اسم السائق)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'DRIVER_NAME',
        p_language          => 'en',
        p_message_text      => 'Driver Name',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'DRIVER_NAME',
        p_language          => 'ar',
        p_message_text      => 'اسم السائق',
        p_used_in_javascript => FALSE
    );

    -- PHONE_NUMBER (رقم التليفون)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'PHONE_NUMBER',
        p_language          => 'en',
        p_message_text      => 'Phone Number',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'PHONE_NUMBER',
        p_language          => 'ar',
        p_message_text      => 'رقم التليفون',
        p_used_in_javascript => FALSE
    );

    -- LICENSE_NUMBER (رقم الرخصة)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'LICENSE_NUMBER',
        p_language          => 'en',
        p_message_text      => 'License Number',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'LICENSE_NUMBER',
        p_language          => 'ar',
        p_message_text      => 'رقم الرخصة',
        p_used_in_javascript => FALSE
    );

    -- VEHICLE_NUMBER (رقم العربية)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'VEHICLE_NUMBER',
        p_language          => 'en',
        p_message_text      => 'Vehicle Number',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'VEHICLE_NUMBER',
        p_language          => 'ar',
        p_message_text      => 'رقم العربية',
        p_used_in_javascript => FALSE
    );

    -- VEHICLE_TYPE (نوع العربية)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'VEHICLE_TYPE',
        p_language          => 'en',
        p_message_text      => 'Vehicle Type',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'VEHICLE_TYPE',
        p_language          => 'ar',
        p_message_text      => 'نوع العربية',
        p_used_in_javascript => FALSE
    );

    -- CBM (الحمولة / السعة)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CBM',
        p_language          => 'en',
        p_message_text      => 'Capacity (CBM)',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CBM',
        p_language          => 'ar',
        p_message_text      => 'السعة (CBM)',
        p_used_in_javascript => FALSE
    );

    -- STATUS (الحالة)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'STATUS',
        p_language          => 'en',
        p_message_text      => 'Status',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'STATUS',
        p_language          => 'ar',
        p_message_text      => 'الحالة',
        p_used_in_javascript => FALSE
    );

    -- CREATED (تاريخ الإنشاء)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CREATED',
        p_language          => 'en',
        p_message_text      => 'Created Date',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CREATED',
        p_language          => 'ar',
        p_message_text      => 'تاريخ الإنشاء',
        p_used_in_javascript => FALSE
    );

    -- CREATED_BY (أنشئ بواسطة)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CREATED_BY',
        p_language          => 'en',
        p_message_text      => 'Created By',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CREATED_BY',
        p_language          => 'ar',
        p_message_text      => 'أنشئ بواسطة',
        p_used_in_javascript => FALSE
    );

    -- UPDATED (تاريخ التعديل)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'UPDATED',
        p_language          => 'en',
        p_message_text      => 'Updated Date',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'UPDATED',
        p_language          => 'ar',
        p_message_text      => 'تاريخ التعديل',
        p_used_in_javascript => FALSE
    );

    -- UPDATED_BY (عدل بواسطة)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'UPDATED_BY',
        p_language          => 'en',
        p_message_text      => 'Updated By',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'UPDATED_BY',
        p_language          => 'ar',
        p_message_text      => 'عدل بواسطة',
        p_used_in_javascript => FALSE
    );

    -- ACTIONS (الإجراءات)
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'ACTIONS',
        p_language          => 'en',
        p_message_text      => 'Actions',
        p_used_in_javascript => FALSE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'ACTIONS',
        p_language          => 'ar',
        p_message_text      => 'الإجراءات',
        p_used_in_javascript => FALSE
    );

    COMMIT;
END;
/
