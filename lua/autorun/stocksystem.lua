AddCSLuaFile()

STOCKSYSTEM = STOCKSYSTEM or {}

if SERVER then
    include("stocksystem/config.lua")
    
    include("stocksystem/sv_savedatatofiles.lua")
    include("stocksystem/sv_stocksdatagenerator.lua")
    include("stocksystem/sv_sellbuysystem.lua")
    include("stocksystem/sv_api.lua")
    AddCSLuaFile("stocksystem/cl_datareceiver.lua")
    AddCSLuaFile("stocksystem/cl_tradinginterface.lua")

else

    include("stocksystem/cl_datareceiver.lua")
    include("stocksystem/cl_tradinginterface.lua")
 
end 