local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*all")
  f:close()
  return content
end

local function is_svglite(svg)
  return svg:match('<g class=["\']svglite["\']') ~= nil
end

function Image(el)
  if not el.src:match("%.svg$") then
    return nil
  end

  if not quarto.doc.is_format("html") then
    return nil
  end

  local svg = read_file(el.src)
  if not svg then
    return nil
  end

  if not is_svglite(svg) then
    return nil
  end

  svg = svg:gsub("<%?xml[^?]*%?>%s*", "")

  return pandoc.RawInline("html", svg)
end
