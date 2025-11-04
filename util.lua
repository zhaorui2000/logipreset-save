--- 工具函数库
-- @module util
local util = {
  version = "1.1.0"
}

-- 表操作相关函数

--------------------------------------------------------------------------------
-- 递归打印表的内容，用于调试和查看表结构
-- @param t table 要打印的表
-- @param indent number 缩进级别，用于格式化输出，默认为2
--------------------------------------------------------------------------------
function util.printTable(t, indent)
  indent = indent or 2
  for k, v in pairs(t) do
    local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
    if type(v) == "table" then
      print(formatting)
      util.printTable(v, indent + 1)
    else
      print(formatting .. tostring(v))
    end
  end
end

--------------------------------------------------------------------------------
-- 合并两个表，第二个表的键值会覆盖第一个表中的相同键
-- @param t1 table 第一个表
-- @param t2 table 第二个表，其键值将覆盖第一个表中的相同键
-- @return table 返回合并后的新表
--------------------------------------------------------------------------------
function util.mergeTables(t1, t2)
  local result = {}
  -- 复制第一个表的所有字段
  for k, v in pairs(t1) do
    result[k] = v
  end
  -- 覆盖/添加第二个表的字段
  for k, v in pairs(t2) do
    result[k] = v
  end
  return result
end

--------------------------------------------------------------------------------
-- 根据权重随机选择指定数量的物品
-- @param items table 物品表，key为物品名称，value为权重，默认为1
-- @param count number 要选择的物品数量
-- @return table 返回选中的物品表，格式与输入相同
--------------------------------------------------------------------------------
function util.randomChoiceWeighted(items, count)
  local DEFAULT_WEIGHT = 1
  if not items or count <= 0 then
    return {}
  end

  -- 转换为带随机键的列表
  local items_list = {}
  for name, weight in pairs(items) do
    table.insert(items_list, {
      name = name,
      key = -math.log(math.random()) / (weight or DEFAULT_WEIGHT)
    })
  end

  local n = #items_list
  if count >= n then
    return items
  end

  -- 按键值升序排序（小键值优先）
  table.sort(items_list, function(a, b)
    return a.key < b.key
  end)

  -- 构建结果表
  local result = {}
  for i = 1, count do
    result[items_list[i].name] = items[items_list[i].name]
  end

  return result
end

--------------------------------------------------------------------------------
-- 扩展当前 util 表，将其他 util 方法加入到自己
-- @param otherUtil table 要合并的其他 util 表
-- @return table 返回扩展后的 util 表
--------------------------------------------------------------------------------
function util.extend(otherUtil)
  if not otherUtil or type(otherUtil) ~= "table" then
    return util
  end

  -- 遍历 otherUtil 表，将其所有方法添加到当前 util 表中
  for k, v in pairs(otherUtil) do
    -- 跳过 version 字段，避免覆盖当前 util 的版本信息
    if k ~= "version" then
      util[k] = v
    end
  end

  return util
end

--------------------------------------------------------------------------------
-- 在表中查找元素
-- @param t table 表
-- @param value any 要查找的值
-- @return any|nil 返回找到的键名，如果没找到返回nil
--------------------------------------------------------------------------------
function util.findInTable(t, value)
  for k, v in pairs(t) do
    if v == value then
      return k
    end
  end
  return nil
end

--------------------------------------------------------------------------------
-- 获取表的长度（包含嵌套表）
-- @param t table 表
-- @return number 返回表的元素总数
--------------------------------------------------------------------------------
function util.count(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

--------------------------------------------------------------------------------
-- 获取表中的所有键
-- @param t table 表
-- @return table 返回键的数组
--------------------------------------------------------------------------------
function util.keys(t)
  local keys = {}
  for k in pairs(t) do
    table.insert(keys, k)
  end
  return keys
end

--------------------------------------------------------------------------------
-- 获取表中的所有值
-- @param t table 表
-- @return table 返回值的数组
--------------------------------------------------------------------------------
function util.values(t)
  local values = {}
  for _, v in pairs(t) do
    table.insert(values, v)
  end
  return values
end

-- 类型检查工具

--------------------------------------------------------------------------------
-- 检查值是否为nil或空
-- @param value any 要检查的值
-- @return boolean 返回布尔值
--------------------------------------------------------------------------------
function util.isEmpty(value)
  if value == nil then
    return true
  elseif type(value) == "string" then
    return value == ""
  elseif type(value) == "table" then
    return next(value) == nil
  end
  return false
end

--------------------------------------------------------------------------------
-- 检查值是否为数字
-- @param value any 要检查的值
-- @return boolean 返回布尔值
--------------------------------------------------------------------------------
function util.isNumber(value)
  return type(value) == "number" and not (value ~= value) -- 排除NaN
end

--------------------------------------------------------------------------------
-- 检查值是否为字符串
-- @param value any 要检查的值
-- @return boolean 返回布尔值
--------------------------------------------------------------------------------
function util.isString(value)
  return type(value) == "string"
end

--------------------------------------------------------------------------------
-- 检查值是否为表
-- @param value any 要检查的值
-- @return boolean 返回布尔值
--------------------------------------------------------------------------------
function util.isTable(value)
  return type(value) == "table"
end

--------------------------------------------------------------------------------
-- 检查值是否为函数
-- @param value any 要检查的值
-- @return boolean 返回布尔值
--------------------------------------------------------------------------------
function util.isFunction(value)
  return type(value) == "function"
end

-- 事件系统

--- 简单的事件系统
local events = {}

--------------------------------------------------------------------------------
-- 发射事件
-- @param eventName string 事件名
-- @param data any 事件数据
--------------------------------------------------------------------------------
function util.emit(eventName, data)
  if not events[eventName] then
    return
  end

  for _, callback in ipairs(events[eventName]) do
    if callback then
      callback(data)
    end
  end
end

--------------------------------------------------------------------------------
-- 监听事件
-- @param eventName string 事件名
-- @param callback function 回调函数
-- @return function 返回取消监听的函数
--------------------------------------------------------------------------------
function util.on(eventName, callback)
  if not events[eventName] then
    events[eventName] = {}
  end

  table.insert(events[eventName], callback)

  -- 返回取消监听的函数
  return function()
    for i, cb in ipairs(events[eventName]) do
      if cb == callback then
        table.remove(events[eventName], i)
        break
      end
    end
  end
end

--------------------------------------------------------------------------------
-- 移除事件监听
-- @param eventName string 事件名
-- @param callback function 要移除的回调函数
--------------------------------------------------------------------------------
function util.off(eventName, callback)
  if not events[eventName] then
    return
  end

  for i, cb in ipairs(events[eventName]) do
    if cb == callback then
      table.remove(events[eventName], i)
      break
    end
  end
end

return util
