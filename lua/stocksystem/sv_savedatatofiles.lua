STOCKSYSTEM.PlayerDataSaveFile = "stocks/playersData.json"
STOCKSYSTEM.StockDataSaveFile = "stocks/stocksData.json"

file.CreateDir("stocks")

function STOCKSYSTEM.SaveAllPlayersDataToFile()
    
    local allUsersTable = {}

    for _, v in pairs(player.GetHumans()) do
        allUsersTable[tostring(v:SteamID())] = {}
        allUsersTable[tostring(v:SteamID())] = v.buyedStocksData
    end

    file.Write(STOCKSYSTEM.PlayerDataSaveFile, util.TableToJSON(allUsersTable, true))

end

function STOCKSYSTEM.SaveStocksDataToFile()

    local pricesData = {}

    for k, v in pairs(STOCKSYSTEM.StockData) do
        pricesData[k] = v.priceHistory[1]
    end

    file.Write(STOCKSYSTEM.StockDataSaveFile, util.TableToJSON(pricesData, true))
end

function STOCKSYSTEM.LoadStocksDataFromFile()
    local savedData = util.JSONToTable(file.Read(STOCKSYSTEM.StockDataSaveFile, "DATA") or "{}")

    for k, v in pairs(savedData) do
        STOCKSYSTEM.StockData[k].initialPrice = v
    end

end

function STOCKSYSTEM.LoadAllPlayersDataToFile()

    local savedData = util.JSONToTable(file.Read(STOCKSYSTEM.PlayerDataSaveFile, "DATA") or "{}")

    local emptyTable = {}

    for k, v in pairs(STOCKSYSTEM.StockData) do
        emptyTable[k] = {}
    end

    for _, v in pairs(player.GetHumans()) do
        v.buyedStocksData = savedData[tostring(v:SteamID())] or emptyTable
        
        net.Start("StocksPlayerStockAmount")
            net.WriteString(util.TableToJSON(v.buyedStocksData))
        net.Send(v)
    end

end