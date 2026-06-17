# DudaPlus

DudaPlus is a FiveM vehicle marketplace resource built for QBCore. It generates rotating vehicle listings, shows them in a NUI storefront, and stores purchased vehicles with condition and rarity metadata.

## Features

- Rotating market stock with refresh intervals defined in `config.lua`.
- Rarity-based tabs and pricing.
- Vehicle condition data including mileage, wear, damage summary, and damage list.
- Vehicle rarity upgrades for owned vehicles.
- Purchase flow that checks garage capacity before completing the sale.
- NUI frontend with market grid, vehicle detail card, and category filters.

## Requirements

- FiveM server
- QBCore
- `oxmysql`
- A vehicle garage system that uses `player_vehicles` and `bp_garages` (can be renamed to whatever you have) tables, or equivalent schema compatible with the server logic

## Installation

1. Place the resource in your server resources folder.
2. Ensure the required dependencies start before this resource:

```cfg
ensure qb-core
ensure oxmysql
ensure dudaplus
```

3. Add the resource to your server configuration.
4. Make sure the database tables used by the script exist and match your garage system.

## Usage

- Open the market with `F7` or the `/market` command.

## Configuration

Main settings live in `config.lua` and `config_condition.lua`.

### `config.lua`

- `Config.RefreshInterval` controls how often the market regenerates listings.
- `Config.MoneyAccount` selects the payment account used for purchases.
- `Config.ListingsPerRarity` defines how many vehicles are generated per rarity tier.
- `Config.SpawnPoints` defines where purchased vehicles can spawn.
- `Config.ListingLocations` controls the location labels shown in the UI.
- `Config.Vehicles` is the vehicle pool used to generate market listings.

### `config_condition.lua`

- `Config.RarityMultipliers` defines payout multipliers by rarity.
- `Config.RarityUpgrade.costs` controls rarity upgrade prices.
- `Config.Rarity` defines wear and mileage behavior for each rarity tier.
- `Config.ConditionLabels` maps wear values to human-readable condition labels.
- `Config.DamageTypes` defines the condition effects and labels shown in the UI.

## Resource Flow

1. The server generates random listings from `Config.Vehicles`.
2. The client opens the UI and requests the current listings.
3. The player inspects a listing, then purchases it if they qualify.
4. The server saves the vehicle into `player_vehicles` with condition data.
5. The client applies saved handling state when the vehicle is spawned.

## Notes

- The server logic references `player_vehicles` and `bp_garages` directly, so you may need small schema or query adjustments if your server uses different table names.
