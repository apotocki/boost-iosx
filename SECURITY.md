# Security Policy

## About this project

`boost-iosx` provides **build scripts** that compile [Boost](https://www.boost.org/)
C++ libraries for Apple platforms (iOS/macOS/etc.). This repository does
**not** contain or modify Boost's own source code as a distributed product —
it downloads verified upstream Boost sources, applies a small set of patches
needed to make the build succeed, and produces artifacts on the user's own
machine.

Prebuilt artifacts occasionally published under **Releases** are provided
only to verify that the build scripts work correctly (self-test / CI
verification, and optional convenience for other projects that want a
ready-made artifact for their own build/test pipelines). They are **not**
intended as a production distribution channel, and are not the primary
deliverable of this project — the build script itself is.

## Branching model

This repository maintains a separate branch per supported Boost version
(e.g. `boost-1.86`, `boost-1.85`), each containing:
- its own adapted build script for that Boost version,
- its own SHA256 checksum used to verify the downloaded Boost source archive,
- its own set of source/build-script patches for that version, stored
  directly in this repository (no patches are fetched from external
  sources).

The security policy below applies uniformly across all branches. When
reporting an issue, please specify the affected branch(es)/version(s).

## Scope

**In scope** for security reports:
- The build and patch scripts in this repository
- The GitHub Actions workflows used to build and test
- The integrity of the Boost source download (including the SHA256
  verification step)
- Any patches applied to Boost sources or its internal build scripts prior
  to compilation

**Out of scope** (please report elsewhere):
- Vulnerabilities in Boost library code itself — please report to the
  [upstream Boost project](https://www.boost.org/security/)
- Issues found only in artifacts published under Releases, since these are
  provided for build verification only and are not a supported production
  distribution

## Reporting a Vulnerability

Please **do not** open a public GitHub issue for security concerns, since
this could disclose exploitable details before a fix is available.

Instead, please report privately via
[GitHub Security Advisories](https://github.com/apotocki/boost-iosx/security/advisories/new)
for this repository.

Please include:
- The affected branch(es) / Boost version(s)
- Steps to reproduce, or a description of the issue
- Any relevant logs or workflow run links

This is a personal open-source project maintained on a best-effort,
volunteer basis — there is no guaranteed response time or SLA. Reports will
be looked at as time permits, and reasonable security issues will typically
be prioritized over other open items. If a fix requires coordinated
disclosure (e.g. an upstream Boost issue), we will try to follow the
upstream project's disclosure timeline where applicable.

## Supported Versions

| Branch                                                                  | Boost version | Supported |
|--------------------------------------------------------------------------|---------------|-----------|
| [`1.91.0`](https://github.com/apotocki/boost-iosx/tree/1.91.0)         | 1.91.0        | ✅        |
| [`1.90.0`](https://github.com/apotocki/boost-iosx/tree/1.90.0)         | 1.90.0        | ✅        |
| [`1.89.0`](https://github.com/apotocki/boost-iosx/tree/1.89.0)         | 1.89.0        | ✅        |
| [`1.88.0`](https://github.com/apotocki/boost-iosx/tree/1.88.0)         | 1.88.0        | ✅        |
| [`1.87.0`](https://github.com/apotocki/boost-iosx/tree/1.87.0)         | 1.87.0        | ✅        |
| [`1.86.0`](https://github.com/apotocki/boost-iosx/tree/1.86.0)         | 1.86.0        | ✅        |
| [`1.85.0`](https://github.com/apotocki/boost-iosx/tree/1.85.0)         | 1.85.0        | ✅        |
| [`1.84.0`](https://github.com/apotocki/boost-iosx/tree/1.84.0)         | 1.84.0        | ✅        |

> Update this table as branches are added or retired. Branches not listed
> here, or marked ❌, do not receive security fixes.
