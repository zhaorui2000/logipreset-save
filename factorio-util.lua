local util = {
  version = "1.0.0"
}

local config = require("config")
local ENV = config.ENV
-- factorio log info block
function util.debug(msg)
  if ENV ~= "debug" then
    return
  end
  log(serpent.block(msg))
  if game then
    game.print(serpent.block(msg))
  end
end

return util
