-- ========================================
-- 📄 ServerScriptService/NPCAI/NPCStates/State_Hit.lua
-- ========================================

local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)
local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)



-- ⭐ เปิดการรับแรงกระแทก
local function EnablePhysics(npc)
    local hrp = npc.model:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = false
        hrp.CanCollide = true
    end
    
    if npc.humanoid then
        npc.humanoid.PlatformStand = true -- ปล่อยให้ร่างกายถูกควบคุมด้วย Physics
        npc.humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        npc.humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    end
end


-- ⭐ ปิดการรับแรงกระแทก (คืนค่าปกติ)
local function DisablePhysics(npc)
    if npc.humanoid then
        npc.humanoid.PlatformStand = false
        npc.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end


-- ⭐ ฟังก์ชันผลักตัวละคร (ปรับจาก PushCharacter)
-- ⭐ ฟังก์ชันผลักตัวละคร
local function KnockbackNPC(npc, direction, power)
    local hrp = npc.model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- เปิดการรับแรงกระแทกก่อน
    EnablePhysics(npc)

    -- สร้าง BodyVelocity เพื่อผลัก
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(100000, 50000, 100000) -- เพิ่ม Y เล็กน้อย
    bodyVelocity.Velocity = direction * power + Vector3.new(0, 20, 0) -- เพิ่มแรงขึ้นเล็กน้อย
    bodyVelocity.Parent = hrp

    -- ลบ BodyVelocity หลังจาก 0.3 วินาที
    task.delay(0.3, function()
        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity:Destroy()
        end
    end)

    print("💨 Knocked back:", npc.model.Name, "with power", power)
end





return {
    Enter = function(npc, hitData)
        local hitCfg = Config.States.Hit
        npc.humanoid.WalkSpeed = 0
        npc.isHit = true
        npc.lastHitTime = tick()

        -- 🩸 แสดงอนิเมชันหรือเสียงโดนตี (แล้วแต่คุณจะเพิ่ม)
        print("💢", npc.model.Name, "โดนโจมตี!")


            -- ⭐ เพิ่ม debug log ตรงนี้
    print("🔍 hitData:", hitData)
    if hitData then
        print("   - Type:", hitData.Type)
        print("   - Direction:", hitData.Direction)
    end



      -- 🔹 ถ้าโดนขว้างของ → ผลักด้วย BodyVelocity
    if hitData and hitData.Type == "ThrownObject" and hitData.Direction then
        local knockbackPower = hitCfg.KnockbackPower or 50
        print("✅ เรียก KnockbackNPC!")
        KnockbackNPC(npc, hitData.Direction, knockbackPower)
    else
        print("❌ ไม่มี Direction หรือ Type ไม่ตรง")
    end


        -- ส่งอีเวนต์สำหรับกล้องสั่น / เอฟเฟกต์
        EventBus:Emit("OnNPCHit", npc, hitData)
      --  EventBus:Emit("ShakeCamera", npc.model, 0.3, 0.2)
    end,

    Update = function(npc)
        local hitCfg = Config.States.Hit

        -- 🕒 หลังจากเวลาชะงัก → กลับไป Chase หรือ Idle
        if tick() - npc.lastHitTime > hitCfg.StunTime then
            npc.isHit = false

            DisablePhysics(npc) -- ปิดการรับแรงกระแทก คืนค่าปกติ



            if npc.target then
                return "Chase"
            else
                return "Idle"
            end
        end

        return "Hit"
    end,

    Exit = function(npc)
        npc.isHit = false

        DisablePhysics(npc) -- ปิดการรับแรงกระแทก

        npc.humanoid.WalkSpeed = Config.States.Chase.Speed
    end,
}
