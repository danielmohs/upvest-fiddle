SELECT
    isin,
    name as security_name,
    ticker as security_ticker
FROM {{ ref('isin_lookup') }}
