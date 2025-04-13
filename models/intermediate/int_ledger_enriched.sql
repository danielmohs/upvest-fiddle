WITH ledger_source AS (
    SELECT * 
    FROM {{ ref('stg_ledger') }}
),

cross_reference AS (
    SELECT *
    FROM {{ ref('int_cross_reference_pivoted') }}
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
        l.booking_id_correction,
        l.is_correction,
        l.cross_reference_id,
        x.order_id,
        x.venue_id,
        x.client_id,
        x.account_id AS customer_account_id

    FROM ledger_source l
    LEFT JOIN cross_reference x USING (cross_reference_id)
)

SELECT * FROM ledger_enriched
