      subroutine fdate(str)
C
C#######################################################################
C
C        $Log: lagrit_fdate.f,v $
C        Revision 2.00  2007/11/05 19:46:00  spchu
C        Import to CVS
C
CPVCS
CPVCS       Rev 1.21   02 Oct 2007 12:40:28   spchu
CPVCS    original version
C
C#######################################################################
C
      character *(*) str
      character*8 date
      character*10 time
      character*5 zone
      integer values(8)
      call date_and_time(date,time,zone,values)
      str=' '
      str(21:24)= date(1:4)
      str(6:7)=date(5:6)
      str(8:8)='/'
      str(9:10)=date(7:8)
      str(12:13)=time(1:2)
      str(14:14)=':'
      str(15:16)=time(3:4)
      str(17:17)=':'
      str(18:19)=time(5:6) 
      return
      end
