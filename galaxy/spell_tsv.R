library(readr)
source('/Retip/spell_common.R')

#args <- commandArgs(trailingOnly = TRUE)
#if (length(args) != 5) stop("usage: spell_tsv.R descr-train.h5 model.h5 in.tsv out.tsv dropped.tsv") 

prase = my.options()
opt = parse_args(prase)

if (is.null(opt$desc) | is.null(opt$model) | is.null(opt$inp) | is.null(opt$out)) {
	print_help(prase)
	stop("Missing mandatory inputs")
}

full.data <- read_tsv(opt$inp)
predict <- my.spell(opt$desc,opt$model,full.data,opt$smiles,opt$name,opt$cores)

write_tsv(predict$out,opt$out)
if (!is.null(opt$bad)) { write_tsv(predict$dropped,opt$bad) }
