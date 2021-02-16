{%- set manage_sources_list =
  salt['config.get']('repositories:manage_sources_list', False)|to_bool %}

{%- set repos = salt['config.get']('repositories:repos', {}) %}

{%- if manage_sources_list %}
repositories-sources_list-file:
  file.managed:
    - name: /etc/apt/sources.list
    - contents: {{ salt['config.get']('repositories:sources_list', '') }}
    - user: root
    - group: root
    - mode: 644
    - onchanges_in:
      - repositories-apt-refresh_db

{%- if repos %}
repositories-apt-sources_list-refresh_db:
  module.run:
    - name: pkg.refresh_db
    - onchanges:
      - file: /etc/apt/sources.list
    - prereq:
      - pkg: gnupg
{%- endif %}
{%- endif %}

{#- gnupg required for apt-key #}
{%- if repos %}
repositories-gnupg-installed:
  pkg.installed:
    - name: gnupg
{%- endif %}

{%- for source_file, repo_opts in repos|dictsort %}

  {%- set file = salt['file.join']('/etc/apt/sources.list.d', source_file)|
    regex_replace('(?:\.list)?$', '.list') %}

  {%- if repo_opts.pop('absent', False) %}

{#- remove repo #}
repositories-{{ source_file }}-absent:
  pkgrepo.absent:
    {%- for key, value in repo_opts|dictsort %}
    - {{ key }}: {{ value|yaml_encode }}
    {%- endfor %}
    - require:
      - pkg: gnupg
    - onchanges_in:
      - repositories-apt-refresh_db

  {%- else %}

{#- add repo #}
'repositories-{{ source_file }}-pkgrepo':
  pkgrepo.managed:
    - file: {{ file }}
    {%- for k, v in repo_opts|dictsort %}
    - {{ k }}: {{ v|yaml_encode }}
    {%- endfor %}
    - clean_file: yes
    - refresh: no
    - require:
      - pkg: gnupg
    - onchanges_in:
      - repositories-apt-refresh_db

  {%- endif %}

{%- endfor %}

{%- if manage_sources_list or repos %}
repositories-apt-refresh_db:
  module.run:
    - name: pkg.refresh_db
{%- endif %}
