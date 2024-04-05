#!/usr/bin/python
import argparse, sys, os, subprocess, re

def build_image(docker=False, singularity=False, path=""):
    if docker:
        subprocess.check_call(["docker",
                            "pull",
                            "icbi/hlaii_tools"])
    elif singularity:
        subprocess.check_call(["singularity",
                            "build",
                            "%s/HLAII_tools.sif" % path,
                            "docker://icbi/hlaii_tools"])

def call_docker(read1, read2, sampleID, outDir, indexDir, cores, resume, keep, src, rnaSeq):
    #TODO - optimize
    mountPoint1 = os.path.basename(read1)
    subprocess.check_call(["mkdir",
                            "-p",
                            "%s" % outDir])
    if not read2:
        subprocess.check_call(["docker", 
                        "run",
                        "--rm",
                        "-v", "%s:/mnt/data/%s" % (read1, mountPoint1),
                        "-v", "%s:/mnt/out/" % outDir,
                        "-v", "%s:/mnt/index/"% indexDir,
                        "-v", "%s/HLA_LA_graphs/PRG_MHC_GRCh38_withIMGT/:/opt/conda/opt/hla-la/graphs/" % indexDir,
                        "-v", "%s/arcasHLA_db/dat/:/usr/local/bin/source/arcasHLA/dat/" % indexDir,
                        "icbi/hlaii_tools",
                        "hlaii_typing",
                        "-1", "/mnt/data/%s" % mountPoint1,
                        "-o", "/mnt/out/",
                        "-g", "/mnt/index/",
                        "-n", "%s" % cores,
                        "-d", "%s" % sampleID,
                        "-l", "%s" % outDir,
                        "-r", "%s" % resume,
                        "-k", "%s" % keep,
                        "-S", "%s" % src,
                        "-p", "%s" % rnaSeq])
    else:
        mountPoint2 = os.path.basename(read2)
        subprocess.check_call(["docker", 
                        "run",
                        "--rm",
                        "-v", "%s:/mnt/data/%s" % (read1, mountPoint1),
                        "-v", "%s:/mnt/data/%s" % (read2, mountPoint2),
                        "-v", "%s:/mnt/out/" % outDir,
                        "-v", "%s:/mnt/index/" % indexDir,
                        "-v", "%s/HLA_LA_graphs/PRG_MHC_GRCh38_withIMGT/:/opt/conda/opt/hla-la/graphs/" % indexDir,
                        "-v", "%s/arcasHLA_db/dat/:/usr/local/bin/source/arcasHLA/dat/" % indexDir,
                        "icbi/hlaii_tools",
                        "hlaii_typing",
                        "-1", "/mnt/data/%s" % mountPoint1,
                        "-2", "/mnt/data/%s" % mountPoint2,
                        "-o", "/mnt/out/",
                        "-g", "/mnt/index/",
                        "-n", "%s" % cores,
                        "-d", "%s" % sampleID,
                        "-l", "%s" % outDir,
                        "-r", "%s" % resume,
                        "-k", "%s" % keep,
                        "-S", "%s" % src,
                        "-p", "%s" % rnaSeq])

def call_singularity(read1, read2, sampleID, outDir, indexDir, workDir, cores, resume, keep, src, rnaSeq):
    #TODO - optimize
    mountPoint1 = os.path.basename(read1)
    subprocess.check_call(["mkdir", 
                        "-p", 
                        "%s" % outDir])

    subprocess.check_call(["cd",
                        "%s" % outDir])

    if not read2:
        subprocess.check_call(["singularity", 
                        "exec",
                        "--no-home",
                        "-B", "%s:/mnt/data/%s" % (read1, mountPoint1),
                        "-B", "%s:/mnt/out/" % outDir,
                        "-B", "%s:%s" % (outDir, outDir),
                        "-B", "%s:/mnt/index/" % indexDir,
                        "-B", "%s/HLA_LA_graphs/PRG_MHC_GRCh38_withIMGT/:/opt/conda/opt/hla-la/graphs/" % indexDir,
                        "-B", "%s/arcasHLA_db/dat/:/usr/local/bin/source/arcasHLA/dat/" % indexDir,
                        "%s/HLAII_tools.sif" % workDir,
                        "hlaii_typing",
                        "-1", "/mnt/data/%s" % mountPoint1,
                        "-o", "/mnt/out/",
                        "-g", "/mnt/index/",
                        "-n", "%s" % cores,
                        "-d", "%s" % sampleID,
                        "-l", "%s" % outDir,
                        "-r", "%s" % resume,
                        "-k", "%s" % keep,
                        "-S", "%s" % src,
                        "-p", "%s" % rnaSeq])
    else:
        mountPoint2 = os.path.basename(read2)
        subprocess.check_call(["singularity", 
                        "exec",
                        "--no-home",
                        "-B", "%s:/mnt/data/%s" % (read1, mountPoint1),
                        "-B", "%s:/mnt/data/%s" % (read2, mountPoint2),
                        "-B", "%s:/mnt/out/" % outDir,
                        "-B", "%s:%s" % (outDir, outDir),
                        "-B", "%s:/mnt/index/" % indexDir,
                        "-B", "%s/HLA_LA_graphs/PRG_MHC_GRCh38_withIMGT/:/opt/conda/opt/hla-la/graphs/" % indexDir,
                        "-B", "%s/arcasHLA_db/dat/:/usr/local/bin/source/arcasHLA/dat/" % indexDir,
                        "%s/HLAII_tools.sif" % workDir,
                        "hlaii_typing",
                        "-1", "/mnt/data/%s" % mountPoint1,
                        "-2", "/mnt/data/%s" % mountPoint2,
                        "-o", "/mnt/out/",
                        "-g", "/mnt/index/",
                        "-n", "%s" % cores,
                        "-d", "%s" % sampleID,
                        "-l", "%s" % outDir,
                        "-r", "%s" % resume,
                        "-k", "%s" % keep,
                        "-S", "%s" % src,
                        "-p", "%s" % rnaSeq])

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-1", "--read1", 
                    help="Forward FASTQ file",
                    required=False)
    parser.add_argument("-2", "--read2", 
                    help="Reverse FASTQ file (Optional)",
                    required=False)
    parser.add_argument("-o", "--outputDir", 
                    help="Path to output directory",
                    required=False)
    parser.add_argument("-r", "--indexDir", 
                    help="Path to reference/index/dictionary directory",
                    required=False)
    parser.add_argument("-c", "--cores", 
                    help="Number of cores",
                    required=False,
                    nargs='?',
                    const=1,
                    type=int)
    parser.add_argument("-i", "--sampleID", 
                    help="Sample identifier",
                    required=False)
    parser.add_argument("-s", "--singularity",
                    help="Invoke singularity to run the pipeline",
                    action="store_true")
    parser.add_argument("-d", "--docker",
                    help="Invoke Docker to run the pipeline",
                    action="store_true")
    parser.add_argument("-b", "--build_image",
                    help="Build the image (choose between singularity or Docker)",
                    action="store_true")
    parser.add_argument("-R", "--resume",
                    help="Resume pipeline",
                    action="store_true")
    parser.add_argument("-k", "--keep",
                    help="Keep BAM files (default: false)",
                    action="store_true",
                    required=False)
    parser.add_argument("--RNAseq",
                    help="Process RNAseq data (default: false)",
                    action="store_true",
                    required=False)

    args = parser.parse_args()
    srcDir = os.path.dirname(os.path.abspath(__file__))
    workDir = os.path.dirname(os.path.realpath(__file__))

    if args.build_image:
        if args.singularity and args.docker:
            print("You must choose either singularity or Docker")
        elif args.singularity:
            print("[ HLA II Typing - Building singularity image ]")
            build_image(args.docker, args.singularity, workDir)
        elif args.docker:
            print("[ HLA II Typing - Pulling Docker image ]")
            build_image(args.docker, args.singularity)
        else:
            print("Missing argument: '--docker' or '--singularity")
        sys.exit()


    if args.singularity and args.docker:
        print("Error: You must choose either singularity or Docker")
        print("Exiting ...")
        sys.exit()

    elif args.singularity:
        print("[ HLA II Typing - Running with singularity ]")
        if args.read1 and args.read2:
            call_singularity(args.read1, args.read2, args.sampleID, args.outputDir, args.indexDir, workDir, args.cores, args.resume, args.keep, srcDir, args.RNAseq)
        elif args.read1 and not args.read2:
            call_singularity(args.read1, args.read2, args.sampleID, args.outputDir, args.indexDir, workDir, args.cores, args.resume, args.keep, srcDir, args.RNAseq)
        elif args.read2 and not args.read1:
            print("Error: only Read2 provided by the user")
            print("Exiting ...")
            sys.exit()
                
    elif args.docker:
        print("[ HLA II Typing - Running with Docker ]")
        if args.read1 and args.read2:
            call_docker(args.read1, args.read2, args.sampleID, args.outputDir, args.indexDir, args.cores, args.resume, args.keep, srcDir, args.RNAseq)
        elif args.read1 and not args.read2:
            call_docker(args.read1, args.read2, args.sampleID, args.outputDir, args.indexDir, args.cores, args.resume, args.keep, srcDir, args.RNAseq)
        elif args.read2 and not args.read1:
            print("Error: only Read2 provided by the user")
            print("Exiting ...")
            sys.exit()
    else:
        print("Missing argument: '--docker' or '--singularity")
        print("Exiting ...")
        sys.exit()
