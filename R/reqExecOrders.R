
.reqExecOrders <- function(conn, reqId="0", executionFilter) {
  if(!is.twsConnection(conn))
    stop("invalid 'twsConnection' object") 
  
  socketcon <- conn[[1]]
  
  VERSION <- "3"
  outgoing <- c(.twsOutgoingMSG$REQ_EXECUTIONS,
                VERSION,
                as.character(reqId),
                executionFilter$clientId,
                executionFilter$acctCode,
                executionFilter$time,
                executionFilter$symbol,
                executionFilter$secType,
                executionFilter$exchange,
                executionFilter$side)
  
  writeBin(outgoing, socketcon)
}


reqExecOrders <- function (conn,
                           reqId="0", 
                           executionFilter,
                           verbose=FALSE,
                           ...) {
  
  ## validate the connection object
  if (!is.twsConnection(conn)) stop('invalid twsConnection object.');
  if (!isConnected(conn)) stop('peer has gone away. check your IB connection',call.=F);
  
  .reqExecOrders(conn, reqId, executionFilter)
    
  #on.exit(.myReqExecutions(conn, "0", executionFilter))
  
  socketcon <- conn[[1]]
  eW <- eWrapper(NULL)
    
  eW$execDetails <- function(curMsg, msg, file, ...) {
    version = msg[1]
    reqId   = msg[2]
    orderId   = msg[3]
    eed <- list(
      contract   = twsContract(
        conId   = msg[4],
        symbol  = msg[5],
        sectype = msg[6],
        expiry  = msg[7],
        strike  = msg[8],
        right   = msg[9],
        exch    = msg[10],
        currency= msg[11],
        local   = msg[12],
        # the following are required to correctly specify a contract
        combo_legs_desc = NULL,
        primary = NULL,
        include_expired = NULL,
        comboleg = NULL,
        multiplier = NULL
      ),
      execution  = twsExecution(orderId = orderId,
                                execId  = msg[13],
                                time    = msg[14],
                                acctNumber = msg[15],
                                exchange   = msg[16],
                                side       = msg[17],
                                shares     = msg[18],
                                price      = msg[19],
                                permId     = msg[20],
                                clientId   = msg[21],
                                liquidation= msg[22],
                                cumQty     = msg[23],
                                avgPrice   = msg[24]
      )
    )
    eed <- structure(eed, class="eventExecutionData")
    eed
  }

  execList <- list();  
  while (TRUE) {
    socketSelect(list(socketcon), FALSE, NULL)
    curMsg <- readBin(socketcon, character(), 1L)
  
    res <- processMsg(curMsg, socketcon, eWrapper=eW, twsconn=conn, timestamp=NULL, file='');
    
    if (curMsg == .twsIncomingMSG$ERR_MSG) {
      drainSocket(socketcon, verbose)
      #if(!errorHandler(socketcon, verbose, OK=c(165,300,366,2104,2106,2107))) {
      #  on.exit()
      #  invisible(return())
      #}
    };
    
    ## check for data
    if (curMsg == .twsIncomingMSG$EXECUTION_DATA)
      execList[[length(execList)+1L]] <- res;
    
    ## check for completion
    if (curMsg == .twsIncomingMSG$EXECUTION_DATA_END) 
      break;
  }
  execList
}
