local Utils = require("ide.utils")
local Project = require("ide.base.project")

local Javascript = Utils.class(Project)

function Javascript:get_type()
    return "javascript"
end

function Javascript.get_templates(t, b)
    local templates = Project.get_templates(t, b)

    templates["svelte"] = {
        name = "Svelte Application",
        command = {
            cmd = "npm",
            args = {"create", "vite@latest", ".", "-y", "--", "--template", "svelte"}
        }
    }

    -- templates["sveltekit"] = {
    --     name = "SvelteKit Application",
    --     code = [[ ]]
    -- }

    if templates["generic"] then
        templates["generic"].default = true
    end

    return templates
end

function Javascript.get_root_pattern()
    return {
        ["package.json"] = {builder = "node"}
    }
end

return Javascript
