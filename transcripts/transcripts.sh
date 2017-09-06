#Something like this. :)
#Except this is crap.

experimentAccession=E-MTAB-4484
configurationXml=/nfs/production3/ma/home/atlas3-production/analysis/baseline/rna-seq/experiments/E-MTAB-4484/E-MTAB-4484-configuration.xml
outdir=/var/tmp/$experimentAccession
mkdir -p $outdir
transcriptsFile=/nfs/production3/ma/home/irap_prod/single_lib/studies/E-MTAB-4484/triticum_aestivum/transcripts.tpm.kallisto.tsv
geneIdFile=$ATLAS_PROD/bioentity_properties/ensembl/triticum_aestivum.ensgene.enstranscript.tsv
geneNameFile=$ATLAS_PROD/bioentity_properties/ensembl/triticum_aestivum.ensgene.symbol.tsv


/nfs/production3/ma/home/atlas3-production/sw/atlasinstall_prod/atlasprod/irap/gxa_summarizeExpressionUnits.pl \
   --quantile-normalize --aggregate-technical-replicates \
   --configuration $configurationXml \
   --input $transcriptsFile \
   --output $outdir/${experimentAccession}-transcript-tpms.techreps.tsv.undecorated

/nfs/production3/ma/home/atlas3-production/sw/atlasinstall_prod/atlasprod/irap/gxa_summarizeExpressionUnits.pl \
  --quantile-normalize --aggregate-technical-replicates --aggregate-quartiles \
  --configuration $configurationXml \
  --input $transcriptsFile \
  --output $outdir/${experimentAccession}-transcript-tpms.quartiles.tsv.undecorated

amm /nfs/production3/ma/home/atlas3-production/sw/atlasinstall_prod/atlasprod/bioentity_annotations/decorateFile.sc \
   --geneIdFile $geneIdFile \
   --geneNameFile $geneNameFile \
    --source $outdir/${experimentAccession}-transcript-tpms.quartiles.tsv.undecorated \
    > $outdir/${experimentAccession}-transcript-tpms.quartiles.tsv

scp DumpIds.pl ebi-cli-003:/var/tmp/x.txt #TODO
join -1 1 -2 2  \
    <(perl /var/tmp/x.txt /nfs/production3/ma/home/atlas3-production/analysis/baseline/rna-seq/experiments/E-MTAB-4484/E-MTAB-4484-configuration.xml) \
    <(head -n1 $outdir/${experimentAccession}-transcript-tpms.techreps.tsv.undecorated | tr $'\t' $'\n' | cat -n | sort -k2 ) \
    > $outDir/ids-and-transcript-cols.tsv

mkdir $outdir/partials

echo _ > $outdir/partials/identifiers.tsv
cut -f 1 $outdir/${experimentAccession}-transcript-tpms.techreps.tsv.undecorated >> $outdir/partials/identifiers.tsv

for x in $(cut -f 2 -d ' ' /var/tmp/E-MTAB-4484/ids-and-transcript-cols.tsv | sort -u ) ; do grep $x /var/tmp/E-MTAB-4484/ids-and-transcript-cols.tsv | cut -f 4 -d ' ' | sort -u | tr '\n' , | xargs echo $x  ; done | sed 's/.$//' | while read assayGroup cols ; do
	echo $assayGroup > $outdir/partials/$assayGroup.partial.tsv
	cut -f $cols $outdir/${experimentAccession}-transcript-tpms.techreps.tsv.undecorated | tr $'\t' ',' >> $outdir/partials/$assayGroup.partial.tsv ; done

paste $outdir/partials/identifiers.tsv $outdir/partials/*partial.tsv > $outdir/${experimentAccession}-transcript-tpms.techreps.tsv.undecorated.aggregated

amm /nfs/production3/ma/home/atlas3-production/sw/atlasinstall_prod/atlasprod/bioentity_annotations/decorateFile.sc \
     --geneIdFile $geneIdFile \
     --geneNameFile $geneNameFile \
      --source $outdir/${experimentAccession}-transcript-tpms.techreps.tsv.undecorated.aggregated \
      > $outdir/${experimentAccession}-transcript-tpms.techreps.tsv
