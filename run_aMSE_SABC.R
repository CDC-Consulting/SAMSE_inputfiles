
 options("show.signif.stars"=FALSE,
        "stringsAsFactors"=FALSE,
        "max.print"=50000,
        "width"=240)
suppressPackageStartupMessages({
  library(aMSE) # replaces aMSE. Use this when want to run FISs
  library(codeutils)
  library(hplot)
  library(makehtml)
  library(knitr)
  library(tidyr)
  library(dplyr)
})

# Step 1: Set up directories and inputs  ----

# Point to your directory e.g. your Gitdir 
# as an example
prefixdir <- paste0(Gitdir,"sizemod_SA/aMSE_runs_final/")

depletion_scenarios <- "DBC" # catch scenario
scenario <- "M20h70L075" # operating model settings, BC

## 1a SA HS directories -----
HS <- "SAHS" # harvest strategy used
inertiaHS <- "_BCFleet05" # Used the BC fleet model
postfixdir <- paste0(scenario,depletion_scenarios,"_",HS,inertiaHS) # SAHS

## 1b All HS ----
verbose <- TRUE
FIS <- TRUE ## NB NB this is important to set which HS
rundir <- path.expand(filenametopath(prefixdir,postfixdir)) # run directory
outdir <- rundir # save output in the same place

# set the directory of where you want to save the RData, example below
RDAsavedir <- path.expand(filenametopath(Dropboxdir,"NationalMSERuns/aMSE_RData/Comparison")) 

# set the control file
controlfile <- paste0("controlSA6_",scenario,depletion_scenarios,".csv") # SA BC

# Step 2a: Run SA HS if already conditioned ----

FIS <- FALSE # Set whether you want to include the FIS, BC is FALSE

# Note the below R files are only available on request to SARDI
  source(pathtopath(Gitdir,"AbHS_new/R/FISfiles/newcandidates.R"))
  source(paste0(Gitdir,"abHS_new/R/sahs_funs_new_fis.R")) # new version f for fast
  source(paste0(Gitdir,"AbHS_new/R/SA_HS_fis.r"))
  HS_SA <- SA_HS_fis


# Create the hsargs for South Australia
hsargs <- list(SAZoneSettings="CZ", # The Zone, if conditioned on Tipara reef, then set at "CZ"
               SA_Spp="GL", # Species, for SA operating model this will be "GL", else "BL"
               hcrname = "SA_HS", #SA_HS_BC05", # HCR name
               CPUE_weight=0.5, # relative weight of CPUE:FIS to the scoring
               FIS_weight=0.5, # as above
               prop_catch_time_period=12, # BC 12, tested 6 and 18 rolling time period to calculate catch weight
               reference_period_start= 1990, # BC = 1990,#Alt ARP=2000# Start of the default cpue RP
               reference_period_end= 2000, # BC = 2000,#Alt ARP = 2010# end of the default cpue RP
               FIS_ref_period_start= 1990,#BC 1990, # default start of FIS reference period, is 1990
               FIS_ref_period_end= 2019, #no FIS in 2000,# BC 2019, # default end of FIS reference period is 2000
               startHSyear=1980, # start year for the HS loop
               startCatch=1965, # hardwired in code
               target_FBS_perc=0.4, 
               # Target percentile range for the buffer of the CPUE target function. Default is 0.4
               CPUE_target_lim= 0.8, # 1.0, # Base Case = 0.8, 
               # CPUE limit Default is 0.8 which is 20% lower than the smallest CPUE during the reference period
               CPUE_target_Max=1.2, 
               # CPUE max. Default is 1.2 which is20% of the max CPUE value from the reference period
               min_kg=2, # Minimum kg range of the buffer. Overrides the target_FBS_perc if the kg range is less than this. Default is 6 for "SZ", else 2
               FIS_buffer=0.4, # FIS buffer range
               trend_yrs=4, # Number annual differences to assess zone score trend over
               trend_buffer=.025, # Buffer of the zone trend function
               trend_limit=.33, # upper and lower limits of zone trend function
               zone_lag=1, # Scoring lag for HS - use with decrement
               decrement=1, # decrement for data. the sum of the 2 is the total lag = 2
               min_ref_period = 6, # Minimum number of years in the reference period. this stops the code, default in SA is 6
               limit_density_prop = 0.8, # The FIS limit (score 0) is set at 80% of lowest value in reference period
               implement = 0.1, # 0.0 or 0.1 (BC) implementation on the TAC as uniform random 0.1=+-10% 0.1 is the BC
               meta = "TRUE", # "TRUE" is BC, or "FALSE"
               low_meta = 0.05,#0.05, # BC 0.05 maximum catch increase; alt 0.03
               med_meta = 0.15, # BC 0.15 maximum catch increase; alt 0.05
               #startHSyear = 1980, # start year for the HS loop
               BaseTAC = NULL # BC = NULL this sets the BaseTAC. If NULL then uses the mean of the reference period. Note EYP is hardwired in the code as so many periods of closure so can't really be changed; ARP scenario BaseTAC=46
               #Catch_prop = Catch_prop not needed for SA dynamics
)

hsargs$inertia <- 0.5 #0.5 or 0 # weight of inertia i.e. historical catch or lagcatch. Flletdynamics will then be 1-w1
#hsargs$fleetdyn <- "safleetdyn" # fleet dynamics model, NB this is the alternative model OF0 and OF05
hsargs$fleetdyn <-"safleetdyn_aveC" #- as above but inertia average Catch; this is the Base Case

#fleetdynsa <- safleetdyn # if using the alternative fleet dynamics model
fleetdynsa <-safleetdyn_aveC #- as above but inertia average Catch; this is the Base Case


# Fleet dynamics settings
SAUcatchpropargs=matrix(data = c(
  -0.23726372,  0.2421129, 0.009574468, 0.1961538, 0.5, 0.9800845, 0.1937051, 0.03213957, 0.02810636, 3.157925556,
  -0.21661025,  0.2232657, 0.013361548, 0.1289027, 0.5, 0.9690409, 0.4356354, 0.01982862, 0.01628880, 3.007643175,
  -0.31806007,  0.2934007, 0.018000000, 0.1995765, 0.5, 0.9224696, 0.2949892, 0.03198060, 0.04829169, 3.166332222,
  -0.22852414,  0.2207853, 0.002955048, 0.1951490, 0.5, 0.9532046, 0.1121821, 0.02671327, 0.02072412, 2.558536349,
  0.04070458, -0.6516648, 0.468991382, 0.0500000, 0.5, 27.5314550, 17.2379839, 0.06008154, 0.05765173, 10.06267413,
  0.04904767, -0.8651647, 0.919850793, 0.0500000, 0.5, 36.3934805, 18.6586772, 0.06942786, 0.05318132, 24.77708048),
  nrow=6, ncol=10, byrow=TRUE)

# SAU names
names <- c("WKI","SKI","EYP","DL","WYP","TIP")
SAUcatchpropargs = cbind(names,as.data.frame(SAUcatchpropargs))

colnames(SAUcatchpropargs) <- c("SAU","slope", "intercept","uppercprop",
  "lowercprop","inertiasau","upperx","lowerx", "delta_Catch_prop", 
  "delta_Catch_prop_sd", "ave_Catch") # Added new fleet dynamic values 
hsargs$SAUcatchpropargs <- SAUcatchpropargs

hsargs$SAUcatchpropargs
hsargs$startCE <- 1968 # start year of the CPUE

# FIS setup

hsargs$fisopt = "classic" # or "lmcpue" - the classic relates the fis to expl numbers,
#hsargs$fisopt = "lmcpue"  # the lmcpue uses the regressed relationship between obser fisindex and cpue

fispar=c(selL50=107.748,delta=15.64,ferrav=0,ferrsd=0.03,  #0.015,
         fisdecrement=1, power = 1, powerbias = 1) # classic FIS parameters


hsargs$fispar <- fispar

namesfis <- c("TIP", "DL", "WYP", "WKI", "SKI", "EYP")
fispar_lmcpue = matrix(data=c(0.008623271, # slope
                           -0.141576651, # intercept
                           -2.532679e-17, #residual_mean
                           0.0287244, # residual_sd
                           NA, NA, NA,NA,
                           NA, NA, NA,NA,
                           NA, NA, NA,NA,
                           NA, NA, NA,NA,
                           NA, NA, NA,NA),
                    nrow=6, ncol=4, byrow= TRUE)
colnames(fispar_lmcpue) <- c("slope", "intercept", "resid_mu", "resid_sd")
rownames(fispar_lmcpue) <- c("TIP","DL","WYP","WKI","SKI","EYP")
hsargs$fispar_lmcpue <- fispar_lmcpue

# Run the MSE (NOTE: do_MSE is continually updated. Make sure all the function settings are up to dat)
# library(profvis)  
# profvis({
if(FIS == TRUE) {
  out <- do_MSE(rundir,controlfile,hsargs=hsargs,hcrfun=HS_SA, # SA_HS_fis if FIS March 2024 file or FIS HS
              sampleCE=saCPUE,sampleFIS=saFIS,sampleNaS=saNaS, 
              getdata=sadata,calcpopC=sacalcexpectpopC,makeouthcr=samakeouthcr,
              #hcrscoreoutputs = saextractandplotscores,
              #HSPMs=sagetHSscores,
              fleetdyn = fleetdynsa, scoreplot=saplotfinalscores2,
              plotmultflags=saplotmultandflags,
              interimout= "",#outdir, #"",
              varyrs=7,startyr=38,
              verbose=TRUE,ndiagprojs=3,
              cutcatchN=56,matureL=c(40,170),wtatL=c(50,200),
              mincount=120,includeNAS = TRUE,
              depensate=0,kobeRP=c(0.4,0.2,0.15),
              nasInterval=1,minsizecomp=c(100,135),
              uplimH = 0.9, incH = 0.01, # for initial H range and step
              #fissettings=NULL,fisindex=NULL,
              deleteyrs=0, # yrs in NAs to delete
              selectyr=0, 
#              calcFIS=calcFISCPUE, 
              calcFIS = calcFIS2,
              prepareforfis=prepareforfis,
              makefisproj=sadmakefisproj) # default of 0 chooses last year's LML for MSY calcs
} else {
# if no FIS
  out <- do_MSE(rundir,controlfile,hsargs=hsargs,hcrfun=HS_SA, # SA_HS_fis if FIS March 2024 file or FIS HS
              sampleCE=saCPUE,sampleFIS=saFIS,sampleNaS=saNaS, 
              getdata=sadata,calcpopC=sacalcexpectpopC,makeouthcr=samakeouthcr,
              #hcrscoreoutputs = saextractandplotscores,
              #HSPMs=sagetHSscores,
              fleetdyn = fleetdynsa, scoreplot=saplotfinalscores2,
              plotmultflags=saplotmultandflags,
              interimout= "",#outdir, #"",
              varyrs=7,startyr=38,
              verbose=TRUE,ndiagprojs=3,
              cutcatchN=56,matureL=c(40,170),wtatL=c(50,200),
              mincount=120,includeNAS = TRUE,
              depensate=0,kobeRP=c(0.4,0.2,0.15),
              nasInterval=1,minsizecomp=c(100,135),
              uplimH = 0.9, incH = 0.01, # for initial H range and step
              #fissettings=NULL,fisindex=NULL,
              deleteyrs=0, # yrs in NAs to delete
              selectyr=0, 
              # calcFIS=calcFISCPUE, 
              calcFIS = NULL,
              prepareforfis=NULL,
              makefisproj=NULL) # d
}


# Create the output files and web view

makeoutput(out,rundir,postfixdir,controlfile,hsfile="SA_HS",
           openfile=TRUE,verbose=FALSE)


save(out, file=paste0(paste0(RDAsavedir,"/",scenario,"_",HS,inertiaHS,".RData"))) # save in the comparison folder




