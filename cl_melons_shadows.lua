
----
---@module
---@name shadows
---@realm CLIENT
----
---- Alternative shadow renderer to Code Blues that supports colored shadows.
----
local shadows = {}

shadows.RenderTarget = GetRenderTarget("MelonsShadows", ScrW(), ScrH())
shadows.Material = CreateMaterial("MelonsShadows", "UnlitGeneric", {
    ["$basetexture"] = shadows.RenderTarget:GetName(),
    ["$transparent"] = "1",
    ["$color"] = "1",
    ["$vertexalpha"] = "1",
    ["$alpha"] = "1"
})
shadows.Current = false
shadows.LastRendered = false

----
---@name shadows.Start
----
---@arg (name: string) Shadow identifier for caching purposes
----
---- Starts the shadow render operation
----
function shadows.Start(name)
    if shadows.LastRendered and (shadows.LastRendered == name) and shadows.Current then
        shadows.Render()
        return false
    end

    shadows.LastRendered = name
    shadows.Current = {
        opacity = 255,
        intensity = 1,
        spread = 5,
        blur = 1,
        relative = false,

        at_x = 0,
        at_y = 0,

        xoffset = 0,
        yoffset = 0
    }

    shadows.Material:SetFloat("$alpha", 1)

    render.PushRenderTarget(shadows.RenderTarget)
    render.Clear(0, 0, 0, 0)
    cam.Start2D()

    return true
end

----
---@name shadows.End
----
---- Ends the shadow render operation and actually renders it
----
function shadows.End()
    local c = shadows.Current
    if not c then
        debug.Trace()
        return Error("[MelonsShadows] Attempting to end a shadow that hasnt been started\n")
    end

    if c.blur != 0 then
        render.BlurRenderTarget(shadows.RenderTarget, c.spread, c.spread, c.blur)
    end

    render.PopRenderTarget()

    shadows.Render()

    cam.End2D()
end

----
---@internal
---@name shadows.Render
----
---- Renders the shadow
----
function shadows.Render()
    local c = shadows.Current
    shadows.Material:SetFloat("$alpha", c.opacity / 255)
    render.SetMaterial(shadows.Material)

    local x, y = 0, 0
    local w, h = ScrW(), ScrH()

    if IsValid(c.relative) then
        x, y = c.relative:LocalToScreen(0, 0)
        x = x - c.at_x
        y = y - c.at_y
    end

    x = x + c.xoffset
    y = y + c.yoffset

    for i = 0, c.intensity do
        render.DrawScreenQuadEx(x, y, w, h)
    end
end

----
---@internal
---@name shadows.CreateSetter
----
---@arg    (key:    string) Key on the state to modify
---@return (func: function) Function to alter the state
----
---- Generates an accessor to set a value on the state
----
function shadows.StateAccessor(key)
    return function(value)
        shadows.Current[key] = value
    end
end

----
---@name shadows.Dirty
----
---- Dirties the current shadow render
----
function shadows.Dirty()
    shadows.LastRendered = false
end

---@type function 
---@name shadows.SetOpacity
---@arg (opacity: number) How opaque should the shadow be 0 -> 255
shadows.SetOpacity = shadows.StateAccessor("opacity")

---@type function 
---@name shadows.SetIntensity
---@arg (intensity: number) How many times the shadow should be drawn
shadows.SetIntensity = shadows.StateAccessor("intensity")

---@type function 
---@name shadows.SetSpread
---@arg (spread: number) How far the shadow should spread out
shadows.SetSpread = shadows.StateAccessor("spread")

---@type function 
---@name shadows.SetBlur
---@arg (blur: number) How many blur iterations to run on the shadow
shadows.SetBlur = shadows.StateAccessor("blur")

---@type function 
---@name shadows.SetRelative
---@arg (relative: Panel) The position of the shadow should be relative to this panel
---- If youre using this, you also want to use shadows.SetRenderedAt
shadows.SetRelative = shadows.StateAccessor("relative")

----
---@name shadows.SetRenderedAt
----
---@arg (x: number) X position that the shadows contents is being rendered at
---@arg (y: number) Y position that the shadows contents is being rendered at
----
---- For use with SetRelative, otherwise useless
----
function shadows.SetRenderedAt(x, y)
    shadows.Current.at_x = x
    shadows.Current.at_y = y
end

----
---@name shadows.SetOffset
----
---@arg (x: number) X position for the offset of the shadow
---@arg (y: number) Y position for the offset of the shadow
----
function shadows.SetOffset(x, y)
    shadows.Dirty() -- this fixes a potential bug that i havent encountered yet lol

    shadows.Current.xoffset = x
    shadows.Current.yoffset = y
end


--- Testing ---
--- Tests depend on Melonlib
if not melon then return shadows end

--- Basic Example
melon.DebugHook(false, "HUDPaint", function()
    shadows.Start()                 -- First, we start the render
        shadows.SetOpacity(100)     -- Next we set the opacity of the shadow
        shadows.SetIntensity(3)     -- Then we set how intense it should be, think how many layers of it
        shadows.SetSpread(4)        -- How far should it spread away from the center
        shadows.SetBlur(1)          -- How many times should it be blurred, how many passes
        shadows.SetOffset(10, 10)   -- What should the X and Y offset be for the shadow

        -- Then we draw what we want the shadow to look like

        surface.SetDrawColor(255, 0, 0)
        surface.DrawRect(50, 50, 150, 50)

        surface.SetDrawColor(0, 255, 0)
        surface.DrawRect(50, 100, 150, 50)

        surface.SetDrawColor(0, 0, 255)
        surface.DrawRect(50, 150, 150, 50)
    shadows.End()                   -- Then we end the render

    -- Now we draw over it and were done
    draw.RoundedBox(8, 50, 50, 150, 150, Color(22, 22, 22))
end )

--- Caching Example
melon.DebugHook(false, "HUDPaint", function()
    -- Were now asking it if we should render the shadow
    if shadows.Start("identifier") then
        -- If we should then we do the exact same as before

        shadows.SetOpacity(100)
        shadows.SetIntensity(3)
        shadows.SetSpread(4)
        shadows.SetBlur(1)
        shadows.SetOffset(10, 10)

        surface.SetDrawColor(255, 0, 0)
        surface.DrawRect(50, 50, 150, 50)

        surface.SetDrawColor(0, 255, 0)
        surface.DrawRect(50, 100, 150, 50)

        surface.SetDrawColor(0, 0, 255)
        surface.DrawRect(50, 150, 150, 50)

        -- Notice how were ending inside the block
        shadows.End()
    end

    -- And now continue what you were doing
    draw.RoundedBox(8, 50, 50, 150, 150, Color(22, 22, 22))

    -- This change of 2 lines *can* immediately eliminate all fps drops from the shadow
    -- as were actually rendering it once
end )

--- Panel Example
melon.DebugPanel("Melon:Draggable", function(pnl)
    pnl:SetSize(150, 150)
    pnl:Center()
    -- pnl:SetPos(50, 50 + 200)
    pnl:SetAlpha(255)

    function pnl:Paint(w, h)
        -- We need to know the position of the panel in screenspace
        -- Its silly but it is what it is
        local x, y = self:LocalToScreen(0, 0)

        -- See the caching example
        -- Everythings the same here
        if shadows.Start("identifier") then
            shadows.SetOpacity(100)
            shadows.SetIntensity(3)
            shadows.SetSpread(4)
            shadows.SetBlur(1)
            shadows.SetOffset(10, 10)

            -- Until here, which is where we tell it a few things
            -- That we want to track the position of the panel were rendering on
            shadows.SetRelative(self)

            -- And that we already rendered at this position, so we can know
            -- when the panel has moved from that position
            shadows.SetRenderedAt(x, y)

            -- Everything else is equivalent to the HUDPaint examples.
            surface.SetDrawColor(255, 0, 0)
            surface.DrawRect(x, y + 0, w, h / 3)

            surface.SetDrawColor(0, 255, 0)
            surface.DrawRect(x, y + h / 3, w, h / 3)

            surface.SetDrawColor(0, 0, 255)
            surface.DrawRect(x, y + (h / 3) * 2, w, h / 3)

            shadows.End()
        end

        draw.RoundedBox(8, 0, 0, w, h, Color(22, 22, 22))
    end

    function pnl:PerformLayout(w, h)
        shadows.Dirty()
    end
end )

return shadows