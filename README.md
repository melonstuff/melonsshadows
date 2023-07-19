![logo](https://i.imgur.com/2uxiBDS.png)

Melon's Shadows is a modern alternative to [Blue's Shadows](https://gist.github.com/Gmod4phun/397ab9785edb709cc057fcd56dcbb7cb#file-blues_shadows-lua) which allows for colored shadows and caching.

# Installation
1. Download the file
2. Put it in your project
3. Modify the file to declare the local as global or use the return

# Usage
1. First, you open a shadow by calling `shadows.Start()` in a 2d rendering hook.  
2. Next you use the `shadows.Set*` methods to determine how the shadow should be processed/rendered.
3. Next you draw what you want to be blurred into your shadow.
4. Finally you call `shadows.End()`, and boom youre done, then you can draw your actual ui over it!

# API
The API is very simple, the only functions you need are the following:  
> `shadows.Start(string?)`  
> Starts the shadow drawing, pushes the rt, everything

> `shadows.End()`  
> Renders the shadow, resets everything to normal

> `shadows.SetOpacity(float)`  
> Sets the opacity of the current shadow, alpha, 0 to 255

> `shadows.SetIntensity(int)`  
> Sets the intensity of the current shadow, how many render passes

> `shadows.SetSpread(int)`  
> Sets the spread of the shadow, how far it should expand from the center

> `shadows.SetBlur(int)`  
> Sets the amount of blur passes

> `shadows.SetRelative(Panel)`  
> Panel that the shadow should be positioned relative to

> `shadows.SetRenderedAt(int, int)`  
> Use in conjunction with SetRelative, where the shadow was drawn, see the examples

> `shadows.Dirty()`  
> Use in conjunction with SetRelative, call in PerformLayout or whenever you need

> `shadows.SetOffset(int, int)`  
> X, Y offset of the shadow

Internal functions can be read about in the source :)

# Basic Example
This is a very basic example that demonstrates how to use the library in HUDPaint, and create an object that looks like this:  
  
![basic](https://i.imgur.com/fs650PU.png)
```lua
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
```

# Caching Example
This is an example showing how to cache the shadow for the next render, something to note is **IT ONLY CACHES THE LAST SHADOW** meaning that it **WILL** re-render if another shadow was drawn after the last one. You can avoid this by creating a RenderTarget yourself and calling [`render.CopyRenderTargetToTexture`](https://wiki.facepunch.com/gmod/render.CopyRenderTargetToTexture) yourself on `shadows.RenderTarget`.  
This will look exactly like the last example.

```lua
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
```

# Panel Example
Panel shadows are handled slightly differently due to their non-static but predictable nature.  
This will look exactly like the first example.

```lua
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

-- Dont forget to call shadows.Dirty() in your PerformLayout if your panel isnt statically sized!!
```

# Notes
This library is essentially BShadows without the limitations imposed by the library itself, such as greyscale shadows only. The only thing that this library is missing that BShadows has is the `_shadowOnly` parameter, if you are blurring your shadow it shouldnt have a large impact visually for alpha but if you need that, sorry.  
Massive respect to Code Blue, BShadows is fantastic but old, so here we are :)
