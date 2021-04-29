# Final Fits (lite)
Welcome to the new Final Fits package. Here lies a a series of scripts which are used to run the final stages of the CMS Hgg analysis: signal modelling, background modelling, datacard creation, final statistical interpretation and final result plots.

Slides from the flashgg tutorial series can be found [here](https://indico.cern.ch/event/963619/contributions/4112177/attachments/2151275/3627204/finalfits_tutorial_201126.pdf)


## Download and setup instructions

```
export SCRAM_ARCH=slc7_amd64_gcc700
cmsrel CMSSW_10_2_13
cd CMSSW_10_2_13/src
cmsenv
git cms-init

# Install the GBRLikelihood package which contains the RooDoubleCBFast implementation
git clone git@github.com:jonathon-langford/HiggsAnalysis.git

# Install Combine as per the documentation here: cms-analysis.github.io/HiggsAnalysis-CombinedLimit/
git clone git@github.com:cms-analysis/HiggsAnalysis-CombinedLimit.git HiggsAnalysis/CombinedLimit

# Install Combine Harvester for parallelizing fits
git clone https://github.com/cms-analysis/CombineHarvester.git CombineHarvester

# Compile external libraries
cmsenv
scram b -j 9

# Install Flashgg Final Fit packages
git clone -b FHWW git@github.com:PeiranLi001/flashggFinalFit-1.git
cd flashggFinalFit/
```

In every new shell run the following to add `tools/commonTools` and `tools/commonObjects` to your `${PYTHONPATH}`:
```
cmsenv
source setup.sh
```

## SingleH setup
There is a automactic script.Named SLSingleH.sh
Before you run it.
You should set:
- Names=("SingleHiggs_ttHJetToGG_2018_1_CategorizedTrees" "SingleHiggs_VHToGG_2018_1_CategorizedTrees" "SingleHiggs_VBFHToGG_2018_1_CategorizedTrees" "SingleHiggs_GluGluHToGG_2018_1_CategorizedTrees") #depend on your file name SingleHiggs_ttHJetToGG_2018_1_CategorizedTrees.root
- years=("2018")
- cat='HHWWggTag_FHDNN_0,HHWWggTag_FHDNN_1,HHWWggTag_FHDNN_2,HHWWggTag_FHDNN_3'
- TreePath="/eos/user/l/lipe/DNN_Evaluation_sample/${year}/CategorizeRootFileCondor_21Apr_WithCuts/" #path to signal tree
- InputWorkspace="/eos/user/l/lipe/HHWWggWorkspace/FHDNN/" #provide a path to save workspace
- doSelections="0" #if you want to applied selections to your tree, then set it to 1
- Selections='dipho_pt > 160' #Here you can define which selections you want to set.

After you set these options,Then you can just run:
```
sh SLSingleH.sh
```
## run signal to compute the limit
There is a automactic script.Named FH.sh
Before you run it.
You should set:
- nodes=("cHHH1" "cHHH2p45" "cHHH5")
- years=("2016" "2017" "2018")
- procs='GluGluToHHTo2G4Q' # for ZZ, it is 'GluGluToHHTo2G2ZTo2G4Q'
- InputTreeCats='HHWWggTag_FH_0,HHWWggTag_FH_1,HHWWggTag_FH_2,HHWWggTag_FH_3' #input cat name in the Signal tree
- InputDataTreeCats='HHWWggTag_FH_0,HHWWggTag_FH_1,HHWWggTag_FH_2,HHWWggTag_FH_3' #input cat name in the Data tree
- SignalTreeFile="/eos/user/l/lipe/DNN_Evaluation_sample/${year}/CategorizeRootFileCondor_21Apr_WithCuts/Signal_${procs}_${node}_${year}_1_CategorizedTrees.root"
- DataTreeFile="/eos/user/l/lipe/DNN_Evaluation_sample/${year}/CategorizeRootFileCondor_21Apr_WithCuts/Data_${year}_CategorizedTrees.root"
- InputWorkspace="/eos/user/l/lipe/HHWWggWorkspace/FHDNN/" #provide a path to save workspace
- doSelections="0" #if you want to applied selections to your tree, then set it to 1
- Selections='dipho_pt > 160' #Here you can define which selections you want to set.

Also check the xs and br on the bottom lines.

After you set these options,Then you can just run:
```
sh FH.sh
```


## Contents
The Finals Fits package contains several subfolders which are used for the following steps:

* Create the Signal Model (see `Signal` dir)
* Create the Background Model (see `Background` dir)
* Generate a Datacard (see `Datacard` dir)
* Running fits with combine (see `Combine` dir)
* Scripts to produce plots (see `Plots` dir)

The signal modelling, background modelling and datacard creation can be ran in parallel. Of course the final fits (`Combine`) requires the output of these three steps. In addition, the scripts in the `Trees2WS` dir are a series of lightweight scripts for converting standard ROOT trees into a RooWorkspace that can be read by the Final Fits package.

Finally, the objects and tools which are common to all subfolders are defined in the `tools` directory. If your input workspaces differ from the flashgg output workspace structure, then you may need to change the options here.

Each of the relevant folders are documented with specific `README.md` files. Some (temporary) instructions can be found in this [google docs](https://docs.google.com/document/d/1NwUrPvOZ2bByaHNqt_Fr6oYcP7icpbw1mPlw_3lHhEE/edit)
