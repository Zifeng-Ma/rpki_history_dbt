{{
  config(
    materialized = 'view'
  )
}}

with monthly as (

    select
        cc,
        family as ip_version,
        toStartOfMonth({{ adapter.quote('time') }}) as month,
        round(
            argMin(
                delegated__space__covered_by_rpki__count
                * 100.0
                / delegated__space__count,
                {{ adapter.quote('time') }}
            ),
            2
        ) as start_of_month_coverage,
        round(
            avg(
                delegated__space__covered_by_rpki__count
                * 100.0
                / delegated__space__count
            ),
            2
        ) as avg_daily_coverage,
        argMax(
            delegated__space__covered_by_rpki__count,
            {{ adapter.quote('time') }}
        ) as latest_rpki_covered_space,
        argMax(
            delegated__space__count,
            {{ adapter.quote('time') }}
        ) as latest_delegated_space,
        count() as observed_days
    from {{ ref('stg_rpki_history') }}
    where delegated__space__count > 0
      and delegated__space__covered_by_rpki__count is not null
    group by
        month,
        cc,
        ip_version

),

earliest as (

    select
        cc,
        ip_version,
        argMin(start_of_month_coverage, month) as earliest_coverage
    from monthly
    group by
        cc,
        ip_version

)

select
    current.cc as cc,
    current.ip_version as ip_version,
    current.month as month,
    current.start_of_month_coverage as start_of_month_coverage,
    current.avg_daily_coverage as avg_daily_coverage,
    current.latest_rpki_covered_space as latest_rpki_covered_space,
    current.latest_delegated_space as latest_delegated_space,

    round(
        current.start_of_month_coverage
        - if(
            countIf(previous.month <= addYears(current.month, -5)) = 0,
            earliest.earliest_coverage,
            argMaxIf(
                previous.start_of_month_coverage,
                previous.month,
                previous.month <= addYears(current.month, -5)
            )
        ),
        2
    ) as coverage_diff_5y,

    round(
        current.start_of_month_coverage
        - if(
            countIf(previous.month <= addYears(current.month, -3)) = 0,
            earliest.earliest_coverage,
            argMaxIf(
                previous.start_of_month_coverage,
                previous.month,
                previous.month <= addYears(current.month, -3)
            )
        ),
        2
    ) as coverage_diff_3y,

    round(
        current.start_of_month_coverage
        - if(
            countIf(previous.month <= addYears(current.month, -1)) = 0,
            earliest.earliest_coverage,
            argMaxIf(
                previous.start_of_month_coverage,
                previous.month,
                previous.month <= addYears(current.month, -1)
            )
        ),
        2
    ) as coverage_diff_1y,

    current.observed_days as observed_days
    
from monthly as current
left join monthly as previous
    on current.cc = previous.cc
   and current.ip_version = previous.ip_version
   and previous.month <= current.month
left join earliest
    on current.cc = earliest.cc
   and current.ip_version = earliest.ip_version
group by all
