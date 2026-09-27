-- Append local English glosses to Chinese candidates without changing their text or order.

local M = {}
local glossary_path = "/glossary/glossary-en.tsv"

function M.init(env)
  env.glosses = {}

  local file = io.open(rime_api:get_user_data_dir() .. glossary_path, "r")
  if not file then
    return
  end

  for line in file:lines() do
    if line ~= "" and not line:match("^%s*#") then
      local word, glosses = line:match("^([^\t]+)\t(.+)$")
      if word and glosses and not env.glosses[word] then
        local parts = {}
        for gloss in glosses:gmatch("[^\t]+") do
          parts[#parts + 1] = gloss
        end
        if #parts > 0 then
          env.glosses[word] = table.concat(parts, " / ")
        end
      end
    end
  end

  file:close()
end

function M.func(input, env)
  local enabled = env.engine.context:get_option("translation_annotation")

  for cand in input:iter() do
    if enabled then
      local gloss = env.glosses[cand.text]
      if gloss then
        local genuine = cand:get_genuine()
        if genuine then
          local comment = genuine.comment or ""
          if not comment:find(gloss, 1, true) then
            genuine.comment = comment == "" and ("  " .. gloss) or (comment .. "  ·  " .. gloss)
          end
        end
      end
    end
    yield(cand)
  end
end

return M
