{{ config(
  materialized = 'incremental',
  incremental_strategy = 'merge',
  unique_key = 'corrected_by_booking_id'
) }}


WITH corrections AS (
    SELECT
        booking_id_correction AS original_booking_id,
        booking_id AS corrected_by_booking_id,
        current_timestamp() AS audit_loaded_at
    FROM {{ ref('stg_ledger') }}
    WHERE booking_id_correction IS NOT NULL
    {% if is_incremental() %}
        AND booking_id > (SELECT max(corrected_by_booking_id) FROM {{ this }})
    {% endif %}
)

SELECT * FROM corrections
