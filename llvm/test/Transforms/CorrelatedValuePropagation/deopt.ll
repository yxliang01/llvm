; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -correlated-propagation -S < %s | FileCheck %s

declare void @use()
; test requires a mix of context sensative refinement, and analysis
; of the originating IR pattern.  Neither part is enough in isolation.
define void @test1(i1 %c, i1 %c2) {
; CHECK-LABEL: @test1(
; CHECK-NEXT:    [[SEL:%.*]] = select i1 [[C:%.*]], i64 -1, i64 1
; CHECK-NEXT:    [[SEL2:%.*]] = select i1 [[C2:%.*]], i64 [[SEL]], i64 0
; CHECK-NEXT:    [[CMP:%.*]] = icmp sgt i64 [[SEL2]], 0
; CHECK-NEXT:    br i1 [[CMP]], label [[TAKEN:%.*]], label [[UNTAKEN:%.*]]
; CHECK:       taken:
; CHECK-NEXT:    call void @use() [ "deopt"(i64 1) ]
; CHECK-NEXT:    ret void
; CHECK:       untaken:
; CHECK-NEXT:    ret void
;
  %sel = select i1 %c, i64 -1, i64 1
  %sel2 = select i1 %c2, i64 %sel, i64 0
  %cmp = icmp sgt i64 %sel2, 0
  br i1 %cmp, label %taken, label %untaken
taken:
  call void @use() ["deopt" (i64 %sel2)]
  ret void
untaken:
  ret void
}

declare void @llvm.assume(i1)
declare void @llvm.experimental.guard(i1,...)

; Same as test1, but with assume not branch
define void @test1_assume(i1 %c, i1 %c2) {
; CHECK-LABEL: @test1_assume(
; CHECK-NEXT:    [[SEL:%.*]] = select i1 [[C:%.*]], i64 -1, i64 1
; CHECK-NEXT:    [[SEL2:%.*]] = select i1 [[C2:%.*]], i64 [[SEL]], i64 0
; CHECK-NEXT:    [[CMP:%.*]] = icmp sgt i64 [[SEL2]], 0
; CHECK-NEXT:    call void @llvm.assume(i1 [[CMP]])
; CHECK-NEXT:    call void @use() [ "deopt"(i64 1) ]
; CHECK-NEXT:    ret void
;
  %sel = select i1 %c, i64 -1, i64 1
  %sel2 = select i1 %c2, i64 %sel, i64 0
  %cmp = icmp sgt i64 %sel2, 0
  call void @llvm.assume(i1 %cmp)
  call void @use() ["deopt" (i64 %sel2)]
  ret void
}

; Same as test1, but with guard not branch
define void @test1_guard(i1 %c, i1 %c2) {
; CHECK-LABEL: @test1_guard(
; CHECK-NEXT:    [[SEL:%.*]] = select i1 [[C:%.*]], i64 -1, i64 1
; CHECK-NEXT:    [[SEL2:%.*]] = select i1 [[C2:%.*]], i64 [[SEL]], i64 0
; CHECK-NEXT:    [[CMP:%.*]] = icmp sgt i64 [[SEL2]], 0
; CHECK-NEXT:    call void (i1, ...) @llvm.experimental.guard(i1 [[CMP]]) [ "deopt"(i64 [[SEL2]]) ]
; CHECK-NEXT:    call void @use() [ "deopt"(i64 1) ]
; CHECK-NEXT:    ret void
;
  %sel = select i1 %c, i64 -1, i64 1
  %sel2 = select i1 %c2, i64 %sel, i64 0
  %cmp = icmp sgt i64 %sel2, 0
  call void (i1, ...) @llvm.experimental.guard(i1 %cmp) ["deopt" (i64 %sel2)]
  call void @use() ["deopt" (i64 %sel2)]
  ret void
}

;; The rest of these are slight variations on the patterns
;; producing 1 of several adjacent constants to test generality

define void @test2(i1 %c, i1 %c2) {
; CHECK-LABEL: @test2(
; CHECK-NEXT:    [[SEL:%.*]] = select i1 [[C:%.*]], i64 0, i64 1
; CHECK-NEXT:    [[SEL2:%.*]] = select i1 [[C2:%.*]], i64 [[SEL]], i64 -1
; CHECK-NEXT:    [[CMP:%.*]] = icmp sgt i64 [[SEL2]], 0
; CHECK-NEXT:    br i1 [[CMP]], label [[TAKEN:%.*]], label [[UNTAKEN:%.*]]
; CHECK:       taken:
; CHECK-NEXT:    call void @use() [ "deopt"(i64 1) ]
; CHECK-NEXT:    ret void
; CHECK:       untaken:
; CHECK-NEXT:    ret void
;
  %sel = select i1 %c, i64 0, i64 1
  %sel2 = select i1 %c2, i64 %sel, i64 -1
  %cmp = icmp sgt i64 %sel2, 0
  br i1 %cmp, label %taken, label %untaken
taken:
  call void @use() ["deopt" (i64 %sel2)]
  ret void
untaken:
  ret void
}
define void @test3(i1 %c, i1 %c2) {
; CHECK-LABEL: @test3(
; CHECK-NEXT:    [[SEL:%.*]] = select i1 [[C:%.*]], i64 0, i64 1
; CHECK-NEXT:    [[SEL2:%.*]] = select i1 [[C2:%.*]], i64 [[SEL]], i64 2
; CHECK-NEXT:    [[CMP:%.*]] = icmp sgt i64 [[SEL2]], 1
; CHECK-NEXT:    br i1 [[CMP]], label [[TAKEN:%.*]], label [[UNTAKEN:%.*]]
; CHECK:       taken:
; CHECK-NEXT:    call void @use() [ "deopt"(i64 2) ]
; CHECK-NEXT:    ret void
; CHECK:       untaken:
; CHECK-NEXT:    ret void
;
  %sel = select i1 %c, i64 0, i64 1
  %sel2 = select i1 %c2, i64 %sel, i64 2
  %cmp = icmp sgt i64 %sel2, 1
  br i1 %cmp, label %taken, label %untaken
taken:
  call void @use() ["deopt" (i64 %sel2)]
  ret void
untaken:
  ret void
}

define void @test4(i1 %c, i1 %c2) {
; CHECK-LABEL: @test4(
; CHECK-NEXT:    [[SEL:%.*]] = select i1 [[C:%.*]], i64 0, i64 1
; CHECK-NEXT:    [[SEL2:%.*]] = select i1 [[C2:%.*]], i64 0, i64 1
; CHECK-NEXT:    [[ADD1:%.*]] = add i64 0, [[SEL]]
; CHECK-NEXT:    [[ADD2:%.*]] = add i64 [[ADD1]], [[SEL2]]
; CHECK-NEXT:    [[CMP:%.*]] = icmp sgt i64 [[ADD2]], 1
; CHECK-NEXT:    br i1 [[CMP]], label [[TAKEN:%.*]], label [[UNTAKEN:%.*]]
; CHECK:       taken:
; CHECK-NEXT:    call void @use() [ "deopt"(i64 2) ]
; CHECK-NEXT:    ret void
; CHECK:       untaken:
; CHECK-NEXT:    ret void
;
  %sel = select i1 %c, i64 0, i64 1
  %sel2 = select i1 %c2, i64 0, i64 1
  %add1 = add i64 0, %sel
  %add2 = add i64 %add1, %sel2
  %cmp = icmp sgt i64 %add2, 1
  br i1 %cmp, label %taken, label %untaken
taken:
  call void @use() ["deopt" (i64 %add2)]
  ret void
untaken:
  ret void
}
