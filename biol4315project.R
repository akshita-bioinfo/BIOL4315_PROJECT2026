# BIOL4315Project

# Concatenate fastq files = fastq (2025) + fastq (2026)
# cat WA.fastq WA_2026.fastq > WA_final.fastq
# cat HU.fastq HU_2026.fastq > HU_final.fastq

# BIOL4315_Project (seq data from last year)

# install packages if req
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

BiocManager::install("Rqc")

# Load required packages
library(Rqc)
library(ggplot2)
library(fastqcr) 
library(QuasR)
library(ShortRead)
library(here)

# check if fastq files exist
files <- list.files("data",
                    pattern = "\\.fastq$",
                    full.names =TRUE)
files

#-------IN BASH: NANOPLOT-------#
# pip install nanoplot
# NanoPlot --fastq data/WA_final.fastq --outdir outputs/WA_nanoplot_report
# NanoPlot --fastq data/HU_final.fastq --outdir outputs/HU_nanoplot_report

#------IN BASH: SEQUALI-------#
# using sequali
# conda activate sequali-env
# sequali --outdir outputs/WAsequali_reports/ data/WA_final.fastq
# sequali --outdir outputs/HUsequali_reports/ data/HU_final.fastq

dir.create(path = "outputs/filtered_files", showWarnings = TRUE)

#----------IN BASH: FILTLONG------#
# using filtlong
# conda activate filtlong_env
# filtlong --keep_percent 75 data/WA_final.fastq > outputs/filtered_files/WA_filtlong_filtered_reads.fastq
# filtlong --keep_percent 75 data/Hu_final.fastq > outputs/filtered_files/HU_filtlong_filtered_reads.fastq

dir.create(path = "outputs/sequali_filtered_files", showWarnings = TRUE)

#---------IN BASH: SEQUALI on FILTERED FILES------#
# Run Sequali over filtered files
# sequali --outdir outputs/sequali_filtered_files/ outputs/filtered_files/WA_filtlong_filtered_reads.fastq
# sequali --outdir outputs/sequali_filtered_files/ outputs/filtered_files/HU_filtlong_filtered_reads.fastq

dir.create(path = "outputs/assembly" , showWarnings = TRUE)

#-------------IN BASH: ASSEMBLY-----------------#
# flye --nano-raw outputs/filtered_files/WA_filtlong_filtered_reads.fastq --out-dir outputs/assembly/WA_flye_output --threads 8 --genome-size 12m
# flye --nano-raw outputs/filtered_files/HU_filtlong_filtered_reads.fastq --out-dir outputs/assembly/HU_flye_output --threads 8 --genome-size 12m

#----------IN BASH: MEDAKA POLISHING------------#
# MAKING REQUIRED DIRECTORIES
# mkdir -p outputs/medaka_round1/WA outputs/medaka_round1/HU outputs/medaka_round2/WA outputs/medaka_round2/HU

# MEDAKA ROUND1 AND ROUND2 FOR WA
# conda activate medaka_final
# medaka_consensus -i data/WA_final.fastq -d outputs/assembly/WA_flye_output/assembly.fasta -o outputs/medaka_round1/WA -t 8
# medaka_consensus -i data/WA_final.fastq -d outputs/medaka_round1/WA/consensus.fasta -o outputs/medaka_round2/WA -t 8

# MEDAKA ROUND1 AND ROUND2 FOR HU
# medaka_consensus -i data/HU_final.fastq -d outputs/assembly/HU_flye_output/assembly.fasta -o outputs/medaka_round1/HU -t 8
# medaka_consensus -i data/HU_final.fastq -d outputs/medaka_round1/HU/consensus.fasta -o outputs/medaka_round2/HU -t 8

#---------IN BASH: ASSEMBLY ANALYSIS------------#
# MAKING REQUIRED DIRECTORIES
# mkdir -p outputs/QUAST_assembly_analysis/WA outputs/QUAST_assembly_analysis/HU 
# mkdir -p outputs/BUSCO_assembly_analysis/WA outputs/BUSCO_assembly_analysis/HU

#_________QUAST (WITHOUT REF)___________#
#_________W.anomalus____________________#
# docker run --rm -v "$(pwd)":/data \
# -w/data quay.io/biocontainers/quast:5.3.0--py313pl5321h5ca1c30_2 \
# quast.py outputs/medaka_round2/WA/consensus.fasta \
# -o outputs/QUAST_assembly_analysis/WA

#__________H.uvarum_____________________#
# docker run --rm -v "$(pwd)":/data \
# -w/data quay.io/biocontainers/quast:5.3.0--py313pl5321h5ca1c30_2 \
# quast.py outputs/medaka_round2/HU/consensus.fasta \
# -o outputs/QUAST_assembly_analysis/HU

#__________QUAST (WITH REF)___________#
#__________W. Anomalus________________#
# docker run --rm -v "$(pwd)":/data -w /data quay.io/biocontainers/quast:5.3.0--py313pl5321h5ca1c30_2 \
# quast.py outputs/medaka_round2/WA/consensus.fasta \
# -r data/WA_ref.fna \
# -o outputs/QUAST_assembly_analysis/WA_ref

#_________H. Uvarum_________________#
# docker run --rm -v "$(pwd)":/data -w /data quay.io/biocontainers/quast:5.3.0--py313pl5321h5ca1c30_2 \
# quast.py outputs/medaka_round2/HU/consensus.fasta \
# -r data/HU_ref.fna \
# -o outputs/QUAST_assembly_analysis/HU_ref

#_____________BUSCO____________________#
#__________W.anomalus__________________#
# docker run --rm -v "$PWD":/data \
# -w /data ezlabgva/busco:v6.0.0_cv1 \
# busco -i outputs/medaka_round2/WA/consensus.fasta \
# -o outputs/busco_output/WA \
# --auto-lineage-euk \
# -m genome -c 8

#_________H.uvarum____________________#
# docker run --rm -v "$PWD":/data \
# -w /data ezlabgva/busco:v6.0.0_cv1 \
# busco -i outputs/medaka_round2/HU/consensus.fasta \
# -o outputs/busco_output/HU \
# --auto-lineage-euk \
# -m genome -c 8

#_________IN BASH: FUNANNOTATE___________#
# PULL DOCKER IMAGE
# docker pull --platform nextgenusfs/funannotate:v1.8.15

#_________CHECKPOINTS (before funannotate)___________#
# docker run --rm --platform linux/amd64 -v "$PWD":/data -e FUNANNOTATE_DB=/data/funannotate_db nextgenusfs/funannotate:v1.8.15 funannotate --version
# asharma033$ docker run --rm --platform linux/amd64 -v "$PWD":/data -e FUNANNOTATE_DB=/data/funannotate_db nextgenusfs/funannotate:v1.8.15 ls /data/funannotate_db

# Install correct busco database
docker run --rm \
--platform linux/amd64 \
-v "$PWD":/data \
-e FUNANNOTATE_DB=/data/
funannotate_db \
nextgenusfs/funannotate:v1.8.15 \
funannotate setup \
-b saccharomycetes \
-d /data/funannotate_db

#______________W.anomalus________________#
# Define reusable variables
# IMAGE="nextgenusfs/funannotate:v1.8.15"
# PLATFORM="--platform linux/amd64"
# CPUS=8
# INPUT="outputs/medaka_round2/WA/consensus.fasta"
# SPECIES="Genus species"   # e.g., "Pichia kluyveri" or "Hanseniaspora uvarum"
# STRAIN="NK1"        # e.g., "RASPBERRY" or "NK1"

# Step 1: Clean redundant/short contigs ("genomic dust")
# docker run -u $(id -u):$(id -g) --rm -v "$PWD":/data -w /data $PLATFORM $IMAGE \
# funannotate clean \
# -i $INPUT \
# -o outputs/funannotate/WA/assembly_clean.fasta

# Step 2: Sort contigs by length and standardize header names (scaffold_1, etc.)
# docker run -u $(id -u):$(id -g) --rm -v "$PWD":/data -w /data $PLATFORM $IMAGE \
# funannotate sort \
# -i outputs/funannotate/WA/assembly_clean.fasta \
# -o outputs/funannotate/WA/assembly_sorted.fasta

# Step 3: Soft-mask repetitive elements
docker run -u $(id -u):$(id -g) --rm -v "$PWD":/data -w /data $PLATFORM $IMAGE \
funannotate mask \
-i  outputs/funannotate/WA/assembly_sorted.fasta \
-o outputs/funannotate/WA/assembly_masked.fasta \
--cpus $CPUS

# Step 4: Predict gene models using Saccharomycetes BUSCO models for training
# docker run -u $(id -u):$(id -g) --rm -v "$PWD":/data -w /data $PLATFORM $IMAGE \
# funannotate predict \
# -i  outputs/funannotate/WA/WA_assembly_masked.fasta \
# -o outputs/funannotate_out/WA \
# -s "$SPECIES" \
# --strain "$STRAIN" \
# --busco_db saccharomycetes \
# --cpus $CPUS

#___________H.uvarum______________________#
# Define reusable variables
# IMAGE="nextgenusfs/funannotate:v1.8.15"
# PLATFORM="--platform linux/amd64"
# CPUS=8
# INPUT="outputs/medaka_round2/HU/consensus.fasta"
# SPECIES="Genus species"   # e.g., "Pichia kluyveri" or "Hanseniaspora uvarum"
# STRAIN="AD"        # e.g., "RASPBERRY" or "NK1"

# Step 1: Clean redundant/short contigs ("genomic dust")
# docker run -u $(id -u):$(id -g) --rm -v "$PWD":/data -w /data $PLATFORM $IMAGE \
# funannotate clean \
# -i $INPUT \
# -o outputs/funannotate/HU/assembly_clean.fasta

# Step 2: Sort contigs by length and standardize header names (scaffold_1, etc.)
# docker run -u $(id -u):$(id -g) --rm -v "$PWD":/data -w /data $PLATFORM $IMAGE \
# funannotate sort \
# -i outputs/funannotate/HU/assembly_clean.fasta \
# -o outputs/funannotate/HU/assembly_sorted.fasta

# Step 3: Soft-mask repetitive elements
# docker run -u $(id -u):$(id -g) --rm -v "$PWD":/data -w /data $PLATFORM $IMAGE \
# funannotate mask \
# -i outputs/funannotate/HU/assembly_sorted.fasta \
# -o outputs/funannotate/HU/assembly_masked.fasta \
# --cpus $CPUS

# Step 4: Predict gene models using Saccharomycetes BUSCO models for training
# docker run -u $(id -u):$(id -g) --rm -v "$PWD":/data -w /data $PLATFORM $IMAGE \
# funannotate predict \
# -i outputs/funannotate/HU/assembly_masked.fasta \
# -o outputs/funannotate_out/HU \
# -s "$SPECIES" \
# --strain "$STRAIN" \
# --busco_db saccharomycetes \
# --cpus $CPUS


# VERSIONS OF TOOLS USED:
# NanoPlot 1.48.0
# Sequali 1.0.2
# Filtlong v0.3.1
# flye 2.9.6-b1802
# medaka 2.2.1