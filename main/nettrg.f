      program nettrg
c
c     This program takes trigger times from reftrg and uses a
c      perform a network trigger.
c
c     compile with: f77 nettrg.f $SACDIR/lib/sac.a -f68881
c
c
      parameter(rmtrgtime=.05,maxstn=4500)
      character*80 infile
      character*8 stn,stnar(maxstn)
      real trigtime,trglen(maxstn)
      integer*8 tdiff,mintime
      integer*8 nepic,trg(maxstn),tlist(maxstn)
      integer ny,nd,nh,nm,ns,nstn,ic,ntlist(maxstn)
      integer stnlist(maxstn,maxstn),trgstn(maxstn)
C***** Take Care of I/O
      write(6,*)'Enter the Trigger Time File'
      read(5,'(a80)')infile
      open(1,file=infile,status='old')
      write(6,*)'Enter the Minimum Number of Stations For Triggering'
      read(5,'(i3)')minstn
      write(6,*)'Enter the Minimum Time Difference Required for a '
      write(6,*)'Network Trigger in Seconds '
      read(5,'(i8)')mintime
      ic=0
      nstn=0
10    read(1,101,end=99)ny,nd,nh,nm,ns,trigtime,stn
c      print*,'stn',stn
      if (trigtime.lt.rmtrgtime) goto 10 
      call convepic(ny,nd,nh,nm,ns,nepic)
c      print*,'epic time :',nepic
C**** Take Care of Sorting Stations:
      if (nstn.gt.0) then
       nsc=0
       do 20 i=1,nstn
c	print*,'stnar(i),stn',stnar(i),':',stn
         if (stn.eq.stnar(i)) then
           nsc=i
         endif 
20     continue
       if (nsc.eq.0) then
         nstn=nstn+1
         nsc=nstn
         stnar(nsc)=stn
       endif
      else   
       nstn=nstn+1
       nsc=nstn
       stnar(nsc)=stn
      endif
C**** Create trigger array:
      ic=ic+1
      trg(ic)=nepic
      trgstn(ic)=nsc
      trglen(ic)=trigtime
c      print*,'trg1=',trg(ic),ic,trg(1)
      print*,'trigger#: ',ic
      goto 10
99    ntimes=ic
c      print*,'trg3=',trg(1)
      print*,'Number of Triggers Read in: ',ntimes
      ic=0
C**** Do Network Triggering:
      do 30 ii=1,ntimes
c      print*,'trg2=',trg(ii),ii
c        print*,trglen(ii)
        if (trglen(ii).eq.0) goto 30
        ic2=0
        do 31 jj=ii+1,ntimes
c          print*,'trg(ii):',trg(ii)
          if (trglen(jj).ne.0) then
           tdiff=abs(trg(ii)-trg(jj))
c           print*,'tdiff=',tdiff
           if (tdiff.le.mintime) then
C*** Remove Redundant Triggers For Same Station
            if (trgstn(jj).eq.trgstn(ii)) then
             trglen(jj)=0.0
             goto 31
            endif
            if (ic2.gt.0) then
              do 33 ll=1,ic2+1
                if (trgstn(jj).eq.stnlist(ic,ll)) then
                 trglen(jj)=0.0
                 goto 31
                endif
33            continue
             endif       
C****
            ic2=ic2+1
            if (ic2.eq.1) ic=ic+1
            if (ic2.eq.1) then
              tlist(ic)=trg(ii)
              stnlist(ic,ic2)=trgstn(ii)
              stnlist(ic,ic2+1)=trgstn(jj)
              trglen(jj)=0.0
              trglen(ii)=0.0
              ntlist(ic)=1
            else
              ntlist(ic)=ntlist(ic)+1
              trglen(jj)=0.0
              stnlist(ic,ic2+1)=trgstn(jj)
c              print*,tlist(ic),ntlist(ic),ic
            endif
           endif
         endif  
31      continue
30    continue
      ntimes=ic
C***** Ouput the network triggers to a file:
      open(9,file='net_trgtimes')
      do 40 ii=1,ntimes
       if (ntlist(ii).ge.minstn) then
        call epicconv(tlist(ii),ny,nd,nh,nm,ns)
c	print*,'ii,ntlist(ii)',ii,ntlist(ii)
        print*,ny,nd,nh,nm,ns,ntlist(ii)
        write(9,102)ny,nd,nh,nm,ns,ntlist(ii)
        if (ntlist(ii).gt.nstn) then
          print*,'ERROR:  Too Many Stations in Station List'
          print*,'Correcting Number of Stations To:',nstn
          ntlist(ii)=nstn
        endif
        write(9,'(50a8)')(stnar(stnlist(ii,jj)),jj=1,ntlist(ii))
c	print*,'stnar(stnlist(ii,jj))',stnar(stnlist(ii,jj))
c	print*,'    stnlist(ii,jj),ii,jj',stnlist(ii,jj),ii,jj
       endif
40    continue
      close(9)
102   format(2x,i4,1x,i3,1x,i2,':',i2,':',i2,6x,i6)
101   format(2x,i4,1x,i3,1x,i2,':',i2,':',i2,5x,f6.2,2x,a8)
C****
      stop
      end
      subroutine epicconv(etime,ny,nd,nh,nm,ns)
C***  Converts epic time (number of seconds past 01/01/1970)
c***  to calender dates
      integer nh,nm,ns,ny,nd
      integer*8 etime,nsec,ntd,ncor
C      write(6,*)'Enter the Epic time'
C      read(5,'(i12)')etime
c      ny=int(float(etime)/31557600.) + 1970
c      ntemp=mod(etime,31557600)
      ntd=int(float(etime)/86400.)
      ncor=etime-(ntd*86400)
C      print*,'ntd, ncore=',ntd,ncore
      if (ntd.lt.0) then
        if (ncor.gt.0) then
          print*,'found error with int function ncor > 0, correcting...'
          ntd=ntd+1
         endif
      endif
      if (ncor.lt.0) then
        print*,'found error with int function ncor < 0, correcting...'
        ntd=ntd-1
      endif
C      print*,'ntd=',ntd
      ny=int(float(4*ntd - 2)/1461)
      numld=int((ny-3)/4.0) + 1
C      print*,'numld=',numld
      nd=ntd-(ny*365+numld)
      ny=ny+1970
      ntemp=mod(etime,86400)
C      print*,'nd=',nd
c      
      ntemp=mod(etime,86400)
c
c Correct for strange origin time 1969:365:04:00:00.0
c      nh=int(float(ntemp)/3600) + 20
      nh=int(float(ntemp)/3600)
C      print*,'ntemp=',ntemp,nh
c      nh=int(float(ntemp)/3600.)
c Correct for origin time 1970:01:00:00:00.0
       nd=nd+1
       if (nd.gt.365) then
        if (mod(ny,4).eq.0) then
           if (nd.gt.366) then
            ny=ny+1
            nd=nd-366
           endif
           goto 20
         endif
         nd=nd-365
         ny=ny+1
       endif
20    continue          
      ntemp=mod(etime,3600)
      nm=int(float(ntemp)/60)
      ns=mod(etime,60)
c      print*,'Calendar Time=',ny,nd,nh,nm,ns
      nyr=ny-1970
      nsec=((nyr)*365+((nyr-3)/4) + 1)*24*3600
      nsec=nsec+(nd-1)*24*3600
      nsec=nsec+nh*3600
      nsec=nsec+nm*60 
      nsec=nsec+ns
c      nsec=nsec+ns-90000
c      nsec=nsec+ns-72000
c      etime=etime+72000
      ndiff=nsec-etime
C      if (ndiff.eq.0) then
C       print*,'------No Error------'
C       print*,'theoretical,given epic time=',nsec,etime
C      endif
      if (ndiff.ne.0) then
       print*,'**********Error Ocurred with data********'
       print*,'theoretical, given epic time=',nsec,etime
      endif
      return
      end 
      subroutine convepic(ny,nd,nh,nm,ns,nsec)
C***  Converts epic time (number of seconds past 01/02/1970)
c***  to calender dates
      integer nh,nm,ns,ny,nd
      integer*8 nsec
      nyr=ny-1970
      nsec=((nyr)*365+((nyr-3)/4) + 1)*24*3600
      nsec=nsec+(nd-1)*24*3600
      nsec=nsec+nh*3600
      nsec=nsec+nm*60 
      nsec=nsec+ns
c      nsec=nsec+ns-90000
c      nsec=nsec+ns-72000
      return
      end  

     
