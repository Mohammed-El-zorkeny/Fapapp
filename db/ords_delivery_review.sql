-- Generated ORDS REST Services for Delivery Review Module
-- Schema: ERP_STOCK
--

DECLARE
  l_roles     OWA.VC_ARR;
  l_modules   OWA.VC_ARR;
  l_patterns  OWA.VC_ARR;

BEGIN
  -- =============================================================
  -- MODULE: DeliveryReview
  -- =============================================================
  BEGIN
    ORDS.DELETE_MODULE(p_module_name => 'DeliveryReview');
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;

  ORDS.DEFINE_MODULE(
      p_module_name    => 'DeliveryReview',
      p_base_path      => '/DeliveryReview/',
      p_items_per_page => 25,
      p_status         => 'PUBLISHED',
      p_comments       => NULL);

  -- 1. Template: GetDeliveryMen (GET)
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'GetDeliveryMen',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'GetDeliveryMen',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_header_value    VARCHAR2(4000);
    l_bearer_token    VARCHAR2(4000);
    l_token           APEX_JWT.T_TOKEN;
    l_user_object     APEX_JSON.T_VALUES;
    l_phone           VARCHAR2(200);
    l_user_type       VARCHAR2(200);
    l_user_id         NUMBER;
    l_count           NUMBER := 0;
BEGIN
    -- Authentication Check
    l_header_value := OWA_UTIL.get_cgi_env(''Authorization'');
    IF l_header_value IS NULL OR INSTR(l_header_value, ''Bearer '') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''يرجى تسجيل الدخول أولاً'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', ''Authentication required'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW(''secretKey'')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => ''ORDS'');
        APEX_JSON.PARSE(l_user_object, l_token.payload);
        l_phone := APEX_JSON.GET_VARCHAR2(p_path => ''sub'', p_values => l_user_object);
        l_user_type := APEX_JSON.GET_VARCHAR2(p_path => ''aud'', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''جلسة غير صالحة'', p_write_null => TRUE);
            APEX_JSON.write(''messageEn'', ''Invalid token'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    :status := 200;
    APEX_JSON.open_object;
    APEX_JSON.write(''status'', ''success'', p_write_null => TRUE);
    APEX_JSON.open_array(''deliveryMen'');

    FOR rec IN (
        SELECT ID, NAME_AR 
        FROM DBS_SAL_SALES_MAN 
        WHERE SAL_MAN_OR_SAL_DE = ''MAN_DE'' AND STATUS = ''1''
        ORDER BY NAME_AR
    ) LOOP
        l_count := l_count + 1;
        APEX_JSON.open_object;
        APEX_JSON.write(''id'', rec.ID, p_write_null => TRUE);
        APEX_JSON.write(''nameAr'', rec.NAME_AR, p_write_null => TRUE);
        APEX_JSON.close_object;
    END LOOP;

    APEX_JSON.close_array;
    APEX_JSON.write(''total'', l_count, p_write_null => TRUE);
    APEX_JSON.close_object;
EXCEPTION
    WHEN OTHERS THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''حدث خطأ في النظام'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', SQLERRM, p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;');

  -- 2. Template: GetInvoicesByDate (GET)
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'GetInvoicesByDate',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'GetInvoicesByDate',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_header_value    VARCHAR2(4000);
    l_bearer_token    VARCHAR2(4000);
    l_token           APEX_JWT.T_TOKEN;
    l_user_object     APEX_JSON.T_VALUES;
    l_phone           VARCHAR2(200);
    l_user_type       VARCHAR2(200);
    l_delivery_date   VARCHAR2(100);
    l_count           NUMBER := 0;
BEGIN
    -- Authentication Check
    l_header_value := OWA_UTIL.get_cgi_env(''Authorization'');
    IF l_header_value IS NULL OR INSTR(l_header_value, ''Bearer '') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''يرجى تسجيل الدخول أولاً'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW(''secretKey'')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => ''ORDS'');
        APEX_JSON.PARSE(l_user_object, l_token.payload);
        l_phone := APEX_JSON.GET_VARCHAR2(p_path => ''sub'', p_values => l_user_object);
        l_user_type := APEX_JSON.GET_VARCHAR2(p_path => ''aud'', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''جلسة غير صالحة'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    -- Fetch date param or default to SYSDATE (today)
    l_delivery_date := :deliveryDate;
    IF l_delivery_date IS NULL THEN
        l_delivery_date := TO_CHAR(SYSDATE, ''YYYY-MM-DD'');
    END IF;

    :status := 200;
    APEX_JSON.open_object;
    APEX_JSON.write(''status'', ''success'', p_write_null => TRUE);
    APEX_JSON.open_array(''invoices'');

    FOR rec IN (
        SELECT 
            I.ID,
            I.AUTO_NUMBER,
            C.NAME_AR AS CUSTOMER_NAME,
            TO_CHAR(I.DELIVERY_DATE, ''YYYY-MM-DD'') AS DELIVERY_DATE,
            I.DELIVERY_STATUS,
            I.SALESMAN_DELIVERY_ID,
            M.NAME_AR AS SALESMAN_NAME,
            I.DELIVERY_NOTES,
            (SELECT COUNT(*) FROM DBS_SAL_INVOICE_DTL D WHERE D.DBS_SAL_INVOICE_ID = I.ID) AS ITEMS_COUNT
        FROM DBS_SAL_INVOICE I
        LEFT JOIN DBS_SAL_CUSTOMERS C ON I.DBS_SAL_CUSTOMERS_ID = C.ID
        LEFT JOIN DBS_SAL_SALES_MAN M ON I.SALESMAN_DELIVERY_ID = M.ID
        WHERE TO_CHAR(I.DELIVERY_DATE, ''YYYY-MM-DD'') = l_delivery_date
        ORDER BY I.ID DESC
    ) LOOP
        l_count := l_count + 1;
        
        -- Translate status code to Arabic string for display
        DECLARE
            l_status_ar VARCHAR2(200);
        BEGIN
            IF rec.DELIVERY_STATUS = ''PENDING_ASSIGNMENT'' THEN l_status_ar := ''في انتظار التخصيص للمندوب'';
            ELSIF rec.DELIVERY_STATUS = ''ASSIGNED'' THEN l_status_ar := ''تم تسليمها للمندوب'';
            ELSIF rec.DELIVERY_STATUS = ''OUT_FOR_DELIVERY'' THEN l_status_ar := ''خرجت للتوصيل'';
            ELSIF rec.DELIVERY_STATUS = ''DELIVERED_FULL'' THEN l_status_ar := ''تم التسليم بالكامل'';
            ELSIF rec.DELIVERY_STATUS = ''DELIVERED_PARTIAL'' THEN l_status_ar := ''تسليم جزئي بمرتجع'';
            ELSIF rec.DELIVERY_STATUS = ''REJECTED'' THEN l_status_ar := ''تم رفض الاستلام'';
            ELSIF rec.DELIVERY_STATUS = ''RETURNED'' THEN l_status_ar := ''مرتجعة للمستودع'';
            ELSE l_status_ar := rec.DELIVERY_STATUS;
            END IF;

            APEX_JSON.open_object;
            APEX_JSON.write(''id'', rec.ID, p_write_null => TRUE);
            APEX_JSON.write(''autoNumber'', rec.AUTO_NUMBER, p_write_null => TRUE);
            APEX_JSON.write(''customerName'', rec.CUSTOMER_NAME, p_write_null => TRUE);
            APEX_JSON.write(''deliveryDate'', rec.DELIVERY_DATE, p_write_null => TRUE);
            APEX_JSON.write(''itemsCount'', rec.ITEMS_COUNT, p_write_null => TRUE);
            APEX_JSON.write(''deliveryStatus'', rec.DELIVERY_STATUS, p_write_null => TRUE);
            APEX_JSON.write(''deliveryStatusAr'', l_status_ar, p_write_null => TRUE);
            APEX_JSON.write(''salesmanDeliveryId'', rec.SALESMAN_DELIVERY_ID, p_write_null => TRUE);
            APEX_JSON.write(''salesmanName'', rec.SALESMAN_NAME, p_write_null => TRUE);
            APEX_JSON.write(''deliveryNotes'', rec.DELIVERY_NOTES, p_write_null => TRUE);
            APEX_JSON.close_object;
        END;
    END LOOP;

    APEX_JSON.close_array;
    APEX_JSON.write(''total'', l_count, p_write_null => TRUE);
    APEX_JSON.close_object;
EXCEPTION
    WHEN OTHERS THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''حدث خطأ في جلب الفواتير'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', SQLERRM, p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;');

  -- 3. Template: GetInvoiceDetails (GET)
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'GetInvoiceDetails',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'GetInvoiceDetails',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_header_value    VARCHAR2(4000);
    l_bearer_token    VARCHAR2(4000);
    l_token           APEX_JWT.T_TOKEN;
    l_user_object     APEX_JSON.T_VALUES;
    l_phone           VARCHAR2(200);
    l_user_type       VARCHAR2(200);
    l_invoice_id      NUMBER;
    l_count           NUMBER := 0;
BEGIN
    -- Authentication Check
    l_header_value := OWA_UTIL.get_cgi_env(''Authorization'');
    IF l_header_value IS NULL OR INSTR(l_header_value, ''Bearer '') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''يرجى تسجيل الدخول أولاً'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW(''secretKey'')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => ''ORDS'');
        APEX_JSON.PARSE(l_user_object, l_token.payload);
        l_phone := APEX_JSON.GET_VARCHAR2(p_path => ''sub'', p_values => l_user_object);
        l_user_type := APEX_JSON.GET_VARCHAR2(p_path => ''aud'', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''جلسة غير صالحة'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    l_invoice_id := TO_NUMBER(:invoiceId);
    IF l_invoice_id IS NULL THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''رقم الفاتورة غير محدد'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 400;
        RETURN;
    END IF;

    :status := 200;
    APEX_JSON.open_object;
    APEX_JSON.write(''status'', ''success'', p_write_null => TRUE);
    APEX_JSON.open_array(''items'');

    FOR rec IN (
        SELECT 
            D.ID AS DETAIL_ID,
            I.ITEM_CODE,
            I.NAME_AR AS ITEM_NAME_AR,
            L.NAME_AR AS LOCATION_NAME,
            I.ITEM_SIDE,
            D.QTY,
            D.IS_DELIVERY_REVIEWED,
            D.DELIVERY_REVIEWED_BY
        FROM DBS_SAL_INVOICE_DTL D
        LEFT JOIN DBS_STOCK_ITEMS I ON D.DBS_STOCK_ITEMS_ID = I.ID
        LEFT JOIN DBS_STOCK_STORE_DTL_LOC L ON I.DBS_STOCK_STORE_DTL_LOC_ID = L.ID
        WHERE D.DBS_SAL_INVOICE_ID = l_invoice_id
        ORDER BY D.ID
    ) LOOP
        l_count := l_count + 1;
        APEX_JSON.open_object;
        APEX_JSON.write(''detailId'', rec.DETAIL_ID, p_write_null => TRUE);
        APEX_JSON.write(''itemCode'', rec.ITEM_CODE, p_write_null => TRUE);
        APEX_JSON.write(''itemNameAr'', rec.ITEM_NAME_AR, p_write_null => TRUE);
        APEX_JSON.write(''locationName'', rec.LOCATION_NAME, p_write_null => TRUE);
        APEX_JSON.write(''itemSide'', rec.ITEM_SIDE, p_write_null => TRUE);
        APEX_JSON.write(''qty'', rec.QTY, p_write_null => TRUE);
        APEX_JSON.write(''isDeliveryReviewed'', rec.IS_DELIVERY_REVIEWED, p_write_null => TRUE);
        APEX_JSON.write(''reviewedBy'', rec.DELIVERY_REVIEWED_BY, p_write_null => TRUE);
        APEX_JSON.close_object;
    END LOOP;

    APEX_JSON.close_array;
    APEX_JSON.write(''total'', l_count, p_write_null => TRUE);
    APEX_JSON.close_object;
EXCEPTION
    WHEN OTHERS THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''حدث خطأ في جلب تفاصيل الفاتورة'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', SQLERRM, p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;');

  -- 4. Template: UpdateInvoiceDelivery (POST)
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'UpdateInvoiceDelivery',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'UpdateInvoiceDelivery',
      p_method         => 'POST',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_header_value      VARCHAR2(4000);
    l_bearer_token      VARCHAR2(4000);
    l_token             APEX_JWT.T_TOKEN;
    l_user_object       APEX_JSON.T_VALUES;
    l_phone             VARCHAR2(200);
    l_user_type         VARCHAR2(200);
    
    l_invoice_id        NUMBER;
    l_salesman_id       NUMBER;
    l_status            VARCHAR2(100);
    l_notes             VARCHAR2(4000);
BEGIN
    -- Authentication Check
    l_header_value := OWA_UTIL.get_cgi_env(''Authorization'');
    IF l_header_value IS NULL OR INSTR(l_header_value, ''Bearer '') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''يرجى تسجيل الدخول أولاً'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW(''secretKey'')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => ''ORDS'');
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''جلسة غير صالحة'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    -- Read POST JSON parameters
    l_invoice_id  := TO_NUMBER(:invoiceId);
    l_salesman_id := TO_NUMBER(:salesmanDeliveryId);
    l_status      := :deliveryStatus;
    l_notes       := :deliveryNotes;

    IF l_invoice_id IS NULL OR l_status IS NULL THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''بيانات الفاتورة أو الحالة ناقصة'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 400;
        RETURN;
    END IF;

    UPDATE DBS_SAL_INVOICE
    SET SALESMAN_DELIVERY_ID = l_salesman_id,
        DELIVERY_STATUS = l_status,
        DELIVERY_NOTES = l_notes,
        END_TIME = CASE 
            WHEN l_status IN (''DELIVERED_FULL'', ''DELIVERED_PARTIAL'', ''REJECTED'', ''RETURNED'') AND END_TIME IS NULL 
            THEN SYSTIMESTAMP 
            ELSE END_TIME 
        END,
        TOTAL_DURATION_MINUTES = CASE 
            WHEN l_status IN (''DELIVERED_FULL'', ''DELIVERED_PARTIAL'', ''REJECTED'', ''RETURNED'') AND TOTAL_DURATION_MINUTES IS NULL AND START_TIME IS NOT NULL 
            THEN EXTRACT(DAY FROM (SYSTIMESTAMP - START_TIME))*1440 + EXTRACT(HOUR FROM (SYSTIMESTAMP - START_TIME))*60 + EXTRACT(MINUTE FROM (SYSTIMESTAMP - START_TIME))
            ELSE TOTAL_DURATION_MINUTES 
        END
    WHERE ID = l_invoice_id;
    COMMIT;

    APEX_JSON.open_object;
    APEX_JSON.write(''status'', ''success'', p_write_null => TRUE);
    APEX_JSON.write(''messageAr'', ''تم تحديث بيانات التسليم للفاتورة بنجاح'', p_write_null => TRUE);
    APEX_JSON.close_object;
    :status := 200;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''حدث خطأ أثناء التحديث'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', SQLERRM, p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;');

  -- 5. Template: UpdateItemReview (POST)
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'UpdateItemReview',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'UpdateItemReview',
      p_method         => 'POST',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_header_value      VARCHAR2(4000);
    l_bearer_token      VARCHAR2(4000);
    l_token             APEX_JWT.T_TOKEN;
    l_user_object       APEX_JSON.T_VALUES;
    l_phone             VARCHAR2(200);
    l_user_type         VARCHAR2(200);
    l_user_id           NUMBER;
    
    l_invoice_id        NUMBER;
    l_detail_id         NUMBER;
    l_is_reviewed       NUMBER;
    l_review_all        BOOLEAN := FALSE;
    l_review_all_str    VARCHAR2(100);
BEGIN
    -- Authentication Check
    l_header_value := OWA_UTIL.get_cgi_env(''Authorization'');
    IF l_header_value IS NULL OR INSTR(l_header_value, ''Bearer '') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''يرجى تسجيل الدخول أولاً'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW(''secretKey'')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => ''ORDS'');
        APEX_JSON.PARSE(l_user_object, l_token.payload);
        l_phone := APEX_JSON.GET_VARCHAR2(p_path => ''sub'', p_values => l_user_object);
        l_user_type := APEX_JSON.GET_VARCHAR2(p_path => ''aud'', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''جلسة غير صالحة'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    -- Get login user ID
    BEGIN
        SELECT ID INTO l_user_id
        FROM VW_API_ENTRY_LOGIN
        WHERE PHONE_NUMBER = l_phone AND TYPE_LOGIN = l_user_type AND STATUS = ''1'' AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''المستخدم غير موجود'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 404;
            RETURN;
    END;

    -- Read POST JSON parameters
    l_invoice_id   := TO_NUMBER(:invoiceId);
    l_detail_id    := TO_NUMBER(:detailId);
    l_is_reviewed  := TO_NUMBER(:isReviewed);
    l_review_all_str := LOWER(:reviewAll);
    
    IF l_review_all_str = ''true'' OR l_review_all_str = ''1'' THEN
        l_review_all := TRUE;
    END IF;

    IF l_invoice_id IS NULL OR l_is_reviewed IS NULL THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''المعاملات المرسلة غير كاملة'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 400;
        RETURN;
    END IF;

    IF l_review_all THEN
        UPDATE DBS_SAL_INVOICE_DTL
        SET IS_DELIVERY_REVIEWED = l_is_reviewed,
            DELIVERY_REVIEWED_BY = l_user_id
        WHERE DBS_SAL_INVOICE_ID = l_invoice_id;
    ELSE
        IF l_detail_id IS NULL THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''يرجى تحديد كود الصنف المراجع'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 400;
            RETURN;
        END IF;
        
        UPDATE DBS_SAL_INVOICE_DTL
        SET IS_DELIVERY_REVIEWED = l_is_reviewed,
            DELIVERY_REVIEWED_BY = l_user_id
        WHERE ID = l_detail_id AND DBS_SAL_INVOICE_ID = l_invoice_id;
    END IF;
    COMMIT;

    APEX_JSON.open_object;
    APEX_JSON.write(''status'', ''success'', p_write_null => TRUE);
    IF l_review_all THEN
        APEX_JSON.write(''messageAr'', ''تمت مراجعة جميع الأصناف بنجاح'', p_write_null => TRUE);
    ELSE
        APEX_JSON.write(''messageAr'', ''تمت مراجعة الصنف بنجاح'', p_write_null => TRUE);
    END IF;
    APEX_JSON.close_object;
    :status := 200;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''حدث خطأ أثناء تحديث المراجعة'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', SQLERRM, p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;');

  -- 6. Template: GetSalesmanInvoices (GET)
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'GetSalesmanInvoices',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'GetSalesmanInvoices',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_header_value    VARCHAR2(4000);
    l_bearer_token    VARCHAR2(4000);
    l_token           APEX_JWT.T_TOKEN;
    l_user_object     APEX_JSON.T_VALUES;
    l_phone           VARCHAR2(200);
    l_user_type       VARCHAR2(200);
    l_salesman_id     NUMBER;
    l_delivery_date   VARCHAR2(100);
    l_count           NUMBER := 0;
BEGIN
    -- Authentication Check
    l_header_value := OWA_UTIL.get_cgi_env(''Authorization'');
    IF l_header_value IS NULL OR INSTR(l_header_value, ''Bearer '') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''يرجى تسجيل الدخول أولاً'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW(''secretKey'')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => ''ORDS'');
        APEX_JSON.PARSE(l_user_object, l_token.payload);
        l_phone := APEX_JSON.GET_VARCHAR2(p_path => ''sub'', p_values => l_user_object);
        l_user_type := APEX_JSON.GET_VARCHAR2(p_path => ''aud'', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''جلسة غير صالحة'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    -- Resolve Salesman ID using login phone
    BEGIN
        SELECT ID INTO l_salesman_id
        FROM DBS_SAL_SALES_MAN
        WHERE PHONE_NUMBER = l_phone AND STATUS = ''1'' AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''المندوب غير مسجل بقاعدة البيانات'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 404;
            RETURN;
    END;

    -- Fetch deliveryDate param or default to SYSDATE (today)
    l_delivery_date := :deliveryDate;
    IF l_delivery_date IS NULL THEN
        l_delivery_date := TO_CHAR(SYSDATE, ''YYYY-MM-DD'');
    END IF;

    :status := 200;
    APEX_JSON.open_object;
    APEX_JSON.write(''status'', ''success'', p_write_null => TRUE);
    APEX_JSON.open_array(''invoices'');

    FOR rec IN (
        SELECT 
            I.ID,
            I.AUTO_NUMBER,
            C.NAME_AR AS CUSTOMER_NAME,
            TO_CHAR(I.DELIVERY_DATE, ''YYYY-MM-DD'') AS DELIVERY_DATE,
            I.DELIVERY_STATUS,
            I.DELIVERY_NOTES,
            C.LOCATION_LINK,
            C.GOVERNORATE_NAME,
            C.DISTRICT_NAME,
            C.FULL_ADDRESS,
            (SELECT COUNT(*) FROM DBS_SAL_INVOICE_DTL D WHERE D.DBS_SAL_INVOICE_ID = I.ID) AS ITEMS_COUNT
        FROM DBS_SAL_INVOICE I
        LEFT JOIN DBS_SAL_CUSTOMERS C ON I.DBS_SAL_CUSTOMERS_ID = C.ID
        WHERE I.SALESMAN_DELIVERY_ID = l_salesman_id
          AND TO_CHAR(I.DELIVERY_DATE, ''YYYY-MM-DD'') = l_delivery_date
        ORDER BY I.ID DESC
    ) LOOP
        l_count := l_count + 1;
        DECLARE
            l_status_ar VARCHAR2(200);
        BEGIN
            IF rec.DELIVERY_STATUS = ''PENDING_ASSIGNMENT'' THEN l_status_ar := ''في انتظار التخصيص للمندوب'';
            ELSIF rec.DELIVERY_STATUS = ''ASSIGNED'' THEN l_status_ar := ''تم تسليمها للمندوب'';
            ELSIF rec.DELIVERY_STATUS = ''OUT_FOR_DELIVERY'' THEN l_status_ar := ''خرجت للتوصيل'';
            ELSIF rec.DELIVERY_STATUS = ''DELIVERED_FULL'' THEN l_status_ar := ''تم التسليم بالكامل'';
            ELSIF rec.DELIVERY_STATUS = ''DELIVERED_PARTIAL'' THEN l_status_ar := ''تسليم جزئي بمرتجع'';
            ELSIF rec.DELIVERY_STATUS = ''REJECTED'' THEN l_status_ar := ''تم رفض الاستلام'';
            ELSIF rec.DELIVERY_STATUS = ''RETURNED'' THEN l_status_ar := ''مرتجعة للمستودع'';
            ELSE l_status_ar := rec.DELIVERY_STATUS;
            END IF;

            APEX_JSON.open_object;
            APEX_JSON.write(''id'', rec.ID, p_write_null => TRUE);
            APEX_JSON.write(''autoNumber'', rec.AUTO_NUMBER, p_write_null => TRUE);
            APEX_JSON.write(''customerName'', rec.CUSTOMER_NAME, p_write_null => TRUE);
            APEX_JSON.write(''deliveryDate'', rec.DELIVERY_DATE, p_write_null => TRUE);
            APEX_JSON.write(''deliveryStatus'', rec.DELIVERY_STATUS, p_write_null => TRUE);
            APEX_JSON.write(''deliveryStatusAr'', l_status_ar, p_write_null => TRUE);
            APEX_JSON.write(''deliveryNotes'', rec.DELIVERY_NOTES, p_write_null => TRUE);
            APEX_JSON.write(''locationLink'', rec.LOCATION_LINK, p_write_null => TRUE);
            APEX_JSON.write(''governorateName'', rec.GOVERNORATE_NAME, p_write_null => TRUE);
            APEX_JSON.write(''districtName'', rec.DISTRICT_NAME, p_write_null => TRUE);
            APEX_JSON.write(''fullAddress'', rec.FULL_ADDRESS, p_write_null => TRUE);
            APEX_JSON.write(''itemsCount'', rec.ITEMS_COUNT, p_write_null => TRUE);
            APEX_JSON.close_object;
        END;
    END LOOP;

    APEX_JSON.close_array;
    APEX_JSON.write(''total'', l_count, p_write_null => TRUE);
    APEX_JSON.close_object;
EXCEPTION
    WHEN OTHERS THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''حدث خطأ في جلب فواتير المندوب'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', SQLERRM, p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;');

  -- 7. Template: StartDeliveryJourney (POST)
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'StartDeliveryJourney',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'StartDeliveryJourney',
      p_method         => 'POST',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_header_value    VARCHAR2(4000);
    l_bearer_token    VARCHAR2(4000);
    l_token           APEX_JWT.T_TOKEN;
    l_user_object     APEX_JSON.T_VALUES;
    l_phone           VARCHAR2(200);
    l_salesman_id     NUMBER;
    
    l_invoice_id      NUMBER;
    l_lat             NUMBER;
    l_lng             NUMBER;
BEGIN
    l_header_value := OWA_UTIL.get_cgi_env(''Authorization'');
    IF l_header_value IS NULL OR INSTR(l_header_value, ''Bearer '') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''يرجى تسجيل الدخول أولاً'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW(''secretKey'')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => ''ORDS'');
        APEX_JSON.PARSE(l_user_object, l_token.payload);
        l_phone := APEX_JSON.GET_VARCHAR2(p_path => ''sub'', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''جلسة غير صالحة'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    SELECT ID INTO l_salesman_id FROM DBS_SAL_SALES_MAN WHERE PHONE_NUMBER = l_phone AND STATUS = ''1'' AND ROWNUM = 1;

    l_invoice_id := :invoiceId;
    l_lat := :latitude;
    l_lng := :longitude;

    UPDATE DBS_SAL_INVOICE
    SET START_LAT = l_lat,
        START_LONG = l_lng,
        START_TIME = SYSTIMESTAMP,
        DELIVERY_STATUS = ''OUT_FOR_DELIVERY''
    WHERE ID = l_invoice_id;

    COMMIT;

    APEX_JSON.open_object;
    APEX_JSON.write(''status'', ''success'', p_write_null => TRUE);
    APEX_JSON.write(''messageAr'', ''تم بدء رحلة التوصيل بنجاح'', p_write_null => TRUE);
    APEX_JSON.close_object;
    :status := 200;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''حدث خطأ أثناء بدء الرحلة'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', SQLERRM, p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;');

  -- 8. Template: AddTrackingPoint (POST)
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'AddTrackingPoint',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'AddTrackingPoint',
      p_method         => 'POST',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_header_value    VARCHAR2(4000);
    l_bearer_token    VARCHAR2(4000);
    l_token           APEX_JWT.T_TOKEN;
    l_user_object     APEX_JSON.T_VALUES;
    l_phone           VARCHAR2(200);
    l_salesman_id     NUMBER;
    
    l_invoice_id      NUMBER;
    l_lat             NUMBER;
    l_lng             NUMBER;
    l_bearing         NUMBER;
    l_battery_level   NUMBER;
    l_is_charging     VARCHAR2(10);
    l_charging_char   CHAR(1);
BEGIN
    l_header_value := OWA_UTIL.get_cgi_env(''Authorization'');
    IF l_header_value IS NULL OR INSTR(l_header_value, ''Bearer '') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''يرجى تسجيل الدخول أولاً'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW(''secretKey'')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => ''ORDS'');
        APEX_JSON.PARSE(l_user_object, l_token.payload);
        l_phone := APEX_JSON.GET_VARCHAR2(p_path => ''sub'', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''جلسة غير صالحة'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    SELECT ID INTO l_salesman_id FROM DBS_SAL_SALES_MAN WHERE PHONE_NUMBER = l_phone AND STATUS = ''1'' AND ROWNUM = 1;

    l_invoice_id    := :invoiceId;
    l_lat           := :latitude;
    l_lng           := :longitude;
    l_bearing       := :bearing;
    l_battery_level := :batteryLevel;
    l_is_charging   := :isCharging;

    IF l_is_charging = ''true'' OR l_is_charging = ''Y'' THEN
        l_charging_char := ''Y'';
    ELSE
        l_charging_char := ''N'';
    END IF;

    INSERT INTO DBS_SALESMAN_PATH_TRACK (
        INVOICE_ID, SALESMAN_ID, LATITUDE, LONGITUDE, BEARING, TRACK_TIME, BATTERY_LEVEL, IS_CHARGING
    ) VALUES (
        l_invoice_id, l_salesman_id, l_lat, l_lng, NVL(l_bearing, 0.0), SYSTIMESTAMP, l_battery_level, l_charging_char
    );

    COMMIT;

    APEX_JSON.open_object;
    APEX_JSON.write(''status'', ''success'', p_write_null => TRUE);
    APEX_JSON.write(''messageAr'', ''تم تسجيل نقطة التتبع'', p_write_null => TRUE);
    APEX_JSON.close_object;
    :status := 200;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''حدث خطأ أثناء تسجيل نقطة التتبع'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', SQLERRM, p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;');

  -- 9. Template: EndDeliveryJourney (POST)
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'EndDeliveryJourney',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'EndDeliveryJourney',
      p_method         => 'POST',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_header_value    VARCHAR2(4000);
    l_bearer_token    VARCHAR2(4000);
    l_token           APEX_JWT.T_TOKEN;
    l_user_object     APEX_JSON.T_VALUES;
    l_phone           VARCHAR2(200);
    l_salesman_id     NUMBER;
    
    l_invoice_id      NUMBER;
    l_lat             NUMBER;
    l_lng             NUMBER;
    l_total_km        NUMBER;
    l_total_minutes   NUMBER;
    l_status          VARCHAR2(100);
    l_notes           VARCHAR2(4000);
BEGIN
    l_header_value := OWA_UTIL.get_cgi_env(''Authorization'');
    IF l_header_value IS NULL OR INSTR(l_header_value, ''Bearer '') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''يرجى تسجيل الدخول أولاً'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW(''secretKey'')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => ''ORDS'');
        APEX_JSON.PARSE(l_user_object, l_token.payload);
        l_phone := APEX_JSON.GET_VARCHAR2(p_path => ''sub'', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''جلسة غير صالحة'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    SELECT ID INTO l_salesman_id FROM DBS_SAL_SALES_MAN WHERE PHONE_NUMBER = l_phone AND STATUS = ''1'' AND ROWNUM = 1;

    l_invoice_id    := :invoiceId;
    l_lat           := :latitude;
    l_total_km      := :totalKm;
    l_total_minutes := :totalMinutes;
    l_status        := :deliveryStatus;
    l_notes         := :notes;

    UPDATE DBS_SAL_INVOICE
    SET END_LAT = l_lat,
        END_LONG = :longitude,
        END_TIME = SYSTIMESTAMP,
        TOTAL_KILOMETERS = l_total_km,
        TOTAL_DURATION_MINUTES = l_total_minutes,
        DELIVERY_STATUS = l_status,
        DELIVERY_NOTES = NVL(l_notes, DELIVERY_NOTES)
    WHERE ID = l_invoice_id;

    COMMIT;

    APEX_JSON.open_object;
    APEX_JSON.write(''status'', ''success'', p_write_null => TRUE);
    APEX_JSON.write(''messageAr'', ''تم إنهاء الرحلة وتحديث حالة الفاتورة بنجاح'', p_write_null => TRUE);
    APEX_JSON.close_object;
    :status := 200;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''حدث خطأ أثناء إنهاء الرحلة'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', SQLERRM, p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;');

END;
