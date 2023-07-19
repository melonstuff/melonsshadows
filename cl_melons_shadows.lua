
----
---@module
---@name shadows
---@realm CLIENT
----
---- Alternative shadow renderer to Code Blues that supports colored shadows.
----
local shadows = {}

shadows.RenderTarget = GetRenderTarget("MelonsShadows", ScrW(), ScrH())
shadows.Material = CreateMaterial("MelonsShadows" .. CurTime(), "UnlitGeneric", {
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
    shadows.Current.xoffset = x
    shadows.Current.yoffset = y
end


--- Testing ---
--- Tests depend on Melonlib
if not melon then return shadows end

melon.DebugPanel("Melon:Draggable", function(pnl)
    pnl:SetSize(512, 512)
    pnl:Center()
    pnl:SetAlpha(255)

    function pnl:Paint(w, h)
        local x, y = self:LocalToScreen(0, 0)

        if shadows.Start("This is all FREE TO RENDER!!!!!!!!") then
            shadows.SetOpacity(255)
            shadows.SetIntensity(2)
            shadows.SetSpread(10)
            shadows.SetBlur(4)
            shadows.SetRelative(self)
            shadows.SetRenderedAt(x, y)
            shadows.SetOffset(60, 20)

            melon.stencil.Start()
                surface.DrawOutlinedRect(x, y, w, h, w / 4)
            melon.stencil.Cut()
                surface.SetMaterial(melon.Material("vgui/gradient-u"))
                surface.SetDrawColor(255, 0, 0)
                surface.DrawTexturedRectRotated(x + w / 2, y + h / 2, w * 2, h * 2, 45)
                surface.SetDrawColor(0, 255, 0)
                surface.DrawTexturedRectRotated(x + w / 2, y + h / 2, w * 2, h * 2, 45 + 90)
                surface.SetDrawColor(0, 0, 255)
                surface.DrawTexturedRectRotated(x + w / 2, y + h / 2, w * 2, h * 2, 45 + 180)
            melon.stencil.End()

            shadows.End()
        end
        
        surface.SetDrawColor(255, 255, 255)
        surface.DrawOutlinedRect(0, 0, w, h, w / 4)
    end
end )

return shadows
