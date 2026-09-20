# JobClothing — FiveM Resource

A production-ready job clothing system for **QBCore** and **QBox** supporting ped placement, per-job/grade uniforms, live preview, and automatic detection of your clothing/target resources.

---

## Features

- **Auto Framework Detection**: Works with `qbx_core` and `qb-core` automatically
- **Ped Placement System**: Interactive ped placement with WASD controls
- **Per Job/Grade Uniforms**: Multiple uniforms per job per grade
- **Clothing Only**: NEVER changes face, hair, skin, tattoos — only clothing/props
- **Live Preview**: Admin can preview uniforms before saving
- **Target Support**: `ox_target`, `qb-target`, or proximity fallback
- **Storage**: `oxmysql` or JSON file fallback
- **Clothing Adapters**: `illenium-appearance`, `fivem-appearance`, `qb-clothing`
- **Grade Inheritance**: Configurable strict vs inherited grade access
- **Server-Side Security**: All permission/job/grade checks done server-side

---

## Dependencies

**Required (one of):**
- `qb-core` OR `qbx_core`

**Recommended (auto-detected):**
- `oxmysql` — for persistent database storage
- `ox_target` OR `qb-target` — for ped interaction
- `illenium-appearance` OR `fivem-appearance` OR `qb-clothing` — for uniform creation

**If none of the clothing resources are detected:** The NUI will show an error when trying to create uniforms, but applying already-saved uniforms (via native GTA calls) will still work.

---

## Installation

### 1. Database Setup (if using oxmysql)

Run the SQL file against your database:

```sql
-- File: sql/install.sql
```

### 2. Add to server.cfg

```cfg
ensure jobclothing
```

**Recommended order:**
```cfg
ensure oxmysql
ensure qb-core
# or ensure qbx_core
ensure ox_target
ensure illenium-appearance
ensure jobclothing
```

### 3. Build the NUI

```bash
cd resources/[standalone]/jobclothing/web
npm install
npm run build
```

The built files will be placed in `web/dist/`.

### 4. Grant Admin Permissions

**Via ACE (recommended):**
```cfg
add_ace group.admin jobclothing.admin allow
```

**Via config.lua groups:**
```lua
Config.AdminGroups = {
    ["god"]   = true,
    ["admin"] = true,
}
```

---

## Configuration

Edit `config.lua`:

```lua
Config = {}

Config.Command      = "jobclothing"    -- Command to open admin menu
Config.Framework    = "auto"           -- "auto" | "qbcore" | "qbox"
Config.Target       = "auto"           -- "auto" | "ox_target" | "qb-target" | "none"
Config.Clothing     = "auto"           -- "auto" | "illenium-appearance" | "fivem-appearance" | "qb-clothing"
Config.Storage      = "auto"           -- "auto" | "oxmysql" | "json"

Config.AdminGroups = {
    ["god"]   = true,
    ["admin"] = true,
}

Config.UseAcePermission = true
Config.AcePermission    = "jobclothing.admin"

-- false: player only sees uniforms for their EXACT grade
-- true:  player sees uniforms for their grade AND all lower grades
Config.GradeInheritance = false

Config.Ped = {
    invincible  = true,
    frozen      = true,
    blockEvents = true,
    scenario    = nil,    -- Optional: "WORLD_HUMAN_STAND_MOBILE" etc.
}

Config.InteractionDistance = 2.0
Config.InteractionKey      = 38        -- E key

Config.Debug = false
```

---

## Usage

### Admin

1. Run `/jobclothing` to open the admin panel
2. **Create a Clothing Ped**: Enter model name (e.g. `s_m_y_cop_01`) and click "Place Ped"
3. **Position the ped** using keyboard controls:
   - `W/S` — forward/back
   - `A/D` — left/right
   - `Shift/Z` — up/down
   - `Q/E` — rotate
   - `Enter` — confirm
   - `Backspace` — cancel
4. **Select a ped** from the list and click "Add Uniform"
5. **Select job + grade**, give it a name, open the clothing editor
6. **Save the uniform**

### Players

1. Walk up to a clothing ped
2. Press `E` or use target interaction
3. Select a uniform from the list
4. The clothing will be applied — your face/hair/skin/tattoos are preserved

---

## Debugging

Enable debug mode in `config.lua`:

```lua
Config.Debug = true
```

Check server console for:
```
[JobClothing] Framework: QBox
[JobClothing] Target: ox_target
[JobClothing] Clothing: illenium-appearance
[JobClothing] Storage: oxmysql
```

**Common issues:**

| Problem | Solution |
|---------|----------|
| No uniforms shown | Check player job/grade matches stored uniforms. Enable `Config.GradeInheritance = true` to test |
| Clothing editor not opening | Verify your clothing resource is started before jobclothing |
| Peds not spawning after restart | Check oxmysql connection or verify `data/peds.json` exists |
| Permission denied | Add ACE permission: `add_ace group.admin jobclothing.admin allow` |

---

## Resource Structure

```
jobclothing/
├── fxmanifest.lua
├── config.lua
├── shared/
│   ├── constants.lua          — Component/prop index mappings
│   └── utils.lua              — Shared utilities
├── client/
│   ├── main.lua               — NUI callbacks, event handlers
│   ├── ped_manager.lua        — Spawn/track clothing peds
│   ├── interaction.lua        — Target system detection
│   ├── placement.lua          — Interactive ped placement
│   └── clothing/
│       ├── adapter.lua        — Auto-detect clothing system
│       ├── illenium.lua       — Illenium-Appearance adapter
│       ├── fivem-appearance.lua
│       └── qb-clothing.lua
├── server/
│   ├── main.lua               — Command, events, security
│   ├── permissions.lua        — ACE + framework permission checks
│   ├── peds.lua               — Ped CRUD + storage
│   ├── uniforms.lua           — Uniform CRUD + storage
│   └── framework/
│       ├── adapter.lua        — Framework auto-detector
│       ├── qbcore.lua         — QBCore adapter
│       └── qbox.lua           — QBox adapter
├── web/
│   ├── src/                   — React source (NUI)
│   └── dist/                  — Built NUI (gitignore src/ if desired)
├── sql/
│   └── install.sql
└── README.md
```

---

## Security Model

| What | Where validated |
|------|----------------|
| Admin permission | Server (`/jobclothing` command, all admin events) |
| Job/grade access | Server (fetched from framework, never trusted from client) |
| Ped existence | Server (before any uniform operation) |
| Uniform ownership | Server (uniform's ped_id checked) |
| Grade match | Server (full re-check on `applyUniform`) |

---

## Extending — Adding a New Clothing System

1. Create `client/clothing/mysystem.lua`
2. Implement the adapter interface:

```lua
MyAdapter = {}

function MyAdapter.getCurrentClothing()
    -- return { components = {...}, props = {...} }
end

function MyAdapter.openClothingEditor(callback)
    -- open your UI, then call callback(outfitData)
end

function MyAdapter.applyClothing(clothingData)
    -- apply only components/props in clothingData
end

function MyAdapter.getSupportedComponents()
    -- return { components = {...}, props = {...} }
end
```

3. Add detection in `client/clothing/adapter.lua`:

```lua
elseif GetResourceState('my-clothing-resource') == 'started' then
    _activeAdapter = MyAdapter
    _clothingName  = "my-clothing-resource"
```

4. Add the new file to `fxmanifest.lua` before `adapter.lua`.

---

## License

MIT — free to use and modify.
