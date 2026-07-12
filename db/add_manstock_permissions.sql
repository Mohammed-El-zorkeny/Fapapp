-- -------------------------------------------------------------
-- 1. ALTER TABLE SEC_USERS (ADD PERMISSION COLUMNS)
-- -------------------------------------------------------------
ALTER TABLE SEC_USERS ADD (
    CAN_ACCESS_STOCK_APP          NUMBER(1) DEFAULT 0,
    CAN_PURCHASE_DELIVERY         NUMBER(1) DEFAULT 0,
    CAN_RETURN_DELIVERY           NUMBER(1) DEFAULT 0,
    CAN_STOCK_COUNT               NUMBER(1) DEFAULT 0,
    CAN_VIEW_ITEM_CARD            NUMBER(1) DEFAULT 0,
    CAN_CHANGE_LOCATION           NUMBER(1) DEFAULT 0,
    CAN_REVIEW_DELIVERY_INVOICES  NUMBER(1) DEFAULT 0
);

-- -------------------------------------------------------------
-- 2. CREATE OR REPLACE VIEW VW_API_ENTRY_LOGIN
-- -------------------------------------------------------------
CREATE OR REPLACE FORCE EDITIONABLE VIEW "VW_API_ENTRY_LOGIN" (
    "ID", "AUTO_NUMBER", "AUTO_NUMBER_BRA", "CODE", "NAME_AR", "NAME_EN", "PREFIX", 
    "PHONE_CODE", "PHONE_NUMBER", "USERNAME", "PHONE_CODE_2", "PHONE_NUMBER_2", 
    "ADDRESS", "ACCOUNT_NUMBER", "EMAIL", "IMAGE_TYPE", "IMAGE_FILE_NAME", "STATUS", 
    "NOTES", "CREATED", "CREATED_BY", "UPDATED", "UPDATED_BY", "COMP_ID", "BRANCH_ID", 
    "EVALUATION_ID", "EVALUATION_NAME", "GOV_ID", "GOV_NAME", "PAY_TYPE", "DEBIT", "CREDIT", 
    "BALANCE_DATE", "TYPE_LOGIN", "BALANCE", "USER_ID", "LOCATION_LINK", "GOVERNORATE_NAME", 
    "DISTRICT_NAME", "FULL_ADDRESS", "CAN_ACCESS_STOCK_APP", "CAN_PURCHASE_DELIVERY", 
    "CAN_RETURN_DELIVERY", "CAN_STOCK_COUNT", "CAN_VIEW_ITEM_CARD", "CAN_CHANGE_LOCATION", 
    "CAN_REVIEW_DELIVERY_INVOICES"
) AS 
SELECT
    a.ID,
    a.AUTO_NUMBER,
    a.AUTO_NUMBER_BRA,
    a.CUSTOMER_CODE AS CODE,
    a.NAME_AR,
    a.NAME_EN,
    a.PREFIX,
    a.PHONE_CODE,
    a.PHONE_NUMBER,
    a.PHONE_NUMBER AS USERNAME,
    a.PHONE_CODE_2,
    a.PHONE_NUMBER_2,
    a.ADDRESS,
    a.ACCOUNT_NUMBER,
    a.EMAIL,
    a.IMAGE_TYPE,
    a.IMAGE_FILE_NAME,
    TO_CHAR(a.STATUS) AS STATUS,
    a.NOTES,
    a.CREATED,
    a.CREATED_BY,
    a.UPDATED,
    a.UPDATED_BY,
    a.COMP_ID,
    a.BRANCH_ID,
    a.EVALUATION_ID,
    (SELECT x.NAME FROM DBS_SAL_EVALUATION x WHERE x.ID = a.EVALUATION_ID) AS EVALUATION_NAME,
    a.GOV_ID,
    (SELECT x.NAME FROM DBS_AU_GOVERNORATES x WHERE x.ID = a.GOV_ID) AS GOV_NAME,
    a.PAY_TYPE,
    a.DEBIT,
    a.CREDIT,
    a.BALANCE_DATE,
    'CUSTOMER' AS TYPE_LOGIN,
    DBS_SAL_CUSTOMERS_BALANCE(a.ID) AS BALANCE,
    CAST(NULL AS NUMBER) AS USER_ID,
    a.LOCATION_LINK,
    a.GOVERNORATE_NAME,
    a.DISTRICT_NAME,
    a.FULL_ADDRESS,
    CAST(0 AS NUMBER) AS CAN_ACCESS_STOCK_APP,
    CAST(0 AS NUMBER) AS CAN_PURCHASE_DELIVERY,
    CAST(0 AS NUMBER) AS CAN_RETURN_DELIVERY,
    CAST(0 AS NUMBER) AS CAN_STOCK_COUNT,
    CAST(0 AS NUMBER) AS CAN_VIEW_ITEM_CARD,
    CAST(0 AS NUMBER) AS CAN_CHANGE_LOCATION,
    CAST(0 AS NUMBER) AS CAN_REVIEW_DELIVERY_INVOICES
FROM DBS_SAL_CUSTOMERS a

UNION ALL

-- SALESMAN
SELECT
    b.ID,
    b.AUTO_NUMBER,
    b.AUTO_NUMBER_BRA,
    b.SALESMAN_CODE AS CODE,
    b.NAME_AR,
    b.NAME_EN,
    b.PREFIX,
    b.PHONE_CODE,
    b.PHONE_NUMBER,
    b.PHONE_NUMBER AS USERNAME,
    b.PHONE_CODE_2,
    b.PHONE_NUMBER_2,
    b.ADDRESS,
    b.ACCOUNT_NUMBER,
    b.EMAIL,
    b.IMAGE_TYPE,
    b.IMAGE_FILE_NAME,
    TO_CHAR(b.STATUS) AS STATUS,
    b.NOTES,
    b.CREATED,
    b.CREATED_BY,
    b.UPDATED,
    b.UPDATED_BY,
    b.COMP_ID,
    b.BRANCH_ID,
    CAST(NULL AS NUMBER) AS EVALUATION_ID,
    CAST(NULL AS VARCHAR2(250)) AS EVALUATION_NAME,
    CAST(NULL AS NUMBER) AS GOV_ID,
    CAST(NULL AS VARCHAR2(250)) AS GOV_NAME,
    CAST(NULL AS VARCHAR2(1)) AS PAY_TYPE,
    CAST(NULL AS NUMBER) AS DEBIT,
    CAST(NULL AS NUMBER) AS CREDIT,
    CAST(NULL AS DATE) AS BALANCE_DATE,
    'SALESMAN' AS TYPE_LOGIN,
    CAST(NULL AS NUMBER) AS BALANCE,
    b.USER_ID,
    CAST(NULL AS VARCHAR2(500)) AS LOCATION_LINK,
    CAST(NULL AS VARCHAR2(100)) AS GOVERNORATE_NAME,
    CAST(NULL AS VARCHAR2(100)) AS DISTRICT_NAME,
    CAST(NULL AS VARCHAR2(1000)) AS FULL_ADDRESS,
    CAST(0 AS NUMBER) AS CAN_ACCESS_STOCK_APP,
    CAST(0 AS NUMBER) AS CAN_PURCHASE_DELIVERY,
    CAST(0 AS NUMBER) AS CAN_RETURN_DELIVERY,
    CAST(0 AS NUMBER) AS CAN_STOCK_COUNT,
    CAST(0 AS NUMBER) AS CAN_VIEW_ITEM_CARD,
    CAST(0 AS NUMBER) AS CAN_CHANGE_LOCATION,
    CAST(0 AS NUMBER) AS CAN_REVIEW_DELIVERY_INVOICES
FROM DBS_SAL_SALES_MAN b

UNION ALL

-- MANSTOCK
SELECT
    c.ID,
    CAST(NULL AS VARCHAR2(50)) AS AUTO_NUMBER,
    CAST(NULL AS VARCHAR2(50)) AS AUTO_NUMBER_BRA,
    c.CODE,
    c.NAME_AR,
    CAST(NULL AS VARCHAR2(100)) AS NAME_EN,
    CAST(NULL AS VARCHAR2(10)) AS PREFIX,
    CAST(NULL AS VARCHAR2(10)) AS PHONE_CODE,
    c.PHONE AS PHONE_NUMBER,
    c.PHONE AS USERNAME,
    CAST(NULL AS VARCHAR2(10)) AS PHONE_CODE_2,
    CAST(NULL AS VARCHAR2(20)) AS PHONE_NUMBER_2,
    CAST(NULL AS VARCHAR2(500)) AS ADDRESS,
    CAST(NULL AS VARCHAR2(50)) AS ACCOUNT_NUMBER,
    CAST(c.EMAIL AS VARCHAR2(100)) AS EMAIL,
    CAST(NULL AS VARCHAR2(250)) AS IMAGE_TYPE,
    CAST(c.IMAGE_PATH AS VARCHAR2(250)) AS IMAGE_FILE_NAME,
    TO_CHAR(c.STATUS) AS STATUS,
    CAST(NULL AS VARCHAR2(4000)) AS NOTES,
    CAST(NULL AS DATE) AS CREATED,
    CAST(NULL AS VARCHAR2(250)) AS CREATED_BY,
    CAST(NULL AS DATE) AS UPDATED,
    CAST(NULL AS VARCHAR2(250)) AS UPDATED_BY,
    CAST(NULL AS NUMBER) AS COMP_ID,
    CAST(NULL AS NUMBER) AS BRANCH_ID,
    CAST(NULL AS NUMBER) AS EVALUATION_ID,
    CAST(NULL AS VARCHAR2(250)) AS EVALUATION_NAME,
    CAST(NULL AS NUMBER) AS GOV_ID,
    CAST(NULL AS VARCHAR2(250)) AS GOV_NAME,
    CAST(NULL AS VARCHAR2(1)) AS PAY_TYPE,
    CAST(NULL AS NUMBER) AS DEBIT,
    CAST(NULL AS NUMBER) AS CREDIT,
    CAST(NULL AS DATE) AS BALANCE_DATE,
    'MANSTOCK' AS TYPE_LOGIN,
    CAST(NULL AS NUMBER) AS BALANCE,
    c.ID AS USER_ID,
    CAST(NULL AS VARCHAR2(500)) AS LOCATION_LINK,
    CAST(NULL AS VARCHAR2(100)) AS GOVERNORATE_NAME,
    CAST(NULL AS VARCHAR2(100)) AS DISTRICT_NAME,
    CAST(NULL AS VARCHAR2(1000)) AS FULL_ADDRESS,
    nvl(c.CAN_ACCESS_STOCK_APP, 0) AS CAN_ACCESS_STOCK_APP,
    nvl(c.CAN_PURCHASE_DELIVERY, 0) AS CAN_PURCHASE_DELIVERY,
    nvl(c.CAN_RETURN_DELIVERY, 0) AS CAN_RETURN_DELIVERY,
    nvl(c.CAN_STOCK_COUNT, 0) AS CAN_STOCK_COUNT,
    nvl(c.CAN_VIEW_ITEM_CARD, 0) AS CAN_VIEW_ITEM_CARD,
    nvl(c.CAN_CHANGE_LOCATION, 0) AS CAN_CHANGE_LOCATION,
    nvl(c.CAN_REVIEW_DELIVERY_INVOICES, 0) AS CAN_REVIEW_DELIVERY_INVOICES
FROM SEC_USERS c
WHERE c.ROLE_ID = 8

UNION ALL

-- ADMIN
SELECT
    c.ID,
    CAST(NULL AS VARCHAR2(50)) AS AUTO_NUMBER,
    CAST(NULL AS VARCHAR2(50)) AS AUTO_NUMBER_BRA,
    c.CODE,
    c.NAME_AR,
    CAST(NULL AS VARCHAR2(100)) AS NAME_EN,
    CAST(NULL AS VARCHAR2(10)) AS PREFIX,
    CAST(NULL AS VARCHAR2(10)) AS PHONE_CODE,
    c.PHONE AS PHONE_NUMBER,
    c.PHONE AS USERNAME,
    CAST(NULL AS VARCHAR2(10)) AS PHONE_CODE_2,
    CAST(NULL AS VARCHAR2(20)) AS PHONE_NUMBER_2,
    CAST(NULL AS VARCHAR2(500)) AS ADDRESS,
    CAST(NULL AS VARCHAR2(50)) AS ACCOUNT_NUMBER,
    CAST(c.EMAIL AS VARCHAR2(100)) AS EMAIL,
    CAST(NULL AS VARCHAR2(250)) AS IMAGE_TYPE,
    CAST(c.IMAGE_PATH AS VARCHAR2(250)) AS IMAGE_FILE_NAME,
    TO_CHAR(c.STATUS) AS STATUS,
    CAST(NULL AS VARCHAR2(4000)) AS NOTES,
    CAST(NULL AS DATE) AS CREATED,
    CAST(NULL AS VARCHAR2(250)) AS CREATED_BY,
    CAST(NULL AS DATE) AS UPDATED,
    CAST(NULL AS VARCHAR2(250)) AS UPDATED_BY,
    CAST(NULL AS NUMBER) AS COMP_ID,
    CAST(NULL AS NUMBER) AS BRANCH_ID,
    CAST(NULL AS NUMBER) AS EVALUATION_ID,
    CAST(NULL AS VARCHAR2(250)) AS EVALUATION_NAME,
    CAST(NULL AS NUMBER) AS GOV_ID,
    CAST(NULL AS VARCHAR2(250)) AS GOV_NAME,
    CAST(NULL AS VARCHAR2(1)) AS PAY_TYPE,
    CAST(NULL AS NUMBER) AS DEBIT,
    CAST(NULL AS NUMBER) AS CREDIT,
    CAST(NULL AS DATE) AS BALANCE_DATE,
    'ADMIN' AS TYPE_LOGIN,
    CAST(NULL AS NUMBER) AS BALANCE,
    c.ID AS USER_ID,
    CAST(NULL AS VARCHAR2(500)) AS LOCATION_LINK,
    CAST(NULL AS VARCHAR2(100)) AS GOVERNORATE_NAME,
    CAST(NULL AS VARCHAR2(100)) AS DISTRICT_NAME,
    CAST(NULL AS VARCHAR2(1000)) AS FULL_ADDRESS,
    nvl(c.CAN_ACCESS_STOCK_APP, 0) AS CAN_ACCESS_STOCK_APP,
    nvl(c.CAN_PURCHASE_DELIVERY, 0) AS CAN_PURCHASE_DELIVERY,
    nvl(c.CAN_RETURN_DELIVERY, 0) AS CAN_RETURN_DELIVERY,
    nvl(c.CAN_STOCK_COUNT, 0) AS CAN_STOCK_COUNT,
    nvl(c.CAN_VIEW_ITEM_CARD, 0) AS CAN_VIEW_ITEM_CARD,
    nvl(c.CAN_CHANGE_LOCATION, 0) AS CAN_CHANGE_LOCATION,
    nvl(c.CAN_REVIEW_DELIVERY_INVOICES, 0) AS CAN_REVIEW_DELIVERY_INVOICES
FROM SEC_USERS c
WHERE c.ROLE_ID = 4

UNION ALL

-- CUSTOMER EMPLOYEES
SELECT
    cu.DBS_SAL_CUSTOMERS_ID AS ID,
    a.AUTO_NUMBER,
    a.AUTO_NUMBER_BRA,
    a.CUSTOMER_CODE AS CODE,
    cu.EMPLOYEE_NAME AS NAME_AR,
    cu.EMPLOYEE_NAME AS NAME_EN,
    a.PREFIX,
    a.PHONE_CODE,
    cu.PHONE_NUMBER,
    cu.PHONE_NUMBER AS USERNAME,
    CAST(NULL AS VARCHAR2(10)) AS PHONE_CODE_2,
    CAST(NULL AS VARCHAR2(20)) AS PHONE_NUMBER_2,
    a.ADDRESS,
    a.ACCOUNT_NUMBER,
    a.EMAIL,
    a.IMAGE_TYPE,
    a.IMAGE_FILE_NAME,
    TO_CHAR(cu.STATUS) AS STATUS,
    cu.NOTES,
    cu.CREATED,
    CAST(cu.CREATED_BY AS VARCHAR2(250)) AS CREATED_BY,
    cu.UPDATED,
    CAST(cu.UPDATED_BY AS VARCHAR2(250)) AS UPDATED_BY,
    a.COMP_ID,
    a.BRANCH_ID,
    CAST(NULL AS NUMBER) AS EVALUATION_ID,
    CAST(NULL AS VARCHAR2(250)) AS EVALUATION_NAME,
    CAST(NULL AS NUMBER) AS GOV_ID,
    CAST(NULL AS VARCHAR2(250)) AS GOV_NAME,
    a.PAY_TYPE,
    a.DEBIT,
    a.CREDIT,
    a.BALANCE_DATE,
    'CUSTOMER_EMP' AS TYPE_LOGIN,
    DBS_SAL_CUSTOMERS_BALANCE(cu.DBS_SAL_CUSTOMERS_ID) AS BALANCE,
    cu.ID AS USER_ID,
    a.LOCATION_LINK,
    a.GOVERNORATE_NAME,
    a.DISTRICT_NAME,
    a.FULL_ADDRESS,
    CAST(0 AS NUMBER) AS CAN_ACCESS_STOCK_APP,
    CAST(0 AS NUMBER) AS CAN_PURCHASE_DELIVERY,
    CAST(0 AS NUMBER) AS CAN_RETURN_DELIVERY,
    CAST(0 AS NUMBER) AS CAN_STOCK_COUNT,
    CAST(0 AS NUMBER) AS CAN_VIEW_ITEM_CARD,
    CAST(0 AS NUMBER) AS CAN_CHANGE_LOCATION,
    CAST(0 AS NUMBER) AS CAN_REVIEW_DELIVERY_INVOICES
FROM DBS_SAL_CUSTOMERS_USERS cu
INNER JOIN DBS_SAL_CUSTOMERS a ON a.ID = cu.DBS_SAL_CUSTOMERS_ID
WHERE cu.STATUS = 1;

-- -------------------------------------------------------------
-- 3. LOGIN PL/SQL ENDPOINT BLOCK WITH SECURITY AND PERMISSIONS
-- -------------------------------------------------------------
DECLARE
    l_phone_input     VARCHAR2(100);
    l_phone_clean     VARCHAR2(20);
    l_otp_input       VARCHAR2(6);
    l_customer_id     NUMBER;
    l_name_ar         VARCHAR2(200);
    l_name_en         VARCHAR2(200);
    l_email           VARCHAR2(200);
    l_type_login      VARCHAR2(20);
    l_token           VARCHAR2(4000);
    l_stored_otp      VARCHAR2(6);
    l_otp_id          NUMBER;
    l_attempts        NUMBER;
    l_governorate_name VARCHAR2(200);
    l_evaluation_name VARCHAR2(200);
    l_balance         NUMBER;
    l_address         VARCHAR2(500);
    l_location_link   VARCHAR2(500);
    l_district_name   VARCHAR2(200);
    l_full_address    VARCHAR2(500);
    l_code            VARCHAR2(50);
    l_user_id         NUMBER;
    
    -- Permissions variables
    l_can_access_stock_app         NUMBER;
    l_can_purchase_delivery        NUMBER;
    l_can_return_delivery          NUMBER;
    l_can_stock_count              NUMBER;
    l_can_view_item_card           NUMBER;
    l_can_change_location          NUMBER;
    l_can_review_delivery_invoices NUMBER;
    
    -- بيانات موظف العميل
    l_job_title       VARCHAR2(100);
    l_can_view_prices NUMBER;
    l_customer_name   VARCHAR2(250);
    
    c_test_otp        CONSTANT VARCHAR2(6) := '202020';
    l_is_test_mode    BOOLEAN := FALSE;
    
BEGIN
    l_phone_input := :phoneNumber;
    l_otp_input   := :otp;
    
    IF l_phone_input IS NULL OR l_otp_input IS NULL THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error');
        APEX_JSON.write('messageAr', 'رقم الموبايل وكود التحقق مطلوبان', TRUE);
        APEX_JSON.write('messageEn', 'Phone number and OTP are required', TRUE);
        APEX_JSON.write('errorCode', 'MISSING_DATA', TRUE);
        APEX_JSON.close_object;
        :status := 400;
        RETURN;
    END IF;
    
    l_phone_clean := VALIDATE_EGYPTIAN_MOBILE(l_phone_input);
    
    IF l_phone_clean IS NULL THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error');
        APEX_JSON.write('messageAr', 'رقم الموبايل غير صحيح', TRUE);
        APEX_JSON.write('messageEn', 'Invalid phone number', TRUE);
        APEX_JSON.write('errorCode', 'INVALID_PHONE', TRUE);
        APEX_JSON.close_object;
        :status := 400;
        RETURN;
    END IF;
    
    l_is_test_mode := (l_otp_input = c_test_otp);
    
    IF l_is_test_mode THEN
        BEGIN
            SELECT ID, NAME_AR, NAME_EN, EMAIL, TYPE_LOGIN, GOVERNORATE_NAME, 
                   EVALUATION_NAME, BALANCE, ADDRESS,
                   LOCATION_LINK, DISTRICT_NAME, FULL_ADDRESS, CODE, USER_ID,
                   CAN_ACCESS_STOCK_APP, CAN_PURCHASE_DELIVERY, CAN_RETURN_DELIVERY,
                   CAN_STOCK_COUNT, CAN_VIEW_ITEM_CARD, CAN_CHANGE_LOCATION,
                   CAN_REVIEW_DELIVERY_INVOICES
            INTO l_customer_id, l_name_ar, l_name_en, l_email, l_type_login,
                 l_governorate_name, l_evaluation_name, l_balance, l_address,
                 l_location_link, l_district_name, l_full_address, l_code, l_user_id,
                 l_can_access_stock_app, l_can_purchase_delivery, l_can_return_delivery,
                 l_can_stock_count, l_can_view_item_card, l_can_change_location,
                 l_can_review_delivery_invoices
            FROM VW_API_ENTRY_LOGIN
            WHERE PHONE_NUMBER = l_phone_clean AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                APEX_JSON.open_object;
                APEX_JSON.write('status', 'error');
                APEX_JSON.write('messageAr', 'رقم الموبايل غير مسجل', TRUE);
                APEX_JSON.write('messageEn', 'Phone not registered', TRUE);
                APEX_JSON.write('errorCode', 'PHONE_NOT_FOUND', TRUE);
                APEX_JSON.close_object;
                :status := 404;
                RETURN;
        END;
    ELSE
        BEGIN
            SELECT OTP_ID, OTP_CODE, CUSTOMER_ID, ATTEMPTS
            INTO l_otp_id, l_stored_otp, l_customer_id, l_attempts
            FROM API_OTP_REQUESTS
            WHERE PHONE_NUMBER = l_phone_clean
              AND IS_USED = 'N'
              AND EXPIRES_AT > SYSTIMESTAMP
            ORDER BY CREATED_AT DESC
            FETCH FIRST 1 ROW ONLY;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                APEX_JSON.open_object;
                APEX_JSON.write('status', 'error');
                APEX_JSON.write('messageAr', 'كود التحقق منتهي الصلاحية أو غير موجود', TRUE);
                APEX_JSON.write('messageEn', 'OTP expired or not found', TRUE);
                APEX_JSON.write('errorCode', 'OTP_EXPIRED', TRUE);
                APEX_JSON.close_object;
                :status := 400;
                RETURN;
        END;
        
        IF l_attempts >= 3 THEN
            UPDATE API_OTP_REQUESTS SET IS_USED = 'Y' WHERE OTP_ID = l_otp_id;
            COMMIT;
            APEX_JSON.open_object;
            APEX_JSON.write('status', 'error');
            APEX_JSON.write('messageAr', 'تم تجاوز عدد المحاولات المسموحة', TRUE);
            APEX_JSON.write('messageEn', 'Maximum attempts exceeded', TRUE);
            APEX_JSON.write('errorCode', 'MAX_ATTEMPTS', TRUE);
            APEX_JSON.close_object;
            :status := 400;
            RETURN;
        END IF;
        
        IF l_stored_otp != l_otp_input THEN
            UPDATE API_OTP_REQUESTS SET ATTEMPTS = ATTEMPTS + 1 WHERE OTP_ID = l_otp_id;
            COMMIT;
            APEX_JSON.open_object;
            APEX_JSON.write('status', 'error');
            APEX_JSON.write('messageAr', 'كود التحقق غير صحيح', TRUE);
            APEX_JSON.write('messageEn', 'Invalid OTP', TRUE);
            APEX_JSON.write('errorCode', 'INVALID_OTP', TRUE);
            APEX_JSON.write('attemptsRemaining', 3 - (l_attempts + 1));
            APEX_JSON.close_object;
            :status := 400;
            RETURN;
        END IF;
        
        UPDATE API_OTP_REQUESTS
        SET IS_USED = 'Y', VERIFIED_AT = SYSTIMESTAMP
        WHERE OTP_ID = l_otp_id;
        
        SELECT ID, NAME_AR, NAME_EN, EMAIL, TYPE_LOGIN, GOVERNORATE_NAME,
               EVALUATION_NAME, BALANCE, ADDRESS,
               LOCATION_LINK, DISTRICT_NAME, FULL_ADDRESS, CODE, USER_ID,
               CAN_ACCESS_STOCK_APP, CAN_PURCHASE_DELIVERY, CAN_RETURN_DELIVERY,
               CAN_STOCK_COUNT, CAN_VIEW_ITEM_CARD, CAN_CHANGE_LOCATION,
               CAN_REVIEW_DELIVERY_INVOICES
        INTO l_customer_id, l_name_ar, l_name_en, l_email, l_type_login, l_governorate_name,
             l_evaluation_name, l_balance, l_address,
             l_location_link, l_district_name, l_full_address, l_code, l_user_id,
             l_can_access_stock_app, l_can_purchase_delivery, l_can_return_delivery,
             l_can_stock_count, l_can_view_item_card, l_can_change_location,
             l_can_review_delivery_invoices
        FROM VW_API_ENTRY_LOGIN
        WHERE PHONE_NUMBER = l_phone_clean AND STATUS = '1' AND ROWNUM = 1;
    END IF;
    
    -- -------------------------------------------------------------
    -- SECURITY BLOCK FOR MANSTOCK ACCESS CONTROL
    -- -------------------------------------------------------------
    IF l_type_login = 'MANSTOCK' AND nvl(l_can_access_stock_app, 0) = 0 THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error');
        APEX_JSON.write('messageAr', 'غير مصرح لك بدخول تطبيق المخازن', TRUE);
        APEX_JSON.write('messageEn', 'Not authorized to access the Stock Application', TRUE);
        APEX_JSON.write('errorCode', 'STOCK_ACCESS_DENIED', TRUE);
        APEX_JSON.close_object;
        :status := 403;
        RETURN;
    END IF;
    
    -- لو موظف عميل نجيب بياناته الإضافية
    IF l_type_login = 'CUSTOMER_EMP' THEN
        BEGIN
            SELECT 
                cu.JOB_TITLE,
                cu.CAN_VIEW_PRICES,
                a.NAME_AR
            INTO l_job_title, l_can_view_prices, l_customer_name
            FROM DBS_SAL_CUSTOMERS_USERS cu
            INNER JOIN DBS_SAL_CUSTOMERS a ON a.ID = cu.DBS_SAL_CUSTOMERS_ID
            WHERE cu.ID = l_user_id
              AND cu.STATUS = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_job_title := NULL;
                l_can_view_prices := 1;
                l_customer_name := NULL;
        END;
    ELSE
        -- العميل نفسه أو أي نوع تاني بيشوف كل حاجة
        l_can_view_prices := 1;
    END IF;
    
    l_token := apex_jwt.encode(
        p_iss       => 'ORDS',
        p_sub       => l_phone_clean,
        p_aud       => l_type_login,
        p_iat_ts    => SYSDATE,
        p_signature_key => sys.UTL_RAW.cast_to_raw('secretKey')
    );
    
    COMMIT;
    
    APEX_JSON.open_object;
    APEX_JSON.write('status', 'success');
    APEX_JSON.write('messageAr', 'تم تسجيل الدخول بنجاح', TRUE);
    APEX_JSON.write('messageEn', 'Login successful', TRUE);
    APEX_JSON.write('token', l_token, TRUE);
    APEX_JSON.write('userId', l_customer_id);
    APEX_JSON.write('userType', l_type_login, TRUE);
    APEX_JSON.write('code', l_code, TRUE);
    APEX_JSON.write('nameArabic', l_name_ar, TRUE);
    APEX_JSON.write('nameEnglish', l_name_en, TRUE);
    APEX_JSON.write('phone', l_phone_clean, TRUE);
    APEX_JSON.write('email', l_email, TRUE);
    APEX_JSON.write('locationLink', l_location_link, TRUE);
    APEX_JSON.write('governorate', l_governorate_name, TRUE);
    APEX_JSON.write('district', l_district_name, TRUE);
    APEX_JSON.write('fullAddress', l_full_address, TRUE);
    APEX_JSON.write('evaluation', l_evaluation_name, TRUE);
    APEX_JSON.write('balance', l_balance);
    APEX_JSON.write('address', l_address, TRUE);
    APEX_JSON.write('canViewPrices', l_can_view_prices);
    
    -- Permissions output
    APEX_JSON.write('canAccessStockApp', nvl(l_can_access_stock_app, 0));
    APEX_JSON.write('canPurchaseDelivery', nvl(l_can_purchase_delivery, 0));
    APEX_JSON.write('canReturnDelivery', nvl(l_can_return_delivery, 0));
    APEX_JSON.write('canStockCount', nvl(l_can_stock_count, 0));
    APEX_JSON.write('canViewItemCard', nvl(l_can_view_item_card, 0));
    APEX_JSON.write('canChangeLocation', nvl(l_can_change_location, 0));
    APEX_JSON.write('canReviewDeliveryInvoices', nvl(l_can_review_delivery_invoices, 0));
    
    -- بيانات إضافية لموظف العميل
    IF l_type_login = 'CUSTOMER_EMP' THEN
        APEX_JSON.write('jobTitle', l_job_title, TRUE);
        APEX_JSON.write('customerName', l_customer_name, TRUE);
        APEX_JSON.write('employeeId', l_user_id);
    END IF;
    
    IF l_is_test_mode THEN
        APEX_JSON.write('testMode', TRUE);
    END IF;
    APEX_JSON.close_object;
    :status := 200;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error');
        APEX_JSON.write('messageAr', 'حدث خطأ في النظام', TRUE);
        APEX_JSON.write('messageEn', 'System error: ' || SQLERRM, TRUE);
        APEX_JSON.write('errorCode', 'SYSTEM_ERROR', TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;
/

-- -------------------------------------------------------------
-- 4. APEX TRANSLATION MESSAGES FOR NEW PERMISSION COLUMNS
-- -------------------------------------------------------------
BEGIN
    -- CAN_ACCESS_STOCK_APP
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_ACCESS_STOCK_APP',
        p_language          => 'en',
        p_message_text      => 'Access Stock Application',
        p_used_in_javascript => TRUE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_ACCESS_STOCK_APP',
        p_language          => 'ar',
        p_message_text      => 'دخول تطبيق المخازن',
        p_used_in_javascript => TRUE
    );

    -- CAN_PURCHASE_DELIVERY
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_PURCHASE_DELIVERY',
        p_language          => 'en',
        p_message_text      => 'Purchase Deliveries',
        p_used_in_javascript => TRUE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_PURCHASE_DELIVERY',
        p_language          => 'ar',
        p_message_text      => 'تسليمات المشتريات',
        p_used_in_javascript => TRUE
    );

    -- CAN_RETURN_DELIVERY
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_RETURN_DELIVERY',
        p_language          => 'en',
        p_message_text      => 'Return Deliveries',
        p_used_in_javascript => TRUE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_RETURN_DELIVERY',
        p_language          => 'ar',
        p_message_text      => 'تسليمات المرتجعات',
        p_used_in_javascript => TRUE
    );

    -- CAN_STOCK_COUNT
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_STOCK_COUNT',
        p_language          => 'en',
        p_message_text      => 'Stock Counting / Inventory',
        p_used_in_javascript => TRUE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_STOCK_COUNT',
        p_language          => 'ar',
        p_message_text      => 'الجرد',
        p_used_in_javascript => TRUE
    );

    -- CAN_VIEW_ITEM_CARD
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_VIEW_ITEM_CARD',
        p_language          => 'en',
        p_message_text      => 'View Item Card',
        p_used_in_javascript => TRUE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_VIEW_ITEM_CARD',
        p_language          => 'ar',
        p_message_text      => 'كارت الصنف',
        p_used_in_javascript => TRUE
    );

    -- CAN_CHANGE_LOCATION
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_CHANGE_LOCATION',
        p_language          => 'en',
        p_message_text      => 'Change Location',
        p_used_in_javascript => TRUE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_CHANGE_LOCATION',
        p_language          => 'ar',
        p_message_text      => 'تغيير الموقع',
        p_used_in_javascript => TRUE
    );

    -- CAN_REVIEW_DELIVERY_INVOICES
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_REVIEW_DELIVERY_INVOICES',
        p_language          => 'en',
        p_message_text      => 'Review Delivery Invoices',
        p_used_in_javascript => TRUE
    );
    APEX_LANG.CREATE_MESSAGE (
        p_application_id    => 167,
        p_name              => 'CAN_REVIEW_DELIVERY_INVOICES',
        p_language          => 'ar',
        p_message_text      => 'مراجعة فواتير تسليم',
        p_used_in_javascript => TRUE
    );

    COMMIT;
END;
/
