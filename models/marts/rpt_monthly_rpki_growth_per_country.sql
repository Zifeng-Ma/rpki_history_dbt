{{
  config(
    materialized = 'view'
  )
}}

select
    cc,
    family as ip_version,
    toStartOfMonth({{ adapter.quote('time') }}) as month,
    round(
        avg(
            delegated__space__covered_by_rpki__count
            * 100.0
            / delegated__space__count
        ),
        2
    ) as avg_daily_coverage,
    count() as observed_days
from {{ ref('stg_rpki_history') }}
where delegated__space__count > 0
  and delegated__space__covered_by_rpki__count is not null
group by
    month,
    cc,
    ip_version
