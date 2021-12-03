      subroutine user_sub(imsgin,xmsgin,cmsgin,msgtyp,nwds,ierr1)
C
C
C #####################################################################
C
C     PURPOSE -
C
C        Process user supplied commands
C
C     INPUT ARGUMENTS -
C
C        imsgin - integer array of tokens returned by parser
C        xmsgin - real array of tokens returned by parser
C        cmsgin - character array of tokens returned by parser
C        msgtyp - integer array of token types returned by parser
C
C     OUTPUT ARGUMENTS -
C
C        ierr1 - 0 for successful completion - -1 otherwise
C
C
C #####################################################################
C$Log: lagrit_main.f,v $
CRevision 2.00  2007/11/05 19:48:30  spchu
CImport to CVS and change file name from adrivgen.f to lagrit_main.f
C
      character*32 cmsgin(nwds)
      integer imsgin(nwds),msgtyp(nwds)
      integer nwds,ierr1,lenc
      real*8 xmsgin(nwds)
C  get command length
      lenc=icharlnf(cmsgin(1))
C  Insert code here to handle user coded subroutines
C  For example
C   if(cmsgin(1)(1:lenc).eq.'my_cmnd') call my_rtn(imsgin,xmsgin
C          cmsgin,msgtyp,nwds,ierr1)
C
      if(cmsgin(1)(1:lenc).eq.'fiximts') then
c        call fiximts()
         ierr1=0
      else
         ierr1=-1
      endif
      return
      end
