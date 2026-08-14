{{
  config(
    materialized = 'view',
    )
}}

with raw_daily_rpki as (
    select
        {{adapter.quote("time")}},
        cc,
        family AS ip_version,
        round(delegated__space__covered_by_rpki__count * 100 / delegated__space__count, 2) AS daily_rpki_space_coverage
    from {{ ref('stg_rpki_history') }}
)
select
*
from raw_daily_rpki