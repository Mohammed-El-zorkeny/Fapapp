-- =============================================================
-- 1. MODIFY DBS_SAL_INVOICE TABLE
-- =============================================================
-- Add column for delivery representative ID
ALTER TABLE "DBS_SAL_INVOICE" ADD "SALESMAN_DELIVERY_ID" NUMBER;

-- Add column for delivery notes
ALTER TABLE "DBS_SAL_INVOICE" ADD "DELIVERY_NOTES" VARCHAR2(4000);

-- Add column for delivery status with default 'PENDING_ASSIGNMENT'
ALTER TABLE "DBS_SAL_INVOICE" ADD "DELIVERY_STATUS" VARCHAR2(50) DEFAULT 'PENDING_ASSIGNMENT' NOT NULL;

-- Add foreign key constraint linking to DBS_SAL_SALES_MAN
ALTER TABLE "DBS_SAL_INVOICE" ADD CONSTRAINT "FK_SAL_INV_DELIVERY_MAN" 
    FOREIGN KEY ("SALESMAN_DELIVERY_ID") REFERENCES "DBS_SAL_SALES_MAN" ("ID") ON DELETE SET NULL;


-- =============================================================
-- 2. MODIFY DBS_SAL_INVOICE_DTL TABLE
-- =============================================================
-- Add column for is delivery reviewed (0 = No, 1 = Yes)
ALTER TABLE "DBS_SAL_INVOICE_DTL" ADD "IS_DELIVERY_REVIEWED" NUMBER(1) DEFAULT 0 NOT NULL;

-- Add column to record which user performed the review
ALTER TABLE "DBS_SAL_INVOICE_DTL" ADD "DELIVERY_REVIEWED_BY" NUMBER;

-- Add check constraint to ensure only 0 or 1 is stored in IS_DELIVERY_REVIEWED
ALTER TABLE "DBS_SAL_INVOICE_DTL" ADD CONSTRAINT "CH_INV_DTL_DEL_REVIEWED" 
    CHECK (IS_DELIVERY_REVIEWED IN (0, 1));
