local user_dir = assert(arg[1], "pass the Rime user directory")
rime_api = { get_user_data_dir = function() return user_dir end }

local filter = dofile(user_dir .. "/lua/translation_annotation.lua")
local env = {
  engine = { context = { get_option = function() return true end } },
}

local started = os.clock()
filter.init(env)
assert(env.glosses["开发"] == "v. develop / v. exploit")
assert(env.glosses["数据库"] == "n. database")
print(string.format("loaded glossary in %.2fs; Lua memory %.1f MiB", os.clock() - started,
  collectgarbage("count") / 1024))

local function candidate(word, comment)
  local genuine = { comment = comment }
  return { text = word, get_genuine = function() return genuine end }, genuine
end

local function run(candidates)
  local output = {}
  yield = function(cand) output[#output + 1] = cand end
  local index = 0
  filter.func({ iter = function()
    return function()
      index = index + 1
      return candidates[index]
    end
  end }, env)
  assert(#output == #candidates)
  for index, cand in ipairs(candidates) do
    assert(output[index] == cand)
  end
end

local known, known_genuine = candidate("开发", "原注释")
local unknown, unknown_genuine = candidate("不存在的候选", "保留")
run({ known, unknown })
assert(known.text == "开发")
assert(known_genuine.comment == "原注释  ·  v. develop / v. exploit")
assert(unknown_genuine.comment == "保留")

run({ known })
assert(known_genuine.comment == "原注释  ·  v. develop / v. exploit")

env.engine.context.get_option = function() return false end
local disabled, disabled_genuine = candidate("数据库", "")
run({ disabled })
assert(disabled_genuine.comment == "")

env.engine.context.get_option = function() return true end
run({ disabled })
assert(disabled_genuine.comment == "  n. database")
print("translation annotation behavior passed")
