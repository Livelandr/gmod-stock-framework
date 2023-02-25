STOCKSYSTEM.Interface = STOCKSYSTEM.Interface or {}

local colors = {
    mainColor = Color(47,47,47),
    subColor = Color(60,60,60),
    dropListColor = Color(55,55,55),
    topMenuColor = Color(0, 255, 34),
    panelBackgroundColor = Color(30,30,30),

    categoryText = Color(255,205,0),

    priceRising = Color(0, 163, 0),
    priceFalling = Color(163, 0, 0),
    graphColor = Color(144,0,246),

    buttonBuyActive = Color(30, 255, 70),
    buttonBuyUnactive = Color(160, 255, 180),
    buttonSellActive = Color(255, 60, 60),
    buttonSellUnactive = Color(255, 175, 175),
} 

local function RegisterFont(font, size)
    surface.CreateFont("STOCKS_" .. font .. size, {
        font = font,
        extended = true,
        size = size
    })
end

RegisterFont("Arial", 15)
RegisterFont("Arial", 20)
RegisterFont("Arial", 25)
RegisterFont("Arial", 30)
RegisterFont("Arial", 35)
RegisterFont("Arial", 40)

local function ColorLerp(delta, colorF, colorT)
    local r = Lerp(delta, colorF.r, colorT.r)
    local g = Lerp(delta, colorF.g, colorT.g)
    local b = Lerp(delta, colorF.b, colorT.b)

    return Color(r, g, b)
end

function STOCKSYSTEM.Interface.ShowDropList(x, y, dropListData)

    local wasAlreadyHovered = false

    local dropList = vgui.Create("DPanel")
    dropList:SetPos(x, y) 
    dropList:SetSize( 150, #dropListData * 25 )
    dropList:MakePopup()
 
    dropList.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, colors.mainColor)
    end
 
    dropList.Think = function()
        if (dropList:IsChildHovered(false) and not wasAlreadyHovered) then
            wasAlreadyHovered = true
        elseif (not dropList:IsChildHovered(false) and wasAlreadyHovered) then
            dropList:Remove()
        end
    end

    local scrollPanel = vgui.Create( "DScrollPanel", dropList )
    scrollPanel:Dock( FILL )

    for _, v in pairs(dropListData) do 
        local button = scrollPanel:Add( "DButton" )
        button:SetText(" ")
        button:Dock( TOP )
        button:DockMargin( 0, 0, 0, 2 )

        button.Paint = function(s, w, h)
            draw.RoundedBox(0, 0, 0, w, h, colors.dropListColor)
            draw.SimpleText(v.displayName, "STOCKS_Arial15", 5, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)    
        end

        button.DoClick = function()
            dropList:Remove()
            v.func(button, button:LocalToScreen(button:GetPos()))
        end
    end

end

function STOCKSYSTEM.Interface.OpenSharesMenu()

    local avaliableCategories = {}
    local updateStocksList

    for k, v in pairs(STOCKSYSTEM.StockData) do
        if (not table.HasValue(avaliableCategories, v.category)) then
            table.insert(avaliableCategories, v.category)
        end
    end

    local SharesMenu = vgui.Create("DFrame")
    SharesMenu:SetParent(STOCKSYSTEM.Interface.MainPanel)
    SharesMenu:SetSize(500, 570)
    SharesMenu:Center()
    SharesMenu:MakePopup()
    SharesMenu:ShowCloseButton(false)

    SharesMenu:SetTitle(" ")

    SharesMenu.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, colors.panelBackgroundColor)
        draw.RoundedBox(0, 0, 0, w, 25, colors.mainColor)
        draw.RoundedBox(0, 1, 25, w - 2, 25, colors.subColor)
        draw.SimpleText("Issuer             Symbol         Delta%        Delta$            Price", "STOCKS_Arial20", 10, 27.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end


    SharesMenu.category = avaliableCategories[1]

    local closeButton = vgui.Create("DButton", SharesMenu)
    closeButton:SetPos(500-25, 0)
    closeButton:SetSize(25, 25)
    closeButton:SetText(" ")

    closeButton.Paint = function(s, w, h)
        draw.SimpleText("X", "STOCKS_Arial30", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    closeButton.DoClick = function()
        SharesMenu:Remove()
    end

    local categoryButton = vgui.Create("DButton", SharesMenu)
    categoryButton:SetPos(10, 0)
    categoryButton:SetSize(200, 25)
    categoryButton:SetText(" ")
    
    categoryButton.Paint = function(s, w, h)
        draw.SimpleText(SharesMenu.category, "STOCKS_Arial25", 0, 0, colors.categoryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    categoryButton.DoClick = function()

        local categoriesList = {}

        for k, v in pairs(avaliableCategories) do
            table.insert(categoriesList, {
                displayName = v,
                func = function()
                    SharesMenu.category = v
                    updateStocksList()
                end 
            })
        end

        STOCKSYSTEM.Interface.ShowDropList(gui.MouseX(), gui.MouseY(), categoriesList)

    end

    local stocksListPanel = vgui.Create("DPanel", SharesMenu)
    stocksListPanel:SetSize(488, 519)
    stocksListPanel:SetPos(6, 51)
    stocksListPanel.Paint = nil

    local stocksList = vgui.Create( "DScrollPanel", stocksListPanel )
    stocksList:Dock( FILL )    

    updateStocksList = function()
        stocksList:Clear()
        for k, v in pairs(STOCKSYSTEM.StockData) do

            if v.category ~= SharesMenu.category then continue end

            local Stock = stocksList:Add( "DButton" )
            Stock:SetText(" ")
            Stock:SetSize(0, 20)
            Stock:Dock( TOP )
            Stock:DockMargin( 0, 0, 0, 5 )
            Stock.currentDelta = 0
            Stock.currentPriceDelta = 0

            Stock.rising = true
            Stock.lastChange = 0


            Stock.Paint = function(s, w, h)

                local delta = (STOCKSYSTEM.StockData[k].priceHistory[1] - (STOCKSYSTEM.StockData[k].priceHistory[2] or STOCKSYSTEM.StockData[k].priceHistory[1] )) / (STOCKSYSTEM.StockData[k].priceHistory[2] or STOCKSYSTEM.StockData[k].priceHistory[1] ) * 100
                if (delta ~= 0 and Stock.currentDelta ~= delta) then
                    Stock.rising = (delta > 0) 
                    Stock.lastChange = SysTime()
                    Stock.currentDelta = delta
                    Stock.currentPriceDelta = (STOCKSYSTEM.StockData[k].priceHistory[1] - (STOCKSYSTEM.StockData[k].priceHistory[2] or STOCKSYSTEM.StockData[k].priceHistory[1] ))
                end

                if (Stock.rising) then
                    draw.RoundedBox(0, 0, 0, w, h, ColorLerp( (SysTime() - Stock.lastChange), colors.priceRising, colors.subColor ))
                else
                    draw.RoundedBox(0, 0, 0, w, h, ColorLerp( (SysTime() - Stock.lastChange), colors.priceFalling, colors.subColor ))
                end

                draw.SimpleText( (string.len(v.name) <= 18 and v.name or string.sub(v.name, 0, 19) .. "...") , "STOCKS_Arial15", 1, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(k, "STOCKS_Arial15", 140, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                draw.SimpleText(math.Round(Stock.currentDelta, 2).."%", "STOCKS_Arial15", 240, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(math.Round(Stock.currentPriceDelta, 2).."$", "STOCKS_Arial15", 330, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(math.Round(STOCKSYSTEM.StockData[k].priceHistory[1], 2) .. "$", "STOCKS_Arial15", 430, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end 

            Stock.DoClick = function()
                STOCKSYSTEM.Interface.CreateGraph(k)
            end

        end

    end

    updateStocksList()

end

function STOCKSYSTEM.Interface.OpenTradingOrder(symbol, buy, amount)

    local price = STOCKSYSTEM.StockData[symbol].priceHistory[1]
    local amount = (amount or 1)

    local isBuying = (buy or false) 

    local conditional = false
    local targetPrice = price

    local TradingOrder = vgui.Create("DFrame")
    --TradingOrder:SetParent(STOCKSYSTEM.Interface.MainPanel)
    TradingOrder:SetSize(500, 450)
    TradingOrder:Center()
    TradingOrder:MakePopup()
    TradingOrder:SetParent(STOCKSYSTEM.Interface.MainPanel)
    TradingOrder:ShowCloseButton(false)

    TradingOrder:SetTitle(" ")

    TradingOrder.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, colors.panelBackgroundColor)
        draw.RoundedBox(0, 0, 0, w, 25, colors.mainColor)
        draw.SimpleText("Trading Order", "STOCKS_Arial25", 5, 0, colors.categoryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        draw.SimpleText("Account: \t" .. LocalPlayer():Name(), "STOCKS_Arial30", 15, 40)

        draw.RoundedBox(0, 6, 150, 488, 225, colors.subColor)
        draw.RoundedBox(0, 7, 151, 486, 223, colors.panelBackgroundColor)
        
        draw.SimpleText("Price: ", "STOCKS_Arial30", 15, 295)
        draw.SimpleText("Amount: ", "STOCKS_Arial30", 15, 330)

        draw.RoundedBox(0, 300, 295, 150, 30, colors.subColor)
        draw.RoundedBox(0, 300, 330, 150, 30, colors.subColor)
        
        if conditional then
            draw.SimpleText("Price: ", "STOCKS_Arial20", 145, 80)
            draw.RoundedBox(0, 200, 77.5, 150, 25, colors.subColor)
        end
    end

    local closeButton = vgui.Create("DButton", TradingOrder)
    closeButton:SetPos(500-25, 0)
    closeButton:SetSize(25, 25)
    closeButton:SetText(" ")

    closeButton.Paint = function(s, w, h)
        draw.SimpleText("X", "STOCKS_Arial30", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    closeButton.DoClick = function()
        TradingOrder:Remove()
    end


    local targetPriceTextEntry = vgui.Create( "DTextEntry", TradingOrder )
    targetPriceTextEntry:SetPos(200, 77.5)
    targetPriceTextEntry:SetSize(150, 25)
    targetPriceTextEntry:SetVisible(conditional)

    targetPriceTextEntry:SetDrawBackground(false)
    targetPriceTextEntry:SetTextColor(color_white)
    targetPriceTextEntry:SetValue(tostring(targetPrice))
    
	targetPriceTextEntry.OnEnter = function( self )
        targetPrice = tonumber(self:GetValue())
        self:SetValue(tostring(targetPrice))
	end 

    local mode = vgui.Create("DButton", TradingOrder)
    mode:SetPos(15, 75)
    mode:SetSize(115, 30)
    mode:SetText(" ")

    mode.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, colors.subColor)

        if (conditional) then
            draw.SimpleText("Limit", "STOCKS_Arial15", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("Market", "STOCKS_Arial15", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end


    mode.DoClick = function()
        
        STOCKSYSTEM.Interface.ShowDropList(gui.MouseX(), gui.MouseY(), {
            {
                displayName = "Market",
                func = function()
                    conditional = false
                    targetPriceTextEntry:SetVisible(conditional)
                end
            },
            {
                displayName = "Limit",
                func = function()
                    conditional = true
                    targetPriceTextEntry:SetVisible(conditional)
                end
            }
        })

    end


    local buyButton = vgui.Create("DButton", TradingOrder)
    buyButton:SetText(" ")
    buyButton:SetPos(30, 160)
    buyButton:SetSize(210, 115)

    buyButton.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, (isBuying and colors.buttonBuyActive or colors.buttonBuyUnactive)) 
        draw.SimpleText("Buy", "STOCKS_Arial35", w / 2, h * 0.25, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(STOCKSYSTEM.StockData[symbol].displayName, "STOCKS_Arial40", w / 2, h * 0.6, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    buyButton.DoClick = function()
        isBuying = true
    end


    local sellButton = vgui.Create("DButton", TradingOrder)
    sellButton:SetText(" ")
    sellButton:SetPos(260, 160)
    sellButton:SetSize(210, 115)

    sellButton.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, (not isBuying and colors.buttonSellActive or colors.buttonSellUnactive)) 
        draw.SimpleText("Sell", "STOCKS_Arial35", w / 2, h * 0.25, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(STOCKSYSTEM.StockData[symbol].displayName, "STOCKS_Arial40", w / 2, h * 0.6, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    sellButton.DoClick = function()
        isBuying = false
    end

    local amountTextEntry
    local priceTextEntry = vgui.Create( "DTextEntry", TradingOrder )
    priceTextEntry:SetPos(300, 295)
    priceTextEntry:SetSize(150, 30)

    priceTextEntry:SetDrawBackground(false)
    priceTextEntry:SetTextColor(color_white)
    priceTextEntry:SetValue(tostring(price * amount))
    
	priceTextEntry.OnEnter = function( self )
        price = self:GetValue()
        amount = math.Round(price / STOCKSYSTEM.StockData[symbol].priceHistory[1])
        amountTextEntry:SetValue(amount)
        price = STOCKSYSTEM.StockData[symbol].priceHistory[1] * amount
	end 
 
    
    amountTextEntry = vgui.Create( "DTextEntry", TradingOrder )
    amountTextEntry:SetPos(300, 330)
    amountTextEntry:SetSize(150, 30)

    amountTextEntry:SetDrawBackground(false)
    amountTextEntry:SetTextColor(color_white)
    amountTextEntry:SetValue(tostring(amount))
    
	amountTextEntry.OnEnter = function( self )
		amount = tonumber(self:GetValue())
        price = STOCKSYSTEM.StockData[symbol].priceHistory[1] * amount
        priceTextEntry:SetValue(price)
	end 


    local sendRequest = vgui.Create("DButton", TradingOrder)
    sendRequest:SetPos(280 / 2, 380)
    sendRequest:SetSize(220,65)
    sendRequest:SetText(" ")

    sendRequest.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, (isBuying and colors.buttonBuyActive or colors.buttonSellActive)) 
        if not conditional then
            draw.SimpleText("Send Request", "STOCKS_Arial35", w / 2, h / 2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else 
            draw.SimpleText("Create condition", "STOCKS_Arial35", w / 2, h / 2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    sendRequest.DoClick = function()
        if not conditional then 
            net.Start((isBuying and "StocksPlayerBuyStock" or "StocksPlayerSellStock"))
                net.WriteString( util.TableToJSON(
                    {
                        amount = amount, 
                        stock = symbol
                    }
                ) )
            net.SendToServer()
        else

            local newCondition = {
                action = (isBuying and "Buy" or "Sell"),
                stock = symbol,
                symbol = STOCKSYSTEM.StockData[symbol].displayName,
                amount = amount,
                isLower = (STOCKSYSTEM.StockData[symbol].priceHistory[1] < targetPrice),
                targetPrice = targetPrice,
                date = os.date( "%d/%m/%Y %H:%M:%S" , os.time() )
            }

            table.insert(STOCKSYSTEM.CoditionalTransactions, newCondition)

        end

        TradingOrder:Close()
    end

end

function STOCKSYSTEM.Interface.OpenStockPortfolio()
    local portfolioValue = 0
    local updatePortfolio = function() end

    local StockPortfolio = vgui.Create("DFrame")
    StockPortfolio:SetParent(STOCKSYSTEM.Interface.MainPanel)
    StockPortfolio:SetSize(500, 570)
    StockPortfolio:Center() 
    StockPortfolio:MakePopup()
    StockPortfolio:ShowCloseButton(false)

    StockPortfolio:SetTitle(" ")

    StockPortfolio.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, colors.panelBackgroundColor)
        draw.RoundedBox(0, 0, 0, w, 50, colors.mainColor)
        draw.SimpleText("Stock Portfolio", "STOCKS_Arial25", 5, 0, colors.categoryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Portfolio Value: " .. portfolioValue .. "$", "STOCKS_Arial25", 5, 25, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        portfolioValue = 0
        for k, v in pairs(STOCKSYSTEM.BuyedStocksData) do
            portfolioValue = portfolioValue + math.Round((v.amount or 0) * STOCKSYSTEM.StockData[k].priceHistory[1], 2)
        end
        
    end
    

    local closeButton = vgui.Create("DButton", StockPortfolio)
    closeButton:SetPos(500-25, 0)
    closeButton:SetSize(25, 25)
    closeButton:SetText(" ")

    closeButton.Paint = function(s, w, h)
        draw.SimpleText("X", "STOCKS_Arial30", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    closeButton.DoClick = function()
        StockPortfolio:Remove()
    end

    local scrollPanelPanel = vgui.Create("DPanel", StockPortfolio)
    scrollPanelPanel:SetSize(498, 515)
    scrollPanelPanel:SetPos(1, 55)

    scrollPanelPanel.Paint = nil


    local stocksPanel = vgui.Create( "DScrollPanel", scrollPanelPanel )
    stocksPanel:Dock( FILL )
    

    updatePortfolio = function()
        stocksPanel:Clear() 

        for k, v in pairs(STOCKSYSTEM.BuyedStocksData) do
            if ((v.amount or 0) == 0) then continue end 

            local stocksPanel = stocksPanel:Add( "DButton" )
            stocksPanel:SetText(" ")
            stocksPanel:SetSize(0, 50)
            stocksPanel:Dock( TOP )
            stocksPanel:DockMargin( 0, 0, 0, 5 )

            stocksPanel.Paint = function(s, w, h)
                draw.RoundedBox(0, 0, 0, w, h, colors.subColor)
                draw.SimpleText(STOCKSYSTEM.StockData[k].name .. "\t" .. (STOCKSYSTEM.BuyedStocksData[k].lastTransaction or "NOT RECORDED DATE"), "STOCKS_Arial15", 5, 0)
                draw.SimpleText(STOCKSYSTEM.BuyedStocksData[k].amount .. " " .. STOCKSYSTEM.StockData[k].displayName, "STOCKS_Arial35", 5, 15)
                draw.SimpleText(math.Round(STOCKSYSTEM.BuyedStocksData[k].amount * STOCKSYSTEM.StockData[k].priceHistory[1], 2) .. "$", "STOCKS_Arial35", w-5, h / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end

            stocksPanel.DoClick = function()
                STOCKSYSTEM.Interface.OpenTradingOrder(k)
            end
        end

        timer.Simple(1, function()
            if IsValid(StockPortfolio) then
                updatePortfolio()
            end
        end)

    end

    updatePortfolio()

end

function STOCKSYSTEM.Interface.OpenTransactionHistory()

    local updateTransactionList = {}
    local profit = 0

    local TransactionHistory = vgui.Create("DFrame")
    TransactionHistory:SetParent(STOCKSYSTEM.Interface.MainPanel)
    TransactionHistory:SetSize(550, 250)
    TransactionHistory:Center() 
    TransactionHistory:MakePopup()
    TransactionHistory:ShowCloseButton(false)

    TransactionHistory:SetTitle(" ")

    TransactionHistory.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, colors.panelBackgroundColor)
        draw.RoundedBox(0, 0, 0, w, 25, colors.mainColor)
        draw.SimpleText("Transaction History", "STOCKS_Arial25", 5, 0, colors.categoryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)  
        draw.SimpleText("Session profit: " .. math.Round(profit, 2) .. "$", "STOCKS_Arial20", 210, 5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)        
    end


    local closeButton = vgui.Create("DButton", TransactionHistory)
    closeButton:SetPos(525, 0)
    closeButton:SetSize(25, 25)
    closeButton:SetText(" ")

    closeButton.Paint = function(s, w, h)
        draw.SimpleText("X", "STOCKS_Arial30", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    closeButton.DoClick = function()
        TransactionHistory:Remove()
    end

    local transactionsListPanel = vgui.Create("DPanel", TransactionHistory)
    transactionsListPanel:SetSize(548, 223)
    transactionsListPanel:SetPos(1, 27)
    transactionsListPanel.Paint = nil

    local transactionsList = vgui.Create("DScrollPanel", transactionsListPanel)
    transactionsList:Dock(FILL)
    local sbar = transactionsList:GetVBar()
    sbar:SetSize(0,0)

    updateTransactionList = function()
        profit = 0
        transactionsList:Clear()

        for k, v in pairs(table.Reverse(STOCKSYSTEM.TransactionsHistory)) do
            local transaction = transactionsList:Add( "DButton" )
            transaction:SetText(" ")
            transaction:Dock( TOP )
            transaction:DockMargin( 0, 0, 0, 1 )

            if v.transaction == "Buy" then
                profit = profit - math.Round(v.price * v.amount, 2)
            else 
                profit = profit + math.Round(v.price * v.amount, 2)
            end

            transaction.Paint = function(s, w, h)
                if v.transaction == "Buy" then
                    draw.RoundedBox(0, 0, 0, w, h, colors.buttonBuyActive )
                else
                    draw.RoundedBox(0, 0, 0, w, h, colors.buttonSellActive )
                end 

                draw.SimpleText((string.len(v.issuer) <= 12 and v.issuer or string.sub(v.issuer, 0, 13) .. "..."), "STOCKS_Arial20", 2, h / 2, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(v.amount .. " " .. v.symbol, "STOCKS_Arial20", 165, h / 2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(math.Round(v.price, 2) .. "$", "STOCKS_Arial20", 255, h / 2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(math.Round(v.price * v.amount, 2) .. "$", "STOCKS_Arial20", 330, h / 2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(v.time, "STOCKS_Arial20", 455, h / 2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            transaction.DoClick = function()
                STOCKSYSTEM.Interface.OpenTradingOrder(v.stock, (v.transaction == "Buy"), v.amount)
            end

        end

        timer.Simple(1, function()
            if (IsValid(TransactionHistory)) then
                updateTransactionList()
            end
        end)

    end

    updateTransactionList()

end

function STOCKSYSTEM.Interface.OpenOrderList()

    local updateOrderList = {}

    local OrderList = vgui.Create("DFrame")
    OrderList:SetParent(STOCKSYSTEM.Interface.MainPanel)
    OrderList:SetSize(550, 250)
    OrderList:Center() 
    OrderList:MakePopup()
    OrderList:ShowCloseButton(false)

    OrderList:SetTitle(" ")

    OrderList.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, colors.panelBackgroundColor)
        draw.RoundedBox(0, 0, 0, w, 25, colors.mainColor)
        draw.SimpleText("Order List", "STOCKS_Arial25", 5, 0, colors.categoryText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)      
    end


    local closeButton = vgui.Create("DButton", OrderList)
    closeButton:SetPos(525, 0)
    closeButton:SetSize(25, 25)
    closeButton:SetText(" ")

    closeButton.Paint = function(s, w, h)
        draw.SimpleText("X", "STOCKS_Arial30", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    closeButton.DoClick = function()
        OrderList:Remove()
    end

    local OrderListPanel = vgui.Create("DPanel", OrderList)
    OrderListPanel:SetSize(548, 223)
    OrderListPanel:SetPos(1, 27)
    OrderListPanel.Paint = nil

    local OrderListScroll = vgui.Create("DScrollPanel", OrderList)
    OrderListScroll:Dock(FILL)
    local sbar = OrderListScroll:GetVBar()
    OrderListScroll:SetSize(0,0)

    updateOrderList = function() 
        OrderListScroll:Clear()

        for k, v in pairs(STOCKSYSTEM.CoditionalTransactions) do

            local condition = OrderListScroll:Add( "DButton" )
            condition:SetText(" ")
            condition:Dock( TOP )
            condition:DockMargin( 0, 0, 0, 1 ) 

            condition.Paint = function(s, w, h)
                if v.action == "Buy" then
                    draw.RoundedBox(0, 0, 0, w, h, colors.buttonBuyActive )
                else
                    draw.RoundedBox(0, 0, 0, w, h, colors.buttonSellActive )
                end 

                draw.SimpleText(Format("%s %s %s when price is %s$ - %s", v.action, v.amount, v.symbol, v.targetPrice, v.date), "STOCKS_Arial20", 5, h / 2, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

            end

            condition.DoClick = function()
                STOCKSYSTEM.Interface.ShowDropList(gui.MouseX(), gui.MouseY(), {
                    {
                    displayName = "Delete condition",
                    func = function()
                        table.remove(STOCKSYSTEM.CoditionalTransactions, k)
                    end
                    }
                })
            end

        end

        timer.Simple(1, function()
            if (IsValid(OrderList)) then
                updateOrderList()
            end
        end)

    end

    updateOrderList()

end

function STOCKSYSTEM.Interface.CreateMainPanel()

    if STOCKSYSTEM.Interface.MainPanel then return end
 
    STOCKSYSTEM.Interface.MainPanel = vgui.Create("DFrame")
    STOCKSYSTEM.Interface.MainPanel:SetSize(ScrW(), 44)

    STOCKSYSTEM.Interface.MainPanel:SetTitle("")

    STOCKSYSTEM.Interface.MainPanel:ShowCloseButton(false)

    STOCKSYSTEM.Interface.MainPanel:MakePopup()

    STOCKSYSTEM.Interface.MainPanel.Paint = function(s, w, h)
       draw.RoundedBox(0, 0, 0, w, h, colors.mainColor)
       local time = os.date( "%H:%M:%S - %d/%m/%Y" , os.time() )
       draw.SimpleText(time .. "\t" .. LocalPlayer():Name() .. "\t LI-v0.2", "STOCKS_Arial30", 75, h/2, colors.topMenuColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local menuButton = vgui.Create("DButton", STOCKSYSTEM.Interface.MainPanel)
    menuButton:SetPos(5, 4)
    menuButton:SetSize(40, 36)

    menuButton:SetText("Menu")

    menuButton.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, colors.topMenuColor) 
    end

    menuButton.DoClick = function()
        local mouseX, mouseY = gui.MousePos()

        STOCKSYSTEM.Interface.ShowDropList(mouseX - 5, mouseY - 5, {
            {
                displayName = "Create Window",
                func = function(s1, x, y)
                    
                    STOCKSYSTEM.Interface.ShowDropList(mouseX - 5, mouseY - 5, {
                        {
                            displayName = "Stock Prices",
                            func = function()
                                STOCKSYSTEM.Interface.OpenSharesMenu()
                            end
                        },
                        {
                            displayName = "Stock Portfolio",
                            func = function()
                                STOCKSYSTEM.Interface.OpenStockPortfolio()
                            end
                        },
                        {
                            displayName = "Transaction History",
                            func = function()
                                STOCKSYSTEM.Interface.OpenTransactionHistory()
                            end
                        },
                        {
                            displayName = "Order List",
                            func = function()
                                STOCKSYSTEM.Interface.OpenOrderList()
                            end
                        }
                    })
                    
                end
            },
            {
                displayName = "Exit",
                func = function()
                    STOCKSYSTEM.Interface.MainPanel:Remove()
                    STOCKSYSTEM.Interface.MainPanel = nil
                end
            },
        })

    end

    local closeButton = vgui.Create("DButton", STOCKSYSTEM.Interface.MainPanel)
    closeButton:SetPos(ScrW()-44, 0)
    closeButton:SetSize(44, 44)
    closeButton:SetText(" ")

    closeButton.Paint = function(s, w, h)
        draw.SimpleText("X", "STOCKS_Arial30", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    closeButton.DoClick = function()
        STOCKSYSTEM.Interface.MainPanel:Remove()
        STOCKSYSTEM.Interface.MainPanel = nil
    end

end

function STOCKSYSTEM.Interface.CreateGraph(stock)

    local function max(tbl)
        local max = tbl[1]
        for k, v in pairs(tbl) do
            if (max < v) then max = v end
        end

        return max
    end

    local function min(tbl)
        local min = tbl[1]
        for k, v in pairs(tbl) do
            if (min > v) then min = v end
        end

        return min
    end

    local GraphFrame = vgui.Create("DFrame") 
    GraphFrame:SetSize(ScrW() * 0.45, ScrH() * 0.45) 
    GraphFrame:Center()
    GraphFrame:SetTitle(stock .. " Graph")
    GraphFrame:MakePopup()
    GraphFrame:SetParent(STOCKSYSTEM.Interface.MainPanel)

    local x, y = GraphFrame:GetPos()
    local xS, yS = GraphFrame:GetSize()

    local x1, x2 = 2, xS - 100
    local y1, y2 = 30, yS - ScrH() * 0.01

    local orderButton = vgui.Create("DButton",GraphFrame)
    orderButton:SetPos(x1, y1)
    orderButton:SetSize(x2-x1, y2-y1)
    orderButton:SetText(" ")
    orderButton.Paint = nil

    orderButton.DoClick = function()
        STOCKSYSTEM.Interface.OpenTradingOrder(stock)
    end

    GraphFrame.Paint = function(s, w, h)

        local priceTable = table.Reverse(STOCKSYSTEM.StockData[stock].priceHistory)

        x, y = GraphFrame:GetPos()

        draw.RoundedBox(0,0,0,w,h, colors.panelBackgroundColor)
        draw.RoundedBox(0, x1, y1, x2-x1, y2-y1, colors.mainColor)

        local min, max = min(priceTable) or 0, max(priceTable) or 0
        local distance = (x2 - x1) / (#priceTable - 1)

        
        draw.SimpleText(math.Round(max, 1), "STOCKS_Arial15", x2 + 10, y1, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(math.Round(min, 1), "STOCKS_Arial15", x2 + 10, y2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        if (GraphFrame:IsHovered() or orderButton:IsHovered()) then
            local mX, mY = GraphFrame:LocalCursorPos()
            draw.SimpleText( math.Round(Lerp((mY - y1) / (y2 - y1), max, min), 1 ), "STOCKS_Arial15", x2 + 10, mY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.RoundedBox(0, 0, mY, w, 5, Color(0,0,0,100))
        end

        for k, v in ipairs(priceTable) do
            if (k == #priceTable) then continue end

            cam.Start2D()
                local currentValue = v
                local nextValue = priceTable[k+1]

                surface.SetDrawColor( colors.graphColor )
                surface.DrawLine( x + x1 + distance * (k - 1), y + Lerp((currentValue - min) / (max - min), y2, y1), x + x1 + distance * k, y + Lerp((nextValue - min) / (max - min), y2, y1) )
            cam.End2D()
        end 

    end

end


concommand.Add("li_openteriminal", function()
    STOCKSYSTEM.Interface.CreateMainPanel()
end)

