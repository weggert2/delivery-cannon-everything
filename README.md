# Delivery Cannon Everything

A Factorio mod for Space Exploration that allows you to send **all non-fluid items** via Delivery Cannon, not just the basic materials.

## What it does

By default, Space Exploration only allows very basic items (ores, plates, basic materials) to be sent via Delivery Cannon. This mod removes that restriction and adds support for:

- **All items**: circuits, assembling machines, inserters, belts, etc.
- **All weapons and ammo**: via the Weapon Delivery Cannon
- **All capsules**: combat robots, construction robots, etc.
- **Equipment, modules, and tools**
- **Items from other mods** (automatically detected)

## How it works

The mod scans all item prototypes during the data-updates phase and adds them to Space Exploration's delivery cannon recipe tables. When Space Exploration processes these tables in data-final-fixes, it automatically creates:

- Capsule items for packing (e.g., `se-delivery-cannon-package-electronic-circuit`)
- Packing recipes in the delivery cannon assembler
- Artillery targeters for weapon delivery (for ammo and capsules)

## Compatibility

- **Requires**: Space Exploration 0.7.0 or higher
- **Factorio Version**: 2.0
- **Mod Compatibility**: Automatically detects and adds items from other mods

## Technical Details

### Load Order
1. Space Exploration's `data.lua` defines the initial delivery cannon tables
2. This mod's `data-updates.lua` adds all available items to those tables
3. Space Exploration's `data-final-fixes.lua` processes the tables and creates recipes

### Excluded Items
The following items are intentionally excluded to prevent issues:
- Delivery cannon items themselves (to avoid recursion)
- Blueprint and planning tools (selection tools, copy-paste tools, etc.)
- Fluids (delivery cannons only support items)

## Credits

Created using Space Exploration's extensible delivery cannon system.
