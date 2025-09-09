local robot = require("robot")
local component = require("component")
local inventory = component.inventory_controller
local sides = require("sides")
local os = require("os")
local redstone = component.redstone

miner_sen = 82 -- 矿机完成信号的接收频率
miner_tra = 81 -- 矿机启动信号的发送频率
bc_tra = 801   -- BC启动信号的发送频率
bc_sen = 802   -- BC完成信号的接收频率

local function transfer(name)
    robot.turnRight()
    local count = inventory.getInventorySize(sides.front)
    local found = false
    
    for i = 1, count do
        local chest_stack = inventory.getStackInSlot(sides.front, i)
        if chest_stack and chest_stack.label == name then
            inventory.suckFromSlot(sides.front, i, 1)
            found = true
            break
        end
    end
    
    if not found then
        print("Not find " .. name .. " in xz")
    end

    robot.turnRight()
    inventory.dropIntoSlot(sides.front, 1)
    robot.select(2)
    inventory.dropIntoSlot(sides.front, 2)
    robot.turnLeft()
    robot.turnLeft()
end

local function transmit(fre, ticks)
    redstone.setWirelessFrequency(fre)
    redstone.setWirelessOutput(true)
    os.sleep(ticks/20)
    redstone.setWirelessOutput(false)
end

local function wait_for_sen(fre)
    redstone.setWirelessFrequency(fre)
    while true do
        if redstone.getWirelessInput() then
            print("signal got")
            break
        end
        os.sleep(0.05)
    end
end

local function detection(fre)
    while true do
        redstone.setWirelessFrequency(fre)
        if redstone.getWirelessInput() then
            transmit(bc_tra, 1*20)
        else
            break
        end
        os.sleep(5) --BC重启激活时间为2~3s
    end
end

local function run(mode)
    robot.down()
    robot.use(sides.front)
    robot.up()
    robot.select(1)
    
    local stackInfo = inventory.getStackInInternalSlot(1)
    local raw_name = stackInfo and stackInfo.label or ""
    
    robot.drop()
    
    os.sleep(8)
    
    if mode == 1 then
        transmit(miner_tra, 2) -- 发送矿机启动信号
        print("gt start")
        wait_for_sen(miner_sen) -- 等待矿机完成信号
        os.sleep(0.5)
    elseif mode == 2 then -- 模式2：运行矿机和BC引擎
        transmit(miner_tra, 2) -- 发送矿机启动信号
        print("gt start")
        wait_for_sen(miner_sen) -- 等待矿机完成信号
        transmit(bc_tra, 10*20) -- 发送BC启动信号
        print("bc start")
        detection(bc_sen) --接收BC完全结束信号
        transmit(bc_tra, 4*20) --重复检测,若无效则加时
        detection(bc_sen)
        print("---end---")
    end
    transfer(raw_name)
end

local function main()
    while true do
        local inv = inventory.getStackInInternalSlot(2)
        
        if inv then
            local mode = inv.size
            print("detected, mode:", mode)
            run(mode)
            os.sleep(0.5)
        else
            print("NULL")
            os.sleep(0.5)
        end
    end
end

main()
