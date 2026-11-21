if SERVER then
    AddCSLuaFile()
    util.AddNetworkString('rachel_jumpscare_gen')

else


    hook.Add("SetupPlayerVisibility", "VisibilityHandler_v2", function()
        local ply = LocalPlayer()

        local pillentity = ply.pk_pill_ent
        if IsValid(pillentity) then
            if ( pillentity:GetNWInt('Rwallhaks', 0) >= CurTime() ) then

                for _, ent in ipairs(ents.GetAll()) do
                    if IsValid(ent) then
                        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
                            AddOriginToPVS(plr:GetPos())
                        end
                    end
                end
            end
        end
    end)
    hook.Add( "PreDrawOutlines_nick_base", "pumpkinwabbitseason_v2", function()
        local ply = LocalPlayer()

        local pillentity = ply.pk_pill_ent
        local ent = ply.pk_pill_ent
        if IsValid(pillentity) then
            ent.Gentoi_witch_indicator_Duration_camlerp = ent.Gentoi_witch_indicator_Duration_camlerp and Lerp(FrameTime()*7, ent.Gentoi_witch_indicator_Duration_camlerp, ent:GetNWInt("Rwallhaks") >= CurTime() and 1 or 0) or 0
            if pillentity.Gentoi_witch_indicator_Duration_camlerp and pillentity.Gentoi_witch_indicator_Duration_camlerp >= 0.05 then
                local entities = {}

                for _, ent in ipairs(entityTable_pillarchase_recode()) do
                    if IsValid(ent) then
                        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
                            if ent == ply then continue end 
                            if ent == pillentity then continue end 
                            if ent:IsPlayer() and ent:Team() == TEAM_SPECTATOR then continue end

                            if ent:GetColor().a <= 30 then continue end
                            if ent:GetClass() == "pill_puppet" then continue end

                            table.insert(entities, ent)
                            
                        end
                    end
                end

                nick_base_halo.Add(entities, Color(255*pillentity.Gentoi_witch_indicator_Duration_camlerp,0,255*pillentity.Gentoi_witch_indicator_Duration_camlerp), 3, true)
            end
        end
    end )


    net.Receive('rachel_jumpscare_gen', function()
        local ent = net.ReadEntity()
        local state = net.ReadBool()
        local startTime = CurTime()

        local hookID = "rachel_jumpscare_" .. LocalPlayer():SteamID()

        --print(state)

        if not state then
            hook.Remove('CalcView', hookID)
        else
            hook.Add('CalcView', hookID, function(ply, pos, angles, fov)
                if not IsValid(ply) or not ply:Alive() or !IsValid(ent) then
                    hook.Remove('CalcView', hookID)
                    if IsValid(ply) then
                        ply:RemoveFlags(FL_NOTARGET)
                        ply:Freeze(false)
                        ply:DrawViewModel(true)
                    end
                    return
                end

                local cam = ent:GetAttachment(ent:LookupAttachment('camera'))

                ply:AddFlags(FL_NOTARGET)
                ply:Freeze(true)
                ply:DrawViewModel(false)

                local lerpFactor = math.Clamp((CurTime() - startTime) / (0.7/3), 0, 1)
                
                local targetFOV = 80 

                local orgiginlerpto = LerpVector(lerpFactor, pos, cam.Pos)
                local angleslerpto = LerpAngle(lerpFactor, angles, cam.Ang)
                local interpolatedFOV = Lerp(lerpFactor, fov, targetFOV)

                local view = {
                    origin = orgiginlerpto,
                    angles = angleslerpto,
                    fov = interpolatedFOV,
                    drawviewer = false
                }
                return view
            end)
        end
    end)

end

local function AdvancedPillSound(SoundData, ent)
    if IsValid(ent) then
        SoundData = SoundData or {}
        SoundData.stringe = SoundData.stringe or {}
        SoundData.soundLevel = SoundData.soundLevel or 75
        SoundData.pitchPercent = SoundData.pitchPercent or 100
        SoundData.volume = SoundData.volume or 1
        SoundData.channel = SoundData.channel or CHAN_AUTO
        SoundData.soundFlags = SoundData.soundFlags or 0
        SoundData.dsp = SoundData.dsp or 0
        SoundData.filter = SoundData.filter or nil

        local chosenSound = SoundData.stringe

        if istable(SoundData.stringe) then
            local index = math.random(1, #SoundData.stringe)
            chosenSound = SoundData.stringe[index]
        end

        ent:EmitSound(
            chosenSound,
            SoundData.soundLevel,
            SoundData.pitchPercent,
            SoundData.volume,
            SoundData.channel,
            SoundData.soundFlags,
            SoundData.dsp,
            SoundData.filter
        )
    end
    return true
end


local function racheljackietien_jumpscare(ply, ent, duration, customanimstuff)
    if not ent.IsInJumpscare then ent.IsInJumpscare = 0 end
    if ent.IsInJumpscare >= CurTime() then return end
    if not ent.IsInJumpscareCooldown then ent.IsInJumpscareCooldown = 0 end
    if ent.IsInJumpscareCooldown >= CurTime() then return end

    local jumpscare_entity = nil

    for _, ent2 in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 90)) do
        if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() >= 0.1 then
            if ent2 == ply then continue end
            if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end

            if IsValid(ent2) then
                jumpscare_entity = ent2
                break
            end
        end
    end

    if jumpscare_entity ~= nil then
        
        ent.JuumpscareStart = CurTime()

        ent.jumpscare_entity = jumpscare_entity
        ent.entitylastpos = jumpscare_entity:GetPos()
        ent.entitylastang = jumpscare_entity:GetAngles()

        local targetAngle = (ply:GetPos() - jumpscare_entity:GetPos()):Angle()

        targetAngle.p = 0
        targetAngle.r = 0

        ply:SetNWInt("DisableMovement_jumpscare_pill_rachel", duration+CurTime())
        jumpscare_entity:SetNWInt("DisableMovement_jumpscare_pill_rachel", duration+CurTime())

        ent.IsInJumpscare = CurTime() + duration

        local puppet = ent:GetPuppet()

        if jumpscare_entity:IsPlayer() then
            net.Start('rachel_jumpscare_gen')
            net.WriteEntity(puppet)
            net.WriteBool(true)
            net.Send(jumpscare_entity)
        else
            jumpscare_entity:NextThink(duration+0.1+CurTime())
        end
        
        jumpscare_entity:AddFlags(FL_NOTARGET)

        ent:CallOnRemove("RachelJumpscare"..ent:EntIndex(), function()
            if !IsValid(jumpscare_entity) then return end

            jumpscare_entity:RemoveFlags(FL_NOTARGET)
            ent.jumpscare_entity = nil

            if jumpscare_entity:IsPlayer() then
                net.Start('rachel_jumpscare_gen')
                net.WriteEntity(puppet)
                net.WriteBool(false)
                net.Send(jumpscare_entity)
            else
                jumpscare_entity:NextThink(CurTime())
            end
            jumpscare_entity:SetPos(ent.entitylastpos)
            jumpscare_entity:SetAngles(ent.entitylastang)
            jumpscare_entity:SetNWInt("DisableMovement_jumpscare_pill_rachel", CurTime())
        end)

        customanimstuff()
    end
end
gentoi_slowdownfunctions_initialize({
    ["Name"] = "RachelMovementCode",
    ["SetupMove"] = function(ply, mv, cmd)
        if ply:GetNWInt("DisableMovement_jumpscare_pill_rachel") >= CurTime() then
            mv:SetForwardSpeed(0)
            mv:SetSideSpeed(0)
            mv:SetUpSpeed(0)
            mv:SetButtons(0)
        end
    end,
    ["CreateMove"] = function(ply,cmd)

        if ply:GetNWInt("DisableMovement_jumpscare_pill_rachel") >= CurTime() then
            cmd:SetForwardMove(0)
            cmd:SetSideMove(0)
            cmd:SetUpMove(0)
            cmd:ClearButtons()
        end
    end,
})

    local preservedmats = {
        [0] = Material("icons/rachel_scanning_icon.png")
    }
pk_pills.register('PIll_rachel_ah', {

    printName='Rachel',
        
    model="models/gentoi/anologhorror/Rachel.mdl",
        
    modelScale='1.0',
        

    noragdoll = true,
    muteSteps = true,
    _Rachel_pill_ds = true,
    gentoi_basepill = true,
        
    anims={
        default={
            idle="idle",
            run="run",
            walk="walk",
            jumpscare="jumpscare",
            crouch = "CrouchIdle",
            crouch_walk = "CrocuhWalk"
        },
        ShouldMoveRotate={
            idle= function(ent) 
                if ent:GetNWBool("Shiftlock") then return "shiftlock" end
                if ent:GetPillUser():IsOnGround() then
                    return 'notanything'
                else
                    return 'notshftlock'
                end
            end,
            cidle= function(ent) 
                if ent:GetNWBool("Shiftlock") then return "shiftlock" end
                if ent:GetPillUser():IsOnGround() then
                    return 'notanything'
                else
                    return 'notshftlock'
                end
            end,
            run= function(ent)
                if ent:GetNWBool("Shiftlock") then return "shiftlock" end
                return 'notshftlock'
            end,
            walk= function(ent)
                if ent:GetNWBool("Shiftlock") then return "shiftlock" end
                return 'notshftlock'
            end,
        },
    },
    

    moveSpeed = {
        walk = 50,
        run = 540,
        ducked=20,
    },
        
    sounds={
        jumpscare = "gentoi/anologhorror/rachel/WitchKill.wav"
    },

    type='ply',

    camera={
        offset = Vector(0, 0, 75),
        dist=120,
    },
        
    jumpPower=0,
        
    health=2000,
    
    movePoseMode="xy",
        aim={
        xPose="aim_yaw",
        yPose="aim_pitch",
        nocrosshair = true
    },
        
    gentoi_basepill_uifunction_drawfunction = function(ply,ent)
        local ply = LocalPlayer()
        local pillentity = ent
        local screenW, screenH = ScrW(), ScrH()

        surface.SetDrawColor(35, 35, 35, 255) 
        local iconsize = screenW / 15
        local xaxis = iconsize / 3
        local yaxis = screenH - iconsize *1.75
        surface.DrawRect(xaxis, yaxis, iconsize, iconsize)

        -- number counter

        surface.DrawRect(xaxis, yaxis, iconsize*0.1, iconsize)

        local yaxis_bar = yaxis + iconsize

        draw.SimpleText("M2", "DermaLarge", xaxis+ScreenScale(1), yaxis+ScreenScale(1), Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if pillentity:GetNWBool("GentoiPills_rachel_xray") then
            surface.SetDrawColor(255, 255, 255, 255)
        else
            surface.SetDrawColor(255, 0, 0, 255)
        end
        surface.SetMaterial(preservedmats[0])
        surface.DrawTexturedRect(xaxis+iconsize*0.05, yaxis+iconsize*0.1, iconsize*0.9, iconsize*0.9)

        draw.SimpleText("Ghastly Ominance", "Trebuchet18", xaxis+iconsize/2, yaxis+iconsize*0.85, Color(165, 0, 165), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if pillentity:GetNWInt("RwallhaksCooldown") > CurTime() then
            local yaxis_bar = yaxis + iconsize
            local iconsize_bar = math.Clamp((pillentity:GetNWInt("RwallhaksCooldown") - CurTime() ) / pillentity:GetNWInt("Rwallhak_duration"), 0, 1)
            local lerpfactoriconsize_bar = Lerp(iconsize_bar, screenW / 15, 0)
            local lerpfactoriyaxis_bar = Lerp(iconsize_bar, yaxis, yaxis_bar)

            surface.SetDrawColor(0, 255, 0, 185) 
            surface.DrawRect(xaxis, lerpfactoriyaxis_bar, iconsize, lerpfactoriconsize_bar)
        end

        if pillentity.Gentoi_witch_indicator_Duration_camlerp and pillentity.Gentoi_witch_indicator_Duration_camlerp >= 0.02 then 
            local pp_colour_contrast = 1

            local colorModify = {
                ["$pp_colour_addr"] = 0.15 * pillentity.Gentoi_witch_indicator_Duration_camlerp,
                ["$pp_colour_addg"] = -0.3 * pillentity.Gentoi_witch_indicator_Duration_camlerp,
                ["$pp_colour_addb"] = 0.15 * pillentity.Gentoi_witch_indicator_Duration_camlerp,
                ["$pp_colour_brightness"] = -0.2 * pillentity.Gentoi_witch_indicator_Duration_camlerp,
                ["$pp_colour_contrast"] = 1,
                ["$pp_colour_colour"] = 1,
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            }

            DrawColorModify(colorModify)
        end

    end,

    gentoi_basepill_camtable = function(ply,ent)
        local basetable =  {
            startoffset = Vector(30,0,0),  -- left-up, front-back, up-down
            dist=100,
            fov = ply:GetInfoNum("gentoipills_basefov", 80),
            id = 0,
            transition = 0,
            bonecenter = "Head",
            cameraentity = ent:GetPuppet()
        }

        ent.Gentoi_pumpkinrabbit_indicator_Duration_camlerp = ent.Gentoi_pumpkinrabbit_indicator_Duration_camlerp and Lerp(FrameTime()*7, ent.Gentoi_pumpkinrabbit_indicator_Duration_camlerp, ent:GetNW2Float("Gentoi_pumpkinrabbit_indicator_Duration") >= CurTime() and 1 or 0) or 0
        basetable["fov"] = basetable["fov"] - 20* ent.Gentoi_pumpkinrabbit_indicator_Duration_camlerp

        return basetable
    end,

    canAim=function(ply,ent) return ent.active end,    

    gentoi_basepill_event = function(ply, ent, event)
        if event == "playerded" then
            local jumpscare_entity = ent.jumpscare_entity
            if !(IsValid(jumpscare_entity)) or !IsValid(ent) then return end
            ent.jumpscare_entity = nil
            jumpscare_entity:SetPos(ent.entitylastpos)
            jumpscare_entity:SetAngles(ent.entitylastang)
            if jumpscare_entity:IsPlayer() then
                net.Start('rachel_jumpscare_gen')
                net.WriteEntity(puppet)
                net.WriteBool(false)
                net.Send(jumpscare_entity)
                jumpscare_entity:Kill(ply)
            else
                jumpscare_entity:NextThink(CurTime())

                jumpscare_entity:TakeDamage(1e9, ply)
                --[[
                jumpscare_entity:TakeDamage(jumpscare_entity:Health()-1, ply)
                
                for i=1,10 do
                    timer.Simple(0.1,function()
                        if !IsValid(ent) then return end
                        if !IsValid(jumpscare_entity) then return end
                        jumpscare_entity:TakeDamage(35, ply)
                    end)
                
                end
                ]]
            end
            ent:RemoveCallOnRemove("RachelJumpscare"..ent:EntIndex())
        end
        if event == "BLOODBLOOD" then


            local offset = ent:GetPuppet():GetRight() * math.Rand(0, 0) + ent:GetPuppet():GetForward() * math.Rand(95, 95) + ent:GetPuppet():GetUp() * math.Rand(65, 65)
                
            local effectdata = EffectData()
            effectdata:SetOrigin(ent:GetPuppet():GetPos() + offset)
            effectdata:SetNormal(ent:GetAngles():Forward())
            effectdata:SetMagnitude(3)
            effectdata:SetScale(15)
            effectdata:SetColor(0)
            effectdata:SetFlags(3)
            util.Effect("bloodspray", effectdata)
            effectdata:SetOrigin(ent:GetPuppet():GetPos() + offset)
            effectdata:SetNormal(ent:GetAngles():Forward())
            effectdata:SetMagnitude(3)
            effectdata:SetScale(15)
            effectdata:SetColor(0)
            effectdata:SetFlags(3)
            util.Effect("BloodImpact", effectdata)
            effectdata:SetOrigin(ent:GetPuppet():GetPos() + offset)
            effectdata:SetNormal(ent:GetAngles():Forward())
            effectdata:SetMagnitude(3)
            effectdata:SetScale(15)
            effectdata:SetColor(0)
            effectdata:SetFlags(3)
            util.Effect("BloodSplash", effectdata)

        end
        if event == "Melee" then
        end
    end,


    attack = {
        mode = 'trigger',
        func = function(ply, ent)

            local dur = ent:GetPuppet():SequenceDuration(ent:GetPuppet():LookupSequence("jumpscare"))
            racheljackietien_jumpscare(
                ply,
                ent,
                dur,
                function()
                    ent:PillSound('jumpscare')
                    ent:PillAnim('jumpscare')
                end
            )
        end
    },


    attack2 = {
        mode = "trigger",
        func = function(ply, ent)
            if SERVER then
                if not GetConVar("GentoiPills_rachel_xray"):GetBool() then return end
                if ent:GetNWInt("RwallhaksCooldown", 0) >= CurTime() then return end

                ent:SetNWInt("Rwallhaks", CurTime()+ GetConVar("GentoiPills_rachel_xray_duration"):GetFloat() )
                ent:SetNWInt("Rwallhak_duration", GetConVar("GentoiPills_rachel_xray_cd"):GetFloat() )
                ent:SetNWInt("RwallhaksCooldown", CurTime()+ GetConVar("GentoiPills_rachel_xray_cd"):GetFloat() )
            end
        end,
    },

    noragdoll=true,


    gentoi_basepill_init=function(ply,ent, puppet)
        puppet.IsInJumpscare = 0
        puppet:SetNWInt("RwallhaksCooldown", CurTime())
    end,

    reload=function(ply,ent)
        --[[
        if not ent.VoiceLineDelay then ent.VoiceLineDelay = 0 end

        if ent.VoiceLineDelay >= CurTime() then
            return
        end

        local soundgo = {
            [0] = "gentoi/anologhorror/locust/locust_speech1.wav",
            [1] = "gentoi/anologhorror/locust/locust_speech2.wav",
            [2] = "gentoi/anologhorror/locust/locust_speech3.wav",
            [3] = "gentoi/anologhorror/locust/locust_speech4.wav",
            [4] = "gentoi/anologhorror/locust/locust_speech5.wav",
            [5] = "gentoi/anologhorror/locust/locust_speech6.wav",
            [6] = "gentoi/anologhorror/locust/locust_speech7.wav"
        }

        local key = math.random(0,#soundgo)
        

        if soundgo[key] ~= nil then

            if SERVER then
                ent:GetPuppet():AddGestureSequence(ent:GetPuppet():LookupSequence("Spaek"..key+1), true)
            end
            
            local duration = SoundDuration(soundgo[key])

            ent.VoiceLineDelay = CurTime() + duration

            AdvancedPillSound(
                {
                    stringe = soundgo[key],
                },
                ent
            )

            ent:StopSound("gentoi/anologhorror/locust/locust_idleloop.wav")
            ent.breathcooldown = ent.VoiceLineDelay
        end]]
    end,

    flashlight = function(ply, ent)
    end,
        
    jump = function(ply, ent) end,

    gentoi_basepill_think = function(ply, ent)
        if CLIENT then
            if not ent.SetChaseMusicInitilize_agatha_gentoi then
                ent.SetChaseMusicInitilize_agatha_gentoi = true
                ply.Gentoi_Chasemusic_shouldplay_killer = function(plye, currentenemy)
                    if !IsValid(ent) then return end
                    return true
                end
                ply.Gentoi_Chasemusic_shouldplay = function(plye, currentenemy)
                    if !IsValid(ent) then return end
                    if plye then end
                    return true
                end
            end
        end


        if CLIENT then
            if LocalPlayer() == ply then
                if ent:GetNWInt("Rwallhaks",0) >= CurTime() then
                    CinemaBarEnable_gentoi(150)
                else
                    CinemaBarEnable_gentoi(0)
                end
            end
        end

        ent:SetNWBool("GentoiPills_rachel_xray", GetConVar("GentoiPills_rachel_xray"):GetBool())
        

        local speed = {
            ['walk'] = GetConVar("GentoiPills_rachel_walkspeed"):GetFloat(),
            ['run'] = GetConVar("GentoiPills_rachel_runspeed"):GetFloat(),
            ['ducked'] = GetConVar("GentoiPills_rachel_crouchspeed"):GetFloat(),
            ['jumppower'] = GetConVar("GentoiPills_rachel_jumppower"):GetFloat()
        }

        if IsValid(ply) and IsValid(ent) then
            ply:SetWalkSpeed(speed["walk"])
            ply:SetRunSpeed(speed["run"])
            ply:SetCrouchedWalkSpeed(speed["ducked"])
            ply:SetJumpPower(speed["jumppower"])
        end

        if ent.jumpscare_entity then
            local entity = ent.jumpscare_entity
            if IsValid(entity) then

                local lengthofentitybody = (entity:EyePos() - entity:GetPos()):Length() /2

                local cam = ent:GetPuppet():GetAttachment(ent:GetPuppet():LookupAttachment('camera'))

                if entity:Health() < 0.1 and entity:IsPlayer() then
                    ent.jumpscare_entity = nil
                else
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local lengthofentitybody = ((maxs.z - mins.z)/2)*4

                    local lerpFactor = math.Clamp((CurTime() - ent.JuumpscareStart) / 0.5, 0, 1)
                    local newAngle = LerpAngle(lerpFactor, ent.entitylastang, cam.Ang)
                    local NewVector = LerpVector(lerpFactor, ent.entitylastpos, cam.Pos - entity:GetUp() * lengthofentitybody)
                    entity:SetPos(NewVector)
                    entity:SetAngles(newAngle)
                end
            end
        end
    end
})

