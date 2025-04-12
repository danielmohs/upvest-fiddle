WITH source AS (
    SELECT * 
    FROM {{ source('fiddle', 'cross_reference') }}
),

staged_cross_reference AS (
    SELECT id AS cross_reference_id,
        flow.key AS flow_key,
        flow.value AS flow_value,
        -- Create unique key for each flow, id pair.
        id || '-' || flow.key AS unique_key
    FROM source, UNNEST(flows) AS flow
)

SELECT * FROM staged_cross_reference
