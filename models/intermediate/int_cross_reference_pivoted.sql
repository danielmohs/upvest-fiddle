{% set flow_keys = var('flow_keys') %}


SELECT cross_reference_id,
    {%- for f_key in flow_keys %}
      max(CASE WHEN flow_key = '{{ f_key }}' THEN flow_value END) AS {{ f_key }}{%- if not loop.last %},{% endif -%}
    {% endfor %}

FROM {{ ref('stg_cross_reference') }}
GROUP BY cross_reference_id
