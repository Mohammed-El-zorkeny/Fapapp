-- ============================================================
-- ORDS Handler: POST /auth/BlockOnScreenshot
-- الوظيفة: قفل حساب المستخدم تلقائياً بعد تجاوز حد الـ screenshots
-- يُستدعى من التطبيق بتوكن المستخدم نفسه (مش Admin)
-- ============================================================

DECLARE
    l_header_value  VARCHAR2(4000);
    l_bearer_token  VARCHAR2(4000);
    l_token         APEX_JWT.T_TOKEN;
    l_user_object   APEX_JSON.T_VALUES;
    l_phone         VARCHAR2(200);
    l_user_type     VARCHAR2(200);
    l_user_id       NUMBER;
    l_user_name     VARCHAR2(250);

BEGIN
    -- ── 1. التحقق من الـ JWT ────────────────────────────────────
    l_header_value := OWA_UTIL.get_cgi_env('Authorization');

    IF l_header_value IS NULL OR INSTR(l_header_value, 'Bearer ') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status',    'error',                    p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'يرجى تسجيل الدخول أولاً', p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'TOKEN_REQUIRED',           p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);

    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value         => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW('secretKey')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => 'ORDS');
        APEX_JSON.PARSE(l_user_object, l_token.payload);

        l_phone     := APEX_JSON.GET_VARCHAR2(p_path => 'sub', p_values => l_user_object);
        l_user_type := APEX_JSON.GET_VARCHAR2(p_path => 'aud', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status',    'error',           p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'جلسة غير صالحة', p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'INVALID_TOKEN',   p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    -- ── 2. جلب بيانات المستخدم ─────────────────────────────────
    BEGIN
        SELECT ID, NAME_AR
        INTO   l_user_id, l_user_name
        FROM   VW_API_ENTRY_LOGIN
        WHERE  PHONE_NUMBER = l_phone
        AND    TYPE_LOGIN   = l_user_type
        AND    STATUS       = '1'
        AND    ROWNUM       = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status',    'error',               p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'المستخدم غير موجود', p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'USER_NOT_FOUND',      p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 404;
            RETURN;
    END;

    -- ── 3. قفل الحساب حسب النوع ────────────────────────────────
    IF l_user_type = 'CUSTOMER' THEN
        UPDATE DBS_SAL_CUSTOMERS
        SET STATUS = 0
        WHERE PHONE_NUMBER = l_phone;

    ELSIF l_user_type = 'CUSTOMER_EMP' THEN
        UPDATE DBS_SAL_CUSTOMERS_USERS
        SET STATUS = 0
        WHERE PHONE_NUMBER = l_phone;

    ELSIF l_user_type = 'SALESMAN' THEN
        UPDATE DBS_SAL_SALES_MAN
        SET STATUS = 0
        WHERE PHONE_NUMBER = l_phone;

    ELSIF l_user_type IN ('ADMIN', 'MANSTOCK') THEN
        UPDATE SEC_USERS
        SET STATUS = '0'
        WHERE PHONE = l_phone;
    END IF;

    -- ── 4. مسح الـ FCM Token ────────────────────────────────────
    DELETE FROM FCM_USER_TOKENS
    WHERE PHONE_NUMBER = l_phone;

    -- ── 5. تسجيل السبب في جدول الإشعارات ──────────────────────
    INSERT INTO APP_NOTIFICATIONS_LOG (
        USER_ID, USER_TYPE, PHONE_NUMBER, TOKEN_ID,
        TITLE, BODY, SCREEN_NAME, REFERENCE_ID,
        IS_READ, STATUS
    ) VALUES (
        l_user_id, l_user_type, l_phone, NULL,
        'قفل تلقائي', 'تم قفل الحساب بسبب تجاوز حد التقاط الشاشة',
        'FORCE_LOGOUT', NULL,
        0, 'SENT'
    );

    COMMIT;

    -- ── 6. Response ────────────────────────────────────────────
    :status := 200;
    APEX_JSON.open_object;
    APEX_JSON.write('status',    'success',                                          p_write_null => TRUE);
    APEX_JSON.write('messageAr', 'تم قفل الحساب بسبب تجاوز حد التقاط الشاشة',      p_write_null => TRUE);
    APEX_JSON.write('messageEn', 'Account blocked due to screenshot abuse',          p_write_null => TRUE);
    APEX_JSON.write('userId',    l_user_id,                                          p_write_null => TRUE);
    APEX_JSON.write('userName',  l_user_name,                                        p_write_null => TRUE);
    APEX_JSON.close_object;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        APEX_JSON.open_object;
        APEX_JSON.write('status',    'error',                     p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'حدث خطأ في النظام',         p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'System error: ' || SQLERRM, p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'SYSTEM_ERROR',              p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;
/
