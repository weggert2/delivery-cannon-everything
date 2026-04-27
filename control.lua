local translator_name = "dce-delivery-cannon-selector-combinator"
local hidden_output_name = "dce-delivery-cannon-selector-combinator-output"
local normal_pack_prefix = "se-delivery-cannon-pack-"
local weapon_pack_prefix = "se-delivery-cannon-weapon-pack-"
local runtime_revision = 12
local update_interval = 15
local debug_log_interval = 300
local max_filters_per_section = 100

local input_connector_ids = {
  defines.wire_connector_id.combinator_input_red,
  defines.wire_connector_id.combinator_input_green
}

local build_recipe_map
local rebuild_translators

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

build_recipe_map = function()
  local recipe_map = {}

  for recipe_name, recipe in pairs(prototypes.recipe) do
    if string.find(recipe_name, normal_pack_prefix, 1, true) == 1 then
      local payload_name = string.sub(recipe_name, #normal_pack_prefix + 1)
      local ingredient_name = nil
      local package_name = recipe.products and recipe.products[1] and recipe.products[1].name or nil

      for _, ingredient in pairs(recipe.ingredients) do
        if ingredient.type == "item" and ingredient.name ~= "se-delivery-cannon-capsule" then
          if ingredient_name then
            ingredient_name = nil
            break
          end

          ingredient_name = ingredient.name
        end
      end

      recipe_map[ingredient_name or payload_name] = {
        recipe = recipe_name,
        package = package_name
      }
    end
  end

  for recipe_name, recipe in pairs(prototypes.recipe) do
    if string.find(recipe_name, weapon_pack_prefix, 1, true) == 1 then
      local item_name = string.sub(recipe_name, #weapon_pack_prefix + 1)
      recipe_map[item_name] = recipe_map[item_name] or {
        recipe = recipe_name,
        package = recipe.products and recipe.products[1] and recipe.products[1].name or nil
      }
    end
  end

  storage.delivery_cannon_recipe_map = recipe_map
end

local function neutralize_visible_behavior(entity)
  entity.operable = false

  local behavior = entity.get_control_behavior()
  if behavior and behavior.type == defines.control_behavior.type.decider_combinator then
    behavior.parameters = nil
  end
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

local function get_backend_connectors(backend)
  return {
    [defines.wire_type.red] = backend.get_wire_connector(defines.wire_connector_id.circuit_red, true),
    [defines.wire_type.green] = backend.get_wire_connector(defines.wire_connector_id.circuit_green, true)
  }
end

local function connect_backend_to_shell_targets(entity, backend)
  local backend_connectors = get_backend_connectors(backend)

  for _, shell_connector in pairs(entity.get_wire_connectors(true)) do
    if shell_connector and shell_connector.valid then
      for _, connection in ipairs(shell_connector.real_connections) do
        local target = connection.target
        if target and target.valid then
          local owner = target.owner
          if owner and owner.valid and owner ~= backend then
            local backend_connector = backend_connectors[target.wire_type]
            if backend_connector and not backend_connector.is_connected_to(target, defines.wire_origin.player) then
              backend_connector.connect_to(target, false, defines.wire_origin.player)
            end
          end
        end
      end
    end
  end
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
    backend = entity.surface.create_entity{
      name = hidden_output_name,
      position = entity.position,
      force = entity.force,
      create_build_effect_smoke = false
    }
  end

  if not backend or not backend.valid then
    return nil
  end

  backend.destructible = false
  backend.minable_flag = false
  backend.operable = false

  if backend.position.x ~= entity.position.x or backend.position.y ~= entity.position.y then
    backend.teleport(entity.position)
  end

  connect_backend_to_shell_targets(entity, backend)
  return backend
end

local function describe_connectors(entity)
  local parts = {}

  for connector_id, connector in pairs(entity.get_wire_connectors(true)) do
    local network_id = connector and connector.valid and connector.network_id or 0
    local real_count = connector and connector.valid and connector.real_connection_count or 0
    parts[#parts + 1] = tostring(connector_id) .. ":" .. tostring(network_id) .. ":" .. tostring(real_count)
  end

  table.sort(parts)
  return table.concat(parts, "|")
end

local function describe_real_connection_targets(entity)
  local parts = {}

  for connector_id, connector in pairs(entity.get_wire_connectors(true)) do
    if connector and connector.valid then
      for _, connection in ipairs(connector.real_connections) do
        local target = connection.target
        local owner = target and target.owner
        if owner and owner.valid then
          local unit = owner.unit_number or 0
          parts[#parts + 1] = tostring(connector_id) .. "->" .. owner.name .. "#" .. tostring(unit) .. ":" .. tostring(target.wire_connector_id)
        end
      end
    end
  end

  table.sort(parts)
  return table.concat(parts, "|")
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
    last_outputs_key = ""
  }
end

rebuild_translators = function()
  storage.translators = {}

  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = translator_name}) do
      register_translator(entity)
    end
  end
end

local function make_signal_key(signal_type, signal_name)
  return signal_type .. ":" .. signal_name
end

local function add_output_signal(outputs, signal_type, signal_name, count)
  if not signal_name or count == 0 then
    return
  end

  local key = make_signal_key(signal_type, signal_name)
  local output = outputs[key]

  if output then
    output.count = output.count + count
    return
  end

  outputs[key] = {
    signal = {
      type = signal_type,
      name = signal_name
    },
    count = count
  }
end

local function get_translated_outputs(entity)
  local outputs = {}

  for _, connector_id in ipairs(input_connector_ids) do
    local network = entity.get_circuit_network(connector_id)
    if network and network.signals then
      for _, signal in ipairs(network.signals) do
        local signal_id = signal.signal
        if (signal_id.type == nil or signal_id.type == "item") and signal_id.name then
          local mapped = storage.delivery_cannon_recipe_map[signal_id.name]
          if mapped then
            add_output_signal(outputs, "recipe", mapped.recipe, signal.count)
            add_output_signal(outputs, "item", mapped.package, signal.count)
          end
        end
      end
    end
  end

  return outputs
end

local function outputs_to_key(outputs)
  local parts = {}

  for output_key, output in pairs(outputs) do
    if output.count ~= 0 then
      parts[#parts + 1] = output_key .. "=" .. tostring(output.count)
    end
  end

  table.sort(parts)
  return table.concat(parts, "|")
end

local function clear_backend_sections(control)
  for index = control.sections_count, 1, -1 do
    control.remove_section(index)
  end
end

local function write_backend_outputs(backend, outputs)
  local control = backend.get_or_create_control_behavior()
  if not control or control.type ~= defines.control_behavior.type.constant_combinator then
    return false, {"missing constant combinator control behavior"}
  end

  local output_keys = {}
  for output_key, output in pairs(outputs) do
    if output.count ~= 0 then
      output_keys[#output_keys + 1] = output_key
    end
  end

  table.sort(output_keys)
  clear_backend_sections(control)

  if #output_keys == 0 then
    control.enabled = false
    return true, {}
  end

  local errors = {}
  local output_index = 1
  while output_index <= #output_keys do
    local section = control.add_section()
    if not section then
      errors[#errors + 1] = "failed to add constant combinator section"
      break
    end

    for slot = 1, max_filters_per_section do
      if output_index > #output_keys then
        break
      end

      local output = outputs[output_keys[output_index]]
      local success, err = pcall(function()
        local value = {
          type = output.signal.type,
          name = output.signal.name
        }

        if output.signal.type == "recipe" then
          value.quality = "normal"
        elseif output.signal.type == "item" then
          value.quality = "normal"
          value.comparator = "="
        end

        section.set_slot(slot, {
          value = value,
          min = output.count
        })
      end)

      if not success then
        errors[#errors + 1] = tostring(err)
      end

      output_index = output_index + 1
    end
  end

  control.enabled = true
  return #errors == 0, errors
end

local function update_translator(unit_number, record, tick)
  local entity = record.entity
  if not entity.valid then
    if record.backend and record.backend.valid then
      record.backend.destroy()
    end
    storage.translators[unit_number] = nil
    return
  end

  if (tick + unit_number) % update_interval ~= 0 then
    return
  end

  neutralize_visible_behavior(entity)

  local backend = record.backend
  if not backend or not backend.valid then
    backend = ensure_backend(entity)
    record.backend = backend
  else
    connect_backend_to_shell_targets(entity, backend)
  end

  if not backend or not backend.valid then
    return
  end

  local outputs = get_translated_outputs(entity)
  local outputs_key = outputs_to_key(outputs)
  local previous_outputs_key = record.last_outputs_key
  local write_ok = true
  local write_errors = {}

  if outputs_key ~= previous_outputs_key then
    write_ok, write_errors = write_backend_outputs(backend, outputs)
    record.last_outputs_key = outputs_key
  end

  if outputs_key ~= previous_outputs_key or tick % debug_log_interval == 0 or not write_ok or #write_errors > 0 then
    log("DCE selector unit=" .. unit_number ..
      " outputs=" .. outputs_key ..
      " shell_connectors=" .. describe_connectors(entity) ..
      " shell_targets=" .. describe_real_connection_targets(entity) ..
      " backend_connectors=" .. describe_connectors(backend) ..
      " backend_targets=" .. describe_real_connection_targets(backend))
    for _, err in ipairs(write_errors) do
      log("DCE selector backend-error unit=" .. unit_number .. " " .. err)
    end
  end
end

local function on_built(event)
  register_translator(event.entity or event.created_entity or event.destination)
end

local function on_removed(event)
  local entity = event.entity
  if not entity or entity.name ~= translator_name then
    return
  end

  if entity.unit_number then
    storage.translators[entity.unit_number] = nil
  end

  destroy_hidden_outputs(entity)
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

script.on_event(defines.events.on_tick, function(event)
  ensure_runtime_state()

  for unit_number, record in pairs(storage.translators) do
    update_translator(unit_number, record, event.tick)
  end
end)
