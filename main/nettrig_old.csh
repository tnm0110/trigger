#!/bin/csh
#
unalias mv
unalias cp
unalias rm
unset noclobber
# I/O
if ($1 == "-h") then
 goto useage
endif
if ($1 == "") then
 set minstn="4"
else
 set minstn=$1
endif
if ($2 == "") then
 set tdif="120"
else
 set tdif=$2
endif
if ($3 == "") then
 set ratio="1.70"
else
 set ratio=$3
endif
if ($4 == "") then
 set sta="10"
else
 set sta=$4
endif
if ($5 == "") then
 set lta="50"
else
 set lta=$5
endif
#
#  This Program Should Be Run One Directory Above the R Directories
#
  if (-e reftrg.out) then
    rm -f reftrg.out
  endif
  if (-e segy2sac.out) then
    rm -f segy2sac.out
  endif
  echo "STA = $sta" > reftrg.out
  echo "LTA = $lta" >> reftrg.out
  echo "RATIO = $ratio" >> reftrg.out
  if (-e trigtimes) then
    rm trigtimes
  endif
  # filter the z-direction files for each day, *.4.sac
  foreach i (R*.01)
  echo "working on directory $i ..."
   cd $i
  # Convert segy files to sac files
   foreach segyfile (*.4)
   segy2sac $segyfile >> ../segy2sac.out
   end
   filtersac all 0.5 2 > ../filter.out 
   rm -f filter.out
   cd filter
   if (! -e trigtimes) then
    touch trigtimes
   endif
foreach sacfile (*.4.sac)
reftrg << EOF >> ../../reftrg.out
$sacfile
$sta
$lta
$ratio
0.0 
EOF
end
  cat trigtimes >> ../../trigtimes
  rm trigtimes
  cd ..
  rm *.4.sac
  rm -rf filter
  cd ..
  end
# Running Network Triggering:
nettrg << EOF
trigtimes
$minstn
$tdif
EOF
echo "all done"
exit
useage:
echo "nettrig.csh minstn tdiff ratio sta lta     where"
echo ""
echo "minstn is the minimum stations required for a network trigger"
echo "tdiff is the minimum time difference for a network trigger"
echo "sta is the short term average"
echo "lta is the long term average"
echo "ratio is the triggering ratio"
exit
