; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=kaveri -disable-promote-alloca-to-vector -amdgpu-enable-lower-module-lds=0 < %s | FileCheck -check-prefix=GCN %s

; This shows that the amount LDS size estimate should try to not be
; sensitive to the order of the LDS globals. This should try to
; estimate the worst case padding behavior to avoid overallocating
; LDS.

; These functions use the same amount of LDS, but the total, final
; size changes depending on the visit order of first use.

; The one with the suboptimal order resulting in extra padding exceeds
; the desired limit

; The padding estimate heuristic used by the promote alloca pass
; is mostly determined by the order of the globals,

; Raw usage = 1060 bytes
; Rounded usage:
; 292 + (4 pad) + 256 + (8 pad) + 512 = 1072
; 512 + (0 pad) + 256 + (0 pad) + 292 = 1060

; At default occupancy guess of 7, 2340 bytes available total.

; 1280 need to be left to promote alloca
; optimally packed, this requires


@lds0 = internal unnamed_addr addrspace(3) global [32 x <4 x i32>] poison, align 16
@lds2 = internal unnamed_addr addrspace(3) global [32 x i64] poison, align 8
@lds1 = internal unnamed_addr addrspace(3) global [73 x i32] poison, align 4


; GCN-LABEL: {{^}}promote_alloca_size_order_0:
; GCN: .amdhsa_group_segment_fixed_size 1060
define amdgpu_kernel void @promote_alloca_size_order_0(ptr addrspace(1) nocapture %out, ptr addrspace(1) nocapture %in, i32 %idx) #0 {
entry:
  %stack = alloca [5 x i32], align 4, addrspace(5)
  %tmp0 = load i32, ptr addrspace(1) %in, align 4
  %arrayidx1 = getelementptr inbounds [5 x i32], ptr addrspace(5) %stack, i32 0, i32 %tmp0
  store i32 4, ptr addrspace(5) %arrayidx1, align 4
  %arrayidx2 = getelementptr inbounds i32, ptr addrspace(1) %in, i32 1
  %tmp1 = load i32, ptr addrspace(1) %arrayidx2, align 4
  %arrayidx3 = getelementptr inbounds [5 x i32], ptr addrspace(5) %stack, i32 0, i32 %tmp1
  store i32 5, ptr addrspace(5) %arrayidx3, align 4
  %tmp2 = load i32, ptr addrspace(5) %stack, align 4
  store i32 %tmp2, ptr addrspace(1) %out, align 4
  %arrayidx12 = getelementptr inbounds [5 x i32], ptr addrspace(5) %stack, i32 0, i32 1
  %tmp3 = load i32, ptr addrspace(5) %arrayidx12
  %arrayidx13 = getelementptr inbounds i32, ptr addrspace(1) %out, i32 1
  store i32 %tmp3, ptr addrspace(1) %arrayidx13

  %gep.lds1 = getelementptr inbounds [73 x i32], ptr addrspace(3) @lds1, i32 0, i32 %idx
  store volatile i32 0, ptr addrspace(3) %gep.lds1, align 4

  %gep.lds2 = getelementptr inbounds [32 x i64], ptr addrspace(3) @lds2, i32 0, i32 %idx
  store volatile i64 0, ptr addrspace(3) %gep.lds2, align 8

  %gep.lds0 = getelementptr inbounds [32 x <4 x i32>], ptr addrspace(3) @lds0, i32 0, i32 %idx
  store volatile <4 x i32> zeroinitializer, ptr addrspace(3) %gep.lds0, align 16

  ret void
}

; GCN-LABEL: {{^}}promote_alloca_size_order_1:
; GCN: .amdhsa_group_segment_fixed_size 1072
define amdgpu_kernel void @promote_alloca_size_order_1(ptr addrspace(1) nocapture %out, ptr addrspace(1) nocapture %in, i32 %idx) #0 {
entry:
  %stack = alloca [5 x i32], align 4, addrspace(5)
  %tmp0 = load i32, ptr addrspace(1) %in, align 4
  %arrayidx1 = getelementptr inbounds [5 x i32], ptr addrspace(5) %stack, i32 0, i32 %tmp0
  store i32 4, ptr addrspace(5) %arrayidx1, align 4
  %arrayidx2 = getelementptr inbounds i32, ptr addrspace(1) %in, i32 1
  %tmp1 = load i32, ptr addrspace(1) %arrayidx2, align 4
  %arrayidx3 = getelementptr inbounds [5 x i32], ptr addrspace(5) %stack, i32 0, i32 %tmp1
  store i32 5, ptr addrspace(5) %arrayidx3, align 4
  %tmp2 = load i32, ptr addrspace(5) %stack, align 4
  store i32 %tmp2, ptr addrspace(1) %out, align 4
  %arrayidx12 = getelementptr inbounds [5 x i32], ptr addrspace(5) %stack, i32 0, i32 1
  %tmp3 = load i32, ptr addrspace(5) %arrayidx12
  %arrayidx13 = getelementptr inbounds i32, ptr addrspace(1) %out, i32 1
  store i32 %tmp3, ptr addrspace(1) %arrayidx13

  %gep.lds0 = getelementptr inbounds [32 x <4 x i32>], ptr addrspace(3) @lds0, i32 0, i32 %idx
  store volatile <4 x i32> zeroinitializer, ptr addrspace(3) %gep.lds0, align 16

  %gep.lds2 = getelementptr inbounds [32 x i64], ptr addrspace(3) @lds2, i32 0, i32 %idx
  store volatile i64 0, ptr addrspace(3) %gep.lds2, align 8

  %gep.lds1 = getelementptr inbounds [73 x i32], ptr addrspace(3) @lds1, i32 0, i32 %idx
  store volatile i32 0, ptr addrspace(3) %gep.lds1, align 4

  ret void
}

@lds3 = internal unnamed_addr addrspace(3) global [13 x i32] poison, align 4
@lds4 = internal unnamed_addr addrspace(3) global [63 x <4 x i32>] poison, align 16

; The guess from the alignment padding pushes this over the determined
; size limit, so it isn't promoted

; GCN-LABEL: {{^}}promote_alloca_align_pad_guess_over_limit:
; GCN: .amdhsa_group_segment_fixed_size 1060
define amdgpu_kernel void @promote_alloca_align_pad_guess_over_limit(ptr addrspace(1) nocapture %out, ptr addrspace(1) nocapture %in, i32 %idx) #0 {
entry:
  %stack = alloca [5 x i32], align 4, addrspace(5)
  %tmp0 = load i32, ptr addrspace(1) %in, align 4
  %arrayidx1 = getelementptr inbounds [5 x i32], ptr addrspace(5) %stack, i32 0, i32 %tmp0
  store i32 4, ptr addrspace(5) %arrayidx1, align 4
  %arrayidx2 = getelementptr inbounds i32, ptr addrspace(1) %in, i32 1
  %tmp1 = load i32, ptr addrspace(1) %arrayidx2, align 4
  %arrayidx3 = getelementptr inbounds [5 x i32], ptr addrspace(5) %stack, i32 0, i32 %tmp1
  store i32 5, ptr addrspace(5) %arrayidx3, align 4
  %tmp2 = load i32, ptr addrspace(5) %stack, align 4
  store i32 %tmp2, ptr addrspace(1) %out, align 4
  %arrayidx12 = getelementptr inbounds [5 x i32], ptr addrspace(5) %stack, i32 0, i32 1
  %tmp3 = load i32, ptr addrspace(5) %arrayidx12
  %arrayidx13 = getelementptr inbounds i32, ptr addrspace(1) %out, i32 1
  store i32 %tmp3, ptr addrspace(1) %arrayidx13

  %gep.lds3 = getelementptr inbounds [13 x i32], ptr addrspace(3) @lds3, i32 0, i32 %idx
  store volatile i32 0, ptr addrspace(3) %gep.lds3, align 4

  %gep.lds4 = getelementptr inbounds [63 x <4 x i32>], ptr addrspace(3) @lds4, i32 0, i32 %idx
  store volatile <4 x i32> zeroinitializer, ptr addrspace(3) %gep.lds4, align 16

  ret void
}

attributes #0 = { nounwind "amdgpu-flat-work-group-size"="64,64" "amdgpu-waves-per-eu"="1,7" }

!llvm.module.flags = !{!0}
!0 = !{i32 1, !"amdhsa_code_object_version", i32 400}
