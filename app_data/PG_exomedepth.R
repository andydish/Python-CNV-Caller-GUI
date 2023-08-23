print("Starting R Script")
options(repos = "https://cran.rstudio.com/")

if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install("GenomicAlignments")
if (!require("Rsamtools", quietly = TRUE))
  BiocManager::install("Rsamtools")
if (!require("ExomeDepth", quietly = TRUE))
  install.packages("ExomeDepth")
if (!require("data.table", quietly = TRUE))
  install.packages("data.table")

library(data.table)
library(Rsamtools)
library(ExomeDepth)

# print the versions of libraries
# List of all attached (i.e., loaded) packages
print("Used R packages and versions:")
attached_packages <- search()

# Loop through all packages and print their versions
for(package_name in attached_packages) {
  # The package name is often prefixed with "package:", which we need to remove
  package_name <- sub("package:", "", package_name)
  
  # Not all items in the search path are packages (e.g., ".GlobalEnv"); only print versions of actual packages
  if (package_name %in% rownames(installed.packages())) {
    print(paste(package_name, packageVersion(package_name), sep=": "))
  }
}


# using our custom paneldesign, each amplicon is an "exon"
exon.data = read.csv('app_data/cgx_panel_for_exomedepth.csv')

# loading the elements from the file into a df with info on panel design
bed.data <- data.table(chromosome = exon.data$chromosome, 
                       start = exon.data$start, 
                       end = exon.data$end,
                       names = exon.data$name)

# Open the file from python
file_connection <- file("app_data/path_file.txt", open = "r")

# Read the first line
analysis.name <- readLines(file_connection, n = 1)
ref.directory <- readLines(file_connection, n = 1)
test.directory <- readLines(file_connection, n = 1)

# Close the connection
close(file_connection)

# make results var
results.dir = paste0("app_data/cnv_results/",analysis.name)
# make the analysis directory
dir.create(results.dir)

# make bam.files and check if bai files have been made
bam.ref <- list.files(ref.directory, pattern = "\\.bam$", full.names = TRUE)
bam.test <- list.files(test.directory, pattern = "\\.bam$", full.names = TRUE)
# combine above for bai generation
bam.files <- c(bam.ref, bam.test)

# Index the bams
for (bam in bam.files) {
  bai_file <- paste0(bam, ".bai")
  
  if (!file.exists(bai_file)) {
    print(paste("Indexing", bam))
    indexBam(bam)
  } else {
    print(paste("Skipping", bam, "- .bai file already exists."))
  }
}

### THIS TAKES A WHILE
## make reference counts
my.ref.counts <- getBamCounts(bed.frame = exon.data,
                              bam.files = bam.ref,
                              min.mapq = 20,
                              include.chr = FALSE)

# save for compliance
save(my.ref.counts, file = paste0(results.dir,"/my.ref.counts_",analysis.name))

# make counts into a data frame
my.ref.counts.dafr <- as(my.ref.counts[, colnames(my.ref.counts)], 'data.frame')

# remove chr from chromosome
my.ref.counts.dafr$chromosome <- gsub(as.character(my.ref.counts.dafr$chromosome),
                                      pattern = 'chr',
                                      replacement = '')

# get ref sample names
my.ref.samples<-colnames(my.ref.counts.dafr)[5:(ncol(my.ref.counts.dafr))]

print(head(my.ref.counts.dafr))

## make test counts
my.test.counts <- getBamCounts(bed.frame = exon.data,
                              bam.files = bam.test,
                              min.mapq = 20,
                              include.chr = FALSE)

# save for compliance
save(my.test.counts, file = paste0(results.dir,"/my.test.counts_",analysis.name))

# make counts into a data frame
my.test.counts.dafr <- as(my.test.counts[, colnames(my.test.counts)], 'data.frame')

# remove chr from chromosome
my.test.counts.dafr$chromosome <- gsub(as.character(my.test.counts.dafr$chromosome),
                                       pattern = 'chr',
                                       replacement = '')

print(head(my.test.counts.dafr))

# make a matrix with element names as the test sample names using the dataframe 
samplecounts.mat<-as.matrix(my.test.counts.dafr[,grep(names(my.test.counts.dafr),pattern='*.bam')])
# get number of samples
nsamples<-ncol(samplecounts.mat)


# make df to save
results <- data.frame()

# make vec to hold failed analyses
no_sig_samps <- c()

for (test in 1:nsamples){
  # this gets the col name by using test + 4 as a numeric locator for the col number
  # then splits the file name by _ and takes everything in front of the first _
  sample_filename <- colnames(my.test.counts.dafr)[test + 4]
  
  sample_fullname <- sub("\\.bam$", "", sample_filename)
  
  sample_name <- strsplit(sample_filename, "_")[[1]][1]
  
  #skip if test is null
  if (is.null(test)){
    print(paste(test,' is NULL!'))
    next
  }
  
  my.reference.set <- as.matrix(my.ref.counts.dafr[,my.ref.samples])
  my.choice <- select.reference.set (test.counts = samplecounts.mat[,test],
                                     reference.counts = (my.reference.set),
                                     bin.length = (my.test.counts.dafr$end - my.test.counts.dafr$start)/1000,
                                     n.bins.reduced = 10000)
  
  my.matrix <- as.matrix(my.ref.counts.dafr[, my.choice$reference.choice, drop = FALSE])
  my.reference.selected <- apply(X = my.matrix,
                                 MAR = 1,
                                 FUN = sum)
  message("\n")
  message(paste0('Now creating the ExomeDepth object for ', sample_name))
  message("\n")
  all.exons <- new('ExomeDepth',
                   test = samplecounts.mat[,test],
                   reference = my.reference.selected,
                   formula = 'cbind(test, reference) ~ 1')
  
  # NOTE name is set to exon since we dont have name
  all.exons <- CallCNVs(x = all.exons,
                        transition.probability = 10^-4,
                        chromosome = my.test.counts.dafr$chromosome,
                        start = my.test.counts.dafr$start,
                        end = my.test.counts.dafr$end,
                        name = my.test.counts.dafr$exon)
  
  
  # skip if nothing in there and save to vec to save later
  if (ncol(all.exons@CNV.calls) == 0 && nrow(all.exons@CNV.calls) == 0) {
    no_sig_samps <- c(no_sig_samps, sample_name)
    next
  }
  
  
  # add sample name to df
  all.exons@CNV.calls$sample <- sample_name
  
  # save file path of the sample
  all.exons@CNV.calls$file <- sample_fullname
  
  # TODO get the length of the exons
  all.exons@CNV.calls$cnv_size <- all.exons@CNV.calls$end - all.exons@CNV.calls$start
  
  # add results to dataframe
  results <- rbind(results, all.exons@CNV.calls)
  
  #save results
  output.file <- paste0(results.dir,'/exome_calls-',sample_fullname,'.csv')
  write.csv(file = output.file,
            x = all.exons@CNV.calls,
            row.names = FALSE)
}

# save aggregate results
output.file <- paste0(results.dir,'/all_results','.csv')
write.csv(file = output.file,
          x = results,
          row.names = FALSE)

# save samples without results
output.file <- paste0(results.dir,"/no_significant_CNVs_samples.csv")
write.csv(no_sig_samps, file = output.file, row.names = FALSE)

message("Done!")