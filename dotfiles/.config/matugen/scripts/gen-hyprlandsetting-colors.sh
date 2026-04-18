#!/usr/bin/env bash

INPUT_FILE="$HOME/.config/com.ml4w.hyprlandsettings/hyprctl.json"
OUTPUT_FILE="$HOME/.config/matugen/hyprlandsettings.json"

touch "$OUTPUT_FILE"

jq '
{
  hyprlandsettings:
    (reduce .[] as $item ({}; 
      # split key into parts
      ($item.key | split(":")) as $rawkeys

      # transform keys: replace "col.*" with ["colors", "..."]
      | ($rawkeys | map(
          if startswith("col.") then
            ["colors", (sub("^col\\."; ""))]
          else
            .
          end
        ) | flatten) as $keys

      # detect if this is a color entry
      | ($rawkeys | any(startswith("col."))) as $isColor

      # assign value
      | setpath($keys;
          (if $isColor then
              { color: ($item.value | sub("^0x[0-9a-fA-F]{2}"; "#")) }
            else
              (if ($item.value == "true") then true
              elif ($item.value == "false") then false
              else $item.value end)
            end)
        )
    ))
}
' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "Generate JSON hyprlandsetting matugen: $OUTPUT_FILE"