-- ========================================
-- 📄 ReplicatedStorage/Config/ItemConfig.lua
-- ========================================

--[[
    วางใน ReplicatedStorage > Config
]]


return {

    ItemBook_1 = {
        table_shelf_for_book = 1,

        use = true,
    },

     ItemBook_2 = {
        table_shelf_for_book = 2,

        use = true,
    },

     ItemBook_3 = {
        table_shelf_for_book = 3,

        use = true,
    },

     ItemBook_4 = {
        table_shelf_for_book = 4,

        use = true,
    },


    
     ItemBook_5 = {
        table_shelf_for_book = 5,

        use = true,
    },


    -- ItemBook 999 will can use every type book 
    -- item will destroy but not success and alret bot
    ItemBook_999 = {

        table_shelf_for_book = 999,

        use = false,
        
        alert_bot = true,

    },


}