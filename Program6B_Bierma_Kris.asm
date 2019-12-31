TITLE Program 6     (Program6B_Bierma_Kris.asm)

; Author:				Kris Bierma
; Last Modified:		12/9/19
; OSU email address:	biermak@oregonstate.edu
; Course number/section:CS271-400
; Project Number:		6         Due Date:	12/8/19 (plus a grace day)
; Description:			A combinatroics practice program for students. It asks the user
;						to calculate the number of combinations of r items taken from a
;						set of n items. It generates random probelms with n in [3..12] 
;						and r in [1..n]. The user enters her answer and the program
;						shows the correct answer. 

INCLUDE Irvine32.inc
;what?

;------------------------------------
; Macro to write a string.
; receives:	the string
; returns:	nothing
; preconditions:		none
; registers changed:	none
;------------------------------------
mWriteString	MACRO	strName
	push	edx
	mov		edx, offset strName
	call	WriteString
	pop		edx
ENDM

;------------------------------------
; Macro to write a decimal.
; receives:	the place in the stack of the value
; returns:	nothing
; preconditions:		none
; registers changed:	none
;------------------------------------
mWriteDec		MACRO	placeInStack
	push	edx
	push	eax
	mov		edx, placeInStack
	mov		eax, [edx]
	call	WriteDec
	pop		eax
	pop		edx
ENDM

; (insert constant definitions here)
NLO = 3
NHI = 12
RLO = 1

.data
welcome		byte	"Welcome to the Combinations Calculator", 10
programmerName	byte	"Implemented by Kris Bierma", 10, 10, 13
extraCred	byte	"**EC: Numbering each problem and keeping score", 10, 13, 0
direct1		byte	"I'll give you a combinations problem.", 10, 13
direct2		byte	"You enter your answer and I'll let you know if you're right.", 10, 13, 0

probMsg1	byte	"Problem ", 0
probMsg2	byte	":", 10, 13, 0
probMsg3	byte	"Number of elements in the set: ", 0
probMsg4	byte	"Number of elements to choose from the set: ", 0
probMsg5	byte	"How many ways can you choose? ", 0

answerMsg1	byte	"There are ", 0
answerMsg2	byte	" combinations of ", 0
answerMsg3	byte	" items from a set of ", 0
answerMsg4	byte	".", 10, 13, 0

performMsg1	byte	"You need more practice.", 10, 13, 0
performMsg2	byte	"You are correct!", 10, 13, 0
scoreMsg	byte	"Total score: ", 0

errorMsg1	byte	"Invalid response. ", 0
errorMsg2	byte	"Invalid. Please enter a valid number.", 10, 13, 0

againMsg	byte	"Another problem? (y/n): ", 0
goodByeMsg	byte	"Okay ... goodbye.", 10, 13, 0

probNum		dword	0
score		dword	0
n			dword	?
r			dword	?
answer		dword	?		; user inputed answer
result		dword	?		; correct answer
userInput	byte 21 dup(0)
yesOrNo		byte 	?		; 'y' or 'n' for go again question 

.code
main PROC
	call	introduction

showProblemLoop:
	push	offset probNum
	push	offset score
	push	offset n
	push	offset r
	push	offset answer
	push	offset result
	call	Randomize
	call	showProblem
	push	offset userInput
	call	getData
	call	Combinations
	call	showResults

goAgain:
	mWriteString	againMsg
	; get answer
	mov		edx, offset yesOrNo
	mov		ecx, 2
	call	ReadString

	; compare with ascii code
	; if yes, go to showProblemLoop
	mov		eax, [edx]
	cmp		eax, 121
	je		showProblemLoop
	
	; if no, quit
	cmp		eax, 110
	je		theEnd

	; if neither, show errorMsg, jmp goAgain
	mWriteString	errorMsg1
	jmp		goAgain

theEnd:
	mWriteString	goodByeMsg
	exit	; exit to operating system
main ENDP


;------------------------------------
; Procedure to display introduction. Displays program title, programmer's name and program description
; receives:	nothing
; returns:	nothing
; preconditions:		calls a macro
; registers changed:	none
;------------------------------------
introduction proc
	mWriteString	 welcome
	ret
introduction endp


;------------------------------------
; Procedure to display the problem, including number of elements 
;	in the set and number of elements to choose from (both randomly chosen).
; receives:	offsets to all these must be on the stack in this 
;	order probNum, score, n, r, answer, result
; returns:	n and r saved to their addresses
; preconditions:		 see "receives" above
; registers changed:	none
;------------------------------------
showProblem PROC
	push	ebp
	mov		ebp, esp
	pushad

	mov		ebx, [ebp + 28]	; get probNum address from stack
	mov		eax, [ebx]		; get probNum from stack
	inc		eax
	mov		[ebx], eax		; inc probNum

; display problem header
	call	Crlf
	mWriteString	probMsg1
	call	WriteDec
	mWriteString	probMsg2

; calculate n randomly
	mov		eax, NHI
	sub		eax, NLO
	inc		eax
	call	RandomRange			; n in range of [3..12]
	add		eax, NLO

; save n to address (and it's currently in eax also)
	mov		ebx, [ebp + 20]
	mov		[ebx], eax

; display num elements = n
	mWriteString	probMsg3
	call	WriteDec
	call	Crlf

; calculate r randomly. eax already contains n, which is the high value for r
	sub		eax, RLO
	inc		eax
	call	RandomRange
	add		eax, RLO

; move r address in and save value in r
	mov		ebx, [ebp + 16]
	mov		[ebx], eax

; display r
	mWriteString	probMsg4
	call	WriteDec
	call	Crlf

	popad
	pop		ebp
	ret
showProblem endp


;------------------------------------
; Gets the user's answer in string format, converts to number.
; receives:	address of userInput pushed to stack
; returns:	updates userInput stored in stack
; preconditions:		none
; registers changed:	none
;------------------------------------
getData PROC
	LOCAL	byteCount:dword, numValue:dword
	pushad

GetUserInput:
; prompt user
	mWriteString	probMsg5

; read as a string
	mov		edx, [ebp + 8]		; address of userInput
	mov		ecx, sizeof	userInput
	call	ReadString
	mov		byteCount, eax

; make sure a value was entered (not just enter key)
	cmp		byteCount, 0
	je		DisplayErrorMsg

; convert to numbers and validate input
	mov		ecx, byteCount
	mov		numValue, 0
	mov		eax, numValue
	mov		esi, [ebp + 8]		; puts address of userInput into esi for use in lodsb inside loop
	cld
ConvertLoop:
	mov		edx, 10
	mul		edx			; first part of numValue calculation
	mov		ebx, eax	; shift numValue to ebx
	lodsb				; put char in al

	; see if char is in ascii range of [48..57]
	cmp		eax, 0
	je		Done
	cmp		eax, 48
	jb		DisplayErrorMsg
	cmp		eax, 57
	ja		DisplayErrorMsg

	; second part of numValue calculation
	sub		eax, 48
	add		ebx, eax
	mov		numvalue, ebx

	loop	ConvertLoop
	jmp		Done

; if invalid, display error msg
DisplayErrorMsg:
	mWriteString	errorMsg2
	jmp		GetUserInput

; pass numValue to address of answer
Done:
	mov		edx, [ebp + 16]
	mov		eax, numValue
	mov		[edx], eax

	popad
	ret 4		; pops off userInput from main
getData endp


;------------------------------------
; Calculate the combinations using n! / (r!(n-r)!)
;	Calls factorial proc for n, r and n-r
; receives:	offsets to all these must be on the stack in this 
;	order probNum, score, n, r, answer, result
; returns:	saves answer in address pushed to stack
; preconditions:		none
; registers changed:	none
;------------------------------------
combinations PROC
	LOCAL nFac:DWORD, rFac:DWORD, nMrFac:dword
	pushad	

; call factorial for n!, store in nFac
	mov		nFac, 1
	mov		edx, [ebp + 20]		; get n
	push	[edx]
	lea		eax, [ebp - 4]		; get address of nFac
	push	eax
	call	factorial

; call factorial for r!, store in rFac
	mov		rFac, 1
	mov		edx, [ebp + 16]		; get r
	push	[edx]
	lea		eax, [ebp - 8]		; get address of rFac
	push	eax
	call	factorial

; calc n-r
	mov		edx, [ebp + 20]
	mov		eax, [edx]
	mov		edx, [ebp + 16]
	sub		eax, [edx]			; eax holds n-r

; call factorial for (n-r)! if not 0, store in nMrFac
	mov		nMrFac, 1

	cmp		eax, 0
	je		ContinueCalc		; don't call factorial if n-r = 0
	
	push	eax
	lea		eax, [ebp - 12]		; get addres of nMrFac
	push	eax
	call	factorial

; calc rFac x nMrFac. put in ebx
ContinueCalc:
	mov		eax, rFac
	mul		nMrFac
	mov		ebx, eax

; calc nFac / above
	mov		eax, nFac
	mov		edx, 0
	div		ebx

; store answer in results address
	mov		ebx, [ebp+8]
	mov		[ebx], eax

	popad
	ret
combinations ENDP


;------------------------------------
; Recursive function to calculate factorial of number.
; receives:	nFac/rFac/nMrFac address and n/r/nMr value (pushed to stack from calling proc)
; returns:	saves value in address pushed to stack
; preconditions:		called from within combinations
; registers changed:	eax, ebx, edx
;------------------------------------
factorial PROC
; set up stack
	push	ebp
	mov		ebp, esp
	
	mov		edx, [ebp + 8]		; get nFac/rFac/nMrFac address
	mov		eax, [edx]
	mov		ebx, [ebp + 12]		; get n/r/nMr value
	mul		ebx
	mov		edx, [ebp + 8]		; get nFac/rFac/nMrFac address (again!)
	mov		[edx], eax			; save current product in value pushed by combinations
	
	cmp		ebx, 1
	ja		recursion
	jmp		quit

recursion:
	dec		ebx
	push	ebx
	push	edx
	call	factorial

; unwind
quit:
	pop		ebp
	ret	8
factorial endp


;------------------------------------
; Shows the results of the combinations calculation and calculates and displays score.
; receives:	addresses to results, r, n, answer, score pushed to stack
; returns:	updates score stored in stack
; preconditions:		none
; registers changed:	none
;------------------------------------
showResults proc
	push	ebp		
	mov		ebp, esp
	pushad

; get n, r, answer, results, score off stack
; display statements
	call	Crlf
	mWriteString	answerMsg1
	mWriteDec	[ebp + 8]		; results
	mWriteString	answerMsg2
	mWriteDec	[ebp + 16]		; r
	mWriteString	answerMsg3
	mWriteDec	[ebp + 20]		; n
	mWriteString	answerMsg4

; compare answer (user-input) to result (correct)
	mov		edx, [ebp + 8]		; results address
	mov		eax, [edx]
	mov		edx, [ebp + 12]		; answer address
	mov		ebx, [edx]
	cmp		eax, ebx
	jne		WrongAnswer

; update and display score for right answer
	mov		edx, [ebp + 24]
	inc		DWORD PTR [edx]
	mWriteString	performMsg2
	jmp		TheEnd

WrongAnswer:
	mWriteString	performMsg1

TheEnd:
	mWriteString	scoreMsg		; display score
	mWriteDec	[ebp + 24]
	call	Crlf
	call	Crlf

	popad
	pop		ebp
	ret
showResults endp

END main
