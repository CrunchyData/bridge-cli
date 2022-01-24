# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
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
