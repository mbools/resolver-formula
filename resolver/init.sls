#####################################
##### Salt Formula For Resolver #####
#####################################

{% set is_resolvconf_enabled = grains['os'] == 'Ubuntu' and salt['pkg.version']('resolvconf') and  salt['pillar.get']('resolver:resolvconf', true) %}

{% if not salt['pillar.get']('resolver:resolvconf', true) %}
remove-resolvconf:
  pkg.purged:
    - name: resolvconf
    - onchanges_in:
      - file: remove-symlink

remove-symlink:
  file.absent:
    - name: /etc/resolv.conf

{% set is_resolvconf_enabled = false %}

{% endif %}

# Resolver Configuration
resolv-file:
  file.managed:
    {% if is_resolvconf_enabled %}
    - name: /etc/resolvconf/resolv.conf.d/base
    {% else %}
    - name: /etc/resolv.conf
    {% endif %}
    - user: root
    - group: root
    - mode: '0644'
    - source: salt://resolver/files/resolv.conf
    - template: jinja
    - defaults:
        nameservers: {{ salt['pillar.get']('resolver:nameservers', ['8.8.8.8','8.8.4.4']) }}
        searchpaths: {{ salt['pillar.get']('resolver:searchpaths', [salt['grains.get']('domain'),]) }}
        options: {{ salt['pillar.get']('resolver:options', []) }}

{% if is_resolvconf_enabled %}
resolv-update:
  cmd.run:
    - name: resolvconf -u
    - onchanges:
      - file: resolv-file
{% endif %}
