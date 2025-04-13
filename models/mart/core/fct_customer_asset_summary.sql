{{ config(
  materialized = 'incremental',
  incremental_strategy = 'merge',
  unique_key = 'merge_key'
) }}

WITH source AS (
    SELECT *,
        -- Compute the effective booking id, which is the original booking id if it's not corrected,
        -- or the booking id of the correction if it is. Needed to support merge strategy.
        
        coalesce(booking_id_correction, booking_id) as merge_key
    FROM {{ ref('int_ledger_enriched') }}
    {% if is_incremental() %}
        WHERE booking_id > (select max(booking_id) FROM {{ this }})
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

flows AS (
    SELECT isin,
        account_id AS customer_account_id,
        client_id,
        venue_id,
        booking_id,
        merge_key,
        -- Enriched amounts
        CASE WHEN credit_account_description = 'CUSTOMER_ACCOUNT' THEN credit_amount ELSE 0 END AS shares_bought,
        CASE WHEN debit_account_description = 'CUSTOMER_ACCOUNT' THEN debit_amount ELSE 0 END AS shares_sold
    FROM source f
),

final AS (
    SELECT f.isin,
        security_name,
        security_ticker,
        customer_account_id,
        client_id,
        venue_id,
        booking_id,
        merge_key,
        sum(shares_bought) AS shares_bought,
        sum(shares_sold) AS shares_sold,
        sum(shares_bought - shares_sold) AS net_flow
    FROM flows f
    LEFT JOIN isin_lookup l on a.isin = l.isin
    group by 1, 2, 3, 4, 5, 6, 7, 8
),

SELECT * FROM aggregated
