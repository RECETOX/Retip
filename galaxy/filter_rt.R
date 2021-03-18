library(readr)
library(argparser)

ds.name = "/annotation"	# xMSAnnotator
p <- arg_parser("filter_rt.R")
p <- add_argument(p,c("--tolerance","--mode","--rt","--rtp","input","output","drop"),
			default=list(10,"absolute","rt","rtp","in.tsv","out.tsv","drop.tsv"),
			help=c("tolerance of RT difference in %",
				"mode of operation: absolute, relative (min-max), order",
				"column with experimental RT", "column with predicted RT",
				"input file", "output file", "dropped file")
)

argv <- parse_args(p,commandArgs(trailingOnly = TRUE))
# if (length(args) != 3) stop("usage: filter_rt.R tolerance in.h5 out.h5") 

rt.name = argv$rt
rtp.name = argv$rtp

full.data <- read_tsv(argv$input)

tol <- as.numeric(argv$tolerance) / 100.

if (is.null(full.data[[rt.name]]) | is.null(full.data[[rtp.name]])) stop(argv$input, ": must contain ",rt.name," and ",rtp.name," columns")

if (argv$mode == "absolute") {
	sel <- abs(full.data[[rt.name]] - full.data[[rtp.name]])/full.data[[rt.name]] < tol
	print("selection:")
	print(sel)
	filtered <- full.data[ sel, ]
	dropped <- full.data[ !sel, ]
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
	full.data$norm_rt <- norm.rt
	print("normalized rt:")
	print(norm.rt)
	norm.rtp <- (full.data[[rtp.name]] - min.rtp)/(max.rtp - min.rtp)
	full.data$norm_rtp <- norm.rtp
	print("normalized rtp:")
	print(norm.rtp)
	sel <- abs(norm.rt - norm.rtp)/norm.rt < tol
	print("selection:")
	print(sel)
	filtered <- full.data[ sel, ]
	dropped <- full.data[ !sel, ]
} else if (argv$mode == "order") {
	order.rt <- rank(full.data[[rt.name]])
	full.data$rt_rank <- order.rt
	order.rtp <- rank(full.data[[rtp.name]])
	full.data$rtp_rank <- order.rtp
	print("rt order:")
	print(order.rt)
	print("rtp order:")
	print(order.rtp)
	sel <- abs(order.rt - order.rtp)/length(order.rt) < tol
	print("selection:")
	print(sel)
	filtered <- full.data[ sel, ]
	dropped <- full.data[ !sel, ]
} else {
	stop("invalid --mode")
}
	
write_tsv(filtered,argv$output)
write_tsv(dropped,argv$drop)
