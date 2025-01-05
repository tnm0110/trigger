	program rmblank
c** this program reformats a file, specifically it 
c** turns blanks into zeros
	character*105 a(1000000)
	character*70 filin
	write(6,*)'Enter the input file'
	read(5,'(a70)')filin
	open(1,file=filin,status='old')
	read(1,'(a65)')a(1)
        write(6,*)'Enter the minimum and maximum characters'
        write(6,*)'between which to remove all blanks'
        read(5,'(i4)')nc1
        read(5,'(i4)')nc2
	ic=1
10	read(1,'(a95)',end=99)a(ic)
	do 21 ii=nc1,nc2
	 if (a(ic)(ii:ii).eq.' ') then
	   a(ic)(ii:ii)='0'
	 endif
 21	continue
	ic=ic+1
	goto 10
99 	num=ic-1
	rewind (1)
	do ii=1,num
	  write(1,'(a98)')a(ii)
	enddo
	stop
	end
	
	
