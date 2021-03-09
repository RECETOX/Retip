library(hdf5r)
source('/Retip/spell_common.R')

# path and dataset name (XXX: hardcoded in xMSAnnotator)

prase = my.options()
opt = parse_args(prase)

if (is.null(opt$desc) | is.null(opt$model) | is.null(opt$inp) | is.null(opt$out) | is.null(opt$ds)) {
	print_help(prase)
	stop("Missing mandatory inputs")
}

ds.name = opt$ds
data.h5 <- H5File$new(opt$inp,mode="r")
data.ds <- data.h5[[ds.name]]
full.data <- data.ds[]

predict <- my.spell(opt$desc,opt$model,full.data,opt$smiles,opt$name,opt$cores)

out=H5File$new(opt$out,mode="w")
out[[ds.name]] <- predict$out
out$close_all()

if (!is.null(opt$bad)) {
	drop=H5File$new(opt$bad,mode="w")
	drop[[ds.name]] <- predict$dropped
	drop$close_all()
}

