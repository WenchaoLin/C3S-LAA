# C3S-LAA
Clustering of Circular Consensus Sequences (C3S) for Long Amplicon Analysis of PacBio Data


Overview of C3S-LAA 
================================================
To improve and extend the functionality of the long amplicon analysis (LAA) module from PacBio, we restructured the clustering approach for LAA based on the high quality circular consensus sequence data, grouping these reads based on the primer sequences used to amplify the DNA and the molecular barcodes used to track individuals. This directs error correction and consensus sequence analysis to be performed on sequences that should be the same, from a given sample, leading to improved accuracy of the outputted data. In addition, integration of Minimus (Sommer et al. BMC Bioinformatics, 2007 8:64) for automated assembly of any overlapping amplicon consensus sequences allows for efficient processing of tiled amplicon resequence data.

Usage
================================================

###  _1) Generate circular consensus sequences (CCSs)_

The reads of insert protocol in SMRT Portal should be used to generate a fasta file containing the CCSs. 

###  _2) Set up the parameter file_

The required dependencies and input files along with the output directory need to be specified. “ccs” parameter indicates the path to the resulting CCS reads (from step 1). This is followed by the various C3S-LAA parameters and torque script settings for running consensus_calling.sh. Further details regarding each of these parameters are given under the <a href="#parameters">parameters</a> section below.

###  _3) Command 1_

        python cluster.py
    
Based on the CCSs are used to cluster the data based on the presence of both the forward and reverse primer sequences for each amplicon (the pipeline considers the sense and antisense primer sequences). From this, we produce a list of CCS identifiers belonging to each primer pair cluster. This list is used to link the corresponding raw reads, using the whitelist option in LAA, to carry out Quiver based consensus calling using only the raw reads belonging to an amplicon-specific cluster. The pipeline can be used to perform one-level clustering for non-barcoded amplicon libraries or two-level clustering for barcoded amplicon libraries. 

###  _4) Command 2_

        qsub consensus_calling.sh
This shell script (consensus_calling.sh) will be generated by running "cluster.py" (from step 3). For users running this shell script as a torque submission, the standard qsub parameters are indicated at the beginning of this shell script (first 6 lines as given below), based on the user input parameters. This may be removed/modified if user decides to run this shell script locally.
        
        #!/bin/sh
        #PBS -N consensus_calling
        #PBS -r n
        #PBS -l walltime=190:00:00
        #PBS -l nodes=1:ppn=12
        #PBS -d /path/
    
    
    
###  _5) Command 3_

        python consensus_assembly.py
This script first generates a multi-fasta file (merged_reads.fasta) containing the error corrected consensus sequences from all the amplicon for a given sample. Using this multi-fasta file, the script carries out assembly to generate an output file "merged_reads_assembly.fasta" that contains the assembly results. The assembled contigs are named as >1, >2, >3 etc. within this file.


<h1 id="parameters">
Parameters
</h1>
User input parameters need to be written by modifying the parameters.py file. Here is an sample parameter file data:

    ### User input parameters for C3S-LAA
    
    ### Required dependencies and input files
    # Path for the AMOS package that contains minimus assembler
    amos_path = "/usr/local/amos/bin/"

    ### path to the primer pair info. file
    primer_info_file = "primer_pairs_info.txt"

    ### path to PacBio fofn
    fofn = "/mnt/data27/ffrancis/PacBio_sequence_files/EqPCR_raw/F03_1/Analysis_Results/m160901_060459_42157_c101086112550000001823264003091775_s1_p0.bas.h5"

    ### path to ccs reads
    ccs = "/mnt/data27/ffrancis/PacBio_sequence_files/old/primer_pair_based_grouping/Eq_wisser_PCR-ccs-opt-smrtanalysis-userdata-jobs-020-020256-data-reads_of_insert.fasta"
    
    ### directory where the consensus files will be saved
    consensus_output = "./output/"
    
    ### C3S-LAA parameters
    #number of bases corresponding to padding + barcode that need to be trimmed from the amplicon consensus
    trim_bp = 21

    ### 1: yes; 0: no
    barcode_subset = 0

    ### reads >= "min_read_length" will be searched for the presence of primer sequences
    min_read_length = 0

    ### 1: filter; 0: no filter
    min_read_len_filter = 1

    ### searches for the primer sequence within n bases from the read terminals
    primer_search_space = 100

    ### Maximum barcode seq length
    max_barcode_length = 0

    ### Maximum padding seq length
    max_padding_length = 5

    ### torque script settings

    ### walltime for consensus calling
    walltime = 190

    ### node no./name for consensus calling
    node = "1"

    ### no. of processors for consensus calling
    processors = 12

    ### consensus sequences generated from >= "no_reads_threshold" will be used for assembly
    no_reads_threshold = 100



C3S-LAA scripts need to be run by defining the path of the SMRT PORTAL provided by PacBio. 
"consensus_assembly.py" requires "amos" package to be installed.


###  _An external file with the primer information should be provided_
Here is an example format:

    f_primer_name	        r_primer_name	        f_primer_sequence	        r_primer_sequence
    TA_1_25390617_27_F	TA_1_25395472_24_R	AAACATTGGTGTGGAAAGCAACTGAAG	AGGGTCACAGCACAGGACAGATTC
    TA_1_25391952_24_F	TA_1_25396540_27_R	AGGGACAACGTAGGGAGCCTTTGG	CGTCGACCACCGAATCAAGCAAGCATG
    TA_2_37562840_25_F	TA_2_37567441_24_R	GGGTGTTGTTCGGTCACCTCCTTTG	ATCCTTTGAGTGACTGAGGGTGTG
    TA_2_37564580_25_F	TA_2_37569533_24_R	TACGAGGTGTTTGGTTTGGTGAACG	CATGCATGCACACCTTCCAAGCTC
    TA_3_33503980_28_F	TA_3_33507309_27_R	TGTCCACCGACGACATCATTGGAGAGTG	TGCACAGTGCACATATGCTGCTTGGTG
    TA_3_33506037_24_F	TA_3_33509162_25_R	CAAACCGCAGAGGATAGAGATCGC	GGGTTCTCATCAACATTTGGACCTC
    TA_6_7045710_25_F	TA_6_7050495_28_R	TAGGGAGAGGTGGGAATATAATGGG	CCATCAAGTACAACAACGCATGATCATC
    TA_6_7047707_27_F	TA_6_7052049_28_R	CAGCATGCGTATAAAGAAGGCGAGCTC	CCCGATGTGCGACGCCGTAACAAATCTC

The primers should be named according to the following naming convention (Name_Chromosome_StartPos_Length_Direction)


###  _An external file with the barcode information (barcode_pairs_info.txt) may optionally be provided_
Here is an example format:   
    
    f_barcode_name	f_barcode_sequence	r_barcode_name	r_barcode_sequence
    B97_BC.F1	CTATACATGACTCTGC	B97_BC.R1	GCAGAGTCATGTATAG
    CML103_BC.F1	CTATACATGACTCTGC	CML103_BC.R2	CATGTACTGATACACA
    CML228_BC.F1	CTATACATGACTCTGC	CML228_BC.R3	GAGAGACGATCACATA
    CML247_BC.F1	CTATACATGACTCTGC	CML247_BC.R4	CTGATATGTAGTCGTA

###  _When multiple lanes of sequence data are available_
A custom file of file names (fofn) as a .txt file, containing the absolute path and file names of the raw reads should be made available. This should be depicted in the "fofn_pacbio_raw_reads" option in the parameters.py file.

Here is an example of the contents of the fofn.txt file:

    /absolute_path/m170410_233007_42157_c101187522550000001823244205011702_s1_p0.1.bax.h5
    /absolute_path/m170410_233007_42157_c101187522550000001823244205011702_s1_p0.2.bax.h5
    /absolute_path/m170410_233007_42157_c101187522550000001823244205011702_s1_p0.3.bax.h5



Dependencies for C3S-LAA
================================================
C3S-LAA can be executed via Python. This requires installation of the following components. Other versions of these components have not been tested.

* Linux/Unix

* <a href="https://github.com/PacificBiosciences/SMRT-Analysis">SMRT-Analysis v2.3.0</a>
* <a href="http://python.org/">Python 2.7</a>
* <a href="http://www.numpy.org/">NumPy 1.9.2</a>
* <a href="http://pandas.pydata.org/">pandas 0.18.1</a>
* <a href="http://biopython.org/wiki/Download">Biopython 1.69</a>


Licensing and Availability
================================================
C3S-LAA is released under an MIT open source license.
The source code is available on GitHub: https://github.com/drmaize/C3S-LAA

