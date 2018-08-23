#!/usr/bin/env python

# Usual reasons to love python imports
import os
import sys
import shlex
from array import array
import ROOT as r

#ext='fullStage1Test'
#ext='fullStage1Test_DCB'
ext='reCategorised'
#ext='reCategorised_DCB'

r.gSystem.Load("libHiggsAnalysisCombinedLimit")
r.gSystem.Load("libHiggsAnalysisGBRLikelihood")

##procs=['ggh','vbf','zh','wh','tth']
#procs=['GG2H','VBF','TTH','QQ2HLNU','QQ2HLL','WH2HQQ','ZH2HQQ','testBBH','testTHQ','testTHW']
#cats=['UntaggedTag_0','UntaggedTag_1','UntaggedTag_2','UntaggedTag_3','VBFTag_0','VBFTag_1','VBFTag_2','TTHLeptonicTag','TTHHadronicTag','ZHLeptonicTag','WHLeptonicTag','VHLeptonicLooseTag','VHHadronicTag','VHMetTag']

#setup files 
#baseFilePath  = '/vols/cms/es811/FinalFits/ws_%s/'%ext
baseFilePath  = '/vols/cms/es811/FinalFits/ws_reCategorised/'
fileNames     = []
for root,dirs,files in os.walk(baseFilePath):
  for fileName in files: 
    if not fileName.startswith('output_'): continue
    if not fileName.endswith('.root'):     continue
    fileNames.append(fileName)
fullFileNames = '' 
for fileName in fileNames: fullFileNames += baseFilePath+fileName+','
fullFileNames = fullFileNames[:-1]
files125 = ''
for fileName in fileNames: 
  if 'M125' in fileName: files125 += baseFilePath+fileName+','
files125 = files125[:-1]
#print 'fileNames = %s'%fullFileNames

#define processes and categories
procs         = ''
for fileName in fileNames: 
  if 'M125' not in fileName: continue
  procs += fileName.split('pythia8_')[1].split('.root')[0]
  procs += ','
procs = procs[:-1]
#cats          = 'RECO_0J,RECO_1J_PTH_0_60,RECO_1J_PTH_60_120,RECO_1J_PTH_120_200,RECO_1J_PTH_GT200,RECO_GE2J_PTH_0_60,RECO_GE2J_PTH_60_120,RECO_GE2J_PTH_120_200,RECO_GE2J_PTH_GT200,RECO_VBFTOPO_JET3VETO,RECO_VBFTOPO_JET3,RECO_VH2JET,RECO_0LEP_PTV_0_150,RECO_0LEP_PTV_150_250_0J,RECO_0LEP_PTV_150_250_GE1J,RECO_0LEP_PTV_GT250,RECO_1LEP_PTV_0_150,RECO_1LEP_PTV_150_250_0J,RECO_1LEP_PTV_150_250_GE1J,RECO_1LEP_PTV_GT250,RECO_2LEP_PTV_0_150,RECO_2LEP_PTV_150_250_0J,RECO_2LEP_PTV_150_250_GE1J,RECO_2LEP_PTV_GT250,RECO_TTH_LEP,RECO_TTH_HAD'
#cats          = 'RECO_0J,RECO_1J_PTH_0_60,RECO_1J_PTH_60_120,RECO_1J_PTH_120_200,RECO_1J_PTH_GT200,RECO_GE2J_PTH_0_60,RECO_GE2J_PTH_60_120,RECO_GE2J_PTH_120_200,RECO_GE2J_PTH_GT200,RECO_VBFTOPO_JET3VETO,RECO_VBFTOPO_JET3,RECO_VH2JET,RECO_0LEP_PTV_0_150,RECO_0LEP_PTV_150_250_0J,RECO_0LEP_PTV_150_250_GE1J,RECO_0LEP_PTV_GT250,RECO_1LEP_PTV_0_150,RECO_1LEP_PTV_150_250_0J,RECO_1LEP_PTV_150_250_GE1J,RECO_1LEP_PTV_GT250,RECO_2LEP_PTV_0_150,RECO_TTH_LEP,RECO_TTH_HAD' #zero entry cats removed
cats  = 'RECO_0J_Tag0,RECO_0J_Tag1,RECO_1J_PTH_0_60_Tag0,RECO_1J_PTH_0_60_Tag1,RECO_1J_PTH_60_120_Tag0,RECO_1J_PTH_60_120_Tag1,RECO_1J_PTH_120_200_Tag0,RECO_1J_PTH_120_200_Tag1,RECO_1J_PTH_GT200,'
#cats += 'RECO_GE2J_PTH_0_60_Tag0,RECO_GE2J_PTH_0_60_Tag1,RECO_GE2J_PTH_60_120_Tag0,RECO_GE2J_PTH_60_120_Tag1,RECO_GE2J_PTH_120_200_Tag0,RECO_GE2J_PTH_120_200_Tag1,RECO_GE2J_PTH_GT200_Tag0,RECO_GE2J_PTH_GT200_Tag1,RECO_VBFTOPO_JET3VETO_Tag0,RECO_VBFTOPO_JET3VETO_Tag1,RECO_VBFTOPO_JET3_Tag0,RECO_VBFTOPO_JET3_Tag1,'
cats += 'RECO_GE2J_PTH_0_60_Tag0,RECO_GE2J_PTH_0_60_Tag1,RECO_GE2J_PTH_60_120_Tag1,RECO_GE2J_PTH_120_200_Tag0,RECO_GE2J_PTH_120_200_Tag1,RECO_GE2J_PTH_GT200_Tag0,RECO_GE2J_PTH_GT200_Tag1,RECO_VBFTOPO_JET3VETO_Tag0,RECO_VBFTOPO_JET3VETO_Tag1,RECO_VBFTOPO_JET3_Tag0,RECO_VBFTOPO_JET3_Tag1,'
cats += 'RECO_WHLEP,RECO_ZHLEP,RECO_VHLEPLOOSE,RECO_VHMET,RECO_VHHAD,'
cats += 'RECO_TTH_LEP,RECO_TTH_HAD'
procs = procs.split(',')
cats  = cats.split(',')
print 'with processes: %s'%procs
print 'and categories: %s'%cats
rvwv=['rv','wv']

for proc in procs:
  for cat in cats:
    f = r.TFile("outdir_%s/CMS-HGG_sigfit_%s_%s_%s.root"%(ext,ext,proc,cat))
    w = f.Get("wsig_13TeV")
    #w.Print();
    #exit(1)
    MH = w.var("MH")
    mass = w.var("CMS_hgg_mass")
    for v in rvwv:
     print " consider ", proc, cat, v
     nGaussian=-1
     coeffs=[]
     #dynamiccaly get nGaussians
     pdf= w.pdf("hggpdfsmrel_13TeV_%s_%s_%s_13TeV"%(proc,cat,v));
     #pdf= r.RooDoubleCBFast(w.pdf("dcb_%s_%s_%s_13TeV"%(proc,cat,v)),"test");
     pdf.Print()
     #exit (1)
     d=119.9
     increment=0.1
     while (d<130.0):
       d=d+increment
       MH.setVal(d)
       m=179.875
       #norm = pdf.createIntegral(r.RooArgSet(mass,MH))
       #thisint= norm.getVal()
       h =pdf.createHistogram("htemp_%.2f_%.2f_%s_%s_%s"%(d,m,proc,cat,v),mass)
       h.Print()
       #print "integral " , thisint
       #while (m<179.9):
        #mass.setVal(m)
        #print " this is the value of ", pdf.GetName() , " at mh= ", d , " and mgg= ", m ,  "  : " ,  
        #thiseval =pdf.evaluate(), " norm ", 
        #m=m+increment
    #exit(1)
     