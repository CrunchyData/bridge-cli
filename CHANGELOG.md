# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- `cb list` command now accepts `--format`. Supports: `table` and `tree`.
- `cb list` command now accepts `--team`.
- `cb maintenance update` and `cb upgrade update` update a pending maintenance
  and a pending upgrade respectively.

### Fixed
- `cb psql` no longer overrides a users `.psqlrc` with `\x auto` which was
  causing unexpected formatting for some users.
- `cb info` now returns new cluster states: `resuming`, `suspended`, `suspending`.
- `cb upgrade cancel` now only cancels upgrades.
- `cb maintenance cancel` now only cancels only maintenances.

## [3.2.0] - 2023-02-28
### Added
- `cb maintenance` command now supports `cancel` and `create`
- `cb network` command added to manage networks. Supports `list` and `info`.
- `cb upgrade status` returns maintenance window information
- `cb upgrade start` command accepts `--starting-from` and `--now` options that
   specify upgrade failover window.
- Specifying an application ID when adding an API key is no longer necessary. A
  "prefixed" API key starting with `cbkey_` is necessary for use with cb. (All
  new API keys are prefixed.)

### Fixed
- Fix `--network` not being honored when passed with `cb create --replica`.
- `cb upgrade start` don't change `ha` by default.

## [3.1.0] - 2022-11-18
### Added
- `cb tailscale` command added to add and remove a cluster from a Tailscale
  network. Supports `connect` and `disconnect`.
- `cb maintenance` command added to manage cluster maintenance windows. Supports
  `info` and `update`.
- `cb info` now returns some maintenance window information

### Fixed
- Fix cluster id bug with `cb restart`

## [3.0.2] - 2022-10-24
### Fixed
 - Fix cluster id parsing bug with `cb logs`.

## [3.0.1] - 2022-10-19
### Fixed
 - Fix cluster id parsing bug with `cb backup list`.

## [3.0.0] - 2022-10-18
### Added
- Support for using cluster name or id with most commonly used commands.
- `host` field to `cb info` output.

### Fixed
 - Fix `cpu` and `memory` type due to recent API changes from `Int` to `Float`.

## [2.2.1] - 2022-08-22
### Fixed
- No output from `cb token`.

## [2.2.0] - 2022-08-19
### Added
- `cb role list` shows current roles for a cluster.
- `cb psql` to take `--role` to specify the name of the role to connect.
- `cb logout` to logout a user from the CLI.


## [2.1.0] - 2022-06-03
### Added
- `cb backup list` shows current backups for a cluster.
- `cb backup token` creates a backup token for a cluster.
- `cb suspend` and `resume` to temporarily stop running a cluster.
- `cb backup capture` manually starts a backup for a cluster.

### Fixed
- Fix required arguments check for `cb upgrade cancel` and `cb upgrade status`.

## [2.0.0] - 2022-05-17
### Added
- `--full` option to `cb restart` to restart the entire server.

### Removed
- `cb teams` removed in favor of `cb team list`.

### Changed
- Updated `cb scope` connections to utilize SCRAM with channel binding only.

## [1.3.0] - 2022-05-03
### Added
- Fully respect the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- `cb logs` command added to view live logs for a cluster.
- The env var `SSL_CERT_FILE` can be used to override the default location of
  the certificate file.

### Fixed
- Fix `unknown ca` error with `cb psql`.
- Fix cluster creation error after the API became stricter.

## [1.2.0] - 2022-04-07
### Added
- `cb team` command added to manage teams. Supports `create`, `list`, `info`,
  `update` and `destroy`.
- `cb uri` can take `--role` to specify the name of the role to retrieve.
- `cb role` command added to manage cluster roles. Supports `create`, `update`
  and `destroy`.
- `cb upgrade` command added to upgrade clusters. Supports `start`, `cancel` and
  `status` sub-commands.
- `cb detach` command added to detach clusters.
- `cb restart` command added to restart clusters.
- `cb rename` command added to rename clusters.

### Changed
* Improved error message when local psql command cannot be found.

### Deprecated
- `cb teams` deprecated in favor of `cb team list`.

## [1.1.0] - 2022-01-27
### Added
- `cb psql` can take `--database` to specify the name of the database to
  connect.
- `cb scope` can take `--database` to specify the name of the database to
  connect.
- `cb create` can take `--version` to specify the major postgres version of the
  new cluster.

### Changed
- `cb teams` now only shows your highest permission. "Administrator" is now "Admin"

### Fixed
- The --ha flag for `cb create` now actually works

## [1.0.0] - 2021-11-29
### Fixed
- Fix for API change with /clusters
- Fixed link to get API tokens

## [0.7.5] - 2021-10-19
### Added
- `cb uri` displays the URI for a cluster with the password displayed as
  black-on-black so you can still copy and paste it, but it has less of a
  chance of being unexpectedly leaked
- `cb info` now shows source cluster id for replica clusters.

### Fixed
- Replica clusters show up in `cb list` as well as tab completion for clusters.

## [0.7.4] - 2021-10-05
### Fixed
- `cb list` shows clusters from all teams, not just personal

## [0.7.3] - 2021-09-30
### Added
- Cluster info now shows network id

## [0.7.2] - 2021-09-16
### Fixed
- Fix error tracking

### Changed
- `cb whoami` output improved

## [0.7.1] - 2021-09-16
### Fixed
- Fix error tracking (incorrectly, as it turned out)

## [0.7.0] - 2021-09-15
### Added
- `cb create` with and without `--fork` can take `--network` to create the new cluster in an existing network
- Error tracking for unhandled exceptions

### Changed
- `cb token -H` is now the flag for the full header version, not `-h` to avoid
  conflicting with help

## [0.6.0] - 2021-08-03
### Changed
- `cb fork` command removed. Forks can now be created with `cb create --fork`

### Added
- `cb create --replica` to create read-replicas of clusters. Note: these cannot
  be seen nor deleted from `cb` at this time

### Fixed
- Cluster names can now have hyphens

## [0.5.0] - 2021-07-29
### Added
- `cb scope` to run diagnostic queries on your cluster

### Fixed
- `cb list` no longer has an unhandled exception when you have no clusters
- All requests now send the full absoluteURI on the Request-Line instead of the
  abs_path which is REQUIRED when a request is being sent to a proxy per the
  (http spec)[https://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html#sec5]

## [0.4.0] - 2021-07-09
### Added
- `cb token -h` to print the token as a full authorization header which can be
  passed to curl directly such as:`curl -H (cb token -h) https:://api.crunchybridge.com/clusters`

### Fixed
- Completion for `cb version` fixed to remove `--`
- Completion for `cb create` for azure plans and regions
- Fix path for TLS certs on arm macs running in rosetta with a statically linked openssl

## [0.3.1] - 2021-07-03
First public release
