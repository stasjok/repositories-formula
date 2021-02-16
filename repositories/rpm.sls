{%- set repos = salt['config.get']('repositories:repos', {}) %}
{%- set del_repo_keys = salt['config.get']('repositories:del_repo_keys', []) %}
{%- set releases = salt['config.get']('repositories:releases', []) %}
{%- set releases_absent = salt['config.get']('repositories:releases_absent', []) %}
{%- set releases_without_deps = releases|sequence|reject('mapping')|list %}
{%- set releases_with_deps = releases|sequence|select('mapping')|list %}

{#- get current keys #}
{%- set keys = salt['pkg.get_repo_keys']() %}
{#- find key ids in list of rpm keys (gpg-pubkey-307e3d54-5aaa90a5) #}
{%- set del_keys = [] %}
{%- for key in del_repo_keys|sequence %}
  {#- remove whitespaces, to lowercase and get only last 8 characters #}
  {%- set key = ''.join(key.split()).lower()[-8:] %}
  {#- select matched keys and append to list for deletion #}
  {%- set key = keys|select('match', 'gpg-pubkey-'~key)|list %}
  {%- do del_keys.extend(key) %}
{%- endfor %}

{#- gpg keys to import; will be appended later in 'manage repositories' loop #}
{%- set add_key_urls = [] %}
{%- set add_key_texts = [] %}


{#- manage *-release packages #}
{%- if releases_absent %}

repositories-releases-absent:
  pkg.removed:
    - pkgs: {{ releases_absent|sequence|yaml }}

{%- endif %}

{%- if releases_without_deps %}

repositories-releases-installed:
  pkg.installed:
    - pkgs: {{ releases_without_deps|sequence|yaml }}

{%- endif %}

{%- for release_dict in releases_with_deps %}
  {%- for release, deps in release_dict|dictsort %}

repositories-{{ release }}-installed:
  pkg.installed:
    - name: {{ release }}
    {%- if 'require' in deps and deps.require %}
    - require:
      {%- for name in deps.require|sequence %}
      - pkgrepo: {{ name }}
      {%- endfor %}
    {%- endif %}
    {%- if 'require_in' in deps and deps.require_in %}
    - require_in:
      {%- for name in deps.require_in|sequence %}
      - pkgrepo: {{ name }}
      {%- endfor %}
    {%- endif %}

  {%- endfor %}
{%- endfor %}


{#- manage repositories #}
{%- for name, values in repos|dictsort %}

  {#- if repo is absent #}
  {%- if values.pop('absent', False) %}

{#- remove repository #}
repositories-repo-{{ name }}-absent:
  pkgrepo.absent:
    - name: {{ name }}

  {#- if repo is not absent #}
  {%- else %}

    {#- append to list of keys for import #}
    {%- set key_id = values.pop('key_id', 'xxxxxxxx') %}
    {%- set key_id = ''.join(key_id.split()).lower()[-8:] %}
    {%- set key_url = values.pop('key_url', False) %}
    {%- set key_text = values.pop('key_text', False) %}
    {%- if key_id == 'xxxxxxxx' or not key_id|substring_in_list(keys) %}
      {%- if key_url %}
        {%- do add_key_urls.append({'id': key_id, 'url': key_url}) %}
      {%- elif key_text %}
        {%- do add_key_texts.append({'id': key_id, 'text': key_text}) %}
      {%- endif %}
    {%- endif %}

{#- add repository #}
repositories-repo-{{ name }}:
  pkgrepo.managed:
    - name: {{ name }}
    {%- for key, value in values|dictsort %}
    - {{ key }}: {{ value|yaml_encode }}
    {%- endfor %}

  {#- end if repos is absent #}
  {%- endif %}

{%- endfor %}


{#- import keys by url #}
{%- for key in add_key_urls %}

{#- in case key_id is not provided, use simple number #}
{%- set key_id = key.id if key.id and key.id != 'xxxxxxxx' else loop.index %}

repositories-keyurl-{{ key_id }}-import:
  module.run:
    - name: pkg.add_repo_key
    - path: {{ key.url|yaml_encode }}

{%- endfor %}


{#- import keys by text #}
{%- for key in add_key_texts %}

{#- in case key_id is not provided, use simple number #}
{%- set key_id = key.id if key.id and key.id != 'xxxxxxxx' else loop.index %}

repositories-keytext-{{ key_id }}-import:
  module.run:
    - name: pkg.add_repo_key
    - text: {{ key.text|yaml_encode }}

{%- endfor %}


{#- remove gpg keys #}
{%- for key in del_keys %}

repositories-del-{{ key }}:
  module.run:
    - name: pkg.del_repo_key
    - keyid: {{ key }}

{%- endfor %}
