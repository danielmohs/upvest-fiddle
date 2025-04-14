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

-- credits = buys and debits = sells for security movements
flows_calculated AS (
    SELECT isin,
        booking_id,
        client_id,
        -- For customer account transactions
        CASE WHEN credit_account_description = 'customer_account' THEN credit_account_id
             WHEN debit_account_description = 'customer_account' THEN debit_account_id
            END AS account_id,
        -- Credits = buys for customer accounts
        {{ get_shares_bought_by_customer('credit_account_description', 'credit_amount') }} AS shares_bought,
        -- Debits = sells for customer accounts
        {{ get_shares_sold_by_customer('debit_account_description', 'debit_amount') }} AS shares_sold

    FROM ledger
),

security_flows AS (
    SELECT f.isin,
        i.security_name,
        i.security_ticker,
        f.account_id,
        --f.client_id, -- excluding client_id for now due to its high cardinality in the sample
        sum(f.shares_bought) AS shares_bought,
        sum(f.shares_sold) AS shares_sold,
        sum(f.shares_bought - f.shares_sold) AS net_flow,
        count(*) As total_transactions
        
    FROM flows_calculated f
    LEFT JOIN isin_lookup i ON f.isin = i.isin
    GROUP BY 1, 2, 3, 4--, 5
)

SELECT * FROM security_flows
