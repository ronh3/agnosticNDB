agnosticdb = agnosticdb or {}

agnosticdb.colors = agnosticdb.colors or {}

local palette = {
  "black",
  "red",
  "firebrick",
  "brown",
  "saddle_brown",
  "SaddleBrown",
  "ansi_light_red",
  "ansiLightRed",
  "sienna",
  "dim_grey",
  "DimGrey",
  "dim_gray",
  "DimGray",
  "orange_red",
  "OrangeRed",
  "indian_red",
  "IndianRed",
  "chocolate",
  "tomato",
  "DarkGoldenrod",
  "dark_goldenrod",
  "peru",
  "rosy_brown",
  "RosyBrown",
  "coral",
  "light_coral",
  "LightCoral",
  "salmon",
  "dark_orange",
  "DarkOrange",
  "dark_salmon",
  "DarkSalmon",
  "goldenrod",
  "ansiYellow",
  "ansi_yellow",
  "ansiLightYellow",
  "ansi_light_yellow",
  "orange",
  "sandy_brown",
  "SandyBrown",
  "LightSalmon",
  "light_salmon",
  "tan",
  "burlywood",
  "grey",
  "gray",
  "light_grey",
  "LightGray",
  "LightGrey",
  "light_gray",
  "gainsboro",
  "wheat",
  "peach_puff",
  "PeachPuff",
  "navajo_white",
  "NavajoWhite",
  "moccasin",
  "bisque",
  "MistyRose",
  "misty_rose",
  "AntiqueWhite",
  "antique_white",
  "blanched_almond",
  "BlanchedAlmond",
  "PapayaWhip",
  "papaya_whip",
  "linen",
  "WhiteSmoke",
  "white_smoke",
  "old_lace",
  "OldLace",
  "seashell",
  "FloralWhite",
  "floral_white",
  "snow",
  "transparent",
  "white",
  "ivory",
  "LightYellow",
  "light_yellow",
  "lemon_chiffon",
  "LemonChiffon",
  "cornsilk",
  "LightGoldenrodYellow",
  "light_goldenrod_yellow",
  "beige",
  "yellow",
  "pale_goldenrod",
  "PaleGoldenrod",
  "khaki",
  "GreenYellow",
  "green_yellow",
  "light_goldenrod",
  "LightGoldenrod",
  "ansiLightBlack",
  "ansi_light_black",
  "gold",
  "ansi_white",
  "ansiWhite",
  "YellowGreen",
  "yellow_green",
  "DarkKhaki",
  "dark_khaki",
  "ansiLightGreen",
  "ansi_light_green",
  "olive_drab",
  "OliveDrab",
  "dark_olive_green",
  "DarkOliveGreen",
  "DarkGreen",
  "dark_green",
  "forest_green",
  "ForestGreen",
  "ansi_green",
  "ansiGreen",
  "lime_green",
  "LimeGreen",
  "DarkSeaGreen",
  "dark_sea_green",
  "green",
  "LawnGreen",
  "lawn_green",
  "chartreuse",
  "PaleGreen",
  "pale_green",
  "honeydew",
  "MintCream",
  "mint_cream",
  "aquamarine",
  "SpringGreen",
  "spring_green",
  "turquoise",
  "MediumSpringGreen",
  "medium_spring_green",
  "medium_aquamarine",
  "MediumAquamarine",
  "medium_turquoise",
  "MediumTurquoise",
  "ansiLightCyan",
  "ansi_light_cyan",
  "medium_sea_green",
  "MediumSeaGreen",
  "light_sea_green",
  "LightSeaGreen",
  "sea_green",
  "SeaGreen",
  "dark_slate_grey",
  "DarkSlateGray",
  "dark_slate_gray",
  "DarkSlateGrey",
  "ansiBlue",
  "ansi_blue",
  "SteelBlue",
  "steel_blue",
  "dodger_blue",
  "DodgerBlue",
  "SlateGrey",
  "slate_gray",
  "slate_grey",
  "SlateGray",
  "light_slate_grey",
  "LightSlateGrey",
  "LightSlateGray",
  "light_slate_gray",
  "cadet_blue",
  "CadetBlue",
  "CornflowerBlue",
  "cornflower_blue",
  "deep_sky_blue",
  "DeepSkyBlue",
  "ansiLightBlue",
  "ansi_light_blue",
  "dark_turquoise",
  "DarkTurquoise",
  "ansi_cyan",
  "ansiCyan",
  "SkyBlue",
  "sky_blue",
  "LightSkyBlue",
  "light_sky_blue",
  "LightSteelBlue",
  "light_steel_blue",
  "cyan",
  "LightBlue",
  "light_blue",
  "PowderBlue",
  "powder_blue",
  "PaleTurquoise",
  "pale_turquoise",
  "AliceBlue",
  "alice_blue",
  "LightCyan",
  "light_cyan",
  "azure",
  "ansiLightWhite",
  "ansi_light_white",
  "ghost_white",
  "GhostWhite",
  "lavender",
  "ansi_light_magenta",
  "ansiLightMagenta",
  "ansiMagenta",
  "ansi_magenta",
  "medium_purple",
  "MediumPurple",
  "light_slate_blue",
  "LightSlateBlue",
  "MediumSlateBlue",
  "medium_slate_blue",
  "royal_blue",
  "RoyalBlue",
  "SlateBlue",
  "slate_blue",
  "dark_slate_blue",
  "DarkSlateBlue",
  "midnight_blue",
  "MidnightBlue",
  "ansi_black",
  "ansiBlack",
  "blue",
  "medium_blue",
  "MediumBlue",
  "navy_blue",
  "NavyBlue",
  "navy",
  "DarkViolet",
  "dark_violet",
  "purple",
  "blue_violet",
  "BlueViolet",
  "magenta",
  "dark_orchid",
  "DarkOrchid",
  "MediumOrchid",
  "medium_orchid",
  "orchid",
  "violet",
  "plum",
  "thistle",
  "LavenderBlush",
  "lavender_blush",
  "pink",
  "LightPink",
  "light_pink",
  "hot_pink",
  "HotPink",
  "pale_violet_red",
  "PaleVioletRed",
  "deep_pink",
  "DeepPink",
  "maroon",
  "VioletRed",
  "violet_red",
  "medium_violet_red",
  "MediumVioletRed",
  "ansiRed",
  "ansi_red",
}

local function canonical_key(name)
  return tostring(name or ""):lower():gsub("_", "")
end

local function prefer_name(name)
  if type(name) ~= "string" then return 0 end
  if name:lower() == name and name:find("_") then return 3 end
  if name:lower() == name then return 2 end
  return 1
end

local function unique_palette()
  local seen = {}
  local list = {}
  for _, name in ipairs(palette) do
    local key = canonical_key(name)
    local existing = seen[key]
    if not existing then
      seen[key] = name
      list[#list + 1] = name
    elseif prefer_name(name) > prefer_name(existing) then
      for i, value in ipairs(list) do
        if value == existing then
          list[i] = name
          break
        end
      end
      seen[key] = name
    end
  end
  return list
end

local function contains_any(name, words)
  for _, word in ipairs(words) do
    if name:find(word, 1, true) then
      return true
    end
  end
  return false
end

local group_order = {
  { id = "reds", label = "Reds" },
  { id = "pinks", label = "Pinks" },
  { id = "oranges", label = "Oranges/Browns" },
  { id = "yellows", label = "Yellows/Golds" },
  { id = "greens", label = "Greens" },
  { id = "cyans", label = "Cyans/Teals" },
  { id = "blues", label = "Blues" },
  { id = "purples", label = "Purples/Violets" },
  { id = "neutrals", label = "Greys/Whites/Blacks" },
  { id = "other", label = "Other" },
}

local function group_for(name)
  local n = tostring(name or ""):lower()
  if contains_any(n, { "pink", "rose", "blush" }) then
    return "pinks"
  end
  if contains_any(n, { "red", "maroon", "firebrick", "crimson", "tomato", "coral", "salmon", "indian" }) then
    return "reds"
  end
  if contains_any(n, { "orange", "brown", "sienna", "peru", "chocolate", "saddle", "tan", "burlywood" }) then
    return "oranges"
  end
  if contains_any(n, { "yellow", "gold", "khaki", "lemon", "corn", "papaya", "goldenrod" }) then
    return "yellows"
  end
  if contains_any(n, { "green", "olive", "chartreuse", "lime", "spring", "sea_green", "mint" }) then
    return "greens"
  end
  if contains_any(n, { "cyan", "turquoise", "aqua", "aquamarine" }) then
    return "cyans"
  end
  if contains_any(n, { "blue", "navy", "slate", "steel", "dodger", "sky", "cornflower", "royal", "midnight" }) then
    return "blues"
  end
  if contains_any(n, { "purple", "violet", "magenta", "orchid", "plum", "thistle", "lavender" }) then
    return "purples"
  end
  if contains_any(n, { "black", "white", "grey", "gray", "silver", "gainsboro", "ivory", "linen", "snow", "beige", "transparent" }) then
    return "neutrals"
  end
  return "other"
end

local function grouped_palette()
  local groups = {}
  for _, entry in ipairs(group_order) do
    groups[entry.id] = { label = entry.label, colors = {} }
  end

  for _, name in ipairs(unique_palette()) do
    local id = group_for(name)
    groups[id].colors[#groups[id].colors + 1] = name
  end

  local result = {}
  for _, entry in ipairs(group_order) do
    local group = groups[entry.id]
    if group and #group.colors > 0 then
      table.sort(group.colors, function(a, b)
        return a:lower() < b:lower()
      end)
      result[#result + 1] = group
    end
  end
  return result
end

function agnosticdb.colors.list()
  return unique_palette()
end

function agnosticdb.colors.grouped()
  return grouped_palette()
end
