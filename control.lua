--------------------------------------------------------------------------------
-- 物流预设保存模组 - 控制脚本
-- 负责处理玩家物流配置的保存和加载功能
--------------------------------------------------------------------------------

-- 导入依赖模块
local factorio_util = require "factorio-util"
local util = require "util"
util.extend(factorio_util)

--------------------------------------------------------------------------------
-- 功能函数定义
--------------------------------------------------------------------------------

-- 判断玩家是否开启了物流功能
local function hasLogisticsEnabled(player)
  return player.force.character_logistic_requests
end

-- 获取玩家的物流组配置并序列化为文本
local function get_player_logistic_presets_text(player)
  -- 检查物流功能是否开启
  if not hasLogisticsEnabled(player) then
    return nil
  end

  -- 获取玩家的请求点
  local requester_point = player.get_requester_point()
  if not requester_point then
    return nil
  end
  local logistic_presets = {}

  -- 遍历所有物流组
  for _, section in pairs(requester_point.sections) do
    logistic_presets[section.group] = logistic_presets[section.group] or {}

    -- 遍历组内的所有过滤器槽位
    for i = 1, section.filters_count do
      local slot = section.get_slot(i)
      logistic_presets[section.group][i] = slot
      if slot.import_from then
        logistic_presets[section.group][i]["import_from"] = slot.import_from.name
      end
    end
  end
  util.debug(logistic_presets)

  -- 序列化配置数据并返回文本
  return helpers.encode_string(serpent.dump(logistic_presets))
end

-- 从文本加载物流配置到玩家
local function set_player_logistic_presets(player, presets_text)
  -- 检查物流功能是否开启
  if not hasLogisticsEnabled(player) then
    game.print({ "", { "error.no-tech" } })
    return
  end

  -- 获取玩家的请求点
  local requester_point = player.get_requester_point()
  if not requester_point then
    return
  end

  -- 解码配置文本
  presets_text = helpers.decode_string(presets_text)
  if presets_text == nil then
    game.print({ "", { "error.corrupted" } })
    return
  end

  -- 反序列化配置数据
  local ok, presets = serpent.load(presets_text)
  if not ok then
    game.print({ "", { "error.corrupted" } })
    return
  end

  util.debug(presets)

  -- 应用配置到玩家的物流组
  for group, filters in pairs(presets) do
    local section = requester_point.add_section(group)
    for i, filter in ipairs(filters) do
      section.set_slot(i, filter)
    end
  end
end

--------------------------------------------------------------------------------
-- 事件处理函数
--------------------------------------------------------------------------------

-- GUI打开事件处理：创建或更新物流配置界面
script.on_event(defines.events.on_gui_opened, function(event)
  local player = game.get_player(event.player_index)

  -- 检查物流功能是否开启
  if not hasLogisticsEnabled(player) then
    return
  end

  -- 如果界面已存在，更新文本内容
  if player.gui.relative.logistic_presets_flow then
    player.gui.relative.logistic_presets_flow.logistic_presets_textfield.text = get_player_logistic_presets_text(player) or
        ""
    return
  end

  -- 创建新的物流配置界面
  local parent = player.gui.relative.add({
    type = "flow",
    name = "logistic_presets_flow",
    anchor = { gui = defines.relative_gui_type.controller_gui, position = defines.relative_gui_position.top },
  })

  -- 添加配置文本输入框
  parent.add({
    type = "textfield",
    name = "logistic_presets_textfield",
    text = get_player_logistic_presets_text(player)
  })

  -- 添加加载配置按钮
  parent.add({
    type = "button",
    name = "load_logistic_presets",
    caption = { "gui.load-btn" },
  })
end)

-- GUI点击事件处理：加载物流配置
script.on_event(defines.events.on_gui_click, function(event)
  -- 检查是否为加载按钮点击事件
  if event.element.name == "load_logistic_presets" then
    local player = game.get_player(event.player_index)

    -- 从文本框中获取配置文本并加载
    set_player_logistic_presets(player, event.element.parent.logistic_presets_textfield.text)
  end
end)
