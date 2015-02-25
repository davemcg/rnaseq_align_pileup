#!/bin/bash

# Takes fastq file from e-geuv-1 and spits out mpileup for alignments against enhanced (Satya ase) and unenhanced 
# chr2 at and around rs291466
# designed for swarm usage

# Convert fastq to fasta
#qsub -N $1.fastqConvert -V -cwd -b y "fastq2fastaqual $1.fastq.gz $1.fasta";
zcat $1_1.fastq.gz | sed -n '1~4s/^@/>/p;2~4p' > $1_1.fasta;
zcat $1_2.fastq.gz | sed -n '1~4s/^@/>/p;2~4p' > $1_2.fasta;

# align with chr2 enhanced with ase and straight hg19 chr2
# star 2.4.0j
/home/mcgaugheyd/Software/STAR-STAR_2.4.0j/bin/Linux_x86_64_static/./STAR \
	--genomeDir /cluster/ifs/projects/brody/rs291466_hibch_1000genomes_rna-seq/star_ase_enhanced_chr2/ \
	--readFilesIn $1_1.fasta $1_2.fasta --runThreadN 8 --genomeLoad NoSharedMemory --outFileNamePrefix $1.enhanced.chr2.;

/home/mcgaugheyd/Software/STAR-STAR_2.4.0j/bin/Linux_x86_64_static/./STAR \
	--genomeDir /cluster/ifs/projects/brody/rs291466_hibch_1000genomes_rna-seq/star_chr2/ \
	--readFilesIn $1_1.fasta $1_2.fasta --runThreadN 8 --genomeLoad NoSharedMemory --outFileNamePrefix $1.chr2.;

#sam to sorted bam
sam2bam.pl -bam $1.enhanced.chr2.sorted $1.enhanced.chr2.Aligned.out.sam;
sam2bam.pl -bam $1.chr2.sorted $1.chr2.Aligned.out.sam;

# run mpileup
samtools mpileup -r chr2:191184475-191184475 $1.enhanced.chr2.sorted.bam \
	| count_genotypes.py > $1.enhanced.mpileup.txt;
samtools mpileup -r chr2:191184475-191184475 $1.chr2.sorted.bam \
	| count_genotypes.py > $1.mpileup.txt;

#move/delete files
mv $1*.Log*out star_log;
rm $1*qual;
rm $1.fasta;
find -maxdepth 1 | grep -P '$1.*\d\d\d' | xargs -I{} mv {} sge_log_errors/;
