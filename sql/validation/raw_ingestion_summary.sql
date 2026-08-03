-- Basic fidelity and plausibility checks for the loaded raw table.
-- Placeholders are rendered by scripts/validate_raw_bigquery.sh.

SELECT
  COUNT(*) AS loaded_row_count,
  __EXPECTED_ROW_COUNT__ AS expected_row_count,
  COUNT(*) - __EXPECTED_ROW_COUNT__ AS row_count_difference,
  COUNT(*) = __EXPECTED_ROW_COUNT__ AS row_count_matches_expected,
  COUNT(DISTINCT CRASH_RECORD_ID) AS distinct_crash_record_ids,
  COUNTIF(CRASH_RECORD_ID IS NULL OR TRIM(CRASH_RECORD_ID) = '')
    AS null_or_blank_crash_record_ids,
  COUNT(*)
    - COUNTIF(CRASH_RECORD_ID IS NULL OR TRIM(CRASH_RECORD_ID) = '')
    - COUNT(DISTINCT NULLIF(TRIM(CRASH_RECORD_ID), ''))
    AS duplicate_id_rows_excluding_missing_ids,
  COUNTIF(
    CRASH_HOUR IS NOT NULL
    AND (CRASH_HOUR < 0 OR CRASH_HOUR > 23)
  ) AS invalid_crash_hours,
  COUNTIF(
    CRASH_DAY_OF_WEEK IS NOT NULL
    AND (CRASH_DAY_OF_WEEK < 1 OR CRASH_DAY_OF_WEEK > 7)
  ) AS invalid_days_of_week,
  COUNTIF(
    CRASH_MONTH IS NOT NULL
    AND (CRASH_MONTH < 1 OR CRASH_MONTH > 12)
  ) AS invalid_months,
  COUNTIF(LATITUDE = 0 AND LONGITUDE = 0) AS zero_coordinate_pairs,
  COUNTIF(
    LATITUDE IS NOT NULL
    AND LONGITUDE IS NOT NULL
    AND NOT (LATITUDE = 0 AND LONGITUDE = 0)
    AND (LATITUDE < 41 OR LATITUDE > 43)
  ) AS latitude_outside_expected_area,
  COUNTIF(
    LATITUDE IS NOT NULL
    AND LONGITUDE IS NOT NULL
    AND NOT (LATITUDE = 0 AND LONGITUDE = 0)
    AND (LONGITUDE < -88 OR LONGITUDE > -87)
  ) AS longitude_outside_expected_area
FROM `__RAW_SQL_TABLE_ID__`;
