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
 set minstn="8"
else
 set minstn=$1
endif
if ($2 == "") then
 set tdif="200"
else
 set tdif=$2
endif
if ($3 == "") then
 set ratio="2.0"
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
#  This Program Should Be Run One Directory Above the Station Directories
#
  if (-e reftrg.out) then
    rm -f reftrg.out
  endif
  echo "STA = $sta" > reftrg.out
  echo "LTA = $lta" >> reftrg.out
  echo "RATIO = $ratio" >> reftrg.out
  if (-e trigtimes) then
    rm trigtimes
  endif
  # filter the z-direction files for each day, *.BHZ.sac
  foreach i (AT*)
  echo "working on directory $i ..."
   cd $i
 # Filtering the Files
   filtersacnew BHZ 0.4 2 > ../filter.out 
   rm -f filter.out
   cd filter
   if (-e trigtimes) then
    rm trigtimes
   endif
   if (! -e trigtimes) then
    touch trigtimes
   endif
foreach sacfile (*.BHZ*SAC)
reftrg << EOF >> ../../reftrg.out
$sacfile
$sta
$lta
$ratio
0.0 
EOF
end
  cat trigtimes >> ../../trigtimes
#  rm trigtimes
  cd ..
#  rm -rf filter
  cd ..
  end
# Running Network Triggering:
if (-e nettrg.out) then
 rm nettrg.out
endif
nettrg << EOF >> nettrg.out
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
