-- STOCK SETTINGS
local pregeneratedPrices = {}

STOCKSYSTEM.LoadStocksDataFromFile()

util.AddNetworkString("StocksDataBroadcast")

------------------------

function STOCKSYSTEM.generateRandomGraph(maxMove, steps, startPrice)
    local tbl = {}

    local curPrice = startPrice

    for i = 1, steps do
        curPrice = math.Round(math.abs(curPrice + math.random(-1, 1) * maxMove * math.Rand(0, 1)), 1)
        table.insert(tbl, curPrice)
    end

    return tbl

end


local function UpdateStockPrice(stock)

    if (not pregeneratedPrices[stock] or #pregeneratedPrices[stock] == 0) then
        pregeneratedPrices[stock] = STOCKSYSTEM.generateRandomGraph(STOCKSYSTEM.StockData[stock].maxPriceMove, 100, STOCKSYSTEM.StockData[stock].initialPrice)
    end

    table.insert(STOCKSYSTEM.StockData[stock].priceHistory, 1,  pregeneratedPrices[stock][1])

    hook.Call("StocksFramework_StockPriceChanged", nil, stock, pregeneratedPrices[stock][1])

    table.remove(pregeneratedPrices[stock], 1)

    STOCKSYSTEM.SaveStocksDataToFile()
end
-------------------------

timer.Create("StockPricesUpdate", STOCKSYSTEM.StockUpdateTime, 0, function()
    for k, v in pairs(STOCKSYSTEM.StockData) do
        if (v.priceGenerationType == "Automatic") then
            UpdateStockPrice(k)
        end
    end

    net.Start("StocksDataBroadcast")
        net.WriteString( util.TableToJSON(STOCKSYSTEM.StockData) )
    net.Broadcast()
end)     
