args<-commandArgs(T)
mat <- read.table(args[1], header = F)
png(paste(args[1],".random.png",sep=""))
plot(mat$V1, mat$V2, type="s", xlab="percentile of gene body(5'->3')", ylab="reads number", ylim=c(0, max(mat$V2)))
dev.off()
