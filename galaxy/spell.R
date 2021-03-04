library(Retip)
library(hdf5r)
library(readr)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4) stop("usage: spell.R descr-train.h5 model.h5 in.tsv out.tsv") 

columns = c("molecular_formula","molecular_formula","qsar_smiles")

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

data <- full.data[,columns]
names(data) <- c("Name","InChIKey","SMILES")
desc <- getCD(data)

rt <- RT.spell(training,desc,model=keras,cesc=preProc)

good <- which(full.data$molecular_formula %in% rt$Name)
out.data <- full.data[good,]

out.data$rtp <- rt[,"RTP"]

print(paste0("input rows: ",nrow(full.data)))
print(paste0("descriptors computed: ",nrow(desc)))
print(paste0("RT predicted: ",nrow(rt)))
print(paste0("output rows: ",nrow(out.data)))

write_tsv(out.data,args[4])
