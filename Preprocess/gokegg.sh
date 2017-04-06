###
dir=/WORK/sysu_luoda_1/bio/Project/GDI0771/Pipe/diff/samples/enrichment
wego=/WORK/sysu_luoda_1/bio/Database/Ensemblgenomes/Ensembl/release76/Homo_sapiens/ref4lncRNA/Homo_sapiens_annot/Homo_sapiens.wego
ko=/WORK/sysu_luoda_1/bio/Database/Ensemblgenomes/Ensembl/release76/Homo_sapiens/ref4lncRNA/Homo_sapiens_annot/Homo_sapiens.ko
komap=/WORK/sysu_luoda_1/bio/Database/blast_db/kegg/data/map_class/animal_ko_map.tab
go=/WORK/sysu_luoda_1/bio/Database/Ensemblgenomes/Ensembl/release76/Homo_sapiens/ref4lncRNA/Homo_sapiens_annot
go_species=Homo_sapiens
	
###
echo "START at `date`"

for i in `ls ${dir}/*.glist`
do
	name=`basename ${i} ".glist"`

	echo '================================'
	echo "processing with ${name}"
	echo '================================'

	#KO
	if [ -s $ko ]; then
		mkdir -p ${dir}/KO
		awk -F "\t" '{printf("%s\t\t\t\t\t%s\n", $1, $2)}' $i > ${dir}/KO/${name}.glist
		perl /WORK/sysu_luoda_1/bio/Bin/pipeline/general_RNAseq/Softwares/enrich/diff/getKO.pl -glist ${dir}/KO/${name}.glist -bg $ko -outdir ${dir}/KO
		perl /WORK/sysu_luoda_1/bio/Bin/pipeline/general_RNAseq/Softwares/enrich/diff/pathfind.pl -fg ${dir}/KO/${name}.ko -komap $komap -bg $ko -output ${dir}/KO/${name}.path
		perl /WORK/sysu_luoda_1/bio/Bin/pipeline/general_RNAseq/Softwares/enrich/keggGradient.pl ${dir}/KO/${name}.path 20
		perl /WORK/sysu_luoda_1/bio/Bin/pipeline/general_RNAseq/Softwares/enrich/diff/keggMap.pl -ko ${dir}/KO/${name}.ko -komap $komap -diff ${dir}/KO/${name}.glist -outdir ${dir}/KO/${name}_map
		rm ${dir}/KO/${name}.glist -rf
	fi

	#GO
	if [ -s $wego ]; then
		mkdir -p ${dir}/GO
		awk '$2 >= 1' $i > ${dir}/GO/${name}_up.glist
		awk '$2 <= -1' $i > ${dir}/GO/${name}_down.glist
		perl /WORK/sysu_luoda_1/bio/Bin/pipeline/general_RNAseq/Softwares/enrich/diff/getwego.pl ${dir}/GO/${name}_up.glist $wego > ${dir}/GO/${name}_up.wego
		perl /WORK/sysu_luoda_1/bio/Bin/pipeline/general_RNAseq/Softwares/enrich/diff/getwego.pl ${dir}/GO/${name}_down.glist $wego > ${dir}/GO/${name}_down.wego
		if [ -s ${dir}/GO/${name}_up.wego ] && [ -s ${dir}/GO/${name}_down.wego ]; then
			perl /WORK/sysu_luoda_1/bio/Bin/pipeline/general_RNAseq/Softwares/enrich/diff/drawGO_black.pl -gglist ${dir}/GO/${name}_up.wego,${dir}/GO/${name}_down.wego -output ${dir}/GO/${name}.go.class
		elif [ -s ${dir}/GO/${name}_up.wego ]; then
			perl /WORK/sysu_luoda_1/bio/Bin/pipeline/general_RNAseq/Softwares/enrich/diff/drawGO_black.pl -gglist ${dir}/GO/${name}_up.wego -output ${dir}/GO/${name}.go.class
		elif [ -s ${dir}/GO/${name}_down.wego ]; then
			perl /WORK/sysu_luoda_1/bio/Bin/pipeline/general_RNAseq/Softwares/enrich/diff/drawGO_black.pl -gglist ${dir}/GO/${name}_down.wego -output ${dir}/GO/${name}.go.class
		fi
		/HOME/sysu_luoda_1/bin/rsvg-convert ${dir}/GO/${name}.go.class.svg -o ${dir}/GO/${name}.go.class.png
		rm ${dir}/GO/${name}_up.glist ${dir}/GO/${name}_down.glist -rf
	fi
done

echo '================================'
echo "processing functional programmes"
echo '================================'

if [ -s $ko ]; then
	perl /WORK/sysu_luoda_1/bio/Bin/pipeline/general_RNAseq/Softwares/enrich/diff/genPathHTML.pl -indir ${dir}/KO
fi
if [[ -s $go/$go_species.P ]] && [[ -s $go/$go_species.F ]] && [[ -s $go/$go_species.C ]]; then
	perl /WORK/sysu_luoda_1/bio/Bin/pipeline/general_RNAseq/Softwares/enrich/diff/functional.pl -go -gldir ${dir} -sdir $go -species $go_species -outdir ${dir}
fi

echo '================================'
echo 'All done'
 
