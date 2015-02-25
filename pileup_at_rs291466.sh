#!/bin/bash

# Takes fastq file from e-geuv-1 and spits out mpileup for alignments against enhanced (Satya ase) and unenhanced 
# chr2 at and around rs291466

# Convert fastq to fasta
#qsub -N $1.fastqConvert -V -cwd -b y "fastq2fastaqual $1.fastq.gz $1.fasta";
qsub -N $1_1.fastqConvert -V -cwd -b y "zcat $1_1.fastq.gz | sed -n '1~4s/^@/>/p;2~4p' > $1_1.fasta";
qsub -N $1_2.fastqConvert -V -cwd -b y "zcat $1_2.fastq.gz | sed -n '1~4s/^@/>/p;2~4p' > $1_2.fasta"

# align with chr2 enhanced with ase and straight hg19 chr2
# star 2.4.0j
qsub -hold_jid $1_1.fastqConvert,$1_2.fastqConvert -N $1.enhance.align -b y -cwd -V -l mem_free=3G -l h_vmem=3G -pe make-dedicated 16 \
	"/home/mcgaugheyd/Software/STAR-STAR_2.4.0j/bin/Linux_x86_64_static/./STAR \
	--genomeDir /cluster/ifs/projects/brody/rs291466_hibch_1000genomes_rna-seq/star_ase_enhanced_chr2/ \
	--readFilesIn $1_1.fasta $1_2.fasta --runThreadN 10 --genomeLoad NoSharedMemory --outFileNamePrefix $1.enhanced.chr2.";

qsub -hold_jid $1_1.fastqConvert,$1_2.fastqConvert -N $1.align -b y -cwd -V -l mem_free=3G -l h_vmem=3G -pe make-dedicated 16  \
	"/home/mcgaugheyd/Software/STAR-STAR_2.4.0j/bin/Linux_x86_64_static/./STAR \
	--genomeDir /cluster/ifs/projects/brody/rs291466_hibch_1000genomes_rna-seq/star_chr2/ \
	--readFilesIn $1_1.fasta $1_2.fasta --runThreadN 10 --genomeLoad NoSharedMemory --outFileNamePrefix $1.chr2.";

#sam to sorted bam
qsub -hold_jid $1.enhance.align -N $1.enhance.sam2bam -b y -cwd -V \
	"sam2bam.pl -bam $1.enhanced.chr2.sorted $1.enhanced.chr2.Aligned.out.sam";
qsub -hold_jid $1.align -N $1.sam2bam -b y -cwd -V \
	"sam2bam.pl -bam $1.chr2.sorted $1.chr2.Aligned.out.sam";

# run mpileup
qsub -hold_jid $1.enhance.sam2bam -N $1.enhance.mpileup -b y -cwd -V \
	"samtools mpileup -r chr2:191184475-191184475 $1.enhanced.chr2.sorted.bam \
	| count_genotypes.py > $1.enhanced.mpileup.txt";
qsub -hold_jid $1.sam2bam -N $1.mpileup -b y -cwd -V \
	"samtools mpileup -r chr2:191184475-191184475 $1.chr2.sorted.bam \
	| count_genotypes.py > $1.mpileup.txt";

#move/delete files
qsub -hold_jid $1.enhance.mpileup,$1.mpileup -N $1.Logs -V -cwd -b y "mv $1*.Log*out star_log";
qsub -hold_jid $1.enhance.mpileup,$1.mpileup -N $1.remove.qual -V -cwd -b y "rm $1*qual";
qsub -hold_jid $1.enhance.mpileup,$1.mpileup -N $1.remove.fasta -V -cwd -b y "rm $1.fasta";
qsub -hold_jid $1.enhance.mpileup,$1.mpileup,$1.Logs,$1.remove.qual,$1.remove.fasta -N $1.sge.log.error -V -cwd -b y \
	"find -maxdepth 1 | grep -P '$1.*\d\d\d' | xargs -I{} mv {} sge_log_errors/";
