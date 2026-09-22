# Technical walkthrough
The addon resource is mods/toritte/frv_multiselect. It clears the FRV category bit (bit 21 at record offset 0x104) in three allowlisted records: 105, 26 and 135. Each edit changes one byte at offset 0x106. No exosuit or Bastion records are written by this addon.

Initialization checks the executable and game DLL hashes, original selection code, settings layout and all baseline record flags. Data must already be private read/write memory. The addon does not change executable instructions or page protection. Failed writes trigger ownership-checked restoration.

When Exosuit MultiSelect v0.3 is present, the addon waits for it to apply, then accepts exactly its four expected exosuit classification changes in the baseline. Other changes still fail the checks.

The package preserves the normal four slots and does not modify equipment unlocks, duplicate-selection rules, cooldown values or call-in counts.
