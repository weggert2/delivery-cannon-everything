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

## How it works

The mod scans all item prototypes during the data-updates phase and adds them to Space Exploration's delivery cannon recipe tables. When Space Exploration processes these tables in data-final-fixes, it automatically creates:

- Capsule items for packing (e.g., `se-delivery-cannon-package-electronic-circuit`)
- Packing recipes in the delivery cannon assembler

Delivery Cannon capsules themselves are handled through a proxy item. You convert a Delivery Cannon capsule into a normal proxy item, ship that proxy through the cannon, then convert it back into a Delivery Cannon capsule at the destination.

## Delivery Cannon Capsule Proxy

Space Exploration's delivery cannon runtime expects a packed payload to contain one non-capsule item. Because of that, a Delivery Cannon capsule cannot be shipped directly as its own payload.

This mod solves that by adding a proxy item:

- Convert `se-delivery-cannon-capsule` into the proxy item
- Ship the proxy item through the normal Delivery Cannon workflow
- Convert the proxy item back into `se-delivery-cannon-capsule` at the destination

This keeps the behavior compatible with Space Exploration while still letting Delivery Cannon capsules be transported between surfaces.

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
