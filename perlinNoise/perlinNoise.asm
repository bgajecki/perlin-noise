; Data segment
.data
;
; Optimization: never use memory, only registers and constants.
;
ONE = 1

input dq 4.7, 7.4
result dq 0

; Code segment
.code

; /brief lerp
; /param a0a1:XMM0[0...127]
; /param w:XMM1[0...63]
; /use XMM2 -> buffer register
; /return XMM0[0...63]
; /description Linear interpolation.
lerp MACRO
   	movlhps xmm1, xmm1 ; Copy parameter
	mov rax, ONE ; Set RAX value to 1.0
	cvtsi2sd xmm2, rax ; Load 1.0 into XMM2
	subsd xmm2, xmm1
	movsd xmm1, xmm2
	mulpd xmm0, xmm1
	movhlps xmm1, xmm0
	addsd xmm0, xmm1
ENDM

; /brief generateRandomDouble
; /use RAX -> buffer register
; /return XMM0[0...127]
; /description  Generate random double number between 1 and 0.
; y = 1/sqrt(random_number)
generateRandomDouble MACRO
	rdrand rax
	and rax, 7FFFFFFFh ; No numbers with sign
	cvtsi2sd xmm0, rax
	movlhps xmm1, xmm1

	rdrand rax
	and rax, 7FFFFFFFh ; No numbers with sign
	cvtsi2sd xmm1, rax

	rsqrtps xmm1, xmm1
ENDM

; /brief dotGridGradient
; /param ixiy:XMM0
; /param xy:XMM1
; /return XMM0[0...63]
; /description 
dotGridGradient MACRO
   	subpd xmm1, xmm0
	generateRandomDouble
	mulpd xmm0, xmm1
	movhlps xmm1, xmm0
	addsd xmm0, xmm1
ENDM


; /brief perlinNoise
; /description Generate Perlin Noise.
; /param RAX - pointer to structure
; /return Noise.
; /use XMM3[0..127] - vector
; /use XMM4[0..127] - floor vector
; /use XMM5[0..127] - cell vector
; /use XMM6[0..127] - difference vector
; /use XMM7[0..127] - mix vector
; /use XMM8[0..127] - Gradient vector
; /use XMM8[0..127] - Interpolation vector
perlinNoise PROC
 push rbp ; save frame pointer
 mov rbp, rsp ; fix stack pointer
 sub rsp, 8 * (4 + 2)
 lea rax, input
	movupd xmm3, [rax]
	movupd xmm4, xmm3
	cvtsd2si rax, xmm4
	movhlps xmm4, xmm4
	cvtsd2si rdx, xmm4

	cvtsi2sd xmm4, rdx
	movlhps xmm4, xmm4
	cvtsi2sd xmm4, rax

	add rdx, ONE
	add rax, ONE

	cvtsi2sd xmm5, rdx
	movlhps xmm5, xmm5
	cvtsi2sd xmm5, rax

	movupd xmm6, xmm3
	subpd xmm6, xmm4

	movupd xmm0, xmm4 ; Floor vector
	movupd xmm1, xmm3 ; Vector
	dotGridGradient
	movupd xmm8, xmm0 ; Save first part of gradient vector

	movupd xmm0, xmm5 ; Cell vector
	movsd xmm0, xmm4 ; Floor vector
	movupd xmm1, xmm3 ; Vector
	dotGridGradient
	movlhps xmm8, xmm0 ; Save second part of gradient vector

	movupd xmm0, xmm8
	movsd xmm1, xmm6
	lerp
	movupd xmm9, xmm0 ; Save first part of interpolation vector

	movupd xmm0, xmm4 ; Floor vector
	movsd xmm0, xmm5 ; Cell vector
	movupd xmm1, xmm3 ; Vector
	dotGridGradient
	movupd xmm8, xmm0 ; Save first part of gradient vector

	movupd xmm0, xmm5 ; Cell vector
	movupd xmm1, xmm3 ; Vector
	dotGridGradient
	movlhps xmm8, xmm0 ; Save second part of gradient vector

	movupd xmm0, xmm8
	movsd xmm1, xmm6
	lerp
	movlhps xmm9, xmm0 ; Save second part of interpolation vector

	movupd xmm0, xmm9
	movhlps xmm1, xmm6
	lerp
	cvtsd2si rax, xmm4
xor rax, rax
mov rsp, rbp
pop rbp
	ret
perlinNoise ENDP
END