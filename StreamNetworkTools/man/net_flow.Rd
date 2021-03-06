% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/net_flow.R
\name{net_flow}
\alias{net_flow}
\title{Network Discharge and Veolcity Summary}
\usage{
net_flow(nhdplus_path, vpu, netdelin, Mscale = "N")
}
\arguments{
\item{nhdplus_path}{Directory for NHDPlusV2 files (\code{\link{net_nhdplus}})}

\item{vpu}{NHDPlusV2 Vector Processing Unit}

\item{netdelin}{output from \code{\link{net_delin}}}
}
\value{
\code{data.frame}: \code{$RUNOFFVC} cumulative mean annual runoff
 (mm); \code{$MAQ0001E} Mean Annual discharge (cf); \code{$minMMQ0001E}
 minimum mean monthly discharge; \code{$maxMMQ0001E} maximum mean monthly
 discharge (cf);\code{$covMMQ0001E} coeffficient of variation of mean monthly
 discharge; \code{$V0001E} mean annual velocity (cfs); \code{minMMV0001E}
 minimum mean monthly velocity (cfs) \code{maxMMV0001E} maximum mean monthly
 velocity;\code{covMMV0001E} coefficient of variation in mean monthly velocity
 estimates.
}
\description{
Network flow summaries derived form NHDPlusV2 EROM mean annual and mean
monthly discharge (Q0001E) and velocity (V0001E) estimates
}
\details{
Requires /VPUAttributeExtension directory see (\code{\link{net_nhdplus}})

If M value is supplied, discharge (Q0001E) values are scaled proportionally.
Velocity (V0001E) and RUNOFFVC are values for COMID outlet
\code{\link{net_delin}}
}
\examples{
# identify NHDPlusV2 COMID
a <- net_sample(nhdplus_path = getwd(), vpu = "01", ws_order = 6, n = 5)
# delineate stream network
b <- net_delin(group_comid = as.character(a[,"COMID"]), nhdplus_path = getwd(), vpu = "01")
# derive discharge and velocity estimates
c <- net_flow(netdelin = b, vpu = "01", nhdplus_path = getwd())
}
