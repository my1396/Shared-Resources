-- This filter ensures colored equations are properly formatted for LaTeX/PDF output by converting \color{#...} to \color[HTML]{...}.
function Math(el)
  -- Check if the output format is PDF or LaTeX
  if FORMAT:match("latex") or FORMAT:match("pdf") then
    -- Find \color{#...} and replace it with \color[HTML]{...}
    el.text = el.text:gsub("\\color{#(%w+)}", "\\color[HTML]{%1}")
    return el
  end
end