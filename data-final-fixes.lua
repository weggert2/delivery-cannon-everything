local function patch_delivery_cannon_circuit_connections()
  local base_assembler = data.raw["assembling-machine"] and
    data.raw["assembling-machine"]["assembling-machine-1"]

  if not base_assembler or not base_assembler.circuit_connector then
    return
  end

  for _, cannon_name in pairs({
    "se-delivery-cannon",
    "se-delivery-cannon-weapon"
  }) do
    local cannon = data.raw["assembling-machine"] and data.raw["assembling-machine"][cannon_name]
    if cannon then
      cannon.circuit_connector = table.deepcopy(base_assembler.circuit_connector)
      cannon.circuit_connector_flipped =
        table.deepcopy(base_assembler.circuit_connector_flipped or base_assembler.circuit_connector)
      cannon.circuit_wire_max_distance =
        cannon.circuit_wire_max_distance or base_assembler.circuit_wire_max_distance
    end
  end
end

patch_delivery_cannon_circuit_connections()

if delivery_cannon_everything_temp_localised_names then
  for _, item_ref in pairs(delivery_cannon_everything_temp_localised_names) do
    if data.raw[item_ref.type] and data.raw[item_ref.type][item_ref.name] then
      data.raw[item_ref.type][item_ref.name].localised_name = nil
    end
  end
end
