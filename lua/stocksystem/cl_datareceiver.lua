STOCKSYSTEM.StockData = STOCKSYSTEM.StockData or {}

STOCKSYSTEM.BuyedStocksData = STOCKSYSTEM.BuyedStocksData or {}
STOCKSYSTEM.TransactionsHistory = STOCKSYSTEM.TransactionsHistory or {}
STOCKSYSTEM.CoditionalTransactions = STOCKSYSTEM.CoditionalTransactions or {}

net.Receive("StocksPlayerNewTransaction", function()
    local data = util.JSONToTable(net.ReadString())
    table.insert(STOCKSYSTEM.TransactionsHistory, data)
end)

net.Receive("StocksPlayerStockAmount", function()
    STOCKSYSTEM.BuyedStocksData = util.JSONToTable(net.ReadString())
end)

net.Receive("StocksDataBroadcast", function()
    STOCKSYSTEM.StockData = util.JSONToTable(net.ReadString())
end)

--- Conditions

file.CreateDir("stocks")
STOCKSYSTEM.CoditionalTransactions = util.JSONToTable( file.Read("stocks/conditions.json") or "{}" )

timer.Create("StocksConditionChecker", 1, 0, function()
    
    for k, v in pairs(STOCKSYSTEM.CoditionalTransactions) do
        if (v.isLower) then
            
            if (v.targetPrice <= STOCKSYSTEM.StockData[v.stock].price) then
    
                net.Start(((v.action == "Buy") and "StocksPlayerBuyStock" or "StocksPlayerSellStock"))
                    net.WriteString( util.TableToJSON(
                        {
                            amount = v.amount, 
                            stock = v.stock
                        }
                    ) )
                net.SendToServer()

                table.remove(STOCKSYSTEM.CoditionalTransactions, k)
                surface.PlaySound("garrysmod/content_downloaded.wav")

            end

        else

            if (v.targetPrice >= STOCKSYSTEM.StockData[v.stock].price) then
    
                net.Start(((v.action == "Buy") and "StocksPlayerBuyStock" or "StocksPlayerSellStock"))
                    net.WriteString( util.TableToJSON(
                        {
                            amount = v.amount, 
                            stock = v.stock
                        }
                    ) )
                net.SendToServer()

                table.remove(STOCKSYSTEM.CoditionalTransactions, k)
                surface.PlaySound("garrysmod/content_downloaded.wav")

            end

        end

    end
    
    file.Write("stocks/conditions.json", util.TableToJSON(STOCKSYSTEM.CoditionalTransactions, true))

end)    