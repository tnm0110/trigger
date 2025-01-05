#!/bin/csh
#
unalias mv
unalias cp
unalias rm
unset noclobber
#
# This script shoud be executed on files while in the station directory
# Filter and detect for each station
#foreach st (st*)
# if (-d $st) then
#  cd $st
  # create directory for filtered signals
  if (! -d filt.det) then
    mkdir filt.det
  endif
  # filter the z-direction files for each day, *.4.sac
 # foreach i (AT*.1)
 #  cd $i 
   echo "macro $SRCHOME/sacmacs/autofilch5 0.4 3" | sac
   mv *.BHZ.SAC ../filt.det
   cd ..
 # end
  # go to the directory of filtered signals and execute the event detector
  cd filt.det
  # create trigger time file
  if (! -e trigtimes) then
    touch trigtimes
  endif
# event detection with reftrg algorithm
foreach sacfile (*.BHZ.SAC)
reftrg << EOF
$sacfile
1.0
5.0
2.0
0.0 
EOF
end
#rm *.4.sac
mv trigtimes ../
# endif
#end
echo "done"
exit

