-- clean-code.lua

local SHOW_LITERAL_BASH_PROMPT = true

local HOME_PREFIXES = {
  [[c:\Users\USER]],
  [[C:\Users\USER]],
  [[/Users/joelkim]],
  [[/home/joelkim]],
  [[/Users/JoelKim]]
}

local HOME_REPLACEMENT = "~"

local function has_class(el, class)
  for _, c in ipairs(el.classes) do
    if c == class then
      return true
    end
  end
  return false
end

local function split_lines(text)
  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")

  local lines = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, line)
  end

  return lines
end

local function starts_with(text, prefix)
  return text:sub(1, #prefix) == prefix
end

local function transform_python(text)
  local lines = split_lines(text)
  local out = {}

  for _, line in ipairs(lines) do
    local indent, body = line:match("^(%s*)(.*)$")
    local keep = true

    -- !로 시작하는 Python/Jupyter shell command에서 ! 제거
    if starts_with(body, "!") then
      body = body:sub(2)

      if SHOW_LITERAL_BASH_PROMPT then
        body = "$ " .. body
      end
    end

    -- %% magic 처리
    if starts_with(body, "%%") then
      body = body:sub(3)

      -- %%writefile foo.py
      -- -> # foo.py
      if body:match("^writefile%s+") then
        body = body:gsub("^writefile%s+", "# ", 1)
      end

      -- %%capture 라인은 표시하지 않음
      if body:match("^capture%s*$") or body:match("^capture%s+") then
        keep = false
      end
    end

    if keep then
      table.insert(out, indent .. body)
    end
  end

  return table.concat(out, "\n")
end

local function transform_bash(text)
  local lines = split_lines(text)

  for i, line in ipairs(lines) do
    -- bash line 끝의 "|| true" 제거
    lines[i] = line:gsub("%s*%|%|%s*true%s*$", "")
  end

  return table.concat(lines, "\n")
end

 -- Lua pattern이 아니라 plain text 기준으로 모두 치환
local function replace_all_plain(text, target, replacement)
  local result = {}
  local start_pos = 1

  while true do
    local s, e = text:find(target, start_pos, true) -- true = plain search
    if not s then
      table.insert(result, text:sub(start_pos))
      break
    end

    table.insert(result, text:sub(start_pos, s - 1))
    table.insert(result, replacement)
    start_pos = e + 1
  end

  return table.concat(result)
end

local function replace_home_paths(line)
  for _, prefix in ipairs(HOME_PREFIXES) do
    line = replace_all_plain(line, prefix, HOME_REPLACEMENT)
  end

  return line
end

local function transform_output(text)
  local lines = split_lines(text)

  for i, line in ipairs(lines) do
    -- 출력 라인 중간에 경로가 있어도 모두 치환
    --
    -- 예:
    -- File "c:\Users\USER\project\main.py", line 10
    -- -> File "~\project\main.py", line 10
    --
    -- Error at /Users/joelkim/project/main.py
    -- -> Error at ~/project/main.py
    lines[i] = replace_home_paths(line)
  end

  return table.concat(lines, "\n")
end

function CodeBlock(el)
  -- 입력 코드 셀 처리
  if has_class(el, "python") then
    el.text = transform_python(el.text)
    return el
  end

  if has_class(el, "bash") or has_class(el, "sh") or has_class(el, "shell") then
    el.text = transform_bash(el.text)
    return el
  end

  return nil
end

function Div(el)
  -- 실행 결과 출력 블록 처리
  --
  -- 보통 Quarto 실행 결과는 다음과 같은 Div로 들어옵니다.
  -- ::: {.cell-output-stdout}
  -- ```
  -- ...
  -- ```
  -- :::
  if has_class(el, "cell-output")
    or has_class(el, "cell-output-stdout")
    or has_class(el, "cell-output-stderr") then

    for i, block in ipairs(el.content) do
      if block.t == "CodeBlock" then
        block.text = transform_output(block.text)
        el.content[i] = block
      end
    end

    return el
  end

  return nil
end
