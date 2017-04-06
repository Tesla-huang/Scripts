#### the data file must has header
args<-commandArgs(T)
data1<-read.table(args[1],sep="\t",header=TRUE)
data2<-read.table(args[2],sep="\t",header=TRUE)
expcol<-args[3]    ###  this expcol was col of exp
tmp1<-cbind(data1[,1],data1[,expcol:ncol(data1)])
tmp2<-cbind(data2[,1],data2[,expcol:ncol(data2)])
nrow1<-nrow(tmp1)
ncol1<-ncol(tmp1)
nrow2<-nrow(tmp2)
ncol2<-ncol(tmp2)
out<-matrix(0,nrow =nrow1*nrow2,ncol=4)
title<-c("Factor1","Factor2","rho","pvalue","fdr")
count=0
for(i in 1:nrow1 )
{
	for(j in 1:nrow2 )
	{
		count<-count+1
		x<-cor.test(as.numeric(tmp1[i,2:ncol1]),as.numeric(tmp2[j,2:ncol2]),method="spearman",exact=TRUE)
		out[count,1]<-as.character(tmp1[i,1])
		out[count,2]<-as.character(tmp2[j,1])
		out[count,4]<-x$p.value
		out[count,3]<-x$estimate
	}
}
fdr<-p.adjust(out[,4],method="fdr",length(out[,4]))
tmp<-cbind(out,fdr)
#dim(tmp)
colnames(tmp)=title
write.table(tmp,file=paste(args[1],args[2],"xls",sep="."),quote=FALSE,row.names=FALSE,sep="\t")
