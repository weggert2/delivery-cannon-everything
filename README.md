# Delivery Cannon Everything

A Factorio mod for Space Exploration that allows you to send **all non-fluid items** via Delivery Cannon, not just the basic materials.

## What it does

By default, Space Exploration only allows very basic items (ores, plates, basic materials) to be sent via Delivery Cannon. This mod removes that restriction and adds support for:

- **All items**: circuits, assembling machines, inserters, belts, etc.
- **Ammo, weapons, and capsules**: through the normal cargo Delivery Cannon workflow
- **All capsules**: combat robots, construction robots, etc.
- **Delivery Cannon capsules**: via a proxy item that can be converted before and after shipping
- **Equipment, modules, and tools**
- **Items from other mods** (automatically detected)
- **Circuit-controlled Delivery Cannons**: including recipe selection by signal

## How it works

The mod scans all item prototypes during the data-updates phase and adds them to Space Exploration's delivery cannon recipe tables. When Space Exploration processes these tables in data-final-fixes, it automatically creates:

- Capsule items for packing (e.g., `se-delivery-cannon-package-electronic-circuit`)
- Packing recipes in the delivery cannon assembler

Delivery Cannon capsules themselves are handled through a proxy item. You convert a Delivery Cannon capsule into a normal proxy item, ship that proxy through the cannon, then convert it back into a Delivery Cannon capsule at the destination.

This mod also patches Space Exploration's Delivery Cannons to behave more like Factorio 2.0 assemblers on the circuit network. They can be connected to red/green wire and set to a delivery cannon recipe by signal.

## Delivery Cannon Capsule Proxy

Space Exploration's delivery cannon runtime expects a packed payload to contain one non-capsule item. Because of that, a Delivery Cannon capsule cannot be shipped directly as its own payload.

This mod solves that by adding a proxy item:

- Convert `se-delivery-cannon-capsule` into the proxy item
- Ship the proxy item through the normal Delivery Cannon workflow
- Convert the proxy item back into `se-delivery-cannon-capsule` at the destination

This keeps the behavior compatible with Space Exploration while still letting Delivery Cannon capsules be transported between surfaces.

## Circuit Network Control

This mod enables circuit network connections on Space Exploration's Delivery Cannons and exposes delivery cannon pack recipes to Factorio 2.0's recipe control UI.

That means you can:

- Wire a Delivery Cannon to the circuit network
- Enable recipe control on the cannon
- Send it a packed delivery-cannon item signal such as `se-delivery-cannon-package-electronic-circuit`
- Let the cannon switch payload recipes automatically

### Delivery Cannon Selector Combinator

To make recipe control practical, the mod adds a new combinator:

- **Name**: `Delivery Cannon Selector Combinator`
- **Unlock**: `se-delivery-cannon`
- **Purpose**: converts normal item signals into the matching packed delivery-cannon item signals

Example:

- Input `electronic-circuit = 1`
- Output `item: se-delivery-cannon-package-electronic-circuit = 1`

Wire item demand into the bottom/input side of the combinator, then wire the top/output side to a Delivery Cannon configured for recipe control.

Notes:

- If multiple supported item signals are present, the combinator will output all matching delivery cannon package item signals with the same counts.
- The output signal on the network is correct and can be seen on connected poles and used by Delivery Cannons.
- Factorio's hover tooltip for the combinator itself may still only show the input side instead of the translated output side.

## Compatibility

- **Requires**: Space Exploration 0.7.0 or higher
- **Factorio Version**: 2.0
- **Mod Compatibility**: Automatically detects and adds items from other mods

## Technical Details

### Load Order
1. Space Exploration's `data.lua` defines the initial delivery cannon tables
2. This mod's `data-updates.lua` adds all available items to those tables
3. Space Exploration's `data-final-fixes.lua` processes the tables and creates recipes
4. Delivery Cannon capsules use a proxy item so they follow Space Exploration's normal payload logic

### Excluded Items
The following items are intentionally excluded to prevent issues:
- Delivery cannon items themselves
- Blueprint and planning tools (selection tools, copy-paste tools, etc.)
- Fluids (delivery cannons only support items)

## Credits

Created in about 30 minutes using Claude. No human brains were utilized in making this work.
