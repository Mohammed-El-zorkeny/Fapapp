-- ============================================================
-- ORDS Handler: POST /auth/UpdateDeviceToken
-- الوظيفة: تسجيل FCM token للجهاز + طرد الجهاز القديم تلقائياً
-- ============================================================

DECLARE
    l_header_value    VARCHAR2(4000);
    l_bearer_token    VARCHAR2(4000);
    l_token           APEX_JWT.T_TOKEN;
    l_user_object     APEX_JSON.T_VALUES;
    l_phone           VARCHAR2(200);
    l_user_type       VARCHAR2(200);
    l_user_id         NUMBER;
    l_body            CLOB;
    l_body_values     APEX_JSON.T_VALUES;
    l_device_token    VARCHAR2(500);
    l_device_type     VARCHAR2(10);
    l_app_version     VARCHAR2(20);
    l_old_token       VARCHAR2(500);

BEGIN
    -- ── 1. قراءة والتحقق من الـ JWT Token ──────────────────────
    l_header_value := OWA_UTIL.get_cgi_env('Authorization');

    IF l_header_value IS NULL OR INSTR(l_header_value, 'Bearer ') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status',    'error',                    p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'يرجى تسجيل الدخول أولاً', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'Authentication required',  p_write_null => TRUE);
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

        IF NOT APEX_JSON.DOES_EXIST(p_path => 'sub', p_values => l_user_object) THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status',    'error',          p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'Token غير صالح', p_write_null => TRUE);
            APEX_JSON.write('messageEn', 'Invalid token',  p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'INVALID_TOKEN',  p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
        END IF;

        l_phone     := APEX_JSON.GET_VARCHAR2(p_path => 'sub', p_values => l_user_object);
        l_user_type := APEX_JSON.GET_VARCHAR2(p_path => 'aud', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status',    'error',                          p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'جلسة غير صالحة',                p_write_null => TRUE);
            APEX_JSON.write('messageEn', 'Invalid token: ' || SQLERRM,    p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'INVALID_TOKEN',                  p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    -- ── 2. جلب بيانات المستخدم ─────────────────────────────────
    BEGIN
        SELECT ID INTO l_user_id
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
            APEX_JSON.write('messageEn', 'User not found',      p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'USER_NOT_FOUND',      p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 404;
            RETURN;
    END;

    -- ── 3. قراءة الـ Body ──────────────────────────────────────
    l_body := :body_text;

    IF l_body IS NULL THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status',    'error',                       p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'لم نتمكن من قراءة البيانات', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'Body is null',                p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'INVALID_REQUEST',             p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 400;
        RETURN;
    END IF;

    APEX_JSON.PARSE(l_body_values, l_body);

    l_device_token := APEX_JSON.GET_VARCHAR2(p_path => 'deviceToken', p_values => l_body_values);
    l_device_type  := APEX_JSON.GET_VARCHAR2(p_path => 'deviceType',  p_values => l_body_values);
    l_app_version  := APEX_JSON.GET_VARCHAR2(p_path => 'appVersion',  p_values => l_body_values);

    IF l_device_token IS NULL THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status',    'error',              p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'رمز الجهاز مطلوب',  p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'Device token is required', p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'MISSING_PARAM',      p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 400;
        RETURN;
    END IF;

    -- ── 4. Single Session: طرد الجهاز القديم ──────────────────
    --
    -- لو المستخدم عنده token قديم مختلف عن الجديد
    -- معناه إنه فتح على جهاز تاني → نبعتله FORCE_LOGOUT
    --
    BEGIN
        SELECT DEVICE_TOKEN
        INTO   l_old_token
        FROM   FCM_USER_TOKENS
        WHERE  USER_ID   = l_user_id
        AND    USER_TYPE = l_user_type;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_old_token := NULL; -- مستخدم جديد، مفيش token قديم
    END;

    IF l_old_token IS NOT NULL AND l_old_token != l_device_token THEN
        PKG_APP_NOTIFICATIONS.SEND_NOTIFICATION(
            p_user_id      => l_user_id,
            p_user_type    => l_user_type,
            p_title        => 'تنبيه أمني',
            p_body         => 'تم تسجيل الدخول من جهاز آخر، سيتم تسجيل خروجك تلقائياً.',
            p_screen_name  => 'FORCE_LOGOUT'
        );
    END IF;

    -- ── 5. حفظ الـ Token الجديد ────────────────────────────────
    MERGE INTO FCM_USER_TOKENS t
    USING (SELECT l_user_id AS USER_ID, l_user_type AS USER_TYPE FROM DUAL) s
    ON (t.USER_ID = s.USER_ID AND t.USER_TYPE = s.USER_TYPE)
    WHEN MATCHED THEN
        UPDATE SET
            DEVICE_TOKEN = l_device_token,
            PHONE_NUMBER = l_phone,
            DEVICE_TYPE  = l_device_type,
            APP_VERSION  = l_app_version,
            UPDATED      = SYSDATE,
            UPDATED_BY   = l_user_id
    WHEN NOT MATCHED THEN
        INSERT (USER_ID, USER_TYPE, PHONE_NUMBER, DEVICE_TOKEN, DEVICE_TYPE, APP_VERSION, CREATED, CREATED_BY)
        VALUES (l_user_id, l_user_type, l_phone, l_device_token, l_device_type, l_app_version, SYSDATE, l_user_id);

    COMMIT;

    -- ── 6. Response ────────────────────────────────────────────
    :status := 200;
    APEX_JSON.open_object;
    APEX_JSON.write('status',      'success',                        p_write_null => TRUE);
    APEX_JSON.write('messageAr',   'تم تحديث رمز الجهاز بنجاح',     p_write_null => TRUE);
    APEX_JSON.write('messageEn',   'Device token updated successfully', p_write_null => TRUE);
    APEX_JSON.write('userId',      l_user_id,                        p_write_null => TRUE);
    APEX_JSON.write('userType',    l_user_type,                      p_write_null => TRUE);
    APEX_JSON.write('deviceType',  l_device_type,                    p_write_null => TRUE);
    APEX_JSON.write('appVersion',  l_app_version,                    p_write_null => TRUE);
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
