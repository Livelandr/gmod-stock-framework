util.AddNetworkString("StocksPlayerStockAmount")
util.AddNetworkString("StocksPlayerBuyStock")
util.AddNetworkString("StocksPlayerSellStock")
util.AddNetworkString("StocksPlayerNewTransaction")

local PLY = FindMetaTable("Player")

gameevent.Listen( "player_activate" )
hook.Add("player_activate", "StockDataNullificator", function(ply)
    STOCKSYSTEM.LoadAllPlayersDataToFile()
end)

function PLY:BuyStock(stock, amount)
    if (STOCKSYSTEM.StockData[stock].priceHistory[1] == 0 or amount <= 0) then return end

    if not STOCKSYSTEM.CanAfford( self, amount * STOCKSYSTEM.StockData[stock].priceHistory[1] ) then
        return
    end

    hook.Call("StocksFramework_StocksBought", nil, self, stock, amount, amount * STOCKSYSTEM.StockData[stock].priceHistory[1])

    STOCKSYSTEM.AddMoneyFunction(self, -amount * STOCKSYSTEM.StockData[stock].priceHistory[1])
    self.buyedStocksData[stock].amount = (self.buyedStocksData[stock].amount or 0) + amount
    self.buyedStocksData[stock].lastTransaction = os.date( "%d/%m/%Y %H:%M:%S" , os.time() )

    hook.Call("StocksFramework_PlayerPositionChanged", self, stock, self.buyedStocksData[stock].amount)

    net.Start("StocksPlayerStockAmount")
        net.WriteString(util.TableToJSON(self.buyedStocksData))
    net.Send(self)
    
    local transactionData = {
        playerName = self:Name(),
        transaction = "Buy",
        symbol = STOCKSYSTEM.StockData[stock].displayName,
        stock = stock,
        issuer = STOCKSYSTEM.StockData[stock].name,
        amount = amount,
        price = STOCKSYSTEM.StockData[stock].priceHistory[1],
        time = self.buyedStocksData[stock].lastTransaction
    }

    net.Start("StocksPlayerNewTransaction")
        net.WriteString(util.TableToJSON(transactionData))
    net.Send(self)
    
    STOCKSYSTEM.SaveAllPlayersDataToFile()
end


function PLY:SellStock(stock, amount)
    if (STOCKSYSTEM.StockData[stock].priceHistory[1] == 0 or amount <= 0) then return end

    if ((self.buyedStocksData[stock].amount or 0) - amount < -STOCKSYSTEM.ShortPositionLimit) then
        return
    end

    
    hook.Call("StocksFramework_StocksSold", nil, self, stock, amount, amount * STOCKSYSTEM.StockData[stock].priceHistory[1])

    STOCKSYSTEM.AddMoneyFunction(self, amount * STOCKSYSTEM.StockData[stock].priceHistory[1])
    self.buyedStocksData[stock].amount = (self.buyedStocksData[stock].amount or 0) - amount
    self.buyedStocksData[stock].lastTransaction = os.date( "%d/%m/%Y %H:%M:%S" , os.time() )
    
    hook.Call("StocksFramework_PlayerPositionChanged", self, stock, self.buyedStocksData[stock].amount)

    net.Start("StocksPlayerStockAmount")
        net.WriteString(util.TableToJSON(self.buyedStocksData))
    net.Send(self)

    local transactionData = {
        playerName = self:Name(),
        transaction = "Sell",
        symbol = STOCKSYSTEM.StockData[stock].displayName,
        stock = stock,
        issuer = STOCKSYSTEM.StockData[stock].name,
        amount = amount,
        price = STOCKSYSTEM.StockData[stock].priceHistory[1],
        time = self.buyedStocksData[stock].lastTransaction
    }

    net.Start("StocksPlayerNewTransaction")
        net.WriteString(util.TableToJSON(transactionData))
    net.Send(self)

    STOCKSYSTEM.SaveAllPlayersDataToFile()
end
 

net.Receive("StocksPlayerBuyStock", function(len, ply)
    local data = util.JSONToTable(net.ReadString())

    ply:BuyStock(data.stock, data.amount)    
end)

net.Receive("StocksPlayerSellStock", function(len, ply)
    local data = util.JSONToTable(net.ReadString())

    ply:SellStock(data.stock, data.amount)    
end)