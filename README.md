# MultiTele

MultiTele is a three-finger Telegram tweak manager for Mx, iQTele and Lead.

## Panel
- Default language: Arabic.
- Supported panel languages: Arabic, English, French, Spanish, Chinese, Turkish, Persian, Russian, Vietnamese and Indonesian.
- Touch Telegram with three fingers together to open the panel.
- Choose one or more tweaks and tap **Done**. MultiTele saves the choices and closes Telegram so the selected tweaks are applied on the next launch.
- Choosing a different panel language also saves the language and closes Telegram so the whole UI reloads in that language.

## GitHub Actions
Run **Build MultiTele** from Actions. Download the `MultiTele-Feather` artifact and inject all four dylibs into Telegram with Feather:

- `MultiTele.dylib`
- `Mx.dylib`
- `iQTele.dylib`
- `Lead.dylib`

Use only the Mx/iQTele/Lead files produced by the workflow because they are patched for managed startup.

## Links shown in the panel
- https://t.me/ikiraplus
- https://t.me/ikira18
- https://ipastore.pages.dev

The three panel images use the direct raw GitHub image URLs supplied for iKiraPlus.

> iOS does not provide a supported API for an app to relaunch itself. MultiTele closes Telegram after Done/language change; open Telegram again to complete the restart.


## Apply behavior
- Choosing a different panel language saves it, shows a confirmation alert, and closes Telegram after OK. Reopen Telegram to see the new language.
- Tapping Done saves tweak choices and closes Telegram so they apply on the next launch.
- The three displayed URLs are directly tappable and open their destinations.
