<* for name, value in colors *>
{{name}} = "rgba({{value.default.hex_stripped}}ff)"
<* endfor *>

<* for name, value in colors *>
{{name}}_dark = "rgba({{value.dark.hex_stripped}}ff)"
<* endfor *>

