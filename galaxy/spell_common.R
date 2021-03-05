my.spell <- function(desc.f,model.f,full.data,smiles.col,name.col,cores=1) {

	library(Retip)
	library(hdf5r)
	library(readr)
	
	columns = c(name.col, name.col, smiles.col)
	
	prep.wizard()
	
	desc <- H5File$new(desc.f,mode="r")
	ds <- desc[["/desc"]]
	cleanTrain <- ds[]
	cleanTrain$SMILES <- NULL
	
	preProc <- cesc(cleanTrain)
	centerTrain <- predict(preProc,cleanTrain)
	
	# must be the same as trainKeras.R
	set.seed(815)
	toTrain <- caret::createDataPartition(centerTrain$XLogP, p = .8, list = FALSE)
	training <- centerTrain[ toTrain,]
	testing  <- centerTrain[-toTrain,]
	
	keras <- load_model_hdf5(model.f)
	
	data <- full.data[,columns]

# XXX: make getCD() shut up; only SMILES column matters
	names(data) <- c("Name","InChIKey","SMILES")

	desc <- getCD(data,cores)
	
	rt <- RT.spell(training,desc,model=keras,cesc=preProc)
	
	good <- which(full.data[[name.col]] %in% rt$Name)
	out.data <- full.data[good,]
	dropped.data <- full.data[-good,]
	
	out.data$rtp <- rt[,"RTP"]
	
	print(paste0("input rows: ",nrow(full.data)))
	print(paste0("descriptors computed: ",nrow(desc)))
	print(paste0("RT predicted: ",nrow(rt)))
	print(paste0("output rows: ",nrow(out.data)))
	
	return(list("out"=out.data,"dropped"=dropped.data))
}


my.options <- function() {
	library(optparse)
	return(OptionParser(option_list = list(
		make_option("--name",type="character",default="recetox_cid",help="name of column to identify compound"),
		make_option("--smiles",type="character",default="qsar_smiles",help="name of column with SMILES"),
		make_option("--desc",type="character",default=NULL,help="Retip chemical descriptors"),
		make_option("--model",type="character",default=NULL,help="Retip model"),
		make_option("--inp",type="character",default=NULL,help="input list of compounds"),
		make_option("--out",type="character",default=NULL,help="output list of compounds with RT predictions"),
		make_option("--bad",type="character",default=NULL,help="output list of compounds for which RT predictions failed"),
		make_option("--cores",type="integer",default=1,help="number of cores to use")
	)))
}
