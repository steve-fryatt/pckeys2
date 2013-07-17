; Copyright 2003-2013, Stephen Fryatt (info@stevefryatt.org.uk)
;
; This file is part of PCKeys 2:
;
;   http://www.stevefryatt.org.uk/software/
;
; Licensed under the EUPL, Version 1.1 only (the "Licence");
; You may not use this work except in compliance with the
; Licence.
;
; You may obtain a copy of the Licence at:
;
;   http://joinup.ec.europa.eu/software/page/eupl
;
; Unless required by applicable law or agreed to in
; writing, software distributed under the Licence is
; distributed on an "AS IS" basis, WITHOUT WARRANTIES
; OR CONDITIONS OF ANY KIND, either express or implied.
;
; See the Licence for the specific language governing
; permissions and limitations under the Licence.

; PCKeys.s
;
; PCKeys 2 Module Source
;
; REM 26/32 bit neutral



XOS_Byte				EQU	&020006
XOS_CallEvery				EQU	&02003C
XOS_Claim				EQU	&02001F
XOS_ConvertCardinal4			EQU	&0200D8
XOS_ConvertHex4				EQU	&0200D2
XOS_Module				EQU	&02001E
XOS_NewLine				EQU	&020003
XOS_PrettyPrint				EQU	&020044
XOS_ReadArgs				EQU	&020049
XOS_ReadUnsigned			EQU	&020021
XOS_Release				EQU	&020020
XOS_RemoveTickerEvent			EQU	&02003D
XOS_Write0				EQU	&020002
XOS_WriteC				EQU	&020000
XOS_WriteS				EQU	&020001
XFilter_DeRegisterPostFilter		EQU	&062643
XFilter_RegisterPostFilter		EQU	&062641
XTaskManager_EnumerateTasks		EQU	&062681
XWimp_CloseDown				EQU	&0600DD
XWimp_Initialise			EQU	&0600C0
XWimp_ReadSysInfo			EQU	&0600F2

OS_Exit					EQU	&000011
OS_GenerateError			EQU	&00002B


Wimp_Poll				EQU	&0400C7
Wimp_GetCaretPosition			EQU	&0400D3
Territory_UpperCaseTable		EQU	&043058


;version$="2.10"
;save_as$="!PCkeys.PCKeys2"


; ---------------------------------------------------------------------------------------------------------------------
; Set up the Module Workspace

WS_BlockSize		*	256
WS_TargetSize		*	&600

			^	0
WS_ModuleFlags		#	4
WS_LastKey		#	4
WS_TaskHandle		#	4
WS_Quit			#	4
WS_AppList		#	4
WS_TaskList		#	4
WS_KeyDelete		#	4
WS_KeyEnd		#	4
WS_KeyHome		#	4
WS_IconDelete		#	4
WS_IconBackspace	#	4
WS_IconEnd		#	4
WS_IconHome		#	4
WS_Block		#	WS_BlockSize
WS_Stack		#	WS_TargetSize - @

WS_Size			*	@

; --------------------------------------------------------------------------------------------------------------------
; Set up the module flags

Flag_Icon		EQU	&10			; Flag set if the caret is currently in a writable icon.
Flag_Wimp		EQU	&20			; Flag set if we are currently in a Wimp context.
FlagDoIcon		EQU	&40			; Flag set if we are supposed to be fiddling wimp icon keys.

; --------------------------------------------------------------------------------------------------------------------
; Set up application list block

			^	0
AppBlock_MagicWord	#	4
AppBlock_Next		#	4
AppBlock_Dim		#	4
AppBlock_Name		#	0			; Placeholder for names.

AppBlock_Size		*	@

; --------------------------------------------------------------------------------------------------------------------
; Set up task handle list block

			^	0
TaskBlock_MagicWord	#	4
TaskBlock_Next		#	4
TaskBlock_Dim		#	4
TaskBlock_AppPtr	#	4
TaskBlock_TaskHandle	#	4

TaskBlock_Size		*	@

; ======================================================================================================================
; Module Header

	AREA	Module,CODE,READONLY
	ENTRY

ModuleHeader
	DCD	TaskCode			; Offset to task code
	DCD	InitCode			; Offset to initialisation code
	DCD	FinalCode			; Offset to finalisation code
	DCD	ServiceCode			; Offset to service-call handler
	DCD	TitleString			; Offset to title string
	DCD	HelpString			; Offset to help string
	DCD	CommandTable			; Offset to command table
	DCD	0				; SWI Chunk number
	DCD	0				; Offset to SWI handler code
	DCD	0				; Offset to SWI decoding table
	DCD	0				; Offset to SWI decoding code
	DCD	0				; MessageTrans file
	DCD	ModuleFlags			; Offset to module flags

; ======================================================================================================================

ModuleFlags
	DCD	1				; 32-bit compatible

; ======================================================================================================================

TitleString
	DCB	"PCKeys",0
	ALIGN

HelpString
	DCB	"PC Keyboard",9,$BuildVersion," (",$BuildDate,") ",169," Stephen Fryatt, 2003-",$BuildDate:RIGHT:4
	ALIGN

; ======================================================================================================================

CommandTable
	DCB	"Desktop_PCKeys",0
	ALIGN
	DCD	CommandDesktop
	DCD	&00000000
	DCD	0
	DCD	0

	DCB	"PCKeysAddApp",0
	ALIGN
	DCD	CommandAddApp
	DCD	&00FF0001
	DCD	CommandAddAppSyntax
	DCD	CommandAddAppHelp

	DCB	"PCKeysRemoveApp",0
	ALIGN
	DCD	CommandRemoveApp
	DCD	&000FF0001
	DCD	CommandRemoveAppSyntax
	DCD	CommandRemoveAppHelp

	DCB	"PCKeysListApps",0
	ALIGN
	DCD	CommandListApps
	DCD	&00000000
	DCD	CommandListAppsSyntax
	DCD	CommandListAppsHelp

	DCB	"PCKeysConfigure",0
	ALIGN
	DCD	CommandConfigure
	DCD	&00FF0000
	DCD	CommandConfigureSyntax
	DCD	CommandConfigureHelp

	DCD	0

; ----------------------------------------------------------------------------------------------------------------------

CommandAddAppHelp
	DCB	"*"
	DCB	27
	DCB	0
	DCB	" "
	DCB	"adds an application to the PCKeys filter list."
	DCB	13

CommandAddAppSyntax
	DCB	27
	DCB	30
	DCB	"-task] <app name>"
	DCB	0

CommandRemoveAppHelp
	DCB	"*"
	DCB	27
	DCB	0
	DCB	" "
	DCB	"removes an application from the PCKeys filter list."
	DCB	13

CommandRemoveAppSyntax
	DCB	27
	DCB	30
	DCB	"-task] <app name>"
	DCB	0

CommandListAppsHelp
	DCB	"*"
	DCB	27
	DCB	0
	DCB	" "
	DCB	"lists the applications currently on the PCKeys filter list."
	DCB	13

CommandListAppsSyntax
	DCB	27
	DCB	1
	DCB	0

CommandConfigureHelp
	DCB	"*"
	DCB	27
	DCB	0
	DCB	" "
	DCB	"sets or displays the PCKeys settings."
	DCB	13

CommandConfigureSyntax
	DCB	27
	DCB	30
	DCB	"-adelete <key>] [-aend|acopy <key>] [-ahome <key>]"
	DCB	13
	DCB	9
	DCB	"[-idelete <key>] [-ibacksp <key>] [-iend|icopy <key>] [-ihome <key>]"
	DCB	13
	DCB	9
	DCB	"[-icons|nicons]"
	DCB	0

	ALIGN

; ======================================================================================================================

; The code for *Desktop_PCKeys

CommandDesktop
	STMFD	R13!,{R14}

	; Exit with V set if Desktop_PCKeys is used manually.

	LDR	R14,[R12,#WS_TaskHandle]
	CMN	R14,#1
	ADRNE	R0,DesktopMisused
	MSRNE	CPSR_f, #9 << 28
	LDMNEFD	R13!,{PC}

	; Pass *Desktop_PCKeys to OS_Module.

	MOV	R2,R0
	ADR	R1,TitleString
	MOV	R0,#2
	SWI	XOS_Module

	LDMFD	R13!,{PC}

DesktopMisused
	DCD	0
	DCB	"Use *Desktop to start PCKeys.",0
	ALIGN

; ======================================================================================================================

; The code for the *PCKeysAddApp command.
;
; Entered with one parameter (the application name).

CommandAddApp
	STMFD	R13!,{R14}
	LDR	R12,[R12]

; Claim 64 bytes of workspace from the stack.

	SUB	R13,R13,#64

; Decode the parameter string.

	MOV	R1,R0
	ADR	R0,AddAppKeywordString
	MOV	R2,R13
	MOV	R3,#64
	SWI	XOS_ReadArgs
	BVS	AddAppExit

; Check if the application is already listed.  If it is, exit now.

	LDR	R0,[R2,#0]
	BL	FindAppBlock
	TEQ	R6,#0
	BNE	AddAppExit

	MOV	R6,R0				; Keep the name pointer somewhere safe

; Count the length of the taskname and terminator.

	MOV	R3,#0

AddAppCountLoop
	LDRB	R4,[R0],#1
	ADD	R3,R3,#1
	CMP	R4,#32
	BGE	AddAppCountLoop

; Claim a block from the RMA to store the task details.

AddAppClaimBlock
	MOV	R0,#6
	ADD	R3,R3,#AppBlock_Size
	SWI	XOS_Module
	BVS	AddAppExit

; Initialise the details.

AddAppFillBlock
	LDR	R0,MagicWord				; Magic word to check block identity.
	STR	R0,[R2,#AppBlock_MagicWord]

	STR	R3,[R2,#AppBlock_Dim]			; Block size.

	ADD	R4,R2,#AppBlock_Name 			; Point to the start of the namespace...

AddAppCopyLoop
	LDRB	R5,[R6],#1				; ...and copy the name in.
	STRB	R5,[R4],#1
	CMP	R5,#32
	BGE	AddAppCopyLoop

; Link the block into the application list.

AddAppLinkIn
	LDR	R5,[R12,#WS_AppList]
	STR	R5,[R2,#AppBlock_Next]
	STR	R2,[R12,#WS_AppList]

	MOV	R6,R2					; Get the block pointer into R6

; Enumerate the tasks and apply a filter to the new task if present

	MOV	R0,#0

AddAppFindLoop
	ADD	R1,R12,#WS_Block
	MOV	R2,#16
	SWI	XTaskManager_EnumerateTasks

	ADD	R3,R12,#WS_Block
	TEQ	R1,R3
	BEQ	AddAppFindLoopEnd

	LDR	R3,[R3,#4]
	ADD	R4,R6,#AppBlock_Name

	BL	Compare
	BNE	AddAppFindLoopEnd

	STMFD	R13!,{R0}
	LDR	R0,[R12,#WS_Block]
	BL	AddFilter
	LDMFD	R13!,{R0}

AddAppFindLoopEnd
	CMP	R0,#0
	BGE	AddAppFindLoop

AddAppExit
	ADD	R13,R13,#64
	LDMFD	R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

AddAppKeywordString
	DCB	"task",0
	ALIGN

; ======================================================================================================================

; The code for the *PCKeysRemoveApp command.
;
; Entered with one paramener (the application name).

CommandRemoveApp
	STMFD	R13!,{R14}
	LDR	R12,[R12]

; Claim 64 bytes of workspace from the stack.

	SUB	R13,R13,#64

; Decode the parameter string.

	MOV	R1,R0
	ADR	R0,RemAppKeywordString
	MOV	R2,R13
	MOV	R3,#64
	SWI	XOS_ReadArgs
	BVS	RemAppExit

; Find the task block if it exists.

	LDR	R0,[R2,#0]
	BL	FindAppBlock

	TEQ	R6,#0
	BEQ	RemAppExit

; Remove all the filters and task blocks.  This is currently done rather inefficiently, searching through the
; linked list until we find a match then removing it and starting again.  This is repeated until the end of the list
; is reached.

RemAppStartTaskSearch
	LDR	R5,[R12,#WS_TaskList]

RemAppTaskSearchLoop
	TEQ	R5,#0
	BEQ	RemAppStartAppSearch

	LDR	R4,[R5,#TaskBlock_AppPtr]

	TEQ	R4,R6
	BNE	RemAppTaskSearchNoMatch

	BL	RemoveFilter
	B	RemAppStartTaskSearch

RemAppTaskSearchNoMatch
	LDR	R5,[R5,#TaskBlock_Next]
	B	RemAppTaskSearchLoop

; Find the app block in the linked list and remove it.

RemAppStartAppSearch
	ADD	R0,R12,#WS_AppList

RemAppFindAppLoop
	LDR       R1,[R0]

	TEQ	R1,R6
	BEQ	RemAppFoundTask

	ADD	R0,R1,#AppBlock_Next
	B	RemAppFindAppLoop

RemAppFoundTask
	LDR       R1,[R6,#AppBlock_Next]
	STR       R1,[R0]

	MOV	R0,#7
	MOV	R2,R6
	SWI	XOS_Module

RemAppExit
	ADD	R13,R13,#64
	LDMFD	R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

RemAppKeywordString
	DCB	"task",0
	ALIGN

; ======================================================================================================================

; The code for the *PCKeysListApps command.
;
; Entered with no parameters.

CommandListApps
	STMFD	R13!,{R14}
	LDR	R12,[R12]

; Write out the column headings.

	MOV	R1,#0
	MOV	R2,#0

	ADR	R0,DisplayTitles
	SWI	XOS_PrettyPrint
	SWIVC	XOS_NewLine
	BVS	ListAppsExit

; Traverse the app data linked list, printing the application data out as we go.

	LDR	R6,[R12,#WS_AppList]

ListAppsOuterLoop
	TEQ	R6,#0
	BEQ	ListAppsExit

; Print the application name

ListAppsPrintName
	ADD	R0,R6,#AppBlock_Name
	MOV	R1,#24
	BL	PrintPaddedString

; Find the number of active filters and print them.

ListAppsCountFilters
	MOV	R0,#0                                   ; Filter count

	LDR	R5,[R12,#WS_TaskList]

ListAppsCountLoop
	TEQ	R5,#0
	BEQ	ListAppsCountExit

	LDR	R1,[R5,#TaskBlock_AppPtr]
	TEQ	R1,R6
	ADDEQ	R0,R0,#1

	LDR	R5,[R5,#TaskBlock_Next]
	B	ListAppsCountLoop

ListAppsCountExit
	TEQ	R0,#0
	BEQ	ListAppsPrintNoFilters

ListAppsPrintFilters
	ADD	R1,R12,#WS_Block
	MOV	R2,#WS_BlockSize
	SWI	XOS_ConvertCardinal4
	SWIVC	XOS_Write0

	B	ListAppsPrintEOL

ListAppsPrintNoFilters
	SWI	XOS_WriteS
	DCB	"None",0
	ALIGN

; End off with a new line.

ListAppsPrintEOL
	SWIVC	XOS_NewLine
	BVS	ListAppsExit

; Get the next application data block and loop.

	LDR	R6,[R6,#AppBlock_Next]
	B	ListAppsOuterLoop

; Print a final blank line and exit.

ListAppsExit
	SWI	XOS_NewLine

	LDMFD	R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

MagicWord
	DCB	"PCKB"					; The RMA data block identifier.

DisplayTitles
	DCB	"Task\t\t\tFilters",13
	DCB	"----\t\t\t-------",0

	ALIGN

; ======================================================================================================================

; The code for the *PCKeysConfigure command.
;
; Entered with various parameters.

CommandConfigure
	STMFD	R13!,{R14}
	LDR	R12,[R12]

; Check if there were any parameters; if not, show the current configuration, decode them.

	TEQ	R1,#0
	BEQ	ConfigureShow


; Set the parameters.

ConfigureSet
	SUB	R13,R13,#128				; Claim 128 bytes of workspace from the stack.

; Decode the parameter string.

	MOV	R1,R0
	ADR	R0,ConfigureKeywordString
	MOV	R2,R13
	MOV	R3,#128
	SWI	XOS_ReadArgs
	BVS	ConfigureExitSet

; Get the numbers one at a time and

	MOV	R4,R2					; Put the command buffer somewhere safe.

	MOV	R0,#10					; Make up R0 for OS_ReadUnsigned
	ORR	R0,R0,#(1<<29)

ConfigureDecodeDelete
	LDR	R1,[R4,#0]
	TEQ	R1,#0
	BEQ	ConfigureDecodeEnd

	MOV	R2,#&200
	SWI	XOS_ReadUnsigned
	BVS	ConfigureExitSet
	STR	R2,[R12,#WS_KeyDelete]

ConfigureDecodeEnd
	LDR	R1,[R4,#4]
	TEQ	R1,#0
	BEQ	ConfigureDecodeHome

	MOV	R2,#&200
	SWI	XOS_ReadUnsigned
	BVS	ConfigureExitSet
	STR	R2,[R12,#WS_KeyEnd]

ConfigureDecodeHome
	LDR	R1,[R4,#8]
	TEQ	R1,#0
	BEQ	ConfigureDecodeIDelete

	MOV	R2,#&200
	SWI	XOS_ReadUnsigned
	BVS	ConfigureExitSet
	STR	R2,[R12,#WS_KeyHome]

ConfigureDecodeIDelete
	LDR	R1,[R4,#12]
	TEQ	R1,#0
	BEQ	ConfigureDecodeIBackspace

	MOV	R2,#&200
	SWI	XOS_ReadUnsigned
	BVS	ConfigureExitSet
	STR	R2,[R12,#WS_IconDelete]

ConfigureDecodeIBackspace
	LDR	R1,[R4,#16]
	TEQ	R1,#0
	BEQ	ConfigureDecodeIEnd

	MOV	R2,#&200
	SWI	XOS_ReadUnsigned
	BVS	ConfigureExitSet
	STR	R2,[R12,#WS_IconBackspace]

ConfigureDecodeIEnd
	LDR	R1,[R4,#20]
	TEQ	R1,#0
	BEQ	ConfigureDecodeIHome

	MOV	R2,#&200
	SWI	XOS_ReadUnsigned
	BVS	ConfigureExitSet
	STR	R2,[R12,#WS_IconEnd]

ConfigureDecodeIHome
	LDR	R1,[R4,#24]
	TEQ	R1,#0
	BEQ	ConfigureDecodeIcons

	MOV	R2,#&200
	SWI	XOS_ReadUnsigned
	BVS	ConfigureExitSet
	STR	R2,[R12,#WS_IconHome]

ConfigureDecodeIcons
	LDR	R1,[R4,#28]
	TEQ	R1,#0
	BEQ	ConfigureDecodeNIcons

	LDR	R2,[R12,#WS_ModuleFlags]
	ORR	R2,R2,#FlagDoIcon
	STR	R2,[R12,#WS_ModuleFlags]

ConfigureDecodeNIcons
	LDR	R1,[R4,#32]
	TEQ	R1,#0
	BEQ	ConfigureExitSet

	LDR	R2,[R12,#WS_ModuleFlags]
	BIC	R2,R2,#FlagDoIcon
	STR	R2,[R12,#WS_ModuleFlags]

ConfigureExitSet
	ADD	R13,R13,#128
	LDMFD	R13!,{PC}


ConfigureShow

; Display the details for the task filter keys.

	ADRL	R0,ConfigureSectionTasks
	SWI	XOS_PrettyPrint
	SWIVC	XOS_NewLine
	BVS	ConfigureExitShow

	ADRL	R0,ConfigureTitles
	SWI	XOS_PrettyPrint
	SWIVC	XOS_NewLine
	BVS	ConfigureExitShow

; Output the details for the individual keys.

	ADRL	R0,ConfigureNameDelete
	MOV	R1,#8
	BL	PrintPaddedString
	BVS	ConfigureExitShow

	LDR	R0,[R12,#WS_KeyDelete]
	ADD	R1,R12,#WS_Block
	MOV	R2,#WS_BlockSize
	SWI	XOS_ConvertHex4
	SWIVC	XOS_Write0
	SWIVC	XOS_NewLine
	BVS	ConfigureExitShow

	ADRL	R0,ConfigureNameEnd
	MOV	R1,#8
	BL	PrintPaddedString
	BVS	ConfigureExitShow

	LDR	R0,[R12,#WS_KeyEnd]
	ADD	R1,R12,#WS_Block
	MOV	R2,#WS_BlockSize
	SWI	XOS_ConvertHex4
	SWIVC	XOS_Write0
	SWIVC	XOS_NewLine
	BVS	ConfigureExitShow

	ADRL	R0,ConfigureNameHome
	MOV	R1,#8
	BL	PrintPaddedString
	BVS	ConfigureExitShow

	LDR	R0,[R12,#WS_KeyHome]
	ADD	R1,R12,#WS_Block
	MOV	R2,#WS_BlockSize
	SWI	XOS_ConvertHex4
	SWIVC	XOS_Write0
	SWIVC	XOS_NewLine
	BVS	ConfigureExitShow

; Output a new line for tidyness.

	SWI	XOS_NewLine
	BVS	ConfigureExitShow

; Test to see if we are fiddling icon keys, and exit now if we are not.  Otherwise, show the icon keys.

	LDR	R0,[R12,#WS_ModuleFlags]
	TST	R0,#FlagDoIcon
	BEQ	ConfigureExitShow

; Display the details for the writable icon keys.

	ADRL	R0,ConfigureSectionIcons
	SWI	XOS_PrettyPrint
	SWIVC	XOS_NewLine
	BVS	ConfigureExitShow

	ADRL	R0,ConfigureTitles
	SWI	XOS_PrettyPrint
	SWIVC	XOS_NewLine
	BVS	ConfigureExitShow

; Output the details for the individual keys.

	ADRL	R0,ConfigureNameDelete
	MOV	R1,#8
	BL	PrintPaddedString
	BVS	ConfigureExitShow

	LDR	R0,[R12,#WS_IconDelete]
	ADD	R1,R12,#WS_Block
	MOV	R2,#WS_BlockSize
	SWI	XOS_ConvertHex4
	SWIVC	XOS_Write0
	SWIVC	XOS_NewLine
	BVS	ConfigureExitShow

	ADRL	R0,ConfigureNameBackspace
	MOV	R1,#8
	BL	PrintPaddedString
	BVS	ConfigureExitShow

	LDR	R0,[R12,#WS_IconBackspace]
	ADD	R1,R12,#WS_Block
	MOV	R2,#WS_BlockSize
	SWI	XOS_ConvertHex4
	SWIVC	XOS_Write0
	SWIVC	XOS_NewLine
	BVS	ConfigureExitShow

	ADRL	R0,ConfigureNameEnd
	MOV	R1,#8
	BL	PrintPaddedString
	BVS	ConfigureExitShow

	LDR	R0,[R12,#WS_IconEnd]
	ADD	R1,R12,#WS_Block
	MOV	R2,#WS_BlockSize
	SWI	XOS_ConvertHex4
	SWIVC	XOS_Write0
	SWIVC	XOS_NewLine
	BVS	ConfigureExitShow

	ADRL	R0,ConfigureNameHome
	MOV	R1,#8
	BL	PrintPaddedString
	BVS	ConfigureExitShow

	LDR	R0,[R12,#WS_IconHome]
	ADD	R1,R12,#WS_Block
	MOV	R2,#WS_BlockSize
	SWI	XOS_ConvertHex4
	SWIVC	XOS_Write0
	SWIVC	XOS_NewLine
	BVS	ConfigureExitShow

; Output a new line for tidyness.

	SWI	XOS_NewLine

ConfigureExitShow
	LDMFD	R13!,{PC}


; ----------------------------------------------------------------------------------------------------------------------

ConfigureKeywordString
	DCB      "adelete/K,aend=acopy/K,ahome/K,idelete/K,ibacksp/K,iend=icopy/K,ihome/K,icons/S,nicons/S",0

ConfigureSectionTasks
	DCB	"Task filters:",0

ConfigureSectionIcons
	DCB	"Writable icons:",0

ConfigureTitles
	DCB	"Key\tCode",13
	DCB	"---\t----",0

ConfigureNameDelete
	DCB	"Delete",0

ConfigureNameBackspace
	DCB	"BackSp",0

ConfigureNameEnd
	DCB	"End",0

ConfigureNameHome
	DCB	"Home",0
	ALIGN

; ======================================================================================================================

InitCode
	STMFD     R13!,{R14}

; Claim our workspace and store the pointer.

	MOV	R0,#6
	MOV	R3,#WS_Size
	SWI	XOS_Module
	BVS	InitExit
	STR	R2,[R12]
	MOV	R12,R2

; Initialise the workspace that was just claimed.

	MOV	R0,#0 ; Was %11 ??
	STR	R0,[R12,#WS_ModuleFlags]

	MOV	R0,#0
	STR	R0,[R12,#WS_LastKey]
	STR	R0,[R12,#WS_TaskHandle]
	STR	R0,[R12,#WS_AppList]
	STR	R0,[R12,#WS_TaskList]

	LDR	R0,Key_Delete
	STR	R0,[R12,#WS_KeyDelete]
	LDR	R0,Key_End
	STR	R0,[R12,#WS_KeyEnd]
	LDR	R0,Key_Home
	STR	R0,[R12,#WS_KeyHome]

	LDR	R0,Icon_Delete
	STR	R0,[R12,#WS_IconDelete]
	LDR	R0,Icon_Backspace
	STR	R0,[R12,#WS_IconBackspace]
	LDR	R0,Icon_End
	STR	R0,[R12,#WS_IconEnd]
	LDR	R0,Icon_Home
	STR	R0,[R12,#WS_IconHome]

; Install code to check desktop state every second  Pass workspace pointer in R12 (already in R2).

	MOV	R0,#99
	ADR	R1,CheckDesktopState
	SWI	XOS_CallEvery
	BVS	InitExit

; Claim InsV to trap keypresses.  Pass workspace pointer in R12 (already in R2).

	MOV	R0,#&14 ; InsV
	ADR	R1,InsV
	MOV	R2,R12
	SWI	XOS_Claim
	BVS	InitExit

; Claim EventV to trap keydown.  Pass workspace pointer in R12 (already in R2).

	MOV	R0,#&10 ; EventV
	ADR	R1,EventV
	SWI	XOS_Claim
	BVS	InitExit

; Switch on Keypress events.

	MOV	R0,#14
	MOV	R1,#11
	SWI	XOS_Byte

InitExit
	LDMFD	R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

; Keys used in application filters

Key_Delete
	DCD	&18B

Key_End
	DCD	&1AD

Key_Home
	DCD	&1AC

; Keys used in writable icons

Icon_Delete
	DCD	&8B

Icon_Backspace
	DCD	&7F

Icon_End
	DCD	&AD

Icon_Home
	DCD	&AC

; ----------------------------------------------------------------------------------------------------------------------

FinalCode
	STMFD	R13!,{R14}
	LDR	R12,[R12]

FinalKillWimptask
	LDR	R0,[R12,#WS_TaskHandle]
	CMP	R0,#0
	BLE	FinalFreeTasks

	LDR	R1,Task
	SWI	XWimp_CloseDown
	MOV	R1,#0
	STR	R1,[R12,#WS_TaskHandle]

; Work through the task list, deregistering the filters and freeing the workspace.

FinalFreeTasks

	LDR	R5,[R12,#WS_TaskList]
	MOV	R0,#7

FinalFreeTasksLoop          TEQ       R5,#0
	BEQ	FinalFreeApps

	BL	RemoveFilter

	MOV	R2,R5
	LDR	R5,[R5,#TaskBlock_Next]
	SWI	XOS_Module

	B	FinalFreeTasksLoop

; Work through the apps list, freeing the workspace.

FinalFreeApps

	LDR	R6,[R12,#WS_AppList]
	MOV	R0,#7

FinalFreeAppsLoop
	TEQ	R6,#0
	BEQ	FinalRemoveTicker

	MOV	R2,R6
	LDR	R6,[R6,#AppBlock_Next]
	SWI	XOS_Module

	B	FinalFreeAppsLoop

; Remove desktop check code.

FinalRemoveTicker
	ADR	R0,CheckDesktopState
	MOV	R1,R12
	SWI	XOS_RemoveTickerEvent

; Turn off keypress events.

	MOV	R0,#13
	MOV	R1,#11
	SWI	XOS_Byte

; Release claim to InsV.

	MOV	R0,#&14 ; InsV
	ADR	R1,InsV
	MOV	R2,R12
	SWI	XOS_Release

; Release claim to EventV.

	MOV	R0,#&10 ; EventV
	ADR	R1,EventV
	MOV	R2,R12
	SWI	XOS_Release

; Free the RMA workspace

FinalReleaseWorkspace
	TEQ	R12,#0
	BEQ	FinalExit
	MOV	R0,#7
	MOV	R2,R12
	SWI	XOS_Module

FinalExit
	LDMFD	R13!,{PC}

; ======================================================================================================================

CheckDesktopState

; Check the state of the desktop and set the status flag appropriately.
;
; This code probably shouldn't be called under interrupt, but it worked OK in PCKeys1 (apparently) without problem
; and there isn't an obvious way to do it otherwise...

	STMFD	R13!,{R0-R12,R14}

	MOV	R0,#3
	SWI	XWimp_ReadSysInfo
	LDMVSFD	R13!,{R0-R12,PC}

	LDR	R1,[R12,#WS_ModuleFlags]

	TEQ	R0,#1
	BICNE	R1,R1, #Flag_Wimp
	ORREQ	R1,R1, #Flag_Wimp

	STR	R1,[R12,#WS_ModuleFlags]

	LDMFD	R13!,{R0-R12,PC}

; ======================================================================================================================

EventV

; Check if the key down event ocurred and, if so, store the code away for future use by the InsV vector code.

	TEQ	R0,#11
	TEQEQ	R1,#1
	STREQ	R2,[R12,#WS_LastKey]

	MOV	PC,R14

; ======================================================================================================================

InsV

; The InsV code is used to fiddle keypresses in writable icons.
;
; Before doing anything else, check that the buffer is the keyboard buffer and if it is stack some registers and
; continue.  If not, just exit.

	TEQ	R1,#0
	MOVNE	PC,R14

	STMFD	R13!,{R2,R14}

; Check that we aresupposed to be fiddling icon keypresses, that we are in a desktop context and that the caret is
; in a writable icon at the moment.  If all three are true, carry on to munge the keypress.

	LDR	R2,[R12,#WS_ModuleFlags]
	AND	R2,R2,#(Flag_Icon:OR:Flag_Wimp:OR:FlagDoIcon)
	TEQ	R2,#(Flag_Icon:OR:Flag_Wimp:OR:FlagDoIcon)
	BNE	InsVExit

; Do the keypress substitution.  Test the code aginst Delete, Home, End and Backspace to see if it needs changing.

InsVTestDelete
	TEQ	R0,#&7F
	LDREQ	R0,[R12,#WS_IconDelete]
	BEQ	InsVExit

InsVTestHome
	TEQ	R0,#&1E
	LDREQ	R0,[R12,#WS_IconHome]
	BEQ	InsVExit

InsVTestEnd
	TEQ	R0,#&8B
	LDREQ	R0,[R12,#WS_IconEnd]
	BEQ	InsVExit

InsVTestBackspace
	TEQ	R0,#8
	BNE	InsVExit

; Backspace is a bit different, as ASCII 8 could also be Ctrl-H and we don't want to change that...  Before we do
; anything else, then, check the internal code of the last key to be pressed on a key-down event.  If it was
; backspace, we can do the substitution.

	LDR	R2,[R12,#WS_LastKey]
	TEQ	R2,#&1E
	LDREQ	R0,[R12,#WS_IconBackspace]

InsVExit
	LDMFD	R13!,{R2,PC}

; ======================================================================================================================

ServiceCode
	TEQ	R1,#&27
	TEQNE	R1,#&49
	TEQNE	R1,#&4A

	MOVNE	PC,R14

	STMFD	R13!,{R14}
	LDR	R12,[R12]

ServiceReset
	TEQ	R1,#&27
	BNE	ServiceStartWimp

	MOV	R14,#0
	STR	R14,[R12,#WS_TaskHandle]
	LDMFD	R13!,{PC}

ServiceStartWimp
	TEQ	R1,#46
	BNE	ServiceStartedWimp

	LDR	R14,[R12,#WS_TaskHandle]
	TEQ	R14,#0
	MOVEQ	R14,#-1
	STREQ	R14,[R12,#WS_TaskHandle]
	ADREQL	R0,CommandDesktop
	MOVEQ	R1,#0
	LDMFD	R13!,{PC}

ServiceStartedWimp
	LDR	R14,[R12,#WS_TaskHandle]
	CMN	R14,#1
	MOVEQ	R14,#0
	STREQ	R14,[R12,#WS_TaskHandle]
	LDMFD	R13!,{PC}

; ======================================================================================================================

FilterCode
	STMFD	R13!, {R0-R5,R14}

; Get the key-code from the poll block, then test it against Delete, End and Home keys to see if it needs changing.

	LDR	R0,[R1,#24]

FilterTestDelete
	TEQ	R0,#&7F
	BNE	FilterTestEnd

	LDR	R0,[R12,#WS_KeyDelete]
	STR	R0,[R1,#24]

	B	FilterExit

FilterTestEnd
	MOV	R2,#&08B
	ORR	R2,R2,#&100
	TEQ	R0,R2
	BNE	FilterTestHome

	LDR	R0,[R12,#WS_KeyEnd]
	STR	R0,[R1,#24]

	B	FilterExit

FilterTestHome
	TEQ	R0,#&1E
	BNE	FilterExit

	LDR	R0,[R12,#WS_KeyHome]
	STR	R0,[R1,#24]

FilterExit
	LDMFD	R13!,{R0-R5,R14}
	TEQ	PC,PC
	MOVNES	PC,R14
	MSR	CPSR_f,#0
	MOV	PC,R14

; ======================================================================================================================

Task
	DCB	"TASK"

WimpVersion
	DCD	310

WimpMessages
WimpMessageTaskInit
	DCD	&400C2		; Message_TaskInitialise
WimpMessageTaskCloseDown
	DCD	&400C3		; Message_TaskCloseDown
WimpMessageQuit
	DCD	0		; Message_Quit

PollMask
	DCD	&3830

TaskName
	DCB	"PC Keyboard",0
	ALIGN

; ======================================================================================================================

TaskCode
	LDR	R12,[R12]
	ADD	R13,R12,#WS_Size			; Set the stack up.
	ADD	R13,R13,#4				; Assume that WS_Size is OK for an immediate constant.

; Kill any previous version of our task which may be running.

	LDR	R0,[R12,#WS_TaskHandle]
	TEQ	R0,#0
	LDRGT	R1,Task
	SWIGT	XWimp_CloseDown
	MOV	R0,#0
	STRGT	R0,[R12,#WS_TaskHandle]

; Set the Quit flag to zero

	STR	R0,[R12,#WS_Quit]

; (Re) initialise the module as a Wimp task.

	LDR	R0,WimpVersion
	LDR	R1,Task
	ADR	R2,TaskName
	ADR	R3,WimpMessages
	SWI	XWimp_Initialise
	SWIVS	OS_Exit
	STR	R1,[R12,#WS_TaskHandle]

; Set R1 up to be the block pointer.

	ADD	R1,R12,#WS_Block

; ----------------------------------------------------------------------------------------------------------------------

PollLoop
	LDR	R0,PollMask
	SWI	Wimp_Poll

; Check for and deal with Null polls.

PollLoopEventNull
	TEQ	R0,#0
	BNE	PollLoopEventWimpMessage

	BL	CheckCaretLocation
	B	PollLoopEnd

; Check for and deal with user messages.

PollLoopEventWimpMessage
	TEQ	R0,#17
	TEQNE	R0,#18
	BNE	PollLoopEnd

	LDR	R0,[R1,#16]

; Message_Quit

PollLoopMessageQuit
	TEQ	R0,#0
	BNE	PollLoopMessageTaskInit
	MOV	R0,#1
	STR	R0,[R12,#WS_Quit]
	B	PollLoopEnd

; Message_TaskInit

PollLoopMessageTaskInit
	LDR	R2,WimpMessageTaskInit
	TEQ	R0,R2
	BNE	PollLoopMessageTaskCloseDown

	ADD	R0,R1,#28
	BL	FindAppBlock

	TEQ	R6,#0
	BEQ	PollLoopEnd

	LDR	R0,[R1,#4]
	BL	AddFilter

	B	PollLoopEnd

; Message_TaskCloseDown

PollLoopMessageTaskCloseDown
	LDR	R2,WimpMessageTaskCloseDown
	TEQ	R0,R2
	BNE	PollLoopEnd

	LDR	R0,[R1,#4]
	BL	FindTaskBlock

	TEQ	R5,#0
	BLNE	RemoveFilter

PollLoopEnd
	LDR	R0,[R12,#WS_Quit]
	TEQ	R0,#0
	BEQ	PollLoop

; ----------------------------------------------------------------------------------------------------------------------

CloseDown
	LDR	R0,[R12,#WS_TaskHandle]
	LDR	R1,Task
	SWI	XWimp_CloseDown

; Set the task handle to zero and die.

	MOV	R0,#0
	STR	R0,[R12,#WS_TaskHandle]

	SWI	OS_Exit

; ======================================================================================================================

CheckCaretLocation

; Check the position of the caret.  This is called on Null polls, and is used to set the icon flag if the caret is
; currently in a Wimp icon as opposed to being 'task controlled'.

	STMFD	R13!,{R0,R2,R14}

	SWI	Wimp_GetCaretPosition
	LDR	R2,[R1,#4]
	CMP	R2,#-1

	LDR	R0,[R12,#WS_ModuleFlags]
	BICEQ	R0,R0,#Flag_Icon
	ORRNE	R0,R0,#Flag_Icon
	STR	R0,[R12,#WS_ModuleFlags]

	LDMFD	R13!,{R0,R2,PC}

; ======================================================================================================================

FindAppBlock

; Find the block containing details of the named application.
;
; R0  => App title
; R12 => Workspace
;
; R6  <= block (zero if not found)

	STMFD	R13!,{R0-R5,R14}

; Set R4 up ready for the compare subroutine.  R6 points to the first block of application data.

	MOV	R4,R0
	LDR	R6,[R12,#WS_AppList]

; If this is the end of the list (null pointer in R6), exit now.

FindAppLoop
	TEQ	R6,#0
	BEQ	FindAppExit

; Point R3 to the application name and compare with the name supplied.  If equal, exit now with R6 pointing to
; the data block.

	ADD	R3,R6,#AppBlock_Name
	BL	Compare
	BEQ	FindAppExit

; Load the next block pointer into R6 and loop.

	LDR	R6,[R6,#AppBlock_Next]
	B	FindAppLoop

FindAppExit
	LDMFD	R13!,{R0-R5,PC}

; ----------------------------------------------------------------------------------------------------------------------

FindTaskBlock

; Find the block containing details of the specified task handle.
;
; R0  == Task handle
; R12 => Workspace
;
; R5  <= block (zero if not found)

	STMFD	R13!,{R0-R4,R14}

; R5 points to the first block of task data.

	LDR	R5,[R12,#WS_TaskList]

; If this is the end of the list (null pointer in R6), exit now.

FindTaskLoop
	TEQ	R5,#0
	BEQ	FindTaskExit

; Test the handle with the one supplied.  If equal, exit now with R6 pointing to the data block.

	LDR	R1,[R5,#TaskBlock_TaskHandle]
	TEQ	R0,R1
	BEQ	FindTaskExit

; Load the next block pointer into R6 and loop.

	LDR	R5,[R5,#TaskBlock_Next]
	B	FindTaskLoop

FindTaskExit
	LDMFD	R13!,{R0-R4,PC}

; ======================================================================================================================

AddFilter

; Add a filter to the specified task, associating its details with the application block supplied.
;
; R0  == Task handle
; R6  => Application block
; R12 => Workspace

	STMFD	R13!,{R0-R6,R14}

; Register the filter, using the default values.

AddFilterRegister
	MOV	R3,R0
	ADRL	R0,TitleString
	ADR	R1,FilterCode
	MOV	R2,R12
	LDR	R4,FilterPollMask
	SWI	XFilter_RegisterPostFilter

	BVS	AddFilterExit				; Don't log the details if we failed to register.

	MOV	R4,R3					; Keep R3 (task handle) safe from OS_Module 6

; Claim a block from the RMA to store the task details.

AddFilterClaimBlock

	MOV	R0,#6
	MOV	R3,#TaskBlock_Size
	SWI	XOS_Module
	BVS	AddFilterExit				; \TODO -- We lose the filter on a memory failure.

; Initialise the details.

AddFilterFillBlock
	LDR	R0,MagicWord				; Magic word to check block identity.
	STR	R0,[R2,#TaskBlock_MagicWord]
	STR	R3,[R2,#TaskBlock_Dim]		; Block size.
	STR	R6,[R2,#TaskBlock_AppPtr]		; Store a pointer to the parent application block.
	STR	R4,[R2,#TaskBlock_TaskHandle]	; Store the task handle.

; Link the block into the task list.

AddFilterLinkIn
	LDR	R5,[R12,#WS_TaskList]
	STR	R5,[R2,#TaskBlock_Next]
	STR	R2,[R12,#WS_TaskList]

AddFilterExit
	LDMFD	R13!,{R0-R6,PC}

; ----------------------------------------------------------------------------------------------------------------------

RemoveFilter

; Remove the filter specidied in the given task block.
;
; R5  => Task block
; R12 => Workspace

	STMFD	R13!,{R0-R6,R14}

RemoveFilterTest
	LDR	R3,[R5,#TaskBlock_TaskHandle]
	TEQ	R3,#0
	BEQ	RemoveFilterExit

RemoveFilterDeregister
	ADRL	R0,TitleString
	ADR	R1,FilterCode
	MOV	R2,R12
	LDR	R4,FilterPollMask
	SWI	XFilter_DeRegisterPostFilter

; Find the task block in the linked list.

	ADD	R0,R12,#WS_TaskList

RemoveFilterFindLoop
	LDR	R1,[R0]

	TEQ	R1,R5
	BEQ	RemoveFilterFoundItem

	ADD	R0,R1,#TaskBlock_Next
	B	RemoveFilterFindLoop

RemoveFilterFoundItem
	LDR	R1,[R5,#TaskBlock_Next]
	STR	R1,[R0]

	MOV	R0,#7
	MOV	R2,R5
	SWI	XOS_Module

RemoveFilterExit
	LDMFD	R13!,{R0-R6,PC}

; ----------------------------------------------------------------------------------------------------------------------

FilterPollMask
	DCD	&FFFFFFFF:EOR:(1:SHL:8)

; ======================================================================================================================

PrintPaddedString

; Print a string and pad it out with spaces to fill the column width.
;
; R0 => String to print
; R1 =  Column width
;
;    => V set on error

	STMFD	R13!,{R0-R2,R14}

	MOV	R2,R0

PrintPaddedLoop
	LDRB	R0,[R2],#1
	TEQ	R0,#0
	BEQ	PrintPaddedDoPad

	SWI	XOS_WriteC
	BVS	PrintPaddedExit

	SUBS	R1,R1,#1
	BEQ	PrintPaddedExit
	B	PrintPaddedLoop

PrintPaddedDoPad
	MOV	R0,#32	; ASC(" ")

PrintPaddedPadLoop
	SWI	XOS_WriteC
	BVS	PrintPaddedExit

	SUBS	R1,R1,#1
	BNE	PrintPaddedPadLoop

PrintPaddedExit
	LDMFD	R13!,{R0-R2,PC}

; ======================================================================================================================

; Compare two control terminated strings, case insenitively.
;
; R3 => String 1
; R4 => String 2
;
; Returns Z flag (EQ/NE).

Compare
	STMFD	R13!,{R0-R4,R14}

	MOV	R0,#-1
	SWI	Territory_UpperCaseTable

; Load two characters.

CompareLoop
	LDRB	R1,[R3],#1
	LDRB	R2,[R4],#1

; Convert both to upper case and ensure that ctrl-chars are converted to zero terminators.

	LDRB	R1,[R0,R1]
	LDRB	R2,[R0,R2]

	CMP	R1,#32
	MOVLT	R1,#0
	CMP	R2,#32
	MOVLT	R2,#0

; Perform the comparison and exit if different or the end of the string has been reached.  Return with result
; in Z flag.

	TEQ	R1,R2
	BNE	CompareExit
	TEQ	R2,#0
	BNE	CompareLoop

CompareExit
	LDMFD	R13!,{R0-R4,PC}

	END
