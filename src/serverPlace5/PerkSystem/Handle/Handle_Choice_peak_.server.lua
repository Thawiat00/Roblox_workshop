local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Handle_choice_peak = ReplicatedStorage:WaitForChild("Common"):WaitForChild("Handle_choice_peak")


-- รับข้อมูลจาก Client
Handle_choice_peak.OnServerEvent:Connect(function(player, buttonName)
    print("Server รับข้อมูลจาก:", player.Name)
    print("ปุ่มที่ถูกคลิก:", buttonName)
    
    -- ทำงานที่ต้องการ เช่น
    -- ให้ไอเทม, เปลี่ยนสถานะ, บันทึกข้อมูล ฯลฯ
    
    -- ตัวอย่าง: ตรวจสอบปุ่มที่คลิก
    if buttonName == "Silent_Step " then
        print("เลือก Peak ที่ Silent_Step ")
        -- ทำงานเฉพาะเมื่อเลือก Peak 1
    elseif buttonName == "Blood Link" then
        print("เลือก Peak ที่ Blood Link")
        -- ทำงานเฉพาะเมื่อเลือก Peak 2
    end
end)