-- data-updates.lua
-- This runs AFTER all mods' data.lua but BEFORE Space Exploration's data-final-fixes.lua
-- which is where SE processes the delivery cannon recipe tables

-- Initialize the tables if they don't exist (they should exist from SE's data.lua)
se_delivery_cannon_recipes = se_delivery_cannon_recipes or {}
se_delivery_cannon_ammo_recipes = se_delivery_cannon_ammo_recipes or {}

local delivery_cannon_capsule = "se-delivery-cannon-capsule"
local delivery_cannon_capsule_proxy = "dce-delivery-capsule-proxy"
local delivery_cannon_capsule_proxy_tint = {r = 0.4, g = 1.0, b = 1.0, a = 0.65}

local delivery_cannon_capsule_proto = data.raw.item and data.raw.item[delivery_cannon_capsule]

if delivery_cannon_capsule_proto and not data.raw.item[delivery_cannon_capsule_proxy] then
  local proxy_icons
  if delivery_cannon_capsule_proto.icons then
    proxy_icons = table.deepcopy(delivery_cannon_capsule_proto.icons)
  elseif delivery_cannon_capsule_proto.icon then
    proxy_icons = {{
      icon = delivery_cannon_capsule_proto.icon,
      icon_size = delivery_cannon_capsule_proto.icon_size,
      icon_mipmaps = delivery_cannon_capsule_proto.icon_mipmaps
    }}
  end

  if proxy_icons then
    for _, icon_data in pairs(proxy_icons) do
      icon_data.tint = delivery_cannon_capsule_proxy_tint
    end
  end

  data:extend({
    {
      type = "item",
      name = delivery_cannon_capsule_proxy,
      localised_name = {"", delivery_cannon_capsule_proto.localised_name or {"item-name." .. delivery_cannon_capsule}, " Proxy"},
      localised_description = {"item-description." .. delivery_cannon_capsule},
      icons = proxy_icons,
      icon = delivery_cannon_capsule_proto.icon,
      icon_size = delivery_cannon_capsule_proto.icon_size,
      icon_mipmaps = delivery_cannon_capsule_proto.icon_mipmaps,
      subgroup = delivery_cannon_capsule_proto.subgroup,
      order = (delivery_cannon_capsule_proto.order or delivery_cannon_capsule) .. "-proxy",
      stack_size = delivery_cannon_capsule_proto.stack_size or 50
    },
    {
      type = "recipe",
      name = "dce-delivery-capsule-proxy-from-capsule",
      localised_name = {"", "Convert ", delivery_cannon_capsule_proto.localised_name or {"item-name." .. delivery_cannon_capsule}, " to Proxy"},
      enabled = true,
      energy_required = 1,
      ingredients = {
        {type = "item", name = delivery_cannon_capsule, amount = 1}
      },
      results = {
        {type = "item", name = delivery_cannon_capsule_proxy, amount = 1}
      }
    },
    {
      type = "recipe",
      name = "dce-delivery-capsule-from-proxy",
      localised_name = {"", "Convert Proxy to ", delivery_cannon_capsule_proto.localised_name or {"item-name." .. delivery_cannon_capsule}},
      enabled = true,
      energy_required = 1,
      ingredients = {
        {type = "item", name = delivery_cannon_capsule_proxy, amount = 1}
      },
      results = {
        {type = "item", name = delivery_cannon_capsule, amount = 1}
      }
    }
  })
end

-- Iterate through all item types and add them to the delivery cannon recipes
local item_types = {
  "item",
  "ammo",
  "capsule",
  "gun",
  "item-with-entity-data",
  "item-with-label",
  "item-with-inventory",
  "item-with-tags",
  "selection-tool",
  "blueprint-book",
  "upgrade-item",
  "deconstruction-item",
  "blueprint",
  "copy-paste-tool",
  "spidertron-remote",
  "rail-planner",
  "tool",
  "armor",
  "repair-tool",
  "module"
}

-- Count items for logging
local added_count = 0
local ammo_count = 0

-- Helper function to check if an item has a valid craftable recipe (not just recycling)
local function has_valid_recipe(item_name)
  for recipe_name, recipe in pairs(data.raw.recipe) do
    if recipe.results then
      for _, result in pairs(recipe.results) do
        local result_name = result.name or result[1]
        if result_name == item_name then
          -- Check if this recipe uses the recycling category (which doesn't exist in SE)
          if recipe.category ~= "recycling" then
            return true
          end
        end
      end
    end
  end
  return false
end

-- Add all items to se_delivery_cannon_recipes
for _, item_type in pairs(item_types) do
  if data.raw[item_type] then
    for item_name, item_proto in pairs(data.raw[item_type]) do
      -- Skip items that are already in the list
      if not se_delivery_cannon_recipes[item_name] then
        -- Skip some special items that shouldn't be delivery-cannoned
        local skip = false

        -- Skip delivery cannon items themselves to avoid recursion
        if string.find(item_name, "delivery-cannon", 1, true) then
          skip = true
        end

        -- Skip blueprint/planning tools
        if item_type == "blueprint" or item_type == "blueprint-book" or
           item_type == "deconstruction-item" or item_type == "upgrade-item" or
           item_type == "selection-tool" or item_type == "copy-paste-tool" then
          skip = true
        end

        -- Skip items that only have recycling recipes (not craftable)
        if not skip and not has_valid_recipe(item_name) then
          skip = true
        end

        if not skip then
          se_delivery_cannon_recipes[item_name] = {
            name = item_name,
            type = item_type
          }
          added_count = added_count + 1
        end
      end
    end
  end
end

-- Add ammo and capsules to se_delivery_cannon_ammo_recipes for weapon delivery cannon
-- Only add items that have valid craftable recipes (not just recycling)
-- Check ammo items
if data.raw["ammo"] then
  for item_name, item_proto in pairs(data.raw["ammo"]) do
    if not se_delivery_cannon_ammo_recipes[item_name] then
      -- Skip delivery cannon weapon capsules
      if not string.find(item_name, "delivery-cannon-weapon", 1, true) then
        -- Only add if there's a non-recycling recipe for this item
        if has_valid_recipe(item_name) then
          se_delivery_cannon_ammo_recipes[item_name] = {
            type = "ammo",
            name = item_name,
            map_color = {r=1.0, g=0.5, b=0}
          }
          ammo_count = ammo_count + 1
        end
      end
    end
  end
end

-- Check capsule items
if data.raw["capsule"] then
  for item_name, item_proto in pairs(data.raw["capsule"]) do
    if not se_delivery_cannon_ammo_recipes[item_name] then
      -- Skip delivery cannon targeter items
      if not string.find(item_name, "delivery-cannon-artillery-targeter", 1, true) then
        -- Only add if there's a non-recycling recipe for this item
        if has_valid_recipe(item_name) then
          se_delivery_cannon_ammo_recipes[item_name] = {
            type = "capsule",
            name = item_name,
            map_color = {r=0.5, g=0.5, b=1.0}
          }
          ammo_count = ammo_count + 1
        end
      end
    end
  end
end

log("Delivery Cannon Everything: Added " .. added_count .. " items to se_delivery_cannon_recipes")
log("Delivery Cannon Everything: Added " .. ammo_count .. " items to se_delivery_cannon_ammo_recipes")
