 
C**********************************************************************
C HDR
C   NAME:
         subroutine stack_layers(
     >               imsgin,xmsgin,cmsgin,msgtype,nwds,ierr)
C
C   PURPOSE
C       read surface files and merge into a single stacked cmo.
C       Does some error checking and corrections with options
C       The lower elevation of each layer truncates the upper.
C       The trunc and buffer options allows a file to be chosen
C       so that when it is added to the cmo, it truncates all
C       the previous layers, commonly done with the topo surface.
C 
C       stack/layers adds the following cmo attributes:
C         nlayers
C         nnperlayer
C         neperlayer
C         layertyp
C
C     NOTE: Original code and options was developed with stack_trilayers()
C     which assumed triangle surface files. This is a more general version
C     and problems with options may be due to generalization in this routine.
C
C     Error processing and reporting is old style and should be updated.
C
C     FORMAT:
C
C     STACK/LAYERS/
C                      [AVS | gmv]/[minx,miny, maxx,maxy] &
C                      filename(1) [matno,  ] &
C                      filename(i) [matno, refine] &
C                      filename(n) [matno, refine] &
C                      [ FLIP ]
C                      [ BUFFER [xdistance] ]   &
C                      [ PINCH [xthick]    ]   &
C                      [ TRUNC [ifile]     ]   &
C                      [ REFINE [xrefine or irefine]]  &
C                      [ NOINTERFACE ]
C    NEW OPTIONS->     [ d_pinch r d_min r id_move i ] &
C
C    old old version: mread/trilayers
C    old version: stack/trilayers or stack/quadlayers
C
C    stack/layers/
C
C     filetype       - optional avs | gmv filetypes, default avs
C     minx, miny,
C     maxx, maxy     - optional to subset each layer
C     filename(1),
C     ...filename(n) - required list of surface files, starting
C                      with bottom layer first
C    flip            - optional (flip = 0 = don't flip normals)
C    pinch xthick    - default (pinch = 0.0)
C                      real value xthick is mininum thickness
C                      if layers cross, this must be set to at least 0.
C                      this allows upper elev to be equal to lower
C                      If upper dips below lower surface
C                      (dpinch uses bead algorithm to deterimine pinchouts)
C    layerclr        - optional (layerclr = 0 = color elem color)
C    trunc nth_file  - optional
C                      integer nth_file truncates all layers below
C    buffer          - optional
C                      xvalue forms layers above and below
C                      each layer except top and bottom.
C    refine          - irefine will proportionally divide thickness
C                      xrefine will divide into given thickness
C                      (Note this is not recognized in syntax)
C    nointerface     - does not add the interface to final cmo
C                      use with buffer option
C                      extremly experimental
C    d_pinch d_min id_move - uses beads_ona_ring, see below 
C                     - does not work if pinch is defined
C                     - works best with buffers, id_move is 3 by default    
C
C    New node attribute added to the stack cmo is VINT layertyp
C    -1   bottom surface
C    -2   top    surface
C     0   original input surfaces (usually interfaces)
C     1   derived surface to buffer interfaces
C     2   derived surface added as refinement layer
C
C     idebug can be set with amount changing > 3 and > 5 
C
C     Screen output will give this information:
C ................................................................                
C  
C          surface name  layer color type llcorner  zic                           
C           surf-12.inp     1    1   -1         1)  -1.200000E+01                 
C                refine     2    1    2        37)  -8.500000E+00                 
C                buffer     3    1    1        73)  -6.000000E+00                 
C            surf-5.inp     4    2    0       109)  -5.000000E+00                 
C                buffer     5    2    1       145)  -4.000000E+00                 
C                buffer     6    2    1       181)   4.000000E+00                 
C             surf5.inp     7    3    0       217)   5.000000E+00                 
C                buffer     8    3    1       253)   6.000000E+00                 
C                buffer     9    3    1       289)   1.700000E+01                 
C       surf2_slope.inp    10    4    0       325)   1.800000E+01                 
C                buffer    11    4    1       361)   1.900000E+01                 
C            surf25.inp    12    4   -2       397)   2.500000E+01                 
C  
C Elements per layer:         48 total:        576                                
C Nodes    per layer:         36 total:        432                                
C STACK DONE:         5 files read out of         5                             
C STACK DONE:         7 layers created for        12 total.                     
C Layers truncated by surf2_slope.inp layer        10                             
C ................................................................                
C  
C
C    options for beads_ona_ring algorithm
C    These options are used along with buffers to help
C    elements to follow the boundary layer interfaces
C
C     dpinch      If interval length d <= d_pinch then set to zero
C                 (pinch uses layer truncation to cause pinchouts)
c     dmin        If interval length is d_pinch < d < d_min set to d_min
c     move      = 1  Get or put values equally up and down
c                 2  Get or put values up only
c                 3  Get or put values down only (default)
c
c     bead algorithm returns the following status variable
c     id_status =  0  Interval has been set to zero or d_min, don't change.
c               =  1  Candidate for setting to zero
c               = -1  Interval has been set to zero but redistribution has
c                        has not been done.
c               =  2  Candidate for setting to d_min
c               = -2  Interval has been set to d_min but redistribution has
c                        has not been done.
c               =  3  Interval length is > d_min
C
C
C     EXAMPLES:
C
C      this command will read 6 triangulated surface files, flip the
C      normal from down to up, truncate srfs 1-4 with fsrfbe.inp, and
C      pinch the layers out at thickness le 1.0 meter
C      dpinch and dmin move points so that they are between
C      dpinch or dmin, nothing in between
C      Warning, if truncating then dpinch should be 0.
C
C      cmo create cmo1
C      stack layers avs &
C           fsrf575.inp  fsrf09.inp   fsrf31.inp &
C           fsrf44.inp   fsrfbe.inp   fsrf1900.buf.inp &
C           /flip/ truncate 5/ pinch 1.0 /
C  or
C
C      stack layers avs &
C           fsrf575.inp  fsrf09.inp   fsrf31.inp &
C           fsrf44.inp   fsrfbe.inp   fsrf1900.buf.inp &
C           /flip/ truncate 5/ &
C           / buffer 3.0 / dpinch 0.0 / dmin 3.0 / move 3
C
C      this command will take the above stacked tri layer cmo 
C      and fill the layers with prism volumes:
C         stack/fill/ cmo_prism / cmo_stack 
C
C   INPUT/OUTPUT
C         ierr   - INTEGER ERROR FLAG (==0 ==> OK, <>0 ==> AN ERROR)
C
C   COMMENTS
C         The main part of this code reads each surface file, 2 at a time
C   and constructs intermediate surfaces if requested. So the points are
C   processed in a layer by layer fashion.
C         The postprocessing is done column by column.
C
C
C   CHANGE HISTORY
C         t.cherry 7/96  - initial version
C         $Lognfig/t3d/src/read_trilayers.f_a  
CPVCS    
CPVCS       Rev 1.10   Thu Apr 06 13:42:16 2000   dcg
CPVCS    replace get_info_i call
C
C**********************************************************************

      implicit none
c
c ARGS
      integer nwds
      integer imsgin(nwds), msgtype(nwds)
      real*8 xmsgin(nwds)
      character*(*) cmsgin(nwds)
 
      character*72 ifile
      character*72 ifile2
      character*72 ifile_trunc
      integer      nfiletrunc, ninter_top
      integer      filetype
      integer      flip
      integer      pinchout, gobeads
      integer      layerclr
      integer      iopt_move
      integer      iopt_refine
      integer      iopt_trunc
      integer      iopt_buff
      integer      iopt_remove
      integer      idebug, ifound, ibuff2, ichange
      integer      maxclr
      integer      ierr,ierr1,ierrw,ics,iwarn1,iwarn2
 
C
c LOCAL VARS
      character*8092 cbuf
      character*132 logmess
      character*82  errmsg
      character*32  cmostak
      character*32  cmo, cmo_type
      character*32  isubname
      logical       usrclr, svd
 
      integer       icharlnf
      integer
     >        i,ii,idx,j,jcol,jclr,ncmo,icmo
     >,       nread, itrunc, ntrunc
     >,       isubset,itop,ibot, laytyp
     >,       nelm, ntri, npoints
     >,       nnode
     >,       icscode
     >,       nfile
     >,       nlayer, nlayer_tot, nrefine
     >,       ifile_single
     >,       ilen, ityp, ipointi, ipointj
     >,       idone, squished, ichg, icnt
 
      character*72 layerlist(*)
      character*72 flist(nwds)
      pointer (ipflist, flist)
      pointer (iplayerlist, layerlist)
 
      integer ltyplist(*)
      pointer (ipltyplist,ltyplist)
      integer iclr(*)
      pointer (ipiclr, iclr)
      integer irefine(*)
      pointer (ipirefine, irefine)
      integer layertyp(*)
      pointer (iplayertyp, layertyp)
 
      real*8 xmin,xmax,ymin,ymax
      real*8 xthick, xvalue, znext
      real*8 distbuf
 
      integer nbeads
      real*8  xprev, yprev
      real*8  dmin, dpinch
      real*8  zin(*)
      real*8  zout(*)
      real*8  d_pinch(*)
      real*8  d_min(*)
      integer id_move(*)
      pointer (ipd_pinch, d_pinch)
      pointer (ipd_min, d_min)
      pointer (ipid_move, id_move)
      pointer (ipzin, zin)
      pointer (ipzout, zout)
 
 
 
c CMO
      integer ltype_sav(*)
      pointer (ipltype_sav, ltype_sav)
      integer itetclr_sav(*)
      pointer (ipitetclr_sav, itetclr_sav)
      integer itetclr(*)
      pointer (ipitetclr, itetclr)
      integer ibuff(*)
      pointer (ipibuff, ibuff)
 
      real*8 xic(*)
      pointer (ipxic, xic)
      real*8 yic(*)
      pointer (ipyic, yic)
 
      real*8 zic(*)
      pointer (ipzic, zic)
      real*8 zic2(*)
      pointer (ipzic2, zic2)
      real*8 z_trunc(*)
      pointer (ipz_trunc, z_trunc)
 
 
C
C#######################################################################
c BEGIN
 
C-----INIT LOCAL VARS
      isubname='stack_layers'
      errmsg= 'Error_buffer: -undefined error-'
      idone = 0
      usrclr = .false.
      svd = .false.
      filetype = 1
      flip = 0
      pinchout = 1
      gobeads = 0
      iopt_trunc = 0
      iopt_buff = 0
      iopt_refine = 0
      iopt_remove = 0
      layerclr = 0
      isubset = 0
      ncmo = 1
      ifile_single = 0
      xthick = 0.
      dpinch = 0.
      dmin = 0.
      iopt_move = 3
 
C     get mesh object name
      call cmo_get_name(cmostak,ics)
      if (ics.ne.0) then
         write(logmess,"('No current mesh object')")
         call writloga('default',0,logmess,0,ierrw)
         ierr = -1
         return
      endif
      call cmo_get_intinfo('idebug',cmostak,idebug,ilen,ityp,ics)
      if (idebug.ne.0) then
        write(logmess,"('Running in DEBUG mode.',i5)") idebug
        call writloga('default',0,logmess,0,ierrw)
      endif
 
 
       write(errmsg,'(a)') 'Error_buffer: command or syntax error'
C------READ PARSER VALUES, i is next value, nwds is last
       i = 3
       if (cmsgin(1)(1:icharlnf(cmsgin(1))).eq.'stack_layers') i=2
       if (cmsgin(i)(1:icharlnf(cmsgin(i))).eq.'avs') then
         i = i+1
         filetype = 1
       endif
       if (cmsgin(i)(1:icharlnf(cmsgin(i))).eq.'gmv') then
         i = i+1
         filetype = 2
       endif
c-----READ subset if exists
       if (msgtype(i).eq.2 .or. msgtype(i).eq.1) then
         isubset = 1
         if (msgtype(i).eq.2) xmin = xmsgin(i)
         if (msgtype(i).eq.1) xmin = dble(imsgin(i))
         i = i+1
         if (msgtype(i).eq.2) ymin = xmsgin(i)
         if (msgtype(i).eq.1) ymin = dble(imsgin(i))
         i = i+1
         if (msgtype(i).eq.2) xmax = xmsgin(i)
         if (msgtype(i).eq.1) xmax = dble(imsgin(i))
         i = i+1
         if (msgtype(i).eq.2) ymax = xmsgin(i)
         if (msgtype(i).eq.1) ymax = dble(imsgin(i))
         i = i+1
       endif
       if (msgtype(i).eq.1) then
         isubset = 1
         xmin = dble(imsgin(i))
         i = i+1
         ymin = dble(imsgin(i))
         i = i+1
         xmax = dble(imsgin(i))
         i = i+1
         ymax = dble(imsgin(i))
         i = i+1
       endif

C------READ toggles from end of parser
c      possible options are
c         truncate [file_number]
c         flip
c         nointerface
c         buffer  buffer_distance
c         refine  n_times_to_refine
c         pinch   min_height
c         layerclr
       do ii = i,nwds
       if (msgtype(ii) .eq. 3) then
         ilen = icharlnf(cmsgin(ii))
         if (cmsgin(ii)(1:5).eq.'trunc') then
             iopt_trunc = 1
             nwds = nwds-1
             if(msgtype(ii+1) .eq. 1) then
               nfiletrunc=imsgin(ii+1)
               nwds = nwds-1
             endif
         endif
         if (cmsgin(ii)(1:5).eq.'noint') then
             iopt_remove = 1
             nwds = nwds-1
         endif
         if (cmsgin(ii)(1:ilen).eq.'flip') then
             flip = 1
             nwds = nwds-1
         endif
         if (cmsgin(ii)(1:3).eq.'buf') then
             iopt_buff = 1
             usrclr = .true.
             ncmo = 3
             nwds = nwds-1
             if(msgtype(ii+1) .eq. 2) then
               distbuf=xmsgin(ii+1)
               nwds = nwds-1
             endif
             if(msgtype(ii+1) .eq. 1) then
               distbuf= dble(imsgin(ii+1))
               nwds = nwds-1
             endif
         endif
         if (cmsgin(ii)(1:3).eq.'ref') then
             iopt_refine = 1
             usrclr = .true.
             nwds = nwds-1
             if(msgtype(ii+1) .eq. 1) then
               nrefine=imsgin(ii+1)
               ncmo = nrefine
               nwds = nwds-1
             endif
         endif
         if (cmsgin(ii)(1:ilen).eq.'pinch') then
            pinchout = 1
            nwds = nwds-1
            gobeads = 0
            if (msgtype(ii+1).eq.2) then
               xthick = xmsgin(ii+1)
               nwds = nwds-1
            endif
            if (msgtype(ii+1).eq.1) then
               xthick = dble(imsgin(ii+1))
               nwds = nwds-1
            endif
         endif
         if (cmsgin(ii)(1:ilen).eq.'layerclr') then
            layerclr = 1
            nwds = nwds-1
         endif
 
CCCCCCCCCCCCCfor new code
         if (cmsgin(ii)(1:ilen).eq.'dpinch') then
            nwds = nwds-1
            if (msgtype(ii+1).eq.2) then
              dpinch = xmsgin(ii+1)
            elseif (msgtype(ii+1).eq.1) then
              dpinch = dble(imsgin(ii+1))
            endif
            nwds = nwds-1
            gobeads = 1
         endif
         if (cmsgin(ii)(1:ilen).eq.'dmin') then
            nwds = nwds-1
            if (msgtype(ii+1).eq.2) then
              dmin = xmsgin(ii+1)
            elseif (msgtype(ii+1).eq.1) then
              dmin = dble(imsgin(ii+1))
            endif
            nwds = nwds-1
            gobeads = 1
         endif
         if (cmsgin(ii)(1:ilen).eq.'move') then
            nwds = nwds-1
            iopt_move = imsgin(ii+1)
            nwds = nwds-1
            gobeads = 1
         endif
 
       endif
       enddo

C      Do some error checking on the command syntax
       if (isubset.ne.0 .and. xmin.ge.xmax) then
         write(logmess,'(a,e14.6,e14.6)')
     >   'Syntax error: xmin greater than xmax: ',xmin,xmax
         call writloga('default',1,logmess,0,ierrw)
         ierr = -1
       endif
       if (isubset.ne.0 .and. ymin.ge.ymax) then
         write(logmess,'(a,e14.6,e14.6)')
     >   'Syntax error: ymin greater than ymax: ',ymin,ymax
         call writloga('default',1,logmess,0,ierrw)
         ierr = -1
       endif
       if ((dpinch.gt. 0.) .and. (dpinch.gt.dmin)) then
         write(logmess,'(a,f7.2,f7.2)')
     >   'Syntax error: dpinch greater than dmin',dpinch,dmin
         call writloga('default',1,logmess,0,ierrw)
         ierr = -1
       endif
       if ((iopt_buff.gt.0) .and. (xthick.gt.distbuf)) then
         write(logmess,'(a,f7.2,f7.2)')
     >   'Syntax error: pinch greater than buffer',xthick,distbuf
         call writloga('default',1,logmess,0,ierrw)
         ierr = -1
       endif

       if (ierr .lt. 0) then
          write(logmess,'(a)')
     >    'STACK SYNTAX:'
          call writloga('default',0,logmess,0,ierr1)
          write(logmess,'(a,a)')
     >    'stack/trilayers/avs|gmv/[minx,miny, maxx,maxy]',
     >    '/ filename_1, ... filename_n '
          call writloga('default',0,logmess,1,ierr1)
          goto 999
       endif
 
       write(errmsg,'(a)') 'Error_buffer: cmo error'
C      Create the temporary cmos
C      ierr.eq.0 means that the cmo already exists.
       call cmo_exist('def1',ierr)
       if(ierr.eq.0) then
          call x3d_error(isubname, 'def1 exists')
          goto 999
       endif
 
       call cmo_exist('def2',ierr)
       if(ierr.eq.0) then
          call x3d_error(isubname, 'def2 exists')
          goto 999
       endif
 
       write(errmsg,'(a)') 'Error_buffer: mmgetblk memory error'
C------ALLOCATE memory
       call mmgetblk("flist", isubname, ipflist, 72*nwds, 1, ierr)
       if(ierr.ne.0)call x3d_error(isubname, 'mmgetblk flist')
       call mmgetblk("iclr", isubname, ipiclr, nwds, 1, ierr)
       if(ierr.ne.0)call x3d_error(isubname, 'mmgetblk iclr')
       call mmgetblk("irefine", isubname, ipirefine, nwds, 1, ierr)
       if(ierr.ne.0)call x3d_error(isubname, 'mmgetblk irefine')
 
C------Finish command line processing of file names and their options
C      READ file names and options before read is called with parser
C todo syntax should allow refine numbers to start at first file
C      as well as current starting at second file
       write(errmsg,'(a)') 'Error_buffer: syntax error in file list'
       nfile = 0
       do ii = i, nwds
         if (msgtype(ii).eq.2) then
           call x3d_error(isubname,'int or char expected')
           ierr = ierr+1
           goto 999
         elseif (msgtype(ii).eq.3 ) then
           nfile = nfile+1
           flist(nfile) = cmsgin(ii)
           if (msgtype(ii+1).eq.1) then
             iclr(nfile) = imsgin(ii+1)
             usrclr=.true.
           else
             iclr(nfile) = nfile
           endif
           if (msgtype(ii+2).eq.1) then
             if(nfile.eq.1) then
               write(logmess,'(a)') 
     > 'syntax warning: file1 integer / file2  integer integer '
               call writloga('default',0,logmess,0,ierrw)
               write(logmess,'(a)') 
     > 'refine starts at second surface, number ignored for file1.'
               call writloga('default',0,logmess,0,ierrw)
             else
               irefine(nfile) = imsgin(ii+2)
             endif
           else
             irefine(nfile) = 0
           endif
         endif
       enddo
       maxclr = iclr(nfile)
 
       write(errmsg,'(a)') 'Error_buffer: error during setup'

       if (nfile .lt. 2 ) call x3d_error(isubname, '1 File, no merge')
       if (nfile .eq. 1 ) ifile_single = 1
       if (nfile .eq. 1 ) nfile = 2
       if (iopt_remove.ne.0 ) then
          write(logmess,'(a)')
     >    'ERROR: option for NO interfaces not available.'
          call writloga('default',1,logmess,1,ierr1)
          goto 999
       endif

c      INFORMATION computing
c      count number of layers there will be in the cmo
c      ntrunc are the layers to truncate by nfiletrunc
c      nfiletrunc is the truncating layer, or top layer
c      nfiletrunc can be buffered if it is not top layer
c      ninter_top is the top interface that can be buffered
       ninter_top = nfile - 1
       if (iopt_trunc.ne.0 .and. nfiletrunc.ne.nfile) 
     >     ninter_top = nfiletrunc
       nlayer_tot = 0
       do i = 1, nfile
         nlayer_tot = nlayer_tot+irefine(i)
         if (iopt_remove.eq.0) then
            nlayer_tot = nlayer_tot+1
         elseif (i.eq.1 .or. i.eq.nfile) then
            nlayer_tot = nlayer_tot+1
         endif
         if (iopt_buff.gt.0) then
           if (i.ne.1 .and. i.le.ninter_top) nlayer_tot=nlayer_tot+2
         endif
         if (i.le.nfiletrunc) ntrunc = nlayer_tot
       enddo
       if(iopt_buff.gt.0 .and. iopt_trunc.ne.0) then
         ntrunc = ntrunc - 1
       endif

       if (iopt_trunc.ne.0) then
          if (nfiletrunc.eq.0) nfiletrunc = nfile
          ifile_trunc = flist(nfiletrunc)
       endif

       write(logmess,'("Layers to create: ",i10)')nlayer_tot
       call writloga('default',1,logmess,0,ierrw)
       write(logmess,'("Max material number: ",i10)')maxclr
       call writloga('default',0,logmess,0,ierrw)
       if (iopt_trunc .ne. 0) then
         write(logmess,'("Layers under trunc file: ",i10)')ntrunc-1
         call writloga('default',0,logmess,0,ierrw)
          write(logmess,'(a)')
     >    'truncating file: '//ifile_trunc(1:icharlnf(ifile_trunc))
          call writloga('default',0,logmess,0,ierrw)
       endif
       write(logmess,'("Reading ",i5," surface files...")')nfile
       call writloga('default',1,logmess,0,ierrw)
 
c     add attribute to indicate layer type such as
c     bottom, top, interface, buffer or refinement 
      if(idebug.le.3) call writset('stat','tty','off',ierrw)
      call mmgetpr('layertyp',cmostak,iplayertyp,ifound)
      if (ifound.ne.0) then
        cbuf='cmo/addatt/' // cmostak(1:icharlnf(cmostak)) //
     >       '/layertyp/' //
     >       'VINT/scalar/nnodes//permanent/agfx ; finish'
        call dotaskx3d(cbuf,ierr)
        if(ierr.ne.0) write(errmsg,'(a)') 
     >               'Error_buffer: make att layertyp'
        if(ierr.ne.0)  goto 999
      endif

c      FILL and SAVE TRUNCATE SURFACE ELEVATIONS
c      Save unaltered z values of the truncating surface
       if (iopt_trunc .ne. 0 ) then
         call file_exist(ifile_trunc(1:icharlnf(ifile_trunc)),ierr)
         if(ierr.ne.0) then 
           errmsg = 'Error_buffer: Missing surface file.'
           goto 999
         endif

         write(logmess,'(a,a)')
     >  'Read truncate layer: ',ifile_trunc(1:icharlnf(ifile_trunc))
         call writloga('default',0,logmess,0,ierrw)
         cmo = 'def1'
         if (filetype.eq.1) then
           cbuf = 'read/avs/' // ifile_trunc(1:icharlnf(ifile_trunc))//
     >        '/ def2' // ' ; finish '
         else
           cbuf = 'read/gmv/' // ifile_trunc(1:icharlnf(ifile_trunc))//
     >        '/ def2' // ' ; finish '
         endif

         call dotaskx3d(cbuf,ierr)
         cmo="def2"
         if(ierr .ne. 0)call x3d_error(isubname, ifile_trunc)
         if(ierr.ne.0)  goto 999

c        subset the truncating surface, set pointers
         if (isubset .ne. 0) then
           write(errmsg,'(a)')'Error_buffer: error during subset'
           call trilayer_subset(cmo,xmin,ymin,xmax,ymax,ierr)
           if(ierr .ne. 0)call x3d_error(isubname, ifile_trunc)
           if(ierr.ne.0)  goto 999
           write(errmsg,'(a)') 'Error_buffer: error during setup'
         endif

         call cmo_get_info('nnodes',cmo,nnode,ilen,ityp,ierr)
         call cmo_get_info('zic',cmo,ipzic2,ilen,ityp,ierr)
         write(errmsg,'("Error_buffer: get_info for trunc layer")')
         if(ierr.ne.0) goto 999

c        check if z_trunc block exists
         call mmgetindex('z_trunc',isubname,ifound,ierr)
         if (ifound .le. 0) then
           call mmgetblk("z_trunc", isubname,ipz_trunc,nnode,2,ierr)
           if(ierr.ne.0) then
             call x3d_error(isubname, 'mmgetblk z_trunc')
             goto 999
           endif
         endif
         do i = 1, nnode
           z_trunc(i) = zic2(i)
         enddo

         svd = .true.
         write(logmess,'(a,i10,1x,a)')
     *      'Saved truncating layer: ',
     *      ntrunc,flist(ntrunc)(1:icharlnf(flist(ntrunc)))
         call writloga('default',1,logmess,0,ierr1)
         call writset('stat','tty','off',ierrw)
         call dotaskx3d('cmo/delete/def2/ ; finish',ierr)
       endif
c      end collection of truncating elevations

c      ALLOCATE MEMORY for local arrays
       write(errmsg,'(a)') 'Error_buffer: mmgetblk memory error'
       call mmgetblk("layerlist",isubname,
     *               iplayerlist,72*nlayer_tot,1,ierr)
       if(ierr.ne.0)call x3d_error(isubname, 'mmgetblk layerlist')
       call mmgetblk("ltyplist",isubname,
     *               ipltyplist,nlayer_tot,1,ierr)
       if(ierr.ne.0)call x3d_error(isubname, 'mmgetblk ltyplist')
       do i = 1, nlayer_tot
         layerlist(i) = '-notset-'
         ltyplist(i)  = -1
       enddo


 
C...................................................................
C      FILL FIRST cmo def1
 
c      read the first file into temp cmo def1
       write(errmsg,'(a)') 'Error_buffer: error from first surface'
       nread = 0
       nlayer = 0
       ifile = flist(1)
       call file_exist(ifile(1:icharlnf(ifile)),ierr)
       if(ierr.ne.0) goto 999
 
       write(logmess,'(a,a)')
     > 'Read first surface: ',ifile(1:icharlnf(ifile))
       call writloga('default',0,logmess,0,ierrw)
 
c      TURN OFF OUTPUT
       if(idebug.le.3) call writset('stat','tty','off',ierrw)
       cmo = 'def1'
       if (filetype.eq.1) then
         cbuf = 'read/avs/' //
     >        ifile(1:icharlnf(ifile)) //
     >        '/ def1' //
     >        ' ; finish '
       else
         cbuf = 'read/gmv/' //
     >        ifile(1:icharlnf(ifile)) //
     >        '/ def1' //
     >        ' ; finish '
 
       endif
       call dotaskx3d(cbuf,ierr)
       if(ierr .ne. 0)call x3d_error(isubname, ifile)
       if(ierr.ne.0)  goto 999
       nread = nread + 1
 
c      subset the first surface layer, set pointers
c      allow subset info to be written this once
       if (isubset .ne. 0) then
         call cmo_set_info('idebug',cmo,5,1,1,ierr)
         call trilayer_subset(cmo,xmin,ymin,xmax,ymax,ierr)
         if(ierr .ne. 0)call x3d_error(isubname, ifile)
         if(ierr.ne.0)  goto 999
         call cmo_set_info('idebug',cmo,idebug,1,1,ierr)
       endif

c      Get the cmo scalar information that will be used as
c      information for each layer for the final stacked cmo
       call cmo_get_info('nelements',cmo,nelm,ilen,ityp,ierr)
       call cmo_get_info('nnodes',cmo,nnode,ilen,ityp,ierr)
       call cmo_get_info('itetclr',cmo,ipitetclr,ilen,ityp,ierr)
       call cmo_get_info('zic',cmo,ipzic,ilen,ityp,ierr)
       if(nelm .le. 0) call x3d_error(isubname, ' 0 elements found.')
       if( ierr.ne.0 .or. nelm.le.0 ) then
         goto 999
       endif
       ntri = nelm
       npoints = nnode

c      Get the mesh type from the first surface
       call cmo_get_mesh_type(cmo,cmo_type,ityp,ierr)
       call cmo_set_mesh_type(cmostak, cmo_type, ierr)
       if(ierr .ne. 0)call x3d_error(isubname, 'cmo set mesh_type')


c-----truncate elevations
c      truncate first surface by saved elevations
       itrunc=0
       if (iopt_trunc.ne.0 .and. nlayer.lt.ntrunc) then
c        loop through points on this surface
         do i = 1, npoints
           xvalue= z_trunc(i)-zic(i)
           if (xvalue.lt.xthick) then
             zic(i)=z_trunc(i)
             itrunc=itrunc+1
           endif
         enddo
         if(itrunc.gt.0) then
           write(logmess,'(a,i10,a)')
     >     'Truncated ',itrunc,' in layer 1 '
     >     //flist(1)(1:icharlnf(flist(1)))
           call writloga('default',0,logmess,0,ierr)
         endif
       endif
c      end truncate
 
c      check normals of the triangles, flip if down
       call cktrilayer_norm('def1',idebug, flip, ierr)
       if(ierr .ne. 0)
     >   call x3d_error(isubname, ifile(1:icharlnf(ifile)))
 
       if (ifile_single .ne. 0 ) then
         nread=1
         nfile=1
         goto 500
       endif

c      create arrays to save the tet colors and layertyp
       call mmgetblk("itetclr_sav", isubname,
     >      ipitetclr_sav, ntri*nlayer_tot,1,ierr)
       if(ierr.ne.0) then
         call x3d_error(isubname, 'mmgetblk itetclr_sav') 
         goto 999
       endif
       call mmgetblk("ltype_sav", isubname,
     >      ipltype_sav, npoints*nlayer_tot,1,ierr)
       if(ierr.ne.0) then
         call x3d_error(isubname, 'mmgetblk ltype_sav') 
         goto 999
       endif
 
c      color by original tri colors, else 1 for first layer
c      if usrclr, use user chosen layer id, but allow
c         tetclr gt 1 to remain gt 1
c      layer type for first layer is -1
       do i = 1, npoints
         ltype_sav(i) = -1
       enddo
       if (layerclr .ne. 0) then
         do i = 1, ntri
            itetclr_sav(i) = 1
         enddo
       else
         do i = 1, ntri
            itetclr_sav(i) = itetclr(i)
            if (usrclr) then
              if (itetclr(i).eq.1 .or. itetclr(i).eq.2) then
                itetclr_sav(i) = iclr(1)
              else
                itetclr_sav(i) = itetclr(i) + maxclr
              endif
            endif
         enddo
       endif
       nlayer = nlayer+1
       layerlist(nlayer) = ifile
 
c      nfile  = number of files total to read into a cmo
c      nread  = number of files read  to create layers
c      nlayer = number of layers created from other layers
c      ncmo   = number of cmo layers created between layers read
c      nelm   = number of elements in each cmo
c      ntri   = number of elements expected based on first file read
C,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
C------MAIN LOOP for read, merge files------------------------------
 
       do ii = 2, nfile
 
       write(errmsg,'(a,i10)') 
     >      'Error_buffer: error while at surface ',ii
       if(idebug.gt.0) then
         write(logmess,'(a,i5,a)')
     >   '--- surface cmo ',ii,'-----------------------------'
         call writloga('default',0,logmess,0,ierr)
       endif
c      TURN OFF OUTPUT
       if(idebug.le.3) call writset('stat','tty','off',ierrw)
 
c      here def2 becomes def1 of the 2 surfaces
c      then we read in a new def2
C TAM  NOTE BUG in copy of 9th cmo, missing user attributes
C      results in MMNEWLEN ERROR

       if (ii.gt.2 ) then
         call cmo_copy("def1","cmonxt", ierr)
         if(ierr .ne. 0) then
           call x3d_error(isubname, 'copy cmonxt to def1 ')
           goto 9999
         endif
         call dotaskx3d('cmo/delete/cmonxt/ ; finish',ierr)

       elseif (ii.eq.2) then
         call cmo_copy("cmoprev","def1", ierr)
         if(ierr .ne. 0) then
           call x3d_error(isubname, 'copy def1 to cmoprev')
           goto 9999
         endif
     
       endif
 
      ifile = flist(nread)
c     -------Read cmo def2
      ifile2 = flist(ii)
      call file_exist(ifile2(1:icharlnf(ifile2)),ierr)
      if(ierr.ne.0) goto 999
 
       write(logmess,'(a,a)')'Read surface: ',ifile2(1:icharlnf(ifile2))
       call writloga('default',0,logmess,0,ierrw)

c      TURN OFF OUTPUT
       if(idebug.le.3) call writset('stat','tty','off',ierrw)
       cmo = 'def2'
       if (filetype.eq.1) then
         cbuf = 'read/avs/' //
     >       ifile2(1:icharlnf(ifile2)) //
     >       '/ def2' //
     >       ' ; finish '
       else
         cbuf = 'read/gmv/' //
     >       ifile2(1:icharlnf(ifile2)) //
     >       '/ def2' //
     >       ' ; finish '
       endif
       call dotaskx3d(cbuf,ierr)
       if(ierr .ne. 0)call x3d_error(isubname, ifile2)
       if(ierr.ne.0)  goto 999
       nread = nread + 1
 
c      subset the next surface layer, set pointers
       if (isubset .ne. 0) then
         call trilayer_subset(cmo,xmin,ymin,xmax,ymax,ierr)
         if(ierr .ne. 0)call x3d_error(isubname, ifile2)
         if(ierr.ne.0)  goto 999
       endif

       call cmo_get_info('zic',cmo,ipzic2,ilen,ityp,ierr)
       if( ierr.ne.0 ) then
         if (ierr.ne.0) write(errmsg,'(a)') 
     >      'Error_buffer: get_info zic2 '
         goto 999
       endif

c      truncate surface by saved elevations
       itrunc=0
       if (iopt_trunc.ne.0 .and. nlayer.lt.ntrunc) then
c        loop through points on this surface
         do i = 1, npoints
           xvalue= z_trunc(i)-zic2(i)
           if (xvalue.lt.xthick) then
             zic2(i)=z_trunc(i)
             itrunc=itrunc+1
           endif
         enddo
         if(itrunc.gt.0) then
           write(logmess,'(a,i10,a,i5,a)')
     >     'Truncated ',itrunc,' in layer',nlayer,
     >     ' '//flist(nlayer)(1:icharlnf(flist(nlayer)))
           call writloga('default',0,logmess,0,ierr)
         endif
       endif
c      end truncate

C     .........................................................
C     LOOP THROUGH LAYERS IN A UNIT (BETWEEN TWO LAYERS)
 
c     figure out how many layer cmo's to create for this unit
c     def1 is lower layer, def2 is top layer of unit
c     cmonxt will be the next layer after def1 and cmoprev
c     since only interfaces are buffered, top and bottom unit have 1 buffer
c     all other units will have 2 buffers
      ncmo=irefine(ii) + 1
      if (iopt_buff.ne.0) then
        ncmo=ncmo+1
        if (nread.ne.2 .and. nread.le.ninter_top) then
           ncmo=ncmo+1
        endif
      endif
 
      do icmo = 1, ncmo
c     figure out type of layer, buffer, refinement or top of unit
c     laytyp 1 = buffer, 2 = refinement, 0 = top layer (interface)
 
c     first unit
      if (nread.eq.2 .and. icmo.ne.ncmo) then
        laytyp = 2
        if (iopt_buff.ne.0 .and. icmo.eq.ncmo-1) laytyp = 1
 
c     last unit
      elseif (nread.eq.nfile .and. icmo.ne.ncmo) then
        laytyp = 2
        if (iopt_buff.ne.0 .and. icmo.eq.1) laytyp = 1
 
c     middle units
      elseif (iopt_buff.ne.0 .and. (icmo.eq.1)) then
        laytyp = 1
      elseif (iopt_buff.ne.0 .and. (icmo.eq.ncmo-1)) then
        laytyp = 1
      elseif (icmo.ne.ncmo .and. irefine(nread).ne.0) then
        laytyp = 2
c
c     done with this unit
      else
        laytyp = 0
      endif

c     DERIVE intermediate layers
      if(idebug.gt.0) then
        write(logmess,'(a,i5,a,i5,a,i5)')
     >  'Unit cmo ',icmo,' of ',ncmo,'  type: ',laytyp
        call writloga('default',0,logmess,0,ierr)
      endif
      if(idebug.le.3) call writset('stat','tty','off',ierrw)
 
c-----If this is a buffer layer
      if (laytyp .eq. 1) then
        cmo = 'cmonxt'
        xvalue=distbuf
        if (icmo.ne.1 .or. nread.eq.2) xvalue=-1.0*distbuf
        write(cbuf,'(a,1pe13.6,a)')
     >    'trilayer/derive/constant/cmonxt/def1/def2/ ',
     >     xvalue,' /  ; finish '
        call dotaskx3d(cbuf,ierr)
        if(ierr.ne.0)call x3d_error(isubname, 'derive tri layer')
        if(ierr.ne.0)  goto 999
        nlayer =  nlayer + 1
        layerlist(nlayer) = 'buffer'
 
 
c-----If this is a refinement layer
      elseif (laytyp .eq. 2) then
 
        cmo = 'cmonxt'
        if (iopt_buff.ne.0 ) then
           if (nread.eq.2 ) then
             xvalue= (1.0/(ncmo-1))*(icmo)
           elseif (nread.eq.nfile) then
             xvalue= (1.0/(ncmo-1))*(icmo-1)
           else
             xvalue= (1.0/(ncmo-2))*(icmo-1)
           endif
        else
           xvalue= (1.0/(ncmo))*icmo
        endif
        write(cbuf,'(a,1pe13.6,a)')
     >   'trilayer/derive/proportional/cmonxt/def1/def2/ ',
     >   xvalue,' /  ; finish '
        call dotaskx3d(cbuf,ierr)
        if(ierr.ne.0)call x3d_error(isubname, 'derive tri layer')
        if(ierr.ne.0)  goto 999
        nlayer =  nlayer + 1
        layerlist(nlayer) = 'refine'
 
c-----Else this is top layer of pair, make def2 cmonxt
      else
 
        call cmo_copy("cmonxt","def2", ierr)
        if(ierr .ne. 0) then
          call x3d_error(isubname, 'copy def2 cmonxt')
          goto 9999
        endif
        call dotaskx3d('cmo/delete/def2/ ; finish',ierr)
        nlayer =  nlayer + 1
        layerlist(nlayer) = ifile2
 
      endif

c-----done filling cmonxt, nlayer is set

      ltyplist(nlayer) = laytyp
      if (nlayer .eq. nlayer_tot) ltyplist(nlayer) = -2
 
      cmo='cmonxt'
      call cmo_get_info('nelements',cmo,nelm,ilen,ityp,ierr)
      if(ierr.ne.0) goto 999
      if(nelm.ne.ntri) then
         write(logmess,'(a,i10,i10)')'Error - sets unequal: ',ntri,nelm
         call writloga('default',0,logmess,0,ierr)
         goto 999
      endif
      if(idebug.le.3) call writset('stat','tty','off',ierrw)
 
C**** IF NOT REMOVING THIS LAYER, DO SOME WORK
      if (iopt_remove.eq.0 .or. nlayer.eq.nlayer_tot .or.
     *    icmo.ne.ncmo ) then
 
c     If this is a derived layer (1 or 2), inherit color from layer below.
      if (ltyplist(nlayer) .gt. 0 ) then
          write(cbuf,'(a)')
     >   'cmo/copyatt/cmonxt / def1 /itetclr/itetclr/  ; finish '
        call dotaskx3d(cbuf,ierr)
        if(ierr.ne.0)call x3d_error('copy att itetclr',isubname)
        if(ierr.ne.0)  goto 999
      endif
 
c     save the tet colors and layer type, so not clobbered by merge
c     color by original tri colors, else layer count
c     if usrclr, use user chosen layer id, but allow
c       itetclr 1 normal points down, 2 points up
c       tetclr gt 2 to remain gt 2 as these are tipping elements
 
      do i = 1,npoints
         j=(nlayer-1)*npoints
         ltype_sav(j+i) = ltyplist(nlayer) 
      enddo
      call cmo_get_info('itetclr',cmo,ipitetclr,ilen,ityp,ierr)
      if (ierr.ne.0) write(errmsg,'(a)') 'Error_buffer: get itetclr'
      if (ierr.ne.0) goto 999
      if (layerclr .ne. 0) then
        do i = 1, ntri
           itetclr_sav((nread*ntri)+i) = nread
        enddo
      else
        j = (nlayer-1)*ntri
        jclr = iclr(nread-1)
        if (icmo.eq.ncmo) jclr = iclr(nread)
 
        do i = 1, ntri
           itetclr_sav(j+i) = itetclr(i)
           if (usrclr) then
             if (itetclr(i).eq.1 .or. itetclr(i).eq.2) then
               itetclr_sav(j+i) = jclr
             else
               itetclr_sav(j+i) = itetclr(i) + maxclr
             endif
           endif
        enddo
      endif
 
C-----DONE filling cmos def1 and cmonxt, do error check
c     done reading or creating layers
 
C     Do some error checks and reporting
      cmo= 'cmonxt'
 
      call cktrilayer_norm('cmonxt',0, flip, ierr)
      if(ierr .ne. 0) then
        write(errmsg,'(a)') 
     >  'Error_buffer: Normals in '//ifile2(1:icharlnf(ifile2))
        goto 999
      endif
 
C     pinchout layers at xthick
C     do not pinchoout truncating layer or its lower buffer
      j=nlayer
      ierr1 = idebug
      call cktrilayer_elev("cmoprev",cmo,pinchout,xthick,ierr1)
      write(logmess,'(a)') 'Layers compared: '//
     >layerlist(j-1)(1:icharlnf(layerlist(j-1)))//
     >' and '//layerlist(j)(1:icharlnf(layerlist(j)))
      call writloga('default',0,logmess,0,ierr1)
 
      endif
c     done checking finished stacked layers
 
 
C-----MERGE cmo cmonxt and def1 if first, else cmostak
c     TURN OFF OUTPUT
      if(idebug.le.3) call writset('stat','tty','off',ierrw)
 
c     copy current cmo to cmoprev
c     for ncmo = last - def2 becomes cmoprev
c     if intrfaces removed, do not change cmoprev
c     reminder - previous cmo not copied at interface
 
      if(idebug.le.3) call writset('stat','tty','off',ierrw)
      if (icmo.eq.ncmo .and. iopt_remove.ne.0) then
      else
        call writset('stat','tty','off',ierrw)
        call dotaskx3d('cmo/delete/cmoprev/ ; finish',ierr)
        call dotaskx3d('cmo/copy/cmoprev/cmonxt/ ; finish',ierr)
        if(ierr .ne. 0)call x3d_error(isubname, 'cmo copy')
      endif
 
c     this is the first layer
      if(idebug.le.3) call writset('stat','tty','off',ierrw)
      if (ii.eq.2 .and. icmo.eq.1 ) then
        call dotaskx3d('addmesh/merge/' //
     >       cmostak(1:icharlnf(cmostak)) //
     >       '/def1/cmonxt/ ; finish',ierr)
 
c     these are the interfaces do not add to mesh if iopt_remove
      elseif ( icmo.eq.ncmo  ) then
        if (iopt_remove .eq. 0 .or. nlayer.eq.nlayer_tot ) then
          call dotaskx3d('addmesh/merge/' //
     >         cmostak(1:icharlnf(cmostak)) // ' / ' //
     >         cmostak(1:icharlnf(cmostak)) //
     >         '/cmonxt/ ; finish',ierr)
        else
          nlayer = nlayer-1
        endif
 
c     these are derived buffer and refine layers between interfaces
      else
        call dotaskx3d('addmesh/merge/' //
     >       cmostak(1:icharlnf(cmostak)) // ' / ' //
     >       cmostak(1:icharlnf(cmostak)) //
     >       '/cmonxt/ ; finish',ierr)
      endif
 
c     TURN ON OUTPUT
      call writset('stat','tty','on',ierrw)
      if(ierr .ne. 0) write(errmsg,'(a)') 
     >  'Error_buffer: addmesh merge'
      if(ierr.ne.0)  goto 999
      call cmo_newlen(cmostak,ierr)
      call cmo_get_info('nelements',cmostak,nelm,ilen,ityp,ierr)
      call cmo_get_info('nnodes',cmostak,nnode,ilen,ityp,ierr)
 
      enddo
C     .........................................................
C     END layers per file
 
      enddo
C,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
C     END MAIN LOOP - layers are now merged into cmostak
C     Done building trilayer cmo, now do some post-processing
C     Make the stack cmo current

      cmo = cmostak
      write(errmsg,'(a)') 
     >  'Error_buffer: error during update of new stack cmo'
 
c COPY SAVED VALUES
      if(idebug.le.3) call writset('stat','tty','off',ierrw)
      call cmo_get_info('nelements',cmo,nelm,ilen,ityp,ierr1)

      call cmo_get_info('itetclr',cmo,ipitetclr,ilen,ityp,ierr)
      if (ierr.ne.0 )
     * write(errmsg,'("Error_buffer: cannot get itetclr")')

      call cmo_get_info('layertyp',cmo,iplayertyp,ilen,ityp,ics)
      if (ics.ne.0)
     * write(errmsg,'("Error_buffer: cannot get layertyp")')

      if (ierr.ne.0 .or. ierr1.ne.0 .or. ics.ne.0) goto 999

C      tam - commented out, this is already done above
C      if (iopt_buff.gt.0)
C     >    call cmo_get_info('layertyp',cmo,iplayertyp,ilen,ityp,ierr1)
C      if (ierr1.ne.0) write(errmsg,'("get_info copy layertyp ")')
C      if (ierr1.ne.0) goto 999
 
      if (nelm.ne. nlayer*ntri) then
         write(logmess,'(a,i10,a,i10)')
     >   'Error: expected ',nlayer*ntri,' elem, got ',nelm
         call writloga('default',0,logmess,0,ierrw)
         goto 999
      else
        do i = 1, nelm
           itetclr(i) = itetclr_sav(i)
        enddo
        do i = 1, npoints*nlayer
           layertyp(i)=ltype_sav(i)
        enddo
      endif

      if (idebug.gt.5) then
         call dotaskx3d('dump gmv STACK_pre_process.gmv/ '//
     >   cmostak(1:icharlnf(cmostak)) //
     >   '/ ; finish',ierr)
      endif

      write(errmsg,'(a)') 
     >  'Error_buffer: error during post-process setup'

C POST PROCESS - BUFFER and BEAD ALGORITHM
C This needs some clean up

      call cmo_get_info('nnodes',cmo,nnode,ilen,ityp,ierr)
      call cmo_get_info('zic',cmo,ipzic,ilen,ityp,ierr)
      call cmo_get_info('xic',cmo,ipxic,ilen,ityp,ierr)
      call cmo_get_info('yic',cmo,ipyic,ilen,ityp,ierr)
      if(ierr.ne.0) goto 9999
 
      ichange = 0
      iwarn1 = 0
      iwarn2 = 0
 
c     first fill Z array by column
c     npoints are the number of points in a layer
c     ntrunc is the truncating layer
c     nnode are the number of points total in cmo
c     number of vertical points are the number of layers = nbeads
c     nbeads = number of points in columns = nlayer_tot = nlayer final
 
      nbeads = nlayer
c     allocate bead arrays and error check arrays
      call mmgetblk("zin", isubname, ipzin, nbeads, 2, ierr)
      if(ierr.ne.0)call x3d_error(isubname, 'beads: mmgetblk zin')
      call mmgetblk("zout", isubname, ipzout, nbeads, 2, ierr)
      if(ierr.ne.0)call x3d_error(isubname, 'beads: mmgetblk zout')
      call mmgetblk("ibuff", isubname, ipibuff, nbeads, 1, ierr)
      if(ierr.ne.0)call x3d_error(isubname, 'beads: mmgetblk ibuff')
 
      if (gobeads .gt. 0) then
        write(errmsg,'(a)') 'memory error for beads setup'

C       beads_ona_ring() expects array lengths of nbeads-1 for 
C       d_pinch, d_min, id_move

        ilen = nbeads-1
        call mmgetblk("d_pinch", isubname, ipd_pinch, ilen, 2, ierr)
        if(ierr.ne.0)call x3d_error(isubname, 'beads: mmgetblk d_pinch')
        call mmgetblk("d_min", isubname, ipd_min, ilen, 2, ierr)
        if(ierr.ne.0)call x3d_error(isubname, 'beads: mmgetblk d_min')
        call mmgetblk("id_move", isubname, ipid_move, ilen, 1, ierr)
        if(ierr.ne.0)call x3d_error(isubname, 'beads: mmgetblk id_move')
 
C       fill control arrays for beads_ona_ring() and error checking
        if (nbeads .gt. 0) then
          do i = 1, ilen
             d_pinch(i) = dpinch
             d_min(i) =   dmin
             id_move(i) = iopt_move
          enddo
        else
         write(logmess,'(a,i10)')
     >   'Error: unexpected number of beads ',nbeads
         call writloga('default',0,logmess,0,ierrw)
         goto 999
        endif

      endif
 
C   ..............................................................
C   LOOP through each of the bead columns
C   jcol is each bead column, i is the row of beads
 
      write(errmsg,'(a)') 
     >  'Error_buffer: error during post-process of node columns'

      ichg=0
      ichange = 0
      do jcol = 1, npoints
 
c       fill zin for x,y column point, this will be the bead string
c       xprev and yprev are for error checking on the loop
        icnt=0
        do i = 1, nbeads
          idx = jcol + ((i-1)*npoints)
          if (i.eq.1) then
            xprev = xic(idx)
            yprev = yic(idx)
          endif
          if (xprev.ne.xic(idx)) then
            iwarn2 = iwarn2 + 1
            if (iwarn2.lt.20) then
              write(logmess,'(a,i10,i10,i10)')
     >        'Not valid column(i,jcol) node: ',i,jcol,idx
              call writloga('default',0,logmess,0,ierrw)
            endif
          endif
          if (yprev.ne.yic(idx)) then
            iwarn2 = iwarn2+1
            if (iwarn2.lt.20) then
              write(logmess,'(a,i10,i10,i10)')
     >        'Not valid column(i,jcol) node: ',i,jcol,idx
              call writloga('default',0,logmess,0,ierrw)
            endif
          endif
          zin(i) = zic(idx)
          xprev = xic(idx)
          yprev = yic(idx)
 
c         fill buffer array
          if (iopt_buff.ne.0) then
            idx = jcol + ((i-1)*npoints)
            if (layertyp(idx) .eq.1) icnt = icnt+1
            ibuff(i) = icnt
          endif
        enddo
c       CHECK ALL ELEVATIONS
        if (zin(1).eq.zin(nbeads)) then
          iwarn1 = iwarn1 + 1
          if (iwarn1.lt.20) then
            write(logmess,'(a,i10,i10)')
     >      'warning: Column has 0 height. column, node: ',jcol,idx
            call writloga('default',0,logmess,0,ierrw)
          endif
        endif
 
c   move points on the column for new zic values
c   - allow only one lower buffer point, rest get put on interface
c     this allows the colors between buffer and interface to be correct
c   - use beads_ona_ring to redistribute distances
 
C       REDISTRIBUTE BEADS
C       Fix distances according to bead input options
C       zout is filled with new values from zin
c         d_pinch If interval length d <= d_pinch then set to zero
c         d_min   If interval length is d_pinch < d < d_min set to d_min
c         id_move = 1  Get or put values equally up and down
c                 2  Get or put values up only
c                 3  Get or put values down only

        if (gobeads .gt. 0) then
          write(errmsg,'(a)') 'error during beads_ona_ring post-process'

          call beads_ona_ring(errmsg,
     >       zout,zin,d_pinch,d_min,id_move,nbeads,ierr)

          if (ierr.ne.0) then
            call writloga('default',1,errmsg,0,ierrw)
cdebug      print*,'ZIN: ',(zin(i),i=1,nbeads)
            write(errmsg,'("Fatal Error during post proccessing.")')
            goto 999
          endif
        else
          do i = 1,nbeads
            zout(i)=zin(i)
          enddo
        endif
c       Now zout contains the new zic values
 
c       CHECK BUFFERS
c       may not be needed anymore, use idebug setting to check
c       check that extra buffer points are pushed to intrface
c       and not sitting at the lower buffer (gives wrong color)
c       and check that only buffer points are at buffers
c       because layers are pinched down, only move lower buffer up

        if (iopt_buff.ne.0 .and. idebug.gt.1) then

          write(errmsg,'(a)') 'error during buffer post-process'
          i = 1
          dowhile (i.lt.nbeads)
            ifound = 0
            squished = 0
            idx = jcol + ((i-1)*npoints)
 
cdebug    if (i.eq.1) then
c         print*,jcol,'>',(j,zout(j),ibuff(j),j=1,nbeads)
c         endif
 
c           check to see if this a pile of duplicate points
            if (zout(i).eq.zout(i+1)) squished = 1
            if (squished.gt.0 ) then
              ii = i+1
              znext = zout(ii)
              dowhile (zout(ii).le.zout(i) .and. ii.le.nbeads)
                ii=ii+1
                squished = squished+1
              enddo
              if (zout(ii).gt.zout(i)) then
                znext = zout(ii)
              else
                write(logmess,'(a,i10,i10,e14.6)')
     >          'WARNING: znext for buffer not found ',jcol,i,zout(i)
                call writloga('default',0,logmess,0,ierrw)
              endif
 
c             find a buffer point, move all points after it
c             this should happen only on lower buffers
              j=0
              dowhile (ifound.eq.0 .and. j.lt.squished)
                ii=i+j
                idx = jcol + ((ii-1)*npoints)
                if (layertyp(idx).eq.1) ifound = ii
                j=j+1
              enddo
              if (mod(ibuff(ii),2).eq.0) ifound = 0
            endif
 
c           now move all beads except buffer, up to the interface
            ibot = ifound+1
            itop = i+squished-1
            if (squished.gt.0 .and. ifound.gt.0 .and.
     >           ibot.gt.0  .and. itop.gt.0 ) then
 
              do ii = ibot,itop
                if(idebug.gt.5) then
                  write(logmess,'(i9,i9,a,e14.6,a,e14.6)')
     >            jcol,ii,' change from ',zout(ii),' to ',znext
                  call writloga('default',0,logmess,0,ierr)
                endif
                zout(ii) = znext
                ichg = ichg+1
              enddo
            else
 
            if (squished.gt.1) then
               if(idebug.gt.9) then
                 write(logmess,'(a,i9,i9,i10)')
     >           'Skipped pile of points. ',jcol,i,squished
                 call writloga('default',0,logmess,0,ierr)
               endif
               do j = 0,squished
                 ii=i+j
                 idx = jcol + ((ii-1)*npoints)
               enddo
            endif
            endif
 
            if (squished.le.1) then
              i=i+1
            else
              i=i+squished
            endif
          enddo
c         end dowhile from bottom to top of column
        endif
c       end adjustments of buffers
        if(ichg.gt.0) then
          write(logmess,'(a,i10)')'Buffer node changes = ',ichg
          call writloga('default',0,logmess,0,ierr)
        endif

        write(errmsg,'(a)') 
     >  'Error_buffer: error during post-process cleanup'
 
c       COPY NEW Z VALUES over old cmo zic
c       CHECK ELEVATIONS - should be monotonic for each column
        if (zout(1).eq.zout(nbeads)) then
          iwarn1 = iwarn1 +1
          if (iwarn1 .lt. 20) then
          write(logmess,'(a,i10)')'Warning: Column has 0 height: ',jcol
          call writloga('default',0,logmess,0,ierrw)
          endif
        endif
 
        do i = 1,nbeads
          idx = jcol + ((i-1)*npoints)
          if(i.gt.1) then
             if (zout(i).lt.zout(i-1)) then
               write(logmess,'(a,i10,1pe13.6,1pe13.6)')
     >         'Node pop: ',idx,zout(i),zout(i-1)
               call writloga('default',0,logmess,0,ierrw)
             endif
          endif
 
          if ( zic(idx) .ne. zout(i)) then
            ichange = ichange + 1
          endif
          zic(idx) = zout(i)
        enddo
 
      enddo
C     END loop through columns
C     ..........................................................
      if(ichange.gt.0) then
        write(logmess,'(a,i10)')'Post process node changes = ',ichange
        call writloga('default',0,logmess,0,ierr)
      endif
      if (iwarn2.gt.0) then
        write(logmess,'(a,i10)')
     > 'Total warnings for invalid columns: ',iwarn2
        call writloga('default',0,logmess,0,ierr)
      endif
      if (iwarn1.gt.0) then
        write(logmess,'(a,i10)')
     > 'Total warnings for flat columns: ',iwarn1
        call writloga('default',0,logmess,0,ierr)
      endif

 
c     END BUFFER and BEAD ALGORITHM
C,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

      write(errmsg,'(a)') 
     >  'Error_buffer: error during stack cleanup ' 
 
c     if idone = 1 then layers were successfully merged to cmo
 500  if(ierr.ne.0) write(errmsg,'(a)') 'Error_buffer: addmesh merge'
      if(ierr.ne.0) goto 999
      idone = 1
 
 999  call writset('stat','tty','on',ierrw)
      if (idone .eq. 0) then
         write(logmess,9995) nread, nfile
         call writloga('default',1,logmess,0,ierrw)
 9995    format('STACK ERROR: ',i9,' files read out of ',i9)
         ierr = -1
         goto 9999
      endif
 
C,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
C     Done creating cmo, now do screen summary
 
      call cmo_get_info('nnodes',cmo,nnode,ilen,ityp,ierr)
      call cmo_get_info('nelements',cmo,nelm,ilen,ityp,ierr)
      call cmo_get_info('zic',cmo,ipzic,ilen,ityp,ierr1)
      if (ierr.ne.0 .or. ierr1.ne.0)
     *    write(errmsg,'(a)')
     *    'Error_buffer: get_info for summary list'
 
      write(logmess,"(a)")
     >'................................................................'
      call writloga('default',1,logmess,0,ierrw)
      write(logmess,"(a)")
     >'         surface name  layer color type llcorner  zic'
      call writloga('default',1,logmess,0,ierrw)
      ibuff2=0
      j=0
      do i = 1, nlayer_tot
       ifile = layerlist(i)
       if (ltyplist(i).ne.2 .and. ltyplist(i).ne.1 ) then
         j=j+1
       endif
 
       idx = 1 + ((i-1)*npoints)
       ii = iclr(j)
       write(logmess,"(a21,1x,i5,i5,i5,1x,i9,a3,1pe13.6)")
     *     ifile(1:icharlnf(ifile)),
     *     i,ii,ltyplist(i), idx ,')  ',zic(idx)
       call writloga('default',0,logmess,0,ierrw)
       if(iopt_remove.ne.0 .and. ibuff2.eq.0 .and.
     *    ltyplist(i).eq.1) j=j+1
 
      enddo
 
      write(logmess,'(a,i10,a,i14)')
     >'Elements per layer: ',ntri,'  stacked total: ',nelm
      call writloga('default',1,logmess,0,ierr1)
      write(logmess,'(a,i10,a,i14)')
     >'Nodes    per layer: ',npoints,'  stacked total: ',nnode
      call writloga('default',0,logmess,0,ierr1)
      if (iopt_trunc.ne.0 .and. ntrunc.ne.0) then
         write(logmess,'(a,a,i9)')'Layers truncated by ',
     >   ifile_trunc(1:icharlnf(ifile_trunc)) //' layer ', ntrunc
         call writloga('default',0,logmess,0,ierrw)
      else
         write(logmess,'(a)')'No Truncating layer specified.'
         call writloga('default',0,logmess,0,ierrw)
      endif

      write(logmess,'(a,i9,a,i9)') 
     >'files read: ',nread,'  from total: ', nfile
      call writloga('default',1,logmess,0,ierrw)
      if (iopt_buff.gt.0 .or. iopt_refine.gt.0) then
         write(logmess,'(a,i9,a,i9,a)')
     >'layers created: ',nlayer-nread,'  from total: ',nlayer
         call writloga('default',0,logmess,0,ierrw)
      endif
      write(logmess,"(a)")
     >'................................................................'
      call writloga('default',1,logmess,1,ierrw)


C     Set the new stacked cmo attributes
      call cmo_set_info('nnodes',cmo,nnode,1,1,ierr)
      call cmo_set_info('nelements',cmo,nelm,1,1,ierr)
      ipointi = 1
      ipointj = nnode
      call cmo_set_info('ipointi',cmo,ipointi,1,1,ierr)
               if (ierr.ne.0) call x3d_error(isubname,'set_ipointi')
      call cmo_set_info('ipointj',cmo,ipointj,1,1,ierr)
               if (ierr.ne.0) call x3d_error(isubname,'set_ipointj')

      cbuf='cmo/addatt/' // cmo(1:icharlnf(cmo)) //
     > '/nlayers/INT/scalar/scalar/constant//   '
     > // ' ; finish'
      call dotaskx3d(cbuf,ierr)
      if(ierr.ne.0) write(errmsg,'(a)') 
     >   'Error_buffer: addatt nlayers'

      cbuf='cmo/addatt/' // cmo(1:icharlnf(cmo)) //
     > '/nnperlayer/INT/scalar/scalar/constant//   '
     > // ' ; finish'
      call dotaskx3d(cbuf,ierr)
      if(ierr.ne.0) write(errmsg,'(a)') 
     >  'Error_buffer: addatt nnperlayer'

      cbuf='cmo/addatt/' // cmo(1:icharlnf(cmo)) //
     > '/neperlayer/INT/scalar/scalar/constant//   '
     > // ' ; finish'
      call dotaskx3d(cbuf,ierr)
      if(ierr.ne.0) write(errmsg,'(a)') 
     >   'Error_buffer: addatt neperlayer'


      write(cbuf,4010)  cmo, nlayer
      call dotaskx3d(cbuf,ierr)
 4010 format('cmo/setatt/',a32,'/nlayers ',i10,' ; finish')

      write(cbuf,4020)  cmo, npoints
      call dotaskx3d(cbuf,ierr)
 4020 format('cmo/setatt/',a32,'/nnperlayer ',i10,' ; finish')

      write(cbuf,4030)  cmo, ntri
      call dotaskx3d(cbuf,ierr)
 4030 format('cmo/setatt/',a32,'/neperlayer ',i10,' ; finish')

C     write out any possible error messeges
      call cmo_select(cmo,icscode)
      if (ierr.eq.0 .and. ierr1.eq.0 ) write(errmsg,'(a)') ' '

 9999 call mmrelprt(isubname,icscode)
      if(idebug.le.3) call writset('stat','tty','off',ierrw)
      call cmo_exist('def1',ierr)
      if (ierr.eq.0) call cmo_release('def1',icscode)
      call cmo_exist('def2',ierr)
      if (ierr.eq.0) call cmo_release('def2',icscode)
      call cmo_exist('cmonxt',ierr)
      if (ierr.eq.0) call cmo_release('cmonxt',icscode)
      call cmo_exist('cmoprev',ierr)
      if (ierr.eq.0) call cmo_release('cmoprev',icscode)


      call writset('stat','tty','on',ierrw)
      write(logmess,"(a,a)")'stack done. ',errmsg
      call writloga('default',0,logmess,1,ierrw) 

      return
      end
c     END stack_layers()
 
