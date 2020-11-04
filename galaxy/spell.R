library(Retip)
library(hdf5r)
library(readr)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4) stop("usage: spell.R descr-train.h5 model.h5 in.tsv out.tsv") 

prep.wizard()

desc <- H5File$new(args[1],mode="r")
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

keras <- load_model_hdf5(args[2])

full.data <- read_tsv(args[3])

data <- full.data[,c("Name","InChIKey","SMILES")]
desc <- getCD(data)

rt <- RT.spell(training,desc,model=keras,cesc=preProc)

full.data$RTP <- rt[,"RTP"]

write_tsv(full.data,args[4])
