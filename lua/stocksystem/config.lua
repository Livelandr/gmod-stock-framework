STOCKSYSTEM.StockUpdateTime = 5 -- Stock prices update interval [def. 5]
STOCKSYSTEM.ShortPositionLimit = 250 -- Maximal short position

STOCKSYSTEM.StockData = { 
    ["TEST"] = { -- Stock id
        displayName = "TEST", -- Stock symbol
        name = "Test Inc.", -- Stock full name
        priceGenerationType = "Automatic", -- Price generation type [Automatic - simulate price dynamics]
        initialPrice = 100, -- Stock price at creation
        maxPriceMove = 10, -- maximal price jump
        priceHistory = {}, -- Price history (Don't touch this unless you know what you doing)
        category = "TestStocks", -- Stock category
    },
}

function STOCKSYSTEM.AddMoneyFunction(ply, price) -- Function for money income/withdraw
   ply:addMoney(price) -- Standard darkrp function
end

function STOCKSYSTEM.CanAfford(ply, amount) -- Money check function
    return (ply:getDarkRPVar("money") >= amount )
end