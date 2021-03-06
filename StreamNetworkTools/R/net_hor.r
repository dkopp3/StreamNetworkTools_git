#' Horton Laws
#'
#' calculates network area, length and bifurcation ratios, using (\code{lm(...)})
#'
#' requires /NHDPlusAttributes directory (see \code{net_nhdplus})
#'
#' Horton estimates (\code{$Horton_est}) include network - 1 (i.e \code{$ohm})
#' because a given group.comid, may not include the whole stream order
#'
#' @param netdelin output from \code{net_delin}
#' @param vpu vector processing unit
#' @param nhdplus_path Directory for NHDPlusV2 files (\code{\link{net_nhdplus}}
#'
#' @return named \code{list}: \code{$topology} is data used to estimate horton
#'   laws: \code{$group.comid} root COMID for steam network; \code{$str_ord}
#'   stream order; \code{$str_num} count of stream reaches,\code{str_len} Mean
#'   reach length; \code{str_area} mean drainage area. \code{$horton_est} are
#'   estimated horotn ratios: \code{ohm} is the strahler order of the network -
#'   1 (see \code{Details}. \code{$Rb,$Rl,$Ra} are bifurcation, length and area
#'   ratios, respectively. \code{Rb.r2, Rl.r2, Ra.r2} are R^2 values from
#'   \code{lm(...)}.
#'
#' @examples
#' # identify NHDPlusV2 COMID
#' a <- net_sample(nhdplus_path = getwd(), vpu = "01", ws_order = 6, n = 5)
#' # delineate stream network
#' b <- net_delin(group_comid = as.character(a[,"COMID"]), nhdplus_path = getwd(), vpu = "01")
#' #estimate horton ratios
#' c <- net_hort(netdelin = b, vpu = "01", nhdplus_path = getwd())
#' @export

net_hort<-function (netdelin, vpu, nhdplus_path){

  if(!is.character(vpu)){
    stop("vpu must be character")
  }

  directory<-grep(paste(vpu,"/NHDPlusAttributes",sep=""),
                  list.dirs(nhdplus_path,full.names=T),
                  value = T)

  vaa<-grep("PlusFlowlineVAA.dbf",
            list.files(directory[1], full.names = T),
            value = T)

  vaa<-foreign::read.dbf(vaa)
  names(vaa) <- toupper(names(vaa))

  #M measures and net.id become unnecessary.
  #the focal ohm is the group comid - 1.
  if(any(duplicated(netdelin$Network[, c("group.comid", "net.comid")]))){
    warning ("FYI droping M and net.id values, group.comid is network index")
  }

  full.net <- unique(netdelin$Network[,c("group.comid", "net.comid", "vpu")])

  vaa <- merge(full.net, vaa, by.x = "net.comid", by.y = "COMID")

  warn_mess <- vaa[as.character(vaa[ ,"group.comid"]) ==
                     as.character(vaa[ ,"net.comid"]),
                   c("net.comid","STREAMORDE")]

  #remove diveregences
  vaa <- vaa[vaa[,"STREAMORDE"] == vaa[, "STREAMCALC"], ]
  names(vaa)

  data<-data.frame(group.comid = character(), str_ord = integer(),
                   str_num = integer(), srt_len = numeric(),
                   str_area = numeric())

  hor.laws <- data.frame(group.comid = character(), ohm = numeric(),
                         Rb = numeric(), Rb.r2 = numeric(),
                         Rl = numeric(), Rl.r2 = numeric(),
                         Ra = numeric(), Ra.r2 = numeric())

  for (q in unique(full.net[,"group.comid"])){
    a <- vaa[vaa[,"group.comid"] == q,
             c("group.comid", "net.comid",
               "STREAMORDE", "LEVELPATHI",
               "TONODE", "FROMNODE","HYDROSEQ",
               "TOTDASQKM", "LENGTHKM", "AREASQKM")]

  for (p in unique(a[,"STREAMORDE"])){
    #p<-1
    # z is a list of each flowline of a given order stream order w/ From - To path
    z <- a[a[,"STREAMORDE"] == p, ]
    z <- split(z,list(z[,"LEVELPATHI"],as.character(z[,"group.comid"])))
    TOO <- lapply(z,"[[","TONODE")
    FRO <- lapply(z,"[[","FROMNODE")

    for (i in length(z):1){
      #i<-1
      #with element i, compare tonode to all fromnodes not i
      #upsrt connection
      TOO_ULi <- unlist(TOO[i], use.names=F)
      FRO_UL <- unlist(FRO[-i], use.names = F)
      TOO_ULi <- TOO_ULi[TOO_ULi %in% FRO_UL]

      if(length(TOO_ULi) > 0){
        TOO_ULi<-sapply(lapply(z,"[[",c("FROMNODE")), function(x) x %in% TOO_ULi)
      if(length(dim(TOO_ULi))>0){
        TOO_ULi<-apply(TOO_ULi,2,function(x) any(x))
      } else {
        TOO_ULi<-sapply(TOO_ULi,function(x) any(x))
      }
      z[[ifelse(which(TOO_ULi), names(which(TOO_ULi)))]]["LEVELPATHI"] <- unique(z[[i]]["LEVELPATHI"])
      }

      #with element i, compare fromnodes to all tonodes not i
      #downstr connection
      FRO_ULi <- unlist(FRO[i], use.names = F)
      TOO_UL <- unlist(TOO[-i], use.names = F)
      FRO_ULi <- FRO_ULi[FRO_ULi%in%TOO_UL]

      if(length(FRO_ULi) > 0){
      #which element in -i matches
      FRO_ULi <- sapply(lapply(z, "[[", c("TONODE")), function(x) x %in% FRO_ULi)
      if(length(dim(FRO_ULi)) > 0){
        FRO_ULi <- apply(FRO_ULi, 2, function(x) any(x))
      } else {
        FRO_ULi <- sapply(FRO_ULi, function(x) any(x))
      }
      z[[ifelse(which(FRO_ULi), names(which(FRO_ULi)))]]["LEVELPATHI"] <- unique(z[[i]]["LEVELPATHI"])
      }
    }

    z <- setNames(do.call(rbind.data.frame, z), names(z[[1]]))
    z <- split(z, list(z[, "LEVELPATHI"], as.character(z[, "group.comid"])))

    #spply aggregares list element
    #naming w/comid
    L <- sapply(lapply(z, "[","LENGTHKM"), sum)
    group.comid <- unlist(lapply(strsplit(names(L), "\\."), "[[", 2))
    L <- data.frame(group.comid = group.comid, L = L, row.names = NULL)
    L <- aggregate(L[,"L"],by = list(group.comid = L[,"group.comid"]), mean)
    names(L)[2] <- "str_len"

    #A <- sapply(lapply(z, "[[", "AREASQKM"), sum)
    A <-  sapply(lapply(z, "[[", "TOTDASQKM"), max)
    group.comid <- unlist(lapply(strsplit(names(A), "\\."), "[[", 2))
    A <- data.frame(group.comid = group.comid, A = A, row.names = NULL)
    A <- aggregate(A[,"A"], by = list(group.comid = A[, "group.comid"]), mean)
    names(A)[2] <- "str_area"

    N <- sapply(lapply(z, "[[", 7), length)
    group.comid <- unlist(lapply(strsplit(names(N), "\\."), "[[", 2))
    N <- data.frame(group.comid = group.comid, N = N, row.names = NULL)
    N <- aggregate(N[,"N"], by = list(group.comid = N[, "group.comid"]), length)
    names(N)[2] <- "str_num"

  temp <- Reduce(function(x, y)
    merge(x, y,by = c("group.comid"), all.x = T), list(N, L, A))

  data <- rbind(data, data.frame(str_ord = p, temp))
  }

      horton <- data[data[,"group.comid"] == q, ]
      # drops the comid because it may be incomplete.
      # a 5th order comid could occur in middle of reach
      # also cannot horton ratios from 1 data point...
      # probably should for 2 eiither, especially
      # since we dont know if the comid includes whole path

      if (length(horton[,"group.comid"]) > 2){
        # for instance: Nw=stream number of order w;
        # Rb^ohm-w is bifurcation ratio (i.e. constant)
        # raised to watershed order minus the order (w)
        # thus Nw=Rb^ohm-w #here i estimate that constant value (Rb)
        # take log to linear model
        # log(Nw)= ohm*logRb-w*logRb
        # log(Nw)=log(Rb)*(ohm-w)

        horton <- horton[horton[,"str_ord"] != max(horton[,"str_ord"]), ]
        ohm <- max(horton[, "str_ord"])
        x <- ohm - horton[, "str_ord"]

        # estimate log(Rb) as slope
        lmRb <- summary(lm(log(horton[,"str_num"]) ~ (x)))
        # log(Rb)=0.9367344; log() has default base of exp(1)
        # thus slove for Rb w/base e
        Rb <- exp(lmRb$coefficients["x", 1])
        lmRb.r.squared <- (lmRb$r.squared)

        #Lw=L1*RL^(w-1)
        x <- horton[, "str_ord"] - 1
        L1 <- rep(horton[horton[,"str_ord"] ==1, "str_len"], length(horton[, "str_len"]))
        lmRl <- summary(lm(log(horton[, "str_len"]) ~ log(L1) + (x)))
        Rl <- exp(lmRl$coefficients["x", 1])
        lmRl.r.squared <- (lmRl$r.squared)

        #Aw=A1*RA^(w-1)
        x <- horton[,"str_ord"] - 1
        A1 <- rep(horton[horton[,"str_ord"] == 1, "str_area"], length(horton[, "str_area"]))
        lmRa <- summary(lm(log(horton[, "str_area"]) ~ log(A1) + (x)))
        Ra <- exp(lmRa$coefficients["x", 1])
        lmRa.r.squared <- (lmRa$r.squared)
        group.comid <- q

        out <- data.frame(COMID = group.comid, ohm = ohm,
                          Rb = Rb, Rb.r2 = lmRb.r.squared,
                          Rl = Rl, Rl.r2 = lmRl.r.squared,
                          Ra = Ra, Ra.r2 = lmRa.r.squared)

        hor.laws <- rbind(hor.laws, out)
        } else {
          ohm <- max(horton[,"str_ord"])-1
          out <- data.frame(COMID = q, ohm = ohm,
                            Rb = NA, Rb.r2 = NA,
                            Rl = NA, Rl.r2 = NA,
                            Ra = NA, Ra.r2 = NA)

          hor.laws <- rbind(hor.laws, out)
          }
  }

  names(hor.laws)[1] <- "group.comid"

  data.out <- list(topology = data[,c("group.comid","str_ord", "str_num", "str_len", "str_area")],
                   Horton_est = hor.laws)


  warn <- merge(warn_mess[,c("net.comid","STREAMORDE")],
                hor.laws[,c("group.comid","ohm")],
                by.x = "net.comid", by.y = "group.comid")

  if (any(warn[,"STREAMORDE"]-1 != warn[,"ohm"])){
    #this is caused by incorrect stream order in network
    id<-as.character(warn[warn[,"STREAMORDE"]-1 != warn[,"ohm"], "net.comid"])
    warning(paste("group.comid", id, "estimates may be inaccurate due to incorrect NHDPlusV2 vaa STREAMORDER"))
  }

  return(data.out)
  }
