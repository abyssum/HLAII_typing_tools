#! /bin/bash

while getopts "1:2::d::o::n::g::l::k::r::p::S::" opt;
do
    case $opt in
    1)    READ1="$OPTARG";;
    2)    READ2="$OPTARG";;
    d)    ID="$OPTARG";;
    o)  OUTDIR="$OPTARG";;
    n)    CORES="$OPTARG";;
    g)    GENOMEDIR="$OPTARG";;
    l)    REALOUT="$OPTARG";;
    k)    KEEPBAM="$OPTARG";;
    r)    RESUME="$OPTARG";;
    p)    RNASEQ="$OPTARG";;
    S)    SRCDIR="$OPTARG";;
    esac
done

# Check for user defined ID, if not get ID from file names
if [ "$ID" != "None" ]; then
    :
else
    ID=$(echo `basename ${READ1##*/} | sed s/.fastq.*//`)
fi

# Resume option
if [ "$RESUME" == 'True' ]; then
    :
else
    if test -d "$OUTDIR/$ID"; then
        rm -r "$OUTDIR/$ID"
    else
        :
    fi
fi

# Get filenames
NAME1=$(echo ${READ1##*/})
NAME2=$(echo ${READ2##*/})

# Create output dirs
BWAOUT="$OUTDIR/$ID/BWA"
HLAHDOUT="$OUTDIR/$ID/HLA_HD"
HLALAOUT="$OUTDIR/$ID/HLA_LA"
XHLAOUT="$OUTDIR/$ID/xHLA"
ARCASHLAOUT="$OUTDIR/$ID/arcasHLA"
HLASCANOUT="$OUTDIR/$ID/HLAscan"
LOGS="$OUTDIR/$ID/LOGS"
OUTFILE="$OUTDIR/$ID/FINAL_RESULT"

mkdir -p $BWAOUT
mkdir -p $HLAHDOUT
mkdir -p $HLALAOUT
mkdir -p $XHLAOUT
mkdir -p $ARCASHLAOUT
mkdir -p $HLASCANOUT
mkdir -p $LOGS
mkdir -p $OUTFILE

echo "command: hlaii_typing.sh -1 $READ1 -2 $READ2 -d $ID -o $OUTDIR -n $CORES -g $GENOMEDIR -l $REALOUT -r $RESUME -S $SRCDIR" > $LOGS/$ID.run.log

if test $READ2; then
    echo " Paired-end reads detected" | sed "s/^/[HLA II Typing] /"
else
    echo " Single-end reads detected" | sed "s/^/[HLA II Typing] /"
fi

# BWA Alignment
if test -f $BWAOUT/$ID.sam; then
    echo " Found BWA mem output - Skipping Alignment with BWA" | sed "s/^/[HLA II Typing] /"
else
    if test $READ2; then
        echo " Processing files $NAME1 - $NAME2" | sed "s/^/[HLA II Typing] /"
        echo " BWA Run started:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
        bwa mem -M -t $CORES \
        $GENOMEDIR/GRCh38.d1.vd1/GRCh38.d1.vd1.fa \
        $READ1 \
        $READ2 \
        > $BWAOUT/$ID.sam 2>$LOGS/$ID.BWA_mem.log
        if [ `echo $?` != 0 ]; then
            echo "An error occured during BWA mem run, check $REALOUT/$ID/LOGS/$ID.BWA_mem.log for more details"
            rm $BWAOUT/$ID.sam
            exit 1
        else
            :
        fi
    else
        echo " Processing file $NAME1" | sed "s/^/[HLA II Typing] /"
        echo " BWA Run started:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
        bwa mem -M -t $CORES \
        $GENOMEDIR/GRCh38.d1.vd1/GRCh38.d1.vd1.fa \
        $READ1 \
        > $BWAOUT/$ID.sam 2>$LOGS/$ID.BWA_mem.log
        if [ `echo $?` != 0 ]; then
            echo "An error occured during BWA mem run, check $REALOUT/$ID/LOGS/$ID.BWA_mem.log for more details"
            rm $BWAOUT/$ID.sam
            exit 1
        else
            :
        fi
    fi    
fi

# Convert SAM to BAM
if test -f $BWAOUT/$ID.bam; then
    echo " Found BAM file - Skipping SAM to BAM convertion" | sed "s/^/[HLA II Typing] /"
else
    echo " Converting SAM to BAM:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
    samtools view -@ $CORES -S -b $BWAOUT/$ID.sam -o $BWAOUT/$ID.bam > $LOGS/$ID.sam_to_bam.log 2>&1
    if [ `echo $?` != 0 ]; then
        echo "An error occured during SAM to BAM convertion, check $REALOUT/$ID/LOGS/$ID.sam_to_bam.log for more details"
        exit 1
    else
        :
    fi
fi

# Sort BAM file
if test -f "$BWAOUT/${ID}_sorted.bam"; then
    echo " Found sorted BAM file - Skipping BAM sorting" | sed "s/^/[HLA II Typing] /"
else
    echo " Sorting BAM file:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
    samtools sort -@ $CORES $BWAOUT/$ID.bam -o "$BWAOUT/${ID}_sorted.bam" > $LOGS/$ID.samtools_sort.log 2>&1
    if [ `echo $?` != 0 ]; then
        echo "An error occured during samtools sort, check $REALOUT/$ID/LOGS/$ID.samtools_sort.log for more details"
        exit 1
    else
        :
    fi
fi

# Index sorted BAM file
if test -f $BWAOUT/${ID}_sorted.bam.bai; then
    echo " Found indexed BAM file - Skipping BAM indexing" | sed "s/^/[HLA II Typing] /"
else
    echo " Indexing sorted BAM file:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
    samtools index -@ $CORES $BWAOUT/${ID}_sorted.bam > $LOGS/$ID.samtools_index.log 2>&1
    if [ `echo $?` != 0 ]; then
        echo "An error occured during samtools index, check $REALOUT/$ID/LOGS/$ID.samtools_index.log for more details"
        exit 1
    else
        :
    fi
fi

# HLA-HD run
if test -f $HLAHDOUT/${ID}/result/${ID}_final.result.txt; then
    echo " Found HLA-HD output - Skipping HLA-HD" | sed "s/^/[HLA II Typing] /"
else
    if test $READ2; then
        echo " HLA-HD run started:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
        hla-hd -t $CORES -m 50 -f /usr/local/bin/source/HLA_HD/hlahd.1.2.1/freq_data \
        $READ1 \
        $READ2 \
        /usr/local/bin/source/HLA_HD/hlahd.1.2.1/HLA_gene.split.txt \
        "$GENOMEDIR/HLA_HD_dict/dictionary" ${ID} \
        $HLAHDOUT > $LOGS/$ID.HLA_HD.log 2>&1
        if [ `echo $?` != 0 ]; then
            echo "An error occured during HLA-HD run, check $REALOUT/$ID/LOGS/$ID.HLA_HD.log for more details"
            exit 1
        else
            :
        fi
        cp $HLAHDOUT/${ID}/result/${ID}_final.result.txt $HLAHDOUT/${ID}/
    else
        echo " HLA-HD run started:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
        hla-hd -t $CORES -m 50 -f /usr/local/bin/source/HLA_HD/hlahd.1.2.1/freq_data \
        $READ1 \
        $READ1 \
        /usr/local/bin/source/HLA_HD/hlahd.1.2.1/HLA_gene.split.txt \
        "$GENOMEDIR/HLA_HD_dict/dictionary" ${ID} \
        $HLAHDOUT > $LOGS/$ID.HLA_HD.log 2>&1
        if [ `echo $?` != 0 ]; then
            echo "An error occured during HLA-HD run, check $REALOUT/$ID/LOGS/$ID.HLA_HD.log for more details"
            exit 1
        else
            :
        fi
    fi
fi

# HLA-LA run
if test -f $HLALAOUT/${ID}/hla/R1_bestguess_G.txt; then
    echo " Found HLA-LA output - Skipping HLA-LA" | sed "s/^/[HLA II Typing] /"
else
    if test $READ2; then
        echo " HLA-LA run started:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
        HLA-LA.pl \
        --BAM $BWAOUT/${ID}_sorted.bam \
        --sampleID ${ID} \
        --maxThreads $CORES \
        --workingDir $HLALAOUT > $LOGS/$ID.HLA_LA.log 2>&1
        if [ `echo $?` != 0 ]; then
            echo "An error occured during HLA-LA run, check $REALOUT/$ID/LOGS/$ID.HLA_LA.log for more details"
            exit 1
        else
            :
        fi
    else
        rm -r $HLALAOUT
    fi
fi

# arcasHLA
if test -f $ARCASHLAOUT/${ID}_sorted.genotype.json; then
    echo " Found arcasHLA output - Skipping arcasHLA extract" | sed "s/^/[HLA II Typing] /"
else
    if test $READ2; then
        ## Extract
        echo " arcasHLA run started:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
        arcasHLA extract \
        $BWAOUT/${ID}_sorted.bam \
        -o $ARCASHLAOUT \
        --paired \
        --unmapped \
        -t $CORES \
        -v > $LOGS/$ID.arcasHLA_extract.log 2>&1
        if [ `echo $?` != 0 ]; then
            echo "An error occured during arcasHLA extract, check $REALOUT/$ID/LOGS/$ID.arcasHLA_extract.log for more details"
            exit 1
        else
            :
        fi
        ## Genotyping
        arcasHLA genotype \
        $ARCASHLAOUT/${ID}_sorted.extracted.1.fq.gz \
        $ARCASHLAOUT/${ID}_sorted.extracted.2.fq.gz \
        -g A,B,C,DPB1,DQB1,DQA1,DRB1,DMA,DMB,DOA,DOB,DRB2,DRB3,DRB4,DRB5,DRB6,DRB7,DRB8,DRB9,E,F,G,H,J,K,L \
        -o $ARCASHLAOUT \
        -t $CORES \
        -v \
        --min_count 1 > $LOGS/$ID.arcasHLA_genotype.log 2>&1
        if [ `echo $?` != 0 ]; then
            echo "An error occured during arcasHLA genotype, check $REALOUT/$ID/LOGS/$ID.arcasHLA_genotype.log for more details"
            exit 1
        else
            :
        fi
    else
        ## Extract
        echo " arcasHLA run started:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
        arcasHLA extract \
        $BWAOUT/${ID}_sorted.bam \
        -o $ARCASHLAOUT \
        --unmapped \
        -t $CORES \
        -v > $LOGS/$ID.arcasHLA_extract.log 2>&1
        if [ `echo $?` != 0 ]; then
            echo "An error occured during arcasHLA extract, check $REALOUT/$ID/LOGS/$ID.arcasHLA_extract.log for more details"
            exit 1
        else
            :
        fi
        ## Genotyping
        arcasHLA genotype \
        $ARCASHLAOUT/${ID}_sorted.extracted.fq.gz \
        -g A,B,C,DPB1,DQB1,DQA1,DRB1,DMA,DMB,DOA,DOB,DRB2,DRB3,DRB4,DRB5,DRB6,DRB7,DRB8,DRB9,E,F,G,H,J,K,L \
        -o $ARCASHLAOUT \
        --single \
        -t $CORES \
        -v \
        --min_count 1 > $LOGS/$ID.arcasHLA_genotype.log 2>&1
        if [ `echo $?` != 0 ]; then
            echo "An error occured during arcasHLA genotype, check $REALOUT/$ID/LOGS/$ID.arcasHLA_genotype.log for more details"
            exit 1
        else
            :
        fi
    fi    
fi

## Partial genotyping
# arcasHLA partial \
# -G $ARCASHLAOUT/${ID}_sorted.genotype.json \
# $ARCASHLAOUT/${ID}_sorted.extracted.1.fq.gz \
# $ARCASHLAOUT/${ID}_sorted.extracted.2.fq.gz > $LOGS/$ID.arcasHLA_partial.log 2>&1
# if [ `echo $?` != 0 ]; then
#     echo "An error occured during arcasHLA partial genotype, check $REALOUT/$ID/LOGS/$ID.arcasHLA_partial.log for more details"
#     exit 1
# else
#     :
# fi
# ## Merge results
# arcasHLA merge \
# --run ${ID} \
# --i $ARCASHLAOUT \
# --o $ARCASHLAOUT/final_result \
# -v > $LOGS/$ID.arcasHLA_merge.log 2>&1
# if [ `echo $?` != 0 ]; then
#     echo "An error occured during arcasHLA merge, check $REALOUT/$ID/LOGS/$ID.arcasHLA_merge.log for more details"
#     exit 1
# else
#     :
# fi

if [ "$RNASEQ" == "True" ]; then
    rm -r $XHLAOUT
    rm -r $HLASCANOUT
else
    # HLAscan
    if test -f "$HLASCANOUT/${ID}_SUCCESS"; then
        echo " Found HLAscan output - Skipping HLAscan" | sed "s/^/[HLA II Typing] /"
    else
        echo " HLAscan run started:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
        for hla in {HLA-A,HLA-B,HLA-C,HLA-DPB1,HLA-DQB1,HLA-DQA1,HLA-DMA,HLA-DMB,HLA-DOA,HLA-DOB,HLA-DRB1,HLA-DRB5,HLA-E,HLA-F,HLA-G}; do
            hla-scan \
            -b $BWAOUT/${ID}_sorted.bam \
            -d $GENOMEDIR/HLAscan_db/HLA-ALL.IMGT \
            -v 38 \
            -t $CORES \
            -g $hla > $HLASCANOUT/${ID}_$hla.report.txt 2>$LOGS/$ID.HLAscan.log
            echo "" > $HLASCANOUT/${ID}_SUCCESS
        done
    fi

    # xHLA run
    if test -f $XHLAOUT/report-${ID}-hla.json; then
        echo " Found xHLA output - Skipping xHLA" | sed "s/^/[HLA II Typing] /"
    else
        echo " xHLA run started:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
        xHLA \
        --sample_id ${ID} \
        --input_bam_path $BWAOUT/${ID}_sorted.bam \
        --delete \
        --output_path $XHLAOUT > $LOGS/$ID.xHLA.log 2>&1
        if [ `echo $?` != 0 ]; then
            echo "An error occured during xHLA run, check $REALOUT/$ID/LOGS/$ID.xHLA.log for more details"
            exit 1
        else
            :
        fi
    fi
fi

# Final output
echo " Creating final output:" `date +"%T"` | sed "s/^/[HLA II Typing] /"

## arcasHLA 
arcasHLA_out="$ARCASHLAOUT/${ID}_sorted.genotype.json"
arcasHLA_res=`cat $arcasHLA_out | tr "," "\n" | sed "s/^.*\[//g" | sed "s/\].*$//g" | sed "s/\"//g" | sed "s/ //g" | uniq | sort | tr "\n", ";"`

## HLA_HD  
HLA_HD_out="$HLAHDOUT/${ID}/result/${ID}_final.result.txt"
HLA_HD_res=`cut -f 2-3 $HLA_HD_out | sed "s/Not typed//g" | sed "s/HLA-//g" | tr "\t" "\n" | sed "s/^-$//" | sed "s/ //g" | sed "/^$/d" | uniq | sort | tr "\n" ";"`

## HLA_LA 
if test $READ2; then
    HLA_LA_out="$HLALAOUT/${ID}/hla/R1_bestguess_G.txt"
    HLA_LA_res=`cat $HLA_LA_out | grep -v Allele - | cut -f 3 | uniq | sort | tr "\n" ";"`
else
    :
fi

if [ "$RNASEQ" == "True" ]; then
    :
else
    ## HLAscan  
    HLAscan_out="$HLASCANOUT/"
    HLAscan_temp="$HLASCANOUT/HLA_temp.txt"
    :> $HLAscan_temp
    for f in `ls $HLAscan_out/*` 
    do
      HLAgene=`echo $f | sed "s/^.*\///" | sed "s/^.*HLA-//" | sed "s/\..*$//"`
      HLAgene="$HLAgene*"
      noHLA=`grep -c "HLAscan cannot determine proper types" $f`
      if [ "$noHLA" -eq "0" ];
      then
        cat $f | grep "\[Type " - | cut -f 2 - | sed "s/^/$HLAgene/g" >> $HLAscan_temp
      fi 
    done
    HLAscan_res=`cat $HLAscan_temp | uniq | sort | tr "\n" ";"`
    rm $HLAscan_temp

    ## xHLA
    xHLA_out="$XHLAOUT/report-${ID}-hla.json"
    xHLA_res=`cat $xHLA_out | tr "\n" " " | sed "s/^.*\[//" | sed "s/\"//g" | tr "," "\n" | sed "s/\].*$//" | sed "s/ //g" | uniq | sort | tr "\n" ";"`
fi

## Final HLA file
:> $OUTFILE/${ID}_final_result.csv
if [ "$RNASEQ" == "True" ]; then
    :
else
    echo "xHLA,$xHLA_res" >> $OUTFILE/${ID}_final_result.csv
    echo "HLAscan,$HLAscan_res" >> $OUTFILE/${ID}_final_result.csv
fi
echo "HLA_HD,$HLA_HD_res" >> $OUTFILE/${ID}_final_result.csv
echo "arcasHLA,$arcasHLA_res" >> $OUTFILE/${ID}_final_result.csv
if test $READ2; then
    echo "HLA_LA,$HLA_LA_res" >> $OUTFILE/${ID}_final_result.csv
else
    :
fi

# House keeping
if [[ "$KEEPBAM" == "False" ]]; then
    rm -r $BWAOUT
else
    :
fi

if test -d "$SRCDIR/hla-${ID}"; then
    rm -r "$SRCDIR/hla-${ID}"
else if test -d "~/hla-${ID}"; then
    rm -r "~/hla-${ID}"
else
    :
fi

echo " Finished:" `date +"%T"` | sed "s/^/[HLA II Typing] /"
echo "[ HLA II Typing - all the results can be found at $REALOUT/$ID/ ]"
