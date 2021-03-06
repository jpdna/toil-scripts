## University of California, Santa Cruz Genomics Institute
### Guide: Running the CGL HG38 RNA-seq Pipeline using Toil

This guide attempts to walk the user through running this pipeline from start to finish. If there are any questions
please contact John Vivian (jtvivian@gmail.com). If you find any errors or corrections please feel free to make a 
pull request.  Feedback of any kind is appreciated.

## Overview
This pipeline accepts URLS (`http://`, `https://`, `ftp://`, `file://` prefixes) of sample **tarfiles**
that contain RNA-seq fastq data files.  It assumes that every fastq file follows the standard of having either 
 **R1** or **R2** in the file name.  If there are several fastq files in the tarfile, (typically in the context 
 of sequencing lanes), they will be concatenated together into one **R1.fq.gz** and one **R2.fq.gz** file.  Note,
 local files follow the syntax of `file://` followed by the full path to that file's location, e.g. 
 `file:///home/ubuntu/sample.tar`.  The exception to this rule is TCGA data, which is downloaded via 
 [Genetorrent](https://cghub.ucsc.edu/software/downloads.html) and instead contains a config file with one analysis
 id per line. 

This pipeline produces a tar.gz file for a given sample that contains:

    RSEM: TPM, FPKM, counts and raw counts (parsed from RSEM output)
    Kallisto: abundance.tsv, abundance.h5, and a JSON of run information
 
The output tarball is *stamped* with the UUID for the sample (e.g. UUID.tar.gz). If a config file is being used, the
UUID is specified on each line per sample, otherwise the UUID is derived from the input file (UUID.tar). 

## Dependencies
This pipeline has been tested on Ubuntu 14.04, but should also run on other unix based systems.  `apt-get` and `pip`
often require `sudo` privilege, so if the below commands fail, try prepending `sudo`.  If you do not have `sudo` 
privileges you will need to build these tools from source, or bug a sysadmin about how to get them (they don't mind). 

#### General Dependencies
    1. Python 2.7
    2. Curl         apt-get install curl
    3. Docker       http://docs.docker.com/engine/installation/

#### Python Dependencies
    1. Toil         pip install toil
    2. S3AM         pip install --pre s3am (optional, needed for uploading output to S3)


## Getting Started
#### Running a single sample locally
Download the toil-scripts repo: `git clone https://github.com/BD2KGenomics/toil-scripts` and 
`cd toil-scripts/rnaseq_cgl`.
    
The bash script `launch_cgl.sh` contains all of the parameters required to run this pipeline, although you 
will likely want to modify a couple lines as it assumes everything will be staged from your home directory.

| Parameter                   | Function                                                                                                                                                                                            |
|-----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|    positional argument      | Path to where the jobStore will exist. The jobStore hosts intermediate files during runtime.                                                                                                        |
| `-c` OR `-d` OR `-s` OR `-g`| `-c` accepts a config file. One sample per line: uuid,url. `-d` is the full path to a dir of samples. `-s` accepts any number of URLs. `-g` accepts a config file. One CGHub analysis id per line   |
| `--retryCount`              | OPTIONAL: Number of times a failed job will retried. Useful for non-systemic failures (HTTP requests, etc)                                                                                          |
| `--ssec`                    | OPTIONAL: Path to a master key if input files are encrypted in S3                                                                                                                                   |
| `--output_dir`              | OPTIONAL: Directory where final output of pipeline will be placed                                                                                                                                   |
| `--s3_dir`                  | OPTIONAL: S3 "Directory" (bucket + directories) where output will be uploaded.                                                                                                                      |
| `--workDir`                 | OPTIONAL: Location where tmp files will be placed during pipeline run. If not used, defaults to TMPDIR environment variable.                                                                        |
| `--sudo`                    | OPTIONAL: Prepends "sudo" to all docker commands. Necessary if user is not a member of a docker group or does not have root privilege                                                               |
| `--restart`                 | OPTIONAL: Restarts pipeline after failure, requires presence of an existing jobStore.                                                                                                               |

For users *outside* of the BD2K group at UC Santa Cruz, here is an example of a modified launch script that assumes the 
RNA-seq sample is local, the user has sudo privilege, and wants the output of the rna-seq pipeline placed locally.

```shell
#!/usr/bin/env bash
# Ensure directory where jobStore and temp files will go exists.
mkdir -p ${HOME}/toil_tmp
# Execution of pipeline
python rnaseq_cgl_pipeline.py \
${HOME}/toil_tmp/jstore \
--retryCount 2 \
--sample_urls file:///full/path/to/sample.tar \
--output_dir ${HOME}/rnaseq_output \
--workDir ${HOME}/toil_tmp \
--sudo 
```

The positional argument (location of the jobStore) and the directory set in `--workDir`, need *plenty* of space to store 
intermediate files during pipeline execution.  Change those parameters to point to the appropriate scratch space or
wherever there exists sufficient storage. The servers I have tested on have 700GB of disk space, which is plenty,
but ultimately this is contingent upon sample size.  Also take note that **STAR** uses a lot of memory (RAM). 
A minimum of 40GB of memory is usually necessary to run **STAR**.

#### Running a sample on a batch system (gridEngine, Parasol, etc).
To run your pipeline using the gridEngine batch system, simply add the argument `--batchSystem=gridEngine` to the launch
script.  We currently support Mesos (preferred), Grid Engine, and Parasol. 
 

## Advanced: Running the Pipeline on a Distributed Cloud Cluster (using Mesos)
Download the toil-scripts repo: `git clone https://github.com/BD2KGenomics/toil-scripts` and 
`cd toil-scripts/rnaseq_cgl`.
    
The bash script `launch_cgl_mesos.sh` contains all of the parameters required to run this pipeline.
    
It is outside the scope of this guide to explain how to setup a distributed cloud cluster.  I recommend taking a 
look at the BD2KGenomics tool: [CGCloud](https://github.com/BD2KGenomics/cgcloud), which can setup a distributed 
cloud cluster using the Mesos batch system in AWS.  Please do not direct questions related to CGCloud or 
setting up a distributed cluster to the author of this pipeline. 

A launch script has been prepared that will run on the head node of the Mesos cluster, scheduling jobs to the worker
nodes that exist within the cluster.

```shell
#!/usr/bin/env bash
mkdir -p ${HOME}/toil_mnt
# Execution of pipeline
python rnaseq_cgl_pipeline.py \
${HOME}/toil_mnt/jstore \
--config rnaseq_cgl_config.csv \
--retryCount 2 \
--ssec /home/mesosbox/shared/master.key \
--s3_dir cgl-driver-projects/test/rna_cgl-test/ \
--sseKey=/home/mesosbox/shared/master.key \
--batchSystem="mesos" \
--mesosMaster mesos-master:5050 \
--workDir=/var/lib/toil 
```

Explanation of additional parameters

| Parameter            | Function                                                                                                                 |
|----------------------|--------------------------------------------------------------------------------------------------------------------------|
| positional argument  | This now points to an AWS jobStore                                                                                       |
| `--batchSystem`      | Path to the config csv file OR the sample.tar.  UUID for the sample is based off the filename before the .tar extension. |
| `--masterIP`         | A boilerplate argument that indicates what port to use                                                                   |
| `--sseKey`           | OPTIONAL: Encrypts intermediate files when using cloud jobStore.                                                         |

**NOTE:** Every worker node must have all of the required dependencies, as well as the inputs for the arguments 
`--sseKey`, `--ssec`, and `--config` must be on *every* worker node, otherwise as the pipeline runs, jobs will fail 
as those files will not be found.  If `--s3_dir` is used, a ~/.boto config file with credentials must also be on every
worker.
