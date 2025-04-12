{{ config(
  materialized = 'incremental',
  incremental_strategy = 'merge',
  unique_key = 'merge_key'
) }}


WITH source AS (
    SELECT *
        -- Compute the effective booking id, which is the original booking id if it's not corrected,
        -- or the booking id of the correction if it is. Needed to support merge strategy.
        , coalesce(booking_id_correction, booking_id) AS merge_key
    FROM {{ ref('int_ledger_enriched') }}
    {% if is_incremental() %}
        WHERE booking_id > (SELECT max(booking_id) FROM {{ this }})
    {% endif %}
),

-- credits (buys) and debits (sells)
flows AS (
    SELECT isin,
        -- For buys (credits to customer accounts)
        CASE WHEN credit_account_description = 'CUSTOMER_ACCOUNT' 
             THEN credit_account_id END AS credit_account_id,
        CASE WHEN credit_account_description = 'CUSTOMER_ACCOUNT' 
             THEN credit_amount ELSE 0 END AS shares_bought,
        -- For sells (debits from customer accounts)
        CASE WHEN debit_account_description = 'CUSTOMER_ACCOUNT' 
             THEN debit_account_id END AS debit_account_id,
        CASE WHEN debit_account_description = 'CUSTOMER_ACCOUNT' 
             THEN debit_amount ELSE 0 END AS shares_sold,
        booking_id,
        merge_key
    FROM source
),

combined AS (
    SELECT isin,
        coalesce(credit_account_id, debit_account_id) AS account_id,
        sum(shares_bought) AS shares_bought,
        sum(shares_sold) AS shares_sold,
        sum(shares_bought - shares_sold) AS net_flow,
        booking_id,
        merge_key
    FROM flows
    GROUP BY 1, 2, 6, 7
)

SELECT * FROM combined
