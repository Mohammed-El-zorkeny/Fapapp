-- -------------------------------------------------------------
-- 1. ADD USER_ID COLUMN TO DELIVERIES TABLE (IF NOT ALREADY ADDED)
-- -------------------------------------------------------------
ALTER TABLE "DBS_PUR_INVOICE_DELIVERY" ADD "USER_ID" NUMBER;

-- -------------------------------------------------------------
-- 2. RE-CREATE BIU TRIGGER WITH USER_ID AUDIT
-- -------------------------------------------------------------
CREATE OR REPLACE EDITIONABLE TRIGGER "DBS_PUR_INV_DEL_BIU"
BEFORE INSERT OR UPDATE ON "DBS_PUR_INVOICE_DELIVERY"
FOR EACH ROW
DECLARE
    V_NEW_ID NUMBER;
BEGIN
    IF INSERTING THEN
        IF :NEW.ID IS NULL THEN
            SELECT NVL(MAX(ID), 0) + 1 INTO :NEW.ID FROM DBS_PUR_INVOICE_DELIVERY;
        END IF;
        :NEW.CREATED := SYSDATE;
        :NEW.CREATED_BY := COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
    END IF;
    
    :NEW.UPDATED := SYSDATE;
    :NEW.UPDATED_BY := COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
END;
/
ALTER TRIGGER "DBS_PUR_INV_DEL_BIU" ENABLE;


-- =============================================================
-- 3. API 1: GET PURCHASE INVOICES LIST (GET)
-- =============================================================
/*
   Parameters expected (Optional):
   - :autoNumber (To filter by specific invoice number)
   Returns: id, autoNumber, invDate
*/
DECLARE
    l_header_value    VARCHAR2(4000);
    l_bearer_token    VARCHAR2(4000);
    l_token           APEX_JWT.T_TOKEN;
    l_user_object     APEX_JSON.T_VALUES;
    l_phone           VARCHAR2(200);
    l_user_type       VARCHAR2(200);
    l_user_id         NUMBER;
    l_count           NUMBER := 0;
    l_auto_number     VARCHAR2(200);
    
BEGIN
    -- Authentication Check
    l_header_value := OWA_UTIL.get_cgi_env('Authorization');
    IF l_header_value IS NULL OR INSTR(l_header_value, 'Bearer ') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error', p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'يرجى تسجيل الدخول أولاً', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'Authentication required', p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'TOKEN_REQUIRED', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW('secretKey')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => 'ORDS');
        APEX_JSON.PARSE(l_user_object, l_token.payload);
        l_phone := APEX_JSON.GET_VARCHAR2(p_path => 'sub', p_values => l_user_object);
        l_user_type := APEX_JSON.GET_VARCHAR2(p_path => 'aud', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status', 'error', p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'جلسة غير صالحة', p_write_null => TRUE);
            APEX_JSON.write('messageEn', 'Invalid token', p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'INVALID_TOKEN', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    -- Verify user login
    BEGIN
        SELECT ID INTO l_user_id
        FROM VW_API_ENTRY_LOGIN
        WHERE PHONE_NUMBER = l_phone AND TYPE_LOGIN = l_user_type AND STATUS = '1' AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status', 'error', p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'المستخدم غير موجود', p_write_null => TRUE);
            APEX_JSON.write('messageEn', 'User not found', p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'USER_NOT_FOUND', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 404;
            RETURN;
    END;

    -- Read optional filter parameter
    BEGIN
        l_auto_number := :autoNumber;
    EXCEPTION
        WHEN OTHERS THEN
            l_auto_number := NULL;
    END;

    :status := 200;
    APEX_JSON.open_object;
    APEX_JSON.write('status', 'success', p_write_null => TRUE);
    APEX_JSON.write('messageAr', 'تم جلب فواتير المشتريات بنجاح', p_write_null => TRUE);
    APEX_JSON.write('messageEn', 'Purchase invoices retrieved successfully', p_write_null => TRUE);
    
    APEX_JSON.open_array('invoices');

    FOR rec IN (
        SELECT
            MS.ID,
            MS.AUTO_NUMBER,
            TO_CHAR(MS.INV_DATE, 'YYYY-MM-DD') AS INV_DATE
        FROM DBS_PUR_INVOICE MS
        WHERE MS.COMP_ID   = 2
          AND MS.BRANCH_ID = 10
          AND (l_auto_number IS NULL OR UPPER(MS.AUTO_NUMBER) LIKE '%' || UPPER(l_auto_number) || '%')
        ORDER BY MS.ID DESC
    ) LOOP
        l_count := l_count + 1;
        
        APEX_JSON.open_object;
        APEX_JSON.write('id',         rec.ID,          p_write_null => TRUE);
        APEX_JSON.write('autoNumber', rec.AUTO_NUMBER, p_write_null => TRUE);
        APEX_JSON.write('invDate',    rec.INV_DATE,    p_write_null => TRUE);
        APEX_JSON.close_object;
    END LOOP;

    APEX_JSON.close_array;
    APEX_JSON.write('total', l_count, p_write_null => TRUE);
    APEX_JSON.close_object;

EXCEPTION
    WHEN OTHERS THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error', p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'حدث خطأ في النظام', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'System error: ' || SQLERRM, p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'SYSTEM_ERROR', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;
/


-- =============================================================
-- 4. API 2: RECEIVE / DELIVER PURCHASE ITEM QUANTITY (POST)
-- =============================================================
/*
   Parameters expected in POST body or bindings:
   - :invoiceId (Numeric ID of the purchase invoice)
   - :itemCode  (Can be Item Code, Barcode, QR Code, or ID of the item)
   - :qtyReceived (Quantity received in this batch)
*/
DECLARE
    l_header_value    VARCHAR2(4000);
    l_bearer_token    VARCHAR2(4000);
    l_token           APEX_JWT.T_TOKEN;
    l_user_object     APEX_JSON.T_VALUES;
    l_phone           VARCHAR2(200);
    l_user_type       VARCHAR2(200);
    l_user_id         NUMBER;
    
    l_invoice_id      NUMBER;
    l_item_id         NUMBER;
    l_qty_received    NUMBER;
    l_item_code       VARCHAR2(100);
    l_count           NUMBER;
    
BEGIN
    -- Authentication Check
    l_header_value := OWA_UTIL.get_cgi_env('Authorization');
    IF l_header_value IS NULL OR INSTR(l_header_value, 'Bearer ') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error', p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'يرجى تسجيل الدخول أولاً', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'Authentication required', p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'TOKEN_REQUIRED', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW('secretKey')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => 'ORDS');
        APEX_JSON.PARSE(l_user_object, l_token.payload);
        l_phone := APEX_JSON.GET_VARCHAR2(p_path => 'sub', p_values => l_user_object);
        l_user_type := APEX_JSON.GET_VARCHAR2(p_path => 'aud', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status', 'error', p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'جلسة غير صالحة', p_write_null => TRUE);
            APEX_JSON.write('messageEn', 'Invalid token', p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'INVALID_TOKEN', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    -- Get User ID (vw_api_entry_login.USER_ID contains the ID from SEC_USERS)
    BEGIN
        SELECT USER_ID INTO l_user_id
        FROM VW_API_ENTRY_LOGIN
        WHERE PHONE_NUMBER = l_phone AND TYPE_LOGIN = l_user_type AND STATUS = '1' AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status', 'error', p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'المستخدم غير موجود', p_write_null => TRUE);
            APEX_JSON.write('messageEn', 'User not found', p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'USER_NOT_FOUND', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 404;
            RETURN;
    END;

    -- Read POST inputs
    l_invoice_id   := TO_NUMBER(:invoiceId);
    l_qty_received := TO_NUMBER(:qtyReceived);
    l_item_code    := :itemCode;

    IF l_invoice_id IS NULL OR l_qty_received IS NULL OR l_qty_received <= 0 OR l_item_code IS NULL THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error', p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'المدخلات غير كاملة أو غير صحيحة', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'Missing or invalid parameters', p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'INVALID_INPUT', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 400;
        RETURN;
    END IF;

    -- Resolve Item ID by item_code, barcode, or ID
    BEGIN
        SELECT ID INTO l_item_id
        FROM DBS_STOCK_ITEMS
        WHERE ITEM_CODE = l_item_code 
           OR BARCODE = l_item_code 
           OR TO_CHAR(ID) = l_item_code
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status', 'error', p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'هذا الصنف غير مسجل بالنظام', p_write_null => TRUE);
            APEX_JSON.write('messageEn', 'Item code not found', p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'ITEM_NOT_FOUND', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 404;
            RETURN;
    END;

    -- Verify if item belongs to the purchase invoice details
    SELECT COUNT(*) INTO l_count
    FROM DBS_PUR_INVOICE_DTL
    WHERE DBS_PUR_INVOICE_ID = l_invoice_id
      AND DBS_STOCK_ITEMS_ID = l_item_id;

    IF l_count = 0 THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error', p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'هذا الصنف غير مدرج بفاتورة الشراء المحددة', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'Item not linked to this purchase invoice', p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'ITEM_INVOICE_MISMATCH', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 400;
        RETURN;
    END IF;

    -- Save the delivery entry with current date and user ID
    INSERT INTO DBS_PUR_INVOICE_DELIVERY (
        DBS_PUR_INVOICE_ID,
        DBS_STOCK_ITEMS_ID,
        QTY_RECEIVED,
        DELIVERY_DATE,
        USER_ID
    ) VALUES (
        l_invoice_id,
        l_item_id,
        l_qty_received,
        SYSDATE,
        l_user_id
    );
    COMMIT;

    APEX_JSON.open_object;
    APEX_JSON.write('status', 'success', p_write_null => TRUE);
    APEX_JSON.write('messageAr', 'تم تسجيل الكمية المستلمة بنجاح', p_write_null => TRUE);
    APEX_JSON.write('messageEn', 'Received quantity recorded successfully', p_write_null => TRUE);
    APEX_JSON.close_object;
    :status := 200;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error', p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'حدث خطأ في النظام', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'System error: ' || SQLERRM, p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'SYSTEM_ERROR', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;
/


-- =============================================================
-- 5. API 3: GET USER'S RECEIVED DELIVERIES LIST (GET)
-- =============================================================
/*
   Returns a list of items received/delivered by the currently logged-in storekeeper.
*/
DECLARE
    l_header_value    VARCHAR2(4000);
    l_bearer_token    VARCHAR2(4000);
    l_token           APEX_JWT.T_TOKEN;
    l_user_object     APEX_JSON.T_VALUES;
    l_phone           VARCHAR2(200);
    l_user_type       VARCHAR2(200);
    l_user_id         NUMBER;
    l_count           NUMBER := 0;
    l_invoice_id      NUMBER;
    
BEGIN
    -- Authentication Check
    l_header_value := OWA_UTIL.get_cgi_env('Authorization');
    IF l_header_value IS NULL OR INSTR(l_header_value, 'Bearer ') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error', p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'يرجى تسجيل الدخول أولاً', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'Authentication required', p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'TOKEN_REQUIRED', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW('secretKey')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => 'ORDS');
        APEX_JSON.PARSE(l_user_object, l_token.payload);
        l_phone := APEX_JSON.GET_VARCHAR2(p_path => 'sub', p_values => l_user_object);
        l_user_type := APEX_JSON.GET_VARCHAR2(p_path => 'aud', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status', 'error', p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'جلسة غير صالحة', p_write_null => TRUE);
            APEX_JSON.write('messageEn', 'Invalid token', p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'INVALID_TOKEN', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    -- Get User ID (vw_api_entry_login.USER_ID contains the ID from SEC_USERS)
    BEGIN
        SELECT USER_ID INTO l_user_id
        FROM VW_API_ENTRY_LOGIN
        WHERE PHONE_NUMBER = l_phone AND TYPE_LOGIN = l_user_type AND STATUS = '1' AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status', 'error', p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'المستخدم غير موجود', p_write_null => TRUE);
            APEX_JSON.write('messageEn', 'User not found', p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'USER_NOT_FOUND', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 404;
            RETURN;
    END;

    -- Read optional invoice filter
    BEGIN
        l_invoice_id := TO_NUMBER(:invoiceId);
    EXCEPTION
        WHEN OTHERS THEN
            l_invoice_id := NULL;
    END;

    :status := 200;
    APEX_JSON.open_object;
    APEX_JSON.write('status', 'success', p_write_null => TRUE);
    APEX_JSON.write('messageAr', 'تم جلب تسليمات المستخدم بنجاح', p_write_null => TRUE);
    APEX_JSON.write('messageEn', 'User deliveries retrieved successfully', p_write_null => TRUE);
    
    APEX_JSON.open_array('deliveries');

    FOR rec IN (
        SELECT
            DEL.ID                    AS DELIVERY_ID,
            DEL.DBS_PUR_INVOICE_ID    AS INVOICE_ID,
            INV.AUTO_NUMBER           AS INVOICE_NUMBER,
            DEL.DBS_STOCK_ITEMS_ID    AS ITEM_ID,
            ITEMS.ITEM_CODE,
            ITEMS.NAME_AR             AS ITEM_NAME,
            ITEMS.ITEM_SIDE,
            (SELECT l.NAME_AR FROM DBS_STOCK_STORE_DTL_LOC l WHERE l.ID = ITEMS.DBS_STOCK_STORE_DTL_LOC_ID) AS LOCATION_NAME,
            DEL.QTY_RECEIVED,
            TO_CHAR(DEL.DELIVERY_DATE, 'YYYY-MM-DD HH24:MI:SS') AS DELIVERY_DATE
        FROM DBS_PUR_INVOICE_DELIVERY DEL
        JOIN DBS_PUR_INVOICE INV ON INV.ID = DEL.DBS_PUR_INVOICE_ID
        JOIN DBS_STOCK_ITEMS ITEMS ON ITEMS.ID = DEL.DBS_STOCK_ITEMS_ID
        WHERE DEL.USER_ID = l_user_id
          AND (l_invoice_id IS NULL OR DEL.DBS_PUR_INVOICE_ID = l_invoice_id)
        ORDER BY DEL.ID DESC
    ) LOOP
        l_count := l_count + 1;
        
        APEX_JSON.open_object;
        APEX_JSON.write('deliveryId',    rec.DELIVERY_ID,      p_write_null => TRUE);
        APEX_JSON.write('invoiceId',     rec.INVOICE_ID,       p_write_null => TRUE);
        APEX_JSON.write('invoiceNumber', rec.INVOICE_NUMBER,   p_write_null => TRUE);
        APEX_JSON.write('itemId',        rec.ITEM_ID,          p_write_null => TRUE);
        APEX_JSON.write('itemCode',      rec.ITEM_CODE,        p_write_null => TRUE);
        APEX_JSON.write('itemName',      rec.ITEM_NAME,        p_write_null => TRUE);
        APEX_JSON.write('itemSide',      rec.ITEM_SIDE,        p_write_null => TRUE);
        APEX_JSON.write('location',      rec.LOCATION_NAME,    p_write_null => TRUE);
        APEX_JSON.write('qtyReceived',   rec.QTY_RECEIVED,     p_write_null => TRUE);
        APEX_JSON.write('deliveryDate',  rec.DELIVERY_DATE,    p_write_null => TRUE);
        APEX_JSON.close_object;
    END LOOP;

    APEX_JSON.close_array;
    APEX_JSON.write('total', l_count, p_write_null => TRUE);
    APEX_JSON.close_object;

EXCEPTION
    WHEN OTHERS THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error', p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'حدث خطأ في النظام', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'System error: ' || SQLERRM, p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'SYSTEM_ERROR', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;
/


-- =============================================================
-- 6. API 4: UPDATE RECEIVED QUANTITY (POST)
-- =============================================================
/*
   Parameters expected in POST body:
   - :deliveryId (ID of the delivery row to update)
   - :qtyReceived (New quantity received)
*/
DECLARE
    l_header_value    VARCHAR2(4000);
    l_bearer_token    VARCHAR2(4000);
    l_token           APEX_JWT.T_TOKEN;
    l_user_object     APEX_JSON.T_VALUES;
    l_phone           VARCHAR2(200);
    l_user_type       VARCHAR2(200);
    l_user_id         NUMBER;
    
    l_delivery_id     NUMBER;
    l_qty_received    NUMBER;
    l_count           NUMBER;
    
BEGIN
    -- Authentication Check
    l_header_value := OWA_UTIL.get_cgi_env('Authorization');
    IF l_header_value IS NULL OR INSTR(l_header_value, 'Bearer ') != 1 THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error', p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'يرجى تسجيل الدخول أولاً', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'Authentication required', p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'TOKEN_REQUIRED', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 401;
        RETURN;
    END IF;

    l_bearer_token := SUBSTR(l_header_value, 8);
    BEGIN
        l_token := APEX_JWT.DECODE(
            p_value => l_bearer_token,
            p_signature_key => SYS.UTL_RAW.CAST_TO_RAW('secretKey')
        );
        APEX_JWT.VALIDATE(p_token => l_token, p_iss => 'ORDS');
        APEX_JSON.PARSE(l_user_object, l_token.payload);
        l_phone := APEX_JSON.GET_VARCHAR2(p_path => 'sub', p_values => l_user_object);
        l_user_type := APEX_JSON.GET_VARCHAR2(p_path => 'aud', p_values => l_user_object);
    EXCEPTION
        WHEN OTHERS THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status', 'error', p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'جلسة غير صالحة', p_write_null => TRUE);
            APEX_JSON.write('messageEn', 'Invalid token', p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'INVALID_TOKEN', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 401;
            RETURN;
    END;

    -- Get User ID
    BEGIN
        SELECT USER_ID INTO l_user_id
        FROM VW_API_ENTRY_LOGIN
        WHERE PHONE_NUMBER = l_phone AND TYPE_LOGIN = l_user_type AND STATUS = '1' AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            APEX_JSON.open_object;
            APEX_JSON.write('status', 'error', p_write_null => TRUE);
            APEX_JSON.write('messageAr', 'المستخدم غير موجود', p_write_null => TRUE);
            APEX_JSON.write('messageEn', 'User not found', p_write_null => TRUE);
            APEX_JSON.write('errorCode', 'USER_NOT_FOUND', p_write_null => TRUE);
            APEX_JSON.close_object;
            :status := 404;
            RETURN;
    END;

    -- Read parameters
    l_delivery_id  := TO_NUMBER(:deliveryId);
    l_qty_received := TO_NUMBER(:qtyReceived);

    IF l_delivery_id IS NULL OR l_qty_received IS NULL OR l_qty_received <= 0 THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error', p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'المدخلات غير كاملة أو غير صحيحة', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'Missing or invalid parameters', p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'INVALID_INPUT', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 400;
        RETURN;
    END IF;

    -- Verify if delivery exists and belongs to the user
    SELECT COUNT(*) INTO l_count
    FROM DBS_PUR_INVOICE_DELIVERY
    WHERE ID = l_delivery_id AND USER_ID = l_user_id;

    IF l_count = 0 THEN
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error', p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'سجل الاستلام غير موجود أو لا يخصك تعديله', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'Delivery not found or not owned by you', p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'DELIVERY_NOT_FOUND', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 404;
        RETURN;
    END IF;

    -- Update quantity
    UPDATE DBS_PUR_INVOICE_DELIVERY
    SET QTY_RECEIVED = l_qty_received
    WHERE ID = l_delivery_id;
    COMMIT;

    APEX_JSON.open_object;
    APEX_JSON.write('status', 'success', p_write_null => TRUE);
    APEX_JSON.write('messageAr', 'تم تعديل الكمية المستلمة بنجاح', p_write_null => TRUE);
    APEX_JSON.write('messageEn', 'Received quantity updated successfully', p_write_null => TRUE);
    APEX_JSON.close_object;
    :status := 200;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        APEX_JSON.open_object;
        APEX_JSON.write('status', 'error', p_write_null => TRUE);
        APEX_JSON.write('messageAr', 'حدث خطأ في النظام', p_write_null => TRUE);
        APEX_JSON.write('messageEn', 'System error: ' || SQLERRM, p_write_null => TRUE);
        APEX_JSON.write('errorCode', 'SYSTEM_ERROR', p_write_null => TRUE);
        APEX_JSON.close_object;
        :status := 500;
END;
/
