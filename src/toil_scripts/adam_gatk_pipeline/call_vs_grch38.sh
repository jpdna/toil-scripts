#!/usr/bin/env bash

set -x -v

# Frank Austin Nothaft, fnothaft@berkeley.edu
#
# Pipeline for alt-aware alignment against the GRCh38 build used in the 1000G vs. b38 recompute,
# followed by preprocessing using ADAM, and variant calling using the HaplotypeCaller.
#
# Precautionary step: Create location where jobStore and tmp files will exist and set TOIL_HOME.

# Execution of pipeline
python -m toil_scripts.adam_gatk_pipeline.align_and_call \
    aws:us-west-2:fnothaft-toil-jobstore \
    --retryCount 3 \
    --uuid SRR062640 \
    --s3_bucket fnothaft-test \
    --file_size 5G \
    --aws_access_key ${BD2K_AWS_ACCESS_KEY_ID} \
    --aws_secret_key ${BD2K_AWS_SECRET_ACCESS_KEY} \
    --ref https://s3-us-west-2.amazonaws.com/cgl-pipeline-inputs/variant_grch38/GRCh38_full_analysis_set_plus_decoy_hla.fa \
    --amb https://s3-us-west-2.amazonaws.com/cgl-pipeline-inputs/variant_grch38/GRCh38_full_analysis_set_plus_decoy_hla.fa.amb \
    --ann https://s3-us-west-2.amazonaws.com/cgl-pipeline-inputs/variant_grch38/GRCh38_full_analysis_set_plus_decoy_hla.fa.ann \
    --bwt https://s3-us-west-2.amazonaws.com/cgl-pipeline-inputs/variant_grch38/GRCh38_full_analysis_set_plus_decoy_hla.fa.bwt \
    --pac https://s3-us-west-2.amazonaws.com/cgl-pipeline-inputs/variant_grch38/GRCh38_full_analysis_set_plus_decoy_hla.fa.pac \
    --sa https://s3-us-west-2.amazonaws.com/cgl-pipeline-inputs/variant_grch38/GRCh38_full_analysis_set_plus_decoy_hla.fa.sa \
    --fai https://s3-us-west-2.amazonaws.com/cgl-pipeline-inputs/variant_grch38/GRCh38_full_analysis_set_plus_decoy_hla.fa.fai \
    --alt https://s3-us-west-2.amazonaws.com/cgl-pipeline-inputs/variant_grch38/GRCh38_full_analysis_set_plus_decoy_hla.fa.alt \
    --use_bwakit \
    --num_nodes 1 \
    --known_SNPs s3://cgl-pipeline-inputs/variant_grch38/ALL_20141222.dbSNP142_human_GRCh38.snps.vcf \
    --driver_memory 50g \
    --executor_memory 50g \
    --phase s3://cgl-pipeline-inputs/variant_grch38/ALL.wgs.1000G_phase3.GRCh38.ncbi_remapper.20150424.shapeit2_indels.vcf.gz \
    --mills s3://cgl-pipeline-inputs/variant_grch38/Mills_and_1000G_gold_standard.indels.b38.primary_assembly.vcf.gz \
    --dbsnp s3://cgl-pipeline-inputs/variant_grch38/ALL_20141222.dbSNP142_human_GRCh38.snps.vcf.gz \
    --omni s3://cgl-pipeline-inputs/variant_grch38/ALL.wgs.1000G_phase3.GRCh38.ncbi_remapper.20150424.shapeit2_indels.vcf.gz \
    --hapmap s3://cgl-pipeline-inputs/variant_grch38/ALL_20141222.dbSNP142_human_GRCh38.snps.vcf.gz \
    --batchSystem=mesos \
    --mesosMaster $(hostname -i):5050 \
    --workDir /var/lib/toil 
