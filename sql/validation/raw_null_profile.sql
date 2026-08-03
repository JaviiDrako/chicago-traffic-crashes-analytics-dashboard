-- Profile null or blank values in fields that are important for analysis.
-- The array keeps this check to one table scan.

WITH profile AS (
  SELECT [
    STRUCT(
      'CRASH_RECORD_ID' AS column_name,
      COUNTIF(CRASH_RECORD_ID IS NULL OR TRIM(CRASH_RECORD_ID) = '')
        AS null_or_blank_count
    ),
    STRUCT(
      'CRASH_DATE' AS column_name,
      COUNTIF(CRASH_DATE IS NULL OR TRIM(CRASH_DATE) = '')
        AS null_or_blank_count
    ),
    STRUCT(
      'CRASH_TYPE' AS column_name,
      COUNTIF(CRASH_TYPE IS NULL OR TRIM(CRASH_TYPE) = '')
        AS null_or_blank_count
    ),
    STRUCT(
      'WEATHER_CONDITION' AS column_name,
      COUNTIF(WEATHER_CONDITION IS NULL OR TRIM(WEATHER_CONDITION) = '')
        AS null_or_blank_count
    ),
    STRUCT(
      'MOST_SEVERE_INJURY' AS column_name,
      COUNTIF(MOST_SEVERE_INJURY IS NULL OR TRIM(MOST_SEVERE_INJURY) = '')
        AS null_or_blank_count
    ),
    STRUCT(
      'NUM_UNITS' AS column_name,
      COUNTIF(NUM_UNITS IS NULL) AS null_or_blank_count
    ),
    STRUCT(
      'LATITUDE' AS column_name,
      COUNTIF(LATITUDE IS NULL) AS null_or_blank_count
    ),
    STRUCT(
      'LONGITUDE' AS column_name,
      COUNTIF(LONGITUDE IS NULL) AS null_or_blank_count
    ),
    STRUCT(
      'LOCATION' AS column_name,
      COUNTIF(LOCATION IS NULL OR TRIM(LOCATION) = '')
        AS null_or_blank_count
    )
  ] AS columns
  FROM `__RAW_SQL_TABLE_ID__`
)
SELECT column_name, null_or_blank_count
FROM profile, UNNEST(columns)
ORDER BY null_or_blank_count DESC;
