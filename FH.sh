#!/usr/bin/env bash
nodes=("cHHH2p45" "cHHH5")
years=("2016")
singleHiggs="tth,wzh,vbf,ggh"
#singleHiggs="wzh,vbf,ggh"
for node in ${nodes[@]}
do
  for year in ${years[@]}
  do
    echo "==================="
    echo "Start ${year} ${node}"
    ext='FH'
    procs='GluGluToHHTo2G4Q'
    
    InputTreeCats='HHWWggTag_FH_0,HHWWggTag_FH_1,HHWWggTag_FH_2,HHWWggTag_FH_3' #input cat name in the Signal tree
    InputDataTreeCats='HHWWggTag_FH_0,HHWWggTag_FH_1,HHWWggTag_FH_2,HHWWggTag_FH_3' #input cat name in the Data tree
    
    cat='HHWWggTag_FHDNN_0,HHWWggTag_FHDNN_1,HHWWggTag_FHDNN_2,HHWWggTag_FHDNN_3' #Final cat name 
    
    # SignalTreeFile="/eos/user/a/atishelm/ntuples/HHWWgg_flashgg/January_2021_Production/2016/FH_DNN_Categorized_LOSignals_noPtOverM-Training/Signal_${node}_2016_all_CategorizedTrees.root"
    SignalTreeFile="/eos/user/l/lipe/DNN_Evaluation_sample/${year}/CategorizeRootFileCondor_21Apr_WithCuts/Signal_${procs}_${node}_${year}_1_CategorizedTrees.root"
    DataTreeFile="/eos/user/l/lipe/DNN_Evaluation_sample/${year}/CategorizeRootFileCondor_21Apr_WithCuts/Data_${year}_CategorizedTrees.root"
    InputWorkspace="/eos/user/l/lipe/HHWWggWorkspace/FHDNN/" 

    Replace='HHWWggTag_FHDNN_0'
    doSelections="0"
    Selections='dipho_pt > 91' # Seletions you want to applied.
    catNames=(${cat//,/ })
    eval `scramv1 runtime -sh`
    source ./setup.sh

############################################
#  Tree selectors#
#
############################################
  path=`pwd`
  cd ./Reweight/
  cp Selections.C Selections_Run.C
  cp DataSelections.C DataSelections_Run.C
  sed -i "s#NODE#${node}#g" Selections_Run.C 
  sed -i "s#NEW_Cat_NAME#${cat}#g" Selections_Run.C 
  sed -i "s#CAT#${InputTreeCats}#g" Selections_Run.C
  sed -i "s#PROCS#${procs}#g" Selections_Run.C
  sed -i "s#YEAR#${year}#g" Selections_Run.C
  sed -i "s#2017#${year}#g" Selections_Run.C
  sed -i "s#INPUTFILE#${SignalTreeFile}#g" Selections_Run.C
if [ "$ext" = "FH" ]
then
  sed -i "s#tagsDumper/trees/##g" Selections_Run.C
  sed -i "s#tagsDumper/trees/##g" DataSelections_Run.C
fi

if [ $year -eq "2018" ]
then
  sed -i "s#metUncUncertainty\"#metUncUncertainty\",\"JetHEM\"#g" Selections_Run.C
fi
##########Data selection #####
  sed -i "s#CAT#${InputDataTreeCats}#g" DataSelections_Run.C
  sed -i "s#NEW_Cat_NAME#${cat}#g" DataSelections_Run.C 
  sed -i "s#YEAR#${year}#g" DataSelections_Run.C
  sed -i "s#INPUTFILE#${DataTreeFile}#g" DataSelections_Run.C


if [ $doSelections -eq "1" ]
then
  echo "Selection start"
  sed -i "s#SELECTIONS#${Selections}#g" Selections_Run.C
  ##########Data selection #####
  sed -i "s#SELECTIONS#${Selections}#g" DataSelections_Run.C

else
  echo "Do not apply any selections ,just copytree "
  sed -i "s#SELECTIONS##g" Selections_Run.C # No Selection 
  sed -i "s#SELECTIONS##g" DataSelections_Run.C #No Selection
fi

#root -b -q  Selections_Run.C
#root -b -q DataSelections_Run.C
rm Selections_Run.C
rm DataSelections_Run.C
#mv ${procs}_node_${node}_${year}.root  ../Trees2WS/
#mv Data_13TeV_${year}.root ../Trees2WS/
cp ${SignalTreeFile}  ../Trees2WS/${procs}_node_${node}_${year}.root
cp ${DataTreeFile}  ../Trees2WS/Data_13TeV_${year}.root
cd ../Trees2WS/
#########################################
# start tree to workspace
########################################

if [ ! -d "${InputWorkspace}/Signal/Input/${year}/" ]; then
  mkdir -p ${InputWorkspace}/Signal/Input/${year}/
fi
# Signal tree to signal ws

if [ $year -eq "2018" ] 
then
  echo "2018, remove prefire"
  cp HHWWgg_config_noprefire.py HHWWgg_config_run.py
else
  cp HHWWgg_config.py HHWWgg_config_run.py
fi
sed -i "s#2017#${year}#g" HHWWgg_config_run.py
sed -i "s#auto#${cat}#g" HHWWgg_config_run.py
rm -rf ws*
python trees2ws.py --inputConfig HHWWgg_config_run.py --inputTreeFile ./${procs}_node_${node}_${year}.root --inputMass node_${node} --productionMode ${procs}  --year ${year} --doSystematics
# data tree to data ws
python trees2ws_data.py --inputConfig HHWWgg_config_run.py --inputTreeFile ./Data_13TeV_${year}.root
rm HHWWgg_config_run.py
for catName in ${catNames[@]}
do
  if [ ! -d "${InputWorkspace}/Background/Input/${procs}_${year}" ]; then
    mkdir -p ${InputWorkspace}/Background/Input/${procs}_${year}
  fi
  cp ws_${procs}/${procs}_node_${node}_${year}_${procs}.root ${InputWorkspace}/Signal/Input/${year}/Shifted_M125_${procs}_node_${node}_${catName}.root
  cp ${InputWorkspace}/Signal/Input/${year}/Shifted_M125_${procs}_node_${node}_${catName}.root ${InputWorkspace}/Signal/Input/${year}/output_M125_${procs}_node_${node}_${catName}.root
  cp ws/Data_13TeV_${year}.root ${InputWorkspace}/Background/Input/${procs}_${year}/allData.root
done
rm ${procs}_node_${node}_${year}.root
rm Data_13TeV_${year}.root

cd ../Signal/
cp ./tools/replacementMapHHWWgg.py ./tools/replacementMap.py
sed -i "s#REPLACEMET_CATWV#${Replace}#g" ./tools/replacementMap.py
#######################################
# Run ftest
######################################
echo "Run FTest"
cp HHWWgg_config_test.py HHWWgg_config_Run.py
sed -i "s#NODE#node_${node}#g" HHWWgg_config_Run.py
sed -i "s#YEAR#${year}#g" HHWWgg_config_Run.py
sed -i "s#PROCS#${procs}#g" HHWWgg_config_Run.py
sed -i "s#CAT#${cat}#g" HHWWgg_config_Run.py
sed -i "s#HHWWggTest#${ext}#g" HHWWgg_config_Run.py
sed -i "s#INPUTDIR#${InputWorkspace}/Signal/Input/${year}/#g" HHWWgg_config_Run.py
python RunSignalScripts.py --inputConfig HHWWgg_config_Run.py --mode fTest --modeOpts "--doPlots"

#######################################
# Run photon sys
######################################
python RunSignalScripts.py --inputConfig HHWWgg_config_Run.py --mode calcPhotonSyst


#######################################
#Run signal Fit
#######################################
python RunSignalScripts.py --inputConfig HHWWgg_config_Run.py --mode signalFit --groupSignalFitJobsByCat
for catName in ${catNames[@]}
do
cp outdir_${ext}_${year}_node_${node}/signalFit/output/CMS-HGG_sigfit_${ext}_${year}_node_${node}_${procs}_${year}_${catName}.root outdir_${ext}_${year}_node_${node}/CMS-HGG_sigfit_${ext}_${year}_node_${node}_${catName}.root
python RunPlotter.py --procs all --years $year --cats $catName --ext ${ext}_${year}_node_${node} --HHWWggLabel $ext
done

rm HHWWgg_config_Run.py
########################################
#           BKG model                  #
#                                      #
########################################
cd ../Background
cp HHWWgg_cofig_test.py HHWWgg_cofig_Run.py
sed -i "s#CAT#${cat}#g" HHWWgg_cofig_Run.py
sed -i "s#YEAR#${year}#g" HHWWgg_cofig_Run.py
sed -i "s#HHWWggTest#${ext}#g" HHWWgg_cofig_Run.py
sed -i "s#PROCS#${procs}#g" HHWWgg_cofig_Run.py
sed -i "s#INPUT#${InputWorkspace}#g" HHWWgg_cofig_Run.py
cmsenv
# make clean
make

python RunBackgroundScripts.py --inputConfig HHWWgg_cofig_Run.py --mode fTestParallel

rm HHWWgg_cofig_Run.py
########################################
#           DATACARD                   #
#                                      #
########################################
echo "Start generate datacard"
cd ../Datacard
rm Datacard*.txt
rm -rf yields_*/
cp systematics_${year}.py systematics.py
#copy signal  and bkg model
rm -rf SingleHiggs_${procs}_node_${node}_${year}/
cp -rf SingleHiggs_${ext}_${year}/ SingleHiggs_${procs}_node_${node}_${year}/
if [ ! -d "./SingleHiggs_${procs}_node_${node}_${year}/Models/" ]; then
  mkdir -p ./SingleHiggs_${procs}_node_${node}_${year}/Models/
fi
####################
#
#   Add singleHiggs procs to RunYields.py 
###################
python RunYields.py --cats ${cat} --inputWSDirMap ${year}=${InputWorkspace}/Signal/Input/${year} --procs ${procs},${singleHiggs} --doSystematics True --doHHWWgg True --HHWWggLabel node_${node} --batch local --ext SingleHiggs  --bkgModelWSDir ./Models --sigModelWSDir ./Models --skipZeroes True 
python makeDatacard.py --years ${year} --prune True --ext SingleHiggs  --doSystematics True --pruneThreshold 0.000001
python cleanDatacard.py --datacard Datacard.txt --factor 2 --removeDoubleSided
mv ./SingleHiggs_${procs}_node_${node}_${year}/*.root SingleHiggs_${procs}_node_${node}_${year}/Models/
for catName in ${catNames[@]}
do
cp ${path}/Background/outdir_${ext}_$year/CMS-HGG_multipdf_${catName}.root ./SingleHiggs_${procs}_node_${node}_${year}/Models/CMS-HGG_multipdf_${catName}_$year.root
cp ${path}/Signal/outdir_${ext}_${year}_node_${node}/signalFit/output/CMS-HGG_sigfit_${ext}_${year}_node_${node}_${procs}_${year}_${catName}.root ./SingleHiggs_${procs}_node_${node}_${year}/Models/CMS-HGG_sigfit_packaged_${procs}_${catName}_${year}.root
done
cp Datacard_cleaned.txt ./SingleHiggs_${procs}_node_${node}_${year}/HHWWgg_${procs}_node_${node}_${ext}_${year}.txt

python RunYields.py --cats $cat --inputWSDirMap $year=${InputWorkspace}/Signal/Input/${year}/ --procs ${procs} --doHHWWgg True --HHWWggLabel node_${node} --batch local --sigModelWSDir ./Models --bkgModelWSDir ./Models --doSystematics True --ext ${procs}_node_${node} 
python makeDatacard.py --years $year --prune True --ext ${procs}_node_${node} --pruneThreshold 0.00001 --doSystematics
python cleanDatacard.py --datacard Datacard.txt --factor 2 --removeDoubleSided
cp Datacard_cleaned.txt ./SingleHiggs_${procs}_node_${node}_${year}/HHWWgg_${procs}_node_${node}_${ext}_${year}_no_singleH.txt
datacards=`ls ./SingleHiggs_${procs}_node_${node}_${year}/*.txt`
for datacard in $datacards
do
echo "xs_HH         rateParam * GluGluToHHTo2G4Q_*_hwwhgg_node_${node} 31.049" >>$datacard
echo "br_HH_WWgg    rateParam * GluGluToHHTo2G4Q_*_hwwhgg_node_${node} 0.000119992" >>$datacard
echo "br_WW_qqqq    rateParam * GluGluToHHTo2G4Q_*_hwwhgg_node_${node} 0.4544" >>$datacard
echo "nuisance edit  freeze xs_HH" >> $datacard
echo "nuisance edit  freeze br_WW_qqqq" >>  $datacard
echo "nuisance edit  freeze br_HH_WWgg" >> $datacard
done

cd ./SingleHiggs_${procs}_node_${node}_${year}
echo "Combine results without singleH:"
combine HHWWgg_${procs}_node_${node}_${ext}_${year}_no_singleH.txt  -m 125.38 -M AsymptoticLimits --run=blind  --freezeParameters MH
 
echo "Combine results singleH:"
combine HHWWgg_${procs}_node_${node}_${ext}_${year}.txt  -m 125.38 -M AsymptoticLimits --run=blind  --freezeParameters MH
cd $path
done
done



