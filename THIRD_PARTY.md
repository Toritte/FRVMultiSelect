# Third-party dependencies and inputs
## Bingus Shared Loader — separate dependency
Author: CowboyBingus. Required version: v15 / API 1.
Download: https://ayakamods.com/mods/bingus-shared-loader.3861/
Source and instructions: https://github.com/CowboyBingus/BingusSharedLoader

CowboyBingus requested that the loader not be bundled or redistributed, and that its download location be credited. This package does not include the loader runtime, dispatcher or startup replacement. Install it separately.

The archive format and addon declaration were studied from its build tooling at commit `836427cef78b8a67cf771c1f16291d93be921744`. This repository has a self-contained Python packager; the upstream loader source tree is not bundled.

## Reused Windows adapter
`src/windows_api.lua` is copied from [BetterStratagemBounce](https://github.com/CowboyBingus/BetterStratagemBounce), commit `2eb2021750cbb37a80af54223d9a7aa56d2c7cf7`, file `src/windows_api.lua`, by CowboyBingus. Its contents also form part of the generated mod archive.

No repository-wide license was found for this snapshot. Permission specifically covering redistribution of this adapter has not been recorded. The separate-loader instruction alone does not establish the adapter's reuse terms. Confirm and record those terms before publishing these prepared sources or the binary package; attribution alone is not a permission grant. This document does not relicense upstream code.

## Game reference data
The supported-build configuration contains hashes, record identifiers/flags and a 724-byte validation signature. It does not contain the game executable or full captured memory. Helldivers 2 and its assets belong to their respective owners; no ownership of them is claimed here.
