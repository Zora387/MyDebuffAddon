-- Crée un cadre pour surveiller les événements
local frame = CreateFrame("Frame")

-- Taille maximale des icônes de débuff à afficher
local MAX_DEBUFFS = 5
local DEBUFF_SIZE = 20

-- Fonction pour afficher les débuffs sur la nameplate
local function UpdateDebuffs(nameplate, unit)
    if not nameplate.debuffFrames then
        nameplate.debuffFrames = {}

        -- Crée les cadres pour les icônes de débuffs une seule fois
        for i = 1, MAX_DEBUFFS do
            local debuffFrame = CreateFrame("Frame", nil, nameplate)
            debuffFrame:SetSize(DEBUFF_SIZE, DEBUFF_SIZE)

            debuffFrame.icon = debuffFrame:CreateTexture(nil, "OVERLAY")
            debuffFrame.icon:SetAllPoints(debuffFrame)

            if i == 1 then
                debuffFrame:SetPoint("BOTTOMLEFT", nameplate, "TOPLEFT", 0, 5)
            else
                debuffFrame:SetPoint("LEFT", nameplate.debuffFrames[i - 1], "RIGHT", 2, 0)
            end

            nameplate.debuffFrames[i] = debuffFrame
        end
    end

    -- Mise à jour des icônes de débuffs
    for i = 1, MAX_DEBUFFS do
        local name, icon, _, _, duration, expirationTime, _, caster = UnitDebuff(unit, i)
        local debuffFrame = nameplate.debuffFrames[i]

        -- Vérifie si le débuff est appliqué par le joueur
        if name and icon then
            debuffFrame.icon:SetTexture(icon)
            debuffFrame:Show()

            -- Gérer l'animation de cooldown
            if duration and duration > 0 then
                if not debuffFrame.cooldown then
                    debuffFrame.cooldown = CreateFrame("Cooldown", nil, debuffFrame, "CooldownFrameTemplate")
                    debuffFrame.cooldown:SetAllPoints(debuffFrame)
                    debuffFrame.cooldown:SetSwipeColor(1, 1, 0, 0.7)  -- Couleur du swipe (jaune)
                    debuffFrame.cooldown:SetHideCountdownNumbers(true)  -- Cacher les chiffres
                end
                debuffFrame.cooldown:SetCooldown(expirationTime - duration, duration)
            else
                if debuffFrame.cooldown then
                    debuffFrame.cooldown:Clear()
                end
            end
        else
            debuffFrame:Hide()  -- Cache les icônes si pas de débuff
        end
    end
end

-- Fonction appelée à chaque fois qu'un nameplate est affiché
local function OnNameplateAdded(self, event, unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplate then
        UpdateDebuffs(nameplate, unit)
    end
end

-- Enregistre les événements
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("UNIT_AURA")  -- Pour actualiser les débuffs en temps réel
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, ...)
    local unit = ...
    if event == "NAME_PLATE_UNIT_ADDED" or (event == "UNIT_AURA" and C_NamePlate.GetNamePlateForUnit(unit)) then
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
        if nameplate then
            UpdateDebuffs(nameplate, unit)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local nameplates = C_NamePlate.GetNamePlates()
        for _, nameplate in ipairs(nameplates) do
            local unit = nameplate.UnitFrame and nameplate.UnitFrame.unit
            if unit then
                UpdateDebuffs(nameplate, unit)
            end
        end
    end
end)
