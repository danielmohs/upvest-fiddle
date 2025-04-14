{{ config(
  materialized = 'incremental',
  incremental_strategy = 'merge',
  unique_key = 'merge_key'
) }}

WITH ledger_source AS (
    SELECT *
    FROM {{ ref('int_ledger_enriched') }}
),

ledger AS (
    SELECT booking_id,
        isin,
        operation_type,
        debit_account_id,
        debit_account_description,
        debit_amount,
        credit_account_id,
        credit_account_description,
        credit_amount,
        booking_id_correction,
        is_correction,
        cross_reference_id,
        order_id,
        venue_id,
        client_id,
        customer_account_id,
        -- Create a unique identifier for merging records that handles corrections:
        -- For corrected entries: uses the correction's booking_id (booking_id_correction)
        -- For normal entries: uses the original booking_id
        -- This ensures that when corrections come in, they replace the original entries
        coalesce(booking_id_correction, booking_id) as merge_key
    FROM ledger_source
    {% if is_incremental() %}
        -- Corrections will be handled by the merge strategy
        WHERE booking_id > (select max(booking_id) FROM {{ this }})
    {% else %}
        -- For the initial load, exclude bookings that were corrected (keep only final version)
        WHERE booking_id NOT IN (
                SELECT booking_id_correction FROM ledger_source WHERE is_correction
                )
    {% endif %}
)

SELECT * FROM ledger
