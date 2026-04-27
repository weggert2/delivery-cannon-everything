if delivery_cannon_everything_temp_localised_names then
  for _, item_ref in pairs(delivery_cannon_everything_temp_localised_names) do
    if data.raw[item_ref.type] and data.raw[item_ref.type][item_ref.name] then
      data.raw[item_ref.type][item_ref.name].localised_name = nil
    end
  end
end
