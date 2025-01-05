#!/bin/csh

######################################################################################################################
#               Shell script to run triggering code. This script runs two fortan program; first reftrg--             #
#    to get individual station triggers and then nettrg2-- to correlate the triggered impulse to all available       #
#    stations.Directory needs to be organized by satation wise and should contatin daylog SAC files ( Z components ) # 
#                        (Change the  correct program path before running)					     #
#														     #
#                        	        Md Mohimanul Islam							     #
#                          	  University of Missouri Columbia   						     #
#                                            02/23/2021                                                              #
######################################################################################################################
unalias mv
unalias cp
unalias rm
unset noclobber
#

# set the program directory
set pdir="/mnt/beryl/mibhk/trigger_test/sac/progdrc"
set ddir="/mnt/beryl/mibhk/trigger_test/sac"

cd $ddir
rm -rf trigtimes
touch trigtimes
set stn=`ls -d */`

foreach i ($stn)

    cd $i
set nsac=`ls *SAC | wc -l`
    echo $nsac
if  ($nsac == 0)  then
    echo "No SAC files to process"
    cd ../
else
# create directory for filtered signals
   if (! -d filt.det) then
     mkdir filt.det
   endif

 # filter the z-direction files for each day, *.Z.sac
 
   echo "macro $pdir/autofilch5 0.4 3" | sac
   cp *.HHZ*.SAC filt.det

 # go to the directory of filtered signals and execute the event detector
 cd filt.det
 # create trigger time file
rm -rf trigtimes
touch trigtimes 

# event detection with reftrg algorithm 
#input : 1.Short time average (STA) [sec]
#        2.Long time average (LTA)  [sec]
#        3. STA/LTA ratio    
#        4.Enter time delay from the begining of trace [sec] 

foreach sacfile (*.HHZ**.SAC)
$pdir/reftrg2 << EOF >> ../../out.reftrg
$sacfile
1.0
5.0
2.0
0.0 
EOF
end
cat trigtimes >> ../../trigtimes
cd ../

endif

cd ../
end

echo "done Station triggering"

# Now run the Network Trigger Algorithom
# input: 1. trigger file name 
#        2. Minimum station required to register trigger
#        3. Minimum time difference for a network trigger; 
#        4. Early Time Shift Before Trigger Time 
#
cd $ddir
 if (-e out.nettrg2) then
  rm out.nettrg2
  endif
$pdir/nettrg2 << EOF >> out.nettrg2
trigtimes
5
200
120
EOF
echo "done Network triggering"


# Now reform the triggered time into correct format
# the format::
#                YYYY JDY HHMMSS.S
#
rm -rf triggered_events
cp net_trgtimes triggered_events
$pdir/rfrmsrch2 << EOF >> out.rfrmsrch2 
triggered_events
EOF

echo "All finished"
