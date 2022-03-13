C #####################################################################
      subroutine massage2(imsgin,xmsgin,cmsgin,msgtype,nwds,
     &   ierror)
C
C #####################################################################
C
C     PURPOSE -
C
C        MASSAGE performs 'Graph Massage' on 3D meshes.  That is,
C        we create and annihilate nodes in a coordinated way
C        to improve the mesh.
C
C     INPUT ARGUMENTS -
C
C         imsgin()  - Integer array of command input tokens
C         xmsgin()  - Real array of command input tokens
C         cmsgin()  - Character array of command input tokens
C         msgtype() - Integer array of command input token types
C         nwds      - Number of command input tokens
C
C     OUTPUT ARGUMENTS -
C
C         ierror - Error Return Code (==0 ==> OK, <>0 ==> Error)
C
C     CHANGE HISTORY -
C######################################################################

      implicit none


      integer lenptr, icharlnf
      parameter (lenptr=1000000)
 
      integer nwds, imsgin(nwds), msgtype(nwds)
      integer i, j, k, ilen, itype, ierror, ierrw, ierr, itest, iout
      real*8 xmsgin(nwds), xmin, xmax, ipt, factor, REF_H, tmp2
      real*8 scale
      integer imin, imax, ntimes, tmp1, iout1, nrefine

      character*(*) cmsgin(nwds)
      character*32 cmdsave(nwds), file_name, field_name, cmo,
     *             HSCALE_CHAR(10000000), REF_H_CHAR, cout

      character*132 cbuf, cbufsave, logmess

      pointer (ipedge_max, edge_max)
      pointer (ipfield, field)
      pointer(ipout1, iout1)
      real*8 edge_max(10000000), field(10000000), HSCALE(10000000)

      nrefine = 0

      file_name = cmsgin(2)
      call fexist(file_name,ierr)
         if(ierr.eq.0) then
            print*,'Missing user-defined function file: ',file_name
            goto 9999
         endif
      
C      print *, msgtype(4)
      if(msgtype(4) .ne. 3) then
         print *, trim(cmsgin(4)),' is not a valid field'
         goto 9999
      else
         field_name = cmsgin(4)
      endif

      do i=4, nwds
         cmdsave(i) = trim(cmsgin(i))
      enddo

C     The target length scale is stored in REF_H to calculate
C     the number of times we will call massage to refine the mesh.

      if(msgtype(3) .eq. 3) then
          write(logmess,'(a)')
     *      'MASSAGE2: ',cmsgin(3),' not a valid target length scale'
         call writloga('default',0,logmess,0,ierrw)
         goto 9999
      else
         REF_H = xmsgin(3)
      endif
C
C     Save the command line for massage calls

      cbuf = 'massage'
      do j=4, nwds
         cbuf = trim(cbuf) // '/' // 
     *          cmdsave(j)
      enddo
      cbuf = trim(cbuf) // '; finish'
      cbufsave = cbuf
C
C  Check that user has specified a valid mesh object.
 
      call cmo_get_name(cmo,ierror)
      if(ierror.ne.0) then
         write(logmess,'(a)')
     *      'MASSAGE: ',cmo,' not a valid mesh object'
         call writloga('default',0,logmess,0,ierrw)
         goto 9999
      endif
C
C     Create a temporary attribute called target_edge_length
      write(REF_H_CHAR,'(f10.4)') REF_H
      call cmo_get_info('target_edge_length', cmo, iout,
     *   ilen, itype, ierror)
      if(ierror .eq. 0) then
         cbuf = 'cmo/DELATT/' // cmo(1:icharlnf(cmo)) //
     *      '/target_edge_length; finish'
         call dotaskx3d(cbuf, ierror)
         cbuf = 'cmo/addatt/' // cmo(1:icharlnf(cmo)) //
     *      '/target_edge_length/real/scalar/scalar//temporary; finish'
         call dotaskx3d (cbuf, ierror)
         cbuf = 'cmo/setatt/' // cmo(1:icharlnf(cmo)) //
     *      '/target_edge_length/' // REF_H_CHAR // ';finish'
         call dotaskx3d (cbuf, ierror)
      else
          cbuf = 'cmo/addatt/' // cmo(1:icharlnf(cmo)) //
     *      '/target_edge_length/real/scalar/scalar//temporary; finish'
         call dotaskx3d (cbuf, ierror)
         cbuf = 'cmo/setatt/' // cmo(1:icharlnf(cmo)) //
     *      '/target_edge_length/' // REF_H_CHAR // ';finish'
         call dotaskx3d (cbuf, ierror)
      endif
C
C     Create the edgemax array using quality
C     and get the maximum edge length

      cbuf = 'quality/edge_max/y;finish'
      call dotaskx3d(cbuf, ierror)
      call mmfindbk('edgemax', cmo, ipedge_max, ilen, ierror)
      call cmo_get_info('edgemax', cmo, ipedge_max, ilen, itype, ierror)

C     Done getting info
C     Now get the maximum value

      xmax = edge_max(1)
      do i = 2,ilen
        ipt=edge_max(i)
        if (ipt .gt. xmax) then
           xmax = ipt
        endif
      enddo
    
C
C     Calculate the number of times to call massage
      scale = xmax/REF_H
      ntimes = 1
      HSCALE(ntimes) = xmax
      write(HSCALE_CHAR(ntimes),'(f10.4)') HSCALE(ntimes)
      do while (scale .gt. 10)
         scale = scale/2.0
         HSCALE(ntimes+1) = HSCALE(ntimes)/2
         print *, 'Values of refinement scale', HSCALE(ntimes+1)
         write(HSCALE_CHAR(ntimes+1),'(f10.4)') HSCALE(ntimes+1)
         ntimes = ntimes + 1
      enddo

      tmp2 = 1.0/float(int(scale))
      tmp1 = ceiling(HSCALE(ntimes)/REF_H)
      factor = tmp1**tmp2

      nrefine = ntimes + int(scale)
      do k = ntimes + 1, nrefine - 1
         HSCALE(k) = REF_H*(factor**(nrefine-k))
         write(HSCALE_CHAR(k),'(f10.4)') HSCALE(k)
      enddo

      HSCALE(nrefine) = REF_H
      write(HSCALE_CHAR(nrefine),'(f10.4)') HSCALE(nrefine)

C     Now refine iteratively      
      itest = 0
      do i = 2, nrefine-1
         itest = itest + 1
         cbuf = 'infile/' // file_name // '; finish'
         call dotaskx3d(cbuf, ierror)
         call cmo_get_info(field_name, cmo, 
     *           ipfield, ilen, itype, ierror)
         if( ierror .eq. 0) then
            cbuf = 'math/floor/' // trim(cmo) // '/'
     *      // trim(field_name) // '/1,0,0/' 
     *      // trim(cmo) // '/' // trim(field_name) // '/' 
     *      // HSCALE_CHAR(i) // ';finish'
            call dotaskx3d(cbuf, ierror)
            cbuf = 'cmo/printatt/' // trim(cmo) // '/'
     *      // trim(field_name) // '/minmax; finish'
            call dotaskx3d(cbuf, ierror)
            call dotaskx3d(cbufsave, ierror)
         else
            call dotaskx3d(cbufsave, ierror)
            goto 9999
         endif
      enddo

C     Repeat the last refinement for good mesh quality
      do i = 1, 5
         cbuf = 'infile/' // file_name // '; finish'
         call dotaskx3d(cbuf, ierror)
         cbuf = 'math/floor/' // trim(cmo) // '/'
     *      // trim(field_name) // '/1,0,0/' 
     *      // trim(cmo) // '/' // trim(field_name) // '/' 
     *      // HSCALE_CHAR(nrefine) // ';finish'
         call dotaskx3d(cbuf, ierror)
         cbuf = 'cmo/printatt/' // trim(cmo) // '/'
     *   // trim(field_name) // '/minmax; finish'
         call dotaskx3d(cbuf, ierror)
         call dotaskx3d(cbufsave, ierror)
      enddo
      
C     Delete the temporary attribute 'target_edge_length'
      cbuf = 'cmo/DELATT/' // cmo(1:icharlnf(cmo)) //
     *   '/target_edge_length; finish'
      call dotaskx3d(cbuf, ierror)


 9999 continue
      end

 

