-- Inspect the loaded table schema and report the number of loaded columns.

SELECT
  ordinal_position,
  column_name,
  data_type,
  is_nullable,
  COUNT(*) OVER () AS loaded_column_count
FROM `__PROJECT_ID__.__RAW_DATASET__.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = '__RAW_TABLE__'
ORDER BY ordinal_position;
