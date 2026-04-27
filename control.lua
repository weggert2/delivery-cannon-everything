local translator_name = "dce-delivery-cannon-selector-combinator"
local hidden_output_name = "dce-delivery-cannon-selector-combinator-output"
local normal_pack_prefix = "se-delivery-cannon-pack-"
local weapon_pack_prefix = "se-delivery-cannon-weapon-pack-"
local max_filters_per_section = 100
local max_signal_count = 2147483647
local runtime_revision = 3

local input_connector_ids = {
  defines.wire_connector_id.combinator_input_red,
  defines.wire_connector_id.combinator_input_green
}

local function ensure_storage()
  storage.translators = storage.translators or {}
  storage.delivery_cannon_recipe_map = storage.delivery_cannon_recipe_map or {}
end

local function ensure_runtime_state()
  ensure_storage()

  if storage.runtime_revision ~= runtime_revision then
    build_recipe_map()
    rebuild_translators()
    storage.runtime_revision = runtime_revision
    return
  end

  if not next(storage.delivery_cannon_recipe_map) then
    build_recipe_map()
  end
end

local function clamp_count(count)
  if count > max_signal_count then
    return max_signal_count
  end

  if count < -max_signal_count then
    return -max_signal_count
  end

  return count
end

local function build_recipe_map()
  local recipe_map = {}

  for recipe_name, recipe in pairs(prototypes.recipe) do
    if string.find(recipe_name, normal_pack_prefix, 1, true) == 1 then
      local payload_name = string.sub(recipe_name, #normal_pack_prefix + 1)
      local ingredient_name = nil

      for _, ingredient in pairs(recipe.ingredients) do
        if ingredient.type == "item" and ingredient.name ~= "se-delivery-cannon-capsule" then
          if ingredient_name then
            ingredient_name = nil
            break
          end

          ingredient_name = ingredient.name
        end
      end

      recipe_map[ingredient_name or payload_name] = recipe_name
    end
  end

  for recipe_name in pairs(prototypes.recipe) do
    if string.find(recipe_name, weapon_pack_prefix, 1, true) == 1 then
      local item_name = string.sub(recipe_name, #weapon_pack_prefix + 1)
      recipe_map[item_name] = recipe_map[item_name] or recipe_name
    end
  end

  storage.delivery_cannon_recipe_map = recipe_map
end

local function get_hidden_outputs(entity)
  return entity.surface.find_entities_filtered{
    name = hidden_output_name,
    position = entity.position,
    force = entity.force
  }
end

local function destroy_hidden_outputs(entity)
  for _, hidden_output in ipairs(get_hidden_outputs(entity)) do
    if hidden_output.valid then
      hidden_output.destroy()
    end
  end
end

local function neutralize_visible_behavior(entity)
  entity.operable = false

  local behavior = entity.get_control_behavior()
  if not behavior then
    return
  end

  if behavior.type == defines.control_behavior.type.decider_combinator then
    behavior.parameters = nil
  end
end

local function fallback_connect_backend(entity, backend)
  local backend_red = backend.get_wire_connector(defines.wire_connector_id.circuit_red, true)
  local backend_green = backend.get_wire_connector(defines.wire_connector_id.circuit_green, true)
  local visible_red = entity.get_wire_connector(defines.wire_connector_id.combinator_output_red, true)
  local visible_green = entity.get_wire_connector(defines.wire_connector_id.combinator_output_green, true)

  if backend_red then
    backend_red.disconnect_all(defines.wire_origin.script)
    backend_red.disconnect_all(defines.wire_origin.player)
  end

  if backend_green then
    backend_green.disconnect_all(defines.wire_origin.script)
    backend_green.disconnect_all(defines.wire_origin.player)
  end

  if backend_red and visible_red and
     not backend_red.is_connected_to(visible_red, defines.wire_origin.player) then
    backend_red.connect_to(visible_red, false, defines.wire_origin.player)
  end

  if backend_green and visible_green and
     not backend_green.is_connected_to(visible_green, defines.wire_origin.player) then
    backend_green.connect_to(visible_green, false, defines.wire_origin.player)
  end
end

local function connect_backend(entity, backend)
  backend.direction = entity.direction

  if backend.position.x ~= entity.position.x or backend.position.y ~= entity.position.y then
    backend.teleport(entity.position)
  end

  fallback_connect_backend(entity, backend)
end

local function create_backend(entity)
  local backend = entity.surface.create_entity{
    name = hidden_output_name,
    position = entity.position,
    force = entity.force,
    direction = entity.direction,
    create_build_effect_smoke = false
  }

  if not backend then
    return nil
  end

  backend.destructible = false
  backend.minable_flag = false
  backend.operable = false
  connect_backend(entity, backend)
  return backend
end

local function ensure_backend(entity)
  local hidden_outputs = get_hidden_outputs(entity)
  local backend = hidden_outputs[1]

  for index = 2, #hidden_outputs do
    if hidden_outputs[index].valid then
      hidden_outputs[index].destroy()
    end
  end

  if not backend or not backend.valid then
    backend = create_backend(entity)
  else
    backend.destructible = false
    backend.minable_flag = false
    backend.operable = false
    connect_backend(entity, backend)
  end

  return backend
end

local function register_translator(entity)
  if not entity or not entity.valid or entity.name ~= translator_name or not entity.unit_number then
    return
  end

  neutralize_visible_behavior(entity)

  local backend = ensure_backend(entity)
  if not backend then
    return
  end

  storage.translators[entity.unit_number] = {
    entity = entity,
    backend = backend,
    last_outputs = {}
  }
end

local function rebuild_translators()
  storage.translators = {}

  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = translator_name}) do
      register_translator(entity)
    end
  end
end

local function get_input_outputs(entity)
  local outputs = {}

  for _, connector_id in ipairs(input_connector_ids) do
    local network = entity.get_circuit_network(connector_id)
    if network and network.signals then
      for _, signal in ipairs(network.signals) do
        local signal_id = signal.signal
        if (signal_id.type == nil or signal_id.type == "item") and signal_id.name then
          local recipe_name = storage.delivery_cannon_recipe_map[signal_id.name]
          if recipe_name then
            outputs[recipe_name] = (outputs[recipe_name] or 0) + signal.count
          end
        end
      end
    end
  end

  return outputs
end

local function outputs_match(previous_outputs, next_outputs)
  for recipe_name, count in pairs(previous_outputs) do
    if next_outputs[recipe_name] ~= count then
      return false
    end
  end

  for recipe_name, count in pairs(next_outputs) do
    if previous_outputs[recipe_name] ~= count then
      return false
    end
  end

  return true
end

local function clear_backend_sections(control)
  for index = control.sections_count, 1, -1 do
    control.remove_section(index)
  end
end

local function apply_outputs(backend, outputs)
  local control = backend.get_or_create_control_behavior()
  if not control or control.type ~= defines.control_behavior.type.constant_combinator then
    return
  end

  local recipe_names = {}
  for recipe_name, count in pairs(outputs) do
    if count ~= 0 then
      recipe_names[#recipe_names + 1] = recipe_name
    end
  end

  table.sort(recipe_names)
  clear_backend_sections(control)

  if #recipe_names == 0 then
    control.enabled = false
    return
  end

  local recipe_index = 1
  while recipe_index <= #recipe_names do
    local section = control.add_section()
    if not section then
      break
    end

    for slot = 1, max_filters_per_section do
      if recipe_index > #recipe_names then
        break
      end

      local recipe_name = recipe_names[recipe_index]
      section.set_slot(slot, {
        value = {
          type = "recipe",
          name = recipe_name,
          quality = "normal"
        },
        min = clamp_count(outputs[recipe_name])
      })
      recipe_index = recipe_index + 1
    end
  end

  control.enabled = true
end

local function unregister_translator(entity)
  if not entity or not entity.valid or entity.name ~= translator_name then
    return
  end

  if entity.unit_number then
    storage.translators[entity.unit_number] = nil
  end
  destroy_hidden_outputs(entity)
end

local function update_translator(unit_number, record)
  local entity = record.entity
  if not entity.valid then
    if record.backend and record.backend.valid then
      record.backend.destroy()
    end
    storage.translators[unit_number] = nil
    return
  end

  neutralize_visible_behavior(entity)

  local backend = record.backend
  if not backend or not backend.valid then
    backend = ensure_backend(entity)
    record.backend = backend
  else
    connect_backend(entity, backend)
  end

  if not backend or not backend.valid then
    return
  end

  local outputs = get_input_outputs(entity)
  if outputs_match(record.last_outputs, outputs) then
    return
  end

  apply_outputs(backend, outputs)
  record.last_outputs = outputs
end

local function on_built(event)
  register_translator(event.entity or event.created_entity or event.destination)
end

local function on_removed(event)
  unregister_translator(event.entity)
end

local function on_rotated(event)
  if event.entity and event.entity.valid and event.entity.name == translator_name then
    register_translator(event.entity)
  end
end

local function initialize_runtime()
  ensure_storage()
  build_recipe_map()
  rebuild_translators()
  storage.runtime_revision = runtime_revision
end

script.on_init(initialize_runtime)
script.on_configuration_changed(initialize_runtime)

script.on_event({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.on_space_platform_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive
}, function(event)
  ensure_runtime_state()
  on_built(event)
end)

script.on_event({
  defines.events.on_player_mined_entity,
  defines.events.on_robot_mined_entity,
  defines.events.on_space_platform_mined_entity,
  defines.events.on_entity_died,
  defines.events.script_raised_destroy
}, function(event)
  ensure_runtime_state()
  on_removed(event)
end)

script.on_event(defines.events.on_player_rotated_entity, function(event)
  ensure_runtime_state()
  on_rotated(event)
end)

script.on_event(defines.events.on_tick, function()
  ensure_runtime_state()

  for unit_number, record in pairs(storage.translators) do
    update_translator(unit_number, record)
  end
end)
