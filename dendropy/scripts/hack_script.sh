#!/bin/sh
set -x

ntaxa=$2
if test -z $ntaxa
then
	echo "expecting 2 arguments the filepath to the trees from the previous round and the number of taxa."
	exit 1
fi 
prevRound=$1
if ! test -f "${prevRound}"
then
	echo "expecting the file ${prevRound} to exist!"
	exit 1
fi 

if test -z $DENDROPY_SCRIPTS_PAR
then
	DENDROPY_SCRIPTS_PAR="${HOME}/Documents/projects/dendropy/dendropy/scripts"
fi


if true
then

################################################################################
# add the taxa to the trees from the previous round
echo 'keep = 5' > add_taxon_commands.txt 
(set -x ; time "${DENDROPY_SCRIPTS_PAR}/igarli_add_tree.py" ${prevRound} >> add_taxon_commands.txt) 2>time_igarli_add_tree.txt || exit
echo 'quit' >> add_taxon_commands.txt 

echo '#NEXUS' > added_taxa.tre
echo 'begin trees;' >> added_taxa.tre
iGarli ../add_garli.conf < add_taxon_commands.txt >igarli_add_err_out.txt 2>&1  || exit
grep '\[iGar' igarli_add_err_out.txt >>added_taxa.tre
echo 'end;' >> added_taxa.tre

fi

################################################################################
# augment the collection of trees
#	igarli_neighborhood.py will generate no output if it thinks this round is 
#	done
round=0
allTreeFiles='added_taxa.tre'
cmdFile="neighborhood_command${round}.txt"
echo 'tmp' > "${cmdFile}"
while test -s "${cmdFile}"
do
	cmdFile="neighborhood_command${round}.txt"
	if test $round -eq 0
	then
		(set -x ; time "${DENDROPY_SCRIPTS_PAR}/igarli_neighborhood.py" "${ntaxa}" 'added_taxa.tre' > "${cmdFile}") 2>time_igarli_neighborhood.txt || exit
	else
		(set -x ; time "${DENDROPY_SCRIPTS_PAR}/igarli_neighborhood.py" "${ntaxa}" 'added_taxa.tre' "${lastTreeFile}" > "${cmdFile}") 2>>time_igarli_neighborhood.txt || exit
	fi
	if test -s "${cmdFile}"
	then
		echo 'quit' >> "${cmdFile}"
		
		round=`expr $round + 1`
		lastTreeFile="neighborhood${round}.tre"
		
		echo '#NEXUS' > "${lastTreeFile}"
		echo 'begin trees;' >> "${lastTreeFile}"
		iGarli ../neighborhood_garli.conf < add_taxon_commands.txt >igarli_nbhd_${round}_err_out.txt 2>&1  || exit
		grep '\[iGar' igarli_nbhd_${round}_err_out.txt >> "${lastTreeFile}"  || exit
		echo 'end;' >> "${lastTreeFile}"
		allTreeFiles="${allTreeFiles} ${lastTreeFile}"
	fi
done


################################################################################
# select the trees to carry to the next round.

(set -x ; time "${DENDROPY_SCRIPTS_PAR}/igarli_select_trees.py" ${allTreeFiles} > selected.tre) 2>time_igarli_select_trees.txt



################################################################################
# Score the trees for the next round (this makes sure that they have good branch
#	lengths and gathers the site likeilhoods for the RELL
########
echo 'sitelike = 1' > score_commands.txt
("${DENDROPY_SCRIPTS_PAR}/igarli_add_tree.py" ${prevRound} >> score_commands.txt) 2>>time_igarli_add_tree.txt || exit
echo 'quit' >> score_commands.txt
echo '#NEXUS' > incrgarli.tre
echo 'begin trees;' >> incrgarli.tre
iGarli ../score_garli.conf < score_commands.txt >igarli_score_err_out.txt 2>&1 || exit
grep '\[iGar' igarli_score_err_out.txt >>incrgarli.tre  || exit
echo 'end;' >> incrgarli.tre
