      program reftrg
c
c     routine to apply the reftek trigger algorithm
c     to a designated SAC file
c     LTA is initialized to STA after 2 STA time constants
c     Trigger detection begins after trgdly seconds
c
c     compile with: f77 reftrg.f $SACDIR/lib/sac.a -f68881
c
c

      parameter(rmintrg=0.0,maxpts=100000000)
      character*60 file
      character*8 stn
      real lta,sta,ratio,xmean
      integer switch

c
c    Dimension huge arrays for application to long time windows
c

      real x(maxpts),trig(maxpts)
      real ysta(maxpts),ylta(maxpts)
      real rat(maxpts)
      real*8 epictime,epictrg,epicdtrg
C     real*8 trigtime
      integer*8 nepictrg,nepic
      integer yearold,dayold,hourold,minold,secold,window
c.langin
c  write the trigger times to a file called 'trigtimes'
      open(unit=10, file='trigtimes', status='old', access='append')
c
c    get input info
c
      write(6,100) 
  100 format('Enter SAC file: ',$)
      read(5,'(a60)') file

      write(6,102)
  102 format('Enter duration for STA (in secs): ',$)
      read(5,*) sta

      write(6,101)
  101 format('Enter duration for LTA (in secs): ',$)
      read(5,*) lta

      write(6,103)
  103 format('Enter STA/LTA ratio: ',$)
      read(5,*) ratio

      write(6,104)
  104 format('LTA will be initialized to STA after 2 STA times',
     *       /,'Enter time delay (in seconds from begining of',
     *         ' trace)',/,'before start of trigger detection: ',$)
      read(5,*) trgdly
      window=0
      do 900 i=1,maxpts
  900 x(i) = 0.0
c
c    get the trace data
c

      call rsac1(file,x,npts,beg,dt,maxpts,nerr)

      call getnhv('nzyear',ny,nerr)
      call getnhv('nzjday',nd,nerr)
      call getnhv('nzhour',nh,nerr)
      call getnhv('nzmin',nm,nerr)
      call getnhv('nzsec',ns,nerr)
      call getnhv('nzmsec',nms,nerr)
      call getkhv('kstnm',stn,nerr)
      call convepic(ny,nd,nh,nm,ns,nepic)
      epictime=dfloat(nepic) + float(nms)/1000
      print*,file
      print*,"epictime=",epictime,nepic
      print*,ny,nd,nh,nm,ns
c      call epicconv(nepic,nty,ntd,nth,ntm,nts)
c      print*,"test=",nty,ntd,nth,ntm,nts
c      print*,"real=",ny,nd,nh,nm,ns
c
c   establish number of points in LTA and STA windows
c    as well as in trgdly
c

      nlta=int(lta/dt) + 1
      nsta=int(sta/dt) + 1
      ntdly=int(trgdly/dt) + 1
c
c  n100 is number of data points in 100 second window
c      (needed for data mean calculation)
c
      n100=int(100./dt) + 1
c
c     clta and csta are constants in trigger algoritms
c

      clta=1./real(nlta)
      csta=1./real(nsta)

      xmean=0.0
c
c    start the triggering process
c

      switch=0
      trigtime=10 + rmintrg
      print*,'npts=',npts
      do 3 i=1,npts
         nmean=i
         xmean=xmean +x(i)
c
c    after 100 seconds, data mean is mean of previous 100 seconds only
c

         if(i.ge.n100) then
                xmean=xmean - x(i-n100)
                nmean=n100
         endif
c
c    LTA value calculated as per REFTEK algorithm
c

         ylta(i)= clta*abs(x(i) - xmean/real(nmean))
     *          + (1-clta)*ylta(i-1)
c
c    STA value calculated as per REFTEK algorithm
c

         ysta(i)= csta*abs(x(i) - xmean/real(nmean))
     *          + (1-csta)*ysta(i-1)
c
c   trig is array that logs trigger status at each time point
c        trig(i) = 0.0 ===> No trigger declared
c        trig(i) = 1.0 ===> A trigger has been declared
c

         trig(i)=0.0

c
c   fix LTA to STA value after 2 STA time constants
c   just to get the process started
c

         if(i.eq.2*nsta) ylta(i)=ysta(i)

c
c   rat(i) is STA/LTA at each time point
c          rat is not calculated until LTA is initialized
c

         if(i.ge.2*nsta) rat(i)=ysta(i)/ylta(i)

c
c   start triggering after trgdly seconds
c   trgdly should be more than 2 STA time constants
c   
         if(i.ge.ntdly) then
c*Sandvol  Write Start Time:
              if ((rat(i).gt.ratio).and.(switch.eq.0)) then
               if (trigtime.le.rmintrg) then
                   switch=1 
                   goto 3
               endif
               switch=1
               time=i*dt+beg
               epictrg=epictime + time
               print*,"triggered=",epictrg,time,rat(i),stn
               nepictrg=dint(epictrg)
               write(6,'(i16,x,f18.2)')nepictrg,epictrgcd 
               call epicconv(nepictrg,ny2,nd2,nh2,nm2,ns2)              	   	       	   
              endif
c*Sandvol  Write end time
              if ((rat(i).le.ratio).and.(switch.eq.1)) then
               switch=0
               time=i*dt+beg
               epicdtrg=epictime + time
               trigtime=epicdtrg-epictrg
c               if(nm2.ge.window) then
                write(10,199)ny2,nd2,nh2,nm2,ns2,trigtime,stn
                yearold=ny2
	        dayold=nd2
	        hourold=nh2
	        minold=nm2
	        secold=ns2
	        window=minold+2
c	       endif    
              endif
              if (rat(i).gt.ratio) trig(i)=1.0
           endif
      
c
 
    3 continue

c
c      find blank in filename
c
      do 4 i=1,32
         if(file(i:i).eq.' ') then
            iblnk=i-1
            go to 5
          endif
    4 continue
      write(6,*) 'no blanks in filename???'
    5 continue
c
c     file.sta contains the STA vs. time trace
c
c.langin     file(1:iblnk+4)=file(1:iblnk)//'.sta'
c.langin      call wsac1(file,ysta,npts,beg,dt,nerr)
c
c     file.lta contains the LTA vs. time trace
c
c.langin      file(1:iblnk+4)=file(1:iblnk)//'.lta'
c.langin      call wsac1(file,ylta,npts,beg,dt,nerr)
c
c     file.trig contains the trigger flag vs. time trace
c
c      file(1:iblnk+5)=file(1:iblnk)//'.trig'
c      call wsac1(file,trig,npts,beg,dt,nerr)
c
c     file.ratio contains the STA/LTA ratio vs. time trace
c
c.langin      file(1:iblnk+6)=file(1:iblnk)//'.ratio'
c.langin      call wsac1(file,rat,npts,beg,dt,nerr)

199   format(2x,i4,x,i3,x,i2,':',i2,':',i2,2x,f9.2,2x,a8)
      close(unit=10)
      stop 
      end
      
      subroutine epicconv(etime,ny,nd,nh,nm,ns)
C***  Converts epic time (number of seconds past 01/01/1970)
c***  to calender dates
      integer nh,nm,ns,ny,nd
      integer*8 etime
C      write(6,*)'Enter the Epic time'
C      read(5,'(i12)')etime
c      ny=int(float(etime)/31557600.) + 1970
c      ntemp=mod(etime,31557600)
      ntd=int(float(etime)/86400.)
      ncor=etime-(ntd*86400)
      if (ntd.lt.0) then
        if (ncor.gt.0) then
          print*,'found error with int function, correcting...'
          ntd=ntd+1
         endif
      endif
      if (ncor.lt.0) then
        print*,'found error with int function, correcting...'
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
C      print*,'Calendar Time=',ny,nd,nh,nm,ns
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

     
