SELECT isin,
    security_name,
    security_ticker
FROM {{ ref('isin_lookup') }}
