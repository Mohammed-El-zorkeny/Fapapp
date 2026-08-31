-- =============================================================
-- INDEXES FOR OPTIMIZING DBS_PLAN_REQUESTS REPORT PERFORMANCE
-- =============================================================

-- 1. Index on DBS_SAL_INVOICE (لعمل Join سريع جداً برقم الطلب وتاريخ التوصيل)
CREATE INDEX "IDX_SAL_INV_REQ_ID" ON "DBS_SAL_INVOICE" ("REQUESTS_ID", "DELIVERY_DATE");

-- 2. Index on DBS_PLAN_REQUESTS_DTL (لحساب إجمالي المبالغ والكميات بسرعة فائقة)
CREATE INDEX "IDX_PLAN_REQ_DTL_FK" ON "DBS_PLAN_REQUESTS_DTL" ("DBS_PLAN_REQUESTS_ID", "QTY", "QTY_PLAN", "PRICE");

-- 3. Index on DBS_PLAN_REQUESTS (لتسريع الفلترة بالشركة والفرع وتاريخ الفاتورة)
CREATE INDEX "IDX_PLAN_REQ_MAIN" ON "DBS_PLAN_REQUESTS" ("COMP_ID", "BRANCH_ID", "INV_DATE");
