{% macro generate_clickhouse_source(database_name, table_name=none, table_names=none) %}

  {% set target_tables = [] %}
  {% if table_name %}
    {% do target_tables.append(table_name) %}
  {% elif table_names %}
    {% if table_names is string %}
      {% do target_tables.append(table_names) %}
    {% else %}
      {% set target_tables = table_names %}
    {% endif %}
  {% endif %}

  {% set query %}
    SELECT 
        table,
        name AS column_name
    FROM system.columns
    WHERE database = '{{ database_name }}'
    {% if target_tables | length > 0 %}
      AND table IN (
        {%- for t in target_tables -%}
          '{{ t }}'{%- if not loop.last -%}, {%- endif -%}
        {%- endfor -%}
      )
    {% endif %}
    ORDER BY table, position
  {% endset %}

  {% set results = run_query(query) %}

  {% if execute %}
    {% set tables_dict = {} %}
    {% for row in results %}
      {% set tbl = row[0] %}
      {% set col = row[1] %}
      {% if tbl not in tables_dict %}
        {% do tables_dict.update({tbl: []}) %}
      {% endif %}
      {% do tables_dict[tbl].append(col) %}
    {% endfor %}

    {% set yaml_lines = [] %}
    {% do yaml_lines.append('version: 2\n\nsources:') %}
    {% do yaml_lines.append('  - name: ' ~ database_name) %}
    {% do yaml_lines.append('    tables:') %}

    {% for tbl, columns in tables_dict.items() %}
      {% do yaml_lines.append('      - name: ' ~ tbl) %}
      {% do yaml_lines.append('        columns:') %}
      {% for col in columns %}
        {% do yaml_lines.append('          - name: ' ~ col) %}
      {% endfor %}
    {% endfor %}

    {% set final_yaml = yaml_lines | join('\n') %}
    {{ print(final_yaml) }}
    {% do return(final_yaml) %}
  {% endif %}

{% endmacro %}