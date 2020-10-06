library(Retip)
library(hdf5r)
library(readr)

# path and dataset name (XXX: hardcoded in xMSAnnotator)
ds.name = "/annotation"

# column name to hope for SMILES
smiles.name = "compound"

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4) stop("usage: spell_h5.R descr-train.h5 model.h5 in.h5 out.h5") 

prep.wizard()

desc <- H5File$new(args[1],mode="r")
ds <- desc[["/desc"]]
cleanTrain <- ds[]

preProc <- cesc(cleanTrain)
centerTrain <- predict(preProc,cleanTrain)

# must be the same as trainKeras.R
set.seed(815)
toTrain <- caret::createDataPartition(centerTrain$XLogP, p = .8, list = FALSE)
training <- centerTrain[ toTrain,]
testing  <- centerTrain[-toTrain,]

keras <- load_model_hdf5(args[2])

# full.data <- read_tsv(args[3])

data.h5 <- H5File$new(args[3],mode="r")
data.ds <- data.h5[[ds.name]]
full.data <- data.ds[]

data <- full.data[,c(smiles.name,smiles.name,smiles.name)]

# XXX: rename to what Retip expects
names(data) <- c("Name","InChIKey","SMILES")
desc <- getCD(data)

rt <- RT.spell(training,desc,model=keras,cesc=preProc)

full.data$rtp <- rt[,"RTP"]

out=H5File$new(args[4],mode="w")
out[[ds.name]] <- full.data
out$close_all()

