# -*- coding: utf-8 -*-
# vim: ft=sls
{%- from "haproxy/map.jinja" import haproxy with context %}
{%- set install_from   = haproxy.install_from|default('package') -%}
{%- set version   = haproxy.version|default('1.5.11') -%}
{%- set vhash   = haproxy.vhash|default('5500a79d0d2b238d4a1e9749bd0c2cb2') -%}
{%- set release   = haproxy.release|default('1') -%}

# install from source
{%- if install_from == 'source' %}
haproxy_src_pkgs:
  pkg:
    - installed
    - pkgs: {{ haproxy.sourcepkgs }}

{%- for dir in ('rpmbuild','rpmbuild/SPECS', 'rpmbuild/SOURCES') %}
/root/{{ dir }}:
  file.directory:
    - user: root
    - group: root
{%- endfor %}

/root/rpmbuild/SPECS/haproxy.spec:
  file.managed:
    - source: salt://haproxy/source/centos7/haproxy.spec
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      version: {{ version }}
      release: {{ release }}

/root/rpmbuild/SOURCES/halog.1:
  file.managed:
    - source: salt://haproxy/source/centos7/halog.1
    - user: root
    - group: root
    - mode: 644

/root/rpmbuild/SOURCES/haproxy.logrotate:
  file.managed:
    - source: salt://haproxy/source/centos7/haproxy.logrotate
    - user: root
    - group: root
    - mode: 644

/root/rpmbuild/SOURCES/haproxy.cfg:
  file.managed:
    - source: salt://haproxy/files/haproxy.cfg
    - user: root
    - group: root
    - mode: 644

/root/rpmbuild/SOURCES/haproxy.service:
  file.managed:
    - source: salt://haproxy/files/haproxy.service
    - user: root
    - group: root
    - mode: 644

/root/rpmbuild/SOURCES/haproxy-{{ version }}.tar.gz:
  file.managed:
    - source: http://www.haproxy.org/download/1.5/src/haproxy-{{ version }}.tar.gz
    - source_hash: md5={{ vhash }}
    - user: root
    - group: root
    - mode: 644

haproxy_build_rpm:
  cmd:
    - wait
    - name: rpmbuild -ba /root/rpmbuild/SPECS/haproxy.spec
    - user: root
    - shell: /bin/bash
    - watch:
      - file: /root/rpmbuild/SPECS/haproxy.spec
      - file: /root/rpmbuild/SOURCES/halog.1
      - file: /root/rpmbuild/SOURCES/haproxy.logrotate
      - file: /root/rpmbuild/SOURCES/haproxy.cfg
      - file: /root/rpmbuild/SOURCES/haproxy.service
      - file: /root/rpmbuild/SOURCES/haproxy-{{ version }}.tar.gz

haproxy:
  pkg.installed:
    - sources:
      - haproxy: /root/rpmbuild/RPMS/x86_64/haproxy-{{ version }}-{{ release }}.el7.centos.{{ grains['cpuarch'] }}.rpm
    - watch:
      - module: haproxy-old

haproxy-old:
  cmd.run:
    - name: /bin/true
    - onlyif: "rpm -q haproxy && ! rpm -q haproxy-{{ version }}"
  module.wait:
    - name: pkg.purge
    - pkgs: 
      - haproxy
    - watch:
      - cmd: haproxy-old

## else not install_from_source
{%- elif install_from == 'package' %}

# Because on Ubuntu we don't have a current HAProxy in the usual repo, we add a PPA
{%- if salt['grains.get']('osfullname') == 'Ubuntu' %}
haproxy_ppa_repo:
  pkgrepo.managed:
    - ppa: vbernat/haproxy-1.5
    - require_in:
      - pkg: haproxy.install
    - watch_in:
      - pkg: haproxy.install
{%- endif %}

haproxy.install:
  pkg.installed:
    - name: haproxy
## endif after else/install_from_source
{%- endif %}



