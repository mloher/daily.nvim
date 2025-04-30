local M = {}

local config = {
  root_folder = "~/notes",
  template = "~/notes/template.md",
  titled_notes_subfolder = "titled"
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
  if vim.fn.filereadable(file) == 0 and vim.fn.filereadable(template_path) ~= 0 then
    print("in if")
    vim.fn.system(string.format("cp %s %s", template_path, file))
    vim.cmd(string.format("edit %s", file))
    vim.cmd(":silent! %s/<DAILY_CURRENT_DATE>/" .. date_string .."/g") 
    vim.cmd(":w")
  else
    vim.cmd(string.format("edit %s", file))
  end
end

local function grep_for()
  if(require('telescope.builtin')) then
    local builtin = require('telescope.builtin')
    builtin.live_grep({
      search_dirs = {config.root_folder},
      default_text = "";
    })
  end
end

local function search_tags()
  local output = vim.fn.systemlist({
    "rg", "-o", "--no-filename","--pcre2", "#\\w+", vim.fn.expand(config.root_folder)
  })

  -- Remove duplicates
  local seen = {}
  local tags = {}
  for _, tag in ipairs(output) do
    if not seen[tag] then
      seen[tag] = true
      table.insert(tags, tag)
    end
  end

  -- Open Telescope picker
  require('telescope.pickers').new({}, {
    prompt_title = "Pick a Hashtag",
    finder = require('telescope.finders').new_table {
      results = tags
    },
    sorter = require('telescope.config').values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')

      map('i', '<CR>', function()
        local selected = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        -- After picking, search for that hashtag
        require('telescope.builtin').live_grep({
          search_dirs = { config.root_folder },
          default_text = selected[1],
          prompt_title = "Search results for " .. selected[1],
          -- additional_args = function()
          --  return { "--pcre2", "-e", "#\\w+" }
          -- end,
        })
      end)

      return true
    end,
  }):find()
end

local function open_titled(name)

  -- Create directory if it doesn't exist
  local dir = vim.fn.expand(string.format("%s/%s", config.root_folder, config.titled_notes_subfolder))
  vim.fn.mkdir(dir, "p")

  -- Create file path
  local file = string.format("%s/%s.md", dir, name)
  vim.cmd(string.format("edit %s", file))
end




function M.setup(opts)
  -- Merge user options with default config
  config = vim.tbl_deep_extend("force", config, opts or {})

  vim.api.nvim_create_user_command("Daily", function(args)
    if (tonumber(args.args) ~= nil) then
      open_daily(tonumber(args.args))
    elseif (args.args ~= nil and args.args ~= "") then
      -- TODO: integration with telescope (find in daily)
      grep_for(args.args)
    elseif (args.args == "" or args.args == nil) then
      open_daily(0)        -- open today
    end
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("DailyGrep", function(args)
    grep_for()
  end, {nargs = 0} )

  vim.api.nvim_create_user_command("DailyTags", function(args)
    search_tags()
  end, {nargs = 0} )

  vim.api.nvim_create_user_command("DailyTitled", function(args)
    open_titled(args.args)
  end, {nargs = 1} )

end

return M
