library(Retip)
library(hdf5r)

ds.name = "/annotation"	# xMSAnnotator

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) stop("usage: filter_rt.R tolerance in.h5 out.h5") 

data.h5 <- H5File$new(args[2],mode="r")
data.ds <- data.h5[[ds.name]]
full.data <- data.ds[]

tol <- as.numeric(args[1]) / 100.

# XXX: hardcoded column names
# rt from xMSAnnotator, rtp from spell_h5.R

filtered <- full.data[ abs(full.data$rt - full.data$rtp)/full.data$rt < tol, ]

out=H5File$new(args[3],mode="w")
out[[ds.name]] <- filtered
out$close_all()
