---
name: apex_translations
description: Generate Oracle APEX translation queries and PL/SQL blocks using APEX_LANG.CREATE_MESSAGE for multilingual applications.
---

# APEX Translations Skill

هذه الـ skill تساعد في إدارة ترجمات Oracle APEX بسهولة لجميع الشاشات والأولويات والجداول.

## كيفية الاستخدام

توليد أكواد الترجمة لـ Oracle APEX للمحافظة على الاتساق بين اللغتين العربية والإنجليزية.

### القالب الأساسي:

```sql
-- 1. التحقق من وجود الترجمات
SELECT * 
FROM apex_application_translations 
WHERE application_id = :APP_ID 
AND translatable_message IN ('MSG_1', 'MSG_2');

-- 2. إنشاء الترجمات
BEGIN
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => :APP_ID,
        p_name              => 'MSG_1',
        p_language          => 'en',
        p_message_text      => 'English Text',
        p_used_in_javascript => FALSE
    );
    
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => :APP_ID,
        p_name              => 'MSG_1',
        p_language          => 'ar',
        p_message_text      => 'النص العربي',
        p_used_in_javascript => FALSE
    );
    
    COMMIT;
END;
/
```
