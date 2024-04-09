# *HLAII_TypingTools*
A pipeline that will run the following HLA II typing tools (tested on WES data and paired-end only, for now):
* HLA-HD
* HLA-LA (only for paired-end reads)
* xHLA
* arcasHLA
* HLAscan

## *Requirements*
* Python >=3.7
* Singularity or Docker (tested only with singularity)
* The user needs to download/move and use the appropriate reference, index and dictionary files.

## *Usage*

### Pull/build the HLAII typing tools image
```
usage: ./HLAII_typing.py [--build_image] [--singularity or --Docker]
```

### Run
```
usage: ./HLAII_typing.py [-h] [-1 READ1] [-2 READ2] [-o OUTPUTDIR] [-r INDEXDIR]
                       [-c [CORES]] [-i SAMPLEID] [-s] [-d] [-R]
```

```
Arguments:
  -h, --help            show this help message and exit
  -1 READ1, --read1 READ1
                        Forward FASTQ file
  -2 READ2, --read2 READ2
                        Reverse FASTQ file (Optional)
  -o OUTPUTDIR, --outputDir OUTPUTDIR
                        Path to output directory
  -r INDEXDIR, --indexDir INDEXDIR
                        Path to reference/index/dictionary directory
  -c [CORES], --cores [CORES]
                        Number of cores (default: 1)
  -i SAMPLEID, --sampleID SAMPLEID
                        Sample identifier
  -s, --singularity     Invoke singularity to run the pipeline
  -d, --docker          Invoke Docker to run the pipeline
  -R, --resume          Resume pipeline from last checkpoint (default: False)
  -k, --keep            Keep BAM files (default: false)
  --RNAseq              Process RNAseq data (default: false)
```