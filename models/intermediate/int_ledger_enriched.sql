WITH ledger_source AS (
    SELECT * 
    FROM {{ ref('stg_ledger') }}
),

ledger_enriched AS (
    SELECT l.booking_id,
        l.isin,
        l.operation_type,
        l.debit_account_id,
        l.debit_account_description,
        l.debit_amount,
        l.credit_account_id,
        l.credit_account_description,
        l.credit_amount,
        l.is_correction,
        l.cross_reference_id,
        x.order_id,
        x.venue_id,
        x.client_id,
        x.account_id AS xref_account_id

    FROM ledger_source l
    LEFT JOIN {{ ref('int_cross_reference_pivoted') }} x USING (cross_reference_id)
    WHERE booking_id NOT IN ( -- Exclude bookings that were corrected (keep only final version)
        SELECT booking_id_correction FROM ledger_source WHERE is_correction
        )
)

SELECT * FROM ledger_enriched
