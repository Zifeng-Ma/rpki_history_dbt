with source as (
        select * from {{ source('project', 'rpki_history') }}
  ),
  renamed as (
      select
        {{ adapter.quote("cc") }},
        {{ adapter.quote("time") }},
        {{ adapter.quote("family") }},
        {{ adapter.quote("rpki__vrp_count") }},
        {{ adapter.quote("delegated__samples") }},
        {{ adapter.quote("delegated__space__count") }},
        {{ adapter.quote("delegated__space__covered_by_rpki__count") }},
        {{ adapter.quote("delegated__prefixes__count") }},
        {{ adapter.quote("delegated__prefixes__covered_by_rpki__count") }},
        {{ adapter.quote("_dlt_load_id") }},
        {{ adapter.quote("_dlt_id") }}

      from source
  )
  select * from renamed
    