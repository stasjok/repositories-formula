{%- set os_family = salt['grains.get']('os_family') %}
{%- set apt_based = ['Debian'] %}
{%- set rpm_based = ['RedHat', 'Suse'] %}

{%- if os_family in apt_based %}

include:
  - .apt

{%- elif os_family in rpm_based %}

include:
  - .rpm

{%- endif %}
