


parse_open_order <- function(msg, contents, ...) {
  eoo <- list(
    # need to add contractId to twsContract...
    contract   = twsContract(
      conId   = contents[3],
      symbol  = contents[4],
      sectype = contents[5],
      expiry  = contents[6],
      strike  = contents[7],
      right   = contents[8],
      exch    = contents[9],
      currency= contents[10],
      local   = contents[11],
      combo_legs_desc = contents[66],
      # the following are required to correctly specify a contract
      primary = NULL,
      include_expired = NULL,
      comboleg = NULL,
      multiplier = NULL
    ),
    order      = twsOrder(
      orderId = contents[2],
      action  = contents[12],
      totalQuantity = contents[13],
      orderType     = contents[14],
      lmtPrice      = contents[15],
      auxPrice      = contents[16],
      tif           = contents[17],
      ocaGroup      = contents[18],
      account       = contents[19],
      openClose     = contents[20],
      origin        = contents[21],
      orderRef      = contents[22],
      clientId      = contents[23],
      permId        = contents[24],
      outsideRTH    = contents[25],
      hidden        = contents[26],
      discretionaryAmt = contents[27],
      goodAfterTime = contents[28],
      # skip deprecated amount contents[29]
      faGroup       = contents[30],
      faMethod      = contents[31],
      faPercentage  = contents[32],
      faProfile     = contents[33],
      goodTillDate  = contents[34],
      rule80A       = contents[35],
      percentOffset = contents[36],
      settlingFirm  = contents[37],
      shortSaleSlot = contents[38],
      designatedLocation = contents[39],
      auctionStrategy = contents[40],
      startingPrice = contents[41],
      stockRefPrice = contents[42],
      delta         = contents[43],
      stockRangeLower = contents[44],
      stockRangeUpper = contents[45],
      displaySize   = contents[46],
      blockOrder    = contents[47],
      sweepToFill   = contents[48],
      allOrNone     = contents[49],
      minQty        = contents[50],
      ocaType       = contents[51],
      eTradeOnly    = contents[52],
      firmQuoteOnly = contents[53],
      nbboPriceCap  = contents[54],
      parentId      = contents[55],
      triggerMethod = contents[56],
      volatility    = contents[57],
      volatilityType = contents[58],
      deltaNeutralOrderType = contents[59],
      deltaNeutralAuxPrice  = contents[60],
      continuousUpdate = contents[61],
      referencePriceType = contents[62],
      trailStopPrice     = contents[63],
      basisPoints        = contents[64],
      basisPointsType    = contents[65],
      # part of contract #66
      scaleInitLevelSize = contents[67],
      scaleSubsLevelSize = contents[68],
      scalePriceIncrement = contents[69],
      clearingAccount = contents[70],
      clearingIntent  = contents[71],
      notHeld         = contents[72],
      # this contingent on UnderComp Not Yet Available in IBrokers [74+]
      # algoStrategy [75+]
      whatIf          = contents[75]
    )
  )
  #eoo <- structure(eoo, class='eventOpenOrder')
  eoo
}



reqOpenOrderContracts <- function(twsconn) {
  eW <- eWrapper()
  eW$assign.Data('done', FALSE)
  orders <- list()
  eW$assign.Data('openOrders', orders)
  
  eW$openOrder <- function(curMsg, msg, timestamp, file, ...) {
    eos <- parse_open_order(curMsg, msg)
    c(curMsg, msg)
    orders <- eW$get.Data('openOrders')
    orders[[length(orders)+1]] <- eos
    #orders <- append(orders, eos)
    eW$assign.Data('openOrders', orders)
  }
  eW$openOrderEnd <- function(curMsg, msg, timestamp, file, ...) {
    eW$assign.Data('done', TRUE)
    c(curMsg, msg)
  }
  
  .reqOpenOrders(twsconn)
  con <- twsconn[[1]]
  
  while (TRUE) {
    socketSelect(list(con), FALSE, NULL)
    curMsg <- readBin(con, character(), 1L)
    processMsg(curMsg, con, eW)
    
    if(eW$get.Data("done")) {
      break
    }
  }
  
  eW$get.Data('openOrders')
}