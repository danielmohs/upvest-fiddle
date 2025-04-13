{{ config(
  materialized = 'incremental',
  incremental_strategy = 'merge',
  unique_key = 'merge_key'
) }}


WITH source AS (
    SELECT *,
        -- Compute the effective booking id, which is the original booking id if it's not corrected,
        -- or the booking id of the correction if it is. Needed to support merge strategy.
        coalesce(booking_id_correction, booking_id) AS merge_key
    FROM {{ ref('int_ledger_enriched') }}
    {% if is_incremental() %}
        WHERE booking_id > (SELECT max(booking_id) FROM {{ this }})
            -- explicitly filter for security movements in this model, in case of future changes
            AND operation_type = 'SECURITIES_MOVEMENT'
    {% else %}
        WHERE operation_type = 'SECURITIES_MOVEMENT'
    {% endif %}
),

isin_lookup AS (
    SELECT isin, 
        security_name, 
        security_ticker
    FROM {{ ref('dim_security') }}
),

-- credits = buys and debits = sells) for security movements
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

final AS (
    SELECT f.isin,
        i.security_name,
        i.security_ticker,
        coalesce(f.credit_account_id, f.debit_account_id) AS account_id,
        sum(f.shares_bought) AS shares_bought,
        sum(f.shares_sold) AS shares_sold,
        sum(f.shares_bought - f.shares_sold) AS net_flow,
        f.booking_id,
        merge_key
    FROM flows f
    LEFT JOIN isin_lookup i ON f.isin = i.isin
    GROUP BY 1, 2, 3, 4, 8, 9
)

SELECT * FROM final
