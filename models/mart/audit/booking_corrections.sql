{{ config(materialized='table') }}

select
    booking_id_correction as original_booking_id,
    booking_id as corrected_by_booking_id
from {{ ref('stg_ledger') }}
where booking_id_correction is not null
