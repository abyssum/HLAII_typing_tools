# FROM biocontainers/biocontainers:latest
FROM continuumio/miniconda3:latest

USER root

# Install dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
 	&&  apt-get install -y \
		gcc \
		g++ \
		bzip2 \
		ca-certificates \
		curl \
		git \
		build-essential \
		zlib1g-dev \
		libcurl4-openssl-dev \
		libxml2-dev \
		libssl-dev \
		openssl \
		r-base \
		wget \
		python3-pip \
		python-pip \
		dos2unix \
		vim \
		locales \
		coreutils \
		autoconf \
 	&& apt-get clean \
 	&& rm -rf /var/lib/apt/lists/*

# Fix locales
RUN export LC_ALL=en_US.UTF-8 && \
	export LANG=en_US.UTF-8 && \
	locale-gen en_US.UTF-8
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Install Samtools
# RUN wget https://github.com/samtools/samtools/releases/download/1.3/samtools-1.3.tar.bz2 \
# 	&& tar xjf samtools-1.3.tar.bz2 \
# 	&& cd samtools-1.3 \
# 	&& mv htslib-1.3 temp \
# 	&& wget https://github.com/humanlongevity/htslib/archive/jpiper/1.3-iam-support.zip \
# 	&& unzip 1.3-iam-support.zip \
# 	&& mv htslib-jpiper-1.3-iam-support htslib-1.3 \
# 	&& cd htslib-1.3 && autoconf && ./configure --enable-libcurl && make -j 8 all && cd .. \
# 	&& perl -pi -e 's/^(LIBS\s+=)/\1 -lcurl -lcrypto/' Makefile \
# 	&& make -j 8 \
# 	&& make install \
# 	&& cd .. \
# 	&& rm -rf samtools-1.3*

# # Install BWA for getting reads from 3rd party BAMs
# RUN wget http://downloads.sourceforge.net/project/bio-bwa/bwa-0.7.15.tar.bz2 \
#     --no-check-certificate \
# 	&& tar xjf bwa-0.7.15.tar.bz2 \
# 	&& cd bwa-0.7.15 \
# 	&& make -j 8 \
# 	&& mv bwa /usr/bin/ \
# 	&& cd .. \
# 	&& rm -rf bwa-*

# Install Sambamba for getting reads from 3rd party BAMs
RUN wget https://github.com/lomereiter/sambamba/releases/download/v0.6.6/sambamba_v0.6.6_linux.tar.bz2 \
	&& tar xjf sambamba_v0.6.6_linux.tar.bz2 \
	&& mv sambamba_v0.6.6 /usr/bin/sambamba \
	&& rm sambamba_v0.6.6_linux.tar.bz2

# Install Bedtools for getting reads from 3rd party BAMs
RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.26.0/bedtools-2.26.0.tar.gz \
	&& tar xzf bedtools-2.26.0.tar.gz \
	&& cd bedtools2/ \
	&& make -j 8 \
	&& make install \
	&& cd .. \
	&& rm -rf bedtools*

# Install R required packages
RUN Rscript -e 'install.packages("devtools", repos="http://cran.r-project.org")' && \
	Rscript -e 'devtools::install_version("data.table", "1.11.2", repos="http://cran.r-project.org")' && \
	Rscript -e 'install.packages("lpSolve", repos="http://cran.r-project.org")' && \
	Rscript -e 'source("http://bioconductor.org/biocLite.R"); biocLite("IRanges", ask = F, suppressUpdates = T, suppressAutoUpdate = T)'

# RUN R -e "install.packages('BiocManager', repos='http://cran.r-project.org', clean=TRUE)"
# RUN R -e 'install.packages("data.table", repos="http://cran.r-project.org", clean=TRUE)'
# RUN R -e 'install.packages("lpSolve", repos="http://cran.r-project.org", clean=TRUE)'
# RUN R -e 'BiocManager::install("IRanges")'

# Install Diamond
RUN wget https://github.com/bbuchfink/diamond/releases/download/v0.8.15/diamond-linux64.tar.gz \
	&& tar xzf diamond-linux64.tar.gz \
	&& mv diamond /usr/bin/ \
	&& rm diamond-linux64.tar.gz

# Install xHLA
WORKDIR /usr/local/bin/
ENV PATH /usr/local/bin/:$PATH
ADD ./HLA_master/data/ /usr/local/bin/HLA_master/data/
ADD ./HLA_master/bin/ /usr/local/bin/HLA_master/bin/
ADD ./HLA_master/bin /usr/local/bin/
RUN diamond makedb --in /usr/local/bin/HLA_master/data/hla.faa --db /usr/local/bin/HLA_master/data/hla.dmnd && \
	ln -s /usr/local/bin/HLA_master/bin/run.py /usr/local/bin/xHLA && \
	ln -s /usr/local/bin/HLA_master/data/ /usr/local/ && \
	sed -i -r 's/, type = file/, type = open/g' /usr/local/bin/HLA_master/bin/report.py && \
	sed -i -r 's/, type = file/, type = open/g' /usr/local/bin/report.py
# ADD ./HLA_master/ /usr/local/bin/source/HLA_master/
# WORKDIR /usr/local/bin/source/HLA_master/bin/
# ENV PATH /usr/local/bin/source/HLA_master/bin/:${PATH}
# RUN ln -s /usr/local/bin/source/HLA_master/bin/run.py /usr/local/bin/xHLA

# Install HLA-LA and bowtie2
RUN conda install -c conda-forge -c bioconda hla-la && \
	conda install -c bioconda bowtie2
	# mkdir /opt/conda/opt/hla-la/graphs && \
	# wget http://www.well.ox.ac.uk/downloads/PRG_MHC_GRCh38_withIMGT.tar.gz /opt/conda/opt/hla-la/graphs
ADD ./GRCh38_d1_vd1.txt /opt/conda/opt/hla-la/src/additionalReferences/PRG_MHC_GRCh38_withIMGT/
# RUN /opt/conda/opt/hla-la/bin/HLA-LA --action prepareGraph --PRG_graph_dir /opt/conda/opt/hla-la/src/additionalReferences/PRG_MHC_GRCh38_withIMGT

# Install HLA-HD
WORKDIR /usr/local/bin/
ADD ./HLA_HD/ /usr/local/bin/source/HLA_HD/
WORKDIR /usr/local/bin/source/HLA_HD/hlahd.1.2.1/bin/
ENV PATH /usr/local/bin/source/HLA_HD/hlahd.1.2.1/bin/:${PATH}
RUN ln -s /usr/local/bin/source/HLA_HD/hlahd.1.2.1/bin/hlahd.sh /usr/local/bin/hla-hd

# Install HISAT-genotype
WORKDIR /usr/local/bin/
RUN conda create -n HISAT_genotype python=3.7
# RUN conda activate HISAT_genotype
ENV PATH /opt/conda/envs/HISAT_genotype/bin:$PATH
RUN /bin/bash -c "source activate HISAT_genotype"
RUN git clone --recurse-submodules https://github.com/DaehwanKimLab/hisat-genotype /usr/local/bin/hisatgenotype && \
	cd hisatgenotype/hisat2 && \
	make hisat2-align-s hisat2-build-s hisat2-inspect-s && \
	cd ../ && \
	# dos2unix setup.sh && \
	# sed -i -r 's/sumbodule/submodule/g' setup.sh && \
	bash setup.sh && \
	echo "2.2.1" > /usr/local/bin/hisatgenotype/hisat2/VERSION
WORKDIR /usr/local/bin/hisatgenotype/
ENV PATH /usr/local/bin/hisatgenotype:$PATH
WORKDIR /usr/local/bin/hisatgenotype/hisat2/
ENV PATH /usr/local/bin/hisatgenotype/hisat2:$PATH
WORKDIR /usr/local/bin/hisatgenotype/hisatgenotype_modules/
ENV PYTHONPATH /usr/local/bin/hisatgenotype/hisatgenotype_modules:$PYTHONPATH
WORKDIR /usr/local/bin/

# Install HLAVBseq
ADD ./HLAVBseq /usr/local/bin/HLAVBseq

# Install required python packages
RUN pip3 install biopython awscli requests pytest boto3 logger numpy scipy pandas && \
	pip2 install awscli requests pytest boto3 logger

# Install arcasHLA
RUN conda install -c anaconda pigz && \
	conda install -c bioconda kallisto && \
	conda install -c conda-forge git-lfs
WORKDIR /usr/local/bin/source/
RUN	git lfs install && \
	git lfs clone  https://github.com/RabadanLab/arcasHLA.git && \
	ln -s /usr/local/bin/source/arcasHLA/arcasHLA /usr/local/bin/arcasHLA && \
	ln -s /usr/local/bin/source/arcasHLA/scripts/ /usr/local/bin/
# ADD ./dat/IMGTHLA/ /usr/local/bin/source/arcasHLA/dat/IMGTHLA/
# ADD ./dat/info/ /usr/local/bin/source/arcasHLA/dat/info/
# ADD ./dat/ref/ /usr/local/bin/source/arcasHLA/dat/ref/

# Install HLAscan
WORKDIR /usr/local/bin/HLA_SCAN/
RUN wget https://github.com/SyntekabioTools/HLAscan/releases/download/v2.1.4/hla_scan_r_v2.1.4 && \
	wget https://github.com/SyntekabioTools/HLAscan/releases/download/v2.0.0/dataset.zip && \
	unzip dataset.zip && \
	chmod 755 ./hla_scan_r_v2.1.4 && \
	ln -s /usr/local/bin/HLA_SCAN/hla_scan_r_v2.1.4 /usr/local/bin/hla-scan
WORKDIR /usr/local/bin/

# Copy wrapper
COPY ./hlaii_typing.sh /usr/local/bin/source
RUN ln -s /usr/local/bin/source/hlaii_typing.sh /usr/local/bin/hlaii_typing

# Install samtools and BWA
RUN conda install --override-channels -c conda-forge -c bioconda  "samtools==1.9" && \
	conda install -c bioconda bwa

RUN useradd -ms /bin/bash icbi
USER icbi
