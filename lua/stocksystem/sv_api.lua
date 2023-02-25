STOCKSYSTEM.API = {}

function STOCKSYSTEM.API.GetStockPrice(stock)
    if (not STOCKSYSTEM.StockData[stock]) then 
        error( "Stock " .. stock .. "does not exist!")
    end

    return STOCKSYSTEM.StockData[stock].priceHistory[1]
end


function STOCKSYSTEM.API.SetStockPrice(stock, price)
    if (not STOCKSYSTEM.StockData[stock]) then 
        error( "Stock " .. stock .. "does not exist!")
    end

    table.insert(STOCKSYSTEM.StockData[stock].priceHistory, 1, price)
    hook.Call("StocksFramework_StockPriceChanged", nil, stock, price)
    STOCKSYSTEM.SaveStocksDataToFile()
end

function STOCKSYSTEM.API.GetStockPricesHistory(stock)
    return STOCKSYSTEM.StockData[stock].priceHistory
end

function STOCKSYSTEM.API.GetPlayerPosition(ply, stock)
    return ply.buyedStocksData[stock].amount or 0
end

function STOCKSYSTEM.API.SetPlayerPosition(ply, stock, amount)
    ply.buyedStocksData[stock].amount = amount
    hook.Call("StocksFramework_PlayerPositionChanged", self, stock, self.buyedStocksData[stock].amount)
end