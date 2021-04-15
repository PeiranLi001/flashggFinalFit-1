#!/usr/bin/env bash
node=("cHHH1")
singleHiggs="tth,wzh,vbf,ggh"
echo "==================="
ext='SL_Run2combinedData'
procs='GluGluToHHTo2G2Qlnu'
cat='HHWWggTag_SLDNN_0,HHWWggTag_SLDNN_1,HHWWggTag_SLDNN_2,HHWWggTag_SLDNN_3' #Final cat name 
InputWorkspace="/eos/user/c/chuw/HHWWggWorkspace/SL_multiClass/" 
hadd_workspaceDir="/afs/cern.ch/user/c/chuw/chuw/HHWWgg/NewCheck/CMSSW_10_6_8/" #flashgg Dir,used hadd_workspaces
catNames=(${cat//,/ })
singleH_Names=(${singleHiggs//,/ })

path=`pwd`
########################################
#           hadd_workspace             #
#                                      #
########################################
cd $hadd_workspaceDir 
eval `scramv1 runtime -sh`
cd $InputWorkspace
cd Background/Input/
mkdir $ext
cd $ext
cp ../${procs}_2016/allData.root Data2016.root
cp ../${procs}_2017/allData.root Data2017.root
cp ../${procs}_2018/allData.root Data2018.root
hadd_workspaces allData.root Data201*
########################################
#           BKG model                  #
#                                      #
########################################
cd $path
eval `scramv1 runtime -sh`
source ./setup.sh
cd ./Background
cp HHWWgg_cofig_test.py HHWWgg_cofig_Run.py
sed -i "s#CAT#${cat}#g" HHWWgg_cofig_Run.py
sed -i "s#PROCS_YEAR#${ext}#g" HHWWgg_cofig_Run.py
sed -i "s#HHWWggTest_YEAR#${ext}#g" HHWWgg_cofig_Run.py
sed -i "s#YEAR#combined#g" HHWWgg_cofig_Run.py
sed -i "s#PROCS#${procs}#g" HHWWgg_cofig_Run.py
sed -i "s#INPUT#${InputWorkspace}#g" HHWWgg_cofig_Run.py
# make clean
make

# python RunBackgroundScripts.py --inputConfig HHWWgg_cofig_Run.py --mode fTestParallel
rm HHWWgg_cofig_Run.py
########################################
#           DATACARD                   #
#                                      #
########################################
echo "Start generate datacard"
cd ../Datacard
rm Datacard*.txt
rm -rf yields_*/
rm -rf ./SL_run2_${node}
cp systematics_merged.py systematics.py
#copy signal  and bkg model
if [ ! -d "./SL_run2_${node}/Models/" ]; then
  mkdir -p ./SL_run2_${node}/Models/
fi
####################
#
#   Add singleHiggs procs to RunYields.py 
###################
cp ${path}/Background/outdir_${ext}/CMS-HGG_multipdf_*.root ./SL_run2_${node}/Models/
cp -rf ./SingleHiggs_${procs}_node_${node}_2016/* SL_run2_${node}/
cp -rf ./SingleHiggs_${procs}_node_${node}_2017/* SL_run2_${node}/
cp -rf ./SingleHiggs_${procs}_node_${node}_2018/* SL_run2_${node}/

python RunYields.py --cats ${cat} --inputWSDirMap 2016=${InputWorkspace}/Signal/Input/2016,2017=${InputWorkspace}/Signal/Input/2017,2018=${InputWorkspace}/Signal/Input/2018/ --procs ${procs} --doSystematics True --doHHWWgg True --HHWWggLabel node_${node} --batch local --ext SingleHiggs  --bkgModelWSDir ./Models --sigModelWSDir ./Models --mergeYears True --ignore-warnings True --skipZeroes True
python makeDatacard.py --years 2016,2017,2018 --prune True --ext SingleHiggs --pruneThreshold 0.00001 --doSystematics
python cleanDatacard.py --datacard Datacard.txt --factor 2 --removeDoubleSided
cp Datacard_cleaned.txt  SL_run2_${node}/SL_run2_merged_${node}.txt
if [ "$node" = "cHHH1" ]
then
XS=31.049
elif [ "$node" = "cHHH2p45" ]
then
  XS=13.126
elif [ "$node" = "cHHH5" ]
then
  XS=91.174
else 
  XS=1
fi
cd SL_run2_${node}/
echo "xs_HH         rateParam * GluGluToHHTo2G2Qlnu_*_hwwhgg_node_${node} $XS" >>SL_run2_merged_${node}.txt
echo "br_HH_WWgg    rateParam * GluGluToHHTo2G2Qlnu_*_hwwhgg_node_${node} 0.000970198" >>SL_run2_merged_${node}.txt
echo "br_WW_qqlnu   rateParam * GluGluToHHTo2G2Qlnu_*_hwwhgg_node_${node} 0.441" >> SL_run2_merged_${node}.txt
echo "nuisance edit  freeze xs_HH" >> SL_run2_merged_${node}.txt
echo "nuisance edit  freeze br_WW_qqlnu" >> SL_run2_merged_${node}.txt
echo "nuisance edit  freeze br_HH_WWgg" >> SL_run2_merged_${node}.txt 
years=("2016" "2017" "2018")
for year in ${years[@]}
do 
  echo "year: $year"
  for catName in ${catNames[@]}
  do
    echo "cat: $catName"
    for procName in ${singleH_Names[@]}
    do
      SF=`grep "$year $procName $catName" /afs/cern.ch/user/c/chuw/chuw/HHWWgg/flashggFinalFit/CMSSW_10_2_13/src/flashggFinalFit/Single_Higgs_ScaleFactors.txt | awk '{print $4}'`
      echo "SF is SF_${procName}_${year}_${catName} $SF"
  echo "SF_${procName}_${year}_${catName}   rateParam ${catName} ${procName}_${year}_hgg ${SF}" >> SL_run2_merged_${node}.txt
  echo "nuisance edit  freeze SF_${procName}_${year}_${catName}" >> SL_run2_merged_${node}.txt
  done
  done
done
combineCards.py HHWWgg_${procs}_node_${node}_SL_2016.txt HHWWgg_${procs}_node_${node}_SL_2017.txt HHWWgg_${procs}_node_${node}_SL_2018.txt >SL_run2_separate_year_${node}.txt
echo "Combine results with merged:"
combine SL_run2_merged_${node}.txt  -m 125.38 -M AsymptoticLimits --run=blind --freezeParameters MH 
echo "Combine results with separate data:"
combine SL_run2_separate_year_${node}.txt  -m 125.38 -M AsymptoticLimits --run=blind  --freezeParameters MH
cd $path


