local M = {}

local config = {
  root_folder = "~/notes",
  template = "~/notes/template.md"
}

local function open_daily(offset)

  -- Get target date
  local target_date = os.time() + (offset * 24 * 60 * 60)
  local year = os.date("%Y",target_date)
  local month = os.date("%m",target_date)
  local day = os.date ("%d",target_date)
  local date_string = string.format("%s-%s-%s",year,month,day)


  -- Create directory if it doesn't exist
  local dir = vim.fn.expand(string.format("%s/%s/%s", config.root_folder, year, month))
  vim.fn.mkdir(dir, "p")

  -- Create file path
  local file = string.format("%s/%s.md", dir, date_string)

  -- Check if file exists, if not, copy template
  -- local f = io.open(file, "r")
  local template_path = vim.fn.expand(config.template)
  if vim.fn.filereadable(file) == 0 and vim.fn.template_path then
    vim.fn.system(string.format("cp %s %s", template_path, file))
    vim.cmd(string.format("edit %s", file))
    vim.cmd(":%s/<DAILY_CURRENT_DATE>/" .. date_string .."/g") 
    vim.cmd(":w")
  else
    vim.cmd(string.format("edit %s", file))
  end
end

function M.setup(opts)
  -- Merge user options with default config
  config = vim.tbl_deep_extend("force", config, opts or {})

  vim.api.nvim_create_user_command("Daily", function(args)
    if (tonumber(args.args) ~= nil) then
      open_daily(tonumber(args.args))
    elseif (args.args ~= nil and args.args ~= "") then
      -- TODO: integration with telescope (find in daily)
      print("TODO arg is a tring")
    elseif (args.args == "" or args.args == nil) then
      open_daily(0)        -- open today
    end
  end, { nargs = "?" })
end

return M
