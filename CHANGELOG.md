# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
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
