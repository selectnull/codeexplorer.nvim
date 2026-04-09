--- definitions

---@class codeexplorer.Position
---@field row integer
---@field col integer

---@class codeexplorer.Symbol
---@field name string
---@field kind string
---@field position codeexplorer.Position
---@field depth integer

---@class codeexplorer.SymbolEntry
---@field symbol codeexplorer.Symbol
---@field index integer
---@field has_children boolean
---@field expanded boolean
