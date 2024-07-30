--@name brainfuck interpreter
--@author Xandertron
--@client
--@owneronly

local pointer = 0
local memory = {}

--https://github.com/rdebath/Brainfuck/tree/master/testing
--counts words, characters, whatever
--local code = ">>>+>>>>>+>>+>>+[<<],[-[-[-[-[-[-[-[-[<+>-[>+<-[>-<-[-[-[<++[<++++++>-]<[>>[-<]<[>]<-]>>[<+>-[<->[-]]]]]]]]]]]]]]]]<[-<<[-]+>]<<[>>>>>>+<<<<<<-]>[>]>>>>>>>+>[<+[>+++++++++<-[>-<-]++>[<+++++++>-[<->-]+[+>>>>>>]]<[>+<-]>[>>>>>++>[-]]+<]>[-<<<<<<]>>>>],]+<++>>>[[+++++>>>>>>]<+>+[[<++++++++>-]<.<<<<<]>>>>>>>>]"
--hello world that fucks up interpreters
--local code = "+[>[<->+[>+++>[+++++++++++>][]-[<]>-]]++++++++++<]>>>>>>----.<<+++.<-..+++.<-.>>>.<<.+++.------.>-.<<+.<."
--takes 5 billion steps to finish
--local code = "+>>+++++++++++++++++++++++++++++<<[>>>[>>]<[[>>+<<-]>>-[<<]]>+<<[-<<]<]>+>>[-<<]<+++++++++[>++++++++>+<<-]>-.----.>." 
--returns max size of cells
local code = "++[>++++++++<-]>[>++++++++<-]>[<<+>>[-<<[->++++++++++++++++<]>[-<++++++++++++++++>]<[->++++++++++++++++<]>[-<++++++++++++++++>]<>>]]<+<[[-]>[-]>[-]+++++++<<+>>[-<<[->++++++++++++++++<]>[-<++++++++++++++++>]<[->++++++++++++++++<]>[-<++++++++++++++++>]<>>]<<[->+>+<<]>>-[-<->]+<[[-]>>>>>>[-]<[-]<[-]<[-]<[-]<[-]>++++++[<++++>-]<[>+++++>++++>+>++>+++<<<<<-]>>>>>.<<<<---.>+++++++.--.>++++++++.<<------.+++.>>.<<----.+.-.>>>---.<<---.+++++++.<.>--------.<++++.+++++++.>>.<++.++.<-------------..+++++++.>>.<+.<----.++++++.-------.>--.>>+.>[-]<[-]<[-]<[-]<[-]<<]>[>>>>[-]<[-]<[-]<[-]<[-]>++++[<++++>-]<[>++++>+++++++>++++++>++<<<<-]>++++++.>----.+++.>+.<+++++.>++++++++.+++++.-------.>.<<----.-.>++.<-.++++++.>>.<------.++.+++++++..<-.>>.<------.<----.++++++.-------.>--.>++++++++++++++.[-]<[-]<[-]<[-]<]<>[-]+++++[<++++++>-]<++>+<[->[->++<]>[-<+>]<<]>>+<[[-]>-<]>[>[-]<[-]>++++++++[<++++>-]<.>++++++[<++++++>-]<+.+++++++++++++..---.+++.[-]]<<<[-]]>[>>+[[->++<]>[-<+>]<<+>]<>>++++[<++++>-]<+[>++++++>+++++++>++>+++++<<<<-]>>>>-.<<<++.+.>----.>--.<<.+++++.>+.<---------.>--.--.++.<.>++.<.>--.>.<<+++.-------.>+.>.>[-]<[-]<[-]<[-]<<>[-]>[-]>[-]>[-]>[-]>[-]+>[-]+>[-]+>[-]+<<<<<<<<<[->>+>+<<<]>>>[-<<<+>>>]<[>[-]>[-]<<[>+>+<<-]>>[<<+>>-]+++++++++<[>>>[-]+<<[>+>[-]<<-]>[<+>-]>[<<++++++++++>>-]<<-<-]+++++++++>[<->-]<[>+<-]<[>+<-]<[>+<-]>>>[<<<+>>>-]>>>[-]<<<+++++++++<[>>>[-]+<<[>+>[-]<<-]>[<+>-]>[<<++++++++++>>>+<-]<<-<-]>>>>[<<<<+>>>>-]<<<[-]<<+>]<[>[-]<[>+<-]+++++++[<+++++++>-]<-.[-]>>[<<+>>-]<<-]<>>>[-]<[-]<[-]<[-]>++++[<++++>-]<[>++++++>+++++++>++<<<-]>++.+++++++.>++++.>.<<------.++.+++++++..>-.>++++++++++++++.[-]<[-]<[-]<<[-]]<[-]++++++++++.[-]"
local userInput = "hello world!"

local code = string.split(code,"")
local userInput = string.split(userInput,"")
local output = {}

local stackPointer = 1
local stack = {}
local loopOpeners = {}
local loopClosers = {}

for pos, char in ipairs(code) do
    if char == "[" then
        table.insert(stack, pos)
    elseif char == "]" then
        local opener = table.remove(stack)
        table.insert(loopOpeners, opener, pos)
        table.insert(loopClosers, pos, opener)
    end
end

local function toByte(str)
    if not str then 
        return 0 
    else 
        return string.byte(str) 
    end
end

local function toChar(num)
    if (num >= 0 and num <= 31) or (num == 127) then --remove ascii control characters
        return "CTRL ("..num..")"
    elseif num < 256 then
        return string.char(num) 
    else
        return "EXCEEDED"
    end
end

local instr = {
    [">"] = function() pointer = (pointer + 1) % 30000 memory[pointer] = memory[pointer] or 0 end,
    ["<"] = function() pointer = (pointer - 1) % 30000 memory[pointer] = memory[pointer] or 0 end,
    ["+"] = function() memory[pointer] = ((memory[pointer] or 0) + 1) % 256 end,
    ["-"] = function() memory[pointer] = ((memory[pointer] or 0) - 1) % 256 end,
    ["."] = function() table.insert(output, toChar(memory[pointer] or 0)) end,
    [","] = function() memory[pointer] = toByte(table.remove(userInput,1)) end,
    ["["] = function() 
                if (memory[pointer] or 0) == 0 then
                    stackPointer = loopOpeners[stackPointer]
                end
            end,
    ["]"] = function()
                if (memory[pointer] or 0) ~= 0 then
                    stackPointer = loopClosers[stackPointer]
                end 
            end
}

local function canRun()
    return quotaTotalAverage()<quotaMax()*0.95
end

local function complete()
    print("OUTPUT: ",table.concat(output))
    printTable(output)
    print("MEMORY:")
    printTable(memory)
    print("P: "..pointer.." | TIR: "..instructionsRan)
    hook.remove("think","run")
end

local function dump()
    printTable(memory)
    printTable(output)
    print(pointer, stackPointer, steps)
end

local function step(doDebug)
    if not code[stackPointer] then 
        complete()
        return false
    end
    
    if doDebug then 
        print("INSTR: " .. code[stackPointer] .. " STKPTR: " .. stackPointer .. " PTR: " .. pointer .. " PTRMEM: " .. (memory[pointer] or 0))
    end
    
    instr[code[stackPointer]]()
    stackPointer = stackPointer + 1
    return true
end

--timer.create("run",0.1,0,function()
--    if not step(true) then timer.remove("run") end
--end)

hook.add("think","run",function()
    while canRun() and step(false) do end
end)
