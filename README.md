# repositories-formula

SaltStack formula for managing repositories.

## Table of Contents

* [General notes](#general-notes)
* [Available states](#available-states)
  * [repositories](#repositories)
  * [repositories.apt](#repositories.apt)
  * [repositories.rpm](#repositories.rpm)

## General notes

See the full [SaltStack Formulas installation and usage instructions](https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html).

**WARNING**: This formula is using `pkg.get_repo_keys`/`pkg.add_repo_key`
functions which are not available in current versions of SaltStack. So this
formula is not functional for RPM-based distributions until
<https://github.com/saltstack/salt/pull/58784> is merged. These functions are
available in [openSUSE fork](https://github.com/openSUSE/salt). SUSE's version
of SaltStack is used in SUSE Manager/[Uyuni](https://www.uyuni-project.org/).

See `pillar.example` file for configuration examples.

## Available states

### repositories

*Meta-state (This is a state that includes other states)*.

This state includes other states based on os_family.

### repositories.apt

This state manages repositories for apt-based distributions. You don't need
to use it directly.

### repositories.rpm

This state manages repositories for rpm-based distributions. You don't need
to use it directly.
