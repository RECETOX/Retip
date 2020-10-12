library(Retip)
library(hdf5r)
library(argparser)

ds.name = "/annotation"	# xMSAnnotator
rt.name = "rt"
rtp.name = "rtp"

p <- arg_parser("filter_rt.R")
p <- add_argument(p,c("--tolerance","--mode","input","output"),
			default=list(10,"absolute","in.h5","out.h5"),
			help=c("tolerance of RT difference in %",
				"mode of operation: absolute, relative (min-max), order",
				"input file", "output file")
)

argv <- parse_args(p,commandArgs(trailingOnly = TRUE))
# if (length(args) != 3) stop("usage: filter_rt.R tolerance in.h5 out.h5") 

data.h5 <- H5File$new(argv$input,mode="r")
data.ds <- data.h5[[ds.name]]
full.data <- data.ds[]

tol <- as.numeric(argv$tolerance) / 100.

# XXX: hardcoded column names
# rt from xMSAnnotator, rtp from spell_h5.R

if (is.null(full.data[[rt.name]]) | is.null(full.data[[rtp.name]])) stop(argv$input, ": must contain ",rt.name," and ",rtp.name," columns")

if (argv$mode == "absolute") {
	sel <- abs(full.data[[rt.name]] - full.data[[rtp.name]])/full.data[[rt.name]] < tol
	print("selection:")
	print(sel)
	filtered <- full.data[ sel, ]
} else if (argv$mode == "relative") {
	min.rt <- min(full.data[[rt.name]])
	max.rt <- max(full.data[[rt.name]])
	min.rtp <- min(full.data[[rtp.name]])
	max.rtp <- max(full.data[[rtp.name]])

# debug hack
#	min.rt <- min.rt - 3
#	min.rtp <- min.rtp - .2

	if (min.rt == max.rt | min.rtp == max.rtp) stop("relative mission impossible, min == max")

	norm.rt <- (full.data[[rt.name]] - min.rt)/(max.rt - min.rt)
	print("normalized rt:")
	print(norm.rt)
	norm.rtp <- (full.data[[rtp.name]] - min.rtp)/(max.rtp - min.rtp)
	print("normalized rtp:")
	print(norm.rtp)
	sel <- abs(norm.rt - norm.rtp)/norm.rt < tol
	print("selection:")
	print(sel)
	filtered <- full.data[ sel, ]
} else if (argv$mode == "order") {
	order.rt <- sort.list(full.data[[rt.name]])
	order.rtp <- sort.list(full.data[[rtp.name]])
	print("rt order:")
	print(order.rt)
	print("rtp order:")
	print(order.rtp)
	sel <- abs(order.rt - order.rtp)/length(order.rt) < tol
	print("selection:")
	print(sel)
	filtered <- full.data[ sel, ]
} else {
	stop("invalid --mode")
}
	

out=H5File$new(argv$output,mode="w")
out[[ds.name]] <- filtered
out$close_all()
