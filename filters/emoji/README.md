Emoji assets for B2 notes (local)

Two options:

1) Manual: Drop PNGs into this folder with the names used by the filter.
   - 1f604.png for :smile: and 😄
   - 1f680.png for :rocket: and 🚀
   - 26a0.png  for :warning: and ⚠️
   - 1f4a1.png for :bulb: and 💡
   - 1f4dd.png for :memo: and 📝
   - 1f4c8.png for :chart_with_upwards_trend: and 📈
   - 1f539.png for 🔹

2) Auto-download (Twemoji subset):
   - License: CC-BY 4.0; see ATTRIBUTION.md
   - Requires curl and a Lua with json support (dkjson). Quick usage:

     lua fetch_twemoji.lua

   - This downloads PNGs into the current folder based on twemoji_manifest.json.

If an expected image is missing, the filter falls back to text so PDF builds do not fail.
