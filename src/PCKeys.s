REM >PCKeys2Src
REM
REM PCKeys Module
REM (c) Stephen Fryatt, 2003
REM
REM Needs ExtBasAsm to assemble.
REM 26/32 bit neutral

version$="2.10"
save_as$="!PCkeys.PCKeys2"

LIBRARY "<Reporter$Dir>.AsmLib"

PRINT "Assemble debug? (Y/N)"
REPEAT
 g%=GET
UNTIL (g% AND &DF)=ASC("Y") OR (g% AND &DF)=ASC("N")
debug%=((g% AND &DF)=ASC("Y"))

ON ERROR PRINT REPORT$;" at line ";ERL : END

REM --------------------------------------------------------------------------------------------------------------------
REM Set up workspace

workspace_target%=&600
workspace_size%=0 : REM This is updated.
block_size%=256

module_flags%=FNworkspace(workspace_size%,4)
last_key%=FNworkspace(workspace_size%,4)
task_handle%=FNworkspace(workspace_size%,4)
quit%=FNworkspace(workspace_size%,4)
app_list%=FNworkspace(workspace_size%,4)
task_list%=FNworkspace(workspace_size%,4)
key_delete%=FNworkspace(workspace_size%,4)
key_end%=FNworkspace(workspace_size%,4)
key_home%=FNworkspace(workspace_size%,4)
icon_delete%=FNworkspace(workspace_size%,4)
icon_backspace%=FNworkspace(workspace_size%,4)
icon_end%=FNworkspace(workspace_size%,4)
icon_home%=FNworkspace(workspace_size%,4)
block%=FNworkspace(workspace_size%,block_size%)

PRINT'"Stack size:  ";workspace_target%-workspace_size%;" bytes."
stack%=FNworkspace(workspace_size%,workspace_target%-workspace_size%)

REM --------------------------------------------------------------------------------------------------------------------
REM Set up the module flags

flag_icon% =   &10 : REM Flag set if the caret is currently in a writable icon.
flag_wimp% =   &20 : REM Flag set if we are currently in a Wimp context.
flag_doicon% = &40 : REM Flag set if we are supposed to be fiddling wimp icon keys.

REM --------------------------------------------------------------------------------------------------------------------
REM Set up application list block

app_block_size%=0 : REM This is updated.

app_block_magic_word%=FNworkspace(app_block_size%,4)
app_block_next%=FNworkspace(app_block_size%,4)
app_block_dim%=FNworkspace(app_block_size%,4)
app_block_name%=FNworkspace(app_block_size%,0) : REM Last, placeholder for name

REM --------------------------------------------------------------------------------------------------------------------
REM Set up task handle list block

task_block_size%=0 : REM This is updated.

task_block_magic_word%=FNworkspace(task_block_size%,4)
task_block_next%=FNworkspace(task_block_size%,4)
task_block_dim%=FNworkspace(task_block_size%,4)
task_block_app_ptr%=FNworkspace(task_block_size%,4)
task_block_task_handle%=FNworkspace(task_block_size%,4)

REM --------------------------------------------------------------------------------------------------------------------

DIM time% 5, date% 256
?time%=3
SYS "OS_Word",14,time%
SYS "Territory_ConvertDateAndTime",-1,time%,date%,255,"(%dy %m3 %ce%yr)" TO ,date_end%
?date_end%=13

REM --------------------------------------------------------------------------------------------------------------------

code_space%=4000
DIM code% code_space%

pass_flags%=%11100

IF debug% THEN PROCReportInit(200)

FOR pass%=pass_flags% TO pass_flags% OR %10 STEP %10
L%=code%+code_space%
O%=code%
P%=0
IF debug% THEN PROCReportStart(pass%)
[OPT pass%
EXT 1
          EQUD      task_code           ; Offset to task code
          EQUD      init_code           ; Offset to initialisation code
          EQUD      final_code          ; Offset to finalisation code
          EQUD      service_code        ; Offset to service-call handler
          EQUD      title_string        ; Offset to title string
          EQUD      help_string         ; Offset to help string
          EQUD      command_table       ; Offset to command table
          EQUD      0                   ; SWI Chunk number
          EQUD      0                   ; Offset to SWI handler code
          EQUD      0                   ; Offset to SWI decoding table
          EQUD      0                   ; Offset to SWI decoding code
          EQUD      0                   ; MessageTrans file
          EQUD      module_flags        ; Offset to module flags

; ======================================================================================================================

.module_flags
          EQUD      1                   ; 32-bit compatible

; ======================================================================================================================

.title_string
          EQUZ      "PCKeys"
          ALIGN

.help_string
          EQUS      "PC Keyboard"
          EQUB      9
          EQUS      version$
          EQUS      " "
          EQUS      $date%
          EQUZ      " © Stephen Fryatt, 2003"
          ALIGN

; ======================================================================================================================

.command_table
          EQUZ      "Desktop_PCKeys"
          ALIGN
          EQUD      command_desktop
          EQUD      &00000000
          EQUD      0
          EQUD      0

          EQUZ      "PCKeysAddApp"
          ALIGN
          EQUD      command_addapp
          EQUD      &00FF0001
          EQUD      command_addapp_syntax
          EQUD      command_addapp_help

          EQUZ      "PCKeysRemoveApp"
          ALIGN
          EQUD      command_removeapp
          EQUD      &000FF0001
          EQUD      command_removeapp_syntax
          EQUD      command_removeapp_help

          EQUZ      "PCKeysListApps"
          ALIGN
          EQUD      command_listapps
          EQUD      &00000000
          EQUD      command_listapps_syntax
          EQUD      command_listapps_help

          EQUZ      "PCKeysConfigure"
          ALIGN
          EQUD      command_configure
          EQUD      &00FF0000
          EQUD      command_configure_syntax
          EQUD      command_configure_help

          EQUD      0

; ----------------------------------------------------------------------------------------------------------------------

.command_addapp_help
          EQUS      "*"
          EQUB      27
          EQUB      0
          EQUS      " "
          EQUS      "adds an application to the PCKeys filter list."
          EQUB      13

.command_addapp_syntax
          EQUB      27
          EQUB      30
          EQUS      "-task] <app name>"
          EQUB      0

.command_removeapp_help
          EQUS      "*"
          EQUB      27
          EQUB      0
          EQUS      " "
          EQUS      "removes an application from the PCKeys filter list."
          EQUB      13

.command_removeapp_syntax
          EQUB      27
          EQUB      30
          EQUS      "-task] <app name>"
          EQUB      0

.command_listapps_help
          EQUS      "*"
          EQUB      27
          EQUB      0
          EQUS      " "
          EQUS      "lists the applications currently on the PCKeys filter list."
          EQUB      13

.command_listapps_syntax
          EQUB      27
          EQUB      1
          EQUB      0

.command_configure_help
          EQUS      "*"
          EQUB      27
          EQUB      0
          EQUS      " "
          EQUS      "sets or displays the PCKeys settings."
          EQUB      13

.command_configure_syntax
          EQUB      27
          EQUB      30
          EQUS      "-adelete <key>] [-aend|acopy <key>] [-ahome <key>]"
          EQUB      13
          EQUB      9
          EQUS      "[-idelete <key>] [-ibacksp <key>] [-iend|icopy <key>] [-ihome <key>]"
          EQUB      13
          EQUB      9
          EQUS      "[-icons|nicons]"
          EQUB      0

          ALIGN

; ======================================================================================================================

; The code for *Desktop_PCKeys

.command_desktop
          STMFD     R13!,{R14}

          MOV       R2,R0
          ADR       R1,title_string
          MOV       R0,#2
          SWI       "XOS_Module"

          LDMFD     R13!,{PC}

; ======================================================================================================================

; The code for the *PCKeysAddApp command.
;
; Entered with one parameter (the application name).

.command_addapp
          STMFD     R13!,{R14}
          LDR       R12,[R12]

; Claim 64 bytes of workspace from the stack.

          SUB       R13,R13,#64

; Decode the parameter string.

          MOV       R1,R0
          ADR       R0,addapp_keyword_string
          MOV       R2,R13
          MOV       R3,#64
          SWI       "OS_ReadArgs"

; Check if the application is already listed.  If it is, exit now.

          LDR       R0,[R2,#0]
          BL        find_app_block
          TEQ       R6,#0
          BNE       addapp_exit

          MOV       R6,R0                                   ; Keep the name pointer somewhere safe

; Count the length of the taskname and terminator.

          MOV       R3,#0

.addapp_count_loop
          LDRB      R4,[R0],#1
          ADD       R3,R3,#1
          CMP       R4,#32
          BGE       addapp_count_loop

; Claim a block from the RMA to store the task details.

.addapp_claim_block
          MOV       R0,#6
          ADD       R3,R3,#app_block_size%
          SWI       "OS_Module"

; Initialise the details.

.addapp_fill_block
          LDR       R0,magic_word                           ; Magic word to check block identity.
          STR       R0,[R2,#app_block_magic_word%]

          STR       R3,[R2,#app_block_dim%]                 ; Block size.

          ADD       R4,R2,#app_block_name%                  ; Point to the start of the namespace...

.addapp_copy_loop2
          LDRB      R5,[R6],#1                              ; ...and copy the name in.
          STRB      R5,[R4],#1
          CMP       R5,#32
          BGE       addapp_copy_loop2

; Link the block into the application list.

.addapp_link_in
          LDR       R5,[R12,#app_list%]
          STR       R5,[R2,#app_block_next%]
          STR       R2,[R12,#app_list%]

          MOV       R6,R2                                   ; Get the block pointer into R6

; Enumerate the tasks and apply a filter to the new task if present

          MOV       R0,#0

.addapp_find_loop
          ADRW      R1,block%
          MOV       R2,#16
          SWI       "XTaskManager_EnumerateTasks"

          ADRW      R3,block%
          TEQ       R1,R3
          BEQ       addapp_find_loop_end

          LDR       R3,[R3,#4]
          ADD       R4,R6,#app_block_name%

          BL        compare
          BNE       addapp_find_loop_end

          STMFD     R13!,{R0}
          LDR       R0,[R12,#block%]
          BL        add_filter
          LDMFD     R13!,{R0}

.addapp_find_loop_end
          CMP       R0,#0
          BGE       addapp_find_loop

.addapp_exit
          ADD       R13,R13,#64
          LDMFD     R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

.addapp_keyword_string
          EQUZ      "task"
          ALIGN

; ======================================================================================================================

; The code for the *PCKeysRemoveApp command.
;
; Entered with one paramener (the application name).

.command_removeapp
          STMFD     R13!,{R14}
          LDR       R12,[R12]

; Claim 64 bytes of workspace from the stack.

          SUB       R13,R13,#64

; Decode the parameter string.

          MOV       R1,R0
          ADR       R0,remapp_keyword_string
          MOV       R2,R13
          MOV       R3,#64
          SWI       "OS_ReadArgs"

; Find the task block if it exists.

          LDR       R0,[R2,#0]
          BL        find_app_block

          TEQ       R6,#0
          BEQ       remapp_exit

; Remove all the filters and task blocks.  This is currently done rather inefficiently, searching through the
; linked list until we find a match then removing it and starting again.  This is repeated until the end of the list
; is reached.

.remapp_start_task_search
          LDR       R5,[R12,#task_list%]

.remapp_task_search_loop
          TEQ       R5,#0
          BEQ       remapp_start_app_search

          LDR       R4,[R5,#task_block_app_ptr%]

          TEQ       R4,R6
          BNE       remapp_task_search_nomatch

          BL        remove_filter
          B         remapp_start_task_search

.remapp_task_search_nomatch
          LDR       R5,[R5,#task_block_next%]
          B         remapp_task_search_loop

; Find the app block in the linked list and remove it.

.remapp_start_app_search
          ADRW      R0,app_list%

.remapp_find_app_loop
          LDR       R1,[R0]

          TEQ       R1,R6
          BEQ       remapp_found_task

          ADD       R0,R1,#app_block_next%
          B         remapp_find_app_loop

.remapp_found_task
          LDR       R1,[R6,#app_block_next%]
          STR       R1,[R0]

          MOV       R0,#7
          MOV       R2,R6
          SWI       "XOS_Module"

.remapp_exit
          ADD       R13,R13,#64
          LDMFD     R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

.remapp_keyword_string
          EQUZ      "task"
          ALIGN

; ======================================================================================================================

; The code for the *PCKeysListApps command.
;
; Entered with no parameters.

.command_listapps
          STMFD     R13!,{R14}
          LDR       R12,[R12]

; Write out the column headings.

          MOV       R1,#0
          MOV       R2,#0

          ADR       R0,display_titles
          SWI       "OS_PrettyPrint"
          SWI       "OS_NewLine"

; Traverse the app data linked list, printing the application data out as we go.

          LDR       R6,[R12,#app_list%]

.listapps_outer_loop
          TEQ       R6,#0
          BEQ       listapps_exit

; Print the application name

.listapps_print_name
          ADD       R0,R6,#app_block_name%
          MOV       R1,#24
          BL        print_padded_string

; Find the number of active filters and print them.

.listapps_count_filters
          MOV       R0,#0                                   ; Filter count

          LDR       R5,[R12,#task_list%]

.listapps_count_loop
          TEQ       R5,#0
          BEQ       listapps_count_exit

          LDR       R1,[R5,#task_block_app_ptr%]
          TEQ       R1,R6
          ADDEQ     R0,R0,#1

          LDR       R5,[R5,#task_block_next%]
          B         listapps_count_loop

.listapps_count_exit
          TEQ       R0,#0
          BEQ       listapps_print_no_filters

.listapps_print_filters
          ADRW      R1,block%
          MOV       R2,#block_size%
          SWI       "OS_ConvertCardinal4"
          SWI       "OS_Write0"

          B         listapps_print_eol

.listapps_print_no_filters
          SWI       "OS_WriteS"
          EQUZ      "None"
          ALIGN

; End off with a new line.

.listapps_print_eol
          SWI       "OS_NewLine"

; Get the next application data block and loop.

          LDR       R6,[R6,#app_block_next%]
          B         listapps_outer_loop

; Print a final blank line and exit.

.listapps_exit
          SWI       "OS_NewLine"

          LDMFD     R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

.magic_word
          EQUS      "PCKB"                        ; The RMA data block identifier.

.display_titles
          EQUS      "Task"
          EQUB      9
          EQUB      9
          EQUB      9
          EQUS      "Filters"

          EQUB      13

          EQUS      "----"
          EQUB      9
          EQUB      9
          EQUB      9
          EQUZ      "-------"

          ALIGN

; ======================================================================================================================

; The code for the *PCKeysConfigure command.
;
; Entered with various parameters.

.command_configure
          STMFD     R13!,{R14}
          LDR       R12,[R12]

; Check if there were any parameters; if not, show the current configuration, decode them.

          TEQ       R1,#0
          BEQ       configure_show


; Set the parameters.

.configure_set
          SUB       R13,R13,#128                             ; Claim 128 bytes of workspace from the stack.

; Decode the parameter string.

          MOV       R1,R0
          ADR       R0,configure_keyword_string
          MOV       R2,R13
          MOV       R3,#128
          SWI       "OS_ReadArgs"

; Get the numbers one at a time and

          MOV       R4,R2                                   ; Put the command buffer somewhere safe.

          MOV       R0,#10                                  ; Make up R0 for OS_ReadUnsigned
          ORR       R0,R0,#(1<<29)

.configure_decode_delete
          LDR       R1,[R4,#0]
          TEQ       R1,#0
          BEQ       configure_decode_end

          MOV       R2,#&200
          SWI       "OS_ReadUnsigned"
          STR       R2,[R12,#key_delete%]

.configure_decode_end
          LDR       R1,[R4,#4]
          TEQ       R1,#0
          BEQ       configure_decode_home

          MOV       R2,#&200
          SWI       "OS_ReadUnsigned"
          STR       R2,[R12,#key_end%]

.configure_decode_home
          LDR       R1,[R4,#8]
          TEQ       R1,#0
          BEQ       configure_decode_idelete

          MOV       R2,#&200
          SWI       "OS_ReadUnsigned"
          STR       R2,[R12,#key_home%]

.configure_decode_idelete
          LDR       R1,[R4,#12]
          TEQ       R1,#0
          BEQ       configure_decode_ibackspace

          MOV       R2,#&200
          SWI       "OS_ReadUnsigned"
          STR       R2,[R12,#icon_delete%]

.configure_decode_ibackspace
          LDR       R1,[R4,#16]
          TEQ       R1,#0
          BEQ       configure_decode_iend

          MOV       R2,#&200
          SWI       "OS_ReadUnsigned"
          STR       R2,[R12,#icon_backspace%]

.configure_decode_iend
          LDR       R1,[R4,#20]
          TEQ       R1,#0
          BEQ       configure_decode_ihome

          MOV       R2,#&200
          SWI       "OS_ReadUnsigned"
          STR       R2,[R12,#icon_end%]

.configure_decode_ihome
          LDR       R1,[R4,#24]
          TEQ       R1,#0
          BEQ       configure_decode_icons

          MOV       R2,#&200
          SWI       "OS_ReadUnsigned"
          STR       R2,[R12,#icon_home%]

.configure_decode_icons
          LDR       R1,[R4,#28]
          TEQ       R1,#0
          BEQ       configure_decode_nicons

          LDR       R2,[R12,#module_flags%]
          ORR       R2,R2,#flag_doicon%
          STR       R2,[R12,#module_flags%]

.configure_decode_nicons
          LDR       R1,[R4,#32]
          TEQ       R1,#0
          BEQ       configure_exit_set

          LDR       R2,[R12,#module_flags%]
          BIC       R2,R2,#flag_doicon%
          STR       R2,[R12,#module_flags%]

.configure_exit_set
          ADD       R13,R13,#128
          LDMFD     R13!,{PC}


.configure_show

; Display the details for the task filter keys.

          ADRL      R0,configure_sect_tasks
          SWI       "OS_PrettyPrint"
          SWI       "OS_NewLine"

          ADRL      R0,configure_titles
          SWI       "OS_PrettyPrint"
          SWI       "OS_NewLine"

; Output the details for the individual keys.

          ADRL      R0,configure_name_delete
          MOV       R1,#8
          BL        print_padded_string

          LDR       R0,[R12,#key_delete%]
          ADRW      R1,block%
          MOV       R2,#block_size%
          SWI       "OS_ConvertHex4"
          SWI       "OS_Write0"
          SWI       "OS_NewLine"

          ADRL      R0,configure_name_end
          MOV       R1,#8
          BL        print_padded_string

          LDR       R0,[R12,#key_end%]
          ADRW      R1,block%
          MOV       R2,#block_size%
          SWI       "OS_ConvertHex4"
          SWI       "OS_Write0"
          SWI       "OS_NewLine"

          ADRL      R0,configure_name_home
          MOV       R1,#8
          BL        print_padded_string

          LDR       R0,[R12,#key_home%]
          ADRW      R1,block%
          MOV       R2,#block_size%
          SWI       "OS_ConvertHex4"
          SWI       "OS_Write0"
          SWI       "OS_NewLine"

; Output a new line for tidyness.

          SWI       "OS_NewLine"

; Test to see if we are fiddling icon keys, and exit now if we are not.  Otherwise, show the icon keys.

          LDR       R0,[R12,#module_flags%]
          TST       R0,#flag_doicon%
          BEQ       configure_exit_show

; Display the details for the writable icon keys.

          ADRL      R0,configure_sect_icons
          SWI       "OS_PrettyPrint"
          SWI       "OS_NewLine"

          ADRL      R0,configure_titles
          SWI       "OS_PrettyPrint"
          SWI       "OS_NewLine"

; Output the details for the individual keys.

          ADRL      R0,configure_name_delete
          MOV       R1,#8
          BL        print_padded_string

          LDR       R0,[R12,#icon_delete%]
          ADRW      R1,block%
          MOV       R2,#block_size%
          SWI       "OS_ConvertHex4"
          SWI       "OS_Write0"
          SWI       "OS_NewLine"

          ADRL      R0,configure_name_backspace
          MOV       R1,#8
          BL        print_padded_string

          LDR       R0,[R12,#icon_backspace%]
          ADRW      R1,block%
          MOV       R2,#block_size%
          SWI       "OS_ConvertHex4"
          SWI       "OS_Write0"
          SWI       "OS_NewLine"

          ADRL      R0,configure_name_end
          MOV       R1,#8
          BL        print_padded_string

          LDR       R0,[R12,#icon_end%]
          ADRW      R1,block%
          MOV       R2,#block_size%
          SWI       "OS_ConvertHex4"
          SWI       "OS_Write0"
          SWI       "OS_NewLine"

          ADRL      R0,configure_name_home
          MOV       R1,#8
          BL        print_padded_string

          LDR       R0,[R12,#icon_home%]
          ADRW      R1,block%
          MOV       R2,#block_size%
          SWI       "OS_ConvertHex4"
          SWI       "OS_Write0"
          SWI       "OS_NewLine"

; Output a new line for tidyness.

          SWI       "OS_NewLine"

.configure_exit_show
          LDMFD     R13!,{PC}


; ----------------------------------------------------------------------------------------------------------------------

.configure_keyword_string
          EQUZ      "adelete/K,aend=acopy/K,ahome/K,idelete/K,ibacksp/K,iend=icopy/K,ihome/K,icons/S,nicons/S"

.configure_sect_tasks
          EQUZ      "Task filters:"

.configure_sect_icons
          EQUZ      "Writable icons:"

.configure_titles
          EQUS      "Key"
          EQUB      9
          EQUS      "Code"

          EQUB      13

          EQUS      "---"
          EQUB      9
          EQUZ      "----"

.configure_name_delete
          EQUZ      "Delete"

.configure_name_backspace
          EQUZ      "BackSp"

.configure_name_end
          EQUZ      "End"

.configure_name_home
          EQUZ      "Home"
          ALIGN

; ======================================================================================================================

.init_code
          STMFD     R13!,{R14}

; Claim our workspace and store the pointer.

          MOV       R0,#6
          MOV       R3,#workspace_size%
          SWI       "XOS_Module"
          BVS       init_exit
          STR       R2,[R12]
          MOV       R12,R2

; Initialise the workspace that was just claimed.

          MOV       R0,#0 ; Was %11 ??
          STR       R0,[R12,#module_flags%]

          MOV       R0,#0
          STR       R0,[R12,#last_key%]
          STR       R0,[R12,#task_handle%]
          STR       R0,[R12,#app_list%]
          STR       R0,[R12,#task_list%]

          LDR       R0,key_delete
          STR       R0,[R12,#key_delete%]
          LDR       R0,key_end
          STR       R0,[R12,#key_end%]
          LDR       R0,key_home
          STR       R0,[R12,#key_home%]

          LDR       R0,icon_delete
          STR       R0,[R12,#icon_delete%]
          LDR       R0,icon_backspace
          STR       R0,[R12,#icon_backspace%]
          LDR       R0,icon_end
          STR       R0,[R12,#icon_end%]
          LDR       R0,icon_home
          STR       R0,[R12,#icon_home%]

; Install code to check desktop state every second  Pass workspace pointer in R12 (already in R2).

          MOV       R0,#99
          ADR       R1,check_desktop_state
          SWI       "XOS_CallEvery"
          BVS       init_exit

; Claim InsV to trap keypresses.  Pass workspace pointer in R12 (already in R2).

          MOV       R0,#&14 ; InsV
          ADR       R1,insv
          MOV       R2,R12
          SWI       "XOS_Claim"
          BVS       init_exit

; Claim EventV to trap keydown.  Pass workspace pointer in R12 (already in R2).

          MOV       R0,#&10 ; EventV
          ADR       R1,eventv
          SWI       "XOS_Claim"
          BVS       init_exit

; Switch on Keypress events.

          MOV       R0,#14
          MOV       R1,#11
          SWI       "XOS_Byte"

.init_exit
          LDMFD     R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

; Keys used in application filters

.key_delete
          EQUD      &18B

.key_end
          EQUD      &1AD

.key_home
          EQUD      &1AC

; Keys used in writable icons

.icon_delete
          EQUD      &8B

.icon_backspace
          EQUD      &7F

.icon_end
          EQUD      &AD

.icon_home
          EQUD      &AC

; ----------------------------------------------------------------------------------------------------------------------

.final_code
          STMFD     R13!,{R14}
          LDR       R12,[R12]

.final_kill_wimptask
          LDR       R0,[R12,#task_handle%]
          CMP       R0,#0
          BLE       final_freetasks

          LDR       R1,task
          SWI       "XWimp_CloseDown"
          MOV       R1,#0
          STR       R1,[R12,#task_handle%]

; Work through the task list, deregistering the filters and freeing the workspace.

.final_freetasks

          LDR       R5,[R12,#task_list%]
          MOV       R0,#7

.final_freetasks_loop
          TEQ       R5,#0
          BEQ       final_freeapps

          BL        remove_filter

          MOV       R2,R5
          LDR       R5,[R5,#task_block_next%]
          SWI       "XOS_Module"

          B         final_freetasks_loop

; Work through the apps list, freeing the workspace.

.final_freeapps

          LDR       R6,[R12,#app_list%]
          MOV       R0,#7

.final_freeapps_loop
          TEQ       R6,#0
          BEQ       final_remove_ticker

          MOV       R2,R6
          LDR       R6,[R6,#app_block_next%]
          SWI       "XOS_Module"

          B         final_freeapps_loop

; Remove desktop check code.

.final_remove_ticker
          ADR       R0,check_desktop_state
          MOV       R1,R12
          SWI       "XOS_RemoveTickerEvent"

; Turn off keypress events.

          MOV       R0,#13
          MOV       R1,#11
          SWI       "XOS_Byte"

; Release claim to InsV.

          MOV       R0,#&14 ; InsV
          ADR       R1,insv
          MOV       R2,R12
          SWI       "XOS_Release"

; Release claim to EventV.

          MOV       R0,#&10 ; EventV
          ADR       R1,eventv
          MOV       R2,R12
          SWI       "XOS_Release"

; Free the RMA workspace

.final_release_workspace
          TEQ       R12,#0
          BEQ       final_exit
          MOV       R0,#7
          MOV       R2,R12
          SWI       "XOS_Module"

.final_exit
          LDMFD     R13!,{PC}

; ======================================================================================================================

.check_desktop_state

; Check the state of the desktop and set the status flag appropriately.
;
; This code probably shouldn't be called under interrupt, but it worked OK in PCKeys1 (apparently) without problem
; and there isn't an obvious way to do it otherwise...

          STMFD     R13!,{R0-R12,R14}

          MOV       R0,#3
          SWI       "Wimp_ReadSysInfo"

          LDR       R1,[R12,#module_flags%]

          TEQ       R0,#1
          BICNE     R1,R1,#flag_wimp%
          ORREQ     R1,R1,#flag_wimp%

          STR       R1,[R12,#module_flags%]

          LDMFD     R13!,{R0-R12,PC}

; ======================================================================================================================

.eventv

; Check if the key down event ocurred and, if so, store the code away for future use by the InsV vector code.

          TEQ       R0,#11
          TEQEQ     R1,#1
          STREQ     R2,[R12,#last_key%]

          MOV       PC,R14

; ======================================================================================================================

.insv

; The InsV code is used to fiddle keypresses in writable icons.
;
; Before doing anything else, check that the buffer is the keyboard buffer and if it is stack some registers and
; continue.  If not, just exit.

          TEQ       R1,#0
          MOVNE     PC,R14

          STMFD     R13!,{R2,R14}

; Check that we aresupposed to be fiddling icon keypresses, that we are in a desktop context and that the caret is
; in a writable icon at the moment.  If all three are true, carry on to munge the keypress.

          LDR       R2,[R12,#module_flags%]
          AND       R2,R2,#(flag_icon% OR flag_wimp% OR flag_doicon%)
          TEQ       R2,#(flag_icon% OR flag_wimp% OR flag_doicon%)
          BNE       insv_exit

; Do the keypress substitution.  Test the code aginst Delete, Home, End and Backspace to see if it needs changing.

.insv_test_delete
          TEQ       R0,#&7F
          LDREQ     R0,[R12,#icon_delete%]
          BEQ       insv_exit

.insv_test_home
          TEQ       R0,#&1E
          LDREQ     R0,[R12,#icon_home%]
          BEQ       insv_exit

.insv_test_end
          TEQ       R0,#&8B
          LDREQ     R0,[R12,#icon_end%]
          BEQ       insv_exit

.insv_test_backspace
          TEQ       R0,#8
          BNE       insv_exit

; Backspace is a bit different, as ASCII 8 could also be Ctrl-H and we don't want to change that...  Before we do
; anything else, then, check the internal code of the last key to be pressed on a key-down event.  If it was
; backspace, we can do the substitution.

          LDR       R2,[R12,#last_key%]
          TEQ       R2,#&1E
          LDREQ     R0,[R12,#icon_backspace%]

.insv_exit
          LDMFD     R13!,{R2,PC}

; ======================================================================================================================

.service_code
          TEQ       R1,#&27
          TEQNE     R1,#&49
          TEQNE     R1,#&4A

          MOVNE     PC,R14

          STMFD     R13!,{R14}
          LDR       R12,[R12]

.service_reset
          TEQ       R1,#&27
          BNE       service_start_wimp

          MOV       R14,#0
          STR       R14,[R12,#task_handle%]
          LDMFD     R13!,{PC}

.service_start_wimp
          TEQ       R1,#46
          BNE       service_started_wimp

          LDR       R14,[R12,#task_handle%]
          TEQ       R14,#0
          MOVEQ     R14,#NOT-1
          STREQ     R14,[R12,#task_handle%]
          ADREQL    R0,command_desktop
          MOVEQ     R1,#0
          LDMFD     R13!,{PC}

.service_started_wimp
          LDR       R14,[R12,#task_handle%]
          CMN       R14,#1
          MOVEQ     R14,#0
          STREQ     R14,[R12,#task_handle%]
          LDMFD     R13!,{PC}

; ======================================================================================================================

.filter_code
          STMFD     R13!, {R0-R5,R14}

; Get the key-code from the poll block, then test it against Delete, End and Home keys to see if it needs changing.

          LDR       R0,[R1,#24]

.filter_test_delete
          TEQ       R0,#&7F
          BNE       filter_test_end

          LDR       R0,[R12,#key_delete%]
          STR       R0,[R1,#24]

          B         filter_exit

.filter_test_end
          MOV       R2,#&08B
          ORR       R2,R2,#&100
          TEQ       R0,R2
          BNE       filter_test_home

          LDR       R0,[R12,#key_end%]
          STR       R0,[R1,#24]

          B         filter_exit

.filter_test_home
          TEQ       R0,#&1E
          BNE       filter_exit

          LDR       R0,[R12,#key_home%]
          STR       R0,[R1,#24]

.filter_exit
          LDMFD     R13!,{R0-R5,R14}
          TEQ       PC,PC
          MOVNES    PC,R14
          MSR       CPSR_f,#0
          MOV       PC,R14

; ======================================================================================================================

.task
          EQUS      "TASK"

.wimp_version
          EQUD      310

.wimp_messages
.wimp_message_taskinit
          EQUD      &400C2    ; Message_TaskInitialise
.wimp_message_taskclosedown
          EQUD      &400C3    ; Message_TaskCloseDown
.wimp_message_quit
          EQUD      0         ; Message_Quit

.poll_mask
          EQUD      &3830

.task_name
          EQUZ      "PC Keyboard"

.misused_start_command
          EQUD      0
          EQUZ      "Use *Desktop to start PCKeys."
          ALIGN

; ======================================================================================================================

.task_code
          LDR       R12,[R12]
          ADRW      R13,workspace_size%+4         ; Set the stack up.

; Check that we aren't in the desktop.

          SWI       "XWimp_ReadSysInfo"
          TEQ       R0,#0
          ADREQ     R0,misused_start_command
          SWIEQ     "OS_GenerateError"

; Kill any previous version of our task which may be running.

          LDR       R0,[R12,#task_handle%]
          TEQ       R0,#0
          LDRGT     R1,task
          SWIGT     "XWimp_CloseDown"
          MOV       R0,#0
          STRGT     R0,[R12,#task_handle%]

; Set the Quit flag to zero

          STR       R0,[R12,#quit%]

; (Re) initialise the module as a Wimp task.

          LDR       R0,wimp_version
          LDR       R1,task
          ADR       R2,task_name
          ADR       R3,wimp_messages
          SWI       "XWimp_Initialise"
          SWIVS     "OS_Exit"
          STR       R1,[R12,#task_handle%]

; Set R1 up to be the block pointer.

          ADRW      R1,block%

; ----------------------------------------------------------------------------------------------------------------------

.poll_loop
          LDR       R0,poll_mask
          SWI       "Wimp_Poll"

; Check for and deal with Null polls.

.poll_event_null
          TEQ       R0,#0
          BNE       poll_event_wimp_message

          BL        check_caret_location
          B         poll_loop_end

; Check for and deal with user messages.

.poll_event_wimp_message
          TEQ       R0,#17
          TEQNE     R0,#18
          BNE       poll_loop_end

          LDR       R0,[R1,#16]

; Message_Quit

.poll_loop_message_quit
          TEQ       R0,#0
          BNE       poll_loop_message_taskinit
          MOV       R0,#1
          STR       R0,[R12,#quit%]
          B         poll_loop_end

; Message_TaskInit

.poll_loop_message_taskinit
          LDR       R2,wimp_message_taskinit
          TEQ       R0,R2
          BNE       poll_loop_message_taskclosedown

          ADD       R0,R1,#28
          BL        find_app_block

          TEQ       R6,#0
          BEQ       poll_loop_end

          LDR       R0,[R1,#4]
          BL        add_filter

          B         poll_loop_end

; Message_TaskCloseDown

.poll_loop_message_taskclosedown
          LDR       R2,wimp_message_taskclosedown
          TEQ       R0,R2
          BNE       poll_loop_end

          LDR       R0,[R1,#4]
          BL        find_task_block

          TEQ       R5,#0
          BLNE      remove_filter

.poll_loop_end
          LDR       R0,[R12,#quit%]
          TEQ       R0,#0
          BEQ       poll_loop

; ----------------------------------------------------------------------------------------------------------------------

.close_down
          LDR       R0,[R12,#task_handle%]
          LDR       R1,task
          SWI       "XWimp_CloseDown"

; Set the task handle to zero and die.

          MOV       R0,#0
          STR       R0,[R12,#task_handle%]

          SWI       "OS_Exit"

; ======================================================================================================================

.check_caret_location

; Check the position of the caret.  This is called on Null polls, and is used to set the icon flag if the caret is
; currently in a Wimp icon as opposed to being 'task controlled'.

          STMFD     R13!,{R0,R2,R14}

          SWI       "Wimp_GetCaretPosition"
          LDR       R2,[R1,#4]
          CMP       R2,#-1

          LDR       R0,[R12,#module_flags%]
          BICEQ     R0,R0,#flag_icon%
          ORRNE     R0,R0,#flag_icon%
          STR       R0,[R12,#module_flags%]

          LDMFD     R13!,{R0,R2,PC}

; ======================================================================================================================

.find_app_block

; Find the block containing details of the named application.
;
; R0  => App title
; R12 => Workspace
;
; R6  <= block (zero if not found)

          STMFD     R13!,{R0-R5,R14}

; Set R4 up ready for the compare subroutine.  R6 points to the first block of application data.

          MOV       R4,R0
          LDR       R6,[R12,#app_list%]

; If this is the end of the list (null pointer in R6), exit now.

.find_app_loop
          TEQ       R6,#0
          BEQ       find_app_exit

; Point R3 to the application name and compare with the name supplied.  If equal, exit now with R6 pointing to
; the data block.

          ADD       R3,R6,#app_block_name%
          BL        compare
          BEQ       find_app_exit

; Load the next block pointer into R6 and loop.

          LDR       R6,[R6,#app_block_next%]
          B         find_app_loop

.find_app_exit
          LDMFD     R13!,{R0-R5,PC}

; ----------------------------------------------------------------------------------------------------------------------

.find_task_block

; Find the block containing details of the specified task handle.
;
; R0  == Task handle
; R12 => Workspace
;
; R5  <= block (zero if not found)

          STMFD     R13!,{R0-R4,R14}

; R5 points to the first block of task data.

          LDR       R5,[R12,#task_list%]

; If this is the end of the list (null pointer in R6), exit now.

.findtask_loop
          TEQ       R5,#0
          BEQ       findtask_exit

; Test the handle with the one supplied.  If equal, exit now with R6 pointing to the data block.

          LDR       R1,[R5,#task_block_task_handle%]
          TEQ       R0,R1
          BEQ       findtask_exit

; Load the next block pointer into R6 and loop.

          LDR       R5,[R5,#task_block_next%]
          B         findtask_loop

.findtask_exit
          LDMFD     R13!,{R0-R4,PC}

; ======================================================================================================================

.add_filter

; Add a filter to the specified task, associating its details with the application block supplied.
;
; R0  == Task handle
; R6  => Application block
; R12 => Workspace

          STMFD     R13!,{R0-R6,R14}

; Register the filter, using the default values.

.addfilter_register
          MOV       R3,R0
          ADRL      R0,title_string
          ADR       R1,filter_code
          MOV       R2,R12
          LDR       R4,filter_poll_mask
          SWI       "XFilter_RegisterPostFilter"

          BVS       add_filter_exit                         ; Don't log the details if we failed to register.

          MOV       R4,R3                                   ; Keep R3 (task handle) safe from OS_Module 6

; Claim a block from the RMA to store the task details.

.addfilter_claim_block

          MOV       R0,#6
          MOV       R3,#task_block_size%
          SWI       "OS_Module"

; Initialise the details.

.addfilter_fill_block
          LDR       R0,magic_word                           ; Magic word to check block identity.
          STR       R0,[R2,#task_block_magic_word%]
          STR       R3,[R2,#task_block_dim%]                ; Block size.
          STR       R6,[R2,#task_block_app_ptr%]            ; Store a pointer to the parent application block.
          STR       R4,[R2,#task_block_task_handle%]        ; Store the task handle.

; Link the block into the task list.

.addfilter_link_in
          LDR       R5,[R12,#task_list%]
          STR       R5,[R2,#task_block_next%]
          STR       R2,[R12,#task_list%]

.add_filter_exit
          LDMFD     R13!,{R0-R6,PC}

; ----------------------------------------------------------------------------------------------------------------------

.remove_filter

; Remove the filter specidied in the given task block.
;
; R5  => Task block
; R12 => Workspace

          STMFD     R13!,{R0-R6,R14}

.removefilter_test
          LDR       R3,[R5,#task_block_task_handle%]
          TEQ       R3,#0
          BEQ       remove_filter_exit

.removefilter_deregister
          ADRL      R0,title_string
          ADR       R1,filter_code
          MOV       R2,R12
          LDR       R4,filter_poll_mask
          SWI       "XFilter_DeRegisterPostFilter"

; Find the task block in the linked list.

          ADRW      R0,task_list%

.removefilter_find_loop
          LDR       R1,[R0]

          TEQ       R1,R5
          BEQ       removefilter_found_item

          ADD       R0,R1,#task_block_next%
          B         removefilter_find_loop

.removefilter_found_item
          LDR       R1,[R5,#task_block_next%]
          STR       R1,[R0]

          MOV       R0,#7
          MOV       R2,R5
          SWI       "XOS_Module"

.remove_filter_exit
          LDMFD     R13!,{R0-R6,PC}

; ----------------------------------------------------------------------------------------------------------------------

.filter_poll_mask
          EQUD      &FFFFFFFF EOR (1<<8)

; ======================================================================================================================

.print_padded_string

; Print a string and pad it out with spaces to fill the column width.
;
; R0 => String to print
; R1 =  Column width

          STMFD     R13!,{R0-R2,R14}

          MOV       R2,R0

.printpadded_loop
          LDRB      R0,[R2],#1
          TEQ       R0,#0
          BEQ       printpadded_do_pad

          SWI       "OS_WriteC"
          SUBS      R1,R1,#1
          BEQ       printpadded_exit
          B         printpadded_loop

.printpadded_do_pad
          MOV       R0,#ASC(" ")

.printpadded_pad_loop
          SWI       "OS_WriteC"

          SUBS      R1,R1,#1
          BNE       printpadded_pad_loop

.printpadded_exit
          LDMFD     R13!,{R0-R2,PC}

; ======================================================================================================================

; Compare two control terminated strings, case insenitively.
;
; R3 => String 1
; R4 => String 2
;
; Returns Z flag (EQ/NE).

.compare
          STMFD     R13!,{R0-R4,R14}

          MVN       R0,#NOT-1
          SWI       "Territory_UpperCaseTable"

; Load two characters.

.compare_loop
          LDRB      R1,[R3],#1
          LDRB      R2,[R4],#1

; Convert both to upper case and ensure that ctrl-chars are converted to zero terminators.

          LDRB      R1,[R0,R1]
          LDRB      R2,[R0,R2]

          CMP       R1,#32
          MOVLT     R1,#0
          CMP       R2,#32
          MOVLT     R2,#0

; Perform the comparison and exit if different or the end of the string has been reached.  Return with result
; in Z flag.

          TEQ       R1,R2
          BNE       compare_exit
          TEQ       R2,#0
          BNE       compare_loop

.compare_exit
          LDMFD     R13!,{R0-R4,PC}

; ======================================================================================================================
]
IF debug% THEN
[OPT pass%
          FNReportGen
]
ENDIF
NEXT pass%

SYS "OS_File",10,"<Basic$Dir>."+save_as$,&FFA,,code%,code%+P%

PRINT "Module size: ";P%;" bytes."

END



DEF FNworkspace(RETURN size%,dim%)
LOCAL ptr%
ptr%=size%
size%+=dim%
=ptr%
