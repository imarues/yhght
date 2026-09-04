# Feather

1. Build the project with GitHub Actions.
2. Download the `MultiTele-Feather` artifact.
3. In Feather, open the Telegram IPA and add these four files under Tweaks:
   - MultiTele.dylib
   - Mx.dylib
   - iQTele.dylib
   - Lead.dylib
4. Sign and install Telegram.
5. Touch the Telegram screen with three fingers together to open MultiTele.
6. Choose tweaks and tap Done. Telegram closes; reopen it to apply the selection.

Do not replace the workflow-produced Mx/iQTele/Lead dylibs with the original versions.

## Mx / Lead compatibility
Mx and Lead are mutually exclusive in MultiTele. Enabling one automatically disables the other. iQTele can be enabled with either one.
