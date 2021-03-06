% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/net_conflu_utl.R
\name{conflu_dist}
\alias{conflu_dist}
\title{Nearest confluence to sampling point}
\usage{
conflu_dist(netdelin, netconflu, nhdplus_path, vpu)
}
\arguments{
\item{netdelin}{output from \code{net_delin}}

\item{netconflu}{output form \code{net_conflu}}

\item{nhdplus_path}{directory containing NHDPlusV2 \code{net_nhdplus}}

\item{vpu}{NHDPlusV2 Vector Processing Unit}
}
\value{
\code{data.frame}: \code{net.id} unique network identifier;
  \code{group.comid} root COMID for network; \code{vpu} Vector Processing
  Unit; \code{X_trib} and \code{Y_trib} confluence coordinates;
  \code{trib_order} order of COMID downstream of confluence;
  \code{area_ratio} darinage areas ratios (i.e. Triburaty Drainage Area /
  Mainstem Drainage Area); \code{trib_area} drainage area upstream of
  confluence; \code{junction_num} is a concatenation of of strahler stream
  orders of confluence reaches (e.g 11 is concluence of 2 frist orders, and
  23 is a second order joining a thrid order); alpha is the angle of
  (degrees) tributary junction; \code{complex} indicates complex triburaty
  junction, \code{trib_comid} is the comid down stream of confluence;
  \code{dist_km} is distance from sampling point to confluence
}
\description{
Calculates distance to nearest confluence and appends confluence attributes
}
\examples{
# identify NHDPlusV2 COMID
a <- net_sample(nhdplus_path = getwd(), vpu = "01", ws_order = 6, n = 5)
# delineate stream network
b <- net_delin(group_comid = as.character(a[,"COMID"]), nhdplus_path = getwd(), vpu = "01")
# calculate confluence metrics
h <- net_conflu(netdelin = c, vpu = "01", nhdplus_path = getwd())
j <- conflu_dist(netdelin = b, netconflu = h, vpu = "01", nhdplus_path = getwd())

}
