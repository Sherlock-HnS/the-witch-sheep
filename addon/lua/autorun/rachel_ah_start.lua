if !pcall(require,"pk_pills") then
    if SERVER then
        hook.Add("PlayerInitialSpawn","pk_pill_extfail_cl",function(ply)
            if game.SinglePlayer() || ply:IsListenServerHost() then
                ply:SendLua('notification.AddLegacy("One or more pill extensions failed to load. Did you forget to install Parakeet\'s Pill Pack?",NOTIFY_ERROR,30)')
            end
        end)
        hook.Add("Initialize","pk_pill_extfail_sv",function(ply)
            print("[ALERT] One or more pill extensions failed to load. Did you forget to install Enhanced Parakeet's Pill Base?")
        end)
    end
    return
end

AddCSLuaFile()

if SERVER then

    local function CreateAConvVarConstant(VarName, DefaultSetting, Text,min,max)
        CreateConVar(VarName, DefaultSetting, FCVAR_ARCHIVE, Text, min, max)     
    end
    --rat_gentoi_stats

    CreateAConvVarConstant("GentoiPills_rachel_walkspeed",20,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rachel_runspeed",540,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rachel_crouchspeed",20,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rachel_jumppower",0,"", 0,1e9)

    CreateAConvVarConstant("GentoiPills_rachel_xray",1,"", 0,1)  
    CreateAConvVarConstant("GentoiPills_rachel_xray_duration",10,"", 0,1e9) 
    CreateAConvVarConstant("GentoiPills_rachel_xray_cd",60,"", 0,1e9) 
else

    hook.Add("PopulateToolMenu", "Gentoi_pill_rachel_populate", function()   

        spawnmenu.AddToolMenuOption("Pill Base Settings", "Pills", "Gentoi_pills_rachel", "Rachel", "", "", function(panel)

            panel:Help("------------ rachel ------------")


            panel:Help("-- Preset --")
            local presettable = {
                name = "Gentoi_pills_rachel_presets",

                listofdefualtconvars = {
                    "GentoiPills_rachel_walkspeed",
                    "GentoiPills_rachel_runspeed",
                    "GentoiPills_rachel_crouchspeed",
                    "GentoiPills_rachel_jumppower",
                    "GentoiPills_rachel_xray",
                    "GentoiPills_rachel_xray_duration",
                    "GentoiPills_rachel_xray_cd"
                }
            }

            local presetName = presettable.name
            local listofdefualtconvars = presettable.listofdefualtconvars

            local combo = vgui.Create("DComboBox")
            combo:Dock(TOP)
            combo:SetTall(30)
            combo:SetValue("Default")

            local saveButton = vgui.Create("DButton")
            saveButton:Dock(TOP)
            saveButton:SetTall(25)
            saveButton:SetText("Save Current")

            local editButton = vgui.Create("DButton")
            editButton:Dock(TOP)
            editButton:SetTall(25)
            editButton:SetText("Edit Presets")

            panel:AddItem(combo)
            panel:AddItem(saveButton)
            panel:AddItem(editButton)

            local PRESET_FOLDER = "OM_LNZ"
            local PRESET_FILE = PRESET_FOLDER .. "/preset_" .. presetName .. ".json"

            local function EnsureFolder()
                if not file.Exists(PRESET_FOLDER, "DATA") then
                    file.CreateDir(PRESET_FOLDER)
                end
            end

            local function LoadPresets()
                EnsureFolder()

                if not file.Exists(PRESET_FILE, "DATA") then
                    return {}
                end

                return util.JSONToTable(file.Read(PRESET_FILE, "DATA")) or {}
            end

            local function SavePresets(presets)
                EnsureFolder()
                file.Write(PRESET_FILE, util.TableToJSON(presets, true))
            end

            local defaultValues = {}

            for _, cvar in ipairs(listofdefualtconvars) do
                local cv = GetConVar(cvar)

                if cv then
                    defaultValues[cvar] = cv:GetDefault()
                end
            end

            local function RefreshDropdown()
                combo:Clear()
                combo:AddChoice("Default")

                for name in pairs(LoadPresets()) do
                    combo:AddChoice(name)
                end
            end

            RefreshDropdown()

            function combo:OnSelect(_, value)
                if value == "Default" then
                    for cvar, default in pairs(defaultValues) do
                        RunConsoleCommand(cvar, tostring(default))
                    end

                    return
                end

                local preset = LoadPresets()[value]
                if not preset then return end

                for cvar, value in pairs(preset) do
                    RunConsoleCommand(cvar, tostring(value))
                end
            end

            saveButton.DoClick = function()
                Derma_StringRequest(
                    "Save Preset",
                    "Preset name:",
                    "",
                    function(name)
                        if not name or name == "" then return end

                        local presets = LoadPresets()
                        presets[name] = {}

                        for _, cvar in ipairs(listofdefualtconvars) do
                            local cv = GetConVar(cvar)

                            if cv then
                                presets[name][cvar] = cv:GetString()
                            end
                        end

                        SavePresets(presets)
                        RefreshDropdown()
                        combo:SetValue(name)
                    end
                )
            end

            local function OpenPresetEditor()
                local presets = LoadPresets()

                local frame = vgui.Create("DFrame")
                frame:SetSize(550, 420)
                frame:Center()
                frame:SetTitle("Preset Editor - " .. presetName)
                frame:MakePopup()

                local list = vgui.Create("DListView", frame)
                list:Dock(LEFT)
                list:SetWide(160)
                list:AddColumn("Presets")

                for name in pairs(presets) do
                    list:AddLine(name)
                end

                local right = vgui.Create("DScrollPanel", frame)
                right:Dock(FILL)

                local selected

                list.OnRowSelected = function(_, _, row)
                    right:Clear()
                    selected = row:GetColumnText(1)

                    for cvar, value in pairs(presets[selected] or {}) do
                        local rowPanel = right:Add("DPanel")
                        rowPanel:Dock(TOP)
                        rowPanel:SetTall(30)
                        rowPanel:DockMargin(4, 4, 4, 4)

                        local label = rowPanel:Add("DLabel")
                        label:Dock(LEFT)
                        label:SetWide(250)
                        label:SetText(cvar)

                        local entry = rowPanel:Add("DTextEntry")
                        entry:Dock(FILL)
                        entry:SetValue(value)

                        entry.OnChange = function(self)
                            presets[selected][cvar] = self:GetValue()
                        end
                    end
                end

                local bottom = vgui.Create("DPanel", frame)
                bottom:Dock(BOTTOM)
                bottom:SetTall(35)

                local save = bottom:Add("DButton")
                save:Dock(LEFT)
                save:SetWide(100)
                save:SetText("Save")
                save.DoClick = function()
                    SavePresets(presets)
                    RefreshDropdown()
                end

                local delete = bottom:Add("DButton")
                delete:Dock(RIGHT)
                delete:SetWide(100)
                delete:SetText("Delete")
                delete.DoClick = function()
                    if not selected then return end

                    presets[selected] = nil
                    SavePresets(presets)

                    frame:Close()
                    RefreshDropdown()
                end

                local rename = bottom:Add("DButton")
                rename:Dock(FILL)
                rename:SetText("Rename")
                rename.DoClick = function()
                    if not selected then return end

                    Derma_StringRequest(
                        "Rename Preset",
                        "New name:",
                        selected,
                        function(name)
                            if not name or name == "" or presets[name] then return end

                            presets[name] = presets[selected]
                            presets[selected] = nil

                            SavePresets(presets)
                            frame:Close()
                            RefreshDropdown()
                        end
                    )
                end
            end

            editButton.DoClick = OpenPresetEditor

            panel:Help("-- Speed --")

            panel:NumSlider("Walk Speed","GentoiPills_rachel_walkspeed",1,200)
            panel:NumSlider("Run Speed","GentoiPills_rachel_runspeed",200,500)
            panel:NumSlider("Crouch Speed","GentoiPills_rachel_crouchspeed",1,200)
            panel:NumSlider("Jump Power","GentoiPills_rachel_jumppower",0,200)

            panel:Help("")

            panel:Help("-- XRAY --")
            panel:CheckBox("Can Be Used","GentoiPills_rachel_xray")
            panel:NumSlider("Duration","GentoiPills_rachel_xray_duration",0,70)
            panel:NumSlider("Cooldown","GentoiPills_rachel_xray_cd",0,70)

            panel:Help("")
        end)        
    end)
end