local Utils = require("ide.utils")
local Dialog = require("ide.ui.dialogs.dialog")
local Components = require("ide.ui.components")

local private = Utils.private_stash()
local TabsDialog = Utils.class(Dialog)

function TabsDialog:init(pages, title, options)
    options = options or { }
    options.resetmodel = false
    Dialog.init(self, title, options)

    private[self] = {
        finishlabel = vim.F.if_nil(options.finishlabel, "Finish"),
        prevlabel = vim.F.if_nil(options.prevlabel, "Previous"),
        nextlabel = vim.F.if_nil(options.nextlabel, "Next"),
        wizard = vim.F.if_nil(options.wizard, false),
        pages = vim.F.if_nil(pages, { }),
        page = 0,
        components = { },
    }

    self:map("z", function() self:prev() end, {builtin = true})
    self:map("m", function() self:next() end, {builtin = true})
    self:update()
end

function TabsDialog:prev()
    self:set_page(private[self].page - 1)
end

function TabsDialog:next()
    self:set_page(private[self].page + 1)
end

function TabsDialog:set_page(page)
    if page < 0 then
        page = 0
    elseif page >= #private[self].pages then
        page = #private[self].pages - 1
    end

    private[self].page = page
    self:update()
end

function TabsDialog:update()
    local w = 0

    if not vim.tbl_isempty(private[self].pages) then
        w = self.width / #private[self].pages
    end

    local c = { }

    -- Header Part
    if w > 0 then
        local col, header = 0, { }

        for i, page in ipairs(private[self].pages) do
            table.insert(header, Components.Button(page, {
                col = col,
                width = w,
                flat = true,
                foreground = i - 1 == private[self].page and "selected" or nil,
                background = i - 1 == private[self].page and "selected" or nil,
                align = "center",

                event = function()
                    if not private[self].wizard then
                        self:set_page(i - 1)
                    end
                end
            }))

            col = col + w
        end

        c = vim.list_extend(c, {header, {}})
    end

    -- Wizard Body
    local components = self:get_page_components(private[self].page)

    if components then
        if vim.is_callable(components) then
            components = components(self, private[self].page)

            if type(components) == "table" and not vim.tbl_islist(components) and not vim.tbl_isempty(components) then
                components = {components}
            end
        end

        if vim.tbl_islist(components) then
            for _, cc in ipairs(components) do
                self:get_model():set_component(cc)
                table.insert(c, cc)
            end
        end
    end

    -- Footer Part
    if w > 0 then
        local footer = {}

        if private[self].wizard then
            local lastpage = private[self].page + 1 >= #private[self].pages

            footer = {
                Components.Button(lastpage and private[self].finishlabel or private[self].nextlabel, {
                    key = lastpage and "A" or nil,
                    col = -2,
                    background = lastpage and "accent" or nil,

                    event = function()
                        if lastpage then
                            self:on_finish()
                        else
                            self:next()
                        end
                    end
                })
            }

            if private[self].page > 0 then
                table.insert(footer, 1, Components.Button(private[self].prevlabel, {
                    col = 1,
                    event = function()
                        self:prev()
                    end
                }))
            end
        else
            footer = {
                Components.Button("Accept", {
                    col = -2,
                    event = function()
                        self:accept()
                    end
                })
            }
        end

        c = vim.list_extend(c, {{}, footer})
    end

    self:set_height(#c)
    Dialog.set_components(self, c)
    self:render()
end

function TabsDialog:on_finish()
    if not self:get_model():validate() then
        return
    end

    self:accept()
end

function TabsDialog:get_page_name(page)
    return private[self].pages[page + 1]
end

function TabsDialog:get_page_components(page)
    return private[self].components[self:get_page_name(page)]
end

function TabsDialog:set_components(components)
    vim.validate({
        components = {components, {"table", "nil"}}
    })

    private[self].components = components
    self:update()
end

return TabsDialog
