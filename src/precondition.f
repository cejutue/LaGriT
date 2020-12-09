*dk precondition
      subroutine precondition(nrows, ncols, ncoefs, AFP,
     *                  INDEX_ROW, INDEX_COL, UMAT, BMAT, DMAT, XMAT)
C
C ######################################################################
C
C        $Log: precondition.f,v $
C        Revision 2.00  2007/11/09 20:03:58  spchu
C        Import to CVS
C
C
CPVCS
CPVCS       Rev 1.21   02 Oct 2007 12:40:28   spchu
CPVCS    original version
C
C#######################################################################
C
C
C     SCALE ALL THE EMEMENTS IN THE 2D MATRIX SUCH THAT THE
C        DIAGONAL ELEMENTS ARE UNITY.
C
C     implicit double precision (a-h, o-z)
C     dimension AFP(ncoefs)
C     dimension INDEX_ROW(ncoefs)
C     dimension INDEX_COL(ncoefs)
C     dimension UMAT(nrows), BMAT(nrows), XMAT(nrows)
C     dimension DMAT(nrows)

      implicit none

      integer nrows, ncols, ncoefs, i

      real*8  AFP(ncoefs)
      integer INDEX_ROW(ncoefs)
      integer INDEX_COL(ncoefs)
      real*8  UMAT(nrows), BMAT(nrows), XMAT(nrows)
      real*8  DMAT(nrows)


CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C     COLLECT THE DIAGONAL ELEMENTS FROM THE 2D MATRIX (AMAT).
C
      do i=1,ncoefs
         if(INDEX_ROW(i).eq.INDEX_COL(i)) then
            DMAT(INDEX_ROW(i))=sqrt(AFP(i))
         endif
      enddo
C
C     SCALE THE ELEMENTS OF "AFP" SUCH THAT ALL ELEMENTS ARE UNITY.
C
      do i=1,ncoefs
         AFP(i)=AFP(i)/(DMAT(INDEX_ROW(i))*DMAT(INDEX_COL(i)))
      enddo
C
C     SCALE THE RIGHTHAND SIDE.
C
      do i=1,nrows
         XMAT(i)=DMAT(i)*UMAT(i)
      enddo
      do i=1,nrows
         BMAT(i)=BMAT(i)/DMAT(i)
      enddo
C
C
C
      goto 9999
 9999 continue
      return
      end
