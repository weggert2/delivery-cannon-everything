-- Space Exploration hardcodes normal delivery cannon pack recipes to:
--   1x se-delivery-cannon-capsule + payload amount x item
-- For se-delivery-cannon-capsule itself that creates duplicate ingredients,
-- so rewrite the generated pack recipe to use only 2 capsules.
local delivery_cannon_capsule = "se-delivery-cannon-capsule"
local pack_recipe_name = "se-delivery-cannon-pack-" .. delivery_cannon_capsule

local pack_recipe = data.raw.recipe and data.raw.recipe[pack_recipe_name]

if pack_recipe then
  pack_recipe.ingredients = {
    {type = "item", name = delivery_cannon_capsule, amount = 2}
  }
end
