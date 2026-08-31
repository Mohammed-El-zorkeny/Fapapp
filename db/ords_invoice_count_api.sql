-- =============================================================
-- ORDS REST APIs FOR SALES INVOICE QUANTITY COUNTING & REVIEW MODULE
-- Schema: ERP_STOCK
-- Module: DeliveryReview
-- =============================================================

DECLARE
  l_roles     OWA.VC_ARR;
  l_modules   OWA.VC_ARR;
  l_patterns  OWA.VC_ARR;

BEGIN

  -- =============================================================
  -- 1. API Endpoint: SaveItemCount (POST)
  -- URL Path: /DeliveryReview/SaveItemCount
  -- Body Parameters: invoiceId, detailId, qtyCounted, notes (optional)
  -- =============================================================
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'SaveItemCount',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => 'Save or update item quantity count and review status');

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'SaveItemCount',
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
    l_user_type       VARCHAR2(200);
    l_user_id         NUMBER;
    
    l_invoice_id      NUMBER;
    l_detail_id       NUMBER;
    l_qty_counted     NUMBER;
    l_notes           VARCHAR2(1000);
    
    l_item_id         NUMBER;
    l_qty_invoice     NUMBER;
    l_location_id     NUMBER;
    l_difference      NUMBER;
    l_review_status   VARCHAR2(30);
    l_is_reviewed     NUMBER := 0;
BEGIN
    -- 1. Authentication Check
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

    -- Get user ID
    BEGIN
        SELECT ID INTO l_user_id
        FROM VW_API_ENTRY_LOGIN
        WHERE PHONE_NUMBER = l_phone AND TYPE_LOGIN = l_user_type AND STATUS = ''1'' AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_user_id := 0;
    END;

    -- 2. Read Request Parameters
    l_invoice_id  := :invoiceId;
    l_detail_id   := :detailId;
    l_qty_counted := NVL(:qtyCounted, 0);
    l_notes       := :notes;

    IF l_invoice_id IS NULL OR l_detail_id IS NULL THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''بيانات الفاتورة أو البند غير مكتملة'', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 400;
        RETURN;
    END IF;

    -- 3. Fetch original detail item info
    BEGIN
        SELECT 
            DBS_STOCK_ITEMS_ID, 
            QTY, 
            DBS_STOCK_STORE_DTL_LOC_ID 
        INTO 
            l_item_id, 
            l_qty_invoice, 
            l_location_id
        FROM DBS_SAL_INVOICE_DTL
        WHERE ID = l_detail_id AND DBS_SAL_INVOICE_ID = l_invoice_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''بند الفاتورة غير موجود'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 444;
            RETURN;
    END;

    -- 4. Calculate status & difference
    l_difference := l_qty_counted - l_qty_invoice;
    IF l_qty_counted = l_qty_invoice THEN
        l_review_status := ''MATCHED'';
        l_is_reviewed   := 1;
    ELSIF l_qty_counted < l_qty_invoice THEN
        l_review_status := ''SHORTAGE'';
        l_is_reviewed   := 0;
    ELSE
        l_review_status := ''SURPLUS'';
        l_is_reviewed   := 0;
    END IF;

    -- 5. Upsert Count Record in DBS_SAL_INVOICE_COUNT_DTL
    MERGE INTO DBS_SAL_INVOICE_COUNT_DTL T
    USING (
        SELECT 
            l_invoice_id AS inv_id, 
            l_detail_id AS dtl_id 
        FROM DUAL
    ) S
    ON (T.DBS_SAL_INVOICE_ID = S.inv_id AND T.DBS_SAL_INVOICE_DTL_ID = S.dtl_id)
    WHEN MATCHED THEN
        UPDATE SET 
            T.QTY_COUNTED          = l_qty_counted,
            T.REVIEW_STATUS        = l_review_status,
            T.IS_DELIVERY_REVIEWED = l_is_reviewed,
            T.USER_ID              = l_user_id,
            T.LOCATION_ID          = l_location_id,
            T.NOTES                = l_notes,
            T.COUNT_DATE           = SYSDATE,
            T.UPDATED              = SYSDATE
    WHEN NOT MATCHED THEN
        INSERT (
            DBS_SAL_INVOICE_ID,
            DBS_SAL_INVOICE_DTL_ID,
            DBS_STOCK_ITEMS_ID,
            USER_ID,
            QTY_INVOICE,
            QTY_COUNTED,
            REVIEW_STATUS,
            IS_DELIVERY_REVIEWED,
            LOCATION_ID,
            NOTES,
            COUNT_DATE,
            CREATED
        ) VALUES (
            l_invoice_id,
            l_detail_id,
            l_item_id,
            l_user_id,
            l_qty_invoice,
            l_qty_counted,
            l_review_status,
            l_is_reviewed,
            l_location_id,
            l_notes,
            SYSDATE,
            SYSDATE
        );

    -- 6. Update DBS_SAL_INVOICE_DTL review flag
    UPDATE DBS_SAL_INVOICE_DTL
    SET IS_DELIVERY_REVIEWED = l_is_reviewed,
        DELIVERY_REVIEWED_BY = l_user_id
    WHERE ID = l_detail_id;

    COMMIT;

    -- 7. JSON Success Response
    APEX_JSON.open_object;
    APEX_JSON.write(''status'', ''success'', p_write_null => TRUE);
    APEX_JSON.write(''messageAr'', ''تم تسجيل عد الصنف بنجاح'', p_write_null => TRUE);
    APEX_JSON.write(''qtyInvoice'', l_qty_invoice, p_write_null => TRUE);
    APEX_JSON.write(''qtyCounted'', l_qty_counted, p_write_null => TRUE);
    APEX_JSON.write(''qtyDifference'', l_difference, p_write_null => TRUE);
    APEX_JSON.write(''reviewStatus'', l_review_status, p_write_null => TRUE);
    APEX_JSON.write(''isReviewed'', l_is_reviewed, p_write_null => TRUE);
    APEX_JSON.close_object;
    :status := 200;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''حدث خطأ أثناء حفظ عد الصنف'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', SQLERRM, p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;');

  -- =============================================================
  -- 2. API Endpoint: ReviewAllItemCounts (POST)
  -- URL Path: /DeliveryReview/ReviewAllItemCounts
  -- Body Parameters: invoiceId
  -- =============================================================
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'ReviewAllItemCounts',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => 'Match all invoice items full quantities');

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'ReviewAllItemCounts',
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
    l_user_type       VARCHAR2(200);
    l_user_id         NUMBER;
    l_invoice_id      NUMBER;
    l_count           NUMBER := 0;
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

    BEGIN
        SELECT ID INTO l_user_id
        FROM VW_API_ENTRY_LOGIN
        WHERE PHONE_NUMBER = l_phone AND TYPE_LOGIN = l_user_type AND STATUS = ''1'' AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN l_user_id := 0;
    END;

    l_invoice_id := :invoiceId;

    FOR rec IN (
        SELECT ID, DBS_STOCK_ITEMS_ID, QTY, DBS_STOCK_STORE_DTL_LOC_ID
        FROM DBS_SAL_INVOICE_DTL
        WHERE DBS_SAL_INVOICE_ID = l_invoice_id
    ) LOOP
        l_count := l_count + 1;
        
        MERGE INTO DBS_SAL_INVOICE_COUNT_DTL T
        USING (SELECT l_invoice_id AS inv_id, rec.ID AS dtl_id FROM DUAL) S
        ON (T.DBS_SAL_INVOICE_ID = S.inv_id AND T.DBS_SAL_INVOICE_DTL_ID = S.dtl_id)
        WHEN MATCHED THEN
            UPDATE SET 
                T.QTY_COUNTED = rec.QTY,
                T.REVIEW_STATUS = ''MATCHED'',
                T.IS_DELIVERY_REVIEWED = 1,
                T.USER_ID = l_user_id,
                T.COUNT_DATE = SYSDATE
        WHEN NOT MATCHED THEN
            INSERT (
                DBS_SAL_INVOICE_ID, DBS_SAL_INVOICE_DTL_ID, DBS_STOCK_ITEMS_ID, USER_ID,
                QTY_INVOICE, QTY_COUNTED, REVIEW_STATUS, IS_DELIVERY_REVIEWED, LOCATION_ID, COUNT_DATE, CREATED
            ) VALUES (
                l_invoice_id, rec.ID, rec.DBS_STOCK_ITEMS_ID, l_user_id,
                rec.QTY, rec.QTY, ''MATCHED'', 1, rec.DBS_STOCK_STORE_DTL_LOC_ID, SYSDATE, SYSDATE
            );
    END LOOP;

    UPDATE DBS_SAL_INVOICE_DTL
    SET IS_DELIVERY_REVIEWED = 1,
        DELIVERY_REVIEWED_BY = l_user_id
    WHERE DBS_SAL_INVOICE_ID = l_invoice_id;

    COMMIT;

    APEX_JSON.open_object;
    APEX_JSON.write(''status'', ''success'', p_write_null => TRUE);
    APEX_JSON.write(''messageAr'', ''تمت مراجعة ومطابقة جميع أصناف الفاتورة بنجاح'', p_write_null => TRUE);
    APEX_JSON.write(''totalItems'', l_count, p_write_null => TRUE);
    APEX_JSON.close_object;
    :status := 200;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''حدث خطأ أثناء مراجعة الكل'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', SQLERRM, p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;');

  -- =============================================================
  -- 3. API Endpoint: GetInvoiceCountDetails (GET)
  -- URL Path: /DeliveryReview/GetInvoiceCountDetails
  -- Query Parameter: invoiceId
  -- =============================================================
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'GetInvoiceCountDetails',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => 'Get detailed invoice items with quantity count status');

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'DeliveryReview',
      p_pattern        => 'GetInvoiceCountDetails',
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
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
            APEX_JSON.write(''messageAr'', ''جلسة غير صالحة'', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    l_invoice_id := :invoiceId;

    :status := 200;
    APEX_JSON.open_object;
    APEX_JSON.write(''status'', ''success'', p_write_null => TRUE);
    APEX_JSON.open_array(''data'');

    FOR rec IN (
        SELECT 
            D.ID AS DETAIL_ID,
            D.DBS_SAL_INVOICE_ID AS INVOICE_ID,
            D.DBS_STOCK_ITEMS_ID AS ITEM_ID,
            I.ITEM_CODE,
            I.NAME_AR AS ITEM_NAME_AR,
            I.NAME_EN AS ITEM_NAME_EN,
            D.QTY AS QTY_INVOICE,
            NVL(C.QTY_COUNTED, 0) AS QTY_COUNTED,
            NVL(C.QTY_DIFFERENCE, (0 - D.QTY)) AS QTY_DIFFERENCE,
            NVL(C.REVIEW_STATUS, ''PENDING'') AS REVIEW_STATUS,
            NVL(D.IS_DELIVERY_REVIEWED, 0) AS IS_DELIVERY_REVIEWED,
            L.NAME_AR AS LOCATION_NAME,
            C.NOTES
        FROM DBS_SAL_INVOICE_DTL D
        JOIN DBS_STOCK_ITEMS I ON D.DBS_STOCK_ITEMS_ID = I.ID
        LEFT JOIN DBS_STOCK_STORE_DTL_LOC L ON D.DBS_STOCK_STORE_DTL_LOC_ID = L.ID
        LEFT JOIN DBS_SAL_INVOICE_COUNT_DTL C 
               ON D.DBS_SAL_INVOICE_ID = C.DBS_SAL_INVOICE_ID AND D.ID = C.DBS_SAL_INVOICE_DTL_ID
        WHERE D.DBS_SAL_INVOICE_ID = l_invoice_id
        ORDER BY D.ID ASC
    ) LOOP
        l_count := l_count + 1;
        APEX_JSON.open_object;
        APEX_JSON.write(''detailId'', rec.DETAIL_ID, p_write_null => TRUE);
        APEX_JSON.write(''invoiceId'', rec.INVOICE_ID, p_write_null => TRUE);
        APEX_JSON.write(''itemId'', rec.ITEM_ID, p_write_null => TRUE);
        APEX_JSON.write(''itemCode'', rec.ITEM_CODE, p_write_null => TRUE);
        APEX_JSON.write(''itemNameAr'', rec.ITEM_NAME_AR, p_write_null => TRUE);
        APEX_JSON.write(''itemNameEn'', rec.ITEM_NAME_EN, p_write_null => TRUE);
        APEX_JSON.write(''qty'', rec.QTY_INVOICE, p_write_null => TRUE);
        APEX_JSON.write(''qtyInvoice'', rec.QTY_INVOICE, p_write_null => TRUE);
        APEX_JSON.write(''qtyCounted'', rec.QTY_COUNTED, p_write_null => TRUE);
        APEX_JSON.write(''qtyDifference'', rec.QTY_DIFFERENCE, p_write_null => TRUE);
        APEX_JSON.write(''reviewStatus'', rec.REVIEW_STATUS, p_write_null => TRUE);
        APEX_JSON.write(''isDeliveryReviewed'', rec.IS_DELIVERY_REVIEWED, p_write_null => TRUE);
        APEX_JSON.write(''locationName'', rec.LOCATION_NAME, p_write_null => TRUE);
        APEX_JSON.write(''notes'', rec.NOTES, p_write_null => TRUE);
        APEX_JSON.close_object;
    END LOOP;

    APEX_JSON.close_array;
    APEX_JSON.write(''total'', l_count, p_write_null => TRUE);
    APEX_JSON.close_object;
EXCEPTION
    WHEN OTHERS THEN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'', p_write_null => TRUE);
        APEX_JSON.write(''messageAr'', ''حدث خطأ أثناء جلب تفاصيل عد البنود'', p_write_null => TRUE);
        APEX_JSON.write(''messageEn'', SQLERRM, p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;');

END;
