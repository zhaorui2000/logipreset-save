local util = {
  version = "1.0.0"
}

--------------------------------------------------------------------------------
-- 递归打印表的内容，用于调试和查看表结构
-- @param t: 要打印的表
-- @param indent: 缩进级别，用于格式化输出，默认为2
--------------------------------------------------------------------------------
function util.printTable(t, indent)
  indent = indent or 2
  for k, v in pairs(t) do
    local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
    if type(v) == "table" then
      print(formatting)
      printTable(v, indent + 1)
    else
      print(formatting .. tostring(v))
    end
  end
end

--------------------------------------------------------------------------------
-- 合并两个表，第二个表的键值会覆盖第一个表中的相同键
-- @param t1: 第一个表
-- @param t2: 第二个表，其键值将覆盖第一个表中的相同键
-- @return: 返回合并后的新表
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
-- @param items: 物品表，key为物品名称，value为权重，默认为1
-- @param count: 要选择的物品数量
-- @return: 返回选中的物品表，格式与输入相同
--------------------------------------------------------------------------------
function util.random_choice_weighted(items, count)
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
-- @param otherUtil: 要合并的其他 util 表
-- @return: 返回扩展后的 util 表
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

return util
