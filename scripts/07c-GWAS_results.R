library(Hmisc)
lenU <- function(x) length(unique(x))


genes <- read.csv("data_in/general/180709genesList.csv", as.is=TRUE)
######################################################
#Read in full variants files (i.e., all variants)
######################################################
dfall <- read.csv("data_in/gatk_processed/UgClSeq_snps.txt", as.is=TRUE)
dfall.IND <- read.csv("data_in/gatk_processed/UgClSeq_indels.txt")
allVar <- rbind(dfall, dfall.IND)
allVar <- subset(allVar, numDat >49) #142376
allVar.table <- table(allVar$SNPEFF_GENE_NAME)

######################################################
#Read in variants files (i.e., the possible ST93 variants)
######################################################
var93.dCSF <- read.csv("data_out/variants/var_dCSF.csv")
var93.dCSF$CP <- paste(var93.dCSF$CHROM, var93.dCSF$POS, sep=".")
var93.dCSF$gene <- as.character(var93.dCSF$gene)

var93.dWBC <- read.csv("data_out/variants/var_dWBC.csv")
var93.dWBC$CP <- paste(var93.dWBC$CHROM, var93.dWBC$POS, sep=".")
var93.dWBC$gene <- as.character(var93.dWBC$gene)

######################################################
#Read in significant variants files (i.e., the significant variants)
######################################################
allSigCP <- read.csv("manuscript/tables/TableS6_geneP-allSigCP.csv")
allSigCP$effect <- as.character(allSigCP$effect)
allSigCP$effect[allSigCP$effect == "UTR-5"] <- "upstream"
allSigCP$effect[allSigCP$effect == "UTR-3"] <- "downstream"
allSigCP$effect[allSigCP$effect %in% c("STOP_GAINED", "start+")] <- "ns"
allSigCP$effect[allSigCP$effect%in% c("frameshift", "CODON_INSERTION", "CODON_CHANGE_PLUS_CODON_DELETION")] <- "indel"
allSigCP$CP <- paste(allSigCP$chr, allSigCP$pos, sep=".")
allSigCP$gene <- as.character(allSigCP$gene)

######################################################
#Filter all variants and ST93 variants
######################################################
df <- data.frame(allVar.table)
names(df)[1] <- "gene"
df$gene <- as.character(df$gene)
df <- subset(df, gene %in% var93.dWBC$gene)
df <- cbind(df, table(var93.dWBC$gene))
names(df)[2] <- "allVar"
names(df)[4] <- "ST93var"

#add location information
genes_sub <- subset(genes, name %in% df$gene)
df_genes <- subset(df, gene %in% genes_sub$name) #removes hypothetical RNAs
df_genes <- cbind(chr = genes_sub$chrom, start = genes_sub$chromStart, df_genes)

######################################################
#Table the actually significanat variants
######################################################
allSigCP.noSig <- subset(df_genes, gene %nin% allSigCP$gene)
allSigCP.noSig$ST93sig <- 0

allSigCP.genes <- subset(allSigCP, gene %in% df_genes$gene)
allSigCP.genes_table <- table(allSigCP.genes$gene)
allSigCP.yesSig <- data.frame(allSigCP.genes_table)
names(allSigCP.yesSig) <- c("gene", "ST93sig")

allSigCP_table<- rbind(allSigCP.yesSig, allSigCP.noSig[, c("gene", "ST93sig")])
allSigCP_table$gene  <- as.character(allSigCP_table$gene)

######################################################
#Combine
######################################################
df_genes <- df_genes[order(df_genes$gene), ]
allSigCP_table <- allSigCP_table[order(allSigCP_table$gene),]

df_genes <- cbind(df_genes, allSigCP_table)

#reorder chr properly
df_genes$chr <- factor(df_genes$chr, levels= paste0("chr", 1:14))
df_genes <- df_genes[order(df_genes$chr, df_genes$start), ]

##############################
#FIGURE
##############################
findMid <- function(mid, x){
  for(i in 2:length(x)+1){
    mid[i-1] <- ((x[i]-x[i-1])/2)+x[i-1]
  #  if(i == 1) mid[i+1] <- ((x[i]-start)/2)+x[i-1]
    #if(i == length(x)+1) mid[i] <- ((x[i] - end)/2)+x[i]
    #if(i != length(x)+1) mid[i] <- ((x[i]-x[i-1])/2)+x[i-1]
  }
  mid
}

chrBreaks <- c(1, 31.5, 54.5, 82.5, 93.5, 117.5, 147.5, 180.5, 197.5, 213.5, 227.5, 257.5, 277.5, 285.5, 311)
mid <- c(31.5/2)
chrLab <- findMid(mid, chrBreaks)
chrLab <- chrLab[-15]

df_genes$ST93sig_col <- ifelse(df_genes$ST93sig==0, "white", "red")

#pdf("manuscript/figures/Figure5_sigVar-relativeFreq-all-poten-sig.pdf", width=10, height=4.5)
tiff(filename = "manuscript/figures/Figure5_sigVar-relativeFreq-all-poten-sig.tiff", width = 6, height = 3.5, units = 'in', res = 300, compression = 'lzw', pointsize = 9)
par(mar=c(1,1,1,1), oma=c(3, 6, 1, 1), fig=c(0, 1, 0, 1), mgp=c(1,0.75,0))
plot(seq_along(df_genes$allVar), df_genes$allVar/sum(df_genes$allVar), type="l", lwd=3, ylim=c(0, 0.12), xaxt="n", yaxt="n", xlab="", ylab="")
mtext("Relative frequency\n (number of variants/gene)", side=2, line=3)
axis(2, las=2)
axis(1, at = chrBreaks, labels=FALSE)
points(seq_along(df_genes$allVar), df_genes$ST93var/sum(df_genes$ST93var), type="l", lwd=3, col="grey")
points(seq_along(df_genes$allVar), df_genes$ST93sig/sum(df_genes$ST93sig), type="p", col=df_genes$ST93sig_col, pch=19)
legend("topleft", lty=1, col=c("black", "grey", "red"), legend=c("all sequenced variants", "potentially significant", "significant"), bg="white", lwd=c(3, 2, 1))
#text(x = chrLab-5, y = -0.01, labels=1:14, cex=1, xpd=NA)
text(x = chrLab, y = -0.01, labels=1:14, cex=1, xpd=NA)
#axis(1, at=chrLab[13], "chr13", cex.axis=0.8)
mtext("Position in genome (chromosome)", side=1, line=2)
dev.off()


######################################################
#Look at all significant survival variants
######################################################
geneP.all <-read.csv("data_out/GWAS/180808genePall.csv")

survival <- subset(geneP.all, Survival < 0.05)[,c(1:6, 26, 42:48)] #12
allSigCP_survival <- subset(allSigCP, gene %in% survival$gene)
#all seven genes with significant survival associations were already included
subset(genes, name %in% survival$gene)
