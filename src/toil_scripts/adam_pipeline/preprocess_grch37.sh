#!/bin/bash

# @author Frank Austin Nothaft fnothaft@berkeley.edu
# @date 2/7/2016
#
# Example pipeline for preprocessing NA12878 high coverage file from
# 1000G using an 8 node Spark cluster on AWS. This assumes an underlying
# 10 node toil cluster of r3.8xlarge instances.
#

region='us-west-2'

python -m toil_scripts.adam_pipeline.spark_toil_script \
    aws:${region}:${jobStore} \
    --input_file_name s3://1000genomes/phase3/data/NA12878/high_coverage_alignment/NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam \
    --num_nodes 8 \
    --output_directory s3://${outputBucket}/ \
    --known_SNPs s3://cgl-pipeline-inputs/variant_b37/dbsnp_132_b37.leftAligned.vcf \
    --aws_access_key ${AWS_ACCESS_KEY_ID} \
    --aws_secret_key ${AWS_SECRET_ACCESS_KEY} \
    --driver_memory 200g \
    --executor_memory 200g \
    --batchSystem=mesos \
    --mesosMaster $(hostname -i):5050
