WITH source AS (
    SELECT * 
    FROM {{ source('fiddle', 'ledger') }}
),

staged_ledger AS (
    SELECT booking_no AS booking_id,
        isin,
        operation_type,
        debit_account_id,
        debit_account_description,
        debit_amount,
        credit_account_id,
        credit_account_description,
        credit_amount,
        booking_no_correction AS booking_id_correction,
        booking_no_correction IS NOT NULL AS is_correction,
        cross_reference_id
    FROM source
)

SELECT * FROM staged_ledger
