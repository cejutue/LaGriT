      subroutine dump_outside_list(ifile,attrib_option,area_option)
C
C #####################################################################
C
C     PURPOSE -
C
C         Output lists of nodes for top, bottom, left, right, front, back
C
C     INPUT ARGUMENTS -
C
C        ifile - Character string for naming output file
C        attrib_option - for finding and saving outside boundary nodes
C           keepatt - keeps and keeps top,bottom,left_w,right_e,back_n,front_s
C           delatt  - removes these attributes 
C        area_option - for computing voronoi or median face areas 
C           keepatt_voronoi creates and keeps xn_varea, yn_varea, zn_varea
C           keepatt_median creates and keeps xn_marea, yn_marea, zn_marea
C
C     OUTPUT ARGUMENTS -
C
C        None
C
C     CHANGE HISTORY -
C
C        $Log: dump_outside_list.f,v $
C        Revision 2.00  2007/11/05 19:45:53  spchu
C        Import to CVS
C
CPVCS    
CPVCS       Rev 1.15   19 Jul 2007 15:22:36   tam
CPVCS    added minmax option for outside directions
CPVCS    
CPVCS       Rev 1.14   15 May 2007 13:42:12   tam
CPVCS    Carl's edits to add option called keepatt_area to commands
CPVCS    option creates and keeps 3 arrays xn_area, yn_area, zn_area
CPVCS    
CPVCS       Rev 1.13   15 May 2007 12:21:14   tam
CPVCS    use DELATT to remove work attributes such as top
CPVCS    
CPVCS       Rev 1.12   26 Feb 2007 14:11:48   tam
CPVCS    changed write statement to use format 940
CPVCS    to limit line length for node list
CPVCS    
CPVCS       Rev 1.11   20 May 2005 07:57:24   gable
CPVCS    Increased char field length for zone and area file names from 32 to 128.
CPVCS    
CPVCS       Rev 1.10   10 Mar 2000 12:47:28   gable
CPVCS    Changes to insure calls to mask_icr are only inside dump_outside_list.f
CPVCS    
CPVCS       Rev 1.9   07 Feb 2000 18:32:36   gable
CPVCS    Modified by RVG to use ibnd temp array instead of icr array.
CPVCS    
CPVCS       Rev 1.8   Mon Jan 25 13:06:32 1999   llt
CPVCS    added option to keep/delete top, bottom, left_w, 
CPVCS    right_e, back_n, and front_s attributes --
CPVCS    default is to delete
CPVCS    
CPVCS       Rev 1.7   Mon Jan 25 10:13:34 1999   llt
CPVCS    modified icrflag_name to left_w, front_s, right_e, and back_n
CPVCS    
CPVCS       Rev 1.6   Wed Feb 11 15:03:36 1998   dcg
CPVCS    declare ipout to be a pointer
CPVCS
CPVCS       Rev 1.5   Wed Feb 11 10:36:40 1998   tam
CPVCS    check for existence and length of attribute before trying
CPVCS    to create it.
CPVCS
CPVCS       Rev 1.4   Mon Apr 14 16:43:46 1997   pvcs
CPVCS    No change.
CPVCS
CPVCS       Rev 1.3   Fri Oct 11 13:35:26 1996   gable
CPVCS    Changed order of output for Top,Bot, ... so that front and back are last
CPVCS    Added zone to top of files
CPVCS
CPVCS       Rev 1.2   Fri Oct 11 11:18:18 1996   gable
CPVCS    Change format so lists end with a blank line and then the word stop
CPVCS
CPVCS       Rev 1.1   Wed May 29 08:51:06 1996   gable
CPVCS    Make changes to be compatible with changes to argument list
CPVCS    of get_xcontab_node. No longer pass idof1 pointer. Also
CPVCS    clean up format.
CPVCS
CPVCS       Rev 1.0   Wed May 08 12:37:52 1996   gable
CPVCS    Initial revision.
C
C ######################################################################
C
	IMPLICIT NONE
C
C
      include "chydro.h"
c
      character*(*) ifile
      character attrib_option*(*)
      character area_option*(*)

c     variables
      character*132 log_io, dotask_command
      character*32 cmo_name, isubname, tstring
      character*128 ifilename, logmess
c
      integer
     >   ierror, ierr, ics, ierrw, 
     >   n, i, icount, itotal, 
     >   mtests, ntests, iunit, iunit2,
     >   ilenout, iatt_type, itest, length, icscode, 
     >   icharlnf, len, ilen, itype 

      integer ipat(64)
      pointer (ipout,outs)
      real*8 outs(*)
      pointer (ipxatt,xatt)
      real*8 xatt(*)
c
c     cmo variables
c
      integer
     >   ilenimt1
     > , itypimt1
      integer
     >   nnodes
     > , ilennnodes
     > , itypnnodes
      integer itypibnd
      pointer (ipimt1, imt1)
      integer  imt1(10000000)
      pointer (ipiwork, iwork)
      integer iwork(10000000)
      pointer (ipibnd, ibnd)
      integer  ibnd(10000000)
      pointer (ipiarray, iarray)
      integer iarray(1000000)
      pointer (ipxcontab_node, xcontab_node)
      real*8 xcontab_node(3,1000000)
C
C     for finding minmax of outside normal zones
C     commented out as they are no longer used
c     pointer (ipxic, xic)
c     pointer (ipyic, yic)
c     pointer (ipzic, zic)
c     real*8  xic(10000000), yic(10000000), zic(10000000)

      pointer (ipi_index, i_index)
      pointer (ipj_index, j_index)
      pointer (ipk_index, k_index)
      integer i_index(10000000),j_index(10000000),k_index(10000000)

      pointer (ipitry, itry)
      pointer (ipifound, ifound)
      integer itry(10000000), ifound(10000000)   

      integer ier,inum,nx,ny,nz,iinc, ierr_att
      integer iout_minmax,iout_voronoi,iattrib_area, 
     >        nbin,ibin,lowbin,endbin,
     >        ivalid,ileft,idone,ii,jj,icol1,icol2

c
C     MO variable arrays
C
      pointer (ipxn_area, xn_area)
      real*8 xn_area(1000000)
      pointer (ipyn_area, yn_area)
      real*8 yn_area(1000000)
      pointer (ipzn_area, zn_area)
      real*8 zn_area(1000000)

      real*8 xsum,ysum,zsum, xareat, area_x, area_y, area_z
c
      integer io_order(6)
      data io_order / 1, 2, 3, 5, 6, 4 /
 
      character*10 ibndflag_name(6)
      data ibndflag_name / 'top', 'bottom', 'left_w',
     >                    'front_s', 'right_e', 'back_n' /
c
c     The ibnd array will be assign an integer value depending on the following
c     bit patterns.
c
      data ipat( 1)  /  0 / ! 000000   ---    ---    ---    ---    ---    ---
      data ipat( 2)  /  1 / ! 000001  bottom  ---    ---    ---    ---    ---
      data ipat( 3)  /  2 / ! 000010   ---   top     ---    ---    ---    ---
      data ipat( 4)  /  3 / ! 000011  bottom top     ---    ---    ---    ---
      data ipat( 5)  /  4 / ! 000100   ---    ---   front   ---    ---    ---
      data ipat( 6)  /  5 / ! 000101  bottom  ---   front   ---    ---    ---
      data ipat( 7)  /  6 / ! 000110   ---   top    front   ---    ---    ---
      data ipat( 8)  /  7 / ! 000111  bottom top    front   ---    ---    ---
      data ipat( 9)  /  8 / ! 001000   ---    ---    ---   right   ---    ---
      data ipat(10)  /  9 / ! 001001  bottom  ---    ---   right   ---    ---
      data ipat(11)  / 10 / ! 001010   ---   top     ---   right   ---    ---
      data ipat(12)  / 11 / ! 001011  bottom top     ---   right   ---    ---
      data ipat(13)  / 12 / ! 001100   ---    ---   front  right   ---    ---
      data ipat(14)  / 13 / ! 001101  bottom  ---   front  right   ---    ---
      data ipat(15)  / 14 / ! 001110   ---   top    front  right   ---    ---
      data ipat(16)  / 15 / ! 001111  bottom top    front  right   ---    ---
      data ipat(17)  / 16 / ! 010000   ---    ---    ---    ---   back    ---
      data ipat(18)  / 17 / ! 010001  bottom  ---    ---    ---   back    ---
      data ipat(19)  / 18 / ! 010010   ---   top     ---    ---   back    ---
      data ipat(20)  / 19 / ! 010011  bottom top     ---    ---   back    ---
      data ipat(21)  / 20 / ! 010100   ---    ---   front   ---   back    ---
      data ipat(22)  / 21 / ! 010101  bottom  ---   front   ---   back    ---
      data ipat(23)  / 22 / ! 010110   ---   top    front   ---   back    ---
      data ipat(24)  / 23 / ! 010111  bottom top    front   ---   back    ---
      data ipat(25)  / 24 / ! 011000   ---    ---    ---   right  back    ---
      data ipat(26)  / 25 / ! 011001  bottom  ---    ---   right  back    ---
      data ipat(27)  / 26 / ! 011010   ---   top     ---   right  back    ---
      data ipat(28)  / 27 / ! 011011  bottom top     ---   right  back    ---
      data ipat(29)  / 28 / ! 011100   ---    ---   front  right  back    ---
      data ipat(30)  / 29 / ! 011101  bottom  ---   front  right  back    ---
      data ipat(31)  / 30 / ! 011110   ---   top    front  right  back    ---
      data ipat(32)  / 31 / ! 011111  bottom top    front  right  back    ---
      data ipat(33)  / 32 / ! 100000   ---    ---    ---    ---    ---   left
      data ipat(34)  / 33 / ! 100001  bottom  ---    ---    ---    ---   left
      data ipat(35)  / 34 / ! 100010   ---   top     ---    ---    ---   left
      data ipat(36)  / 35 / ! 100011  bottom top     ---    ---    ---   left
      data ipat(37)  / 36 / ! 100100   ---    ---   front   ---    ---   left
      data ipat(38)  / 37 / ! 100101  bottom  ---   front   ---    ---   left
      data ipat(39)  / 38 / ! 100110   ---   top    front   ---    ---   left
      data ipat(40)  / 39 / ! 100111  bottom top    front   ---    ---   left
      data ipat(41)  / 40 / ! 101000   ---    ---    ---   right   ---   left
      data ipat(42)  / 41 / ! 101001  bottom  ---    ---   right   ---   left
      data ipat(43)  / 42 / ! 101010   ---   top     ---   right   ---   left
      data ipat(44)  / 43 / ! 101011  bottom top     ---   right   ---   left
      data ipat(45)  / 44 / ! 101100   ---    ---   front  right   ---   left
      data ipat(46)  / 45 / ! 101101  bottom  ---   front  right   ---   left
      data ipat(47)  / 46 / ! 101110   ---   top    front  right   ---   left
      data ipat(48)  / 47 / ! 101111  bottom top    front  right   ---   left
      data ipat(49)  / 48 / ! 110000   ---    ---    ---    ---   back   left
      data ipat(50)  / 49 / ! 110001  bottom  ---    ---    ---   back   left
      data ipat(51)  / 50 / ! 110010   ---   top     ---    ---   back   left
      data ipat(52)  / 51 / ! 110011  bottom top     ---    ---   back   left
      data ipat(53)  / 52 / ! 110100   ---    ---   front   ---   back   left
      data ipat(54)  / 53 / ! 110101  bottom  ---   front   ---   back   left
      data ipat(55)  / 54 / ! 110110   ---   top    front   ---   back   left
      data ipat(56)  / 55 / ! 110111  bottom top    front   ---   back   left
      data ipat(57)  / 56 / ! 111000   ---    ---    ---   right  back   left
      data ipat(58)  / 57 / ! 111001  bottom  ---    ---   right  back   left
      data ipat(59)  / 58 / ! 111010   ---   top     ---   right  back   left
      data ipat(60)  / 59 / ! 111011  bottom top     ---   right  back   left
      data ipat(61)  / 60 / ! 111100   ---    ---   front  right  back   left
      data ipat(62)  / 61 / ! 111101  bottom  ---   front  right  back   left
      data ipat(63)  / 62 / ! 111110   ---   top    front  right  back   left
      data ipat(64)  / 63 / ! 111111  bottom top    front  right  back   left
C
      integer if_debug
      data if_debug / 1 /
c
c     When if_debug is made non-zero, 6 new attribute arrays
c     are initialized and filled to designate
c     top, bot, left, right, front, back
c
*--------------------------------------------------------
      isubname='dump_outside_list'

c     set default options
c     all nodes on outside boundary written
c     area computed for outside triangles will be voronoi
      iout_minmax = 0
      iout_voronoi = 1
      iattrib_area = 0
      ierr_att = -1

C     Set atributes for boundary attributes
C     note that this routine now takes 2 option strings
C     keepatt_area now assumes voronoi attributes 

C     Set options for outside attributes
      if((icharlnf(attrib_option) .eq. 14) .and.
     *   (attrib_option(1:14) .eq. 'minmax_keepatt'))then
         iout_minmax=1
         attrib_option='keepatt'
      else if((icharlnf(attrib_option) .eq. 19) .and.
     *   (attrib_option(1:19) .eq. 'minmax_keepatt_area'))then
         iout_minmax=1
         attrib_option='keepatt'
         area_option='keepatt_area'
      else if((icharlnf(attrib_option) .eq. 13) .and.
     *   (attrib_option(1:13) .eq. 'minmax_delatt'))then
         iout_minmax=1
         attrib_option='delatt'
      else if (attrib_option(1:8).eq.'-notset-') then
         attrib_option='delatt'
      endif

C     Set options for boundary area attributes
      if((icharlnf(area_option) .eq. 15) .and.
     *   (area_option(1:15) .eq. 'keepatt_voronoi'))then
         iout_voronoi=1
         iattrib_area=1

      elseif((icharlnf(area_option) .eq. 15) .and.
     *   (area_option(1:15) .eq. 'voronoi_keepatt'))then
         iout_voronoi=1
         iattrib_area=1

      elseif((icharlnf(area_option) .eq. 14) .and.
     *   (area_option(1:15) .eq. 'median_keepatt'))then
         iout_voronoi=0
         iattrib_area=1

      elseif((icharlnf(area_option) .eq. 14) .and.
     *   (area_option(1:15) .eq. 'keepatt_median'))then
         iout_voronoi=0
         iattrib_area=1

      elseif((icharlnf(area_option) .eq. 12) .and.
     *   (area_option(1:15) .eq. 'keepatt_area'))then
         iout_voronoi=1
         iattrib_area=1
      endif

c
c
      write(log_io,100)
  100 format('*********dump_outside_list********')
      call writloga('default',0,log_io,0,ierror)
      if (iout_voronoi.ne.0) write(log_io,'(a)')
     *    "Voronoi Areas used for outside faces."
      if (iout_voronoi.eq.0) write(log_io,'(a)')
     *    "Median  Area used for outside faces."
      call writloga('default',0,log_io,0,ierror)
c
      call cmo_get_name
     >  (cmo_name,ierror)
      if(ierror .ne. 0)write(6,*)ierror,' ierror value cmo_name'
 
      call cmo_get_info
     >  ('nnodes',cmo_name,nnodes,ilennnodes,itypnnodes,ierror)
      if(ierror .ne. 0)write(6,*)ierror,' ierror value imt1'
 
      call cmo_get_info
     >  ('imt1',cmo_name,ipimt1,ilenimt1,itypimt1,ierror)
      if(ierror .ne. 0)write(6,*)ierror,' ierror value imt1'
 
CRVG
c      call cmo_get_info
c     >  ('icr1',cmo_name,ipicr1,ilenicr1,itypicr1,ierror)
c      if(ierror .ne. 0)write(6,*)ierror,' ierror value itetclr'
c 
c      if(ierror .ne. 0)write(6,*)ierror,' ierror value icr'
c
c     Instead of using the icr array we will get a new array and use it
c     since other routines don't want the icr array corrupted
c
      length = nnodes
      itypibnd = 1
c
c     Allocate a work array ibnd which will be released at the end of routine.
c
      call mmgetblk('ibnd',cmo_name,ipibnd,length,itypibnd,icscode)
c
c     Now call mask_icr (should be called mask_ibnd)

C
c     insure that the ibnd array has the outside nodes correctly defined
c
      call mask_icr(ierror)
CRVG
c
c     set up work vector nnodes long
c     iwork is filled with outside node information
c     itry, ifound are for finding minmax of outside normals
c
      call mmgetblk("iwork",isubname,ipiwork,nnodes,1,ierror)
      if (iout_minmax.eq.1) then
        call mmgetblk("itry",isubname,ipitry,nnodes,1,ierror)
        call mmgetblk("ifound",isubname,ipifound,nnodes,1,ierror)
      endif

c
c
c     Find and output top bottom and sides using values of ibnd array
c
c     Below are the values assigned to ibnd
c
c     open file to output zone lists
c
      ifilename=ifile(1:icharlnf(ifile)) // '_outside.zone'
      iunit=-1
      call hassign(iunit,ifilename,ierror)
      if (iunit.lt.0 .or. ierror.lt.0) then
        call x3d_error(isubname,'1 hassign bad file unit')
      endif

c     open file to output-area zone lists
c
      if (iout_voronoi.gt.0) then
        ifilename=ifile(1:icharlnf(ifile)) // '_outside_vor.area'
      else
        ifilename=ifile(1:icharlnf(ifile)) // '_outside_med.area'
      endif
      iunit2=-1
      call hassign(iunit2,ifilename,ierror)
      if (iunit2.lt.0 .or. ierror.lt.0) then
        call x3d_error(isubname,'2 hassign bad file unit')
      endif
C
c    write the 'zone' header at the top of the file
c
      logmess = 'zone'
      write(iunit, 9072)logmess
      write(iunit2,9072)logmess
 
      length = 3*nnodes
      itest  = 2
      call mmgetblk('xcontab_node',isubname,
     *              ipxcontab_node,length,itest,icscode)
C
C     Allocate MO arrays to hold x,y,z components of node area vector
C     check for existance of old attributes, then add if not exist
C
       if (iattrib_area.ne.0) then
       if (iout_voronoi.ne.0) then
         ierr_att = 0

         call mmfindbk('xn_varea',cmo_name,ipxn_area,ilenout,ierr)
         if(ierr.ne.0) then
           call dotask
     *    ('cmo/addatt/-def-/xn_varea/vdouble/scalar/nnodes;finish',ics)
            call cmo_get_info
     *     ('xn_varea',cmo_name,ipxn_area,ilenimt1,itypimt1,ierror)
            if (ierror.ne.0) ierr_att = 1
         else
           write(logmess,'(a)') 
     *     'attribute already exists, will overwrite: xn_varea'
           call writloga('default',0,logmess,0,ierrw)
         endif

         call mmfindbk('yn_varea',cmo_name,ipyn_area,ilenout,ierr)
         if(ierr.ne.0) then
           call dotask
     *    ('cmo/addatt/-def-/yn_varea/vdouble/scalar/nnodes;finish',ics)
            call cmo_get_info
     *     ('yn_varea',cmo_name,ipyn_area,ilenimt1,itypimt1,ierror)
            if (ierror.ne.0) ierr_att = 1
         else
           write(logmess,'(a)')
     *     'attribute already exists, will overwrite: yn_varea'
           call writloga('default',0,logmess,0,ierrw)
         endif

         call mmfindbk('zn_varea',cmo_name,ipzn_area,ilenout,ierr)
         if(ierr.ne.0) then
           call dotask
     *    ('cmo/addatt/-def-/zn_varea/vdouble/scalar/nnodes;finish',ics)
            call cmo_get_info
     *     ('zn_varea',cmo_name,ipzn_area,ilenimt1,itypimt1,ierror)
            if (ierror.ne.0) ierr_att = 1
         else
           write(logmess,'(a)')
     *     'attribute already exists, will overwrite: zn_varea'
           call writloga('default',0,logmess,0,ierrw)
         endif

C      median areas must be chosen explicitly through keepatt_median
       else
         ierr_att = 0

         call mmfindbk('xn_marea',cmo_name,ipxn_area,ilenout,ierr)
         if(ierr.ne.0) then
           call dotask
     *    ('cmo/addatt/-def-/xn_marea/vdouble/scalar/nnodes;finish',ics)
            call cmo_get_info
     *     ('xn_marea',cmo_name,ipxn_area,ilenimt1,itypimt1,ierror)
            if (ierror.ne.0) ierr_att = 1
         else
           write(logmess,'(a)') 
     *     'attribute already exists, will overwrite: xn_marea'
           call writloga('default',0,logmess,0,ierrw)
         endif

         call mmfindbk('yn_marea',cmo_name,ipyn_area,ilenout,ierr)
         if(ierr.ne.0) then
           call dotask
     *    ('cmo/addatt/-def-/yn_marea/vdouble/scalar/nnodes;finish',ics)
            call cmo_get_info
     *     ('yn_marea',cmo_name,ipyn_area,ilenimt1,itypimt1,ierror)
            if (ierror.ne.0) ierr_att = 1
         else
           write(logmess,'(a)')
     *     'attribute already exists, will overwrite: yn_marea'
           call writloga('default',0,logmess,0,ierrw)
         endif

         call mmfindbk('zn_marea',cmo_name,ipzn_area,ilenout,ierr)
         if(ierr.ne.0) then
           call dotask
     *    ('cmo/addatt/-def-/zn_marea/vdouble/scalar/nnodes;finish',ics)
            call cmo_get_info
     *     ('zn_marea',cmo_name,ipzn_area,ilenimt1,itypimt1,ierror)
            if (ierror.ne.0) ierr_att = 1
         else
           write(logmess,'(a)')
     *     'attribute already exists, will overwrite: zn_marea'
           call writloga('default',0,logmess,0,ierrw)
         endif

      endif
      endif

C     default uses voronoi version of outside faces
C     only use median if keepatt_median is used

      if (iout_voronoi.gt.0) then
        call get_xcontab('area_voronoi',cmo_name,ipxcontab_node)
      else
        call get_xcontab('area_vector',cmo_name,ipxcontab_node)
      endif

      if (iout_minmax.eq.1) then

C  Method for minmax outside nodes -----------------------------------
C       Use ijk to find the min max ijk for each direction
C       Overwrite the iwork array to small subset which
C       will be the max binned values for each direction
C
c       We want to sort the nodes two ways, by bins and by index.
c       sort by bins will give nx,ny,nz
c       Get the i_index, j_index, k_index arrays,  the results of sort/xyz/bins.
        call dotaskx3d('sort/xyz/bins ; finish',ierror)
        if (ierror .ne.0) then
           write(log_io,'(a,a)')
     &     isubname,' Error with sort/xyz/bins'
           call writloga('default',0,log_io,0,ierror)
        endif
        call cmo_get_info('i_index',cmo_name,ipi_index,ilen,itype,ier)
        call cmo_get_info('j_index',cmo_name,ipj_index,ilen,itype,ier)
        call cmo_get_info('k_index',cmo_name,ipk_index,ilen,itype,ier)

c       Find nx,ny,nz for each of the outside directions
        nx=0
        ny=0
        nz=0
        do i=1,nnodes
           if (nx.le.i_index(i)) then
              nx=i_index(i)
           endif
           if (ny.le.j_index(i)) then
              ny=j_index(i)
           endif
           if (nz.le.k_index(i)) then
              nz=k_index(i)
           endif
        enddo
c       end setup for indexing minmax outside nodes
      endif


C MAIN LOOP
C Loop through the six directions,
C     top(zone 1), bottom(zone 2), left(zone 3),
C     right(zone 5), front(zone 4), back(zone 6)
C     For each outside direction 
C       add an integer attribute array for each face
C       check that it exists, and is proper length

      xsum=0.0
      ysum=0.0
      zsum=0.0
      do mtests = 1, 6
 
        ntests = io_order(mtests)
c
        if(if_debug .ne. 0)then
        len = icharlnf(ibndflag_name(ntests))
        call mmfindbk
     >  (ibndflag_name(ntests),cmo_name,ipout,ilenout,ierror)
 
        if(ierror.ne.0) then
          dotask_command = 'cmo/addatt/' //
     >        cmo_name(1:icharlnf(cmo_name)) //
     >        '/' //
     >        ibndflag_name(ntests) (1:len) //
     >        '/vint/scalar/nnodes/linear/permanent/afgx/-5.0/' //
     >        ' ; finish '
          call dotaskx3d(dotask_command,ierror)
          if (ierror.ne.0)
     >       call x3d_error(isubname,ibndflag_name(ntests)(1:len))
 
          call mmfindbk
     >    (ibndflag_name(ntests),cmo_name,ipout,ilenout,ierror)
c
        else
          if (ilenout.lt.nnodes) call cmo_newlen(cmo_name,icscode)
        endif
        iatt_type=2
        endif

c     
c    cccccccccccccccccccccccccccccccccccccc
c    Fill the work arrays and icount total number of nodes

C       Use normal faces to find nodes for each direction
        icount = 0
        do n = 1, nnodes
           call getbit(32,ntests-1,ibnd(n),itest)
           if(itest .eq. 1)then
              icount = icount + 1
              iwork(icount) = n
           endif
        enddo

c    cccccccccccccccccccccccccccccccccccccc

C     For minmax option, find and reset work arrays
C     Use sorted bins to find one unique min or max for each direction
c     1-top 2-bottom 3-left 4-right 5-back 6-front
c     where bins are defined with i(row),j(col),k(vertical)
c     this is a brute method, something more elegant can be
c     written if not embedded within this routine.

      if (iout_minmax.eq.1) then

c     setup the endbin and loop increments for current direction
           endbin=1
           iinc = 1
           if (mtests.eq.1) then
              endbin=nz
              iinc = -1
           endif
           if (mtests.eq.4) then
              endbin=nx
              iinc = -1
           endif
           if (mtests.eq.5) then
              endbin=ny
              iinc = -1
           endif
           lowbin = endbin

c          search through outside nodes already in iwork array
c          and find end column or row nodes for each i,j,k
c          also find min and max bin for this direction
           ileft=0
           idone=0
           do i = 1, icount
             inum=iwork(i)
             if (mtests.eq.1 .or. mtests.eq.2) ibin=k_index(inum)
             if (mtests.eq.3 .or. mtests.eq.4) ibin=i_index(inum)
             if (mtests.eq.5 .or. mtests.eq.6) ibin=j_index(inum)

c            found lowest/highest node for this direction
             if (ibin.eq.endbin) then
                idone=idone+1
                ifound(idone)=inum

c            find lowest/highest level of bins for this direction
             else
                if (endbin.gt.1) then
                  if (ibin.lt.lowbin) lowbin = ibin
                else
                  if (ibin.gt.lowbin) lowbin = ibin
                endif
                ileft=ileft+1
                itry(ileft)=inum
             endif
           enddo

c          found the obvious outside nodes at max or min ijk
c          search for remaining candidates that will occur
c          at lower levels of elements that are stair-stepped

c          loop through each level
           endbin=endbin + iinc
           do nbin = endbin,lowbin,iinc

c            loop through remaining outside nodes
             do i = 1,ileft
              ivalid=1
              do n = 1,idone
              if (mtests.eq.1 .or. mtests.eq.2) then
                  ii=i_index(itry(i))
                  jj=j_index(itry(i))
                  icol1= i_index(ifound(n))
                  icol2= j_index(ifound(n))
              else if (mtests.eq.3 .or. mtests.eq.4) then
                  ii=j_index(itry(i))
                  jj=k_index(itry(i))
                  icol1= j_index(ifound(n))
                  icol2= k_index(ifound(n))
              else
                  ii=i_index(itry(i))
                  jj=k_index(itry(i))
                  icol1= i_index(ifound(n))
                  icol2= k_index(ifound(n))
              endif
              if ((icol1.eq.ii) .and. (icol2.eq.jj) ) then
                   ivalid=0
              endif
              enddo
              if (ivalid.eq.1) then
                inum=itry(i)
              if (mtests.eq.1 .or. mtests.eq.2) ibin=k_index(inum)
              if (mtests.eq.3 .or. mtests.eq.4) ibin=i_index(inum)
              if (mtests.eq.5 .or. mtests.eq.6) ibin=j_index(inum)
                if (ibin.eq.nbin) then
                  idone=idone+1
                  ifound(idone)=itry(i)
                endif
              endif

c            end search through remaining outside nodes 
             enddo
c          end loop through each level 
           enddo

c          end search for minmax outside for this direction of mtests
           endif

           if (iout_minmax.eq.1) then
             if (mtests.eq.1) then
               write(log_io,'(a)')
     *   'MINMAX of outside option assumes regular rectangular grid.'
               call writloga('default',1,log_io,0,ierror)
             endif
             write(log_io,'(a,i14,a,i14)')
     *       'Total outside nodes: ',icount,' Total minmax: ',idone
             call writloga('default',0,log_io,0,ierror)

c            copy new set of outside nodes into work array
             icount = idone
             do i = 1, icount
               iwork(i)=ifound(i)
             enddo
           endif


c    cccccccccccccccccccccccccccccccccccccc
c    iwork array now has the node numbers by direction

c
c        OUTPUT NODE LISTS
c
         if(icount .ne. 0)then
            itotal = itotal + icount
            write(log_io,910)ibndflag_name(ntests), ntests, icount
  910       format('Face ',a10,i5,' has ',i9, ' nodes.')
            call writloga('default',0,log_io,0,ierror)
c
            write(iunit,165)
     >        ntests,
     >        ibndflag_name(ntests)(1:icharlnf(ibndflag_name(ntests)))
 165        format(i5.5,2x,a)
            write(iunit,170)'nnum'
 170        format(a4)

            if (iout_minmax.eq.1) then
              write(iunit,*)idone
              write(iunit,940)(ifound(n),n=1,idone)
            else
              write(iunit,*)icount
              write(iunit,940)(iwork(n),n=1,icount)
            endif
 940        format(10(i10,1x))

c
c         OUTPUT AREAS - write to file and write sums to screen
c
c           Get information to write to output
c           sum of areas written to file after zone name
            xareat=0.0
            area_x = 0.0
            area_y = 0.0
            area_z = 0.0
            do i=1,icount
               xareat=xareat+sqrt(xcontab_node(1,iwork(i))**2+
     *                            xcontab_node(2,iwork(i))**2+
     *                            xcontab_node(3,iwork(i))**2)
               area_x=area_x+sqrt(xcontab_node(1,iwork(i))**2)
               area_y=area_y+sqrt(xcontab_node(2,iwork(i))**2)
               area_z=area_z+sqrt(xcontab_node(3,iwork(i))**2)
            enddo

C           no longer write xareat, magnitude does not equal sum of areas
C           the sum area is already written in vector form
C           ie, the sum of top areas is equal to the z component sum
C           sum all faces of each direction
            if (mtests.eq.1 .or. mtests.eq.2) then
              xsum=xsum+area_z
            elseif (mtests.eq.3 .or. mtests.eq.5) then
              xsum=xsum+area_x
            else
              xsum=xsum+area_y
            endif

c           zone name and sum of area components
c           write(iunit2,175)
c    >        ntests,
c    >        ibndflag_name(ntests)(1:icharlnf(ibndflag_name(ntests)))
c175        format(i5.5,2x,a)

            tstring = "   Sum MEDIAN vectors:  "
            if(iout_voronoi .ne. 0) tstring = "   Sum VORONOI vectors: "
            write(iunit2,175)
     >       ntests,
     >       ibndflag_name(ntests)(1:icharlnf(ibndflag_name(ntests)))
     >       // tstring(1:24) ,area_x,area_y,area_z
 175        format(i5.5,2x,a,3e14.7)


c           vector areas for each node in current zone
            write(iunit2,180)'nnum'
 180        format(a4)

C DEBUG
c           write(*,'(6(1x,1pe20.12))')
c    *                     (xcontab_node(1,iwork(n)),
c    *                      xcontab_node(2,iwork(n)),
c    *                      xcontab_node(3,iwork(n)),
c    *                                   n=1,icount)


            write(iunit2,*)icount
            write(iunit2,'(6(1x,1pe20.12))')
     *                     (xcontab_node(1,iwork(n)),
     *                      xcontab_node(2,iwork(n)),
     *                      xcontab_node(3,iwork(n)),
     *                                   n=1,icount)

             tstring = " Sum Median   "
             if(iout_voronoi .ne. 0) tstring = " Sum Voronoi "

C           WRITE zone information to screen output
            write(log_io,920)ibndflag_name(ntests),tstring
  920       format
     *     (a10,a12,
     *      '      Area_x          Area_y          Area_z')
            call writloga('default',0,log_io,0,ierror)
            write(log_io,925)area_x,area_y,area_z
  925       format(20x,3e16.7)
            call writloga('default',0,log_io,0,ierror)
C
C           Fill arrays with x,y,z components of outside area vectors.
C
            if (iattrib_area.ne.0 .and. ierr_att.eq.0) then
               do n = 1, icount
                   xn_area(iwork(n)) = xcontab_node(1,iwork(n))
                   yn_area(iwork(n)) = xcontab_node(2,iwork(n))
                   zn_area(iwork(n)) = xcontab_node(3,iwork(n))
               enddo
            endif

c         assign values to the array added above

          if(if_debug .ne. 0)then
            do n = 1, icount
               ipiarray = ipout
               iarray(iwork(n)) = ntests
            enddo
          endif
         endif

C     END MAIN LOOP through six directions of mtests
      enddo

      write(log_io,'(a)')" "
      write(log_io,'(a,1pe20.12)')"Sum of outside areas: ",xsum
      write(log_io,'(a)')" "

      write(iunit,9074)
      write(iunit2,9074)
      logmess = 'stop'
      write(iunit,9075)logmess
      write(iunit2,9075)logmess
 9072 format(a4)
 9074 format(' ')
 9075 format(a4)
      close(iunit)
      close(iunit2)

      if (attrib_option(1:6) .eq. 'delatt') then

c delete top
         call dotaskx3d('cmo/DELATT/ /top ; finish',ierror)
         if (ierror.ne.0)
     .       call x3d_error(isubname,'Could not delete top')

c delete bottom
         call dotaskx3d('cmo/DELATT/ /bottom ; finish',ierror)
         if (ierror.ne.0)
     .       call x3d_error(isubname,'Could not delete bottom')

c delete left_w
         call dotaskx3d('cmo/DELATT/ /left_w ; finish',ierror)
         if (ierror.ne.0)
     .       call x3d_error(isubname,'Could not delete left_w')

c delete right_e
         call dotaskx3d('cmo/DELATT/ /right_e ; finish',ierror)
         if (ierror.ne.0)
     .       call x3d_error(isubname,'Could not delete right_e')

c delete back_n
         call dotaskx3d('cmo/DELATT/ /back_n ; finish',ierror)
         if (ierror.ne.0)
     .       call x3d_error(isubname,'Could not delete back_n')

c delete front_s
         call dotaskx3d('cmo/DELATT/ /front_s ; finish',ierror)
         if (ierror.ne.0)
     .       call x3d_error(isubname,'Could not delete front_s')

      endif


 
c     release memory of work array
c
      call mmrelprt(isubname,ierror)
CRVG
      call mmrelblk('ibnd',cmo_name,ipibnd,icscode)
CRVG
      return
      end
