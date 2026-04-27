local translator_name = "dce-delivery-cannon-selector-combinator"
local hidden_output_name = "dce-delivery-cannon-selector-combinator-output"
local translator_tint = {r = 0.65, g = 0.95, b = 1.0, a = 0.85}
local blank_sprite = {
  filename = "__core__/graphics/empty.png",
  width = 1,
  height = 1,
  priority = "high"
}
local blank_sprite_4way = {
  north = blank_sprite,
  east = blank_sprite,
  south = blank_sprite,
  west = blank_sprite
}

local function tint_sprites(sprite_definition)
  if type(sprite_definition) ~= "table" then
    return
  end

  if sprite_definition.filename and not sprite_definition.draw_as_shadow then
    sprite_definition.tint = translator_tint
  end

  for _, child in pairs(sprite_definition) do
    if type(child) == "table" then
      tint_sprites(child)
    end
  end
end

local base_selector =
  data.raw["selector-combinator"] and data.raw["selector-combinator"]["selector-combinator"]
local base_decider =
  data.raw["decider-combinator"] and
  data.raw["decider-combinator"]["decider-combinator"]
local base_constant =
  data.raw["constant-combinator"] and data.raw["constant-combinator"]["constant-combinator"]
local base_item = data.raw.item and data.raw.item["selector-combinator"]
local base_recipe = data.raw.recipe and data.raw.recipe["selector-combinator"]

if not base_selector or not base_decider or not base_constant or
   not base_item or not base_recipe then
  return
end

local translator_entity = table.deepcopy(base_decider)
translator_entity.name = translator_name
translator_entity.minable = {
  mining_time = 0.1,
  result = translator_name
}
translator_entity.rotatable = true
translator_entity.fast_replaceable_group = translator_name
translator_entity.corpse = "selector-combinator-remnants"
translator_entity.dying_explosion = "selector-combinator-explosion"
translator_entity.icons = {
  {
    icon = "__base__/graphics/icons/selector-combinator.png",
    icon_size = 64
  },
  {
    icon = "__space-exploration-graphics__/graphics/icons/delivery-cannon-capsule.png",
    icon_size = 64,
    scale = 0.45,
    shift = {9, 9},
    tint = {r = 0.6, g = 1.0, b = 1.0, a = 0.9}
  }
}
translator_entity.localised_name = {"", "Delivery Cannon Selector Combinator"}
translator_entity.localised_description = {
  "",
  "Transforms item signals into matching delivery cannon recipe signals.\n",
  "Wire item inputs to the bottom and recipe outputs from the top."
}
translator_entity.order = "z[dce-delivery-cannon-selector-combinator]"
translator_entity.sprites = table.deepcopy(base_selector.sprites)
translator_entity.activity_led_sprites = table.deepcopy(base_selector.activity_led_sprites)
translator_entity.frozen_patch = table.deepcopy(base_selector.frozen_patch)
translator_entity.activity_led_light_offsets =
  table.deepcopy(base_selector.activity_led_light_offsets)
translator_entity.screen_light_offsets =
  table.deepcopy(base_selector.screen_light_offsets)
tint_sprites(translator_entity.sprites)
tint_sprites(translator_entity.activity_led_sprites)
tint_sprites(translator_entity.frozen_patch)
translator_entity.activity_led_light = {
  intensity = 0,
  size = 1,
  color = {r = 0.6, g = 1.0, b = 1.0}
}
translator_entity.screen_light = {
  intensity = 0,
  size = 0.6,
  color = {r = 0.6, g = 1.0, b = 1.0}
}
translator_entity.equal_symbol_sprites = blank_sprite_4way
translator_entity.greater_symbol_sprites = blank_sprite_4way
translator_entity.less_symbol_sprites = blank_sprite_4way
translator_entity.not_equal_symbol_sprites = blank_sprite_4way
translator_entity.greater_or_equal_symbol_sprites = blank_sprite_4way
translator_entity.less_or_equal_symbol_sprites = blank_sprite_4way

local translator_item = table.deepcopy(base_item)
translator_item.name = translator_name
translator_item.place_result = translator_name
translator_item.icons = table.deepcopy(translator_entity.icons)
translator_item.order = "c[combinators]-cz[dce-delivery-cannon-selector-combinator]"
translator_item.localised_name = translator_entity.localised_name
translator_item.localised_description = translator_entity.localised_description

local translator_recipe = table.deepcopy(base_recipe)
translator_recipe.name = translator_name
translator_recipe.icons = table.deepcopy(translator_entity.icons)
translator_recipe.results = {
  {type = "item", name = translator_name, amount = 1}
}
translator_recipe.ingredients = {
  {type = "item", name = "selector-combinator", amount = 1},
  {type = "item", name = "advanced-circuit", amount = 2},
  {type = "item", name = "se-delivery-cannon-capsule", amount = 1}
}
translator_recipe.localised_name = translator_entity.localised_name
translator_recipe.order = translator_item.order

local hidden_output = table.deepcopy(base_constant)
hidden_output.name = hidden_output_name
hidden_output.flags = {
  "not-on-map",
  "placeable-off-grid",
  "not-blueprintable",
  "not-deconstructable",
  "not-upgradable"
}
hidden_output.hidden = true
hidden_output.selectable_in_game = false
hidden_output.minable = nil
hidden_output.allow_copy_paste = false
hidden_output.collision_box = {{0, 0}, {0, 0}}
hidden_output.selection_box = {{0, 0}, {0, 0}}
hidden_output.collision_mask = {layers = {}}
hidden_output.max_health = 1
hidden_output.sprites = blank_sprite
hidden_output.activity_led_sprites = blank_sprite
hidden_output.activity_led_light = {
  intensity = 0,
  size = 0,
  color = {r = 0, g = 0, b = 0}
}
hidden_output.circuit_wire_connection_points =
  table.deepcopy(base_selector.output_connection_points)
hidden_output.circuit_wire_max_distance = base_selector.circuit_wire_max_distance
hidden_output.draw_circuit_wires = false
hidden_output.draw_copper_wires = false
hidden_output.localised_name = {"", "Delivery Cannon Selector Output"}

data:extend({
  translator_entity,
  translator_item,
  translator_recipe,
  hidden_output
})

local delivery_cannon_technology =
  data.raw.technology and data.raw.technology["se-delivery-cannon"]
if delivery_cannon_technology then
  delivery_cannon_technology.effects = delivery_cannon_technology.effects or {}
  table.insert(delivery_cannon_technology.effects, {
    type = "unlock-recipe",
    recipe = translator_name
  })
end
