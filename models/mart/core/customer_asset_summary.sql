WITH ledger AS (
    SELECT *
    FROM {{ ref('int_ledger_corrected') }}
    WHERE operation_type = 'securities_movement'
),

isin_lookup AS (
    SELECT isin, 
        security_name, 
        security_ticker
    FROM {{ ref('dim_security') }}
),

flows_calculated AS (
    SELECT isin,
        booking_id,
        customer_account_id,
        client_id,
        venue_id,
       -- credits = buys and debits = sells for security movements
        CASE WHEN credit_account_description = 'customer_account' THEN credit_amount 
            ELSE 0 END AS shares_bought,
        CASE WHEN debit_account_description = 'customer_account' THEN debit_amount 
            ELSE 0 END AS shares_sold,
        -- Transaction counts
        CASE WHEN credit_account_description = 'customer_account' THEN 1 
            ELSE 0 END AS credit_txn,
        CASE WHEN debit_account_description = 'customer_account' THEN 1 
            ELSE 0 END AS debit_txn
         
    FROM ledger f
),

aggregated AS (
    SELECT f.isin,
        l.security_name,
        l.security_ticker,
        f.client_id,
        f.customer_account_id,
        f.venue_id,
        sum(f.shares_bought) AS shares_bought,
        sum(f.shares_sold) AS shares_sold,
        sum(f.shares_bought - f.shares_sold) AS net_flow,
        sum(f.credit_txn) AS credit_transactions,
        sum(f.debit_txn) AS debit_transactions,
        sum(f.credit_txn + f.debit_txn) AS total_transactions

    FROM flows_calculated f
    LEFT JOIN isin_lookup l ON f.isin = l.isin
    GROUP BY 1, 2, 3, 4, 5, 6
)

SELECT * FROM aggregated
