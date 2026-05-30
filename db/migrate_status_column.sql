-- ============================================================
-- Migration: DBS_SAL_CUSTOMERS
-- نقل البيانات من STATUS إلى STATUS_1 ثم إعادة التسمية
-- ============================================================

-- ── 1. نقل البيانات من STATUS إلى STATUS_1 ─────────────────
UPDATE DBS_SAL_CUSTOMERS
SET STATUS_1 = STATUS;

COMMIT;

-- ── 2. التحقق إن النقل تم صح قبل المسح ────────────────────
-- (اختياري - تأكد إن مفيش فرق بين الكولومنين)
SELECT COUNT(*) AS MISMATCH_COUNT
FROM DBS_SAL_CUSTOMERS
WHERE NVL(STATUS, -1) != NVL(STATUS_1, -1);

-- لو النتيجة = 0 يبقى كل حاجة تمام، كمّل
-- لو النتيجة > 0 وقف ولا تكمّل

-- ── 3. مسح الكولومن القديم STATUS ──────────────────────────
ALTER TABLE DBS_SAL_CUSTOMERS DROP COLUMN STATUS;

-- ── 4. إعادة تسمية STATUS_1 إلى STATUS ─────────────────────
ALTER TABLE DBS_SAL_CUSTOMERS RENAME COLUMN STATUS_1 TO STATUS;

-- ── 5. تأكد إن كل حاجة تمام ────────────────────────────────
SELECT COLUMN_NAME, DATA_TYPE, NULLABLE
FROM USER_TAB_COLUMNS
WHERE TABLE_NAME = 'DBS_SAL_CUSTOMERS'
AND   COLUMN_NAME = 'STATUS';
