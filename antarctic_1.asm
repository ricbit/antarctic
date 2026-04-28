; Antarctic Adventure (MSX, Konami, 1983, first release)
; Disassembled by Ricardo Bittencourt (bluepenguin@gmail.com)
; Last update at 2026-04-27
;
	output "antarctic_1.rom"
	org 04000h

VRAM_SAT_BASE                    equ     03B00h    ; Sprite Attribute Table base in VRAM (32 entries x 4 bytes)
GAME_STATE                       equ     0E000h    ; 1 byte, Main game state machine index
GAME_SUBSTATE                    equ     0E001h    ; 1 byte, Substate index for current game state
INPUT_DEVICE_FLAGS               equ     0E002h    ; 1 byte, Bit 4=Keyboard/Joystick, Bit 6=Demo play
FRAME_COUNTER                    equ     0E003h    ; 1 byte, Global frame counter (increments every VBLANK)
WAIT_TIMER                       equ     0E004h    ; 1 byte, General purpose delay timer
VBLANK_BUSY_FLAG                 equ     0E005h    ; 1 byte, Non-zero if VBLANK handler is running
PREV_INPUT_KEYS                  equ     0E008h    ; 1 byte, Storage for previous frame input
CUR_INPUT_KEYS                   equ     0E009h    ; 1 byte, Storage for current frame input
TIME_UP_FLAG                     equ     0E00Ch    ; 2 bytes, Flag set when time runs out (checked in State 11)
STAGE_GOAL_FLAG                  equ     0E00Dh    ; 1 byte, Flag set when distance reaches zero
KONAMI_LOGO_ROW_PTR              equ     0E00Eh    ; 2 bytes, VRAM ptr to current logo row during opening animation
MUSIC_VARS_CH0                   equ     0E010h    ; 10 bytes, Sound channel 0 variables
MUSIC_VARS_CH1                   equ     0E01Ah    ; 10 bytes, Sound channel 1 variables
MUSIC_VARS_CH2                   equ     0E024h    ; 10 bytes, Sound channel 2 variables
MIRROR_VDP_REGISTERS             equ     0E038h    ; 8 bytes, Mirror of VDP registers in RAM (registers 0-7)
HI_SCORE_BCD                     equ     0E040h    ; 3 bytes, High Score (6 digits BCD); index with BCD_LOW / BCD_MID / BCD_HIGH
CURRENT_SCORE_BCD                equ     0E043h    ; 3 bytes, Current Score (6 digits BCD); index with BCD_LOW / BCD_MID / BCD_HIGH
SAT_MIRROR                       equ     0E050h    ; 128 bytes, RAM mirror of SAT (32 × 4); index with SPRITE_n + ATTR_*
PENGUIN_X_POS                    equ     0E079h    ; 1 byte, Penguin X; alias for SAT_MIRROR + SPRITE_PENGUIN + ATTR_X
VRAM_UPDATE_BUFFER               equ     0E0D0h    ; 1 byte, Buffer for VRAM update value
DEBUG_FLAGS                      equ     0E0D1h    ; 1 byte, write-only direction-flag sink during DRIFT; never read (debug relict)
STAGE_COMPLETION_FLAGS           equ     0E0D5h    ; 10 bytes, Completion flags for each stage
VRAM_FILL_VALUE                  equ     0E0DFh    ; 1 byte, Temporary storage for VRAM fill byte
CURRENT_VISIBLE_STAGE            equ     0E0E0h    ; 1 byte, Visible stage in BCD (01..09, 10, ...); HUD digit, BCD-inc'd at goal
CURRENT_STAGE_INDEX              equ     0E0E1h    ; 1 byte, Current stage number (0-9)
DISTANCE_EVENT_TICK              equ     0E0E2h    ; 1 byte, Nibble cursor into DISTANCE_EVENT_TABLE; ++ per milestone
REMANING_TIME_BCD                equ     0E0E3h    ; 2 bytes, Distance to finish (4 digits BCD)
REMANING_TIME_HIGH               equ     0E0E4h    ; High byte of remaining distance (BCD)
STAGE_DISTANCE_BCD               equ     0E0E5h    ; 2 bytes, Current stage or distance record (4 digits BCD)
STAGE_DISTANCE_HIGH              equ     0E0E6h    ; Temporary storage for high byte of stage distance
MAP_PROGRESS_LIMIT               equ     0E0E7h    ; 1 byte, Limit index for map path drawing (completed stages)
CURRENT_STAGE                    equ     0E0E8h    ; 1 byte, Index variable for difficulty/stage settings
DISTANCE_TICK_TIMER              equ     0E0E9h    ; 2 bytes, Timer for stage-distance decrement (counter +0, reload +1)
DEMO_PLAY_TIMING_COUNTER         equ     0E0EBh    ; 1 byte, Timer used for demo play data synchronization
INPUT_DEMO_PLAY_PTR              equ     0E0ECh    ; 2 bytes, Pointer to input buffer for demo play
STAGE_DEMO_PLAY_TIMER            equ     0E0EEh    ; 2 bytes, Timer for demo-play sequence
MAP_VRAM_ADDR                    equ     0E0F0h    ; 2 bytes, Current VRAM address for map drawing
MAP_DATA_PTR                     equ     0E0F2h    ; 2 bytes, Pointer to active map data stream
PATH_VRAM_PTR                    equ     0E0F4h    ; 2 bytes, VRAM target for the current path tile
MAP_STEP_INDEX                   equ     0E0F6h    ; 1 byte, Current step index in MAP_PATH_DATA
PENGUIN_ANIM_FRAME               equ     0E0F8h    ; 1 byte, Penguin animation frame index
PENGUIN_INPUT_LOCK_TIMER         equ     0E0F9h    ; 1 byte, non-zero during scripted anims (goal walk, stun, fall)
PENGUIN_MOVE_STATE               equ     0E0FAh    ; 1 byte, Penguin movement flags (0=Straight, 1=Left, 2=Right)
PENGUIN_JUMP_STATE               equ     0E0FBh    ; 1 byte, Jump direction/state (0=None, 1=Left, 2=Right)
PENGUIN_SIDE_FLAG                equ     0E0FCh    ; 1 byte, Screen side flag (0=Left, 1=Right)
SPEED_ACCEL_DELAY                equ     0E0FEh    ; 1 byte, delay counter for acceleration
PENGUIN_SPEED                    equ     0E100h    ; 2 bytes, Controls scroll speed (16-bit, lower = faster)
ACTIVE_ROAD_FRAME                equ     0E102h    ; 1 byte, 0-3 child-pattern index in active road segment (wraps mod 4)
ACTIVE_ROAD_PTR_RIGHT            equ     0E103h    ; 2 bytes, Active road segment, right-slot (bit 0=0); init ROAD_ICE_RIGHT_1
ACTIVE_ROAD_PTR_LEFT             equ     0E105h    ; 2 bytes, Active road segment, left-slot (bit 0=1); init ROAD_ICE_LEFT_1
STAGE_SEGMENT_TIMER              equ     0E107h    ; 1 byte, Countdown before road segment updates
STAGE_SEGMENT_INDEX              equ     0E108h    ; 1 byte, Index of the current segment within the stage entry
ROAD_SEGMENT_INDEX               equ     0E109h    ; 1 byte, Current road segment index (raw)
CURRENT_STAGE_DATA_PTR           equ     0E10Ah    ; 2 bytes, Pointer to the current 4-byte stage entry
SKY_COLOR                        equ     0E10Ch    ; 2 bytes, Color attribute for road/sky fill (packed pair)
ITEM_TICK_PERIOD                 equ     0E10Eh    ; 2 bytes (reload, countdown) — frames per item-stream advance; speed-tuned
STAGE_TIMER_VAL                  equ     0E110h    ; 1 byte, Initial stage timer value (default 10h)
ITEM_COMMAND_INDEX               equ     0E111h    ; 1 byte, Current step in the active item's animation/movement script
ITEM_TABLE                       equ     0E112h    ; 24 bytes, Table of items (flags/fish) state and type (4 slots x 6 bytes)
ITEM_TABLE_TYPE_BASE             equ     0E113h    ; 1 byte, Item type field for slot 0 (ITEM_TABLE + 1, inside ITEM_TABLE)
ITEM_DATA_LATCH                  equ     0E12Ah    ; 1 byte, Gate for item data updates
PENGUIN_ANIM_HOLD_FLAG           equ     0E130h    ; 1 byte, Non-zero pauses penguin walk animation updates
COLLISION_PROCESSED_FLAG         equ     0E132h    ; 1 byte, Flag to prevent multiple collision triggers for same item
TIMER_ACTIVE_FLAG                equ     0E133h    ; 1 byte, 1=Timer running, 0=Timer stopped
STUMBLE_PROCESSED_FLAG           equ     0E135h    ; 1 byte, One-shot guard against double stumble/collision triggers
STUMBLE_OBSTACLE_ADDR            equ     0E136h    ; 2 bytes, address of the obstacle being stumbled over
FISH_POS_GUARD_FLAG              equ     0E137h    ; 1 byte, Prevents repeated fish position init
VICTORY_WADDLE_STEP              equ     0E138h    ; 1 byte, Waddle step counter for victory animation
VICTORY_WADDLE_BASE_X            equ     0E139h    ; 1 byte, Base X position for victory waddle
VICTORY_DANCE_COUNTER            equ     0E13Ah    ; 1 byte, Victory dance frame/cycle counter
SELECT_CONTROLLER_DISABLED       equ     0E13Bh    ; 1 byte, 1=Disable input selection logic
PENGUIN_FALL_TIMER               equ     0E140h    ; 1 byte, Non-zero when penguin is falling
PENGUIN_FALL_ANIM_COUNTER        equ     0E141h    ; 1 byte, Fall animation frame counter (0-127, checked vs 32)
PENGUIN_STUN_TIMER               equ     0E142h    ; 1 byte, Non-zero when penguin is stunned
PENGUIN_EVENT_TIMER              equ     0E143h    ; 1 byte, Shared timer for goal bob/stun event gating
PENGUIN_STUN_PATTERN             equ     0E144h    ; 1 byte, Stun animation pattern/dir bits (bit2=direction)
DEMO_PLAY_MASK_RELOAD            equ     0E148h    ; 1 byte, Reload value for demo play mask timer
DEMO_PLAY_MASK_TIMER             equ     0E149h    ; 1 byte, Countdown for demo play mask refresh
DEMO_PLAY_MASK_FLAGS             equ     0E14Ah    ; 4 bytes, Active flags for demo play mask sprites
VRAM_STREAM_PTR                  equ     0E14Eh    ; 2 bytes, VRAM stream address for init writes
FLICKER_SPRITE_BUFFER            equ     0E150h    ; 32 bytes, Flicker history buffer (start)
FLICKER_BUFFER_LAST              equ     0E16Fh    ; Last byte of flicker buffer
VRAM_STREAM_STATUS               equ     0E170h    ; 1 byte, Init stream status flag (set to FFh)
HUD_SPEED_BAR_TILES              equ     0E171h    ; 6 bytes, Tile codes uploaded to name-table row 1 col 25 as HUD speed bar
ITEM_COLLISION_PTR               equ     0E181h    ; 2 bytes, Pointer to collided item entry
FISH_POS_STATE                   equ     0E183h    ; 1 byte, Fish position state/flags
FISH_POS_COUNTER                 equ     0E184h    ; 1 byte, Fish position counter
ITEM_IDLE_ANIM_COUNTER           equ     0E185h    ; 1 byte, Idle animation counter for items
CURRENT_ENTITY_POINTER           equ     0E188h    ; 2 bytes, Pointer to active entity struct
SEQUENCE_THRESHOLD               equ     0E18Ah    ; 1 byte, Threshold for sequence task
SEQUENCE_DATA_PTR                equ     0E18Bh    ; 2 bytes, Pointer to current sequence data stream
TITLE_BLINK_TIMER                equ     0E18Dh    ; 1 byte, Timer for title screen blinking elements
SEQUENCE_ACTIVE                  equ     0E18Eh    ; 1 byte, Sequence/animation active flag
SEQUENCE_TIMER                   equ     0E18Fh    ; 1 byte, Sequence/animation delay timer
ITEM_MOVE_OVERRIDE_FLAG          equ     0E190h    ; 1 byte, enables one-shot item movement override path
ITEM_MOVE_TOGGLE                 equ     0E191h    ; 1 byte, Item movement toggle (keyboard override)
FISH_POS_VRAM_SELECT             equ     0E192h    ; 1 byte, Selects fish position VRAM target
DISTANCE_EVENT_INDEX             equ     0E194h    ; 1 byte, milestone index (0-3) into DISTANCE_EVENT_STREAMS; +1 = secondary slot
PENGUIN_DRIFT_FLAG               equ     0E196h    ; 1 byte, Auto X-drift active; set by milestones, cleared near goal
MISC_TICK_PACER                  equ     0E197h    ; 1 byte, Free-running 16-frame pacer for UPDATE_MISC_TASKS
ITEM_PICKUP_TILE_BUFFER          equ     0E1A0h    ; 13 bytes, Scratch tile-stream buffer for HANDLE_COLLISION_FLAG's pickup anim
STACK                            equ     0E400h    ; Stack top marker (grows downward into E3xx; no fixed allocation size)
HKEYI                            equ     0FD9Ah    ; Interrupt handler

NOTE_C                           equ     00000h    ; Note index: C
NOTE_C_SHARP                     equ     00001h    ; Note index: C#
NOTE_D                           equ     00002h    ; Note index: D
NOTE_D_SHARP                     equ     00003h    ; Note index: D#
NOTE_E                           equ     00004h    ; Note index: E
NOTE_F                           equ     00005h    ; Note index: F
NOTE_F_SHARP                     equ     00006h    ; Note index: F#
NOTE_G                           equ     00007h    ; Note index: G
NOTE_G_SHARP                     equ     00008h    ; Note index: G#
NOTE_A                           equ     00009h    ; Note index: A
NOTE_A_SHARP                     equ     0000Ah    ; Note index: A#
NOTE_B                           equ     0000Bh    ; Note index: B
NOTE_HOLD                        equ     0000Ch    ; Note index: hold
DURATION_8                       equ     00000h    ; Duration index: 8
DURATION_16                      equ     00001h    ; Duration index: 16
DURATION_32                      equ     00002h    ; Duration index: 32
DURATION_48                      equ     00003h    ; Duration index: 48
DURATION_64                      equ     00004h    ; Duration index: 64
DURATION_96                      equ     00005h    ; Duration index: 96
DURATION_5                       equ     00006h    ; Duration index: 5
DURATION_10                      equ     00007h    ; Duration index: 10
DURATION_15                      equ     00008h    ; Duration index: 15
DURATION_20                      equ     00009h    ; Duration index: 20
DURATION_100                     equ     0000Ah    ; Duration index: 100
DURATION_30                      equ     0000Bh    ; Duration index: 30
DURATION_24                      equ     0000Ch    ; Duration index: 24
DURATION_60                      equ     0000Dh    ; Duration index: 60
DURATION_80                      equ     0000Eh    ; Duration index: 80
DURATION_40                      equ     0000Fh    ; Duration index: 40
COLOR_TRANSPARENT                equ     00000h    ; MSX1 palette 0: Transparent
COLOR_BLACK                      equ     00001h    ; MSX1 palette 1: Black
COLOR_MED_GREEN                  equ     00002h    ; MSX1 palette 2: Medium Green
COLOR_LIGHT_GREEN                equ     00003h    ; MSX1 palette 3: Light Green
COLOR_DARK_BLUE                  equ     00004h    ; MSX1 palette 4: Dark Blue
COLOR_LIGHT_BLUE                 equ     00005h    ; MSX1 palette 5: Light Blue
COLOR_DARK_RED                   equ     00006h    ; MSX1 palette 6: Dark Red
COLOR_CYAN                       equ     00007h    ; MSX1 palette 7: Cyan
COLOR_MED_RED                    equ     00008h    ; MSX1 palette 8: Medium Red
COLOR_LIGHT_RED                  equ     00009h    ; MSX1 palette 9: Light Red
COLOR_DARK_YELLOW                equ     0000Ah    ; MSX1 palette 10: Dark Yellow
COLOR_LIGHT_YELLOW               equ     0000Bh    ; MSX1 palette 11: Light Yellow
COLOR_DARK_GREEN                 equ     0000Ch    ; MSX1 palette 12: Dark Green
COLOR_MAGENTA                    equ     0000Dh    ; MSX1 palette 13: Magenta
COLOR_GRAY                       equ     0000Eh    ; MSX1 palette 14: Gray
COLOR_WHITE                      equ     0000Fh    ; MSX1 palette 15: White
CMD_SOUND_INTRO_MUSIC            equ     00092h    ; Sound command: demo BGM
CMD_SOUND_MAIN_THEME             equ     0008Ah    ; Sound command: main theme
CMD_SOUND_TIME_OUT               equ     0008Ch    ; Sound command: time out
CMD_SOUND_STAGE_CLEAR            equ     0008Fh    ; Sound command: stage clear
CMD_SOUND_STOP                   equ     00095h    ; Sound command: stop
ID_SOUND_GOAL_TICK               equ     00001h    ; Sound ID: goal tick
ID_SOUND_JUMP                    equ     00002h    ; Sound ID: jump
ID_SOUND_STUN_1                  equ     00003h    ; Sound ID: stun stage 1 (initial impact, plays first in stun cascade)
ID_SOUND_STUN_2                  equ     00004h    ; Sound ID: stun stage 2 (follow-up impact; plays twice in cascade)
ID_SOUND_FALL_HOLE               equ     00005h    ; Sound ID: fall in hole
ID_SOUND_CATCH_FLAG              equ     00006h    ; Sound ID: flag pickup (HANDLE_COLLISION_FLAG, +500 score)
ID_SOUND_CATCH_FISH              equ     00007h    ; Sound ID: fish catch (small-hole-with-fish path, +300 score)
ID_SOUND_SEAL_COLLISION          equ     00008h    ; Sound ID: seal collision (HANDLE_STUMBLE_LARGE; precedes the stun cascade)
ID_SOUND_DISTANCE_WARNING        equ     00009h    ; Sound ID: distance warning
MUSIC_DRIVER_TIMER               equ     00000h    ; Sound RAM offset: main timer
MUSIC_DRIVER_DURATION_BASE       equ     00001h    ; Sound RAM offset: duration base
MUSIC_DRIVER_CONTROL             equ     00002h    ; Sound RAM offset: control
MUSIC_DRIVER_STREAM_PTR_LO       equ     00003h    ; Sound RAM offset: stream ptr low
MUSIC_DRIVER_STREAM_PTR_HI       equ     00004h    ; Sound RAM offset: stream ptr high
MUSIC_DRIVER_OCTAVE              equ     00005h    ; Sound RAM offset: octave/pitch shift
MUSIC_DRIVER_SUSTAIN_BASE        equ     00006h    ; Sound RAM offset: sustain base
MUSIC_DRIVER_SUSTAIN_COUNTER     equ     00007h    ; Sound RAM offset: sustain counter
MUSIC_DRIVER_SUSTAIN_TIMER       equ     00008h    ; Sound RAM offset: sustain timer
MUSIC_DRIVER_REPEAT_COUNT        equ     00009h    ; Sound RAM offset: repeat count
KEY_NONE                         equ     00000h    ; Joypad/keyboard input: no key pressed
KEY_UP                           equ     00001h    ; Joypad/keyboard input: up
KEY_DOWN                         equ     00002h    ; Joypad/keyboard input: down
KEY_LEFT                         equ     00004h    ; Joypad/keyboard input: left
KEY_RIGHT                        equ     00008h    ; Joypad/keyboard input: right
KEY_SPACE                        equ     00010h    ; Joypad/keyboard input: trigger A / space
MAP_DIR_UP                       equ     00000h    ; MAP_PATH_DATA direction nibble: up (shifted; MOVEMENT_TABLE offset 0)
MAP_DIR_RIGHT                    equ     00040h    ; MAP_PATH_DATA direction nibble: right (shifted; MOVEMENT_TABLE offset 4)
MAP_DIR_DOWN                     equ     00080h    ; MAP_PATH_DATA direction nibble: down (shifted; MOVEMENT_TABLE offset 8)
MAP_DIR_LEFT                     equ     000C0h    ; MAP_PATH_DATA direction nibble: left (shifted; MOVEMENT_TABLE offset Ch)
BCD_LOW                          equ     00000h    ; Byte offset: low byte of a 3-byte BCD (e.g. HI_SCORE_BCD)
BCD_MID                          equ     00001h    ; Byte offset: middle byte of a 3-byte BCD integer
BCD_HIGH                         equ     00002h    ; Byte offset: high byte of a 3-byte BCD integer (most significant)
ATTR_Y                           equ     00000h    ; SAT attribute offset: Y (byte 0 of a 4-byte sprite entry)
ATTR_X                           equ     00001h    ; SAT attribute offset: X (byte 1)
ATTR_PATT                        equ     00002h    ; SAT attribute offset: pattern (byte 2)
ATTR_COLOR                       equ     00003h    ; SAT attribute offset: color (byte 3)
SPRITE_4                         equ     00010h    ; SAT_MIRROR byte offset for sprite 4
SPRITE_5                         equ     00014h    ; SAT_MIRROR byte offset for sprite 5
SPRITE_6                         equ     00018h    ; SAT_MIRROR byte offset for sprite 6
SPRITE_21                        equ     00054h    ; SAT_MIRROR byte offset for sprite 21
SPRITE_PENGUIN                   equ     00028h    ; Anchor for 4-sprite penguin body (sprite 10); +4/+8/+0Ch for 3 corners
SPRITE_ITEM                      equ     0003Ch    ; Dynamic item sprite: fish flying, etc. (sprite 15)
SPRITE_SHADOW                    equ     00050h    ; Penguin shadow sprite (sprite 20)
SPRITE_CLOUD                     equ     00068h    ; Anchor for 4 cloud sprites (sprite 26); use +4/+8/+0Ch for the others
SPRITE_AUX                       equ     0001Ch    ; Auxiliary buffer anchor (sprite 7, mirrors 7-9; goal/fall reuse)
SPRITE_OBSTACLE                  equ     00040h    ; Obstacle anim buffer anchor (sprite 16, mirrors 16-19; +0/+1 type/params)
VDP_98                           equ     00098h    ; MSX I/O port 98h: VDP Data Port
VDP_99                           equ     00099h    ; MSX I/O port 99h: VDP Register/Address Port
PSG_ADDR                         equ     000A0h    ; MSX I/O port A0h: PSG Address select
PSG_WRDATA                       equ     000A1h    ; MSX I/O port A1h: PSG Data write
PSG_RDDATA                       equ     000A2h    ; MSX I/O port A2h: PSG Data read
PPI_A9                           equ     000A9h    ; MSX I/O port A9h: PPI Port A (keyboard inputs)
PPI_AA                           equ     000AAh    ; MSX I/O port AAh: PPI Port C (keyboard row selection)
VRAM_SIZE                        equ     04000h    ; Total VRAM size (16 KB)
VDP_TEMP_AREA                    equ     0E00Ah    ; 1 byte at E00Ah, title-window animation counter (TITLE_WINDOW_ANIMATION)
SKY_DAY_BLUE                     equ     00000h    ; STAGE_VISUAL_THEME index: day theme (cyan sky, default tiles)
SKY_NIGHT_RED                    equ     00001h    ; STAGE_VISUAL_THEME index: night theme (red sky, GFX_STAGE_NIGHT_TILES)
ID_STATE_7                       equ     00007h    ; GAME_STATE 7: Prepare demo play
ID_STATE_8                       equ     00008h    ; GAME_STATE 8: Demo play mode
ID_STATE_9                       equ     00009h    ; GAME_STATE 9: Stage setup and HUD refresh
ID_STATE_12                      equ     0000Ch    ; GAME_STATE 12: Time out sequence
ID_STATE_14                      equ     0000Eh    ; GAME_STATE 14: Goal reached sequence
ID_SUBSTATE_1                    equ     00001h    ; Generic substate 1 (used in LOAD_SUBSTATE packed 16-bit init)
ID_SUBSTATE_2                    equ     00002h    ; Generic substate 2

; VDP MEMORY MAP (Set during initialization at 44BF-44D5):
; Register #0 (02h): Mode Register 0
; Register #1 (E2h): Mode Register 1 (16K VRAM, Display ON, INT enabled, Sprites 16x16)
; Register #2 (0Eh): Name Table Base Address = 3800h (0Eh * 400h)
; Register #3 (7Fh): Color Table Base Address = 0000h (bit 7 * 2000h, Graphics Mode)
; Register #4 (07h): Pattern Generator Base Address = 2000h (bit 2 * 2000h, Graphics Mode)
; Register #5 (76h): Sprite Attribute Table Base Address = 3B00h (76h * 80h)
; Register #6 (03h): Sprite Pattern Generator Base Address = 1800h (03h * 800h)
; Register #7 (E1h): Backdrop Color = 1 (Black), Text Color = 14 (Gray)
;
; Note: These base addresses are never changed during gameplay.
;
; SOUND CHANNEL RAM TABLES (0Ah bytes each, used by PLAY_SOUND/PROCESS_SOUND):
; Base addresses: CH0 = E010h, CH1 = E01Ah, CH2 = E024h.
; Offsets within each 0Ah-byte block:
; +00 TIMER           Main duration timer for current note/tone (decrements each tick).
; +01 DURATION_BASE   Base duration value (from duration table or 0x2n command).
; +02 CONTROL         Sound ID/priority, bit 7 = music stream mode.
; +03 STREAM_PTR_LO   Current sound stream pointer (low).
; +04 STREAM_PTR_HI   Current sound stream pointer (high).
; +05 OCTAVE          Octave/pitch shift (0-7) from 0FDh parameter.
; +06 SUSTAIN_BASE    Sustain/gate base value from 0FDh parameter.
; +07 SUSTAIN_COUNTER Current gate counter (reloaded from SUSTAIN_BASE, 0 = silence).
; +08 SUSTAIN_TIMER   Secondary timer used for gate/volume updates.
; +09 REPEAT_COUNT    Repeat/loop counter for 0FEh command.
;

; Macro to load a register pair with VRAM address in VDP format
; Usage: LOAD_VRAM_WRITE de, 1234h
; Result: high byte | 0x40 (write bit), low byte
        macro LOAD_VRAM_WRITE reg, addr
                ld      reg, ((addr >> 8) | 0x40) << 8 | (addr & 0xFF)
        endm

; Macro to load a register pair with a raw VRAM address (no VDP write bit).
; Use for VRAM addresses that the callee will later combine with the write
; bit itself (e.g. FILL_VRAM / COPY_RAM_TO_VRAM do `set 6,d` before SET_VDP).
; Usage: LOAD_VRAM_ADDRESS de, 1080h
        macro LOAD_VRAM_ADDRESS reg, addr
                ld      reg, addr
        endm

; Macro to load a register pair with packed (state, substate) for the
; (GAME_STATE), hl write at SET_GAME_STATE_HL: low byte = state, high
; byte = substate. Usage: LOAD_SUBSTATE hl, ID_STATE_7, ID_SUBSTATE_1
        macro LOAD_SUBSTATE reg, state_id, substate_id
                ld      reg, ((substate_id) << 8) | (state_id)
        endm

; Macro to load a register pair with a Name Table coordinate
; Usage: LOAD_NAME_TABLE de, y, x
        macro LOAD_NAME_TABLE reg, y, x
                ld      reg, 3800h + y * 32 + x
        endm

; Macro to load a VRAM color byte (high nibble=foreground, low nibble=background)
; Usage: LOAD_VRAM_COLOR a, COLOR_WHITE, COLOR_BLACK
        macro LOAD_VRAM_COLOR reg, foreground, background
                ld      reg, ((foreground & 0x0F) << 4) | (background & 0x0F)
        endm

; Macro to load a register pair with a sprite attribute VRAM address
; Usage: LOAD_SPRITE_ATTR de, sprite, offset
; Result: reg = 03B00h + sprite * 4 + offset
        macro LOAD_SPRITE_ATTR reg, sprite, offset
                ld      reg, 03B00h + sprite * 4 + offset
        endm

; Macro to define a stage distance/time entry (distance bytes stored little-endian)
; Usage: STAGE_ENTRY 1200h, 0, 90h
        macro STAGE_ENTRY dist, map_offset, time
                db      (dist >> 8)
                db      map_offset
                dw      time
        endm

; Macro to define one stage's 4 road-segment indices
; Usage: STAGE_SEGMENTS seg0, seg1, seg2, seg3
        macro STAGE_SEGMENTS seg0, seg1, seg2, seg3
                db      seg0, seg1, seg2, seg3
        endm

; Macro to define a map draw commands block
; Usage: MAP_COMMANDS size, commands, terminator
        macro MAP_COMMANDS size, commands, terminator
                db size
                dh commands
                db terminator
        endm

; Macro to fill a VRAM region with a value
; Usage: VRAM_FILL value, count, vram_address
        macro VRAM_FILL value, count, addr
                db      value, count
                dw      addr | 4000h
        endm

; Macro to emit a VRAM address word with the write bit set
; Usage: VDP_ADDRESS 1234h
        macro VDP_ADDRESS addr
                dw      addr | 4000h
        endm

; Macro to emit a Name Table VRAM address from row/column coordinates
; Usage: VRAM_NAME_TABLE y, x
        macro VRAM_NAME_TABLE y, x
                dw      3800h + y * 32 + x
        endm

; Macro to emit a WRITE_VRAM_TILES_STREAM header byte
; Usage: VRAM_TILE_HEADER 3900h, 8
; base: 3800h/3900h/3A00h/3B00h
; row: 1-32 (macro stores row-1; routine adds +20h = +1 row on first ctrl byte)
        macro VRAM_TILE_HEADER base, row
                db      ((((row - 1) & 7) << 5) & 0F0h) | ((((base) >> 8) - 38h) & 3)
        endm

; Macro to emit a WRITE_VRAM_TILES_STREAM control byte
; Usage: VRAM_TILE_COLUMN 0Fh
; col: 0-31 column offset within the current 32-byte row
        macro VRAM_TILE_COLUMN col
                db      0E0h + (col & 1Fh)
        endm

; Macro to emit WRITE_VRAM_TILES_STREAM tile-data bytes as a hex string
; Usage: VRAM_TILES "7780"
        macro VRAM_TILES bytes
                dh      bytes
        endm

; Macro to emit one SEQUENCE_TIMER_TABLE entry (a single 1-byte timer seed,
; loaded into SEQUENCE_TIMER when START_SEQUENCE_CHECK kicks off a sequence).
; Usage: TIMER_VALUE 7
        macro TIMER_VALUE value
                db      value
        endm

; Macro to emit the lead byte of a FORMAT_VRAM_FILL_STREAM (the tile value
; that will be painted across every run in the stream).
; Usage: ROAD_FILL_VALUE 0Fh
        macro ROAD_FILL_VALUE value
                db      value
        endm

; Macro to emit one [count, addr_lo] pair of a FORMAT_VRAM_FILL_STREAM.
; Paints count tiles starting at VRAM 39xx:addr_lo, with the page-high byte
; auto-incrementing when addr_lo < 20h. In practice each pair paints one
; horizontal strip of the road's perspective mask.
; Usage: ROAD_FILL_RUN 15, 51h
        macro ROAD_FILL_RUN count, addr_lo
                db      count, addr_lo
        endm

; Macro to emit the FEh control byte that starts a new block within a
; FORMAT_VRAM_STREAM (a new VRAM target address follows).
        macro STREAM_NEXT_BLOCK
                db      0FEh
        endm

; Macro to emit the FFh control byte that terminates a FORMAT_VRAM_STREAM.
        macro STREAM_BLOCK_END
                db      0FFh
        endm

; Macro to emit a STATION_FRAME stream's first byte: base VRAM page and row.
; UPDATE_STATION_FRAME reads bits 4-7 as (row-1)*20h (row seed for first ctrl)
; and bits 0-1 as (page_high - 38h) — so 3800h..3B00h selects the VRAM page.
; Usage: STATION_FRAME_HEADER 3800h, 7
        macro STATION_FRAME_HEADER base, row
                db      ((((row - 1) & 7) << 5) & 0F0h) | ((((base) >> 8) - 38h) & 3)
        endm

; Macro to emit a STATION_FRAME inner header byte (E0h..FFh): selects the
; starting column of the next row written into VRAM.
; Usage: STATION_FRAME_INNER_HEADER 0Fh    ; column 15
        macro STATION_FRAME_INNER_HEADER col
                db      0E0h | (col & 1Fh)
        endm

; Macro to set music octave/gate parameters in sound streams (0FDh prefix)
        macro SET_OCTAVE_SUSTAIN pitch, sustain
                db      0FDh, ((sustain << 3) | (pitch & 7))
        endm

; Macro to emit a music note (duration in high nibble, note in low nibble)
        macro NOTE note, duration
                db      ((duration & 0Fh) << 4) | (note & 0Fh)
        endm

; Macro to set SFX duration base (0x20-0x2F)
; Usage: SET_DURATION 1 -> db 21h
        macro SET_DURATION duration
                db      (0x20 | (duration & 0x0F))
        endm

; Macro to emit SFX volume + period pair
; Usage: SOUND vol, period
; Result: db ((vol << 4) | period_hi), period_lo
        macro SOUND vol, period
                db      ((vol & 0x0F) << 4) | ((period >> 8) & 0x0F), (period & 0xFF)
        endm

; Macro to emit one hardware-sprite attribute entry (4 bytes: Y, X, pattern,
; color). Consumed by FORMAT_SPRITE_ATTR tables; Y=E0h hides the sprite,
; coordinates are screen-relative.
; Usage: SPRITE_ATTR 7Fh, 70h, 0F0h, COLOR_DARK_YELLOW
        macro SPRITE_ATTR y, x, pattern, color
                db      y, x, pattern, color
        endm

; Macro to emit one entry of a FORMAT_SPRITE_ATTR_STREAM (5 bytes: RepeatCount,
; Y, X, pattern, color). Batches consecutive sprites that share attributes;
; RepeatCount = 0 terminates the stream.
; Usage: SPRITE_ATTR_REPT 4, 4Fh, 80h, 7Ch, COLOR_TRANSPARENT
        macro SPRITE_ATTR_REPT repeat, y, x, pattern, color
                db      repeat, y, x, pattern, color
        endm

; Macro to emit one FORMAT_ITEM_PROPERTIES entry in ITEM_PROPERTIES_TABLE
; (6 bytes: animation ptr word + 4 collision bytes). The 4 bytes are
; consumed by COLLISION_CHECK_LOOP as two (low_x, width) X-range pairs;
; the exact role of each pair depends on the item class (see INTERNALS.md):
;   - Small hole (ANIM_SMALL_HOLE_*): x1=1 (skip-X sentinel) routes to
;     the stun-only path; (w1, x2) then act as stun (low_x, width),
;     w2 unused.
;   - Big hole   (ANIM_BIG_HOLE_*):   (x1, w1) = fall zone,
;                                     (x2, w2) = stun zone.
;   - Flag       (ANIM_FLAG_*):       (x1, w1) = pickup zone,
;                                     (x2, w2) unused.
; Usage: ITEM_PROP ANIM_BIG_HOLE_LEFT, 2Bh, 5Bh, 10h, 90h
        macro ITEM_PROP anim_ptr, x1, w1, x2, w2
                dw      anim_ptr
                db      x1, w1, x2, w2
        endm

; Macro to emit one FORMAT_PENGUIN_PATTERN entry: four sprite pattern indices
; in [Top-Left, Bottom-Left, Top-Right, Bottom-Right] order, used by
; PENGUIN_ANIM_TABLE for the main penguin animations.
; Usage: PENGUIN_PATTERN 0, 4, 8, 0Ch
        macro PENGUIN_PATTERN p0, p1, p2, p3
                db      p0, p1, p2, p3
        endm

; Macro to emit one FORMAT_ITEM_ANIM_SPRITES entry (3 bytes: Y, X, pattern —
; no color byte). Frames are concatenated; callers pick 2-sprite (6B) or
; 4-sprite (12B) frames depending on the animation.
; Usage: SPRITE_ANIM_FRAME 67h, 78h, 7Ch
        macro SPRITE_ANIM_FRAME y, x, pattern
                db      y, x, pattern
        endm

; Macros for FORMAT_ROAD_SEGMENT_INIT entries. Each road-segment-init block
; is 17 bytes = 1-byte header (E1xx target offset) + two 8-byte rows of
; lane/color values. Usage:
;   ROAD_SEGMENT_HEADER 60h
;   ROAD_SEGMENT_ROW 0, 0, 0, 0F3h,
;   ROAD_SEGMENT_ROW 0F6h, 0F4h, 0F3h, 0F7h
        macro ROAD_SEGMENT_HEADER base_offset
                db      base_offset
        endm

        macro ROAD_SEGMENT_ROW v0, v1, v2, v3
                db      v0, v1, v2, v3
        endm

; Macro to emit the 2-byte color trailer of a FORMAT_FLAG_DATA block: the
; foreground colors for the flag's sprites 4 and 5, placed immediately after
; the 00h terminator of the bit-packed flag pattern stream.
; Usage: FLAG_COLORS COLOR_DARK_RED, COLOR_WHITE
        macro FLAG_COLORS spr4, spr5
                db      spr4, spr5
        endm

; Macro to emit one LOCKED_COLLISION_TABLE entry (2 bytes: low_x, width)
; defining an X-range used by CHECK_COLLISIONS_WHILE_LOCKED — the collision
; check that runs during input-locked animation states (stun/fall/goal walk).
; Usage: LOCKED_COLLISION 58h, 30h
        macro LOCKED_COLLISION low_x, width
                db      low_x, width
        endm

; Macro to emit one FORMAT_SEQUENCE_THRESHOLDS pair (2 bytes: low_threshold,
; high_threshold) for one time digit of SEQUENCE_TIME_THRESHOLDS
; (10 pairs total, digits 0-9).
; Usage: THRESHOLD 80h, 0
        macro THRESHOLD low, high
                db      low, high
        endm

; Macro to emit one DISTANCE_EVENT_TABLE byte (two 4-bit event nibbles).
; Each nibble is read by CHECK_DISTANCE_MILESTONE and decoded as:
;   bits 0-1: base sign index (0..2; 3 = skip).
;   bit 2: enables the secondary-slot flag (writes 2 to DISTANCE_EVENT_INDEX+1).
;   bit 3: forces bit 1 of the base index (so 0->2 selects WATER_CURVE_LEFT;
;          combined with 1 -> 3 = skip, so values 9h and Fh both skip).
; Usage: DISTANCE_EVENT 0Fh, 8h  ; first nibble skip, second = lane 0 (right)
        macro DISTANCE_EVENT high, low
                db      ((high & 0Fh) << 4) | (low & 0Fh)
        endm

; Macro to emit one CLOUD_ANIMATION_OFFSETS entry: a signed Y delta applied
; to the cloud sprite each animation tick.
        macro CLOUD_OFFSET dy
                db      dy
        endm

; Macro to emit one PENGUIN_STUN_Y_OFFSETS entry: a signed Y delta applied
; to the penguin sprite each frame during the stun/stumble animation
; (HANDLE_PENGUIN_STUN_ANIMATION reads one byte per tick).
; Usage: STUN_Y_OFFSET -3
        macro STUN_Y_OFFSET dy
                db      dy
        endm

; Macro to emit one PENGUIN_JUMP_Y_OFFSETS entry: a signed Y delta applied
; to the penguin sprite each frame of the jump arc (12 frames total,
; indexed by the jump timer via ADD_HL_A).
; Usage: JUMP_Y_OFFSET -4
        macro JUMP_Y_OFFSET dy
                db      dy
        endm

; Macro to emit one GOAL_PENGUIN_BOB_Y entry: a signed Y delta applied to
; the penguin sprite each frame of the goal-sequence bobbing animation
; (indexed by PENGUIN_INPUT_LOCK_TIMER via ADD_HL_A).
; Usage: BOB_Y_OFFSET 1
        macro BOB_Y_OFFSET dy
                db      dy
        endm

; Macro to emit one (Y, X) sprite coordinate pair (e.g. DEMO_PLAY_MASK_COORDS_DATA).
; Both bytes are stored signed in the asm so negative values render as -N.
        macro SPRITE_YX y, x
                db      y, x
        endm

; Macro to emit one INPUT_DEMO_PLAY_DATA sample byte (joypad/key bitmask).
; Pass an OR of KEY_* constants, or KEY_NONE for an empty sample.
; Usage: INPUT_DEMO_PLAY KEY_UP | KEY_LEFT
        macro INPUT_DEMO_PLAY keys
                db      keys
        endm

; Macro to emit one MAP_PATH_DATA step byte: a MAP_DIR_* constant (already
; shifted into the high nibble) OR'd with a 4-bit tile index in the low
; nibble. MAP_UPDATE_PATH reads one step per odd frame — high nibble picks
; the VRAM movement, low nibble picks the tile drawn there.
; Usage: MAP_STEP MAP_DIR_RIGHT, 2
        macro MAP_STEP direction, tile
                db      direction | (tile & 0Fh)
        endm

; Macro to emit the 20h sentinel that ends a MAP_PATH_DATA stream.
        macro MAP_END
                db      20h
        endm

; Macro to emit a SEQ_STREAM_* command selecting entry n (0..Fh) from
; ITEM_PROPERTIES_TABLE. Dispatcher: PROCESS_ITEM_SEQUENCE routes the byte
; through CHECK_SEQUENCE_STATUS and uses the value as an item-properties
; index for the current sequence slot.
; Usage: SEQ_ITEM_PROP 5
        macro SEQ_ITEM_PROP n
                db      (n) & 0Fh
        endm

; Macro to emit a SEQ_STREAM_* command setting the movement state to n
; (0..3). Encoded as 10h | (n & 3); the dispatcher sets
; ITEM_MOVE_OVERRIDE_FLAG and writes the state into ITEM_TABLE+1.
; Usage: SEQ_MOVE_STATE 2
        macro SEQ_MOVE_STATE n
                db      10h | ((n) & 3)
        endm

; Macro to emit the 0FFh sentinel that ends a sequence step (routes to
; STORE_ITEM_STATE / idle in PROCESS_ITEM_SEQUENCE).
        macro SEQ_IDLE
                db      0FFh
        endm


MSX_ROM_MAGIC:
        ; MSX ROM Header (16 bytes; "AB" magic + entry/extension addresses)
        db      "AB" ; magic                                   ;#4000: 41 42
        dw      GAME_BOOT ; starting address                   ;#4002: 10 40
        dw      0 ; CALL statement handler                     ;#4004: 00 00
        dw      0 ; device handler                             ;#4006: 00 00
        dw      0 ; BASIC program                              ;#4008: 00 00
        dw      0 ; reserved                                   ;#400A: 00 00
        dw      0 ; reserved                                   ;#400C: 00 00
        dw      0 ; reserved                                   ;#400E: 00 00

GAME_BOOT:
        ; Entry point for MSX ROM startup
        di                                                     ;#4010: F3
        im      1                                              ;#4011: ED 56
        ld      a,0C3h                                         ;#4013: 3E C3
        ld      (HKEYI),a                                      ;#4015: 32 9A FD
        ld      hl,INTERRUPT_HANDLER                           ;#4018: 21 44 40
        ld      (HKEYI+1),hl                                   ;#401B: 22 9B FD
        ld      sp,STACK                                       ;#401E: 31 00 E4
        ld      hl,GAME_STATE                                  ;#4021: 21 00 E0
        ld      de,GAME_STATE+1                                ;#4024: 11 01 E0
        ld      bc,7FFh                                        ;#4027: 01 FF 07
        ld      (hl),0                                         ;#402A: 36 00
        ldir                                                   ;#402C: ED B0
        ld      a,1                                            ;#402E: 3E 01
        ld      (VBLANK_BUSY_FLAG),a                           ;#4030: 32 05 E0
        call    INIT_HARDWARE                                  ;#4033: CD 82 44
        di                                                     ;#4036: F3
        xor     a                                              ;#4037: AF
        ld      (VBLANK_BUSY_FLAG),a                           ;#4038: 32 05 E0
        inc     a                                              ;#403B: 3C
        ld      (GAME_STATE),a                                 ;#403C: 32 00 E0
        in      a,(VDP_99)                                     ;#403F: DB 99
        ei                                                     ;#4041: FB
WAIT_FOR_INTERRUPT:
        ; Idle loop waiting for interrupt
        jr      WAIT_FOR_INTERRUPT                             ;#4042: 18 FE

INTERRUPT_HANDLER:
        ; Core interupt and timing handler
        push    af                                             ;#4044: F5
        push    bc                                             ;#4045: C5
        push    de                                             ;#4046: D5
        push    hl                                             ;#4047: E5
        di                                                     ;#4048: F3
        in      a,(VDP_99)                                     ;#4049: DB 99
        ld      a,(GAME_STATE)                                 ;#404B: 3A 00 E0
        or      a                                              ;#404E: B7
        jr      z,MAIN_LOOP_ENTRY                              ;#404F: 28 03
        call    PROCESS_SOUND                                  ;#4051: CD D7 79
MAIN_LOOP_ENTRY:
        ; Main loop wait/dispatch entry
        ld      a,(GAME_STATE)                                 ;#4054: 3A 00 E0
        cp      ID_STATE_12                                    ;#4057: FE 0C
        jr      nc,SET_VBLANK_BUSY                             ;#4059: 30 1C
        ld      a,(PENGUIN_FALL_TIMER)                         ;#405B: 3A 40 E1
        ld      hl,PENGUIN_STUN_TIMER                          ;#405E: 21 42 E1
        add     a,(hl)                                         ;#4061: 86
        jr      nz,CHECK_TIMER_UPDATE                          ;#4062: 20 03
        call    UPDATE_PENGUIN_ANIMATION                       ;#4064: CD 94 4C
CHECK_TIMER_UPDATE:
        ; Checks if half-second timer needs updating
        call    UPDATE_GAME_TIMER                              ;#4067: CD 5A 46
        ld      a,(SAT_MIRROR + SPRITE_PENGUIN + 8 + ATTR_X)   ;#406A: 3A 81 E0
        bit     7,a                                            ;#406D: CB 7F
        ld      a,0                                            ;#406F: 3E 00
        jr      z,UPDATE_SIDE_FLAG                             ;#4071: 28 01
        inc     a                                              ;#4073: 3C
UPDATE_SIDE_FLAG:
        ; Updates the penguin's screen side flag
        ld      (PENGUIN_SIDE_FLAG),a                          ;#4074: 32 FC E0
SET_VBLANK_BUSY:
        ; Sets the VBLANK busy flag
        ld      hl,VBLANK_BUSY_FLAG                            ;#4077: 21 05 E0
        bit     0,(hl)                                         ;#407A: CB 46
        jr      nz,EARLY_RETURN                                ;#407C: 20 14
        ld      (hl),1                                         ;#407E: 36 01
        ei                                                     ;#4080: FB
        call    READ_INPUT                                     ;#4081: CD A2 40
        call    STATE_MACHINE                                  ;#4084: CD 0C 41
        di                                                     ;#4087: F3
        pop     hl                                             ;#4088: E1
        pop     de                                             ;#4089: D1
        pop     bc                                             ;#408A: C1
        xor     a                                              ;#408B: AF
        ld      (VBLANK_BUSY_FLAG),a                           ;#408C: 32 05 E0
        pop     af                                             ;#408F: F1
        ei                                                     ;#4090: FB
        ret                                                    ;#4091: C9

EARLY_RETURN:
        ; Returns from interrupt or process
        pop     hl                                             ;#4092: E1
        pop     de                                             ;#4093: D1
        pop     bc                                             ;#4094: C1
        pop     af                                             ;#4095: F1
        ei                                                     ;#4096: FB
        ret                                                    ;#4097: C9

JUMP_TABLE_DISPATCHER:
        ; Dispatcher for inline jump tables (index in A)
        add     a,a                                            ;#4098: 87
        pop     hl                                             ;#4099: E1
        call    ADD_HL_A                                       ;#409A: CD D1 48
        ld      e,(hl)                                         ;#409D: 5E
        inc     hl                                             ;#409E: 23
        ld      d,(hl)                                         ;#409F: 56
        ex      de,hl                                          ;#40A0: EB
        jp      (hl)                                           ;#40A1: E9

READ_INPUT:
        ; Poll Joystick (PSG) or Keyboard (PPI)
        ld      a,(GAME_STATE)                                 ;#40A2: 3A 00 E0
        cp      7                                              ;#40A5: FE 07
        ret     c                                              ;#40A7: D8
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#40A8: 3A 02 E0
        bit     6,a                                            ;#40AB: CB 77
        jr      z,LOAD_DEMO_PLAY_DATA                          ;#40AD: 28 41
        bit     4,a                                            ;#40AF: CB 67
        jr      nz,READ_KEYBOARD_AS_JOYSTICK                   ;#40B1: 20 11
        ld      a,0Eh                                          ;#40B3: 3E 0E
        out     (PSG_ADDR),a                                   ;#40B5: D3 A0
        in      a,(PSG_RDDATA)                                 ;#40B7: DB A2
        cpl                                                    ;#40B9: 2F
        and     3Fh                                            ;#40BA: E6 3F
STORE_INPUT_AND_RET:
        ; Stores input and returns
        ld      hl,CUR_INPUT_KEYS                              ;#40BC: 21 09 E0
        ld      c,(hl)                                         ;#40BF: 4E
        ld      (hl),a                                         ;#40C0: 77
        dec     hl                                             ;#40C1: 2B
        ld      (hl),c                                         ;#40C2: 71
        ret                                                    ;#40C3: C9

READ_KEYBOARD_AS_JOYSTICK:
        ; Reads cursor keys and space, emulating joystick
        ld      bc,57AAh ; c = PPI_AA                          ;#40C4: 01 AA 57
        out     (c),b                                          ;#40C7: ED 41
        out     (c),b                                          ;#40C9: ED 41
        in      a,(PPI_A9)                                     ;#40CB: DB A9
        cpl                                                    ;#40CD: 2F
        rrca                                                   ;#40CE: 0F
        and     20h                                            ;#40CF: E6 20
        ld      e,a                                            ;#40D1: 5F
        inc     b                                              ;#40D2: 04
        out     (c),b                                          ;#40D3: ED 41
        out     (c),b                                          ;#40D5: ED 41
        in      a,(PPI_A9)                                     ;#40D7: DB A9
        cpl                                                    ;#40D9: 2F
        rrca                                                   ;#40DA: 0F
        rrca                                                   ;#40DB: 0F
        ld      b,a                                            ;#40DC: 47
        and     4                                              ;#40DD: E6 04
        or      e                                              ;#40DF: B3
        ld      c,a                                            ;#40E0: 4F
        ld      a,b                                            ;#40E1: 78
        rrca                                                   ;#40E2: 0F
        rrca                                                   ;#40E3: 0F
        ld      b,a                                            ;#40E4: 47
        and     18h                                            ;#40E5: E6 18
        or      c                                              ;#40E7: B1
        ld      c,a                                            ;#40E8: 4F
        ld      a,b                                            ;#40E9: 78
        rrca                                                   ;#40EA: 0F
        and     3                                              ;#40EB: E6 03
        or      c                                              ;#40ED: B1
        jr      STORE_INPUT_AND_RET                            ;#40EE: 18 CC

LOAD_DEMO_PLAY_DATA:
        ; Read an input from the demo play data
        ld      de,(INPUT_DEMO_PLAY_PTR)                       ;#40F0: ED 5B EC E0
        ld      hl,DEMO_PLAY_TIMING_COUNTER                    ;#40F4: 21 EB E0
        inc     (hl)                                           ;#40F7: 34
        ld      a,(hl)                                         ;#40F8: 7E
        and     1Fh                                            ;#40F9: E6 1F
        jr      nz,RETURN_CURRENT_INPUT                        ;#40FB: 20 08
        ld      a,(de)                                         ;#40FD: 1A
        inc     de                                             ;#40FE: 13
        ld      (INPUT_DEMO_PLAY_PTR),de                       ;#40FF: ED 53 EC E0
        jr      STORE_INPUT_AND_RET                            ;#4103: 18 B7

RETURN_CURRENT_INPUT:
        ; Input routine exit path returning current keys
        ld      a,(CUR_INPUT_KEYS)                             ;#4105: 3A 09 E0
        and     0Fh                                            ;#4108: E6 0F
        jr      STORE_INPUT_AND_RET                            ;#410A: 18 B0

STATE_MACHINE:
        ; Main game state machine loop and frame counter update
        ld      hl,FRAME_COUNTER                               ;#410C: 21 03 E0
        inc     (hl)                                           ;#410F: 34
        call    POLL_CONTROLLER_SELECT                         ;#4110: CD 18 44
        ld      a,(GAME_STATE)                                 ;#4113: 3A 00 E0
        call    JUMP_TABLE_DISPATCHER                          ;#4116: CD 98 40
        dw      DUMMY_RET                                      ;#4119: 39 41
        dw      GAME_STATE_1_HANDLER                           ;#411B: 3A 41
        dw      GAME_STATE_2_HANDLER                           ;#411D: 4B 41
        dw      GAME_STATE_3_HANDLER                           ;#411F: 5D 41
        dw      GAME_STATE_4_HANDLER                           ;#4121: 68 41
        dw      GAME_STATE_5_HANDLER                           ;#4123: 76 41
        dw      GAME_STATE_6_HANDLER                           ;#4125: 7E 41
        dw      GAME_STATE_7_HANDLER                           ;#4127: 85 41
        dw      GAME_STATE_8_HANDLER                           ;#4129: D4 41
        dw      GAME_STATE_9_HANDLER                           ;#412B: 40 42
        dw      GAME_STATE_10_HANDLER                          ;#412D: 82 42
        dw      GAME_STATE_11_HANDLER                          ;#412F: 9B 42
        dw      GAME_STATE_12_HANDLER                          ;#4131: C1 42
        dw      GAME_STATE_13_HANDLER                          ;#4133: E6 42
        dw      GAME_STATE_14_HANDLER                          ;#4135: F7 42
        dw      GAME_STATE_15_HANDLER                          ;#4137: DB 48

DUMMY_RET:
        ; Simple RET instruction
        ret                                                    ;#4139: C9

GAME_STATE_1_HANDLER:
        ; Game state 1: Init VRAM
        call    INIT_ALL_VDP_PLANES                            ;#413A: CD 23 58
        LOAD_VRAM_COLOR a, COLOR_BLACK, COLOR_BLACK            ;#413D: 3E 11
        ld      (VDP_TEMP_AREA),a                              ;#413F: 32 0A E0
        ld      hl,0                                           ;#4142: 21 00 00
        ld      (KONAMI_LOGO_ROW_PTR),hl                       ;#4145: 22 0E E0
        jp      INCREMENT_STATE                                ;#4148: C3 F3 43

GAME_STATE_2_HANDLER:
        ; Game state 2: Konami opening scroll
        ld      a,(FRAME_COUNTER)                              ;#414B: 3A 03 E0
        rra                                                    ;#414E: 1F
        ret     nc                                             ;#414F: D0
        call    KONAMI_OPENING_ANIMATION                       ;#4150: CD 79 48
        ret     nz                                             ;#4153: C0
        ld      hl,MSG_VIDEO_CARTRIDGE                         ;#4154: 21 CD 57
        call    WRITE_VRAM_STREAM                              ;#4157: CD 90 45
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#415A: C3 EE 43

GAME_STATE_3_HANDLER:
        ; Game state 3: Pause between openings
        ld      hl,WAIT_TIMER                                  ;#415D: 21 04 E0
        dec     (hl)                                           ;#4160: 35
        ret     nz                                             ;#4161: C0
        call    INIT_TITLE_BACKGROUND                          ;#4162: CD 2C 48
        jp      INCREMENT_STATE_WITH_GIVEN_DELAY               ;#4165: C3 F0 43

GAME_STATE_4_HANDLER:
        ; Game state 4: Reveal game logo
        call    TITLE_WINDOW_ANIMATION                         ;#4168: CD 47 48
        ret     c                                              ;#416B: D8
        ld      hl,MSG_PLAY_SELECT                             ;#416C: 21 82 57
        call    WRITE_VRAM_STREAM                              ;#416F: CD 90 45
        xor     a                                              ;#4172: AF
        jp      INCREMENT_STATE_WITH_GIVEN_DELAY               ;#4173: C3 F0 43

GAME_STATE_5_HANDLER:
        ; Game state 5: Post-logo delay
        ld      hl,WAIT_TIMER                                  ;#4176: 21 04 E0
        dec     (hl)                                           ;#4179: 35
        ret     nz                                             ;#417A: C0
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#417B: C3 EE 43

GAME_STATE_6_HANDLER:
        ; Game state 6: Clear sprites and wait for VRAM update
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#417E: CD B3 45
        ret     p                                              ;#4181: F0
        jp      INCREMENT_STATE                                ;#4182: C3 F3 43

GAME_STATE_7_HANDLER:
        ; Game state 7: Prepare demo play
        ld      a,(GAME_SUBSTATE)                              ;#4185: 3A 01 E0
        call    JUMP_TABLE_DISPATCHER                          ;#4188: CD 98 40
        dw      INIT_DEMO_PLAY                                 ;#418B: 91 41
        dw      PREPARE_DEMO_PLAY                              ;#418D: A8 41
        dw      FINISH_DEMO_PLAY                               ;#418F: C9 41

INIT_DEMO_PLAY:
        ; Sets up input flags and pointers for demo-play startup
        call    INIT_RAM_AND_VRAM                              ;#4191: CD 4B 44
        ld      hl,INPUT_DEVICE_FLAGS                          ;#4194: 21 02 E0
        res     6,(hl)                                         ;#4197: CB B6
        ; 73Ch (1852) ticks at 60 Hz ≈ 30.9 s — demo-play replay length.
        ld      hl,73Ch                                        ;#4199: 21 3C 07
        ld      (STAGE_DEMO_PLAY_TIMER),hl                     ;#419C: 22 EE E0
        ld      hl,INPUT_DEMO_PLAY_DATA                        ;#419F: 21 E3 57
        ld      (INPUT_DEMO_PLAY_PTR),hl                       ;#41A2: 22 EC E0
        jp      GAME_STATE_9_HANDLER                           ;#41A5: C3 40 42

PREPARE_DEMO_PLAY:
        ; Draws first section of penguin during demo-play sequence
        ld      hl,KONAMI_COPYRIGHT_TEXT+2                     ;#41A8: 21 76 57
        LOAD_NAME_TABLE de, 6, 11                              ;#41AB: 11 CB 38
        call    WRITE_VRAM_STREAM_WITH_OFFSET                  ;#41AE: CD 94 45
        ld      a,1                                            ;#41B1: 3E 01
        ld      (TIMER_ACTIVE_FLAG),a                          ;#41B3: 32 33 E1
        call    MAIN_GAME_ENGINE                               ;#41B6: CD 1B 4B
        ld      hl,(STAGE_DEMO_PLAY_TIMER)                     ;#41B9: 2A EE E0
        dec     hl                                             ;#41BC: 2B
        ld      (STAGE_DEMO_PLAY_TIMER),hl                     ;#41BD: 22 EE E0
        ld      a,h                                            ;#41C0: 7C
        or      l                                              ;#41C1: B5
        ret     nz                                             ;#41C2: C0
        ld      (TIMER_ACTIVE_FLAG),a                          ;#41C3: 32 33 E1
        jp      INCREMENT_SUBSTATE_WITH_FIXED_DELAY            ;#41C6: C3 FC 43

FINISH_DEMO_PLAY:
        ; Clears sprites and transitions to next game state
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#41C9: CD B3 45
        ret     p                                              ;#41CC: F0
        xor     a                                              ;#41CD: AF
        ld      (GAME_STATE),a                                 ;#41CE: 32 00 E0
        jp      INCREMENT_STATE                                ;#41D1: C3 F3 43

GAME_STATE_8_HANDLER:
        ; Game state 8: Demo play mode
        ld      a,(GAME_SUBSTATE)                              ;#41D4: 3A 01 E0
        call    JUMP_TABLE_DISPATCHER                          ;#41D7: CD 98 40
        dw      AUTO_DEMO_PLAY_RESTART                         ;#41DA: E2 41
        dw      TITLE_MENU_INIT                                ;#41DC: F3 41
        dw      TITLE_MENU_BLINK_UPDATE                        ;#41DE: 06 42
        dw      START_GAME_PREP                                ;#41E0: 36 42

AUTO_DEMO_PLAY_RESTART:
        ; Sets up demo mode and restarts game intro sequence
        call    CLEAR_SPRITES                                  ;#41E2: CD E8 45
        call    CLEAR_NAME_TABLE                               ;#41E5: CD 9E 44
        call    INIT_TITLE_BACKGROUND                          ;#41E8: CD 2C 48
        ld      a,CMD_SOUND_INTRO_MUSIC                        ;#41EB: 3E 92
        call    PLAY_SOUND_SAFE                                ;#41ED: CD 70 79
        jp      INCREMENT_SUBSTATE                             ;#41F0: C3 01 44

TITLE_MENU_INIT:
        ; Initializes blink timer for the "PLAY SELECT" menu
        call    TITLE_WINDOW_ANIMATION                         ;#41F3: CD 47 48
        jr      c,TITLE_MENU_INIT                              ;#41F6: 38 FB
        ld      hl,MSG_PLAY_SELECT                             ;#41F8: 21 82 57
        call    WRITE_VRAM_STREAM                              ;#41FB: CD 90 45
        ld      a,6                                            ;#41FE: 3E 06
        ld      (TITLE_BLINK_TIMER),a                          ;#4200: 32 8D E1
        jp      INCREMENT_SUBSTATE                             ;#4203: C3 01 44

TITLE_MENU_BLINK_UPDATE:
        ; Oscillates the "PLAY SELECT" message visibility
        ld      hl,FRAME_COUNTER                               ;#4206: 21 03 E0
        ld      a,(hl)                                         ;#4209: 7E
        and     7                                              ;#420A: E6 07
        ret     nz                                             ;#420C: C0
        ld      a,(hl)                                         ;#420D: 7E
        bit     3,a                                            ;#420E: CB 5F
        jr      nz,DRAW_PLAY_SELECT                            ;#4210: 20 16
        LOAD_NAME_TABLE de, 16, 0                              ;#4212: 11 00 3A
        ld      bc,20h                                         ;#4215: 01 20 00
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4218: 3A 02 E0
        and     10h                                            ;#421B: E6 10
        rlca                                                   ;#421D: 07
        rlca                                                   ;#421E: 07
        call    ADD_DE_A                                       ;#421F: CD D6 48
        ld      a,1                                            ;#4222: 3E 01
        call    FILL_VRAM                                      ;#4224: CD F1 44
        ret                                                    ;#4227: C9

DRAW_PLAY_SELECT:
        ; Routine to draw the "PLAY SELECT" text
        ld      hl,MSG_PLAY_SELECT                             ;#4228: 21 82 57
        call    WRITE_VRAM_STREAM                              ;#422B: CD 90 45
        ld      hl,TITLE_BLINK_TIMER                           ;#422E: 21 8D E1
        dec     (hl)                                           ;#4231: 35
        ret     nz                                             ;#4232: C0
        jp      INCREMENT_SUBSTATE_WITH_FIXED_DELAY            ;#4233: C3 FC 43

START_GAME_PREP:
        ; Prepare VRAM/RAM and transition to next game state
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#4236: CD B3 45
        ret     p                                              ;#4239: F0
        call    INIT_RAM_AND_VRAM                              ;#423A: CD 4B 44
        jp      INCREMENT_STATE                                ;#423D: C3 F3 43

GAME_STATE_9_HANDLER:
        ; Game state 9: Stage setup and HUD refresh
        ld      a,(CURRENT_STAGE)                              ;#4240: 3A E8 E0
        ld      hl,STAGE_DISTANCE_TABLE                        ;#4243: 21 AA 4A
        add     a,a                                            ;#4246: 87
        add     a,a                                            ;#4247: 87
        call    ADD_HL_A                                       ;#4248: CD D1 48
        ld      e,(hl)                                         ;#424B: 5E
        inc     hl                                             ;#424C: 23
        ld      d,(hl)                                         ;#424D: 56
        inc     hl                                             ;#424E: 23
        ld      (STAGE_DISTANCE_HIGH),de                       ;#424F: ED 53 E6 E0
        ld      e,(hl)                                         ;#4253: 5E
        inc     hl                                             ;#4254: 23
        ld      d,(hl)                                         ;#4255: 56
        ld      a,(CURRENT_STAGE_INDEX)                        ;#4256: 3A E1 E0
        ld      hl,STAGE_COMPLETION_FLAGS                      ;#4259: 21 D5 E0
        call    ADD_HL_A                                       ;#425C: CD D1 48
        ld      a,(hl)                                         ;#425F: 7E
        sub     10h                                            ;#4260: D6 10
        jr      c,SET_REMAINING_DISTANCE                       ;#4262: 38 0C
        daa                                                    ;#4264: 27
        ld      c,a                                            ;#4265: 4F
        ld      a,e                                            ;#4266: 7B
        sub     c                                              ;#4267: 91
        jr      nc,BCD_SUB_CARRY                               ;#4268: 30 04
        daa                                                    ;#426A: 27
        dec     d                                              ;#426B: 15
        jr      FINALIZE_DISTANCE_CALC                         ;#426C: 18 01

BCD_SUB_CARRY:
        ; Handle BCD subtraction carry
        daa                                                    ;#426E: 27
FINALIZE_DISTANCE_CALC:
        ; Finalize BCD distance calculation
        ld      e,a                                            ;#426F: 5F
SET_REMAINING_DISTANCE:
        ; Sets the remaining stage distance in BCD
        ld      (REMANING_TIME_BCD),de                         ;#4270: ED 53 E3 E0
        call    REFRESH_HUD                                    ;#4274: CD A3 46
        call    INIT_ALL_VDP_PLANES                            ;#4277: CD 23 58
        ld      a,ID_STATE_14                                  ;#427A: 3E 0E
        ld      (GAME_STATE),a                                 ;#427C: 32 00 E0
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#427F: C3 EE 43

GAME_STATE_10_HANDLER:
        ; Game state 10: Gameplay init
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#4282: CD B3 45
        ret     p                                              ;#4285: F0
        call    INIT_GAMEPLAY_VARS                             ;#4286: CD D2 4A
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4289: 3A 02 E0
        bit     6,a                                            ;#428C: CB 77
        ld      a,CMD_SOUND_MAIN_THEME                         ;#428E: 3E 8A
        call    nz,PLAY_SOUND_SAFE                             ;#4290: C4 70 79
        ld      a,1                                            ;#4293: 3E 01
        ld      (TIMER_ACTIVE_FLAG),a                          ;#4295: 32 33 E1
        jp      INCREMENT_STATE                                ;#4298: C3 F3 43

GAME_STATE_11_HANDLER:
        ; Game state 11: Main gameplay loop
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#429B: 3A 02 E0
        bit     6,a                                            ;#429E: CB 77
        jr      z,SET_STATE_INTRO                              ;#42A0: 28 1A
        call    MAIN_GAME_ENGINE                               ;#42A2: CD 1B 4B
        ld      hl,(TIME_UP_FLAG)                              ;#42A5: 2A 0C E0
        ld      a,l                                            ;#42A8: 7D
        add     a,h                                            ;#42A9: 84
        ret     z                                              ;#42AA: C8
        ld      a,l                                            ;#42AB: 7D
        ld      hl,TIMER_ACTIVE_FLAG                           ;#42AC: 21 33 E1
        ld      (hl),0                                         ;#42AF: 36 00
        or      a                                              ;#42B1: B7
        ld      a,ID_STATE_12                                  ;#42B2: 3E 0C
        jr      nz,SET_STATE                                   ;#42B4: 20 02
        ld      a,ID_STATE_14                                  ;#42B6: 3E 0E
SET_STATE:
        ; Store A into GAME_STATE (caller sets A to ID_STATE_12 or ID_STATE_14)
        ld      (GAME_STATE),a                                 ;#42B8: 32 00 E0
        ret                                                    ;#42BB: C9

SET_STATE_INTRO:
        ; Sets game state to Stage Intro (7.1)
        LOAD_SUBSTATE hl, ID_STATE_7, ID_SUBSTATE_1            ;#42BC: 21 07 01
        jr      SET_GAME_STATE_HL                              ;#42BF: 18 32

GAME_STATE_12_HANDLER:
        ; Game state 12: Time out sequence
        xor     a                                              ;#42C1: AF
        ld      (TIME_UP_FLAG),a                               ;#42C2: 32 0C E0
        ld      hl,SAT_MIRROR + SPRITE_CLOUD + ATTR_Y          ;#42C5: 21 B8 E0
        ld      de,4                                           ;#42C8: 11 04 00
        ld      b,4                                            ;#42CB: 06 04
CLEAR_CLOUD_SPRITES_Y:
        ; Clear cloud sprite Y positions (hide off-screen)
        ld      (hl),0E0h                                      ;#42CD: 36 E0
        add     hl,de                                          ;#42CF: 19
        djnz    CLEAR_CLOUD_SPRITES_Y                          ;#42D0: 10 FB
        call    SYNC_SPRITE_ATTRIBUTES_ALL                     ;#42D2: CD 8C 66
        ; At this point a=0
        ld      (DISTANCE_EVENT_TICK),a                        ;#42D5: 32 E2 E0
        ld      a,CMD_SOUND_TIME_OUT                           ;#42D8: 3E 8C
        call    PLAY_SOUND_SAFE                                ;#42DA: CD 70 79
        ld      hl,MSG_TIME_OUT                                ;#42DD: 21 C2 57
        call    WRITE_VRAM_STREAM                              ;#42E0: CD 90 45
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#42E3: C3 EE 43

GAME_STATE_13_HANDLER:
        ; Game state 13: Wait for time-out sound
        ld      a,(MUSIC_VARS_CH0+MUSIC_DRIVER_CONTROL)        ;#42E6: 3A 12 E0
        or      a                                              ;#42E9: B7
        ret     nz                                             ;#42EA: C0
        ld      hl,INPUT_DEVICE_FLAGS                          ;#42EB: 21 02 E0
        res     6,(hl)                                         ;#42EE: CB B6
        LOAD_SUBSTATE hl, ID_STATE_7, ID_SUBSTATE_2            ;#42F0: 21 07 02
SET_GAME_STATE_HL:
        ; Sets main Game State and Substate from HL
        ld      (GAME_STATE),hl                                ;#42F3: 22 00 E0
        ret                                                    ;#42F6: C9

GAME_STATE_14_HANDLER:
        ; Game state 14: Goal reached sequence
        ld      a,(GAME_SUBSTATE)                              ;#42F7: 3A 01 E0
        call    JUMP_TABLE_DISPATCHER                          ;#42FA: CD 98 40
        dw      GOAL_PENGUIN_WALK                              ;#42FD: 0D 43
        dw      GOAL_PROCESS_SCORE                             ;#42FF: 20 43
        dw      GOAL_WAIT_SOUND_1                              ;#4301: 60 43
        dw      GOAL_PENGUIN_DANCE                             ;#4303: 6E 43
        dw      GOAL_WAIT_UNTIL_MUTE                           ;#4305: 8B 43
        dw      GOAL_WAIT_SOUND_2                              ;#4307: B5 43
        dw      GOAL_TALLY_TIMER_BONUS                         ;#4309: BE 43
        dw      GOAL_CLEANUP_AND_EXIT                          ;#430B: E5 43

GOAL_PENGUIN_WALK:
        ; Penguin walking towards the flag
        ld      hl,PENGUIN_INPUT_LOCK_TIMER                    ;#430D: 21 F9 E0
        ld      a,(hl)                                         ;#4310: 7E
        or      a                                              ;#4311: B7
        jp      z,INCREMENT_SUBSTATE                           ;#4312: CA 01 44
        call    UPDATE_THROTTLED_ANIMATION                     ;#4315: CD E9 4B
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4318: 3A F9 E0
        or      a                                              ;#431B: B7
        ret     nz                                             ;#431C: C0
        jp      INCREMENT_SUBSTATE                             ;#431D: C3 01 44

GOAL_PROCESS_SCORE:
        ; Preliminary score calculation/resetting
        ld      hl,CURRENT_VISIBLE_STAGE                       ;#4320: 21 E0 E0
        ld      a,(hl)                                         ;#4323: 7E
        add     a,1                                            ;#4324: C6 01
        daa                                                    ;#4326: 27
        ld      (hl),a                                         ;#4327: 77
        inc     hl                                             ;#4328: 23
        ; Now hl points to CURRENT_STAGE_INDEX
        ld      a,(hl)                                         ;#4329: 7E
        ld      c,a                                            ;#432A: 4F
        inc     a                                              ;#432B: 3C
        cp      0Ah                                            ;#432C: FE 0A
        jr      c,GOAL_SKIP_TEXT_INIT                          ;#432E: 38 04
        xor     a                                              ;#4330: AF
        ld      (DISTANCE_EVENT_TICK),a                        ;#4331: 32 E2 E0
GOAL_SKIP_TEXT_INIT:
        ; Skip time-bonus text initialization
        ld      (hl),a                                         ;#4334: 77
        ld      a,c                                            ;#4335: 79
        ld      hl,STAGE_COMPLETION_FLAGS                      ;#4336: 21 D5 E0
        call    ADD_HL_A                                       ;#4339: CD D1 48
        ld      a,(REMANING_TIME_BCD)                          ;#433C: 3A E3 E0
        ld      (hl),a                                         ;#433F: 77
        xor     a                                              ;#4340: AF
        ld      (STAGE_GOAL_FLAG),a                            ;#4341: 32 0D E0
        ld      hl,CURRENT_STAGE                               ;#4344: 21 E8 E0
        inc     (hl)                                           ;#4347: 34
        ld      a,(hl)                                         ;#4348: 7E
        cp      0Ah                                            ;#4349: FE 0A
        jr      nz,GOAL_INIT_VICTORY_PENGUIN                   ;#434B: 20 02
        ld      (hl),0                                         ;#434D: 36 00
GOAL_INIT_VICTORY_PENGUIN:
        ; Initialize penguin position/speed for victory
        ld      a,(PENGUIN_X_POS)                              ;#434F: 3A 79 E0
        ld      h,a                                            ;#4352: 67
        ld      l,1                                            ;#4353: 2E 01
        ld      (VICTORY_WADDLE_STEP),hl                       ;#4355: 22 38 E1
        ld      a,13h                                          ;#4358: 3E 13
        ld      (PENGUIN_SPEED),a                              ;#435A: 32 00 E1
        jp      INCREMENT_SUBSTATE                             ;#435D: C3 01 44

GOAL_WAIT_SOUND_1:
        ; Wait for initial victory sound to finish
        ld      c,0FFh                                         ;#4360: 0E FF
        call    UPDATE_VICTORY_PENGUIN_ANIM                    ;#4362: CD 85 54
        ret     nz                                             ;#4365: C0
        ld      a,0Ch                                          ;#4366: 3E 0C
        ld      (VICTORY_WADDLE_STEP),a                        ;#4368: 32 38 E1
        jp      INCREMENT_SUBSTATE                             ;#436B: C3 01 44

GOAL_PENGUIN_DANCE:
        ; Victory dance animation
        ld      c,0                                            ;#436E: 0E 00
        ld      a,(PENGUIN_X_POS)                              ;#4370: 3A 79 E0
        ld      h,a                                            ;#4373: 67
        call    UPDATE_VICTORY_PENGUIN_ANIM                    ;#4374: CD 85 54
        ret     nz                                             ;#4377: C0
        call    INIT_GOAL_SPRITES                              ;#4378: CD 70 66
        call    CYCLE_GOAL_PENGUIN_PATTERNS                    ;#437B: CD C7 54
        call    INIT_GOAL_GRAPHICS                             ;#437E: CD 2B 55
        ld      a,CMD_SOUND_STAGE_CLEAR                        ;#4381: 3E 8F
        call    PLAY_SOUND_SAFE                                ;#4383: CD 70 79
        ld      a,4                                            ;#4386: 3E 04
        ld      (GAME_SUBSTATE),a                              ;#4388: 32 01 E0
GOAL_WAIT_UNTIL_MUTE:
        ; Wait for MUSIC_VARS_CH1 to silence, then update goal flag position
        ld      a,(MUSIC_VARS_CH1)                             ;#438B: 3A 1A E0
        dec     a                                              ;#438E: 3D
        ret     nz                                             ;#438F: C0
        call    UPDATE_GOAL_FLAG_POSITION                      ;#4390: CD 6A 55
        ld      a,(CURRENT_STAGE_INDEX)                        ;#4393: 3A E1 E0
        or      a                                              ;#4396: B7
        jr      z,CHECK_VICTORY_DANCE_START                    ;#4397: 28 04
        cp      5                                              ;#4399: FE 05
        jr      nz,CONTINUE_GOAL_ANIMATION                     ;#439B: 20 0D
CHECK_VICTORY_DANCE_START:
        ; Check if victory dance should begin
        ld      a,(VICTORY_DANCE_COUNTER)                      ;#439D: 3A 3A E1
        cp      0Fh                                            ;#43A0: FE 0F
        jr      nz,CONTINUE_GOAL_ANIMATION                     ;#43A2: 20 06
        call    LOAD_VICTORY_GFX                               ;#43A4: CD DD 54
        jp      INCREMENT_SUBSTATE                             ;#43A7: C3 01 44

CONTINUE_GOAL_ANIMATION:
        ; Continue updating goal animation (victory dance)
        call    UPDATE_VICTORY_DANCE                           ;#43AA: CD CB 54
        ld      a,(VICTORY_DANCE_COUNTER)                      ;#43AD: 3A 3A E1
        cp      10h                                            ;#43B0: FE 10
        ret     nz                                             ;#43B2: C0
        jr      INCREMENT_SUBSTATE                             ;#43B3: 18 4C

GOAL_WAIT_SOUND_2:
        ; Wait for secondary victory sound
        ld      a,(MUSIC_VARS_CH0+MUSIC_DRIVER_CONTROL)        ;#43B5: 3A 12 E0
        or      a                                              ;#43B8: B7
        ret     nz                                             ;#43B9: C0
        ld      a,10h                                          ;#43BA: 3E 10
        jr      INCREMENT_SUBSTATE_WITH_GIVEN_DELAY            ;#43BC: 18 40

GOAL_TALLY_TIMER_BONUS:
        ; Countdown loop to convert remaining time to score
        ld      hl,WAIT_TIMER                                  ;#43BE: 21 04 E0
        ld      a,(hl)                                         ;#43C1: 7E
        or      a                                              ;#43C2: B7
        jr      z,PROCESS_SCORE_TALLY                          ;#43C3: 28 02
        dec     (hl)                                           ;#43C5: 35
        ret                                                    ;#43C6: C9

PROCESS_SCORE_TALLY:
        ; Handle score addition and sound effect
        ld      a,(FRAME_COUNTER)                              ;#43C7: 3A 03 E0
        and     3                                              ;#43CA: E6 03
        ret     nz                                             ;#43CC: C0
        ld      hl,(REMANING_TIME_BCD)                         ;#43CD: 2A E3 E0
        ld      a,h                                            ;#43D0: 7C
        add     a,l                                            ;#43D1: 85
        jr      z,INCREMENT_SUBSTATE_WITH_FIXED_DELAY          ;#43D2: 28 28
        ld      c,0                                            ;#43D4: 0E 00
        call    DECREMENT_DISTANCE                             ;#43D6: CD 73 46
        ld      de,100h                                        ;#43D9: 11 00 01
        call    ADD_SCORE                                      ;#43DC: CD 16 46
        ld      a,ID_SOUND_GOAL_TICK                           ;#43DF: 3E 01
        call    PLAY_SOUND_SAFE                                ;#43E1: CD 70 79
        ret                                                    ;#43E4: C9

GOAL_CLEANUP_AND_EXIT:
        ; Final cleanup before transitioning out of State 14
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#43E5: CD B3 45
        ret     p                                              ;#43E8: F0
        ld      a,ID_STATE_8                                   ;#43E9: 3E 08
        ld      (GAME_STATE),a                                 ;#43EB: 32 00 E0
INCREMENT_STATE_WITH_FIXED_DELAY:
        ; Transition to game after controller selection
        ld      a,50h                                          ;#43EE: 3E 50
INCREMENT_STATE_WITH_GIVEN_DELAY:
        ; Increments game state with delay in A
        ld      (WAIT_TIMER),a                                 ;#43F0: 32 04 E0
INCREMENT_STATE:
        ; Increments game state
        ld      hl,GAME_STATE                                  ;#43F3: 21 00 E0
        inc     (hl)                                           ;#43F6: 34
        xor     a                                              ;#43F7: AF
        ld      (GAME_SUBSTATE),a                              ;#43F8: 32 01 E0
        ret                                                    ;#43FB: C9

INCREMENT_SUBSTATE_WITH_FIXED_DELAY:
        ; Increments substate if enough frames passed
        ld      a,50h                                          ;#43FC: 3E 50
INCREMENT_SUBSTATE_WITH_GIVEN_DELAY:
        ; Increments substate if A frames passed
        ld      (WAIT_TIMER),a                                 ;#43FE: 32 04 E0
INCREMENT_SUBSTATE:
        ; Increments game substate
        ld      hl,GAME_SUBSTATE                               ;#4401: 21 01 E0
        inc     (hl)                                           ;#4404: 34
        ret                                                    ;#4405: C9

DRAW_CONTROLLER_INDICATOR:
        ; Update indicator (Joystick vs Keyboard) on screen (unused)?
        call    WRITE_VRAM_STREAM                              ;#4406: CD 90 45
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4409: 3A 02 E0
        rlca                                                   ;#440C: 07
        and     1                                              ;#440D: E6 01
        add     a,31h                                          ;#440F: C6 31
        LOAD_NAME_TABLE de, 9, 19                              ;#4411: 11 33 39
        call    WRITE_VRAM_BYTE                                ;#4414: CD B3 48
        ret                                                    ;#4417: C9

POLL_CONTROLLER_SELECT:
        ; Checks for '1' or '2' keys to select input device
        ld      a,(SELECT_CONTROLLER_DISABLED)                 ;#4418: 3A 3B E1
        or      a                                              ;#441B: B7
        ret     nz                                             ;#441C: C0
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#441D: 3A 02 E0
        bit     6,a                                            ;#4420: CB 77
        ret     nz                                             ;#4422: C0
        ld      a,50h                                          ;#4423: 3E 50
        out     (PPI_AA),a                                     ;#4425: D3 AA
        out     (PPI_AA),a                                     ;#4427: D3 AA
        in      a,(PPI_A9)                                     ;#4429: DB A9
        cpl                                                    ;#442B: 2F
        and     6                                              ;#442C: E6 06
        ld      b,40h                                          ;#442E: 06 40
        cp      2                                              ;#4430: FE 02
        jr      z,POLL_CONTROLLER_DONE                         ;#4432: 28 05
        ld      b,50h                                          ;#4434: 06 50
        cp      4                                              ;#4436: FE 04
        ret     nz                                             ;#4438: C0
POLL_CONTROLLER_DONE:
        ; Controller selection finished
        xor     a                                              ;#4439: AF
        ld      (TIMER_ACTIVE_FLAG),a                          ;#443A: 32 33 E1
        ld      a,b                                            ;#443D: 78
        ld      (INPUT_DEVICE_FLAGS),a                         ;#443E: 32 02 E0
        pop     hl                                             ;#4441: E1
        ld      a,7                                            ;#4442: 3E 07
        ld      (GAME_STATE),a                                 ;#4444: 32 00 E0
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#4447: C3 EE 43
        ret                                                    ;#444A: C9

INIT_RAM_AND_VRAM:
        ; Clears work RAM and initializes VDP tables
        ld      hl,CURRENT_SCORE_BCD + BCD_LOW                 ;#444B: 21 43 E0
        ld      de,CURRENT_SCORE_BCD + BCD_LOW + 1             ;#444E: 11 44 E0
        ld      bc,100h                                        ;#4451: 01 00 01
        ld      (hl),0                                         ;#4454: 36 00
        ldir                                                   ;#4456: ED B0
        ld      hl,DEFAULT_GAME_VARS                           ;#4458: 21 79 44
        ld      de,CURRENT_VISIBLE_STAGE                       ;#445B: 11 E0 E0
        ld      bc,9                                           ;#445E: 01 09 00
        ldir                                                   ;#4461: ED B0
        LOAD_VRAM_ADDRESS de, 900h                             ;#4463: 11 00 09
        ld      bc,100h                                        ;#4466: 01 00 01
        ld      a,0F0h                                         ;#4469: 3E F0
        call    FILL_VRAM                                      ;#446B: CD F1 44
        ; Repeat for each of the 10 (0Ah) stages.
        ld      b,0Ah                                          ;#446E: 06 0A
        ld      hl,STAGE_COMPLETION_FLAGS                      ;#4470: 21 D5 E0
INIT_STAGE_COMPLETION_FLAGS:
        ; Initialize stage completion flags to default value
        ld      (hl),5                                         ;#4473: 36 05
        inc     hl                                             ;#4475: 23
        djnz    INIT_STAGE_COMPLETION_FLAGS                    ;#4476: 10 FB
        ret                                                    ;#4478: C9

DEFAULT_GAME_VARS:
        ; Initial values for E0E0h-E0E8h (Flags, Timers)
        db      1 ; CURRENT_VISIBLE_STAGE initial value        ;#4479: 01
        db      0 ; CURRENT_STAGE_INDEX initial value (stage 0) ;#447A: 00
        db      0 ; DISTANCE_EVENT_TICK initial value          ;#447B: 00
        dw      200h ; REMANING_TIME_BCD initial value (start distance) ;#447C: 00 02
        dw      1700h ; STAGE_DISTANCE_BCD initial value       ;#447E: 00 17
        db      0 ; MAP_PROGRESS_LIMIT initial value           ;#4480: 00
        db      0 ; CURRENT_STAGE initial value                ;#4481: 00

INIT_HARDWARE:
        ; Initialize VDP, PSG, and clear VRAM
        call    INIT_VDP_REGISTERS                             ;#4482: CD B9 44
        ld      a,7                                            ;#4485: 3E 07
        out     (PSG_ADDR),a                                   ;#4487: D3 A0
        ld      a,0B8h                                         ;#4489: 3E B8
        out     (PSG_WRDATA),a                                 ;#448B: D3 A1
        call    INIT_PSG_PORT_B                                ;#448D: CD FD 45
        call    MUTE_PSG                                       ;#4490: CD A6 44
        LOAD_VRAM_ADDRESS de, 0                                ;#4493: 11 00 00
        ld      bc,VRAM_SIZE                                   ;#4496: 01 00 40
ZERO_FILL_VRAM_RANGE:
        ; Set A=0 and fill VRAM for DE/BC range
        xor     a                                              ;#4499: AF
        call    FILL_VRAM                                      ;#449A: CD F1 44
        ret                                                    ;#449D: C9

CLEAR_NAME_TABLE:
        ; Clear the VRAM name table (3800h-3AFFh)
        LOAD_NAME_TABLE de, 0, 0                               ;#449E: 11 00 38
        ld      bc,300h                                        ;#44A1: 01 00 03
        jr      ZERO_FILL_VRAM_RANGE                           ;#44A4: 18 F3

MUTE_PSG:
        ; Mute all PSG channels (Registers 8, 9, 10)
        xor     a                                              ;#44A6: AF
        ld      bc,PSG_ADDR + 3 * 256                          ;#44A7: 01 A0 03
        ld      d,8                                            ;#44AA: 16 08
MUTE_PSG_LOOP:
        ; Iterate PSG register write/mute loop
        out     (c),d                                          ;#44AC: ED 51
        inc     d                                              ;#44AE: 14
        out     (PSG_WRDATA),a                                 ;#44AF: D3 A1
        djnz    MUTE_PSG_LOOP                                  ;#44B1: 10 F9
        ld      a,CMD_SOUND_STOP                               ;#44B3: 3E 95
        call    PLAY_SOUND_SAFE                                ;#44B5: CD 70 79
        ret                                                    ;#44B8: C9

INIT_VDP_REGISTERS:
        ; Copy VDP register values to RAM mirror and write to VDP
        ld      hl,INITIAL_VDP_REGISTERS                       ;#44B9: 21 D6 44
        ld      de,MIRROR_VDP_REGISTERS                        ;#44BC: 11 38 E0
        ld      bc,8                                           ;#44BF: 01 08 00
        ldir                                                   ;#44C2: ED B0
        ld      hl,MIRROR_VDP_REGISTERS                        ;#44C4: 21 38 E0
        ld      b,8                                            ;#44C7: 06 08
        ld      d,80h                                          ;#44C9: 16 80
INIT_VDP_REG_LOOP:
        ; Loop writing VDP registers from mirror
        ld      e,(hl)                                         ;#44CB: 5E
        di                                                     ;#44CC: F3
        call    SET_VDP                                        ;#44CD: CD C9 48
        ei                                                     ;#44D0: FB
        inc     hl                                             ;#44D1: 23
        inc     d                                              ;#44D2: 14
        djnz    INIT_VDP_REG_LOOP                              ;#44D3: 10 F6
        ret                                                    ;#44D5: C9

INITIAL_VDP_REGISTERS:
        ; Initial VDP register values
        ; Format: FORMAT_VDP_REGISTERS
        db      2, 0E2h, 0Eh, 7Fh, 7, 76h, 3, 0E1h ; VDP Registers initialization table  ;#44D6: 02 E2 0E 7F 07 76 03 E1

COPY_RAM_TO_VRAM:
        ; Copy RAM to VRAM
        di                                                     ;#44DE: F3
        set     6,d                                            ;#44DF: CB F2
        call    SET_VDP                                        ;#44E1: CD C9 48
        res     6,d                                            ;#44E4: CB B2
COPY_RAM_TO_VRAM_LOOP:
        ; Loop copying RAM to VRAM
        ld      a,(hl)                                         ;#44E6: 7E
        out     (VDP_98),a                                     ;#44E7: D3 98
        inc     hl                                             ;#44E9: 23
        dec     bc                                             ;#44EA: 0B
        ld      a,b                                            ;#44EB: 78
        or      c                                              ;#44EC: B1
        jr      nz,COPY_RAM_TO_VRAM_LOOP                       ;#44ED: 20 F7
        ei                                                     ;#44EF: FB
        ret                                                    ;#44F0: C9

FILL_VRAM:
        ; Fill VRAM with value
        di                                                     ;#44F1: F3
        ld      h,a                                            ;#44F2: 67
        set     6,d                                            ;#44F3: CB F2
        call    SET_VDP                                        ;#44F5: CD C9 48
        res     6,d                                            ;#44F8: CB B2
FILL_VRAM_LOOP:
        ; Loop filling VRAM
        ld      a,h                                            ;#44FA: 7C
        out     (VDP_98),a                                     ;#44FB: D3 98
        dec     bc                                             ;#44FD: 0B
        ld      a,b                                            ;#44FE: 78
        or      c                                              ;#44FF: B1
        jr      nz,FILL_VRAM_LOOP                              ;#4500: 20 F8
        ei                                                     ;#4502: FB
        ret                                                    ;#4503: C9

FILL_VRAM_STREAM:
        ; Fills VRAM regions from a character-based stream (value, count, addr)
        ld      a,(hl)                                         ;#4504: 7E
        inc     hl                                             ;#4505: 23
        ld      (VRAM_FILL_VALUE),a                            ;#4506: 32 DF E0
        ld      d,39h                                          ;#4509: 16 39
FILL_VRAM_STREAM_LOOP:
        ; Loop over stream entries for VRAM fill
        ld      c,(hl)                                         ;#450B: 4E
        inc     hl                                             ;#450C: 23
        xor     a                                              ;#450D: AF
        cp      c                                              ;#450E: B9
        ret     z                                              ;#450F: C8
        ld      b,a                                            ;#4510: 47
        ld      e,(hl)                                         ;#4511: 5E
        inc     hl                                             ;#4512: 23
        ld      a,e                                            ;#4513: 7B
        cp      20h                                            ;#4514: FE 20
        jr      nc,FILL_VRAM_STREAM_ITER                       ;#4516: 30 01
        inc     d                                              ;#4518: 14
FILL_VRAM_STREAM_ITER:
        ; Next entry in VRAM fill stream
        ld      a,(VRAM_FILL_VALUE)                            ;#4519: 3A DF E0
        push    hl                                             ;#451C: E5
        push    de                                             ;#451D: D5
        call    FILL_VRAM                                      ;#451E: CD F1 44
        pop     de                                             ;#4521: D1
        pop     hl                                             ;#4522: E1
        jr      FILL_VRAM_STREAM_LOOP                          ;#4523: 18 E6

WRITE_VRAM_TILES_STREAM:
        ; Writes tiles to VRAM using a custom stream format
        ; For this routine, the sprite attribute table is just more name-table rows.
        ; Stream format overview:
        ; - Byte 0: header `H` (high nibble seeds row base, low 2 bits select VRAM page).
        ; - Then records: [K, data...] where K is E0h-FFh control, data bytes <E0h.
        ; - Terminator: `00h` in the data loop ends the stream.
        ld      a,(hl)                                         ;#4525: 7E
        or      a                                              ;#4526: B7
        ret     z                                              ;#4527: C8
        and     0F0h                                           ;#4528: E6 F0
        ld      c,a                                            ;#452A: 4F
        ; C stores the high nibble of the header.
        ld      a,(hl)                                         ;#452B: 7E
        inc     hl                                             ;#452C: 23
        and     3                                              ;#452D: E6 03
        add     a,78h                                          ;#452F: C6 78
        ld      d,a                                            ;#4531: 57
        ; D stores 38h, 39h, 3Ah, or 3Bh (with VDP write bit encoding applied).
        ld      a,c                                            ;#4532: 79
WRITE_VRAM_TILES_ADDRESS:
        ; Consume control byte and advance row base
        ld      b,(hl)                                         ;#4533: 46
        ; Lower nibble of B selects column.
        inc     hl                                             ;#4534: 23
        ; Increment row by one (times 32).
        ld      a,20h                                          ;#4535: 3E 20
        add     a,c                                            ;#4537: 81
        ld      c,a                                            ;#4538: 4F
        ; C stores the row (times 32), increment D if carry.
        jr      nc,WRITE_VRAM_TILES_NEXT                       ;#4539: 30 01
        inc     d                                              ;#453B: 14
WRITE_VRAM_TILES_NEXT:
        ; Compute DE and set next VRAM write address
        ld      a,c                                            ;#453C: 79
        add     a,b                                            ;#453D: 80
        sub     0E0h                                           ;#453E: D6 E0
        ; E has row * 32 + column.
        ld      e,a                                            ;#4540: 5F
        call    SET_VDP                                        ;#4541: CD C9 48
WRITE_VRAM_TILES_LOOP:
        ; Emit data bytes until next control/terminator
        ; Format of this stream:
        ; - `00h`: terminator, returns.
        ; - `E0h-FFh`: control, change address.
        ; - `01h-DFh`: writes to VRAM sequentially.
        ld      a,(hl)                                         ;#4544: 7E
        or      a                                              ;#4545: B7
        ret     z                                              ;#4546: C8
        cp      0E0h                                           ;#4547: FE E0
        jr      nc,WRITE_VRAM_TILES_ADDRESS                    ;#4549: 30 E8
        inc     hl                                             ;#454B: 23
        out     (VDP_98),a                                     ;#454C: D3 98
        jr      WRITE_VRAM_TILES_LOOP                          ;#454E: 18 F4

DECOMPRESS_VRAM_INDIRECT:
        ; Standard entry (Addr in stream)
        ld      e,(hl)                                         ;#4550: 5E
        inc     hl                                             ;#4551: 23
        ld      d,(hl)                                         ;#4552: 56
        inc     hl                                             ;#4553: 23
DECOMPRESS_VRAM_DIRECT:
        ; Entry with Addr in DE (No Mirror)
        ld      c,0                                            ;#4554: 0E 00
        jr      DECOMPRESS_VRAM_SET_VDP                        ;#4556: 18 02

DECOMPRESS_VRAM_DIRECT_MIRROR:
        ; Entry with Addr in DE (Mirrored)
        ld      c,1                                            ;#4558: 0E 01
DECOMPRESS_VRAM_SET_VDP:
        ; Common SET_VDP entry for decompression
        call    SET_VDP                                        ;#455A: CD C9 48
DECOMPRESS_VRAM_DATA_ONLY:
        ; Data-only entry (No SET_VDP call)
        ld      a,(hl)                                         ;#455D: 7E
        inc     hl                                             ;#455E: 23
        or      a                                              ;#455F: B7
        jr      z,DECOMPRESS_VRAM_EXIT                         ;#4560: 28 1C
        bit     7,a                                            ;#4562: CB 7F
        jr      nz,DECOMPRESS_VRAM_LITERAL                     ;#4564: 20 0C
        ld      b,a                                            ;#4566: 47
        call    READ_BYTE_WITH_OPTIONAL_MIRROR                 ;#4567: CD 80 45
DECOMPRESS_VRAM_RLE_LOOP:
        ; Loop for RLE decompression
        out     (VDP_98),a                                     ;#456A: D3 98
        push    hl                                             ;#456C: E5
        pop     hl                                             ;#456D: E1
        djnz    DECOMPRESS_VRAM_RLE_LOOP                       ;#456E: 10 FA
        jr      DECOMPRESS_VRAM_DATA_ONLY                      ;#4570: 18 EB

DECOMPRESS_VRAM_LITERAL:
        ; Handle literal byte sequence during decompression
        res     7,a                                            ;#4572: CB BF
        ld      b,a                                            ;#4574: 47
DECOMPRESS_VRAM_LIT_LOOP:
        ; Loop for literal decompression
        call    READ_BYTE_WITH_OPTIONAL_MIRROR                 ;#4575: CD 80 45
        out     (VDP_98),a                                     ;#4578: D3 98
        djnz    DECOMPRESS_VRAM_LIT_LOOP                       ;#457A: 10 F9
        jr      DECOMPRESS_VRAM_DATA_ONLY                      ;#457C: 18 DF

DECOMPRESS_VRAM_EXIT:
        ; Exit decompression routine
        ei                                                     ;#457E: FB
        ret                                                    ;#457F: C9

READ_BYTE_WITH_OPTIONAL_MIRROR:
        ; Reads (HL), inc HL, and reverses bits if bit 0 of C is set
        ld      a,(hl)                                         ;#4580: 7E
        inc     hl                                             ;#4581: 23
        bit     0,c                                            ;#4582: CB 41
        ret     z                                              ;#4584: C8
        push    bc                                             ;#4585: C5
        ld      b,8                                            ;#4586: 06 08
        ld      c,a                                            ;#4588: 4F
BIT_REV_LOOP:
        ; Bits reversal loop for mirror decompression
        rr      c                                              ;#4589: CB 19
        rla                                                    ;#458B: 17
        djnz    BIT_REV_LOOP                                   ;#458C: 10 FB
        pop     bc                                             ;#458E: C1
        ret                                                    ;#458F: C9

WRITE_VRAM_STREAM:
        ; Updates VRAM from a data stream with addresses and terminators
        ld      e,(hl)                                         ;#4590: 5E
        inc     hl                                             ;#4591: 23
        ld      d,(hl)                                         ;#4592: 56
        inc     hl                                             ;#4593: 23
WRITE_VRAM_STREAM_WITH_OFFSET:
        ; Adds DE to VRAM pointer before streaming
        ld      a,(hl)                                         ;#4594: 7E
        inc     hl                                             ;#4595: 23
        ld      b,a                                            ;#4596: 47
        inc     b                                              ;#4597: 04
        ret     z                                              ;#4598: C8
        inc     b                                              ;#4599: 04
        jr      z,WRITE_VRAM_STREAM                            ;#459A: 28 F4
        call    WRITE_VRAM_BYTE                                ;#459C: CD B3 48
        inc     de                                             ;#459F: 13
        jr      WRITE_VRAM_STREAM_WITH_OFFSET                  ;#45A0: 18 F2

REPLICATE_4_BYTE_BLOCK:
        ; Replicate a 4-byte block in memory C times
        push    hl                                             ;#45A2: E5
        ld      b,4                                            ;#45A3: 06 04
REPLICATE_4_BYTE_LOOP:
        ; Loop to copy 4 bytes into destination
        ld      a,(hl)                                         ;#45A5: 7E
        ld      (de),a                                         ;#45A6: 12
        inc     hl                                             ;#45A7: 23
        inc     de                                             ;#45A8: 13
        djnz    REPLICATE_4_BYTE_LOOP                          ;#45A9: 10 FA
        dec     c                                              ;#45AB: 0D
        jr      z,CLEAR_SPRITES_VRAM_DONE                      ;#45AC: 28 03
        pop     hl                                             ;#45AE: E1
        jr      REPLICATE_4_BYTE_BLOCK                         ;#45AF: 18 F1

CLEAR_SPRITES_VRAM_DONE:
        ; Wait animation tile write finished
        pop     bc                                             ;#45B1: C1
        ret                                                    ;#45B2: C9

CLEAR_SPRITES_AND_UPDATE_VRAM:
        ; Clears sprites and conditionally updates VRAM tiles during wait
        call    CLEAR_SPRITES                                  ;#45B3: CD E8 45
        ld      d,38h                                          ;#45B6: 16 38
        ld      hl,WAIT_TIMER                                  ;#45B8: 21 04 E0
        ld      b,18h                                          ;#45BB: 06 18
        bit     6,(hl)                                         ;#45BD: CB 76
        jr      nz,CLEAR_SAT_MIRROR_LOOP                       ;#45BF: 20 08
        ld      a,1Fh                                          ;#45C1: 3E 1F
        sub     (hl)                                           ;#45C3: 96
        ld      e,a                                            ;#45C4: 5F
        set     6,(hl)                                         ;#45C5: CB F6
        jr      CLEAR_SPRITES_VRAM_UPDATE                      ;#45C7: 18 05

CLEAR_SAT_MIRROR_LOOP:
        ; Loop clearing SAT_MIRROR
        res     6,(hl)                                         ;#45C9: CB B6
        dec     (hl)                                           ;#45CB: 35
        ret     m                                              ;#45CC: F8
        ld      e,(hl)                                         ;#45CD: 5E
CLEAR_SPRITES_VRAM_UPDATE:
        ; Select VRAM update offset for wait animation
        ld      a,(GAME_STATE)                                 ;#45CE: 3A 00 E0
        cp      0Ah                                            ;#45D1: FE 0A
        jr      c,CLEAR_SPRITES_VRAM_LOOP                      ;#45D3: 38 06
        ld      a,40h                                          ;#45D5: 3E 40
        add     a,e                                            ;#45D7: 83
        ld      e,a                                            ;#45D8: 5F
        dec     b                                              ;#45D9: 05
        dec     b                                              ;#45DA: 05
CLEAR_SPRITES_VRAM_LOOP:
        ; Loop writing wait animation tiles to VRAM
        xor     a                                              ;#45DB: AF
        call    WRITE_VRAM_BYTE                                ;#45DC: CD B3 48
        ld      a,20h                                          ;#45DF: 3E 20
        call    ADD_DE_A                                       ;#45E1: CD D6 48
        djnz    CLEAR_SPRITES_VRAM_LOOP                        ;#45E4: 10 F5
        xor     a                                              ;#45E6: AF
        ret                                                    ;#45E7: C9

CLEAR_SPRITES:
        ; Clears sprite attribute mirror in RAM and copies to VRAM
        ld      hl,SAT_MIRROR                                  ;#45E8: 21 50 E0
        push    hl                                             ;#45EB: E5
        ld      b,80h                                          ;#45EC: 06 80
CLEAR_SPRITE_ATTR_LOOP:
        ; Loop to zero sprite attribute mirror
        ld      (hl),0                                         ;#45EE: 36 00
        inc     hl                                             ;#45F0: 23
        djnz    CLEAR_SPRITE_ATTR_LOOP                         ;#45F1: 10 FB
        LOAD_SPRITE_ATTR de, 0, 0                              ;#45F3: 11 00 3B
        pop     hl                                             ;#45F6: E1
        ld      bc,80h                                         ;#45F7: 01 80 00
        jp      COPY_RAM_TO_VRAM                               ;#45FA: C3 DE 44

INIT_PSG_PORT_B:
        ; Initialize PSG Port B (Register 15)
        ld      a,0Fh                                          ;#45FD: 3E 0F
        out     (PSG_ADDR),a                                   ;#45FF: D3 A0
        ld      a,8Fh                                          ;#4601: 3E 8F
        out     (PSG_WRDATA),a                                 ;#4603: D3 A1
        ret                                                    ;#4605: C9

READ_INPUT_EDGE:
        ; Detect new button presses (edge trigger)
        ld      a,(CUR_INPUT_KEYS)                             ;#4606: 3A 09 E0
        ld      b,a                                            ;#4609: 47
        ld      a,(PREV_INPUT_KEYS)                            ;#460A: 3A 08 E0
        and     30h                                            ;#460D: E6 30
        cpl                                                    ;#460F: 2F
        ld      c,a                                            ;#4610: 4F
        ld      a,b                                            ;#4611: 78
        and     30h                                            ;#4612: E6 30
        and     c                                              ;#4614: A1
        ret                                                    ;#4615: C9

ADD_SCORE:
        ; Add value in DE to current BCD score
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4616: 3A 02 E0
        add     a,a                                            ;#4619: 87
        ret     p                                              ;#461A: F0
        ld      hl,CURRENT_SCORE_BCD + BCD_LOW                 ;#461B: 21 43 E0
        ld      a,(hl)                                         ;#461E: 7E
        add     a,e                                            ;#461F: 83
        daa                                                    ;#4620: 27
        ld      (hl),a                                         ;#4621: 77
        ld      e,a                                            ;#4622: 5F
        inc     hl                                             ;#4623: 23
        ld      a,(hl)                                         ;#4624: 7E
        adc     a,d                                            ;#4625: 8A
        daa                                                    ;#4626: 27
        ld      (hl),a                                         ;#4627: 77
        ld      d,a                                            ;#4628: 57
        inc     hl                                             ;#4629: 23
        jr      nc,ADD_SCORE_DONE                              ;#462A: 30 14
        ld      a,(hl)                                         ;#462C: 7E
        adc     a,0                                            ;#462D: CE 00
        daa                                                    ;#462F: 27
        ld      (hl),a                                         ;#4630: 77
        jr      nc,ADD_SCORE_DONE                              ;#4631: 30 0D
        ld      bc,9999h ; Max score is 999999                 ;#4633: 01 99 99
        ld      (HI_SCORE_BCD + BCD_LOW),bc                    ;#4636: ED 43 40 E0
        ld      (HI_SCORE_BCD + BCD_MID),bc                    ;#463A: ED 43 41 E0
        jr      HUD_DRAW_HI_SCORE                              ;#463E: 18 72

ADD_SCORE_DONE:
        ; Score addition finished
        ld      a,(HI_SCORE_BCD + BCD_HIGH)                    ;#4640: 3A 42 E0
        ld      b,(hl)                                         ;#4643: 46
        sub     (hl)                                           ;#4644: 96
        jr      c,ADD_SCORE_CHECK_HI                           ;#4645: 38 09
        jr      nz,HUD_DRAW_SCORE                              ;#4647: 20 72
        ld      hl,(HI_SCORE_BCD + BCD_LOW)                    ;#4649: 2A 40 E0
        sbc     hl,de                                          ;#464C: ED 52
        jr      nc,HUD_DRAW_SCORE                              ;#464E: 30 6B
ADD_SCORE_CHECK_HI:
        ; Check if score is higher than record
        ld      (HI_SCORE_BCD + BCD_LOW),de                    ;#4650: ED 53 40 E0
        ld      a,b                                            ;#4654: 78
        ld      (HI_SCORE_BCD + BCD_HIGH),a                    ;#4655: 32 42 E0
        jr      HUD_DRAW_HI_SCORE                              ;#4658: 18 58

UPDATE_GAME_TIMER:
        ; Decrement stage timer once per second
        ld      a,(TIMER_ACTIVE_FLAG)                          ;#465A: 3A 33 E1
        or      a                                              ;#465D: B7
        ret     z                                              ;#465E: C8
        ld      hl,(REMANING_TIME_BCD)                         ;#465F: 2A E3 E0
        ld      a,h                                            ;#4662: 7C
        add     a,l                                            ;#4663: 85
        jr      nz,UPDATE_GAME_TIMER_DONE                      ;#4664: 20 05
        inc     a                                              ;#4666: 3C
        ld      (TIME_UP_FLAG),a                               ;#4667: 32 0C E0
        ret                                                    ;#466A: C9

UPDATE_GAME_TIMER_DONE:
        ; Timer update finished
        ld      a,(FRAME_COUNTER)                              ;#466B: 3A 03 E0
        and     3Fh                                            ;#466E: E6 3F
        ret     nz                                             ;#4670: C0
        ld      c,1                                            ;#4671: 0E 01
DECREMENT_DISTANCE:
        ; Decrement remaining distance BCD and refresh HUD
        ld      hl,REMANING_TIME_BCD                           ;#4673: 21 E3 E0
        ld      a,(hl)                                         ;#4676: 7E
        sub     1                                              ;#4677: D6 01
        daa                                                    ;#4679: 27
        ld      (hl),a                                         ;#467A: 77
        inc     hl                                             ;#467B: 23
        ld      a,(hl)                                         ;#467C: 7E
        jr      nc,DECREMENT_DISTANCE_DONE                     ;#467D: 30 04
        sub     1                                              ;#467F: D6 01
        daa                                                    ;#4681: 27
        ld      (hl),a                                         ;#4682: 77
DECREMENT_DISTANCE_DONE:
        ; Distance decrement finished
        dec     hl                                             ;#4683: 2B
        or      a                                              ;#4684: B7
        jr      nz,HUD_DRAW_DISTANCE                           ;#4685: 20 11
        ld      a,(hl)                                         ;#4687: 7E
        cp      11h                                            ;#4688: FE 11
        jr      nc,HUD_DRAW_DISTANCE                           ;#468A: 30 0C
        dec     c                                              ;#468C: 0D
        jr      nz,HUD_DRAW_DISTANCE                           ;#468D: 20 09
        push    af                                             ;#468F: F5
        push    hl                                             ;#4690: E5
        ld      a,ID_SOUND_DISTANCE_WARNING                    ;#4691: 3E 09
        call    PLAY_SOUND_SAFE                                ;#4693: CD 70 79
        pop     hl                                             ;#4696: E1
        pop     af                                             ;#4697: F1
HUD_DRAW_DISTANCE:
        ; Draw remaining distance (4 digits)
        ld      b,2                                            ;#4698: 06 02
        LOAD_NAME_TABLE de, 1, 7                               ;#469A: 11 27 38
        ld      hl,REMANING_TIME_HIGH                          ;#469D: 21 E4 E0
        jp      WRITE_BCD_TO_HUD                               ;#46A0: C3 11 47

REFRESH_HUD:
        ; Redraw all HUD elements (Distance, HI_SCORE Stage, Time, Scores)
        ld      hl,HUD_STATIC_TEXT                             ;#46A3: 21 45 57
        call    WRITE_VRAM_STREAM                              ;#46A6: CD 90 45
        call    HUD_DRAW_DISTANCE                              ;#46A9: CD 98 46
        call    HUD_DRAW_STAGE_HI_SCORE                        ;#46AC: CD FF 46
        call    HUD_DRAW_STAGE                                 ;#46AF: CD 09 47
HUD_DRAW_HI_SCORE:
        ; Setup for drawing high score after updates
        ld      hl,HI_SCORE_BCD + BCD_HIGH                     ;#46B2: 21 42 E0
        LOAD_NAME_TABLE de, 0, 15                              ;#46B5: 11 0F 38
        call    HUD_DRAW_6_DIGITS                              ;#46B8: CD C1 46
HUD_DRAW_SCORE:
        ; Entry point for HUD score drawing
        LOAD_NAME_TABLE de, 0, 5                               ;#46BB: 11 05 38
        ld      hl,CURRENT_SCORE_BCD + BCD_HIGH                ;#46BE: 21 45 E0
HUD_DRAW_6_DIGITS:
        ; Internal body for drawing 6-digit BCD values
        ld      b,3                                            ;#46C1: 06 03
        jr      WRITE_BCD_TO_HUD                               ;#46C3: 18 4C

UPDATE_STAGE_DISTANCE:
        ; Decrements stage distance counter
        ld      hl,DISTANCE_TICK_TIMER                         ;#46C5: 21 E9 E0
        dec     (hl)                                           ;#46C8: 35
        ret     nz                                             ;#46C9: C0
        ld      a,(PENGUIN_SPEED)                              ;#46CA: 3A 00 E1
        srl     a                                              ;#46CD: CB 3F
        dec     a                                              ;#46CF: 3D
        ld      (hl),a                                         ;#46D0: 77
        ld      hl,STAGE_DISTANCE_HIGH                         ;#46D1: 21 E6 E0
        ld      a,(hl)                                         ;#46D4: 7E
        dec     hl                                             ;#46D5: 2B
        or      (hl)                                           ;#46D6: B6
        jr      nz,DECREMENT_BCD_DIGITS                        ;#46D7: 20 05
        inc     a                                              ;#46D9: 3C
        ld      (STAGE_GOAL_FLAG),a                            ;#46DA: 32 0D E0
        ret                                                    ;#46DD: C9

DECREMENT_BCD_DIGITS:
        ; Loop drawing BCD digits
        ld      a,(hl)                                         ;#46DE: 7E
        sub     1                                              ;#46DF: D6 01
        daa                                                    ;#46E1: 27
        ld      (hl),a                                         ;#46E2: 77
        ld      c,a                                            ;#46E3: 4F
        inc     hl                                             ;#46E4: 23
        jr      nc,DECREMENT_BCD_DIGITS_DONE                   ;#46E5: 30 05
        ld      a,(hl)                                         ;#46E7: 7E
        sub     1                                              ;#46E8: D6 01
        daa                                                    ;#46EA: 27
        ld      (hl),a                                         ;#46EB: 77
DECREMENT_BCD_DIGITS_DONE:
        ; Digits drawing finished
        ld      a,c                                            ;#46EC: 79
        or      a                                              ;#46ED: B7
        jr      nz,UPDATE_STAGE_DISTANCE_NEXT                  ;#46EE: 20 0C
        or      (hl)                                           ;#46F0: B6
        jr      z,UPDATE_STAGE_DISTANCE_NEXT                   ;#46F1: 28 09
        ld      a,(hl)                                         ;#46F3: 7E
        and     3                                              ;#46F4: E6 03
        jr      nz,UPDATE_STAGE_DISTANCE_NEXT                  ;#46F6: 20 04
        inc     a                                              ;#46F8: 3C
        ld      (STAGE_SEGMENT_TIMER),a                        ;#46F9: 32 07 E1
UPDATE_STAGE_DISTANCE_NEXT:
        ; Continue distance update
        call    CHECK_DISTANCE_MILESTONE                       ;#46FC: CD A1 52
HUD_DRAW_STAGE_HI_SCORE:
        ; Draw stage HI_SCORE/current stage (4 digits)
        ld      b,2                                            ;#46FF: 06 02
        LOAD_NAME_TABLE de, 1, 15                              ;#4701: 11 2F 38
        ld      hl,STAGE_DISTANCE_HIGH                         ;#4704: 21 E6 E0
        jr      WRITE_BCD_TO_HUD                               ;#4707: 18 08

HUD_DRAW_STAGE:
        ; Draw current stage number from CURRENT_VISIBLE_STAGE (1 BCD byte = 2 digits)
        LOAD_NAME_TABLE de, 0, 28                              ;#4709: 11 1C 38
        ld      hl,CURRENT_VISIBLE_STAGE                       ;#470C: 21 E0 E0
        ld      b,1                                            ;#470F: 06 01
WRITE_BCD_TO_HUD:
        ; Core routine to draw BCD bytes as digits to VRAM (dec hl, loop b times)
        ld      a,(hl)                                         ;#4711: 7E
        push    af                                             ;#4712: F5
        and     0Fh                                            ;#4713: E6 0F
        or      10h                                            ;#4715: F6 10
        ld      c,a                                            ;#4717: 4F
        pop     af                                             ;#4718: F1
        and     0F0h                                           ;#4719: E6 F0
        rra                                                    ;#471B: 1F
        rra                                                    ;#471C: 1F
        rra                                                    ;#471D: 1F
        rra                                                    ;#471E: 1F
        or      10h                                            ;#471F: F6 10
        call    WRITE_VRAM_BYTE                                ;#4721: CD B3 48
        inc     de                                             ;#4724: 13
        ld      a,c                                            ;#4725: 79
        call    WRITE_VRAM_BYTE                                ;#4726: CD B3 48
        dec     hl                                             ;#4729: 2B
        inc     de                                             ;#472A: 13
        djnz    WRITE_BCD_TO_HUD                               ;#472B: 10 E4
        ret                                                    ;#472D: C9

UPDATE_STAGE_SEQUENCE:
        ; Pick SEQUENCE_THRESHOLD and SEQUENCE_DATA_PTR for stage + progress
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#472E: 3A E0 E0
        and     0Fh                                            ;#4731: E6 0F
        ld      hl,SEQUENCE_TIME_THRESHOLDS                    ;#4733: 21 70 47
        add     a,a                                            ;#4736: 87
        call    ADD_HL_A                                       ;#4737: CD D1 48
        ld      a,(STAGE_DISTANCE_HIGH)                        ;#473A: 3A E6 E0
        and     10h                                            ;#473D: E6 10
        jr      z,UPDATE_STAGE_SEQUENCE_PICK_SUBTASK           ;#473F: 28 01
        inc     hl                                             ;#4741: 23
UPDATE_STAGE_SEQUENCE_PICK_SUBTASK:
        ; Threshold picked; now pick subtask pointer from progress segment
        ld      a,(hl)                                         ;#4742: 7E
        ld      (SEQUENCE_THRESHOLD),a                         ;#4743: 32 8A E1
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4746: 3A E0 E0
        and     0Fh                                            ;#4749: E6 0F
        ld      hl,SEQUENCE_TASK_TABLE                         ;#474B: 21 AC 47
        add     a,a                                            ;#474E: 87
        call    ADD_HL_A                                       ;#474F: CD D1 48
        ld      e,(hl)                                         ;#4752: 5E
        inc     hl                                             ;#4753: 23
        ld      d,(hl)                                         ;#4754: 56
        ex      de,hl                                          ;#4755: EB
        ld      a,(STAGE_DISTANCE_HIGH)                        ;#4756: 3A E6 E0
        and     0FCh                                           ;#4759: E6 FC
        rrca                                                   ;#475B: 0F
        rrca                                                   ;#475C: 0F
        res     3,a                                            ;#475D: CB 9F
        cp      4                                              ;#475F: FE 04
        jr      c,UPDATE_STAGE_SEQUENCE_INDEX_READY            ;#4761: 38 01
        dec     a                                              ;#4763: 3D
UPDATE_STAGE_SEQUENCE_INDEX_READY:
        ; Progress index settled (with/without -1 adjustment); load subtask pointer
        add     a,a                                            ;#4764: 87
        call    ADD_HL_A                                       ;#4765: CD D1 48
        ld      e,(hl)                                         ;#4768: 5E
        inc     hl                                             ;#4769: 23
        ld      d,(hl)                                         ;#476A: 56
        ex      de,hl                                          ;#476B: EB
        ld      (SEQUENCE_DATA_PTR),hl                         ;#476C: 22 8B E1
        ret                                                    ;#476F: C9

SEQUENCE_TIME_THRESHOLDS:
        ; Sequence threshold table (per time digit, two variants)
        ; Format: FORMAT_SEQUENCE_THRESHOLDS
        ; - 10 pairs: [low_threshold, high_threshold] per time digit (0-9).
        THRESHOLD 80h, 0                                       ;#4770: 80 00
        THRESHOLD 0A0h, 0A0h                                   ;#4772: A0 A0
        THRESHOLD 50h, 50h                                     ;#4774: 50 50
        THRESHOLD 0E0h, 0E0h                                   ;#4776: E0 E0
        THRESHOLD 50h, 50h                                     ;#4778: 50 50
        THRESHOLD 0, 20h                                       ;#477A: 00 20
        THRESHOLD 0E0h, 0E0h                                   ;#477C: E0 E0
        THRESHOLD 20h, 20h                                     ;#477E: 20 20
        THRESHOLD 0, 0                                         ;#4780: 00 00
        THRESHOLD 0FFh, 0FFh                                   ;#4782: FF FF

SEQ_STREAM_FISH_JUMP:
        ; Sequence command stream for fish jump behavior
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_ITEM_PROP 1                                        ;#4784: 01
        SEQ_ITEM_PROP 5                                        ;#4785: 05
        SEQ_IDLE                                               ;#4786: FF
        SEQ_ITEM_PROP 0                                        ;#4787: 00
        SEQ_MOVE_STATE 2                                       ;#4788: 12
        SEQ_ITEM_PROP 5                                        ;#4789: 05
        SEQ_IDLE                                               ;#478A: FF
        SEQ_ITEM_PROP 0                                        ;#478B: 00

SEQ_STREAM_SEAL_MOVE:
        ; Sequence command stream for seal movement behavior
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_MOVE_STATE 1                                       ;#478C: 11
        SEQ_ITEM_PROP 1                                        ;#478D: 01
        SEQ_ITEM_PROP 0                                        ;#478E: 00
        SEQ_MOVE_STATE 2                                       ;#478F: 12
        SEQ_ITEM_PROP 0                                        ;#4790: 00
        SEQ_ITEM_PROP 1                                        ;#4791: 01
        SEQ_MOVE_STATE 2                                       ;#4792: 12
        SEQ_ITEM_PROP 0                                        ;#4793: 00

SEQ_STREAM_MIX_A:
        ; Sequence stream A: cycles item-prop entries 0,1,3,5 (mixed item types)
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_ITEM_PROP 0                                        ;#4794: 00
        SEQ_IDLE                                               ;#4795: FF
        SEQ_ITEM_PROP 3                                        ;#4796: 03
        SEQ_MOVE_STATE 1                                       ;#4797: 11
        SEQ_ITEM_PROP 1                                        ;#4798: 01
        SEQ_ITEM_PROP 5                                        ;#4799: 05
        SEQ_IDLE                                               ;#479A: FF
        SEQ_ITEM_PROP 3                                        ;#479B: 03

SEQ_STREAM_MIX_B:
        ; Sequence stream B: cycles item-prop entries 0,1,3 (no flag)
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_ITEM_PROP 0                                        ;#479C: 00
        SEQ_IDLE                                               ;#479D: FF
        SEQ_ITEM_PROP 3                                        ;#479E: 03
        SEQ_ITEM_PROP 3                                        ;#479F: 03
        SEQ_ITEM_PROP 0                                        ;#47A0: 00
        SEQ_MOVE_STATE 1                                       ;#47A1: 11
        SEQ_ITEM_PROP 1                                        ;#47A2: 01
        SEQ_MOVE_STATE 2                                       ;#47A3: 12

SEQ_STREAM_MIX_C:
        ; Sequence stream C: cycles item-prop entries 3,5 (no small holes)
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_ITEM_PROP 5                                        ;#47A4: 05
        SEQ_IDLE                                               ;#47A5: FF
        SEQ_ITEM_PROP 5                                        ;#47A6: 05
        SEQ_IDLE                                               ;#47A7: FF
        SEQ_ITEM_PROP 3                                        ;#47A8: 03
        SEQ_MOVE_STATE 2                                       ;#47A9: 12
        SEQ_ITEM_PROP 5                                        ;#47AA: 05
        SEQ_IDLE                                               ;#47AB: FF

SEQUENCE_TASK_TABLE:
        ; Subtask-table base per stage; indexed by CURRENT_VISIBLE_STAGE & 0Fh (BCD units)
        dw      SEQUENCE_SUB_TASK_TABLE_A + 0Eh ; stage 0      ;#47AC: CE 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 1Ah ; stage 1      ;#47AE: DA 47
        dw      SEQUENCE_SUB_TASK_TABLE_A       ; stage 2      ;#47B0: C0 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 20h ; stage 3      ;#47B2: E0 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 0Eh ; stage 4      ;#47B4: CE 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 16h ; stage 5      ;#47B6: D6 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 20h ; stage 6      ;#47B8: E0 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 18h ; stage 7      ;#47BA: D8 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 1Ah ; stage 8      ;#47BC: DA 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 22h ; stage 9      ;#47BE: E2 47

SEQUENCE_SUB_TASK_TABLE_A:
        ; Combined sequence subtask list base (idle/fish mix prefix)
        ; Format: FORMAT_SEQUENCE_SUBTASK_TABLE
        ; - Entries point to SEQ_STREAM_* command streams.
        dw      SEQ_STREAM_MIX_B                               ;#47C0 9C 47
        dw      SEQ_STREAM_FISH_JUMP                           ;#47C2 84 47
        dw      SEQ_STREAM_MIX_B                               ;#47C4 9C 47
        dw      SEQ_STREAM_FISH_JUMP                           ;#47C6 84 47
        dw      SEQ_STREAM_MIX_C                               ;#47C8 A4 47
        dw      SEQ_STREAM_MIX_A                               ;#47CA 94 47
        dw      SEQ_STREAM_FISH_JUMP                           ;#47CC 84 47
        dw      SEQ_STREAM_MIX_A                               ;#47CE 94 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47D0 8C 47
        dw      SEQ_STREAM_MIX_B                               ;#47D2 9C 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47D4 8C 47
        dw      SEQ_STREAM_FISH_JUMP                           ;#47D6 84 47
        dw      SEQ_STREAM_MIX_B                               ;#47D8 9C 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47DA 8C 47
        dw      SEQ_STREAM_MIX_A                               ;#47DC 94 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47DE 8C 47
        dw      SEQ_STREAM_MIX_C                               ;#47E0 A4 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47E2 8C 47
        dw      SEQ_STREAM_MIX_C                               ;#47E4 A4 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47E6 8C 47

CHECK_SEQUENCE_STATUS:
        ; Checks sequence flag and decrements timer
        ld      a,(SEQUENCE_ACTIVE)                            ;#47E8: 3A 8E E1
        rra                                                    ;#47EB: 1F
        ret     nc                                             ;#47EC: D0
        ld      hl,SEQUENCE_TIMER                              ;#47ED: 21 8F E1
        dec     (hl)                                           ;#47F0: 35
        jr      nz,START_SEQUENCE_CHECK_DONE                   ;#47F1: 20 04
        xor     a                                              ;#47F3: AF
        ld      (SEQUENCE_ACTIVE),a                            ;#47F4: 32 8E E1
START_SEQUENCE_CHECK_DONE:
        ; Sequence check finished
        ld      c,3                                            ;#47F7: 0E 03
        ret                                                    ;#47F9: C9

START_SEQUENCE_CHECK:
        ; Entry point for checking if a new periodic sequence (fish/seal) should start
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#47FA: 3A E0 E0
        and     0Fh                                            ;#47FD: E6 0F
        ld      hl,SEQUENCE_TIMER_TABLE                        ;#47FF: 21 22 48
        call    ADD_HL_A                                       ;#4802: CD D1 48
        ld      de,(STAGE_DISTANCE_BCD)                        ;#4805: ED 5B E5 E0
        ld      a,d                                            ;#4809: 7A
        cp      4                                              ;#480A: FE 04
        ret     c                                              ;#480C: D8
        ld      a,e                                            ;#480D: 7B
        or      a                                              ;#480E: B7
        ret     nz                                             ;#480F: C0
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4810: 3A E0 E0
        add     a,d                                            ;#4813: 82
        and     3                                              ;#4814: E6 03
        cp      2                                              ;#4816: FE 02
        ret     nz                                             ;#4818: C0
        inc     a                                              ;#4819: 3C
        ld      (SEQUENCE_ACTIVE),a                            ;#481A: 32 8E E1
        ld      a,(hl)                                         ;#481D: 7E
        ld      (SEQUENCE_TIMER),a                             ;#481E: 32 8F E1
        ret                                                    ;#4821: C9

SEQUENCE_TIMER_TABLE:
        ; Sequence timer lookup (per seconds digit)
        ; One byte per entry, 10 entries indexed by (CURRENT_VISIBLE_STAGE & 0Fh).
        ; `START_SEQUENCE_CHECK` loads the selected byte into `SEQUENCE_TIMER` when it
        ; decides to kick off a new periodic sequence (fish/seal). Values: 7, 2, 2, 3,
        ; 3, 4, 4, 5, 6, 6. (Not to be confused with SEQUENCE_TIME_THRESHOLDS,
        ; which really is 10 low/high pairs.)
        ; Format: FORMAT_SEQUENCE_TIMER_TABLE
        TIMER_VALUE 7                                          ;#4822: 07
        TIMER_VALUE 2                                          ;#4823: 02
        TIMER_VALUE 2                                          ;#4824: 02
        TIMER_VALUE 3                                          ;#4825: 03
        TIMER_VALUE 3                                          ;#4826: 03
        TIMER_VALUE 4                                          ;#4827: 04
        TIMER_VALUE 4                                          ;#4828: 04
        TIMER_VALUE 5                                          ;#4829: 05
        TIMER_VALUE 6                                          ;#482A: 06
        TIMER_VALUE 6                                          ;#482B: 06

INIT_TITLE_BACKGROUND:
        ; Initialize title background tiles for title flow
        call    INIT_ALL_VDP_PLANES                            ;#482C: CD 23 58
        LOAD_VRAM_ADDRESS de, 1080h                            ;#482F: 11 80 10
        ld      bc,180h                                        ;#4832: 01 80 01
        LOAD_VRAM_COLOR a, COLOR_CYAN, COLOR_TRANSPARENT       ;#4835: 3E 70
        call    FILL_VRAM                                      ;#4837: CD F1 44
        xor     a                                              ;#483A: AF
        ld      (VDP_TEMP_AREA),a                              ;#483B: 32 0A E0
        LOAD_NAME_TABLE de, 11, 6                              ;#483E: 11 66 39
        ld      bc,13h                                         ;#4841: 01 13 00
        jp      FILL_VRAM                                      ;#4844: C3 F1 44

TITLE_WINDOW_ANIMATION:
        ; Manages title window tile paging and animation
        ld      hl,VDP_TEMP_AREA                               ;#4847: 21 0A E0
        ld      a,(hl)                                         ;#484A: 7E
        inc     (hl)                                           ;#484B: 34
        cp      17h                                            ;#484C: FE 17
        jr      nc,DRAW_FLOATING_KONAMI_COPYRIGHT              ;#484E: 30 1C
        LOAD_NAME_TABLE de, 4, 5                               ;#4850: 11 85 38
        ld      c,a                                            ;#4853: 4F
        add     a,e                                            ;#4854: 83
        ld      e,a                                            ;#4855: 5F
        ld      a,c                                            ;#4856: 79
        add     a,a                                            ;#4857: 87
        add     a,0B2h                                         ;#4858: C6 B2
        ld      c,a                                            ;#485A: 4F
        ld      b,3                                            ;#485B: 06 03
        xor     a                                              ;#485D: AF
TITLE_WINDOW_ANIMATION_LOOP:
        ; Loop writing title window tiles to VRAM
        call    WRITE_VRAM_BYTE                                ;#485E: CD B3 48
        ld      a,20h                                          ;#4861: 3E 20
        call    ADD_DE_A                                       ;#4863: CD D6 48
        ld      a,c                                            ;#4866: 79
        inc     c                                              ;#4867: 0C
        djnz    TITLE_WINDOW_ANIMATION_LOOP                    ;#4868: 10 F4
        scf                                                    ;#486A: 37
        ret                                                    ;#486B: C9

DRAW_FLOATING_KONAMI_COPYRIGHT:
        ; Loop updating opening animation
        push    af                                             ;#486C: F5
        ld      hl,KONAMI_COPYRIGHT_TEXT                       ;#486D: 21 74 57
        call    WRITE_VRAM_STREAM                              ;#4870: CD 90 45
        pop     af                                             ;#4873: F1
        cp      34h                                            ;#4874: FE 34
        ret     c                                              ;#4876: D8
        or      a                                              ;#4877: B7
        ret                                                    ;#4878: C9

KONAMI_OPENING_ANIMATION:
        ; Updates VRAM row pointer and writes 3 tiles for Konami logo
        ld      hl,(KONAMI_LOGO_ROW_PTR)                       ;#4879: 2A 0E E0
        ld      de,20h                                         ;#487C: 11 20 00
        add     hl,de                                          ;#487F: 19
        ld      (KONAMI_LOGO_ROW_PTR),hl                       ;#4880: 22 0E E0
        ex      de,hl                                          ;#4883: EB
        or      a                                              ;#4884: B7
        LOAD_NAME_TABLE hl, 21, 10                             ;#4885: 21 AA 3A
        sbc     hl,de                                          ;#4888: ED 52
        ex      de,hl                                          ;#488A: EB
        ; Konami logo starts at tile 44h.
        ld      a,44h                                          ;#488B: 3E 44
        ; c = Konami logo is 3 rows height.
        ; b = First line is 3 cols width.
        ld      bc,303h                                        ;#488D: 01 03 03
KONAMI_LOGO_WRITE_DONE:
        ; logo tile write finished
        push    de                                             ;#4890: D5
KONAMI_LOGO_WRITE_LOOP:
        ; Loop writing Konami logo tiles
        call    WRITE_VRAM_BYTE                                ;#4891: CD B3 48
        inc     de                                             ;#4894: 13
        inc     a                                              ;#4895: 3C
        djnz    KONAMI_LOGO_WRITE_LOOP                         ;#4896: 10 F9
        pop     de                                             ;#4898: D1
        ld      hl,20h                                         ;#4899: 21 20 00
        add     hl,de                                          ;#489C: 19
        ex      de,hl                                          ;#489D: EB
        ld      h,a                                            ;#489E: 67
        ; Remaining logo lines are 14 cols width.
        ld      a,0Eh                                          ;#489F: 3E 0E
        sub     c                                              ;#48A1: 91
        ld      b,a                                            ;#48A2: 47
        ld      a,h                                            ;#48A3: 7C
        dec     c                                              ;#48A4: 0D
        jr      nz,KONAMI_LOGO_WRITE_DONE                      ;#48A5: 20 E9
        ld      bc,0Ch                                         ;#48A7: 01 0C 00
        xor     a                                              ;#48AA: AF
        call    FILL_VRAM                                      ;#48AB: CD F1 44
        ld      hl,VDP_TEMP_AREA                               ;#48AE: 21 0A E0
        dec     (hl)                                           ;#48B1: 35
        ret                                                    ;#48B2: C9

WRITE_VRAM_BYTE:
        ; Writes single byte in A to VRAM at current address
        push    af                                             ;#48B3: F5
        set     6,d                                            ;#48B4: CB F2
        call    SET_VDP                                        ;#48B6: CD C9 48
        res     6,d                                            ;#48B9: CB B2
        pop     af                                             ;#48BB: F1
        out     (VDP_98),a                                     ;#48BC: D3 98
        ei                                                     ;#48BE: FB
        ret                                                    ;#48BF: C9

READ_VRAM_BYTE:
        ; Reads single byte from VRAM into A
        call    SET_VDP                                        ;#48C0: CD C9 48
        nop                                                    ;#48C3: 00
        nop                                                    ;#48C4: 00
        in      a,(VDP_98)                                     ;#48C5: DB 98
        ei                                                     ;#48C7: FB
        ret                                                    ;#48C8: C9

SET_VDP:
        ; Set VDP address
        di                                                     ;#48C9: F3
        ld      a,e                                            ;#48CA: 7B
        out     (VDP_99),a                                     ;#48CB: D3 99
        ld      a,d                                            ;#48CD: 7A
        out     (VDP_99),a                                     ;#48CE: D3 99
        ret                                                    ;#48D0: C9

ADD_HL_A:
        ; HL = HL + A
        add     a,l                                            ;#48D1: 85
        ld      l,a                                            ;#48D2: 6F
        ret     nc                                             ;#48D3: D0
        inc     h                                              ;#48D4: 24
        ret                                                    ;#48D5: C9

ADD_DE_A:
        ; DE = DE + A
        add     a,e                                            ;#48D6: 83
        ld      e,a                                            ;#48D7: 5F
        ret     nc                                             ;#48D8: D0
        inc     d                                              ;#48D9: 14
        ret                                                    ;#48DA: C9

GAME_STATE_15_HANDLER:
        ; Game state 15: Antarctic map animation
        ld      a,(GAME_SUBSTATE)                              ;#48DB: 3A 01 E0
        call    JUMP_TABLE_DISPATCHER                          ;#48DE: CD 98 40
        dw      MAP_INIT                                       ;#48E1: EF 48
        dw      MAP_DRAW_HORIZONTAL_BORDER_TOP                 ;#48E3: 09 49
        dw      MAP_DRAW_TILES                                 ;#48E5: 10 49
        dw      MAP_DRAW_HORIZONTAL_BORDER_BOTTOM              ;#48E7: 47 49
        dw      MAP_PATH_INIT                                  ;#48E9: 61 49
        dw      MAP_UPDATE_PATH                                ;#48EB: 6E 49
        dw      MAP_EXIT_WAIT                                  ;#48ED: C5 49

MAP_INIT:
        ; Substate 0: Initialize map pointers and background fill
        ld      hl,MAP_DRAW_COMMANDS_TABLE                     ;#48EF: 21 D2 49
        ld      (MAP_DATA_PTR),hl                              ;#48F2: 22 F2 E0
        LOAD_NAME_TABLE hl, 4, 4                               ;#48F5: 21 84 38
        ld      (MAP_VRAM_ADDR),hl                             ;#48F8: 22 F0 E0
        LOAD_VRAM_ADDRESS de, 1080h                            ;#48FB: 11 80 10
        ld      bc,180h                                        ;#48FE: 01 80 01
        LOAD_VRAM_COLOR a, COLOR_WHITE, COLOR_DARK_BLUE        ;#4901: 3E F4
        call    FILL_VRAM                                      ;#4903: CD F1 44
        jp      INCREMENT_SUBSTATE                             ;#4906: C3 01 44

MAP_DRAW_HORIZONTAL_BORDER_TOP:
        ; Substate 1: Draw first part of UI borders
        LOAD_NAME_TABLE de, 4, 3                               ;#4909: 11 83 38
        ld      a,92h                                          ;#490C: 3E 92
        jr      MAP_DRAW_HORIZONTAL_BORDER_DIRECT              ;#490E: 18 3C

MAP_DRAW_TILES:
        ; Substate 2: Incremental map rendering from data stream
        ld      a,(FRAME_COUNTER)                              ;#4910: 3A 03 E0
        rra                                                    ;#4913: 1F
        ret     c                                              ;#4914: D8
        ld      hl,(MAP_VRAM_ADDR)                             ;#4915: 2A F0 E0
        ld      a,20h                                          ;#4918: 3E 20
        call    ADD_HL_A                                       ;#491A: CD D1 48
        ld      (MAP_VRAM_ADDR),hl                             ;#491D: 22 F0 E0
        ex      de,hl                                          ;#4920: EB
        push    de                                             ;#4921: D5
        ld      a,0Ah                                          ;#4922: 3E 0A
        ld      bc,18h                                         ;#4924: 01 18 00
        call    FILL_VRAM                                      ;#4927: CD F1 44
        pop     de                                             ;#492A: D1
        inc     de                                             ;#492B: 13
        ld      a,4                                            ;#492C: 3E 04
        ld      c,16h                                          ;#492E: 0E 16
        call    FILL_VRAM                                      ;#4930: CD F1 44
        ld      hl,(MAP_DATA_PTR)                              ;#4933: 2A F2 E0
        ld      a,(hl)                                         ;#4936: 7E
        inc     hl                                             ;#4937: 23
        or      a                                              ;#4938: B7
        jp      z,INCREMENT_SUBSTATE                           ;#4939: CA 01 44
        ld      e,a                                            ;#493C: 5F
        inc     a                                              ;#493D: 3C
        jr      z,MAP_DRAW_UPDATE_PTR                          ;#493E: 28 03
        call    WRITE_VRAM_STREAM_WITH_OFFSET                  ;#4940: CD 94 45
MAP_DRAW_UPDATE_PTR:
        ; Save map data pointer
        ld      (MAP_DATA_PTR),hl                              ;#4943: 22 F2 E0
        ret                                                    ;#4946: C9

MAP_DRAW_HORIZONTAL_BORDER_BOTTOM:
        ; Substate 3: Draw second part of UI borders
        LOAD_NAME_TABLE de, 21, 3                              ;#4947: 11 A3 3A
        ld      a,91h                                          ;#494A: 3E 91
MAP_DRAW_HORIZONTAL_BORDER_DIRECT:
        ; Shared horizontal border drawing routine for map UI
        call    WRITE_VRAM_BYTE                                ;#494C: CD B3 48
        inc     de                                             ;#494F: 13
        ld      bc,18h                                         ;#4950: 01 18 00
        add     a,4                                            ;#4953: C6 04
        push    af                                             ;#4955: F5
        call    FILL_VRAM                                      ;#4956: CD F1 44
        pop     af                                             ;#4959: F1
        sub     2                                              ;#495A: D6 02
        out     (VDP_98),a                                     ;#495C: D3 98
        jp      INCREMENT_SUBSTATE                             ;#495E: C3 01 44

MAP_PATH_INIT:
        ; Substate 4: Initialize path pointers and step index
        LOAD_NAME_TABLE hl, 8, 19                              ;#4961: 21 13 39
        ld      (PATH_VRAM_PTR),hl                             ;#4964: 22 F4 E0
        xor     a                                              ;#4967: AF
        ld      (MAP_STEP_INDEX),a                             ;#4968: 32 F6 E0
        jp      INCREMENT_SUBSTATE                             ;#496B: C3 01 44

MAP_UPDATE_PATH:
        ; Move penguin icon along path tracking indices
        ld      a,(FRAME_COUNTER)                              ;#496E: 3A 03 E0
        rra                                                    ;#4971: 1F
        ret     c                                              ;#4972: D8
        ld      hl,MAP_STEP_INDEX                              ;#4973: 21 F6 E0
        ld      a,(hl)                                         ;#4976: 7E
        ld      de,MAP_PATH_DATA                               ;#4977: 11 81 4A
        call    ADD_DE_A                                       ;#497A: CD D6 48
        ld      a,(de)                                         ;#497D: 1A
        ld      (VRAM_UPDATE_BUFFER),a                         ;#497E: 32 D0 E0
        cp      20h                                            ;#4981: FE 20
        jp      z,INCREMENT_SUBSTATE                           ;#4983: CA 01 44
        inc     (hl)                                           ;#4986: 34
        ld      c,97h                                          ;#4987: 0E 97
        ld      a,(MAP_PROGRESS_LIMIT)                         ;#4989: 3A E7 E0
        cp      (hl)                                           ;#498C: BE
        jr      c,MAP_UPDATE_PATH_PROCESS                      ;#498D: 38 02
        ld      c,0A4h                                         ;#498F: 0E A4
MAP_UPDATE_PATH_PROCESS:
        ; Process penguin path movement
        ld      hl,VRAM_UPDATE_BUFFER                          ;#4991: 21 D0 E0
        xor     a                                              ;#4994: AF
        rrd                                                    ;#4995: ED 67
        ld      b,a                                            ;#4997: 47
        ld      a,(hl)                                         ;#4998: 7E
        ld      hl,MAP_PATH_MOVEMENT_TABLE                     ;#4999: 21 B2 49
        call    ADD_HL_A                                       ;#499C: CD D1 48
        ld      de,(PATH_VRAM_PTR)                             ;#499F: ED 5B F4 E0
        call    JUMP_TO_HL                                     ;#49A3: CD B1 49
        ld      (PATH_VRAM_PTR),de                             ;#49A6: ED 53 F4 E0
        ld      a,b                                            ;#49AA: 78
        add     a,c                                            ;#49AB: 81
        call    WRITE_VRAM_BYTE                                ;#49AC: CD B3 48
        scf                                                    ;#49AF: 37
        ret                                                    ;#49B0: C9

JUMP_TO_HL:
        ; Generic jump via HL helper
        jp      (hl)                                           ;#49B1: E9

MAP_PATH_MOVEMENT_TABLE:
        ; Table of VRAM update handlers for penguin path icon
        ; Indexed-jump dispatch table — NOT unreachable code.
        ; Reached via MAP_PATH_MOVEMENT_TABLE + (high-nibble * 4) of
        ; the MAP_PATH_DATA step byte.
        ld      a,-20h ; UP                                    ;#49B2: 3E E0
        jr      MAP_MOVE_ADJUST_HIGH_BYTE                      ;#49B4: 18 0A
        ld      a,1 ; RIGHT                                    ;#49B6: 3E 01
        jr      MAP_MOVE_ADD_OFFSET                            ;#49B8: 18 07
        ld      a,20h ; DOWN                                   ;#49BA: 3E 20
        jr      MAP_MOVE_ADD_OFFSET                            ;#49BC: 18 03
        ld      a,-1 ; LEFT                                    ;#49BE: 3E FF

MAP_MOVE_ADJUST_HIGH_BYTE:
        ; Adjust high byte for negative offset
        dec     d                                              ;#49C0: 15
MAP_MOVE_ADD_OFFSET:
        ; Add offset to VRAM pointer
        call    ADD_DE_A                                       ;#49C1: CD D6 48
        ret                                                    ;#49C4: C9

MAP_EXIT_WAIT:
        ; Substate 6: Transition delay before state 9
        ld      hl,WAIT_TIMER                                  ;#49C5: 21 04 E0
        dec     (hl)                                           ;#49C8: 35
        ret     nz                                             ;#49C9: C0
        ld      a,ID_STATE_9                                   ;#49CA: 3E 09
        ld      (GAME_STATE),a                                 ;#49CC: 32 00 E0
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#49CF: C3 EE 43

MAP_DRAW_COMMANDS_TABLE:
        ; Data block for map drawing VRAM commands
        ; Format: FORMAT_MAP_DRAW_COMMANDS
        ; - Script for drawing the world map screen.
        ; - Each entry: [offset, byte stream..., 0FFh]; offset advances row VRAM ptr (DE).
        ; - Bytes in the stream are written sequentially to VRAM, advancing DE each byte.
        ; - 0FFh terminates the current entry; 00h terminates the whole table.
        db      0FFh                                           ;#49D2: FF
        MAP_COMMANDS 0CEh, "5E5F6061", 0FFh                    ;#49D3: CE 5E 5F 60 61 FF
        MAP_COMMANDS 0EDh, "620F0F0F0F0F636465", 0FFh          ;#49D9: ED 62 0F 0F 0F 0F 0F 63 64 65 FF
        MAP_COMMANDS 8, "6604040404670F0F0F0F0F0F0F68", 0FFh   ;#49E4: 08 66 04 04 04 04 67 0F 0F 0F 0F 0F 0F 0F 68 FF
        MAP_COMMANDS 28h, "696A6488897E0F0F0F0F0F0F0F6B", 0FFh  ;#49F4: 28 69 6A 64 88 89 7E 0F 0F 0F 0F 0F 0F 0F 6B FF
        MAP_COMMANDS 49h, "6C6D7F07800F0F0F0F0F0F0F61", 0FFh   ;#4A04: 49 6C 6D 7F 07 80 0F 0F 0F 0F 0F 0F 0F 61 FF
        MAP_COMMANDS 6Ah, "6781820F0F0F8D8E8F900F0F6E", 0FFh   ;#4A13: 6A 67 81 82 0F 0F 0F 8D 8E 8F 90 0F 0F 6E FF
        MAP_COMMANDS 8Ah, "6F0F0F0F0F0F8C0F0F0F0F0F70", 0FFh   ;#4A22: 8A 6F 0F 0F 0F 0F 0F 8C 0F 0F 0F 0F 0F 70 FF
        MAP_COMMANDS 0ABh, "710F0F83840F0F0F0F0F0F72", 0FFh    ;#4A31: AB 71 0F 0F 83 84 0F 0F 0F 0F 0F 0F 72 FF
        MAP_COMMANDS 0CBh, "730F0F8507860F0F0F0F0F74", 0FFh    ;#4A3F: CB 73 0F 0F 85 07 86 0F 0F 0F 0F 0F 74 FF
        MAP_COMMANDS 0EBh, "6975768A8B870F0F0F0F77", 0FFh      ;#4A4D: EB 69 75 76 8A 8B 87 0F 0F 0F 0F 77 FF
        MAP_COMMANDS 10h, "780F0F0F0F79", 0FFh                 ;#4A5A: 10 78 0F 0F 0F 0F 79 FF
        MAP_COMMANDS 30h, "7A757B7C7D", 0FFh                   ;#4A62: 30 7A 75 7B 7C 7D FF
        db      0FFh                                           ;#4A69: FF
        MAP_COMMANDS 67h, "212E34213223342923210404041A1B1C1D1E1F", 0FFh  ;#4A6A: 67 21 2E 34 21 32 23 34 29 23 21 04 04 04 1A 1B 1C 1D 1E 1F FF
        db      0FFh                                           ;#4A7F: FF
        db      00h                                            ;#4A80: 00

MAP_PATH_DATA:
        ; Data block defining the penguin route coordinates and tile steps
        ; Format: FORMAT_MAP_PATH_DATA
        ; - Each byte is MAP_DIR_* (high nibble 0/4/8/Ch = UP/RIGHT/DOWN/LEFT) OR'd with
        ; a tile index (low nibble 0..Fh).
        ; - MAP_UPDATE_PATH consumes one byte per odd frame: the high nibble indexes
        ; MAP_PATH_MOVEMENT_TABLE to move PATH_VRAM_PTR, and the low nibble is added
        ; to a tile base (97h before MAP_PROGRESS_LIMIT, A4h after) for the VRAM write.
        ; - 20h terminates the path (MAP_UPDATE_PATH leaves the substate).
        MAP_STEP MAP_DIR_RIGHT, 2                              ;#4A81: 42
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4A82: 82
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4A83: 82
        MAP_STEP MAP_DIR_DOWN, 5                               ;#4A84: 85
        MAP_STEP MAP_DIR_RIGHT, 0Bh                            ;#4A85: 4B
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4A86: 82
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4A87: 82
        MAP_STEP MAP_DIR_DOWN, 0Bh                             ;#4A88: 8B
        MAP_STEP MAP_DIR_LEFT, 4                               ;#4A89: C4
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4A8A: 82
        MAP_STEP MAP_DIR_DOWN, 0Bh                             ;#4A8B: 8B
        MAP_STEP MAP_DIR_LEFT, 4                               ;#4A8C: C4
        MAP_STEP MAP_DIR_LEFT, 4                               ;#4A8D: C4
        MAP_STEP MAP_DIR_LEFT, 0                               ;#4A8E: C0
        MAP_STEP MAP_DIR_UP, 0Bh                               ;#4A8F: 0B
        MAP_STEP MAP_DIR_UP, 2                                 ;#4A90: 02
        MAP_STEP MAP_DIR_UP, 2                                 ;#4A91: 02
        MAP_STEP MAP_DIR_LEFT, 5                               ;#4A92: C5
        MAP_STEP MAP_DIR_UP, 0Ch                               ;#4A93: 0C
        MAP_STEP MAP_DIR_LEFT, 5                               ;#4A94: C5
        MAP_STEP MAP_DIR_LEFT, 5                               ;#4A95: C5
        MAP_STEP MAP_DIR_LEFT, 6                               ;#4A96: C6
        MAP_STEP MAP_DIR_DOWN, 6                               ;#4A97: 86
        MAP_STEP MAP_DIR_DOWN, 7                               ;#4A98: 87
        MAP_STEP MAP_DIR_LEFT, 5                               ;#4A99: C5
        MAP_STEP MAP_DIR_UP, 2                                 ;#4A9A: 02
        MAP_STEP MAP_DIR_UP, 0Ch                               ;#4A9B: 0C
        MAP_STEP MAP_DIR_UP, 0Ah                               ;#4A9C: 0A
        MAP_STEP MAP_DIR_UP, 9                                 ;#4A9D: 09
        MAP_STEP MAP_DIR_RIGHT, 8                              ;#4A9E: 48
        MAP_STEP MAP_DIR_RIGHT, 3                              ;#4A9F: 43
        MAP_STEP MAP_DIR_UP, 0Ch                               ;#4AA0: 0C
        MAP_STEP MAP_DIR_UP, 0Ch                               ;#4AA1: 0C
        MAP_STEP MAP_DIR_UP, 1                                 ;#4AA2: 01
        MAP_STEP MAP_DIR_RIGHT, 5                              ;#4AA3: 45
        MAP_STEP MAP_DIR_RIGHT, 5                              ;#4AA4: 45
        MAP_STEP MAP_DIR_RIGHT, 5                              ;#4AA5: 45
        MAP_STEP MAP_DIR_RIGHT, 2                              ;#4AA6: 42
        MAP_STEP MAP_DIR_DOWN, 5                               ;#4AA7: 85
        MAP_STEP MAP_DIR_RIGHT, 7                              ;#4AA8: 47
        MAP_END                                                ;#4AA9: 20

STAGE_DISTANCE_TABLE:
        ; Data table for stage distances and difficulty settings
        ; Format: FORMAT_STAGE_DISTANCE_TABLE
        ; - 10 entries. Each STAGE_ENTRY writes dist_hi (byte 0), map_offset (byte 1),
        ; and initial timer value (bytes 2-3, little-endian).
        ; - Consumed by stage-init code to set the total distance (dist_hi << 8),
        ; the starting offset into MAP_PATH_DATA, and the initial stage timer.
        STAGE_ENTRY 1200h, 0, 90h                              ;#4AAA: 12 00 90 00
        STAGE_ENTRY 1500h, 5, 100h                             ;#4AAE: 15 05 00 01
        STAGE_ENTRY 1200h, 8, 90h                              ;#4AB2: 12 08 90 00
        STAGE_ENTRY 1500h, 0Bh, 100h                           ;#4AB6: 15 0B 00 01
        STAGE_ENTRY 1700h, 0Eh, 120h                           ;#4ABA: 17 0E 20 01
        STAGE_ENTRY 1100h, 13h, 80h                            ;#4ABE: 11 13 80 00
        STAGE_ENTRY 1200h, 17h, 80h                            ;#4AC2: 12 17 80 00
        STAGE_ENTRY 1200h, 1Bh, 80h                            ;#4AC6: 12 1B 80 00
        STAGE_ENTRY 500h, 20h, 40h                             ;#4ACA: 05 20 40 00
        STAGE_ENTRY 2600h, 21h, 165h                           ;#4ACE: 26 21 65 01

INIT_GAMEPLAY_VARS:
        ; Initialize gameplay variables and RAM (clears E0F0-E220, sets timers)
        ld      hl,MAP_VRAM_ADDR                               ;#4AD2: 21 F0 E0
        ld      de,MAP_VRAM_ADDR+1                             ;#4AD5: 11 F1 E0
        ld      bc,130h                                        ;#4AD8: 01 30 01
        ld      (hl),0                                         ;#4ADB: 36 00
        ldir                                                   ;#4ADD: ED B0
        ld      a,10h                                          ;#4ADF: 3E 10
        ld      h,a                                            ;#4AE1: 67
        ld      l,a                                            ;#4AE2: 6F
        ld      (PENGUIN_SPEED),hl                             ;#4AE3: 22 00 E1
        ld      (STAGE_TIMER_VAL),a                            ;#4AE6: 32 10 E1
        ld      a,8                                            ;#4AE9: 3E 08
        ld      (DEMO_PLAY_MASK_TIMER),a                       ;#4AEB: 32 49 E1
        ld      a,5                                            ;#4AEE: 3E 05
        ld      (DISTANCE_TICK_TIMER),a                        ;#4AF0: 32 E9 E0
        ld      hl,3030h                                       ;#4AF3: 21 30 30
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4AF6: 3A E0 E0
        rra                                                    ;#4AF9: 1F
        jr      nc,INIT_STAGE_GRAPHICS_SEQ                     ;#4AFA: 30 03
        ld      hl,3434h                                       ;#4AFC: 21 34 34
INIT_STAGE_GRAPHICS_SEQ:
        ; Init stage graphics sequence
        ld      (ITEM_TICK_PERIOD),hl                          ;#4AFF: 22 0E E1
        ld      a,1                                            ;#4B02: 3E 01
        ld      (SELECT_CONTROLLER_DISABLED),a                 ;#4B04: 32 3B E1
        call    GFX_INIT_BANK1                                 ;#4B07: CD 9B 5D
        call    GFX_INIT_BANK2                                 ;#4B0A: CD 38 62
        call    LOAD_MAIN_SPRITE_PATTERNS                      ;#4B0D: CD FF 66
        call    INIT_SPRITES_FROM_STREAM                       ;#4B10: CD 6B 66
        call    INIT_STAGE                                     ;#4B13: CD 15 50
        xor     a                                              ;#4B16: AF
        ld      (SELECT_CONTROLLER_DISABLED),a                 ;#4B17: 32 3B E1
        ret                                                    ;#4B1A: C9

MAIN_GAME_ENGINE:
        ; Core game engine loop
        call    CALC_HUD_SPEED_BAR                             ;#4B1B: CD 11 77
        call    SYNC_SPRITE_ATTRIBUTES_PARTIAL                 ;#4B1E: CD 12 76
        ld      a,(PENGUIN_FALL_TIMER)                         ;#4B21: 3A 40 E1
        or      a                                              ;#4B24: B7
        jp      nz,HANDLE_PENGUIN_FALL                         ;#4B25: C2 65 4F
        ld      a,(PENGUIN_STUN_TIMER)                         ;#4B28: 3A 42 E1
        or      a                                              ;#4B2B: B7
        jp      nz,HANDLE_PENGUIN_STUN_ANIMATION               ;#4B2C: C2 3A 4E
        call    PROCESS_PENGUIN_INPUT_AND_MOVE                 ;#4B2F: CD 87 76
        call    HANDLE_PENGUIN_MOVEMENT                        ;#4B32: CD 7D 4B
        call    HANDLE_PENGUIN_DRIFT                           ;#4B35: CD 62 53
        call    HANDLE_COLLISION_FISH                          ;#4B38: CD A3 4D
        call    HANDLE_COLLISION_SEAL                          ;#4B3B: CD E0 4D
        ld      a,(PENGUIN_FALL_TIMER)                         ;#4B3E: 3A 40 E1
        or      a                                              ;#4B41: B7
        ret     nz                                             ;#4B42: C0
        call    PROCESS_SCENE_TIMER                            ;#4B43: CD 4B 51
        call    UPDATE_STATION_FRAME                           ;#4B46: CD C2 74
        call    UPDATE_STAGE_DISTANCE                          ;#4B49: CD C5 46
        call    UPDATE_STAGE_SEQUENCE                          ;#4B4C: CD 2E 47
        call    UPDATE_ITEMS                                   ;#4B4F: CD D3 51
        jp      HANDLE_DEMO_PLAY_MASKING                       ;#4B52: C3 4C 77

PENGUIN_ANIM_TABLE:
        ; Table of sprite pattern indices for penguin
        ; Format: FORMAT_PENGUIN_PATTERN
        ; - Layout: [Top-Left, Bottom-Left, Top-Right, Bottom-Right].
        ; - Used for the main penguin animations (waddling, jumping, etc.).
        PENGUIN_PATTERN 0, 4, 8, 0Ch                           ;#4B55: 00 04 08 0C
        PENGUIN_PATTERN 10h, 14h, 18h, 1Ch                     ;#4B59: 10 14 18 1C
        PENGUIN_PATTERN 20h, 24h, 28h, 2Ch                     ;#4B5D: 20 24 28 2C
        PENGUIN_PATTERN 0, 4, 30h, 34h                         ;#4B61: 00 04 30 34
        PENGUIN_PATTERN 38h, 3Ch, 40h, 44h                     ;#4B65: 38 3C 40 44
        PENGUIN_PATTERN 60h, 64h, 68h, 6Ch                     ;#4B69: 60 64 68 6C
        PENGUIN_PATTERN 20h, 48h, 4Ch, 50h                     ;#4B6D: 20 48 4C 50
        PENGUIN_PATTERN 54h, 14h, 58h, 5Ch                     ;#4B71: 54 14 58 5C
        PENGUIN_PATTERN 10h, 0A8h, 18h, 0ACh                   ;#4B75: 10 A8 18 AC
        PENGUIN_PATTERN 0B0h, 24h, 0B4h, 2Ch                   ;#4B79: B0 24 B4 2C

HANDLE_PENGUIN_MOVEMENT:
        ; Handles joystick input and position updates
        ld      hl,PENGUIN_INPUT_LOCK_TIMER                    ;#4B7D: 21 F9 E0
        ld      a,(hl)                                         ;#4B80: 7E
        or      a                                              ;#4B81: B7
        jp      nz,UPDATE_THROTTLED_ANIMATION                  ;#4B82: C2 E9 4B
        call    READ_INPUT_EDGE                                ;#4B85: CD 06 46
        jp      nz,INIT_JUMP                                   ;#4B88: C2 D5 4B
        ld      a,b                                            ;#4B8B: 78
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4B8C: ED 5B 78 E0
        call    UPDATE_PENGUIN_POSITION                        ;#4B90: CD 5D 4C
SWAP_AND_UPDATE_PENGUIN_COORDS:
        ; Swap registers and update penguin coordinates
        ex      de,hl                                          ;#4B93: EB
UPDATE_PENGUIN_COORDS:
        ; Update penguin X/Y and secondary sprite positions
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#4B94: CD BD 4B
SYNC_PENGUIN_SPRITES_TO_VRAM:
        ; Prepare and upload penguin sprite attributes to VRAM
        ld      hl,SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y        ;#4B97: 21 78 E0
        LOAD_SPRITE_ATTR de, 10, 0                             ;#4B9A: 11 28 3B
        ld      bc,10h                                         ;#4B9D: 01 10 00
        call    COPY_RAM_TO_VRAM                               ;#4BA0: CD DE 44
        jp      UPDATE_GOAL_BOB_ANIM                           ;#4BA3: C3 BA 4C

UPDATE_PENGUIN_SPRITE_PATTERNS:
        ; Updates the 4 pattern indices of the 32x32 penguin (SPRITE_PENGUIN..+0Ch)
        exx                                                    ;#4BA6: D9
        ld      hl,PENGUIN_ANIM_TABLE                          ;#4BA7: 21 55 4B
        call    ADD_HL_A                                       ;#4BAA: CD D1 48
        ld      de,SAT_MIRROR + SPRITE_PENGUIN + ATTR_PATT     ;#4BAD: 11 7A E0
        ld      b,4                                            ;#4BB0: 06 04
UPDATE_PENGUIN_PATT_LOOP:
        ; Loop to copy 4 pattern indices
        ld      a,(hl)                                         ;#4BB2: 7E
        ld      (de),a                                         ;#4BB3: 12
        ld      a,4                                            ;#4BB4: 3E 04
        add     a,e                                            ;#4BB6: 83
        ld      e,a                                            ;#4BB7: 5F
        inc     hl                                             ;#4BB8: 23
        djnz    UPDATE_PENGUIN_PATT_LOOP                       ;#4BB9: 10 F7
        exx                                                    ;#4BBB: D9
        ret                                                    ;#4BBC: C9

UPDATE_PENGUIN_MULTI_SPRITE_COORDS:
        ; Updates coordinates for 32x32 penguin (SAT slots 10-13, SPRITE_PENGUIN..+0Ch)
        ld      d,h                                            ;#4BBD: 54
        ld      (SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y),hl      ;#4BBE: 22 78 E0
        ld      a,h                                            ;#4BC1: 7C
        add     a,10h                                          ;#4BC2: C6 10
        ld      h,a                                            ;#4BC4: 67
        ld      (SAT_MIRROR + SPRITE_PENGUIN + 4 + ATTR_Y),hl  ;#4BC5: 22 7C E0
        ld      a,l                                            ;#4BC8: 7D
        add     a,10h                                          ;#4BC9: C6 10
        ld      l,a                                            ;#4BCB: 6F
        ld      e,a                                            ;#4BCC: 5F
        ld      (SAT_MIRROR + SPRITE_PENGUIN + 8 + ATTR_Y),de  ;#4BCD: ED 53 80 E0
        ld      (SAT_MIRROR + SPRITE_PENGUIN + 0Ch + ATTR_Y),hl ;#4BD1: 22 84 E0
        ret                                                    ;#4BD4: C9

INIT_JUMP:
        ; Initialize penguin jump sequence and sound
        ld      a,ID_SOUND_JUMP                                ;#4BD5: 3E 02
        call    PLAY_SOUND_SAFE                                ;#4BD7: CD 70 79
        ld      a,b                                            ;#4BDA: 78
        and     0Ch                                            ;#4BDB: E6 0C
        jr      z,SET_JUMP_DIR                                 ;#4BDD: 28 05
        ld      a,(PENGUIN_MOVE_STATE)                         ;#4BDF: 3A FA E0
        and     3                                              ;#4BE2: E6 03
SET_JUMP_DIR:
        ; Set jump direction based on move state
        ld      (PENGUIN_JUMP_STATE),a                         ;#4BE4: 32 FB E0
        jr      UPDATE_ANIMATION_STEP                          ;#4BE7: 18 06

UPDATE_THROTTLED_ANIMATION:
        ; Updates animation every 4th frame
        ld      a,(FRAME_COUNTER)                              ;#4BE9: 3A 03 E0
        and     3                                              ;#4BEC: E6 03
        ret     nz                                             ;#4BEE: C0
UPDATE_ANIMATION_STEP:
        ; Increments animation frame and updates patterns/position
        ld      a,(hl)                                         ;#4BEF: 7E
        inc     (hl)                                           ;#4BF0: 34
        cp      0Bh                                            ;#4BF1: FE 0B
        jr      nz,CALC_ANIM_FRAME_INDEX                       ;#4BF3: 20 02
        ld      (hl),0                                         ;#4BF5: 36 00
CALC_ANIM_FRAME_INDEX:
        ; Calculate animation frame index
        push    af                                             ;#4BF7: F5
        ld      c,0                                            ;#4BF8: 0E 00
        cp      0Bh                                            ;#4BFA: FE 0B
        jr      z,SET_ANIM_PATTERN_INDEX                       ;#4BFC: 28 07
        ld      c,10h                                          ;#4BFE: 0E 10
        rra                                                    ;#4C00: 1F
        jr      c,SET_ANIM_PATTERN_INDEX                       ;#4C01: 38 02
        ld      c,0Ch                                          ;#4C03: 0E 0C
SET_ANIM_PATTERN_INDEX:
        ; Set calculated pattern index
        ld      a,c                                            ;#4C05: 79
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4C06: CD A6 4B
        pop     af                                             ;#4C09: F1
        ld      hl,PENGUIN_JUMP_Y_OFFSETS                      ;#4C0A: 21 51 4C
        call    ADD_HL_A                                       ;#4C0D: CD D1 48
        ld      a,(hl)                                         ;#4C10: 7E
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4C11: ED 5B 78 E0
        add     a,e                                            ;#4C15: 83
        ld      e,a                                            ;#4C16: 5F
        ld      hl,PENGUIN_JUMP_STATE                          ;#4C17: 21 FB E0
        ld      a,(hl)                                         ;#4C1A: 7E
        dec     a                                              ;#4C1B: 3D
        jr      z,JUMP_MOVE_LEFT_STEP                          ;#4C1C: 28 23
        dec     a                                              ;#4C1E: 3D
        jr      z,JUMP_MOVE_RIGHT_STEP                         ;#4C1F: 28 28
UPDATE_JUMP_SPRITES:
        ; Update sprite coordinates after jump
        ex      de,hl                                          ;#4C21: EB
        call    UPDATE_PENGUIN_COORDS                          ;#4C22: CD 94 4B
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4C25: 3A F9 E0
        or      a                                              ;#4C28: B7
        ret     nz                                             ;#4C29: C0
        call    CHECK_ITEM_COLLISIONS                          ;#4C2A: CD 1A 4D
        ld      a,(PENGUIN_FALL_TIMER)                         ;#4C2D: 3A 40 E1
        ld      hl,PENGUIN_STUN_TIMER                          ;#4C30: 21 42 E1
        add     a,(hl)                                         ;#4C33: 86
        ret     nz                                             ;#4C34: C0
        ld      hl,COLLISION_PROCESSED_FLAG                    ;#4C35: 21 32 E1
        cp      (hl)                                           ;#4C38: BE
        ret     z                                              ;#4C39: C8
        ld      (hl),a                                         ;#4C3A: 77
        ld      de,30h                                         ;#4C3B: 11 30 00
        jp      ADD_SCORE                                      ;#4C3E: C3 16 46

JUMP_MOVE_LEFT_STEP:
        ; Horizontal shift left during jump
        call    MOVE_PENGUIN_LEFT                              ;#4C41: CD 6D 4C
        call    MOVE_PENGUIN_LEFT                              ;#4C44: CD 6D 4C
        jr      UPDATE_JUMP_SPRITES                            ;#4C47: 18 D8

JUMP_MOVE_RIGHT_STEP:
        ; Horizontal shift right during jump
        call    MOVE_PENGUIN_RIGHT                             ;#4C49: CD 8A 4C
        call    MOVE_PENGUIN_RIGHT                             ;#4C4C: CD 8A 4C
        jr      UPDATE_JUMP_SPRITES                            ;#4C4F: 18 D0

PENGUIN_JUMP_Y_OFFSETS:
        ; Table of signed Y-offsets for jumping (12 bytes)
        ; Format: FORMAT_JUMP_Y_OFFSETS
        JUMP_Y_OFFSET -4                                       ;#4C51: FC
        JUMP_Y_OFFSET -3                                       ;#4C52: FD
        JUMP_Y_OFFSET -3                                       ;#4C53: FD
        JUMP_Y_OFFSET -2                                       ;#4C54: FE
        JUMP_Y_OFFSET -1                                       ;#4C55: FF
        JUMP_Y_OFFSET -1                                       ;#4C56: FF
        JUMP_Y_OFFSET 1                                        ;#4C57: 01
        JUMP_Y_OFFSET 1                                        ;#4C58: 01
        JUMP_Y_OFFSET 2                                        ;#4C59: 02
        JUMP_Y_OFFSET 3                                        ;#4C5A: 03
        JUMP_Y_OFFSET 3                                        ;#4C5B: 03
        JUMP_Y_OFFSET 4                                        ;#4C5C: 04

UPDATE_PENGUIN_POSITION:
        ; Handle player input and update X coordinate
        and     0Ch                                            ;#4C5D: E6 0C
        ret     z                                              ;#4C5F: C8
        ld      hl,PENGUIN_MOVE_STATE                          ;#4C60: 21 FA E0
        cp      0Ch                                            ;#4C63: FE 0C
        jr      z,HANDLE_SIMULTANEOUS_LR                       ;#4C65: 28 10
        res     7,(hl)                                         ;#4C67: CB BE
        cp      4                                              ;#4C69: FE 04
        jr      nz,MOVE_PENGUIN_RIGHT                          ;#4C6B: 20 1D
MOVE_PENGUIN_LEFT:
        ; Updates X (in D) if > 20, sets direction flags
        ld      a,d                                            ;#4C6D: 7A
        cp      14h                                            ;#4C6E: FE 14
        ret     c                                              ;#4C70: D8
        dec     d                                              ;#4C71: 15
        set     0,(hl)                                         ;#4C72: CB C6
        res     1,(hl)                                         ;#4C74: CB 8E
        ret                                                    ;#4C76: C9

HANDLE_SIMULTANEOUS_LR:
        ; Handle simultaneous Left/Right input
        ld      a,(hl)                                         ;#4C77: 7E
        or      a                                              ;#4C78: B7
        ret     z                                              ;#4C79: C8
        bit     7,a                                            ;#4C7A: CB 7F
        jr      z,MAINTAIN_CURRENT_DIRECTION                   ;#4C7C: 28 06
        bit     0,a                                            ;#4C7E: CB 47
        jr      nz,MOVE_PENGUIN_LEFT                           ;#4C80: 20 EB
        jr      MOVE_PENGUIN_RIGHT                             ;#4C82: 18 06

MAINTAIN_CURRENT_DIRECTION:
        ; Maintain current direction flag
        set     7,(hl)                                         ;#4C84: CB FE
        bit     1,a                                            ;#4C86: CB 4F
        jr      nz,MOVE_PENGUIN_LEFT                           ;#4C88: 20 E3
MOVE_PENGUIN_RIGHT:
        ; Updates X (in D) if < 204, sets direction flags
        ld      a,d                                            ;#4C8A: 7A
        cp      0CCh                                           ;#4C8B: FE CC
        ret     nc                                             ;#4C8D: D0
        set     1,(hl)                                         ;#4C8E: CB CE
        res     0,(hl)                                         ;#4C90: CB 86
        inc     d                                              ;#4C92: 14
        ret                                                    ;#4C93: C9

UPDATE_PENGUIN_ANIMATION:
        ; Update penguin waddling animation
        ld      hl,PENGUIN_INPUT_LOCK_TIMER                    ;#4C94: 21 F9 E0
        ld      a,(PENGUIN_ANIM_HOLD_FLAG)                     ;#4C97: 3A 30 E1
        or      (hl)                                           ;#4C9A: B6
        ret     nz                                             ;#4C9B: C0
        ld      a,(FRAME_COUNTER)                              ;#4C9C: 3A 03 E0
        and     7                                              ;#4C9F: E6 07
        ret     nz                                             ;#4CA1: C0
UPDATE_PENGUIN_SPRITES:
        ; General update for penguin sprites
        ld      hl,PENGUIN_ANIM_FRAME                          ;#4CA2: 21 F8 E0
        inc     (hl)                                           ;#4CA5: 34
        ld      a,(hl)                                         ;#4CA6: 7E
        ld      c,0                                            ;#4CA7: 0E 00
        rra                                                    ;#4CA9: 1F
        jr      nc,APPLY_WALK_ANIM_PATTERN                     ;#4CAA: 30 07
        ld      c,4                                            ;#4CAC: 0E 04
        rra                                                    ;#4CAE: 1F
        jr      nc,APPLY_WALK_ANIM_PATTERN                     ;#4CAF: 30 02
        ld      c,8                                            ;#4CB1: 0E 08
APPLY_WALK_ANIM_PATTERN:
        ; Apply calculated walking animation pattern
        ld      a,c                                            ;#4CB3: 79
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4CB4: CD A6 4B
        jp      SYNC_PENGUIN_SPRITES_TO_VRAM                   ;#4CB7: C3 97 4B

UPDATE_GOAL_BOB_ANIM:
        ; Logic for penguin bobbing animation at the finish line
        ld      hl,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4CBA: 2A 78 E0
        ld      a,l                                            ;#4CBD: 7D
        add     a,1Eh                                          ;#4CBE: C6 1E
        ld      l,a                                            ;#4CC0: 6F
        ld      c,a                                            ;#4CC1: 4F
        ld      a,h                                            ;#4CC2: 7C
        add     a,10h                                          ;#4CC3: C6 10
        ld      b,a                                            ;#4CC5: 47
        ld      de,GOAL_PENGUIN_BOB_Y-1                        ;#4CC6: 11 FA 4C
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4CC9: 3A F9 E0
        or      a                                              ;#4CCC: B7
        jr      nz,APPLY_BOB_OFFSET                            ;#4CCD: 20 09
        ld      de,GOAL_PENGUIN_BOB_Y+9                        ;#4CCF: 11 04 4D
        ld      a,(PENGUIN_EVENT_TIMER)                        ;#4CD2: 3A 43 E1
        or      a                                              ;#4CD5: B7
        jr      z,BUFFER_PENGUIN_ATTRS                         ;#4CD6: 28 10
APPLY_BOB_OFFSET:
        ; Apply bobbing Y-offset to penguin position
        ex      de,hl                                          ;#4CD8: EB
        call    ADD_HL_A                                       ;#4CD9: CD D1 48
        ld      l,(hl)                                         ;#4CDC: 6E
        ld      a,d                                            ;#4CDD: 7A
        add     a,l                                            ;#4CDE: 85
        ld      d,a                                            ;#4CDF: 57
        ld      a,b                                            ;#4CE0: 78
        sub     l                                              ;#4CE1: 95
        ld      b,a                                            ;#4CE2: 47
        ld      e,0AEh                                         ;#4CE3: 1E AE
        ld      c,0AEh                                         ;#4CE5: 0E AE
        ex      de,hl                                          ;#4CE7: EB
BUFFER_PENGUIN_ATTRS:
        ; Store calculated shadow attributes into SAT_MIRROR slots 20-21
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_Y),hl       ;#4CE8: 22 A0 E0
        ; Packed 2-byte write: sprite-21 Y + X. The penguin shadow is rendered as two
        ; sprites side by side — sprite 20 (SPRITE_SHADOW) is the left half, sprite 21
        ; is the right half. Both share the SAT_MIRROR slots E0A0..E0A7.
        ld      (SAT_MIRROR + SPRITE_21 + ATTR_Y),bc           ;#4CEB: ED 43 A4 E0
COPY_PENGUIN_ATTRS_TO_VRAM:
        ; Upload penguin attribute buffer to VRAM
        ld      hl,SAT_MIRROR + SPRITE_SHADOW + ATTR_Y         ;#4CEF: 21 A0 E0
        LOAD_SPRITE_ATTR de, 20, 0                             ;#4CF2: 11 50 3B
        ld      bc,8                                           ;#4CF5: 01 08 00
        jp      COPY_RAM_TO_VRAM                               ;#4CF8: C3 DE 44

GOAL_PENGUIN_BOB_Y:
        ; Penguin bobbing Y-offsets during goal sequence
        ; Format: FORMAT_BOB_Y_OFFSETS
        BOB_Y_OFFSET 1                                         ;#4CFB: 01
        BOB_Y_OFFSET 2                                         ;#4CFC: 02
        BOB_Y_OFFSET 2                                         ;#4CFD: 02
        BOB_Y_OFFSET 3                                         ;#4CFE: 03
        BOB_Y_OFFSET 3                                         ;#4CFF: 03
        BOB_Y_OFFSET 3                                         ;#4D00: 03
        BOB_Y_OFFSET 3                                         ;#4D01: 03
        BOB_Y_OFFSET 3                                         ;#4D02: 03
        BOB_Y_OFFSET 2                                         ;#4D03: 02
        BOB_Y_OFFSET 2                                         ;#4D04: 02
        BOB_Y_OFFSET 1                                         ;#4D05: 01
        BOB_Y_OFFSET 1                                         ;#4D06: 01
        BOB_Y_OFFSET 2                                         ;#4D07: 02
        BOB_Y_OFFSET 2                                         ;#4D08: 02
        BOB_Y_OFFSET 3                                         ;#4D09: 03
        BOB_Y_OFFSET 2                                         ;#4D0A: 02
        BOB_Y_OFFSET 2                                         ;#4D0B: 02
        BOB_Y_OFFSET 1                                         ;#4D0C: 01
        BOB_Y_OFFSET 0                                         ;#4D0D: 00
        BOB_Y_OFFSET 1                                         ;#4D0E: 01
        BOB_Y_OFFSET 2                                         ;#4D0F: 02
        BOB_Y_OFFSET 2                                         ;#4D10: 02
        BOB_Y_OFFSET 2                                         ;#4D11: 02
        BOB_Y_OFFSET 1                                         ;#4D12: 01
        BOB_Y_OFFSET 0                                         ;#4D13: 00
        BOB_Y_OFFSET 1                                         ;#4D14: 01
        BOB_Y_OFFSET 2                                         ;#4D15: 02
        BOB_Y_OFFSET 2                                         ;#4D16: 02
        BOB_Y_OFFSET 2                                         ;#4D17: 02
        BOB_Y_OFFSET 1                                         ;#4D18: 01
        BOB_Y_OFFSET 0                                         ;#4D19: 00

CHECK_ITEM_COLLISIONS:
        ; Walk ITEM_TABLE and check item collisions vs penguin
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4D1A: 3A F9 E0
        or      a                                              ;#4D1D: B7
        ret     nz                                             ;#4D1E: C0
        ld      b,4                                            ;#4D1F: 06 04
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4D21: 3A E0 E0
        cp      5                                              ;#4D24: FE 05
        jr      c,COLLISION_CHECK_LOOP_ENTRY                   ;#4D26: 38 01
        inc     b                                              ;#4D28: 04
COLLISION_CHECK_LOOP_ENTRY:
        ; Setup HL and B for item collision loop
        ld      hl,ITEM_TABLE                                  ;#4D29: 21 12 E1
COLLISION_CHECK_LOOP:
        ; Main item collision loop
        ld      a,(hl)                                         ;#4D2C: 7E
        cp      0Dh                                            ;#4D2D: FE 0D
        ld      a,5                                            ;#4D2F: 3E 05
        jr      nz,COLLISION_NEXT_ENTITY                       ;#4D31: 20 2D
        inc     hl                                             ;#4D33: 23
        ld      c,(hl)                                         ;#4D34: 4E
        inc     hl                                             ;#4D35: 23
        inc     hl                                             ;#4D36: 23
        inc     hl                                             ;#4D37: 23
        ld      e,(hl)                                         ;#4D38: 5E
        inc     hl                                             ;#4D39: 23
        ld      d,(hl)                                         ;#4D3A: 56
        ex      de,hl                                          ;#4D3B: EB
        dec     a                                              ;#4D3C: 3D
        cp      c                                              ;#4D3D: B9
        ld      a,(PENGUIN_X_POS)                              ;#4D3E: 3A 79 E0
        jr      nc,COLLISION_BRANCH_X                          ;#4D41: 30 08
        sub     (hl)                                           ;#4D43: 96
        inc     hl                                             ;#4D44: 23
        cp      (hl)                                           ;#4D45: BE
        jp      c,HANDLE_COLLISION_FLAG                        ;#4D46: DA ED 4F
        jr      COLLISION_SKIP_ENTITY                          ;#4D49: 18 13

COLLISION_BRANCH_X:
        ; Check X-coordinate collision
        ld      c,(hl)                                         ;#4D4B: 4E
        dec     c                                              ;#4D4C: 0D
        jr      z,COLLISION_BRANCH_Y                           ;#4D4D: 28 08
        ld      c,a                                            ;#4D4F: 4F
        sub     (hl)                                           ;#4D50: 96
        inc     hl                                             ;#4D51: 23
        cp      (hl)                                           ;#4D52: BE
        jp      c,HANDLE_COLLISION_FALL                        ;#4D53: DA 1C 4F
        ld      a,c                                            ;#4D56: 79
COLLISION_BRANCH_Y:
        ; Check Y-coordinate collision
        inc     hl                                             ;#4D57: 23
        sub     (hl)                                           ;#4D58: 96
        inc     hl                                             ;#4D59: 23
        cp      (hl)                                           ;#4D5A: BE
        jp      c,HANDLE_COLLISION_HOLE                        ;#4D5B: DA F7 4D
COLLISION_SKIP_ENTITY:
        ; Skip currently checked entity
        ex      de,hl                                          ;#4D5E: EB
        xor     a                                              ;#4D5F: AF
COLLISION_NEXT_ENTITY:
        ; Advance to next entity in table
        inc     a                                              ;#4D60: 3C
        call    ADD_HL_A                                       ;#4D61: CD D1 48
        djnz    COLLISION_CHECK_LOOP                           ;#4D64: 10 C6
        ret                                                    ;#4D66: C9

CHECK_COLLISIONS_WHILE_LOCKED:
        ; Secondary collision check while input is locked (stun/fall/goal-walk)
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4D67: 3A F9 E0
        or      a                                              ;#4D6A: B7
        ret     z                                              ;#4D6B: C8
        ld      b,5                                            ;#4D6C: 06 05
        ld      hl,ITEM_TABLE                                  ;#4D6E: 21 12 E1
LOCKED_COLLISION_LOOP:
        ; Loop body of CHECK_COLLISIONS_WHILE_LOCKED (one ITEM_TABLE slot per iteration)
        ld      a,(hl)                                         ;#4D71: 7E
        inc     hl                                             ;#4D72: 23
        cp      0Dh                                            ;#4D73: FE 0D
        ld      a,5                                            ;#4D75: 3E 05
        jr      nz,LOCKED_COLLISION_NEXT                       ;#4D77: 20 14
        ex      de,hl                                          ;#4D79: EB
        ld      a,(de)                                         ;#4D7A: 1A
        cp      5                                              ;#4D7B: FE 05
        add     a,a                                            ;#4D7D: 87
        ld      hl,LOCKED_COLLISION_TABLE                      ;#4D7E: 21 99 4D
        call    ADD_HL_A                                       ;#4D81: CD D1 48
        ld      a,(PENGUIN_X_POS)                              ;#4D84: 3A 79 E0
        sub     (hl)                                           ;#4D87: 96
        inc     hl                                             ;#4D88: 23
        cp      (hl)                                           ;#4D89: BE
        jr      c,LOCKED_COLLISION_MATCH                       ;#4D8A: 38 07
        ex      de,hl                                          ;#4D8C: EB
LOCKED_COLLISION_NEXT:
        ; Advance to the next ITEM_TABLE slot
        call    ADD_HL_A                                       ;#4D8D: CD D1 48
        djnz    LOCKED_COLLISION_LOOP                          ;#4D90: 10 DF
        ret                                                    ;#4D92: C9

LOCKED_COLLISION_MATCH:
        ; On match, set COLLISION_PROCESSED_FLAG and return
        ld      a,1                                            ;#4D93: 3E 01
        ld      (COLLISION_PROCESSED_FLAG),a                   ;#4D95: 32 32 E1
        ret                                                    ;#4D98: C9

LOCKED_COLLISION_TABLE:
        ; X-range pairs (low_x, width) used by CHECK_COLLISIONS_WHILE_LOCKED
        ; Format: LOCKED_COLLISION
        LOCKED_COLLISION 58h, 30h                              ;#4D99: 58 30
        LOCKED_COLLISION 18h, 30h                              ;#4D9B: 18 30
        LOCKED_COLLISION 98h, 30h                              ;#4D9D: 98 30
        LOCKED_COLLISION 2Ch, 58h                              ;#4D9F: 2C 58
        LOCKED_COLLISION 64h, 58h                              ;#4DA1: 64 58

HANDLE_COLLISION_FISH:
        ; Mid-air fish catch via CURRENT_ENTITY_POINTER: +300, jingle, hides SPRITE_ITEM
        ; Skip processing while stun/fall state is active (early-return gate).
        ld      a,(PENGUIN_STUN_TIMER)                         ;#4DA3: 3A 42 E1
        ld      hl,PENGUIN_FALL_TIMER                          ;#4DA6: 21 40 E1
        add     a,(hl)                                         ;#4DA9: 86
        ret     nz                                             ;#4DAA: C0
        ; Load active obstacle entity pointer and discard hidden entries (Y=E0h).
        ld      de,(CURRENT_ENTITY_POINTER)                    ;#4DAB: ED 5B 88 E1
        ld      a,e                                            ;#4DAF: 7B
        cp      0E0h                                           ;#4DB0: FE E0
        ret     z                                              ;#4DB2: C8
        ; Near-field collision math against penguin sprite coordinates.
        ld      hl,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4DB3: 2A 78 E0
        ; Fast horizontal reject: a = obstacle_x - penguin_x, ret if |X diff| >= 10.
        sub     l                                              ;#4DB6: 95
        ld      e,a                                            ;#4DB7: 5F
        sub     0Ah                                            ;#4DB8: D6 0A
        ret     nc                                             ;#4DBA: D0
        ; Weighted X/Y threshold test; carry indicates overlap.
        ld      a,13h                                          ;#4DBB: 3E 13
        add     a,e                                            ;#4DBD: 83
        ld      l,a                                            ;#4DBE: 6F
        ld      a,e                                            ;#4DBF: 7B
        add     a,a                                            ;#4DC0: 87
        add     a,17h                                          ;#4DC1: C6 17
        ld      e,a                                            ;#4DC3: 5F
        ld      a,d                                            ;#4DC4: 7A
        sub     h                                              ;#4DC5: 94
        sub     l                                              ;#4DC6: 95
        add     a,e                                            ;#4DC7: 83
        ret     nc                                             ;#4DC8: D0
        ; Item-catch collision response: play catch SFX, hide item sprite, +300.
        ld      a,ID_SOUND_CATCH_FISH                          ;#4DC9: 3E 07
        call    PLAY_SOUND_SAFE                                ;#4DCB: CD 70 79
        ld      hl,SAT_MIRROR + SPRITE_ITEM + ATTR_Y           ;#4DCE: 21 8C E0
        ld      de,FISH_POS_STATE                              ;#4DD1: 11 83 E1
        call    HIDE_DYNAMIC_SPRITE                            ;#4DD4: CD 6C 76
        call    SYNC_SPRITE_LOOP                               ;#4DD7: CD 17 76
        ld      de,300h                                        ;#4DDA: 11 00 03
        jp      ADD_SCORE                                      ;#4DDD: C3 16 46

HANDLE_COLLISION_SEAL:
        ; Seal collision: fires when SPRITE_OBSTACLE Y == 8Fh (seal-on-ground)
        ld      hl,(SAT_MIRROR + SPRITE_OBSTACLE + ATTR_Y)     ;#4DE0: 2A 90 E0
        ld      a,l                                            ;#4DE3: 7D
        ; Y-position gate: obstacle must be at Y=8Fh (on-road row) for heavy-stumble.
        cp      8Fh                                            ;#4DE4: FE 8F
        ret     nz                                             ;#4DE6: C0
        ld      a,(PENGUIN_X_POS)                              ;#4DE7: 3A 79 E0
        ld      l,a                                            ;#4DEA: 6F
        ld      a,h                                            ;#4DEB: 7C
        sub     l                                              ;#4DEC: 95
        ; Preserve signed X relation (flags) before range transform.
        push    af                                             ;#4DED: F5
        sub     18h                                            ;#4DEE: D6 18
        add     a,23h                                          ;#4DF0: C6 23
        ; Carry branch enters HANDLE_STUMBLE_LARGE for heavy obstacle collisions.
        jp      c,HANDLE_STUMBLE_LARGE                         ;#4DF2: DA 0B 4E
        pop     af                                             ;#4DF5: F1
        ret                                                    ;#4DF6: C9

HANDLE_COLLISION_HOLE:
        ; Hole-collision stun branch: plays STUN_1, joins START_PENGUIN_STUN
        ; One-shot guard: ensures stun fires only once per collision event.
        ld      a,(STUMBLE_PROCESSED_FLAG)                     ;#4DF7: 3A 35 E1
        or      a                                              ;#4DFA: B7
        ret     nz                                             ;#4DFB: C0
        ld      a,ID_SOUND_STUN_1                              ;#4DFC: 3E 03
        call    PLAY_SOUND_SAFE                                ;#4DFE: CD 70 79
        ; Base timer seed for normal stun response.
        ld      hl,101h                                        ;#4E01: 21 01 01
        ld      a,(PENGUIN_MOVE_STATE)                         ;#4E04: 3A FA E0
        cpl                                                    ;#4E07: 2F
        rra                                                    ;#4E08: 1F
        jr      START_PENGUIN_STUN                             ;#4E09: 18 16

HANDLE_STUMBLE_LARGE:
        ; Stumble handler for large object (Seal) collisions
        ; Stores stumble marker, plays stumble SFX, and derives timer variant.
        ld      hl,101h                                        ;#4E0B: 21 01 01
        ld      (STUMBLE_OBSTACLE_ADDR),hl                     ;#4E0E: 22 36 E1
        ld      a,ID_SOUND_SEAL_COLLISION                      ;#4E11: 3E 08
        call    PLAY_SOUND_SAFE                                ;#4E13: CD 70 79
        ld      hl,102h                                        ;#4E16: 21 02 01
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4E19: 3A F9 E0
        or      a                                              ;#4E1C: B7
        jr      z,STUMBLE_LARGE_DONE                           ;#4E1D: 28 01
        inc     l                                              ;#4E1F: 2C
STUMBLE_LARGE_DONE:
        ; Stumble logic finished
        pop     af                                             ;#4E20: F1
START_PENGUIN_STUN:
        ; Initiate the penguin stun sequence
        ; Writes stun timer/pattern, refreshes sprites, resets speed (shared stun path).
        ld      (PENGUIN_STUN_TIMER),hl                        ;#4E21: 22 42 E1
        ld      a,20h                                          ;#4E24: 3E 20
        jr      nc,START_PENGUIN_STUN_DONE                     ;#4E26: 30 02
        ld      a,24h                                          ;#4E28: 3E 24
START_PENGUIN_STUN_DONE:
        ; Stun initialization finished
        ld      (PENGUIN_STUN_PATTERN),a                       ;#4E2A: 32 44 E1
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4E2D: CD A6 4B
        call    SYNC_PENGUIN_SPRITES_TO_VRAM                   ;#4E30: CD 97 4B
        ld      hl,1313h                                       ;#4E33: 21 13 13
        ld      (PENGUIN_SPEED),hl                             ;#4E36: 22 00 E1
        ret                                                    ;#4E39: C9

HANDLE_PENGUIN_STUN_ANIMATION:
        ; Updates penguin position during stun state (every 4th frame)
        ld      a,(FRAME_COUNTER)                              ;#4E3A: 3A 03 E0
        and     3                                              ;#4E3D: E6 03
        ret     nz                                             ;#4E3F: C0
        ld      hl,PENGUIN_STUN_TIMER                          ;#4E40: 21 42 E1
        ld      a,(hl)                                         ;#4E43: 7E
        cp      3                                              ;#4E44: FE 03
        jp      z,STUN_RECOVERY_ANIMATION                      ;#4E46: CA D2 4E
        inc     hl                                             ;#4E49: 23
        ld      a,(hl)                                         ;#4E4A: 7E
        inc     (hl)                                           ;#4E4B: 34
        ld      hl,PENGUIN_STUN_Y_OFFSETS-1                    ;#4E4C: 21 BD 4E
        call    ADD_HL_A                                       ;#4E4F: CD D1 48
        ld      c,(hl)                                         ;#4E52: 4E
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4E53: ED 5B 78 E0
STUN_X_MOVE_LOOP:
        ; Loop to apply horizontal shift based on stun timer
        ld      hl,VRAM_UPDATE_BUFFER                          ;#4E57: 21 D0 E0
        ld      a,(PENGUIN_STUN_PATTERN)                       ;#4E5A: 3A 44 E1
        bit     2,a                                            ;#4E5D: CB 57
        call    z,STUMBLE_MOVE_LEFT_3X                         ;#4E5F: CC B3 4E
        call    nz,STUMBLE_MOVE_RIGHT_3X                       ;#4E62: C4 AA 4E
        ld      hl,PENGUIN_STUN_TIMER                          ;#4E65: 21 42 E1
        ld      a,(hl)                                         ;#4E68: 7E
        dec     a                                              ;#4E69: 3D
        jr      z,STUN_APPLY_Y_OFFSET                          ;#4E6A: 28 03
        dec     (hl)                                           ;#4E6C: 35
        jr      STUN_X_MOVE_LOOP                               ;#4E6D: 18 E8

STUN_APPLY_Y_OFFSET:
        ; Apply vertical offset from data table and update sprite
        ex      de,hl                                          ;#4E6F: EB
        ld      a,l                                            ;#4E70: 7D
        add     a,c                                            ;#4E71: 81
        ld      l,a                                            ;#4E72: 6F
        call    UPDATE_PENGUIN_COORDS                          ;#4E73: CD 94 4B
        ld      a,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)       ;#4E76: 3A 78 E0
        cp      90h                                            ;#4E79: FE 90
        jr      nz,SPAWN_ITEM_SKIP_STUN                        ;#4E7B: 20 1F
PLAY_STUN_2_AND_ADVANCE:
        ; Play STUN_2 SFX, render road, advance stage segment after stun landing
        ld      a,ID_SOUND_STUN_2                              ;#4E7D: 3E 04
        call    PLAY_SOUND_SAFE                                ;#4E7F: CD 70 79
        call    RENDER_LEFT_ROAD_FRAME                         ;#4E82: CD 5C 51
        call    ADVANCE_STAGE_SEGMENT_DATA                     ;#4E85: CD 65 51
        xor     a                                              ;#4E88: AF
        ld      b,a                                            ;#4E89: 47
        ld      hl,STUMBLE_OBSTACLE_ADDR                       ;#4E8A: 21 36 E1
        cp      (hl)                                           ;#4E8D: BE
        jr      z,SPAWN_ITEM_ENTRY                             ;#4E8E: 28 05
        ld      (hl),a                                         ;#4E90: 77
        inc     a                                              ;#4E91: 3C
        ld      (STUMBLE_PROCESSED_FLAG),a                     ;#4E92: 32 35 E1
SPAWN_ITEM_ENTRY:
        ; Entry point in the collision handler for spawning fish/items
        call    CHECK_AND_SPAWN_ITEM                           ;#4E95: CD 86 51
        xor     a                                              ;#4E98: AF
        ld      (STUMBLE_PROCESSED_FLAG),a                     ;#4E99: 32 35 E1
SPAWN_ITEM_SKIP_STUN:
        ; Skip item spawning
        ld      hl,PENGUIN_EVENT_TIMER                         ;#4E9C: 21 43 E1
        ld      a,(hl)                                         ;#4E9F: 7E
        sub     15h                                            ;#4EA0: D6 15
        ret     nz                                             ;#4EA2: C0
        ld      (hl),a                                         ;#4EA3: 77
        dec     hl                                             ;#4EA4: 2B
        ld      (hl),a                                         ;#4EA5: 77
        ld      (FISH_POS_GUARD_FLAG),a                        ;#4EA6: 32 37 E1
        ret                                                    ;#4EA9: C9

STUMBLE_MOVE_RIGHT_3X:
        ; Forceful right movement during stumble
        call    MOVE_PENGUIN_RIGHT                             ;#4EAA: CD 8A 4C
        call    MOVE_PENGUIN_RIGHT                             ;#4EAD: CD 8A 4C
        jp      MOVE_PENGUIN_RIGHT                             ;#4EB0: C3 8A 4C

STUMBLE_MOVE_LEFT_3X:
        ; Forceful left movement during stumble
        call    MOVE_PENGUIN_LEFT                              ;#4EB3: CD 6D 4C
        call    MOVE_PENGUIN_LEFT                              ;#4EB6: CD 6D 4C
        call    MOVE_PENGUIN_LEFT                              ;#4EB9: CD 6D 4C
        xor     a                                              ;#4EBC: AF
        ret                                                    ;#4EBD: C9

PENGUIN_STUN_Y_OFFSETS:
        ; Y-offsets for penguin stun/stumble animation
        ; Format: FORMAT_STUN_Y_OFFSETS
        STUN_Y_OFFSET -3                                       ;#4EBE: FD
        STUN_Y_OFFSET -2                                       ;#4EBF: FE
        STUN_Y_OFFSET -2                                       ;#4EC0: FE
        STUN_Y_OFFSET -1                                       ;#4EC1: FF
        STUN_Y_OFFSET 1                                        ;#4EC2: 01
        STUN_Y_OFFSET 2                                        ;#4EC3: 02
        STUN_Y_OFFSET 2                                        ;#4EC4: 02
        STUN_Y_OFFSET 3                                        ;#4EC5: 03
        STUN_Y_OFFSET -2                                       ;#4EC6: FE
        STUN_Y_OFFSET -2                                       ;#4EC7: FE
        STUN_Y_OFFSET -1                                       ;#4EC8: FF
        STUN_Y_OFFSET 1                                        ;#4EC9: 01
        STUN_Y_OFFSET 2                                        ;#4ECA: 02
        STUN_Y_OFFSET 2                                        ;#4ECB: 02
        STUN_Y_OFFSET -2                                       ;#4ECC: FE
        STUN_Y_OFFSET -2                                       ;#4ECD: FE
        STUN_Y_OFFSET -1                                       ;#4ECE: FF
        STUN_Y_OFFSET 1                                        ;#4ECF: 01
        STUN_Y_OFFSET 2                                        ;#4ED0: 02
        STUN_Y_OFFSET 2                                        ;#4ED1: 02

STUN_RECOVERY_ANIMATION:
        ; Handle stun recovery animation phase
        ld      hl,PENGUIN_INPUT_LOCK_TIMER                    ;#4ED2: 21 F9 E0
        ld      a,(hl)                                         ;#4ED5: 7E
        inc     (hl)                                           ;#4ED6: 34
        cp      0Bh                                            ;#4ED7: FE 0B
        jr      nz,APPLY_STUN_SPRITE_UPDATE                    ;#4ED9: 20 02
        ld      (hl),0                                         ;#4EDB: 36 00
APPLY_STUN_SPRITE_UPDATE:
        ; Apply sprite updates during stun recovery
        push    af                                             ;#4EDD: F5
        ld      a,(PENGUIN_STUN_PATTERN)                       ;#4EDE: 3A 44 E1
        ld      c,a                                            ;#4EE1: 4F
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4EE2: CD A6 4B
        pop     af                                             ;#4EE5: F1
        ld      hl,PENGUIN_JUMP_Y_OFFSETS                      ;#4EE6: 21 51 4C
        call    ADD_HL_A                                       ;#4EE9: CD D1 48
        ld      a,(hl)                                         ;#4EEC: 7E
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4EED: ED 5B 78 E0
        add     a,e                                            ;#4EF1: 83
        ld      e,a                                            ;#4EF2: 5F
        bit     2,c                                            ;#4EF3: CB 51
        ld      hl,VRAM_UPDATE_BUFFER                          ;#4EF5: 21 D0 E0
        call    z,STUMBLE_MOVE_LEFT_3X                         ;#4EF8: CC B3 4E
        call    nz,STUMBLE_MOVE_RIGHT_3X                       ;#4EFB: C4 AA 4E
        ex      de,hl                                          ;#4EFE: EB
        call    UPDATE_PENGUIN_COORDS                          ;#4EFF: CD 94 4B
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4F02: 3A F9 E0
        or      a                                              ;#4F05: B7
        ret     nz                                             ;#4F06: C0
        ld      a,1                                            ;#4F07: 3E 01
        ld      (STUMBLE_PROCESSED_FLAG),a                     ;#4F09: 32 35 E1
        call    PLAY_STUN_2_AND_ADVANCE                        ;#4F0C: CD 7D 4E
        xor     a                                              ;#4F0F: AF
        ld      (STUMBLE_PROCESSED_FLAG),a                     ;#4F10: 32 35 E1
        dec     hl                                             ;#4F13: 2B
        inc     a                                              ;#4F14: 3C
        ld      (hl),a                                         ;#4F15: 77
        ld      a,ID_SOUND_STUN_2                              ;#4F16: 3E 04
        call    PLAY_SOUND_SAFE                                ;#4F18: CD 70 79
        ret                                                    ;#4F1B: C9

HANDLE_COLLISION_FALL:
        ; Handle collision that causes falling (e.g. hole)
        ld      hl,1                                           ;#4F1C: 21 01 00
        ld      (PENGUIN_FALL_TIMER),hl                        ;#4F1F: 22 40 E1
        xor     a                                              ;#4F22: AF
        ld      (PENGUIN_STUN_TIMER),a                         ;#4F23: 32 42 E1
        ld      a,0FFh                                         ;#4F26: 3E FF
        ld      (PENGUIN_ANIM_FRAME),a                         ;#4F28: 32 F8 E0
        ld      a,ID_SOUND_FALL_HOLE                           ;#4F2B: 3E 05
        call    PLAY_SOUND_SAFE                                ;#4F2D: CD 70 79
        ld      hl,SAT_MIRROR + SPRITE_6 + ATTR_Y              ;#4F30: 21 68 E0
        ld      bc,4B6h                                        ;#4F33: 01 B6 04
HIDE_AUX_SPRITES_LOOP:
        ; Park aux-sprite buffer (sprites 6-9) off-screen (Y=B6h) during fall
        ld      (hl),c                                         ;#4F36: 71
        ld      a,4                                            ;#4F37: 3E 04
        call    ADD_HL_A                                       ;#4F39: CD D1 48
        djnz    HIDE_AUX_SPRITES_LOOP                          ;#4F3C: 10 F8
SET_PENGUIN_FALL_COORDS:
        ; Set penguin coordinates for fall sequence
        ld      hl,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4F3E: 2A 78 E0
        ld      l,9Fh                                          ;#4F41: 2E 9F
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#4F43: CD BD 4B
        ld      a,10h                                          ;#4F46: 3E 10
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4F48: CD A6 4B
        ld      a,0E0h                                         ;#4F4B: 3E E0
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_Y),a        ;#4F4D: 32 A0 E0
        ld      hl,0E0h * 256 + COLOR_DARK_YELLOW              ;#4F50: 21 0A E0
        ; Packed 2-byte write: the slot for shadow is reused as yellow penguin's legs.
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_COLOR),hl   ;#4F53: 22 A3 E0
SYNC_AUX_SPRITES_TO_VRAM:
        ; Copy 32-byte aux-sprite buffer (E068, sprites 6-13) to VRAM
        ld      hl,SAT_MIRROR + SPRITE_6 + ATTR_Y              ;#4F56: 21 68 E0
        LOAD_SPRITE_ATTR de, 6, 0                              ;#4F59: 11 18 3B
        ld      bc,20h                                         ;#4F5C: 01 20 00
        call    COPY_RAM_TO_VRAM                               ;#4F5F: CD DE 44
        jp      COPY_PENGUIN_ATTRS_TO_VRAM                     ;#4F62: C3 EF 4C

HANDLE_PENGUIN_FALL:
        ; Handle penguin fall state (increments anim counter, waits for input)
        ld      hl,PENGUIN_FALL_ANIM_COUNTER                   ;#4F65: 21 41 E1
        inc     (hl)                                           ;#4F68: 34
        res     7,(hl)                                         ;#4F69: CB BE
        ld      a,(hl)                                         ;#4F6B: 7E
        cp      20h                                            ;#4F6C: FE 20
        jr      c,SET_PENGUIN_FALL_COORDS                      ;#4F6E: 38 CE
        call    READ_INPUT_EDGE                                ;#4F70: CD 06 46
        jr      nz,PENGUIN_FALL_LOOP                           ;#4F73: 20 3E
        ld      a,(FRAME_COUNTER)                              ;#4F75: 3A 03 E0
        ld      c,a                                            ;#4F78: 4F
        and     7                                              ;#4F79: E6 07
        ret     nz                                             ;#4F7B: C0
        ; Fall-recovery branch table — picks one of three (a, b, de) tuples by
        ; FRAME_COUNTER bits 3 and 4 (each phase lasts 8 frames).
        ; In this branch, the shadow sprites are used from the penguin's legs.
        ; The values feed INIT_FALL_RECOVERY:
        ; a = shadow X offset added to penguin_X
        ; b + 10h = final shadow Y
        ; d = penguin body pattern;
        ; e = legs pattern.
        ; frame 0 (bit 3 = 0):           a=8,    b=99h, d=14h, e=70h
        ld      a,8                                            ;#4F7C: 3E 08
        ld      b,99h                                          ;#4F7E: 06 99
        ld      de,1470h                                       ;#4F80: 11 70 14
        bit     3,c                                            ;#4F83: CB 59
        jr      z,INIT_FALL_RECOVERY                           ;#4F85: 28 10
        ; frame 1 (bit 3 = 1, bit 4 = 0): a=4,    b=96h, d=18h, e=74h
        ld      a,4                                            ;#4F87: 3E 04
        ld      b,96h                                          ;#4F89: 06 96
        ld      de,1874h                                       ;#4F8B: 11 74 18
        bit     4,c                                            ;#4F8E: CB 61
        jr      z,INIT_FALL_RECOVERY                           ;#4F90: 28 05
        ; frame 2 (bits 3+4 both set):    a=0Bh, (b kept from frame 1), d=1Ch, e=78h
        ld      a,0Bh                                          ;#4F92: 3E 0B
        ld      de,1C78h                                       ;#4F94: 11 78 1C
INIT_FALL_RECOVERY:
        ; Initialize recovery after falling
        ld      hl,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4F97: 2A 78 E0
        ld      l,b                                            ;#4F9A: 68
        add     a,h                                            ;#4F9B: 84
        ld      c,a                                            ;#4F9C: 4F
        ld      a,b                                            ;#4F9D: 78
        ld      b,e                                            ;#4F9E: 43
        ; Packed 2-byte write: shadow X (E0A1) + shadow pattern (E0A2).
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_X),bc       ;#4F9F: ED 43 A1 E0
        add     a,10h                                          ;#4FA3: C6 10
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_Y),a        ;#4FA5: 32 A0 E0
        push    de                                             ;#4FA8: D5
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#4FA9: CD BD 4B
        pop     af                                             ;#4FAC: F1
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4FAD: CD A6 4B
        jp      SYNC_AUX_SPRITES_TO_VRAM                       ;#4FB0: C3 56 4F

PENGUIN_FALL_LOOP:
        ; Loop for penguin falling animation
        xor     a                                              ;#4FB3: AF
        ld      (PENGUIN_FALL_TIMER),a                         ;#4FB4: 32 40 E1
        ld      (PENGUIN_ANIM_FRAME),a                         ;#4FB7: 32 F8 E0
        ld      hl,313h                                        ;#4FBA: 21 13 03
        ld      (PENGUIN_SPEED),hl                             ;#4FBD: 22 00 E1
        ld      a,(PENGUIN_X_POS)                              ;#4FC0: 3A 79 E0
        push    af                                             ;#4FC3: F5
        ld      hl,SPRITE_INIT_TABLE+1                         ;#4FC4: 21 99 66
        ld      de,SAT_MIRROR + SPRITE_6 + ATTR_Y              ;#4FC7: 11 68 E0
        ld      c,4                                            ;#4FCA: 0E 04
        call    REPLICATE_4_BYTE_BLOCK                         ;#4FCC: CD A2 45
        ld      b,4                                            ;#4FCF: 06 04
HIDE_AUX_SPRITES_DATA_LOOP:
        ; Replicate SPRITE_INIT_TABLE bytes across 4 aux-sprite slots (PENGUIN_FALL_LOOP)
        ld      c,(hl)                                         ;#4FD1: 4E
        inc     hl                                             ;#4FD2: 23
        push    bc                                             ;#4FD3: C5
        call    REPLICATE_4_BYTE_BLOCK                         ;#4FD4: CD A2 45
        pop     bc                                             ;#4FD7: C1
        djnz    HIDE_AUX_SPRITES_DATA_LOOP                     ;#4FD8: 10 F7
        pop     hl                                             ;#4FDA: E1
        ld      l,90h                                          ;#4FDB: 2E 90
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#4FDD: CD BD 4B
        ld      hl,0A0h + COLOR_DARK_BLUE * 256                ;#4FE0: 21 A0 04
        ; Packed 2-byte write: shadow pattern A0h (low) + shadow color 4 dark blue (high).
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_PATT),hl    ;#4FE3: 22 A2 E0
        call    SYNC_PENGUIN_SPRITES_TO_VRAM                   ;#4FE6: CD 97 4B
        call    SYNC_SPRITE_ATTRIBUTES_ALL                     ;#4FE9: CD 8C 66
        ret                                                    ;#4FEC: C9

HANDLE_COLLISION_FLAG:
        ; Road-flag pickup (SEQ_ITEM_PROP 5/6): +500, jingle, draws the tile stream
        ex      de,hl                                          ;#4FED: EB
        dec     hl                                             ;#4FEE: 2B
        dec     hl                                             ;#4FEF: 2B
        ld      d,(hl)                                         ;#4FF0: 56
        dec     hl                                             ;#4FF1: 2B
        ld      e,(hl)                                         ;#4FF2: 5E
        dec     hl                                             ;#4FF3: 2B
        dec     hl                                             ;#4FF4: 2B
        ld      (hl),0                                         ;#4FF5: 36 00
        ex      de,hl                                          ;#4FF7: EB
        inc     hl                                             ;#4FF8: 23
        ld      de,ITEM_PICKUP_TILE_BUFFER                     ;#4FF9: 11 A0 E1
        ld      bc,0Dh                                         ;#4FFC: 01 0D 00
        ldir                                                   ;#4FFF: ED B0
        xor     a                                              ;#5001: AF
        ld      (de),a                                         ;#5002: 12
        ld      a,ID_SOUND_CATCH_FLAG                          ;#5003: 3E 06
        call    PLAY_SOUND_SAFE                                ;#5005: CD 70 79
        ld      hl,ITEM_PICKUP_TILE_BUFFER                     ;#5008: 21 A0 E1
        call    WRITE_VRAM_TILES_STREAM                        ;#500B: CD 25 45
        ld      de,500h                                        ;#500E: 11 00 05
        call    ADD_SCORE                                      ;#5011: CD 16 46
        ret                                                    ;#5014: C9

INIT_STAGE:
        ; Initialize stage-specific BCD values and timers
        ld      a,(CURRENT_STAGE_INDEX)                        ;#5015: 3A E1 E0
        ld      hl,STAGE_VISUAL_THEME_TABLE                    ;#5018: 21 41 51
        call    ADD_HL_A                                       ;#501B: CD D1 48
        ld      a,COLOR_CYAN                                   ;#501E: 3E 07
        bit     0,(hl)                                         ;#5020: CB 46
        jr      z,INIT_STAGE_SET_SKY_COLOR                     ;#5022: 28 02
        ld      a,COLOR_LIGHT_RED                              ;#5024: 3E 09
INIT_STAGE_SET_SKY_COLOR:
        ; Set stage sky color attribute
        ld      (SKY_COLOR),a                                  ;#5026: 32 0C E1
        ld      a,(hl)                                         ;#5029: 7E
        ld      hl,GFX_STARTUP_COLOR_TABLE_TAIL                ;#502A: 21 8D 5D
        LOAD_VRAM_WRITE de, 21EFh                              ;#502D: 11 EF 61
        or      a                                              ;#5030: B7
        jr      z,LOAD_STAGE_TILES_AND_COLORS                  ;#5031: 28 06
        ld      hl,GFX_STAGE_NIGHT_TILES                       ;#5033: 21 98 5D
        ld      de,GFX_STAGE_NIGHT_COLORS                      ;#5036: 11 0C 62
LOAD_STAGE_TILES_AND_COLORS:
        ; Load stage tiles and colors to VRAM
        push    de                                             ;#5039: D5
        LOAD_VRAM_WRITE de, 588h                               ;#503A: 11 88 45
        call    DECOMPRESS_VRAM_DIRECT                         ;#503D: CD 54 45
        pop     hl                                             ;#5040: E1
        LOAD_VRAM_WRITE de, 0F78h                              ;#5041: 11 78 4F
        call    DECOMPRESS_VRAM_DIRECT                         ;#5044: CD 54 45
        LOAD_NAME_TABLE de, 3, 0                               ;#5047: 11 60 38
        ld      bc,0E0h                                        ;#504A: 01 E0 00
        ld      a,(SKY_COLOR)                                  ;#504D: 3A 0C E1
        call    FILL_VRAM                                      ;#5050: CD F1 44
        LOAD_NAME_TABLE de, 10, 0                              ;#5053: 11 40 39
        ld      bc,1C0h                                        ;#5056: 01 C0 01
        LOAD_VRAM_COLOR a, COLOR_TRANSPARENT, COLOR_WHITE      ;#5059: 3E 0F
        call    FILL_VRAM                                      ;#505B: CD F1 44
        ld      hl,ROAD_ICE_RIGHT_1_FILL                       ;#505E: 21 FA 71
        call    UPLOAD_ROAD_SEGMENT_TO_VRAM                    ;#5061: CD C2 50
        ld      hl,ROAD_ICE_LEFT_1_FILL                        ;#5064: 21 37 72
        call    UPLOAD_ROAD_SEGMENT_TO_VRAM                    ;#5067: CD C2 50
        ld      hl,STAGE_SEGMENT_SEQUENCES                     ;#506A: 21 15 51
        ld      a,(CURRENT_STAGE_INDEX)                        ;#506D: 3A E1 E0
        add     a,a                                            ;#5070: 87
        add     a,a                                            ;#5071: 87
        call    ADD_HL_A                                       ;#5072: CD D1 48
        ld      (CURRENT_STAGE_DATA_PTR),hl                    ;#5075: 22 0A E1
        xor     a                                              ;#5078: AF
        ld      (ACTIVE_ROAD_FRAME),a                          ;#5079: 32 02 E1
        ld      (STAGE_SEGMENT_INDEX),a                        ;#507C: 32 08 E1
        ld      hl,ROAD_ICE_RIGHT_1                            ;#507F: 21 F2 71
        ld      (ACTIVE_ROAD_PTR_RIGHT),hl                     ;#5082: 22 03 E1
        ld      hl,ROAD_ICE_LEFT_1                             ;#5085: 21 2F 72
        ld      (ACTIVE_ROAD_PTR_LEFT),hl                      ;#5088: 22 05 E1
        call    RENDER_LEFT_ROAD_FRAME                         ;#508B: CD 5C 51
        call    CALC_STAGE_SEGMENT_ADDR                        ;#508E: CD 6C 51
        ret                                                    ;#5091: C9

PROCESS_ROAD_SEGMENT_ADVANCE:
        ; Advance to next road data segment and trigger VRAM update
        ld      hl,STAGE_SEGMENT_INDEX                         ;#5092: 21 08 E1
        ld      a,(hl)                                         ;#5095: 7E
        inc     (hl)                                           ;#5096: 34
        ld      hl,(CURRENT_STAGE_DATA_PTR)                    ;#5097: 2A 0A E1
        call    ADD_HL_A                                       ;#509A: CD D1 48
        ld      a,(hl)                                         ;#509D: 7E
        cp      0FFh                                           ;#509E: FE FF
        ret     z                                              ;#50A0: C8
        ld      (ROAD_SEGMENT_INDEX),a                         ;#50A1: 32 09 E1
        ld      bc,ACTIVE_ROAD_PTR_RIGHT                       ;#50A4: 01 03 E1
        bit     0,a                                            ;#50A7: CB 47
        jr      z,STORE_ROAD_SEG_SKIP_BC                       ;#50A9: 28 02
        inc     bc                                             ;#50AB: 03
        inc     bc                                             ;#50AC: 03
STORE_ROAD_SEG_SKIP_BC:
        ; Skip register BC store
        add     a,a                                            ;#50AD: 87
        ld      hl,STAGE_SEGMENT_DEFINITIONS                   ;#50AE: 21 EA 71
        call    ADD_HL_A                                       ;#50B1: CD D1 48
        ld      a,(hl)                                         ;#50B4: 7E
        ld      e,a                                            ;#50B5: 5F
        ld      (bc),a                                         ;#50B6: 02
        inc     hl                                             ;#50B7: 23
        inc     bc                                             ;#50B8: 03
        ld      a,(hl)                                         ;#50B9: 7E
        ld      d,a                                            ;#50BA: 57
        ld      (bc),a                                         ;#50BB: 02
        ex      de,hl                                          ;#50BC: EB
        ld      a,8                                            ;#50BD: 3E 08
        call    ADD_HL_A                                       ;#50BF: CD D1 48
UPLOAD_ROAD_SEGMENT_TO_VRAM:
        ; Decompresses and uploads a block of road graphics to VRAM
        call    FILL_VRAM_STREAM                               ;#50C2: CD 04 45
        call    WRITE_VRAM_STREAM                              ;#50C5: CD 90 45
        ld      e,(hl)                                         ;#50C8: 5E
UPLOAD_ROAD_SEG_DONE:
        ; Road segment upload finished
        ld      a,(SKY_COLOR)                                  ;#50C9: 3A 0C E1
        ld      c,a                                            ;#50CC: 4F
        ld      b,10h                                          ;#50CD: 06 10
        ld      d,0E1h                                         ;#50CF: 16 E1
INIT_VRAM_LOOP:
        ; Loop through VRAM stream data
        inc     hl                                             ;#50D1: 23
        ld      a,(hl)                                         ;#50D2: 7E
        or      a                                              ;#50D3: B7
        jr      nz,INIT_VRAM_WRITE_VAL                         ;#50D4: 20 01
        ld      a,c                                            ;#50D6: 79
INIT_VRAM_WRITE_VAL:
        ; Write default value to VRAM stream
        ld      (de),a                                         ;#50D7: 12
        inc     de                                             ;#50D8: 13
        djnz    INIT_VRAM_LOOP                                 ;#50D9: 10 F6
INIT_VRAM_DONE:
        ; VRAM initialization finished
        LOAD_NAME_TABLE de, 9, 0                               ;#50DB: 11 20 39
        ld      (VRAM_STREAM_PTR),de                           ;#50DE: ED 53 4E E1
        ld      a,0FFh                                         ;#50E2: 3E FF
        ld      (VRAM_STREAM_STATUS),a                         ;#50E4: 32 70 E1
        ld      hl,VRAM_STREAM_PTR                             ;#50E7: 21 4E E1
        call    WRITE_VRAM_STREAM                              ;#50EA: CD 90 45
        xor     a                                              ;#50ED: AF
        ret                                                    ;#50EE: C9

UPDATE_STAGE_OBJECTS_LOGIC:
        ; Update stage objects and check flags
        call    CHECK_FLICKER_TIMER                            ;#50EF: CD FD 52
        ld      hl,STAGE_SEGMENT_TIMER                         ;#50F2: 21 07 E1
        ld      a,(hl)                                         ;#50F5: 7E
        dec     a                                              ;#50F6: 3D
        ret     nz                                             ;#50F7: C0
        ld      a,(ACTIVE_ROAD_FRAME)                          ;#50F8: 3A 02 E1
        dec     a                                              ;#50FB: 3D
        ret     nz                                             ;#50FC: C0
        ld      (hl),a                                         ;#50FD: 77
        call    PROCESS_ROAD_SEGMENT_ADVANCE                   ;#50FE: CD 92 50
        or      a                                              ;#5101: B7
        ret     nz                                             ;#5102: C0
        ld      hl,(ACTIVE_ROAD_PTR_RIGHT)                     ;#5103: 2A 03 E1
        ld      a,(ROAD_SEGMENT_INDEX)                         ;#5106: 3A 09 E1
        bit     0,a                                            ;#5109: CB 47
        jr      z,FETCH_SEGMENT_DATA_PTR                       ;#510B: 28 03
        ld      hl,(ACTIVE_ROAD_PTR_LEFT)                      ;#510D: 2A 05 E1
FETCH_SEGMENT_DATA_PTR:
        ; Fetch pointer to segment data (index 0)
        xor     a                                              ;#5110: AF
        call    CALC_SEGMENT_ADDR_OFFSET                       ;#5111: CD 6F 51
        ret                                                    ;#5114: C9

STAGE_SEGMENT_SEQUENCES:
        ; Stage segment-sequence table (stages 0-8 use 4 bytes; stage 9 uses 8).
        ; Each stage row is consumed by PROCESS_ROAD_SEGMENT_ADVANCE, one byte per
        ; segment-timer fire. The bytes are indices into STAGE_SEGMENT_DEFINITIONS.
        ; Bit 0 picks the slot (0=ACTIVE_ROAD_PTR_RIGHT,
        ; 1=ACTIVE_ROAD_PTR_LEFT); the byte (*2) is the offset into the 4-entry table.
        ; FFh means skip this segment; 77h is tail padding that the stage distance
        ; never reaches (would deref a garbage pointer if read).
        ; Stages 0-8 occupy 4 bytes each. Stage 9 (2600h BCD, the longest distance)
        ; extends past its 4-byte row, giving it 8 effective bytes.
        ; STAGE_SEGMENT_INDEX is incremented without bound, so the overrun is by design.
        STAGE_SEGMENTS 3,    0FFh, 1,    77h  ; Stage 0        ;#5115: 03 FF 01 77
        STAGE_SEGMENTS 3,    2,    1,    0    ; Stage 1        ;#5119: 03 02 01 00
        STAGE_SEGMENTS 0FFh, 3,    1,    77h  ; Stage 2        ;#511D: FF 03 01 77
        STAGE_SEGMENTS 2,    3,    0,    1    ; Stage 3        ;#5121: 02 03 00 01
        STAGE_SEGMENTS 2,    0FFh, 0,    0FFh ; Stage 4        ;#5125: 02 FF 00 FF
        STAGE_SEGMENTS 0FFh, 3,    1,    77h  ; Stage 5        ;#5129: FF 03 01 77
        STAGE_SEGMENTS 2,    0,    0FFh, 77h  ; Stage 6        ;#512D: 02 00 FF 77
        STAGE_SEGMENTS 3,    0FFh, 1,    77h  ; Stage 7        ;#5131: 03 FF 01 77
        STAGE_SEGMENTS 0FFh, 77h,  77h,  77h  ; Stage 8 (shortest, 500h) ;#5135: FF 77 77 77
        STAGE_SEGMENTS 0FFh, 2,    3,    0    ; Stage 9 (longest, 2600h; row continues) ;#5139: FF 02 03 00
        STAGE_SEGMENTS 1,    3,    1,    77h  ; Stage 9 (continued, positions 4..7) ;#513D: 01 03 01 77
STAGE_VISUAL_THEME_TABLE:
        ; Table of visual style indices (0=Day/Blue, 1=Night/Red) per stage.
        ; Used by INIT_STAGE to select color/gfx bank.
        ; Format: FORMAT_SKY_COLOR
        db      SKY_DAY_BLUE                                   ;#5141: 00
        db      SKY_NIGHT_RED                                  ;#5142: 01
        db      SKY_DAY_BLUE                                   ;#5143: 00
        db      SKY_DAY_BLUE                                   ;#5144: 00
        db      SKY_DAY_BLUE                                   ;#5145: 00
        db      SKY_NIGHT_RED                                  ;#5146: 01
        db      SKY_DAY_BLUE                                   ;#5147: 00
        db      SKY_NIGHT_RED                                  ;#5148: 01
        db      SKY_DAY_BLUE                                   ;#5149: 00
        db      SKY_DAY_BLUE                                   ;#514A: 00

PROCESS_SCENE_TIMER:
        ; Decrements PENGUIN_SPEED timer, triggers events
        ld      hl,PENGUIN_SPEED                               ;#514B: 21 00 E1
        ld      c,(hl)                                         ;#514E: 4E
        inc     hl                                             ;#514F: 23
        dec     (hl)                                           ;#5150: 35
        jr      z,RESET_SCENE_TIMER_AND_ADVANCE                ;#5151: 28 11
        ld      a,(hl)                                         ;#5153: 7E
        cp      3                                              ;#5154: FE 03
        jp      z,UPDATE_STAGE_OBJECTS_LOGIC                   ;#5156: CA EF 50
        dec     a                                              ;#5159: 3D
        jr      nz,ADVANCE_STAGE_SEG_DONE                      ;#515A: 20 1F
RENDER_LEFT_ROAD_FRAME:
        ; Render left road slot current-frame pattern via WRITE_VRAM_TILES_STREAM
        ld      hl,(ACTIVE_ROAD_PTR_LEFT)                      ;#515C: 2A 05 E1
        ld      a,(ACTIVE_ROAD_FRAME)                          ;#515F: 3A 02 E1
        jr      CALC_SEGMENT_ADDR_OFFSET                       ;#5162: 18 0B

RESET_SCENE_TIMER_AND_ADVANCE:
        ; Reset timer and advance stage data
        ld      (hl),c                                         ;#5164: 71
ADVANCE_STAGE_SEGMENT_DATA:
        ; Increment segment counter and load patterns
        ld      hl,ACTIVE_ROAD_FRAME                           ;#5165: 21 02 E1
        ld      a,(hl)                                         ;#5168: 7E
        inc     (hl)                                           ;#5169: 34
        res     2,(hl)                                         ;#516A: CB 96
CALC_STAGE_SEGMENT_ADDR:
        ; Calculate address of stage segment data
        ld      hl,(ACTIVE_ROAD_PTR_RIGHT)                     ;#516C: 2A 03 E1
CALC_SEGMENT_ADDR_OFFSET:
        ; Calculate address of stage segment data with offset A
        add     a,a                                            ;#516F: 87
        call    ADD_HL_A                                       ;#5170: CD D1 48
        ld      e,(hl)                                         ;#5173: 5E
        inc     hl                                             ;#5174: 23
        ld      d,(hl)                                         ;#5175: 56
        ex      de,hl                                          ;#5176: EB
        call    WRITE_VRAM_TILES_STREAM                        ;#5177: CD 25 45
        ret                                                    ;#517A: C9

ADVANCE_STAGE_SEG_DONE:
        ; Stage segment advancement finished
        ld      b,0                                            ;#517B: 06 00
        dec     a                                              ;#517D: 3D
        jr      z,CHECK_AND_SPAWN_ITEM                         ;#517E: 28 06
        inc     b                                              ;#5180: 04
        srl     c                                              ;#5181: CB 39
        ld      a,(hl)                                         ;#5183: 7E
        cp      c                                              ;#5184: B9
        ret     nz                                             ;#5185: C0
CHECK_AND_SPAWN_ITEM:
        ; Periodically check and spawn fish/flags
        ld      hl,ITEM_TABLE                                  ;#5186: 21 12 E1
        ld      c,b                                            ;#5189: 48
        ld      b,4                                            ;#518A: 06 04
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#518C: 3A E0 E0
        cp      5                                              ;#518F: FE 05
        jr      c,SPAWN_ITEM_LOOP_NEXT                         ;#5191: 38 01
        inc     b                                              ;#5193: 04
SPAWN_ITEM_LOOP_NEXT:
        ; Next iteration of item spawn loop
        ld      a,c                                            ;#5194: 79
        or      a                                              ;#5195: B7
        jr      z,SPAWN_ITEM_CHECK_SLOT                        ;#5196: 28 07
        ld      a,(hl)                                         ;#5198: 7E
        cp      0Bh                                            ;#5199: FE 0B
        ld      a,6                                            ;#519B: 3E 06
        jr      c,SPAWN_ITEM_SKIP                              ;#519D: 38 22
SPAWN_ITEM_CHECK_SLOT:
        ; Check if item slot is free
        ld      a,(hl)                                         ;#519F: 7E
        or      a                                              ;#51A0: B7
        ld      a,6                                            ;#51A1: 3E 06
        jr      z,SPAWN_ITEM_SKIP                              ;#51A3: 28 1C
        inc     (hl)                                           ;#51A5: 34
        ld      a,(hl)                                         ;#51A6: 7E
        cp      10h                                            ;#51A7: FE 10
        jr      c,SPAWN_ITEM_INIT                              ;#51A9: 38 02
        ld      (hl),0                                         ;#51AB: 36 00
SPAWN_ITEM_INIT:
        ; Initialize new item in slot
        inc     hl                                             ;#51AD: 23
        inc     hl                                             ;#51AE: 23
        ld      e,(hl)                                         ;#51AF: 5E
        inc     hl                                             ;#51B0: 23
        ld      d,(hl)                                         ;#51B1: 56
        ex      de,hl                                          ;#51B2: EB
        push    de                                             ;#51B3: D5
        push    bc                                             ;#51B4: C5
        call    WRITE_VRAM_TILES_STREAM                        ;#51B5: CD 25 45
        pop     bc                                             ;#51B8: C1
        pop     de                                             ;#51B9: D1
        inc     hl                                             ;#51BA: 23
        ex      de,hl                                          ;#51BB: EB
        ld      (hl),d                                         ;#51BC: 72
        dec     hl                                             ;#51BD: 2B
        ld      (hl),e                                         ;#51BE: 73
        ld      a,4                                            ;#51BF: 3E 04
SPAWN_ITEM_SKIP:
        ; Skip to next slot
        call    ADD_HL_A                                       ;#51C1: CD D1 48
        djnz    SPAWN_ITEM_LOOP_NEXT                           ;#51C4: 10 CE
        call    CHECK_SPECIAL_ITEM_COLLISION                   ;#51C6: CD 96 75
        call    HANDLE_SPECIAL_ITEM_EVENT                      ;#51C9: CD E9 77
        call    CHECK_ITEM_COLLISIONS                          ;#51CC: CD 1A 4D
        call    CHECK_COLLISIONS_WHILE_LOCKED                  ;#51CF: CD 67 4D
        ret                                                    ;#51D2: C9

UPDATE_ITEMS:
        ; Main loop for updating items and sequences
        call    START_SEQUENCE_CHECK                           ;#51D3: CD FA 47
        ld      hl,(STAGE_DISTANCE_BCD)                        ;#51D6: 2A E5 E0
        ld      a,h                                            ;#51D9: 7C
        and     a                                              ;#51DA: A7
        jr      nz,TICK_ITEM_TIMER                             ;#51DB: 20 04
        ld      a,l                                            ;#51DD: 7D
        cp      86h                                            ;#51DE: FE 86
        ret     c                                              ;#51E0: D8
TICK_ITEM_TIMER:
        ; Tick item-timer countdown; reload from period and walk ITEM_TABLE on expiry
        ld      hl,ITEM_TICK_PERIOD                            ;#51E1: 21 0E E1
        ld      a,(hl)                                         ;#51E4: 7E
        inc     hl                                             ;#51E5: 23
        dec     (hl)                                           ;#51E6: 35
        ret     nz                                             ;#51E7: C0
        ld      (hl),a                                         ;#51E8: 77
        ld      hl,ITEM_TABLE                                  ;#51E9: 21 12 E1
        ld      b,3                                            ;#51EC: 06 03
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#51EE: 3A E0 E0
        cp      5                                              ;#51F1: FE 05
        jr      c,CHECK_ACTIVE_ITEM_SLOT                       ;#51F3: 38 01
        inc     b                                              ;#51F5: 04
CHECK_ACTIVE_ITEM_SLOT:
        ; Check for active item slot
        ld      a,(hl)                                         ;#51F6: 7E
        or      a                                              ;#51F7: B7
        jr      z,UPDATE_ITEM_STATE                            ;#51F8: 28 08
        ld      a,6                                            ;#51FA: 3E 06
        call    ADD_HL_A                                       ;#51FC: CD D1 48
        djnz    CHECK_ACTIVE_ITEM_SLOT                         ;#51FF: 10 F5
        ret                                                    ;#5201: C9

UPDATE_ITEM_STATE:
        ; Update state of active item
        ; Runs periodically for entities spawned by START_SEQUENCE_CHECK. Processes
        ; 8-byte command streams divided into 4-byte packets. Instruction set (1 byte):
        ; - 00h-0Fh: Select entry from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: Set movement state (stored at ITEM_TABLE + 0).
        ; - FFh: End of sequence/Idle.
        inc     (hl)                                           ;#5202: 34
        inc     hl                                             ;#5203: 23
        ex      de,hl                                          ;#5204: EB
        ld      hl,ITEM_COMMAND_INDEX                          ;#5205: 21 11 E1
        inc     (hl)                                           ;#5208: 34
        res     3,(hl)                                         ;#5209: CB 9E
        ld      a,(hl)                                         ;#520B: 7E
        ld      hl,(SEQUENCE_DATA_PTR)                         ;#520C: 2A 8B E1
        call    ADD_HL_A                                       ;#520F: CD D1 48
        ld      c,(hl)                                         ;#5212: 4E
        push    de                                             ;#5213: D5
        call    CHECK_SEQUENCE_STATUS                          ;#5214: CD E8 47
        pop     de                                             ;#5217: D1
        ld      a,c                                            ;#5218: 79
        inc     a                                              ;#5219: 3C
        jr      z,STORE_ITEM_STATE                             ;#521A: 28 3E
        dec     a                                              ;#521C: 3D
        bit     4,a                                            ;#521D: CB 67
        jr      z,SET_ITEM_MOVE_OVERRIDE_DONE                  ;#521F: 28 0C
        ld      hl,ITEM_MOVE_OVERRIDE_FLAG                     ;#5221: 21 90 E1
        ld      (hl),1                                         ;#5224: 36 01
        inc     hl                                             ;#5226: 23
        and     3                                              ;#5227: E6 03
        ld      c,a                                            ;#5229: 4F
        ld      (hl),a                                         ;#522A: 77
        jr      PROCESS_ITEM_MOVEMENT                          ;#522B: 18 0B

SET_ITEM_MOVE_OVERRIDE_DONE:
        ; Item-move override setup finished
        ld      a,c                                            ;#522D: 79
        or      a                                              ;#522E: B7
        jr      z,PROCESS_ITEM_MOVEMENT                        ;#522F: 28 07
        ld      a,(PENGUIN_SIDE_FLAG)                          ;#5231: 3A FC E0
        or      a                                              ;#5234: B7
        jr      z,PROCESS_ITEM_MOVEMENT                        ;#5235: 28 01
        inc     c                                              ;#5237: 0C
PROCESS_ITEM_MOVEMENT:
        ; Handle movement for item
        ex      de,hl                                          ;#5238: EB
        call    SAVE_ITEM_DATA                                 ;#5239: CD 5E 52
        ld      a,(ITEM_MOVE_OVERRIDE_FLAG)                    ;#523C: 3A 90 E1
        rra                                                    ;#523F: 1F
        ret     nc                                             ;#5240: D0
        ld      a,(ITEM_MOVE_TOGGLE)                           ;#5241: 3A 91 E1
        cpl                                                    ;#5244: 2F
        and     3                                              ;#5245: E6 03
        ld      c,a                                            ;#5247: 4F
        ld      hl,ITEM_DATA_LATCH                             ;#5248: 21 2A E1
        ld      a,(hl)                                         ;#524B: 7E
        or      a                                              ;#524C: B7
        jr      nz,CLEAR_ITEM_MOVE_OVERRIDE                    ;#524D: 20 05
        inc     (hl)                                           ;#524F: 34
        inc     hl                                             ;#5250: 23
        call    SAVE_ITEM_DATA                                 ;#5251: CD 5E 52
CLEAR_ITEM_MOVE_OVERRIDE:
        ; Clears ITEM_MOVE_OVERRIDE_FLAG at end of item-state update (legacy name)
        ld      hl,ITEM_MOVE_OVERRIDE_FLAG                     ;#5254: 21 90 E1
        ld      (hl),0                                         ;#5257: 36 00
        ret                                                    ;#5259: C9

STORE_ITEM_STATE:
        ; Store updated item state
        ex      de,hl                                          ;#525A: EB
        dec     hl                                             ;#525B: 2B
        ld      (hl),a                                         ;#525C: 77
        ret                                                    ;#525D: C9

SAVE_ITEM_DATA:
        ; Save item data to table
        ld      (hl),c                                         ;#525E: 71
        inc     hl                                             ;#525F: 23
        ld      de,ITEM_PROPERTIES_TABLE                       ;#5260: 11 77 52
        ld      a,c                                            ;#5263: 79
        add     a,a                                            ;#5264: 87
        ld      c,a                                            ;#5265: 4F
        add     a,a                                            ;#5266: 87
        add     a,c                                            ;#5267: 81
        call    ADD_DE_A                                       ;#5268: CD D6 48
        ld      a,(de)                                         ;#526B: 1A
        ld      (hl),a                                         ;#526C: 77
        inc     de                                             ;#526D: 13
        inc     hl                                             ;#526E: 23
        ld      a,(de)                                         ;#526F: 1A
        ld      (hl),a                                         ;#5270: 77
        inc     de                                             ;#5271: 13
        inc     hl                                             ;#5272: 23
        ld      (hl),e                                         ;#5273: 73
        inc     hl                                             ;#5274: 23
        ld      (hl),d                                         ;#5275: 72
        ret                                                    ;#5276: C9

ITEM_PROPERTIES_TABLE:
        ; Per-item anim ptr + 2 (low_x, width) X-range pairs; see INTERNALS.md
        ; Format: FORMAT_ITEM_PROPERTIES
        ; - 6 bytes per entry: animation ptr (word, LE) then four collision bytes
        ; consumed by COLLISION_CHECK_LOOP as two (low_x, width) X-range pairs.
        ; - Small hole: x1=1 (skip-X sentinel) routes straight to stun; (w1, x2) =
        ; stun (low_x, width), w2 unused. Big hole: (x1, w1) = fall zone,
        ; (x2, w2) = stun zone. Flag: (x1, w1) = pickup zone, (x2, w2) unused.
        ; - See INTERNALS.md for the full overloaded layout.
        ITEM_PROP ANIM_SMALL_HOLE_CENTER, 1, 53h, 3Ah, 0       ;#5277: C2 6E 01 53 3A 00
        ITEM_PROP ANIM_SMALL_HOLE_LEFT, 1, 13h, 3Bh, 0         ;#527D: 7B 6F 01 13 3B 00
        ITEM_PROP ANIM_SMALL_HOLE_RIGHT, 1, 92h, 3Bh, 0        ;#5283: 3A 70 01 92 3B 00
        ITEM_PROP ANIM_BIG_HOLE_LEFT, 2Bh, 5Bh, 10h, 90h       ;#5289: 92 6B 2B 5B 10 90
        ITEM_PROP ANIM_BIG_HOLE_RIGHT, 64h, 53h, 48h, 88h      ;#528F: 2E 6D 64 53 48 88
        ITEM_PROP ANIM_FLAG_RIGHT, 80h, 2Ch, 0, 0              ;#5295: 71 71 80 2C 00 00
        ITEM_PROP ANIM_FLAG_LEFT, 2Eh, 2Ch, 0, 0               ;#529B: F9 70 2E 2C 00 00

CHECK_DISTANCE_MILESTONE:
        ; Checks distance for periodic events
        ld      hl,(STAGE_DISTANCE_BCD)                        ;#52A1: 2A E5 E0
        ld      a,h                                            ;#52A4: 7C
        and     1                                              ;#52A5: E6 01
        ret     z                                              ;#52A7: C8
        ld      a,l                                            ;#52A8: 7D
        cp      82h                                            ;#52A9: FE 82
        ret     nz                                             ;#52AB: C0
        ld      hl,DISTANCE_EVENT_TICK                         ;#52AC: 21 E2 E0
        ld      a,(hl)                                         ;#52AF: 7E
        inc     (hl)                                           ;#52B0: 34
        srl     a                                              ;#52B1: CB 3F
        push    af                                             ;#52B3: F5
        ld      hl,DISTANCE_EVENT_TABLE                        ;#52B4: 21 8D 53
        call    ADD_HL_A                                       ;#52B7: CD D1 48
        pop     af                                             ;#52BA: F1
        ld      a,(hl)                                         ;#52BB: 7E
        jr      c,DECODE_DISTANCE_EVENT_NIBBLE                 ;#52BC: 38 04
        rra                                                    ;#52BE: 1F
        rra                                                    ;#52BF: 1F
        rra                                                    ;#52C0: 1F
        rra                                                    ;#52C1: 1F
DECODE_DISTANCE_EVENT_NIBBLE:
        ; Decode one 4-bit nibble from DISTANCE_EVENT_TABLE
        ld      c,a                                            ;#52C2: 4F
        and     3                                              ;#52C3: E6 03
        cp      3                                              ;#52C5: FE 03
        ret     z                                              ;#52C7: C8
        bit     3,c                                            ;#52C8: CB 59
        jr      z,SET_DISTANCE_EVENT_INDEX                     ;#52CA: 28 02
        set     1,a                                            ;#52CC: CB CF
SET_DISTANCE_EVENT_INDEX:
        ; Store decoded index in DISTANCE_EVENT_INDEX (+ secondary-slot flag)
        ld      hl,DISTANCE_EVENT_INDEX                        ;#52CE: 21 94 E1
        ld      (hl),a                                         ;#52D1: 77
        inc     hl                                             ;#52D2: 23
        bit     2,c                                            ;#52D3: CB 51
        jr      z,PROCESS_DYNAMIC_OBJ_ITER                     ;#52D5: 28 02
        ld      (hl),2                                         ;#52D7: 36 02
PROCESS_DYNAMIC_OBJ_ITER:
        ; Next dynamic object iteration
        inc     hl                                             ;#52D9: 23
        ld      (hl),1                                         ;#52DA: 36 01
        inc     hl                                             ;#52DC: 23
        ld      (hl),0                                         ;#52DD: 36 00
        inc     hl                                             ;#52DF: 23
        ld      a,(PENGUIN_SPEED)                              ;#52E0: 3A 00 E1
        srl     a                                              ;#52E3: CB 3F
        srl     a                                              ;#52E5: CB 3F
        ld      (hl),a                                         ;#52E7: 77
        call    PREPARE_CURVE_OVERLAY_ICE                      ;#52E8: CD 72 54
DRAW_DISTANCE_EVENT_STREAM:
        ; Draw the stream selected by DISTANCE_EVENT_INDEX (entries 0-3)
        ld      hl,DISTANCE_EVENT_STREAMS                      ;#52EB: 21 AE 53
WRITE_VRAM_STREAM_INDEXED:
        ; Loads a stream pointer from HL[index*2] and writes to VRAM
        ld      a,(DISTANCE_EVENT_INDEX)                       ;#52EE: 3A 94 E1
        add     a,a                                            ;#52F1: 87
        call    ADD_HL_A                                       ;#52F2: CD D1 48
        ld      e,(hl)                                         ;#52F5: 5E
        inc     hl                                             ;#52F6: 23
        ld      d,(hl)                                         ;#52F7: 56
        ex      de,hl                                          ;#52F8: EB
        call    WRITE_VRAM_STREAM                              ;#52F9: CD 90 45
        ret                                                    ;#52FC: C9

CHECK_FLICKER_TIMER:
        ; Check if flicker timer is active
        ld      a,(PENGUIN_DRIFT_FLAG)                         ;#52FD: 3A 96 E1
        or      a                                              ;#5300: B7
        ret     z                                              ;#5301: C8
        ld      bc,1Fh                                         ;#5302: 01 1F 00
        ld      a,(DISTANCE_EVENT_INDEX)                       ;#5305: 3A 94 E1
        rra                                                    ;#5308: 1F
        jr      c,FLICKER_BUFFER_SHIFT                         ;#5309: 38 10
        ld      a,(FLICKER_SPRITE_BUFFER)                      ;#530B: 3A 50 E1
        ld      hl,FLICKER_SPRITE_BUFFER+1                     ;#530E: 21 51 E1
        ld      de,FLICKER_SPRITE_BUFFER                       ;#5311: 11 50 E1
        ldir                                                   ;#5314: ED B0
        ld      (FLICKER_BUFFER_LAST),a                        ;#5316: 32 6F E1
        jr      UPDATE_MISC_TASKS                              ;#5319: 18 0E

FLICKER_BUFFER_SHIFT:
        ; Shifts sprite attribute history buffer to create flickering effect
        ld      a,(FLICKER_BUFFER_LAST)                        ;#531B: 3A 6F E1
        ld      hl,FLICKER_BUFFER_LAST-1                       ;#531E: 21 6E E1
        ld      de,FLICKER_BUFFER_LAST                         ;#5321: 11 6F E1
        lddr                                                   ;#5324: ED B8
        ld      (FLICKER_SPRITE_BUFFER),a                      ;#5326: 32 50 E1
UPDATE_MISC_TASKS:
        ; Tick the 16-frame pacer (E197); run secondary-slot direction toggle
        call    INIT_VRAM_DONE                                 ;#5329: CD DB 50
        ld      hl,MISC_TICK_PACER                             ;#532C: 21 97 E1
        inc     (hl)                                           ;#532F: 34
        ld      a,(hl)                                         ;#5330: 7E
        and     0Fh                                            ;#5331: E6 0F
        jr      nz,CHECK_DISTANCE_PERIODIC                     ;#5333: 20 10
        dec     hl                                             ;#5335: 2B
        dec     hl                                             ;#5336: 2B
        cp      (hl)                                           ;#5337: BE
        jr      z,CHECK_DISTANCE_PERIODIC                      ;#5338: 28 0B
        dec     (hl)                                           ;#533A: 35
        jr      nz,CHECK_DISTANCE_PERIODIC                     ;#533B: 20 08
        dec     hl                                             ;#533D: 2B
        ld      a,(hl)                                         ;#533E: 7E
        xor     1                                              ;#533F: EE 01
        ld      (hl),a                                         ;#5341: 77
        call    DRAW_DISTANCE_EVENT_STREAM                     ;#5342: CD EB 52
CHECK_DISTANCE_PERIODIC:
        ; Even-hundreds distance milestone (low<45h, every 16 frames)
        ld      hl,(STAGE_DISTANCE_BCD)                        ;#5345: 2A E5 E0
        ld      a,h                                            ;#5348: 7C
        and     1                                              ;#5349: E6 01
        ret     nz                                             ;#534B: C0
        ld      a,l                                            ;#534C: 7D
        cp      45h                                            ;#534D: FE 45
        ret     nc                                             ;#534F: D0
        ld      hl,MISC_TICK_PACER                             ;#5350: 21 97 E1
        ld      a,(hl)                                         ;#5353: 7E
        and     0Fh                                            ;#5354: E6 0F
        ret     nz                                             ;#5356: C0
        dec     hl                                             ;#5357: 2B
        ld      (hl),a                                         ;#5358: 77
        ld      hl,DISTANCE_EVENT_STREAMS+8                    ;#5359: 21 B6 53
        call    WRITE_VRAM_STREAM_INDEXED                      ;#535C: CD EE 52
        call    PREPARE_CURVE_OVERLAY_WATER                    ;#535F: CD 6D 54
HANDLE_PENGUIN_DRIFT:
        ; Auto X-drift driven by latest distance-milestone scenery side; see INTERNALS.md
        ld      hl,PENGUIN_DRIFT_FLAG                          ;#5362: 21 96 E1
        ld      a,(hl)                                         ;#5365: 7E
        or      a                                              ;#5366: B7
        ret     z                                              ;#5367: C8
        inc     hl                                             ;#5368: 23
        inc     hl                                             ;#5369: 23
        dec     (hl)                                           ;#536A: 35
        ret     nz                                             ;#536B: C0
        ld      a,(PENGUIN_SPEED)                              ;#536C: 3A 00 E1
        srl     a                                              ;#536F: CB 3F
        srl     a                                              ;#5371: CB 3F
        ld      (hl),a                                         ;#5373: 77
        ld      hl,DEBUG_FLAGS                                 ;#5374: 21 D1 E0
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#5377: ED 5B 78 E0
        ld      a,(DISTANCE_EVENT_INDEX)                       ;#537B: 3A 94 E1
        rra                                                    ;#537E: 1F
        jr      c,DRIFT_MOVE_RIGHT                             ;#537F: 38 06
        call    MOVE_PENGUIN_LEFT                              ;#5381: CD 6D 4C
        jp      SWAP_AND_UPDATE_PENGUIN_COORDS                 ;#5384: C3 93 4B

DRIFT_MOVE_RIGHT:
        ; Right-direction branch of HANDLE_PENGUIN_DRIFT
        call    MOVE_PENGUIN_RIGHT                             ;#5387: CD 8A 4C
        jp      SWAP_AND_UPDATE_PENGUIN_COORDS                 ;#538A: C3 93 4B

DISTANCE_EVENT_TABLE:
        ; Table of event flags based on distance (FF=End)
        ; Format: FORMAT_DISTANCE_EVENT
        ; - Each nibble: bits 0-1 = sign index (0..2; 3=skip), bit 2 = secondary-slot
        ; flag, bit 3 = forces bit 1 of the index (8h=index 2, Fh and 9h skip).
        DISTANCE_EVENT 0Fh, 0Fh                                ;#538D: FF
        DISTANCE_EVENT 0Fh, 0Fh                                ;#538E: FF
        DISTANCE_EVENT 0Fh, 0Fh                                ;#538F: FF
        DISTANCE_EVENT 9, 9                                    ;#5390: 99
        DISTANCE_EVENT 0Fh, 8                                  ;#5391: F8
        DISTANCE_EVENT 8, 0                                    ;#5392: 80
        DISTANCE_EVENT 0Fh, 0Fh                                ;#5393: FF
        DISTANCE_EVENT 0, 0Fh                                  ;#5394: 0F
        DISTANCE_EVENT 9, 0                                    ;#5395: 90
        DISTANCE_EVENT 0Fh, 8                                  ;#5396: F8
        DISTANCE_EVENT 8, 0Fh                                  ;#5397: 8F
        DISTANCE_EVENT 0Fh, 9                                  ;#5398: F9
        DISTANCE_EVENT 1, 0Fh                                  ;#5399: 1F
        DISTANCE_EVENT 1, 0Fh                                  ;#539A: 1F
        DISTANCE_EVENT 0Fh, 8                                  ;#539B: F8
        DISTANCE_EVENT 5, 5                                    ;#539C: 55
        DISTANCE_EVENT 5, 0Fh                                  ;#539D: 5F
        DISTANCE_EVENT 0, 9                                    ;#539E: 09
        DISTANCE_EVENT 0Fh, 4                                  ;#539F: F4
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53A0: FF
        DISTANCE_EVENT 0Fh, 0                                  ;#53A1: F0
        DISTANCE_EVENT 1, 0Fh                                  ;#53A2: 1F
        DISTANCE_EVENT 0Fh, 0                                  ;#53A3: F0
        DISTANCE_EVENT 9, 0Fh                                  ;#53A4: 9F
        DISTANCE_EVENT 9, 0                                    ;#53A5: 90
        DISTANCE_EVENT 0Fh, 5                                  ;#53A6: F5
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53A7: FF
        DISTANCE_EVENT 0Fh, 1                                  ;#53A8: F1
        DISTANCE_EVENT 8, 0Fh                                  ;#53A9: 8F
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53AA: FF
        DISTANCE_EVENT 9, 0                                    ;#53AB: 90
        DISTANCE_EVENT 9, 9                                    ;#53AC: 99
        DISTANCE_EVENT 0, 0Fh                                  ;#53AD: 0F

DISTANCE_EVENT_STREAMS:
        ; 8-entry pointer table of distance-milestone VRAM streams (see INTERNALS.md)
        dw      STREAM_ICE_LEFT                                ;#53AE: BE 53
        dw      STREAM_ICE_RIGHT                               ;#53B0: CF 53
        dw      STREAM_WATER_CURVE_LEFT                        ;#53B2: F1 53
        dw      STREAM_WATER_CURVE_RIGHT                       ;#53B4: 10 54
        dw      STREAM_SMALL_ICE                               ;#53B6: E0 53
        dw      STREAM_SMALL_ICE                               ;#53B8: E0 53
        dw      STREAM_WATER_STRAIGHT_RIGHT                    ;#53BA: 4E 54
        dw      STREAM_WATER_STRAIGHT_LEFT                     ;#53BC: 2F 54

STREAM_ICE_LEFT:
        ; VRAM stream for ice patch (left-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#53BE: 49 39
        VRAM_TILES "1414131315303031101010323323"              ;#53C0: 14 14 13 13 15 30 30 31 10 10 10 32 33 23
        STREAM_BLOCK_END                                       ;#53CE: FF

STREAM_ICE_RIGHT:
        ; VRAM stream for ice patch (right-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#53CF: 49 39
        VRAM_TILES "2374321010103130301513131414"              ;#53D1: 23 74 32 10 10 10 31 30 30 15 13 13 14 14
        STREAM_BLOCK_END                                       ;#53DF: FF

STREAM_SMALL_ICE:
        ; VRAM stream for small ice patch
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#53E0: 49 39
        VRAM_TILES "1514131252100F0F101112131415"              ;#53E2: 15 14 13 12 52 10 0F 0F 10 11 12 13 14 15
        STREAM_BLOCK_END                                       ;#53F0: FF

STREAM_WATER_CURVE_LEFT:
        ; VRAM stream for curved water (left-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#53F1: 49 39
        VRAM_TILES "14141313153030311010104147535354"          ;#53F3: 14 14 13 13 15 30 30 31 10 10 10 41 47 53 53 54
        VRAM_TILES "54545454545454"                            ;#5403: 54 54 54 54 54 54 54
        STREAM_NEXT_BLOCK                                      ;#540A: FE
        VRAM_NAME_TABLE 0Bh, 12h                               ;#540B: 72 39
        VRAM_TILES "0F3E"                                      ;#540D: 0F 3E
        STREAM_BLOCK_END                                       ;#540F: FF

STREAM_WATER_CURVE_RIGHT:
        ; VRAM stream for curved water (right-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 0                                 ;#5410: 40 39
        VRAM_TILES "54545454545454545353888210101031"          ;#5412: 54 54 54 54 54 54 54 54 53 53 88 82 10 10 10 31
        VRAM_TILES "30301513131414"                            ;#5422: 30 30 15 13 13 14 14
        STREAM_NEXT_BLOCK                                      ;#5429: FE
        VRAM_NAME_TABLE 0Bh, 0Ch                               ;#542A: 6C 39
        VRAM_TILES "7F0F"                                      ;#542C: 7F 0F
        STREAM_BLOCK_END                                       ;#542E: FF

STREAM_WATER_STRAIGHT_LEFT:
        ; VRAM stream for straight water (left-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 0                                 ;#542F: 40 39
        VRAM_TILES "040404040404040404040404047D7A0F"          ;#5431: 04 04 04 04 04 04 04 04 04 04 04 04 04 7D 7A 0F
        VRAM_TILES "0F101112131415"                            ;#5441: 0F 10 11 12 13 14 15
        STREAM_NEXT_BLOCK                                      ;#5448: FE
        VRAM_NAME_TABLE 0Bh, 0Ch                               ;#5449: 6C 39
        VRAM_TILES "7978"                                      ;#544B: 79 78
        STREAM_BLOCK_END                                       ;#544D: FF

STREAM_WATER_STRAIGHT_RIGHT:
        ; VRAM stream for straight water (right-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#544E: 49 39
        VRAM_TILES "1514131252100F0F393C040404040404"          ;#5450: 15 14 13 12 52 10 0F 0F 39 3C 04 04 04 04 04 04
        VRAM_TILES "04040404040404"                            ;#5460: 04 04 04 04 04 04 04
        STREAM_NEXT_BLOCK                                      ;#5467: FE
        VRAM_NAME_TABLE 0Bh, 12h                               ;#5468: 72 39
        VRAM_TILES "3738"                                      ;#546A: 37 38
        STREAM_BLOCK_END                                       ;#546C: FF

PREPARE_CURVE_OVERLAY_WATER:
        ; Set HL=ROAD_WATER_RIGHT_1_INIT for the curve-tile overlay write
        ld      hl,ROAD_WATER_RIGHT_1_INIT                     ;#546D: 21 90 72
        jr      UPDATE_CURVE_OVERLAY_SEGMENT                   ;#5470: 18 03

PREPARE_CURVE_OVERLAY_ICE:
        ; Set HL=ROAD_ICE_RIGHT_1_INIT for the curve-tile overlay write
        ld      hl,ROAD_ICE_RIGHT_1_INIT                       ;#5472: 21 1E 72
UPDATE_CURVE_OVERLAY_SEGMENT:
        ; Upload curve road-segment tiles when DISTANCE_EVENT_INDEX bit 1 is set
        ld      a,(DISTANCE_EVENT_INDEX)                       ;#5475: 3A 94 E1
        bit     1,a                                            ;#5478: CB 4F
        ret     z                                              ;#547A: C8
        rra                                                    ;#547B: 1F
        ld      a,(hl)                                         ;#547C: 7E
        jr      nc,UPDATE_CURVE_OVERLAY_DONE                   ;#547D: 30 02
        sub     10h                                            ;#547F: D6 10
UPDATE_CURVE_OVERLAY_DONE:
        ; Rejoin point in UPDATE_CURVE_OVERLAY_SEGMENT after the curve-flag check
        ld      e,a                                            ;#5481: 5F
        jp      UPLOAD_ROAD_SEG_DONE                           ;#5482: C3 C9 50

UPDATE_VICTORY_PENGUIN_ANIM:
        ; Update penguin waddling animation during goal sequence
        ld      a,(FRAME_COUNTER)                              ;#5485: 3A 03 E0
        and     3                                              ;#5488: E6 03
        ret     nz                                             ;#548A: C0
        inc     c                                              ;#548B: 0C
        jr      nz,CALC_VICTORY_WADDLE_OFFSET                  ;#548C: 20 26
        ld      a,(VICTORY_WADDLE_BASE_X)                      ;#548E: 3A 39 E1
        ld      c,a                                            ;#5491: 4F
        xor     a                                              ;#5492: AF
        ld      b,a                                            ;#5493: 47
        ld      hl,70h                                         ;#5494: 21 70 00
        sbc     hl,bc                                          ;#5497: ED 42
        ld      a,(VICTORY_WADDLE_STEP)                        ;#5499: 3A 38 E1
        ld      b,a                                            ;#549C: 47
        ld      e,l                                            ;#549D: 5D
        ld      d,h                                            ;#549E: 54
VICTORY_CALC_LOOP:
        ; Loop for victory waddle calculation
        add     hl,de                                          ;#549F: 19
        djnz    VICTORY_CALC_LOOP                              ;#54A0: 10 FD
        ld      a,h                                            ;#54A2: 7C
        rlca                                                   ;#54A3: 07
        rlca                                                   ;#54A4: 07
        rlca                                                   ;#54A5: 07
        rlca                                                   ;#54A6: 07
        and     0F0h                                           ;#54A7: E6 F0
        ld      e,a                                            ;#54A9: 5F
        ld      a,l                                            ;#54AA: 7D
        rrca                                                   ;#54AB: 0F
        rrca                                                   ;#54AC: 0F
        rrca                                                   ;#54AD: 0F
        rrca                                                   ;#54AE: 0F
        and     0Fh                                            ;#54AF: E6 0F
        or      e                                              ;#54B1: B3
        add     a,c                                            ;#54B2: 81
        ld      h,a                                            ;#54B3: 67
CALC_VICTORY_WADDLE_OFFSET:
        ; Calculate new Y-offset for waddle effect
        ld      a,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)       ;#54B4: 3A 78 E0
        dec     a                                              ;#54B7: 3D
        ld      l,a                                            ;#54B8: 6F
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#54B9: CD BD 4B
        call    UPDATE_PENGUIN_SPRITES                         ;#54BC: CD A2 4C
        ld      hl,VICTORY_WADDLE_STEP                         ;#54BF: 21 38 E1
        inc     (hl)                                           ;#54C2: 34
        ld      a,10h                                          ;#54C3: 3E 10
        cp      (hl)                                           ;#54C5: BE
        ret                                                    ;#54C6: C9

CYCLE_GOAL_PENGUIN_PATTERNS:
        ; Cycle penguin sprite patterns during victory dance
        xor     a                                              ;#54C7: AF
        ld      (VICTORY_DANCE_COUNTER),a                      ;#54C8: 32 3A E1
UPDATE_VICTORY_DANCE:
        ; Update victory dance animation counter
        ld      hl,VICTORY_DANCE_COUNTER                       ;#54CB: 21 3A E1
        ld      a,(hl)                                         ;#54CE: 7E
        inc     (hl)                                           ;#54CF: 34
        ld      hl,VICTORY_DANCE_FRAME_1                       ;#54D0: 21 F8 54
        rra                                                    ;#54D3: 1F
        jr      nc,SET_VICTORY_FRAME_2                         ;#54D4: 30 03
        ld      hl,VICTORY_DANCE_FRAME_2                       ;#54D6: 21 0C 55
SET_VICTORY_FRAME_2:
        ; Select second frame of victory dance
        call    WRITE_VRAM_TILES_STREAM                        ;#54D9: CD 25 45
        ret                                                    ;#54DC: C9

LOAD_VICTORY_GFX:
        ; Load supplementary sprite data for victory sequence
        ld      hl,VICTORY_SPRITE_PATTERNS                     ;#54DD: 21 2A 6B
        call    DECOMPRESS_VRAM_INDIRECT                       ;#54E0: CD 50 45
        ld      hl,GOAL_FLAG_ATTRIBUTES                        ;#54E3: 21 EF 66
        ld      de,SAT_MIRROR + SPRITE_AUX + ATTR_Y            ;#54E6: 11 6C E0
        ld      bc,10h                                         ;#54E9: 01 10 00
        ldir                                                   ;#54EC: ED B0
        call    SYNC_SPRITE_ATTRIBUTES_ALL                     ;#54EE: CD 8C 66
        ld      hl,VICTORY_DANCE_FRAME_3                       ;#54F1: 21 16 55
        call    WRITE_VRAM_TILES_STREAM                        ;#54F4: CD 25 45
        ret                                                    ;#54F7: C9

VICTORY_DANCE_FRAME_1:
        ; Victory dance tile-stream frame 1
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 8                              ;#54F8: E1
        VRAM_TILE_COLUMN 0Fh                                   ;#54F9: EF
        VRAM_TILES "B6B7"                                      ;#54FA: B6 B7
        VRAM_TILE_COLUMN 0Eh                                   ;#54FC: EE
        VRAM_TILES "B8B9BABB"                                  ;#54FD: B8 B9 BA BB
        VRAM_TILE_COLUMN 0Eh                                   ;#5501: EE
        VRAM_TILES "BEBFC0BC"                                  ;#5502: BE BF C0 BC
        VRAM_TILE_COLUMN 0Eh                                   ;#5506: EE
        VRAM_TILES "C3C4C5C6"                                  ;#5507: C3 C4 C5 C6
        db      00h                                            ;#550B: 00

VICTORY_DANCE_FRAME_2:
        ; Victory dance tile-stream frame 2
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3A00h, 1                              ;#550C: 02
        VRAM_TILE_COLUMN 0Eh                                   ;#550D: EE
        VRAM_TILES "C2"                                        ;#550E: C2
        VRAM_TILE_COLUMN 0Eh                                   ;#550F: EE
        VRAM_TILES "BDC1"                                      ;#5510: BD C1
        VRAM_TILE_COLUMN 0Eh                                   ;#5512: EE
        VRAM_TILES "C7C8"                                      ;#5513: C7 C8
        db      00h                                            ;#5515: 00

VICTORY_DANCE_FRAME_3:
        ; Victory dance tile-stream frame 3 (penguin on pedestal)
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 8                              ;#5516: E1
        VRAM_TILE_COLUMN 0Eh                                   ;#5517: EE
        VRAM_TILES "D2D5D8"                                    ;#5518: D2 D5 D8
        VRAM_TILE_COLUMN 0Eh                                   ;#551B: EE
        VRAM_TILES "D3D6D9DB"                                  ;#551C: D3 D6 D9 DB
        VRAM_TILE_COLUMN 0Eh                                   ;#5520: EE
        VRAM_TILES "D4D7DADC"                                  ;#5521: D4 D7 DA DC
        VRAM_TILE_COLUMN 0Eh                                   ;#5525: EE
        VRAM_TILES "DDDEDF0F"                                  ;#5526: DD DE DF 0F
        db      00h                                            ;#552A: 00

INIT_GOAL_GRAPHICS:
        ; Decompress and initialize goal-specific VRAM graphics
        ld      hl,GFX_GOAL_COLOR_PATCH                        ;#552B: 21 F9 65
        LOAD_VRAM_WRITE de, 1100h                              ;#552E: 11 00 51
        call    DECOMPRESS_VRAM_DIRECT                         ;#5531: CD 54 45
        ld      hl,COUNTRY_NAME_POINTERS                       ;#5534: 21 88 55
        ld      a,(CURRENT_STAGE_INDEX)                        ;#5537: 3A E1 E0
        ld      c,a                                            ;#553A: 4F
        add     a,a                                            ;#553B: 87
        call    ADD_HL_A                                       ;#553C: CD D1 48
        ld      e,(hl)                                         ;#553F: 5E
        inc     hl                                             ;#5540: 23
        ld      d,(hl)                                         ;#5541: 56
        ex      de,hl                                          ;#5542: EB
        LOAD_NAME_TABLE de, 22, 12                             ;#5543: 11 CC 3A
        call    WRITE_VRAM_STREAM_WITH_OFFSET                  ;#5546: CD 94 45
        ld      hl,FLAG_PTR_TABLE                              ;#5549: 21 F1 55
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#554C: 3A E0 E0
        and     0Fh                                            ;#554F: E6 0F
        add     a,a                                            ;#5551: 87
        call    ADD_HL_A                                       ;#5552: CD D1 48
        ld      e,(hl)                                         ;#5555: 5E
        inc     hl                                             ;#5556: 23
        ld      d,(hl)                                         ;#5557: 56
        ex      de,hl                                          ;#5558: EB
        ld      de,GFX_FLAG_VRAM_DEST                          ;#5559: 11 40 5F
        call    DECOMPRESS_VRAM_DIRECT                         ;#555C: CD 54 45
        ld      a,(hl)                                         ;#555F: 7E
        ld      (SAT_MIRROR + SPRITE_4 + ATTR_COLOR),a         ;#5560: 32 63 E0
        inc     hl                                             ;#5563: 23
        ld      a,(hl)                                         ;#5564: 7E
        ld      (SAT_MIRROR + SPRITE_5 + ATTR_COLOR),a         ;#5565: 32 67 E0
        jr      SYNC_GOAL_FLAG_SPRITES                         ;#5568: 18 11

UPDATE_GOAL_FLAG_POSITION:
        ; Handle the flag ascending/positioning logic
        ld      a,(SAT_MIRROR + SPRITE_4 + ATTR_Y)             ;#556A: 3A 60 E0
        sub     2                                              ;#556D: D6 02
        cp      36h                                            ;#556F: FE 36
        ret     z                                              ;#5571: C8
        ld      (SAT_MIRROR + SPRITE_4 + ATTR_Y),a             ;#5572: 32 60 E0
        ld      (SAT_MIRROR + SPRITE_5 + ATTR_Y),a             ;#5575: 32 64 E0
        ld      (SAT_MIRROR + SPRITE_6 + ATTR_Y),a             ;#5578: 32 68 E0
SYNC_GOAL_FLAG_SPRITES:
        ; Copy flag sprite attributes to VRAM
        ld      hl,SAT_MIRROR + SPRITE_4 + ATTR_Y              ;#557B: 21 60 E0
        LOAD_SPRITE_ATTR de, 4, 0                              ;#557E: 11 10 3B
        ld      bc,0Ch                                         ;#5581: 01 0C 00
        call    COPY_RAM_TO_VRAM                               ;#5584: CD DE 44
        ret                                                    ;#5587: C9

COUNTRY_NAME_POINTERS:
        ; Table of pointers to country name strings (Japan to South Pole)
        dw      TXT_JAPAN                                      ;#5588: 9C 55
        dw      TXT_AUSTRALIA                                  ;#558A: A4 55
        dw      TXT_AUSTRALIA                                  ;#558C: A4 55
        dw      TXT_FRANCE                                     ;#558E: B0 55
        dw      TXT_NEW_ZEALAND                                ;#5590: B9 55
        dw      TXT_SOUTH_POLE                                 ;#5592: EA 55
        dw      TXT_USA                                        ;#5594: C7 55
        dw      TXT_USA                                        ;#5596: C7 55
        dw      TXT_ARGENTINA                                  ;#5598: CD 55
        dw      TXT_UK                                         ;#559A: D9 55

TXT_JAPAN:
        ; "JAPAN" string (Encoding: ASCII-0x20)
        ; Format: FORMAT_VRAM_STRING
        abyte -20h "@JAPAN@"                                   ;#559C: 20 2A 21 30 21 2E 20
        db      0FFh                                           ;#55A3: FF

TXT_AUSTRALIA:
        ; "AUSTRALIA" string (Encoding: ASCII-0x20)
        ; Format: FORMAT_VRAM_STRING
        abyte -20h "@AUSTRALIA@"                               ;#55A4: 20 21 35 33 34 32 21 2C 29 21 20
        db      0FFh                                           ;#55AF: FF

TXT_FRANCE:
        ; "FRANCE" string (Encoding: ASCII-0x20)
        ; Format: FORMAT_VRAM_STRING
        abyte -20h "@", 0E9h, "RANCE@"                         ;#55B0: 20 C9 32 21 2E 23 25 20
        db      0FFh                                           ;#55B8: FF

TXT_NEW_ZEALAND:
        ; "NEW ZEALAND" string (Encoding: ASCII-0x20)
        ; Format: FORMAT_VRAM_STRING
        abyte -20h "@NE", 0EAh, "/", 0EBh, "EALAND@"           ;#55B9: 20 2E 25 CA 0F CB 25 21 2C 21 2E 24 20
        db      0FFh                                           ;#55C6: FF

TXT_USA:
        ; "USA" string (Encoding: ASCII-0x20)
        ; Format: FORMAT_VRAM_STRING
        abyte -20h "@USA@"                                     ;#55C7: 20 35 33 21 20
        db      0FFh                                           ;#55CC: FF

TXT_ARGENTINA:
        ; "ARGENTINA" string (Encoding: ASCII-0x20)
        ; Format: FORMAT_VRAM_STRING
        abyte -20h "@ARGENTINA@"                               ;#55CD: 20 21 32 27 25 2E 34 29 2E 21 20
        db      0FFh                                           ;#55D8: FF

TXT_UK:
        ; "UNITED KINGDOM" string (Encoding: ASCII-0x20)
        ; Format: FORMAT_VRAM_STRING
        abyte -20h "@UNITED/KINGDOM@"                          ;#55D9: 20 35 2E 29 34 25 24 0F 2B 29 2E 27 24 2F 2D 20
        db      0FFh                                           ;#55E9: FF

TXT_SOUTH_POLE:
        ; "SOUTH POLE" (南極点) string
        ; Format: FORMAT_VRAM_STRING
        abyte -20h "@", 0EEh, 0EFh, 0F0h, 0F1h, "@"            ;#55EA: 20 CE CF D0 D1 20
        db      0FFh                                           ;#55F0: FF

FLAG_PTR_TABLE:
        ; Pointer table for finish line flag graphics (indexed by last time digit 0-9).
        ; Each flag=64 bytes (2x16x16 sprites overlaid). MSX blocks A,C top / B,D bottom.
        dw      FLAG_DATA_UK                                   ;#55F1: CD 56
        dw      FLAG_DATA_JAPAN                                ;#55F3: 05 56
        dw      FLAG_DATA_AUSTRALIA                            ;#55F5: 1E 56
        dw      FLAG_DATA_AUSTRALIA                            ;#55F7: 1E 56
        dw      FLAG_DATA_FRANCE                               ;#55F9: 4D 56
        dw      FLAG_DATA_NEW_ZEALAND                          ;#55FB: 5A 56
        dw      FLAG_DATA_SOUTH_POLE                           ;#55FD: 0A 57
        dw      FLAG_DATA_USA                                  ;#55FF: 86 56
        dw      FLAG_DATA_USA                                  ;#5601: 86 56
        dw      FLAG_DATA_ARGENTINA                            ;#5603: AA 56

FLAG_DATA_JAPAN:
        ; Japan flag graphics (red circle on white)
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "0200820307030F82070309008280C003"             ;#5605: 02 00 82 03 07 03 0F 82 07 03 09 00 82 80 C0 03
        dh      "E082C0802700"                                 ;#5615: E0 82 C0 80 27 00
        db      00h                                            ;#561B: 00 06 0F
        FLAG_COLORS COLOR_DARK_RED, COLOR_WHITE                ;#561C

FLAG_DATA_AUSTRALIA:
        ; Australia flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "87CC6D0CFF0C6DCC090087C08000C000"             ;#561E: 87 CC 6D 0C FF 0C 6D CC 09 00 87 C0 80 00 C0 00
        dh      "80C00900070002FF02FB01FF0400893F"             ;#562E: 80 C0 09 00 07 00 02 FF 02 FB 01 FF 04 00 89 3F
        dh      "3B3F3D2F3B3FFFF703FF0400"                     ;#563E: 3B 3F 3D 2F 3B 3F FF F7 03 FF 04 00
        db      00h                                            ;#564A: 00 06 0D
        FLAG_COLORS COLOR_DARK_RED, COLOR_MAGENTA              ;#564B

FLAG_DATA_FRANCE:
        ; France flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "10000C3F04000CF81400"                         ;#564D: 10 00 0C 3F 04 00 0C F8 14 00
        db      00h                                            ;#5657: 00 06 04
        FLAG_COLORS COLOR_DARK_RED, COLOR_DARK_BLUE            ;#5658

FLAG_DATA_NEW_ZEALAND:
        ; New Zealand flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "87CC6D0CFF0C6DCC090087C08000C000"             ;#565A: 87 CC 6D 0C FF 0C 6D CC 09 00 87 C0 80 00 C0 00
        dh      "80C00900070005FF04008C3F3F373F3B"             ;#566A: 80 C0 09 00 07 00 05 FF 04 00 8C 3F 3F 37 3F 3B
        dh      "2F3FFFFFF7FFFF0400"                           ;#567A: 2F 3F FF FF F7 FF FF 04 00
        db      00h                                            ;#5683: 00 06 0D
        FLAG_COLORS COLOR_DARK_RED, COLOR_MAGENTA              ;#5684

FLAG_DATA_USA:
        ; USA flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "070085FF00FF00FF05008BFF00FF00FF"             ;#5686: 07 00 85 FF 00 FF 00 FF 05 00 8B FF 00 FF 00 FF
        dh      "00FF00FF00FF04008655AA55AA55AA1A"             ;#5696: 00 FF 00 FF 00 FF 04 00 86 55 AA 55 AA 55 AA 1A
        dh      "00"                                           ;#56A6: 00
        db      00h                                            ;#56A7: 00 06 04
        FLAG_COLORS COLOR_DARK_RED, COLOR_DARK_BLUE            ;#56A8

FLAG_DATA_ARGENTINA:
        ; Argentina flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "040084010303010C008480C0C0800800"             ;#56AA: 04 00 84 01 03 03 01 0C 00 84 80 C0 C0 80 08 00
        dh      "04FF040004FF040004FF040004FF0400"             ;#56BA: 04 FF 04 00 04 FF 04 00 04 FF 04 00 04 FF 04 00
        db      00h                                            ;#56CA: 00 0A 07
        FLAG_COLORS COLOR_DARK_YELLOW, COLOR_CYAN              ;#56CB

FLAG_DATA_UK:
        ; United Kingdom flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "8C6131190D01FFFF010D19316104008C"             ;#56CD: 8C 61 31 19 0D 01 FF FF 01 0D 19 31 61 04 00 8C
        dh      "868C98B080FFFF80B0988C860400840C"             ;#56DD: 86 8C 98 B0 80 FF FF 80 B0 98 8C 86 04 00 84 0C
        dh      "84C0E0040084E0C0840C040084302103"             ;#56ED: 84 C0 E0 04 00 84 E0 C0 84 0C 04 00 84 30 21 03
        dh      "07040084070321300400"                         ;#56FD: 07 04 00 84 07 03 21 30 04 00
        db      00h                                            ;#5707: 00 08 05
        FLAG_COLORS COLOR_MED_RED, COLOR_LIGHT_BLUE            ;#5708

FLAG_DATA_SOUTH_POLE:
        ; South Pole flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "8B03040A0C2C3E1808080C0705008BC0"             ;#570A: 8B 03 04 0A 0C 2C 3E 18 08 08 0C 07 05 00 8B C0
        dh      "20501030781C141030E0050085000002"             ;#571A: 20 50 10 30 78 1C 14 10 30 E0 05 00 85 00 00 02
        dh      "010303008300001805008500004080C0"             ;#572A: 01 03 03 00 83 00 00 18 05 00 85 00 00 40 80 C0
        dh      "0300830000180500"                             ;#573A: 03 00 83 00 00 18 05 00
        db      00h                                            ;#5742: 00 01 0A
        FLAG_COLORS COLOR_BLACK, COLOR_DARK_YELLOW             ;#5743

HUD_STATIC_TEXT:
        ; Static HUD labels and sign graphics (e.g. "KM", "STAGE")
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 0, 0Ch                                 ;#5745: 0C 38
        abyte -20h "HI@"                                       ;#5747: 28 29 20
        STREAM_NEXT_BLOCK                                      ;#574A: FE
        VRAM_NAME_TABLE 0, 16h                                 ;#574B: 16 38
        abyte -20h "STAGE@"                                    ;#574D: 33 34 21 27 25 20
        STREAM_NEXT_BLOCK                                      ;#5753: FE
        VRAM_NAME_TABLE 1, 2                                   ;#5754: 22 38
        abyte -20h "TIME@"                                     ;#5756: 34 29 2D 25 20
        STREAM_NEXT_BLOCK                                      ;#575B: FE
        VRAM_NAME_TABLE 1, 0Ch                                 ;#575C: 2C 38
        abyte -20h "XZ[    `a"                                 ;#575E: 38 3A 3B 00 00 00 00 40 41
        STREAM_NEXT_BLOCK                                      ;#5767: FE
        VRAM_NAME_TABLE 1, 16h                                 ;#5768: 36 38
        abyte -20h "FQW"                                       ;#576A: 26 31 37
        STREAM_NEXT_BLOCK                                      ;#576D: FE
        VRAM_NAME_TABLE 0, 2                                   ;#576E: 02 38
        abyte -20h "1P@"                                       ;#5770: 11 30 20
        STREAM_BLOCK_END                                       ;#5773: FF

KONAMI_COPYRIGHT_TEXT:
        ; Copyright text stream ("© 1984") for opening animation
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 8, 0Bh                                 ;#5774: 0B 39
        abyte -20h ":;<=>? 1984"                               ;#5776: 1A 1B 1C 1D 1E 1F 00 11 19 18 14
        STREAM_BLOCK_END                                       ;#5781: FF

MSG_PLAY_SELECT:
        ; VRAM message stream for title/logo
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 0Dh, 0Bh                               ;#5782: AB 39
        abyte -20h "PLAY SELECT"                               ;#5784: 30 2C 21 39 00 33 25 2C 25 23 34
        STREAM_NEXT_BLOCK                                      ;#578F: FE
        VRAM_NAME_TABLE 10h, 6                                 ;#5790: 06 3A
        abyte -20h "1@", 5Ch, "]  PLAY ^_ JOYSTICK"            ;#5792: 11 20 3C 3D 00 00 30 2C 21 39 00 3E 3F 00 2A 2F 39 33 34 29 23 2B
        STREAM_NEXT_BLOCK                                      ;#57A8: FE
        VRAM_NAME_TABLE 12h, 6                                 ;#57A9: 46 3A
        abyte -20h "2@", 5Ch, "]  PLAY ^_ KEYBOABD"            ;#57AB: 12 20 3C 3D 00 00 30 2C 21 39 00 3E 3F 00 2B 25 39 22 2F 21 22 24
        STREAM_BLOCK_END                                       ;#57C1: FF

MSG_TIME_OUT:
        ; Stream starting with STAGE message
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 7, 0Ch                                 ;#57C2: EC 38
        abyte -20h "TIME OUT"                                  ;#57C4: 34 29 2D 25 00 2F 35 34
        STREAM_BLOCK_END                                       ;#57CC: FF

MSG_VIDEO_CARTRIDGE:
        ; Stream starting with KONAMI message
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 0Bh, 6                                 ;#57CD: 66 39
        abyte -20h "@ VIDEO CARTRIDGE @"                       ;#57CF: 20 00 36 29 24 25 2F 00 23 21 32 34 32 29 24 27 25 00 20
        STREAM_BLOCK_END                                       ;#57E2: FF

INPUT_DEMO_PLAY_DATA:
        ; Stored inputs used for demo play
        ; Format: FORMAT_INPUT_DEMO_PLAY
        INPUT_DEMO_PLAY KEY_NONE                               ;#57E3: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57E4: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57E5: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57E6: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57E7: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57E8: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57E9: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57EA: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57EB: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57EC: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57ED: 00
        INPUT_DEMO_PLAY KEY_UP                                 ;#57EE: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#57EF: 09
        INPUT_DEMO_PLAY KEY_UP                                 ;#57F0: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#57F1: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#57F2: 11
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT                      ;#57F3: 05
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT                      ;#57F4: 05
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#57F5: 09
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#57F6: 09
        INPUT_DEMO_PLAY KEY_UP                                 ;#57F7: 01
        INPUT_DEMO_PLAY KEY_DOWN | KEY_LEFT                    ;#57F8: 06
        INPUT_DEMO_PLAY KEY_LEFT                               ;#57F9: 04
        INPUT_DEMO_PLAY KEY_SPACE                              ;#57FA: 10
        INPUT_DEMO_PLAY KEY_UP                                 ;#57FB: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#57FC: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#57FD: 11
        INPUT_DEMO_PLAY KEY_SPACE                              ;#57FE: 10
        INPUT_DEMO_PLAY KEY_UP                                 ;#57FF: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5800: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5801: 09
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5802: 09
        INPUT_DEMO_PLAY KEY_UP                                 ;#5803: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT                      ;#5804: 05
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT | KEY_SPACE          ;#5805: 15
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5806: 09
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT | KEY_SPACE         ;#5807: 19
        INPUT_DEMO_PLAY KEY_UP                                 ;#5808: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5809: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT                      ;#580A: 05
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#580B: 11
        INPUT_DEMO_PLAY KEY_UP                                 ;#580C: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#580D: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#580E: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#580F: 11
        INPUT_DEMO_PLAY KEY_UP                                 ;#5810: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5811: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5812: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#5813: 11
        INPUT_DEMO_PLAY KEY_UP                                 ;#5814: 01
        INPUT_DEMO_PLAY KEY_NONE                               ;#5815: 00
        INPUT_DEMO_PLAY KEY_RIGHT | KEY_SPACE                  ;#5816: 18
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT | KEY_SPACE         ;#5817: 19
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5818: 09
        INPUT_DEMO_PLAY KEY_UP                                 ;#5819: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#581A: 11
        INPUT_DEMO_PLAY KEY_UP                                 ;#581B: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#581C: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#581D: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#581E: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#581F: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5820: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5821: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5822: 01

INIT_ALL_VDP_PLANES:
        ; Sets up all three VDP pattern planes
        LOAD_VRAM_ADDRESS de, 0                                ;#5823: 11 00 00
        call    INIT_VDP_PLANE                                 ;#5826: CD 35 58
        LOAD_VRAM_ADDRESS de, 800h                             ;#5829: 11 00 08
        call    INIT_VDP_PLANE                                 ;#582C: CD 35 58
        LOAD_VRAM_ADDRESS de, 1000h                            ;#582F: 11 00 10
        jp      INIT_VDP_PLANE                                 ;#5832: C3 35 58

INIT_VDP_PLANE:
        ; Sets up a single VDP pattern plane
        push    de                                             ;#5835: D5
        xor     a                                              ;#5836: AF
        ; This loop seeds solid color tiles for each MSX palette color index.
        ld      c,10h                                          ;#5837: 0E 10
VDP_INIT_COLOR_BLOCK:
        ; Outer loop for clearing VRAM plane
        ld      b,8                                            ;#5839: 06 08
VDP_INIT_COLOR_BLOCK_LINE:
        ; Inner loop for clearing VRAM plane
        call    WRITE_VRAM_BYTE                                ;#583B: CD B3 48
        inc     de                                             ;#583E: 13
        djnz    VDP_INIT_COLOR_BLOCK_LINE                      ;#583F: 10 FA
        inc     a                                              ;#5841: 3C
        dec     c                                              ;#5842: 0D
        jr      nz,VDP_INIT_COLOR_BLOCK                        ;#5843: 20 F4
        ld      bc,270h                                        ;#5845: 01 70 02
        LOAD_VRAM_COLOR a, COLOR_WHITE, COLOR_TRANSPARENT      ;#5848: 3E F0
        call    FILL_VRAM                                      ;#584A: CD F1 44
        ld      hl,GFX_STARTUP_COLOR_TABLE                     ;#584D: 21 59 5D
        call    DECOMPRESS_VRAM_DATA_ONLY                      ;#5850: CD 5D 45
        ld      b,16h                                          ;#5853: 06 16
VDP_INIT_COLOR_LOOP:
        ; Loop for decompressing startup patterns
        ld      hl,GFX_STARTUP_COLOR_TABLE_LOOP                ;#5855: 21 8F 5D
        push    bc                                             ;#5858: C5
        call    DECOMPRESS_VRAM_DATA_ONLY                      ;#5859: CD 5D 45
        pop     bc                                             ;#585C: C1
        djnz    VDP_INIT_COLOR_LOOP                            ;#585D: 10 F6
        pop     de                                             ;#585F: D1
        LOAD_VRAM_WRITE hl, 2000h                              ;#5860: 21 00 60
        add     hl,de                                          ;#5863: 19
        ex      de,hl                                          ;#5864: EB
        ld      hl,GFX_STARTUP_PATTERNS                        ;#5865: 21 74 58
        call    DECOMPRESS_VRAM_DIRECT                         ;#5868: CD 54 45
        ld      hl,GFX_STARTUP_PATT_EXTRA1                     ;#586B: 21 04 5C
        call    DECOMPRESS_VRAM_DATA_ONLY                      ;#586E: CD 5D 45
        ; Fallthrough: GFX_STARTUP_PATT_EXTRA2
        jp      DECOMPRESS_VRAM_DATA_ONLY                      ;#5871: C3 5D 45

GFX_STARTUP_PATTERNS:
        ; Main startup patterns
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "4000400083001C22036385221C001838"             ;#5874: 40 00 40 00 83 00 1C 22 03 63 85 22 1C 00 18 38
        dh      "0418AE7E003E63030E3C707F003E6303"             ;#5884: 04 18 AE 7E 00 3E 63 03 0E 3C 70 7F 00 3E 63 03
        dh      "0E03633E000E1E3666667F06007F607E"             ;#5894: 0E 03 63 3E 00 0E 1E 36 66 66 7F 06 00 7F 60 7E
        dh      "6303633E003E63607E63633E007F6306"             ;#58A4: 63 03 63 3E 00 3E 63 60 7E 63 63 3E 00 7F 63 06
        dh      "0C03189A003E63633E63633E003E6363"             ;#58B4: 0C 03 18 9A 00 3E 63 63 3E 63 63 3E 00 3E 63 63
        dh      "3F03633E0F1026282826100F03830443"             ;#58C4: 3F 03 63 3E 0F 10 26 28 28 26 10 0F 03 83 04 43
        dh      "8A83031C3870E1CDCDFD79030081EE03"             ;#58D4: 8A 83 03 1C 38 70 E1 CD CD FD 79 03 00 81 EE 03
        dh      "6B81EB030089731A7A5A7A000300F304"             ;#58E4: 6B 81 EB 03 00 89 73 1A 7A 5A 7A 00 03 00 F3 04
        dh      "5B0400817E0400921C3663637F636300"             ;#58F4: 5B 04 00 81 7E 04 00 92 1C 36 63 63 7F 63 63 00
        dh      "7E63637E63637E003E63036085633E00"             ;#5904: 7E 63 63 7E 63 63 7E 00 3E 63 03 60 85 63 3E 00
        dh      "7C6603639B667C007F60607E60607F00"             ;#5914: 7C 66 03 63 9B 66 7C 00 7F 60 60 7E 60 60 7F 00
        dh      "EEAA8AEA2EA8E8003E63606763633F00"             ;#5924: EE AA 8A EA 2E A8 E8 00 3E 63 60 67 63 63 3F 00
        dh      "0363817F036382003C0518833C001F04"             ;#5934: 03 63 81 7F 03 63 82 00 3C 05 18 83 3C 00 1F 04
        dh      "068B663C0063666C787C6E6700066093"             ;#5944: 06 8B 66 3C 00 63 66 6C 78 7C 6E 67 00 06 60 93
        dh      "7F0063777F7F6B63630063737B7F6F67"             ;#5954: 7F 00 63 77 7F 7F 6B 63 63 00 63 73 7B 7F 6F 67
        dh      "63003E0563833E007E03639D7E606000"             ;#5964: 63 00 3E 05 63 83 3E 00 7E 03 63 9D 7E 60 60 00
        dh      "EE8888EE8888EE007E6363627C666300"             ;#5974: EE 88 88 EE 88 88 EE 00 7E 63 63 62 7C 66 63 00
        dh      "3E63603E03633E007E06188100066382"             ;#5984: 3E 63 60 3E 03 63 3E 00 7E 06 18 81 00 06 63 82
        dh      "3E00046385361C0800C005A083C000F3"             ;#5994: 3E 00 04 63 85 36 1C 08 00 C0 05 A0 83 C0 00 F3
        dh      "03DB88F3D3DB0066667E3C03188D00DF"             ;#59A4: 03 DB 88 F3 D3 DB 00 66 66 7E 3C 03 18 8D 00 DF
        dh      "1A18CC0616DE00F86060670360A80000"             ;#59B4: 1A 18 CC 06 16 DE 00 F8 60 60 67 03 60 A8 00 00
        dh      "40495A7352590000009252CE02DC0000"             ;#59C4: 40 49 5A 73 52 59 00 00 00 92 52 CE 02 DC 00 00
        dh      "02008AAAAADA00000848EE4A4A6A0000"             ;#59D4: 02 00 8A AA AA DA 00 00 08 48 EE 4A 4A 6A 00 00
        dh      "20242D39292D040001F00350010007EE"             ;#59E4: 20 24 2D 39 29 2D 04 00 01 F0 03 50 01 00 07 EE
        dh      "010007E00E0082070F060082F8F0043E"             ;#59F4: 01 00 07 E0 0E 00 82 07 0F 06 00 82 F8 F0 04 3E
        dh      "043F8B1F3F7FFFFEFCF8F0E0C0800300"             ;#5A04: 04 3F 8B 1F 3F 7F FF FE FC F8 F0 E0 C0 80 03 00
        dh      "023E0500831F7FFB0500830FCFEF0500"             ;#5A14: 02 3E 05 00 83 1F 7F FB 05 00 83 0F CF EF 05 00
        dh      "8378FCBC0500833F7FF305008387C7C7"             ;#5A24: 83 78 FC BC 05 00 83 3F 7F F3 05 00 83 87 C7 C7
        dh      "050083BCFEDF05008878FCBC60F0F060"             ;#5A34: 05 00 83 BC FE DF 05 00 88 78 FC BC 60 F0 F0 60
        dh      "0003F0023F063E88F8FCFE7F3F1F0F07"             ;#5A44: 00 03 F0 02 3F 06 3E 88 F8 FC FE 7F 3F 1F 0F 07
        dh      "033E857EFCFCF8E005F183FB7F1F06EF"             ;#5A54: 03 3E 85 7E FC FC F8 E0 05 F1 83 FB 7F 1F 06 EF
        dh      "82CF0F081E88E1033FF1E1F37F1E07E7"             ;#5A64: 82 CF 0F 08 1E 88 E1 03 3F F1 E1 F3 7F 1E 07 E7
        dh      "81F7088F081E82F1F204F597F2F1E010"             ;#5A74: 81 F7 08 8F 08 1E 82 F1 F2 04 F5 97 F2 F1 E0 10
        dh      "C868C82810E00000082E6F7F3F7F0003"             ;#5A84: C8 68 C8 28 10 E0 00 00 08 2E 6F 7F 3F 7F 00 03
        dh      "070FDF03FF8300E0FC05FF040090E0F0"             ;#5A94: 07 0F DF 03 FF 83 00 E0 FC 05 FF 04 00 90 E0 F0
        dh      "FCFF0003030001010307C08087E704FF"             ;#5AA4: FC FF 00 03 03 00 01 01 03 07 C0 80 87 E7 04 FF
        dh      "030085C0F0FCFFFF040089C0E0E0F010"             ;#5AB4: 03 00 85 C0 F0 FC FF FF 04 00 89 C0 E0 E0 F0 10
        dh      "18181D1D030F021F023F027F02FF02F8"             ;#5AC4: 18 18 1D 1D 03 0F 02 1F 02 3F 02 7F 02 FF 02 F8
        dh      "03E003F08307030105008880CEFF7F0F"             ;#5AD4: 03 E0 03 F0 83 07 03 01 05 00 88 80 CE FF 7F 0F
        dh      "0F1F0003F803FC8EFFC0003E3F030307"             ;#5AE4: 0F 1F 00 03 F8 03 FC 8E FF C0 00 3E 3F 03 03 07
        dh      "06061F1F0F8F03CF890F0080C0C0E0E0"             ;#5AF4: 06 06 1F 1F 0F 8F 03 CF 89 0F 00 80 C0 C0 E0 E0
        dh      "F0F0037F85FF7F7F5F4C06F002F8027F"             ;#5B04: F0 F0 03 7F 85 FF 7F 7F 5F 4C 06 F0 02 F8 02 7F
        dh      "043F847F7FF8FC03F003E0037F873F3F"             ;#5B14: 04 3F 84 7F 7F F8 FC 03 F0 03 E0 03 7F 87 3F 3F
        dh      "1F1F0FC08003008380C0C004FF841F07"             ;#5B24: 1F 1F 0F C0 80 03 00 83 80 C0 C0 04 FF 84 1F 07
        dh      "000003FF97FE3E1CC000FFFFFEFEFCFC"             ;#5B34: 00 00 03 FF 97 FE 3E 1C C0 00 FF FF FE FE FC FC
        dh      "F8F00F07070303071F1FF0F004E082C0"             ;#5B44: F8 F0 0F 07 07 03 03 07 1F 1F F0 F0 04 E0 82 C0
        dh      "80031F820F07030005FF83FEF00005FF"             ;#5B54: 80 03 1F 82 0F 07 03 00 05 FF 83 FE F0 00 05 FF
        dh      "8338000085FEFCF8E08003008A7F6701"             ;#5B64: 83 38 00 00 85 FE FC F8 E0 80 03 00 8A 7F 67 01
        dh      "0307070F0F80C003E084C0C0800F051F"             ;#5B74: 03 07 07 0F 0F 80 C0 03 E0 84 C0 C0 80 0F 05 1F
        dh      "8F0F0F80FCF8F1F3F3FFFF010F1F3F3F"             ;#5B84: 8F 0F 0F 80 FC F8 F1 F3 F3 FF FF 01 0F 1F 3F 3F
        dh      "07FF84FDFCFCF805FF843F1F03F804F0"             ;#5B94: 07 FF 84 FD FC FC F8 05 FF 84 3F 1F 03 F8 04 F0
        dh      "89301000FFFF7F3F1F0F030384070F1F"             ;#5BA4: 89 30 10 00 FF FF 7F 3F 1F 0F 03 03 84 07 0F 1F
        dh      "0F0307050088010FFF000001033F06FF"             ;#5BB4: 0F 03 07 05 00 88 01 0F FF 00 00 01 03 3F 06 FF
        dh      "857F3F01000006FF821F00"                       ;#5BC4: 85 7F 3F 01 00 00 06 FF 82 1F 00

GFX_BANK2_PATTERN_PART3:
        ; Pattern Data Bank 2
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "8340E0400500A0010F010F0A0D0F0905"             ;#5BCF: 83 40 E0 40 05 00 A0 01 0F 01 0F 0A 0D 0F 09 05
        dh      "EE04EEAD65E525F18141F7D46750F500"             ;#5BDF: EE 04 EE AD 65 E5 25 F1 81 41 F7 D4 67 50 F5 00
        dh      "E000E020E000500500060F0A0006F00A"             ;#5BEF: E0 00 E0 20 E0 00 50 05 00 06 0F 0A 00 06 F0 0A
        dh      "0006FF0500"                                   ;#5BFF: 00 06 FF 05 00

GFX_STARTUP_PATT_EXTRA1:
        ; Supplemental startup patterns
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "06C004FF10C00C0004FF060008030307"             ;#5C04: 06 C0 04 FF 10 C0 0C 00 04 FF 06 00 08 03 03 07
        dh      "050002FF04E084C000FFFF13C006E005"             ;#5C14: 05 00 02 FF 04 E0 84 C0 00 FF FF 13 C0 06 E0 05
        dh      "C0"                                           ;#5C24: C0
        db      0                                              ;#5C25: 00

GFX_STARTUP_PATT_EXTRA2:
        ; Supplemental startup patterns
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "0103070102030207030F831F1E1E033F"             ;#5C26: 01 03 07 01 02 03 02 07 03 0F 83 1F 1E 1E 03 3F
        dh      "8D7C78F8E0E0F0F0F8F8787C3C3C03FE"             ;#5C36: 8D 7C 78 F8 E0 E0 F0 F0 F8 F8 78 7C 3C 3C 03 FE
        dh      "831F0F0F0600843B3F3F3B053901B903"             ;#5C46: 83 1F 0F 0F 06 00 84 3B 3F 3F 3B 05 39 01 B9 03
        dh      "00860307071F9FDF05C782C3C106008A"             ;#5C56: 00 86 03 07 07 1F 9F DF 05 C7 82 C3 C1 06 00 8A
        dh      "C7CFCF000F1F9CDFCFC7060083C3E3E3"             ;#5C66: C7 CF CF 00 0F 1F 9C DF CF C7 06 00 83 C3 E3 E3
        dh      "03F38473F3F3BB06008A18B9FBF3C383"             ;#5C76: 03 F3 84 73 F3 F3 BB 06 00 8A 18 B9 FB F3 C3 83
        dh      "83818180060003FB84C08080C003F886"             ;#5C86: 83 81 81 80 06 00 03 FB 84 C0 80 80 C0 03 F8 86
        dh      "00010363E1E003FB03E394F3FB7B3B00"             ;#5C96: 00 01 03 63 E1 E0 03 FB 03 E3 94 F3 FB 7B 3B 00
        dh      "00808000008F9FBFBCB8B8BCBF9F8F06"             ;#5CA6: 00 80 80 00 00 8F 9F BF BC B8 B8 BC BF 9F 8F 06
        dh      "0003800400038002030207030F831F1E"             ;#5CB6: 00 03 80 04 00 03 80 02 03 02 07 03 0F 83 1F 1E
        dh      "1E033F8D7C78F8E0E0F0F0F8F8787C3C"             ;#5CC6: 1E 03 3F 8D 7C 78 F8 E0 E0 F0 F0 F8 F8 78 7C 3C
        dh      "3C03FE831F0F0F06008B1E3F7F797070"             ;#5CD6: 3C 03 FE 83 1F 0F 0F 06 00 8B 1E 3F 7F 79 70 70
        dh      "787F3F9E0005E001EF03E703E383E1E1"             ;#5CE6: 78 7F 3F 9E 00 05 E0 01 EF 03 E7 03 E3 83 E1 E1
        dh      "E006008A1E1CBCBDB9F9F9F0F0E00600"             ;#5CF6: E0 06 00 8A 1E 1C BC BD B9 F9 F9 F0 F0 E0 06 00
        dh      "8A3CFEEEC7FFFFC0E7FF3E060084767F"             ;#5D06: 8A 3C FE EE C7 FF FF C0 E7 FF 3E 06 00 84 76 7F
        dh      "7F7B0673030086060E0E3F3FBF038E84"             ;#5D16: 7F 7B 06 73 03 00 86 06 0E 0E 3F 3F BF 03 8E 84
        dh      "8F8F8783060003B9043983BD9F8E0600"             ;#5D26: 8F 8F 87 83 06 00 03 B9 04 39 83 BD 9F 8E 06 00
        dh      "85DCDDDFDFDE05DC06008AC3CFCEDC1F"             ;#5D36: 85 DC DD DF DF DE 05 DC 06 00 8A C3 CF CE DC 1F
        dh      "1F1C0E0F0306008AC0E0E070F0F00070"             ;#5D46: 1F 1C 0E 0F 03 06 00 8A C0 E0 E0 70 F0 F0 00 70
        dh      "F0E0"                                         ;#5D56: F0 E0
        db      0                                              ;#5D58: 00

GFX_STARTUP_COLOR_TABLE:
        ; Startup color table data for clearing plane
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "18F478F470F450F72074281F2060106A"             ;#5D59: 18 F4 78 F4 70 F4 50 F7 20 74 28 1F 20 60 10 6A
        dh      "38EF021E061F02EF067F0AE70BEF061F"             ;#5D69: 38 EF 02 1E 06 1F 02 EF 06 7F 0A E7 0B EF 06 1F
        dh      "05EF386F0216061F026F067F0A670B6F"             ;#5D79: 05 EF 38 6F 02 16 06 1F 02 6F 06 7F 0A 67 0B 6F
        dh      "061F056F"                                     ;#5D89: 06 1F 05 6F

GFX_STARTUP_COLOR_TABLE_TAIL:
        ; Startup clear tail stream entry (falls into loop filler)
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "0817"                                         ;#5D8D: 08 17

GFX_STARTUP_COLOR_TABLE_LOOP:
        ; Repeating color-table filler
        ; Fallthrough from GFX_STARTUP_COLOR_TABLE.
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "0AF1037102510141"                             ;#5D8F: 0A F1 03 71 02 51 01 41
        db      0                                              ;#5D97: 00

GFX_STAGE_NIGHT_TILES:
        ; Night-stage tile-pattern patch (loaded by INIT_STAGE_SET_SKY_COLOR)
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "0819"                                         ;#5D98: 08 19
        db      0                                              ;#5D9A: 00

GFX_INIT_BANK1:
        ; Decompress bank-1 patterns and colors at stage start
        ld      hl,GFX_BANK1_PATTERN                           ;#5D9B: 21 CB 5D
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5D9E: CD 50 45
        ld      hl,GFX_BANK1_PATTERN+2                         ;#5DA1: 21 CD 5D
        LOAD_VRAM_WRITE de, 2A88h                              ;#5DA4: 11 88 6A
        call    DECOMPRESS_VRAM_DIRECT_MIRROR                  ;#5DA7: CD 58 45
        ; Fallthrough: GFX_BANK1_PATTERN_PART2
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5DAA: CD 50 45
        ld      hl,GFX_BANK1_COLOR_EXTRA                       ;#5DAD: 21 53 61
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5DB0: CD 50 45
        ld      hl,GFX_BANK1_COLOR+2                           ;#5DB3: 21 5A 61
        LOAD_VRAM_WRITE de, 0A88h                              ;#5DB6: 11 88 4A
        call    DECOMPRESS_VRAM_DIRECT                         ;#5DB9: CD 54 45
        ; Fallthrough: GFX_BANK1_COLOR_PART2
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5DBC: CD 50 45
        ld      hl,GFX_BANK1_COLOR                             ;#5DBF: 21 58 61
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5DC2: CD 50 45
        ld      hl,GFX_BANK1_COLOR_EXTRA2                      ;#5DC5: 21 29 62
        jp      DECOMPRESS_VRAM_INDIRECT                       ;#5DC8: C3 50 45

GFX_BANK1_PATTERN:
        ; Bank 1 patterns: stage init (loaded by GFX_INIT_BANK1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 2880h                                      ;#5DCB: 80 68
        dh      "8200FF070084FF0007FF0400A5FF00FF"             ;#5DCD: 82 00 FF 07 00 84 FF 00 07 FF 04 00 A5 FF 00 FF
        dh      "FF0000FF00FF0000FF00FFFF00FF00FF"             ;#5DDD: FF 00 00 FF 00 FF 00 00 FF 00 FF FF 00 FF 00 FF
        dh      "FF00FFFF00FF0000FF0000FF00031FFF"             ;#5DED: FF 00 FF FF 00 FF 00 00 FF 00 00 FF 00 03 1F FF
        dh      "1502030003FF8255AA030003FF890583"             ;#5DFD: 15 02 03 00 03 FF 82 55 AA 03 00 03 FF 89 05 83
        dh      "1FFF0000FFFF0003FF8C0000FFFF00E0"             ;#5E0D: 1F FF 00 00 FF FF 00 03 FF 8C 00 00 FF FF 00 E0
        dh      "FFFF0000FFFF030001FF030087FF0000"             ;#5E1D: FF FF 00 00 FF FF 03 00 01 FF 03 00 87 FF 00 00
        dh      "FFFF2A05060089AA54031FFF2A050000"             ;#5E2D: FF FF 2A 05 06 00 89 AA 54 03 1F FF 2A 05 00 00
        dh      "04FF85AA5522000003FF8BAA50070000"             ;#5E3D: 04 FF 85 AA 55 22 00 00 03 FF 8B AA 50 07 00 00
        dh      "FFFFE01FFFFF030082FF0003FF030089"             ;#5E4D: FF FF E0 1F FF FF 03 00 82 FF 00 03 FF 03 00 89
        dh      "FFFF00FFFF00000F0104008817FFFF55"             ;#5E5D: FF FF 00 FF FF 00 00 0F 01 04 00 88 17 FF FF 55
        dh      "2A05000003FF8355AA110500820F0204"             ;#5E6D: 2A 05 00 00 03 FF 83 55 AA 11 05 00 82 0F 02 04
        dh      "00881FFFFFAA54031F0003FF010003FF"             ;#5E7D: 00 88 1F FF FF AA 54 03 1F 00 03 FF 01 00 03 FF
        dh      "010003FF860000FFFFAA55070004FF85"             ;#5E8D: 01 00 03 FF 86 00 00 FF FF AA 55 07 00 04 FF 85
        dh      "A8473F000003FF8800FFFF000FFF1502"             ;#5E9D: A8 47 3F 00 00 03 FF 88 00 FF FF 00 0F FF 15 02
        dh      "040003FF8900E0FFFF00FF00FFFF0400"             ;#5EAD: 04 00 03 FF 89 00 E0 FF FF 00 FF 00 FF FF 04 00
        dh      "84FF0000FF0A0001FF0400843F00FFFF"             ;#5EBD: 84 FF 00 00 FF 0A 00 01 FF 04 00 84 3F 00 FF FF
        dh      "03008A80FF0000FF7F1F0F0301030005"             ;#5ECD: 03 00 8A 80 FF 00 00 FF 7F 1F 0F 03 01 03 00 05
        dh      "FF857F3F0F0701060003FF8D3F1F0703"             ;#5EDD: FF 85 7F 3F 0F 07 01 06 00 03 FF 8D 3F 1F 07 03
        dh      "00FF7F1F0F0701000007FF857F1F0F07"             ;#5EED: 00 FF 7F 1F 0F 07 01 00 00 07 FF 85 7F 1F 0F 07
        dh      "01040006FF827F3F04FF911F07030007"             ;#5EFD: 01 04 00 06 FF 82 7F 3F 04 FF 91 1F 07 03 00 07
        dh      "0F1F1F1F0F0703FF3F0F0301030084FF"             ;#5F0D: 0F 1F 1F 1F 0F 07 03 FF 3F 0F 03 01 03 00 84 FF
        dh      "7F1F0F04000600021F05FF030003FF82"             ;#5F1D: 7F 1F 0F 04 00 06 00 02 1F 05 FF 03 00 03 FF 82
        dh      "7F1F030003FF0500907F1F0F1F3F0F07"             ;#5F2D: 7F 1F 03 00 03 FF 05 00 90 7F 1F 0F 1F 3F 0F 07
        dh      "01070F"                                       ;#5F3D: 01 07 0F

GFX_FLAG_VRAM_DEST:
        ; VRAM destination address constant for flag decompression
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "1F3F0703"                                     ;#5F40: 1F 3F 07 03
        db      0                                              ;#5F44: 00
        db      0                                              ;#5F45: 00
        dh      "0400020105FF873F1F3F7FFF00030900"             ;#5F46: 04 00 02 01 05 FF 87 3F 1F 3F 7F FF 00 03 09 00
        dh      "8201030300830103070500017F053F82"             ;#5F56: 82 01 03 03 00 83 01 03 07 05 00 01 7F 05 3F 82
        dh      "1F0F06FF067F8C1F0F07017F1F0F0301"             ;#5F66: 1F 0F 06 FF 06 7F 8C 1F 0F 07 01 7F 1F 0F 03 01
        dh      "00030703FF053F"                               ;#5F76: 00 03 07 03 FF 05 3F
        db      0                                              ;#5F7D: 00

GFX_BANK1_PATTERN_PART2:
        ; Bank 1 patterns part 2: stage init (continuation of GFX_BANK1_PATTERN)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 2C90h                                      ;#5F7E: 90 6C
        dh      "0B0001FF0B000103070001FF070001F0"             ;#5F80: 0B 00 01 FF 0B 00 01 03 07 00 01 FF 07 00 01 F0
        dh      "0400011F070001FF0400823FFF060002"             ;#5F90: 04 00 01 1F 07 00 01 FF 04 00 82 3F FF 06 00 02
        dh      "FF060082FCFF050082010F060002FF06"             ;#5FA0: FF 06 00 82 FC FF 05 00 82 01 0F 06 00 02 FF 06
        dh      "0082F0FE060004FF1300010F070001C0"             ;#5FB0: 00 82 F0 FE 06 00 04 FF 13 00 01 0F 07 00 01 C0
        dh      "040001F80300820F7F06008280F00900"             ;#5FC0: 04 00 01 F8 03 00 82 0F 7F 06 00 82 80 F0 09 00
        dh      "0103070001E00700010F070001C00400"             ;#5FD0: 01 03 07 00 01 E0 07 00 01 0F 07 00 01 C0 04 00
        dh      "017F030F040001FE03F01F0001010700"             ;#5FE0: 01 7F 03 0F 04 00 01 FE 03 F0 1F 00 01 01 07 00
        dh      "018007000107070001E00B0001F80700"             ;#5FF0: 01 80 07 00 01 07 07 00 01 E0 0B 00 01 F8 07 00
        dh      "011F0400017F070001FE090002070600"             ;#6000: 01 1F 04 00 01 7F 07 00 01 FE 09 00 02 07 06 00
        dh      "85E0E0001F1F060002FF060002F80500"             ;#6010: 85 E0 E0 00 1F 1F 06 00 02 FF 06 00 02 F8 05 00
        dh      "021F060002F8060002FF0A0001030700"             ;#6020: 02 1F 06 00 02 F8 06 00 02 FF 0A 00 01 03 07 00
        dh      "01C00300847F7FFF7F040084FEFEFFFE"             ;#6030: 01 C0 03 00 84 7F 7F FF 7F 04 00 84 FE FE FF FE
        dh      "040004FF160002040A00023006000203"             ;#6040: 04 00 04 FF 16 00 02 04 0A 00 02 30 06 00 02 03
        dh      "030002C0090004F00C0006FF038001C0"             ;#6050: 03 00 02 C0 09 00 04 F0 0C 00 06 FF 03 80 01 C0
        dh      "030E020803000203040202000100030F"             ;#6060: 03 0E 02 08 03 00 02 03 04 02 02 00 01 00 03 0F
        dh      "0109040003E001200400937BE0E4E4E0"             ;#6070: 01 09 04 00 03 E0 01 20 04 00 93 7B E0 E4 E4 E0
        dh      "E09800F6FFBFBFFFFF53003070770BF8"             ;#6080: E0 98 00 F6 FF BF BF FF FF 53 00 30 70 77 0B F8
        dh      "87E00026EEEFFFFF049F04FF88FECC00"             ;#6090: 87 E0 00 26 EE EF FF FF 04 9F 04 FF 88 FE CC 00
        dh      "24EEEFFF870F7F9B6F03010000226363"             ;#60A0: 24 EE EF FF 87 0F 7F 9B 6F 03 01 00 00 22 63 63
        dh      "F3F7F7FFFFDD8800DBFFFF0000026363"             ;#60B0: F3 F7 F7 FF FF DD 88 00 DB FF FF 00 00 02 63 63
        dh      "F3F7F703FF07FE09FF82C381030002FF"             ;#60C0: F3 F7 F7 03 FF 07 FE 09 FF 82 C3 81 03 00 02 FF
        dh      "010F0CFF010003FF85F7C782000003FF"             ;#60D0: 01 0F 0C FF 01 00 03 FF 85 F7 C7 82 00 00 03 FF
        dh      "071F09FF07C308FF01F80DF70BFC0100"             ;#60E0: 07 1F 09 FF 07 C3 08 FF 01 F8 0D F7 0B FC 01 00
        dh      "08FF847F22000004F78477220000024F"             ;#60F0: 08 FF 84 7F 22 00 00 04 F7 84 77 22 00 00 02 4F
        dh      "067F0103150182030F04008480C0E0FF"             ;#6100: 06 7F 01 03 15 01 82 03 0F 04 00 84 80 C0 E0 FF
        dh      "0500820FFF050093F8E74D1800000F1F"             ;#6110: 05 00 82 0F FF 05 00 93 F8 E7 4D 18 00 00 0F 1F
        dh      "FAEBC5800000F0FC3FDC6803008503FF"             ;#6120: FA EB C5 80 00 00 F0 FC 3F DC 68 03 00 85 03 FF
        dh      "FFB5160500031F013F040004FF040084"             ;#6130: FF B5 16 05 00 03 1F 01 3F 04 00 04 FF 04 00 84
        dh      "C0FCFCFF040084FFEFFFF7040084FFD3"             ;#6140: C0 FC FC FF 04 00 84 FF EF FF F7 04 00 84 FF D3
        dh      "FDCE"                                         ;#6150: FD CE
        db      0                                              ;#6152: 00

GFX_BANK1_COLOR_EXTRA:
        ; Bank 1 color patch: stage init (small extra for GFX_INIT_BANK1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 2A98h                                      ;#6153: 98 6A
        dh      "1000"                                         ;#6155: 10 00
        db      0                                              ;#6157: 00

GFX_BANK1_COLOR:
        ; Bank 1 colors: stage init (loaded by GFX_INIT_BANK1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 880h                                       ;#6158: 80 48
        dh      "78EF78EF38EF604F064F821F412C4F82"             ;#615A: 78 EF 78 EF 38 EF 60 4F 06 4F 82 1F 41 2C 4F 82
        dh      "1F410A4F181F024F03410A4F01410341"             ;#616A: 1F 41 0A 4F 18 1F 02 4F 03 41 0A 4F 01 41 03 41
        dh      "0B4F021F054F0341"                             ;#617A: 0B 4F 02 1F 05 4F 03 41
        db      0                                              ;#6182: 00

GFX_BANK1_COLOR_PART2:
        ; Bank 1 colors part 2: stage init (continuation of GFX_BANK1_COLOR)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 0C90h                                      ;#6183: 90 4C
        dh      "704F304F201F024F0241064F0241044F"             ;#6185: 70 4F 30 4F 20 1F 02 4F 02 41 06 4F 02 41 04 4F
        dh      "785F305F01EF075F01EF075F01EF075F"             ;#6195: 78 5F 30 5F 01 EF 07 5F 01 EF 07 5F 01 EF 07 5F
        dh      "4C3F04EF033F05EF023F06EF109F028F"             ;#61A5: 4C 3F 04 EF 03 3F 05 EF 02 3F 06 EF 10 9F 02 8F
        dh      "0689089F048F0B89046F039F0497069F"             ;#61B5: 06 89 08 9F 04 8F 0B 89 04 6F 03 9F 04 97 06 9F
        dh      "036F039F0F96039F076F019F05F60396"             ;#61C5: 03 6F 03 9F 0F 96 03 9F 07 6F 01 9F 05 F6 03 96
        dh      "076E018E09971F9F088F2097039F0D96"             ;#61D5: 07 6E 01 8E 09 97 1F 9F 08 8F 20 97 03 9F 0D 96
        dh      "0B760D9F0396059F08961717011F08F7"             ;#61E5: 0B 76 0D 9F 03 96 05 9F 08 96 17 17 01 1F 08 F7
        dh      "07F701F405F703F404F704F404F704F4"             ;#61F5: 07 F7 01 F4 05 F7 03 F4 04 F7 04 F4 04 F7 04 F4
        dh      "03F705F428F7"                                 ;#6205: 03 F7 05 F4 28 F7
        db      0                                              ;#620B: 00

GFX_STAGE_NIGHT_COLORS:
        ; Night-stage color patch (paired with GFX_STAGE_NIGHT_TILES)
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "1719011F08F907F901F405F903F404F9"             ;#620C: 17 19 01 1F 08 F9 07 F9 01 F4 05 F9 03 F4 04 F9
        dh      "04F404F904F403F905F428F9"                     ;#621C: 04 F4 04 F9 04 F4 03 F9 05 F4 28 F9
        db      0                                              ;#6228: 00

GFX_BANK1_COLOR_EXTRA2:
        ; Bank 1 color patch 2: stage init (final extra for GFX_INIT_BANK1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 0A98h                                      ;#6229: 98 4A
        dh      "044F01410344034F01410444"                     ;#622B: 04 4F 01 41 03 44 03 4F 01 41 04 44
        db      0                                              ;#6237: 00

GFX_INIT_BANK2:
        ; Decompress bank-2 patterns and colors at stage start
        ld      hl,GFX_BANK2_PATTERN_PART1                     ;#6238: 21 6E 62
        call    DECOMPRESS_VRAM_INDIRECT                       ;#623B: CD 50 45
        ; Fallthrough: GFX_BANK2_COLOR_PART2
        call    DECOMPRESS_VRAM_INDIRECT                       ;#623E: CD 50 45
        ld      hl,GFX_BANK2_PATTERN_PART3                     ;#6241: 21 CF 5B
        call    DECOMPRESS_VRAM_DATA_ONLY                      ;#6244: CD 5D 45
        ld      hl,GFX_BANK2_PATTERN_PART1+2                   ;#6247: 21 70 62
        LOAD_VRAM_WRITE de, 32B0h                              ;#624A: 11 B0 72
        call    DECOMPRESS_VRAM_DIRECT_MIRROR                  ;#624D: CD 58 45
        ld      hl,GFX_BANK2_PATTERN_PART4                     ;#6250: 21 FE 65
        call    DECOMPRESS_VRAM_INDIRECT                       ;#6253: CD 50 45
        ld      hl,GFX_BANK2_COLOR_PART1                       ;#6256: 21 22 65
        call    DECOMPRESS_VRAM_INDIRECT                       ;#6259: CD 50 45
        ; Fallthrough: GFX_BANK2_COLOR_PART2
        call    DECOMPRESS_VRAM_INDIRECT                       ;#625C: CD 50 45
        ld      hl,GFX_BANK2_COLOR_PART1+2                     ;#625F: 21 24 65
        LOAD_VRAM_WRITE de, 12B0h                              ;#6262: 11 B0 52
        call    DECOMPRESS_VRAM_DIRECT                         ;#6265: CD 54 45
        ld      hl,GFX_BANK2_COLOR_PART3                       ;#6268: 21 5C 66
        jp      DECOMPRESS_VRAM_INDIRECT                       ;#626B: C3 50 45

GFX_BANK2_PATTERN_PART1:
        ; Bank 2 patterns part 1: stage init (loaded by GFX_INIT_BANK2)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 3200h                                      ;#626E: 00 72
        dh      "857F1F0F0301030005FF857F3F0F0701"             ;#6270: 85 7F 1F 0F 03 01 03 00 05 FF 85 7F 3F 0F 07 01
        dh      "060003FF8D3F1F070300FF7F1F0F0701"             ;#6280: 06 00 03 FF 8D 3F 1F 07 03 00 FF 7F 1F 0F 07 01
        dh      "000007FF857F1F0F0701040005FF837F"             ;#6290: 00 00 07 FF 85 7F 1F 0F 07 01 04 00 05 FF 83 7F
        dh      "1F0F03FF857F1F0F070104FF861F0703"             ;#62A0: 1F 0F 03 FF 85 7F 1F 0F 07 01 04 FF 86 1F 07 03
        dh      "00FF7F060085FFFF0F0301030004FF04"             ;#62B0: 00 FF 7F 06 00 85 FF FF 0F 03 01 03 00 04 FF 04
        dh      "0005FF8D7F00000103070F0F1F000001"             ;#62C0: 00 05 FF 8D 7F 00 00 01 03 07 0F 0F 1F 00 00 01
        dh      "0306008407070F1F0500870103070F0F"             ;#62D0: 03 06 00 84 07 07 0F 1F 05 00 87 01 03 07 0F 0F
        dh      "1F3F03FF017F0A3F921F0F7F1F0F0301"             ;#62E0: 1F 3F 03 FF 01 7F 0A 3F 92 1F 0F 7F 1F 0F 03 01
        dh      "0003073F3F1F0F07010000"                       ;#62F0: 00 03 07 3F 3F 1F 0F 07 01 00 00
        db      0                                              ;#62FB: 00

GFX_BANK2_PATTERN_PART2:
        ; Bank 2 patterns part 2: stage init
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 3360h                                      ;#62FC: 60 73
        dh      "030005FF010007FF02000DFF04008503"             ;#62FE: 03 00 05 FF 01 00 07 FF 02 00 0D FF 04 00 85 03
        dh      "00000F7F030086F80000F0FF01040096"             ;#630E: 00 00 0F 7F 03 00 86 F8 00 00 F0 FF 01 04 00 96
        dh      "010F00FF3F00000FFFFF3FFFFCF8C000"             ;#631E: 01 0F 00 FF 3F 00 00 0F FF FF 3F FF FC F8 C0 00
        dh      "F0FFFFF0C080030084F8FF1F03030083"             ;#632E: F0 FF FF F0 C0 80 03 00 84 F8 FF 1F 03 03 00 83
        dh      "1FFF03030085E00000E0FE06008280F0"             ;#633E: 1F FF 03 03 00 85 E0 00 00 E0 FE 06 00 82 80 F0
        dh      "0300010F06008607FFFF07000003FF87"             ;#634E: 03 00 01 0F 06 00 86 07 FF FF 07 00 00 03 FF 87
        dh      "FCF0FF0F00C080030083C0F07F070089"             ;#635E: FC F0 FF 0F 00 C0 80 03 00 83 C0 F0 7F 07 00 89
        dh      "F0FCF8F0C000FCFF07070001FF030082"             ;#636E: F0 FC F8 F0 C0 00 FC FF 07 07 00 01 FF 03 00 82
        dh      "FF0F0400860F7FFFFF7F0C040002FF03"             ;#637E: FF 0F 04 00 86 0F 7F FF FF 7F 0C 04 00 02 FF 03
        dh      "3F030002FF03F802FF0D0F010003FF01"             ;#638E: 3F 03 00 02 FF 03 F8 02 FF 0D 0F 01 00 03 FF 01
        dh      "FC0BF001FF08070300010F04FF010F04"             ;#639E: FC 0B F0 01 FF 08 07 03 00 01 0F 04 FF 01 0F 04
        dh      "F784F0C00000071F070F010007F00200"             ;#63AE: F7 84 F0 C0 00 00 07 1F 07 0F 01 00 07 F0 02 00
        dh      "07F802F006F08200C0060F82000306F0"             ;#63BE: 07 F8 02 F0 06 F0 82 00 C0 06 0F 82 00 03 06 F0
        dh      "820F3F060F01FF047F010F0500850303"             ;#63CE: 82 0F 3F 06 0F 01 FF 04 7F 01 0F 05 00 85 03 03
        dh      "0F0F030B008EC0C0F0F0C00000010707"             ;#63DE: 0F 0F 03 0B 00 8E C0 C0 F0 F0 C0 00 00 01 07 07
        dh      "1F1F01FF09008C80E0E0F8F880000007"             ;#63EE: 1F 1F 01 FF 09 00 8C 80 E0 E0 F8 F8 80 00 00 07
        dh      "1FF0E0040084E0F81F070600040F8500"             ;#63FE: 1F F0 E0 04 00 84 E0 F8 1F 07 06 00 04 0F 85 00
        dh      "073FF8C0040084E0FC1F03070004F084"             ;#640E: 07 3F F8 C0 04 00 84 E0 FC 1F 03 07 00 04 F0 84
        dh      "FFFF3F01040004FF040084FFFFFC8004"             ;#641E: FF FF 3F 01 04 00 04 FF 04 00 84 FF FF FC 80 04
        dh      "00830F0F03050003FF011F040003FF01"             ;#642E: 00 83 0F 0F 03 05 00 03 FF 01 1F 04 00 03 FF 01
        dh      "F8040083F0F0C00900830F7FF806FF03"             ;#643E: F8 04 00 83 F0 F0 C0 09 00 83 0F 7F F8 06 FF 03
        dh      "0006FF020003FF050083FFFF3F050083"             ;#644E: 00 06 FF 02 00 03 FF 05 00 83 FF FF 3F 05 00 83
        dh      "FFFFFC050008F0040004FF080F068082"             ;#645E: FF FF FC 05 00 08 F0 04 00 04 FF 08 0F 06 80 82
        dh      "C0E0058083C000000608820C0F050801"             ;#646E: C0 E0 05 80 83 C0 00 00 06 08 82 0C 0F 05 08 01
        dh      "0F0F009B0F0000071F3F7C78F2F2F0E0"             ;#647E: 0F 0F 00 9B 0F 00 00 07 1F 3F 7C 78 F2 F2 F0 E0
        dh      "F8FC3E1E4F4F0F000001070F1F3C3005"             ;#648E: F8 FC 3E 1E 4F 4F 0F 00 00 01 07 0F 1F 3C 30 05
        dh      "F883FCF0C0051F833F0F03870080E0F0"             ;#649E: F8 83 FC F0 C0 05 1F 83 3F 0F 03 87 00 80 E0 F0
        dh      "F81C0C06800A0007010200058083C0C0"             ;#64AE: F8 1C 0C 06 80 0A 00 07 01 02 00 05 80 83 C0 C0
        dh      "E0050183030307038098C04060A0E030"             ;#64BE: E0 05 01 83 03 03 07 03 80 98 C0 40 60 A0 E0 30
        dh      "3C1F0F07030100000101030703000070"             ;#64CE: 3C 1F 0F 07 03 01 00 00 01 01 03 07 03 00 00 70
        dh      "FFE303FF85000006FFE703FF03008880"             ;#64DE: FF E3 03 FF 85 00 00 06 FF E7 03 FF 03 00 88 80
        dh      "80C0E0C000000103000101030088F07F"             ;#64EE: 80 C0 E0 C0 00 00 01 03 00 01 01 03 00 88 F0 7F
        dh      "337FFFFF000098007F60607E60606000"             ;#64FE: 33 7F FF FF 00 00 98 00 7F 60 60 7E 60 60 60 00
        dh      "63636B6B7F7722007F070E1C38707F06"             ;#650E: 63 63 6B 6B 7F 77 22 00 7F 07 0E 1C 38 70 7F 06
        dh      "000260"                                       ;#651E: 00 02 60
        db      0                                              ;#6521: 00

GFX_BANK2_COLOR_PART1:
        ; Bank 2 colors part 1: stage init (loaded by GFX_INIT_BANK2)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1200h                                      ;#6522: 00 52
        dh      "704F201F064F0841084F021F0241064F"             ;#6524: 70 4F 20 1F 06 4F 08 41 08 4F 02 1F 02 41 06 4F
        db      0                                              ;#6534: 00

GFX_BANK2_COLOR_PART2:
        ; Bank 2 colors part 2: stage init (continuation of PART1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1360h                                      ;#6535: 60 53
        dh      "264F021F064F021F054F031F044F041F"             ;#6537: 26 4F 02 1F 06 4F 02 1F 05 4F 03 1F 04 4F 04 1F
        dh      "044F041F044F041F044F041F044F541F"             ;#6547: 04 4F 04 1F 04 4F 04 1F 04 4F 04 1F 04 4F 54 1F
        dh      "064F0241064F0241034F05410641024F"             ;#6557: 06 4F 02 41 06 4F 02 41 03 4F 05 41 06 41 02 4F
        dh      "054F0341074102F40954071F041D041F"             ;#6567: 05 4F 03 41 07 41 02 F4 09 54 07 1F 04 1D 04 1F
        dh      "0E45014F0745024F0745024F0645025F"             ;#6577: 0E 45 01 4F 07 45 02 4F 07 45 02 4F 06 45 02 5F
        dh      "0645025F0645024F0645051D031F04EF"             ;#6587: 06 45 02 5F 06 45 02 4F 06 45 05 1D 03 1F 04 EF
        dh      "065F02FE04F504EF045F04EF045F03FE"             ;#6597: 06 5F 02 FE 04 F5 04 EF 04 5F 04 EF 04 5F 03 FE
        dh      "05F504EF045F04EF02E502F504EF02E5"             ;#65A7: 05 F5 04 EF 04 5F 04 EF 02 E5 02 F5 04 EF 02 E5
        dh      "02F506EF025F03EF02E503F503EF02E5"             ;#65B7: 02 F5 06 EF 02 5F 03 EF 02 E5 03 F5 03 EF 02 E5
        dh      "03F506EF6A5F183F17EF01E105EF01E1"             ;#65C7: 03 F5 06 EF 6A 5F 18 3F 17 EF 01 E1 05 EF 01 E1
        dh      "121F1A1F0216061F0216471F054F031F"             ;#65D7: 12 1F 1A 1F 02 16 06 1F 02 16 47 1F 05 4F 03 1F
        dh      "054F031F054F031F054F031F054F031F"             ;#65E7: 05 4F 03 1F 05 4F 03 1F 05 4F 03 1F 05 4F 03 1F
        dh      "054F"                                         ;#65F7: 05 4F

GFX_GOAL_COLOR_PATCH:
        ; Goal-scene color patch (loaded by INIT_GOAL_GRAPHICS at the goal)
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "784F784F"                                     ;#65F9: 78 4F 78 4F
        db      0                                              ;#65FD: 00

GFX_BANK2_PATTERN_PART4:
        ; Bank 2 patterns part 4: stage init (loaded by GFX_INIT_BANK2)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 3690h                                      ;#65FE: 90 76
        dh      "82020502000607020106020301030084"             ;#6600: 82 02 05 02 00 06 07 02 01 06 02 03 01 03 00 84
        dh      "2757070706FF82070109008380402004"             ;#6610: 27 57 07 07 06 FF 82 07 01 09 00 83 80 40 20 04
        dh      "FF02FE83FCFEFE04FF8B7F3F1F1F0F07"             ;#6620: FF 02 FE 83 FC FE FE 04 FF 8B 7F 3F 1F 1F 0F 07
        dh      "01000204080300038002C084E0F0F8C0"             ;#6630: 01 00 02 04 08 03 00 03 80 02 C0 84 E0 F0 F8 C0
        dh      "0400980001010100000000F8F0E0FF00"             ;#6640: 04 00 98 00 01 01 01 00 00 00 00 F8 F0 E0 FF 00
        dh      "00000000F0FCF800000000"                       ;#6650: 00 00 00 00 F0 FC F8 00 00 00 00
        db      0                                              ;#665B: 00

GFX_BANK2_COLOR_PART3:
        ; Bank 2 colors part 3: stage init (loaded by GFX_INIT_BANK2)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1690h                                      ;#665C: 90 56
        dh      "581F03AF014F05AF02A40D4F"                     ;#665E: 58 1F 03 AF 01 4F 05 AF 02 A4 0D 4F
        db      0                                              ;#666A: 00

INIT_SPRITES_FROM_STREAM:
        ; Initialize quaternary stage VRAM graphics (Sprite data stream)
        ld      hl,SPRITE_INIT_TABLE                           ;#666B: 21 98 66
        jr      CLEAR_AND_INIT_SPRITE_ATTRS                    ;#666E: 18 03

INIT_GOAL_SPRITES:
        ; Reset sprite attributes and initialize goal sequence sprites
        ld      hl,GOAL_SPRITE_DATA                            ;#6670: 21 D5 66
CLEAR_AND_INIT_SPRITE_ATTRS:
        ; Clear SAT mirror, then init from HL stream ([Count][Y,X,Pat,Col]..., 00=End)
        push    hl                                             ;#6673: E5
        ld      hl,SAT_MIRROR                                  ;#6674: 21 50 E0
        push    hl                                             ;#6677: E5
        ld      b,80h                                          ;#6678: 06 80
INIT_SPRITE_ATTRS_CLEAR:
        ; Clear sprite attribute mirror loop
        ld      (hl),0                                         ;#667A: 36 00
        inc     hl                                             ;#667C: 23
        djnz    INIT_SPRITE_ATTRS_CLEAR                        ;#667D: 10 FB
        pop     de                                             ;#667F: D1
        pop     hl                                             ;#6680: E1
INIT_SPRITE_ATTRS_LOOP:
        ; Internal loop for processing sprite attribute stream
        ld      a,(hl)                                         ;#6681: 7E
        inc     hl                                             ;#6682: 23
        or      a                                              ;#6683: B7
        jr      z,SYNC_SPRITE_ATTRIBUTES_ALL                   ;#6684: 28 06
        ld      c,a                                            ;#6686: 4F
        call    REPLICATE_4_BYTE_BLOCK                         ;#6687: CD A2 45
        jr      INIT_SPRITE_ATTRS_LOOP                         ;#668A: 18 F5

SYNC_SPRITE_ATTRIBUTES_ALL:
        ; Sync all 32 sprite attributes to VRAM
        ld      hl,SAT_MIRROR                                  ;#668C: 21 50 E0
        ld      de,VRAM_SAT_BASE                               ;#668F: 11 00 3B
        ld      bc,80h                                         ;#6692: 01 80 00
        jp      COPY_RAM_TO_VRAM                               ;#6695: C3 DE 44

SPRITE_INIT_TABLE:
        ; Initial SAT state at stage start
        ; Consumed by INIT_SPRITES_FROM_STREAM. Layout:
        ; - Penguin body (patterns 00h/04h/08h/0Ch, color 01h) + shadow
        ; (A0h/A4h, color 04h) at center-screen (X=70h..80h, Y=90h..AEh).
        ; These are the only sprites the player initially sees.
        ; - A cluster of 8 sprites parked at (Y=08h, X=00h, pattern 70h)
        ; overlapping at the top-left corner, on the same scanlines as the top-row
        ; HUD sprites so the hardware's 4-sprites-per-line limit hides whichever
        ; sprites land fifth+; the game repositions them across the top bar later
        ; as stage-clear indicators.
        ; - Remaining entries queued off-screen (Y=E0h) as placeholder slots
        ; for objects that spawn later in the stage.
        ; Format: FORMAT_SPRITE_ATTR_STREAM
        ; - Stream of blocks: [RepeatCount, Y, X, Pattern, Color].
        ; - Used for batches of sprites: static screen layout or multi-part entities.
        ; - If RepeatCount == 0, end of stream.
        SPRITE_ATTR_REPT 0Ah, 0E0h, 0, 7Ch, COLOR_TRANSPARENT  ;#6698: 0A E0 00 7C 00
        SPRITE_ATTR_REPT 1, 90h, 70h, 0, COLOR_BLACK           ;#669D: 01 90 70 00 01
        SPRITE_ATTR_REPT 1, 90h, 80h, 4, COLOR_BLACK           ;#66A2: 01 90 80 04 01
        SPRITE_ATTR_REPT 1, 0A0h, 70h, 8, COLOR_BLACK          ;#66A7: 01 A0 70 08 01
        SPRITE_ATTR_REPT 1, 0A0h, 80h, 0Ch, COLOR_BLACK        ;#66AC: 01 A0 80 0C 01
        SPRITE_ATTR_REPT 1, 0E0h, 0, 0D4h, COLOR_DARK_YELLOW   ;#66B1: 01 E0 00 D4 0A
        SPRITE_ATTR_REPT 1, 0E0h, 0, 0, COLOR_MED_RED          ;#66B6: 01 E0 00 00 08
        SPRITE_ATTR_REPT 1, 0E0h, 0, 7Ch, COLOR_BLACK          ;#66BB: 01 E0 00 7C 01
        SPRITE_ATTR_REPT 3, 0E0h, 0, 7Ch, COLOR_DARK_RED       ;#66C0: 03 E0 00 7C 06
        SPRITE_ATTR_REPT 1, 0AEh, 70h, 0A0h, COLOR_DARK_BLUE   ;#66C5: 01 AE 70 A0 04
        SPRITE_ATTR_REPT 1, 0AEh, 80h, 0A4h, COLOR_DARK_BLUE   ;#66CA: 01 AE 80 A4 04
        SPRITE_ATTR_REPT 8, 8, 0, 70h, COLOR_TRANSPARENT       ;#66CF: 08 08 00 70 00
        db      00h                                            ;#66D4: 00

GOAL_SPRITE_DATA:
        ; Goal-scene SAT setup: penguin's beak + white backdrop behind the goal flags
        ; Consumed by INIT_GOAL_SPRITES at the finish line.
        ; - The first 6 entries at (Y=4Fh..52h, X=80h) layer patterns 7Ch/E8h/ECh/E4h to
        ; form the white backdrop (pat E4h at color 0Fh = white) that sits behind the
        ; goal flags; the other layers are transparent overlays used by later
        ; animation frames.
        ; - The last visible entry at (Y=7Fh, X=78h, pat D0h, color 0Ah) is the penguin's
        ; beak sprite, drawn on top of the main penguin patterns once the penguin
        ; reaches the goal. The 4 goal flag sprites themselves live in
        ; GOAL_FLAG_ATTRIBUTES, written straight to SAT_MIRROR.
        ; Format: FORMAT_SPRITE_ATTR_STREAM
        ; - Stream of blocks: [RepeatCount, Y, X, Pattern, Color].
        ; - Used for batches of sprites: static screen layout or multi-part entities.
        ; - If RepeatCount == 0, end of stream.
        SPRITE_ATTR_REPT 4, 4Fh, 80h, 7Ch, COLOR_TRANSPARENT   ;#66D5: 04 4F 80 7C 00
        SPRITE_ATTR_REPT 1, 52h, 80h, 0E8h, COLOR_TRANSPARENT  ;#66DA: 01 52 80 E8 00
        SPRITE_ATTR_REPT 1, 52h, 80h, 0ECh, COLOR_TRANSPARENT  ;#66DF: 01 52 80 EC 00
        SPRITE_ATTR_REPT 1, 52h, 80h, 0E4h, COLOR_WHITE        ;#66E4: 01 52 80 E4 0F
        SPRITE_ATTR_REPT 1, 7Fh, 78h, 0D0h, COLOR_DARK_YELLOW  ;#66E9: 01 7F 78 D0 0A
        db      00h                                            ;#66EE: 00

GOAL_FLAG_ATTRIBUTES:
        ; Initial sprite attributes for the 4 goal-scene flags (4 x 4 bytes)
        ; Format: FORMAT_SPRITE_ATTR
        ; - Single 4-byte block for one hardware sprite: [Y, X, Pattern, Color].
        ; - Coordinates are screen-relative (Y=208 or E0h hides the sprite).
        SPRITE_ATTR 7Fh, 70h, 0F0h, COLOR_DARK_YELLOW          ;#66EF: 7F 70 F0 0A
        SPRITE_ATTR 87h, 78h, 0F4h, COLOR_DARK_YELLOW          ;#66F3: 87 78 F4 0A
        SPRITE_ATTR 77h, 70h, 0F8h, COLOR_BLACK                ;#66F7: 77 70 F8 01
        SPRITE_ATTR 77h, 80h, 0FCh, COLOR_BLACK                ;#66FB: 77 80 FC 01

LOAD_MAIN_SPRITE_PATTERNS:
        ; Initialize tertiary stage VRAM graphics (Entry point)
        ld      hl,MAIN_SPRITE_PATTERNS                        ;#66FF: 21 05 67
        jp      DECOMPRESS_VRAM_INDIRECT                       ;#6702: C3 50 45

MAIN_SPRITE_PATTERNS:
        ; Sprite patterns: stage init (loaded by LOAD_MAIN_SPRITE_PATTERNS)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1800h                                      ;#6705: 00 58
        dh      "0D0083030F1F03008A030F1B376F5FFF"             ;#6707: 0D 00 83 03 0F 1F 03 00 8A 03 0F 1B 37 6F 5F FF
        dh      "FFBFBF03FF030086C0F0F8FCFEFE07FF"             ;#6717: FF BF BF 03 FF 03 00 86 C0 F0 F8 FC FE FE 07 FF
        dh      "0D0086C0E0F03F706007010300830303"             ;#6727: 0D 00 86 C0 E0 F0 3F 70 60 07 01 03 00 83 03 03
        dh      "000CFF847FFFE3010CFF87FEFFC780F8"             ;#6737: 00 0C FF 84 7F FF E3 01 0C FF 87 FE FF C7 80 F8
        dh      "18080680040082C0C00B000501010303"             ;#6747: 18 08 06 80 04 00 82 C0 C0 0B 00 05 01 01 03 03
        dh      "008A071F376FDFBFFFFFBFBF03FF0300"             ;#6757: 00 8A 07 1F 37 6F DF BF FF FF BF BF 03 FF 03 00
        dh      "85C0F0F8FCFC03FE05FF0C008BE0F0F8"             ;#6767: 85 C0 F0 F8 FC FC 03 FE 05 FF 0C 00 8B E0 F0 F8
        dh      "F8070F1F3E383020090008FF887F7F3F"             ;#6777: F8 07 0F 1F 3E 38 30 20 09 00 08 FF 88 7F 7F 3F
        dh      "1F7F7700000DFF86FD39080C00000780"             ;#6787: 1F 7F 77 00 00 0D FF 86 FD 39 08 0C 00 00 07 80
        dh      "8600C0E0A0E0E00C0084071F3F7F0300"             ;#6797: 86 00 C0 E0 A0 E0 E0 0C 00 84 07 1F 3F 7F 03 00
        dh      "8A030F1B372F6F7F7FDFBF03FF030084"             ;#67A7: 8A 03 0F 1B 37 2F 6F 7F 7F DF BF 03 FF 03 00 84
        dh      "E0F8FCFE09FF0A000680836000000701"             ;#67B7: E0 F8 FC FE 09 FF 0A 00 06 80 83 60 00 00 07 01
        dh      "860003070507070DFF83BF9C1008FF8F"             ;#67C7: 86 00 03 07 05 07 07 0D FF 83 BF 9C 10 08 FF 8F
        dh      "FEFEFCF8FEEE0000E0F0F8381C0C0409"             ;#67D7: FE FE FC F8 FE EE 00 00 E0 F0 F8 38 1C 0C 04 09
        dh      "00833F7060050185020607070303000C"             ;#67E7: 00 83 3F 70 60 05 01 85 02 06 07 07 03 03 00 0C
        dh      "FF843F0F01000CFF87FEF8E080F81808"             ;#67F7: FF 84 3F 0F 01 00 0C FF 87 FE F8 E0 80 F8 18 08
        dh      "0580854060E0E0C00D00862030181F0F"             ;#6807: 05 80 85 40 60 E0 E0 C0 0D 00 86 20 30 18 1F 0F
        dh      "0703008A030F1B376F5FFFFFBFBF03FF"             ;#6817: 07 03 00 8A 03 0F 1B 37 6F 5F FF FF BF BF 03 FF
        dh      "030086C0F0F8FCFEFE07FF0A0089040C"             ;#6827: 03 00 86 C0 F0 F8 FC FE FE 07 FF 0A 00 89 04 0C
        dh      "1CF8F0E0030000050185020607070303"             ;#6837: 1C F8 F0 E0 03 00 00 05 01 85 02 06 07 07 03 03
        dh      "000CFF847F1F07010CFF87FCF08000C0"             ;#6847: 00 0C FF 84 7F 1F 07 01 0C FF 87 FC F0 80 00 C0
        dh      "00000580854060E0E0C0060084E0F8FC"             ;#6857: 00 00 05 80 85 40 60 E0 E0 C0 06 00 84 E0 F8 FC
        dh      "FE09FF0900058083E0F06003010C0006"             ;#6867: FE 09 FF 09 00 05 80 83 E0 F0 60 03 01 0C 00 06
        dh      "FF8A7F7F3F3F1F1F0E0C080007FF84FE"             ;#6877: FF 8A 7F 7F 3F 3F 1F 1F 0E 0C 08 00 07 FF 84 FE
        dh      "FEFCB8050083F8FC0C1600050182070F"             ;#6887: FE FC B8 05 00 83 F8 FC 0C 16 00 05 01 82 07 0F
        dh      "03008A071F376FDFBFFFFFBFBF03FF83"             ;#6897: 03 00 8A 07 1F 37 6F DF BF FF FF BF BF 03 FF 83
        dh      "1F3F300D0007FF857F7F3F1B01040006"             ;#68A7: 1F 3F 30 0D 00 07 FF 85 7F 7F 3F 1B 01 04 00 06
        dh      "FF8BFEFEFCFCF8F8F03010000C038018"             ;#68B7: FF 8B FE FE FC FC F8 F8 F0 30 10 00 0C 03 80 18
        dh      "00841E3F3F03030089030F1B376F5FFF"             ;#68C7: 00 84 1E 3F 3F 03 03 00 89 03 0F 1B 37 6F 5F FF
        dh      "DFDF04FF030086C0F0F8FCFEFE07FF0C"             ;#68D7: DF DF 04 FF 03 00 86 C0 F0 F8 FC FE FE 07 FF 0C
        dh      "008578FCFCC0010F0008FF825F0F0307"             ;#68E7: 00 85 78 FC FC C0 01 0F 00 08 FF 82 5F 0F 03 07
        dh      "8303010108FF82FAF003E08480000080"             ;#68F7: 83 03 01 01 08 FF 82 FA F0 03 E0 84 80 00 00 80
        dh      "1700862070D8F8F8700A0086040E1B1F"             ;#6907: 17 00 86 20 70 D8 F8 F8 70 0A 00 86 04 0E 1B 1F
        dh      "1F0E050004780138120086040E1B1F1F"             ;#6917: 1F 0E 05 00 04 78 01 38 12 00 86 04 0E 1B 1F 1F
        dh      "0E0A00862070D8F8F8700300040F010E"             ;#6927: 0E 0A 00 86 20 70 D8 F8 F8 70 03 00 04 0F 01 0E
        dh      "2D00830301010E00858080A0C0200900"             ;#6937: 2D 00 83 03 01 01 0E 00 85 80 80 A0 C0 20 09 00
        dh      "88030701000001000108008780C0E0E0"             ;#6947: 88 03 07 01 00 00 01 00 01 08 00 87 80 C0 E0 E0
        dh      "6060C0080086071F377F3F0C0A000180"             ;#6957: 60 60 C0 08 00 86 07 1F 37 7F 3F 0C 0A 00 01 80
        dh      "03E087F07030181C101004008930383C"             ;#6967: 03 E0 87 F0 70 30 18 1C 10 10 04 00 89 30 38 3C
        dh      "3F1F3F2F27030A0086800888FEF0800B"             ;#6977: 3F 1F 3F 2F 27 03 0A 00 86 80 08 88 FE F0 80 0B
        dh      "008501010503040A0083C080800C0087"             ;#6987: 00 85 01 01 05 03 04 0A 00 83 C0 80 80 0C 00 87
        dh      "01030707060603090088C0E080000080"             ;#6997: 01 03 07 07 06 06 03 09 00 88 C0 E0 80 00 00 80
        dh      "0080070001010307870F0E0C18380808"             ;#69A7: 00 80 07 00 01 01 03 07 87 0F 0E 0C 18 38 08 08
        dh      "050086E0F8ECFEFC300C00860180817F"             ;#69B7: 05 00 86 E0 F8 EC FE FC 30 0C 00 86 01 80 81 7F
        dh      "0F010700890C1C3CFCF8FCF4E4C00600"             ;#69C7: 0F 01 07 00 89 0C 1C 3C FC F8 FC F4 E4 C0 06 00
        dh      "8207070D00017F03FF0C0001FE03FF0D"             ;#69D7: 82 07 07 0D 00 01 7F 03 FF 0C 00 01 FE 03 FF 0D
        dh      "0082E0E0100087C0F0F8FCFCFEFE06FF"             ;#69E7: 00 82 E0 E0 10 00 87 C0 F0 F8 FC FC FE FE 06 FF
        dh      "0700890C1C3CF8F8F0C000800BFF85FE"             ;#69F7: 07 00 89 0C 1C 3C F8 F8 F0 C0 00 80 0B FF 85 FE
        dh      "FCFC3808068084B8F8F0E00D00893038"             ;#6A07: FC FC 38 08 06 80 84 B8 F8 F0 E0 0D 00 89 30 38
        dh      "3C1F1F0F030001030088030F1B372F7F"             ;#6A17: 3C 1F 1F 0F 03 00 01 03 00 88 03 0F 1B 37 2F 7F
        dh      "5FDF05FF0601841D1F0F0706000BFF85"             ;#6A27: 5F DF 05 FF 06 01 84 1D 1F 0F 07 06 00 0B FF 85
        dh      "7F3F3F1C100600880600201329010906"             ;#6A37: 7F 3F 3F 1C 10 06 00 88 06 00 20 13 29 01 09 06
        dh      "080088600004C894809060040085030F"             ;#6A47: 08 00 88 60 00 04 C8 94 80 90 60 04 00 85 03 0F
        dh      "1F3F3F097F870000C0F0F8FCFC09FE08"             ;#6A57: 1F 3F 3F 09 7F 87 00 00 C0 F0 F8 FC FC 09 FE 08
        dh      "0088060C20132911290608008F603004"             ;#6A67: 00 88 06 0C 20 13 29 11 29 06 08 00 8F 60 30 04
        dh      "C8948894600101030D1E3F3F037F03FE"             ;#6A77: C8 94 88 94 60 01 01 03 0D 1E 3F 3F 03 7F 03 FE
        dh      "84FCF0607F0BFF813F060085030F3F7F"             ;#6A87: 84 FC F0 60 7F 0B FF 81 3F 06 00 85 03 0F 3F 7F
        dh      "7F08FF030085C0F0FCFEFE08FF81FE0B"             ;#6A97: 7F 08 FF 03 00 85 C0 F0 FC FE FE 08 FF 81 FE 0B
        dh      "FF81FC0300878080C0B078FCFC03FE03"             ;#6AA7: FF 81 FC 03 00 87 80 80 C0 B0 78 FC FC 03 FE 03
        dh      "7F833F0F06080086030F380C07030A00"             ;#6AB7: 7F 83 3F 0F 06 08 00 86 03 0F 38 0C 07 03 0A 00
        dh      "86C0F01C30E0C007008B0404CCDF7F3F"             ;#6AC7: 86 C0 F0 1C 30 E0 C0 07 00 8B 04 04 CC DF 7F 3F
        dh      "7FFF3F0D1007008940C08080C0E0F080"             ;#6AD7: 7F FF 3F 0D 10 07 00 89 40 C0 80 80 C0 E0 F0 80
        dh      "800B00851FFF7F3F030B0085C0F0FFFE"             ;#6AE7: 80 0B 00 85 1F FF 7F 3F 03 0B 00 85 C0 F0 FF FE
        dh      "F00C00840F3F1F070D0083F0FCC00D00"             ;#6AF7: F0 0C 00 84 0F 3F 1F 07 0D 00 83 F0 FC C0 0D 00
        dh      "83070F070D008380F0000CFF04000CFF"             ;#6B07: 83 07 0F 07 0D 00 83 80 F0 00 0C FF 04 00 0C FF
        dh      "0400060084030F1F1F0C0084C0F0F8F8"             ;#6B17: 04 00 06 00 84 03 0F 1F 1F 0C 00 84 C0 F0 F8 F8
        dh      "0600"                                         ;#6B27: 06 00
        db      0                                              ;#6B29: 00

VICTORY_SPRITE_PATTERNS:
        ; Victory-dance sprite patterns (loaded by LOAD_VICTORY_GFX at the goal)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1F80h                                      ;#6B2A: 80 5F
        dh      "0400860F1F1B1D1C0F0A0086F0F8DCBE"             ;#6B2C: 04 00 86 0F 1F 1B 1D 1C 0F 0A 00 86 F0 F8 DC BE
        dh      "7CF006000B0084030707030C0085C0C0"             ;#6B3C: 7C F0 06 00 0B 00 84 03 07 07 03 0C 00 85 C0 C0
        dh      "C08000A000383C0F0F06040000000000"             ;#6B4C: C0 80 00 A0 00 38 3C 0F 0F 06 04 00 00 00 00 00
        dh      "000000000000FEFFFF1F0F0700000000"             ;#6B5C: 00 00 00 00 00 00 FE FF FF 1F 0F 07 00 00 00 00
        dh      "00000000A000000080C1C3E7EF000000"             ;#6B6C: 00 00 00 00 A0 00 00 00 80 C1 C3 E7 EF 00 00 00
        dh      "00000000000000008080808080000000"             ;#6B7C: 00 00 00 00 00 00 00 00 80 80 80 80 80 00 00 00
        dh      "0000000000"                                   ;#6B8C: 00 00 00 00 00
        db      0                                              ;#6B91: 00

ANIM_BIG_HOLE_LEFT:
        ; HUD spawn/pickup tile-stream for the big hole on the left lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#6B92: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6B93: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6B94: EF
        VRAM_TILES "93"                                        ;#6B95: 93
        db      00h                                            ;#6B96: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6B97: 41
        VRAM_TILE_COLUMN 0Eh                                   ;#6B98: EE
        VRAM_TILES "A195A2"                                    ;#6B99: A1 95 A2
        db      00h                                            ;#6B9C: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6B9D: 41
        VRAM_TILE_COLUMN 0Eh                                   ;#6B9E: EE
        VRAM_TILES "0F0F0F"                                    ;#6B9F: 0F 0F 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#6BA2: EE
        VRAM_TILES "9898A3"                                    ;#6BA3: 98 98 A3
        db      00h                                            ;#6BA6: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#6BA7: 61
        VRAM_TILE_COLUMN 0Eh                                   ;#6BA8: EE
        VRAM_TILES "0F0F0F"                                    ;#6BA9: 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6BAC: ED
        VRAM_TILES "999A9A9B"                                  ;#6BAD: 99 9A 9A 9B
        db      00h                                            ;#6BB1: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#6BB2: 81
        VRAM_TILE_COLUMN 0Dh                                   ;#6BB3: ED
        VRAM_TILES "0F0F0F0F"                                  ;#6BB4: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6BB8: EC
        VRAM_TILES "A49D9D9D9DA5"                              ;#6BB9: A4 9D 9D 9D 9D A5
        db      00h                                            ;#6BBF: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#6BC0: A1
        VRAM_TILE_COLUMN 0Ch                                   ;#6BC1: EC
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6BC2: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ah                                   ;#6BC8: EA
        VRAM_TILES "A8AA9F9F9F9F9FABA7"                        ;#6BC9: A8 AA 9F 9F 9F 9F 9F AB A7
        db      00h                                            ;#6BD2: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#6BD3: C1
        VRAM_TILE_COLUMN 0Ah                                   ;#6BD4: EA
        VRAM_TILES "0F0F0F0F0F0F0F0F0F"                        ;#6BD5: 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#6BDE: E9
        VRAM_TILES "70826C6C6C6C6C6C8371"                      ;#6BDF: 70 82 6C 6C 6C 6C 6C 6C 83 71
        db      00h                                            ;#6BE9: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#6BEA: E1
        VRAM_TILE_COLUMN 9                                     ;#6BEB: E9
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F"                      ;#6BEC: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 8                                     ;#6BF6: E8
        VRAM_TILE_COLUMN 7                                     ;#6BF7: E7
        VRAM_TILES "7273848B6D6D6D6D6D6D8E8675"                ;#6BF8: 72 73 84 8B 6D 6D 6D 6D 6D 6D 8E 86 75
        db      00h                                            ;#6C05: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#6C06: 22
        VRAM_TILE_COLUMN 7                                     ;#6C07: E7
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F"                ;#6C08: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 6                                     ;#6C15: E6
        VRAM_TILES "727384906E6E6E6E6E6E6E91047478"            ;#6C16: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 91 04 74 78
        VRAM_TILE_COLUMN 5                                     ;#6C25: E5
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F8D6F7B7C"          ;#6C26: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 8D 6F 7B 7C
        VRAM_TILES "7D"                                        ;#6C36: 7D
        db      00h                                            ;#6C37: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#6C38: 42
        VRAM_TILE_COLUMN 6                                     ;#6C39: E6
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"            ;#6C3A: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 5                                     ;#6C49: E5
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E928675"          ;#6C4A: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 92 86 75
        VRAM_TILES "0F"                                        ;#6C5A: 0F
        VRAM_TILE_COLUMN 4                                     ;#6C5B: E4
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F6F8C87"          ;#6C5C: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 6F 8C 87
        VRAM_TILES "7E7F"                                      ;#6C6C: 7E 7F
        db      00h                                            ;#6C6E: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#6C6F: 62
        VRAM_TILE_COLUMN 5                                     ;#6C70: E5
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6C71: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 4                                     ;#6C81: E4
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E6E9104"          ;#6C82: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 91 04
        VRAM_TILES "7478"                                      ;#6C92: 74 78
        VRAM_TILE_COLUMN 3                                     ;#6C94: E3
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F6F6F8D"          ;#6C95: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F 8D
        VRAM_TILES "6F7B7C7D"                                  ;#6CA5: 6F 7B 7C 7D
        db      00h                                            ;#6CA9: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#6CAA: 82
        VRAM_TILE_COLUMN 4                                     ;#6CAB: E4
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6CAC: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F"                                      ;#6CBC: 0F 0F
        VRAM_TILE_COLUMN 3                                     ;#6CBE: E3
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E6E6E6E"          ;#6CBF: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E
        VRAM_TILES "9286750F"                                  ;#6CCF: 92 86 75 0F
        VRAM_TILE_COLUMN 2                                     ;#6CD3: E2
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F6F6F6F"          ;#6CD4: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F
        VRAM_TILES "6F8C877E7F"                                ;#6CE4: 6F 8C 87 7E 7F
        db      00h                                            ;#6CE9: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#6CEA: A2
        VRAM_TILE_COLUMN 3                                     ;#6CEB: E3
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6CEC: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F0F"                                    ;#6CFC: 0F 0F 0F
        VRAM_TILE_COLUMN 2                                     ;#6CFF: E2
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E6E6E6E"          ;#6D00: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E
        VRAM_TILES "6E91047478"                                ;#6D10: 6E 91 04 74 78
        db      00h                                            ;#6D15: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#6D16: C2
        VRAM_TILE_COLUMN 2                                     ;#6D17: E2
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6D18: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F0F0F0F"                                ;#6D28: 0F 0F 0F 0F 0F
        db      00h                                            ;#6D2D: 00

ANIM_BIG_HOLE_RIGHT:
        ; HUD spawn/pickup tile-stream for the big hole on the right lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#6D2E: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6D2F: 41
        VRAM_TILE_COLUMN 10h                                   ;#6D30: F0
        VRAM_TILES "93"                                        ;#6D31: 93
        db      00h                                            ;#6D32: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6D33: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6D34: EF
        VRAM_TILES "949596"                                    ;#6D35: 94 95 96
        db      00h                                            ;#6D38: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6D39: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6D3A: EF
        VRAM_TILES "0F0F0F"                                    ;#6D3B: 0F 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6D3E: EF
        VRAM_TILES "979898"                                    ;#6D3F: 97 98 98
        db      00h                                            ;#6D42: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#6D43: 61
        VRAM_TILE_COLUMN 0Fh                                   ;#6D44: EF
        VRAM_TILES "0F0F0F"                                    ;#6D45: 0F 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6D48: EF
        VRAM_TILES "999A9A9B"                                  ;#6D49: 99 9A 9A 9B
        db      00h                                            ;#6D4D: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#6D4E: 81
        VRAM_TILE_COLUMN 0Fh                                   ;#6D4F: EF
        VRAM_TILES "0F0F0F0F"                                  ;#6D50: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#6D54: EE
        VRAM_TILES "9C9D9D9D9D9E"                              ;#6D55: 9C 9D 9D 9D 9D 9E
        db      00h                                            ;#6D5B: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#6D5C: A1
        VRAM_TILE_COLUMN 0Eh                                   ;#6D5D: EE
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6D5E: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6D64: ED
        VRAM_TILES "A6AA9F9F9F9F9FABA7"                        ;#6D65: A6 AA 9F 9F 9F 9F 9F AB A7
        db      00h                                            ;#6D6E: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#6D6F: C1
        VRAM_TILE_COLUMN 0Dh                                   ;#6D70: ED
        VRAM_TILES "0F0F0F0F0F0F0F0F0F"                        ;#6D71: 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6D7A: ED
        VRAM_TILES "70826C6C6C6C6C6C8377"                      ;#6D7B: 70 82 6C 6C 6C 6C 6C 6C 83 77
        db      00h                                            ;#6D85: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#6D86: E1
        VRAM_TILE_COLUMN 0Dh                                   ;#6D87: ED
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F"                      ;#6D88: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6D92: ED
        VRAM_TILE_COLUMN 0Ch                                   ;#6D93: EC
        VRAM_TILES "7689886D6D6D6D6D6D6D8E8675"                ;#6D94: 76 89 88 6D 6D 6D 6D 6D 6D 6D 8E 86 75
        db      00h                                            ;#6DA1: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#6DA2: 22
        VRAM_TILE_COLUMN 0Ch                                   ;#6DA3: EC
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F"                ;#6DA4: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6DB1: EC
        VRAM_TILES "76898F6E6E6E6E6E6E6E91047478"              ;#6DB2: 76 89 8F 6E 6E 6E 6E 6E 6E 6E 91 04 74 78
        VRAM_TILE_COLUMN 0Bh                                   ;#6DC0: EB
        VRAM_TILES "808193856F6F6F6F6F6F6F8D6F7B7C7D"          ;#6DC1: 80 81 93 85 6F 6F 6F 6F 6F 6F 6F 8D 6F 7B 7C 7D
        db      00h                                            ;#6DD1: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#6DD2: 42
        VRAM_TILE_COLUMN 0Ch                                   ;#6DD3: EC
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F"              ;#6DD4: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Bh                                   ;#6DE2: EB
        VRAM_TILES "727384906E6E6E6E6E6E6E6E91047478"          ;#6DE3: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 91 04 74 78
        VRAM_TILE_COLUMN 0Ah                                   ;#6DF3: EA
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F8D6F7B"          ;#6DF4: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 8D 6F 7B
        VRAM_TILES "7C7D"                                      ;#6E04: 7C 7D
        db      00h                                            ;#6E06: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#6E07: 62
        VRAM_TILE_COLUMN 0Bh                                   ;#6E08: EB
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6E09: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ah                                   ;#6E19: EA
        VRAM_TILES "0F76898F6E6E6E6E6E6E6E6E6E6E9104"          ;#6E1A: 0F 76 89 8F 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 91 04
        VRAM_TILES "7478"                                      ;#6E2A: 74 78
        VRAM_TILE_COLUMN 0Ah                                   ;#6E2C: EA
        VRAM_TILES "8081938D6F6F6F6F6F6F6F6F6F6F8D6F"          ;#6E2D: 80 81 93 8D 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F 8D 6F
        VRAM_TILES "7B7C7D"                                    ;#6E3D: 7B 7C 7D
        db      00h                                            ;#6E40: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#6E41: 82
        VRAM_TILE_COLUMN 0Bh                                   ;#6E42: EB
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6E43: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F"                                        ;#6E53: 0F
        VRAM_TILE_COLUMN 0Ah                                   ;#6E54: EA
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E6E6E91"          ;#6E55: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 91
        VRAM_TILES "047478"                                    ;#6E65: 04 74 78
        VRAM_TILE_COLUMN 9                                     ;#6E68: E9
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F6F6F6F"          ;#6E69: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F
        VRAM_TILES "8D6F7B7C7D"                                ;#6E79: 8D 6F 7B 7C 7D
        db      00h                                            ;#6E7E: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#6E7F: A2
        VRAM_TILE_COLUMN 0Ah                                   ;#6E80: EA
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6E81: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F0F"                                    ;#6E91: 0F 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#6E94: E9
        VRAM_TILES "0F76898F6E6E6E6E6E6E6E6E6E6E6E6E"          ;#6E95: 0F 76 89 8F 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E
        VRAM_TILES "6E91047778"                                ;#6EA5: 6E 91 04 77 78
        db      00h                                            ;#6EAA: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#6EAB: C2
        VRAM_TILE_COLUMN 0Ah                                   ;#6EAC: EA
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6EAD: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F0F0F"                                  ;#6EBD: 0F 0F 0F 0F
        db      00h                                            ;#6EC1: 00

ANIM_SMALL_HOLE_CENTER:
        ; HUD spawn/pickup tile-stream for the small hole in the center lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#6EC2: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6EC3: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6EC4: EF
        VRAM_TILES "AFB0"                                      ;#6EC5: AF B0
        db      00h                                            ;#6EC7: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6EC8: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6EC9: EF
        VRAM_TILES "94A2"                                      ;#6ECA: 94 A2
        db      00h                                            ;#6ECC: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6ECD: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6ECE: EF
        VRAM_TILES "0F0F"                                      ;#6ECF: 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6ED1: EF
        VRAM_TILES "BFC0"                                      ;#6ED2: BF C0
        db      00h                                            ;#6ED4: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#6ED5: 61
        VRAM_TILE_COLUMN 0Fh                                   ;#6ED6: EF
        VRAM_TILES "0F0F"                                      ;#6ED7: 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6ED9: EF
        VRAM_TILES "B7B8"                                      ;#6EDA: B7 B8
        db      00h                                            ;#6EDC: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#6EDD: 81
        VRAM_TILE_COLUMN 0Fh                                   ;#6EDE: EF
        VRAM_TILES "0F0F"                                      ;#6EDF: 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6EE1: EF
        VRAM_TILES "BCBD"                                      ;#6EE2: BC BD
        db      00h                                            ;#6EE4: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#6EE5: A1
        VRAM_TILE_COLUMN 0Fh                                   ;#6EE6: EF
        VRAM_TILES "0F0F"                                      ;#6EE7: 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6EE9: EF
        VRAM_TILES "C1C2"                                      ;#6EEA: C1 C2
        db      00h                                            ;#6EEC: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#6EED: C1
        VRAM_TILE_COLUMN 0Fh                                   ;#6EEE: EF
        VRAM_TILES "0F0F"                                      ;#6EEF: 0F 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#6EF1: EE
        VRAM_TILES "94959596"                                  ;#6EF2: 94 95 95 96
        db      00h                                            ;#6EF6: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#6EF7: E1
        VRAM_TILE_COLUMN 0Eh                                   ;#6EF8: EE
        VRAM_TILES "0F0F0F0F"                                  ;#6EF9: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 1Fh                                   ;#6EFD: FF
        VRAM_TILE_COLUMN 0Eh                                   ;#6EFE: EE
        VRAM_TILES "97989899"                                  ;#6EFF: 97 98 98 99
        db      00h                                            ;#6F03: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#6F04: 22
        VRAM_TILE_COLUMN 0Eh                                   ;#6F05: EE
        VRAM_TILES "0F0F0F0F"                                  ;#6F06: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#6F0A: EE
        VRAM_TILES "9A98989B"                                  ;#6F0B: 9A 98 98 9B
        VRAM_TILE_COLUMN 0Eh                                   ;#6F0F: EE
        VRAM_TILES "ABAAAAAC"                                  ;#6F10: AB AA AA AC
        db      00h                                            ;#6F14: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#6F15: 42
        VRAM_TILE_COLUMN 0Eh                                   ;#6F16: EE
        VRAM_TILES "0F0F0F0F"                                  ;#6F17: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6F1B: ED
        VRAM_TILES "9C9D98989E9F"                              ;#6F1C: 9C 9D 98 98 9E 9F
        VRAM_TILE_COLUMN 0Dh                                   ;#6F22: ED
        VRAM_TILES "A3A4A1A1A5A6"                              ;#6F23: A3 A4 A1 A1 A5 A6
        db      00h                                            ;#6F29: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#6F2A: 62
        VRAM_TILE_COLUMN 0Dh                                   ;#6F2B: ED
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6F2C: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6F32: ED
        VRAM_TILES "9A989898989B"                              ;#6F33: 9A 98 98 98 98 9B
        VRAM_TILE_COLUMN 0Dh                                   ;#6F39: ED
        VRAM_TILES "ABA1A8A8A1AC"                              ;#6F3A: AB A1 A8 A8 A1 AC
        db      00h                                            ;#6F40: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#6F41: 82
        VRAM_TILE_COLUMN 0Dh                                   ;#6F42: ED
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6F43: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6F49: EC
        VRAM_TILES "9C9D989898989E9F"                          ;#6F4A: 9C 9D 98 98 98 98 9E 9F
        VRAM_TILE_COLUMN 0Ch                                   ;#6F52: EC
        VRAM_TILES "A3A4A8A9A9A9A5A6"                          ;#6F53: A3 A4 A8 A9 A9 A9 A5 A6
        db      00h                                            ;#6F5B: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#6F5C: A2
        VRAM_TILE_COLUMN 0Ch                                   ;#6F5D: EC
        VRAM_TILES "0F0F0F0F0F0F0F0F"                          ;#6F5E: 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6F66: EC
        VRAM_TILES "9A9898989898989B"                          ;#6F67: 9A 98 98 98 98 98 98 9B
        db      00h                                            ;#6F6F: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#6F70: C2
        VRAM_TILE_COLUMN 0Ch                                   ;#6F71: EC
        VRAM_TILES "0F0F0F0F0F0F0F0F"                          ;#6F72: 0F 0F 0F 0F 0F 0F 0F 0F
        db      00h                                            ;#6F7A: 00

ANIM_SMALL_HOLE_LEFT:
        ; HUD spawn/pickup tile-stream for the small hole on the left lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#6F7B: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6F7C: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6F7D: EF
        VRAM_TILES "B2"                                        ;#6F7E: B2
        db      00h                                            ;#6F7F: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6F80: 41
        VRAM_TILE_COLUMN 0Eh                                   ;#6F81: EE
        VRAM_TILES "B40F"                                      ;#6F82: B4 0F
        db      00h                                            ;#6F84: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6F85: 41
        VRAM_TILE_COLUMN 0Eh                                   ;#6F86: EE
        VRAM_TILES "0F"                                        ;#6F87: 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6F88: ED
        VRAM_TILES "BFB6"                                      ;#6F89: BF B6
        db      00h                                            ;#6F8B: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#6F8C: 61
        VRAM_TILE_COLUMN 0Dh                                   ;#6F8D: ED
        VRAM_TILES "0F0F"                                      ;#6F8E: 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6F90: ED
        VRAM_TILES "BABB"                                      ;#6F91: BA BB
        db      00h                                            ;#6F93: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#6F94: 81
        VRAM_TILE_COLUMN 0Dh                                   ;#6F95: ED
        VRAM_TILES "0F0F"                                      ;#6F96: 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6F98: EC
        VRAM_TILES "BEBE"                                      ;#6F99: BE BE
        db      00h                                            ;#6F9B: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#6F9C: A1
        VRAM_TILE_COLUMN 0Ch                                   ;#6F9D: EC
        VRAM_TILES "0F0F"                                      ;#6F9E: 0F 0F
        VRAM_TILE_COLUMN 0Bh                                   ;#6FA0: EB
        VRAM_TILES "C1C3C2"                                    ;#6FA1: C1 C3 C2
        db      00h                                            ;#6FA4: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#6FA5: C1
        VRAM_TILE_COLUMN 0Bh                                   ;#6FA6: EB
        VRAM_TILES "0F0F0F"                                    ;#6FA7: 0F 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#6FAA: E9
        VRAM_TILES "9495959596"                                ;#6FAB: 94 95 95 95 96
        db      00h                                            ;#6FB0: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#6FB1: E1
        VRAM_TILE_COLUMN 9                                     ;#6FB2: E9
        VRAM_TILES "0F0F0F0F0F"                                ;#6FB3: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 1Fh                                   ;#6FB8: FF
        VRAM_TILE_COLUMN 8                                     ;#6FB9: E8
        VRAM_TILES "9798989899"                                ;#6FBA: 97 98 98 98 99
        db      00h                                            ;#6FBF: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#6FC0: 22
        VRAM_TILE_COLUMN 8                                     ;#6FC1: E8
        VRAM_TILES "0F0F0F0F0F"                                ;#6FC2: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 7                                     ;#6FC7: E7
        VRAM_TILES "9A9898989B"                                ;#6FC8: 9A 98 98 98 9B
        VRAM_TILE_COLUMN 7                                     ;#6FCD: E7
        VRAM_TILES "ABAAAAAAAC"                                ;#6FCE: AB AA AA AA AC
        db      00h                                            ;#6FD3: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#6FD4: 42
        VRAM_TILE_COLUMN 7                                     ;#6FD5: E7
        VRAM_TILES "0F0F0F0F0F"                                ;#6FD6: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 6                                     ;#6FDB: E6
        VRAM_TILES "9A9898989E9F"                              ;#6FDC: 9A 98 98 98 9E 9F
        VRAM_TILE_COLUMN 6                                     ;#6FE2: E6
        VRAM_TILES "A0A1A1A1A5A6"                              ;#6FE3: A0 A1 A1 A1 A5 A6
        db      00h                                            ;#6FE9: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#6FEA: 62
        VRAM_TILE_COLUMN 6                                     ;#6FEB: E6
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6FEC: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 5                                     ;#6FF2: E5
        VRAM_TILES "9A989898989B0F"                            ;#6FF3: 9A 98 98 98 98 9B 0F
        VRAM_TILE_COLUMN 5                                     ;#6FFA: E5
        VRAM_TILES "A0A1A8A8A1A2"                              ;#6FFB: A0 A1 A8 A8 A1 A2
        db      00h                                            ;#7001: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#7002: 82
        VRAM_TILE_COLUMN 5                                     ;#7003: E5
        VRAM_TILES "0F0F0F0F0F0F"                              ;#7004: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 4                                     ;#700A: E4
        VRAM_TILES "9A989898989E9F"                            ;#700B: 9A 98 98 98 98 9E 9F
        VRAM_TILE_COLUMN 4                                     ;#7012: E4
        VRAM_TILES "A0A1A8A8A1A2A6"                            ;#7013: A0 A1 A8 A8 A1 A2 A6
        db      00h                                            ;#701A: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#701B: A2
        VRAM_TILE_COLUMN 4                                     ;#701C: E4
        VRAM_TILES "0F0F0F0F0F0F0F"                            ;#701D: 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 3                                     ;#7024: E3
        VRAM_TILES "9A9898989898989B0F"                        ;#7025: 9A 98 98 98 98 98 98 9B 0F
        db      00h                                            ;#702E: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#702F: C2
        VRAM_TILE_COLUMN 3                                     ;#7030: E3
        VRAM_TILES "0F0F0F0F0F0F0F0F"                          ;#7031: 0F 0F 0F 0F 0F 0F 0F 0F
        db      00h                                            ;#7039: 00

ANIM_SMALL_HOLE_RIGHT:
        ; HUD spawn/pickup tile-stream for the small hole on the right lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#703A: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#703B: 41
        VRAM_TILE_COLUMN 10h                                   ;#703C: F0
        VRAM_TILES "B1"                                        ;#703D: B1
        db      00h                                            ;#703E: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#703F: 41
        VRAM_TILE_COLUMN 10h                                   ;#7040: F0
        VRAM_TILES "0FB3"                                      ;#7041: 0F B3
        db      00h                                            ;#7043: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7044: 41
        VRAM_TILE_COLUMN 11h                                   ;#7045: F1
        VRAM_TILES "0F"                                        ;#7046: 0F
        VRAM_TILE_COLUMN 11h                                   ;#7047: F1
        VRAM_TILES "B5C0"                                      ;#7048: B5 C0
        db      00h                                            ;#704A: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#704B: 61
        VRAM_TILE_COLUMN 11h                                   ;#704C: F1
        VRAM_TILES "0F0F"                                      ;#704D: 0F 0F
        VRAM_TILE_COLUMN 11h                                   ;#704F: F1
        VRAM_TILES "B9BA"                                      ;#7050: B9 BA
        db      00h                                            ;#7052: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#7053: 81
        VRAM_TILE_COLUMN 11h                                   ;#7054: F1
        VRAM_TILES "0F0F"                                      ;#7055: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#7057: F2
        VRAM_TILES "BEBE"                                      ;#7058: BE BE
        db      00h                                            ;#705A: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#705B: A1
        VRAM_TILE_COLUMN 12h                                   ;#705C: F2
        VRAM_TILES "0F0F"                                      ;#705D: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#705F: F2
        VRAM_TILES "C1C3C2"                                    ;#7060: C1 C3 C2
        db      00h                                            ;#7063: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#7064: C1
        VRAM_TILE_COLUMN 12h                                   ;#7065: F2
        VRAM_TILES "0F0F0F"                                    ;#7066: 0F 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#7069: F2
        VRAM_TILES "9495959596"                                ;#706A: 94 95 95 95 96
        db      00h                                            ;#706F: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#7070: E1
        VRAM_TILE_COLUMN 12h                                   ;#7071: F2
        VRAM_TILES "0F0F0F0F0F"                                ;#7072: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 1Fh                                   ;#7077: FF
        VRAM_TILE_COLUMN 13h                                   ;#7078: F3
        VRAM_TILES "9798989899"                                ;#7079: 97 98 98 98 99
        db      00h                                            ;#707E: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#707F: 22
        VRAM_TILE_COLUMN 13h                                   ;#7080: F3
        VRAM_TILES "0F0F0F0F0F"                                ;#7081: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 14h                                   ;#7086: F4
        VRAM_TILES "9A9898989B"                                ;#7087: 9A 98 98 98 9B
        VRAM_TILE_COLUMN 14h                                   ;#708C: F4
        VRAM_TILES "ABAAAAAAAC"                                ;#708D: AB AA AA AA AC
        db      00h                                            ;#7092: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#7093: 42
        VRAM_TILE_COLUMN 14h                                   ;#7094: F4
        VRAM_TILES "0F0F0F0F0F"                                ;#7095: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 14h                                   ;#709A: F4
        VRAM_TILES "9C9D9898989E"                              ;#709B: 9C 9D 98 98 98 9E
        VRAM_TILE_COLUMN 14h                                   ;#70A1: F4
        VRAM_TILES "A3A4A1A1A1A2"                              ;#70A2: A3 A4 A1 A1 A1 A2
        db      00h                                            ;#70A8: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#70A9: 62
        VRAM_TILE_COLUMN 14h                                   ;#70AA: F4
        VRAM_TILES "0F0F0F0F0F0F"                              ;#70AB: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 14h                                   ;#70B1: F4
        VRAM_TILES "0F9A989898989B"                            ;#70B2: 0F 9A 98 98 98 98 9B
        VRAM_TILE_COLUMN 15h                                   ;#70B9: F5
        VRAM_TILES "A0A1A8A8A1A2"                              ;#70BA: A0 A1 A8 A8 A1 A2
        db      00h                                            ;#70C0: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#70C1: 82
        VRAM_TILE_COLUMN 15h                                   ;#70C2: F5
        VRAM_TILES "0F0F0F0F0F0F"                              ;#70C3: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 15h                                   ;#70C9: F5
        VRAM_TILES "9C9D989898989E"                            ;#70CA: 9C 9D 98 98 98 98 9E
        VRAM_TILE_COLUMN 15h                                   ;#70D1: F5
        VRAM_TILES "A3A4A8A9A8A1A2"                            ;#70D2: A3 A4 A8 A9 A8 A1 A2
        db      00h                                            ;#70D9: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#70DA: A2
        VRAM_TILE_COLUMN 15h                                   ;#70DB: F5
        VRAM_TILES "0F0F0F0F0F0F0F"                            ;#70DC: 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 15h                                   ;#70E3: F5
        VRAM_TILES "0F9A9898989898989B"                        ;#70E4: 0F 9A 98 98 98 98 98 98 9B
        db      00h                                            ;#70ED: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#70EE: C2
        VRAM_TILE_COLUMN 16h                                   ;#70EF: F6
        VRAM_TILES "0F0F0F0F0F0F0F0F"                          ;#70F0: 0F 0F 0F 0F 0F 0F 0F 0F
        db      00h                                            ;#70F8: 00

ANIM_FLAG_LEFT:
        ; HUD spawn/pickup tile-stream for the flag on the left lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#70F9: 00
        db      00h                                            ;#70FA: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#70FB: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#70FC: EF
        VRAM_TILES "C6"                                        ;#70FD: C6
        db      00h                                            ;#70FE: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#70FF: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#7100: EF
        VRAM_TILES "C7"                                        ;#7101: C7
        db      00h                                            ;#7102: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7103: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#7104: EF
        VRAM_TILES "0F"                                        ;#7105: 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#7106: EF
        VRAM_TILES "C9"                                        ;#7107: C9
        db      00h                                            ;#7108: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#7109: 61
        VRAM_TILE_COLUMN 0Fh                                   ;#710A: EF
        VRAM_TILES "0F"                                        ;#710B: 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#710C: EE
        VRAM_TILES "CE"                                        ;#710D: CE
        db      00h                                            ;#710E: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#710F: 81
        VRAM_TILE_COLUMN 0Dh                                   ;#7110: ED
        VRAM_TILES "C8CA"                                      ;#7111: C8 CA
        VRAM_TILE_COLUMN 0Dh                                   ;#7113: ED
        VRAM_TILES "CFCB"                                      ;#7114: CF CB
        db      00h                                            ;#7116: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#7117: 81
        VRAM_TILE_COLUMN 0Dh                                   ;#7118: ED
        VRAM_TILES "0F0F"                                      ;#7119: 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#711B: ED
        VRAM_TILES "CC0F"                                      ;#711C: CC 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#711E: EC
        VRAM_TILES "A1CD"                                      ;#711F: A1 CD
        db      00h                                            ;#7121: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#7122: A1
        VRAM_TILE_COLUMN 0Dh                                   ;#7123: ED
        VRAM_TILES "0F"                                        ;#7124: 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#7125: EC
        VRAM_TILES "0F0F"                                      ;#7126: 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#7128: EC
        VRAM_TILES "03AD"                                      ;#7129: 03 AD
        VRAM_TILE_COLUMN 0Bh                                   ;#712B: EB
        VRAM_TILES "B5B1"                                      ;#712C: B5 B1
        db      00h                                            ;#712E: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#712F: E1
        VRAM_TILE_COLUMN 0Ch                                   ;#7130: EC
        VRAM_TILES "0F0F"                                      ;#7131: 0F 0F
        VRAM_TILE_COLUMN 0Bh                                   ;#7133: EB
        VRAM_TILES "AEAE"                                      ;#7134: AE AE
        VRAM_TILE_COLUMN 0Bh                                   ;#7136: EB
        VRAM_TILES "0303"                                      ;#7137: 03 03
        VRAM_TILE_COLUMN 0Ah                                   ;#7139: EA
        VRAM_TILES "7FB0"                                      ;#713A: 7F B0
        db      00h                                            ;#713C: 00
        db      00h                                            ;#713D: 00
        VRAM_TILE_HEADER 3A00h, 1                              ;#713E: 02
        VRAM_TILE_COLUMN 0Bh                                   ;#713F: EB
        VRAM_TILES "0F0F"                                      ;#7140: 0F 0F
        VRAM_TILE_COLUMN 0Bh                                   ;#7142: EB
        VRAM_TILES "0F0F"                                      ;#7143: 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#7145: E9
        VRAM_TILES "AF0303"                                    ;#7146: AF 03 03
        VRAM_TILE_COLUMN 9                                     ;#7149: E9
        VRAM_TILES "AF0303"                                    ;#714A: AF 03 03
        VRAM_TILE_COLUMN 8                                     ;#714D: E8
        VRAM_TILES "7FB2"                                      ;#714E: 7F B2
        db      00h                                            ;#7150: 00
        db      00h                                            ;#7151: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#7152: 42
        VRAM_TILE_COLUMN 9                                     ;#7153: E9
        VRAM_TILES "0F0F0F"                                    ;#7154: 0F 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#7157: E9
        VRAM_TILES "0F0F0F"                                    ;#7158: 0F 0F 0F
        VRAM_TILE_COLUMN 8                                     ;#715B: E8
        VRAM_TILES "0F0F"                                      ;#715C: 0F 0F
        VRAM_TILE_COLUMN 5                                     ;#715E: E5
        VRAM_TILES "030303"                                    ;#715F: 03 03 03
        VRAM_TILE_COLUMN 5                                     ;#7162: E5
        VRAM_TILES "030303"                                    ;#7163: 03 03 03
        db      00h                                            ;#7166: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#7167: A2
        VRAM_TILE_COLUMN 5                                     ;#7168: E5
        VRAM_TILES "0F0F0F"                                    ;#7169: 0F 0F 0F
        VRAM_TILE_COLUMN 5                                     ;#716C: E5
        VRAM_TILES "0F0F0F"                                    ;#716D: 0F 0F 0F
        db      00h                                            ;#7170: 00

ANIM_FLAG_RIGHT:
        ; HUD spawn/pickup tile-stream for the flag on the right lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#7171: 00
        db      00h                                            ;#7172: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7173: 41
        VRAM_TILE_COLUMN 10h                                   ;#7174: F0
        VRAM_TILES "C6"                                        ;#7175: C6
        db      00h                                            ;#7176: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7177: 41
        VRAM_TILE_COLUMN 10h                                   ;#7178: F0
        VRAM_TILES "C8"                                        ;#7179: C8
        db      00h                                            ;#717A: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#717B: 41
        VRAM_TILE_COLUMN 10h                                   ;#717C: F0
        VRAM_TILES "0F"                                        ;#717D: 0F
        VRAM_TILE_COLUMN 11h                                   ;#717E: F1
        VRAM_TILES "C9"                                        ;#717F: C9
        db      00h                                            ;#7180: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#7181: 61
        VRAM_TILE_COLUMN 11h                                   ;#7182: F1
        VRAM_TILES "0F"                                        ;#7183: 0F
        VRAM_TILE_COLUMN 11h                                   ;#7184: F1
        VRAM_TILES "CE"                                        ;#7185: CE
        db      00h                                            ;#7186: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#7187: 81
        VRAM_TILE_COLUMN 11h                                   ;#7188: F1
        VRAM_TILES "C8CA"                                      ;#7189: C8 CA
        VRAM_TILE_COLUMN 11h                                   ;#718B: F1
        VRAM_TILES "CFCB"                                      ;#718C: CF CB
        db      00h                                            ;#718E: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#718F: 81
        VRAM_TILE_COLUMN 11h                                   ;#7190: F1
        VRAM_TILES "0F0F"                                      ;#7191: 0F 0F
        VRAM_TILE_COLUMN 11h                                   ;#7193: F1
        VRAM_TILES "0FCC"                                      ;#7194: 0F CC
        VRAM_TILE_COLUMN 11h                                   ;#7196: F1
        VRAM_TILES "A1CD"                                      ;#7197: A1 CD
        db      00h                                            ;#7199: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#719A: A1
        VRAM_TILE_COLUMN 12h                                   ;#719B: F2
        VRAM_TILES "0F"                                        ;#719C: 0F
        VRAM_TILE_COLUMN 11h                                   ;#719D: F1
        VRAM_TILES "0F0F"                                      ;#719E: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#71A0: F2
        VRAM_TILES "AF03"                                      ;#71A1: AF 03
        VRAM_TILE_COLUMN 12h                                   ;#71A3: F2
        VRAM_TILES "B2"                                        ;#71A4: B2
        db      00h                                            ;#71A5: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#71A6: E1
        VRAM_TILE_COLUMN 12h                                   ;#71A7: F2
        VRAM_TILES "0F0F"                                      ;#71A8: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#71AA: F2
        VRAM_TILES "0FAEAE"                                    ;#71AB: 0F AE AE
        VRAM_TILE_COLUMN 13h                                   ;#71AE: F3
        VRAM_TILES "0303"                                      ;#71AF: 03 03
        VRAM_TILE_COLUMN 12h                                   ;#71B1: F2
        VRAM_TILES "7FB0"                                      ;#71B2: 7F B0
        db      00h                                            ;#71B4: 00
        db      00h                                            ;#71B5: 00
        VRAM_TILE_HEADER 3A00h, 1                              ;#71B6: 02
        VRAM_TILE_COLUMN 13h                                   ;#71B7: F3
        VRAM_TILES "0F0F"                                      ;#71B8: 0F 0F
        VRAM_TILE_COLUMN 13h                                   ;#71BA: F3
        VRAM_TILES "0F0F"                                      ;#71BB: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#71BD: F2
        VRAM_TILES "0FAF0303"                                  ;#71BE: 0F AF 03 03
        VRAM_TILE_COLUMN 13h                                   ;#71C2: F3
        VRAM_TILES "AF0303"                                    ;#71C3: AF 03 03
        VRAM_TILE_COLUMN 12h                                   ;#71C6: F2
        VRAM_TILES "7FB2"                                      ;#71C7: 7F B2
        db      00h                                            ;#71C9: 00
        db      00h                                            ;#71CA: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#71CB: 42
        VRAM_TILE_COLUMN 13h                                   ;#71CC: F3
        VRAM_TILES "0F0F0F"                                    ;#71CD: 0F 0F 0F
        VRAM_TILE_COLUMN 13h                                   ;#71D0: F3
        VRAM_TILES "0F0F0F"                                    ;#71D1: 0F 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#71D4: F2
        VRAM_TILES "0F0F"                                      ;#71D5: 0F 0F
        VRAM_TILE_COLUMN 18h                                   ;#71D7: F8
        VRAM_TILES "030303"                                    ;#71D8: 03 03 03
        VRAM_TILE_COLUMN 18h                                   ;#71DB: F8
        VRAM_TILES "030303"                                    ;#71DC: 03 03 03
        db      00h                                            ;#71DF: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#71E0: A2
        VRAM_TILE_COLUMN 18h                                   ;#71E1: F8
        VRAM_TILES "0F0F0F"                                    ;#71E2: 0F 0F 0F
        VRAM_TILE_COLUMN 18h                                   ;#71E5: F8
        VRAM_TILES "0F0F0F"                                    ;#71E6: 0F 0F 0F
        db      00h                                            ;#71E9: 00

STAGE_SEGMENT_DEFINITIONS:
        ; Pointer table for road segment data (4 entries)
        dw      ROAD_ICE_RIGHT_1                               ;#71EA: F2 71
        dw      ROAD_ICE_LEFT_1                                ;#71EC: 2F 72
        dw      ROAD_WATER_RIGHT_1                             ;#71EE: 6C 72
        dw      ROAD_WATER_LEFT_1                              ;#71F0: A1 72

ROAD_ICE_RIGHT_1:
        ; Ice road, right slot — root (4 frame ptrs + fill + paint + init)
        dw      ROAD_ICE_RIGHT_2                               ;#71F2: D6 72
        dw      ROAD_ICE_RIGHT_3                               ;#71F4: FE 72
        dw      ROAD_ICE_RIGHT_4                               ;#71F6: 16 73
        dw      ROAD_ICE_RIGHT_5                               ;#71F8: 37 73

ROAD_ICE_RIGHT_1_FILL:
        ; Ice road, right slot — perspective background fill (right half)
        ; Format: FORMAT_VRAM_FILL_STREAM
        ; - First byte: fill value (tile index to paint).
        ; - Then pairs: [count, addr_lo]. Each pair paints one horizontal strip.
        ; - Addr base is 39xx; high byte auto-increments when addr_lo < 20h.
        ; - Count 00h terminates the stream.
        ROAD_FILL_VALUE 0Fh                                    ;#71FA: 0F
        ROAD_FILL_RUN 0Fh, 51h                                 ;#71FB: 0F 51
        ROAD_FILL_RUN 0Eh, 72h                                 ;#71FD: 0E 72
        ROAD_FILL_RUN 0Dh, 93h                                 ;#71FF: 0D 93
        ROAD_FILL_RUN 0Bh, 0B5h                                ;#7201: 0B B5
        ROAD_FILL_RUN 0Ah, 0D6h                                ;#7203: 0A D6
        ROAD_FILL_RUN 9, 0F7h                                  ;#7205: 09 F7
        ROAD_FILL_RUN 8, 18h                                   ;#7207: 08 18
        ROAD_FILL_RUN 6, 3Ah                                   ;#7209: 06 3A
        ROAD_FILL_RUN 5, 5Bh                                   ;#720B: 05 5B
        ROAD_FILL_RUN 3, 7Dh                                   ;#720D: 03 7D
        ROAD_FILL_RUN 2, 9Eh                                   ;#720F: 02 9E
        ROAD_FILL_RUN 1, 0BFh                                  ;#7211: 01 BF
        db      00h                                            ;#7213: 00

ROAD_ICE_RIGHT_1_VRAM:
        ; Ice road, right slot — name-table paint pass (road tiles)
        ; Fallthrough from ROAD_ICE_RIGHT_1_FILL (WRITE_VRAM_STREAM step of UPLOAD).
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 11h                               ;#7214: 51 39
        VRAM_TILES "0F101112131415"                            ;#7216: 0F 10 11 12 13 14 15
        STREAM_BLOCK_END                                       ;#721D: FF

ROAD_ICE_RIGHT_1_INIT:
        ; Ice road, right slot — E1xx color/lane init buffer
        ; Format: FORMAT_ROAD_SEGMENT_INIT
        ROAD_SEGMENT_HEADER 60h                                ;#721E: 60
        ROAD_SEGMENT_ROW 0, 0, 0, 0F3h                         ;#721F: 00 00 00 F3
        ROAD_SEGMENT_ROW 0F4h, 0F3h, 0F7h, 0F5h                ;#7223: F4 F3 F7 F5
        ROAD_SEGMENT_ROW 0F6h, 0F4h, 0F3h, 0F7h                ;#7227: F6 F4 F3 F7
        ROAD_SEGMENT_ROW 0F5h, 0F6h, 0, 0                      ;#722B: F5 F6 00 00

ROAD_ICE_LEFT_1:
        ; Ice road, left slot — root (4 frame ptrs + fill + paint + init)
        dw      ROAD_ICE_LEFT_2                                ;#722F: 4F 73
        dw      ROAD_ICE_LEFT_3                                ;#7231: 77 73
        dw      ROAD_ICE_LEFT_4                                ;#7233: 8F 73
        dw      ROAD_ICE_LEFT_5                                ;#7235: B0 73

ROAD_ICE_LEFT_1_FILL:
        ; Ice road, left slot — perspective background fill (left half)
        ; Format: FORMAT_VRAM_FILL_STREAM
        ; - First byte: fill value (tile index to paint).
        ; - Then pairs: [count, addr_lo]. Each pair paints one horizontal strip.
        ; - Addr base is 39xx; high byte auto-increments when addr_lo < 20h.
        ; - Count 00h terminates the stream.
        ROAD_FILL_VALUE 0Fh                                    ;#7237: 0F
        ROAD_FILL_RUN 0Fh, 40h                                 ;#7238: 0F 40
        ROAD_FILL_RUN 0Eh, 60h                                 ;#723A: 0E 60
        ROAD_FILL_RUN 0Dh, 80h                                 ;#723C: 0D 80
        ROAD_FILL_RUN 0Bh, 0A0h                                ;#723E: 0B A0
        ROAD_FILL_RUN 0Ah, 0C0h                                ;#7240: 0A C0
        ROAD_FILL_RUN 9, 0E0h                                  ;#7242: 09 E0
        ROAD_FILL_RUN 8, 0                                     ;#7244: 08 00
        ROAD_FILL_RUN 6, 20h                                   ;#7246: 06 20
        ROAD_FILL_RUN 5, 40h                                   ;#7248: 05 40
        ROAD_FILL_RUN 3, 60h                                   ;#724A: 03 60
        ROAD_FILL_RUN 2, 80h                                   ;#724C: 02 80
        ROAD_FILL_RUN 1, 0A0h                                  ;#724E: 01 A0
        db      00h                                            ;#7250: 00

ROAD_ICE_LEFT_1_VRAM:
        ; Ice road, left slot — name-table paint pass (road tiles)
        ; Fallthrough from ROAD_ICE_LEFT_1_FILL (WRITE_VRAM_STREAM step of UPLOAD).
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 8                                 ;#7251: 48 39
        VRAM_TILES "1514131252100F"                            ;#7253: 15 14 13 12 52 10 0F
        STREAM_BLOCK_END                                       ;#725A: FF

ROAD_ICE_LEFT_1_INIT:
        ; Ice road, left slot — E1xx color/lane init buffer
        ; Fallthrough from ROAD_ICE_LEFT_1_VRAM (read after WRITE_VRAM_STREAM returns).
        ; Format: FORMAT_ROAD_SEGMENT_INIT
        ROAD_SEGMENT_HEADER 50h                                ;#725B: 50
        ROAD_SEGMENT_ROW 0F3h, 0F5h, 0F6h, 0F4h                ;#725C: F3 F5 F6 F4
        ROAD_SEGMENT_ROW 0F5h, 0F7h, 0F6h, 0F4h                ;#7260: F5 F7 F6 F4
        ROAD_SEGMENT_ROW 0F4h, 0F3h, 0F5h, 0F6h                ;#7264: F4 F3 F5 F6
        ROAD_SEGMENT_ROW 0F4h, 0F5h, 0F6h, 0                   ;#7268: F4 F5 F6 00

ROAD_WATER_RIGHT_1:
        ; Water road, right slot — root (4 frame ptrs + fill + paint + init)
        dw      ROAD_WATER_RIGHT_2                             ;#726C: C8 73
        dw      ROAD_WATER_RIGHT_3                             ;#726E: E9 73
        dw      ROAD_WATER_RIGHT_4                             ;#7270: 0A 74
        dw      ROAD_WATER_RIGHT_5                             ;#7272: 28 74

ROAD_WATER_RIGHT_1_FILL:
        ; Water road, right slot — perspective background fill (right half)
        ; Fallthrough from ROAD_WATER_RIGHT_1 frame ptrs (FILL_VRAM_STREAM input).
        ; Format: FORMAT_VRAM_FILL_STREAM
        ; - First byte: fill value (tile index to paint).
        ; - Then pairs: [count, addr_lo]. Each pair paints one horizontal strip.
        ; - Addr base is 39xx; high byte auto-increments when addr_lo < 20h.
        ; - Count 00h terminates the stream.
        ROAD_FILL_VALUE 4                                      ;#7274: 04
        ROAD_FILL_RUN 0Dh, 53h                                 ;#7275: 0D 53
        ROAD_FILL_RUN 0Ch, 74h                                 ;#7277: 0C 74
        ROAD_FILL_RUN 0Ah, 96h                                 ;#7279: 0A 96
        ROAD_FILL_RUN 9, 0B7h                                  ;#727B: 09 B7
        ROAD_FILL_RUN 7, 0D9h                                  ;#727D: 07 D9
        ROAD_FILL_RUN 6, 0FAh                                  ;#727F: 06 FA
        ROAD_FILL_RUN 5, 1Bh                                   ;#7281: 05 1B
        ROAD_FILL_RUN 3, 3Dh                                   ;#7283: 03 3D
        db      00h                                            ;#7285: 00

ROAD_WATER_RIGHT_1_VRAM:
        ; Water road, right slot — name-table paint pass (road tiles)
        ; Fallthrough from ROAD_WATER_RIGHT_1_FILL (WRITE_VRAM_STREAM step of UPLOAD).
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 11h                               ;#7286: 51 39
        VRAM_TILES "393C"                                      ;#7288: 39 3C
        STREAM_NEXT_BLOCK                                      ;#728A: FE
        VRAM_NAME_TABLE 0Bh, 12h                               ;#728B: 72 39
        VRAM_TILES "3738"                                      ;#728D: 37 38
        STREAM_BLOCK_END                                       ;#728F: FF

ROAD_WATER_RIGHT_1_INIT:
        ; Water road, right slot — E1xx color/lane init buffer
        ; Format: FORMAT_ROAD_SEGMENT_INIT
        ROAD_SEGMENT_HEADER 60h                                ;#7290: 60
        ROAD_SEGMENT_ROW 0, 0, 0, 0                            ;#7291: 00 00 00 00
        ROAD_SEGMENT_ROW 0F8h, 0FCh, 0F9h, 0FBh                ;#7295: F8 FC F9 FB
        ROAD_SEGMENT_ROW 0FCh, 0F9h, 0F9h, 0F9h                ;#7299: FC F9 F9 F9
        ROAD_SEGMENT_ROW 0FBh, 0FAh, 0, 0                      ;#729D: FB FA 00 00

ROAD_WATER_LEFT_1:
        ; Water road, left slot — root (4 frame ptrs + fill + paint + init)
        dw      ROAD_WATER_LEFT_2                              ;#72A1: 45 74
        dw      ROAD_WATER_LEFT_3                              ;#72A3: 66 74
        dw      ROAD_WATER_LEFT_4                              ;#72A5: 87 74
        dw      ROAD_WATER_LEFT_5                              ;#72A7: A5 74

ROAD_WATER_LEFT_1_FILL:
        ; Water road, left slot — perspective background fill (left half)
        ; Fallthrough from ROAD_WATER_LEFT_1 frame ptrs (FILL_VRAM_STREAM input).
        ; Format: FORMAT_VRAM_FILL_STREAM
        ; - First byte: fill value (tile index to paint).
        ; - Then pairs: [count, addr_lo]. Each pair paints one horizontal strip.
        ; - Addr base is 39xx; high byte auto-increments when addr_lo < 20h.
        ; - Count 00h terminates the stream.
        ROAD_FILL_VALUE 4                                      ;#72A9: 04
        ROAD_FILL_RUN 0Dh, 40h                                 ;#72AA: 0D 40
        ROAD_FILL_RUN 0Ch, 60h                                 ;#72AC: 0C 60
        ROAD_FILL_RUN 0Ah, 80h                                 ;#72AE: 0A 80
        ROAD_FILL_RUN 9, 0A0h                                  ;#72B0: 09 A0
        ROAD_FILL_RUN 7, 0C0h                                  ;#72B2: 07 C0
        ROAD_FILL_RUN 6, 0E0h                                  ;#72B4: 06 E0
        ROAD_FILL_RUN 5, 0                                     ;#72B6: 05 00
        ROAD_FILL_RUN 3, 20h                                   ;#72B8: 03 20
        db      00h                                            ;#72BA: 00

ROAD_WATER_LEFT_1_VRAM:
        ; Water road, left slot — name-table paint pass (road tiles)
        ; Fallthrough from ROAD_WATER_LEFT_1_FILL (WRITE_VRAM_STREAM step of UPLOAD).
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 0Dh                               ;#72BB: 4D 39
        VRAM_TILES "7D7A"                                      ;#72BD: 7D 7A
        STREAM_NEXT_BLOCK                                      ;#72BF: FE
        VRAM_NAME_TABLE 0Bh, 0Ch                               ;#72C0: 6C 39
        VRAM_TILES "7978"                                      ;#72C2: 79 78
        STREAM_BLOCK_END                                       ;#72C4: FF

ROAD_WATER_LEFT_1_INIT:
        ; Water road, left slot — E1xx color/lane init buffer
        ; Fallthrough from ROAD_WATER_LEFT_1_VRAM (read after WRITE_VRAM_STREAM returns).
        ; Format: FORMAT_ROAD_SEGMENT_INIT
        ROAD_SEGMENT_HEADER 50h                                ;#72C5: 50
        ROAD_SEGMENT_ROW 0, 0, 0, 0F8h                         ;#72C6: 00 00 00 F8
        ROAD_SEGMENT_ROW 0FBh, 0F9h, 0FCh, 0FBh                ;#72CA: FB F9 FC FB
        ROAD_SEGMENT_ROW 0F9h, 0FBh, 0FCh, 0FAh                ;#72CE: F9 FB FC FA
        ROAD_SEGMENT_ROW 0, 0, 0, 0                            ;#72D2: 00 00 00 00

ROAD_ICE_RIGHT_2:
        ; Ice road, right slot — animation frame 1/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#72D6: 21
        VRAM_TILE_COLUMN 18h                                   ;#72D7: F8
        VRAM_TILES "1315121212141414"                          ;#72D8: 13 15 12 12 12 14 14 14
        VRAM_TILE_COLUMN 15h                                   ;#72E0: F5
        VRAM_TILES "16171819191A1B1C1C1C1C"                    ;#72E1: 16 17 18 19 19 1A 1B 1C 1C 1C 1C
        VRAM_TILE_COLUMN 17h                                   ;#72EC: F7
        VRAM_TILES "1D1E1F1F1F20212223"                        ;#72ED: 1D 1E 1F 1F 1F 20 21 22 23
        VRAM_TILE_COLUMN 1Ah                                   ;#72F6: FA
        VRAM_TILES "0F2425262626"                              ;#72F7: 0F 24 25 26 26 26
        db      00h                                            ;#72FD: 00

ROAD_ICE_RIGHT_3:
        ; Ice road, right slot — animation frame 2/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#72FE: 21
        VRAM_TILE_COLUMN 1Ah                                   ;#72FF: FA
        VRAM_TILES "15"                                        ;#7300: 15
        VRAM_TILE_COLUMN 15h                                   ;#7301: F5
        VRAM_TILES "27282929192A"                              ;#7302: 27 28 29 29 19 2A
        VRAM_TILE_COLUMN 17h                                   ;#7308: F7
        VRAM_TILES "2B2B1E1F2829192D"                          ;#7309: 2B 2B 1E 1F 28 29 19 2D
        VRAM_TILE_COLUMN 1Ah                                   ;#7311: FA
        VRAM_TILES "2E2626"                                    ;#7312: 2E 26 26
        db      00h                                            ;#7315: 00

ROAD_ICE_RIGHT_4:
        ; Ice road, right slot — animation frame 3/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#7316: 21
        VRAM_TILE_COLUMN 18h                                   ;#7317: F8
        VRAM_TILES "151515121212"                              ;#7318: 15 15 15 12 12 12
        VRAM_TILE_COLUMN 15h                                   ;#731E: F5
        VRAM_TILES "16171819192F1B1C2222"                      ;#731F: 16 17 18 19 19 2F 1B 1C 22 22
        VRAM_TILE_COLUMN 17h                                   ;#7329: F7
        VRAM_TILES "1D1E1F1F1F202122"                          ;#732A: 1D 1E 1F 1F 1F 20 21 22
        VRAM_TILE_COLUMN 1Ah                                   ;#7332: FA
        VRAM_TILES "0F2425"                                    ;#7333: 0F 24 25
        db      00h                                            ;#7336: 00

ROAD_ICE_RIGHT_5:
        ; Ice road, right slot — animation frame 4/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#7337: 21
        VRAM_TILE_COLUMN 1Ah                                   ;#7338: FA
        VRAM_TILES "12"                                        ;#7339: 12
        VRAM_TILE_COLUMN 15h                                   ;#733A: F5
        VRAM_TILES "27282929192D"                              ;#733B: 27 28 29 29 19 2D
        VRAM_TILE_COLUMN 17h                                   ;#7341: F7
        VRAM_TILES "2B2B1E1F2C29192D"                          ;#7342: 2B 2B 1E 1F 2C 29 19 2D
        VRAM_TILE_COLUMN 1Ah                                   ;#734A: FA
        VRAM_TILES "2E2626"                                    ;#734B: 2E 26 26
        db      00h                                            ;#734E: 00

ROAD_ICE_LEFT_2:
        ; Ice road, left slot — animation frame 1/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#734F: 21
        VRAM_TILE_COLUMN 0                                     ;#7350: E0
        VRAM_TILES "1414141212121513"                          ;#7351: 14 14 14 12 12 12 15 13
        VRAM_TILE_COLUMN 0                                     ;#7359: E0
        VRAM_TILES "5D5D5D5D5C5B5A5A595857"                    ;#735A: 5D 5D 5D 5D 5C 5B 5A 5A 59 58 57
        VRAM_TILE_COLUMN 0                                     ;#7365: E0
        VRAM_TILES "646362616060605F5E"                        ;#7366: 64 63 62 61 60 60 60 5F 5E
        VRAM_TILE_COLUMN 0                                     ;#736F: E0
        VRAM_TILES "67676766650F"                              ;#7370: 67 67 67 66 65 0F
        db      00h                                            ;#7376: 00

ROAD_ICE_LEFT_3:
        ; Ice road, left slot — animation frame 2/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#7377: 21
        VRAM_TILE_COLUMN 5                                     ;#7378: E5
        VRAM_TILES "14"                                        ;#7379: 14
        VRAM_TILE_COLUMN 5                                     ;#737A: E5
        VRAM_TILES "6B5A6A6A6968"                              ;#737B: 6B 5A 6A 6A 69 68
        VRAM_TILE_COLUMN 1                                     ;#7381: E1
        VRAM_TILES "6E5A6A69605F6C6C"                          ;#7382: 6E 5A 6A 69 60 5F 6C 6C
        VRAM_TILE_COLUMN 3                                     ;#738A: E3
        VRAM_TILES "67676F"                                    ;#738B: 67 67 6F
        db      00h                                            ;#738E: 00

ROAD_ICE_LEFT_4:
        ; Ice road, left slot — animation frame 3/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#738F: 21
        VRAM_TILE_COLUMN 2                                     ;#7390: E2
        VRAM_TILES "121212151515"                              ;#7391: 12 12 12 15 15 15
        VRAM_TILE_COLUMN 1                                     ;#7397: E1
        VRAM_TILES "63635D5C705A5A595857"                      ;#7398: 63 63 5D 5C 70 5A 5A 59 58 57
        VRAM_TILE_COLUMN 1                                     ;#73A2: E1
        VRAM_TILES "6362616060605F5E"                          ;#73A3: 63 62 61 60 60 60 5F 5E
        VRAM_TILE_COLUMN 3                                     ;#73AB: E3
        VRAM_TILES "66650F"                                    ;#73AC: 66 65 0F
        db      00h                                            ;#73AF: 00

ROAD_ICE_LEFT_5:
        ; Ice road, left slot — animation frame 4/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#73B0: 21
        VRAM_TILE_COLUMN 5                                     ;#73B1: E5
        VRAM_TILES "12"                                        ;#73B2: 12
        VRAM_TILE_COLUMN 5                                     ;#73B3: E5
        VRAM_TILES "6E5A6A6A6968"                              ;#73B4: 6E 5A 6A 6A 69 68
        VRAM_TILE_COLUMN 1                                     ;#73BA: E1
        VRAM_TILES "6E5A6A6D605F6C6C"                          ;#73BB: 6E 5A 6A 6D 60 5F 6C 6C
        VRAM_TILE_COLUMN 3                                     ;#73C3: E3
        VRAM_TILES "67676F"                                    ;#73C4: 67 67 6F
        db      00h                                            ;#73C7: 00

ROAD_WATER_RIGHT_2:
        ; Water road, right slot — animation frame 1/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#73C8: 61
        VRAM_TILE_COLUMN 13h                                   ;#73C9: F3
        VRAM_TILES "494336"                                    ;#73CA: 49 43 36
        VRAM_TILE_COLUMN 15h                                   ;#73CD: F5
        VRAM_TILES "3748"                                      ;#73CE: 37 48
        VRAM_TILE_COLUMN 16h                                   ;#73D0: F6
        VRAM_TILES "3B4236"                                    ;#73D1: 3B 42 36
        VRAM_TILE_COLUMN 18h                                   ;#73D4: F8
        VRAM_TILES "3738"                                      ;#73D5: 37 38
        VRAM_TILE_COLUMN 18h                                   ;#73D7: F8
        VRAM_TILES "0F0F54"                                    ;#73D8: 0F 0F 54
        VRAM_TILE_COLUMN 1Ah                                   ;#73DB: FA
        VRAM_TILES "504704"                                    ;#73DC: 50 47 04
        VRAM_TILE_COLUMN 1Bh                                   ;#73DF: FB
        VRAM_TILES "4248040404"                                ;#73E0: 42 48 04 04 04
        VRAM_TILE_COLUMN 1Eh                                   ;#73E5: FE
        VRAM_TILES "4243"                                      ;#73E6: 42 43
        db      00h                                            ;#73E8: 00

ROAD_WATER_RIGHT_3:
        ; Water road, right slot — animation frame 2/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#73E9: 61
        VRAM_TILE_COLUMN 13h                                   ;#73EA: F3
        VRAM_TILES "0F4504"                                    ;#73EB: 0F 45 04
        VRAM_TILE_COLUMN 16h                                   ;#73EE: F6
        VRAM_TILES "38"                                        ;#73EF: 38
        VRAM_TILE_COLUMN 16h                                   ;#73F0: F6
        VRAM_TILES "4A4C04"                                    ;#73F1: 4A 4C 04
        VRAM_TILE_COLUMN 17h                                   ;#73F4: F7
        VRAM_TILES "374438"                                    ;#73F5: 37 44 38
        VRAM_TILE_COLUMN 1Ah                                   ;#73F8: FA
        VRAM_TILES "4041"                                      ;#73F9: 40 41
        VRAM_TILE_COLUMN 1Ah                                   ;#73FB: FA
        VRAM_TILES "0F4243"                                    ;#73FC: 0F 42 43
        VRAM_TILE_COLUMN 1Bh                                   ;#73FF: FB
        VRAM_TILES "0F51"                                      ;#7400: 0F 51
        VRAM_TILE_COLUMN 1Dh                                   ;#7402: FD
        VRAM_TILES "444504"                                    ;#7403: 44 45 04
        VRAM_TILE_COLUMN 1Eh                                   ;#7406: FE
        VRAM_TILES "464D"                                      ;#7407: 46 4D
        db      00h                                            ;#7409: 00

ROAD_WATER_RIGHT_4:
        ; Water road, right slot — animation frame 3/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#740A: 61
        VRAM_TILE_COLUMN 14h                                   ;#740B: F4
        VRAM_TILES "4F"                                        ;#740C: 4F
        VRAM_TILE_COLUMN 15h                                   ;#740D: F5
        VRAM_TILES "403D"                                      ;#740E: 40 3D
        VRAM_TILE_COLUMN 16h                                   ;#7410: F6
        VRAM_TILES "0F354D"                                    ;#7411: 0F 35 4D
        VRAM_TILE_COLUMN 17h                                   ;#7414: F7
        VRAM_TILES "4B4E04"                                    ;#7415: 4B 4E 04
        VRAM_TILE_COLUMN 19h                                   ;#7418: F9
        VRAM_TILES "4A4B"                                      ;#7419: 4A 4B
        VRAM_TILE_COLUMN 1Fh                                   ;#741B: FF
        VRAM_TILE_COLUMN 1Ch                                   ;#741C: FC
        VRAM_TILES "0F4041"                                    ;#741D: 0F 40 41
        VRAM_TILE_COLUMN 1Dh                                   ;#7420: FD
        VRAM_TILES "0F4252"                                    ;#7421: 0F 42 52
        VRAM_TILE_COLUMN 1Eh                                   ;#7424: FE
        VRAM_TILES "4E53"                                      ;#7425: 4E 53
        db      00h                                            ;#7427: 00

ROAD_WATER_RIGHT_5:
        ; Water road, right slot — animation frame 4/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#7428: 61
        VRAM_TILE_COLUMN 14h                                   ;#7429: F4
        VRAM_TILES "3F36"                                      ;#742A: 3F 36
        VRAM_TILE_COLUMN 15h                                   ;#742C: F5
        VRAM_TILES "463A"                                      ;#742D: 46 3A
        VRAM_TILE_COLUMN 18h                                   ;#742F: F8
        VRAM_TILES "36"                                        ;#7430: 36
        VRAM_TILE_COLUMN 17h                                   ;#7431: F7
        VRAM_TILES "0F3750"                                    ;#7432: 0F 37 50
        VRAM_TILE_COLUMN 18h                                   ;#7435: F8
        VRAM_TILES "4F554504"                                  ;#7436: 4F 55 45 04
        VRAM_TILE_COLUMN 1Ah                                   ;#743A: FA
        VRAM_TILES "464C49"                                    ;#743B: 46 4C 49
        VRAM_TILE_COLUMN 1Fh                                   ;#743E: FF
        VRAM_TILE_COLUMN 1Fh                                   ;#743F: FF
        VRAM_TILES "43"                                        ;#7440: 43
        VRAM_TILE_COLUMN 1Eh                                   ;#7441: FE
        VRAM_TILES "0F0F"                                      ;#7442: 0F 0F
        db      00h                                            ;#7444: 00

ROAD_WATER_LEFT_2:
        ; Water road, left slot — animation frame 1/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#7445: 61
        VRAM_TILE_COLUMN 0Ah                                   ;#7446: EA
        VRAM_TILES "77848A"                                    ;#7447: 77 84 8A
        VRAM_TILE_COLUMN 9                                     ;#744A: E9
        VRAM_TILES "8978"                                      ;#744B: 89 78
        VRAM_TILE_COLUMN 7                                     ;#744D: E7
        VRAM_TILES "77837C"                                    ;#744E: 77 83 7C
        VRAM_TILE_COLUMN 6                                     ;#7451: E6
        VRAM_TILES "7978"                                      ;#7452: 79 78
        VRAM_TILE_COLUMN 5                                     ;#7454: E5
        VRAM_TILES "6A0F0F"                                    ;#7455: 6A 0F 0F
        VRAM_TILE_COLUMN 3                                     ;#7458: E3
        VRAM_TILES "045D66"                                    ;#7459: 04 5D 66
        VRAM_TILE_COLUMN 0                                     ;#745C: E0
        VRAM_TILES "0404045E58"                                ;#745D: 04 04 04 5E 58
        VRAM_TILE_COLUMN 0                                     ;#7462: E0
        VRAM_TILES "5958"                                      ;#7463: 59 58
        db      00h                                            ;#7465: 00

ROAD_WATER_LEFT_3:
        ; Water road, left slot — animation frame 2/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#7466: 61
        VRAM_TILE_COLUMN 0Ah                                   ;#7467: EA
        VRAM_TILES "04860F"                                    ;#7468: 04 86 0F
        VRAM_TILE_COLUMN 9                                     ;#746B: E9
        VRAM_TILES "79"                                        ;#746C: 79
        VRAM_TILE_COLUMN 7                                     ;#746D: E7
        VRAM_TILES "048D8B"                                    ;#746E: 04 8D 8B
        VRAM_TILE_COLUMN 6                                     ;#7471: E6
        VRAM_TILES "798578"                                    ;#7472: 79 85 78
        VRAM_TILE_COLUMN 4                                     ;#7475: E4
        VRAM_TILES "5756"                                      ;#7476: 57 56
        VRAM_TILE_COLUMN 3                                     ;#7478: E3
        VRAM_TILES "59580F"                                    ;#7479: 59 58 0F
        VRAM_TILE_COLUMN 3                                     ;#747C: E3
        VRAM_TILES "670F"                                      ;#747D: 67 0F
        VRAM_TILE_COLUMN 0                                     ;#747F: E0
        VRAM_TILES "045B5A"                                    ;#7480: 04 5B 5A
        VRAM_TILE_COLUMN 0                                     ;#7483: E0
        VRAM_TILES "635C"                                      ;#7484: 63 5C
        db      00h                                            ;#7486: 00

ROAD_WATER_LEFT_4:
        ; Water road, left slot — animation frame 3/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#7487: 61
        VRAM_TILE_COLUMN 0Bh                                   ;#7488: EB
        VRAM_TILES "90"                                        ;#7489: 90
        VRAM_TILE_COLUMN 9                                     ;#748A: E9
        VRAM_TILES "7E81"                                      ;#748B: 7E 81
        VRAM_TILE_COLUMN 7                                     ;#748D: E7
        VRAM_TILES "8E760F"                                    ;#748E: 8E 76 0F
        VRAM_TILE_COLUMN 6                                     ;#7491: E6
        VRAM_TILES "048F8C"                                    ;#7492: 04 8F 8C
        VRAM_TILE_COLUMN 5                                     ;#7495: E5
        VRAM_TILES "6160"                                      ;#7496: 61 60
        VRAM_TILE_COLUMN 1Fh                                   ;#7498: FF
        VRAM_TILE_COLUMN 1                                     ;#7499: E1
        VRAM_TILES "57560F"                                    ;#749A: 57 56 0F
        VRAM_TILE_COLUMN 0                                     ;#749D: E0
        VRAM_TILES "68580F"                                    ;#749E: 68 58 0F
        VRAM_TILE_COLUMN 0                                     ;#74A1: E0
        VRAM_TILES "6964"                                      ;#74A2: 69 64
        db      00h                                            ;#74A4: 00

ROAD_WATER_LEFT_5:
        ; Water road, left slot — animation frame 4/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#74A5: 61
        VRAM_TILE_COLUMN 0Ah                                   ;#74A6: EA
        VRAM_TILES "7780"                                      ;#74A7: 77 80
        VRAM_TILE_COLUMN 9                                     ;#74A9: E9
        VRAM_TILES "7B87"                                      ;#74AA: 7B 87
        VRAM_TILE_COLUMN 7                                     ;#74AC: E7
        VRAM_TILES "77"                                        ;#74AD: 77
        VRAM_TILE_COLUMN 6                                     ;#74AE: E6
        VRAM_TILES "91780F"                                    ;#74AF: 91 78 0F
        VRAM_TILE_COLUMN 4                                     ;#74B2: E4
        VRAM_TILES "045B6B65"                                  ;#74B3: 04 5B 6B 65
        VRAM_TILE_COLUMN 3                                     ;#74B7: E3
        VRAM_TILES "5F625C"                                    ;#74B8: 5F 62 5C
        VRAM_TILE_COLUMN 1Fh                                   ;#74BB: FF
        VRAM_TILE_COLUMN 0                                     ;#74BC: E0
        VRAM_TILES "59"                                        ;#74BD: 59
        VRAM_TILE_COLUMN 0                                     ;#74BE: E0
        VRAM_TILES "0F0F"                                      ;#74BF: 0F 0F
        db      00h                                            ;#74C1: 00

UPDATE_STATION_FRAME:
        ; Approach animation: paint the end-stage station at the next zoom level
        ; Triggers every 32 (0x20) units of distance when distance < 256
        ; (HL < 0x0100), so it fires 5 times across the final stretch (one frame per
        ; fire). The lower distance nibble selects the frame from STATION_FRAMES,
        ; stepping through STATION_FRAME_0..4 from farthest (smallest) to closest
        ; (largest). Uses a specialized VRAM stream format: header (2 bytes) with
        ; high byte = address/offset bits and low byte = target offset; data bytes
        ; get +40h added before VDP output; offset values >= 0xE0 reload the VRAM
        ; address (new header); terminator 0x00 ends the stream.
        ld      hl,(STAGE_DISTANCE_BCD)                        ;#74C2: 2A E5 E0
        ld      a,h                                            ;#74C5: 7C
        or      a                                              ;#74C6: B7
        ret     nz                                             ;#74C7: C0
        ld      a,l                                            ;#74C8: 7D
        and     1Fh                                            ;#74C9: E6 1F
        ret     nz                                             ;#74CB: C0
        ld      a,l                                            ;#74CC: 7D
        rlca                                                   ;#74CD: 07
        rlca                                                   ;#74CE: 07
        rlca                                                   ;#74CF: 07
        add     a,a                                            ;#74D0: 87
        ld      hl,STATION_FRAMES                              ;#74D1: 21 06 75
        call    ADD_HL_A                                       ;#74D4: CD D1 48
        ld      e,(hl)                                         ;#74D7: 5E
        inc     hl                                             ;#74D8: 23
        ld      d,(hl)                                         ;#74D9: 56
        ex      de,hl                                          ;#74DA: EB
        ld      a,(hl)                                         ;#74DB: 7E
        and     0F0h                                           ;#74DC: E6 F0
        ld      c,a                                            ;#74DE: 4F
        ld      a,(hl)                                         ;#74DF: 7E
        inc     hl                                             ;#74E0: 23
        and     3                                              ;#74E1: E6 03
        add     a,78h                                          ;#74E3: C6 78
        ld      d,a                                            ;#74E5: 57
        ld      a,c                                            ;#74E6: 79
STATION_FRAME_HEADER_LOOP:
        ; Start of VRAM header processing
        ld      b,(hl)                                         ;#74E7: 46
        inc     hl                                             ;#74E8: 23
        ld      a,20h                                          ;#74E9: 3E 20
        add     a,c                                            ;#74EB: 81
        ld      c,a                                            ;#74EC: 4F
        jr      nc,STATION_FRAME_ADDR_CALC                     ;#74ED: 30 01
        inc     d                                              ;#74EF: 14
STATION_FRAME_ADDR_CALC:
        ; Carry-adjusted VRAM address calculation
        ld      a,c                                            ;#74F0: 79
        add     a,b                                            ;#74F1: 80
        sub     0E0h                                           ;#74F2: D6 E0
        ld      e,a                                            ;#74F4: 5F
        call    SET_VDP                                        ;#74F5: CD C9 48
STATION_FRAME_TILE_LOOP:
        ; Emit tile bytes (with +40h offset) until 00h or next E0-FF header
        ld      a,(hl)                                         ;#74F8: 7E
        or      a                                              ;#74F9: B7
        ret     z                                              ;#74FA: C8
        cp      0E0h                                           ;#74FB: FE E0
        jr      nc,STATION_FRAME_HEADER_LOOP                   ;#74FD: 30 E8
        inc     hl                                             ;#74FF: 23
        add     a,40h                                          ;#7500: C6 40
        out     (VDP_98),a                                     ;#7502: D3 98
        jr      STATION_FRAME_TILE_LOOP                        ;#7504: 18 F2

STATION_FRAMES:
        ; Pointer table for end-stage station/house zoom-in frames (0=farthest, 4=closest)
        dw      STATION_FRAME_4                                ;#7506: 4B 75
        dw      STATION_FRAME_3                                ;#7508: 28 75
        dw      STATION_FRAME_2                                ;#750A: 1A 75
        dw      STATION_FRAME_1                                ;#750C: 15 75
        dw      STATION_FRAME_0                                ;#750E: 10 75

STATION_FRAME_0:
        ; End-stage station, zoom level 0 (farthest, 2 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3900h, 2                          ;#7510: 21
        STATION_FRAME_INNER_HEADER 0Fh                         ;#7511: EF
        VRAM_TILES "9091"                                      ;#7512: 90 91
        db      00h                                            ;#7514: 00

STATION_FRAME_1:
        ; End-stage station, zoom level 1 (2 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3900h, 2                          ;#7515: 21
        STATION_FRAME_INNER_HEADER 0Fh                         ;#7516: EF
        VRAM_TILES "9293"                                      ;#7517: 92 93
        db      00h                                            ;#7519: 00

STATION_FRAME_2:
        ; End-stage station, zoom level 2 (9 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3900h, 1                          ;#751A: 01
        STATION_FRAME_INNER_HEADER 0Fh                         ;#751B: EF
        VRAM_TILES "AF"                                        ;#751C: AF
        STATION_FRAME_INNER_HEADER 0Eh                         ;#751D: EE
        VRAM_TILES "94969698"                                  ;#751E: 94 96 96 98
        STATION_FRAME_INNER_HEADER 0Eh                         ;#7522: EE
        VRAM_TILES "9597979A"                                  ;#7523: 95 97 97 9A
        db      00h                                            ;#7527: 00

STATION_FRAME_3:
        ; End-stage station, zoom level 3 (27 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3800h, 8                          ;#7528: E0
        STATION_FRAME_INNER_HEADER 0Fh                         ;#7529: EF
        VRAM_TILES "AF"                                        ;#752A: AF
        STATION_FRAME_INNER_HEADER 0Fh                         ;#752B: EF
        VRAM_TILES "B1B2"                                      ;#752C: B1 B2
        STATION_FRAME_INNER_HEADER 0Dh                         ;#752E: ED
        VRAM_TILES "9D9B9C9C9C9B"                              ;#752F: 9D 9B 9C 9C 9C 9B
        STATION_FRAME_INNER_HEADER 0Dh                         ;#7535: ED
        VRAM_TILES "C89EA4A6A8A1"                              ;#7536: C8 9E A4 A6 A8 A1
        STATION_FRAME_INNER_HEADER 0Dh                         ;#753C: ED
        VRAM_TILES "C89FA5A7A9C9"                              ;#753D: C8 9F A5 A7 A9 C9
        STATION_FRAME_INNER_HEADER 0Dh                         ;#7543: ED
        VRAM_TILES "A3A0A0A0ADA0"                              ;#7544: A3 A0 A0 A0 AD A0
        db      00h                                            ;#754A: 00

STATION_FRAME_4:
        ; End-stage station, zoom level 4 (closest, 64 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3800h, 7                          ;#754B: C0
        STATION_FRAME_INNER_HEADER 0Fh                         ;#754C: EF
        VRAM_TILES "71"                                        ;#754D: 71
        STATION_FRAME_INNER_HEADER 0Fh                         ;#754E: EF
        VRAM_TILES "B0"                                        ;#754F: B0
        STATION_FRAME_INNER_HEADER 0Fh                         ;#7550: EF
        VRAM_TILES "B1B2"                                      ;#7551: B1 B2
        STATION_FRAME_INNER_HEADER 0Bh                         ;#7553: EB
        VRAM_TILES "9D9D9B9B9B9C9C9C9C9B"                      ;#7554: 9D 9D 9B 9B 9B 9C 9C 9C 9C 9B
        STATION_FRAME_INNER_HEADER 0Bh                         ;#755E: EB
        VRAM_TILES "C8C8C9C9C9C9C9A2A2C9"                      ;#755F: C8 C8 C9 C9 C9 C9 C9 A2 A2 C9
        STATION_FRAME_INNER_HEADER 0Bh                         ;#7569: EB
        VRAM_TILES "C8C8C9AAC9AAC999C9C9"                      ;#756A: C8 C8 C9 AA C9 AA C9 99 C9 C9
        STATION_FRAME_INNER_HEADER 0Bh                         ;#7574: EB
        VRAM_TILES "C8C8C9ABC9ABC999C9C9"                      ;#7575: C8 C8 C9 AB C9 AB C9 99 C9 C9
        STATION_FRAME_INNER_HEADER 0Bh                         ;#757F: EB
        VRAM_TILES "C8C8C9C9C9C9C9AEC9C9"                      ;#7580: C8 C8 C9 C9 C9 C9 C9 AE C9 C9
        STATION_FRAME_INNER_HEADER 0Bh                         ;#758A: EB
        VRAM_TILES "A3A3ACA0A0ACAC9AA0AC"                      ;#758B: A3 A3 AC A0 A0 AC AC 9A A0 AC
        db      00h                                            ;#7595: 00

CHECK_SPECIAL_ITEM_COLLISION:
        ; Detects collision with type-7 small-hole occupants (fish / seal)
        ld      hl,FISH_POS_STATE                              ;#7596: 21 83 E1
        ld      a,(hl)                                         ;#7599: 7E
        and     0E3h                                           ;#759A: E6 E3
        ret     nz                                             ;#759C: C0
        ld      de,ITEM_TABLE_TYPE_BASE                        ;#759D: 11 13 E1
        ld      b,3                                            ;#75A0: 06 03
CHECK_SPECIAL_ITEM_COLLISION_LOOP:
        ; Loop for checking item collisions
        ld      a,(de)                                         ;#75A2: 1A
        cp      3                                              ;#75A3: FE 03
        jr      nc,SKIP_ITEM_CHECK                             ;#75A5: 30 07
        dec     de                                             ;#75A7: 1B
        ld      a,(de)                                         ;#75A8: 1A
        cp      7                                              ;#75A9: FE 07
        jr      z,ITEM_FOUND_COLLISION                         ;#75AB: 28 09
        inc     de                                             ;#75AD: 13
SKIP_ITEM_CHECK:
        ; Skip current item check
        ld      a,6                                            ;#75AE: 3E 06
        call    ADD_DE_A                                       ;#75B0: CD D6 48
        djnz    CHECK_SPECIAL_ITEM_COLLISION_LOOP              ;#75B3: 10 ED
        ret                                                    ;#75B5: C9

ITEM_FOUND_COLLISION:
        ; Item found, handle collision logic
        ld      (ITEM_COLLISION_PTR),de                        ;#75B6: ED 53 81 E1
        inc     de                                             ;#75BA: 13
        ld      a,(SEQUENCE_THRESHOLD)                         ;#75BB: 3A 8A E1
        ld      c,a                                            ;#75BE: 4F
        ld      a,(FRAME_COUNTER)                              ;#75BF: 3A 03 E0
        cp      c                                              ;#75C2: B9
        jr      nc,NO_COLLISION_RESET                          ;#75C3: 30 39
        ld      a,(CUR_INPUT_KEYS)                             ;#75C5: 3A 09 E0
        and     0Ch                                            ;#75C8: E6 0C
        jr      z,HANDLE_IDLE_ITEM_ANIM                        ;#75CA: 28 04
        bit     2,a                                            ;#75CC: CB 57
        jr      SET_FISH_POS_FRAME                             ;#75CE: 18 09

HANDLE_IDLE_ITEM_ANIM:
        ; Handle idle animation for item
        ld      a,(ITEM_IDLE_ANIM_COUNTER)                     ;#75D0: 3A 85 E1
        inc     a                                              ;#75D3: 3C
        ld      (ITEM_IDLE_ANIM_COUNTER),a                     ;#75D4: 32 85 E1
        bit     0,a                                            ;#75D7: CB 47
SET_FISH_POS_FRAME:
        ; Set fish position frame
        ld      a,90h                                          ;#75D9: 3E 90
        set     0,(hl)                                         ;#75DB: CB C6
        jr      z,UPDATE_ITEM_SPRITE_ATTRS                     ;#75DD: 28 04
        ld      a,80h                                          ;#75DF: 3E 80
        rlc     (hl)                                           ;#75E1: CB 06
UPDATE_ITEM_SPRITE_ATTRS:
        ; Update item sprite attributes
        ld      c,a                                            ;#75E3: 4F
        ld      hl,SAT_MIRROR + SPRITE_ITEM + ATTR_Y           ;#75E4: 21 8C E0
        ld      a,(de)                                         ;#75E7: 1A
        ld      d,c                                            ;#75E8: 51
        cp      1                                              ;#75E9: FE 01
        ld      bc,7A66h                                       ;#75EB: 01 66 7A
        jr      c,SET_SPRITE_Y_OFFSETS                         ;#75EE: 38 04
        jr      z,SET_SPRITE_Y_ALT                             ;#75F0: 28 04
        ld      b,92h                                          ;#75F2: 06 92
SET_SPRITE_Y_OFFSETS:
        ; Set sprite Y offsets
        jr      STORE_SPRITE_ATTRS                             ;#75F4: 18 02

SET_SPRITE_Y_ALT:
        ; Set alternate sprite Y offset
        ld      b,64h                                          ;#75F6: 06 64
STORE_SPRITE_ATTRS:
        ; Store sprite attributes to buffer
        ld      (hl),c                                         ;#75F8: 71
        inc     hl                                             ;#75F9: 23
        ld      (hl),b                                         ;#75FA: 70
        inc     hl                                             ;#75FB: 23
        ld      (hl),d                                         ;#75FC: 72
        ret                                                    ;#75FD: C9

NO_COLLISION_RESET:
        ; Reset collision state if no item found
        xor     a                                              ;#75FE: AF
        ld      (FISH_POS_VRAM_SELECT),a                       ;#75FF: 32 92 E1
        ld      a,(de)                                         ;#7602: 1A
        cp      1                                              ;#7603: FE 01
        jr      c,MARK_COLLISION_TYPE_1                        ;#7605: 38 05
        jr      z,MARK_COLLISION_TYPE_2                        ;#7607: 28 06
        set     5,(hl)                                         ;#7609: CB EE
        ret                                                    ;#760B: C9

MARK_COLLISION_TYPE_1:
        ; Mark collision flag (type 1)
        set     6,(hl)                                         ;#760C: CB F6
        ret                                                    ;#760E: C9

MARK_COLLISION_TYPE_2:
        ; Mark collision flag (type 2)
        set     7,(hl)                                         ;#760F: CB FE
        ret                                                    ;#7611: C9

SYNC_SPRITE_ATTRIBUTES_PARTIAL:
        ; Upload sprite attribute subset to VRAM
        ld      a,(FRAME_COUNTER)                              ;#7612: 3A 03 E0
        rra                                                    ;#7615: 1F
        ret     c                                              ;#7616: D8
SYNC_SPRITE_LOOP:
        ; Loop entry for iterating through dynamic sprite attributes
        ld      hl,(SAT_MIRROR + SPRITE_ITEM + ATTR_Y)         ;#7617: 2A 8C E0
        ld      (CURRENT_ENTITY_POINTER),hl                    ;#761A: 22 88 E1
        ld      hl,SAT_MIRROR + SPRITE_ITEM + ATTR_Y           ;#761D: 21 8C E0
        LOAD_SPRITE_ATTR de, 15, 0                             ;#7620: 11 3C 3B
        ld      bc,4                                           ;#7623: 01 04 00
        call    COPY_RAM_TO_VRAM                               ;#7626: CD DE 44
        ld      de,FISH_POS_STATE                              ;#7629: 11 83 E1
        ld      a,(de)                                         ;#762C: 1A
        and     3                                              ;#762D: E6 03
        ret     z                                              ;#762F: C8
        ld      hl,SAT_MIRROR + SPRITE_ITEM + ATTR_PATT        ;#7630: 21 8E E0
        call    SYNC_ANIMATION_TIMER                           ;#7633: CD 74 76
        ld      a,(de)                                         ;#7636: 1A
        dec     hl                                             ;#7637: 2B
        rra                                                    ;#7638: 1F
        jr      c,MAX_ANIMATION_COUNTER                        ;#7639: 38 04
        dec     (hl)                                           ;#763B: 35
        dec     (hl)                                           ;#763C: 35
        jr      SYNC_ANIMATION_COMMON_ENTRY                    ;#763D: 18 02

MAX_ANIMATION_COUNTER:
        ; Max out animation counter
        inc     (hl)                                           ;#763F: 34
        inc     (hl)                                           ;#7640: 34
SYNC_ANIMATION_COMMON_ENTRY:
        ; Common entry for animation sync
        push    hl                                             ;#7641: E5
        ld      hl,FISH_POS_COUNTER                            ;#7642: 21 84 E1
        inc     (hl)                                           ;#7645: 34
        ld      a,(hl)                                         ;#7646: 7E
        pop     hl                                             ;#7647: E1
        dec     hl                                             ;#7648: 2B
        cp      8                                              ;#7649: FE 08
        jr      c,DEC_ANIMATION_COUNTERS                       ;#764B: 38 15
        cp      10h                                            ;#764D: FE 10
        ret     c                                              ;#764F: D8
        jr      z,ADVANCE_ANIMATION_PHASE                      ;#7650: 28 13
        cp      22h                                            ;#7652: FE 22
        jr      nc,HIDE_DYNAMIC_SPRITE                         ;#7654: 30 16
        ld      c,5                                            ;#7656: 0E 05
        cp      1Ah                                            ;#7658: FE 1A
        jr      c,UPDATE_ANIM_FRAME_OFFSET                     ;#765A: 38 02
        inc     c                                              ;#765C: 0C
        inc     c                                              ;#765D: 0C
UPDATE_ANIM_FRAME_OFFSET:
        ; Add offset to animation frame
        ld      a,(hl)                                         ;#765E: 7E
        add     a,c                                            ;#765F: 81
        ld      (hl),a                                         ;#7660: 77
        ret                                                    ;#7661: C9

DEC_ANIMATION_COUNTERS:
        ; Decrement animation counters
        dec     (hl)                                           ;#7662: 35
        dec     (hl)                                           ;#7663: 35
        ret                                                    ;#7664: C9

ADVANCE_ANIMATION_PHASE:
        ; Advance to next animation phase
        inc     hl                                             ;#7665: 23
        inc     hl                                             ;#7666: 23
        ld      a,(hl)                                         ;#7667: 7E
        add     a,8                                            ;#7668: C6 08
        ld      (hl),a                                         ;#766A: 77
        ret                                                    ;#766B: C9

HIDE_DYNAMIC_SPRITE:
        ; Hide a dynamic sprite and clear its RAM entry
        ld      (hl),0E0h                                      ;#766C: 36 E0
        xor     a                                              ;#766E: AF
        ld      (de),a                                         ;#766F: 12
        inc     de                                             ;#7670: 13
        ld      (de),a                                         ;#7671: 12
        jr      SYNC_SPRITE_LOOP                               ;#7672: 18 A3

SYNC_ANIMATION_TIMER:
        ; Sync animation with global timer
        ld      a,(FRAME_COUNTER)                              ;#7674: 3A 03 E0
        and     0Fh                                            ;#7677: E6 0F
        ret     nz                                             ;#7679: C0
        ld      a,(hl)                                         ;#767A: 7E
        srl     a                                              ;#767B: CB 3F
        srl     a                                              ;#767D: CB 3F
        srl     a                                              ;#767F: CB 3F
        ccf                                                    ;#7681: 3F
        rla                                                    ;#7682: 17
        rla                                                    ;#7683: 17
        rla                                                    ;#7684: 17
        ld      (hl),a                                         ;#7685: 77
        ret                                                    ;#7686: C9

PROCESS_PENGUIN_INPUT_AND_MOVE:
        ; Handle keyboard/joystick and update penguin position
        call    HANDLE_SPEED_INPUT                             ;#7687: CD D2 76
        ld      a,(PENGUIN_SPEED)                              ;#768A: 3A 00 E1
        or      a                                              ;#768D: B7
        rra                                                    ;#768E: 1F
        ld      (DEMO_PLAY_MASK_RELOAD),a                      ;#768F: 32 48 E1
        ld      a,(STAGE_DISTANCE_HIGH)                        ;#7692: 3A E6 E0
        and     0Ch                                            ;#7695: E6 0C
        ld      a,2Ch                                          ;#7697: 3E 2C
        jr      nz,SPEED_FORCE_LOW_GEAR                        ;#7699: 20 02
        add     a,4                                            ;#769B: C6 04
SPEED_FORCE_LOW_GEAR:
        ; Branch for handling low distance speed override
        ld      c,a                                            ;#769D: 4F
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#769E: 3A E0 E0
        and     0F0h                                           ;#76A1: E6 F0
        jr      z,CALC_ITEM_TICK_PERIOD                        ;#76A3: 28 0C
        and     0E0h                                           ;#76A5: E6 E0
        jr      z,SPEED_DEC_VERY_FAST                          ;#76A7: 28 04
        ld      a,c                                            ;#76A9: 79
        sub     4                                              ;#76AA: D6 04
        ld      c,a                                            ;#76AC: 4F
SPEED_DEC_VERY_FAST:
        ; Reduce speed context A
        ld      a,c                                            ;#76AD: 79
        sub     4                                              ;#76AE: D6 04
        ld      c,a                                            ;#76B0: 4F
CALC_ITEM_TICK_PERIOD:
        ; Adjust item-tick period from PENGUIN_SPEED
        ld      a,(PENGUIN_SPEED)                              ;#76B1: 3A 00 E1
        cp      0Ch                                            ;#76B4: FE 0C
        jr      c,SPEED_DEC_FAST                               ;#76B6: 38 0D
        and     0Ch                                            ;#76B8: E6 0C
        jr      z,SPEED_DEC_SLOW                               ;#76BA: 28 11
        cp      0Ch                                            ;#76BC: FE 0C
        jr      z,SET_ITEM_TICK_PERIOD                         ;#76BE: 28 09
        ld      a,c                                            ;#76C0: 79
STORE_ITEM_TICK_PERIOD:
        ; Store final item-tick period to ITEM_TICK_PERIOD
        ld      (ITEM_TICK_PERIOD),a                           ;#76C1: 32 0E E1
        ret                                                    ;#76C4: C9

SPEED_DEC_FAST:
        ; Reduce speed context B
        ld      a,c                                            ;#76C5: 79
        sub     4                                              ;#76C6: D6 04
        ld      c,a                                            ;#76C8: 4F
SET_ITEM_TICK_PERIOD:
        ; Set calculated item-tick period (shared tail of CALC_ITEM_TICK_PERIOD)
        ld      a,c                                            ;#76C9: 79
        sub     4                                              ;#76CA: D6 04
        ld      c,a                                            ;#76CC: 4F
SPEED_DEC_SLOW:
        ; Reduce speed context C
        ld      a,c                                            ;#76CD: 79
        sub     4                                              ;#76CE: D6 04
        jr      STORE_ITEM_TICK_PERIOD                         ;#76D0: 18 EF

HANDLE_SPEED_INPUT:
        ; Process input keys and dispatch speed handler
        ld      a,(CUR_INPUT_KEYS)                             ;#76D2: 3A 09 E0
        and     3                                              ;#76D5: E6 03
        call    JUMP_TABLE_DISPATCHER                          ;#76D7: CD 98 40
        ; Dispatch table for Up/Down input (Bit 0=Up, Bit 1=Down)
        ; 00: None (Coast)
        ; 01: Up (Accelerate)
        ; 02: Down (Brake)
        ; 03: Up+Down (Coast)
        dw      HANDLE_SPEED_COAST                             ;#76DA: 10 77
        dw      HANDLE_SPEED_UP                                ;#76DC: E2 76
        dw      HANDLE_SPEED_DOWN                              ;#76DE: FA 76
        dw      HANDLE_SPEED_COAST                             ;#76E0: 10 77

HANDLE_SPEED_UP:
        ; Handle 'Up' input (Accelerate)
        ld      hl,SPEED_ACCEL_DELAY-1                         ;#76E2: 21 FD E0
        xor     a                                              ;#76E5: AF
        ld      (hl),a                                         ;#76E6: 77
        inc     hl                                             ;#76E7: 23
        inc     hl                                             ;#76E8: 23
        ld      (hl),a                                         ;#76E9: 77
        dec     hl                                             ;#76EA: 2B
        inc     (hl)                                           ;#76EB: 34
        ld      a,(hl)                                         ;#76EC: 7E
        sub     0Ch                                            ;#76ED: D6 0C
        ret     nz                                             ;#76EF: C0
        ld      (hl),a                                         ;#76F0: 77
        ld      hl,PENGUIN_SPEED                               ;#76F1: 21 00 E1
        ld      a,(hl)                                         ;#76F4: 7E
        cp      9                                              ;#76F5: FE 09
        ret     c                                              ;#76F7: D8
        dec     (hl)                                           ;#76F8: 35
        ret                                                    ;#76F9: C9

HANDLE_SPEED_DOWN:
        ; Handle 'Down' input (Brake)
        ld      hl,SPEED_ACCEL_DELAY-1                         ;#76FA: 21 FD E0
        xor     a                                              ;#76FD: AF
        ld      (hl),a                                         ;#76FE: 77
        inc     hl                                             ;#76FF: 23
        ld      (hl),a                                         ;#7700: 77
        inc     hl                                             ;#7701: 23
        inc     (hl)                                           ;#7702: 34
        ld      a,(hl)                                         ;#7703: 7E
        sub     4                                              ;#7704: D6 04
        ret     nz                                             ;#7706: C0
        ld      (hl),a                                         ;#7707: 77
        ld      hl,PENGUIN_SPEED                               ;#7708: 21 00 E1
        ld      a,(hl)                                         ;#770B: 7E
        cp      13h                                            ;#770C: FE 13
        ret     nc                                             ;#770E: D0
        inc     (hl)                                           ;#770F: 34
HANDLE_SPEED_COAST:
        ; Handle no Up/Down input
        ret                                                    ;#7710: C9

CALC_HUD_SPEED_BAR:
        ; Build HUD speed-bar tile run from PENGUIN_SPEED into HUD_SPEED_BAR_TILES
        ld      a,(PENGUIN_FALL_TIMER)                         ;#7711: 3A 40 E1
        ld      hl,PENGUIN_STUN_TIMER                          ;#7714: 21 42 E1
        add     a,(hl)                                         ;#7717: 86
        ld      hl,HUD_SPEED_BAR_TILES                         ;#7718: 21 71 E1
        jr      nz,CALC_HUD_SPEED_BAR_PAD                      ;#771B: 20 1F
        ld      a,(PENGUIN_SPEED)                              ;#771D: 3A 00 E1
        ld      b,a                                            ;#7720: 47
        and     1                                              ;#7721: E6 01
        add     a,42h                                          ;#7723: C6 42
        ld      c,a                                            ;#7725: 4F
        ld      a,b                                            ;#7726: 78
        rra                                                    ;#7727: 1F
        cpl                                                    ;#7728: 2F
        and     0Fh                                            ;#7729: E6 0F
        sub     6                                              ;#772B: D6 06
        jr      z,CALC_HUD_SPEED_BAR_STORE                     ;#772D: 28 06
        ld      b,a                                            ;#772F: 47
CALC_HUD_SPEED_BAR_LOOP:
        ; Inner loop writing 42h tiles for the speed-bar fill
        ld      (hl),42h                                       ;#7730: 36 42
        inc     hl                                             ;#7732: 23
        djnz    CALC_HUD_SPEED_BAR_LOOP                        ;#7733: 10 FB
CALC_HUD_SPEED_BAR_STORE:
        ; Write the trailing animated tile (42h or 43h, alternating with speed)
        ld      (hl),c                                         ;#7735: 71
        inc     hl                                             ;#7736: 23
        ld      a,l                                            ;#7737: 7D
        cp      78h                                            ;#7738: FE 78
        jr      z,SYNC_HUD_SPEED_BAR                           ;#773A: 28 04
CALC_HUD_SPEED_BAR_PAD:
        ; Pad remaining slots with 0 until end of buffer
        ld      c,0                                            ;#773C: 0E 00
        jr      CALC_HUD_SPEED_BAR_STORE                       ;#773E: 18 F5

SYNC_HUD_SPEED_BAR:
        ; Copy HUD_SPEED_BAR_TILES to name table row 1, col 25
        ld      hl,HUD_SPEED_BAR_TILES                         ;#7740: 21 71 E1
        LOAD_NAME_TABLE de, 1, 25                              ;#7743: 11 39 38
        ld      bc,6                                           ;#7746: 01 06 00
        jp      COPY_RAM_TO_VRAM                               ;#7749: C3 DE 44

HANDLE_DEMO_PLAY_MASKING:
        ; Places 4 invisible sprites to mask other sprites (5th sprite limit)
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#774C: 3A 02 E0
        bit     6,a                                            ;#774F: CB 77
        ret     z                                              ;#7751: C8
        ld      b,4                                            ;#7752: 06 04
        ld      de,SAT_MIRROR + SPRITE_CLOUD + ATTR_Y          ;#7754: 11 B8 E0
        ld      hl,DEMO_PLAY_MASK_FLAGS                        ;#7757: 21 4A E1
DEMO_PLAY_MASK_LOOP:
        ; Loop for demo play masking
        ld      a,(hl)                                         ;#775A: 7E
        or      a                                              ;#775B: B7
        ld      a,4                                            ;#775C: 3E 04
        jr      nz,DEMO_PLAY_MASK_NEXT                         ;#775E: 20 1B
        push    hl                                             ;#7760: E5
        inc     (hl)                                           ;#7761: 34
        ld      hl,DEMO_PLAY_MASK_COORDS_DATA-2                ;#7762: 21 DF 77
        ld      a,b                                            ;#7765: 78
        add     a,a                                            ;#7766: 87
        call    ADD_HL_A                                       ;#7767: CD D1 48
        ld      a,(hl)                                         ;#776A: 7E
        ld      (de),a                                         ;#776B: 12
        inc     hl                                             ;#776C: 23
        inc     de                                             ;#776D: 13
        ld      a,(hl)                                         ;#776E: 7E
        ld      (de),a                                         ;#776F: 12
        inc     de                                             ;#7770: 13
        ld      a,0E0h                                         ;#7771: 3E E0
        ld      (de),a                                         ;#7773: 12
        inc     de                                             ;#7774: 13
        ld      a,0Fh                                          ;#7775: 3E 0F
        ld      (de),a                                         ;#7777: 12
        ld      a,1                                            ;#7778: 3E 01
        pop     hl                                             ;#777A: E1
DEMO_PLAY_MASK_NEXT:
        ; Next demo play mask entry
        call    ADD_DE_A                                       ;#777B: CD D6 48
        inc     hl                                             ;#777E: 23
        djnz    DEMO_PLAY_MASK_LOOP                            ;#777F: 10 D9
        ld      hl,DEMO_PLAY_MASK_TIMER                        ;#7781: 21 49 E1
        dec     (hl)                                           ;#7784: 35
        ret     nz                                             ;#7785: C0
        ld      a,(DEMO_PLAY_MASK_RELOAD)                      ;#7786: 3A 48 E1
        ld      (hl),a                                         ;#7789: 77
        ld      b,0                                            ;#778A: 06 00
        ld      hl,DEMO_PLAY_MASK_FLAGS                        ;#778C: 21 4A E1
        ld      de,SAT_MIRROR + SPRITE_CLOUD + ATTR_Y          ;#778F: 11 B8 E0
PROCESS_NEXT_CLOUD_SPRITE:
        ; Loop entry for processing the 4 cloud sprites
        ld      a,(hl)                                         ;#7792: 7E
        or      a                                              ;#7793: B7
        jr      z,ADVANCE_CLOUD_SPRITE_PTRS                    ;#7794: 28 2F
        ld      a,(de)                                         ;#7796: 1A
        cp      8                                              ;#7797: FE 08
        jr      nz,ANIMATE_CLOUD_SPRITES                       ;#7799: 20 07
        ld      a,0D1h                                         ;#779B: 3E D1
        ld      (de),a                                         ;#779D: 12
        ld      (hl),0                                         ;#779E: 36 00
        jr      ADVANCE_CLOUD_SPRITE_PTRS                      ;#77A0: 18 23

ANIMATE_CLOUD_SPRITES:
        ; Handles bobbing animation for Cloud sprites
        push    de                                             ;#77A2: D5
        inc     (hl)                                           ;#77A3: 34
        ex      de,hl                                          ;#77A4: EB
        dec     (hl)                                           ;#77A5: 35
        push    de                                             ;#77A6: D5
        ld      de,CLOUD_ANIMATION_OFFSETS                     ;#77A7: 11 DD 77
        ld      a,b                                            ;#77AA: 78
        call    ADD_DE_A                                       ;#77AB: CD D6 48
        ld      a,(de)                                         ;#77AE: 1A
        inc     hl                                             ;#77AF: 23
        add     a,(hl)                                         ;#77B0: 86
        ld      (hl),a                                         ;#77B1: 77
        ex      de,hl                                          ;#77B2: EB
        pop     hl                                             ;#77B3: E1
        ld      a,(hl)                                         ;#77B4: 7E
        cp      0Ch                                            ;#77B5: FE 0C
        ld      a,0DCh                                         ;#77B7: 3E DC
        jr      z,UPDATE_CLOUD_SPRITE_ATTR                     ;#77B9: 28 07
        ld      a,(hl)                                         ;#77BB: 7E
        cp      18h                                            ;#77BC: FE 18
        ld      a,0D8h                                         ;#77BE: 3E D8
        jr      nz,CLOUD_SPRITE_RESTORE_PTR                    ;#77C0: 20 02
UPDATE_CLOUD_SPRITE_ATTR:
        ; Updates a specific attribute at offset 1 during specific animation frames
        inc     de                                             ;#77C2: 13
        ld      (de),a                                         ;#77C3: 12
CLOUD_SPRITE_RESTORE_PTR:
        ; Restores the sprite pointer (DE) from the stack after potential updates
        pop     de                                             ;#77C4: D1
ADVANCE_CLOUD_SPRITE_PTRS:
        ; Advances the pointers to the next sprite in the batch of 4
        ld      a,4                                            ;#77C5: 3E 04
        call    ADD_DE_A                                       ;#77C7: CD D6 48
        inc     hl                                             ;#77CA: 23
        ld      a,4                                            ;#77CB: 3E 04
        inc     b                                              ;#77CD: 04
        cp      b                                              ;#77CE: B8
        jr      nz,PROCESS_NEXT_CLOUD_SPRITE                   ;#77CF: 20 C1
        ld      hl,SAT_MIRROR + SPRITE_CLOUD + ATTR_Y          ;#77D1: 21 B8 E0
        LOAD_SPRITE_ATTR de, 26, 0                             ;#77D4: 11 68 3B
        ld      bc,10h                                         ;#77D7: 01 10 00
        jp      COPY_RAM_TO_VRAM                               ;#77DA: C3 DE 44

CLOUD_ANIMATION_OFFSETS:
        ; Per-frame Y deltas for cloud sprite bobbing (4 signed bytes)
        ; Format: FORMAT_CLOUD_OFFSETS
        CLOUD_OFFSET -1                                        ;#77DD: FF
        CLOUD_OFFSET 1                                         ;#77DE: 01
        CLOUD_OFFSET -2                                        ;#77DF: FE
        CLOUD_OFFSET 2                                         ;#77E0: 02

DEMO_PLAY_MASK_COORDS_DATA:
        ; Demo play-mask sprite (Y, X) pairs (4 sprites x 2 unsigned bytes)
        ; Format: FORMAT_SPRITE_YX_PAIRS
        SPRITE_YX 38h, 98h                                     ;#77E1: 38 98
        SPRITE_YX 37h, 58h                                     ;#77E3: 37 58
        SPRITE_YX 3Ch, 7Ch                                     ;#77E5: 3C 7C
        SPRITE_YX 3Ah, 74h                                     ;#77E7: 3A 74

HANDLE_SPECIAL_ITEM_EVENT:
        ; Processes effect of special item collision
        ld      a,(FISH_POS_STATE)                             ;#77E9: 3A 83 E1
        and     0E0h                                           ;#77EC: E6 E0
        ret     z                                              ;#77EE: C8
        ld      hl,(ITEM_COLLISION_PTR)                        ;#77EF: 2A 81 E1
        ld      a,(hl)                                         ;#77F2: 7E
        ld      hl,FISH_POS_STATE                              ;#77F3: 21 83 E1
        sub     0Fh                                            ;#77F6: D6 0F
        jr      nz,LOAD_ITEM_ANIM_PTR                          ;#77F8: 20 08
        ld      (hl),a                                         ;#77FA: 77
        ld      hl,ITEM_POS_OFFSCREEN                          ;#77FB: 21 64 79
        ld      b,4                                            ;#77FE: 06 04
        jr      INIT_ANIM_BUFFER_PTRS                          ;#7800: 18 3C

LOAD_ITEM_ANIM_PTR:
        ; Load pointer to animation data
        ld      hl,ITEM_ANIM_SEAL_TABLE                        ;#7802: 21 68 78
        add     a,8                                            ;#7805: C6 08
        ld      b,a                                            ;#7807: 47
        add     a,a                                            ;#7808: 87
        call    ADD_HL_A                                       ;#7809: CD D1 48
        ld      e,(hl)                                         ;#780C: 5E
        inc     hl                                             ;#780D: 23
        ld      d,(hl)                                         ;#780E: 56
        ld      a,b                                            ;#780F: 78
        ld      b,4                                            ;#7810: 06 04
        cp      6                                              ;#7812: FE 06
        jr      c,CHECK_ANIM_FRAME_INDEX                       ;#7814: 38 0C
        ld      hl,FISH_POS_GUARD_FLAG                         ;#7816: 21 37 E1
        bit     0,(hl)                                         ;#7819: CB 46
        jr      nz,CHECK_ANIM_FRAME_INDEX                      ;#781B: 20 05
        ld      hl,FISH_POS_VRAM_SELECT                        ;#781D: 21 92 E1
        ld      (hl),1                                         ;#7820: 36 01
CHECK_ANIM_FRAME_INDEX:
        ; Check animation frame index validity
        cp      3                                              ;#7822: FE 03
        ex      de,hl                                          ;#7824: EB
        ld      d,0Ch                                          ;#7825: 16 0C
        jr      nc,CALC_ANIM_SOURCE_ADDR                       ;#7827: 30 04
        ld      d,6                                            ;#7829: 16 06
        ld      b,2                                            ;#782B: 06 02
CALC_ANIM_SOURCE_ADDR:
        ; Calculate source address for animation data
        ld      a,(FISH_POS_STATE)                             ;#782D: 3A 83 E1
        cp      40h                                            ;#7830: FE 40
        jr      z,INIT_ANIM_BUFFER_PTRS                        ;#7832: 28 0A
        jr      c,CALC_ANIM_SOURCE_NEXT                        ;#7834: 38 04
        ld      a,d                                            ;#7836: 7A
        call    ADD_HL_A                                       ;#7837: CD D1 48
CALC_ANIM_SOURCE_NEXT:
        ; Next animation source calculation step
        ld      a,d                                            ;#783A: 7A
        call    ADD_HL_A                                       ;#783B: CD D1 48
INIT_ANIM_BUFFER_PTRS:
        ; Initialize pointers for animation buffer copy
        ld      de,SAT_MIRROR + SPRITE_OBSTACLE + ATTR_Y       ;#783E: 11 90 E0
        push    de                                             ;#7841: D5
ANIM_FRAME_COPY_LOOP:
        ; Outer loop for copying animation frame data
        ld      c,3                                            ;#7842: 0E 03
ANIM_BYTE_COPY_LOOP:
        ; Inner loop for copying attribute bytes
        ld      a,(hl)                                         ;#7844: 7E
        ld      (de),a                                         ;#7845: 12
        inc     hl                                             ;#7846: 23
        inc     de                                             ;#7847: 13
        dec     c                                              ;#7848: 0D
        jr      nz,ANIM_BYTE_COPY_LOOP                         ;#7849: 20 F9
        inc     de                                             ;#784B: 13
        djnz    ANIM_FRAME_COPY_LOOP                           ;#784C: 10 F4
        pop     hl                                             ;#784E: E1
        ld      c,10h                                          ;#784F: 0E 10
        ld      a,(FISH_POS_VRAM_SELECT)                       ;#7851: 3A 92 E1
        rra                                                    ;#7854: 1F
        ld      de,VRAM_SAT_BASE                               ;#7855: 11 00 3B
        jr      nc,UPLOAD_ANIM_TO_VRAM_HIGH                    ;#7858: 30 06
        call    COPY_RAM_TO_VRAM                               ;#785A: CD DE 44
        ld      hl,SAT_MIRROR                                  ;#785D: 21 50 E0
UPLOAD_ANIM_TO_VRAM_HIGH:
        ; Upload animation data to high VRAM address
        LOAD_SPRITE_ATTR de, 16, 0                             ;#7860: 11 40 3B
        ld      c,10h                                          ;#7863: 0E 10
        jp      COPY_RAM_TO_VRAM                               ;#7865: C3 DE 44

ITEM_ANIM_SEAL_TABLE:
        ; Pointer table for seal-approach animation frames (9 entries)
        dw      ITEM_ANIM_SEAL_0                               ;#7868: 7A 78
        dw      ITEM_ANIM_SEAL_1                               ;#786A: 8C 78
        dw      ITEM_ANIM_SEAL_2                               ;#786C: 9E 78
        dw      ITEM_ANIM_SEAL_3                               ;#786E: B0 78
        dw      ITEM_ANIM_SEAL_4                               ;#7870: D4 78
        dw      ITEM_ANIM_SEAL_5                               ;#7872: F8 78
        dw      ITEM_ANIM_SEAL_6                               ;#7874: 1C 79
        dw      ITEM_ANIM_SEAL_7                               ;#7876: 40 79
        dw      ITEM_POS_OFFSCREEN                             ;#7878: 64 79

ITEM_ANIM_SEAL_0:
        ; Seal approach frame 0 (farthest; 3 positions x 2 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 67h, 78h, 7Ch                        ;#787A: 67 78 7C
        SPRITE_ANIM_FRAME 67h, 78h, 0E8h                       ;#787D: 67 78 E8
        SPRITE_ANIM_FRAME 67h, 90h, 7Ch                        ;#7880: 67 90 7C
        SPRITE_ANIM_FRAME 67h, 90h, 0E8h                       ;#7883: 67 90 E8
        SPRITE_ANIM_FRAME 67h, 60h, 7Ch                        ;#7886: 67 60 7C
        SPRITE_ANIM_FRAME 67h, 60h, 0E8h                       ;#7889: 67 60 E8

ITEM_ANIM_SEAL_1:
        ; Seal approach frame 1 (3 positions x 2 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 6Ch, 78h, 0B8h                       ;#788C: 6C 78 B8
        SPRITE_ANIM_FRAME 6Ch, 78h, 0BCh                       ;#788F: 6C 78 BC
        SPRITE_ANIM_FRAME 6Ch, 94h, 0B8h                       ;#7892: 6C 94 B8
        SPRITE_ANIM_FRAME 6Ch, 94h, 0BCh                       ;#7895: 6C 94 BC
        SPRITE_ANIM_FRAME 6Ch, 5Bh, 0B8h                       ;#7898: 6C 5B B8
        SPRITE_ANIM_FRAME 6Ch, 5Bh, 0BCh                       ;#789B: 6C 5B BC

ITEM_ANIM_SEAL_2:
        ; Seal approach frame 2 (3 positions x 2 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 78h, 78h, 0B8h                       ;#789E: 78 78 B8
        SPRITE_ANIM_FRAME 78h, 78h, 0BCh                       ;#78A1: 78 78 BC
        SPRITE_ANIM_FRAME 78h, 9Dh, 0B8h                       ;#78A4: 78 9D B8
        SPRITE_ANIM_FRAME 78h, 9Dh, 0BCh                       ;#78A7: 78 9D BC
        SPRITE_ANIM_FRAME 78h, 53h, 0B8h                       ;#78AA: 78 53 B8
        SPRITE_ANIM_FRAME 78h, 53h, 0BCh                       ;#78AD: 78 53 BC

ITEM_ANIM_SEAL_3:
        ; Seal approach frame 3 (3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 7Bh, 78h, 0C0h                       ;#78B0: 7B 78 C0
        SPRITE_ANIM_FRAME 8Bh, 70h, 0C4h                       ;#78B3: 8B 70 C4
        SPRITE_ANIM_FRAME 7Bh, 78h, 0C8h                       ;#78B6: 7B 78 C8
        SPRITE_ANIM_FRAME 8Bh, 80h, 0CCh                       ;#78B9: 8B 80 CC
        SPRITE_ANIM_FRAME 7Bh, 0A4h, 0C0h                      ;#78BC: 7B A4 C0
        SPRITE_ANIM_FRAME 8Bh, 9Ch, 0C4h                       ;#78BF: 8B 9C C4
        SPRITE_ANIM_FRAME 7Bh, 0A4h, 0C8h                      ;#78C2: 7B A4 C8
        SPRITE_ANIM_FRAME 8Bh, 0ACh, 0CCh                      ;#78C5: 8B AC CC
        SPRITE_ANIM_FRAME 7Bh, 4Ch, 0C0h                       ;#78C8: 7B 4C C0
        SPRITE_ANIM_FRAME 8Bh, 44h, 0C4h                       ;#78CB: 8B 44 C4
        SPRITE_ANIM_FRAME 7Bh, 4Ch, 0C8h                       ;#78CE: 7B 4C C8
        SPRITE_ANIM_FRAME 8Bh, 54h, 0CCh                       ;#78D1: 8B 54 CC

ITEM_ANIM_SEAL_4:
        ; Seal approach frame 4 (3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 86h, 78h, 0C0h                       ;#78D4: 86 78 C0
        SPRITE_ANIM_FRAME 96h, 70h, 0C4h                       ;#78D7: 96 70 C4
        SPRITE_ANIM_FRAME 86h, 78h, 0C8h                       ;#78DA: 86 78 C8
        SPRITE_ANIM_FRAME 96h, 80h, 0CCh                       ;#78DD: 96 80 CC
        SPRITE_ANIM_FRAME 86h, 0ACh, 0C0h                      ;#78E0: 86 AC C0
        SPRITE_ANIM_FRAME 96h, 0A4h, 0C4h                      ;#78E3: 96 A4 C4
        SPRITE_ANIM_FRAME 86h, 0ACh, 0C8h                      ;#78E6: 86 AC C8
        SPRITE_ANIM_FRAME 96h, 0B4h, 0CCh                      ;#78E9: 96 B4 CC
        SPRITE_ANIM_FRAME 86h, 44h, 0C0h                       ;#78EC: 86 44 C0
        SPRITE_ANIM_FRAME 96h, 3Ch, 0C4h                       ;#78EF: 96 3C C4
        SPRITE_ANIM_FRAME 86h, 44h, 0C8h                       ;#78F2: 86 44 C8
        SPRITE_ANIM_FRAME 96h, 4Ch, 0CCh                       ;#78F5: 96 4C CC

ITEM_ANIM_SEAL_5:
        ; Seal approach frame 5 (3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 8Fh, 78h, 0C0h                       ;#78F8: 8F 78 C0
        SPRITE_ANIM_FRAME 9Fh, 70h, 0C4h                       ;#78FB: 9F 70 C4
        SPRITE_ANIM_FRAME 8Fh, 78h, 0C8h                       ;#78FE: 8F 78 C8
        SPRITE_ANIM_FRAME 9Fh, 80h, 0CCh                       ;#7901: 9F 80 CC
        SPRITE_ANIM_FRAME 8Fh, 0B2h, 0C0h                      ;#7904: 8F B2 C0
        SPRITE_ANIM_FRAME 9Fh, 0AAh, 0C4h                      ;#7907: 9F AA C4
        SPRITE_ANIM_FRAME 8Fh, 0B2h, 0C8h                      ;#790A: 8F B2 C8
        SPRITE_ANIM_FRAME 9Fh, 0BAh, 0CCh                      ;#790D: 9F BA CC
        SPRITE_ANIM_FRAME 8Fh, 3Eh, 0C0h                       ;#7910: 8F 3E C0
        SPRITE_ANIM_FRAME 9Fh, 36h, 0C4h                       ;#7913: 9F 36 C4
        SPRITE_ANIM_FRAME 8Fh, 3Eh, 0C8h                       ;#7916: 8F 3E C8
        SPRITE_ANIM_FRAME 9Fh, 46h, 0CCh                       ;#7919: 9F 46 CC

ITEM_ANIM_SEAL_6:
        ; Seal approach frame 6 (3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 98h, 78h, 0C0h                       ;#791C: 98 78 C0
        SPRITE_ANIM_FRAME 0A8h, 70h, 0C4h                      ;#791F: A8 70 C4
        SPRITE_ANIM_FRAME 98h, 78h, 0C8h                       ;#7922: 98 78 C8
        SPRITE_ANIM_FRAME 0A8h, 80h, 0CCh                      ;#7925: A8 80 CC
        SPRITE_ANIM_FRAME 98h, 0B8h, 0C0h                      ;#7928: 98 B8 C0
        SPRITE_ANIM_FRAME 0A8h, 0B0h, 0C4h                     ;#792B: A8 B0 C4
        SPRITE_ANIM_FRAME 98h, 0B8h, 0C8h                      ;#792E: 98 B8 C8
        SPRITE_ANIM_FRAME 0A8h, 0C0h, 0CCh                     ;#7931: A8 C0 CC
        SPRITE_ANIM_FRAME 98h, 38h, 0C0h                       ;#7934: 98 38 C0
        SPRITE_ANIM_FRAME 0A8h, 30h, 0C4h                      ;#7937: A8 30 C4
        SPRITE_ANIM_FRAME 98h, 38h, 0C8h                       ;#793A: 98 38 C8
        SPRITE_ANIM_FRAME 0A8h, 40h, 0CCh                      ;#793D: A8 40 CC

ITEM_ANIM_SEAL_7:
        ; Seal approach frame 7 (closest; 3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 0A1h, 78h, 0C0h                      ;#7940: A1 78 C0
        SPRITE_ANIM_FRAME 0B1h, 70h, 0C4h                      ;#7943: B1 70 C4
        SPRITE_ANIM_FRAME 0A1h, 78h, 0C8h                      ;#7946: A1 78 C8
        SPRITE_ANIM_FRAME 0B1h, 80h, 0CCh                      ;#7949: B1 80 CC
        SPRITE_ANIM_FRAME 0A1h, 0BEh, 0C0h                     ;#794C: A1 BE C0
        SPRITE_ANIM_FRAME 0B1h, 0B6h, 0C4h                     ;#794F: B1 B6 C4
        SPRITE_ANIM_FRAME 0A1h, 0BEh, 0C8h                     ;#7952: A1 BE C8
        SPRITE_ANIM_FRAME 0B1h, 0C6h, 0CCh                     ;#7955: B1 C6 CC
        SPRITE_ANIM_FRAME 0A1h, 32h, 0C0h                      ;#7958: A1 32 C0
        SPRITE_ANIM_FRAME 0B1h, 2Ah, 0C4h                      ;#795B: B1 2A C4
        SPRITE_ANIM_FRAME 0A1h, 32h, 0C8h                      ;#795E: A1 32 C8
        SPRITE_ANIM_FRAME 0B1h, 3Ah, 0CCh                      ;#7961: B1 3A CC

ITEM_POS_OFFSCREEN:
        ; Off-screen/reset position
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 0E0h, 0, 0                           ;#7964: E0 00 00
        SPRITE_ANIM_FRAME 0E0h, 0, 0                           ;#7967: E0 00 00
        SPRITE_ANIM_FRAME 0E0h, 0, 0                           ;#796A: E0 00 00
        SPRITE_ANIM_FRAME 0E0h, 0, 0                           ;#796D: E0 00 00

PLAY_SOUND_SAFE:
        ; Start sound track (Saves registers, disables INT)
        di                                                     ;#7970: F3
        push    hl                                             ;#7971: E5
        push    de                                             ;#7972: D5
        push    bc                                             ;#7973: C5
        push    af                                             ;#7974: F5
        call    PLAY_SOUND                                     ;#7975: CD 7E 79
        pop     af                                             ;#7978: F1
        pop     bc                                             ;#7979: C1
        pop     de                                             ;#797A: D1
        pop     hl                                             ;#797B: E1
        ei                                                     ;#797C: FB
        ret                                                    ;#797D: C9

PLAY_SOUND:
        ; Start sound track
        ld      b,2                                            ;#797E: 06 02
        ld      hl,MUSIC_VARS_CH0+MUSIC_DRIVER_CONTROL         ;#7980: 21 12 E0
        cp      8Ah                                            ;#7983: FE 8A
        jr      c,PLAY_SOUND_SELECT_CH2                        ;#7985: 38 07
        cp      8Ch                                            ;#7987: FE 8C
        jr      c,PLAY_SOUND_CHECK_PRIORITY                    ;#7989: 38 07
        inc     b                                              ;#798B: 04
        jr      PLAY_SOUND_CHECK_PRIORITY                      ;#798C: 18 04

PLAY_SOUND_SELECT_CH2:
        ; Sets the target channel to Channel 2 for high-priority sounds
        dec     b                                              ;#798E: 05
        ld      hl,MUSIC_VARS_CH2+MUSIC_DRIVER_CONTROL         ;#798F: 21 26 E0
PLAY_SOUND_CHECK_PRIORITY:
        ; Checks if the requested sound has higher priority than the currently playing one
        cp      (hl)                                           ;#7992: BE
        jr      c,PLAY_SOUND_DONE                              ;#7993: 38 23
        ld      c,a                                            ;#7995: 4F
        and     3Fh                                            ;#7996: E6 3F
        add     a,a                                            ;#7998: 87
        ld      de,SOUND_TABLE-2                               ;#7999: 11 F2 7A
        call    ADD_DE_A                                       ;#799C: CD D6 48
PLAY_SOUND_INIT_CHANNEL_DATA:
        ; Initialize channel data pointers from sound table
        dec     hl                                             ;#799F: 2B
        dec     hl                                             ;#79A0: 2B
        ld      (hl),1                                         ;#79A1: 36 01
        inc     hl                                             ;#79A3: 23
        ld      (hl),1                                         ;#79A4: 36 01
        inc     hl                                             ;#79A6: 23
        ld      a,c                                            ;#79A7: 79
        ld      (hl),a                                         ;#79A8: 77
        inc     hl                                             ;#79A9: 23
        ld      a,(de)                                         ;#79AA: 1A
        ld      (hl),a                                         ;#79AB: 77
        inc     hl                                             ;#79AC: 23
        inc     de                                             ;#79AD: 13
        ld      a,(de)                                         ;#79AE: 1A
        ld      (hl),a                                         ;#79AF: 77
        ld      a,8                                            ;#79B0: 3E 08
        call    ADD_HL_A                                       ;#79B2: CD D1 48
        inc     de                                             ;#79B5: 13
        djnz    PLAY_SOUND_INIT_CHANNEL_DATA                   ;#79B6: 10 E7
PLAY_SOUND_DONE:
        ; Sound priority check finished
        ret                                                    ;#79B8: C9

PLAY_SOUND_HANDLE_REPEAT:
        ; Process the repeat/loop command in sound data
        inc     hl                                             ;#79B9: 23
        ld      a,(hl)                                         ;#79BA: 7E
        inc     a                                              ;#79BB: 3C
        jr      z,PLAY_SOUND_FETCH_STATUS                      ;#79BC: 28 10
        inc     (ix+MUSIC_DRIVER_REPEAT_COUNT)                 ;#79BE: DD 34 09
        dec     a                                              ;#79C1: 3D
        cp      (ix+MUSIC_DRIVER_REPEAT_COUNT)                 ;#79C2: DD BE 09
        jr      nz,PLAY_SOUND_FETCH_STATUS                     ;#79C5: 20 07
        xor     a                                              ;#79C7: AF
        ld      (ix+MUSIC_DRIVER_REPEAT_COUNT),a               ;#79C8: DD 77 09
        jp      PROCESS_SOUND_END_OF_SOUND                     ;#79CB: C3 44 7A

PLAY_SOUND_FETCH_STATUS:
        ; Resume processing by fetching current channel status
        ld      a,(ix+MUSIC_DRIVER_CONTROL)                    ;#79CE: DD 7E 02
        push    bc                                             ;#79D1: C5
        call    PLAY_SOUND                                     ;#79D2: CD 7E 79
        pop     bc                                             ;#79D5: C1
        ret                                                    ;#79D6: C9

PROCESS_SOUND:
        ; Entry point for periodic sound engine update (interrupt driven)
        ld      c,1                                            ;#79D7: 0E 01
        ld      ix,MUSIC_VARS_CH0                              ;#79D9: DD 21 10 E0
        exx                                                    ;#79DD: D9
        ld      b,3                                            ;#79DE: 06 03
        ld      de,0Ah                                         ;#79E0: 11 0A 00
PROCESS_SOUND_CHANNEL_LOOP:
        ; Loop entry for processing the three PSG sound channels
        exx                                                    ;#79E3: D9
        ld      a,(ix+MUSIC_DRIVER_CONTROL)                    ;#79E4: DD 7E 02
        or      a                                              ;#79E7: B7
        call    nz,PROCESS_SOUND_CHANNEL                       ;#79E8: C4 F4 79
        inc     c                                              ;#79EB: 0C
        inc     c                                              ;#79EC: 0C
        exx                                                    ;#79ED: D9
        add     ix,de                                          ;#79EE: DD 19
        djnz    PROCESS_SOUND_CHANNEL_LOOP                     ;#79F0: 10 F1
        exx                                                    ;#79F2: D9
        ret                                                    ;#79F3: C9

PROCESS_SOUND_CHANNEL:
        ; Process the current state of a single sound channel
        jp      m,PROCESS_SOUND_DECREMENT_TIMER                ;#79F4: FA 4B 7A
        dec     (ix)                                           ;#79F7: DD 35 00
        ret     nz                                             ;#79FA: C0
PROCESS_SOUND_READ_NEXT_BYTE:
        ; Fetch and decode the next byte from the sound stream
        ld      l,(ix+MUSIC_DRIVER_STREAM_PTR_LO)              ;#79FB: DD 6E 03
        ld      h,(ix+MUSIC_DRIVER_STREAM_PTR_HI)              ;#79FE: DD 66 04
        ld      a,(hl)                                         ;#7A01: 7E
        cp      0FEh                                           ;#7A02: FE FE
        jr      z,PLAY_SOUND_HANDLE_REPEAT                     ;#7A04: 28 B3
        jr      nc,PROCESS_SOUND_END_OF_SOUND                  ;#7A06: 30 3C
        bit     7,(ix+MUSIC_DRIVER_CONTROL)                    ;#7A08: DD CB 02 7E
        jp      nz,PROCESS_SOUND_SPECIAL_MARKER                ;#7A0C: C2 76 7A
        and     0F0h                                           ;#7A0F: E6 F0
        cp      20h                                            ;#7A11: FE 20
        jr      nz,PROCESS_SOUND_SKIP_SET_VOL                  ;#7A13: 20 07
        ld      a,(hl)                                         ;#7A15: 7E
        and     0Fh                                            ;#7A16: E6 0F
        ld      (ix+MUSIC_DRIVER_DURATION_BASE),a              ;#7A18: DD 77 01
        inc     hl                                             ;#7A1B: 23
PROCESS_SOUND_SKIP_SET_VOL:
        ; Skip setting the volume if the command is not 0x20
        ld      a,(hl)                                         ;#7A1C: 7E
        and     0F0h                                           ;#7A1D: E6 F0
        ld      b,a                                            ;#7A1F: 47
        xor     (hl)                                           ;#7A20: AE
        ld      d,a                                            ;#7A21: 57
        inc     hl                                             ;#7A22: 23
        ld      e,(hl)                                         ;#7A23: 5E
        inc     hl                                             ;#7A24: 23
        ld      (ix+MUSIC_DRIVER_STREAM_PTR_LO),l              ;#7A25: DD 75 03
        ld      (ix+MUSIC_DRIVER_STREAM_PTR_HI),h              ;#7A28: DD 74 04
        ex      de,hl                                          ;#7A2B: EB
        call    PROCESS_SOUND_WRITE_PERIOD                     ;#7A2C: CD C8 7A
        ld      a,b                                            ;#7A2F: 78
        rrca                                                   ;#7A30: 0F
        rrca                                                   ;#7A31: 0F
        rrca                                                   ;#7A32: 0F
        rrca                                                   ;#7A33: 0F
        and     0Fh                                            ;#7A34: E6 0F
PROCESS_SOUND_UPDATE_CHANNEL_REGS:
        ; Updates channel state pointers and duration counters
        ld      h,a                                            ;#7A36: 67
        ld      a,(ix+MUSIC_DRIVER_DURATION_BASE)              ;#7A37: DD 7E 01
        ld      (ix),a                                         ;#7A3A: DD 77 00
        add     a,3                                            ;#7A3D: C6 03
        ld      (ix+MUSIC_DRIVER_SUSTAIN_TIMER),a              ;#7A3F: DD 77 08
        jr      PROCESS_SOUND_WRITE_VOLUME                     ;#7A42: 18 28

PROCESS_SOUND_END_OF_SOUND:
        ; Handle the end of a sound data stream
        xor     a                                              ;#7A44: AF
        ld      (ix+MUSIC_DRIVER_CONTROL),a                    ;#7A45: DD 77 02
        ld      h,a                                            ;#7A48: 67
        jr      PROCESS_SOUND_WRITE_VOLUME                     ;#7A49: 18 21

PROCESS_SOUND_DECREMENT_TIMER:
        ; Logic to decrement the main sound duration timer
        dec     (ix)                                           ;#7A4B: DD 35 00
        jr      z,PROCESS_SOUND_READ_NEXT_BYTE                 ;#7A4E: 28 AB
        dec     (ix+MUSIC_DRIVER_SUSTAIN_TIMER)                ;#7A50: DD 35 08
        ld      a,(ix+MUSIC_DRIVER_SUSTAIN_TIMER)              ;#7A53: DD 7E 08
        cp      (ix)                                           ;#7A56: DD BE 00
        jr      nz,PROCESS_SOUND_DECREMENT_TIMER2              ;#7A59: 20 05
        cp      1                                              ;#7A5B: FE 01
        jr      c,PROCESS_SOUND_RESET_TIMER2                   ;#7A5D: 38 04
        ret                                                    ;#7A5F: C9

PROCESS_SOUND_DECREMENT_TIMER2:
        ; Logic to decrement the secondary duration timer
        dec     (ix+MUSIC_DRIVER_SUSTAIN_TIMER)                ;#7A60: DD 35 08
PROCESS_SOUND_RESET_TIMER2:
        ; Reset the secondary timer from the initial value
        ld      a,(ix+MUSIC_DRIVER_SUSTAIN_COUNTER)            ;#7A63: DD 7E 07
        dec     a                                              ;#7A66: 3D
        ret     m                                              ;#7A67: F8
        ld      (ix+MUSIC_DRIVER_SUSTAIN_COUNTER),a            ;#7A68: DD 77 07
        ld      h,a                                            ;#7A6B: 67
PROCESS_SOUND_WRITE_VOLUME:
        ; Write volume to current PSG channel
        ld      a,c                                            ;#7A6C: 79
        rrca                                                   ;#7A6D: 0F
        add     a,88h                                          ;#7A6E: C6 88
        out     (PSG_ADDR),a                                   ;#7A70: D3 A0
        ld      a,h                                            ;#7A72: 7C
        out     (PSG_WRDATA),a                                 ;#7A73: D3 A1
        ret                                                    ;#7A75: C9

PROCESS_SOUND_SPECIAL_MARKER:
        ; Decode special markers (>= 0xFD) in the sound stream
        cp      0FDh                                           ;#7A76: FE FD
        jr      nz,PROCESS_SOUND_OTHER_MARKER                  ;#7A78: 20 10
        inc     hl                                             ;#7A7A: 23
        ld      a,(hl)                                         ;#7A7B: 7E
        and     7                                              ;#7A7C: E6 07
        ld      (ix+MUSIC_DRIVER_OCTAVE),a                     ;#7A7E: DD 77 05
        xor     (hl)                                           ;#7A81: AE
        rrca                                                   ;#7A82: 0F
        rrca                                                   ;#7A83: 0F
        rrca                                                   ;#7A84: 0F
        ld      (ix+MUSIC_DRIVER_SUSTAIN_BASE),a               ;#7A85: DD 77 06
        inc     hl                                             ;#7A88: 23
        ld      a,(hl)                                         ;#7A89: 7E
PROCESS_SOUND_OTHER_MARKER:
        ; Decode markers other than 0xFD
        and     0Fh                                            ;#7A8A: E6 0F
        ld      b,a                                            ;#7A8C: 47
        xor     (hl)                                           ;#7A8D: AE
        inc     hl                                             ;#7A8E: 23
        ld      (ix+MUSIC_DRIVER_STREAM_PTR_LO),l              ;#7A8F: DD 75 03
        ld      (ix+MUSIC_DRIVER_STREAM_PTR_HI),h              ;#7A92: DD 74 04
        rrca                                                   ;#7A95: 0F
        rrca                                                   ;#7A96: 0F
        rrca                                                   ;#7A97: 0F
        rrca                                                   ;#7A98: 0F
        ld      hl,SOUND_DURATION_TABLE                        ;#7A99: 21 E4 7A
        call    ADD_HL_A                                       ;#7A9C: CD D1 48
        ld      a,(hl)                                         ;#7A9F: 7E
        ld      (ix+MUSIC_DRIVER_DURATION_BASE),a              ;#7AA0: DD 77 01
        ld      a,b                                            ;#7AA3: 78
        sub     0Ch                                            ;#7AA4: D6 0C
        ld      (ix+MUSIC_DRIVER_SUSTAIN_COUNTER),a            ;#7AA6: DD 77 07
        jr      z,PROCESS_SOUND_SKIP_PITCH_LOOKUP              ;#7AA9: 28 06
        ld      a,(ix+MUSIC_DRIVER_SUSTAIN_BASE)               ;#7AAB: DD 7E 06
        ld      (ix+MUSIC_DRIVER_SUSTAIN_COUNTER),a            ;#7AAE: DD 77 07
PROCESS_SOUND_SKIP_PITCH_LOOKUP:
        ; Skip pitch lookup for command 0x0C
        call    PROCESS_SOUND_UPDATE_CHANNEL_REGS              ;#7AB1: CD 36 7A
        ld      a,b                                            ;#7AB4: 78
        ld      hl,SOUND_PITCH_OFFSET_TABLE                    ;#7AB5: 21 D8 7A
        call    ADD_HL_A                                       ;#7AB8: CD D1 48
        ld      l,(hl)                                         ;#7ABB: 6E
        ld      h,0                                            ;#7ABC: 26 00
        ld      a,(ix+MUSIC_DRIVER_OCTAVE)                     ;#7ABE: DD 7E 05
        or      a                                              ;#7AC1: B7
        jr      z,PROCESS_SOUND_WRITE_PERIOD                   ;#7AC2: 28 04
        ld      b,a                                            ;#7AC4: 47
PROCESS_SOUND_PITCH_SHIFT_LOOP:
        ; Small loop to shift the pitch value in HL
        add     hl,hl                                          ;#7AC5: 29
        djnz    PROCESS_SOUND_PITCH_SHIFT_LOOP                 ;#7AC6: 10 FD
PROCESS_SOUND_WRITE_PERIOD:
        ; Write 12-bit period to PSG frequency registers
        ld      a,c                                            ;#7AC8: 79
        out     (PSG_ADDR),a                                   ;#7AC9: D3 A0
        ld      a,h                                            ;#7ACB: 7C
        out     (PSG_WRDATA),a                                 ;#7ACC: D3 A1
        dec     c                                              ;#7ACE: 0D
        ld      a,c                                            ;#7ACF: 79
        out     (PSG_ADDR),a                                   ;#7AD0: D3 A0
        ld      a,l                                            ;#7AD2: 7D
        out     (PSG_WRDATA),a                                 ;#7AD3: D3 A1
        inc     c                                              ;#7AD5: 0C
        ret                                                    ;#7AD6: C9
        db      0FFh                                           ;#7AD7: FF

SOUND_PITCH_OFFSET_TABLE:
        ; Table of pitch/period offsets
        ; Format: FORMAT_PITCH_TABLE
        db      06Ah ; C  (1055 Hz)                            ;#7AD8: 6A
        db      064h ; C# (1118.5 Hz)                          ;#7AD9: 64
        db      05Fh ; D  (1177.5 Hz)                          ;#7ADA: 5F
        db      059h ; D# (1257 Hz)                            ;#7ADB: 59
        db      054h ; E  (1331.5 Hz)                          ;#7ADC: 54
        db      050h ; F  (1398 Hz)                            ;#7ADD: 50
        db      04Bh ; F# (1491.5 Hz)                          ;#7ADE: 4B
        db      047h ; G  (1575.5 Hz)                          ;#7ADF: 47
        db      043h ; G# (1669.5 Hz)                          ;#7AE0: 43
        db      03Fh ; A  (1775.5 Hz)                          ;#7AE1: 3F
        db      03Ch ; A# (1864.5 Hz)                          ;#7AE2: 3C
        db      038h ; B  (1997.5 Hz)                          ;#7AE3: 38

SOUND_DURATION_TABLE:
        ; Table of note durations
        ; Format: FORMAT_DURATION_TABLE
        db      8                                              ;#7AE4: 08
        db      10h                                            ;#7AE5: 10
        db      20h                                            ;#7AE6: 20
        db      30h                                            ;#7AE7: 30
        db      40h                                            ;#7AE8: 40
        db      60h                                            ;#7AE9: 60
        db      5                                              ;#7AEA: 05
        db      0Ah                                            ;#7AEB: 0A
        db      0Fh                                            ;#7AEC: 0F
        db      14h                                            ;#7AED: 14
        db      64h                                            ;#7AEE: 64
        db      1Eh                                            ;#7AEF: 1E
        db      18h                                            ;#7AF0: 18
        db      3Ch                                            ;#7AF1: 3C
        db      50h                                            ;#7AF2: 50
        db      28h                                            ;#7AF3: 28

SOUND_TABLE:
        ; Base of sound pointer table
        dw      SOUND_DATA_TICK                                ;#7AF4: E6 7C
        dw      SOUND_DATA_JUMP                                ;#7AF6: C0 7C
        dw      SOUND_DATA_OBSTACLE                            ;#7AF8: 1E 7D
        dw      SOUND_DATA_CATCH                               ;#7AFA: 26 7D
        dw      SOUND_DATA_FALL_HOLE                           ;#7AFC: 0A 7D
        dw      SOUND_DATA_STAGE_START                         ;#7AFE: FE 7C
        dw      SOUND_DATA_STUN_DESCENDING                     ;#7B00: EC 7C
        dw      SOUND_DATA_STUMBLE                             ;#7B02: 15 7E
        dw      SOUND_DATA_DISTANCE_WARNING                    ;#7B04: CE 7C
        dw      SOUND_DATA_MAIN_THEME                          ;#7B06: 23 7B
        dw      SOUND_DATA_MAIN_THEME_CH1                      ;#7B08: A3 7B
        dw      SOUND_DATA_TIME_OUT                            ;#7B0A: C2 7D
        dw      SOUND_DATA_TIME_OUT_CH1                        ;#7B0C: DF 7D
        dw      SOUND_DATA_TIME_OUT_CH2                        ;#7B0E: 02 7E
        dw      SOUND_DATA_STAGE_CLEAR                         ;#7B10: 79 7C
        dw      SOUND_DATA_STAGE_CLEAR_CH1                     ;#7B12: 97 7C
        dw      SOUND_DATA_STAGE_CLEAR_CH2                     ;#7B14: AE 7C
        dw      SOUND_DATA_INTRO_MUSIC                         ;#7B16: 2E 7D
        dw      SOUND_DATA_INTRO_MUSIC_CH1                     ;#7B18: 60 7D
        dw      SOUND_DATA_INTRO_MUSIC_CH2                     ;#7B1A: 93 7D
        dw      SOUND_DATA_SILENCE                             ;#7B1C: 22 7B
        dw      SOUND_DATA_SILENCE                             ;#7B1E: 22 7B
        dw      SOUND_DATA_SILENCE                             ;#7B20: 22 7B

SOUND_DATA_SILENCE:
        ; Data for Sound 21-23 (Silence/Stop, Size: 1)
        db      0FFh                                           ;#7B22: FF

SOUND_DATA_MAIN_THEME:
        ; Data for Sound 10 (Main Theme CH0, Size: 128)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7B23: FD 5A
        NOTE NOTE_B, DURATION_48                               ;#7B25: 3B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7B26: FD 59
        NOTE NOTE_D, DURATION_32                               ;#7B28: 22
        NOTE NOTE_E, DURATION_16                               ;#7B29: 14
        NOTE NOTE_E, DURATION_96                               ;#7B2A: 54
        NOTE NOTE_C, DURATION_48                               ;#7B2B: 30
        NOTE NOTE_E, DURATION_32                               ;#7B2C: 24
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7B2D: 16
        NOTE NOTE_F_SHARP, DURATION_96                         ;#7B2E: 56
        NOTE NOTE_A, DURATION_48                               ;#7B2F: 39
        NOTE NOTE_G, DURATION_32                               ;#7B30: 27
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7B31: FD 5A
        NOTE NOTE_B, DURATION_16                               ;#7B33: 1B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7B34: FD 59
        NOTE NOTE_D, DURATION_48                               ;#7B36: 32
        NOTE NOTE_C, DURATION_32                               ;#7B37: 20
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7B38: FD 5A
        NOTE NOTE_B, DURATION_16                               ;#7B3A: 1B
        NOTE NOTE_B, DURATION_48                               ;#7B3B: 3B
        NOTE NOTE_A, DURATION_48                               ;#7B3C: 39
        NOTE NOTE_G, DURATION_64                               ;#7B3D: 47
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7B3E: FD 59
        NOTE NOTE_D, DURATION_8                                ;#7B40: 02
        NOTE NOTE_G, DURATION_8                                ;#7B41: 07
        NOTE NOTE_E, DURATION_8                                ;#7B42: 04
        NOTE NOTE_G, DURATION_8                                ;#7B43: 07
        NOTE NOTE_D, DURATION_8                                ;#7B44: 02
        NOTE NOTE_G, DURATION_8                                ;#7B45: 07
        NOTE NOTE_E, DURATION_8                                ;#7B46: 04
        NOTE NOTE_G, DURATION_8                                ;#7B47: 07
        NOTE NOTE_D, DURATION_8                                ;#7B48: 02
        NOTE NOTE_G, DURATION_8                                ;#7B49: 07
        NOTE NOTE_E, DURATION_8                                ;#7B4A: 04
        NOTE NOTE_G, DURATION_8                                ;#7B4B: 07
        NOTE NOTE_D, DURATION_8                                ;#7B4C: 02
        NOTE NOTE_G, DURATION_8                                ;#7B4D: 07
        NOTE NOTE_E, DURATION_8                                ;#7B4E: 04
        NOTE NOTE_G, DURATION_8                                ;#7B4F: 07
        NOTE NOTE_D, DURATION_16                               ;#7B50: 12
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B51: 06
        NOTE NOTE_HOLD, DURATION_8                             ;#7B52: 0C
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B53: 06
        NOTE NOTE_HOLD, DURATION_8                             ;#7B54: 0C
        NOTE NOTE_D, DURATION_16                               ;#7B55: 12
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B56: 06
        NOTE NOTE_HOLD, DURATION_8                             ;#7B57: 0C
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B58: 06
        NOTE NOTE_HOLD, DURATION_8                             ;#7B59: 0C
        NOTE NOTE_D, DURATION_8                                ;#7B5A: 02
        NOTE NOTE_A, DURATION_8                                ;#7B5B: 09
        NOTE NOTE_E, DURATION_8                                ;#7B5C: 04
        NOTE NOTE_A, DURATION_8                                ;#7B5D: 09
        NOTE NOTE_D, DURATION_8                                ;#7B5E: 02
        NOTE NOTE_A, DURATION_8                                ;#7B5F: 09
        NOTE NOTE_E, DURATION_8                                ;#7B60: 04
        NOTE NOTE_A, DURATION_8                                ;#7B61: 09
        NOTE NOTE_D, DURATION_8                                ;#7B62: 02
        NOTE NOTE_A, DURATION_8                                ;#7B63: 09
        NOTE NOTE_E, DURATION_8                                ;#7B64: 04
        NOTE NOTE_A, DURATION_8                                ;#7B65: 09
        NOTE NOTE_D, DURATION_16                               ;#7B66: 12
        NOTE NOTE_G, DURATION_8                                ;#7B67: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7B68: 0C
        NOTE NOTE_G, DURATION_8                                ;#7B69: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7B6A: 0C
        NOTE NOTE_D, DURATION_16                               ;#7B6B: 12
        NOTE NOTE_G, DURATION_8                                ;#7B6C: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7B6D: 0C
        NOTE NOTE_G, DURATION_8                                ;#7B6E: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7B6F: 0C
        NOTE NOTE_D, DURATION_8                                ;#7B70: 02
        NOTE NOTE_G, DURATION_8                                ;#7B71: 07
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B72: 06
        NOTE NOTE_G, DURATION_8                                ;#7B73: 07
        NOTE NOTE_D, DURATION_8                                ;#7B74: 02
        NOTE NOTE_G, DURATION_8                                ;#7B75: 07
        NOTE NOTE_D, DURATION_8                                ;#7B76: 02
        NOTE NOTE_G, DURATION_8                                ;#7B77: 07
        NOTE NOTE_F, DURATION_8                                ;#7B78: 05
        NOTE NOTE_G, DURATION_8                                ;#7B79: 07
        NOTE NOTE_D, DURATION_8                                ;#7B7A: 02
        NOTE NOTE_G, DURATION_8                                ;#7B7B: 07
        NOTE NOTE_C, DURATION_8                                ;#7B7C: 00
        NOTE NOTE_G, DURATION_8                                ;#7B7D: 07
        NOTE NOTE_E, DURATION_8                                ;#7B7E: 04
        NOTE NOTE_G, DURATION_8                                ;#7B7F: 07
        NOTE NOTE_C, DURATION_8                                ;#7B80: 00
        NOTE NOTE_G, DURATION_8                                ;#7B81: 07
        NOTE NOTE_C, DURATION_8                                ;#7B82: 00
        NOTE NOTE_G, DURATION_8                                ;#7B83: 07
        NOTE NOTE_D_SHARP, DURATION_8                          ;#7B84: 03
        NOTE NOTE_G, DURATION_8                                ;#7B85: 07
        NOTE NOTE_C, DURATION_8                                ;#7B86: 00
        NOTE NOTE_G, DURATION_8                                ;#7B87: 07
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7B88: FD 5A
        NOTE NOTE_B, DURATION_8                                ;#7B8A: 0B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7B8B: FD 59
        NOTE NOTE_G, DURATION_8                                ;#7B8D: 07
        NOTE NOTE_D, DURATION_8                                ;#7B8E: 02
        NOTE NOTE_G, DURATION_8                                ;#7B8F: 07
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7B90: FD 5A
        NOTE NOTE_B, DURATION_8                                ;#7B92: 0B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7B93: FD 59
        NOTE NOTE_G, DURATION_8                                ;#7B95: 07
        NOTE NOTE_C, DURATION_8                                ;#7B96: 00
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B97: 06
        NOTE NOTE_D, DURATION_8                                ;#7B98: 02
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B99: 06
        NOTE NOTE_C, DURATION_8                                ;#7B9A: 00
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B9B: 06
        NOTE NOTE_G, DURATION_16                               ;#7B9C: 17
        NOTE NOTE_HOLD, DURATION_16                            ;#7B9D: 1C
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7B9E: 16
        NOTE NOTE_G, DURATION_16                               ;#7B9F: 17
        NOTE NOTE_HOLD, DURATION_32                            ;#7BA0: 2C
        db      0FEh, 0FFh ; Repeat (FF=forever)               ;#7BA1: FE FF

SOUND_DATA_MAIN_THEME_CH1:
        ; Data for Sound 11 (Main Theme CH1, Size: 214)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BA3: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BA5: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BA6: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BA8: 12
        NOTE NOTE_D, DURATION_16                               ;#7BA9: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BAA: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BAC: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BAD: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BAF: 12
        NOTE NOTE_D, DURATION_16                               ;#7BB0: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BB1: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BB3: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BB4: FD 5A
        NOTE NOTE_C, DURATION_16                               ;#7BB6: 10
        NOTE NOTE_C, DURATION_16                               ;#7BB7: 10
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BB8: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BBA: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BBB: FD 5A
        NOTE NOTE_C, DURATION_16                               ;#7BBD: 10
        NOTE NOTE_C, DURATION_16                               ;#7BBE: 10
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BBF: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BC1: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BC2: FD 5A
        NOTE NOTE_E, DURATION_16                               ;#7BC4: 14
        NOTE NOTE_E, DURATION_16                               ;#7BC5: 14
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BC6: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BC8: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BC9: FD 5A
        NOTE NOTE_E, DURATION_16                               ;#7BCB: 14
        NOTE NOTE_E, DURATION_16                               ;#7BCC: 14
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BCD: FD 5B
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7BCF: 16
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BD0: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BD2: 12
        NOTE NOTE_D, DURATION_16                               ;#7BD3: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BD4: FD 5B
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7BD6: 16
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BD7: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BD9: 12
        NOTE NOTE_D, DURATION_16                               ;#7BDA: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BDB: FD 5B
        NOTE NOTE_C, DURATION_16                               ;#7BDD: 10
        NOTE NOTE_A, DURATION_16                               ;#7BDE: 19
        NOTE NOTE_A, DURATION_16                               ;#7BDF: 19
        NOTE NOTE_G, DURATION_16                               ;#7BE0: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BE1: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BE3: 12
        NOTE NOTE_D, DURATION_16                               ;#7BE4: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BE5: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BE7: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BE8: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BEA: 12
        NOTE NOTE_D, DURATION_16                               ;#7BEB: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BEC: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7BEE: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BEF: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BF1: 12
        NOTE NOTE_D, DURATION_16                               ;#7BF2: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BF3: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BF5: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BF6: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BF8: 12
        NOTE NOTE_D, DURATION_16                               ;#7BF9: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BFA: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7BFC: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BFD: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BFF: 12
        NOTE NOTE_D, DURATION_16                               ;#7C00: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C01: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C03: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C04: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C06: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C07: FD 5B
        NOTE NOTE_B, DURATION_16                               ;#7C09: 1B
        NOTE NOTE_G, DURATION_32                               ;#7C0A: 27
        NOTE NOTE_HOLD, DURATION_16                            ;#7C0B: 1C
        NOTE NOTE_B, DURATION_16                               ;#7C0C: 1B
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C0D: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C0F: 12
        NOTE NOTE_D, DURATION_16                               ;#7C10: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C11: FD 5B
        NOTE NOTE_B, DURATION_16                               ;#7C13: 1B
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C14: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C16: 12
        NOTE NOTE_D, DURATION_16                               ;#7C17: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C18: FD 5B
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7C1A: 16
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C1B: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C1D: 12
        NOTE NOTE_D, DURATION_16                               ;#7C1E: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C1F: FD 5B
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7C21: 16
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C22: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C24: 12
        NOTE NOTE_D, DURATION_16                               ;#7C25: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C26: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7C28: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C29: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C2B: 12
        NOTE NOTE_D, DURATION_16                               ;#7C2C: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C2D: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7C2F: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C30: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C32: 12
        NOTE NOTE_D, DURATION_16                               ;#7C33: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C34: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C36: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C37: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C39: 12
        NOTE NOTE_D, DURATION_16                               ;#7C3A: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C3B: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C3D: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C3E: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C40: 12
        NOTE NOTE_D, DURATION_16                               ;#7C41: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C42: FD 5B
        NOTE NOTE_D, DURATION_16                               ;#7C44: 12
        NOTE NOTE_G, DURATION_16                               ;#7C45: 17
        NOTE NOTE_B, DURATION_16                               ;#7C46: 1B
        NOTE NOTE_G, DURATION_16                               ;#7C47: 17
        NOTE NOTE_B, DURATION_16                               ;#7C48: 1B
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C49: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C4B: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C4C: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C4E: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C4F: FD 5A
        NOTE NOTE_C, DURATION_16                               ;#7C51: 10
        NOTE NOTE_E, DURATION_16                               ;#7C52: 14
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C53: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C55: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C56: FD 5A
        NOTE NOTE_C, DURATION_16                               ;#7C58: 10
        NOTE NOTE_E, DURATION_16                               ;#7C59: 14
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C5A: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C5C: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C5D: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C5F: 12
        NOTE NOTE_HOLD, DURATION_16                            ;#7C60: 1C
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C61: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7C63: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C64: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C66: 12
        NOTE NOTE_HOLD, DURATION_16                            ;#7C67: 1C
        NOTE NOTE_D, DURATION_16                               ;#7C68: 12
        NOTE NOTE_HOLD, DURATION_16                            ;#7C69: 1C
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C6A: FD 5B
        NOTE NOTE_B, DURATION_16                               ;#7C6C: 1B
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C6D: FD 5A
        NOTE NOTE_D, DURATION_8                                ;#7C6F: 02
        NOTE NOTE_C, DURATION_8                                ;#7C70: 00
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C71: FD 5B
        NOTE NOTE_B, DURATION_8                                ;#7C73: 0B
        NOTE NOTE_A, DURATION_8                                ;#7C74: 09
        NOTE NOTE_G, DURATION_8                                ;#7C75: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7C76: 0C
        db      0FEh, 0FFh ; Repeat (FF=forever)               ;#7C77: FE FF

SOUND_DATA_STAGE_CLEAR:
        ; Data for Sound 15 (Stage Clear CH0, Size: 29)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7C79: FD 59
        NOTE NOTE_C, DURATION_20                               ;#7C7B: 90
        NOTE NOTE_C, DURATION_15                               ;#7C7C: 80
        NOTE NOTE_C, DURATION_5                                ;#7C7D: 60
        NOTE NOTE_C, DURATION_20                               ;#7C7E: 90
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C7F: FD 5A
        NOTE NOTE_B, DURATION_15                               ;#7C81: 8B
        NOTE NOTE_A, DURATION_5                                ;#7C82: 69
        NOTE NOTE_G, DURATION_20                               ;#7C83: 97
        NOTE NOTE_E, DURATION_20                               ;#7C84: 94
        NOTE NOTE_G, DURATION_20                               ;#7C85: 97
        NOTE NOTE_E, DURATION_20                               ;#7C86: 94
        NOTE NOTE_D, DURATION_10                               ;#7C87: 72
        NOTE NOTE_E, DURATION_10                               ;#7C88: 74
        NOTE NOTE_F, DURATION_10                               ;#7C89: 75
        NOTE NOTE_G, DURATION_10                               ;#7C8A: 77
        NOTE NOTE_A, DURATION_10                               ;#7C8B: 79
        NOTE NOTE_G, DURATION_10                               ;#7C8C: 77
        NOTE NOTE_A, DURATION_10                               ;#7C8D: 79
        NOTE NOTE_B, DURATION_10                               ;#7C8E: 7B
        SET_OCTAVE_SUSTAIN 1, 0Ch                              ;#7C8F: FD 61
        NOTE NOTE_C, DURATION_20                               ;#7C91: 90
        NOTE NOTE_C, DURATION_15                               ;#7C92: 80
        NOTE NOTE_C, DURATION_5                                ;#7C93: 60
        NOTE NOTE_C, DURATION_20                               ;#7C94: 90
        db      0FFh                                           ;#7C95: FF
        db      0FFh                                           ;#7C96: FF

SOUND_DATA_STAGE_CLEAR_CH1:
        ; Data for Sound 16 (Stage Clear CH1, Size: 22)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C97: FD 5B
        NOTE NOTE_G, DURATION_20                               ;#7C99: 97
        NOTE NOTE_G, DURATION_20                               ;#7C9A: 97
        NOTE NOTE_G, DURATION_20                               ;#7C9B: 97
        NOTE NOTE_HOLD, DURATION_20                            ;#7C9C: 9C
        NOTE NOTE_G, DURATION_20                               ;#7C9D: 97
        NOTE NOTE_G, DURATION_20                               ;#7C9E: 97
        NOTE NOTE_G, DURATION_20                               ;#7C9F: 97
        NOTE NOTE_HOLD, DURATION_20                            ;#7CA0: 9C
        NOTE NOTE_F, DURATION_20                               ;#7CA1: 95
        NOTE NOTE_D, DURATION_20                               ;#7CA2: 92
        NOTE NOTE_G, DURATION_20                               ;#7CA3: 97
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7CA4: FD 5C
        NOTE NOTE_G, DURATION_20                               ;#7CA6: 97
        SET_OCTAVE_SUSTAIN 3, 0Ch                              ;#7CA7: FD 63
        NOTE NOTE_C, DURATION_20                               ;#7CA9: 90
        NOTE NOTE_G, DURATION_20                               ;#7CAA: 97
        NOTE NOTE_G, DURATION_20                               ;#7CAB: 97
        db      0FFh                                           ;#7CAC: FF
        db      0FFh                                           ;#7CAD: FF

SOUND_DATA_STAGE_CLEAR_CH2:
        ; Data for Sound 17 (Stage Clear CH2, Size: 17)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7CAE: FD 5B
        NOTE NOTE_C, DURATION_20                               ;#7CB0: 90
        NOTE NOTE_C, DURATION_20                               ;#7CB1: 90
        NOTE NOTE_C, DURATION_20                               ;#7CB2: 90
        NOTE NOTE_HOLD, DURATION_20                            ;#7CB3: 9C
        NOTE NOTE_C, DURATION_20                               ;#7CB4: 90
        NOTE NOTE_C, DURATION_20                               ;#7CB5: 90
        NOTE NOTE_C, DURATION_20                               ;#7CB6: 90
        NOTE NOTE_HOLD, DURATION_20                            ;#7CB7: 9C
        NOTE NOTE_HOLD, DURATION_100                           ;#7CB8: AC
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7CB9: FD 5A
        NOTE NOTE_E, DURATION_15                               ;#7CBB: 84
        NOTE NOTE_E, DURATION_5                                ;#7CBC: 64
        NOTE NOTE_E, DURATION_20                               ;#7CBD: 94
        db      0FFh                                           ;#7CBE: FF
        db      0FFh                                           ;#7CBF: FF

SOUND_DATA_JUMP:
        ; Data for Sound 2 (Jump, Size: 14)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 2                                         ;#7CC0: 22
        SOUND 0Dh, 7Fh                                         ;#7CC1: D0 7F
        SOUND 0Bh, 70h                                         ;#7CC3: B0 70
        SOUND 0Bh, 77h                                         ;#7CC5: B0 77
        SOUND 0Ah, 62h                                         ;#7CC7: A0 62
        SOUND 9, 50h                                           ;#7CC9: 90 50
        SOUND 8, 43h                                           ;#7CCB: 80 43
        db      0FFh                                           ;#7CCD: FF

SOUND_DATA_DISTANCE_WARNING:
        ; Data for Sound 9 (Distance < 1000m), Size: 24)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 3                                         ;#7CCE: 23
        SOUND 9, 60h                                           ;#7CCF: 90 60
        SOUND 9, 40h                                           ;#7CD1: 90 40
        SOUND 9, 60h                                           ;#7CD3: 90 60
        SOUND 9, 40h                                           ;#7CD5: 90 40
        SOUND 9, 60h                                           ;#7CD7: 90 60
        SOUND 9, 40h                                           ;#7CD9: 90 40
        SOUND 9, 60h                                           ;#7CDB: 90 60
        SOUND 9, 40h                                           ;#7CDD: 90 40
        SOUND 9, 60h                                           ;#7CDF: 90 60
        SOUND 9, 40h                                           ;#7CE1: 90 40
        SOUND 9, 60h                                           ;#7CE3: 90 60
        db      0FFh                                           ;#7CE5: FF

SOUND_DATA_TICK:
        ; Data for Sound 1 (Goal Tally Tick, Size: 6)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 1                                         ;#7CE6: 21
        SOUND 0Ah, 25h                                         ;#7CE7: A0 25
        SOUND 0Ah, 27h                                         ;#7CE9: A0 27
        db      0FFh                                           ;#7CEB: FF

SOUND_DATA_STUN_DESCENDING:
        ; Data for Sound 7 (Descending Scale, Size: 18)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 1                                         ;#7CEC: 21
        SOUND 0Ch, 0DDh                                        ;#7CED: C0 DD
        SOUND 0Ch, 0BBh                                        ;#7CEF: C0 BB
        SOUND 0Bh, 0AAh                                        ;#7CF1: B0 AA
        SOUND 0Bh, 99h                                         ;#7CF3: B0 99
        SOUND 0Ah, 88h                                         ;#7CF5: A0 88
        SOUND 0Ah, 77h                                         ;#7CF7: A0 77
        SOUND 9, 66h                                           ;#7CF9: 90 66
        SOUND 9, 55h                                           ;#7CFB: 90 55
        db      0FFh                                           ;#7CFD: FF

SOUND_DATA_STAGE_START:
        ; Data for Sound 6 (Stage Start Jingle, Size: 12)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 2                                         ;#7CFE: 22
        SOUND 0Ch, 55h                                         ;#7CFF: C0 55
        SOUND 0Ch, 66h                                         ;#7D01: C0 66
        SOUND 0Ch, 55h                                         ;#7D03: C0 55
        SOUND 0Bh, 44h                                         ;#7D05: B0 44
        SOUND 0Ah, 33h                                         ;#7D07: A0 33
        db      0FFh                                           ;#7D09: FF

SOUND_DATA_FALL_HOLE:
        ; Data for Sound 5 (Fall in Hole, Size: 20)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 2                                         ;#7D0A: 22
        SOUND 0Eh, 0A5h                                        ;#7D0B: E0 A5
        SOUND 0Ch, 0B5h                                        ;#7D0D: C0 B5
        SOUND 0Ah, 0C5h                                        ;#7D0F: A0 C5
        SOUND 9, 0D5h                                          ;#7D11: 90 D5
        SOUND 8, 0E5h                                          ;#7D13: 80 E5
        SOUND 7, 0F5h                                          ;#7D15: 70 F5
        SOUND 6, 105h                                          ;#7D17: 61 05
        SOUND 5, 125h                                          ;#7D19: 51 25
        SOUND 5, 145h                                          ;#7D1B: 51 45
        db      0FFh                                           ;#7D1D: FF

SOUND_DATA_OBSTACLE:
        ; Data for Sound 3 (Hit Obstacle, Size: 8)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 1                                         ;#7D1E: 21
        SOUND 0Ch, 103h                                        ;#7D1F: C1 03
        SOUND 0Ch, 10Dh                                        ;#7D21: C1 0D
        SOUND 0Ch, 106h                                        ;#7D23: C1 06
        db      0FFh                                           ;#7D25: FF

SOUND_DATA_CATCH:
        ; Data for Sound 4 (Catch Fish/Flag, Size: 8)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 1                                         ;#7D26: 21
        SOUND 0Ch, 143h                                        ;#7D27: C1 43
        SOUND 0Ch, 14Dh                                        ;#7D29: C1 4D
        SOUND 0Ch, 146h                                        ;#7D2B: C1 46
        db      0FFh                                           ;#7D2D: FF

SOUND_DATA_INTRO_MUSIC:
        ; Data for Sound 18 (Demo BGM CH0, Size: 50)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D2E: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7D30: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D31: FD 59
        NOTE NOTE_D, DURATION_10                               ;#7D33: 72
        NOTE NOTE_E, DURATION_10                               ;#7D34: 74
        NOTE NOTE_D, DURATION_10                               ;#7D35: 72
        NOTE NOTE_G, DURATION_20                               ;#7D36: 97
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7D37: 76
        NOTE NOTE_E, DURATION_10                               ;#7D38: 74
        NOTE NOTE_D, DURATION_30                               ;#7D39: B2
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D3A: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7D3C: 7B
        NOTE NOTE_G, DURATION_20                               ;#7D3D: 97
        NOTE NOTE_G, DURATION_5                                ;#7D3E: 67
        NOTE NOTE_A, DURATION_5                                ;#7D3F: 69
        NOTE NOTE_B, DURATION_5                                ;#7D40: 6B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D41: FD 59
        NOTE NOTE_C, DURATION_5                                ;#7D43: 60
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D44: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7D46: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D47: FD 59
        NOTE NOTE_D, DURATION_10                               ;#7D49: 72
        NOTE NOTE_E, DURATION_10                               ;#7D4A: 74
        NOTE NOTE_D, DURATION_10                               ;#7D4B: 72
        NOTE NOTE_G, DURATION_20                               ;#7D4C: 97
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7D4D: 76
        NOTE NOTE_E, DURATION_10                               ;#7D4E: 74
        NOTE NOTE_D, DURATION_5                                ;#7D4F: 62
        NOTE NOTE_E, DURATION_5                                ;#7D50: 64
        NOTE NOTE_D, DURATION_5                                ;#7D51: 62
        NOTE NOTE_C, DURATION_5                                ;#7D52: 60
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D53: FD 5A
        NOTE NOTE_B, DURATION_5                                ;#7D55: 6B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D56: FD 59
        NOTE NOTE_C, DURATION_5                                ;#7D58: 60
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D59: FD 5A
        NOTE NOTE_B, DURATION_5                                ;#7D5B: 6B
        NOTE NOTE_A, DURATION_5                                ;#7D5C: 69
        NOTE NOTE_G, DURATION_20                               ;#7D5D: 97
        NOTE NOTE_HOLD, DURATION_20                            ;#7D5E: 9C
        db      0FFh                                           ;#7D5F: FF

SOUND_DATA_INTRO_MUSIC_CH1:
        ; Data for Sound 19 (Demo BGM CH1, Size: 51)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D60: FD 5A
        NOTE NOTE_G, DURATION_10                               ;#7D62: 77
        NOTE NOTE_B, DURATION_10                               ;#7D63: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D64: FD 59
        NOTE NOTE_C, DURATION_10                               ;#7D66: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D67: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7D69: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D6A: FD 59
        NOTE NOTE_D, DURATION_20                               ;#7D6C: 92
        NOTE NOTE_C, DURATION_10                               ;#7D6D: 70
        NOTE NOTE_C, DURATION_10                               ;#7D6E: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D6F: FD 5A
        NOTE NOTE_B, DURATION_30                               ;#7D71: BB
        NOTE NOTE_G, DURATION_10                               ;#7D72: 77
        NOTE NOTE_D, DURATION_20                               ;#7D73: 92
        NOTE NOTE_HOLD, DURATION_20                            ;#7D74: 9C
        NOTE NOTE_G, DURATION_10                               ;#7D75: 77
        NOTE NOTE_B, DURATION_10                               ;#7D76: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D77: FD 59
        NOTE NOTE_C, DURATION_10                               ;#7D79: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D7A: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7D7C: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D7D: FD 59
        NOTE NOTE_D, DURATION_20                               ;#7D7F: 92
        NOTE NOTE_C, DURATION_10                               ;#7D80: 70
        NOTE NOTE_C, DURATION_10                               ;#7D81: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D82: FD 5A
        NOTE NOTE_B, DURATION_5                                ;#7D84: 6B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D85: FD 59
        NOTE NOTE_C, DURATION_5                                ;#7D87: 60
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D88: FD 5A
        NOTE NOTE_B, DURATION_5                                ;#7D8A: 6B
        NOTE NOTE_A, DURATION_5                                ;#7D8B: 69
        NOTE NOTE_G, DURATION_5                                ;#7D8C: 67
        NOTE NOTE_A, DURATION_5                                ;#7D8D: 69
        NOTE NOTE_G, DURATION_5                                ;#7D8E: 67
        NOTE NOTE_F_SHARP, DURATION_5                          ;#7D8F: 66
        NOTE NOTE_D, DURATION_20                               ;#7D90: 92
        NOTE NOTE_HOLD, DURATION_20                            ;#7D91: 9C
        db      0FFh                                           ;#7D92: FF

SOUND_DATA_INTRO_MUSIC_CH2:
        ; Data for Sound 20 (Demo BGM CH2, Size: 47)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7D93: FD 5B
        NOTE NOTE_G, DURATION_10                               ;#7D95: 77
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7D96: 76
        NOTE NOTE_E, DURATION_10                               ;#7D97: 74
        NOTE NOTE_D, DURATION_10                               ;#7D98: 72
        NOTE NOTE_C, DURATION_10                               ;#7D99: 70
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7D9A: FD 5C
        NOTE NOTE_B, DURATION_10                               ;#7D9C: 7B
        NOTE NOTE_A, DURATION_10                               ;#7D9D: 79
        NOTE NOTE_G, DURATION_10                               ;#7D9E: 77
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7D9F: FD 5B
        NOTE NOTE_G, DURATION_10                               ;#7DA1: 77
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7DA2: 76
        NOTE NOTE_E, DURATION_10                               ;#7DA3: 74
        NOTE NOTE_D, DURATION_10                               ;#7DA4: 72
        NOTE NOTE_C, DURATION_10                               ;#7DA5: 70
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7DA6: FD 5C
        NOTE NOTE_B, DURATION_10                               ;#7DA8: 7B
        NOTE NOTE_A, DURATION_10                               ;#7DA9: 79
        NOTE NOTE_G, DURATION_10                               ;#7DAA: 77
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7DAB: FD 5B
        NOTE NOTE_G, DURATION_10                               ;#7DAD: 77
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7DAE: 76
        NOTE NOTE_E, DURATION_10                               ;#7DAF: 74
        NOTE NOTE_D, DURATION_10                               ;#7DB0: 72
        NOTE NOTE_C, DURATION_10                               ;#7DB1: 70
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7DB2: FD 5C
        NOTE NOTE_B, DURATION_10                               ;#7DB4: 7B
        NOTE NOTE_A, DURATION_10                               ;#7DB5: 79
        NOTE NOTE_G, DURATION_10                               ;#7DB6: 77
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7DB7: FD 5B
        NOTE NOTE_D, DURATION_10                               ;#7DB9: 72
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7DBA: FD 5C
        NOTE NOTE_D, DURATION_10                               ;#7DBC: 72
        NOTE NOTE_E, DURATION_10                               ;#7DBD: 74
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7DBE: 76
        NOTE NOTE_G, DURATION_10                               ;#7DBF: 77
        NOTE NOTE_HOLD, DURATION_20                            ;#7DC0: 9C
        db      0FFh                                           ;#7DC1: FF

SOUND_DATA_TIME_OUT:
        ; Data for Sound 12 (Time Out CH0, Size: 29)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DC2: FD 59
        NOTE NOTE_E, DURATION_20                               ;#7DC4: 94
        NOTE NOTE_E, DURATION_10                               ;#7DC5: 74
        NOTE NOTE_E, DURATION_10                               ;#7DC6: 74
        NOTE NOTE_E, DURATION_20                               ;#7DC7: 94
        NOTE NOTE_D, DURATION_10                               ;#7DC8: 72
        NOTE NOTE_C, DURATION_10                               ;#7DC9: 70
        NOTE NOTE_F, DURATION_30                               ;#7DCA: B5
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DCB: FD 5A
        NOTE NOTE_F, DURATION_10                               ;#7DCD: 75
        NOTE NOTE_F, DURATION_30                               ;#7DCE: B5
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DCF: FD 59
        NOTE NOTE_F, DURATION_10                               ;#7DD1: 75
        NOTE NOTE_E, DURATION_20                               ;#7DD2: 94
        NOTE NOTE_C, DURATION_10                               ;#7DD3: 70
        NOTE NOTE_E, DURATION_10                               ;#7DD4: 74
        NOTE NOTE_D, DURATION_20                               ;#7DD5: 92
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DD6: FD 5A
        NOTE NOTE_A, DURATION_10                               ;#7DD8: 79
        NOTE NOTE_B, DURATION_10                               ;#7DD9: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DDA: FD 59
        NOTE NOTE_C, DURATION_60                               ;#7DDC: D0
        NOTE NOTE_HOLD, DURATION_16                            ;#7DDD: 1C
        db      0FFh                                           ;#7DDE: FF

SOUND_DATA_TIME_OUT_CH1:
        ; Data for Sound 13 (Time Out CH1, Size: 35)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7DDF: FD 5B
        NOTE NOTE_C, DURATION_20                               ;#7DE1: 90
        NOTE NOTE_C, DURATION_10                               ;#7DE2: 70
        NOTE NOTE_C, DURATION_10                               ;#7DE3: 70
        NOTE NOTE_C, DURATION_20                               ;#7DE4: 90
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DE5: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7DE7: 7B
        NOTE NOTE_G, DURATION_10                               ;#7DE8: 77
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DE9: FD 59
        NOTE NOTE_C, DURATION_30                               ;#7DEB: B0
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DEC: FD 5A
        NOTE NOTE_C, DURATION_10                               ;#7DEE: 70
        NOTE NOTE_C, DURATION_30                               ;#7DEF: B0
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DF0: FD 59
        NOTE NOTE_C, DURATION_10                               ;#7DF2: 70
        NOTE NOTE_C, DURATION_20                               ;#7DF3: 90
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DF4: FD 5A
        NOTE NOTE_G, DURATION_10                               ;#7DF6: 77
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DF7: FD 59
        NOTE NOTE_C, DURATION_10                               ;#7DF9: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DFA: FD 5A
        NOTE NOTE_B, DURATION_20                               ;#7DFC: 9B
        NOTE NOTE_F, DURATION_10                               ;#7DFD: 75
        NOTE NOTE_G, DURATION_10                               ;#7DFE: 77
        NOTE NOTE_G, DURATION_60                               ;#7DFF: D7
        NOTE NOTE_HOLD, DURATION_16                            ;#7E00: 1C
        db      0FFh                                           ;#7E01: FF

SOUND_DATA_TIME_OUT_CH2:
        ; Data for Sound 14 (Time Out CH2, Size: 19)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7E02: FD 5B
        NOTE NOTE_G, DURATION_20                               ;#7E04: 97
        NOTE NOTE_E, DURATION_20                               ;#7E05: 94
        NOTE NOTE_G, DURATION_20                               ;#7E06: 97
        NOTE NOTE_E, DURATION_20                               ;#7E07: 94
        NOTE NOTE_A, DURATION_20                               ;#7E08: 99
        NOTE NOTE_F, DURATION_20                               ;#7E09: 95
        NOTE NOTE_A, DURATION_20                               ;#7E0A: 99
        NOTE NOTE_F, DURATION_20                               ;#7E0B: 95
        NOTE NOTE_G, DURATION_20                               ;#7E0C: 97
        NOTE NOTE_E, DURATION_20                               ;#7E0D: 94
        NOTE NOTE_G, DURATION_20                               ;#7E0E: 97
        NOTE NOTE_F, DURATION_20                               ;#7E0F: 95
        NOTE NOTE_G, DURATION_20                               ;#7E10: 97
        NOTE NOTE_G, DURATION_20                               ;#7E11: 97
        NOTE NOTE_G, DURATION_20                               ;#7E12: 97
        NOTE NOTE_HOLD, DURATION_20                            ;#7E13: 9C
        db      0FFh                                           ;#7E14: FF

SOUND_DATA_STUMBLE:
        ; Data for Sound 8 (Stumble/Seal Bump, Size: 24)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 2                                         ;#7E15: 22
        SOUND 0Dh, 1EEh                                        ;#7E16: D1 EE
        SOUND 0Dh, 1CCh                                        ;#7E18: D1 CC
        SOUND 0Ch, 1EEh                                        ;#7E1A: C1 EE
        SOUND 0Bh, 1FFh                                        ;#7E1C: B1 FF
        SOUND 0Ah, 199h                                        ;#7E1E: A1 99
        SOUND 9, 188h                                          ;#7E20: 91 88
        SOUND 8, 177h                                          ;#7E22: 81 77
        SOUND 7, 166h                                          ;#7E24: 71 66
        SOUND 6, 177h                                          ;#7E26: 61 77
        SOUND 5, 188h                                          ;#7E28: 51 88
        SOUND 4, 199h                                          ;#7E2A: 41 99
        db      0FFh                                           ;#7E2C: FF

DEBUG_VRAM_DUMP_AND_HANG:
        ; Developer relict: Dumps 2KB VRAM to RAM E000h and freezes
        ld      hl,GAME_STATE                                  ;#7E2D: 21 00 E0
        ld      bc,800h                                        ;#7E30: 01 00 08
        di                                                     ;#7E33: F3
        call    SET_VDP                                        ;#7E34: CD C9 48
DEBUG_VRAM_READ_LOOP:
        ; VRAM read loop for debug dump
        in      a,(VDP_98)                                     ;#7E37: DB 98
        ld      (hl),a                                         ;#7E39: 77
        inc     hl                                             ;#7E3A: 23
        dec     bc                                             ;#7E3B: 0B
        ld      a,b                                            ;#7E3C: 78
        or      c                                              ;#7E3D: B1
        jr      nz,DEBUG_VRAM_READ_LOOP                        ;#7E3E: 20 F7
        ei                                                     ;#7E40: FB
FREEZE_LOOP:
        ; Infinite loop for debug freeze
        jr      FREEZE_LOOP                                    ;#7E41: 18 FE

PADDING:
        ; ROM padding to 16KB boundary
        defs    8000h - $, 0FFh                                ;#7E43
