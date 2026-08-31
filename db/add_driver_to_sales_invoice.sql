-- =============================================================
-- ADD DRIVER COLUMN TO DBS_SAL_INVOICE TABLE
-- =============================================================

-- 1. إضافة عمود السائق لجدول الفواتير
ALTER TABLE "DBS_SAL_INVOICE" ADD (
    "DBS_DRIVERS_ID" NUMBER
);

-- 2. إضافة العلاقة (Foreign Key) لربطه بجدول السائقين DBS_DRIVERS
ALTER TABLE "DBS_SAL_INVOICE" ADD CONSTRAINT "FK_SAL_INV_DRIVER" 
    FOREIGN KEY ("DBS_DRIVERS_ID") REFERENCES "DBS_DRIVERS" ("ID") ON DELETE SET NULL;

-- 3. إنشاء فهرس Index لتحسين سرعة الاستعلامات
CREATE INDEX "IDX_SAL_INV_DRIVER_ID" ON "DBS_SAL_INVOICE" ("DBS_DRIVERS_ID");
