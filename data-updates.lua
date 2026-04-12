-- data-updates.lua
-- This runs AFTER all mods' data.lua but BEFORE Space Exploration's data-final-fixes.lua
-- which is where SE processes the delivery cannon recipe tables

-- Initialize the tables if they don't exist (they should exist from SE's data.lua)
se_delivery_cannon_recipes = se_delivery_cannon_recipes or {}
se_delivery_cannon_ammo_recipes = se_delivery_cannon_ammo_recipes or {}

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

-- Add all items to se_delivery_cannon_recipes
for _, item_type in pairs(item_types) do
  if data.raw[item_type] then
    for item_name, item_proto in pairs(data.raw[item_type]) do
      -- Skip items that are already in the list
      if not se_delivery_cannon_recipes[item_name] then
        -- Skip some special items that shouldn't be delivery-cannoned
        local skip = false

        -- Skip delivery cannon items themselves to avoid recursion
        if string.find(item_name, "delivery%-cannon", 1, true) then
          skip = true
        end

        -- Skip blueprint/planning tools
        if item_type == "blueprint" or item_type == "blueprint-book" or
           item_type == "deconstruction-item" or item_type == "upgrade-item" or
           item_type == "selection-tool" or item_type == "copy-paste-tool" then
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
-- Check ammo items
if data.raw["ammo"] then
  for item_name, item_proto in pairs(data.raw["ammo"]) do
    if not se_delivery_cannon_ammo_recipes[item_name] then
      -- Skip delivery cannon weapon capsules
      if not string.find(item_name, "delivery%-cannon%-weapon", 1, true) then
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

-- Check capsule items
if data.raw["capsule"] then
  for item_name, item_proto in pairs(data.raw["capsule"]) do
    if not se_delivery_cannon_ammo_recipes[item_name] then
      -- Skip delivery cannon targeter items
      if not string.find(item_name, "delivery%-cannon%-artillery%-targeter", 1, true) then
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

log("Delivery Cannon Everything: Added " .. added_count .. " items to se_delivery_cannon_recipes")
log("Delivery Cannon Everything: Added " .. ammo_count .. " items to se_delivery_cannon_ammo_recipes")
