; Antarctic Adventure (MSX, Konami, 1984, second release)
; Disassembled by Ricardo Bittencourt (bluepenguin@gmail.com)
; Last update at 2026-04-27
;
	output "antarctic_2.rom"
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
BIOS_VDP_98                      equ     00006h    ; MSX BIOS work area: VDP write port (0x98) byte
BIOS_VDP_99                      equ     00007h    ; MSX BIOS work area: VDP read port (0x99) byte
BIOS_WRTVDP                      equ     00047h    ; MSX BIOS: write byte B to VDP register C
BIOS_SETRD                       equ     00050h    ; MSX BIOS: set VDP for read at HL
BIOS_SETWRT                      equ     00053h    ; MSX BIOS: set VDP for write at HL
BIOS_WRTPSG                      equ     00093h    ; MSX BIOS: write E to PSG register A
BIOS_RDPSG                       equ     00096h    ; MSX BIOS: read PSG register A into A
BIOS_RDVDP                       equ     0013Eh    ; MSX BIOS: read VDP status register into A
BIOS_SNSMAT                      equ     00141h    ; MSX BIOS: read keyboard matrix row A into A
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

; Macro to emit an inline Name Table coordinate word (prefix for centered text entries)
; Usage: TXT_NAME_TABLE 22, 13
        macro TXT_NAME_TABLE y, x
                dw      3800h + y * 32 + x
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
        ld      hl,INTERRUPT_HANDLER                           ;#4018: 21 45 40
        ld      (HKEYI+1),hl                                   ;#401B: 22 9B FD
        ld      sp,STACK                                       ;#401E: 31 00 E4
        ld      hl,GAME_STATE                                  ;#4021: 21 00 E0
        ld      de,GAME_STATE+1                                ;#4024: 11 01 E0
        ld      bc,7FFh                                        ;#4027: 01 FF 07
        ld      (hl),0                                         ;#402A: 36 00
        ldir                                                   ;#402C: ED B0
        ld      a,1                                            ;#402E: 3E 01
        ld      (VBLANK_BUSY_FLAG),a                           ;#4030: 32 05 E0
        call    INIT_HARDWARE                                  ;#4033: CD 7A 44
        di                                                     ;#4036: F3
        xor     a                                              ;#4037: AF
        ld      (VBLANK_BUSY_FLAG),a                           ;#4038: 32 05 E0
        inc     a                                              ;#403B: 3C
        ld      (GAME_STATE),a                                 ;#403C: 32 00 E0
        call    BIOS_RDVDP                                     ;#403F: CD 3E 01
        ei                                                     ;#4042: FB
WAIT_FOR_INTERRUPT:
        ; Idle loop waiting for interrupt
        jr      WAIT_FOR_INTERRUPT                             ;#4043: 18 FE

INTERRUPT_HANDLER:
        ; Core interupt and timing handler
        push    af                                             ;#4045: F5
        push    bc                                             ;#4046: C5
        push    de                                             ;#4047: D5
        push    hl                                             ;#4048: E5
        di                                                     ;#4049: F3
        call    BIOS_RDVDP                                     ;#404A: CD 3E 01
        ld      a,(GAME_STATE)                                 ;#404D: 3A 00 E0
        or      a                                              ;#4050: B7
        jr      z,MAIN_LOOP_ENTRY                              ;#4051: 28 03
        call    PROCESS_SOUND                                  ;#4053: CD EA 79
MAIN_LOOP_ENTRY:
        ; Main loop wait/dispatch entry
        ld      a,(GAME_STATE)                                 ;#4056: 3A 00 E0
        cp      ID_STATE_12                                    ;#4059: FE 0C
        jr      nc,SET_VBLANK_BUSY                             ;#405B: 30 1C
        ld      a,(PENGUIN_FALL_TIMER)                         ;#405D: 3A 40 E1
        ld      hl,PENGUIN_STUN_TIMER                          ;#4060: 21 42 E1
        add     a,(hl)                                         ;#4063: 86
        jr      nz,CHECK_TIMER_UPDATE                          ;#4064: 20 03
        call    UPDATE_PENGUIN_ANIMATION                       ;#4066: CD 98 4C
CHECK_TIMER_UPDATE:
        ; Checks if half-second timer needs updating
        call    UPDATE_GAME_TIMER                              ;#4069: CD 4C 46
        ld      a,(SAT_MIRROR + SPRITE_PENGUIN + 8 + ATTR_X)   ;#406C: 3A 81 E0
        bit     7,a                                            ;#406F: CB 7F
        ld      a,0                                            ;#4071: 3E 00
        jr      z,UPDATE_SIDE_FLAG                             ;#4073: 28 01
        inc     a                                              ;#4075: 3C
UPDATE_SIDE_FLAG:
        ; Updates the penguin's screen side flag
        ld      (PENGUIN_SIDE_FLAG),a                          ;#4076: 32 FC E0
SET_VBLANK_BUSY:
        ; Sets the VBLANK busy flag
        ld      hl,VBLANK_BUSY_FLAG                            ;#4079: 21 05 E0
        bit     0,(hl)                                         ;#407C: CB 46
        jr      nz,EARLY_RETURN                                ;#407E: 20 14
        ld      (hl),1                                         ;#4080: 36 01
        ei                                                     ;#4082: FB
        call    READ_INPUT                                     ;#4083: CD A4 40
        call    STATE_MACHINE                                  ;#4086: CD 07 41
        di                                                     ;#4089: F3
        pop     hl                                             ;#408A: E1
        pop     de                                             ;#408B: D1
        pop     bc                                             ;#408C: C1
        xor     a                                              ;#408D: AF
        ld      (VBLANK_BUSY_FLAG),a                           ;#408E: 32 05 E0
        pop     af                                             ;#4091: F1
        ei                                                     ;#4092: FB
        ret                                                    ;#4093: C9

EARLY_RETURN:
        ; Returns from interrupt or process
        pop     hl                                             ;#4094: E1
        pop     de                                             ;#4095: D1
        pop     bc                                             ;#4096: C1
        pop     af                                             ;#4097: F1
        ei                                                     ;#4098: FB
        ret                                                    ;#4099: C9

JUMP_TABLE_DISPATCHER:
        ; Dispatcher for inline jump tables (index in A)
        add     a,a                                            ;#409A: 87
        pop     hl                                             ;#409B: E1
        call    ADD_HL_A                                       ;#409C: CD D3 48
        ld      e,(hl)                                         ;#409F: 5E
        inc     hl                                             ;#40A0: 23
        ld      d,(hl)                                         ;#40A1: 56
        ex      de,hl                                          ;#40A2: EB
        jp      (hl)                                           ;#40A3: E9

READ_INPUT:
        ; Poll Joystick (PSG) or Keyboard (PPI)
        ld      a,(GAME_STATE)                                 ;#40A4: 3A 00 E0
        cp      7                                              ;#40A7: FE 07
        ret     c                                              ;#40A9: D8
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#40AA: 3A 02 E0
        bit     6,a                                            ;#40AD: CB 77
        jr      z,LOAD_DEMO_PLAY_DATA                          ;#40AF: 28 3A
        bit     4,a                                            ;#40B1: CB 67
        jr      nz,READ_KEYBOARD_AS_JOYSTICK                   ;#40B3: 20 10
        ld      a,0Eh                                          ;#40B5: 3E 0E
        call    BIOS_RDPSG                                     ;#40B7: CD 96 00
        cpl                                                    ;#40BA: 2F
        and     3Fh                                            ;#40BB: E6 3F
STORE_INPUT_AND_RET:
        ; Stores input and returns
        ld      hl,CUR_INPUT_KEYS                              ;#40BD: 21 09 E0
        ld      c,(hl)                                         ;#40C0: 4E
        ld      (hl),a                                         ;#40C1: 77
        dec     hl                                             ;#40C2: 2B
        ld      (hl),c                                         ;#40C3: 71
        ret                                                    ;#40C4: C9

READ_KEYBOARD_AS_JOYSTICK:
        ; Reads cursor keys and space, emulating joystick
        ld      a,7                                            ;#40C5: 3E 07
        call    BIOS_SNSMAT                                    ;#40C7: CD 41 01
        cpl                                                    ;#40CA: 2F
        rrca                                                   ;#40CB: 0F
        and     20h                                            ;#40CC: E6 20
        ld      e,a                                            ;#40CE: 5F
        ld      a,8                                            ;#40CF: 3E 08
        call    BIOS_SNSMAT                                    ;#40D1: CD 41 01
        cpl                                                    ;#40D4: 2F
        rrca                                                   ;#40D5: 0F
        rrca                                                   ;#40D6: 0F
        ld      b,a                                            ;#40D7: 47
        and     4                                              ;#40D8: E6 04
        or      e                                              ;#40DA: B3
        ld      c,a                                            ;#40DB: 4F
        ld      a,b                                            ;#40DC: 78
        rrca                                                   ;#40DD: 0F
        rrca                                                   ;#40DE: 0F
        ld      b,a                                            ;#40DF: 47
        and     18h                                            ;#40E0: E6 18
        or      c                                              ;#40E2: B1
        ld      c,a                                            ;#40E3: 4F
        ld      a,b                                            ;#40E4: 78
        rrca                                                   ;#40E5: 0F
        and     3                                              ;#40E6: E6 03
        or      c                                              ;#40E8: B1
        jr      STORE_INPUT_AND_RET                            ;#40E9: 18 D2

LOAD_DEMO_PLAY_DATA:
        ; Read an input from the demo play data
        ld      de,(INPUT_DEMO_PLAY_PTR)                       ;#40EB: ED 5B EC E0
        ld      hl,DEMO_PLAY_TIMING_COUNTER                    ;#40EF: 21 EB E0
        inc     (hl)                                           ;#40F2: 34
        ld      a,(hl)                                         ;#40F3: 7E
        and     1Fh                                            ;#40F4: E6 1F
        jr      nz,RETURN_CURRENT_INPUT                        ;#40F6: 20 08
        ld      a,(de)                                         ;#40F8: 1A
        inc     de                                             ;#40F9: 13
        ld      (INPUT_DEMO_PLAY_PTR),de                       ;#40FA: ED 53 EC E0
        jr      STORE_INPUT_AND_RET                            ;#40FE: 18 BD

RETURN_CURRENT_INPUT:
        ; Input routine exit path returning current keys
        ld      a,(CUR_INPUT_KEYS)                             ;#4100: 3A 09 E0
        and     0Fh                                            ;#4103: E6 0F
        jr      STORE_INPUT_AND_RET                            ;#4105: 18 B6

STATE_MACHINE:
        ; Main game state machine loop and frame counter update
        ld      hl,FRAME_COUNTER                               ;#4107: 21 03 E0
        inc     (hl)                                           ;#410A: 34
        call    POLL_CONTROLLER_SELECT                         ;#410B: CD 13 44
        ld      a,(GAME_STATE)                                 ;#410E: 3A 00 E0
        call    JUMP_TABLE_DISPATCHER                          ;#4111: CD 9A 40
        dw      DUMMY_RET                                      ;#4114: 34 41
        dw      GAME_STATE_1_HANDLER                           ;#4116: 35 41
        dw      GAME_STATE_2_HANDLER                           ;#4118: 46 41
        dw      GAME_STATE_3_HANDLER                           ;#411A: 58 41
        dw      GAME_STATE_4_HANDLER                           ;#411C: 63 41
        dw      GAME_STATE_5_HANDLER                           ;#411E: 71 41
        dw      GAME_STATE_6_HANDLER                           ;#4120: 79 41
        dw      GAME_STATE_7_HANDLER                           ;#4122: 80 41
        dw      GAME_STATE_8_HANDLER                           ;#4124: CF 41
        dw      GAME_STATE_9_HANDLER                           ;#4126: 3B 42
        dw      GAME_STATE_10_HANDLER                          ;#4128: 7D 42
        dw      GAME_STATE_11_HANDLER                          ;#412A: 96 42
        dw      GAME_STATE_12_HANDLER                          ;#412C: BC 42
        dw      GAME_STATE_13_HANDLER                          ;#412E: E1 42
        dw      GAME_STATE_14_HANDLER                          ;#4130: F2 42
        dw      GAME_STATE_15_HANDLER                          ;#4132: DD 48

DUMMY_RET:
        ; Simple RET instruction
        ret                                                    ;#4134: C9

GAME_STATE_1_HANDLER:
        ; Game state 1: Init VRAM
        call    INIT_ALL_VDP_PLANES                            ;#4135: CD 34 58
        LOAD_VRAM_COLOR a, COLOR_BLACK, COLOR_BLACK            ;#4138: 3E 11
        ld      (VDP_TEMP_AREA),a                              ;#413A: 32 0A E0
        ld      hl,0                                           ;#413D: 21 00 00
        ld      (KONAMI_LOGO_ROW_PTR),hl                       ;#4140: 22 0E E0
        jp      INCREMENT_STATE                                ;#4143: C3 EE 43

GAME_STATE_2_HANDLER:
        ; Game state 2: Konami opening scroll
        ld      a,(FRAME_COUNTER)                              ;#4146: 3A 03 E0
        rra                                                    ;#4149: 1F
        ret     nc                                             ;#414A: D0
        call    KONAMI_OPENING_ANIMATION                       ;#414B: CD 6B 48
        ret     nz                                             ;#414E: C0
        ld      hl,MSG_VIDEO_CARTRIDGE                         ;#414F: 21 DE 57
        call    WRITE_VRAM_STREAM                              ;#4152: CD 83 45
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#4155: C3 E9 43

GAME_STATE_3_HANDLER:
        ; Game state 3: Pause between openings
        ld      hl,WAIT_TIMER                                  ;#4158: 21 04 E0
        dec     (hl)                                           ;#415B: 35
        ret     nz                                             ;#415C: C0
        call    INIT_TITLE_BACKGROUND                          ;#415D: CD 1E 48
        jp      INCREMENT_STATE_WITH_GIVEN_DELAY               ;#4160: C3 EB 43

GAME_STATE_4_HANDLER:
        ; Game state 4: Reveal game logo
        call    TITLE_WINDOW_ANIMATION                         ;#4163: CD 39 48
        ret     c                                              ;#4166: D8
        ld      hl,MSG_PLAY_SELECT                             ;#4167: 21 93 57
        call    WRITE_VRAM_STREAM                              ;#416A: CD 83 45
        xor     a                                              ;#416D: AF
        jp      INCREMENT_STATE_WITH_GIVEN_DELAY               ;#416E: C3 EB 43

GAME_STATE_5_HANDLER:
        ; Game state 5: Post-logo delay
        ld      hl,WAIT_TIMER                                  ;#4171: 21 04 E0
        dec     (hl)                                           ;#4174: 35
        ret     nz                                             ;#4175: C0
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#4176: C3 E9 43

GAME_STATE_6_HANDLER:
        ; Game state 6: Clear sprites and wait for VRAM update
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#4179: CD A6 45
        ret     p                                              ;#417C: F0
        jp      INCREMENT_STATE                                ;#417D: C3 EE 43

GAME_STATE_7_HANDLER:
        ; Game state 7: Prepare demo play
        ld      a,(GAME_SUBSTATE)                              ;#4180: 3A 01 E0
        call    JUMP_TABLE_DISPATCHER                          ;#4183: CD 9A 40
        dw      INIT_DEMO_PLAY                                 ;#4186: 8C 41
        dw      PREPARE_DEMO_PLAY                              ;#4188: A3 41
        dw      FINISH_DEMO_PLAY                               ;#418A: C4 41

INIT_DEMO_PLAY:
        ; Sets up input flags and pointers for demo-play startup
        call    INIT_RAM_AND_VRAM                              ;#418C: CD 43 44
        ld      hl,INPUT_DEVICE_FLAGS                          ;#418F: 21 02 E0
        res     6,(hl)                                         ;#4192: CB B6
        ; 73Ch (1852) ticks at 60 Hz ≈ 30.9 s — demo-play replay length.
        ld      hl,73Ch                                        ;#4194: 21 3C 07
        ld      (STAGE_DEMO_PLAY_TIMER),hl                     ;#4197: 22 EE E0
        ld      hl,INPUT_DEMO_PLAY_DATA                        ;#419A: 21 F4 57
        ld      (INPUT_DEMO_PLAY_PTR),hl                       ;#419D: 22 EC E0
        jp      GAME_STATE_9_HANDLER                           ;#41A0: C3 3B 42

PREPARE_DEMO_PLAY:
        ; Draws first section of penguin during demo-play sequence
        ld      hl,KONAMI_COPYRIGHT_TEXT+2                     ;#41A3: 21 87 57
        LOAD_NAME_TABLE de, 6, 11                              ;#41A6: 11 CB 38
        call    WRITE_VRAM_STREAM_WITH_OFFSET                  ;#41A9: CD 87 45
        ld      a,1                                            ;#41AC: 3E 01
        ld      (TIMER_ACTIVE_FLAG),a                          ;#41AE: 32 33 E1
        call    MAIN_GAME_ENGINE                               ;#41B1: CD 1F 4B
        ld      hl,(STAGE_DEMO_PLAY_TIMER)                     ;#41B4: 2A EE E0
        dec     hl                                             ;#41B7: 2B
        ld      (STAGE_DEMO_PLAY_TIMER),hl                     ;#41B8: 22 EE E0
        ld      a,h                                            ;#41BB: 7C
        or      l                                              ;#41BC: B5
        ret     nz                                             ;#41BD: C0
        ld      (TIMER_ACTIVE_FLAG),a                          ;#41BE: 32 33 E1
        jp      INCREMENT_SUBSTATE_WITH_FIXED_DELAY            ;#41C1: C3 F7 43

FINISH_DEMO_PLAY:
        ; Clears sprites and transitions to next game state
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#41C4: CD A6 45
        ret     p                                              ;#41C7: F0
        xor     a                                              ;#41C8: AF
        ld      (GAME_STATE),a                                 ;#41C9: 32 00 E0
        jp      INCREMENT_STATE                                ;#41CC: C3 EE 43

GAME_STATE_8_HANDLER:
        ; Game state 8: Demo play mode
        ld      a,(GAME_SUBSTATE)                              ;#41CF: 3A 01 E0
        call    JUMP_TABLE_DISPATCHER                          ;#41D2: CD 9A 40
        dw      AUTO_DEMO_PLAY_RESTART                         ;#41D5: DD 41
        dw      TITLE_MENU_INIT                                ;#41D7: EE 41
        dw      TITLE_MENU_BLINK_UPDATE                        ;#41D9: 01 42
        dw      START_GAME_PREP                                ;#41DB: 31 42

AUTO_DEMO_PLAY_RESTART:
        ; Sets up demo mode and restarts game intro sequence
        call    CLEAR_SPRITES                                  ;#41DD: CD DB 45
        call    CLEAR_NAME_TABLE                               ;#41E0: CD 95 44
        call    INIT_TITLE_BACKGROUND                          ;#41E3: CD 1E 48
        ld      a,CMD_SOUND_INTRO_MUSIC                        ;#41E6: 3E 92
        call    PLAY_SOUND_SAFE                                ;#41E8: CD 83 79
        jp      INCREMENT_SUBSTATE                             ;#41EB: C3 FC 43

TITLE_MENU_INIT:
        ; Initializes blink timer for the "PLAY SELECT" menu
        call    TITLE_WINDOW_ANIMATION                         ;#41EE: CD 39 48
        jr      c,TITLE_MENU_INIT                              ;#41F1: 38 FB
        ld      hl,MSG_PLAY_SELECT                             ;#41F3: 21 93 57
        call    WRITE_VRAM_STREAM                              ;#41F6: CD 83 45
        ld      a,6                                            ;#41F9: 3E 06
        ld      (TITLE_BLINK_TIMER),a                          ;#41FB: 32 8D E1
        jp      INCREMENT_SUBSTATE                             ;#41FE: C3 FC 43

TITLE_MENU_BLINK_UPDATE:
        ; Oscillates the "PLAY SELECT" message visibility
        ld      hl,FRAME_COUNTER                               ;#4201: 21 03 E0
        ld      a,(hl)                                         ;#4204: 7E
        and     7                                              ;#4205: E6 07
        ret     nz                                             ;#4207: C0
        ld      a,(hl)                                         ;#4208: 7E
        bit     3,a                                            ;#4209: CB 5F
        jr      nz,DRAW_PLAY_SELECT                            ;#420B: 20 16
        LOAD_NAME_TABLE de, 16, 0                              ;#420D: 11 00 3A
        ld      bc,20h                                         ;#4210: 01 20 00
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4213: 3A 02 E0
        and     10h                                            ;#4216: E6 10
        rlca                                                   ;#4218: 07
        rlca                                                   ;#4219: 07
        call    ADD_DE_A                                       ;#421A: CD D8 48
        ld      a,1                                            ;#421D: 3E 01
        call    FILL_VRAM                                      ;#421F: CD DC 44
        ret                                                    ;#4222: C9

DRAW_PLAY_SELECT:
        ; Routine to draw the "PLAY SELECT" text
        ld      hl,MSG_PLAY_SELECT                             ;#4223: 21 93 57
        call    WRITE_VRAM_STREAM                              ;#4226: CD 83 45
        ld      hl,TITLE_BLINK_TIMER                           ;#4229: 21 8D E1
        dec     (hl)                                           ;#422C: 35
        ret     nz                                             ;#422D: C0
        jp      INCREMENT_SUBSTATE_WITH_FIXED_DELAY            ;#422E: C3 F7 43

START_GAME_PREP:
        ; Prepare VRAM/RAM and transition to next game state
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#4231: CD A6 45
        ret     p                                              ;#4234: F0
        call    INIT_RAM_AND_VRAM                              ;#4235: CD 43 44
        jp      INCREMENT_STATE                                ;#4238: C3 EE 43

GAME_STATE_9_HANDLER:
        ; Game state 9: Stage setup and HUD refresh
        ld      a,(CURRENT_STAGE)                              ;#423B: 3A E8 E0
        ld      hl,STAGE_DISTANCE_TABLE                        ;#423E: 21 AE 4A
        add     a,a                                            ;#4241: 87
        add     a,a                                            ;#4242: 87
        call    ADD_HL_A                                       ;#4243: CD D3 48
        ld      e,(hl)                                         ;#4246: 5E
        inc     hl                                             ;#4247: 23
        ld      d,(hl)                                         ;#4248: 56
        inc     hl                                             ;#4249: 23
        ld      (STAGE_DISTANCE_HIGH),de                       ;#424A: ED 53 E6 E0
        ld      e,(hl)                                         ;#424E: 5E
        inc     hl                                             ;#424F: 23
        ld      d,(hl)                                         ;#4250: 56
        ld      a,(CURRENT_STAGE_INDEX)                        ;#4251: 3A E1 E0
        ld      hl,STAGE_COMPLETION_FLAGS                      ;#4254: 21 D5 E0
        call    ADD_HL_A                                       ;#4257: CD D3 48
        ld      a,(hl)                                         ;#425A: 7E
        sub     10h                                            ;#425B: D6 10
        jr      c,SET_REMAINING_DISTANCE                       ;#425D: 38 0C
        daa                                                    ;#425F: 27
        ld      c,a                                            ;#4260: 4F
        ld      a,e                                            ;#4261: 7B
        sub     c                                              ;#4262: 91
        jr      nc,BCD_SUB_CARRY                               ;#4263: 30 04
        daa                                                    ;#4265: 27
        dec     d                                              ;#4266: 15
        jr      FINALIZE_DISTANCE_CALC                         ;#4267: 18 01

BCD_SUB_CARRY:
        ; Handle BCD subtraction carry
        daa                                                    ;#4269: 27
FINALIZE_DISTANCE_CALC:
        ; Finalize BCD distance calculation
        ld      e,a                                            ;#426A: 5F
SET_REMAINING_DISTANCE:
        ; Sets the remaining stage distance in BCD
        ld      (REMANING_TIME_BCD),de                         ;#426B: ED 53 E3 E0
        call    REFRESH_HUD                                    ;#426F: CD 95 46
        call    INIT_ALL_VDP_PLANES                            ;#4272: CD 34 58
        ld      a,ID_STATE_14                                  ;#4275: 3E 0E
        ld      (GAME_STATE),a                                 ;#4277: 32 00 E0
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#427A: C3 E9 43

GAME_STATE_10_HANDLER:
        ; Game state 10: Gameplay init
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#427D: CD A6 45
        ret     p                                              ;#4280: F0
        call    INIT_GAMEPLAY_VARS                             ;#4281: CD D6 4A
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4284: 3A 02 E0
        bit     6,a                                            ;#4287: CB 77
        ld      a,CMD_SOUND_MAIN_THEME                         ;#4289: 3E 8A
        call    nz,PLAY_SOUND_SAFE                             ;#428B: C4 83 79
        ld      a,1                                            ;#428E: 3E 01
        ld      (TIMER_ACTIVE_FLAG),a                          ;#4290: 32 33 E1
        jp      INCREMENT_STATE                                ;#4293: C3 EE 43

GAME_STATE_11_HANDLER:
        ; Game state 11: Main gameplay loop
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4296: 3A 02 E0
        bit     6,a                                            ;#4299: CB 77
        jr      z,SET_STATE_INTRO                              ;#429B: 28 1A
        call    MAIN_GAME_ENGINE                               ;#429D: CD 1F 4B
        ld      hl,(TIME_UP_FLAG)                              ;#42A0: 2A 0C E0
        ld      a,l                                            ;#42A3: 7D
        add     a,h                                            ;#42A4: 84
        ret     z                                              ;#42A5: C8
        ld      a,l                                            ;#42A6: 7D
        ld      hl,TIMER_ACTIVE_FLAG                           ;#42A7: 21 33 E1
        ld      (hl),0                                         ;#42AA: 36 00
        or      a                                              ;#42AC: B7
        ld      a,ID_STATE_12                                  ;#42AD: 3E 0C
        jr      nz,SET_STATE                                   ;#42AF: 20 02
        ld      a,ID_STATE_14                                  ;#42B1: 3E 0E
SET_STATE:
        ; Store A into GAME_STATE (caller sets A to ID_STATE_12 or ID_STATE_14)
        ld      (GAME_STATE),a                                 ;#42B3: 32 00 E0
        ret                                                    ;#42B6: C9

SET_STATE_INTRO:
        ; Sets game state to Stage Intro (7.1)
        LOAD_SUBSTATE hl, ID_STATE_7, ID_SUBSTATE_1            ;#42B7: 21 07 01
        jr      SET_GAME_STATE_HL                              ;#42BA: 18 32

GAME_STATE_12_HANDLER:
        ; Game state 12: Time out sequence
        xor     a                                              ;#42BC: AF
        ld      (TIME_UP_FLAG),a                               ;#42BD: 32 0C E0
        ld      hl,SAT_MIRROR + SPRITE_CLOUD + ATTR_Y          ;#42C0: 21 B8 E0
        ld      de,4                                           ;#42C3: 11 04 00
        ld      b,4                                            ;#42C6: 06 04
CLEAR_CLOUD_SPRITES_Y:
        ; Clear cloud sprite Y positions (hide off-screen)
        ld      (hl),0E0h                                      ;#42C8: 36 E0
        add     hl,de                                          ;#42CA: 19
        djnz    CLEAR_CLOUD_SPRITES_Y                          ;#42CB: 10 FB
        call    SYNC_SPRITE_ATTRIBUTES_ALL                     ;#42CD: CD 9D 66
        ; At this point a=0
        ld      (DISTANCE_EVENT_TICK),a                        ;#42D0: 32 E2 E0
        ld      a,CMD_SOUND_TIME_OUT                           ;#42D3: 3E 8C
        call    PLAY_SOUND_SAFE                                ;#42D5: CD 83 79
        ld      hl,MSG_TIME_OUT                                ;#42D8: 21 D3 57
        call    WRITE_VRAM_STREAM                              ;#42DB: CD 83 45
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#42DE: C3 E9 43

GAME_STATE_13_HANDLER:
        ; Game state 13: Wait for time-out sound
        ld      a,(MUSIC_VARS_CH0+MUSIC_DRIVER_CONTROL)        ;#42E1: 3A 12 E0
        or      a                                              ;#42E4: B7
        ret     nz                                             ;#42E5: C0
        ld      hl,INPUT_DEVICE_FLAGS                          ;#42E6: 21 02 E0
        res     6,(hl)                                         ;#42E9: CB B6
        LOAD_SUBSTATE hl, ID_STATE_7, ID_SUBSTATE_2            ;#42EB: 21 07 02
SET_GAME_STATE_HL:
        ; Sets main Game State and Substate from HL
        ld      (GAME_STATE),hl                                ;#42EE: 22 00 E0
        ret                                                    ;#42F1: C9

GAME_STATE_14_HANDLER:
        ; Game state 14: Goal reached sequence
        ld      a,(GAME_SUBSTATE)                              ;#42F2: 3A 01 E0
        call    JUMP_TABLE_DISPATCHER                          ;#42F5: CD 9A 40
        dw      GOAL_PENGUIN_WALK                              ;#42F8: 08 43
        dw      GOAL_PROCESS_SCORE                             ;#42FA: 1B 43
        dw      GOAL_WAIT_SOUND_1                              ;#42FC: 5B 43
        dw      GOAL_PENGUIN_DANCE                             ;#42FE: 69 43
        dw      GOAL_WAIT_UNTIL_MUTE                           ;#4300: 86 43
        dw      GOAL_WAIT_SOUND_2                              ;#4302: B0 43
        dw      GOAL_TALLY_TIMER_BONUS                         ;#4304: B9 43
        dw      GOAL_CLEANUP_AND_EXIT                          ;#4306: E0 43

GOAL_PENGUIN_WALK:
        ; Penguin walking towards the flag
        ld      hl,PENGUIN_INPUT_LOCK_TIMER                    ;#4308: 21 F9 E0
        ld      a,(hl)                                         ;#430B: 7E
        or      a                                              ;#430C: B7
        jp      z,INCREMENT_SUBSTATE                           ;#430D: CA FC 43
        call    UPDATE_THROTTLED_ANIMATION                     ;#4310: CD ED 4B
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4313: 3A F9 E0
        or      a                                              ;#4316: B7
        ret     nz                                             ;#4317: C0
        jp      INCREMENT_SUBSTATE                             ;#4318: C3 FC 43

GOAL_PROCESS_SCORE:
        ; Preliminary score calculation/resetting
        ld      hl,CURRENT_VISIBLE_STAGE                       ;#431B: 21 E0 E0
        ld      a,(hl)                                         ;#431E: 7E
        add     a,1                                            ;#431F: C6 01
        daa                                                    ;#4321: 27
        ld      (hl),a                                         ;#4322: 77
        inc     hl                                             ;#4323: 23
        ; Now hl points to CURRENT_STAGE_INDEX
        ld      a,(hl)                                         ;#4324: 7E
        ld      c,a                                            ;#4325: 4F
        inc     a                                              ;#4326: 3C
        cp      0Ah                                            ;#4327: FE 0A
        jr      c,GOAL_SKIP_TEXT_INIT                          ;#4329: 38 04
        xor     a                                              ;#432B: AF
        ld      (DISTANCE_EVENT_TICK),a                        ;#432C: 32 E2 E0
GOAL_SKIP_TEXT_INIT:
        ; Skip time-bonus text initialization
        ld      (hl),a                                         ;#432F: 77
        ld      a,c                                            ;#4330: 79
        ld      hl,STAGE_COMPLETION_FLAGS                      ;#4331: 21 D5 E0
        call    ADD_HL_A                                       ;#4334: CD D3 48
        ld      a,(REMANING_TIME_BCD)                          ;#4337: 3A E3 E0
        ld      (hl),a                                         ;#433A: 77
        xor     a                                              ;#433B: AF
        ld      (STAGE_GOAL_FLAG),a                            ;#433C: 32 0D E0
        ld      hl,CURRENT_STAGE                               ;#433F: 21 E8 E0
        inc     (hl)                                           ;#4342: 34
        ld      a,(hl)                                         ;#4343: 7E
        cp      0Ah                                            ;#4344: FE 0A
        jr      nz,GOAL_INIT_VICTORY_PENGUIN                   ;#4346: 20 02
        ld      (hl),0                                         ;#4348: 36 00
GOAL_INIT_VICTORY_PENGUIN:
        ; Initialize penguin position/speed for victory
        ld      a,(PENGUIN_X_POS)                              ;#434A: 3A 79 E0
        ld      h,a                                            ;#434D: 67
        ld      l,1                                            ;#434E: 2E 01
        ld      (VICTORY_WADDLE_STEP),hl                       ;#4350: 22 38 E1
        ld      a,13h                                          ;#4353: 3E 13
        ld      (PENGUIN_SPEED),a                              ;#4355: 32 00 E1
        jp      INCREMENT_SUBSTATE                             ;#4358: C3 FC 43

GOAL_WAIT_SOUND_1:
        ; Wait for initial victory sound to finish
        ld      c,0FFh                                         ;#435B: 0E FF
        call    UPDATE_VICTORY_PENGUIN_ANIM                    ;#435D: CD 89 54
        ret     nz                                             ;#4360: C0
        ld      a,0Ch                                          ;#4361: 3E 0C
        ld      (VICTORY_WADDLE_STEP),a                        ;#4363: 32 38 E1
        jp      INCREMENT_SUBSTATE                             ;#4366: C3 FC 43

GOAL_PENGUIN_DANCE:
        ; Victory dance animation
        ld      c,0                                            ;#4369: 0E 00
        ld      a,(PENGUIN_X_POS)                              ;#436B: 3A 79 E0
        ld      h,a                                            ;#436E: 67
        call    UPDATE_VICTORY_PENGUIN_ANIM                    ;#436F: CD 89 54
        ret     nz                                             ;#4372: C0
        call    INIT_GOAL_SPRITES                              ;#4373: CD 81 66
        call    CYCLE_GOAL_PENGUIN_PATTERNS                    ;#4376: CD CB 54
        call    INIT_GOAL_GRAPHICS                             ;#4379: CD 2F 55
        ld      a,CMD_SOUND_STAGE_CLEAR                        ;#437C: 3E 8F
        call    PLAY_SOUND_SAFE                                ;#437E: CD 83 79
        ld      a,4                                            ;#4381: 3E 04
        ld      (GAME_SUBSTATE),a                              ;#4383: 32 01 E0
GOAL_WAIT_UNTIL_MUTE:
        ; Wait for MUSIC_VARS_CH1 to silence, then update goal flag position
        ld      a,(MUSIC_VARS_CH1)                             ;#4386: 3A 1A E0
        dec     a                                              ;#4389: 3D
        ret     nz                                             ;#438A: C0
        call    UPDATE_GOAL_FLAG_POSITION                      ;#438B: CD 6B 55
        ld      a,(CURRENT_STAGE_INDEX)                        ;#438E: 3A E1 E0
        or      a                                              ;#4391: B7
        jr      z,CHECK_VICTORY_DANCE_START                    ;#4392: 28 04
        cp      5                                              ;#4394: FE 05
        jr      nz,CONTINUE_GOAL_ANIMATION                     ;#4396: 20 0D
CHECK_VICTORY_DANCE_START:
        ; Check if victory dance should begin
        ld      a,(VICTORY_DANCE_COUNTER)                      ;#4398: 3A 3A E1
        cp      0Fh                                            ;#439B: FE 0F
        jr      nz,CONTINUE_GOAL_ANIMATION                     ;#439D: 20 06
        call    LOAD_VICTORY_GFX                               ;#439F: CD E1 54
        jp      INCREMENT_SUBSTATE                             ;#43A2: C3 FC 43

CONTINUE_GOAL_ANIMATION:
        ; Continue updating goal animation (victory dance)
        call    UPDATE_VICTORY_DANCE                           ;#43A5: CD CF 54
        ld      a,(VICTORY_DANCE_COUNTER)                      ;#43A8: 3A 3A E1
        cp      10h                                            ;#43AB: FE 10
        ret     nz                                             ;#43AD: C0
        jr      INCREMENT_SUBSTATE                             ;#43AE: 18 4C

GOAL_WAIT_SOUND_2:
        ; Wait for secondary victory sound
        ld      a,(MUSIC_VARS_CH0+MUSIC_DRIVER_CONTROL)        ;#43B0: 3A 12 E0
        or      a                                              ;#43B3: B7
        ret     nz                                             ;#43B4: C0
        ld      a,10h                                          ;#43B5: 3E 10
        jr      INCREMENT_SUBSTATE_WITH_GIVEN_DELAY            ;#43B7: 18 40

GOAL_TALLY_TIMER_BONUS:
        ; Countdown loop to convert remaining time to score
        ld      hl,WAIT_TIMER                                  ;#43B9: 21 04 E0
        ld      a,(hl)                                         ;#43BC: 7E
        or      a                                              ;#43BD: B7
        jr      z,PROCESS_SCORE_TALLY                          ;#43BE: 28 02
        dec     (hl)                                           ;#43C0: 35
        ret                                                    ;#43C1: C9

PROCESS_SCORE_TALLY:
        ; Handle score addition and sound effect
        ld      a,(FRAME_COUNTER)                              ;#43C2: 3A 03 E0
        and     3                                              ;#43C5: E6 03
        ret     nz                                             ;#43C7: C0
        ld      hl,(REMANING_TIME_BCD)                         ;#43C8: 2A E3 E0
        ld      a,h                                            ;#43CB: 7C
        add     a,l                                            ;#43CC: 85
        jr      z,INCREMENT_SUBSTATE_WITH_FIXED_DELAY          ;#43CD: 28 28
        ld      c,0                                            ;#43CF: 0E 00
        call    DECREMENT_DISTANCE                             ;#43D1: CD 65 46
        ld      de,100h                                        ;#43D4: 11 00 01
        call    ADD_SCORE                                      ;#43D7: CD 08 46
        ld      a,ID_SOUND_GOAL_TICK                           ;#43DA: 3E 01
        call    PLAY_SOUND_SAFE                                ;#43DC: CD 83 79
        ret                                                    ;#43DF: C9

GOAL_CLEANUP_AND_EXIT:
        ; Final cleanup before transitioning out of State 14
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#43E0: CD A6 45
        ret     p                                              ;#43E3: F0
        ld      a,ID_STATE_8                                   ;#43E4: 3E 08
        ld      (GAME_STATE),a                                 ;#43E6: 32 00 E0
INCREMENT_STATE_WITH_FIXED_DELAY:
        ; Transition to game after controller selection
        ld      a,50h                                          ;#43E9: 3E 50
INCREMENT_STATE_WITH_GIVEN_DELAY:
        ; Increments game state with delay in A
        ld      (WAIT_TIMER),a                                 ;#43EB: 32 04 E0
INCREMENT_STATE:
        ; Increments game state
        ld      hl,GAME_STATE                                  ;#43EE: 21 00 E0
        inc     (hl)                                           ;#43F1: 34
        xor     a                                              ;#43F2: AF
        ld      (GAME_SUBSTATE),a                              ;#43F3: 32 01 E0
        ret                                                    ;#43F6: C9

INCREMENT_SUBSTATE_WITH_FIXED_DELAY:
        ; Increments substate if enough frames passed
        ld      a,50h                                          ;#43F7: 3E 50
INCREMENT_SUBSTATE_WITH_GIVEN_DELAY:
        ; Increments substate if A frames passed
        ld      (WAIT_TIMER),a                                 ;#43F9: 32 04 E0
INCREMENT_SUBSTATE:
        ; Increments game substate
        ld      hl,GAME_SUBSTATE                               ;#43FC: 21 01 E0
        inc     (hl)                                           ;#43FF: 34
        ret                                                    ;#4400: C9

DRAW_CONTROLLER_INDICATOR:
        ; Update indicator (Joystick vs Keyboard) on screen (unused)?
        call    WRITE_VRAM_STREAM                              ;#4401: CD 83 45
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4404: 3A 02 E0
        rlca                                                   ;#4407: 07
        and     1                                              ;#4408: E6 01
        add     a,31h                                          ;#440A: C6 31
        LOAD_NAME_TABLE de, 9, 19                              ;#440C: 11 33 39
        call    WRITE_VRAM_BYTE                                ;#440F: CD A5 48
        ret                                                    ;#4412: C9

POLL_CONTROLLER_SELECT:
        ; Checks for '1' or '2' keys to select input device
        ld      a,(SELECT_CONTROLLER_DISABLED)                 ;#4413: 3A 3B E1
        or      a                                              ;#4416: B7
        ret     nz                                             ;#4417: C0
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4418: 3A 02 E0
        bit     6,a                                            ;#441B: CB 77
        ret     nz                                             ;#441D: C0
        ld      a,0                                            ;#441E: 3E 00
        call    BIOS_SNSMAT                                    ;#4420: CD 41 01
        cpl                                                    ;#4423: 2F
        and     6                                              ;#4424: E6 06
        ld      b,40h                                          ;#4426: 06 40
        cp      2                                              ;#4428: FE 02
        jr      z,POLL_CONTROLLER_DONE                         ;#442A: 28 05
        ld      b,50h                                          ;#442C: 06 50
        cp      4                                              ;#442E: FE 04
        ret     nz                                             ;#4430: C0
POLL_CONTROLLER_DONE:
        ; Controller selection finished
        xor     a                                              ;#4431: AF
        ld      (TIMER_ACTIVE_FLAG),a                          ;#4432: 32 33 E1
        ld      a,b                                            ;#4435: 78
        ld      (INPUT_DEVICE_FLAGS),a                         ;#4436: 32 02 E0
        pop     hl                                             ;#4439: E1
        ld      a,7                                            ;#443A: 3E 07
        ld      (GAME_STATE),a                                 ;#443C: 32 00 E0
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#443F: C3 E9 43
        ret                                                    ;#4442: C9

INIT_RAM_AND_VRAM:
        ; Clears work RAM and initializes VDP tables
        ld      hl,CURRENT_SCORE_BCD + BCD_LOW                 ;#4443: 21 43 E0
        ld      de,CURRENT_SCORE_BCD + BCD_LOW + 1             ;#4446: 11 44 E0
        ld      bc,100h                                        ;#4449: 01 00 01
        ld      (hl),0                                         ;#444C: 36 00
        ldir                                                   ;#444E: ED B0
        ld      hl,DEFAULT_GAME_VARS                           ;#4450: 21 71 44
        ld      de,CURRENT_VISIBLE_STAGE                       ;#4453: 11 E0 E0
        ld      bc,9                                           ;#4456: 01 09 00
        ldir                                                   ;#4459: ED B0
        LOAD_VRAM_ADDRESS de, 900h                             ;#445B: 11 00 09
        ld      bc,100h                                        ;#445E: 01 00 01
        ld      a,0F0h                                         ;#4461: 3E F0
        call    FILL_VRAM                                      ;#4463: CD DC 44
        ; Repeat for each of the 10 (0Ah) stages.
        ld      b,0Ah                                          ;#4466: 06 0A
        ld      hl,STAGE_COMPLETION_FLAGS                      ;#4468: 21 D5 E0
INIT_STAGE_COMPLETION_FLAGS:
        ; Initialize stage completion flags to default value
        ld      (hl),5                                         ;#446B: 36 05
        inc     hl                                             ;#446D: 23
        djnz    INIT_STAGE_COMPLETION_FLAGS                    ;#446E: 10 FB
        ret                                                    ;#4470: C9

DEFAULT_GAME_VARS:
        ; Initial values for E0E0h-E0E8h (Flags, Timers)
        db      1 ; CURRENT_VISIBLE_STAGE initial value        ;#4471: 01
        db      0 ; CURRENT_STAGE_INDEX initial value (stage 0) ;#4472: 00
        db      0 ; DISTANCE_EVENT_TICK initial value          ;#4473: 00
        dw      200h ; REMANING_TIME_BCD initial value (start distance) ;#4474: 00 02
        dw      1700h ; STAGE_DISTANCE_BCD initial value       ;#4476: 00 17
        db      0 ; MAP_PROGRESS_LIMIT initial value           ;#4478: 00
        db      0 ; CURRENT_STAGE initial value                ;#4479: 00

INIT_HARDWARE:
        ; Initialize VDP, PSG, and clear VRAM
        call    INIT_VDP_REGISTERS                             ;#447A: CD A3 44
        ld      a,7                                            ;#447D: 3E 07
        ld      e,0B8h                                         ;#447F: 1E B8
        call    BIOS_WRTPSG                                    ;#4481: CD 93 00
        call    INIT_PSG_PORT_B                                ;#4484: CD F0 45
        call    MUTE_PSG                                       ;#4487: CD 9D 44
        LOAD_VRAM_ADDRESS de, 0                                ;#448A: 11 00 00
        ld      bc,VRAM_SIZE                                   ;#448D: 01 00 40
ZERO_FILL_VRAM_RANGE:
        ; Set A=0 and fill VRAM for DE/BC range
        xor     a                                              ;#4490: AF
        call    FILL_VRAM                                      ;#4491: CD DC 44
        ret                                                    ;#4494: C9

CLEAR_NAME_TABLE:
        ; Clear the VRAM name table (3800h-3AFFh)
        LOAD_NAME_TABLE de, 0, 0                               ;#4495: 11 00 38
        ld      bc,300h                                        ;#4498: 01 00 03
        jr      ZERO_FILL_VRAM_RANGE                           ;#449B: 18 F3

MUTE_PSG:
        ; Stop sound
        ld      a,CMD_SOUND_STOP                               ;#449D: 3E 95
        call    PLAY_SOUND_SAFE                                ;#449F: CD 83 79
        ret                                                    ;#44A2: C9

INIT_VDP_REGISTERS:
        ; Copy VDP register values to RAM mirror and write to VDP
        ld      hl,INITIAL_VDP_REGISTERS                       ;#44A3: 21 BF 44
        ld      de,MIRROR_VDP_REGISTERS                        ;#44A6: 11 38 E0
        ld      bc,8                                           ;#44A9: 01 08 00
        ldir                                                   ;#44AC: ED B0
        ld      hl,MIRROR_VDP_REGISTERS                        ;#44AE: 21 38 E0
        ld      d,8                                            ;#44B1: 16 08
        ld      c,0                                            ;#44B3: 0E 00
INIT_VDP_REG_LOOP:
        ; Loop writing VDP registers from mirror
        ld      b,(hl)                                         ;#44B5: 46
        call    BIOS_WRTVDP                                    ;#44B6: CD 47 00
        inc     hl                                             ;#44B9: 23
        inc     c                                              ;#44BA: 0C
        dec     d                                              ;#44BB: 15
        jr      nz,INIT_VDP_REG_LOOP                           ;#44BC: 20 F7
        ret                                                    ;#44BE: C9

INITIAL_VDP_REGISTERS:
        ; Initial VDP register values
        ; Format: FORMAT_VDP_REGISTERS
        db      2, 0E2h, 0Eh, 7Fh, 7, 76h, 3, 0E1h ; VDP Registers initialization table  ;#44BF: 02 E2 0E 7F 07 76 03 E1

COPY_RAM_TO_VRAM:
        ; Copy RAM to VRAM
        di                                                     ;#44C7: F3
        set     6,d                                            ;#44C8: CB F2
        call    SET_VDP                                        ;#44CA: CD B7 48
        res     6,d                                            ;#44CD: CB B2
COPY_RAM_TO_VRAM_LOOP:
        ; Loop copying RAM to VRAM
        ld      a,(hl)                                         ;#44CF: 7E
        exx                                                    ;#44D0: D9
        out     (c),a                                          ;#44D1: ED 79
        exx                                                    ;#44D3: D9
        inc     hl                                             ;#44D4: 23
        dec     bc                                             ;#44D5: 0B
        ld      a,b                                            ;#44D6: 78
        or      c                                              ;#44D7: B1
        jr      nz,COPY_RAM_TO_VRAM_LOOP                       ;#44D8: 20 F5
        ei                                                     ;#44DA: FB
        ret                                                    ;#44DB: C9

FILL_VRAM:
        ; Fill VRAM with value
        di                                                     ;#44DC: F3
        ld      h,a                                            ;#44DD: 67
        set     6,d                                            ;#44DE: CB F2
        call    SET_VDP                                        ;#44E0: CD B7 48
        res     6,d                                            ;#44E3: CB B2
FILL_VRAM_LOOP:
        ; Loop filling VRAM
        ld      a,h                                            ;#44E5: 7C
        exx                                                    ;#44E6: D9
        out     (c),a                                          ;#44E7: ED 79
        exx                                                    ;#44E9: D9
        dec     bc                                             ;#44EA: 0B
        ld      a,b                                            ;#44EB: 78
        or      c                                              ;#44EC: B1
        jr      nz,FILL_VRAM_LOOP                              ;#44ED: 20 F6
        ei                                                     ;#44EF: FB
        ret                                                    ;#44F0: C9

FILL_VRAM_STREAM:
        ; Fills VRAM regions from a character-based stream (value, count, addr)
        ld      a,(hl)                                         ;#44F1: 7E
        inc     hl                                             ;#44F2: 23
        ld      (VRAM_FILL_VALUE),a                            ;#44F3: 32 DF E0
        ld      d,39h                                          ;#44F6: 16 39
FILL_VRAM_STREAM_LOOP:
        ; Loop over stream entries for VRAM fill
        ld      c,(hl)                                         ;#44F8: 4E
        inc     hl                                             ;#44F9: 23
        xor     a                                              ;#44FA: AF
        cp      c                                              ;#44FB: B9
        ret     z                                              ;#44FC: C8
        ld      b,a                                            ;#44FD: 47
        ld      e,(hl)                                         ;#44FE: 5E
        inc     hl                                             ;#44FF: 23
        ld      a,e                                            ;#4500: 7B
        cp      20h                                            ;#4501: FE 20
        jr      nc,FILL_VRAM_STREAM_ITER                       ;#4503: 30 01
        inc     d                                              ;#4505: 14
FILL_VRAM_STREAM_ITER:
        ; Next entry in VRAM fill stream
        ld      a,(VRAM_FILL_VALUE)                            ;#4506: 3A DF E0
        push    hl                                             ;#4509: E5
        push    de                                             ;#450A: D5
        call    FILL_VRAM                                      ;#450B: CD DC 44
        pop     de                                             ;#450E: D1
        pop     hl                                             ;#450F: E1
        jr      FILL_VRAM_STREAM_LOOP                          ;#4510: 18 E6

WRITE_VRAM_TILES_STREAM:
        ; Writes tiles to VRAM using a custom stream format
        ; For this routine, the sprite attribute table is just more name-table rows.
        ; Stream format overview:
        ; - Byte 0: header `H` (high nibble seeds row base, low 2 bits select VRAM page).
        ; - Then records: [K, data...] where K is E0h-FFh control, data bytes <E0h.
        ; - Terminator: `00h` in the data loop ends the stream.
        ld      a,(hl)                                         ;#4512: 7E
        or      a                                              ;#4513: B7
        ret     z                                              ;#4514: C8
        and     0F0h                                           ;#4515: E6 F0
        ld      c,a                                            ;#4517: 4F
        ; C stores the high nibble of the header.
        ld      a,(hl)                                         ;#4518: 7E
        inc     hl                                             ;#4519: 23
        and     3                                              ;#451A: E6 03
        add     a,78h                                          ;#451C: C6 78
        ld      d,a                                            ;#451E: 57
        ; D stores 38h, 39h, 3Ah, or 3Bh (with VDP write bit encoding applied).
        ld      a,c                                            ;#451F: 79
WRITE_VRAM_TILES_ADDRESS:
        ; Consume control byte and advance row base
        ld      b,(hl)                                         ;#4520: 46
        ; Lower nibble of B selects column.
        inc     hl                                             ;#4521: 23
        ; Increment row by one (times 32).
        ld      a,20h                                          ;#4522: 3E 20
        add     a,c                                            ;#4524: 81
        ld      c,a                                            ;#4525: 4F
        ; C stores the row (times 32), increment D if carry.
        jr      nc,WRITE_VRAM_TILES_NEXT                       ;#4526: 30 01
        inc     d                                              ;#4528: 14
WRITE_VRAM_TILES_NEXT:
        ; Compute DE and set next VRAM write address
        ld      a,c                                            ;#4529: 79
        add     a,b                                            ;#452A: 80
        sub     0E0h                                           ;#452B: D6 E0
        ; E has row * 32 + column.
        ld      e,a                                            ;#452D: 5F
        call    SET_VDP                                        ;#452E: CD B7 48
WRITE_VRAM_TILES_LOOP:
        ; Emit data bytes until next control/terminator
        ; Format of this stream:
        ; - `00h`: terminator, returns.
        ; - `E0h-FFh`: control, change address.
        ; - `01h-DFh`: writes to VRAM sequentially.
        ld      a,(hl)                                         ;#4531: 7E
        or      a                                              ;#4532: B7
        ret     z                                              ;#4533: C8
        cp      0E0h                                           ;#4534: FE E0
        jr      nc,WRITE_VRAM_TILES_ADDRESS                    ;#4536: 30 E8
        inc     hl                                             ;#4538: 23
        exx                                                    ;#4539: D9
        out     (c),a                                          ;#453A: ED 79
        exx                                                    ;#453C: D9
        jr      WRITE_VRAM_TILES_LOOP                          ;#453D: 18 F2

DECOMPRESS_VRAM_INDIRECT:
        ; Standard entry (Addr in stream)
        ld      e,(hl)                                         ;#453F: 5E
        inc     hl                                             ;#4540: 23
        ld      d,(hl)                                         ;#4541: 56
        inc     hl                                             ;#4542: 23
DECOMPRESS_VRAM_DIRECT:
        ; Entry with Addr in DE (No Mirror)
        ld      c,0                                            ;#4543: 0E 00
        jr      DECOMPRESS_VRAM_SET_VDP                        ;#4545: 18 02

DECOMPRESS_VRAM_DIRECT_MIRROR:
        ; Entry with Addr in DE (Mirrored)
        ld      c,1                                            ;#4547: 0E 01
DECOMPRESS_VRAM_SET_VDP:
        ; Common SET_VDP entry for decompression
        call    SET_VDP                                        ;#4549: CD B7 48
DECOMPRESS_VRAM_DATA_ONLY:
        ; Data-only entry (No SET_VDP call)
        ld      a,(hl)                                         ;#454C: 7E
        inc     hl                                             ;#454D: 23
        or      a                                              ;#454E: B7
        jr      z,DECOMPRESS_VRAM_EXIT                         ;#454F: 28 20
        bit     7,a                                            ;#4551: CB 7F
        jr      nz,DECOMPRESS_VRAM_LITERAL                     ;#4553: 20 0E
        ld      b,a                                            ;#4555: 47
        call    READ_BYTE_WITH_OPTIONAL_MIRROR                 ;#4556: CD 73 45
DECOMPRESS_VRAM_RLE_LOOP:
        ; Loop for RLE decompression
        exx                                                    ;#4559: D9
        out     (c),a                                          ;#455A: ED 79
        exx                                                    ;#455C: D9
        push    hl                                             ;#455D: E5
        pop     hl                                             ;#455E: E1
        djnz    DECOMPRESS_VRAM_RLE_LOOP                       ;#455F: 10 F8
        jr      DECOMPRESS_VRAM_DATA_ONLY                      ;#4561: 18 E9

DECOMPRESS_VRAM_LITERAL:
        ; Handle literal byte sequence during decompression
        res     7,a                                            ;#4563: CB BF
        ld      b,a                                            ;#4565: 47
DECOMPRESS_VRAM_LIT_LOOP:
        ; Loop for literal decompression
        call    READ_BYTE_WITH_OPTIONAL_MIRROR                 ;#4566: CD 73 45
        exx                                                    ;#4569: D9
        out     (c),a                                          ;#456A: ED 79
        exx                                                    ;#456C: D9
        djnz    DECOMPRESS_VRAM_LIT_LOOP                       ;#456D: 10 F7
        jr      DECOMPRESS_VRAM_DATA_ONLY                      ;#456F: 18 DB

DECOMPRESS_VRAM_EXIT:
        ; Exit decompression routine
        ei                                                     ;#4571: FB
        ret                                                    ;#4572: C9

READ_BYTE_WITH_OPTIONAL_MIRROR:
        ; Reads (HL), inc HL, and reverses bits if bit 0 of C is set
        ld      a,(hl)                                         ;#4573: 7E
        inc     hl                                             ;#4574: 23
        bit     0,c                                            ;#4575: CB 41
        ret     z                                              ;#4577: C8
        push    bc                                             ;#4578: C5
        ld      b,8                                            ;#4579: 06 08
        ld      c,a                                            ;#457B: 4F
BIT_REV_LOOP:
        ; Bits reversal loop for mirror decompression
        rr      c                                              ;#457C: CB 19
        rla                                                    ;#457E: 17
        djnz    BIT_REV_LOOP                                   ;#457F: 10 FB
        pop     bc                                             ;#4581: C1
        ret                                                    ;#4582: C9

WRITE_VRAM_STREAM:
        ; Updates VRAM from a data stream with addresses and terminators
        ld      e,(hl)                                         ;#4583: 5E
        inc     hl                                             ;#4584: 23
        ld      d,(hl)                                         ;#4585: 56
        inc     hl                                             ;#4586: 23
WRITE_VRAM_STREAM_WITH_OFFSET:
        ; Adds DE to VRAM pointer before streaming
        ld      a,(hl)                                         ;#4587: 7E
        inc     hl                                             ;#4588: 23
        ld      b,a                                            ;#4589: 47
        inc     b                                              ;#458A: 04
        ret     z                                              ;#458B: C8
        inc     b                                              ;#458C: 04
        jr      z,WRITE_VRAM_STREAM                            ;#458D: 28 F4
        call    WRITE_VRAM_BYTE                                ;#458F: CD A5 48
        inc     de                                             ;#4592: 13
        jr      WRITE_VRAM_STREAM_WITH_OFFSET                  ;#4593: 18 F2

REPLICATE_4_BYTE_BLOCK:
        ; Replicate a 4-byte block in memory C times
        push    hl                                             ;#4595: E5
        ld      b,4                                            ;#4596: 06 04
REPLICATE_4_BYTE_LOOP:
        ; Loop to copy 4 bytes into destination
        ld      a,(hl)                                         ;#4598: 7E
        ld      (de),a                                         ;#4599: 12
        inc     hl                                             ;#459A: 23
        inc     de                                             ;#459B: 13
        djnz    REPLICATE_4_BYTE_LOOP                          ;#459C: 10 FA
        dec     c                                              ;#459E: 0D
        jr      z,CLEAR_SPRITES_VRAM_DONE                      ;#459F: 28 03
        pop     hl                                             ;#45A1: E1
        jr      REPLICATE_4_BYTE_BLOCK                         ;#45A2: 18 F1

CLEAR_SPRITES_VRAM_DONE:
        ; Wait animation tile write finished
        pop     bc                                             ;#45A4: C1
        ret                                                    ;#45A5: C9

CLEAR_SPRITES_AND_UPDATE_VRAM:
        ; Clears sprites and conditionally updates VRAM tiles during wait
        call    CLEAR_SPRITES                                  ;#45A6: CD DB 45
        ld      d,38h                                          ;#45A9: 16 38
        ld      hl,WAIT_TIMER                                  ;#45AB: 21 04 E0
        ld      b,18h                                          ;#45AE: 06 18
        bit     6,(hl)                                         ;#45B0: CB 76
        jr      nz,CLEAR_SAT_MIRROR_LOOP                       ;#45B2: 20 08
        ld      a,1Fh                                          ;#45B4: 3E 1F
        sub     (hl)                                           ;#45B6: 96
        ld      e,a                                            ;#45B7: 5F
        set     6,(hl)                                         ;#45B8: CB F6
        jr      CLEAR_SPRITES_VRAM_UPDATE                      ;#45BA: 18 05

CLEAR_SAT_MIRROR_LOOP:
        ; Loop clearing SAT_MIRROR
        res     6,(hl)                                         ;#45BC: CB B6
        dec     (hl)                                           ;#45BE: 35
        ret     m                                              ;#45BF: F8
        ld      e,(hl)                                         ;#45C0: 5E
CLEAR_SPRITES_VRAM_UPDATE:
        ; Select VRAM update offset for wait animation
        ld      a,(GAME_STATE)                                 ;#45C1: 3A 00 E0
        cp      0Ah                                            ;#45C4: FE 0A
        jr      c,CLEAR_SPRITES_VRAM_LOOP                      ;#45C6: 38 06
        ld      a,40h                                          ;#45C8: 3E 40
        add     a,e                                            ;#45CA: 83
        ld      e,a                                            ;#45CB: 5F
        dec     b                                              ;#45CC: 05
        dec     b                                              ;#45CD: 05
CLEAR_SPRITES_VRAM_LOOP:
        ; Loop writing wait animation tiles to VRAM
        xor     a                                              ;#45CE: AF
        call    WRITE_VRAM_BYTE                                ;#45CF: CD A5 48
        ld      a,20h                                          ;#45D2: 3E 20
        call    ADD_DE_A                                       ;#45D4: CD D8 48
        djnz    CLEAR_SPRITES_VRAM_LOOP                        ;#45D7: 10 F5
        xor     a                                              ;#45D9: AF
        ret                                                    ;#45DA: C9

CLEAR_SPRITES:
        ; Clears sprite attribute mirror in RAM and copies to VRAM
        ld      hl,SAT_MIRROR                                  ;#45DB: 21 50 E0
        push    hl                                             ;#45DE: E5
        ld      b,80h                                          ;#45DF: 06 80
CLEAR_SPRITE_ATTR_LOOP:
        ; Loop to zero sprite attribute mirror
        ld      (hl),0                                         ;#45E1: 36 00
        inc     hl                                             ;#45E3: 23
        djnz    CLEAR_SPRITE_ATTR_LOOP                         ;#45E4: 10 FB
        LOAD_SPRITE_ATTR de, 0, 0                              ;#45E6: 11 00 3B
        pop     hl                                             ;#45E9: E1
        ld      bc,80h                                         ;#45EA: 01 80 00
        jp      COPY_RAM_TO_VRAM                               ;#45ED: C3 C7 44

INIT_PSG_PORT_B:
        ; Initialize PSG Port B (Register 15)
        ld      e,8Fh                                          ;#45F0: 1E 8F
        ld      a,0Fh                                          ;#45F2: 3E 0F
        call    BIOS_WRTPSG                                    ;#45F4: CD 93 00
        ret                                                    ;#45F7: C9

READ_INPUT_EDGE:
        ; Detect new button presses (edge trigger)
        ld      a,(CUR_INPUT_KEYS)                             ;#45F8: 3A 09 E0
        ld      b,a                                            ;#45FB: 47
        ld      a,(PREV_INPUT_KEYS)                            ;#45FC: 3A 08 E0
        and     30h                                            ;#45FF: E6 30
        cpl                                                    ;#4601: 2F
        ld      c,a                                            ;#4602: 4F
        ld      a,b                                            ;#4603: 78
        and     30h                                            ;#4604: E6 30
        and     c                                              ;#4606: A1
        ret                                                    ;#4607: C9

ADD_SCORE:
        ; Add value in DE to current BCD score
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4608: 3A 02 E0
        add     a,a                                            ;#460B: 87
        ret     p                                              ;#460C: F0
        ld      hl,CURRENT_SCORE_BCD + BCD_LOW                 ;#460D: 21 43 E0
        ld      a,(hl)                                         ;#4610: 7E
        add     a,e                                            ;#4611: 83
        daa                                                    ;#4612: 27
        ld      (hl),a                                         ;#4613: 77
        ld      e,a                                            ;#4614: 5F
        inc     hl                                             ;#4615: 23
        ld      a,(hl)                                         ;#4616: 7E
        adc     a,d                                            ;#4617: 8A
        daa                                                    ;#4618: 27
        ld      (hl),a                                         ;#4619: 77
        ld      d,a                                            ;#461A: 57
        inc     hl                                             ;#461B: 23
        jr      nc,ADD_SCORE_DONE                              ;#461C: 30 14
        ld      a,(hl)                                         ;#461E: 7E
        adc     a,0                                            ;#461F: CE 00
        daa                                                    ;#4621: 27
        ld      (hl),a                                         ;#4622: 77
        jr      nc,ADD_SCORE_DONE                              ;#4623: 30 0D
        ld      bc,9999h ; Max score is 999999                 ;#4625: 01 99 99
        ld      (HI_SCORE_BCD + BCD_LOW),bc                    ;#4628: ED 43 40 E0
        ld      (HI_SCORE_BCD + BCD_MID),bc                    ;#462C: ED 43 41 E0
        jr      HUD_DRAW_HI_SCORE                              ;#4630: 18 72

ADD_SCORE_DONE:
        ; Score addition finished
        ld      a,(HI_SCORE_BCD + BCD_HIGH)                    ;#4632: 3A 42 E0
        ld      b,(hl)                                         ;#4635: 46
        sub     (hl)                                           ;#4636: 96
        jr      c,ADD_SCORE_CHECK_HI                           ;#4637: 38 09
        jr      nz,HUD_DRAW_SCORE                              ;#4639: 20 72
        ld      hl,(HI_SCORE_BCD + BCD_LOW)                    ;#463B: 2A 40 E0
        sbc     hl,de                                          ;#463E: ED 52
        jr      nc,HUD_DRAW_SCORE                              ;#4640: 30 6B
ADD_SCORE_CHECK_HI:
        ; Check if score is higher than record
        ld      (HI_SCORE_BCD + BCD_LOW),de                    ;#4642: ED 53 40 E0
        ld      a,b                                            ;#4646: 78
        ld      (HI_SCORE_BCD + BCD_HIGH),a                    ;#4647: 32 42 E0
        jr      HUD_DRAW_HI_SCORE                              ;#464A: 18 58

UPDATE_GAME_TIMER:
        ; Decrement stage timer once per second
        ld      a,(TIMER_ACTIVE_FLAG)                          ;#464C: 3A 33 E1
        or      a                                              ;#464F: B7
        ret     z                                              ;#4650: C8
        ld      hl,(REMANING_TIME_BCD)                         ;#4651: 2A E3 E0
        ld      a,h                                            ;#4654: 7C
        add     a,l                                            ;#4655: 85
        jr      nz,UPDATE_GAME_TIMER_DONE                      ;#4656: 20 05
        inc     a                                              ;#4658: 3C
        ld      (TIME_UP_FLAG),a                               ;#4659: 32 0C E0
        ret                                                    ;#465C: C9

UPDATE_GAME_TIMER_DONE:
        ; Timer update finished
        ld      a,(FRAME_COUNTER)                              ;#465D: 3A 03 E0
        and     3Fh                                            ;#4660: E6 3F
        ret     nz                                             ;#4662: C0
        ld      c,1                                            ;#4663: 0E 01
DECREMENT_DISTANCE:
        ; Decrement remaining distance BCD and refresh HUD
        ld      hl,REMANING_TIME_BCD                           ;#4665: 21 E3 E0
        ld      a,(hl)                                         ;#4668: 7E
        sub     1                                              ;#4669: D6 01
        daa                                                    ;#466B: 27
        ld      (hl),a                                         ;#466C: 77
        inc     hl                                             ;#466D: 23
        ld      a,(hl)                                         ;#466E: 7E
        jr      nc,DECREMENT_DISTANCE_DONE                     ;#466F: 30 04
        sub     1                                              ;#4671: D6 01
        daa                                                    ;#4673: 27
        ld      (hl),a                                         ;#4674: 77
DECREMENT_DISTANCE_DONE:
        ; Distance decrement finished
        dec     hl                                             ;#4675: 2B
        or      a                                              ;#4676: B7
        jr      nz,HUD_DRAW_DISTANCE                           ;#4677: 20 11
        ld      a,(hl)                                         ;#4679: 7E
        cp      11h                                            ;#467A: FE 11
        jr      nc,HUD_DRAW_DISTANCE                           ;#467C: 30 0C
        dec     c                                              ;#467E: 0D
        jr      nz,HUD_DRAW_DISTANCE                           ;#467F: 20 09
        push    af                                             ;#4681: F5
        push    hl                                             ;#4682: E5
        ld      a,ID_SOUND_DISTANCE_WARNING                    ;#4683: 3E 09
        call    PLAY_SOUND_SAFE                                ;#4685: CD 83 79
        pop     hl                                             ;#4688: E1
        pop     af                                             ;#4689: F1
HUD_DRAW_DISTANCE:
        ; Draw remaining distance (4 digits)
        ld      b,2                                            ;#468A: 06 02
        LOAD_NAME_TABLE de, 1, 7                               ;#468C: 11 27 38
        ld      hl,REMANING_TIME_HIGH                          ;#468F: 21 E4 E0
        jp      WRITE_BCD_TO_HUD                               ;#4692: C3 03 47

REFRESH_HUD:
        ; Redraw all HUD elements (Distance, HI_SCORE Stage, Time, Scores)
        ld      hl,HUD_STATIC_TEXT                             ;#4695: 21 56 57
        call    WRITE_VRAM_STREAM                              ;#4698: CD 83 45
        call    HUD_DRAW_DISTANCE                              ;#469B: CD 8A 46
        call    HUD_DRAW_STAGE_HI_SCORE                        ;#469E: CD F1 46
        call    HUD_DRAW_STAGE                                 ;#46A1: CD FB 46
HUD_DRAW_HI_SCORE:
        ; Setup for drawing high score after updates
        ld      hl,HI_SCORE_BCD + BCD_HIGH                     ;#46A4: 21 42 E0
        LOAD_NAME_TABLE de, 0, 15                              ;#46A7: 11 0F 38
        call    HUD_DRAW_6_DIGITS                              ;#46AA: CD B3 46
HUD_DRAW_SCORE:
        ; Entry point for HUD score drawing
        LOAD_NAME_TABLE de, 0, 5                               ;#46AD: 11 05 38
        ld      hl,CURRENT_SCORE_BCD + BCD_HIGH                ;#46B0: 21 45 E0
HUD_DRAW_6_DIGITS:
        ; Internal body for drawing 6-digit BCD values
        ld      b,3                                            ;#46B3: 06 03
        jr      WRITE_BCD_TO_HUD                               ;#46B5: 18 4C

UPDATE_STAGE_DISTANCE:
        ; Decrements stage distance counter
        ld      hl,DISTANCE_TICK_TIMER                         ;#46B7: 21 E9 E0
        dec     (hl)                                           ;#46BA: 35
        ret     nz                                             ;#46BB: C0
        ld      a,(PENGUIN_SPEED)                              ;#46BC: 3A 00 E1
        srl     a                                              ;#46BF: CB 3F
        dec     a                                              ;#46C1: 3D
        ld      (hl),a                                         ;#46C2: 77
        ld      hl,STAGE_DISTANCE_HIGH                         ;#46C3: 21 E6 E0
        ld      a,(hl)                                         ;#46C6: 7E
        dec     hl                                             ;#46C7: 2B
        or      (hl)                                           ;#46C8: B6
        jr      nz,DECREMENT_BCD_DIGITS                        ;#46C9: 20 05
        inc     a                                              ;#46CB: 3C
        ld      (STAGE_GOAL_FLAG),a                            ;#46CC: 32 0D E0
        ret                                                    ;#46CF: C9

DECREMENT_BCD_DIGITS:
        ; Loop drawing BCD digits
        ld      a,(hl)                                         ;#46D0: 7E
        sub     1                                              ;#46D1: D6 01
        daa                                                    ;#46D3: 27
        ld      (hl),a                                         ;#46D4: 77
        ld      c,a                                            ;#46D5: 4F
        inc     hl                                             ;#46D6: 23
        jr      nc,DECREMENT_BCD_DIGITS_DONE                   ;#46D7: 30 05
        ld      a,(hl)                                         ;#46D9: 7E
        sub     1                                              ;#46DA: D6 01
        daa                                                    ;#46DC: 27
        ld      (hl),a                                         ;#46DD: 77
DECREMENT_BCD_DIGITS_DONE:
        ; Digits drawing finished
        ld      a,c                                            ;#46DE: 79
        or      a                                              ;#46DF: B7
        jr      nz,UPDATE_STAGE_DISTANCE_NEXT                  ;#46E0: 20 0C
        or      (hl)                                           ;#46E2: B6
        jr      z,UPDATE_STAGE_DISTANCE_NEXT                   ;#46E3: 28 09
        ld      a,(hl)                                         ;#46E5: 7E
        and     3                                              ;#46E6: E6 03
        jr      nz,UPDATE_STAGE_DISTANCE_NEXT                  ;#46E8: 20 04
        inc     a                                              ;#46EA: 3C
        ld      (STAGE_SEGMENT_TIMER),a                        ;#46EB: 32 07 E1
UPDATE_STAGE_DISTANCE_NEXT:
        ; Continue distance update
        call    CHECK_DISTANCE_MILESTONE                       ;#46EE: CD A5 52
HUD_DRAW_STAGE_HI_SCORE:
        ; Draw stage HI_SCORE/current stage (4 digits)
        ld      b,2                                            ;#46F1: 06 02
        LOAD_NAME_TABLE de, 1, 15                              ;#46F3: 11 2F 38
        ld      hl,STAGE_DISTANCE_HIGH                         ;#46F6: 21 E6 E0
        jr      WRITE_BCD_TO_HUD                               ;#46F9: 18 08

HUD_DRAW_STAGE:
        ; Draw current stage number from CURRENT_VISIBLE_STAGE (1 BCD byte = 2 digits)
        LOAD_NAME_TABLE de, 0, 28                              ;#46FB: 11 1C 38
        ld      hl,CURRENT_VISIBLE_STAGE                       ;#46FE: 21 E0 E0
        ld      b,1                                            ;#4701: 06 01
WRITE_BCD_TO_HUD:
        ; Core routine to draw BCD bytes as digits to VRAM (dec hl, loop b times)
        ld      a,(hl)                                         ;#4703: 7E
        push    af                                             ;#4704: F5
        and     0Fh                                            ;#4705: E6 0F
        or      10h                                            ;#4707: F6 10
        ld      c,a                                            ;#4709: 4F
        pop     af                                             ;#470A: F1
        and     0F0h                                           ;#470B: E6 F0
        rra                                                    ;#470D: 1F
        rra                                                    ;#470E: 1F
        rra                                                    ;#470F: 1F
        rra                                                    ;#4710: 1F
        or      10h                                            ;#4711: F6 10
        call    WRITE_VRAM_BYTE                                ;#4713: CD A5 48
        inc     de                                             ;#4716: 13
        ld      a,c                                            ;#4717: 79
        call    WRITE_VRAM_BYTE                                ;#4718: CD A5 48
        dec     hl                                             ;#471B: 2B
        inc     de                                             ;#471C: 13
        djnz    WRITE_BCD_TO_HUD                               ;#471D: 10 E4
        ret                                                    ;#471F: C9

UPDATE_STAGE_SEQUENCE:
        ; Pick SEQUENCE_THRESHOLD and SEQUENCE_DATA_PTR for stage + progress
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4720: 3A E0 E0
        and     0Fh                                            ;#4723: E6 0F
        ld      hl,SEQUENCE_TIME_THRESHOLDS                    ;#4725: 21 62 47
        add     a,a                                            ;#4728: 87
        call    ADD_HL_A                                       ;#4729: CD D3 48
        ld      a,(STAGE_DISTANCE_HIGH)                        ;#472C: 3A E6 E0
        and     10h                                            ;#472F: E6 10
        jr      z,UPDATE_STAGE_SEQUENCE_PICK_SUBTASK           ;#4731: 28 01
        inc     hl                                             ;#4733: 23
UPDATE_STAGE_SEQUENCE_PICK_SUBTASK:
        ; Threshold picked; now pick subtask pointer from progress segment
        ld      a,(hl)                                         ;#4734: 7E
        ld      (SEQUENCE_THRESHOLD),a                         ;#4735: 32 8A E1
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4738: 3A E0 E0
        and     0Fh                                            ;#473B: E6 0F
        ld      hl,SEQUENCE_TASK_TABLE                         ;#473D: 21 9E 47
        add     a,a                                            ;#4740: 87
        call    ADD_HL_A                                       ;#4741: CD D3 48
        ld      e,(hl)                                         ;#4744: 5E
        inc     hl                                             ;#4745: 23
        ld      d,(hl)                                         ;#4746: 56
        ex      de,hl                                          ;#4747: EB
        ld      a,(STAGE_DISTANCE_HIGH)                        ;#4748: 3A E6 E0
        and     0FCh                                           ;#474B: E6 FC
        rrca                                                   ;#474D: 0F
        rrca                                                   ;#474E: 0F
        res     3,a                                            ;#474F: CB 9F
        cp      4                                              ;#4751: FE 04
        jr      c,UPDATE_STAGE_SEQUENCE_INDEX_READY            ;#4753: 38 01
        dec     a                                              ;#4755: 3D
UPDATE_STAGE_SEQUENCE_INDEX_READY:
        ; Progress index settled (with/without -1 adjustment); load subtask pointer
        add     a,a                                            ;#4756: 87
        call    ADD_HL_A                                       ;#4757: CD D3 48
        ld      e,(hl)                                         ;#475A: 5E
        inc     hl                                             ;#475B: 23
        ld      d,(hl)                                         ;#475C: 56
        ex      de,hl                                          ;#475D: EB
        ld      (SEQUENCE_DATA_PTR),hl                         ;#475E: 22 8B E1
        ret                                                    ;#4761: C9

SEQUENCE_TIME_THRESHOLDS:
        ; Sequence threshold table (per time digit, two variants)
        ; Format: FORMAT_SEQUENCE_THRESHOLDS
        ; - 10 pairs: [low_threshold, high_threshold] per time digit (0-9).
        THRESHOLD 80h, 0                                       ;#4762: 80 00
        THRESHOLD 0A0h, 0A0h                                   ;#4764: A0 A0
        THRESHOLD 50h, 50h                                     ;#4766: 50 50
        THRESHOLD 0E0h, 0E0h                                   ;#4768: E0 E0
        THRESHOLD 50h, 50h                                     ;#476A: 50 50
        THRESHOLD 0, 20h                                       ;#476C: 00 20
        THRESHOLD 0E0h, 0E0h                                   ;#476E: E0 E0
        THRESHOLD 20h, 20h                                     ;#4770: 20 20
        THRESHOLD 0, 0                                         ;#4772: 00 00
        THRESHOLD 0FFh, 0FFh                                   ;#4774: FF FF

SEQ_STREAM_FISH_JUMP:
        ; Sequence command stream for fish jump behavior
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_ITEM_PROP 1                                        ;#4776: 01
        SEQ_ITEM_PROP 5                                        ;#4777: 05
        SEQ_IDLE                                               ;#4778: FF
        SEQ_ITEM_PROP 0                                        ;#4779: 00
        SEQ_MOVE_STATE 2                                       ;#477A: 12
        SEQ_ITEM_PROP 5                                        ;#477B: 05
        SEQ_IDLE                                               ;#477C: FF
        SEQ_ITEM_PROP 0                                        ;#477D: 00

SEQ_STREAM_SEAL_MOVE:
        ; Sequence command stream for seal movement behavior
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_MOVE_STATE 1                                       ;#477E: 11
        SEQ_ITEM_PROP 1                                        ;#477F: 01
        SEQ_ITEM_PROP 0                                        ;#4780: 00
        SEQ_MOVE_STATE 2                                       ;#4781: 12
        SEQ_ITEM_PROP 0                                        ;#4782: 00
        SEQ_ITEM_PROP 1                                        ;#4783: 01
        SEQ_MOVE_STATE 2                                       ;#4784: 12
        SEQ_ITEM_PROP 0                                        ;#4785: 00

SEQ_STREAM_MIX_A:
        ; Sequence stream A: cycles item-prop entries 0,1,3,5 (mixed item types)
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_ITEM_PROP 0                                        ;#4786: 00
        SEQ_IDLE                                               ;#4787: FF
        SEQ_ITEM_PROP 3                                        ;#4788: 03
        SEQ_MOVE_STATE 1                                       ;#4789: 11
        SEQ_ITEM_PROP 1                                        ;#478A: 01
        SEQ_ITEM_PROP 5                                        ;#478B: 05
        SEQ_IDLE                                               ;#478C: FF
        SEQ_ITEM_PROP 3                                        ;#478D: 03

SEQ_STREAM_MIX_B:
        ; Sequence stream B: cycles item-prop entries 0,1,3 (no flag)
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_ITEM_PROP 0                                        ;#478E: 00
        SEQ_IDLE                                               ;#478F: FF
        SEQ_ITEM_PROP 3                                        ;#4790: 03
        SEQ_ITEM_PROP 3                                        ;#4791: 03
        SEQ_ITEM_PROP 0                                        ;#4792: 00
        SEQ_MOVE_STATE 1                                       ;#4793: 11
        SEQ_ITEM_PROP 1                                        ;#4794: 01
        SEQ_MOVE_STATE 2                                       ;#4795: 12

SEQ_STREAM_MIX_C:
        ; Sequence stream C: cycles item-prop entries 3,5 (no small holes)
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_ITEM_PROP 5                                        ;#4796: 05
        SEQ_IDLE                                               ;#4797: FF
        SEQ_ITEM_PROP 5                                        ;#4798: 05
        SEQ_IDLE                                               ;#4799: FF
        SEQ_ITEM_PROP 3                                        ;#479A: 03
        SEQ_MOVE_STATE 2                                       ;#479B: 12
        SEQ_ITEM_PROP 5                                        ;#479C: 05
        SEQ_IDLE                                               ;#479D: FF

SEQUENCE_TASK_TABLE:
        ; Subtask-table base per stage; indexed by CURRENT_VISIBLE_STAGE & 0Fh (BCD units)
        dw      SEQUENCE_SUB_TASK_TABLE_A + 0Eh ; stage 0      ;#479E: C0 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 1Ah ; stage 1      ;#47A0: CC 47
        dw      SEQUENCE_SUB_TASK_TABLE_A       ; stage 2      ;#47A2: B2 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 20h ; stage 3      ;#47A4: D2 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 0Eh ; stage 4      ;#47A6: C0 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 16h ; stage 5      ;#47A8: C8 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 20h ; stage 6      ;#47AA: D2 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 18h ; stage 7      ;#47AC: CA 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 1Ah ; stage 8      ;#47AE: CC 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 22h ; stage 9      ;#47B0: D4 47

SEQUENCE_SUB_TASK_TABLE_A:
        ; Combined sequence subtask list base
        ; Format: FORMAT_SEQUENCE_SUBTASK_TABLE
        ; - Entries point to SEQ_STREAM_* command streams.
        dw      SEQ_STREAM_MIX_B                               ;#47B2 8E 47
        dw      SEQ_STREAM_FISH_JUMP                           ;#47B4 76 47
        dw      SEQ_STREAM_MIX_B                               ;#47B6 8E 47
        dw      SEQ_STREAM_FISH_JUMP                           ;#47B8 76 47
        dw      SEQ_STREAM_MIX_C                               ;#47BA 96 47
        dw      SEQ_STREAM_MIX_A                               ;#47BC 86 47
        dw      SEQ_STREAM_FISH_JUMP                           ;#47BE 76 47
        dw      SEQ_STREAM_MIX_A                               ;#47C0 86 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47C2 7E 47
        dw      SEQ_STREAM_MIX_B                               ;#47C4 8E 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47C6 7E 47
        dw      SEQ_STREAM_FISH_JUMP                           ;#47C8 76 47
        dw      SEQ_STREAM_MIX_B                               ;#47CA 8E 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47CC 7E 47
        dw      SEQ_STREAM_MIX_A                               ;#47CE 86 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47D0 7E 47
        dw      SEQ_STREAM_MIX_C                               ;#47D2 96 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47D4 7E 47
        dw      SEQ_STREAM_MIX_C                               ;#47D6 96 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47D8 7E 47

CHECK_SEQUENCE_STATUS:
        ; Checks sequence flag and decrements timer
        ld      a,(SEQUENCE_ACTIVE)                            ;#47DA: 3A 8E E1
        rra                                                    ;#47DD: 1F
        ret     nc                                             ;#47DE: D0
        ld      hl,SEQUENCE_TIMER                              ;#47DF: 21 8F E1
        dec     (hl)                                           ;#47E2: 35
        jr      nz,START_SEQUENCE_CHECK_DONE                   ;#47E3: 20 04
        xor     a                                              ;#47E5: AF
        ld      (SEQUENCE_ACTIVE),a                            ;#47E6: 32 8E E1
START_SEQUENCE_CHECK_DONE:
        ; Sequence check finished
        ld      c,3                                            ;#47E9: 0E 03
        ret                                                    ;#47EB: C9

START_SEQUENCE_CHECK:
        ; Entry point for checking if a new periodic sequence (fish/seal) should start
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#47EC: 3A E0 E0
        and     0Fh                                            ;#47EF: E6 0F
        ld      hl,SEQUENCE_TIMER_TABLE                        ;#47F1: 21 14 48
        call    ADD_HL_A                                       ;#47F4: CD D3 48
        ld      de,(STAGE_DISTANCE_BCD)                        ;#47F7: ED 5B E5 E0
        ld      a,d                                            ;#47FB: 7A
        cp      4                                              ;#47FC: FE 04
        ret     c                                              ;#47FE: D8
        ld      a,e                                            ;#47FF: 7B
        or      a                                              ;#4800: B7
        ret     nz                                             ;#4801: C0
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4802: 3A E0 E0
        add     a,d                                            ;#4805: 82
        and     3                                              ;#4806: E6 03
        cp      2                                              ;#4808: FE 02
        ret     nz                                             ;#480A: C0
        inc     a                                              ;#480B: 3C
        ld      (SEQUENCE_ACTIVE),a                            ;#480C: 32 8E E1
        ld      a,(hl)                                         ;#480F: 7E
        ld      (SEQUENCE_TIMER),a                             ;#4810: 32 8F E1
        ret                                                    ;#4813: C9

SEQUENCE_TIMER_TABLE:
        ; Sequence timer lookup (per seconds digit)
        ; One byte per entry, 10 entries indexed by (CURRENT_VISIBLE_STAGE & 0Fh).
        ; `START_SEQUENCE_CHECK` loads the selected byte into `SEQUENCE_TIMER` when it
        ; decides to kick off a new periodic sequence (fish/seal). Values: 7, 2, 2, 3,
        ; 3, 4, 4, 5, 6, 6. (Not to be confused with SEQUENCE_TIME_THRESHOLDS,
        ; which really is 10 low/high pairs.)
        ; Format: FORMAT_SEQUENCE_TIMER_TABLE
        TIMER_VALUE 7                                          ;#4814: 07
        TIMER_VALUE 2                                          ;#4815: 02
        TIMER_VALUE 2                                          ;#4816: 02
        TIMER_VALUE 3                                          ;#4817: 03
        TIMER_VALUE 3                                          ;#4818: 03
        TIMER_VALUE 4                                          ;#4819: 04
        TIMER_VALUE 4                                          ;#481A: 04
        TIMER_VALUE 5                                          ;#481B: 05
        TIMER_VALUE 6                                          ;#481C: 06
        TIMER_VALUE 6                                          ;#481D: 06

INIT_TITLE_BACKGROUND:
        ; Initialize title background tiles for title flow
        call    INIT_ALL_VDP_PLANES                            ;#481E: CD 34 58
        LOAD_VRAM_ADDRESS de, 1080h                            ;#4821: 11 80 10
        ld      bc,180h                                        ;#4824: 01 80 01
        LOAD_VRAM_COLOR a, COLOR_CYAN, COLOR_TRANSPARENT       ;#4827: 3E 70
        call    FILL_VRAM                                      ;#4829: CD DC 44
        xor     a                                              ;#482C: AF
        ld      (VDP_TEMP_AREA),a                              ;#482D: 32 0A E0
        LOAD_NAME_TABLE de, 11, 6                              ;#4830: 11 66 39
        ld      bc,13h                                         ;#4833: 01 13 00
        jp      FILL_VRAM                                      ;#4836: C3 DC 44

TITLE_WINDOW_ANIMATION:
        ; Manages title window tile paging and animation
        ld      hl,VDP_TEMP_AREA                               ;#4839: 21 0A E0
        ld      a,(hl)                                         ;#483C: 7E
        inc     (hl)                                           ;#483D: 34
        cp      17h                                            ;#483E: FE 17
        jr      nc,DRAW_FLOATING_KONAMI_COPYRIGHT              ;#4840: 30 1C
        LOAD_NAME_TABLE de, 4, 5                               ;#4842: 11 85 38
        ld      c,a                                            ;#4845: 4F
        add     a,e                                            ;#4846: 83
        ld      e,a                                            ;#4847: 5F
        ld      a,c                                            ;#4848: 79
        add     a,a                                            ;#4849: 87
        add     a,0B2h                                         ;#484A: C6 B2
        ld      c,a                                            ;#484C: 4F
        ld      b,3                                            ;#484D: 06 03
        xor     a                                              ;#484F: AF
TITLE_WINDOW_ANIMATION_LOOP:
        ; Loop writing title window tiles to VRAM
        call    WRITE_VRAM_BYTE                                ;#4850: CD A5 48
        ld      a,20h                                          ;#4853: 3E 20
        call    ADD_DE_A                                       ;#4855: CD D8 48
        ld      a,c                                            ;#4858: 79
        inc     c                                              ;#4859: 0C
        djnz    TITLE_WINDOW_ANIMATION_LOOP                    ;#485A: 10 F4
        scf                                                    ;#485C: 37
        ret                                                    ;#485D: C9

DRAW_FLOATING_KONAMI_COPYRIGHT:
        ; Loop updating opening animation
        push    af                                             ;#485E: F5
        ld      hl,KONAMI_COPYRIGHT_TEXT                       ;#485F: 21 85 57
        call    WRITE_VRAM_STREAM                              ;#4862: CD 83 45
        pop     af                                             ;#4865: F1
        cp      34h                                            ;#4866: FE 34
        ret     c                                              ;#4868: D8
        or      a                                              ;#4869: B7
        ret                                                    ;#486A: C9

KONAMI_OPENING_ANIMATION:
        ; Updates VRAM row pointer and writes 3 tiles for Konami logo
        ld      hl,(KONAMI_LOGO_ROW_PTR)                       ;#486B: 2A 0E E0
        ld      de,20h                                         ;#486E: 11 20 00
        add     hl,de                                          ;#4871: 19
        ld      (KONAMI_LOGO_ROW_PTR),hl                       ;#4872: 22 0E E0
        ex      de,hl                                          ;#4875: EB
        or      a                                              ;#4876: B7
        LOAD_NAME_TABLE hl, 21, 10                             ;#4877: 21 AA 3A
        sbc     hl,de                                          ;#487A: ED 52
        ex      de,hl                                          ;#487C: EB
        ; Konami logo starts at tile 44h.
        ld      a,44h                                          ;#487D: 3E 44
        ; c = Konami logo is 3 rows height.
        ; b = First line is 3 cols width.
        ld      bc,303h                                        ;#487F: 01 03 03
KONAMI_LOGO_WRITE_DONE:
        ; logo tile write finished
        push    de                                             ;#4882: D5
KONAMI_LOGO_WRITE_LOOP:
        ; Loop writing Konami logo tiles
        call    WRITE_VRAM_BYTE                                ;#4883: CD A5 48
        inc     de                                             ;#4886: 13
        inc     a                                              ;#4887: 3C
        djnz    KONAMI_LOGO_WRITE_LOOP                         ;#4888: 10 F9
        pop     de                                             ;#488A: D1
        ld      hl,20h                                         ;#488B: 21 20 00
        add     hl,de                                          ;#488E: 19
        ex      de,hl                                          ;#488F: EB
        ld      h,a                                            ;#4890: 67
        ; Remaining logo lines are 14 cols width.
        ld      a,0Eh                                          ;#4891: 3E 0E
        sub     c                                              ;#4893: 91
        ld      b,a                                            ;#4894: 47
        ld      a,h                                            ;#4895: 7C
        dec     c                                              ;#4896: 0D
        jr      nz,KONAMI_LOGO_WRITE_DONE                      ;#4897: 20 E9
        ld      bc,0Ch                                         ;#4899: 01 0C 00
        xor     a                                              ;#489C: AF
        call    FILL_VRAM                                      ;#489D: CD DC 44
        ld      hl,VDP_TEMP_AREA                               ;#48A0: 21 0A E0
        dec     (hl)                                           ;#48A3: 35
        ret                                                    ;#48A4: C9

WRITE_VRAM_BYTE:
        ; Writes single byte in A to VRAM at current address
        call    SET_VDP                                        ;#48A5: CD B7 48
        exx                                                    ;#48A8: D9
        out     (c),a                                          ;#48A9: ED 79
        exx                                                    ;#48AB: D9
        ei                                                     ;#48AC: FB
        ret                                                    ;#48AD: C9

READ_VRAM_BYTE:
        ; Reads single byte from VRAM into A
        call    SET_VDP_READ                                   ;#48AE: CD C6 48
        exx                                                    ;#48B1: D9
        in      a,(c)                                          ;#48B2: ED 78
        exx                                                    ;#48B4: D9
        ei                                                     ;#48B5: FB
        ret                                                    ;#48B6: C9

SET_VDP:
        ; Set VDP address
        ex      af,af'                                         ;#48B7: 08
        ex      de,hl                                          ;#48B8: EB
        call    BIOS_SETWRT                                    ;#48B9: CD 53 00
        di                                                     ;#48BC: F3
        ex      de,hl                                          ;#48BD: EB
        exx                                                    ;#48BE: D9
        ld      a,(BIOS_VDP_98)                                ;#48BF: 3A 06 00
        ld      c,a                                            ;#48C2: 4F
        exx                                                    ;#48C3: D9
        ex      af,af'                                         ;#48C4: 08
        ret                                                    ;#48C5: C9

SET_VDP_READ:
        ; Set VDP address for read (BIOS_SETRD variant)
        ex      de,hl                                          ;#48C6: EB
        call    BIOS_SETRD                                     ;#48C7: CD 50 00
        di                                                     ;#48CA: F3
        ex      de,hl                                          ;#48CB: EB
        exx                                                    ;#48CC: D9
        ld      a,(BIOS_VDP_99)                                ;#48CD: 3A 07 00
        ld      c,a                                            ;#48D0: 4F
        exx                                                    ;#48D1: D9
        ret                                                    ;#48D2: C9

ADD_HL_A:
        ; HL = HL + A
        add     a,l                                            ;#48D3: 85
        ld      l,a                                            ;#48D4: 6F
        ret     nc                                             ;#48D5: D0
        inc     h                                              ;#48D6: 24
        ret                                                    ;#48D7: C9

ADD_DE_A:
        ; DE = DE + A
        add     a,e                                            ;#48D8: 83
        ld      e,a                                            ;#48D9: 5F
        ret     nc                                             ;#48DA: D0
        inc     d                                              ;#48DB: 14
        ret                                                    ;#48DC: C9

GAME_STATE_15_HANDLER:
        ; Game state 15: Antarctic map animation
        ld      a,(GAME_SUBSTATE)                              ;#48DD: 3A 01 E0
        call    JUMP_TABLE_DISPATCHER                          ;#48E0: CD 9A 40
        dw      MAP_INIT                                       ;#48E3: F1 48
        dw      MAP_DRAW_HORIZONTAL_BORDER_TOP                 ;#48E5: 0B 49
        dw      MAP_DRAW_TILES                                 ;#48E7: 12 49
        dw      MAP_DRAW_HORIZONTAL_BORDER_BOTTOM              ;#48E9: 49 49
        dw      MAP_PATH_INIT                                  ;#48EB: 65 49
        dw      MAP_UPDATE_PATH                                ;#48ED: 72 49
        dw      MAP_EXIT_WAIT                                  ;#48EF: C9 49

MAP_INIT:
        ; Substate 0: Initialize map pointers and background fill
        ld      hl,MAP_DRAW_COMMANDS_TABLE                     ;#48F1: 21 D6 49
        ld      (MAP_DATA_PTR),hl                              ;#48F4: 22 F2 E0
        LOAD_NAME_TABLE hl, 4, 4                               ;#48F7: 21 84 38
        ld      (MAP_VRAM_ADDR),hl                             ;#48FA: 22 F0 E0
        LOAD_VRAM_ADDRESS de, 1080h                            ;#48FD: 11 80 10
        ld      bc,180h                                        ;#4900: 01 80 01
        LOAD_VRAM_COLOR a, COLOR_WHITE, COLOR_DARK_BLUE        ;#4903: 3E F4
        call    FILL_VRAM                                      ;#4905: CD DC 44
        jp      INCREMENT_SUBSTATE                             ;#4908: C3 FC 43

MAP_DRAW_HORIZONTAL_BORDER_TOP:
        ; Substate 1: Draw first part of UI borders
        LOAD_NAME_TABLE de, 4, 3                               ;#490B: 11 83 38
        ld      a,92h                                          ;#490E: 3E 92
        jr      MAP_DRAW_HORIZONTAL_BORDER_DIRECT              ;#4910: 18 3C

MAP_DRAW_TILES:
        ; Substate 2: Incremental map rendering from data stream
        ld      a,(FRAME_COUNTER)                              ;#4912: 3A 03 E0
        rra                                                    ;#4915: 1F
        ret     c                                              ;#4916: D8
        ld      hl,(MAP_VRAM_ADDR)                             ;#4917: 2A F0 E0
        ld      a,20h                                          ;#491A: 3E 20
        call    ADD_HL_A                                       ;#491C: CD D3 48
        ld      (MAP_VRAM_ADDR),hl                             ;#491F: 22 F0 E0
        ex      de,hl                                          ;#4922: EB
        push    de                                             ;#4923: D5
        ld      a,0Ah                                          ;#4924: 3E 0A
        ld      bc,18h                                         ;#4926: 01 18 00
        call    FILL_VRAM                                      ;#4929: CD DC 44
        pop     de                                             ;#492C: D1
        inc     de                                             ;#492D: 13
        ld      a,4                                            ;#492E: 3E 04
        ld      c,16h                                          ;#4930: 0E 16
        call    FILL_VRAM                                      ;#4932: CD DC 44
        ld      hl,(MAP_DATA_PTR)                              ;#4935: 2A F2 E0
        ld      a,(hl)                                         ;#4938: 7E
        inc     hl                                             ;#4939: 23
        or      a                                              ;#493A: B7
        jp      z,INCREMENT_SUBSTATE                           ;#493B: CA FC 43
        ld      e,a                                            ;#493E: 5F
        inc     a                                              ;#493F: 3C
        jr      z,MAP_DRAW_UPDATE_PTR                          ;#4940: 28 03
        call    WRITE_VRAM_STREAM_WITH_OFFSET                  ;#4942: CD 87 45
MAP_DRAW_UPDATE_PTR:
        ; Save map data pointer
        ld      (MAP_DATA_PTR),hl                              ;#4945: 22 F2 E0
        ret                                                    ;#4948: C9

MAP_DRAW_HORIZONTAL_BORDER_BOTTOM:
        ; Substate 3: Draw second part of UI borders
        LOAD_NAME_TABLE de, 21, 3                              ;#4949: 11 A3 3A
        ld      a,91h                                          ;#494C: 3E 91
MAP_DRAW_HORIZONTAL_BORDER_DIRECT:
        ; Shared horizontal border drawing routine for map UI
        call    WRITE_VRAM_BYTE                                ;#494E: CD A5 48
        inc     de                                             ;#4951: 13
        ld      bc,18h                                         ;#4952: 01 18 00
        add     a,4                                            ;#4955: C6 04
        push    af                                             ;#4957: F5
        call    FILL_VRAM                                      ;#4958: CD DC 44
        pop     af                                             ;#495B: F1
        sub     2                                              ;#495C: D6 02
        exx                                                    ;#495E: D9
        out     (c),a                                          ;#495F: ED 79
        exx                                                    ;#4961: D9
        jp      INCREMENT_SUBSTATE                             ;#4962: C3 FC 43

MAP_PATH_INIT:
        ; Substate 4: Initialize path pointers and step index
        LOAD_NAME_TABLE hl, 8, 19                              ;#4965: 21 13 39
        ld      (PATH_VRAM_PTR),hl                             ;#4968: 22 F4 E0
        xor     a                                              ;#496B: AF
        ld      (MAP_STEP_INDEX),a                             ;#496C: 32 F6 E0
        jp      INCREMENT_SUBSTATE                             ;#496F: C3 FC 43

MAP_UPDATE_PATH:
        ; Move penguin icon along path tracking indices
        ld      a,(FRAME_COUNTER)                              ;#4972: 3A 03 E0
        rra                                                    ;#4975: 1F
        ret     c                                              ;#4976: D8
        ld      hl,MAP_STEP_INDEX                              ;#4977: 21 F6 E0
        ld      a,(hl)                                         ;#497A: 7E
        ld      de,MAP_PATH_DATA                               ;#497B: 11 85 4A
        call    ADD_DE_A                                       ;#497E: CD D8 48
        ld      a,(de)                                         ;#4981: 1A
        ld      (VRAM_UPDATE_BUFFER),a                         ;#4982: 32 D0 E0
        cp      20h                                            ;#4985: FE 20
        jp      z,INCREMENT_SUBSTATE                           ;#4987: CA FC 43
        inc     (hl)                                           ;#498A: 34
        ld      c,97h                                          ;#498B: 0E 97
        ld      a,(MAP_PROGRESS_LIMIT)                         ;#498D: 3A E7 E0
        cp      (hl)                                           ;#4990: BE
        jr      c,MAP_UPDATE_PATH_PROCESS                      ;#4991: 38 02
        ld      c,0A4h                                         ;#4993: 0E A4
MAP_UPDATE_PATH_PROCESS:
        ; Process penguin path movement
        ld      hl,VRAM_UPDATE_BUFFER                          ;#4995: 21 D0 E0
        xor     a                                              ;#4998: AF
        rrd                                                    ;#4999: ED 67
        ld      b,a                                            ;#499B: 47
        ld      a,(hl)                                         ;#499C: 7E
        ld      hl,MAP_PATH_MOVEMENT_TABLE                     ;#499D: 21 B6 49
        call    ADD_HL_A                                       ;#49A0: CD D3 48
        ld      de,(PATH_VRAM_PTR)                             ;#49A3: ED 5B F4 E0
        call    JUMP_TO_HL                                     ;#49A7: CD B5 49
        ld      (PATH_VRAM_PTR),de                             ;#49AA: ED 53 F4 E0
        ld      a,b                                            ;#49AE: 78
        add     a,c                                            ;#49AF: 81
        call    WRITE_VRAM_BYTE                                ;#49B0: CD A5 48
        scf                                                    ;#49B3: 37
        ret                                                    ;#49B4: C9

JUMP_TO_HL:
        ; Generic jump via HL helper
        jp      (hl)                                           ;#49B5: E9

MAP_PATH_MOVEMENT_TABLE:
        ; Table of VRAM update handlers for penguin path icon
        ; Indexed-jump dispatch table — NOT unreachable code.
        ; Reached via MAP_PATH_MOVEMENT_TABLE + (high-nibble * 4) of
        ; the MAP_PATH_DATA step byte.
        ld      a,-20h ; UP                                    ;#49B6: 3E E0
        jr      MAP_MOVE_ADJUST_HIGH_BYTE                      ;#49B8: 18 0A
        ld      a,1 ; RIGHT                                    ;#49BA: 3E 01
        jr      MAP_MOVE_ADD_OFFSET                            ;#49BC: 18 07
        ld      a,20h ; DOWN                                   ;#49BE: 3E 20
        jr      MAP_MOVE_ADD_OFFSET                            ;#49C0: 18 03
        ld      a,-1 ; LEFT                                    ;#49C2: 3E FF

MAP_MOVE_ADJUST_HIGH_BYTE:
        ; Adjust high byte for negative offset
        dec     d                                              ;#49C4: 15
MAP_MOVE_ADD_OFFSET:
        ; Add offset to VRAM pointer
        call    ADD_DE_A                                       ;#49C5: CD D8 48
        ret                                                    ;#49C8: C9

MAP_EXIT_WAIT:
        ; Substate 6: Transition delay before state 9
        ld      hl,WAIT_TIMER                                  ;#49C9: 21 04 E0
        dec     (hl)                                           ;#49CC: 35
        ret     nz                                             ;#49CD: C0
        ld      a,ID_STATE_9                                   ;#49CE: 3E 09
        ld      (GAME_STATE),a                                 ;#49D0: 32 00 E0
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#49D3: C3 E9 43

MAP_DRAW_COMMANDS_TABLE:
        ; Data block for map drawing VRAM commands
        ; Format: FORMAT_MAP_DRAW_COMMANDS
        ; - Script for drawing the world map screen.
        ; - Each entry: [offset, byte stream..., 0FFh]; offset advances row VRAM ptr (DE).
        ; - Bytes in the stream are written sequentially to VRAM, advancing DE each byte.
        ; - 0FFh terminates the current entry; 00h terminates the whole table.
        db      0FFh                                           ;#49D6: FF
        MAP_COMMANDS 0CEh, "5E5F6061", 0FFh                    ;#49D7: CE 5E 5F 60 61 FF
        MAP_COMMANDS 0EDh, "620F0F0F0F0F636465", 0FFh          ;#49DD: ED 62 0F 0F 0F 0F 0F 63 64 65 FF
        MAP_COMMANDS 8, "6604040404670F0F0F0F0F0F0F68", 0FFh   ;#49E8: 08 66 04 04 04 04 67 0F 0F 0F 0F 0F 0F 0F 68 FF
        MAP_COMMANDS 28h, "696A6488897E0F0F0F0F0F0F0F6B", 0FFh  ;#49F8: 28 69 6A 64 88 89 7E 0F 0F 0F 0F 0F 0F 0F 6B FF
        MAP_COMMANDS 49h, "6C6D7F07800F0F0F0F0F0F0F61", 0FFh   ;#4A08: 49 6C 6D 7F 07 80 0F 0F 0F 0F 0F 0F 0F 61 FF
        MAP_COMMANDS 6Ah, "6781820F0F0F8D8E8F900F0F6E", 0FFh   ;#4A17: 6A 67 81 82 0F 0F 0F 8D 8E 8F 90 0F 0F 6E FF
        MAP_COMMANDS 8Ah, "6F0F0F0F0F0F8C0F0F0F0F0F70", 0FFh   ;#4A26: 8A 6F 0F 0F 0F 0F 0F 8C 0F 0F 0F 0F 0F 70 FF
        MAP_COMMANDS 0ABh, "710F0F83840F0F0F0F0F0F72", 0FFh    ;#4A35: AB 71 0F 0F 83 84 0F 0F 0F 0F 0F 0F 72 FF
        MAP_COMMANDS 0CBh, "730F0F8507860F0F0F0F0F74", 0FFh    ;#4A43: CB 73 0F 0F 85 07 86 0F 0F 0F 0F 0F 74 FF
        MAP_COMMANDS 0EBh, "6975768A8B870F0F0F0F77", 0FFh      ;#4A51: EB 69 75 76 8A 8B 87 0F 0F 0F 0F 77 FF
        MAP_COMMANDS 10h, "780F0F0F0F79", 0FFh                 ;#4A5E: 10 78 0F 0F 0F 0F 79 FF
        MAP_COMMANDS 30h, "7A757B7C7D", 0FFh                   ;#4A66: 30 7A 75 7B 7C 7D FF
        db      0FFh                                           ;#4A6D: FF
        MAP_COMMANDS 67h, "212E34213223342923210404041A1B1C1D1E1F", 0FFh  ;#4A6E: 67 21 2E 34 21 32 23 34 29 23 21 04 04 04 1A 1B 1C 1D 1E 1F FF
        db      0FFh                                           ;#4A83: FF
        db      00h                                            ;#4A84: 00

MAP_PATH_DATA:
        ; Data block defining the penguin route coordinates and tile steps
        ; Format: FORMAT_MAP_PATH_DATA
        ; - Each byte is MAP_DIR_* (high nibble 0/4/8/Ch = UP/RIGHT/DOWN/LEFT) OR'd with
        ; a tile index (low nibble 0..Fh).
        ; - MAP_UPDATE_PATH consumes one byte per odd frame: the high nibble indexes
        ; MAP_PATH_MOVEMENT_TABLE to move PATH_VRAM_PTR, and the low nibble is added
        ; to a tile base (97h before MAP_PROGRESS_LIMIT, A4h after) for the VRAM write.
        ; - 20h terminates the path (MAP_UPDATE_PATH leaves the substate).
        MAP_STEP MAP_DIR_RIGHT, 2                              ;#4A85: 42
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4A86: 82
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4A87: 82
        MAP_STEP MAP_DIR_DOWN, 5                               ;#4A88: 85
        MAP_STEP MAP_DIR_RIGHT, 0Bh                            ;#4A89: 4B
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4A8A: 82
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4A8B: 82
        MAP_STEP MAP_DIR_DOWN, 0Bh                             ;#4A8C: 8B
        MAP_STEP MAP_DIR_LEFT, 4                               ;#4A8D: C4
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4A8E: 82
        MAP_STEP MAP_DIR_DOWN, 0Bh                             ;#4A8F: 8B
        MAP_STEP MAP_DIR_LEFT, 4                               ;#4A90: C4
        MAP_STEP MAP_DIR_LEFT, 4                               ;#4A91: C4
        MAP_STEP MAP_DIR_LEFT, 0                               ;#4A92: C0
        MAP_STEP MAP_DIR_UP, 0Bh                               ;#4A93: 0B
        MAP_STEP MAP_DIR_UP, 2                                 ;#4A94: 02
        MAP_STEP MAP_DIR_UP, 2                                 ;#4A95: 02
        MAP_STEP MAP_DIR_LEFT, 5                               ;#4A96: C5
        MAP_STEP MAP_DIR_UP, 0Ch                               ;#4A97: 0C
        MAP_STEP MAP_DIR_LEFT, 5                               ;#4A98: C5
        MAP_STEP MAP_DIR_LEFT, 5                               ;#4A99: C5
        MAP_STEP MAP_DIR_LEFT, 6                               ;#4A9A: C6
        MAP_STEP MAP_DIR_DOWN, 6                               ;#4A9B: 86
        MAP_STEP MAP_DIR_DOWN, 7                               ;#4A9C: 87
        MAP_STEP MAP_DIR_LEFT, 5                               ;#4A9D: C5
        MAP_STEP MAP_DIR_UP, 2                                 ;#4A9E: 02
        MAP_STEP MAP_DIR_UP, 0Ch                               ;#4A9F: 0C
        MAP_STEP MAP_DIR_UP, 0Ah                               ;#4AA0: 0A
        MAP_STEP MAP_DIR_UP, 9                                 ;#4AA1: 09
        MAP_STEP MAP_DIR_RIGHT, 8                              ;#4AA2: 48
        MAP_STEP MAP_DIR_RIGHT, 3                              ;#4AA3: 43
        MAP_STEP MAP_DIR_UP, 0Ch                               ;#4AA4: 0C
        MAP_STEP MAP_DIR_UP, 0Ch                               ;#4AA5: 0C
        MAP_STEP MAP_DIR_UP, 1                                 ;#4AA6: 01
        MAP_STEP MAP_DIR_RIGHT, 5                              ;#4AA7: 45
        MAP_STEP MAP_DIR_RIGHT, 5                              ;#4AA8: 45
        MAP_STEP MAP_DIR_RIGHT, 5                              ;#4AA9: 45
        MAP_STEP MAP_DIR_RIGHT, 2                              ;#4AAA: 42
        MAP_STEP MAP_DIR_DOWN, 5                               ;#4AAB: 85
        MAP_STEP MAP_DIR_RIGHT, 7                              ;#4AAC: 47
        MAP_END                                                ;#4AAD: 20

STAGE_DISTANCE_TABLE:
        ; Data table for stage distances and difficulty settings
        ; Format: FORMAT_STAGE_DISTANCE_TABLE
        ; - 10 entries. Each STAGE_ENTRY writes dist_hi (byte 0), map_offset (byte 1),
        ; and initial timer value (bytes 2-3, little-endian).
        ; - Consumed by stage-init code to set the total distance (dist_hi << 8),
        ; the starting offset into MAP_PATH_DATA, and the initial stage timer.
        STAGE_ENTRY 1200h, 0, 90h                              ;#4AAE: 12 00 90 00
        STAGE_ENTRY 1500h, 5, 100h                             ;#4AB2: 15 05 00 01
        STAGE_ENTRY 1200h, 8, 90h                              ;#4AB6: 12 08 90 00
        STAGE_ENTRY 1500h, 0Bh, 100h                           ;#4ABA: 15 0B 00 01
        STAGE_ENTRY 1700h, 0Eh, 120h                           ;#4ABE: 17 0E 20 01
        STAGE_ENTRY 1100h, 13h, 80h                            ;#4AC2: 11 13 80 00
        STAGE_ENTRY 1200h, 17h, 80h                            ;#4AC6: 12 17 80 00
        STAGE_ENTRY 1200h, 1Bh, 80h                            ;#4ACA: 12 1B 80 00
        STAGE_ENTRY 500h, 20h, 40h                             ;#4ACE: 05 20 40 00
        STAGE_ENTRY 2600h, 21h, 165h                           ;#4AD2: 26 21 65 01

INIT_GAMEPLAY_VARS:
        ; Initialize gameplay variables and RAM (clears E0F0-E220, sets timers)
        ld      hl,MAP_VRAM_ADDR                               ;#4AD6: 21 F0 E0
        ld      de,MAP_VRAM_ADDR+1                             ;#4AD9: 11 F1 E0
        ld      bc,130h                                        ;#4ADC: 01 30 01
        ld      (hl),0                                         ;#4ADF: 36 00
        ldir                                                   ;#4AE1: ED B0
        ld      a,10h                                          ;#4AE3: 3E 10
        ld      h,a                                            ;#4AE5: 67
        ld      l,a                                            ;#4AE6: 6F
        ld      (PENGUIN_SPEED),hl                             ;#4AE7: 22 00 E1
        ld      (STAGE_TIMER_VAL),a                            ;#4AEA: 32 10 E1
        ld      a,8                                            ;#4AED: 3E 08
        ld      (DEMO_PLAY_MASK_TIMER),a                       ;#4AEF: 32 49 E1
        ld      a,5                                            ;#4AF2: 3E 05
        ld      (DISTANCE_TICK_TIMER),a                        ;#4AF4: 32 E9 E0
        ld      hl,3030h                                       ;#4AF7: 21 30 30
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4AFA: 3A E0 E0
        rra                                                    ;#4AFD: 1F
        jr      nc,INIT_STAGE_GRAPHICS_SEQ                     ;#4AFE: 30 03
        ld      hl,3434h                                       ;#4B00: 21 34 34
INIT_STAGE_GRAPHICS_SEQ:
        ; Init stage graphics sequence
        ld      (ITEM_TICK_PERIOD),hl                          ;#4B03: 22 0E E1
        ld      a,1                                            ;#4B06: 3E 01
        ld      (SELECT_CONTROLLER_DISABLED),a                 ;#4B08: 32 3B E1
        call    GFX_INIT_BANK1                                 ;#4B0B: CD AC 5D
        call    GFX_INIT_BANK2                                 ;#4B0E: CD 49 62
        call    LOAD_MAIN_SPRITE_PATTERNS                      ;#4B11: CD 10 67
        call    INIT_SPRITES_FROM_STREAM                       ;#4B14: CD 7C 66
        call    INIT_STAGE                                     ;#4B17: CD 19 50
        xor     a                                              ;#4B1A: AF
        ld      (SELECT_CONTROLLER_DISABLED),a                 ;#4B1B: 32 3B E1
        ret                                                    ;#4B1E: C9

MAIN_GAME_ENGINE:
        ; Core game engine loop
        call    CALC_HUD_SPEED_BAR                             ;#4B1F: CD 24 77
        call    SYNC_SPRITE_ATTRIBUTES_PARTIAL                 ;#4B22: CD 25 76
        ld      a,(PENGUIN_FALL_TIMER)                         ;#4B25: 3A 40 E1
        or      a                                              ;#4B28: B7
        jp      nz,HANDLE_PENGUIN_FALL                         ;#4B29: C2 69 4F
        ld      a,(PENGUIN_STUN_TIMER)                         ;#4B2C: 3A 42 E1
        or      a                                              ;#4B2F: B7
        jp      nz,HANDLE_PENGUIN_STUN_ANIMATION               ;#4B30: C2 3E 4E
        call    PROCESS_PENGUIN_INPUT_AND_MOVE                 ;#4B33: CD 9A 76
        call    HANDLE_PENGUIN_MOVEMENT                        ;#4B36: CD 81 4B
        call    HANDLE_PENGUIN_DRIFT                           ;#4B39: CD 66 53
        call    HANDLE_COLLISION_FISH                          ;#4B3C: CD A7 4D
        call    HANDLE_COLLISION_SEAL                          ;#4B3F: CD E4 4D
        ld      a,(PENGUIN_FALL_TIMER)                         ;#4B42: 3A 40 E1
        or      a                                              ;#4B45: B7
        ret     nz                                             ;#4B46: C0
        call    PROCESS_SCENE_TIMER                            ;#4B47: CD 4F 51
        call    UPDATE_STATION_FRAME                           ;#4B4A: CD D3 74
        call    UPDATE_STAGE_DISTANCE                          ;#4B4D: CD B7 46
        call    UPDATE_STAGE_SEQUENCE                          ;#4B50: CD 20 47
        call    UPDATE_ITEMS                                   ;#4B53: CD D7 51
        jp      HANDLE_DEMO_PLAY_MASKING                       ;#4B56: C3 5F 77

PENGUIN_ANIM_TABLE:
        ; Table of sprite pattern indices for penguin
        ; Format: FORMAT_PENGUIN_PATTERN
        ; - Layout: [Top-Left, Bottom-Left, Top-Right, Bottom-Right].
        ; - Used for the main penguin animations (waddling, jumping, etc.).
        PENGUIN_PATTERN 0, 4, 8, 0Ch                           ;#4B59: 00 04 08 0C
        PENGUIN_PATTERN 10h, 14h, 18h, 1Ch                     ;#4B5D: 10 14 18 1C
        PENGUIN_PATTERN 20h, 24h, 28h, 2Ch                     ;#4B61: 20 24 28 2C
        PENGUIN_PATTERN 0, 4, 30h, 34h                         ;#4B65: 00 04 30 34
        PENGUIN_PATTERN 38h, 3Ch, 40h, 44h                     ;#4B69: 38 3C 40 44
        PENGUIN_PATTERN 60h, 64h, 68h, 6Ch                     ;#4B6D: 60 64 68 6C
        PENGUIN_PATTERN 20h, 48h, 4Ch, 50h                     ;#4B71: 20 48 4C 50
        PENGUIN_PATTERN 54h, 14h, 58h, 5Ch                     ;#4B75: 54 14 58 5C
        PENGUIN_PATTERN 10h, 0A8h, 18h, 0ACh                   ;#4B79: 10 A8 18 AC
        PENGUIN_PATTERN 0B0h, 24h, 0B4h, 2Ch                   ;#4B7D: B0 24 B4 2C

HANDLE_PENGUIN_MOVEMENT:
        ; Handles joystick input and position updates
        ld      hl,PENGUIN_INPUT_LOCK_TIMER                    ;#4B81: 21 F9 E0
        ld      a,(hl)                                         ;#4B84: 7E
        or      a                                              ;#4B85: B7
        jp      nz,UPDATE_THROTTLED_ANIMATION                  ;#4B86: C2 ED 4B
        call    READ_INPUT_EDGE                                ;#4B89: CD F8 45
        jp      nz,INIT_JUMP                                   ;#4B8C: C2 D9 4B
        ld      a,b                                            ;#4B8F: 78
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4B90: ED 5B 78 E0
        call    UPDATE_PENGUIN_POSITION                        ;#4B94: CD 61 4C
SWAP_AND_UPDATE_PENGUIN_COORDS:
        ; Swap registers and update penguin coordinates
        ex      de,hl                                          ;#4B97: EB
UPDATE_PENGUIN_COORDS:
        ; Update penguin X/Y and secondary sprite positions
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#4B98: CD C1 4B
SYNC_PENGUIN_SPRITES_TO_VRAM:
        ; Prepare and upload penguin sprite attributes to VRAM
        ld      hl,SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y        ;#4B9B: 21 78 E0
        LOAD_SPRITE_ATTR de, 10, 0                             ;#4B9E: 11 28 3B
        ld      bc,10h                                         ;#4BA1: 01 10 00
        call    COPY_RAM_TO_VRAM                               ;#4BA4: CD C7 44
        jp      UPDATE_GOAL_BOB_ANIM                           ;#4BA7: C3 BE 4C

UPDATE_PENGUIN_SPRITE_PATTERNS:
        ; Updates the 4 pattern indices of the 32x32 penguin (SPRITE_PENGUIN..+0Ch)
        exx                                                    ;#4BAA: D9
        ld      hl,PENGUIN_ANIM_TABLE                          ;#4BAB: 21 59 4B
        call    ADD_HL_A                                       ;#4BAE: CD D3 48
        ld      de,SAT_MIRROR + SPRITE_PENGUIN + ATTR_PATT     ;#4BB1: 11 7A E0
        ld      b,4                                            ;#4BB4: 06 04
UPDATE_PENGUIN_PATT_LOOP:
        ; Loop to copy 4 pattern indices
        ld      a,(hl)                                         ;#4BB6: 7E
        ld      (de),a                                         ;#4BB7: 12
        ld      a,4                                            ;#4BB8: 3E 04
        add     a,e                                            ;#4BBA: 83
        ld      e,a                                            ;#4BBB: 5F
        inc     hl                                             ;#4BBC: 23
        djnz    UPDATE_PENGUIN_PATT_LOOP                       ;#4BBD: 10 F7
        exx                                                    ;#4BBF: D9
        ret                                                    ;#4BC0: C9

UPDATE_PENGUIN_MULTI_SPRITE_COORDS:
        ; Updates coordinates for 32x32 penguin (SAT slots 10-13, SPRITE_PENGUIN..+0Ch)
        ld      d,h                                            ;#4BC1: 54
        ld      (SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y),hl      ;#4BC2: 22 78 E0
        ld      a,h                                            ;#4BC5: 7C
        add     a,10h                                          ;#4BC6: C6 10
        ld      h,a                                            ;#4BC8: 67
        ld      (SAT_MIRROR + SPRITE_PENGUIN + 4 + ATTR_Y),hl  ;#4BC9: 22 7C E0
        ld      a,l                                            ;#4BCC: 7D
        add     a,10h                                          ;#4BCD: C6 10
        ld      l,a                                            ;#4BCF: 6F
        ld      e,a                                            ;#4BD0: 5F
        ld      (SAT_MIRROR + SPRITE_PENGUIN + 8 + ATTR_Y),de  ;#4BD1: ED 53 80 E0
        ld      (SAT_MIRROR + SPRITE_PENGUIN + 0Ch + ATTR_Y),hl ;#4BD5: 22 84 E0
        ret                                                    ;#4BD8: C9

INIT_JUMP:
        ; Initialize penguin jump sequence and sound
        ld      a,ID_SOUND_JUMP                                ;#4BD9: 3E 02
        call    PLAY_SOUND_SAFE                                ;#4BDB: CD 83 79
        ld      a,b                                            ;#4BDE: 78
        and     0Ch                                            ;#4BDF: E6 0C
        jr      z,SET_JUMP_DIR                                 ;#4BE1: 28 05
        ld      a,(PENGUIN_MOVE_STATE)                         ;#4BE3: 3A FA E0
        and     3                                              ;#4BE6: E6 03
SET_JUMP_DIR:
        ; Set jump direction based on move state
        ld      (PENGUIN_JUMP_STATE),a                         ;#4BE8: 32 FB E0
        jr      UPDATE_ANIMATION_STEP                          ;#4BEB: 18 06

UPDATE_THROTTLED_ANIMATION:
        ; Updates animation every 4th frame
        ld      a,(FRAME_COUNTER)                              ;#4BED: 3A 03 E0
        and     3                                              ;#4BF0: E6 03
        ret     nz                                             ;#4BF2: C0
UPDATE_ANIMATION_STEP:
        ; Increments animation frame and updates patterns/position
        ld      a,(hl)                                         ;#4BF3: 7E
        inc     (hl)                                           ;#4BF4: 34
        cp      0Bh                                            ;#4BF5: FE 0B
        jr      nz,CALC_ANIM_FRAME_INDEX                       ;#4BF7: 20 02
        ld      (hl),0                                         ;#4BF9: 36 00
CALC_ANIM_FRAME_INDEX:
        ; Calculate animation frame index
        push    af                                             ;#4BFB: F5
        ld      c,0                                            ;#4BFC: 0E 00
        cp      0Bh                                            ;#4BFE: FE 0B
        jr      z,SET_ANIM_PATTERN_INDEX                       ;#4C00: 28 07
        ld      c,10h                                          ;#4C02: 0E 10
        rra                                                    ;#4C04: 1F
        jr      c,SET_ANIM_PATTERN_INDEX                       ;#4C05: 38 02
        ld      c,0Ch                                          ;#4C07: 0E 0C
SET_ANIM_PATTERN_INDEX:
        ; Set calculated pattern index
        ld      a,c                                            ;#4C09: 79
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4C0A: CD AA 4B
        pop     af                                             ;#4C0D: F1
        ld      hl,PENGUIN_JUMP_Y_OFFSETS                      ;#4C0E: 21 55 4C
        call    ADD_HL_A                                       ;#4C11: CD D3 48
        ld      a,(hl)                                         ;#4C14: 7E
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4C15: ED 5B 78 E0
        add     a,e                                            ;#4C19: 83
        ld      e,a                                            ;#4C1A: 5F
        ld      hl,PENGUIN_JUMP_STATE                          ;#4C1B: 21 FB E0
        ld      a,(hl)                                         ;#4C1E: 7E
        dec     a                                              ;#4C1F: 3D
        jr      z,JUMP_MOVE_LEFT_STEP                          ;#4C20: 28 23
        dec     a                                              ;#4C22: 3D
        jr      z,JUMP_MOVE_RIGHT_STEP                         ;#4C23: 28 28
UPDATE_JUMP_SPRITES:
        ; Update sprite coordinates after jump
        ex      de,hl                                          ;#4C25: EB
        call    UPDATE_PENGUIN_COORDS                          ;#4C26: CD 98 4B
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4C29: 3A F9 E0
        or      a                                              ;#4C2C: B7
        ret     nz                                             ;#4C2D: C0
        call    CHECK_ITEM_COLLISIONS                          ;#4C2E: CD 1E 4D
        ld      a,(PENGUIN_FALL_TIMER)                         ;#4C31: 3A 40 E1
        ld      hl,PENGUIN_STUN_TIMER                          ;#4C34: 21 42 E1
        add     a,(hl)                                         ;#4C37: 86
        ret     nz                                             ;#4C38: C0
        ld      hl,COLLISION_PROCESSED_FLAG                    ;#4C39: 21 32 E1
        cp      (hl)                                           ;#4C3C: BE
        ret     z                                              ;#4C3D: C8
        ld      (hl),a                                         ;#4C3E: 77
        ld      de,30h                                         ;#4C3F: 11 30 00
        jp      ADD_SCORE                                      ;#4C42: C3 08 46

JUMP_MOVE_LEFT_STEP:
        ; Horizontal shift left during jump
        call    MOVE_PENGUIN_LEFT                              ;#4C45: CD 71 4C
        call    MOVE_PENGUIN_LEFT                              ;#4C48: CD 71 4C
        jr      UPDATE_JUMP_SPRITES                            ;#4C4B: 18 D8

JUMP_MOVE_RIGHT_STEP:
        ; Horizontal shift right during jump
        call    MOVE_PENGUIN_RIGHT                             ;#4C4D: CD 8E 4C
        call    MOVE_PENGUIN_RIGHT                             ;#4C50: CD 8E 4C
        jr      UPDATE_JUMP_SPRITES                            ;#4C53: 18 D0

PENGUIN_JUMP_Y_OFFSETS:
        ; Table of signed Y-offsets for jumping (12 bytes)
        ; Format: FORMAT_JUMP_Y_OFFSETS
        JUMP_Y_OFFSET -4                                       ;#4C55: FC
        JUMP_Y_OFFSET -3                                       ;#4C56: FD
        JUMP_Y_OFFSET -3                                       ;#4C57: FD
        JUMP_Y_OFFSET -2                                       ;#4C58: FE
        JUMP_Y_OFFSET -1                                       ;#4C59: FF
        JUMP_Y_OFFSET -1                                       ;#4C5A: FF
        JUMP_Y_OFFSET 1                                        ;#4C5B: 01
        JUMP_Y_OFFSET 1                                        ;#4C5C: 01
        JUMP_Y_OFFSET 2                                        ;#4C5D: 02
        JUMP_Y_OFFSET 3                                        ;#4C5E: 03
        JUMP_Y_OFFSET 3                                        ;#4C5F: 03
        JUMP_Y_OFFSET 4                                        ;#4C60: 04

UPDATE_PENGUIN_POSITION:
        ; Handle player input and update X coordinate
        and     0Ch                                            ;#4C61: E6 0C
        ret     z                                              ;#4C63: C8
        ld      hl,PENGUIN_MOVE_STATE                          ;#4C64: 21 FA E0
        cp      0Ch                                            ;#4C67: FE 0C
        jr      z,HANDLE_SIMULTANEOUS_LR                       ;#4C69: 28 10
        res     7,(hl)                                         ;#4C6B: CB BE
        cp      4                                              ;#4C6D: FE 04
        jr      nz,MOVE_PENGUIN_RIGHT                          ;#4C6F: 20 1D
MOVE_PENGUIN_LEFT:
        ; Updates X (in D) if > 20, sets direction flags
        ld      a,d                                            ;#4C71: 7A
        cp      14h                                            ;#4C72: FE 14
        ret     c                                              ;#4C74: D8
        dec     d                                              ;#4C75: 15
        set     0,(hl)                                         ;#4C76: CB C6
        res     1,(hl)                                         ;#4C78: CB 8E
        ret                                                    ;#4C7A: C9

HANDLE_SIMULTANEOUS_LR:
        ; Handle simultaneous Left/Right input
        ld      a,(hl)                                         ;#4C7B: 7E
        or      a                                              ;#4C7C: B7
        ret     z                                              ;#4C7D: C8
        bit     7,a                                            ;#4C7E: CB 7F
        jr      z,MAINTAIN_CURRENT_DIRECTION                   ;#4C80: 28 06
        bit     0,a                                            ;#4C82: CB 47
        jr      nz,MOVE_PENGUIN_LEFT                           ;#4C84: 20 EB
        jr      MOVE_PENGUIN_RIGHT                             ;#4C86: 18 06

MAINTAIN_CURRENT_DIRECTION:
        ; Maintain current direction flag
        set     7,(hl)                                         ;#4C88: CB FE
        bit     1,a                                            ;#4C8A: CB 4F
        jr      nz,MOVE_PENGUIN_LEFT                           ;#4C8C: 20 E3
MOVE_PENGUIN_RIGHT:
        ; Updates X (in D) if < 204, sets direction flags
        ld      a,d                                            ;#4C8E: 7A
        cp      0CCh                                           ;#4C8F: FE CC
        ret     nc                                             ;#4C91: D0
        set     1,(hl)                                         ;#4C92: CB CE
        res     0,(hl)                                         ;#4C94: CB 86
        inc     d                                              ;#4C96: 14
        ret                                                    ;#4C97: C9

UPDATE_PENGUIN_ANIMATION:
        ; Update penguin waddling animation
        ld      hl,PENGUIN_INPUT_LOCK_TIMER                    ;#4C98: 21 F9 E0
        ld      a,(PENGUIN_ANIM_HOLD_FLAG)                     ;#4C9B: 3A 30 E1
        or      (hl)                                           ;#4C9E: B6
        ret     nz                                             ;#4C9F: C0
        ld      a,(FRAME_COUNTER)                              ;#4CA0: 3A 03 E0
        and     7                                              ;#4CA3: E6 07
        ret     nz                                             ;#4CA5: C0
UPDATE_PENGUIN_SPRITES:
        ; General update for penguin sprites
        ld      hl,PENGUIN_ANIM_FRAME                          ;#4CA6: 21 F8 E0
        inc     (hl)                                           ;#4CA9: 34
        ld      a,(hl)                                         ;#4CAA: 7E
        ld      c,0                                            ;#4CAB: 0E 00
        rra                                                    ;#4CAD: 1F
        jr      nc,APPLY_WALK_ANIM_PATTERN                     ;#4CAE: 30 07
        ld      c,4                                            ;#4CB0: 0E 04
        rra                                                    ;#4CB2: 1F
        jr      nc,APPLY_WALK_ANIM_PATTERN                     ;#4CB3: 30 02
        ld      c,8                                            ;#4CB5: 0E 08
APPLY_WALK_ANIM_PATTERN:
        ; Apply calculated walking animation pattern
        ld      a,c                                            ;#4CB7: 79
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4CB8: CD AA 4B
        jp      SYNC_PENGUIN_SPRITES_TO_VRAM                   ;#4CBB: C3 9B 4B

UPDATE_GOAL_BOB_ANIM:
        ; Logic for penguin bobbing animation at the finish line
        ld      hl,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4CBE: 2A 78 E0
        ld      a,l                                            ;#4CC1: 7D
        add     a,1Eh                                          ;#4CC2: C6 1E
        ld      l,a                                            ;#4CC4: 6F
        ld      c,a                                            ;#4CC5: 4F
        ld      a,h                                            ;#4CC6: 7C
        add     a,10h                                          ;#4CC7: C6 10
        ld      b,a                                            ;#4CC9: 47
        ld      de,GOAL_PENGUIN_BOB_Y-1                        ;#4CCA: 11 FE 4C
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4CCD: 3A F9 E0
        or      a                                              ;#4CD0: B7
        jr      nz,APPLY_BOB_OFFSET                            ;#4CD1: 20 09
        ld      de,GOAL_PENGUIN_BOB_Y+9                        ;#4CD3: 11 08 4D
        ld      a,(PENGUIN_EVENT_TIMER)                        ;#4CD6: 3A 43 E1
        or      a                                              ;#4CD9: B7
        jr      z,BUFFER_PENGUIN_ATTRS                         ;#4CDA: 28 10
APPLY_BOB_OFFSET:
        ; Apply bobbing Y-offset to penguin position
        ex      de,hl                                          ;#4CDC: EB
        call    ADD_HL_A                                       ;#4CDD: CD D3 48
        ld      l,(hl)                                         ;#4CE0: 6E
        ld      a,d                                            ;#4CE1: 7A
        add     a,l                                            ;#4CE2: 85
        ld      d,a                                            ;#4CE3: 57
        ld      a,b                                            ;#4CE4: 78
        sub     l                                              ;#4CE5: 95
        ld      b,a                                            ;#4CE6: 47
        ld      e,0AEh                                         ;#4CE7: 1E AE
        ld      c,0AEh                                         ;#4CE9: 0E AE
        ex      de,hl                                          ;#4CEB: EB
BUFFER_PENGUIN_ATTRS:
        ; Store calculated shadow attributes into SAT_MIRROR slots 20-21
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_Y),hl       ;#4CEC: 22 A0 E0
        ; Packed 2-byte write: sprite-21 Y + X. The penguin shadow is rendered as two
        ; sprites side by side — sprite 20 (SPRITE_SHADOW) is the left half, sprite 21
        ; is the right half. Both share the SAT_MIRROR slots E0A0..E0A7.
        ld      (SAT_MIRROR + SPRITE_21 + ATTR_Y),bc           ;#4CEF: ED 43 A4 E0
COPY_PENGUIN_ATTRS_TO_VRAM:
        ; Upload penguin attribute buffer to VRAM
        ld      hl,SAT_MIRROR + SPRITE_SHADOW + ATTR_Y         ;#4CF3: 21 A0 E0
        LOAD_SPRITE_ATTR de, 20, 0                             ;#4CF6: 11 50 3B
        ld      bc,8                                           ;#4CF9: 01 08 00
        jp      COPY_RAM_TO_VRAM                               ;#4CFC: C3 C7 44

GOAL_PENGUIN_BOB_Y:
        ; Penguin bobbing Y-offsets during goal sequence
        ; Format: FORMAT_BOB_Y_OFFSETS
        BOB_Y_OFFSET 1                                         ;#4CFF: 01
        BOB_Y_OFFSET 2                                         ;#4D00: 02
        BOB_Y_OFFSET 2                                         ;#4D01: 02
        BOB_Y_OFFSET 3                                         ;#4D02: 03
        BOB_Y_OFFSET 3                                         ;#4D03: 03
        BOB_Y_OFFSET 3                                         ;#4D04: 03
        BOB_Y_OFFSET 3                                         ;#4D05: 03
        BOB_Y_OFFSET 3                                         ;#4D06: 03
        BOB_Y_OFFSET 2                                         ;#4D07: 02
        BOB_Y_OFFSET 2                                         ;#4D08: 02
        BOB_Y_OFFSET 1                                         ;#4D09: 01
        BOB_Y_OFFSET 1                                         ;#4D0A: 01
        BOB_Y_OFFSET 2                                         ;#4D0B: 02
        BOB_Y_OFFSET 2                                         ;#4D0C: 02
        BOB_Y_OFFSET 3                                         ;#4D0D: 03
        BOB_Y_OFFSET 2                                         ;#4D0E: 02
        BOB_Y_OFFSET 2                                         ;#4D0F: 02
        BOB_Y_OFFSET 1                                         ;#4D10: 01
        BOB_Y_OFFSET 0                                         ;#4D11: 00
        BOB_Y_OFFSET 1                                         ;#4D12: 01
        BOB_Y_OFFSET 2                                         ;#4D13: 02
        BOB_Y_OFFSET 2                                         ;#4D14: 02
        BOB_Y_OFFSET 2                                         ;#4D15: 02
        BOB_Y_OFFSET 1                                         ;#4D16: 01
        BOB_Y_OFFSET 0                                         ;#4D17: 00
        BOB_Y_OFFSET 1                                         ;#4D18: 01
        BOB_Y_OFFSET 2                                         ;#4D19: 02
        BOB_Y_OFFSET 2                                         ;#4D1A: 02
        BOB_Y_OFFSET 2                                         ;#4D1B: 02
        BOB_Y_OFFSET 1                                         ;#4D1C: 01
        BOB_Y_OFFSET 0                                         ;#4D1D: 00

CHECK_ITEM_COLLISIONS:
        ; Walk ITEM_TABLE and check item collisions vs penguin
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4D1E: 3A F9 E0
        or      a                                              ;#4D21: B7
        ret     nz                                             ;#4D22: C0
        ld      b,4                                            ;#4D23: 06 04
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4D25: 3A E0 E0
        cp      5                                              ;#4D28: FE 05
        jr      c,COLLISION_CHECK_LOOP_ENTRY                   ;#4D2A: 38 01
        inc     b                                              ;#4D2C: 04
COLLISION_CHECK_LOOP_ENTRY:
        ; Setup HL and B for item collision loop
        ld      hl,ITEM_TABLE                                  ;#4D2D: 21 12 E1
COLLISION_CHECK_LOOP:
        ; Main item collision loop
        ld      a,(hl)                                         ;#4D30: 7E
        cp      0Dh                                            ;#4D31: FE 0D
        ld      a,5                                            ;#4D33: 3E 05
        jr      nz,COLLISION_NEXT_ENTITY                       ;#4D35: 20 2D
        inc     hl                                             ;#4D37: 23
        ld      c,(hl)                                         ;#4D38: 4E
        inc     hl                                             ;#4D39: 23
        inc     hl                                             ;#4D3A: 23
        inc     hl                                             ;#4D3B: 23
        ld      e,(hl)                                         ;#4D3C: 5E
        inc     hl                                             ;#4D3D: 23
        ld      d,(hl)                                         ;#4D3E: 56
        ex      de,hl                                          ;#4D3F: EB
        dec     a                                              ;#4D40: 3D
        cp      c                                              ;#4D41: B9
        ld      a,(PENGUIN_X_POS)                              ;#4D42: 3A 79 E0
        jr      nc,COLLISION_BRANCH_X                          ;#4D45: 30 08
        sub     (hl)                                           ;#4D47: 96
        inc     hl                                             ;#4D48: 23
        cp      (hl)                                           ;#4D49: BE
        jp      c,HANDLE_COLLISION_FLAG                        ;#4D4A: DA F1 4F
        jr      COLLISION_SKIP_ENTITY                          ;#4D4D: 18 13

COLLISION_BRANCH_X:
        ; Check X-coordinate collision
        ld      c,(hl)                                         ;#4D4F: 4E
        dec     c                                              ;#4D50: 0D
        jr      z,COLLISION_BRANCH_Y                           ;#4D51: 28 08
        ld      c,a                                            ;#4D53: 4F
        sub     (hl)                                           ;#4D54: 96
        inc     hl                                             ;#4D55: 23
        cp      (hl)                                           ;#4D56: BE
        jp      c,HANDLE_COLLISION_FALL                        ;#4D57: DA 20 4F
        ld      a,c                                            ;#4D5A: 79
COLLISION_BRANCH_Y:
        ; Check Y-coordinate collision
        inc     hl                                             ;#4D5B: 23
        sub     (hl)                                           ;#4D5C: 96
        inc     hl                                             ;#4D5D: 23
        cp      (hl)                                           ;#4D5E: BE
        jp      c,HANDLE_COLLISION_HOLE                        ;#4D5F: DA FB 4D
COLLISION_SKIP_ENTITY:
        ; Skip currently checked entity
        ex      de,hl                                          ;#4D62: EB
        xor     a                                              ;#4D63: AF
COLLISION_NEXT_ENTITY:
        ; Advance to next entity in table
        inc     a                                              ;#4D64: 3C
        call    ADD_HL_A                                       ;#4D65: CD D3 48
        djnz    COLLISION_CHECK_LOOP                           ;#4D68: 10 C6
        ret                                                    ;#4D6A: C9

CHECK_COLLISIONS_WHILE_LOCKED:
        ; Secondary collision check while input is locked (stun/fall/goal-walk)
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4D6B: 3A F9 E0
        or      a                                              ;#4D6E: B7
        ret     z                                              ;#4D6F: C8
        ld      b,5                                            ;#4D70: 06 05
        ld      hl,ITEM_TABLE                                  ;#4D72: 21 12 E1
LOCKED_COLLISION_LOOP:
        ; Loop body of CHECK_COLLISIONS_WHILE_LOCKED (one ITEM_TABLE slot per iteration)
        ld      a,(hl)                                         ;#4D75: 7E
        inc     hl                                             ;#4D76: 23
        cp      0Dh                                            ;#4D77: FE 0D
        ld      a,5                                            ;#4D79: 3E 05
        jr      nz,LOCKED_COLLISION_NEXT                       ;#4D7B: 20 14
        ex      de,hl                                          ;#4D7D: EB
        ld      a,(de)                                         ;#4D7E: 1A
        cp      5                                              ;#4D7F: FE 05
        add     a,a                                            ;#4D81: 87
        ld      hl,LOCKED_COLLISION_TABLE                      ;#4D82: 21 9D 4D
        call    ADD_HL_A                                       ;#4D85: CD D3 48
        ld      a,(PENGUIN_X_POS)                              ;#4D88: 3A 79 E0
        sub     (hl)                                           ;#4D8B: 96
        inc     hl                                             ;#4D8C: 23
        cp      (hl)                                           ;#4D8D: BE
        jr      c,LOCKED_COLLISION_MATCH                       ;#4D8E: 38 07
        ex      de,hl                                          ;#4D90: EB
LOCKED_COLLISION_NEXT:
        ; Advance to the next ITEM_TABLE slot
        call    ADD_HL_A                                       ;#4D91: CD D3 48
        djnz    LOCKED_COLLISION_LOOP                          ;#4D94: 10 DF
        ret                                                    ;#4D96: C9

LOCKED_COLLISION_MATCH:
        ; On match, set COLLISION_PROCESSED_FLAG and return
        ld      a,1                                            ;#4D97: 3E 01
        ld      (COLLISION_PROCESSED_FLAG),a                   ;#4D99: 32 32 E1
        ret                                                    ;#4D9C: C9

LOCKED_COLLISION_TABLE:
        ; X-range pairs (low_x, width) used by CHECK_COLLISIONS_WHILE_LOCKED
        ; Format: LOCKED_COLLISION
        LOCKED_COLLISION 58h, 30h                              ;#4D9D: 58 30
        LOCKED_COLLISION 18h, 30h                              ;#4D9F: 18 30
        LOCKED_COLLISION 98h, 30h                              ;#4DA1: 98 30
        LOCKED_COLLISION 2Ch, 58h                              ;#4DA3: 2C 58
        LOCKED_COLLISION 64h, 58h                              ;#4DA5: 64 58

HANDLE_COLLISION_FISH:
        ; Mid-air fish catch via CURRENT_ENTITY_POINTER: +300, jingle, hides SPRITE_ITEM
        ; Skip processing while stun/fall state is active (early-return gate).
        ld      a,(PENGUIN_STUN_TIMER)                         ;#4DA7: 3A 42 E1
        ld      hl,PENGUIN_FALL_TIMER                          ;#4DAA: 21 40 E1
        add     a,(hl)                                         ;#4DAD: 86
        ret     nz                                             ;#4DAE: C0
        ; Load active obstacle entity pointer and discard hidden entries (Y=E0h).
        ld      de,(CURRENT_ENTITY_POINTER)                    ;#4DAF: ED 5B 88 E1
        ld      a,e                                            ;#4DB3: 7B
        cp      0E0h                                           ;#4DB4: FE E0
        ret     z                                              ;#4DB6: C8
        ; Near-field collision math against penguin sprite coordinates.
        ld      hl,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4DB7: 2A 78 E0
        ; Fast horizontal reject: a = obstacle_x - penguin_x, ret if |X diff| >= 10.
        sub     l                                              ;#4DBA: 95
        ld      e,a                                            ;#4DBB: 5F
        sub     0Ah                                            ;#4DBC: D6 0A
        ret     nc                                             ;#4DBE: D0
        ; Weighted X/Y threshold test; carry indicates overlap.
        ld      a,13h                                          ;#4DBF: 3E 13
        add     a,e                                            ;#4DC1: 83
        ld      l,a                                            ;#4DC2: 6F
        ld      a,e                                            ;#4DC3: 7B
        add     a,a                                            ;#4DC4: 87
        add     a,17h                                          ;#4DC5: C6 17
        ld      e,a                                            ;#4DC7: 5F
        ld      a,d                                            ;#4DC8: 7A
        sub     h                                              ;#4DC9: 94
        sub     l                                              ;#4DCA: 95
        add     a,e                                            ;#4DCB: 83
        ret     nc                                             ;#4DCC: D0
        ; Item-catch collision response: play catch SFX, hide item sprite, +300.
        ld      a,ID_SOUND_CATCH_FISH                          ;#4DCD: 3E 07
        call    PLAY_SOUND_SAFE                                ;#4DCF: CD 83 79
        ld      hl,SAT_MIRROR + SPRITE_ITEM + ATTR_Y           ;#4DD2: 21 8C E0
        ld      de,FISH_POS_STATE                              ;#4DD5: 11 83 E1
        call    HIDE_DYNAMIC_SPRITE                            ;#4DD8: CD 7F 76
        call    SYNC_SPRITE_LOOP                               ;#4DDB: CD 2A 76
        ld      de,300h                                        ;#4DDE: 11 00 03
        jp      ADD_SCORE                                      ;#4DE1: C3 08 46

HANDLE_COLLISION_SEAL:
        ; Seal collision: fires when SPRITE_OBSTACLE Y == 8Fh (seal-on-ground)
        ld      hl,(SAT_MIRROR + SPRITE_OBSTACLE + ATTR_Y)     ;#4DE4: 2A 90 E0
        ld      a,l                                            ;#4DE7: 7D
        ; Y-position gate: obstacle must be at Y=8Fh (on-road row) for heavy-stumble.
        cp      8Fh                                            ;#4DE8: FE 8F
        ret     nz                                             ;#4DEA: C0
        ld      a,(PENGUIN_X_POS)                              ;#4DEB: 3A 79 E0
        ld      l,a                                            ;#4DEE: 6F
        ld      a,h                                            ;#4DEF: 7C
        sub     l                                              ;#4DF0: 95
        ; Preserve signed X relation (flags) before range transform.
        push    af                                             ;#4DF1: F5
        sub     18h                                            ;#4DF2: D6 18
        add     a,23h                                          ;#4DF4: C6 23
        ; Carry branch enters HANDLE_STUMBLE_LARGE for heavy obstacle collisions.
        jp      c,HANDLE_STUMBLE_LARGE                         ;#4DF6: DA 0F 4E
        pop     af                                             ;#4DF9: F1
        ret                                                    ;#4DFA: C9

HANDLE_COLLISION_HOLE:
        ; Hole-collision stun branch: plays STUN_1, joins START_PENGUIN_STUN
        ; One-shot guard: ensures stun fires only once per collision event.
        ld      a,(STUMBLE_PROCESSED_FLAG)                     ;#4DFB: 3A 35 E1
        or      a                                              ;#4DFE: B7
        ret     nz                                             ;#4DFF: C0
        ld      a,ID_SOUND_STUN_1                              ;#4E00: 3E 03
        call    PLAY_SOUND_SAFE                                ;#4E02: CD 83 79
        ; Base timer seed for normal stun response.
        ld      hl,101h                                        ;#4E05: 21 01 01
        ld      a,(PENGUIN_MOVE_STATE)                         ;#4E08: 3A FA E0
        cpl                                                    ;#4E0B: 2F
        rra                                                    ;#4E0C: 1F
        jr      START_PENGUIN_STUN                             ;#4E0D: 18 16

HANDLE_STUMBLE_LARGE:
        ; Stumble handler for large object (Seal) collisions
        ; Stores stumble marker, plays stumble SFX, and derives timer variant.
        ld      hl,101h                                        ;#4E0F: 21 01 01
        ld      (STUMBLE_OBSTACLE_ADDR),hl                     ;#4E12: 22 36 E1
        ld      a,ID_SOUND_SEAL_COLLISION                      ;#4E15: 3E 08
        call    PLAY_SOUND_SAFE                                ;#4E17: CD 83 79
        ld      hl,102h                                        ;#4E1A: 21 02 01
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4E1D: 3A F9 E0
        or      a                                              ;#4E20: B7
        jr      z,STUMBLE_LARGE_DONE                           ;#4E21: 28 01
        inc     l                                              ;#4E23: 2C
STUMBLE_LARGE_DONE:
        ; Stumble logic finished
        pop     af                                             ;#4E24: F1
START_PENGUIN_STUN:
        ; Initiate the penguin stun sequence
        ; Writes stun timer/pattern, refreshes sprites, resets speed (shared stun path).
        ld      (PENGUIN_STUN_TIMER),hl                        ;#4E25: 22 42 E1
        ld      a,20h                                          ;#4E28: 3E 20
        jr      nc,START_PENGUIN_STUN_DONE                     ;#4E2A: 30 02
        ld      a,24h                                          ;#4E2C: 3E 24
START_PENGUIN_STUN_DONE:
        ; Stun initialization finished
        ld      (PENGUIN_STUN_PATTERN),a                       ;#4E2E: 32 44 E1
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4E31: CD AA 4B
        call    SYNC_PENGUIN_SPRITES_TO_VRAM                   ;#4E34: CD 9B 4B
        ld      hl,1313h                                       ;#4E37: 21 13 13
        ld      (PENGUIN_SPEED),hl                             ;#4E3A: 22 00 E1
        ret                                                    ;#4E3D: C9

HANDLE_PENGUIN_STUN_ANIMATION:
        ; Updates penguin position during stun state (every 4th frame)
        ld      a,(FRAME_COUNTER)                              ;#4E3E: 3A 03 E0
        and     3                                              ;#4E41: E6 03
        ret     nz                                             ;#4E43: C0
        ld      hl,PENGUIN_STUN_TIMER                          ;#4E44: 21 42 E1
        ld      a,(hl)                                         ;#4E47: 7E
        cp      3                                              ;#4E48: FE 03
        jp      z,STUN_RECOVERY_ANIMATION                      ;#4E4A: CA D6 4E
        inc     hl                                             ;#4E4D: 23
        ld      a,(hl)                                         ;#4E4E: 7E
        inc     (hl)                                           ;#4E4F: 34
        ld      hl,PENGUIN_STUN_Y_OFFSETS-1                    ;#4E50: 21 C1 4E
        call    ADD_HL_A                                       ;#4E53: CD D3 48
        ld      c,(hl)                                         ;#4E56: 4E
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4E57: ED 5B 78 E0
STUN_X_MOVE_LOOP:
        ; Loop to apply horizontal shift based on stun timer
        ld      hl,VRAM_UPDATE_BUFFER                          ;#4E5B: 21 D0 E0
        ld      a,(PENGUIN_STUN_PATTERN)                       ;#4E5E: 3A 44 E1
        bit     2,a                                            ;#4E61: CB 57
        call    z,STUMBLE_MOVE_LEFT_3X                         ;#4E63: CC B7 4E
        call    nz,STUMBLE_MOVE_RIGHT_3X                       ;#4E66: C4 AE 4E
        ld      hl,PENGUIN_STUN_TIMER                          ;#4E69: 21 42 E1
        ld      a,(hl)                                         ;#4E6C: 7E
        dec     a                                              ;#4E6D: 3D
        jr      z,STUN_APPLY_Y_OFFSET                          ;#4E6E: 28 03
        dec     (hl)                                           ;#4E70: 35
        jr      STUN_X_MOVE_LOOP                               ;#4E71: 18 E8

STUN_APPLY_Y_OFFSET:
        ; Apply vertical offset from data table and update sprite
        ex      de,hl                                          ;#4E73: EB
        ld      a,l                                            ;#4E74: 7D
        add     a,c                                            ;#4E75: 81
        ld      l,a                                            ;#4E76: 6F
        call    UPDATE_PENGUIN_COORDS                          ;#4E77: CD 98 4B
        ld      a,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)       ;#4E7A: 3A 78 E0
        cp      90h                                            ;#4E7D: FE 90
        jr      nz,SPAWN_ITEM_SKIP_STUN                        ;#4E7F: 20 1F
PLAY_STUN_2_AND_ADVANCE:
        ; Play STUN_2 SFX, render road, advance stage segment after stun landing
        ld      a,ID_SOUND_STUN_2                              ;#4E81: 3E 04
        call    PLAY_SOUND_SAFE                                ;#4E83: CD 83 79
        call    RENDER_LEFT_ROAD_FRAME                         ;#4E86: CD 60 51
        call    ADVANCE_STAGE_SEGMENT_DATA                     ;#4E89: CD 69 51
        xor     a                                              ;#4E8C: AF
        ld      b,a                                            ;#4E8D: 47
        ld      hl,STUMBLE_OBSTACLE_ADDR                       ;#4E8E: 21 36 E1
        cp      (hl)                                           ;#4E91: BE
        jr      z,SPAWN_ITEM_ENTRY                             ;#4E92: 28 05
        ld      (hl),a                                         ;#4E94: 77
        inc     a                                              ;#4E95: 3C
        ld      (STUMBLE_PROCESSED_FLAG),a                     ;#4E96: 32 35 E1
SPAWN_ITEM_ENTRY:
        ; Entry point in the collision handler for spawning fish/items
        call    CHECK_AND_SPAWN_ITEM                           ;#4E99: CD 8A 51
        xor     a                                              ;#4E9C: AF
        ld      (STUMBLE_PROCESSED_FLAG),a                     ;#4E9D: 32 35 E1
SPAWN_ITEM_SKIP_STUN:
        ; Skip item spawning
        ld      hl,PENGUIN_EVENT_TIMER                         ;#4EA0: 21 43 E1
        ld      a,(hl)                                         ;#4EA3: 7E
        sub     15h                                            ;#4EA4: D6 15
        ret     nz                                             ;#4EA6: C0
        ld      (hl),a                                         ;#4EA7: 77
        dec     hl                                             ;#4EA8: 2B
        ld      (hl),a                                         ;#4EA9: 77
        ld      (FISH_POS_GUARD_FLAG),a                        ;#4EAA: 32 37 E1
        ret                                                    ;#4EAD: C9

STUMBLE_MOVE_RIGHT_3X:
        ; Forceful right movement during stumble
        call    MOVE_PENGUIN_RIGHT                             ;#4EAE: CD 8E 4C
        call    MOVE_PENGUIN_RIGHT                             ;#4EB1: CD 8E 4C
        jp      MOVE_PENGUIN_RIGHT                             ;#4EB4: C3 8E 4C

STUMBLE_MOVE_LEFT_3X:
        ; Forceful left movement during stumble
        call    MOVE_PENGUIN_LEFT                              ;#4EB7: CD 71 4C
        call    MOVE_PENGUIN_LEFT                              ;#4EBA: CD 71 4C
        call    MOVE_PENGUIN_LEFT                              ;#4EBD: CD 71 4C
        xor     a                                              ;#4EC0: AF
        ret                                                    ;#4EC1: C9

PENGUIN_STUN_Y_OFFSETS:
        ; Y-offsets for penguin stun/stumble animation
        ; Format: FORMAT_STUN_Y_OFFSETS
        STUN_Y_OFFSET -3                                       ;#4EC2: FD
        STUN_Y_OFFSET -2                                       ;#4EC3: FE
        STUN_Y_OFFSET -2                                       ;#4EC4: FE
        STUN_Y_OFFSET -1                                       ;#4EC5: FF
        STUN_Y_OFFSET 1                                        ;#4EC6: 01
        STUN_Y_OFFSET 2                                        ;#4EC7: 02
        STUN_Y_OFFSET 2                                        ;#4EC8: 02
        STUN_Y_OFFSET 3                                        ;#4EC9: 03
        STUN_Y_OFFSET -2                                       ;#4ECA: FE
        STUN_Y_OFFSET -2                                       ;#4ECB: FE
        STUN_Y_OFFSET -1                                       ;#4ECC: FF
        STUN_Y_OFFSET 1                                        ;#4ECD: 01
        STUN_Y_OFFSET 2                                        ;#4ECE: 02
        STUN_Y_OFFSET 2                                        ;#4ECF: 02
        STUN_Y_OFFSET -2                                       ;#4ED0: FE
        STUN_Y_OFFSET -2                                       ;#4ED1: FE
        STUN_Y_OFFSET -1                                       ;#4ED2: FF
        STUN_Y_OFFSET 1                                        ;#4ED3: 01
        STUN_Y_OFFSET 2                                        ;#4ED4: 02
        STUN_Y_OFFSET 2                                        ;#4ED5: 02

STUN_RECOVERY_ANIMATION:
        ; Handle stun recovery animation phase
        ld      hl,PENGUIN_INPUT_LOCK_TIMER                    ;#4ED6: 21 F9 E0
        ld      a,(hl)                                         ;#4ED9: 7E
        inc     (hl)                                           ;#4EDA: 34
        cp      0Bh                                            ;#4EDB: FE 0B
        jr      nz,APPLY_STUN_SPRITE_UPDATE                    ;#4EDD: 20 02
        ld      (hl),0                                         ;#4EDF: 36 00
APPLY_STUN_SPRITE_UPDATE:
        ; Apply sprite updates during stun recovery
        push    af                                             ;#4EE1: F5
        ld      a,(PENGUIN_STUN_PATTERN)                       ;#4EE2: 3A 44 E1
        ld      c,a                                            ;#4EE5: 4F
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4EE6: CD AA 4B
        pop     af                                             ;#4EE9: F1
        ld      hl,PENGUIN_JUMP_Y_OFFSETS                      ;#4EEA: 21 55 4C
        call    ADD_HL_A                                       ;#4EED: CD D3 48
        ld      a,(hl)                                         ;#4EF0: 7E
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4EF1: ED 5B 78 E0
        add     a,e                                            ;#4EF5: 83
        ld      e,a                                            ;#4EF6: 5F
        bit     2,c                                            ;#4EF7: CB 51
        ld      hl,VRAM_UPDATE_BUFFER                          ;#4EF9: 21 D0 E0
        call    z,STUMBLE_MOVE_LEFT_3X                         ;#4EFC: CC B7 4E
        call    nz,STUMBLE_MOVE_RIGHT_3X                       ;#4EFF: C4 AE 4E
        ex      de,hl                                          ;#4F02: EB
        call    UPDATE_PENGUIN_COORDS                          ;#4F03: CD 98 4B
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4F06: 3A F9 E0
        or      a                                              ;#4F09: B7
        ret     nz                                             ;#4F0A: C0
        ld      a,1                                            ;#4F0B: 3E 01
        ld      (STUMBLE_PROCESSED_FLAG),a                     ;#4F0D: 32 35 E1
        call    PLAY_STUN_2_AND_ADVANCE                        ;#4F10: CD 81 4E
        xor     a                                              ;#4F13: AF
        ld      (STUMBLE_PROCESSED_FLAG),a                     ;#4F14: 32 35 E1
        dec     hl                                             ;#4F17: 2B
        inc     a                                              ;#4F18: 3C
        ld      (hl),a                                         ;#4F19: 77
        ld      a,ID_SOUND_STUN_2                              ;#4F1A: 3E 04
        call    PLAY_SOUND_SAFE                                ;#4F1C: CD 83 79
        ret                                                    ;#4F1F: C9

HANDLE_COLLISION_FALL:
        ; Handle collision that causes falling (e.g. hole)
        ld      hl,1                                           ;#4F20: 21 01 00
        ld      (PENGUIN_FALL_TIMER),hl                        ;#4F23: 22 40 E1
        xor     a                                              ;#4F26: AF
        ld      (PENGUIN_STUN_TIMER),a                         ;#4F27: 32 42 E1
        ld      a,0FFh                                         ;#4F2A: 3E FF
        ld      (PENGUIN_ANIM_FRAME),a                         ;#4F2C: 32 F8 E0
        ld      a,ID_SOUND_FALL_HOLE                           ;#4F2F: 3E 05
        call    PLAY_SOUND_SAFE                                ;#4F31: CD 83 79
        ld      hl,SAT_MIRROR + SPRITE_6 + ATTR_Y              ;#4F34: 21 68 E0
        ld      bc,4B6h                                        ;#4F37: 01 B6 04
HIDE_AUX_SPRITES_LOOP:
        ; Park aux-sprite buffer (sprites 6-9) off-screen (Y=B6h) during fall
        ld      (hl),c                                         ;#4F3A: 71
        ld      a,4                                            ;#4F3B: 3E 04
        call    ADD_HL_A                                       ;#4F3D: CD D3 48
        djnz    HIDE_AUX_SPRITES_LOOP                          ;#4F40: 10 F8
SET_PENGUIN_FALL_COORDS:
        ; Set penguin coordinates for fall sequence
        ld      hl,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4F42: 2A 78 E0
        ld      l,9Fh                                          ;#4F45: 2E 9F
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#4F47: CD C1 4B
        ld      a,10h                                          ;#4F4A: 3E 10
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4F4C: CD AA 4B
        ld      a,0E0h                                         ;#4F4F: 3E E0
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_Y),a        ;#4F51: 32 A0 E0
        ld      hl,0E0h * 256 + COLOR_DARK_YELLOW              ;#4F54: 21 0A E0
        ; Packed 2-byte write: the slot for shadow is reused as yellow penguin's legs.
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_COLOR),hl   ;#4F57: 22 A3 E0
SYNC_AUX_SPRITES_TO_VRAM:
        ; Copy 32-byte aux-sprite buffer (E068, sprites 6-13) to VRAM
        ld      hl,SAT_MIRROR + SPRITE_6 + ATTR_Y              ;#4F5A: 21 68 E0
        LOAD_SPRITE_ATTR de, 6, 0                              ;#4F5D: 11 18 3B
        ld      bc,20h                                         ;#4F60: 01 20 00
        call    COPY_RAM_TO_VRAM                               ;#4F63: CD C7 44
        jp      COPY_PENGUIN_ATTRS_TO_VRAM                     ;#4F66: C3 F3 4C

HANDLE_PENGUIN_FALL:
        ; Handle penguin fall state (increments anim counter, waits for input)
        ld      hl,PENGUIN_FALL_ANIM_COUNTER                   ;#4F69: 21 41 E1
        inc     (hl)                                           ;#4F6C: 34
        res     7,(hl)                                         ;#4F6D: CB BE
        ld      a,(hl)                                         ;#4F6F: 7E
        cp      20h                                            ;#4F70: FE 20
        jr      c,SET_PENGUIN_FALL_COORDS                      ;#4F72: 38 CE
        call    READ_INPUT_EDGE                                ;#4F74: CD F8 45
        jr      nz,PENGUIN_FALL_LOOP                           ;#4F77: 20 3E
        ld      a,(FRAME_COUNTER)                              ;#4F79: 3A 03 E0
        ld      c,a                                            ;#4F7C: 4F
        and     7                                              ;#4F7D: E6 07
        ret     nz                                             ;#4F7F: C0
        ; Fall-recovery branch table — picks one of three (a, b, de) tuples by
        ; FRAME_COUNTER bits 3 and 4 (each phase lasts 8 frames).
        ; In this branch, the shadow sprites are used from the penguin's legs.
        ; The values feed INIT_FALL_RECOVERY:
        ; a = shadow X offset added to penguin_X
        ; b + 10h = final shadow Y
        ; d = penguin body pattern;
        ; e = legs pattern.
        ; frame 0 (bit 3 = 0):           a=8,    b=99h, d=14h, e=70h
        ld      a,8                                            ;#4F80: 3E 08
        ld      b,99h                                          ;#4F82: 06 99
        ld      de,1470h                                       ;#4F84: 11 70 14
        bit     3,c                                            ;#4F87: CB 59
        jr      z,INIT_FALL_RECOVERY                           ;#4F89: 28 10
        ; frame 1 (bit 3 = 1, bit 4 = 0): a=4,    b=96h, d=18h, e=74h
        ld      a,4                                            ;#4F8B: 3E 04
        ld      b,96h                                          ;#4F8D: 06 96
        ld      de,1874h                                       ;#4F8F: 11 74 18
        bit     4,c                                            ;#4F92: CB 61
        jr      z,INIT_FALL_RECOVERY                           ;#4F94: 28 05
        ; frame 2 (bits 3+4 both set):    a=0Bh, (b kept from frame 1), d=1Ch, e=78h
        ld      a,0Bh                                          ;#4F96: 3E 0B
        ld      de,1C78h                                       ;#4F98: 11 78 1C
INIT_FALL_RECOVERY:
        ; Initialize recovery after falling
        ld      hl,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4F9B: 2A 78 E0
        ld      l,b                                            ;#4F9E: 68
        add     a,h                                            ;#4F9F: 84
        ld      c,a                                            ;#4FA0: 4F
        ld      a,b                                            ;#4FA1: 78
        ld      b,e                                            ;#4FA2: 43
        ; Packed 2-byte write: shadow X (E0A1) + shadow pattern (E0A2).
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_X),bc       ;#4FA3: ED 43 A1 E0
        add     a,10h                                          ;#4FA7: C6 10
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_Y),a        ;#4FA9: 32 A0 E0
        push    de                                             ;#4FAC: D5
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#4FAD: CD C1 4B
        pop     af                                             ;#4FB0: F1
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4FB1: CD AA 4B
        jp      SYNC_AUX_SPRITES_TO_VRAM                       ;#4FB4: C3 5A 4F

PENGUIN_FALL_LOOP:
        ; Loop for penguin falling animation
        xor     a                                              ;#4FB7: AF
        ld      (PENGUIN_FALL_TIMER),a                         ;#4FB8: 32 40 E1
        ld      (PENGUIN_ANIM_FRAME),a                         ;#4FBB: 32 F8 E0
        ld      hl,313h                                        ;#4FBE: 21 13 03
        ld      (PENGUIN_SPEED),hl                             ;#4FC1: 22 00 E1
        ld      a,(PENGUIN_X_POS)                              ;#4FC4: 3A 79 E0
        push    af                                             ;#4FC7: F5
        ld      hl,SPRITE_INIT_TABLE+1                         ;#4FC8: 21 AA 66
        ld      de,SAT_MIRROR + SPRITE_6 + ATTR_Y              ;#4FCB: 11 68 E0
        ld      c,4                                            ;#4FCE: 0E 04
        call    REPLICATE_4_BYTE_BLOCK                         ;#4FD0: CD 95 45
        ld      b,4                                            ;#4FD3: 06 04
HIDE_AUX_SPRITES_DATA_LOOP:
        ; Replicate SPRITE_INIT_TABLE bytes across 4 aux-sprite slots (PENGUIN_FALL_LOOP)
        ld      c,(hl)                                         ;#4FD5: 4E
        inc     hl                                             ;#4FD6: 23
        push    bc                                             ;#4FD7: C5
        call    REPLICATE_4_BYTE_BLOCK                         ;#4FD8: CD 95 45
        pop     bc                                             ;#4FDB: C1
        djnz    HIDE_AUX_SPRITES_DATA_LOOP                     ;#4FDC: 10 F7
        pop     hl                                             ;#4FDE: E1
        ld      l,90h                                          ;#4FDF: 2E 90
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#4FE1: CD C1 4B
        ld      hl,0A0h + COLOR_DARK_BLUE * 256                ;#4FE4: 21 A0 04
        ; Packed 2-byte write: shadow pattern A0h (low) + shadow color 4 dark blue (high).
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_PATT),hl    ;#4FE7: 22 A2 E0
        call    SYNC_PENGUIN_SPRITES_TO_VRAM                   ;#4FEA: CD 9B 4B
        call    SYNC_SPRITE_ATTRIBUTES_ALL                     ;#4FED: CD 9D 66
        ret                                                    ;#4FF0: C9

HANDLE_COLLISION_FLAG:
        ; Road-flag pickup (SEQ_ITEM_PROP 5/6): +500, jingle, draws the tile stream
        ex      de,hl                                          ;#4FF1: EB
        dec     hl                                             ;#4FF2: 2B
        dec     hl                                             ;#4FF3: 2B
        ld      d,(hl)                                         ;#4FF4: 56
        dec     hl                                             ;#4FF5: 2B
        ld      e,(hl)                                         ;#4FF6: 5E
        dec     hl                                             ;#4FF7: 2B
        dec     hl                                             ;#4FF8: 2B
        ld      (hl),0                                         ;#4FF9: 36 00
        ex      de,hl                                          ;#4FFB: EB
        inc     hl                                             ;#4FFC: 23
        ld      de,ITEM_PICKUP_TILE_BUFFER                     ;#4FFD: 11 A0 E1
        ld      bc,0Dh                                         ;#5000: 01 0D 00
        ldir                                                   ;#5003: ED B0
        xor     a                                              ;#5005: AF
        ld      (de),a                                         ;#5006: 12
        ld      a,ID_SOUND_CATCH_FLAG                          ;#5007: 3E 06
        call    PLAY_SOUND_SAFE                                ;#5009: CD 83 79
        ld      hl,ITEM_PICKUP_TILE_BUFFER                     ;#500C: 21 A0 E1
        call    WRITE_VRAM_TILES_STREAM                        ;#500F: CD 12 45
        ld      de,500h                                        ;#5012: 11 00 05
        call    ADD_SCORE                                      ;#5015: CD 08 46
        ret                                                    ;#5018: C9

INIT_STAGE:
        ; Initialize stage-specific BCD values and timers
        ld      a,(CURRENT_STAGE_INDEX)                        ;#5019: 3A E1 E0
        ld      hl,STAGE_VISUAL_THEME_TABLE                    ;#501C: 21 45 51
        call    ADD_HL_A                                       ;#501F: CD D3 48
        ld      a,COLOR_CYAN                                   ;#5022: 3E 07
        bit     0,(hl)                                         ;#5024: CB 46
        jr      z,INIT_STAGE_SET_SKY_COLOR                     ;#5026: 28 02
        ld      a,COLOR_LIGHT_RED                              ;#5028: 3E 09
INIT_STAGE_SET_SKY_COLOR:
        ; Set stage sky color attribute
        ld      (SKY_COLOR),a                                  ;#502A: 32 0C E1
        ld      a,(hl)                                         ;#502D: 7E
        ld      hl,GFX_STARTUP_COLOR_TABLE_TAIL                ;#502E: 21 9E 5D
        LOAD_VRAM_WRITE de, 21EFh                              ;#5031: 11 00 62
        or      a                                              ;#5034: B7
        jr      z,LOAD_STAGE_TILES_AND_COLORS                  ;#5035: 28 06
        ld      hl,GFX_STAGE_NIGHT_TILES                       ;#5037: 21 A9 5D
        ld      de,GFX_STAGE_NIGHT_COLORS                      ;#503A: 11 1D 62
LOAD_STAGE_TILES_AND_COLORS:
        ; Load stage tiles and colors to VRAM
        push    de                                             ;#503D: D5
        LOAD_VRAM_WRITE de, 588h                               ;#503E: 11 88 45
        call    DECOMPRESS_VRAM_DIRECT                         ;#5041: CD 43 45
        pop     hl                                             ;#5044: E1
        LOAD_VRAM_WRITE de, 0F78h                              ;#5045: 11 78 4F
        call    DECOMPRESS_VRAM_DIRECT                         ;#5048: CD 43 45
        LOAD_NAME_TABLE de, 3, 0                               ;#504B: 11 60 38
        ld      bc,0E0h                                        ;#504E: 01 E0 00
        ld      a,(SKY_COLOR)                                  ;#5051: 3A 0C E1
        call    FILL_VRAM                                      ;#5054: CD DC 44
        LOAD_NAME_TABLE de, 10, 0                              ;#5057: 11 40 39
        ld      bc,1C0h                                        ;#505A: 01 C0 01
        LOAD_VRAM_COLOR a, COLOR_TRANSPARENT, COLOR_WHITE      ;#505D: 3E 0F
        call    FILL_VRAM                                      ;#505F: CD DC 44
        ld      hl,ROAD_ICE_RIGHT_1_FILL                       ;#5062: 21 0B 72
        call    UPLOAD_ROAD_SEGMENT_TO_VRAM                    ;#5065: CD C6 50
        ld      hl,ROAD_ICE_LEFT_1_FILL                        ;#5068: 21 48 72
        call    UPLOAD_ROAD_SEGMENT_TO_VRAM                    ;#506B: CD C6 50
        ld      hl,STAGE_SEGMENT_SEQUENCES                     ;#506E: 21 19 51
        ld      a,(CURRENT_STAGE_INDEX)                        ;#5071: 3A E1 E0
        add     a,a                                            ;#5074: 87
        add     a,a                                            ;#5075: 87
        call    ADD_HL_A                                       ;#5076: CD D3 48
        ld      (CURRENT_STAGE_DATA_PTR),hl                    ;#5079: 22 0A E1
        xor     a                                              ;#507C: AF
        ld      (ACTIVE_ROAD_FRAME),a                          ;#507D: 32 02 E1
        ld      (STAGE_SEGMENT_INDEX),a                        ;#5080: 32 08 E1
        ld      hl,ROAD_ICE_RIGHT_1                            ;#5083: 21 03 72
        ld      (ACTIVE_ROAD_PTR_RIGHT),hl                     ;#5086: 22 03 E1
        ld      hl,ROAD_ICE_LEFT_1                             ;#5089: 21 40 72
        ld      (ACTIVE_ROAD_PTR_LEFT),hl                      ;#508C: 22 05 E1
        call    RENDER_LEFT_ROAD_FRAME                         ;#508F: CD 60 51
        call    CALC_STAGE_SEGMENT_ADDR                        ;#5092: CD 70 51
        ret                                                    ;#5095: C9

PROCESS_ROAD_SEGMENT_ADVANCE:
        ; Advance to next road data segment and trigger VRAM update
        ld      hl,STAGE_SEGMENT_INDEX                         ;#5096: 21 08 E1
        ld      a,(hl)                                         ;#5099: 7E
        inc     (hl)                                           ;#509A: 34
        ld      hl,(CURRENT_STAGE_DATA_PTR)                    ;#509B: 2A 0A E1
        call    ADD_HL_A                                       ;#509E: CD D3 48
        ld      a,(hl)                                         ;#50A1: 7E
        cp      0FFh                                           ;#50A2: FE FF
        ret     z                                              ;#50A4: C8
        ld      (ROAD_SEGMENT_INDEX),a                         ;#50A5: 32 09 E1
        ld      bc,ACTIVE_ROAD_PTR_RIGHT                       ;#50A8: 01 03 E1
        bit     0,a                                            ;#50AB: CB 47
        jr      z,STORE_ROAD_SEG_SKIP_BC                       ;#50AD: 28 02
        inc     bc                                             ;#50AF: 03
        inc     bc                                             ;#50B0: 03
STORE_ROAD_SEG_SKIP_BC:
        ; Skip register BC store
        add     a,a                                            ;#50B1: 87
        ld      hl,STAGE_SEGMENT_DEFINITIONS                   ;#50B2: 21 FB 71
        call    ADD_HL_A                                       ;#50B5: CD D3 48
        ld      a,(hl)                                         ;#50B8: 7E
        ld      e,a                                            ;#50B9: 5F
        ld      (bc),a                                         ;#50BA: 02
        inc     hl                                             ;#50BB: 23
        inc     bc                                             ;#50BC: 03
        ld      a,(hl)                                         ;#50BD: 7E
        ld      d,a                                            ;#50BE: 57
        ld      (bc),a                                         ;#50BF: 02
        ex      de,hl                                          ;#50C0: EB
        ld      a,8                                            ;#50C1: 3E 08
        call    ADD_HL_A                                       ;#50C3: CD D3 48
UPLOAD_ROAD_SEGMENT_TO_VRAM:
        ; Decompresses and uploads a block of road graphics to VRAM
        call    FILL_VRAM_STREAM                               ;#50C6: CD F1 44
        call    WRITE_VRAM_STREAM                              ;#50C9: CD 83 45
        ld      e,(hl)                                         ;#50CC: 5E
UPLOAD_ROAD_SEG_DONE:
        ; Road segment upload finished
        ld      a,(SKY_COLOR)                                  ;#50CD: 3A 0C E1
        ld      c,a                                            ;#50D0: 4F
        ld      b,10h                                          ;#50D1: 06 10
        ld      d,0E1h                                         ;#50D3: 16 E1
INIT_VRAM_LOOP:
        ; Loop through VRAM stream data
        inc     hl                                             ;#50D5: 23
        ld      a,(hl)                                         ;#50D6: 7E
        or      a                                              ;#50D7: B7
        jr      nz,INIT_VRAM_WRITE_VAL                         ;#50D8: 20 01
        ld      a,c                                            ;#50DA: 79
INIT_VRAM_WRITE_VAL:
        ; Write default value to VRAM stream
        ld      (de),a                                         ;#50DB: 12
        inc     de                                             ;#50DC: 13
        djnz    INIT_VRAM_LOOP                                 ;#50DD: 10 F6
INIT_VRAM_DONE:
        ; VRAM initialization finished
        LOAD_NAME_TABLE de, 9, 0                               ;#50DF: 11 20 39
        ld      (VRAM_STREAM_PTR),de                           ;#50E2: ED 53 4E E1
        ld      a,0FFh                                         ;#50E6: 3E FF
        ld      (VRAM_STREAM_STATUS),a                         ;#50E8: 32 70 E1
        ld      hl,VRAM_STREAM_PTR                             ;#50EB: 21 4E E1
        call    WRITE_VRAM_STREAM                              ;#50EE: CD 83 45
        xor     a                                              ;#50F1: AF
        ret                                                    ;#50F2: C9

UPDATE_STAGE_OBJECTS_LOGIC:
        ; Update stage objects and check flags
        call    CHECK_FLICKER_TIMER                            ;#50F3: CD 01 53
        ld      hl,STAGE_SEGMENT_TIMER                         ;#50F6: 21 07 E1
        ld      a,(hl)                                         ;#50F9: 7E
        dec     a                                              ;#50FA: 3D
        ret     nz                                             ;#50FB: C0
        ld      a,(ACTIVE_ROAD_FRAME)                          ;#50FC: 3A 02 E1
        dec     a                                              ;#50FF: 3D
        ret     nz                                             ;#5100: C0
        ld      (hl),a                                         ;#5101: 77
        call    PROCESS_ROAD_SEGMENT_ADVANCE                   ;#5102: CD 96 50
        or      a                                              ;#5105: B7
        ret     nz                                             ;#5106: C0
        ld      hl,(ACTIVE_ROAD_PTR_RIGHT)                     ;#5107: 2A 03 E1
        ld      a,(ROAD_SEGMENT_INDEX)                         ;#510A: 3A 09 E1
        bit     0,a                                            ;#510D: CB 47
        jr      z,FETCH_SEGMENT_DATA_PTR                       ;#510F: 28 03
        ld      hl,(ACTIVE_ROAD_PTR_LEFT)                      ;#5111: 2A 05 E1
FETCH_SEGMENT_DATA_PTR:
        ; Fetch pointer to segment data (index 0)
        xor     a                                              ;#5114: AF
        call    CALC_SEGMENT_ADDR_OFFSET                       ;#5115: CD 73 51
        ret                                                    ;#5118: C9

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
        STAGE_SEGMENTS 3,    0FFh, 1,    77h  ; Stage 0        ;#5119: 03 FF 01 77
        STAGE_SEGMENTS 3,    2,    1,    0    ; Stage 1        ;#511D: 03 02 01 00
        STAGE_SEGMENTS 0FFh, 3,    1,    77h  ; Stage 2        ;#5121: FF 03 01 77
        STAGE_SEGMENTS 2,    3,    0,    1    ; Stage 3        ;#5125: 02 03 00 01
        STAGE_SEGMENTS 2,    0FFh, 0,    0FFh ; Stage 4        ;#5129: 02 FF 00 FF
        STAGE_SEGMENTS 0FFh, 3,    1,    77h  ; Stage 5        ;#512D: FF 03 01 77
        STAGE_SEGMENTS 2,    0,    0FFh, 77h  ; Stage 6        ;#5131: 02 00 FF 77
        STAGE_SEGMENTS 3,    0FFh, 1,    77h  ; Stage 7        ;#5135: 03 FF 01 77
        STAGE_SEGMENTS 0FFh, 77h,  77h,  77h  ; Stage 8 (shortest, 500h) ;#5139: FF 77 77 77
        STAGE_SEGMENTS 0FFh, 2,    3,    0    ; Stage 9 (longest, 2600h; row continues) ;#513D: FF 02 03 00
        STAGE_SEGMENTS 1,    3,    1,    77h  ; Stage 9 (continued, positions 4..7) ;#5141: 01 03 01 77
STAGE_VISUAL_THEME_TABLE:
        ; Table of visual style indices (0=Day/Blue, 1=Night/Red) per stage.
        ; Used by INIT_STAGE to select color/gfx bank.
        ; Format: FORMAT_SKY_COLOR
        db      SKY_DAY_BLUE                                   ;#5145: 00
        db      SKY_NIGHT_RED                                  ;#5146: 01
        db      SKY_DAY_BLUE                                   ;#5147: 00
        db      SKY_DAY_BLUE                                   ;#5148: 00
        db      SKY_DAY_BLUE                                   ;#5149: 00
        db      SKY_NIGHT_RED                                  ;#514A: 01
        db      SKY_DAY_BLUE                                   ;#514B: 00
        db      SKY_NIGHT_RED                                  ;#514C: 01
        db      SKY_DAY_BLUE                                   ;#514D: 00
        db      SKY_DAY_BLUE                                   ;#514E: 00

PROCESS_SCENE_TIMER:
        ; Decrements PENGUIN_SPEED timer, triggers events
        ld      hl,PENGUIN_SPEED                               ;#514F: 21 00 E1
        ld      c,(hl)                                         ;#5152: 4E
        inc     hl                                             ;#5153: 23
        dec     (hl)                                           ;#5154: 35
        jr      z,RESET_SCENE_TIMER_AND_ADVANCE                ;#5155: 28 11
        ld      a,(hl)                                         ;#5157: 7E
        cp      3                                              ;#5158: FE 03
        jp      z,UPDATE_STAGE_OBJECTS_LOGIC                   ;#515A: CA F3 50
        dec     a                                              ;#515D: 3D
        jr      nz,ADVANCE_STAGE_SEG_DONE                      ;#515E: 20 1F
RENDER_LEFT_ROAD_FRAME:
        ; Render left road slot current-frame pattern via WRITE_VRAM_TILES_STREAM
        ld      hl,(ACTIVE_ROAD_PTR_LEFT)                      ;#5160: 2A 05 E1
        ld      a,(ACTIVE_ROAD_FRAME)                          ;#5163: 3A 02 E1
        jr      CALC_SEGMENT_ADDR_OFFSET                       ;#5166: 18 0B

RESET_SCENE_TIMER_AND_ADVANCE:
        ; Reset timer and advance stage data
        ld      (hl),c                                         ;#5168: 71
ADVANCE_STAGE_SEGMENT_DATA:
        ; Increment segment counter and load patterns
        ld      hl,ACTIVE_ROAD_FRAME                           ;#5169: 21 02 E1
        ld      a,(hl)                                         ;#516C: 7E
        inc     (hl)                                           ;#516D: 34
        res     2,(hl)                                         ;#516E: CB 96
CALC_STAGE_SEGMENT_ADDR:
        ; Calculate address of stage segment data
        ld      hl,(ACTIVE_ROAD_PTR_RIGHT)                     ;#5170: 2A 03 E1
CALC_SEGMENT_ADDR_OFFSET:
        ; Calculate address of stage segment data with offset A
        add     a,a                                            ;#5173: 87
        call    ADD_HL_A                                       ;#5174: CD D3 48
        ld      e,(hl)                                         ;#5177: 5E
        inc     hl                                             ;#5178: 23
        ld      d,(hl)                                         ;#5179: 56
        ex      de,hl                                          ;#517A: EB
        call    WRITE_VRAM_TILES_STREAM                        ;#517B: CD 12 45
        ret                                                    ;#517E: C9

ADVANCE_STAGE_SEG_DONE:
        ; Stage segment advancement finished
        ld      b,0                                            ;#517F: 06 00
        dec     a                                              ;#5181: 3D
        jr      z,CHECK_AND_SPAWN_ITEM                         ;#5182: 28 06
        inc     b                                              ;#5184: 04
        srl     c                                              ;#5185: CB 39
        ld      a,(hl)                                         ;#5187: 7E
        cp      c                                              ;#5188: B9
        ret     nz                                             ;#5189: C0
CHECK_AND_SPAWN_ITEM:
        ; Periodically check and spawn fish/flags
        ld      hl,ITEM_TABLE                                  ;#518A: 21 12 E1
        ld      c,b                                            ;#518D: 48
        ld      b,4                                            ;#518E: 06 04
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#5190: 3A E0 E0
        cp      5                                              ;#5193: FE 05
        jr      c,SPAWN_ITEM_LOOP_NEXT                         ;#5195: 38 01
        inc     b                                              ;#5197: 04
SPAWN_ITEM_LOOP_NEXT:
        ; Next iteration of item spawn loop
        ld      a,c                                            ;#5198: 79
        or      a                                              ;#5199: B7
        jr      z,SPAWN_ITEM_CHECK_SLOT                        ;#519A: 28 07
        ld      a,(hl)                                         ;#519C: 7E
        cp      0Bh                                            ;#519D: FE 0B
        ld      a,6                                            ;#519F: 3E 06
        jr      c,SPAWN_ITEM_SKIP                              ;#51A1: 38 22
SPAWN_ITEM_CHECK_SLOT:
        ; Check if item slot is free
        ld      a,(hl)                                         ;#51A3: 7E
        or      a                                              ;#51A4: B7
        ld      a,6                                            ;#51A5: 3E 06
        jr      z,SPAWN_ITEM_SKIP                              ;#51A7: 28 1C
        inc     (hl)                                           ;#51A9: 34
        ld      a,(hl)                                         ;#51AA: 7E
        cp      10h                                            ;#51AB: FE 10
        jr      c,SPAWN_ITEM_INIT                              ;#51AD: 38 02
        ld      (hl),0                                         ;#51AF: 36 00
SPAWN_ITEM_INIT:
        ; Initialize new item in slot
        inc     hl                                             ;#51B1: 23
        inc     hl                                             ;#51B2: 23
        ld      e,(hl)                                         ;#51B3: 5E
        inc     hl                                             ;#51B4: 23
        ld      d,(hl)                                         ;#51B5: 56
        ex      de,hl                                          ;#51B6: EB
        push    de                                             ;#51B7: D5
        push    bc                                             ;#51B8: C5
        call    WRITE_VRAM_TILES_STREAM                        ;#51B9: CD 12 45
        pop     bc                                             ;#51BC: C1
        pop     de                                             ;#51BD: D1
        inc     hl                                             ;#51BE: 23
        ex      de,hl                                          ;#51BF: EB
        ld      (hl),d                                         ;#51C0: 72
        dec     hl                                             ;#51C1: 2B
        ld      (hl),e                                         ;#51C2: 73
        ld      a,4                                            ;#51C3: 3E 04
SPAWN_ITEM_SKIP:
        ; Skip to next slot
        call    ADD_HL_A                                       ;#51C5: CD D3 48
        djnz    SPAWN_ITEM_LOOP_NEXT                           ;#51C8: 10 CE
        call    CHECK_SPECIAL_ITEM_COLLISION                   ;#51CA: CD A9 75
        call    HANDLE_SPECIAL_ITEM_EVENT                      ;#51CD: CD FC 77
        call    CHECK_ITEM_COLLISIONS                          ;#51D0: CD 1E 4D
        call    CHECK_COLLISIONS_WHILE_LOCKED                  ;#51D3: CD 6B 4D
        ret                                                    ;#51D6: C9

UPDATE_ITEMS:
        ; Main loop for updating items and sequences
        call    START_SEQUENCE_CHECK                           ;#51D7: CD EC 47
        ld      hl,(STAGE_DISTANCE_BCD)                        ;#51DA: 2A E5 E0
        ld      a,h                                            ;#51DD: 7C
        and     a                                              ;#51DE: A7
        jr      nz,TICK_ITEM_TIMER                             ;#51DF: 20 04
        ld      a,l                                            ;#51E1: 7D
        cp      86h                                            ;#51E2: FE 86
        ret     c                                              ;#51E4: D8
TICK_ITEM_TIMER:
        ; Tick item-timer countdown; reload from period and walk ITEM_TABLE on expiry
        ld      hl,ITEM_TICK_PERIOD                            ;#51E5: 21 0E E1
        ld      a,(hl)                                         ;#51E8: 7E
        inc     hl                                             ;#51E9: 23
        dec     (hl)                                           ;#51EA: 35
        ret     nz                                             ;#51EB: C0
        ld      (hl),a                                         ;#51EC: 77
        ld      hl,ITEM_TABLE                                  ;#51ED: 21 12 E1
        ld      b,3                                            ;#51F0: 06 03
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#51F2: 3A E0 E0
        cp      5                                              ;#51F5: FE 05
        jr      c,CHECK_ACTIVE_ITEM_SLOT                       ;#51F7: 38 01
        inc     b                                              ;#51F9: 04
CHECK_ACTIVE_ITEM_SLOT:
        ; Check for active item slot
        ld      a,(hl)                                         ;#51FA: 7E
        or      a                                              ;#51FB: B7
        jr      z,UPDATE_ITEM_STATE                            ;#51FC: 28 08
        ld      a,6                                            ;#51FE: 3E 06
        call    ADD_HL_A                                       ;#5200: CD D3 48
        djnz    CHECK_ACTIVE_ITEM_SLOT                         ;#5203: 10 F5
        ret                                                    ;#5205: C9

UPDATE_ITEM_STATE:
        ; Update state of active item
        ; Runs periodically for entities spawned by START_SEQUENCE_CHECK. Processes
        ; 8-byte command streams divided into 4-byte packets. Instruction set (1 byte):
        ; - 00h-0Fh: Select entry from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: Set movement state (stored at ITEM_TABLE + 0).
        ; - FFh: End of sequence/Idle.
        inc     (hl)                                           ;#5206: 34
        inc     hl                                             ;#5207: 23
        ex      de,hl                                          ;#5208: EB
        ld      hl,ITEM_COMMAND_INDEX                          ;#5209: 21 11 E1
        inc     (hl)                                           ;#520C: 34
        res     3,(hl)                                         ;#520D: CB 9E
        ld      a,(hl)                                         ;#520F: 7E
        ld      hl,(SEQUENCE_DATA_PTR)                         ;#5210: 2A 8B E1
        call    ADD_HL_A                                       ;#5213: CD D3 48
        ld      c,(hl)                                         ;#5216: 4E
        push    de                                             ;#5217: D5
        call    CHECK_SEQUENCE_STATUS                          ;#5218: CD DA 47
        pop     de                                             ;#521B: D1
        ld      a,c                                            ;#521C: 79
        inc     a                                              ;#521D: 3C
        jr      z,STORE_ITEM_STATE                             ;#521E: 28 3E
        dec     a                                              ;#5220: 3D
        bit     4,a                                            ;#5221: CB 67
        jr      z,SET_ITEM_MOVE_OVERRIDE_DONE                  ;#5223: 28 0C
        ld      hl,ITEM_MOVE_OVERRIDE_FLAG                     ;#5225: 21 90 E1
        ld      (hl),1                                         ;#5228: 36 01
        inc     hl                                             ;#522A: 23
        and     3                                              ;#522B: E6 03
        ld      c,a                                            ;#522D: 4F
        ld      (hl),a                                         ;#522E: 77
        jr      PROCESS_ITEM_MOVEMENT                          ;#522F: 18 0B

SET_ITEM_MOVE_OVERRIDE_DONE:
        ; Item-move override setup finished
        ld      a,c                                            ;#5231: 79
        or      a                                              ;#5232: B7
        jr      z,PROCESS_ITEM_MOVEMENT                        ;#5233: 28 07
        ld      a,(PENGUIN_SIDE_FLAG)                          ;#5235: 3A FC E0
        or      a                                              ;#5238: B7
        jr      z,PROCESS_ITEM_MOVEMENT                        ;#5239: 28 01
        inc     c                                              ;#523B: 0C
PROCESS_ITEM_MOVEMENT:
        ; Handle movement for item
        ex      de,hl                                          ;#523C: EB
        call    SAVE_ITEM_DATA                                 ;#523D: CD 62 52
        ld      a,(ITEM_MOVE_OVERRIDE_FLAG)                    ;#5240: 3A 90 E1
        rra                                                    ;#5243: 1F
        ret     nc                                             ;#5244: D0
        ld      a,(ITEM_MOVE_TOGGLE)                           ;#5245: 3A 91 E1
        cpl                                                    ;#5248: 2F
        and     3                                              ;#5249: E6 03
        ld      c,a                                            ;#524B: 4F
        ld      hl,ITEM_DATA_LATCH                             ;#524C: 21 2A E1
        ld      a,(hl)                                         ;#524F: 7E
        or      a                                              ;#5250: B7
        jr      nz,CLEAR_ITEM_MOVE_OVERRIDE                    ;#5251: 20 05
        inc     (hl)                                           ;#5253: 34
        inc     hl                                             ;#5254: 23
        call    SAVE_ITEM_DATA                                 ;#5255: CD 62 52
CLEAR_ITEM_MOVE_OVERRIDE:
        ; Clears ITEM_MOVE_OVERRIDE_FLAG at end of item-state update (legacy name)
        ld      hl,ITEM_MOVE_OVERRIDE_FLAG                     ;#5258: 21 90 E1
        ld      (hl),0                                         ;#525B: 36 00
        ret                                                    ;#525D: C9

STORE_ITEM_STATE:
        ; Store updated item state
        ex      de,hl                                          ;#525E: EB
        dec     hl                                             ;#525F: 2B
        ld      (hl),a                                         ;#5260: 77
        ret                                                    ;#5261: C9

SAVE_ITEM_DATA:
        ; Save item data to table
        ld      (hl),c                                         ;#5262: 71
        inc     hl                                             ;#5263: 23
        ld      de,ITEM_PROPERTIES_TABLE                       ;#5264: 11 7B 52
        ld      a,c                                            ;#5267: 79
        add     a,a                                            ;#5268: 87
        ld      c,a                                            ;#5269: 4F
        add     a,a                                            ;#526A: 87
        add     a,c                                            ;#526B: 81
        call    ADD_DE_A                                       ;#526C: CD D8 48
        ld      a,(de)                                         ;#526F: 1A
        ld      (hl),a                                         ;#5270: 77
        inc     de                                             ;#5271: 13
        inc     hl                                             ;#5272: 23
        ld      a,(de)                                         ;#5273: 1A
        ld      (hl),a                                         ;#5274: 77
        inc     de                                             ;#5275: 13
        inc     hl                                             ;#5276: 23
        ld      (hl),e                                         ;#5277: 73
        inc     hl                                             ;#5278: 23
        ld      (hl),d                                         ;#5279: 72
        ret                                                    ;#527A: C9

ITEM_PROPERTIES_TABLE:
        ; Per-item anim ptr + 2 (low_x, width) X-range pairs; see INTERNALS.md
        ; Format: FORMAT_ITEM_PROPERTIES
        ; - 6 bytes per entry: animation ptr (word, LE) then four collision bytes
        ; consumed by COLLISION_CHECK_LOOP as two (low_x, width) X-range pairs.
        ; - Small hole: x1=1 (skip-X sentinel) routes straight to stun; (w1, x2) =
        ; stun (low_x, width), w2 unused. Big hole: (x1, w1) = fall zone,
        ; (x2, w2) = stun zone. Flag: (x1, w1) = pickup zone, (x2, w2) unused.
        ; - See INTERNALS.md for the full overloaded layout.
        ITEM_PROP ANIM_SMALL_HOLE_CENTER, 1, 53h, 3Ah, 0       ;#527B: D3 6E 01 53 3A 00
        ITEM_PROP ANIM_SMALL_HOLE_LEFT, 1, 13h, 3Bh, 0         ;#5281: 8C 6F 01 13 3B 00
        ITEM_PROP ANIM_SMALL_HOLE_RIGHT, 1, 92h, 3Bh, 0        ;#5287: 4B 70 01 92 3B 00
        ITEM_PROP ANIM_BIG_HOLE_LEFT, 2Bh, 5Bh, 10h, 90h       ;#528D: A3 6B 2B 5B 10 90
        ITEM_PROP ANIM_BIG_HOLE_RIGHT, 64h, 53h, 48h, 88h      ;#5293: 3F 6D 64 53 48 88
        ITEM_PROP ANIM_FLAG_RIGHT, 80h, 2Ch, 0, 0              ;#5299: 82 71 80 2C 00 00
        ITEM_PROP ANIM_FLAG_LEFT, 2Eh, 2Ch, 0, 0               ;#529F: 0A 71 2E 2C 00 00

CHECK_DISTANCE_MILESTONE:
        ; Checks distance for periodic events
        ld      hl,(STAGE_DISTANCE_BCD)                        ;#52A5: 2A E5 E0
        ld      a,h                                            ;#52A8: 7C
        and     1                                              ;#52A9: E6 01
        ret     z                                              ;#52AB: C8
        ld      a,l                                            ;#52AC: 7D
        cp      82h                                            ;#52AD: FE 82
        ret     nz                                             ;#52AF: C0
        ld      hl,DISTANCE_EVENT_TICK                         ;#52B0: 21 E2 E0
        ld      a,(hl)                                         ;#52B3: 7E
        inc     (hl)                                           ;#52B4: 34
        srl     a                                              ;#52B5: CB 3F
        push    af                                             ;#52B7: F5
        ld      hl,DISTANCE_EVENT_TABLE                        ;#52B8: 21 91 53
        call    ADD_HL_A                                       ;#52BB: CD D3 48
        pop     af                                             ;#52BE: F1
        ld      a,(hl)                                         ;#52BF: 7E
        jr      c,DECODE_DISTANCE_EVENT_NIBBLE                 ;#52C0: 38 04
        rra                                                    ;#52C2: 1F
        rra                                                    ;#52C3: 1F
        rra                                                    ;#52C4: 1F
        rra                                                    ;#52C5: 1F
DECODE_DISTANCE_EVENT_NIBBLE:
        ; Decode one 4-bit nibble from DISTANCE_EVENT_TABLE
        ld      c,a                                            ;#52C6: 4F
        and     3                                              ;#52C7: E6 03
        cp      3                                              ;#52C9: FE 03
        ret     z                                              ;#52CB: C8
        bit     3,c                                            ;#52CC: CB 59
        jr      z,SET_DISTANCE_EVENT_INDEX                     ;#52CE: 28 02
        set     1,a                                            ;#52D0: CB CF
SET_DISTANCE_EVENT_INDEX:
        ; Store decoded index in DISTANCE_EVENT_INDEX (+ secondary-slot flag)
        ld      hl,DISTANCE_EVENT_INDEX                        ;#52D2: 21 94 E1
        ld      (hl),a                                         ;#52D5: 77
        inc     hl                                             ;#52D6: 23
        bit     2,c                                            ;#52D7: CB 51
        jr      z,PROCESS_DYNAMIC_OBJ_ITER                     ;#52D9: 28 02
        ld      (hl),2                                         ;#52DB: 36 02
PROCESS_DYNAMIC_OBJ_ITER:
        ; Next dynamic object iteration
        inc     hl                                             ;#52DD: 23
        ld      (hl),1                                         ;#52DE: 36 01
        inc     hl                                             ;#52E0: 23
        ld      (hl),0                                         ;#52E1: 36 00
        inc     hl                                             ;#52E3: 23
        ld      a,(PENGUIN_SPEED)                              ;#52E4: 3A 00 E1
        srl     a                                              ;#52E7: CB 3F
        srl     a                                              ;#52E9: CB 3F
        ld      (hl),a                                         ;#52EB: 77
        call    PREPARE_CURVE_OVERLAY_ICE                      ;#52EC: CD 76 54
DRAW_DISTANCE_EVENT_STREAM:
        ; Draw the stream selected by DISTANCE_EVENT_INDEX (entries 0-3)
        ld      hl,DISTANCE_EVENT_STREAMS                      ;#52EF: 21 B2 53
WRITE_VRAM_STREAM_INDEXED:
        ; Loads a stream pointer from HL[index*2] and writes to VRAM
        ld      a,(DISTANCE_EVENT_INDEX)                       ;#52F2: 3A 94 E1
        add     a,a                                            ;#52F5: 87
        call    ADD_HL_A                                       ;#52F6: CD D3 48
        ld      e,(hl)                                         ;#52F9: 5E
        inc     hl                                             ;#52FA: 23
        ld      d,(hl)                                         ;#52FB: 56
        ex      de,hl                                          ;#52FC: EB
        call    WRITE_VRAM_STREAM                              ;#52FD: CD 83 45
        ret                                                    ;#5300: C9

CHECK_FLICKER_TIMER:
        ; Check if flicker timer is active
        ld      a,(PENGUIN_DRIFT_FLAG)                         ;#5301: 3A 96 E1
        or      a                                              ;#5304: B7
        ret     z                                              ;#5305: C8
        ld      bc,1Fh                                         ;#5306: 01 1F 00
        ld      a,(DISTANCE_EVENT_INDEX)                       ;#5309: 3A 94 E1
        rra                                                    ;#530C: 1F
        jr      c,FLICKER_BUFFER_SHIFT                         ;#530D: 38 10
        ld      a,(FLICKER_SPRITE_BUFFER)                      ;#530F: 3A 50 E1
        ld      hl,FLICKER_SPRITE_BUFFER+1                     ;#5312: 21 51 E1
        ld      de,FLICKER_SPRITE_BUFFER                       ;#5315: 11 50 E1
        ldir                                                   ;#5318: ED B0
        ld      (FLICKER_BUFFER_LAST),a                        ;#531A: 32 6F E1
        jr      UPDATE_MISC_TASKS                              ;#531D: 18 0E

FLICKER_BUFFER_SHIFT:
        ; Shifts sprite attribute history buffer to create flickering effect
        ld      a,(FLICKER_BUFFER_LAST)                        ;#531F: 3A 6F E1
        ld      hl,FLICKER_BUFFER_LAST-1                       ;#5322: 21 6E E1
        ld      de,FLICKER_BUFFER_LAST                         ;#5325: 11 6F E1
        lddr                                                   ;#5328: ED B8
        ld      (FLICKER_SPRITE_BUFFER),a                      ;#532A: 32 50 E1
UPDATE_MISC_TASKS:
        ; Tick the 16-frame pacer (E197); run secondary-slot direction toggle
        call    INIT_VRAM_DONE                                 ;#532D: CD DF 50
        ld      hl,MISC_TICK_PACER                             ;#5330: 21 97 E1
        inc     (hl)                                           ;#5333: 34
        ld      a,(hl)                                         ;#5334: 7E
        and     0Fh                                            ;#5335: E6 0F
        jr      nz,CHECK_DISTANCE_PERIODIC                     ;#5337: 20 10
        dec     hl                                             ;#5339: 2B
        dec     hl                                             ;#533A: 2B
        cp      (hl)                                           ;#533B: BE
        jr      z,CHECK_DISTANCE_PERIODIC                      ;#533C: 28 0B
        dec     (hl)                                           ;#533E: 35
        jr      nz,CHECK_DISTANCE_PERIODIC                     ;#533F: 20 08
        dec     hl                                             ;#5341: 2B
        ld      a,(hl)                                         ;#5342: 7E
        xor     1                                              ;#5343: EE 01
        ld      (hl),a                                         ;#5345: 77
        call    DRAW_DISTANCE_EVENT_STREAM                     ;#5346: CD EF 52
CHECK_DISTANCE_PERIODIC:
        ; Even-hundreds distance milestone (low<45h, every 16 frames)
        ld      hl,(STAGE_DISTANCE_BCD)                        ;#5349: 2A E5 E0
        ld      a,h                                            ;#534C: 7C
        and     1                                              ;#534D: E6 01
        ret     nz                                             ;#534F: C0
        ld      a,l                                            ;#5350: 7D
        cp      45h                                            ;#5351: FE 45
        ret     nc                                             ;#5353: D0
        ld      hl,MISC_TICK_PACER                             ;#5354: 21 97 E1
        ld      a,(hl)                                         ;#5357: 7E
        and     0Fh                                            ;#5358: E6 0F
        ret     nz                                             ;#535A: C0
        dec     hl                                             ;#535B: 2B
        ld      (hl),a                                         ;#535C: 77
        ld      hl,DISTANCE_EVENT_STREAMS+8                    ;#535D: 21 BA 53
        call    WRITE_VRAM_STREAM_INDEXED                      ;#5360: CD F2 52
        call    PREPARE_CURVE_OVERLAY_WATER                    ;#5363: CD 71 54
HANDLE_PENGUIN_DRIFT:
        ; Auto X-drift driven by latest distance-milestone scenery side; see INTERNALS.md
        ld      hl,PENGUIN_DRIFT_FLAG                          ;#5366: 21 96 E1
        ld      a,(hl)                                         ;#5369: 7E
        or      a                                              ;#536A: B7
        ret     z                                              ;#536B: C8
        inc     hl                                             ;#536C: 23
        inc     hl                                             ;#536D: 23
        dec     (hl)                                           ;#536E: 35
        ret     nz                                             ;#536F: C0
        ld      a,(PENGUIN_SPEED)                              ;#5370: 3A 00 E1
        srl     a                                              ;#5373: CB 3F
        srl     a                                              ;#5375: CB 3F
        ld      (hl),a                                         ;#5377: 77
        ld      hl,DEBUG_FLAGS                                 ;#5378: 21 D1 E0
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#537B: ED 5B 78 E0
        ld      a,(DISTANCE_EVENT_INDEX)                       ;#537F: 3A 94 E1
        rra                                                    ;#5382: 1F
        jr      c,DRIFT_MOVE_RIGHT                             ;#5383: 38 06
        call    MOVE_PENGUIN_LEFT                              ;#5385: CD 71 4C
        jp      SWAP_AND_UPDATE_PENGUIN_COORDS                 ;#5388: C3 97 4B

DRIFT_MOVE_RIGHT:
        ; Right-direction branch of HANDLE_PENGUIN_DRIFT
        call    MOVE_PENGUIN_RIGHT                             ;#538B: CD 8E 4C
        jp      SWAP_AND_UPDATE_PENGUIN_COORDS                 ;#538E: C3 97 4B

DISTANCE_EVENT_TABLE:
        ; Table of event flags based on distance (FF=End)
        ; Format: FORMAT_DISTANCE_EVENT
        ; - Each nibble: bits 0-1 = sign index (0..2; 3=skip), bit 2 = secondary-slot
        ; flag, bit 3 = forces bit 1 of the index (8h=index 2, Fh and 9h skip).
        DISTANCE_EVENT 0Fh, 0Fh                                ;#5391: FF
        DISTANCE_EVENT 0Fh, 0Fh                                ;#5392: FF
        DISTANCE_EVENT 0Fh, 0Fh                                ;#5393: FF
        DISTANCE_EVENT 9, 9                                    ;#5394: 99
        DISTANCE_EVENT 0Fh, 8                                  ;#5395: F8
        DISTANCE_EVENT 8, 0                                    ;#5396: 80
        DISTANCE_EVENT 0Fh, 0Fh                                ;#5397: FF
        DISTANCE_EVENT 0, 0Fh                                  ;#5398: 0F
        DISTANCE_EVENT 9, 0                                    ;#5399: 90
        DISTANCE_EVENT 0Fh, 8                                  ;#539A: F8
        DISTANCE_EVENT 8, 0Fh                                  ;#539B: 8F
        DISTANCE_EVENT 0Fh, 9                                  ;#539C: F9
        DISTANCE_EVENT 1, 0Fh                                  ;#539D: 1F
        DISTANCE_EVENT 1, 0Fh                                  ;#539E: 1F
        DISTANCE_EVENT 0Fh, 8                                  ;#539F: F8
        DISTANCE_EVENT 5, 5                                    ;#53A0: 55
        DISTANCE_EVENT 5, 0Fh                                  ;#53A1: 5F
        DISTANCE_EVENT 0, 9                                    ;#53A2: 09
        DISTANCE_EVENT 0Fh, 4                                  ;#53A3: F4
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53A4: FF
        DISTANCE_EVENT 0Fh, 0                                  ;#53A5: F0
        DISTANCE_EVENT 1, 0Fh                                  ;#53A6: 1F
        DISTANCE_EVENT 0Fh, 0                                  ;#53A7: F0
        DISTANCE_EVENT 9, 0Fh                                  ;#53A8: 9F
        DISTANCE_EVENT 9, 0                                    ;#53A9: 90
        DISTANCE_EVENT 0Fh, 5                                  ;#53AA: F5
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53AB: FF
        DISTANCE_EVENT 0Fh, 1                                  ;#53AC: F1
        DISTANCE_EVENT 8, 0Fh                                  ;#53AD: 8F
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53AE: FF
        DISTANCE_EVENT 9, 0                                    ;#53AF: 90
        DISTANCE_EVENT 9, 9                                    ;#53B0: 99
        DISTANCE_EVENT 0, 0Fh                                  ;#53B1: 0F

DISTANCE_EVENT_STREAMS:
        ; 8-entry pointer table of distance-milestone VRAM streams
        dw      STREAM_ICE_LEFT                                ;#53B2: C2 53
        dw      STREAM_ICE_RIGHT                               ;#53B4: D3 53
        dw      STREAM_WATER_CURVE_LEFT                        ;#53B6: F5 53
        dw      STREAM_WATER_CURVE_RIGHT                       ;#53B8: 14 54
        dw      STREAM_SMALL_ICE                               ;#53BA: E4 53
        dw      STREAM_SMALL_ICE                               ;#53BC: E4 53
        dw      STREAM_WATER_STRAIGHT_RIGHT                    ;#53BE: 52 54
        dw      STREAM_WATER_STRAIGHT_LEFT                     ;#53C0: 33 54

STREAM_ICE_LEFT:
        ; VRAM stream for ice patch (left-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#53C2: 49 39
        VRAM_TILES "1414131315303031101010323323"              ;#53C4: 14 14 13 13 15 30 30 31 10 10 10 32 33 23
        STREAM_BLOCK_END                                       ;#53D2: FF

STREAM_ICE_RIGHT:
        ; VRAM stream for ice patch (right-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#53D3: 49 39
        VRAM_TILES "2374321010103130301513131414"              ;#53D5: 23 74 32 10 10 10 31 30 30 15 13 13 14 14
        STREAM_BLOCK_END                                       ;#53E3: FF

STREAM_SMALL_ICE:
        ; VRAM stream for small ice patch
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#53E4: 49 39
        VRAM_TILES "1514131252100F0F101112131415"              ;#53E6: 15 14 13 12 52 10 0F 0F 10 11 12 13 14 15
        STREAM_BLOCK_END                                       ;#53F4: FF

STREAM_WATER_CURVE_LEFT:
        ; VRAM stream for curved water (left-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#53F5: 49 39
        VRAM_TILES "14141313153030311010104147535354"          ;#53F7: 14 14 13 13 15 30 30 31 10 10 10 41 47 53 53 54
        VRAM_TILES "54545454545454"                            ;#5407: 54 54 54 54 54 54 54
        STREAM_NEXT_BLOCK                                      ;#540E: FE
        VRAM_NAME_TABLE 0Bh, 12h                               ;#540F: 72 39
        VRAM_TILES "0F3E"                                      ;#5411: 0F 3E
        STREAM_BLOCK_END                                       ;#5413: FF

STREAM_WATER_CURVE_RIGHT:
        ; VRAM stream for curved water (right-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 0                                 ;#5414: 40 39
        VRAM_TILES "54545454545454545353888210101031"          ;#5416: 54 54 54 54 54 54 54 54 53 53 88 82 10 10 10 31
        VRAM_TILES "30301513131414"                            ;#5426: 30 30 15 13 13 14 14
        STREAM_NEXT_BLOCK                                      ;#542D: FE
        VRAM_NAME_TABLE 0Bh, 0Ch                               ;#542E: 6C 39
        VRAM_TILES "7F0F"                                      ;#5430: 7F 0F
        STREAM_BLOCK_END                                       ;#5432: FF

STREAM_WATER_STRAIGHT_LEFT:
        ; VRAM stream for straight water (left-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 0                                 ;#5433: 40 39
        VRAM_TILES "040404040404040404040404047D7A0F"          ;#5435: 04 04 04 04 04 04 04 04 04 04 04 04 04 7D 7A 0F
        VRAM_TILES "0F101112131415"                            ;#5445: 0F 10 11 12 13 14 15
        STREAM_NEXT_BLOCK                                      ;#544C: FE
        VRAM_NAME_TABLE 0Bh, 0Ch                               ;#544D: 6C 39
        VRAM_TILES "7978"                                      ;#544F: 79 78
        STREAM_BLOCK_END                                       ;#5451: FF

STREAM_WATER_STRAIGHT_RIGHT:
        ; VRAM stream for straight water (right-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#5452: 49 39
        VRAM_TILES "1514131252100F0F393C040404040404"          ;#5454: 15 14 13 12 52 10 0F 0F 39 3C 04 04 04 04 04 04
        VRAM_TILES "04040404040404"                            ;#5464: 04 04 04 04 04 04 04
        STREAM_NEXT_BLOCK                                      ;#546B: FE
        VRAM_NAME_TABLE 0Bh, 12h                               ;#546C: 72 39
        VRAM_TILES "3738"                                      ;#546E: 37 38
        STREAM_BLOCK_END                                       ;#5470: FF

PREPARE_CURVE_OVERLAY_WATER:
        ; Set HL=ROAD_WATER_RIGHT_1_INIT for the curve-tile overlay write
        ld      hl,ROAD_WATER_RIGHT_1_INIT                     ;#5471: 21 A1 72
        jr      UPDATE_CURVE_OVERLAY_SEGMENT                   ;#5474: 18 03

PREPARE_CURVE_OVERLAY_ICE:
        ; Set HL=ROAD_ICE_RIGHT_1_INIT for the curve-tile overlay write
        ld      hl,ROAD_ICE_RIGHT_1_INIT                       ;#5476: 21 2F 72
UPDATE_CURVE_OVERLAY_SEGMENT:
        ; Upload curve road-segment tiles when DISTANCE_EVENT_INDEX bit 1 is set
        ld      a,(DISTANCE_EVENT_INDEX)                       ;#5479: 3A 94 E1
        bit     1,a                                            ;#547C: CB 4F
        ret     z                                              ;#547E: C8
        rra                                                    ;#547F: 1F
        ld      a,(hl)                                         ;#5480: 7E
        jr      nc,UPDATE_CURVE_OVERLAY_DONE                   ;#5481: 30 02
        sub     10h                                            ;#5483: D6 10
UPDATE_CURVE_OVERLAY_DONE:
        ; Rejoin point in UPDATE_CURVE_OVERLAY_SEGMENT after the curve-flag check
        ld      e,a                                            ;#5485: 5F
        jp      UPLOAD_ROAD_SEG_DONE                           ;#5486: C3 CD 50

UPDATE_VICTORY_PENGUIN_ANIM:
        ; Update penguin waddling animation during goal sequence
        ld      a,(FRAME_COUNTER)                              ;#5489: 3A 03 E0
        and     3                                              ;#548C: E6 03
        ret     nz                                             ;#548E: C0
        inc     c                                              ;#548F: 0C
        jr      nz,CALC_VICTORY_WADDLE_OFFSET                  ;#5490: 20 26
        ld      a,(VICTORY_WADDLE_BASE_X)                      ;#5492: 3A 39 E1
        ld      c,a                                            ;#5495: 4F
        xor     a                                              ;#5496: AF
        ld      b,a                                            ;#5497: 47
        ld      hl,70h                                         ;#5498: 21 70 00
        sbc     hl,bc                                          ;#549B: ED 42
        ld      a,(VICTORY_WADDLE_STEP)                        ;#549D: 3A 38 E1
        ld      b,a                                            ;#54A0: 47
        ld      e,l                                            ;#54A1: 5D
        ld      d,h                                            ;#54A2: 54
VICTORY_CALC_LOOP:
        ; Loop for victory waddle calculation
        add     hl,de                                          ;#54A3: 19
        djnz    VICTORY_CALC_LOOP                              ;#54A4: 10 FD
        ld      a,h                                            ;#54A6: 7C
        rlca                                                   ;#54A7: 07
        rlca                                                   ;#54A8: 07
        rlca                                                   ;#54A9: 07
        rlca                                                   ;#54AA: 07
        and     0F0h                                           ;#54AB: E6 F0
        ld      e,a                                            ;#54AD: 5F
        ld      a,l                                            ;#54AE: 7D
        rrca                                                   ;#54AF: 0F
        rrca                                                   ;#54B0: 0F
        rrca                                                   ;#54B1: 0F
        rrca                                                   ;#54B2: 0F
        and     0Fh                                            ;#54B3: E6 0F
        or      e                                              ;#54B5: B3
        add     a,c                                            ;#54B6: 81
        ld      h,a                                            ;#54B7: 67
CALC_VICTORY_WADDLE_OFFSET:
        ; Calculate new Y-offset for waddle effect
        ld      a,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)       ;#54B8: 3A 78 E0
        dec     a                                              ;#54BB: 3D
        ld      l,a                                            ;#54BC: 6F
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#54BD: CD C1 4B
        call    UPDATE_PENGUIN_SPRITES                         ;#54C0: CD A6 4C
        ld      hl,VICTORY_WADDLE_STEP                         ;#54C3: 21 38 E1
        inc     (hl)                                           ;#54C6: 34
        ld      a,10h                                          ;#54C7: 3E 10
        cp      (hl)                                           ;#54C9: BE
        ret                                                    ;#54CA: C9

CYCLE_GOAL_PENGUIN_PATTERNS:
        ; Cycle penguin sprite patterns during victory dance
        xor     a                                              ;#54CB: AF
        ld      (VICTORY_DANCE_COUNTER),a                      ;#54CC: 32 3A E1
UPDATE_VICTORY_DANCE:
        ; Update victory dance animation counter
        ld      hl,VICTORY_DANCE_COUNTER                       ;#54CF: 21 3A E1
        ld      a,(hl)                                         ;#54D2: 7E
        inc     (hl)                                           ;#54D3: 34
        ld      hl,VICTORY_DANCE_FRAME_1                       ;#54D4: 21 FC 54
        rra                                                    ;#54D7: 1F
        jr      nc,SET_VICTORY_FRAME_2                         ;#54D8: 30 03
        ld      hl,VICTORY_DANCE_FRAME_2                       ;#54DA: 21 10 55
SET_VICTORY_FRAME_2:
        ; Select second frame of victory dance
        call    WRITE_VRAM_TILES_STREAM                        ;#54DD: CD 12 45
        ret                                                    ;#54E0: C9

LOAD_VICTORY_GFX:
        ; Load supplementary sprite data for victory sequence
        ld      hl,VICTORY_SPRITE_PATTERNS                     ;#54E1: 21 3B 6B
        call    DECOMPRESS_VRAM_INDIRECT                       ;#54E4: CD 3F 45
        ld      hl,GOAL_FLAG_ATTRIBUTES                        ;#54E7: 21 00 67
        ld      de,SAT_MIRROR + SPRITE_AUX + ATTR_Y            ;#54EA: 11 6C E0
        ld      bc,10h                                         ;#54ED: 01 10 00
        ldir                                                   ;#54F0: ED B0
        call    SYNC_SPRITE_ATTRIBUTES_ALL                     ;#54F2: CD 9D 66
        ld      hl,VICTORY_DANCE_FRAME_3                       ;#54F5: 21 1A 55
        call    WRITE_VRAM_TILES_STREAM                        ;#54F8: CD 12 45
        ret                                                    ;#54FB: C9

VICTORY_DANCE_FRAME_1:
        ; Victory dance tile-stream frame 1
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 8                              ;#54FC: E1
        VRAM_TILE_COLUMN 0Fh                                   ;#54FD: EF
        VRAM_TILES "B6B7"                                      ;#54FE: B6 B7
        VRAM_TILE_COLUMN 0Eh                                   ;#5500: EE
        VRAM_TILES "B8B9BABB"                                  ;#5501: B8 B9 BA BB
        VRAM_TILE_COLUMN 0Eh                                   ;#5505: EE
        VRAM_TILES "BEBFC0BC"                                  ;#5506: BE BF C0 BC
        VRAM_TILE_COLUMN 0Eh                                   ;#550A: EE
        VRAM_TILES "C3C4C5C6"                                  ;#550B: C3 C4 C5 C6
        db      00h                                            ;#550F: 00

VICTORY_DANCE_FRAME_2:
        ; Victory dance tile-stream frame 2
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3A00h, 1                              ;#5510: 02
        VRAM_TILE_COLUMN 0Eh                                   ;#5511: EE
        VRAM_TILES "C2"                                        ;#5512: C2
        VRAM_TILE_COLUMN 0Eh                                   ;#5513: EE
        VRAM_TILES "BDC1"                                      ;#5514: BD C1
        VRAM_TILE_COLUMN 0Eh                                   ;#5516: EE
        VRAM_TILES "C7C8"                                      ;#5517: C7 C8
        db      00h                                            ;#5519: 00

VICTORY_DANCE_FRAME_3:
        ; Victory dance tile-stream frame 3 (penguin on pedestal)
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 8                              ;#551A: E1
        VRAM_TILE_COLUMN 0Eh                                   ;#551B: EE
        VRAM_TILES "D2D5D8"                                    ;#551C: D2 D5 D8
        VRAM_TILE_COLUMN 0Eh                                   ;#551F: EE
        VRAM_TILES "D3D6D9DB"                                  ;#5520: D3 D6 D9 DB
        VRAM_TILE_COLUMN 0Eh                                   ;#5524: EE
        VRAM_TILES "D4D7DADC"                                  ;#5525: D4 D7 DA DC
        VRAM_TILE_COLUMN 0Eh                                   ;#5529: EE
        VRAM_TILES "DDDEDF0F"                                  ;#552A: DD DE DF 0F
        db      00h                                            ;#552E: 00

INIT_GOAL_GRAPHICS:
        ; Decompress and initialize goal-specific VRAM graphics
        ld      hl,GFX_GOAL_COLOR_PATCH                        ;#552F: 21 0A 66
        LOAD_VRAM_WRITE de, 1100h                              ;#5532: 11 00 51
        call    DECOMPRESS_VRAM_DIRECT                         ;#5535: CD 43 45
        ld      hl,COUNTRY_NAME_POINTERS                       ;#5538: 21 89 55
        ld      a,(CURRENT_STAGE_INDEX)                        ;#553B: 3A E1 E0
        ld      c,a                                            ;#553E: 4F
        add     a,a                                            ;#553F: 87
        call    ADD_HL_A                                       ;#5540: CD D3 48
        ld      e,(hl)                                         ;#5543: 5E
        inc     hl                                             ;#5544: 23
        ld      d,(hl)                                         ;#5545: 56
        ex      de,hl                                          ;#5546: EB
        call    WRITE_VRAM_STREAM                              ;#5547: CD 83 45
        ld      hl,FLAG_PTR_TABLE                              ;#554A: 21 02 56
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#554D: 3A E0 E0
        and     0Fh                                            ;#5550: E6 0F
        add     a,a                                            ;#5552: 87
        call    ADD_HL_A                                       ;#5553: CD D3 48
        ld      e,(hl)                                         ;#5556: 5E
        inc     hl                                             ;#5557: 23
        ld      d,(hl)                                         ;#5558: 56
        ex      de,hl                                          ;#5559: EB
        ld      de,GFX_FLAG_VRAM_DEST                          ;#555A: 11 40 5F
        call    DECOMPRESS_VRAM_DIRECT                         ;#555D: CD 43 45
        ld      a,(hl)                                         ;#5560: 7E
        ld      (SAT_MIRROR + SPRITE_4 + ATTR_COLOR),a         ;#5561: 32 63 E0
        inc     hl                                             ;#5564: 23
        ld      a,(hl)                                         ;#5565: 7E
        ld      (SAT_MIRROR + SPRITE_5 + ATTR_COLOR),a         ;#5566: 32 67 E0
        jr      SYNC_GOAL_FLAG_SPRITES                         ;#5569: 18 11

UPDATE_GOAL_FLAG_POSITION:
        ; Handle the flag ascending/positioning logic
        ld      a,(SAT_MIRROR + SPRITE_4 + ATTR_Y)             ;#556B: 3A 60 E0
        sub     2                                              ;#556E: D6 02
        cp      36h                                            ;#5570: FE 36
        ret     z                                              ;#5572: C8
        ld      (SAT_MIRROR + SPRITE_4 + ATTR_Y),a             ;#5573: 32 60 E0
        ld      (SAT_MIRROR + SPRITE_5 + ATTR_Y),a             ;#5576: 32 64 E0
        ld      (SAT_MIRROR + SPRITE_6 + ATTR_Y),a             ;#5579: 32 68 E0
SYNC_GOAL_FLAG_SPRITES:
        ; Copy flag sprite attributes to VRAM
        ld      hl,SAT_MIRROR + SPRITE_4 + ATTR_Y              ;#557C: 21 60 E0
        LOAD_SPRITE_ATTR de, 4, 0                              ;#557F: 11 10 3B
        ld      bc,0Ch                                         ;#5582: 01 0C 00
        call    COPY_RAM_TO_VRAM                               ;#5585: CD C7 44
        ret                                                    ;#5588: C9

COUNTRY_NAME_POINTERS:
        ; Table of pointers to country name strings (Japan to South Pole)
        dw      TXT_JAPAN                                      ;#5589: 9D 55
        dw      TXT_AUSTRALIA                                  ;#558B: A7 55
        dw      TXT_AUSTRALIA                                  ;#558D: A7 55
        dw      TXT_FRANCE                                     ;#558F: B5 55
        dw      TXT_NEW_ZEALAND                                ;#5591: C0 55
        dw      TXT_SOUTH_POLE                                 ;#5593: F9 55
        dw      TXT_USA                                        ;#5595: D0 55
        dw      TXT_USA                                        ;#5597: D0 55
        dw      TXT_ARGENTINA                                  ;#5599: D8 55
        dw      TXT_UK                                         ;#559B: E6 55

TXT_JAPAN:
        ; "JAPAN" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 13                                  ;#559D: CD 3A
        abyte -20h "@JAPAN@"                                   ;#559F: 20 2A 21 30 21 2E 20
        db      0FFh                                           ;#55A6: FF

TXT_AUSTRALIA:
        ; "AUSTRALIA" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 11                                  ;#55A7: CB 3A
        abyte -20h "@AUSTRALIA@"                               ;#55A9: 20 21 35 33 34 32 21 2C 29 21 20
        db      0FFh                                           ;#55B4: FF

TXT_FRANCE:
        ; "FRANCE" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 13                                  ;#55B5: CD 3A
        abyte -20h "@", 0E9h, "RANCE@"                         ;#55B7: 20 C9 32 21 2E 23 25 20
        db      0FFh                                           ;#55BF: FF

TXT_NEW_ZEALAND:
        ; "NEW ZEALAND" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 10                                  ;#55C0: CA 3A
        abyte -20h "@NE", 0EAh, "/", 0EBh, "EALAND@"           ;#55C2: 20 2E 25 CA 0F CB 25 21 2C 21 2E 24 20
        db      0FFh                                           ;#55CF: FF

TXT_USA:
        ; "USA" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 14                                  ;#55D0: CE 3A
        abyte -20h "@USA@"                                     ;#55D2: 20 35 33 21 20
        db      0FFh                                           ;#55D7: FF

TXT_ARGENTINA:
        ; "ARGENTINA" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 11                                  ;#55D8: CB 3A
        abyte -20h "@ARGENTINA@"                               ;#55DA: 20 21 32 27 25 2E 34 29 2E 21 20
        db      0FFh                                           ;#55E5: FF

TXT_UK:
        ; "UNITED KINGDOM" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 9                                   ;#55E6: C9 3A
        abyte -20h "@UNITED/KINGDOM@"                          ;#55E8: 20 35 2E 29 34 25 24 0F 2B 29 2E 27 24 2F 2D 20
        db      0FFh                                           ;#55F8: FF

TXT_SOUTH_POLE:
        ; "SOUTH POLE" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 13                                  ;#55F9: CD 3A
        abyte -20h "@", 0EEh, 0EFh, 0F0h, 0F1h, "@"            ;#55FB: 20 CE CF D0 D1 20
        db      0FFh                                           ;#5601: FF

FLAG_PTR_TABLE:
        ; Pointer table for finish line flag graphics (indexed by last time digit 0-9).
        ; Each flag=64 bytes (2x16x16 sprites overlaid). MSX blocks A,C top / B,D bottom.
        dw      FLAG_DATA_UK                                   ;#5602: DE 56
        dw      FLAG_DATA_JAPAN                                ;#5604: 16 56
        dw      FLAG_DATA_AUSTRALIA                            ;#5606: 2F 56
        dw      FLAG_DATA_AUSTRALIA                            ;#5608: 2F 56
        dw      FLAG_DATA_FRANCE                               ;#560A: 5E 56
        dw      FLAG_DATA_NEW_ZEALAND                          ;#560C: 6B 56
        dw      FLAG_DATA_SOUTH_POLE                           ;#560E: 1B 57
        dw      FLAG_DATA_USA                                  ;#5610: 97 56
        dw      FLAG_DATA_USA                                  ;#5612: 97 56
        dw      FLAG_DATA_ARGENTINA                            ;#5614: BB 56

FLAG_DATA_JAPAN:
        ; Japan flag graphics (red circle on white)
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "0200820307030F82070309008280C003"             ;#5616: 02 00 82 03 07 03 0F 82 07 03 09 00 82 80 C0 03
        dh      "E082C0802700"                                 ;#5626: E0 82 C0 80 27 00
        db      00h                                            ;#562C: 00 06 0F
        FLAG_COLORS COLOR_DARK_RED, COLOR_WHITE                ;#562D

FLAG_DATA_AUSTRALIA:
        ; Australia flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "87CC6D0CFF0C6DCC090087C08000C000"             ;#562F: 87 CC 6D 0C FF 0C 6D CC 09 00 87 C0 80 00 C0 00
        dh      "80C00900070002FF02FB01FF0400893F"             ;#563F: 80 C0 09 00 07 00 02 FF 02 FB 01 FF 04 00 89 3F
        dh      "3B3F3D2F3B3FFFF703FF0400"                     ;#564F: 3B 3F 3D 2F 3B 3F FF F7 03 FF 04 00
        db      00h                                            ;#565B: 00 06 0D
        FLAG_COLORS COLOR_DARK_RED, COLOR_MAGENTA              ;#565C

FLAG_DATA_FRANCE:
        ; France flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "10000C3F04000CF81400"                         ;#565E: 10 00 0C 3F 04 00 0C F8 14 00
        db      00h                                            ;#5668: 00 06 04
        FLAG_COLORS COLOR_DARK_RED, COLOR_DARK_BLUE            ;#5669

FLAG_DATA_NEW_ZEALAND:
        ; New Zealand flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "87CC6D0CFF0C6DCC090087C08000C000"             ;#566B: 87 CC 6D 0C FF 0C 6D CC 09 00 87 C0 80 00 C0 00
        dh      "80C00900070005FF04008C3F3F373F3B"             ;#567B: 80 C0 09 00 07 00 05 FF 04 00 8C 3F 3F 37 3F 3B
        dh      "2F3FFFFFF7FFFF0400"                           ;#568B: 2F 3F FF FF F7 FF FF 04 00
        db      00h                                            ;#5694: 00 06 0D
        FLAG_COLORS COLOR_DARK_RED, COLOR_MAGENTA              ;#5695

FLAG_DATA_USA:
        ; USA flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "070085FF00FF00FF05008BFF00FF00FF"             ;#5697: 07 00 85 FF 00 FF 00 FF 05 00 8B FF 00 FF 00 FF
        dh      "00FF00FF00FF04008655AA55AA55AA1A"             ;#56A7: 00 FF 00 FF 00 FF 04 00 86 55 AA 55 AA 55 AA 1A
        dh      "00"                                           ;#56B7: 00
        db      00h                                            ;#56B8: 00 06 04
        FLAG_COLORS COLOR_DARK_RED, COLOR_DARK_BLUE            ;#56B9

FLAG_DATA_ARGENTINA:
        ; Argentina flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "040084010303010C008480C0C0800800"             ;#56BB: 04 00 84 01 03 03 01 0C 00 84 80 C0 C0 80 08 00
        dh      "04FF040004FF040004FF040004FF0400"             ;#56CB: 04 FF 04 00 04 FF 04 00 04 FF 04 00 04 FF 04 00
        db      00h                                            ;#56DB: 00 0A 07
        FLAG_COLORS COLOR_DARK_YELLOW, COLOR_CYAN              ;#56DC

FLAG_DATA_UK:
        ; United Kingdom flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "8C6131190D01FFFF010D19316104008C"             ;#56DE: 8C 61 31 19 0D 01 FF FF 01 0D 19 31 61 04 00 8C
        dh      "868C98B080FFFF80B0988C860400840C"             ;#56EE: 86 8C 98 B0 80 FF FF 80 B0 98 8C 86 04 00 84 0C
        dh      "84C0E0040084E0C0840C040084302103"             ;#56FE: 84 C0 E0 04 00 84 E0 C0 84 0C 04 00 84 30 21 03
        dh      "07040084070321300400"                         ;#570E: 07 04 00 84 07 03 21 30 04 00
        db      00h                                            ;#5718: 00 08 05
        FLAG_COLORS COLOR_MED_RED, COLOR_LIGHT_BLUE            ;#5719

FLAG_DATA_SOUTH_POLE:
        ; South Pole flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "8B03040A0C2C3E1808080C0705008BC0"             ;#571B: 8B 03 04 0A 0C 2C 3E 18 08 08 0C 07 05 00 8B C0
        dh      "20501030781C141030E0050085000002"             ;#572B: 20 50 10 30 78 1C 14 10 30 E0 05 00 85 00 00 02
        dh      "010303008300001805008500004080C0"             ;#573B: 01 03 03 00 83 00 00 18 05 00 85 00 00 40 80 C0
        dh      "0300830000180500"                             ;#574B: 03 00 83 00 00 18 05 00
        db      00h                                            ;#5753: 00 01 0A
        FLAG_COLORS COLOR_BLACK, COLOR_DARK_YELLOW             ;#5754

HUD_STATIC_TEXT:
        ; Static HUD labels and sign graphics (e.g. "KM", "STAGE")
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 0, 0Ch                                 ;#5756: 0C 38
        abyte -20h "HI@"                                       ;#5758: 28 29 20
        STREAM_NEXT_BLOCK                                      ;#575B: FE
        VRAM_NAME_TABLE 0, 16h                                 ;#575C: 16 38
        abyte -20h "STAGE@"                                    ;#575E: 33 34 21 27 25 20
        STREAM_NEXT_BLOCK                                      ;#5764: FE
        VRAM_NAME_TABLE 1, 2                                   ;#5765: 22 38
        abyte -20h "TIME@"                                     ;#5767: 34 29 2D 25 20
        STREAM_NEXT_BLOCK                                      ;#576C: FE
        VRAM_NAME_TABLE 1, 0Ch                                 ;#576D: 2C 38
        abyte -20h "XZ[    `a"                                 ;#576F: 38 3A 3B 00 00 00 00 40 41
        STREAM_NEXT_BLOCK                                      ;#5778: FE
        VRAM_NAME_TABLE 1, 16h                                 ;#5779: 36 38
        abyte -20h "FQW"                                       ;#577B: 26 31 37
        STREAM_NEXT_BLOCK                                      ;#577E: FE
        VRAM_NAME_TABLE 0, 2                                   ;#577F: 02 38
        abyte -20h "1P@"                                       ;#5781: 11 30 20
        STREAM_BLOCK_END                                       ;#5784: FF

KONAMI_COPYRIGHT_TEXT:
        ; Copyright text stream ("© 1984") for opening animation
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 8, 0Bh                                 ;#5785: 0B 39
        abyte -20h ":;<=>? 1984"                               ;#5787: 1A 1B 1C 1D 1E 1F 00 11 19 18 14
        STREAM_BLOCK_END                                       ;#5792: FF

MSG_PLAY_SELECT:
        ; VRAM message stream for title/logo
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 0Dh, 0Bh                               ;#5793: AB 39
        abyte -20h "PLAY SELECT"                               ;#5795: 30 2C 21 39 00 33 25 2C 25 23 34
        STREAM_NEXT_BLOCK                                      ;#57A0: FE
        VRAM_NAME_TABLE 10h, 6                                 ;#57A1: 06 3A
        abyte -20h "1@", 5Ch, "]  PLAY ^_ JOYSTICK"            ;#57A3: 11 20 3C 3D 00 00 30 2C 21 39 00 3E 3F 00 2A 2F 39 33 34 29 23 2B
        STREAM_NEXT_BLOCK                                      ;#57B9: FE
        VRAM_NAME_TABLE 12h, 6                                 ;#57BA: 46 3A
        abyte -20h "2@", 5Ch, "]  PLAY ^_ KEYBOARD"            ;#57BC: 12 20 3C 3D 00 00 30 2C 21 39 00 3E 3F 00 2B 25 39 22 2F 21 32 24
        STREAM_BLOCK_END                                       ;#57D2: FF

MSG_TIME_OUT:
        ; Stream starting with STAGE message
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 7, 0Ch                                 ;#57D3: EC 38
        abyte -20h "TIME OUT"                                  ;#57D5: 34 29 2D 25 00 2F 35 34
        STREAM_BLOCK_END                                       ;#57DD: FF

MSG_VIDEO_CARTRIDGE:
        ; Stream starting with KONAMI message
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 0Bh, 6                                 ;#57DE: 66 39
        abyte -20h "@ VIDEO CARTRIDGE @"                       ;#57E0: 20 00 36 29 24 25 2F 00 23 21 32 34 32 29 24 27 25 00 20
        STREAM_BLOCK_END                                       ;#57F3: FF

INPUT_DEMO_PLAY_DATA:
        ; Stored inputs used for demo play
        ; Format: FORMAT_INPUT_DEMO_PLAY
        INPUT_DEMO_PLAY KEY_NONE                               ;#57F4: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57F5: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57F6: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57F7: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57F8: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57F9: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57FA: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57FB: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57FC: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57FD: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#57FE: 00
        INPUT_DEMO_PLAY KEY_UP                                 ;#57FF: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5800: 09
        INPUT_DEMO_PLAY KEY_UP                                 ;#5801: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5802: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#5803: 11
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT                      ;#5804: 05
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT                      ;#5805: 05
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5806: 09
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5807: 09
        INPUT_DEMO_PLAY KEY_UP                                 ;#5808: 01
        INPUT_DEMO_PLAY KEY_DOWN | KEY_LEFT                    ;#5809: 06
        INPUT_DEMO_PLAY KEY_LEFT                               ;#580A: 04
        INPUT_DEMO_PLAY KEY_SPACE                              ;#580B: 10
        INPUT_DEMO_PLAY KEY_UP                                 ;#580C: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#580D: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#580E: 11
        INPUT_DEMO_PLAY KEY_SPACE                              ;#580F: 10
        INPUT_DEMO_PLAY KEY_UP                                 ;#5810: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5811: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5812: 09
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5813: 09
        INPUT_DEMO_PLAY KEY_UP                                 ;#5814: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT                      ;#5815: 05
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT | KEY_SPACE          ;#5816: 15
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5817: 09
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT | KEY_SPACE         ;#5818: 19
        INPUT_DEMO_PLAY KEY_UP                                 ;#5819: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#581A: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT                      ;#581B: 05
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#581C: 11
        INPUT_DEMO_PLAY KEY_UP                                 ;#581D: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#581E: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#581F: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#5820: 11
        INPUT_DEMO_PLAY KEY_UP                                 ;#5821: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5822: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5823: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#5824: 11
        INPUT_DEMO_PLAY KEY_UP                                 ;#5825: 01
        INPUT_DEMO_PLAY KEY_NONE                               ;#5826: 00
        INPUT_DEMO_PLAY KEY_RIGHT | KEY_SPACE                  ;#5827: 18
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT | KEY_SPACE         ;#5828: 19
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5829: 09
        INPUT_DEMO_PLAY KEY_UP                                 ;#582A: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#582B: 11
        INPUT_DEMO_PLAY KEY_UP                                 ;#582C: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#582D: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#582E: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#582F: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5830: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5831: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5832: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5833: 01

INIT_ALL_VDP_PLANES:
        ; Sets up all three VDP pattern planes
        LOAD_VRAM_ADDRESS de, 0                                ;#5834: 11 00 00
        call    INIT_VDP_PLANE                                 ;#5837: CD 46 58
        LOAD_VRAM_ADDRESS de, 800h                             ;#583A: 11 00 08
        call    INIT_VDP_PLANE                                 ;#583D: CD 46 58
        LOAD_VRAM_ADDRESS de, 1000h                            ;#5840: 11 00 10
        jp      INIT_VDP_PLANE                                 ;#5843: C3 46 58

INIT_VDP_PLANE:
        ; Sets up a single VDP pattern plane
        push    de                                             ;#5846: D5
        xor     a                                              ;#5847: AF
        ; This loop seeds solid color tiles for each MSX palette color index.
        ld      c,10h                                          ;#5848: 0E 10
VDP_INIT_COLOR_BLOCK:
        ; Outer loop for clearing VRAM plane
        ld      b,8                                            ;#584A: 06 08
VDP_INIT_COLOR_BLOCK_LINE:
        ; Inner loop for clearing VRAM plane
        call    WRITE_VRAM_BYTE                                ;#584C: CD A5 48
        inc     de                                             ;#584F: 13
        djnz    VDP_INIT_COLOR_BLOCK_LINE                      ;#5850: 10 FA
        inc     a                                              ;#5852: 3C
        dec     c                                              ;#5853: 0D
        jr      nz,VDP_INIT_COLOR_BLOCK                        ;#5854: 20 F4
        ld      bc,270h                                        ;#5856: 01 70 02
        LOAD_VRAM_COLOR a, COLOR_WHITE, COLOR_TRANSPARENT      ;#5859: 3E F0
        call    FILL_VRAM                                      ;#585B: CD DC 44
        ld      hl,GFX_STARTUP_COLOR_TABLE                     ;#585E: 21 6A 5D
        call    DECOMPRESS_VRAM_DATA_ONLY                      ;#5861: CD 4C 45
        ld      b,16h                                          ;#5864: 06 16
VDP_INIT_COLOR_LOOP:
        ; Loop for decompressing startup patterns
        ld      hl,GFX_STARTUP_COLOR_TABLE_LOOP                ;#5866: 21 A0 5D
        push    bc                                             ;#5869: C5
        call    DECOMPRESS_VRAM_DATA_ONLY                      ;#586A: CD 4C 45
        pop     bc                                             ;#586D: C1
        djnz    VDP_INIT_COLOR_LOOP                            ;#586E: 10 F6
        pop     de                                             ;#5870: D1
        LOAD_VRAM_WRITE hl, 2000h                              ;#5871: 21 00 60
        add     hl,de                                          ;#5874: 19
        ex      de,hl                                          ;#5875: EB
        ld      hl,GFX_STARTUP_PATTERNS                        ;#5876: 21 85 58
        call    DECOMPRESS_VRAM_DIRECT                         ;#5879: CD 43 45
        ld      hl,GFX_STARTUP_PATT_EXTRA1                     ;#587C: 21 15 5C
        call    DECOMPRESS_VRAM_DATA_ONLY                      ;#587F: CD 4C 45
        ; Fallthrough: GFX_STARTUP_PATT_EXTRA2
        jp      DECOMPRESS_VRAM_DATA_ONLY                      ;#5882: C3 4C 45

GFX_STARTUP_PATTERNS:
        ; Main startup patterns
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "4000400083001C22036385221C001838"             ;#5885: 40 00 40 00 83 00 1C 22 03 63 85 22 1C 00 18 38
        dh      "0418AE7E003E63030E3C707F003E6303"             ;#5895: 04 18 AE 7E 00 3E 63 03 0E 3C 70 7F 00 3E 63 03
        dh      "0E03633E000E1E3666667F06007F607E"             ;#58A5: 0E 03 63 3E 00 0E 1E 36 66 66 7F 06 00 7F 60 7E
        dh      "6303633E003E63607E63633E007F6306"             ;#58B5: 63 03 63 3E 00 3E 63 60 7E 63 63 3E 00 7F 63 06
        dh      "0C03189A003E63633E63633E003E6363"             ;#58C5: 0C 03 18 9A 00 3E 63 63 3E 63 63 3E 00 3E 63 63
        dh      "3F03633E0F1026282826100F03830443"             ;#58D5: 3F 03 63 3E 0F 10 26 28 28 26 10 0F 03 83 04 43
        dh      "8A83031C3870E1CDCDFD79030081EE03"             ;#58E5: 8A 83 03 1C 38 70 E1 CD CD FD 79 03 00 81 EE 03
        dh      "6B81EB030089731A7A5A7A000300F304"             ;#58F5: 6B 81 EB 03 00 89 73 1A 7A 5A 7A 00 03 00 F3 04
        dh      "5B0400817E0400921C3663637F636300"             ;#5905: 5B 04 00 81 7E 04 00 92 1C 36 63 63 7F 63 63 00
        dh      "7E63637E63637E003E63036085633E00"             ;#5915: 7E 63 63 7E 63 63 7E 00 3E 63 03 60 85 63 3E 00
        dh      "7C6603639B667C007F60607E60607F00"             ;#5925: 7C 66 03 63 9B 66 7C 00 7F 60 60 7E 60 60 7F 00
        dh      "EEAA8AEA2EA8E8003E63606763633F00"             ;#5935: EE AA 8A EA 2E A8 E8 00 3E 63 60 67 63 63 3F 00
        dh      "0363817F036382003C0518833C001F04"             ;#5945: 03 63 81 7F 03 63 82 00 3C 05 18 83 3C 00 1F 04
        dh      "068B663C0063666C787C6E6700066093"             ;#5955: 06 8B 66 3C 00 63 66 6C 78 7C 6E 67 00 06 60 93
        dh      "7F0063777F7F6B63630063737B7F6F67"             ;#5965: 7F 00 63 77 7F 7F 6B 63 63 00 63 73 7B 7F 6F 67
        dh      "63003E0563833E007E03639D7E606000"             ;#5975: 63 00 3E 05 63 83 3E 00 7E 03 63 9D 7E 60 60 00
        dh      "EE8888EE8888EE007E6363627C666300"             ;#5985: EE 88 88 EE 88 88 EE 00 7E 63 63 62 7C 66 63 00
        dh      "3E63603E03633E007E06188100066382"             ;#5995: 3E 63 60 3E 03 63 3E 00 7E 06 18 81 00 06 63 82
        dh      "3E00046385361C0800C005A083C000F3"             ;#59A5: 3E 00 04 63 85 36 1C 08 00 C0 05 A0 83 C0 00 F3
        dh      "03DB88F3D3DB0066667E3C03188D00DF"             ;#59B5: 03 DB 88 F3 D3 DB 00 66 66 7E 3C 03 18 8D 00 DF
        dh      "1A18CC0616DE00F86060670360A80000"             ;#59C5: 1A 18 CC 06 16 DE 00 F8 60 60 67 03 60 A8 00 00
        dh      "40495A7352590000009252CE02DC0000"             ;#59D5: 40 49 5A 73 52 59 00 00 00 92 52 CE 02 DC 00 00
        dh      "02008AAAAADA00000848EE4A4A6A0000"             ;#59E5: 02 00 8A AA AA DA 00 00 08 48 EE 4A 4A 6A 00 00
        dh      "20242D39292D040001F00350010007EE"             ;#59F5: 20 24 2D 39 29 2D 04 00 01 F0 03 50 01 00 07 EE
        dh      "010007E00E0082070F060082F8F0043E"             ;#5A05: 01 00 07 E0 0E 00 82 07 0F 06 00 82 F8 F0 04 3E
        dh      "043F8B1F3F7FFFFEFCF8F0E0C0800300"             ;#5A15: 04 3F 8B 1F 3F 7F FF FE FC F8 F0 E0 C0 80 03 00
        dh      "023E0500831F7FFB0500830FCFEF0500"             ;#5A25: 02 3E 05 00 83 1F 7F FB 05 00 83 0F CF EF 05 00
        dh      "8378FCBC0500833F7FF305008387C7C7"             ;#5A35: 83 78 FC BC 05 00 83 3F 7F F3 05 00 83 87 C7 C7
        dh      "050083BCFEDF05008878FCBC60F0F060"             ;#5A45: 05 00 83 BC FE DF 05 00 88 78 FC BC 60 F0 F0 60
        dh      "0003F0023F063E88F8FCFE7F3F1F0F07"             ;#5A55: 00 03 F0 02 3F 06 3E 88 F8 FC FE 7F 3F 1F 0F 07
        dh      "033E857EFCFCF8E005F183FB7F1F06EF"             ;#5A65: 03 3E 85 7E FC FC F8 E0 05 F1 83 FB 7F 1F 06 EF
        dh      "82CF0F081E88E1033FF1E1F37F1E07E7"             ;#5A75: 82 CF 0F 08 1E 88 E1 03 3F F1 E1 F3 7F 1E 07 E7
        dh      "81F7088F081E82F1F204F597F2F1E010"             ;#5A85: 81 F7 08 8F 08 1E 82 F1 F2 04 F5 97 F2 F1 E0 10
        dh      "C868C82810E00000082E6F7F3F7F0003"             ;#5A95: C8 68 C8 28 10 E0 00 00 08 2E 6F 7F 3F 7F 00 03
        dh      "070FDF03FF8300E0FC05FF040090E0F0"             ;#5AA5: 07 0F DF 03 FF 83 00 E0 FC 05 FF 04 00 90 E0 F0
        dh      "FCFF0003030001010307C08087E704FF"             ;#5AB5: FC FF 00 03 03 00 01 01 03 07 C0 80 87 E7 04 FF
        dh      "030085C0F0FCFFFF040089C0E0E0F010"             ;#5AC5: 03 00 85 C0 F0 FC FF FF 04 00 89 C0 E0 E0 F0 10
        dh      "18181D1D030F021F023F027F02FF02F8"             ;#5AD5: 18 18 1D 1D 03 0F 02 1F 02 3F 02 7F 02 FF 02 F8
        dh      "03E003F08307030105008880CEFF7F0F"             ;#5AE5: 03 E0 03 F0 83 07 03 01 05 00 88 80 CE FF 7F 0F
        dh      "0F1F0003F803FC8EFFC0003E3F030307"             ;#5AF5: 0F 1F 00 03 F8 03 FC 8E FF C0 00 3E 3F 03 03 07
        dh      "06061F1F0F8F03CF890F0080C0C0E0E0"             ;#5B05: 06 06 1F 1F 0F 8F 03 CF 89 0F 00 80 C0 C0 E0 E0
        dh      "F0F0037F85FF7F7F5F4C06F002F8027F"             ;#5B15: F0 F0 03 7F 85 FF 7F 7F 5F 4C 06 F0 02 F8 02 7F
        dh      "043F847F7FF8FC03F003E0037F873F3F"             ;#5B25: 04 3F 84 7F 7F F8 FC 03 F0 03 E0 03 7F 87 3F 3F
        dh      "1F1F0FC08003008380C0C004FF841F07"             ;#5B35: 1F 1F 0F C0 80 03 00 83 80 C0 C0 04 FF 84 1F 07
        dh      "000003FF97FE3E1CC000FFFFFEFEFCFC"             ;#5B45: 00 00 03 FF 97 FE 3E 1C C0 00 FF FF FE FE FC FC
        dh      "F8F00F07070303071F1FF0F004E082C0"             ;#5B55: F8 F0 0F 07 07 03 03 07 1F 1F F0 F0 04 E0 82 C0
        dh      "80031F820F07030005FF83FEF00005FF"             ;#5B65: 80 03 1F 82 0F 07 03 00 05 FF 83 FE F0 00 05 FF
        dh      "8338000085FEFCF8E08003008A7F6701"             ;#5B75: 83 38 00 00 85 FE FC F8 E0 80 03 00 8A 7F 67 01
        dh      "0307070F0F80C003E084C0C0800F051F"             ;#5B85: 03 07 07 0F 0F 80 C0 03 E0 84 C0 C0 80 0F 05 1F
        dh      "8F0F0F80FCF8F1F3F3FFFF010F1F3F3F"             ;#5B95: 8F 0F 0F 80 FC F8 F1 F3 F3 FF FF 01 0F 1F 3F 3F
        dh      "07FF84FDFCFCF805FF843F1F03F804F0"             ;#5BA5: 07 FF 84 FD FC FC F8 05 FF 84 3F 1F 03 F8 04 F0
        dh      "89301000FFFF7F3F1F0F030384070F1F"             ;#5BB5: 89 30 10 00 FF FF 7F 3F 1F 0F 03 03 84 07 0F 1F
        dh      "0F0307050088010FFF000001033F06FF"             ;#5BC5: 0F 03 07 05 00 88 01 0F FF 00 00 01 03 3F 06 FF
        dh      "857F3F01000006FF821F00"                       ;#5BD5: 85 7F 3F 01 00 00 06 FF 82 1F 00

GFX_BANK2_PATTERN_PART3:
        ; Pattern Data Bank 2
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "8340E0400500A0010F010F0A0D0F0905"             ;#5BE0: 83 40 E0 40 05 00 A0 01 0F 01 0F 0A 0D 0F 09 05
        dh      "EE04EEAD65E525F18141F7D46750F500"             ;#5BF0: EE 04 EE AD 65 E5 25 F1 81 41 F7 D4 67 50 F5 00
        dh      "E000E020E000500500060F0A0006F00A"             ;#5C00: E0 00 E0 20 E0 00 50 05 00 06 0F 0A 00 06 F0 0A
        dh      "0006FF0500"                                   ;#5C10: 00 06 FF 05 00

GFX_STARTUP_PATT_EXTRA1:
        ; Supplemental startup patterns
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "06C004FF10C00C0004FF060008030307"             ;#5C15: 06 C0 04 FF 10 C0 0C 00 04 FF 06 00 08 03 03 07
        dh      "050002FF04E084C000FFFF13C006E005"             ;#5C25: 05 00 02 FF 04 E0 84 C0 00 FF FF 13 C0 06 E0 05
        dh      "C0"                                           ;#5C35: C0
        db      0                                              ;#5C36: 00

GFX_STARTUP_PATT_EXTRA2:
        ; Supplemental startup patterns
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "0103070102030207030F831F1E1E033F"             ;#5C37: 01 03 07 01 02 03 02 07 03 0F 83 1F 1E 1E 03 3F
        dh      "8D7C78F8E0E0F0F0F8F8787C3C3C03FE"             ;#5C47: 8D 7C 78 F8 E0 E0 F0 F0 F8 F8 78 7C 3C 3C 03 FE
        dh      "831F0F0F0600843B3F3F3B053901B903"             ;#5C57: 83 1F 0F 0F 06 00 84 3B 3F 3F 3B 05 39 01 B9 03
        dh      "00860307071F9FDF05C782C3C106008A"             ;#5C67: 00 86 03 07 07 1F 9F DF 05 C7 82 C3 C1 06 00 8A
        dh      "C7CFCF000F1F9CDFCFC7060083C3E3E3"             ;#5C77: C7 CF CF 00 0F 1F 9C DF CF C7 06 00 83 C3 E3 E3
        dh      "03F38473F3F3BB06008A18B9FBF3C383"             ;#5C87: 03 F3 84 73 F3 F3 BB 06 00 8A 18 B9 FB F3 C3 83
        dh      "83818180060003FB84C08080C003F886"             ;#5C97: 83 81 81 80 06 00 03 FB 84 C0 80 80 C0 03 F8 86
        dh      "00010363E1E003FB03E394F3FB7B3B00"             ;#5CA7: 00 01 03 63 E1 E0 03 FB 03 E3 94 F3 FB 7B 3B 00
        dh      "00808000008F9FBFBCB8B8BCBF9F8F06"             ;#5CB7: 00 80 80 00 00 8F 9F BF BC B8 B8 BC BF 9F 8F 06
        dh      "0003800400038002030207030F831F1E"             ;#5CC7: 00 03 80 04 00 03 80 02 03 02 07 03 0F 83 1F 1E
        dh      "1E033F8D7C78F8E0E0F0F0F8F8787C3C"             ;#5CD7: 1E 03 3F 8D 7C 78 F8 E0 E0 F0 F0 F8 F8 78 7C 3C
        dh      "3C03FE831F0F0F06008B1E3F7F797070"             ;#5CE7: 3C 03 FE 83 1F 0F 0F 06 00 8B 1E 3F 7F 79 70 70
        dh      "787F3F9E0005E001EF03E703E383E1E1"             ;#5CF7: 78 7F 3F 9E 00 05 E0 01 EF 03 E7 03 E3 83 E1 E1
        dh      "E006008A1E1CBCBDB9F9F9F0F0E00600"             ;#5D07: E0 06 00 8A 1E 1C BC BD B9 F9 F9 F0 F0 E0 06 00
        dh      "8A3CFEEEC7FFFFC0E7FF3E060084767F"             ;#5D17: 8A 3C FE EE C7 FF FF C0 E7 FF 3E 06 00 84 76 7F
        dh      "7F7B0673030086060E0E3F3FBF038E84"             ;#5D27: 7F 7B 06 73 03 00 86 06 0E 0E 3F 3F BF 03 8E 84
        dh      "8F8F8783060003B9043983BD9F8E0600"             ;#5D37: 8F 8F 87 83 06 00 03 B9 04 39 83 BD 9F 8E 06 00
        dh      "85DCDDDFDFDE05DC06008AC3CFCEDC1F"             ;#5D47: 85 DC DD DF DF DE 05 DC 06 00 8A C3 CF CE DC 1F
        dh      "1F1C0E0F0306008AC0E0E070F0F00070"             ;#5D57: 1F 1C 0E 0F 03 06 00 8A C0 E0 E0 70 F0 F0 00 70
        dh      "F0E0"                                         ;#5D67: F0 E0
        db      0                                              ;#5D69: 00

GFX_STARTUP_COLOR_TABLE:
        ; Startup color table data for clearing plane
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "18F478F470F450F72074281F2060106A"             ;#5D6A: 18 F4 78 F4 70 F4 50 F7 20 74 28 1F 20 60 10 6A
        dh      "38EF021E061F02EF067F0AE70BEF061F"             ;#5D7A: 38 EF 02 1E 06 1F 02 EF 06 7F 0A E7 0B EF 06 1F
        dh      "05EF386F0216061F026F067F0A670B6F"             ;#5D8A: 05 EF 38 6F 02 16 06 1F 02 6F 06 7F 0A 67 0B 6F
        dh      "061F056F"                                     ;#5D9A: 06 1F 05 6F

GFX_STARTUP_COLOR_TABLE_TAIL:
        ; Startup clear tail stream entry (falls into loop filler)
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "0817"                                         ;#5D9E: 08 17

GFX_STARTUP_COLOR_TABLE_LOOP:
        ; Repeating color-table filler
        ; Fallthrough from GFX_STARTUP_COLOR_TABLE.
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "0AF1037102510141"                             ;#5DA0: 0A F1 03 71 02 51 01 41
        db      0                                              ;#5DA8: 00

GFX_STAGE_NIGHT_TILES:
        ; Night-stage tile-pattern patch (loaded by INIT_STAGE_SET_SKY_COLOR)
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "0819"                                         ;#5DA9: 08 19
        db      0                                              ;#5DAB: 00

GFX_INIT_BANK1:
        ; Decompress bank-1 patterns and colors at stage start
        ld      hl,GFX_BANK1_PATTERN                           ;#5DAC: 21 DC 5D
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5DAF: CD 3F 45
        ld      hl,GFX_BANK1_PATTERN+2                         ;#5DB2: 21 DE 5D
        LOAD_VRAM_WRITE de, 2A88h                              ;#5DB5: 11 88 6A
        call    DECOMPRESS_VRAM_DIRECT_MIRROR                  ;#5DB8: CD 47 45
        ; Fallthrough: GFX_BANK1_PATTERN_PART2
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5DBB: CD 3F 45
        ld      hl,GFX_BANK1_COLOR_EXTRA                       ;#5DBE: 21 64 61
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5DC1: CD 3F 45
        ld      hl,GFX_BANK1_COLOR+2                           ;#5DC4: 21 6B 61
        LOAD_VRAM_WRITE de, 0A88h                              ;#5DC7: 11 88 4A
        call    DECOMPRESS_VRAM_DIRECT                         ;#5DCA: CD 43 45
        ; Fallthrough: GFX_BANK1_COLOR_PART2
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5DCD: CD 3F 45
        ld      hl,GFX_BANK1_COLOR                             ;#5DD0: 21 69 61
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5DD3: CD 3F 45
        ld      hl,GFX_BANK1_COLOR_EXTRA2                      ;#5DD6: 21 3A 62
        jp      DECOMPRESS_VRAM_INDIRECT                       ;#5DD9: C3 3F 45

GFX_BANK1_PATTERN:
        ; Bank 1 patterns: stage init (loaded by GFX_INIT_BANK1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 2880h                                      ;#5DDC: 80 68
        dh      "8200FF070084FF0007FF0400A5FF00FF"             ;#5DDE: 82 00 FF 07 00 84 FF 00 07 FF 04 00 A5 FF 00 FF
        dh      "FF0000FF00FF0000FF00FFFF00FF00FF"             ;#5DEE: FF 00 00 FF 00 FF 00 00 FF 00 FF FF 00 FF 00 FF
        dh      "FF00FFFF00FF0000FF0000FF00031FFF"             ;#5DFE: FF 00 FF FF 00 FF 00 00 FF 00 00 FF 00 03 1F FF
        dh      "1502030003FF8255AA030003FF890583"             ;#5E0E: 15 02 03 00 03 FF 82 55 AA 03 00 03 FF 89 05 83
        dh      "1FFF0000FFFF0003FF8C0000FFFF00E0"             ;#5E1E: 1F FF 00 00 FF FF 00 03 FF 8C 00 00 FF FF 00 E0
        dh      "FFFF0000FFFF030001FF030087FF0000"             ;#5E2E: FF FF 00 00 FF FF 03 00 01 FF 03 00 87 FF 00 00
        dh      "FFFF2A05060089AA54031FFF2A050000"             ;#5E3E: FF FF 2A 05 06 00 89 AA 54 03 1F FF 2A 05 00 00
        dh      "04FF85AA5522000003FF8BAA50070000"             ;#5E4E: 04 FF 85 AA 55 22 00 00 03 FF 8B AA 50 07 00 00
        dh      "FFFFE01FFFFF030082FF0003FF030089"             ;#5E5E: FF FF E0 1F FF FF 03 00 82 FF 00 03 FF 03 00 89
        dh      "FFFF00FFFF00000F0104008817FFFF55"             ;#5E6E: FF FF 00 FF FF 00 00 0F 01 04 00 88 17 FF FF 55
        dh      "2A05000003FF8355AA110500820F0204"             ;#5E7E: 2A 05 00 00 03 FF 83 55 AA 11 05 00 82 0F 02 04
        dh      "00881FFFFFAA54031F0003FF010003FF"             ;#5E8E: 00 88 1F FF FF AA 54 03 1F 00 03 FF 01 00 03 FF
        dh      "010003FF860000FFFFAA55070004FF85"             ;#5E9E: 01 00 03 FF 86 00 00 FF FF AA 55 07 00 04 FF 85
        dh      "A8473F000003FF8800FFFF000FFF1502"             ;#5EAE: A8 47 3F 00 00 03 FF 88 00 FF FF 00 0F FF 15 02
        dh      "040003FF8900E0FFFF00FF00FFFF0400"             ;#5EBE: 04 00 03 FF 89 00 E0 FF FF 00 FF 00 FF FF 04 00
        dh      "84FF0000FF0A0001FF0400843F00FFFF"             ;#5ECE: 84 FF 00 00 FF 0A 00 01 FF 04 00 84 3F 00 FF FF
        dh      "03008A80FF0000FF7F1F0F0301030005"             ;#5EDE: 03 00 8A 80 FF 00 00 FF 7F 1F 0F 03 01 03 00 05
        dh      "FF857F3F0F0701060003FF8D3F1F0703"             ;#5EEE: FF 85 7F 3F 0F 07 01 06 00 03 FF 8D 3F 1F 07 03
        dh      "00FF7F1F0F0701000007FF857F1F0F07"             ;#5EFE: 00 FF 7F 1F 0F 07 01 00 00 07 FF 85 7F 1F 0F 07
        dh      "01040006FF827F3F04FF911F07030007"             ;#5F0E: 01 04 00 06 FF 82 7F 3F 04 FF 91 1F 07 03 00 07
        dh      "0F1F1F1F0F0703FF3F0F0301030084FF"             ;#5F1E: 0F 1F 1F 1F 0F 07 03 FF 3F 0F 03 01 03 00 84 FF
        dh      "7F1F0F04000600021F05FF030003FF82"             ;#5F2E: 7F 1F 0F 04 00 06 00 02 1F 05 FF 03 00 03 FF 82
        dh      "7F1F"                                         ;#5F3E: 7F 1F

GFX_FLAG_VRAM_DEST:
        ; VRAM destination address constant for flag decompression
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "030003FF0500907F1F0F1F3F0F070107"             ;#5F40: 03 00 03 FF 05 00 90 7F 1F 0F 1F 3F 0F 07 01 07
        dh      "0F"                                           ;#5F50: 0F

GFX_FLAG_BANK_DATA:
        ; Bank graphics data continuation
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "1F3F0703"                                     ;#5F51: 1F 3F 07 03
        db      0                                              ;#5F55: 00
        db      0                                              ;#5F56: 00
        dh      "0400020105FF873F1F3F7FFF00030900"             ;#5F57: 04 00 02 01 05 FF 87 3F 1F 3F 7F FF 00 03 09 00
        dh      "8201030300830103070500017F053F82"             ;#5F67: 82 01 03 03 00 83 01 03 07 05 00 01 7F 05 3F 82
        dh      "1F0F06FF067F8C1F0F07017F1F0F0301"             ;#5F77: 1F 0F 06 FF 06 7F 8C 1F 0F 07 01 7F 1F 0F 03 01
        dh      "00030703FF053F"                               ;#5F87: 00 03 07 03 FF 05 3F
        db      0                                              ;#5F8E: 00

GFX_BANK1_PATTERN_PART2:
        ; Bank 1 patterns part 2: stage init (continuation of GFX_BANK1_PATTERN)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 2C90h                                      ;#5F8F: 90 6C
        dh      "0B0001FF0B000103070001FF070001F0"             ;#5F91: 0B 00 01 FF 0B 00 01 03 07 00 01 FF 07 00 01 F0
        dh      "0400011F070001FF0400823FFF060002"             ;#5FA1: 04 00 01 1F 07 00 01 FF 04 00 82 3F FF 06 00 02
        dh      "FF060082FCFF050082010F060002FF06"             ;#5FB1: FF 06 00 82 FC FF 05 00 82 01 0F 06 00 02 FF 06
        dh      "0082F0FE060004FF1300010F070001C0"             ;#5FC1: 00 82 F0 FE 06 00 04 FF 13 00 01 0F 07 00 01 C0
        dh      "040001F80300820F7F06008280F00900"             ;#5FD1: 04 00 01 F8 03 00 82 0F 7F 06 00 82 80 F0 09 00
        dh      "0103070001E00700010F070001C00400"             ;#5FE1: 01 03 07 00 01 E0 07 00 01 0F 07 00 01 C0 04 00
        dh      "017F030F040001FE03F01F0001010700"             ;#5FF1: 01 7F 03 0F 04 00 01 FE 03 F0 1F 00 01 01 07 00
        dh      "018007000107070001E00B0001F80700"             ;#6001: 01 80 07 00 01 07 07 00 01 E0 0B 00 01 F8 07 00
        dh      "011F0400017F070001FE090002070600"             ;#6011: 01 1F 04 00 01 7F 07 00 01 FE 09 00 02 07 06 00
        dh      "85E0E0001F1F060002FF060002F80500"             ;#6021: 85 E0 E0 00 1F 1F 06 00 02 FF 06 00 02 F8 05 00
        dh      "021F060002F8060002FF0A0001030700"             ;#6031: 02 1F 06 00 02 F8 06 00 02 FF 0A 00 01 03 07 00
        dh      "01C00300847F7FFF7F040084FEFEFFFE"             ;#6041: 01 C0 03 00 84 7F 7F FF 7F 04 00 84 FE FE FF FE
        dh      "040004FF160002040A00023006000203"             ;#6051: 04 00 04 FF 16 00 02 04 0A 00 02 30 06 00 02 03
        dh      "030002C0090004F00C0006FF038001C0"             ;#6061: 03 00 02 C0 09 00 04 F0 0C 00 06 FF 03 80 01 C0
        dh      "030E020803000203040202000100030F"             ;#6071: 03 0E 02 08 03 00 02 03 04 02 02 00 01 00 03 0F
        dh      "0109040003E001200400937BE0E4E4E0"             ;#6081: 01 09 04 00 03 E0 01 20 04 00 93 7B E0 E4 E4 E0
        dh      "E09800F6FFBFBFFFFF53003070770BF8"             ;#6091: E0 98 00 F6 FF BF BF FF FF 53 00 30 70 77 0B F8
        dh      "87E00026EEEFFFFF049F04FF88FECC00"             ;#60A1: 87 E0 00 26 EE EF FF FF 04 9F 04 FF 88 FE CC 00
        dh      "24EEEFFF870F7F9B6F03010000226363"             ;#60B1: 24 EE EF FF 87 0F 7F 9B 6F 03 01 00 00 22 63 63
        dh      "F3F7F7FFFFDD8800DBFFFF0000026363"             ;#60C1: F3 F7 F7 FF FF DD 88 00 DB FF FF 00 00 02 63 63
        dh      "F3F7F703FF07FE09FF82C381030002FF"             ;#60D1: F3 F7 F7 03 FF 07 FE 09 FF 82 C3 81 03 00 02 FF
        dh      "010F0CFF010003FF85F7C782000003FF"             ;#60E1: 01 0F 0C FF 01 00 03 FF 85 F7 C7 82 00 00 03 FF
        dh      "071F09FF07C308FF01F80DF70BFC0100"             ;#60F1: 07 1F 09 FF 07 C3 08 FF 01 F8 0D F7 0B FC 01 00
        dh      "08FF847F22000004F78477220000024F"             ;#6101: 08 FF 84 7F 22 00 00 04 F7 84 77 22 00 00 02 4F
        dh      "067F0103150182030F04008480C0E0FF"             ;#6111: 06 7F 01 03 15 01 82 03 0F 04 00 84 80 C0 E0 FF
        dh      "0500820FFF050093F8E74D1800000F1F"             ;#6121: 05 00 82 0F FF 05 00 93 F8 E7 4D 18 00 00 0F 1F
        dh      "FAEBC5800000F0FC3FDC6803008503FF"             ;#6131: FA EB C5 80 00 00 F0 FC 3F DC 68 03 00 85 03 FF
        dh      "FFB5160500031F013F040004FF040084"             ;#6141: FF B5 16 05 00 03 1F 01 3F 04 00 04 FF 04 00 84
        dh      "C0FCFCFF040084FFEFFFF7040084FFD3"             ;#6151: C0 FC FC FF 04 00 84 FF EF FF F7 04 00 84 FF D3
        dh      "FDCE"                                         ;#6161: FD CE
        db      0                                              ;#6163: 00

GFX_BANK1_COLOR_EXTRA:
        ; Bank 1 color patch: stage init (small extra for GFX_INIT_BANK1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 2A98h                                      ;#6164: 98 6A
        dh      "1000"                                         ;#6166: 10 00
        db      0                                              ;#6168: 00

GFX_BANK1_COLOR:
        ; Bank 1 colors: stage init (loaded by GFX_INIT_BANK1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 880h                                       ;#6169: 80 48
        dh      "78EF78EF38EF604F064F821F412C4F82"             ;#616B: 78 EF 78 EF 38 EF 60 4F 06 4F 82 1F 41 2C 4F 82
        dh      "1F410A4F181F024F03410A4F01410341"             ;#617B: 1F 41 0A 4F 18 1F 02 4F 03 41 0A 4F 01 41 03 41
        dh      "0B4F021F054F0341"                             ;#618B: 0B 4F 02 1F 05 4F 03 41
        db      0                                              ;#6193: 00

GFX_BANK1_COLOR_PART2:
        ; Bank 1 colors part 2: stage init (continuation of GFX_BANK1_COLOR)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 0C90h                                      ;#6194: 90 4C
        dh      "704F304F201F024F0241064F0241044F"             ;#6196: 70 4F 30 4F 20 1F 02 4F 02 41 06 4F 02 41 04 4F
        dh      "785F305F01EF075F01EF075F01EF075F"             ;#61A6: 78 5F 30 5F 01 EF 07 5F 01 EF 07 5F 01 EF 07 5F
        dh      "4C3F04EF033F05EF023F06EF109F028F"             ;#61B6: 4C 3F 04 EF 03 3F 05 EF 02 3F 06 EF 10 9F 02 8F
        dh      "0689089F048F0B89046F039F0497069F"             ;#61C6: 06 89 08 9F 04 8F 0B 89 04 6F 03 9F 04 97 06 9F
        dh      "036F039F0F96039F076F019F05F60396"             ;#61D6: 03 6F 03 9F 0F 96 03 9F 07 6F 01 9F 05 F6 03 96
        dh      "076E018E09971F9F088F2097039F0D96"             ;#61E6: 07 6E 01 8E 09 97 1F 9F 08 8F 20 97 03 9F 0D 96
        dh      "0B760D9F0396059F08961717011F08F7"             ;#61F6: 0B 76 0D 9F 03 96 05 9F 08 96 17 17 01 1F 08 F7
        dh      "07F701F405F703F404F704F404F704F4"             ;#6206: 07 F7 01 F4 05 F7 03 F4 04 F7 04 F4 04 F7 04 F4
        dh      "03F705F428F7"                                 ;#6216: 03 F7 05 F4 28 F7
        db      0                                              ;#621C: 00

GFX_STAGE_NIGHT_COLORS:
        ; Night-stage color patch (paired with GFX_STAGE_NIGHT_TILES)
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "1719011F08F907F901F405F903F404F9"             ;#621D: 17 19 01 1F 08 F9 07 F9 01 F4 05 F9 03 F4 04 F9
        dh      "04F404F904F403F905F428F9"                     ;#622D: 04 F4 04 F9 04 F4 03 F9 05 F4 28 F9
        db      0                                              ;#6239: 00

GFX_BANK1_COLOR_EXTRA2:
        ; Bank 1 color patch 2: stage init (final extra for GFX_INIT_BANK1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 0A98h                                      ;#623A: 98 4A
        dh      "044F01410344034F01410444"                     ;#623C: 04 4F 01 41 03 44 03 4F 01 41 04 44
        db      0                                              ;#6248: 00

GFX_INIT_BANK2:
        ; Decompress bank-2 patterns and colors at stage start
        ld      hl,GFX_BANK2_PATTERN_PART1                     ;#6249: 21 7F 62
        call    DECOMPRESS_VRAM_INDIRECT                       ;#624C: CD 3F 45
        ; Fallthrough: GFX_BANK2_COLOR_PART2
        call    DECOMPRESS_VRAM_INDIRECT                       ;#624F: CD 3F 45
        ld      hl,GFX_BANK2_PATTERN_PART3                     ;#6252: 21 E0 5B
        call    DECOMPRESS_VRAM_DATA_ONLY                      ;#6255: CD 4C 45
        ld      hl,GFX_BANK2_PATTERN_PART1+2                   ;#6258: 21 81 62
        LOAD_VRAM_WRITE de, 32B0h                              ;#625B: 11 B0 72
        call    DECOMPRESS_VRAM_DIRECT_MIRROR                  ;#625E: CD 47 45
        ld      hl,GFX_BANK2_PATTERN_PART4                     ;#6261: 21 0F 66
        call    DECOMPRESS_VRAM_INDIRECT                       ;#6264: CD 3F 45
        ld      hl,GFX_BANK2_COLOR_PART1                       ;#6267: 21 33 65
        call    DECOMPRESS_VRAM_INDIRECT                       ;#626A: CD 3F 45
        ; Fallthrough: GFX_BANK2_COLOR_PART2
        call    DECOMPRESS_VRAM_INDIRECT                       ;#626D: CD 3F 45
        ld      hl,GFX_BANK2_COLOR_PART1+2                     ;#6270: 21 35 65
        LOAD_VRAM_WRITE de, 12B0h                              ;#6273: 11 B0 52
        call    DECOMPRESS_VRAM_DIRECT                         ;#6276: CD 43 45
        ld      hl,GFX_BANK2_COLOR_PART3                       ;#6279: 21 6D 66
        jp      DECOMPRESS_VRAM_INDIRECT                       ;#627C: C3 3F 45

GFX_BANK2_PATTERN_PART1:
        ; Bank 2 patterns part 1: stage init (loaded by GFX_INIT_BANK2)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 3200h                                      ;#627F: 00 72
        dh      "857F1F0F0301030005FF857F3F0F0701"             ;#6281: 85 7F 1F 0F 03 01 03 00 05 FF 85 7F 3F 0F 07 01
        dh      "060003FF8D3F1F070300FF7F1F0F0701"             ;#6291: 06 00 03 FF 8D 3F 1F 07 03 00 FF 7F 1F 0F 07 01
        dh      "000007FF857F1F0F0701040005FF837F"             ;#62A1: 00 00 07 FF 85 7F 1F 0F 07 01 04 00 05 FF 83 7F
        dh      "1F0F03FF857F1F0F070104FF861F0703"             ;#62B1: 1F 0F 03 FF 85 7F 1F 0F 07 01 04 FF 86 1F 07 03
        dh      "00FF7F060085FFFF0F0301030004FF04"             ;#62C1: 00 FF 7F 06 00 85 FF FF 0F 03 01 03 00 04 FF 04
        dh      "0005FF8D7F00000103070F0F1F000001"             ;#62D1: 00 05 FF 8D 7F 00 00 01 03 07 0F 0F 1F 00 00 01
        dh      "0306008407070F1F0500870103070F0F"             ;#62E1: 03 06 00 84 07 07 0F 1F 05 00 87 01 03 07 0F 0F
        dh      "1F3F03FF017F0A3F921F0F7F1F0F0301"             ;#62F1: 1F 3F 03 FF 01 7F 0A 3F 92 1F 0F 7F 1F 0F 03 01
        dh      "0003073F3F1F0F07010000"                       ;#6301: 00 03 07 3F 3F 1F 0F 07 01 00 00
        db      0                                              ;#630C: 00

GFX_BANK2_PATTERN_PART2:
        ; Bank 2 patterns part 2: stage init
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 3360h                                      ;#630D: 60 73
        dh      "030005FF010007FF02000DFF04008503"             ;#630F: 03 00 05 FF 01 00 07 FF 02 00 0D FF 04 00 85 03
        dh      "00000F7F030086F80000F0FF01040096"             ;#631F: 00 00 0F 7F 03 00 86 F8 00 00 F0 FF 01 04 00 96
        dh      "010F00FF3F00000FFFFF3FFFFCF8C000"             ;#632F: 01 0F 00 FF 3F 00 00 0F FF FF 3F FF FC F8 C0 00
        dh      "F0FFFFF0C080030084F8FF1F03030083"             ;#633F: F0 FF FF F0 C0 80 03 00 84 F8 FF 1F 03 03 00 83
        dh      "1FFF03030085E00000E0FE06008280F0"             ;#634F: 1F FF 03 03 00 85 E0 00 00 E0 FE 06 00 82 80 F0
        dh      "0300010F06008607FFFF07000003FF87"             ;#635F: 03 00 01 0F 06 00 86 07 FF FF 07 00 00 03 FF 87
        dh      "FCF0FF0F00C080030083C0F07F070089"             ;#636F: FC F0 FF 0F 00 C0 80 03 00 83 C0 F0 7F 07 00 89
        dh      "F0FCF8F0C000FCFF07070001FF030082"             ;#637F: F0 FC F8 F0 C0 00 FC FF 07 07 00 01 FF 03 00 82
        dh      "FF0F0400860F7FFFFF7F0C040002FF03"             ;#638F: FF 0F 04 00 86 0F 7F FF FF 7F 0C 04 00 02 FF 03
        dh      "3F030002FF03F802FF0D0F010003FF01"             ;#639F: 3F 03 00 02 FF 03 F8 02 FF 0D 0F 01 00 03 FF 01
        dh      "FC0BF001FF08070300010F04FF010F04"             ;#63AF: FC 0B F0 01 FF 08 07 03 00 01 0F 04 FF 01 0F 04
        dh      "F784F0C00000071F070F010007F00200"             ;#63BF: F7 84 F0 C0 00 00 07 1F 07 0F 01 00 07 F0 02 00
        dh      "07F802F006F08200C0060F82000306F0"             ;#63CF: 07 F8 02 F0 06 F0 82 00 C0 06 0F 82 00 03 06 F0
        dh      "820F3F060F01FF047F010F0500850303"             ;#63DF: 82 0F 3F 06 0F 01 FF 04 7F 01 0F 05 00 85 03 03
        dh      "0F0F030B008EC0C0F0F0C00000010707"             ;#63EF: 0F 0F 03 0B 00 8E C0 C0 F0 F0 C0 00 00 01 07 07
        dh      "1F1F01FF09008C80E0E0F8F880000007"             ;#63FF: 1F 1F 01 FF 09 00 8C 80 E0 E0 F8 F8 80 00 00 07
        dh      "1FF0E0040084E0F81F070600040F8500"             ;#640F: 1F F0 E0 04 00 84 E0 F8 1F 07 06 00 04 0F 85 00
        dh      "073FF8C0040084E0FC1F03070004F084"             ;#641F: 07 3F F8 C0 04 00 84 E0 FC 1F 03 07 00 04 F0 84
        dh      "FFFF3F01040004FF040084FFFFFC8004"             ;#642F: FF FF 3F 01 04 00 04 FF 04 00 84 FF FF FC 80 04
        dh      "00830F0F03050003FF011F040003FF01"             ;#643F: 00 83 0F 0F 03 05 00 03 FF 01 1F 04 00 03 FF 01
        dh      "F8040083F0F0C00900830F7FF806FF03"             ;#644F: F8 04 00 83 F0 F0 C0 09 00 83 0F 7F F8 06 FF 03
        dh      "0006FF020003FF050083FFFF3F050083"             ;#645F: 00 06 FF 02 00 03 FF 05 00 83 FF FF 3F 05 00 83
        dh      "FFFFFC050008F0040004FF080F068082"             ;#646F: FF FF FC 05 00 08 F0 04 00 04 FF 08 0F 06 80 82
        dh      "C0E0058083C000000608820C0F050801"             ;#647F: C0 E0 05 80 83 C0 00 00 06 08 82 0C 0F 05 08 01
        dh      "0F0F009B0F0000071F3F7C78F2F2F0E0"             ;#648F: 0F 0F 00 9B 0F 00 00 07 1F 3F 7C 78 F2 F2 F0 E0
        dh      "F8FC3E1E4F4F0F000001070F1F3C3005"             ;#649F: F8 FC 3E 1E 4F 4F 0F 00 00 01 07 0F 1F 3C 30 05
        dh      "F883FCF0C0051F833F0F03870080E0F0"             ;#64AF: F8 83 FC F0 C0 05 1F 83 3F 0F 03 87 00 80 E0 F0
        dh      "F81C0C06800A0007010200058083C0C0"             ;#64BF: F8 1C 0C 06 80 0A 00 07 01 02 00 05 80 83 C0 C0
        dh      "E0050183030307038098C04060A0E030"             ;#64CF: E0 05 01 83 03 03 07 03 80 98 C0 40 60 A0 E0 30
        dh      "3C1F0F07030100000101030703000070"             ;#64DF: 3C 1F 0F 07 03 01 00 00 01 01 03 07 03 00 00 70
        dh      "FFE303FF85000006FFE703FF03008880"             ;#64EF: FF E3 03 FF 85 00 00 06 FF E7 03 FF 03 00 88 80
        dh      "80C0E0C000000103000101030088F07F"             ;#64FF: 80 C0 E0 C0 00 00 01 03 00 01 01 03 00 88 F0 7F
        dh      "337FFFFF000098007F60607E60606000"             ;#650F: 33 7F FF FF 00 00 98 00 7F 60 60 7E 60 60 60 00
        dh      "63636B6B7F7722007F070E1C38707F06"             ;#651F: 63 63 6B 6B 7F 77 22 00 7F 07 0E 1C 38 70 7F 06
        dh      "000260"                                       ;#652F: 00 02 60
        db      0                                              ;#6532: 00

GFX_BANK2_COLOR_PART1:
        ; Bank 2 colors part 1: stage init (loaded by GFX_INIT_BANK2)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1200h                                      ;#6533: 00 52
        dh      "704F201F064F0841084F021F0241064F"             ;#6535: 70 4F 20 1F 06 4F 08 41 08 4F 02 1F 02 41 06 4F
        db      0                                              ;#6545: 00

GFX_BANK2_COLOR_PART2:
        ; Bank 2 colors part 2: stage init (continuation of PART1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1360h                                      ;#6546: 60 53
        dh      "264F021F064F021F054F031F044F041F"             ;#6548: 26 4F 02 1F 06 4F 02 1F 05 4F 03 1F 04 4F 04 1F
        dh      "044F041F044F041F044F041F044F541F"             ;#6558: 04 4F 04 1F 04 4F 04 1F 04 4F 04 1F 04 4F 54 1F
        dh      "064F0241064F0241034F05410641024F"             ;#6568: 06 4F 02 41 06 4F 02 41 03 4F 05 41 06 41 02 4F
        dh      "054F0341074102F40954071F041D041F"             ;#6578: 05 4F 03 41 07 41 02 F4 09 54 07 1F 04 1D 04 1F
        dh      "0E45014F0745024F0745024F0645025F"             ;#6588: 0E 45 01 4F 07 45 02 4F 07 45 02 4F 06 45 02 5F
        dh      "0645025F0645024F0645051D031F04EF"             ;#6598: 06 45 02 5F 06 45 02 4F 06 45 05 1D 03 1F 04 EF
        dh      "065F02FE04F504EF045F04EF045F03FE"             ;#65A8: 06 5F 02 FE 04 F5 04 EF 04 5F 04 EF 04 5F 03 FE
        dh      "05F504EF045F04EF02E502F504EF02E5"             ;#65B8: 05 F5 04 EF 04 5F 04 EF 02 E5 02 F5 04 EF 02 E5
        dh      "02F506EF025F03EF02E503F503EF02E5"             ;#65C8: 02 F5 06 EF 02 5F 03 EF 02 E5 03 F5 03 EF 02 E5
        dh      "03F506EF6A5F183F17EF01E105EF01E1"             ;#65D8: 03 F5 06 EF 6A 5F 18 3F 17 EF 01 E1 05 EF 01 E1
        dh      "121F1A1F0216061F0216471F054F031F"             ;#65E8: 12 1F 1A 1F 02 16 06 1F 02 16 47 1F 05 4F 03 1F
        dh      "054F031F054F031F054F031F054F031F"             ;#65F8: 05 4F 03 1F 05 4F 03 1F 05 4F 03 1F 05 4F 03 1F
        dh      "054F"                                         ;#6608: 05 4F

GFX_GOAL_COLOR_PATCH:
        ; Goal-scene color patch (loaded by INIT_GOAL_GRAPHICS at the goal)
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "784F784F"                                     ;#660A: 78 4F 78 4F
        db      0                                              ;#660E: 00

GFX_BANK2_PATTERN_PART4:
        ; Bank 2 patterns part 4: stage init (loaded by GFX_INIT_BANK2)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 3690h                                      ;#660F: 90 76
        dh      "82020502000607020106020301030084"             ;#6611: 82 02 05 02 00 06 07 02 01 06 02 03 01 03 00 84
        dh      "2757070706FF82070109008380402004"             ;#6621: 27 57 07 07 06 FF 82 07 01 09 00 83 80 40 20 04
        dh      "FF02FE83FCFEFE04FF8B7F3F1F1F0F07"             ;#6631: FF 02 FE 83 FC FE FE 04 FF 8B 7F 3F 1F 1F 0F 07
        dh      "01000204080300038002C084E0F0F8C0"             ;#6641: 01 00 02 04 08 03 00 03 80 02 C0 84 E0 F0 F8 C0
        dh      "0400980001010100000000F8F0E0FF00"             ;#6651: 04 00 98 00 01 01 01 00 00 00 00 F8 F0 E0 FF 00
        dh      "00000000F0FCF800000000"                       ;#6661: 00 00 00 00 F0 FC F8 00 00 00 00
        db      0                                              ;#666C: 00

GFX_BANK2_COLOR_PART3:
        ; Bank 2 colors part 3: stage init (loaded by GFX_INIT_BANK2)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1690h                                      ;#666D: 90 56
        dh      "581F03AF014F05AF02A40D4F"                     ;#666F: 58 1F 03 AF 01 4F 05 AF 02 A4 0D 4F
        db      0                                              ;#667B: 00

INIT_SPRITES_FROM_STREAM:
        ; Initialize quaternary stage VRAM graphics (Sprite data stream)
        ld      hl,SPRITE_INIT_TABLE                           ;#667C: 21 A9 66
        jr      CLEAR_AND_INIT_SPRITE_ATTRS                    ;#667F: 18 03

INIT_GOAL_SPRITES:
        ; Reset sprite attributes and initialize goal sequence sprites
        ld      hl,GOAL_SPRITE_DATA                            ;#6681: 21 E6 66
CLEAR_AND_INIT_SPRITE_ATTRS:
        ; Clear SAT mirror, then init from HL stream ([Count][Y,X,Pat,Col]..., 00=End)
        push    hl                                             ;#6684: E5
        ld      hl,SAT_MIRROR                                  ;#6685: 21 50 E0
        push    hl                                             ;#6688: E5
        ld      b,80h                                          ;#6689: 06 80
INIT_SPRITE_ATTRS_CLEAR:
        ; Clear sprite attribute mirror loop
        ld      (hl),0                                         ;#668B: 36 00
        inc     hl                                             ;#668D: 23
        djnz    INIT_SPRITE_ATTRS_CLEAR                        ;#668E: 10 FB
        pop     de                                             ;#6690: D1
        pop     hl                                             ;#6691: E1
INIT_SPRITE_ATTRS_LOOP:
        ; Internal loop for processing sprite attribute stream
        ld      a,(hl)                                         ;#6692: 7E
        inc     hl                                             ;#6693: 23
        or      a                                              ;#6694: B7
        jr      z,SYNC_SPRITE_ATTRIBUTES_ALL                   ;#6695: 28 06
        ld      c,a                                            ;#6697: 4F
        call    REPLICATE_4_BYTE_BLOCK                         ;#6698: CD 95 45
        jr      INIT_SPRITE_ATTRS_LOOP                         ;#669B: 18 F5

SYNC_SPRITE_ATTRIBUTES_ALL:
        ; Sync all 32 sprite attributes to VRAM
        ld      hl,SAT_MIRROR                                  ;#669D: 21 50 E0
        ld      de,VRAM_SAT_BASE                               ;#66A0: 11 00 3B
        ld      bc,80h                                         ;#66A3: 01 80 00
        jp      COPY_RAM_TO_VRAM                               ;#66A6: C3 C7 44

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
        SPRITE_ATTR_REPT 0Ah, 0E0h, 0, 7Ch, COLOR_TRANSPARENT  ;#66A9: 0A E0 00 7C 00
        SPRITE_ATTR_REPT 1, 90h, 70h, 0, COLOR_BLACK           ;#66AE: 01 90 70 00 01
        SPRITE_ATTR_REPT 1, 90h, 80h, 4, COLOR_BLACK           ;#66B3: 01 90 80 04 01
        SPRITE_ATTR_REPT 1, 0A0h, 70h, 8, COLOR_BLACK          ;#66B8: 01 A0 70 08 01
        SPRITE_ATTR_REPT 1, 0A0h, 80h, 0Ch, COLOR_BLACK        ;#66BD: 01 A0 80 0C 01
        SPRITE_ATTR_REPT 1, 0E0h, 0, 0D4h, COLOR_DARK_YELLOW   ;#66C2: 01 E0 00 D4 0A
        SPRITE_ATTR_REPT 1, 0E0h, 0, 0, COLOR_MED_RED          ;#66C7: 01 E0 00 00 08
        SPRITE_ATTR_REPT 1, 0E0h, 0, 7Ch, COLOR_BLACK          ;#66CC: 01 E0 00 7C 01
        SPRITE_ATTR_REPT 3, 0E0h, 0, 7Ch, COLOR_DARK_RED       ;#66D1: 03 E0 00 7C 06
        SPRITE_ATTR_REPT 1, 0AEh, 70h, 0A0h, COLOR_DARK_BLUE   ;#66D6: 01 AE 70 A0 04
        SPRITE_ATTR_REPT 1, 0AEh, 80h, 0A4h, COLOR_DARK_BLUE   ;#66DB: 01 AE 80 A4 04
        SPRITE_ATTR_REPT 8, 8, 0, 70h, COLOR_TRANSPARENT       ;#66E0: 08 08 00 70 00
        db      00h                                            ;#66E5: 00

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
        SPRITE_ATTR_REPT 4, 4Fh, 80h, 7Ch, COLOR_TRANSPARENT   ;#66E6: 04 4F 80 7C 00
        SPRITE_ATTR_REPT 1, 52h, 80h, 0E8h, COLOR_TRANSPARENT  ;#66EB: 01 52 80 E8 00
        SPRITE_ATTR_REPT 1, 52h, 80h, 0ECh, COLOR_TRANSPARENT  ;#66F0: 01 52 80 EC 00
        SPRITE_ATTR_REPT 1, 52h, 80h, 0E4h, COLOR_WHITE        ;#66F5: 01 52 80 E4 0F
        SPRITE_ATTR_REPT 1, 7Fh, 78h, 0D0h, COLOR_DARK_YELLOW  ;#66FA: 01 7F 78 D0 0A
        db      00h                                            ;#66FF: 00

GOAL_FLAG_ATTRIBUTES:
        ; Initial sprite attributes for the 4 goal-scene flags (4 x 4 bytes)
        ; Format: FORMAT_SPRITE_ATTR
        ; - Single 4-byte block for one hardware sprite: [Y, X, Pattern, Color].
        ; - Coordinates are screen-relative (Y=208 or E0h hides the sprite).
        SPRITE_ATTR 7Fh, 70h, 0F0h, COLOR_DARK_YELLOW          ;#6700: 7F 70 F0 0A
        SPRITE_ATTR 87h, 78h, 0F4h, COLOR_DARK_YELLOW          ;#6704: 87 78 F4 0A
        SPRITE_ATTR 77h, 70h, 0F8h, COLOR_BLACK                ;#6708: 77 70 F8 01
        SPRITE_ATTR 77h, 80h, 0FCh, COLOR_BLACK                ;#670C: 77 80 FC 01

LOAD_MAIN_SPRITE_PATTERNS:
        ; Initialize tertiary stage VRAM graphics (Entry point)
        ld      hl,MAIN_SPRITE_PATTERNS                        ;#6710: 21 16 67
        jp      DECOMPRESS_VRAM_INDIRECT                       ;#6713: C3 3F 45

MAIN_SPRITE_PATTERNS:
        ; Sprite patterns: stage init (loaded by LOAD_MAIN_SPRITE_PATTERNS)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1800h                                      ;#6716: 00 58
        dh      "0D0083030F1F03008A030F1B376F5FFF"             ;#6718: 0D 00 83 03 0F 1F 03 00 8A 03 0F 1B 37 6F 5F FF
        dh      "FFBFBF03FF030086C0F0F8FCFEFE07FF"             ;#6728: FF BF BF 03 FF 03 00 86 C0 F0 F8 FC FE FE 07 FF
        dh      "0D0086C0E0F03F706007010300830303"             ;#6738: 0D 00 86 C0 E0 F0 3F 70 60 07 01 03 00 83 03 03
        dh      "000CFF847FFFE3010CFF87FEFFC780F8"             ;#6748: 00 0C FF 84 7F FF E3 01 0C FF 87 FE FF C7 80 F8
        dh      "18080680040082C0C00B000501010303"             ;#6758: 18 08 06 80 04 00 82 C0 C0 0B 00 05 01 01 03 03
        dh      "008A071F376FDFBFFFFFBFBF03FF0300"             ;#6768: 00 8A 07 1F 37 6F DF BF FF FF BF BF 03 FF 03 00
        dh      "85C0F0F8FCFC03FE05FF0C008BE0F0F8"             ;#6778: 85 C0 F0 F8 FC FC 03 FE 05 FF 0C 00 8B E0 F0 F8
        dh      "F8070F1F3E383020090008FF887F7F3F"             ;#6788: F8 07 0F 1F 3E 38 30 20 09 00 08 FF 88 7F 7F 3F
        dh      "1F7F7700000DFF86FD39080C00000780"             ;#6798: 1F 7F 77 00 00 0D FF 86 FD 39 08 0C 00 00 07 80
        dh      "8600C0E0A0E0E00C0084071F3F7F0300"             ;#67A8: 86 00 C0 E0 A0 E0 E0 0C 00 84 07 1F 3F 7F 03 00
        dh      "8A030F1B372F6F7F7FDFBF03FF030084"             ;#67B8: 8A 03 0F 1B 37 2F 6F 7F 7F DF BF 03 FF 03 00 84
        dh      "E0F8FCFE09FF0A000680836000000701"             ;#67C8: E0 F8 FC FE 09 FF 0A 00 06 80 83 60 00 00 07 01
        dh      "860003070507070DFF83BF9C1008FF8F"             ;#67D8: 86 00 03 07 05 07 07 0D FF 83 BF 9C 10 08 FF 8F
        dh      "FEFEFCF8FEEE0000E0F0F8381C0C0409"             ;#67E8: FE FE FC F8 FE EE 00 00 E0 F0 F8 38 1C 0C 04 09
        dh      "00833F7060050185020607070303000C"             ;#67F8: 00 83 3F 70 60 05 01 85 02 06 07 07 03 03 00 0C
        dh      "FF843F0F01000CFF87FEF8E080F81808"             ;#6808: FF 84 3F 0F 01 00 0C FF 87 FE F8 E0 80 F8 18 08
        dh      "0580854060E0E0C00D00862030181F0F"             ;#6818: 05 80 85 40 60 E0 E0 C0 0D 00 86 20 30 18 1F 0F
        dh      "0703008A030F1B376F5FFFFFBFBF03FF"             ;#6828: 07 03 00 8A 03 0F 1B 37 6F 5F FF FF BF BF 03 FF
        dh      "030086C0F0F8FCFEFE07FF0A0089040C"             ;#6838: 03 00 86 C0 F0 F8 FC FE FE 07 FF 0A 00 89 04 0C
        dh      "1CF8F0E0030000050185020607070303"             ;#6848: 1C F8 F0 E0 03 00 00 05 01 85 02 06 07 07 03 03
        dh      "000CFF847F1F07010CFF87FCF08000C0"             ;#6858: 00 0C FF 84 7F 1F 07 01 0C FF 87 FC F0 80 00 C0
        dh      "00000580854060E0E0C0060084E0F8FC"             ;#6868: 00 00 05 80 85 40 60 E0 E0 C0 06 00 84 E0 F8 FC
        dh      "FE09FF0900058083E0F06003010C0006"             ;#6878: FE 09 FF 09 00 05 80 83 E0 F0 60 03 01 0C 00 06
        dh      "FF8A7F7F3F3F1F1F0E0C080007FF84FE"             ;#6888: FF 8A 7F 7F 3F 3F 1F 1F 0E 0C 08 00 07 FF 84 FE
        dh      "FEFCB8050083F8FC0C1600050182070F"             ;#6898: FE FC B8 05 00 83 F8 FC 0C 16 00 05 01 82 07 0F
        dh      "03008A071F376FDFBFFFFFBFBF03FF83"             ;#68A8: 03 00 8A 07 1F 37 6F DF BF FF FF BF BF 03 FF 83
        dh      "1F3F300D0007FF857F7F3F1B01040006"             ;#68B8: 1F 3F 30 0D 00 07 FF 85 7F 7F 3F 1B 01 04 00 06
        dh      "FF8BFEFEFCFCF8F8F03010000C038018"             ;#68C8: FF 8B FE FE FC FC F8 F8 F0 30 10 00 0C 03 80 18
        dh      "00841E3F3F03030089030F1B376F5FFF"             ;#68D8: 00 84 1E 3F 3F 03 03 00 89 03 0F 1B 37 6F 5F FF
        dh      "DFDF04FF030086C0F0F8FCFEFE07FF0C"             ;#68E8: DF DF 04 FF 03 00 86 C0 F0 F8 FC FE FE 07 FF 0C
        dh      "008578FCFCC0010F0008FF825F0F0307"             ;#68F8: 00 85 78 FC FC C0 01 0F 00 08 FF 82 5F 0F 03 07
        dh      "8303010108FF82FAF003E08480000080"             ;#6908: 83 03 01 01 08 FF 82 FA F0 03 E0 84 80 00 00 80
        dh      "1700862070D8F8F8700A0086040E1B1F"             ;#6918: 17 00 86 20 70 D8 F8 F8 70 0A 00 86 04 0E 1B 1F
        dh      "1F0E050004780138120086040E1B1F1F"             ;#6928: 1F 0E 05 00 04 78 01 38 12 00 86 04 0E 1B 1F 1F
        dh      "0E0A00862070D8F8F8700300040F010E"             ;#6938: 0E 0A 00 86 20 70 D8 F8 F8 70 03 00 04 0F 01 0E
        dh      "2D00830301010E00858080A0C0200900"             ;#6948: 2D 00 83 03 01 01 0E 00 85 80 80 A0 C0 20 09 00
        dh      "88030701000001000108008780C0E0E0"             ;#6958: 88 03 07 01 00 00 01 00 01 08 00 87 80 C0 E0 E0
        dh      "6060C0080086071F377F3F0C0A000180"             ;#6968: 60 60 C0 08 00 86 07 1F 37 7F 3F 0C 0A 00 01 80
        dh      "03E087F07030181C101004008930383C"             ;#6978: 03 E0 87 F0 70 30 18 1C 10 10 04 00 89 30 38 3C
        dh      "3F1F3F2F27030A0086800888FEF0800B"             ;#6988: 3F 1F 3F 2F 27 03 0A 00 86 80 08 88 FE F0 80 0B
        dh      "008501010503040A0083C080800C0087"             ;#6998: 00 85 01 01 05 03 04 0A 00 83 C0 80 80 0C 00 87
        dh      "01030707060603090088C0E080000080"             ;#69A8: 01 03 07 07 06 06 03 09 00 88 C0 E0 80 00 00 80
        dh      "0080070001010307870F0E0C18380808"             ;#69B8: 00 80 07 00 01 01 03 07 87 0F 0E 0C 18 38 08 08
        dh      "050086E0F8ECFEFC300C00860180817F"             ;#69C8: 05 00 86 E0 F8 EC FE FC 30 0C 00 86 01 80 81 7F
        dh      "0F010700890C1C3CFCF8FCF4E4C00600"             ;#69D8: 0F 01 07 00 89 0C 1C 3C FC F8 FC F4 E4 C0 06 00
        dh      "8207070D00017F03FF0C0001FE03FF0D"             ;#69E8: 82 07 07 0D 00 01 7F 03 FF 0C 00 01 FE 03 FF 0D
        dh      "0082E0E0100087C0F0F8FCFCFEFE06FF"             ;#69F8: 00 82 E0 E0 10 00 87 C0 F0 F8 FC FC FE FE 06 FF
        dh      "0700890C1C3CF8F8F0C000800BFF85FE"             ;#6A08: 07 00 89 0C 1C 3C F8 F8 F0 C0 00 80 0B FF 85 FE
        dh      "FCFC3808068084B8F8F0E00D00893038"             ;#6A18: FC FC 38 08 06 80 84 B8 F8 F0 E0 0D 00 89 30 38
        dh      "3C1F1F0F030001030088030F1B372F7F"             ;#6A28: 3C 1F 1F 0F 03 00 01 03 00 88 03 0F 1B 37 2F 7F
        dh      "5FDF05FF0601841D1F0F0706000BFF85"             ;#6A38: 5F DF 05 FF 06 01 84 1D 1F 0F 07 06 00 0B FF 85
        dh      "7F3F3F1C100600880600201329010906"             ;#6A48: 7F 3F 3F 1C 10 06 00 88 06 00 20 13 29 01 09 06
        dh      "080088600004C894809060040085030F"             ;#6A58: 08 00 88 60 00 04 C8 94 80 90 60 04 00 85 03 0F
        dh      "1F3F3F097F870000C0F0F8FCFC09FE08"             ;#6A68: 1F 3F 3F 09 7F 87 00 00 C0 F0 F8 FC FC 09 FE 08
        dh      "0088060C20132911290608008F603004"             ;#6A78: 00 88 06 0C 20 13 29 11 29 06 08 00 8F 60 30 04
        dh      "C8948894600101030D1E3F3F037F03FE"             ;#6A88: C8 94 88 94 60 01 01 03 0D 1E 3F 3F 03 7F 03 FE
        dh      "84FCF0607F0BFF813F060085030F3F7F"             ;#6A98: 84 FC F0 60 7F 0B FF 81 3F 06 00 85 03 0F 3F 7F
        dh      "7F08FF030085C0F0FCFEFE08FF81FE0B"             ;#6AA8: 7F 08 FF 03 00 85 C0 F0 FC FE FE 08 FF 81 FE 0B
        dh      "FF81FC0300878080C0B078FCFC03FE03"             ;#6AB8: FF 81 FC 03 00 87 80 80 C0 B0 78 FC FC 03 FE 03
        dh      "7F833F0F06080086030F380C07030A00"             ;#6AC8: 7F 83 3F 0F 06 08 00 86 03 0F 38 0C 07 03 0A 00
        dh      "86C0F01C30E0C007008B0404CCDF7F3F"             ;#6AD8: 86 C0 F0 1C 30 E0 C0 07 00 8B 04 04 CC DF 7F 3F
        dh      "7FFF3F0D1007008940C08080C0E0F080"             ;#6AE8: 7F FF 3F 0D 10 07 00 89 40 C0 80 80 C0 E0 F0 80
        dh      "800B00851FFF7F3F030B0085C0F0FFFE"             ;#6AF8: 80 0B 00 85 1F FF 7F 3F 03 0B 00 85 C0 F0 FF FE
        dh      "F00C00840F3F1F070D0083F0FCC00D00"             ;#6B08: F0 0C 00 84 0F 3F 1F 07 0D 00 83 F0 FC C0 0D 00
        dh      "83070F070D008380F0000CFF04000CFF"             ;#6B18: 83 07 0F 07 0D 00 83 80 F0 00 0C FF 04 00 0C FF
        dh      "0400060084030F1F1F0C0084C0F0F8F8"             ;#6B28: 04 00 06 00 84 03 0F 1F 1F 0C 00 84 C0 F0 F8 F8
        dh      "0600"                                         ;#6B38: 06 00
        db      0                                              ;#6B3A: 00

VICTORY_SPRITE_PATTERNS:
        ; Victory-dance sprite patterns (loaded by LOAD_VICTORY_GFX at the goal)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1F80h                                      ;#6B3B: 80 5F
        dh      "0400860F1F1B1D1C0F0A0086F0F8DCBE"             ;#6B3D: 04 00 86 0F 1F 1B 1D 1C 0F 0A 00 86 F0 F8 DC BE
        dh      "7CF006000B0084030707030C0085C0C0"             ;#6B4D: 7C F0 06 00 0B 00 84 03 07 07 03 0C 00 85 C0 C0
        dh      "C08000A000383C0F0F06040000000000"             ;#6B5D: C0 80 00 A0 00 38 3C 0F 0F 06 04 00 00 00 00 00
        dh      "000000000000FEFFFF1F0F0700000000"             ;#6B6D: 00 00 00 00 00 00 FE FF FF 1F 0F 07 00 00 00 00
        dh      "00000000A000000080C1C3E7EF000000"             ;#6B7D: 00 00 00 00 A0 00 00 00 80 C1 C3 E7 EF 00 00 00
        dh      "00000000000000008080808080000000"             ;#6B8D: 00 00 00 00 00 00 00 00 80 80 80 80 80 00 00 00
        dh      "0000000000"                                   ;#6B9D: 00 00 00 00 00
        db      0                                              ;#6BA2: 00

ANIM_BIG_HOLE_LEFT:
        ; HUD spawn/pickup tile-stream for the big hole on the left lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#6BA3: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6BA4: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6BA5: EF
        VRAM_TILES "93"                                        ;#6BA6: 93
        db      00h                                            ;#6BA7: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6BA8: 41
        VRAM_TILE_COLUMN 0Eh                                   ;#6BA9: EE
        VRAM_TILES "A195A2"                                    ;#6BAA: A1 95 A2
        db      00h                                            ;#6BAD: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6BAE: 41
        VRAM_TILE_COLUMN 0Eh                                   ;#6BAF: EE
        VRAM_TILES "0F0F0F"                                    ;#6BB0: 0F 0F 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#6BB3: EE
        VRAM_TILES "9898A3"                                    ;#6BB4: 98 98 A3
        db      00h                                            ;#6BB7: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#6BB8: 61
        VRAM_TILE_COLUMN 0Eh                                   ;#6BB9: EE
        VRAM_TILES "0F0F0F"                                    ;#6BBA: 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6BBD: ED
        VRAM_TILES "999A9A9B"                                  ;#6BBE: 99 9A 9A 9B
        db      00h                                            ;#6BC2: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#6BC3: 81
        VRAM_TILE_COLUMN 0Dh                                   ;#6BC4: ED
        VRAM_TILES "0F0F0F0F"                                  ;#6BC5: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6BC9: EC
        VRAM_TILES "A49D9D9D9DA5"                              ;#6BCA: A4 9D 9D 9D 9D A5
        db      00h                                            ;#6BD0: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#6BD1: A1
        VRAM_TILE_COLUMN 0Ch                                   ;#6BD2: EC
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6BD3: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ah                                   ;#6BD9: EA
        VRAM_TILES "A8AA9F9F9F9F9FABA7"                        ;#6BDA: A8 AA 9F 9F 9F 9F 9F AB A7
        db      00h                                            ;#6BE3: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#6BE4: C1
        VRAM_TILE_COLUMN 0Ah                                   ;#6BE5: EA
        VRAM_TILES "0F0F0F0F0F0F0F0F0F"                        ;#6BE6: 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#6BEF: E9
        VRAM_TILES "70826C6C6C6C6C6C8371"                      ;#6BF0: 70 82 6C 6C 6C 6C 6C 6C 83 71
        db      00h                                            ;#6BFA: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#6BFB: E1
        VRAM_TILE_COLUMN 9                                     ;#6BFC: E9
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F"                      ;#6BFD: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 8                                     ;#6C07: E8
        VRAM_TILE_COLUMN 7                                     ;#6C08: E7
        VRAM_TILES "7273848B6D6D6D6D6D6D8E8675"                ;#6C09: 72 73 84 8B 6D 6D 6D 6D 6D 6D 8E 86 75
        db      00h                                            ;#6C16: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#6C17: 22
        VRAM_TILE_COLUMN 7                                     ;#6C18: E7
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F"                ;#6C19: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 6                                     ;#6C26: E6
        VRAM_TILES "727384906E6E6E6E6E6E6E91047478"            ;#6C27: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 91 04 74 78
        VRAM_TILE_COLUMN 5                                     ;#6C36: E5
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F8D6F7B7C"          ;#6C37: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 8D 6F 7B 7C
        VRAM_TILES "7D"                                        ;#6C47: 7D
        db      00h                                            ;#6C48: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#6C49: 42
        VRAM_TILE_COLUMN 6                                     ;#6C4A: E6
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"            ;#6C4B: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 5                                     ;#6C5A: E5
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E928675"          ;#6C5B: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 92 86 75
        VRAM_TILES "0F"                                        ;#6C6B: 0F
        VRAM_TILE_COLUMN 4                                     ;#6C6C: E4
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F6F8C87"          ;#6C6D: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 6F 8C 87
        VRAM_TILES "7E7F"                                      ;#6C7D: 7E 7F
        db      00h                                            ;#6C7F: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#6C80: 62
        VRAM_TILE_COLUMN 5                                     ;#6C81: E5
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6C82: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 4                                     ;#6C92: E4
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E6E9104"          ;#6C93: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 91 04
        VRAM_TILES "7478"                                      ;#6CA3: 74 78
        VRAM_TILE_COLUMN 3                                     ;#6CA5: E3
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F6F6F8D"          ;#6CA6: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F 8D
        VRAM_TILES "6F7B7C7D"                                  ;#6CB6: 6F 7B 7C 7D
        db      00h                                            ;#6CBA: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#6CBB: 82
        VRAM_TILE_COLUMN 4                                     ;#6CBC: E4
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6CBD: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F"                                      ;#6CCD: 0F 0F
        VRAM_TILE_COLUMN 3                                     ;#6CCF: E3
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E6E6E6E"          ;#6CD0: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E
        VRAM_TILES "9286750F"                                  ;#6CE0: 92 86 75 0F
        VRAM_TILE_COLUMN 2                                     ;#6CE4: E2
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F6F6F6F"          ;#6CE5: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F
        VRAM_TILES "6F8C877E7F"                                ;#6CF5: 6F 8C 87 7E 7F
        db      00h                                            ;#6CFA: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#6CFB: A2
        VRAM_TILE_COLUMN 3                                     ;#6CFC: E3
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6CFD: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F0F"                                    ;#6D0D: 0F 0F 0F
        VRAM_TILE_COLUMN 2                                     ;#6D10: E2
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E6E6E6E"          ;#6D11: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E
        VRAM_TILES "6E91047478"                                ;#6D21: 6E 91 04 74 78
        db      00h                                            ;#6D26: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#6D27: C2
        VRAM_TILE_COLUMN 2                                     ;#6D28: E2
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6D29: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F0F0F0F"                                ;#6D39: 0F 0F 0F 0F 0F
        db      00h                                            ;#6D3E: 00

ANIM_BIG_HOLE_RIGHT:
        ; HUD spawn/pickup tile-stream for the big hole on the right lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#6D3F: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6D40: 41
        VRAM_TILE_COLUMN 10h                                   ;#6D41: F0
        VRAM_TILES "93"                                        ;#6D42: 93
        db      00h                                            ;#6D43: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6D44: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6D45: EF
        VRAM_TILES "949596"                                    ;#6D46: 94 95 96
        db      00h                                            ;#6D49: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6D4A: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6D4B: EF
        VRAM_TILES "0F0F0F"                                    ;#6D4C: 0F 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6D4F: EF
        VRAM_TILES "979898"                                    ;#6D50: 97 98 98
        db      00h                                            ;#6D53: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#6D54: 61
        VRAM_TILE_COLUMN 0Fh                                   ;#6D55: EF
        VRAM_TILES "0F0F0F"                                    ;#6D56: 0F 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6D59: EF
        VRAM_TILES "999A9A9B"                                  ;#6D5A: 99 9A 9A 9B
        db      00h                                            ;#6D5E: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#6D5F: 81
        VRAM_TILE_COLUMN 0Fh                                   ;#6D60: EF
        VRAM_TILES "0F0F0F0F"                                  ;#6D61: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#6D65: EE
        VRAM_TILES "9C9D9D9D9D9E"                              ;#6D66: 9C 9D 9D 9D 9D 9E
        db      00h                                            ;#6D6C: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#6D6D: A1
        VRAM_TILE_COLUMN 0Eh                                   ;#6D6E: EE
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6D6F: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6D75: ED
        VRAM_TILES "A6AA9F9F9F9F9FABA7"                        ;#6D76: A6 AA 9F 9F 9F 9F 9F AB A7
        db      00h                                            ;#6D7F: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#6D80: C1
        VRAM_TILE_COLUMN 0Dh                                   ;#6D81: ED
        VRAM_TILES "0F0F0F0F0F0F0F0F0F"                        ;#6D82: 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6D8B: ED
        VRAM_TILES "70826C6C6C6C6C6C8377"                      ;#6D8C: 70 82 6C 6C 6C 6C 6C 6C 83 77
        db      00h                                            ;#6D96: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#6D97: E1
        VRAM_TILE_COLUMN 0Dh                                   ;#6D98: ED
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F"                      ;#6D99: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6DA3: ED
        VRAM_TILE_COLUMN 0Ch                                   ;#6DA4: EC
        VRAM_TILES "7689886D6D6D6D6D6D6D8E8675"                ;#6DA5: 76 89 88 6D 6D 6D 6D 6D 6D 6D 8E 86 75
        db      00h                                            ;#6DB2: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#6DB3: 22
        VRAM_TILE_COLUMN 0Ch                                   ;#6DB4: EC
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F"                ;#6DB5: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6DC2: EC
        VRAM_TILES "76898F6E6E6E6E6E6E6E91047478"              ;#6DC3: 76 89 8F 6E 6E 6E 6E 6E 6E 6E 91 04 74 78
        VRAM_TILE_COLUMN 0Bh                                   ;#6DD1: EB
        VRAM_TILES "808193856F6F6F6F6F6F6F8D6F7B7C7D"          ;#6DD2: 80 81 93 85 6F 6F 6F 6F 6F 6F 6F 8D 6F 7B 7C 7D
        db      00h                                            ;#6DE2: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#6DE3: 42
        VRAM_TILE_COLUMN 0Ch                                   ;#6DE4: EC
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F"              ;#6DE5: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Bh                                   ;#6DF3: EB
        VRAM_TILES "727384906E6E6E6E6E6E6E6E91047478"          ;#6DF4: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 91 04 74 78
        VRAM_TILE_COLUMN 0Ah                                   ;#6E04: EA
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F8D6F7B"          ;#6E05: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 8D 6F 7B
        VRAM_TILES "7C7D"                                      ;#6E15: 7C 7D
        db      00h                                            ;#6E17: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#6E18: 62
        VRAM_TILE_COLUMN 0Bh                                   ;#6E19: EB
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6E1A: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ah                                   ;#6E2A: EA
        VRAM_TILES "0F76898F6E6E6E6E6E6E6E6E6E6E9104"          ;#6E2B: 0F 76 89 8F 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 91 04
        VRAM_TILES "7478"                                      ;#6E3B: 74 78
        VRAM_TILE_COLUMN 0Ah                                   ;#6E3D: EA
        VRAM_TILES "8081938D6F6F6F6F6F6F6F6F6F6F8D6F"          ;#6E3E: 80 81 93 8D 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F 8D 6F
        VRAM_TILES "7B7C7D"                                    ;#6E4E: 7B 7C 7D
        db      00h                                            ;#6E51: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#6E52: 82
        VRAM_TILE_COLUMN 0Bh                                   ;#6E53: EB
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6E54: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F"                                        ;#6E64: 0F
        VRAM_TILE_COLUMN 0Ah                                   ;#6E65: EA
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E6E6E91"          ;#6E66: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 91
        VRAM_TILES "047478"                                    ;#6E76: 04 74 78
        VRAM_TILE_COLUMN 9                                     ;#6E79: E9
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F6F6F6F"          ;#6E7A: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F
        VRAM_TILES "8D6F7B7C7D"                                ;#6E8A: 8D 6F 7B 7C 7D
        db      00h                                            ;#6E8F: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#6E90: A2
        VRAM_TILE_COLUMN 0Ah                                   ;#6E91: EA
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6E92: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F0F"                                    ;#6EA2: 0F 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#6EA5: E9
        VRAM_TILES "0F76898F6E6E6E6E6E6E6E6E6E6E6E6E"          ;#6EA6: 0F 76 89 8F 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E
        VRAM_TILES "6E91047778"                                ;#6EB6: 6E 91 04 77 78
        db      00h                                            ;#6EBB: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#6EBC: C2
        VRAM_TILE_COLUMN 0Ah                                   ;#6EBD: EA
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6EBE: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F0F0F"                                  ;#6ECE: 0F 0F 0F 0F
        db      00h                                            ;#6ED2: 00

ANIM_SMALL_HOLE_CENTER:
        ; HUD spawn/pickup tile-stream for the small hole in the center lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#6ED3: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6ED4: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6ED5: EF
        VRAM_TILES "AFB0"                                      ;#6ED6: AF B0
        db      00h                                            ;#6ED8: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6ED9: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6EDA: EF
        VRAM_TILES "94A2"                                      ;#6EDB: 94 A2
        db      00h                                            ;#6EDD: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6EDE: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6EDF: EF
        VRAM_TILES "0F0F"                                      ;#6EE0: 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6EE2: EF
        VRAM_TILES "BFC0"                                      ;#6EE3: BF C0
        db      00h                                            ;#6EE5: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#6EE6: 61
        VRAM_TILE_COLUMN 0Fh                                   ;#6EE7: EF
        VRAM_TILES "0F0F"                                      ;#6EE8: 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6EEA: EF
        VRAM_TILES "B7B8"                                      ;#6EEB: B7 B8
        db      00h                                            ;#6EED: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#6EEE: 81
        VRAM_TILE_COLUMN 0Fh                                   ;#6EEF: EF
        VRAM_TILES "0F0F"                                      ;#6EF0: 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6EF2: EF
        VRAM_TILES "BCBD"                                      ;#6EF3: BC BD
        db      00h                                            ;#6EF5: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#6EF6: A1
        VRAM_TILE_COLUMN 0Fh                                   ;#6EF7: EF
        VRAM_TILES "0F0F"                                      ;#6EF8: 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6EFA: EF
        VRAM_TILES "C1C2"                                      ;#6EFB: C1 C2
        db      00h                                            ;#6EFD: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#6EFE: C1
        VRAM_TILE_COLUMN 0Fh                                   ;#6EFF: EF
        VRAM_TILES "0F0F"                                      ;#6F00: 0F 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#6F02: EE
        VRAM_TILES "94959596"                                  ;#6F03: 94 95 95 96
        db      00h                                            ;#6F07: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#6F08: E1
        VRAM_TILE_COLUMN 0Eh                                   ;#6F09: EE
        VRAM_TILES "0F0F0F0F"                                  ;#6F0A: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 1Fh                                   ;#6F0E: FF
        VRAM_TILE_COLUMN 0Eh                                   ;#6F0F: EE
        VRAM_TILES "97989899"                                  ;#6F10: 97 98 98 99
        db      00h                                            ;#6F14: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#6F15: 22
        VRAM_TILE_COLUMN 0Eh                                   ;#6F16: EE
        VRAM_TILES "0F0F0F0F"                                  ;#6F17: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#6F1B: EE
        VRAM_TILES "9A98989B"                                  ;#6F1C: 9A 98 98 9B
        VRAM_TILE_COLUMN 0Eh                                   ;#6F20: EE
        VRAM_TILES "ABAAAAAC"                                  ;#6F21: AB AA AA AC
        db      00h                                            ;#6F25: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#6F26: 42
        VRAM_TILE_COLUMN 0Eh                                   ;#6F27: EE
        VRAM_TILES "0F0F0F0F"                                  ;#6F28: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6F2C: ED
        VRAM_TILES "9C9D98989E9F"                              ;#6F2D: 9C 9D 98 98 9E 9F
        VRAM_TILE_COLUMN 0Dh                                   ;#6F33: ED
        VRAM_TILES "A3A4A1A1A5A6"                              ;#6F34: A3 A4 A1 A1 A5 A6
        db      00h                                            ;#6F3A: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#6F3B: 62
        VRAM_TILE_COLUMN 0Dh                                   ;#6F3C: ED
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6F3D: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6F43: ED
        VRAM_TILES "9A989898989B"                              ;#6F44: 9A 98 98 98 98 9B
        VRAM_TILE_COLUMN 0Dh                                   ;#6F4A: ED
        VRAM_TILES "ABA1A8A8A1AC"                              ;#6F4B: AB A1 A8 A8 A1 AC
        db      00h                                            ;#6F51: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#6F52: 82
        VRAM_TILE_COLUMN 0Dh                                   ;#6F53: ED
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6F54: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6F5A: EC
        VRAM_TILES "9C9D989898989E9F"                          ;#6F5B: 9C 9D 98 98 98 98 9E 9F
        VRAM_TILE_COLUMN 0Ch                                   ;#6F63: EC
        VRAM_TILES "A3A4A8A9A9A9A5A6"                          ;#6F64: A3 A4 A8 A9 A9 A9 A5 A6
        db      00h                                            ;#6F6C: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#6F6D: A2
        VRAM_TILE_COLUMN 0Ch                                   ;#6F6E: EC
        VRAM_TILES "0F0F0F0F0F0F0F0F"                          ;#6F6F: 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6F77: EC
        VRAM_TILES "9A9898989898989B"                          ;#6F78: 9A 98 98 98 98 98 98 9B
        db      00h                                            ;#6F80: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#6F81: C2
        VRAM_TILE_COLUMN 0Ch                                   ;#6F82: EC
        VRAM_TILES "0F0F0F0F0F0F0F0F"                          ;#6F83: 0F 0F 0F 0F 0F 0F 0F 0F
        db      00h                                            ;#6F8B: 00

ANIM_SMALL_HOLE_LEFT:
        ; HUD spawn/pickup tile-stream for the small hole on the left lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#6F8C: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6F8D: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6F8E: EF
        VRAM_TILES "B2"                                        ;#6F8F: B2
        db      00h                                            ;#6F90: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6F91: 41
        VRAM_TILE_COLUMN 0Eh                                   ;#6F92: EE
        VRAM_TILES "B40F"                                      ;#6F93: B4 0F
        db      00h                                            ;#6F95: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6F96: 41
        VRAM_TILE_COLUMN 0Eh                                   ;#6F97: EE
        VRAM_TILES "0F"                                        ;#6F98: 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6F99: ED
        VRAM_TILES "BFB6"                                      ;#6F9A: BF B6
        db      00h                                            ;#6F9C: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#6F9D: 61
        VRAM_TILE_COLUMN 0Dh                                   ;#6F9E: ED
        VRAM_TILES "0F0F"                                      ;#6F9F: 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6FA1: ED
        VRAM_TILES "BABB"                                      ;#6FA2: BA BB
        db      00h                                            ;#6FA4: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#6FA5: 81
        VRAM_TILE_COLUMN 0Dh                                   ;#6FA6: ED
        VRAM_TILES "0F0F"                                      ;#6FA7: 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6FA9: EC
        VRAM_TILES "BEBE"                                      ;#6FAA: BE BE
        db      00h                                            ;#6FAC: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#6FAD: A1
        VRAM_TILE_COLUMN 0Ch                                   ;#6FAE: EC
        VRAM_TILES "0F0F"                                      ;#6FAF: 0F 0F
        VRAM_TILE_COLUMN 0Bh                                   ;#6FB1: EB
        VRAM_TILES "C1C3C2"                                    ;#6FB2: C1 C3 C2
        db      00h                                            ;#6FB5: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#6FB6: C1
        VRAM_TILE_COLUMN 0Bh                                   ;#6FB7: EB
        VRAM_TILES "0F0F0F"                                    ;#6FB8: 0F 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#6FBB: E9
        VRAM_TILES "9495959596"                                ;#6FBC: 94 95 95 95 96
        db      00h                                            ;#6FC1: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#6FC2: E1
        VRAM_TILE_COLUMN 9                                     ;#6FC3: E9
        VRAM_TILES "0F0F0F0F0F"                                ;#6FC4: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 1Fh                                   ;#6FC9: FF
        VRAM_TILE_COLUMN 8                                     ;#6FCA: E8
        VRAM_TILES "9798989899"                                ;#6FCB: 97 98 98 98 99
        db      00h                                            ;#6FD0: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#6FD1: 22
        VRAM_TILE_COLUMN 8                                     ;#6FD2: E8
        VRAM_TILES "0F0F0F0F0F"                                ;#6FD3: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 7                                     ;#6FD8: E7
        VRAM_TILES "9A9898989B"                                ;#6FD9: 9A 98 98 98 9B
        VRAM_TILE_COLUMN 7                                     ;#6FDE: E7
        VRAM_TILES "ABAAAAAAAC"                                ;#6FDF: AB AA AA AA AC
        db      00h                                            ;#6FE4: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#6FE5: 42
        VRAM_TILE_COLUMN 7                                     ;#6FE6: E7
        VRAM_TILES "0F0F0F0F0F"                                ;#6FE7: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 6                                     ;#6FEC: E6
        VRAM_TILES "9A9898989E9F"                              ;#6FED: 9A 98 98 98 9E 9F
        VRAM_TILE_COLUMN 6                                     ;#6FF3: E6
        VRAM_TILES "A0A1A1A1A5A6"                              ;#6FF4: A0 A1 A1 A1 A5 A6
        db      00h                                            ;#6FFA: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#6FFB: 62
        VRAM_TILE_COLUMN 6                                     ;#6FFC: E6
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6FFD: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 5                                     ;#7003: E5
        VRAM_TILES "9A989898989B0F"                            ;#7004: 9A 98 98 98 98 9B 0F
        VRAM_TILE_COLUMN 5                                     ;#700B: E5
        VRAM_TILES "A0A1A8A8A1A2"                              ;#700C: A0 A1 A8 A8 A1 A2
        db      00h                                            ;#7012: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#7013: 82
        VRAM_TILE_COLUMN 5                                     ;#7014: E5
        VRAM_TILES "0F0F0F0F0F0F"                              ;#7015: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 4                                     ;#701B: E4
        VRAM_TILES "9A989898989E9F"                            ;#701C: 9A 98 98 98 98 9E 9F
        VRAM_TILE_COLUMN 4                                     ;#7023: E4
        VRAM_TILES "A0A1A8A8A1A2A6"                            ;#7024: A0 A1 A8 A8 A1 A2 A6
        db      00h                                            ;#702B: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#702C: A2
        VRAM_TILE_COLUMN 4                                     ;#702D: E4
        VRAM_TILES "0F0F0F0F0F0F0F"                            ;#702E: 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 3                                     ;#7035: E3
        VRAM_TILES "9A9898989898989B0F"                        ;#7036: 9A 98 98 98 98 98 98 9B 0F
        db      00h                                            ;#703F: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#7040: C2
        VRAM_TILE_COLUMN 3                                     ;#7041: E3
        VRAM_TILES "0F0F0F0F0F0F0F0F"                          ;#7042: 0F 0F 0F 0F 0F 0F 0F 0F
        db      00h                                            ;#704A: 00

ANIM_SMALL_HOLE_RIGHT:
        ; HUD spawn/pickup tile-stream for the small hole on the right lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#704B: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#704C: 41
        VRAM_TILE_COLUMN 10h                                   ;#704D: F0
        VRAM_TILES "B1"                                        ;#704E: B1
        db      00h                                            ;#704F: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7050: 41
        VRAM_TILE_COLUMN 10h                                   ;#7051: F0
        VRAM_TILES "0FB3"                                      ;#7052: 0F B3
        db      00h                                            ;#7054: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7055: 41
        VRAM_TILE_COLUMN 11h                                   ;#7056: F1
        VRAM_TILES "0F"                                        ;#7057: 0F
        VRAM_TILE_COLUMN 11h                                   ;#7058: F1
        VRAM_TILES "B5C0"                                      ;#7059: B5 C0
        db      00h                                            ;#705B: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#705C: 61
        VRAM_TILE_COLUMN 11h                                   ;#705D: F1
        VRAM_TILES "0F0F"                                      ;#705E: 0F 0F
        VRAM_TILE_COLUMN 11h                                   ;#7060: F1
        VRAM_TILES "B9BA"                                      ;#7061: B9 BA
        db      00h                                            ;#7063: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#7064: 81
        VRAM_TILE_COLUMN 11h                                   ;#7065: F1
        VRAM_TILES "0F0F"                                      ;#7066: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#7068: F2
        VRAM_TILES "BEBE"                                      ;#7069: BE BE
        db      00h                                            ;#706B: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#706C: A1
        VRAM_TILE_COLUMN 12h                                   ;#706D: F2
        VRAM_TILES "0F0F"                                      ;#706E: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#7070: F2
        VRAM_TILES "C1C3C2"                                    ;#7071: C1 C3 C2
        db      00h                                            ;#7074: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#7075: C1
        VRAM_TILE_COLUMN 12h                                   ;#7076: F2
        VRAM_TILES "0F0F0F"                                    ;#7077: 0F 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#707A: F2
        VRAM_TILES "9495959596"                                ;#707B: 94 95 95 95 96
        db      00h                                            ;#7080: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#7081: E1
        VRAM_TILE_COLUMN 12h                                   ;#7082: F2
        VRAM_TILES "0F0F0F0F0F"                                ;#7083: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 1Fh                                   ;#7088: FF
        VRAM_TILE_COLUMN 13h                                   ;#7089: F3
        VRAM_TILES "9798989899"                                ;#708A: 97 98 98 98 99
        db      00h                                            ;#708F: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#7090: 22
        VRAM_TILE_COLUMN 13h                                   ;#7091: F3
        VRAM_TILES "0F0F0F0F0F"                                ;#7092: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 14h                                   ;#7097: F4
        VRAM_TILES "9A9898989B"                                ;#7098: 9A 98 98 98 9B
        VRAM_TILE_COLUMN 14h                                   ;#709D: F4
        VRAM_TILES "ABAAAAAAAC"                                ;#709E: AB AA AA AA AC
        db      00h                                            ;#70A3: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#70A4: 42
        VRAM_TILE_COLUMN 14h                                   ;#70A5: F4
        VRAM_TILES "0F0F0F0F0F"                                ;#70A6: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 14h                                   ;#70AB: F4
        VRAM_TILES "9C9D9898989E"                              ;#70AC: 9C 9D 98 98 98 9E
        VRAM_TILE_COLUMN 14h                                   ;#70B2: F4
        VRAM_TILES "A3A4A1A1A1A2"                              ;#70B3: A3 A4 A1 A1 A1 A2
        db      00h                                            ;#70B9: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#70BA: 62
        VRAM_TILE_COLUMN 14h                                   ;#70BB: F4
        VRAM_TILES "0F0F0F0F0F0F"                              ;#70BC: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 14h                                   ;#70C2: F4
        VRAM_TILES "0F9A989898989B"                            ;#70C3: 0F 9A 98 98 98 98 9B
        VRAM_TILE_COLUMN 15h                                   ;#70CA: F5
        VRAM_TILES "A0A1A8A8A1A2"                              ;#70CB: A0 A1 A8 A8 A1 A2
        db      00h                                            ;#70D1: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#70D2: 82
        VRAM_TILE_COLUMN 15h                                   ;#70D3: F5
        VRAM_TILES "0F0F0F0F0F0F"                              ;#70D4: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 15h                                   ;#70DA: F5
        VRAM_TILES "9C9D989898989E"                            ;#70DB: 9C 9D 98 98 98 98 9E
        VRAM_TILE_COLUMN 15h                                   ;#70E2: F5
        VRAM_TILES "A3A4A8A9A8A1A2"                            ;#70E3: A3 A4 A8 A9 A8 A1 A2
        db      00h                                            ;#70EA: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#70EB: A2
        VRAM_TILE_COLUMN 15h                                   ;#70EC: F5
        VRAM_TILES "0F0F0F0F0F0F0F"                            ;#70ED: 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 15h                                   ;#70F4: F5
        VRAM_TILES "0F9A9898989898989B"                        ;#70F5: 0F 9A 98 98 98 98 98 98 9B
        db      00h                                            ;#70FE: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#70FF: C2
        VRAM_TILE_COLUMN 16h                                   ;#7100: F6
        VRAM_TILES "0F0F0F0F0F0F0F0F"                          ;#7101: 0F 0F 0F 0F 0F 0F 0F 0F
        db      00h                                            ;#7109: 00

ANIM_FLAG_LEFT:
        ; HUD spawn/pickup tile-stream for the flag on the left lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#710A: 00
        db      00h                                            ;#710B: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#710C: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#710D: EF
        VRAM_TILES "C6"                                        ;#710E: C6
        db      00h                                            ;#710F: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7110: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#7111: EF
        VRAM_TILES "C7"                                        ;#7112: C7
        db      00h                                            ;#7113: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7114: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#7115: EF
        VRAM_TILES "0F"                                        ;#7116: 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#7117: EF
        VRAM_TILES "C9"                                        ;#7118: C9
        db      00h                                            ;#7119: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#711A: 61
        VRAM_TILE_COLUMN 0Fh                                   ;#711B: EF
        VRAM_TILES "0F"                                        ;#711C: 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#711D: EE
        VRAM_TILES "CE"                                        ;#711E: CE
        db      00h                                            ;#711F: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#7120: 81
        VRAM_TILE_COLUMN 0Dh                                   ;#7121: ED
        VRAM_TILES "C8CA"                                      ;#7122: C8 CA
        VRAM_TILE_COLUMN 0Dh                                   ;#7124: ED
        VRAM_TILES "CFCB"                                      ;#7125: CF CB
        db      00h                                            ;#7127: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#7128: 81
        VRAM_TILE_COLUMN 0Dh                                   ;#7129: ED
        VRAM_TILES "0F0F"                                      ;#712A: 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#712C: ED
        VRAM_TILES "CC0F"                                      ;#712D: CC 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#712F: EC
        VRAM_TILES "A1CD"                                      ;#7130: A1 CD
        db      00h                                            ;#7132: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#7133: A1
        VRAM_TILE_COLUMN 0Dh                                   ;#7134: ED
        VRAM_TILES "0F"                                        ;#7135: 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#7136: EC
        VRAM_TILES "0F0F"                                      ;#7137: 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#7139: EC
        VRAM_TILES "03AD"                                      ;#713A: 03 AD
        VRAM_TILE_COLUMN 0Bh                                   ;#713C: EB
        VRAM_TILES "B5B1"                                      ;#713D: B5 B1
        db      00h                                            ;#713F: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#7140: E1
        VRAM_TILE_COLUMN 0Ch                                   ;#7141: EC
        VRAM_TILES "0F0F"                                      ;#7142: 0F 0F
        VRAM_TILE_COLUMN 0Bh                                   ;#7144: EB
        VRAM_TILES "AEAE"                                      ;#7145: AE AE
        VRAM_TILE_COLUMN 0Bh                                   ;#7147: EB
        VRAM_TILES "0303"                                      ;#7148: 03 03
        VRAM_TILE_COLUMN 0Ah                                   ;#714A: EA
        VRAM_TILES "7FB0"                                      ;#714B: 7F B0
        db      00h                                            ;#714D: 00
        db      00h                                            ;#714E: 00
        VRAM_TILE_HEADER 3A00h, 1                              ;#714F: 02
        VRAM_TILE_COLUMN 0Bh                                   ;#7150: EB
        VRAM_TILES "0F0F"                                      ;#7151: 0F 0F
        VRAM_TILE_COLUMN 0Bh                                   ;#7153: EB
        VRAM_TILES "0F0F"                                      ;#7154: 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#7156: E9
        VRAM_TILES "AF0303"                                    ;#7157: AF 03 03
        VRAM_TILE_COLUMN 9                                     ;#715A: E9
        VRAM_TILES "AF0303"                                    ;#715B: AF 03 03
        VRAM_TILE_COLUMN 8                                     ;#715E: E8
        VRAM_TILES "7FB2"                                      ;#715F: 7F B2
        db      00h                                            ;#7161: 00
        db      00h                                            ;#7162: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#7163: 42
        VRAM_TILE_COLUMN 9                                     ;#7164: E9
        VRAM_TILES "0F0F0F"                                    ;#7165: 0F 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#7168: E9
        VRAM_TILES "0F0F0F"                                    ;#7169: 0F 0F 0F
        VRAM_TILE_COLUMN 8                                     ;#716C: E8
        VRAM_TILES "0F0F"                                      ;#716D: 0F 0F
        VRAM_TILE_COLUMN 5                                     ;#716F: E5
        VRAM_TILES "030303"                                    ;#7170: 03 03 03
        VRAM_TILE_COLUMN 5                                     ;#7173: E5
        VRAM_TILES "030303"                                    ;#7174: 03 03 03
        db      00h                                            ;#7177: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#7178: A2
        VRAM_TILE_COLUMN 5                                     ;#7179: E5
        VRAM_TILES "0F0F0F"                                    ;#717A: 0F 0F 0F
        VRAM_TILE_COLUMN 5                                     ;#717D: E5
        VRAM_TILES "0F0F0F"                                    ;#717E: 0F 0F 0F
        db      00h                                            ;#7181: 00

ANIM_FLAG_RIGHT:
        ; HUD spawn/pickup tile-stream for the flag on the right lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#7182: 00
        db      00h                                            ;#7183: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7184: 41
        VRAM_TILE_COLUMN 10h                                   ;#7185: F0
        VRAM_TILES "C6"                                        ;#7186: C6
        db      00h                                            ;#7187: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7188: 41
        VRAM_TILE_COLUMN 10h                                   ;#7189: F0
        VRAM_TILES "C8"                                        ;#718A: C8
        db      00h                                            ;#718B: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#718C: 41
        VRAM_TILE_COLUMN 10h                                   ;#718D: F0
        VRAM_TILES "0F"                                        ;#718E: 0F
        VRAM_TILE_COLUMN 11h                                   ;#718F: F1
        VRAM_TILES "C9"                                        ;#7190: C9
        db      00h                                            ;#7191: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#7192: 61
        VRAM_TILE_COLUMN 11h                                   ;#7193: F1
        VRAM_TILES "0F"                                        ;#7194: 0F
        VRAM_TILE_COLUMN 11h                                   ;#7195: F1
        VRAM_TILES "CE"                                        ;#7196: CE
        db      00h                                            ;#7197: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#7198: 81
        VRAM_TILE_COLUMN 11h                                   ;#7199: F1
        VRAM_TILES "C8CA"                                      ;#719A: C8 CA
        VRAM_TILE_COLUMN 11h                                   ;#719C: F1
        VRAM_TILES "CFCB"                                      ;#719D: CF CB
        db      00h                                            ;#719F: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#71A0: 81
        VRAM_TILE_COLUMN 11h                                   ;#71A1: F1
        VRAM_TILES "0F0F"                                      ;#71A2: 0F 0F
        VRAM_TILE_COLUMN 11h                                   ;#71A4: F1
        VRAM_TILES "0FCC"                                      ;#71A5: 0F CC
        VRAM_TILE_COLUMN 11h                                   ;#71A7: F1
        VRAM_TILES "A1CD"                                      ;#71A8: A1 CD
        db      00h                                            ;#71AA: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#71AB: A1
        VRAM_TILE_COLUMN 12h                                   ;#71AC: F2
        VRAM_TILES "0F"                                        ;#71AD: 0F
        VRAM_TILE_COLUMN 11h                                   ;#71AE: F1
        VRAM_TILES "0F0F"                                      ;#71AF: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#71B1: F2
        VRAM_TILES "AF03"                                      ;#71B2: AF 03
        VRAM_TILE_COLUMN 12h                                   ;#71B4: F2
        VRAM_TILES "B2"                                        ;#71B5: B2
        db      00h                                            ;#71B6: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#71B7: E1
        VRAM_TILE_COLUMN 12h                                   ;#71B8: F2
        VRAM_TILES "0F0F"                                      ;#71B9: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#71BB: F2
        VRAM_TILES "0FAEAE"                                    ;#71BC: 0F AE AE
        VRAM_TILE_COLUMN 13h                                   ;#71BF: F3
        VRAM_TILES "0303"                                      ;#71C0: 03 03
        VRAM_TILE_COLUMN 12h                                   ;#71C2: F2
        VRAM_TILES "7FB0"                                      ;#71C3: 7F B0
        db      00h                                            ;#71C5: 00
        db      00h                                            ;#71C6: 00
        VRAM_TILE_HEADER 3A00h, 1                              ;#71C7: 02
        VRAM_TILE_COLUMN 13h                                   ;#71C8: F3
        VRAM_TILES "0F0F"                                      ;#71C9: 0F 0F
        VRAM_TILE_COLUMN 13h                                   ;#71CB: F3
        VRAM_TILES "0F0F"                                      ;#71CC: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#71CE: F2
        VRAM_TILES "0FAF0303"                                  ;#71CF: 0F AF 03 03
        VRAM_TILE_COLUMN 13h                                   ;#71D3: F3
        VRAM_TILES "AF0303"                                    ;#71D4: AF 03 03
        VRAM_TILE_COLUMN 12h                                   ;#71D7: F2
        VRAM_TILES "7FB2"                                      ;#71D8: 7F B2
        db      00h                                            ;#71DA: 00
        db      00h                                            ;#71DB: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#71DC: 42
        VRAM_TILE_COLUMN 13h                                   ;#71DD: F3
        VRAM_TILES "0F0F0F"                                    ;#71DE: 0F 0F 0F
        VRAM_TILE_COLUMN 13h                                   ;#71E1: F3
        VRAM_TILES "0F0F0F"                                    ;#71E2: 0F 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#71E5: F2
        VRAM_TILES "0F0F"                                      ;#71E6: 0F 0F
        VRAM_TILE_COLUMN 18h                                   ;#71E8: F8
        VRAM_TILES "030303"                                    ;#71E9: 03 03 03
        VRAM_TILE_COLUMN 18h                                   ;#71EC: F8
        VRAM_TILES "030303"                                    ;#71ED: 03 03 03
        db      00h                                            ;#71F0: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#71F1: A2
        VRAM_TILE_COLUMN 18h                                   ;#71F2: F8
        VRAM_TILES "0F0F0F"                                    ;#71F3: 0F 0F 0F
        VRAM_TILE_COLUMN 18h                                   ;#71F6: F8
        VRAM_TILES "0F0F0F"                                    ;#71F7: 0F 0F 0F
        db      00h                                            ;#71FA: 00

STAGE_SEGMENT_DEFINITIONS:
        ; Pointer table for road segment data (4 entries)
        dw      ROAD_ICE_RIGHT_1                               ;#71FB: 03 72
        dw      ROAD_ICE_LEFT_1                                ;#71FD: 40 72
        dw      ROAD_WATER_RIGHT_1                             ;#71FF: 7D 72
        dw      ROAD_WATER_LEFT_1                              ;#7201: B2 72

ROAD_ICE_RIGHT_1:
        ; Ice road, right slot — root (4 frame ptrs + fill + paint + init)
        dw      ROAD_ICE_RIGHT_2                               ;#7203: E7 72
        dw      ROAD_ICE_RIGHT_3                               ;#7205: 0F 73
        dw      ROAD_ICE_RIGHT_4                               ;#7207: 27 73
        dw      ROAD_ICE_RIGHT_5                               ;#7209: 48 73

ROAD_ICE_RIGHT_1_FILL:
        ; Ice road, right slot — perspective background fill (right half)
        ; Format: FORMAT_VRAM_FILL_STREAM
        ; - First byte: fill value (tile index to paint).
        ; - Then pairs: [count, addr_lo]. Each pair paints one horizontal strip.
        ; - Addr base is 39xx; high byte auto-increments when addr_lo < 20h.
        ; - Count 00h terminates the stream.
        ROAD_FILL_VALUE 0Fh                                    ;#720B: 0F
        ROAD_FILL_RUN 0Fh, 51h                                 ;#720C: 0F 51
        ROAD_FILL_RUN 0Eh, 72h                                 ;#720E: 0E 72
        ROAD_FILL_RUN 0Dh, 93h                                 ;#7210: 0D 93
        ROAD_FILL_RUN 0Bh, 0B5h                                ;#7212: 0B B5
        ROAD_FILL_RUN 0Ah, 0D6h                                ;#7214: 0A D6
        ROAD_FILL_RUN 9, 0F7h                                  ;#7216: 09 F7
        ROAD_FILL_RUN 8, 18h                                   ;#7218: 08 18
        ROAD_FILL_RUN 6, 3Ah                                   ;#721A: 06 3A
        ROAD_FILL_RUN 5, 5Bh                                   ;#721C: 05 5B
        ROAD_FILL_RUN 3, 7Dh                                   ;#721E: 03 7D
        ROAD_FILL_RUN 2, 9Eh                                   ;#7220: 02 9E
        ROAD_FILL_RUN 1, 0BFh                                  ;#7222: 01 BF
        db      00h                                            ;#7224: 00

ROAD_ICE_RIGHT_1_VRAM:
        ; Ice road, right slot — name-table paint pass (road tiles)
        ; Fallthrough from ROAD_ICE_RIGHT_1_FILL (WRITE_VRAM_STREAM step of UPLOAD).
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 11h                               ;#7225: 51 39
        VRAM_TILES "0F101112131415"                            ;#7227: 0F 10 11 12 13 14 15
        STREAM_BLOCK_END                                       ;#722E: FF

ROAD_ICE_RIGHT_1_INIT:
        ; Ice road, right slot — E1xx color/lane init buffer
        ; Format: FORMAT_ROAD_SEGMENT_INIT
        ROAD_SEGMENT_HEADER 60h                                ;#722F: 60
        ROAD_SEGMENT_ROW 0, 0, 0, 0F3h                         ;#7230: 00 00 00 F3
        ROAD_SEGMENT_ROW 0F4h, 0F3h, 0F7h, 0F5h                ;#7234: F4 F3 F7 F5
        ROAD_SEGMENT_ROW 0F6h, 0F4h, 0F3h, 0F7h                ;#7238: F6 F4 F3 F7
        ROAD_SEGMENT_ROW 0F5h, 0F6h, 0, 0                      ;#723C: F5 F6 00 00

ROAD_ICE_LEFT_1:
        ; Ice road, left slot — root (4 frame ptrs + fill + paint + init)
        dw      ROAD_ICE_LEFT_2                                ;#7240: 60 73
        dw      ROAD_ICE_LEFT_3                                ;#7242: 88 73
        dw      ROAD_ICE_LEFT_4                                ;#7244: A0 73
        dw      ROAD_ICE_LEFT_5                                ;#7246: C1 73

ROAD_ICE_LEFT_1_FILL:
        ; Ice road, left slot — perspective background fill (left half)
        ; Format: FORMAT_VRAM_FILL_STREAM
        ; - First byte: fill value (tile index to paint).
        ; - Then pairs: [count, addr_lo]. Each pair paints one horizontal strip.
        ; - Addr base is 39xx; high byte auto-increments when addr_lo < 20h.
        ; - Count 00h terminates the stream.
        ROAD_FILL_VALUE 0Fh                                    ;#7248: 0F
        ROAD_FILL_RUN 0Fh, 40h                                 ;#7249: 0F 40
        ROAD_FILL_RUN 0Eh, 60h                                 ;#724B: 0E 60
        ROAD_FILL_RUN 0Dh, 80h                                 ;#724D: 0D 80
        ROAD_FILL_RUN 0Bh, 0A0h                                ;#724F: 0B A0
        ROAD_FILL_RUN 0Ah, 0C0h                                ;#7251: 0A C0
        ROAD_FILL_RUN 9, 0E0h                                  ;#7253: 09 E0
        ROAD_FILL_RUN 8, 0                                     ;#7255: 08 00
        ROAD_FILL_RUN 6, 20h                                   ;#7257: 06 20
        ROAD_FILL_RUN 5, 40h                                   ;#7259: 05 40
        ROAD_FILL_RUN 3, 60h                                   ;#725B: 03 60
        ROAD_FILL_RUN 2, 80h                                   ;#725D: 02 80
        ROAD_FILL_RUN 1, 0A0h                                  ;#725F: 01 A0
        db      00h                                            ;#7261: 00

ROAD_ICE_LEFT_1_VRAM:
        ; Ice road, left slot — name-table paint pass (road tiles)
        ; Fallthrough from ROAD_ICE_LEFT_1_FILL (WRITE_VRAM_STREAM step of UPLOAD).
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 8                                 ;#7262: 48 39
        VRAM_TILES "1514131252100F"                            ;#7264: 15 14 13 12 52 10 0F
        STREAM_BLOCK_END                                       ;#726B: FF

ROAD_ICE_LEFT_1_INIT:
        ; Ice road, left slot — E1xx color/lane init buffer
        ; Fallthrough from ROAD_ICE_LEFT_1_VRAM (read after WRITE_VRAM_STREAM returns).
        ; Format: FORMAT_ROAD_SEGMENT_INIT
        ROAD_SEGMENT_HEADER 50h                                ;#726C: 50
        ROAD_SEGMENT_ROW 0F3h, 0F5h, 0F6h, 0F4h                ;#726D: F3 F5 F6 F4
        ROAD_SEGMENT_ROW 0F5h, 0F7h, 0F6h, 0F4h                ;#7271: F5 F7 F6 F4
        ROAD_SEGMENT_ROW 0F4h, 0F3h, 0F5h, 0F6h                ;#7275: F4 F3 F5 F6
        ROAD_SEGMENT_ROW 0F4h, 0F5h, 0F6h, 0                   ;#7279: F4 F5 F6 00

ROAD_WATER_RIGHT_1:
        ; Water road, right slot — root (4 frame ptrs + fill + paint + init)
        dw      ROAD_WATER_RIGHT_2                             ;#727D: D9 73
        dw      ROAD_WATER_RIGHT_3                             ;#727F: FA 73
        dw      ROAD_WATER_RIGHT_4                             ;#7281: 1B 74
        dw      ROAD_WATER_RIGHT_5                             ;#7283: 39 74

ROAD_WATER_RIGHT_1_FILL:
        ; Water road, right slot — perspective background fill (right half)
        ; Fallthrough from ROAD_WATER_RIGHT_1 frame ptrs (FILL_VRAM_STREAM input).
        ; Format: FORMAT_VRAM_FILL_STREAM
        ; - First byte: fill value (tile index to paint).
        ; - Then pairs: [count, addr_lo]. Each pair paints one horizontal strip.
        ; - Addr base is 39xx; high byte auto-increments when addr_lo < 20h.
        ; - Count 00h terminates the stream.
        ROAD_FILL_VALUE 4                                      ;#7285: 04
        ROAD_FILL_RUN 0Dh, 53h                                 ;#7286: 0D 53
        ROAD_FILL_RUN 0Ch, 74h                                 ;#7288: 0C 74
        ROAD_FILL_RUN 0Ah, 96h                                 ;#728A: 0A 96
        ROAD_FILL_RUN 9, 0B7h                                  ;#728C: 09 B7
        ROAD_FILL_RUN 7, 0D9h                                  ;#728E: 07 D9
        ROAD_FILL_RUN 6, 0FAh                                  ;#7290: 06 FA
        ROAD_FILL_RUN 5, 1Bh                                   ;#7292: 05 1B
        ROAD_FILL_RUN 3, 3Dh                                   ;#7294: 03 3D
        db      00h                                            ;#7296: 00

ROAD_WATER_RIGHT_1_VRAM:
        ; Water road, right slot — name-table paint pass (road tiles)
        ; Fallthrough from ROAD_WATER_RIGHT_1_FILL (WRITE_VRAM_STREAM step of UPLOAD).
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 11h                               ;#7297: 51 39
        VRAM_TILES "393C"                                      ;#7299: 39 3C
        STREAM_NEXT_BLOCK                                      ;#729B: FE
        VRAM_NAME_TABLE 0Bh, 12h                               ;#729C: 72 39
        VRAM_TILES "3738"                                      ;#729E: 37 38
        STREAM_BLOCK_END                                       ;#72A0: FF

ROAD_WATER_RIGHT_1_INIT:
        ; Water road, right slot — E1xx color/lane init buffer
        ; Format: FORMAT_ROAD_SEGMENT_INIT
        ROAD_SEGMENT_HEADER 60h                                ;#72A1: 60
        ROAD_SEGMENT_ROW 0, 0, 0, 0                            ;#72A2: 00 00 00 00
        ROAD_SEGMENT_ROW 0F8h, 0FCh, 0F9h, 0FBh                ;#72A6: F8 FC F9 FB
        ROAD_SEGMENT_ROW 0FCh, 0F9h, 0F9h, 0F9h                ;#72AA: FC F9 F9 F9
        ROAD_SEGMENT_ROW 0FBh, 0FAh, 0, 0                      ;#72AE: FB FA 00 00

ROAD_WATER_LEFT_1:
        ; Water road, left slot — root (4 frame ptrs + fill + paint + init)
        dw      ROAD_WATER_LEFT_2                              ;#72B2: 56 74
        dw      ROAD_WATER_LEFT_3                              ;#72B4: 77 74
        dw      ROAD_WATER_LEFT_4                              ;#72B6: 98 74
        dw      ROAD_WATER_LEFT_5                              ;#72B8: B6 74

ROAD_WATER_LEFT_1_FILL:
        ; Water road, left slot — perspective background fill (left half)
        ; Fallthrough from ROAD_WATER_LEFT_1 frame ptrs (FILL_VRAM_STREAM input).
        ; Format: FORMAT_VRAM_FILL_STREAM
        ; - First byte: fill value (tile index to paint).
        ; - Then pairs: [count, addr_lo]. Each pair paints one horizontal strip.
        ; - Addr base is 39xx; high byte auto-increments when addr_lo < 20h.
        ; - Count 00h terminates the stream.
        ROAD_FILL_VALUE 4                                      ;#72BA: 04
        ROAD_FILL_RUN 0Dh, 40h                                 ;#72BB: 0D 40
        ROAD_FILL_RUN 0Ch, 60h                                 ;#72BD: 0C 60
        ROAD_FILL_RUN 0Ah, 80h                                 ;#72BF: 0A 80
        ROAD_FILL_RUN 9, 0A0h                                  ;#72C1: 09 A0
        ROAD_FILL_RUN 7, 0C0h                                  ;#72C3: 07 C0
        ROAD_FILL_RUN 6, 0E0h                                  ;#72C5: 06 E0
        ROAD_FILL_RUN 5, 0                                     ;#72C7: 05 00
        ROAD_FILL_RUN 3, 20h                                   ;#72C9: 03 20
        db      00h                                            ;#72CB: 00

ROAD_WATER_LEFT_1_VRAM:
        ; Water road, left slot — name-table paint pass (road tiles)
        ; Fallthrough from ROAD_WATER_LEFT_1_FILL (WRITE_VRAM_STREAM step of UPLOAD).
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 0Dh                               ;#72CC: 4D 39
        VRAM_TILES "7D7A"                                      ;#72CE: 7D 7A
        STREAM_NEXT_BLOCK                                      ;#72D0: FE
        VRAM_NAME_TABLE 0Bh, 0Ch                               ;#72D1: 6C 39
        VRAM_TILES "7978"                                      ;#72D3: 79 78
        STREAM_BLOCK_END                                       ;#72D5: FF

ROAD_WATER_LEFT_1_INIT:
        ; Water road, left slot — E1xx color/lane init buffer
        ; Fallthrough from ROAD_WATER_LEFT_1_VRAM (read after WRITE_VRAM_STREAM returns).
        ; Format: FORMAT_ROAD_SEGMENT_INIT
        ROAD_SEGMENT_HEADER 50h                                ;#72D6: 50
        ROAD_SEGMENT_ROW 0, 0, 0, 0F8h                         ;#72D7: 00 00 00 F8
        ROAD_SEGMENT_ROW 0FBh, 0F9h, 0FCh, 0FBh                ;#72DB: FB F9 FC FB
        ROAD_SEGMENT_ROW 0F9h, 0FBh, 0FCh, 0FAh                ;#72DF: F9 FB FC FA
        ROAD_SEGMENT_ROW 0, 0, 0, 0                            ;#72E3: 00 00 00 00

ROAD_ICE_RIGHT_2:
        ; Ice road, right slot — animation frame 1/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#72E7: 21
        VRAM_TILE_COLUMN 18h                                   ;#72E8: F8
        VRAM_TILES "1315121212141414"                          ;#72E9: 13 15 12 12 12 14 14 14
        VRAM_TILE_COLUMN 15h                                   ;#72F1: F5
        VRAM_TILES "16171819191A1B1C1C1C1C"                    ;#72F2: 16 17 18 19 19 1A 1B 1C 1C 1C 1C
        VRAM_TILE_COLUMN 17h                                   ;#72FD: F7
        VRAM_TILES "1D1E1F1F1F20212223"                        ;#72FE: 1D 1E 1F 1F 1F 20 21 22 23
        VRAM_TILE_COLUMN 1Ah                                   ;#7307: FA
        VRAM_TILES "0F2425262626"                              ;#7308: 0F 24 25 26 26 26
        db      00h                                            ;#730E: 00

ROAD_ICE_RIGHT_3:
        ; Ice road, right slot — animation frame 2/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#730F: 21
        VRAM_TILE_COLUMN 1Ah                                   ;#7310: FA
        VRAM_TILES "15"                                        ;#7311: 15
        VRAM_TILE_COLUMN 15h                                   ;#7312: F5
        VRAM_TILES "27282929192A"                              ;#7313: 27 28 29 29 19 2A
        VRAM_TILE_COLUMN 17h                                   ;#7319: F7
        VRAM_TILES "2B2B1E1F2829192D"                          ;#731A: 2B 2B 1E 1F 28 29 19 2D
        VRAM_TILE_COLUMN 1Ah                                   ;#7322: FA
        VRAM_TILES "2E2626"                                    ;#7323: 2E 26 26
        db      00h                                            ;#7326: 00

ROAD_ICE_RIGHT_4:
        ; Ice road, right slot — animation frame 3/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#7327: 21
        VRAM_TILE_COLUMN 18h                                   ;#7328: F8
        VRAM_TILES "151515121212"                              ;#7329: 15 15 15 12 12 12
        VRAM_TILE_COLUMN 15h                                   ;#732F: F5
        VRAM_TILES "16171819192F1B1C2222"                      ;#7330: 16 17 18 19 19 2F 1B 1C 22 22
        VRAM_TILE_COLUMN 17h                                   ;#733A: F7
        VRAM_TILES "1D1E1F1F1F202122"                          ;#733B: 1D 1E 1F 1F 1F 20 21 22
        VRAM_TILE_COLUMN 1Ah                                   ;#7343: FA
        VRAM_TILES "0F2425"                                    ;#7344: 0F 24 25
        db      00h                                            ;#7347: 00

ROAD_ICE_RIGHT_5:
        ; Ice road, right slot — animation frame 4/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#7348: 21
        VRAM_TILE_COLUMN 1Ah                                   ;#7349: FA
        VRAM_TILES "12"                                        ;#734A: 12
        VRAM_TILE_COLUMN 15h                                   ;#734B: F5
        VRAM_TILES "27282929192D"                              ;#734C: 27 28 29 29 19 2D
        VRAM_TILE_COLUMN 17h                                   ;#7352: F7
        VRAM_TILES "2B2B1E1F2C29192D"                          ;#7353: 2B 2B 1E 1F 2C 29 19 2D
        VRAM_TILE_COLUMN 1Ah                                   ;#735B: FA
        VRAM_TILES "2E2626"                                    ;#735C: 2E 26 26
        db      00h                                            ;#735F: 00

ROAD_ICE_LEFT_2:
        ; Ice road, left slot — animation frame 1/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#7360: 21
        VRAM_TILE_COLUMN 0                                     ;#7361: E0
        VRAM_TILES "1414141212121513"                          ;#7362: 14 14 14 12 12 12 15 13
        VRAM_TILE_COLUMN 0                                     ;#736A: E0
        VRAM_TILES "5D5D5D5D5C5B5A5A595857"                    ;#736B: 5D 5D 5D 5D 5C 5B 5A 5A 59 58 57
        VRAM_TILE_COLUMN 0                                     ;#7376: E0
        VRAM_TILES "646362616060605F5E"                        ;#7377: 64 63 62 61 60 60 60 5F 5E
        VRAM_TILE_COLUMN 0                                     ;#7380: E0
        VRAM_TILES "67676766650F"                              ;#7381: 67 67 67 66 65 0F
        db      00h                                            ;#7387: 00

ROAD_ICE_LEFT_3:
        ; Ice road, left slot — animation frame 2/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#7388: 21
        VRAM_TILE_COLUMN 5                                     ;#7389: E5
        VRAM_TILES "14"                                        ;#738A: 14
        VRAM_TILE_COLUMN 5                                     ;#738B: E5
        VRAM_TILES "6B5A6A6A6968"                              ;#738C: 6B 5A 6A 6A 69 68
        VRAM_TILE_COLUMN 1                                     ;#7392: E1
        VRAM_TILES "6E5A6A69605F6C6C"                          ;#7393: 6E 5A 6A 69 60 5F 6C 6C
        VRAM_TILE_COLUMN 3                                     ;#739B: E3
        VRAM_TILES "67676F"                                    ;#739C: 67 67 6F
        db      00h                                            ;#739F: 00

ROAD_ICE_LEFT_4:
        ; Ice road, left slot — animation frame 3/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#73A0: 21
        VRAM_TILE_COLUMN 2                                     ;#73A1: E2
        VRAM_TILES "121212151515"                              ;#73A2: 12 12 12 15 15 15
        VRAM_TILE_COLUMN 1                                     ;#73A8: E1
        VRAM_TILES "63635D5C705A5A595857"                      ;#73A9: 63 63 5D 5C 70 5A 5A 59 58 57
        VRAM_TILE_COLUMN 1                                     ;#73B3: E1
        VRAM_TILES "6362616060605F5E"                          ;#73B4: 63 62 61 60 60 60 5F 5E
        VRAM_TILE_COLUMN 3                                     ;#73BC: E3
        VRAM_TILES "66650F"                                    ;#73BD: 66 65 0F
        db      00h                                            ;#73C0: 00

ROAD_ICE_LEFT_5:
        ; Ice road, left slot — animation frame 4/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#73C1: 21
        VRAM_TILE_COLUMN 5                                     ;#73C2: E5
        VRAM_TILES "12"                                        ;#73C3: 12
        VRAM_TILE_COLUMN 5                                     ;#73C4: E5
        VRAM_TILES "6E5A6A6A6968"                              ;#73C5: 6E 5A 6A 6A 69 68
        VRAM_TILE_COLUMN 1                                     ;#73CB: E1
        VRAM_TILES "6E5A6A6D605F6C6C"                          ;#73CC: 6E 5A 6A 6D 60 5F 6C 6C
        VRAM_TILE_COLUMN 3                                     ;#73D4: E3
        VRAM_TILES "67676F"                                    ;#73D5: 67 67 6F
        db      00h                                            ;#73D8: 00

ROAD_WATER_RIGHT_2:
        ; Water road, right slot — animation frame 1/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#73D9: 61
        VRAM_TILE_COLUMN 13h                                   ;#73DA: F3
        VRAM_TILES "494336"                                    ;#73DB: 49 43 36
        VRAM_TILE_COLUMN 15h                                   ;#73DE: F5
        VRAM_TILES "3748"                                      ;#73DF: 37 48
        VRAM_TILE_COLUMN 16h                                   ;#73E1: F6
        VRAM_TILES "3B4236"                                    ;#73E2: 3B 42 36
        VRAM_TILE_COLUMN 18h                                   ;#73E5: F8
        VRAM_TILES "3738"                                      ;#73E6: 37 38
        VRAM_TILE_COLUMN 18h                                   ;#73E8: F8
        VRAM_TILES "0F0F54"                                    ;#73E9: 0F 0F 54
        VRAM_TILE_COLUMN 1Ah                                   ;#73EC: FA
        VRAM_TILES "504704"                                    ;#73ED: 50 47 04
        VRAM_TILE_COLUMN 1Bh                                   ;#73F0: FB
        VRAM_TILES "4248040404"                                ;#73F1: 42 48 04 04 04
        VRAM_TILE_COLUMN 1Eh                                   ;#73F6: FE
        VRAM_TILES "4243"                                      ;#73F7: 42 43
        db      00h                                            ;#73F9: 00

ROAD_WATER_RIGHT_3:
        ; Water road, right slot — animation frame 2/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#73FA: 61
        VRAM_TILE_COLUMN 13h                                   ;#73FB: F3
        VRAM_TILES "0F4504"                                    ;#73FC: 0F 45 04
        VRAM_TILE_COLUMN 16h                                   ;#73FF: F6
        VRAM_TILES "38"                                        ;#7400: 38
        VRAM_TILE_COLUMN 16h                                   ;#7401: F6
        VRAM_TILES "4A4C04"                                    ;#7402: 4A 4C 04
        VRAM_TILE_COLUMN 17h                                   ;#7405: F7
        VRAM_TILES "374438"                                    ;#7406: 37 44 38
        VRAM_TILE_COLUMN 1Ah                                   ;#7409: FA
        VRAM_TILES "4041"                                      ;#740A: 40 41
        VRAM_TILE_COLUMN 1Ah                                   ;#740C: FA
        VRAM_TILES "0F4243"                                    ;#740D: 0F 42 43
        VRAM_TILE_COLUMN 1Bh                                   ;#7410: FB
        VRAM_TILES "0F51"                                      ;#7411: 0F 51
        VRAM_TILE_COLUMN 1Dh                                   ;#7413: FD
        VRAM_TILES "444504"                                    ;#7414: 44 45 04
        VRAM_TILE_COLUMN 1Eh                                   ;#7417: FE
        VRAM_TILES "464D"                                      ;#7418: 46 4D
        db      00h                                            ;#741A: 00

ROAD_WATER_RIGHT_4:
        ; Water road, right slot — animation frame 3/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#741B: 61
        VRAM_TILE_COLUMN 14h                                   ;#741C: F4
        VRAM_TILES "4F"                                        ;#741D: 4F
        VRAM_TILE_COLUMN 15h                                   ;#741E: F5
        VRAM_TILES "403D"                                      ;#741F: 40 3D
        VRAM_TILE_COLUMN 16h                                   ;#7421: F6
        VRAM_TILES "0F354D"                                    ;#7422: 0F 35 4D
        VRAM_TILE_COLUMN 17h                                   ;#7425: F7
        VRAM_TILES "4B4E04"                                    ;#7426: 4B 4E 04
        VRAM_TILE_COLUMN 19h                                   ;#7429: F9
        VRAM_TILES "4A4B"                                      ;#742A: 4A 4B
        VRAM_TILE_COLUMN 1Fh                                   ;#742C: FF
        VRAM_TILE_COLUMN 1Ch                                   ;#742D: FC
        VRAM_TILES "0F4041"                                    ;#742E: 0F 40 41
        VRAM_TILE_COLUMN 1Dh                                   ;#7431: FD
        VRAM_TILES "0F4252"                                    ;#7432: 0F 42 52
        VRAM_TILE_COLUMN 1Eh                                   ;#7435: FE
        VRAM_TILES "4E53"                                      ;#7436: 4E 53
        db      00h                                            ;#7438: 00

ROAD_WATER_RIGHT_5:
        ; Water road, right slot — animation frame 4/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#7439: 61
        VRAM_TILE_COLUMN 14h                                   ;#743A: F4
        VRAM_TILES "3F36"                                      ;#743B: 3F 36
        VRAM_TILE_COLUMN 15h                                   ;#743D: F5
        VRAM_TILES "463A"                                      ;#743E: 46 3A
        VRAM_TILE_COLUMN 18h                                   ;#7440: F8
        VRAM_TILES "36"                                        ;#7441: 36
        VRAM_TILE_COLUMN 17h                                   ;#7442: F7
        VRAM_TILES "0F3750"                                    ;#7443: 0F 37 50
        VRAM_TILE_COLUMN 18h                                   ;#7446: F8
        VRAM_TILES "4F554504"                                  ;#7447: 4F 55 45 04
        VRAM_TILE_COLUMN 1Ah                                   ;#744B: FA
        VRAM_TILES "464C49"                                    ;#744C: 46 4C 49
        VRAM_TILE_COLUMN 1Fh                                   ;#744F: FF
        VRAM_TILE_COLUMN 1Fh                                   ;#7450: FF
        VRAM_TILES "43"                                        ;#7451: 43
        VRAM_TILE_COLUMN 1Eh                                   ;#7452: FE
        VRAM_TILES "0F0F"                                      ;#7453: 0F 0F
        db      00h                                            ;#7455: 00

ROAD_WATER_LEFT_2:
        ; Water road, left slot — animation frame 1/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#7456: 61
        VRAM_TILE_COLUMN 0Ah                                   ;#7457: EA
        VRAM_TILES "77848A"                                    ;#7458: 77 84 8A
        VRAM_TILE_COLUMN 9                                     ;#745B: E9
        VRAM_TILES "8978"                                      ;#745C: 89 78
        VRAM_TILE_COLUMN 7                                     ;#745E: E7
        VRAM_TILES "77837C"                                    ;#745F: 77 83 7C
        VRAM_TILE_COLUMN 6                                     ;#7462: E6
        VRAM_TILES "7978"                                      ;#7463: 79 78
        VRAM_TILE_COLUMN 5                                     ;#7465: E5
        VRAM_TILES "6A0F0F"                                    ;#7466: 6A 0F 0F
        VRAM_TILE_COLUMN 3                                     ;#7469: E3
        VRAM_TILES "045D66"                                    ;#746A: 04 5D 66
        VRAM_TILE_COLUMN 0                                     ;#746D: E0
        VRAM_TILES "0404045E58"                                ;#746E: 04 04 04 5E 58
        VRAM_TILE_COLUMN 0                                     ;#7473: E0
        VRAM_TILES "5958"                                      ;#7474: 59 58
        db      00h                                            ;#7476: 00

ROAD_WATER_LEFT_3:
        ; Water road, left slot — animation frame 2/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#7477: 61
        VRAM_TILE_COLUMN 0Ah                                   ;#7478: EA
        VRAM_TILES "04860F"                                    ;#7479: 04 86 0F
        VRAM_TILE_COLUMN 9                                     ;#747C: E9
        VRAM_TILES "79"                                        ;#747D: 79
        VRAM_TILE_COLUMN 7                                     ;#747E: E7
        VRAM_TILES "048D8B"                                    ;#747F: 04 8D 8B
        VRAM_TILE_COLUMN 6                                     ;#7482: E6
        VRAM_TILES "798578"                                    ;#7483: 79 85 78
        VRAM_TILE_COLUMN 4                                     ;#7486: E4
        VRAM_TILES "5756"                                      ;#7487: 57 56
        VRAM_TILE_COLUMN 3                                     ;#7489: E3
        VRAM_TILES "59580F"                                    ;#748A: 59 58 0F
        VRAM_TILE_COLUMN 3                                     ;#748D: E3
        VRAM_TILES "670F"                                      ;#748E: 67 0F
        VRAM_TILE_COLUMN 0                                     ;#7490: E0
        VRAM_TILES "045B5A"                                    ;#7491: 04 5B 5A
        VRAM_TILE_COLUMN 0                                     ;#7494: E0
        VRAM_TILES "635C"                                      ;#7495: 63 5C
        db      00h                                            ;#7497: 00

ROAD_WATER_LEFT_4:
        ; Water road, left slot — animation frame 3/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#7498: 61
        VRAM_TILE_COLUMN 0Bh                                   ;#7499: EB
        VRAM_TILES "90"                                        ;#749A: 90
        VRAM_TILE_COLUMN 9                                     ;#749B: E9
        VRAM_TILES "7E81"                                      ;#749C: 7E 81
        VRAM_TILE_COLUMN 7                                     ;#749E: E7
        VRAM_TILES "8E760F"                                    ;#749F: 8E 76 0F
        VRAM_TILE_COLUMN 6                                     ;#74A2: E6
        VRAM_TILES "048F8C"                                    ;#74A3: 04 8F 8C
        VRAM_TILE_COLUMN 5                                     ;#74A6: E5
        VRAM_TILES "6160"                                      ;#74A7: 61 60
        VRAM_TILE_COLUMN 1Fh                                   ;#74A9: FF
        VRAM_TILE_COLUMN 1                                     ;#74AA: E1
        VRAM_TILES "57560F"                                    ;#74AB: 57 56 0F
        VRAM_TILE_COLUMN 0                                     ;#74AE: E0
        VRAM_TILES "68580F"                                    ;#74AF: 68 58 0F
        VRAM_TILE_COLUMN 0                                     ;#74B2: E0
        VRAM_TILES "6964"                                      ;#74B3: 69 64
        db      00h                                            ;#74B5: 00

ROAD_WATER_LEFT_5:
        ; Water road, left slot — animation frame 4/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#74B6: 61
        VRAM_TILE_COLUMN 0Ah                                   ;#74B7: EA
        VRAM_TILES "7780"                                      ;#74B8: 77 80
        VRAM_TILE_COLUMN 9                                     ;#74BA: E9
        VRAM_TILES "7B87"                                      ;#74BB: 7B 87
        VRAM_TILE_COLUMN 7                                     ;#74BD: E7
        VRAM_TILES "77"                                        ;#74BE: 77
        VRAM_TILE_COLUMN 6                                     ;#74BF: E6
        VRAM_TILES "91780F"                                    ;#74C0: 91 78 0F
        VRAM_TILE_COLUMN 4                                     ;#74C3: E4
        VRAM_TILES "045B6B65"                                  ;#74C4: 04 5B 6B 65
        VRAM_TILE_COLUMN 3                                     ;#74C8: E3
        VRAM_TILES "5F625C"                                    ;#74C9: 5F 62 5C
        VRAM_TILE_COLUMN 1Fh                                   ;#74CC: FF
        VRAM_TILE_COLUMN 0                                     ;#74CD: E0
        VRAM_TILES "59"                                        ;#74CE: 59
        VRAM_TILE_COLUMN 0                                     ;#74CF: E0
        VRAM_TILES "0F0F"                                      ;#74D0: 0F 0F
        db      00h                                            ;#74D2: 00

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
        ld      hl,(STAGE_DISTANCE_BCD)                        ;#74D3: 2A E5 E0
        ld      a,h                                            ;#74D6: 7C
        or      a                                              ;#74D7: B7
        ret     nz                                             ;#74D8: C0
        ld      a,l                                            ;#74D9: 7D
        and     1Fh                                            ;#74DA: E6 1F
        ret     nz                                             ;#74DC: C0
        ld      a,l                                            ;#74DD: 7D
        rlca                                                   ;#74DE: 07
        rlca                                                   ;#74DF: 07
        rlca                                                   ;#74E0: 07
        add     a,a                                            ;#74E1: 87
        ld      hl,STATION_FRAMES                              ;#74E2: 21 19 75
        call    ADD_HL_A                                       ;#74E5: CD D3 48
        ld      e,(hl)                                         ;#74E8: 5E
        inc     hl                                             ;#74E9: 23
        ld      d,(hl)                                         ;#74EA: 56
        ex      de,hl                                          ;#74EB: EB
        ld      a,(hl)                                         ;#74EC: 7E
        and     0F0h                                           ;#74ED: E6 F0
        ld      c,a                                            ;#74EF: 4F
        ld      a,(hl)                                         ;#74F0: 7E
        inc     hl                                             ;#74F1: 23
        and     3                                              ;#74F2: E6 03
        add     a,78h                                          ;#74F4: C6 78
        ld      d,a                                            ;#74F6: 57
        ld      a,c                                            ;#74F7: 79
STATION_FRAME_HEADER_LOOP:
        ; Start of VRAM header processing
        ld      b,(hl)                                         ;#74F8: 46
        inc     hl                                             ;#74F9: 23
        ld      a,20h                                          ;#74FA: 3E 20
        add     a,c                                            ;#74FC: 81
        ld      c,a                                            ;#74FD: 4F
        jr      nc,STATION_FRAME_ADDR_CALC                     ;#74FE: 30 01
        inc     d                                              ;#7500: 14
STATION_FRAME_ADDR_CALC:
        ; Carry-adjusted VRAM address calculation
        ld      a,c                                            ;#7501: 79
        add     a,b                                            ;#7502: 80
        sub     0E0h                                           ;#7503: D6 E0
        ld      e,a                                            ;#7505: 5F
        call    SET_VDP                                        ;#7506: CD B7 48
STATION_FRAME_TILE_LOOP:
        ; Emit tile bytes (with +40h offset) until 00h or next E0-FF header
        ld      a,(hl)                                         ;#7509: 7E
        or      a                                              ;#750A: B7
        ret     z                                              ;#750B: C8
        cp      0E0h                                           ;#750C: FE E0
        jr      nc,STATION_FRAME_HEADER_LOOP                   ;#750E: 30 E8
        inc     hl                                             ;#7510: 23
        add     a,40h                                          ;#7511: C6 40
        exx                                                    ;#7513: D9
        out     (c),a                                          ;#7514: ED 79
        exx                                                    ;#7516: D9
        jr      STATION_FRAME_TILE_LOOP                        ;#7517: 18 F0

STATION_FRAMES:
        ; Pointer table for end-stage station/house zoom-in frames (0=farthest, 4=closest)
        dw      STATION_FRAME_4                                ;#7519: 5E 75
        dw      STATION_FRAME_3                                ;#751B: 3B 75
        dw      STATION_FRAME_2                                ;#751D: 2D 75
        dw      STATION_FRAME_1                                ;#751F: 28 75
        dw      STATION_FRAME_0                                ;#7521: 23 75

STATION_FRAME_0:
        ; End-stage station, zoom level 0 (farthest, 2 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3900h, 2                          ;#7523: 21
        STATION_FRAME_INNER_HEADER 0Fh                         ;#7524: EF
        VRAM_TILES "9091"                                      ;#7525: 90 91
        db      00h                                            ;#7527: 00

STATION_FRAME_1:
        ; End-stage station, zoom level 1 (2 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3900h, 2                          ;#7528: 21
        STATION_FRAME_INNER_HEADER 0Fh                         ;#7529: EF
        VRAM_TILES "9293"                                      ;#752A: 92 93
        db      00h                                            ;#752C: 00

STATION_FRAME_2:
        ; End-stage station, zoom level 2 (9 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3900h, 1                          ;#752D: 01
        STATION_FRAME_INNER_HEADER 0Fh                         ;#752E: EF
        VRAM_TILES "AF"                                        ;#752F: AF
        STATION_FRAME_INNER_HEADER 0Eh                         ;#7530: EE
        VRAM_TILES "94969698"                                  ;#7531: 94 96 96 98
        STATION_FRAME_INNER_HEADER 0Eh                         ;#7535: EE
        VRAM_TILES "9597979A"                                  ;#7536: 95 97 97 9A
        db      00h                                            ;#753A: 00

STATION_FRAME_3:
        ; End-stage station, zoom level 3 (27 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3800h, 8                          ;#753B: E0
        STATION_FRAME_INNER_HEADER 0Fh                         ;#753C: EF
        VRAM_TILES "AF"                                        ;#753D: AF
        STATION_FRAME_INNER_HEADER 0Fh                         ;#753E: EF
        VRAM_TILES "B1B2"                                      ;#753F: B1 B2
        STATION_FRAME_INNER_HEADER 0Dh                         ;#7541: ED
        VRAM_TILES "9D9B9C9C9C9B"                              ;#7542: 9D 9B 9C 9C 9C 9B
        STATION_FRAME_INNER_HEADER 0Dh                         ;#7548: ED
        VRAM_TILES "C89EA4A6A8A1"                              ;#7549: C8 9E A4 A6 A8 A1
        STATION_FRAME_INNER_HEADER 0Dh                         ;#754F: ED
        VRAM_TILES "C89FA5A7A9C9"                              ;#7550: C8 9F A5 A7 A9 C9
        STATION_FRAME_INNER_HEADER 0Dh                         ;#7556: ED
        VRAM_TILES "A3A0A0A0ADA0"                              ;#7557: A3 A0 A0 A0 AD A0
        db      00h                                            ;#755D: 00

STATION_FRAME_4:
        ; End-stage station, zoom level 4 (closest, 64 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3800h, 7                          ;#755E: C0
        STATION_FRAME_INNER_HEADER 0Fh                         ;#755F: EF
        VRAM_TILES "71"                                        ;#7560: 71
        STATION_FRAME_INNER_HEADER 0Fh                         ;#7561: EF
        VRAM_TILES "B0"                                        ;#7562: B0
        STATION_FRAME_INNER_HEADER 0Fh                         ;#7563: EF
        VRAM_TILES "B1B2"                                      ;#7564: B1 B2
        STATION_FRAME_INNER_HEADER 0Bh                         ;#7566: EB
        VRAM_TILES "9D9D9B9B9B9C9C9C9C9B"                      ;#7567: 9D 9D 9B 9B 9B 9C 9C 9C 9C 9B
        STATION_FRAME_INNER_HEADER 0Bh                         ;#7571: EB
        VRAM_TILES "C8C8C9C9C9C9C9A2A2C9"                      ;#7572: C8 C8 C9 C9 C9 C9 C9 A2 A2 C9
        STATION_FRAME_INNER_HEADER 0Bh                         ;#757C: EB
        VRAM_TILES "C8C8C9AAC9AAC999C9C9"                      ;#757D: C8 C8 C9 AA C9 AA C9 99 C9 C9
        STATION_FRAME_INNER_HEADER 0Bh                         ;#7587: EB
        VRAM_TILES "C8C8C9ABC9ABC999C9C9"                      ;#7588: C8 C8 C9 AB C9 AB C9 99 C9 C9
        STATION_FRAME_INNER_HEADER 0Bh                         ;#7592: EB
        VRAM_TILES "C8C8C9C9C9C9C9AEC9C9"                      ;#7593: C8 C8 C9 C9 C9 C9 C9 AE C9 C9
        STATION_FRAME_INNER_HEADER 0Bh                         ;#759D: EB
        VRAM_TILES "A3A3ACA0A0ACAC9AA0AC"                      ;#759E: A3 A3 AC A0 A0 AC AC 9A A0 AC
        db      00h                                            ;#75A8: 00

CHECK_SPECIAL_ITEM_COLLISION:
        ; Detects collision with type-7 small-hole occupants (fish / seal)
        ld      hl,FISH_POS_STATE                              ;#75A9: 21 83 E1
        ld      a,(hl)                                         ;#75AC: 7E
        and     0E3h                                           ;#75AD: E6 E3
        ret     nz                                             ;#75AF: C0
        ld      de,ITEM_TABLE_TYPE_BASE                        ;#75B0: 11 13 E1
        ld      b,3                                            ;#75B3: 06 03
CHECK_SPECIAL_ITEM_COLLISION_LOOP:
        ; Loop for checking item collisions
        ld      a,(de)                                         ;#75B5: 1A
        cp      3                                              ;#75B6: FE 03
        jr      nc,SKIP_ITEM_CHECK                             ;#75B8: 30 07
        dec     de                                             ;#75BA: 1B
        ld      a,(de)                                         ;#75BB: 1A
        cp      7                                              ;#75BC: FE 07
        jr      z,ITEM_FOUND_COLLISION                         ;#75BE: 28 09
        inc     de                                             ;#75C0: 13
SKIP_ITEM_CHECK:
        ; Skip current item check
        ld      a,6                                            ;#75C1: 3E 06
        call    ADD_DE_A                                       ;#75C3: CD D8 48
        djnz    CHECK_SPECIAL_ITEM_COLLISION_LOOP              ;#75C6: 10 ED
        ret                                                    ;#75C8: C9

ITEM_FOUND_COLLISION:
        ; Item found, handle collision logic
        ld      (ITEM_COLLISION_PTR),de                        ;#75C9: ED 53 81 E1
        inc     de                                             ;#75CD: 13
        ld      a,(SEQUENCE_THRESHOLD)                         ;#75CE: 3A 8A E1
        ld      c,a                                            ;#75D1: 4F
        ld      a,(FRAME_COUNTER)                              ;#75D2: 3A 03 E0
        cp      c                                              ;#75D5: B9
        jr      nc,NO_COLLISION_RESET                          ;#75D6: 30 39
        ld      a,(CUR_INPUT_KEYS)                             ;#75D8: 3A 09 E0
        and     0Ch                                            ;#75DB: E6 0C
        jr      z,HANDLE_IDLE_ITEM_ANIM                        ;#75DD: 28 04
        bit     2,a                                            ;#75DF: CB 57
        jr      SET_FISH_POS_FRAME                             ;#75E1: 18 09

HANDLE_IDLE_ITEM_ANIM:
        ; Handle idle animation for item
        ld      a,(ITEM_IDLE_ANIM_COUNTER)                     ;#75E3: 3A 85 E1
        inc     a                                              ;#75E6: 3C
        ld      (ITEM_IDLE_ANIM_COUNTER),a                     ;#75E7: 32 85 E1
        bit     0,a                                            ;#75EA: CB 47
SET_FISH_POS_FRAME:
        ; Set fish position frame
        ld      a,90h                                          ;#75EC: 3E 90
        set     0,(hl)                                         ;#75EE: CB C6
        jr      z,UPDATE_ITEM_SPRITE_ATTRS                     ;#75F0: 28 04
        ld      a,80h                                          ;#75F2: 3E 80
        rlc     (hl)                                           ;#75F4: CB 06
UPDATE_ITEM_SPRITE_ATTRS:
        ; Update item sprite attributes
        ld      c,a                                            ;#75F6: 4F
        ld      hl,SAT_MIRROR + SPRITE_ITEM + ATTR_Y           ;#75F7: 21 8C E0
        ld      a,(de)                                         ;#75FA: 1A
        ld      d,c                                            ;#75FB: 51
        cp      1                                              ;#75FC: FE 01
        ld      bc,7A66h                                       ;#75FE: 01 66 7A
        jr      c,SET_SPRITE_Y_OFFSETS                         ;#7601: 38 04
        jr      z,SET_SPRITE_Y_ALT                             ;#7603: 28 04
        ld      b,92h                                          ;#7605: 06 92
SET_SPRITE_Y_OFFSETS:
        ; Set sprite Y offsets
        jr      STORE_SPRITE_ATTRS                             ;#7607: 18 02

SET_SPRITE_Y_ALT:
        ; Set alternate sprite Y offset
        ld      b,64h                                          ;#7609: 06 64
STORE_SPRITE_ATTRS:
        ; Store sprite attributes to buffer
        ld      (hl),c                                         ;#760B: 71
        inc     hl                                             ;#760C: 23
        ld      (hl),b                                         ;#760D: 70
        inc     hl                                             ;#760E: 23
        ld      (hl),d                                         ;#760F: 72
        ret                                                    ;#7610: C9

NO_COLLISION_RESET:
        ; Reset collision state if no item found
        xor     a                                              ;#7611: AF
        ld      (FISH_POS_VRAM_SELECT),a                       ;#7612: 32 92 E1
        ld      a,(de)                                         ;#7615: 1A
        cp      1                                              ;#7616: FE 01
        jr      c,MARK_COLLISION_TYPE_1                        ;#7618: 38 05
        jr      z,MARK_COLLISION_TYPE_2                        ;#761A: 28 06
        set     5,(hl)                                         ;#761C: CB EE
        ret                                                    ;#761E: C9

MARK_COLLISION_TYPE_1:
        ; Mark collision flag (type 1)
        set     6,(hl)                                         ;#761F: CB F6
        ret                                                    ;#7621: C9

MARK_COLLISION_TYPE_2:
        ; Mark collision flag (type 2)
        set     7,(hl)                                         ;#7622: CB FE
        ret                                                    ;#7624: C9

SYNC_SPRITE_ATTRIBUTES_PARTIAL:
        ; Upload sprite attribute subset to VRAM
        ld      a,(FRAME_COUNTER)                              ;#7625: 3A 03 E0
        rra                                                    ;#7628: 1F
        ret     c                                              ;#7629: D8
SYNC_SPRITE_LOOP:
        ; Loop entry for iterating through dynamic sprite attributes
        ld      hl,(SAT_MIRROR + SPRITE_ITEM + ATTR_Y)         ;#762A: 2A 8C E0
        ld      (CURRENT_ENTITY_POINTER),hl                    ;#762D: 22 88 E1
        ld      hl,SAT_MIRROR + SPRITE_ITEM + ATTR_Y           ;#7630: 21 8C E0
        LOAD_SPRITE_ATTR de, 15, 0                             ;#7633: 11 3C 3B
        ld      bc,4                                           ;#7636: 01 04 00
        call    COPY_RAM_TO_VRAM                               ;#7639: CD C7 44
        ld      de,FISH_POS_STATE                              ;#763C: 11 83 E1
        ld      a,(de)                                         ;#763F: 1A
        and     3                                              ;#7640: E6 03
        ret     z                                              ;#7642: C8
        ld      hl,SAT_MIRROR + SPRITE_ITEM + ATTR_PATT        ;#7643: 21 8E E0
        call    SYNC_ANIMATION_TIMER                           ;#7646: CD 87 76
        ld      a,(de)                                         ;#7649: 1A
        dec     hl                                             ;#764A: 2B
        rra                                                    ;#764B: 1F
        jr      c,MAX_ANIMATION_COUNTER                        ;#764C: 38 04
        dec     (hl)                                           ;#764E: 35
        dec     (hl)                                           ;#764F: 35
        jr      SYNC_ANIMATION_COMMON_ENTRY                    ;#7650: 18 02

MAX_ANIMATION_COUNTER:
        ; Max out animation counter
        inc     (hl)                                           ;#7652: 34
        inc     (hl)                                           ;#7653: 34
SYNC_ANIMATION_COMMON_ENTRY:
        ; Common entry for animation sync
        push    hl                                             ;#7654: E5
        ld      hl,FISH_POS_COUNTER                            ;#7655: 21 84 E1
        inc     (hl)                                           ;#7658: 34
        ld      a,(hl)                                         ;#7659: 7E
        pop     hl                                             ;#765A: E1
        dec     hl                                             ;#765B: 2B
        cp      8                                              ;#765C: FE 08
        jr      c,DEC_ANIMATION_COUNTERS                       ;#765E: 38 15
        cp      10h                                            ;#7660: FE 10
        ret     c                                              ;#7662: D8
        jr      z,ADVANCE_ANIMATION_PHASE                      ;#7663: 28 13
        cp      22h                                            ;#7665: FE 22
        jr      nc,HIDE_DYNAMIC_SPRITE                         ;#7667: 30 16
        ld      c,5                                            ;#7669: 0E 05
        cp      1Ah                                            ;#766B: FE 1A
        jr      c,UPDATE_ANIM_FRAME_OFFSET                     ;#766D: 38 02
        inc     c                                              ;#766F: 0C
        inc     c                                              ;#7670: 0C
UPDATE_ANIM_FRAME_OFFSET:
        ; Add offset to animation frame
        ld      a,(hl)                                         ;#7671: 7E
        add     a,c                                            ;#7672: 81
        ld      (hl),a                                         ;#7673: 77
        ret                                                    ;#7674: C9

DEC_ANIMATION_COUNTERS:
        ; Decrement animation counters
        dec     (hl)                                           ;#7675: 35
        dec     (hl)                                           ;#7676: 35
        ret                                                    ;#7677: C9

ADVANCE_ANIMATION_PHASE:
        ; Advance to next animation phase
        inc     hl                                             ;#7678: 23
        inc     hl                                             ;#7679: 23
        ld      a,(hl)                                         ;#767A: 7E
        add     a,8                                            ;#767B: C6 08
        ld      (hl),a                                         ;#767D: 77
        ret                                                    ;#767E: C9

HIDE_DYNAMIC_SPRITE:
        ; Hide a dynamic sprite and clear its RAM entry
        ld      (hl),0E0h                                      ;#767F: 36 E0
        xor     a                                              ;#7681: AF
        ld      (de),a                                         ;#7682: 12
        inc     de                                             ;#7683: 13
        ld      (de),a                                         ;#7684: 12
        jr      SYNC_SPRITE_LOOP                               ;#7685: 18 A3

SYNC_ANIMATION_TIMER:
        ; Sync animation with global timer
        ld      a,(FRAME_COUNTER)                              ;#7687: 3A 03 E0
        and     0Fh                                            ;#768A: E6 0F
        ret     nz                                             ;#768C: C0
        ld      a,(hl)                                         ;#768D: 7E
        srl     a                                              ;#768E: CB 3F
        srl     a                                              ;#7690: CB 3F
        srl     a                                              ;#7692: CB 3F
        ccf                                                    ;#7694: 3F
        rla                                                    ;#7695: 17
        rla                                                    ;#7696: 17
        rla                                                    ;#7697: 17
        ld      (hl),a                                         ;#7698: 77
        ret                                                    ;#7699: C9

PROCESS_PENGUIN_INPUT_AND_MOVE:
        ; Handle keyboard/joystick and update penguin position
        call    HANDLE_SPEED_INPUT                             ;#769A: CD E5 76
        ld      a,(PENGUIN_SPEED)                              ;#769D: 3A 00 E1
        or      a                                              ;#76A0: B7
        rra                                                    ;#76A1: 1F
        ld      (DEMO_PLAY_MASK_RELOAD),a                      ;#76A2: 32 48 E1
        ld      a,(STAGE_DISTANCE_HIGH)                        ;#76A5: 3A E6 E0
        and     0Ch                                            ;#76A8: E6 0C
        ld      a,2Ch                                          ;#76AA: 3E 2C
        jr      nz,SPEED_FORCE_LOW_GEAR                        ;#76AC: 20 02
        add     a,4                                            ;#76AE: C6 04
SPEED_FORCE_LOW_GEAR:
        ; Branch for handling low distance speed override
        ld      c,a                                            ;#76B0: 4F
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#76B1: 3A E0 E0
        and     0F0h                                           ;#76B4: E6 F0
        jr      z,CALC_ITEM_TICK_PERIOD                        ;#76B6: 28 0C
        and     0E0h                                           ;#76B8: E6 E0
        jr      z,SPEED_DEC_VERY_FAST                          ;#76BA: 28 04
        ld      a,c                                            ;#76BC: 79
        sub     4                                              ;#76BD: D6 04
        ld      c,a                                            ;#76BF: 4F
SPEED_DEC_VERY_FAST:
        ; Reduce speed context A
        ld      a,c                                            ;#76C0: 79
        sub     4                                              ;#76C1: D6 04
        ld      c,a                                            ;#76C3: 4F
CALC_ITEM_TICK_PERIOD:
        ; Adjust item-tick period from PENGUIN_SPEED
        ld      a,(PENGUIN_SPEED)                              ;#76C4: 3A 00 E1
        cp      0Ch                                            ;#76C7: FE 0C
        jr      c,SPEED_DEC_FAST                               ;#76C9: 38 0D
        and     0Ch                                            ;#76CB: E6 0C
        jr      z,SPEED_DEC_SLOW                               ;#76CD: 28 11
        cp      0Ch                                            ;#76CF: FE 0C
        jr      z,SET_ITEM_TICK_PERIOD                         ;#76D1: 28 09
        ld      a,c                                            ;#76D3: 79
STORE_ITEM_TICK_PERIOD:
        ; Store final item-tick period to ITEM_TICK_PERIOD
        ld      (ITEM_TICK_PERIOD),a                           ;#76D4: 32 0E E1
        ret                                                    ;#76D7: C9

SPEED_DEC_FAST:
        ; Reduce speed context B
        ld      a,c                                            ;#76D8: 79
        sub     4                                              ;#76D9: D6 04
        ld      c,a                                            ;#76DB: 4F
SET_ITEM_TICK_PERIOD:
        ; Set calculated item-tick period (shared tail of CALC_ITEM_TICK_PERIOD)
        ld      a,c                                            ;#76DC: 79
        sub     4                                              ;#76DD: D6 04
        ld      c,a                                            ;#76DF: 4F
SPEED_DEC_SLOW:
        ; Reduce speed context C
        ld      a,c                                            ;#76E0: 79
        sub     4                                              ;#76E1: D6 04
        jr      STORE_ITEM_TICK_PERIOD                         ;#76E3: 18 EF

HANDLE_SPEED_INPUT:
        ; Process input keys and dispatch speed handler
        ld      a,(CUR_INPUT_KEYS)                             ;#76E5: 3A 09 E0
        and     3                                              ;#76E8: E6 03
        call    JUMP_TABLE_DISPATCHER                          ;#76EA: CD 9A 40
        ; Dispatch table for Up/Down input (Bit 0=Up, Bit 1=Down)
        ; 00: None (Coast)
        ; 01: Up (Accelerate)
        ; 02: Down (Brake)
        ; 03: Up+Down (Coast)
        dw      HANDLE_SPEED_COAST                             ;#76ED: 23 77
        dw      HANDLE_SPEED_UP                                ;#76EF: F5 76
        dw      HANDLE_SPEED_DOWN                              ;#76F1: 0D 77
        dw      HANDLE_SPEED_COAST                             ;#76F3: 23 77

HANDLE_SPEED_UP:
        ; Handle 'Up' input (Accelerate)
        ld      hl,SPEED_ACCEL_DELAY-1                         ;#76F5: 21 FD E0
        xor     a                                              ;#76F8: AF
        ld      (hl),a                                         ;#76F9: 77
        inc     hl                                             ;#76FA: 23
        inc     hl                                             ;#76FB: 23
        ld      (hl),a                                         ;#76FC: 77
        dec     hl                                             ;#76FD: 2B
        inc     (hl)                                           ;#76FE: 34
        ld      a,(hl)                                         ;#76FF: 7E
        sub     0Ch                                            ;#7700: D6 0C
        ret     nz                                             ;#7702: C0
        ld      (hl),a                                         ;#7703: 77
        ld      hl,PENGUIN_SPEED                               ;#7704: 21 00 E1
        ld      a,(hl)                                         ;#7707: 7E
        cp      9                                              ;#7708: FE 09
        ret     c                                              ;#770A: D8
        dec     (hl)                                           ;#770B: 35
        ret                                                    ;#770C: C9

HANDLE_SPEED_DOWN:
        ; Handle 'Down' input (Brake)
        ld      hl,SPEED_ACCEL_DELAY-1                         ;#770D: 21 FD E0
        xor     a                                              ;#7710: AF
        ld      (hl),a                                         ;#7711: 77
        inc     hl                                             ;#7712: 23
        ld      (hl),a                                         ;#7713: 77
        inc     hl                                             ;#7714: 23
        inc     (hl)                                           ;#7715: 34
        ld      a,(hl)                                         ;#7716: 7E
        sub     4                                              ;#7717: D6 04
        ret     nz                                             ;#7719: C0
        ld      (hl),a                                         ;#771A: 77
        ld      hl,PENGUIN_SPEED                               ;#771B: 21 00 E1
        ld      a,(hl)                                         ;#771E: 7E
        cp      13h                                            ;#771F: FE 13
        ret     nc                                             ;#7721: D0
        inc     (hl)                                           ;#7722: 34
HANDLE_SPEED_COAST:
        ; Handle no Up/Down input
        ret                                                    ;#7723: C9

CALC_HUD_SPEED_BAR:
        ; Build HUD speed-bar tile run from PENGUIN_SPEED into HUD_SPEED_BAR_TILES
        ld      a,(PENGUIN_FALL_TIMER)                         ;#7724: 3A 40 E1
        ld      hl,PENGUIN_STUN_TIMER                          ;#7727: 21 42 E1
        add     a,(hl)                                         ;#772A: 86
        ld      hl,HUD_SPEED_BAR_TILES                         ;#772B: 21 71 E1
        jr      nz,CALC_HUD_SPEED_BAR_PAD                      ;#772E: 20 1F
        ld      a,(PENGUIN_SPEED)                              ;#7730: 3A 00 E1
        ld      b,a                                            ;#7733: 47
        and     1                                              ;#7734: E6 01
        add     a,42h                                          ;#7736: C6 42
        ld      c,a                                            ;#7738: 4F
        ld      a,b                                            ;#7739: 78
        rra                                                    ;#773A: 1F
        cpl                                                    ;#773B: 2F
        and     0Fh                                            ;#773C: E6 0F
        sub     6                                              ;#773E: D6 06
        jr      z,CALC_HUD_SPEED_BAR_STORE                     ;#7740: 28 06
        ld      b,a                                            ;#7742: 47
CALC_HUD_SPEED_BAR_LOOP:
        ; Inner loop writing 42h tiles for the speed-bar fill
        ld      (hl),42h                                       ;#7743: 36 42
        inc     hl                                             ;#7745: 23
        djnz    CALC_HUD_SPEED_BAR_LOOP                        ;#7746: 10 FB
CALC_HUD_SPEED_BAR_STORE:
        ; Write the trailing animated tile (42h or 43h, alternating with speed)
        ld      (hl),c                                         ;#7748: 71
        inc     hl                                             ;#7749: 23
        ld      a,l                                            ;#774A: 7D
        cp      78h                                            ;#774B: FE 78
        jr      z,SYNC_HUD_SPEED_BAR                           ;#774D: 28 04
CALC_HUD_SPEED_BAR_PAD:
        ; Pad remaining slots with 0 until end of buffer
        ld      c,0                                            ;#774F: 0E 00
        jr      CALC_HUD_SPEED_BAR_STORE                       ;#7751: 18 F5

SYNC_HUD_SPEED_BAR:
        ; Copy HUD_SPEED_BAR_TILES to name table row 1, col 25
        ld      hl,HUD_SPEED_BAR_TILES                         ;#7753: 21 71 E1
        LOAD_NAME_TABLE de, 1, 25                              ;#7756: 11 39 38
        ld      bc,6                                           ;#7759: 01 06 00
        jp      COPY_RAM_TO_VRAM                               ;#775C: C3 C7 44

HANDLE_DEMO_PLAY_MASKING:
        ; Places 4 invisible sprites to mask other sprites (5th sprite limit)
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#775F: 3A 02 E0
        bit     6,a                                            ;#7762: CB 77
        ret     z                                              ;#7764: C8
        ld      b,4                                            ;#7765: 06 04
        ld      de,SAT_MIRROR + SPRITE_CLOUD + ATTR_Y          ;#7767: 11 B8 E0
        ld      hl,DEMO_PLAY_MASK_FLAGS                        ;#776A: 21 4A E1
DEMO_PLAY_MASK_LOOP:
        ; Loop for demo play masking
        ld      a,(hl)                                         ;#776D: 7E
        or      a                                              ;#776E: B7
        ld      a,4                                            ;#776F: 3E 04
        jr      nz,DEMO_PLAY_MASK_NEXT                         ;#7771: 20 1B
        push    hl                                             ;#7773: E5
        inc     (hl)                                           ;#7774: 34
        ld      hl,DEMO_PLAY_MASK_COORDS_DATA-2                ;#7775: 21 F2 77
        ld      a,b                                            ;#7778: 78
        add     a,a                                            ;#7779: 87
        call    ADD_HL_A                                       ;#777A: CD D3 48
        ld      a,(hl)                                         ;#777D: 7E
        ld      (de),a                                         ;#777E: 12
        inc     hl                                             ;#777F: 23
        inc     de                                             ;#7780: 13
        ld      a,(hl)                                         ;#7781: 7E
        ld      (de),a                                         ;#7782: 12
        inc     de                                             ;#7783: 13
        ld      a,0E0h                                         ;#7784: 3E E0
        ld      (de),a                                         ;#7786: 12
        inc     de                                             ;#7787: 13
        ld      a,0Fh                                          ;#7788: 3E 0F
        ld      (de),a                                         ;#778A: 12
        ld      a,1                                            ;#778B: 3E 01
        pop     hl                                             ;#778D: E1
DEMO_PLAY_MASK_NEXT:
        ; Next demo play mask entry
        call    ADD_DE_A                                       ;#778E: CD D8 48
        inc     hl                                             ;#7791: 23
        djnz    DEMO_PLAY_MASK_LOOP                            ;#7792: 10 D9
        ld      hl,DEMO_PLAY_MASK_TIMER                        ;#7794: 21 49 E1
        dec     (hl)                                           ;#7797: 35
        ret     nz                                             ;#7798: C0
        ld      a,(DEMO_PLAY_MASK_RELOAD)                      ;#7799: 3A 48 E1
        ld      (hl),a                                         ;#779C: 77
        ld      b,0                                            ;#779D: 06 00
        ld      hl,DEMO_PLAY_MASK_FLAGS                        ;#779F: 21 4A E1
        ld      de,SAT_MIRROR + SPRITE_CLOUD + ATTR_Y          ;#77A2: 11 B8 E0
PROCESS_NEXT_CLOUD_SPRITE:
        ; Loop entry for processing the 4 cloud sprites
        ld      a,(hl)                                         ;#77A5: 7E
        or      a                                              ;#77A6: B7
        jr      z,ADVANCE_CLOUD_SPRITE_PTRS                    ;#77A7: 28 2F
        ld      a,(de)                                         ;#77A9: 1A
        cp      8                                              ;#77AA: FE 08
        jr      nz,ANIMATE_CLOUD_SPRITES                       ;#77AC: 20 07
        ld      a,0D1h                                         ;#77AE: 3E D1
        ld      (de),a                                         ;#77B0: 12
        ld      (hl),0                                         ;#77B1: 36 00
        jr      ADVANCE_CLOUD_SPRITE_PTRS                      ;#77B3: 18 23

ANIMATE_CLOUD_SPRITES:
        ; Handles bobbing animation for Cloud sprites
        push    de                                             ;#77B5: D5
        inc     (hl)                                           ;#77B6: 34
        ex      de,hl                                          ;#77B7: EB
        dec     (hl)                                           ;#77B8: 35
        push    de                                             ;#77B9: D5
        ld      de,CLOUD_ANIMATION_OFFSETS                     ;#77BA: 11 F0 77
        ld      a,b                                            ;#77BD: 78
        call    ADD_DE_A                                       ;#77BE: CD D8 48
        ld      a,(de)                                         ;#77C1: 1A
        inc     hl                                             ;#77C2: 23
        add     a,(hl)                                         ;#77C3: 86
        ld      (hl),a                                         ;#77C4: 77
        ex      de,hl                                          ;#77C5: EB
        pop     hl                                             ;#77C6: E1
        ld      a,(hl)                                         ;#77C7: 7E
        cp      0Ch                                            ;#77C8: FE 0C
        ld      a,0DCh                                         ;#77CA: 3E DC
        jr      z,UPDATE_CLOUD_SPRITE_ATTR                     ;#77CC: 28 07
        ld      a,(hl)                                         ;#77CE: 7E
        cp      18h                                            ;#77CF: FE 18
        ld      a,0D8h                                         ;#77D1: 3E D8
        jr      nz,CLOUD_SPRITE_RESTORE_PTR                    ;#77D3: 20 02
UPDATE_CLOUD_SPRITE_ATTR:
        ; Updates a specific attribute at offset 1 during specific animation frames
        inc     de                                             ;#77D5: 13
        ld      (de),a                                         ;#77D6: 12
CLOUD_SPRITE_RESTORE_PTR:
        ; Restores the sprite pointer (DE) from the stack after potential updates
        pop     de                                             ;#77D7: D1
ADVANCE_CLOUD_SPRITE_PTRS:
        ; Advances the pointers to the next sprite in the batch of 4
        ld      a,4                                            ;#77D8: 3E 04
        call    ADD_DE_A                                       ;#77DA: CD D8 48
        inc     hl                                             ;#77DD: 23
        ld      a,4                                            ;#77DE: 3E 04
        inc     b                                              ;#77E0: 04
        cp      b                                              ;#77E1: B8
        jr      nz,PROCESS_NEXT_CLOUD_SPRITE                   ;#77E2: 20 C1
        ld      hl,SAT_MIRROR + SPRITE_CLOUD + ATTR_Y          ;#77E4: 21 B8 E0
        LOAD_SPRITE_ATTR de, 26, 0                             ;#77E7: 11 68 3B
        ld      bc,10h                                         ;#77EA: 01 10 00
        jp      COPY_RAM_TO_VRAM                               ;#77ED: C3 C7 44

CLOUD_ANIMATION_OFFSETS:
        ; Per-frame Y deltas for cloud sprite bobbing (4 signed bytes)
        ; Format: FORMAT_CLOUD_OFFSETS
        CLOUD_OFFSET -1                                        ;#77F0: FF
        CLOUD_OFFSET 1                                         ;#77F1: 01
        CLOUD_OFFSET -2                                        ;#77F2: FE
        CLOUD_OFFSET 2                                         ;#77F3: 02

DEMO_PLAY_MASK_COORDS_DATA:
        ; Demo play-mask sprite (Y, X) pairs (4 sprites x 2 unsigned bytes)
        ; Format: FORMAT_SPRITE_YX_PAIRS
        SPRITE_YX 38h, 98h                                     ;#77F4: 38 98
        SPRITE_YX 37h, 58h                                     ;#77F6: 37 58
        SPRITE_YX 3Ch, 7Ch                                     ;#77F8: 3C 7C
        SPRITE_YX 3Ah, 74h                                     ;#77FA: 3A 74

HANDLE_SPECIAL_ITEM_EVENT:
        ; Processes effect of special item collision
        ld      a,(FISH_POS_STATE)                             ;#77FC: 3A 83 E1
        and     0E0h                                           ;#77FF: E6 E0
        ret     z                                              ;#7801: C8
        ld      hl,(ITEM_COLLISION_PTR)                        ;#7802: 2A 81 E1
        ld      a,(hl)                                         ;#7805: 7E
        ld      hl,FISH_POS_STATE                              ;#7806: 21 83 E1
        sub     0Fh                                            ;#7809: D6 0F
        jr      nz,LOAD_ITEM_ANIM_PTR                          ;#780B: 20 08
        ld      (hl),a                                         ;#780D: 77
        ld      hl,ITEM_POS_OFFSCREEN                          ;#780E: 21 77 79
        ld      b,4                                            ;#7811: 06 04
        jr      INIT_ANIM_BUFFER_PTRS                          ;#7813: 18 3C

LOAD_ITEM_ANIM_PTR:
        ; Load pointer to animation data
        ld      hl,ITEM_ANIM_SEAL_TABLE                        ;#7815: 21 7B 78
        add     a,8                                            ;#7818: C6 08
        ld      b,a                                            ;#781A: 47
        add     a,a                                            ;#781B: 87
        call    ADD_HL_A                                       ;#781C: CD D3 48
        ld      e,(hl)                                         ;#781F: 5E
        inc     hl                                             ;#7820: 23
        ld      d,(hl)                                         ;#7821: 56
        ld      a,b                                            ;#7822: 78
        ld      b,4                                            ;#7823: 06 04
        cp      6                                              ;#7825: FE 06
        jr      c,CHECK_ANIM_FRAME_INDEX                       ;#7827: 38 0C
        ld      hl,FISH_POS_GUARD_FLAG                         ;#7829: 21 37 E1
        bit     0,(hl)                                         ;#782C: CB 46
        jr      nz,CHECK_ANIM_FRAME_INDEX                      ;#782E: 20 05
        ld      hl,FISH_POS_VRAM_SELECT                        ;#7830: 21 92 E1
        ld      (hl),1                                         ;#7833: 36 01
CHECK_ANIM_FRAME_INDEX:
        ; Check animation frame index validity
        cp      3                                              ;#7835: FE 03
        ex      de,hl                                          ;#7837: EB
        ld      d,0Ch                                          ;#7838: 16 0C
        jr      nc,CALC_ANIM_SOURCE_ADDR                       ;#783A: 30 04
        ld      d,6                                            ;#783C: 16 06
        ld      b,2                                            ;#783E: 06 02
CALC_ANIM_SOURCE_ADDR:
        ; Calculate source address for animation data
        ld      a,(FISH_POS_STATE)                             ;#7840: 3A 83 E1
        cp      40h                                            ;#7843: FE 40
        jr      z,INIT_ANIM_BUFFER_PTRS                        ;#7845: 28 0A
        jr      c,CALC_ANIM_SOURCE_NEXT                        ;#7847: 38 04
        ld      a,d                                            ;#7849: 7A
        call    ADD_HL_A                                       ;#784A: CD D3 48
CALC_ANIM_SOURCE_NEXT:
        ; Next animation source calculation step
        ld      a,d                                            ;#784D: 7A
        call    ADD_HL_A                                       ;#784E: CD D3 48
INIT_ANIM_BUFFER_PTRS:
        ; Initialize pointers for animation buffer copy
        ld      de,SAT_MIRROR + SPRITE_OBSTACLE + ATTR_Y       ;#7851: 11 90 E0
        push    de                                             ;#7854: D5
ANIM_FRAME_COPY_LOOP:
        ; Outer loop for copying animation frame data
        ld      c,3                                            ;#7855: 0E 03
ANIM_BYTE_COPY_LOOP:
        ; Inner loop for copying attribute bytes
        ld      a,(hl)                                         ;#7857: 7E
        ld      (de),a                                         ;#7858: 12
        inc     hl                                             ;#7859: 23
        inc     de                                             ;#785A: 13
        dec     c                                              ;#785B: 0D
        jr      nz,ANIM_BYTE_COPY_LOOP                         ;#785C: 20 F9
        inc     de                                             ;#785E: 13
        djnz    ANIM_FRAME_COPY_LOOP                           ;#785F: 10 F4
        pop     hl                                             ;#7861: E1
        ld      c,10h                                          ;#7862: 0E 10
        ld      a,(FISH_POS_VRAM_SELECT)                       ;#7864: 3A 92 E1
        rra                                                    ;#7867: 1F
        ld      de,VRAM_SAT_BASE                               ;#7868: 11 00 3B
        jr      nc,UPLOAD_ANIM_TO_VRAM_HIGH                    ;#786B: 30 06
        call    COPY_RAM_TO_VRAM                               ;#786D: CD C7 44
        ld      hl,SAT_MIRROR                                  ;#7870: 21 50 E0
UPLOAD_ANIM_TO_VRAM_HIGH:
        ; Upload animation data to high VRAM address
        LOAD_SPRITE_ATTR de, 16, 0                             ;#7873: 11 40 3B
        ld      c,10h                                          ;#7876: 0E 10
        jp      COPY_RAM_TO_VRAM                               ;#7878: C3 C7 44

ITEM_ANIM_SEAL_TABLE:
        ; Pointer table for seal-approach animation frames (9 entries)
        dw      ITEM_ANIM_SEAL_0                               ;#787B: 8D 78
        dw      ITEM_ANIM_SEAL_1                               ;#787D: 9F 78
        dw      ITEM_ANIM_SEAL_2                               ;#787F: B1 78
        dw      ITEM_ANIM_SEAL_3                               ;#7881: C3 78
        dw      ITEM_ANIM_SEAL_4                               ;#7883: E7 78
        dw      ITEM_ANIM_SEAL_5                               ;#7885: 0B 79
        dw      ITEM_ANIM_SEAL_6                               ;#7887: 2F 79
        dw      ITEM_ANIM_SEAL_7                               ;#7889: 53 79
        dw      ITEM_POS_OFFSCREEN                             ;#788B: 77 79

ITEM_ANIM_SEAL_0:
        ; Seal approach frame 0 (farthest; 3 positions x 2 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 67h, 78h, 7Ch                        ;#788D: 67 78 7C
        SPRITE_ANIM_FRAME 67h, 78h, 0E8h                       ;#7890: 67 78 E8
        SPRITE_ANIM_FRAME 67h, 90h, 7Ch                        ;#7893: 67 90 7C
        SPRITE_ANIM_FRAME 67h, 90h, 0E8h                       ;#7896: 67 90 E8
        SPRITE_ANIM_FRAME 67h, 60h, 7Ch                        ;#7899: 67 60 7C
        SPRITE_ANIM_FRAME 67h, 60h, 0E8h                       ;#789C: 67 60 E8

ITEM_ANIM_SEAL_1:
        ; Seal approach frame 1 (3 positions x 2 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 6Ch, 78h, 0B8h                       ;#789F: 6C 78 B8
        SPRITE_ANIM_FRAME 6Ch, 78h, 0BCh                       ;#78A2: 6C 78 BC
        SPRITE_ANIM_FRAME 6Ch, 94h, 0B8h                       ;#78A5: 6C 94 B8
        SPRITE_ANIM_FRAME 6Ch, 94h, 0BCh                       ;#78A8: 6C 94 BC
        SPRITE_ANIM_FRAME 6Ch, 5Bh, 0B8h                       ;#78AB: 6C 5B B8
        SPRITE_ANIM_FRAME 6Ch, 5Bh, 0BCh                       ;#78AE: 6C 5B BC

ITEM_ANIM_SEAL_2:
        ; Seal approach frame 2 (3 positions x 2 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 78h, 78h, 0B8h                       ;#78B1: 78 78 B8
        SPRITE_ANIM_FRAME 78h, 78h, 0BCh                       ;#78B4: 78 78 BC
        SPRITE_ANIM_FRAME 78h, 9Dh, 0B8h                       ;#78B7: 78 9D B8
        SPRITE_ANIM_FRAME 78h, 9Dh, 0BCh                       ;#78BA: 78 9D BC
        SPRITE_ANIM_FRAME 78h, 53h, 0B8h                       ;#78BD: 78 53 B8
        SPRITE_ANIM_FRAME 78h, 53h, 0BCh                       ;#78C0: 78 53 BC

ITEM_ANIM_SEAL_3:
        ; Seal approach frame 3 (3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 7Bh, 78h, 0C0h                       ;#78C3: 7B 78 C0
        SPRITE_ANIM_FRAME 8Bh, 70h, 0C4h                       ;#78C6: 8B 70 C4
        SPRITE_ANIM_FRAME 7Bh, 78h, 0C8h                       ;#78C9: 7B 78 C8
        SPRITE_ANIM_FRAME 8Bh, 80h, 0CCh                       ;#78CC: 8B 80 CC
        SPRITE_ANIM_FRAME 7Bh, 0A4h, 0C0h                      ;#78CF: 7B A4 C0
        SPRITE_ANIM_FRAME 8Bh, 9Ch, 0C4h                       ;#78D2: 8B 9C C4
        SPRITE_ANIM_FRAME 7Bh, 0A4h, 0C8h                      ;#78D5: 7B A4 C8
        SPRITE_ANIM_FRAME 8Bh, 0ACh, 0CCh                      ;#78D8: 8B AC CC
        SPRITE_ANIM_FRAME 7Bh, 4Ch, 0C0h                       ;#78DB: 7B 4C C0
        SPRITE_ANIM_FRAME 8Bh, 44h, 0C4h                       ;#78DE: 8B 44 C4
        SPRITE_ANIM_FRAME 7Bh, 4Ch, 0C8h                       ;#78E1: 7B 4C C8
        SPRITE_ANIM_FRAME 8Bh, 54h, 0CCh                       ;#78E4: 8B 54 CC

ITEM_ANIM_SEAL_4:
        ; Seal approach frame 4 (3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 86h, 78h, 0C0h                       ;#78E7: 86 78 C0
        SPRITE_ANIM_FRAME 96h, 70h, 0C4h                       ;#78EA: 96 70 C4
        SPRITE_ANIM_FRAME 86h, 78h, 0C8h                       ;#78ED: 86 78 C8
        SPRITE_ANIM_FRAME 96h, 80h, 0CCh                       ;#78F0: 96 80 CC
        SPRITE_ANIM_FRAME 86h, 0ACh, 0C0h                      ;#78F3: 86 AC C0
        SPRITE_ANIM_FRAME 96h, 0A4h, 0C4h                      ;#78F6: 96 A4 C4
        SPRITE_ANIM_FRAME 86h, 0ACh, 0C8h                      ;#78F9: 86 AC C8
        SPRITE_ANIM_FRAME 96h, 0B4h, 0CCh                      ;#78FC: 96 B4 CC
        SPRITE_ANIM_FRAME 86h, 44h, 0C0h                       ;#78FF: 86 44 C0
        SPRITE_ANIM_FRAME 96h, 3Ch, 0C4h                       ;#7902: 96 3C C4
        SPRITE_ANIM_FRAME 86h, 44h, 0C8h                       ;#7905: 86 44 C8
        SPRITE_ANIM_FRAME 96h, 4Ch, 0CCh                       ;#7908: 96 4C CC

ITEM_ANIM_SEAL_5:
        ; Seal approach frame 5 (3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 8Fh, 78h, 0C0h                       ;#790B: 8F 78 C0
        SPRITE_ANIM_FRAME 9Fh, 70h, 0C4h                       ;#790E: 9F 70 C4
        SPRITE_ANIM_FRAME 8Fh, 78h, 0C8h                       ;#7911: 8F 78 C8
        SPRITE_ANIM_FRAME 9Fh, 80h, 0CCh                       ;#7914: 9F 80 CC
        SPRITE_ANIM_FRAME 8Fh, 0B2h, 0C0h                      ;#7917: 8F B2 C0
        SPRITE_ANIM_FRAME 9Fh, 0AAh, 0C4h                      ;#791A: 9F AA C4
        SPRITE_ANIM_FRAME 8Fh, 0B2h, 0C8h                      ;#791D: 8F B2 C8
        SPRITE_ANIM_FRAME 9Fh, 0BAh, 0CCh                      ;#7920: 9F BA CC
        SPRITE_ANIM_FRAME 8Fh, 3Eh, 0C0h                       ;#7923: 8F 3E C0
        SPRITE_ANIM_FRAME 9Fh, 36h, 0C4h                       ;#7926: 9F 36 C4
        SPRITE_ANIM_FRAME 8Fh, 3Eh, 0C8h                       ;#7929: 8F 3E C8
        SPRITE_ANIM_FRAME 9Fh, 46h, 0CCh                       ;#792C: 9F 46 CC

ITEM_ANIM_SEAL_6:
        ; Seal approach frame 6 (3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 98h, 78h, 0C0h                       ;#792F: 98 78 C0
        SPRITE_ANIM_FRAME 0A8h, 70h, 0C4h                      ;#7932: A8 70 C4
        SPRITE_ANIM_FRAME 98h, 78h, 0C8h                       ;#7935: 98 78 C8
        SPRITE_ANIM_FRAME 0A8h, 80h, 0CCh                      ;#7938: A8 80 CC
        SPRITE_ANIM_FRAME 98h, 0B8h, 0C0h                      ;#793B: 98 B8 C0
        SPRITE_ANIM_FRAME 0A8h, 0B0h, 0C4h                     ;#793E: A8 B0 C4
        SPRITE_ANIM_FRAME 98h, 0B8h, 0C8h                      ;#7941: 98 B8 C8
        SPRITE_ANIM_FRAME 0A8h, 0C0h, 0CCh                     ;#7944: A8 C0 CC
        SPRITE_ANIM_FRAME 98h, 38h, 0C0h                       ;#7947: 98 38 C0
        SPRITE_ANIM_FRAME 0A8h, 30h, 0C4h                      ;#794A: A8 30 C4
        SPRITE_ANIM_FRAME 98h, 38h, 0C8h                       ;#794D: 98 38 C8
        SPRITE_ANIM_FRAME 0A8h, 40h, 0CCh                      ;#7950: A8 40 CC

ITEM_ANIM_SEAL_7:
        ; Seal approach frame 7 (closest; 3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 0A1h, 78h, 0C0h                      ;#7953: A1 78 C0
        SPRITE_ANIM_FRAME 0B1h, 70h, 0C4h                      ;#7956: B1 70 C4
        SPRITE_ANIM_FRAME 0A1h, 78h, 0C8h                      ;#7959: A1 78 C8
        SPRITE_ANIM_FRAME 0B1h, 80h, 0CCh                      ;#795C: B1 80 CC
        SPRITE_ANIM_FRAME 0A1h, 0BEh, 0C0h                     ;#795F: A1 BE C0
        SPRITE_ANIM_FRAME 0B1h, 0B6h, 0C4h                     ;#7962: B1 B6 C4
        SPRITE_ANIM_FRAME 0A1h, 0BEh, 0C8h                     ;#7965: A1 BE C8
        SPRITE_ANIM_FRAME 0B1h, 0C6h, 0CCh                     ;#7968: B1 C6 CC
        SPRITE_ANIM_FRAME 0A1h, 32h, 0C0h                      ;#796B: A1 32 C0
        SPRITE_ANIM_FRAME 0B1h, 2Ah, 0C4h                      ;#796E: B1 2A C4
        SPRITE_ANIM_FRAME 0A1h, 32h, 0C8h                      ;#7971: A1 32 C8
        SPRITE_ANIM_FRAME 0B1h, 3Ah, 0CCh                      ;#7974: B1 3A CC

ITEM_POS_OFFSCREEN:
        ; Off-screen/reset position
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 0E0h, 0, 0                           ;#7977: E0 00 00
        SPRITE_ANIM_FRAME 0E0h, 0, 0                           ;#797A: E0 00 00
        SPRITE_ANIM_FRAME 0E0h, 0, 0                           ;#797D: E0 00 00
        SPRITE_ANIM_FRAME 0E0h, 0, 0                           ;#7980: E0 00 00

PLAY_SOUND_SAFE:
        ; Start sound track (Saves registers, disables INT)
        di                                                     ;#7983: F3
        push    hl                                             ;#7984: E5
        push    de                                             ;#7985: D5
        push    bc                                             ;#7986: C5
        push    af                                             ;#7987: F5
        call    PLAY_SOUND                                     ;#7988: CD 91 79
        pop     af                                             ;#798B: F1
        pop     bc                                             ;#798C: C1
        pop     de                                             ;#798D: D1
        pop     hl                                             ;#798E: E1
        ei                                                     ;#798F: FB
        ret                                                    ;#7990: C9

PLAY_SOUND:
        ; Start sound track
        ld      b,2                                            ;#7991: 06 02
        ld      hl,MUSIC_VARS_CH0+MUSIC_DRIVER_CONTROL         ;#7993: 21 12 E0
        cp      8Ah                                            ;#7996: FE 8A
        jr      c,PLAY_SOUND_SELECT_CH2                        ;#7998: 38 07
        cp      8Ch                                            ;#799A: FE 8C
        jr      c,PLAY_SOUND_CHECK_PRIORITY                    ;#799C: 38 07
        inc     b                                              ;#799E: 04
        jr      PLAY_SOUND_CHECK_PRIORITY                      ;#799F: 18 04

PLAY_SOUND_SELECT_CH2:
        ; Sets the target channel to Channel 2 for high-priority sounds
        dec     b                                              ;#79A1: 05
        ld      hl,MUSIC_VARS_CH2+MUSIC_DRIVER_CONTROL         ;#79A2: 21 26 E0
PLAY_SOUND_CHECK_PRIORITY:
        ; Checks if the requested sound has higher priority than the currently playing one
        cp      (hl)                                           ;#79A5: BE
        jr      c,PLAY_SOUND_DONE                              ;#79A6: 38 23
        ld      c,a                                            ;#79A8: 4F
        and     3Fh                                            ;#79A9: E6 3F
        add     a,a                                            ;#79AB: 87
        ld      de,SOUND_TABLE-2                               ;#79AC: 11 0C 7B
        call    ADD_DE_A                                       ;#79AF: CD D8 48
PLAY_SOUND_INIT_CHANNEL_DATA:
        ; Initialize channel data pointers from sound table
        dec     hl                                             ;#79B2: 2B
        dec     hl                                             ;#79B3: 2B
        ld      (hl),1                                         ;#79B4: 36 01
        inc     hl                                             ;#79B6: 23
        ld      (hl),1                                         ;#79B7: 36 01
        inc     hl                                             ;#79B9: 23
        ld      a,c                                            ;#79BA: 79
        ld      (hl),a                                         ;#79BB: 77
        inc     hl                                             ;#79BC: 23
        ld      a,(de)                                         ;#79BD: 1A
        ld      (hl),a                                         ;#79BE: 77
        inc     hl                                             ;#79BF: 23
        inc     de                                             ;#79C0: 13
        ld      a,(de)                                         ;#79C1: 1A
        ld      (hl),a                                         ;#79C2: 77
        ld      a,8                                            ;#79C3: 3E 08
        call    ADD_HL_A                                       ;#79C5: CD D3 48
        inc     de                                             ;#79C8: 13
        djnz    PLAY_SOUND_INIT_CHANNEL_DATA                   ;#79C9: 10 E7
PLAY_SOUND_DONE:
        ; Sound priority check finished
        ret                                                    ;#79CB: C9

PLAY_SOUND_HANDLE_REPEAT:
        ; Process the repeat/loop command in sound data
        inc     hl                                             ;#79CC: 23
        ld      a,(hl)                                         ;#79CD: 7E
        inc     a                                              ;#79CE: 3C
        jr      z,PLAY_SOUND_FETCH_STATUS                      ;#79CF: 28 10
        inc     (ix+MUSIC_DRIVER_REPEAT_COUNT)                 ;#79D1: DD 34 09
        dec     a                                              ;#79D4: 3D
        cp      (ix+MUSIC_DRIVER_REPEAT_COUNT)                 ;#79D5: DD BE 09
        jr      nz,PLAY_SOUND_FETCH_STATUS                     ;#79D8: 20 07
        xor     a                                              ;#79DA: AF
        ld      (ix+MUSIC_DRIVER_REPEAT_COUNT),a               ;#79DB: DD 77 09
        jp      PROCESS_SOUND_END_OF_SOUND                     ;#79DE: C3 64 7A

PLAY_SOUND_FETCH_STATUS:
        ; Resume processing by fetching current channel status
        ld      a,(ix+MUSIC_DRIVER_CONTROL)                    ;#79E1: DD 7E 02
        push    bc                                             ;#79E4: C5
        call    PLAY_SOUND                                     ;#79E5: CD 91 79
        pop     bc                                             ;#79E8: C1
        ret                                                    ;#79E9: C9

PROCESS_SOUND:
        ; Entry point for periodic sound engine update (interrupt driven)
        ld      a,7                                            ;#79EA: 3E 07
        call    BIOS_RDPSG                                     ;#79EC: CD 96 00
        and     0B8h                                           ;#79EF: E6 B8
        ld      e,a                                            ;#79F1: 5F
        ld      a,7                                            ;#79F2: 3E 07
        call    BIOS_WRTPSG                                    ;#79F4: CD 93 00
        ld      c,1                                            ;#79F7: 0E 01
        ld      ix,MUSIC_VARS_CH0                              ;#79F9: DD 21 10 E0
        exx                                                    ;#79FD: D9
        ld      b,3                                            ;#79FE: 06 03
        ld      de,0Ah                                         ;#7A00: 11 0A 00
PROCESS_SOUND_CHANNEL_LOOP:
        ; Loop entry for processing the three PSG sound channels
        exx                                                    ;#7A03: D9
        ld      a,(ix+MUSIC_DRIVER_CONTROL)                    ;#7A04: DD 7E 02
        or      a                                              ;#7A07: B7
        call    nz,PROCESS_SOUND_CHANNEL                       ;#7A08: C4 14 7A
        inc     c                                              ;#7A0B: 0C
        inc     c                                              ;#7A0C: 0C
        exx                                                    ;#7A0D: D9
        add     ix,de                                          ;#7A0E: DD 19
        djnz    PROCESS_SOUND_CHANNEL_LOOP                     ;#7A10: 10 F1
        exx                                                    ;#7A12: D9
        ret                                                    ;#7A13: C9

PROCESS_SOUND_CHANNEL:
        ; Process the current state of a single sound channel
        jp      m,PROCESS_SOUND_DECREMENT_TIMER                ;#7A14: FA 6B 7A
        dec     (ix)                                           ;#7A17: DD 35 00
        ret     nz                                             ;#7A1A: C0
PROCESS_SOUND_READ_NEXT_BYTE:
        ; Fetch and decode the next byte from the sound stream
        ld      l,(ix+MUSIC_DRIVER_STREAM_PTR_LO)              ;#7A1B: DD 6E 03
        ld      h,(ix+MUSIC_DRIVER_STREAM_PTR_HI)              ;#7A1E: DD 66 04
        ld      a,(hl)                                         ;#7A21: 7E
        cp      0FEh                                           ;#7A22: FE FE
        jr      z,PLAY_SOUND_HANDLE_REPEAT                     ;#7A24: 28 A6
        jr      nc,PROCESS_SOUND_END_OF_SOUND                  ;#7A26: 30 3C
        bit     7,(ix+MUSIC_DRIVER_CONTROL)                    ;#7A28: DD CB 02 7E
        jp      nz,PROCESS_SOUND_SPECIAL_MARKER                ;#7A2C: C2 94 7A
        and     0F0h                                           ;#7A2F: E6 F0
        cp      20h                                            ;#7A31: FE 20
        jr      nz,PROCESS_SOUND_SKIP_SET_VOL                  ;#7A33: 20 07
        ld      a,(hl)                                         ;#7A35: 7E
        and     0Fh                                            ;#7A36: E6 0F
        ld      (ix+MUSIC_DRIVER_DURATION_BASE),a              ;#7A38: DD 77 01
        inc     hl                                             ;#7A3B: 23
PROCESS_SOUND_SKIP_SET_VOL:
        ; Skip setting the volume if the command is not 0x20
        ld      a,(hl)                                         ;#7A3C: 7E
        and     0F0h                                           ;#7A3D: E6 F0
        ld      b,a                                            ;#7A3F: 47
        xor     (hl)                                           ;#7A40: AE
        ld      d,a                                            ;#7A41: 57
        inc     hl                                             ;#7A42: 23
        ld      e,(hl)                                         ;#7A43: 5E
        inc     hl                                             ;#7A44: 23
        ld      (ix+MUSIC_DRIVER_STREAM_PTR_LO),l              ;#7A45: DD 75 03
        ld      (ix+MUSIC_DRIVER_STREAM_PTR_HI),h              ;#7A48: DD 74 04
        ex      de,hl                                          ;#7A4B: EB
        call    PROCESS_SOUND_WRITE_PERIOD                     ;#7A4C: CD E6 7A
        ld      a,b                                            ;#7A4F: 78
        rrca                                                   ;#7A50: 0F
        rrca                                                   ;#7A51: 0F
        rrca                                                   ;#7A52: 0F
        rrca                                                   ;#7A53: 0F
        and     0Fh                                            ;#7A54: E6 0F
PROCESS_SOUND_UPDATE_CHANNEL_REGS:
        ; Updates channel state pointers and duration counters
        ld      h,a                                            ;#7A56: 67
        ld      a,(ix+MUSIC_DRIVER_DURATION_BASE)              ;#7A57: DD 7E 01
        ld      (ix),a                                         ;#7A5A: DD 77 00
        add     a,3                                            ;#7A5D: C6 03
        ld      (ix+MUSIC_DRIVER_SUSTAIN_TIMER),a              ;#7A5F: DD 77 08
        jr      PROCESS_SOUND_WRITE_VOLUME                     ;#7A62: 18 28

PROCESS_SOUND_END_OF_SOUND:
        ; Handle the end of a sound data stream
        xor     a                                              ;#7A64: AF
        ld      (ix+MUSIC_DRIVER_CONTROL),a                    ;#7A65: DD 77 02
        ld      h,a                                            ;#7A68: 67
        jr      PROCESS_SOUND_WRITE_VOLUME                     ;#7A69: 18 21

PROCESS_SOUND_DECREMENT_TIMER:
        ; Logic to decrement the main sound duration timer
        dec     (ix)                                           ;#7A6B: DD 35 00
        jr      z,PROCESS_SOUND_READ_NEXT_BYTE                 ;#7A6E: 28 AB
        dec     (ix+MUSIC_DRIVER_SUSTAIN_TIMER)                ;#7A70: DD 35 08
        ld      a,(ix+MUSIC_DRIVER_SUSTAIN_TIMER)              ;#7A73: DD 7E 08
        cp      (ix)                                           ;#7A76: DD BE 00
        jr      nz,PROCESS_SOUND_DECREMENT_TIMER2              ;#7A79: 20 05
        cp      1                                              ;#7A7B: FE 01
        jr      c,PROCESS_SOUND_RESET_TIMER2                   ;#7A7D: 38 04
        ret                                                    ;#7A7F: C9

PROCESS_SOUND_DECREMENT_TIMER2:
        ; Logic to decrement the secondary duration timer
        dec     (ix+MUSIC_DRIVER_SUSTAIN_TIMER)                ;#7A80: DD 35 08
PROCESS_SOUND_RESET_TIMER2:
        ; Reset the secondary timer from the initial value
        ld      a,(ix+MUSIC_DRIVER_SUSTAIN_COUNTER)            ;#7A83: DD 7E 07
        dec     a                                              ;#7A86: 3D
        ret     m                                              ;#7A87: F8
        ld      (ix+MUSIC_DRIVER_SUSTAIN_COUNTER),a            ;#7A88: DD 77 07
        ld      h,a                                            ;#7A8B: 67
PROCESS_SOUND_WRITE_VOLUME:
        ; Write volume to current PSG channel
        ld      a,c                                            ;#7A8C: 79
        rrca                                                   ;#7A8D: 0F
        add     a,88h                                          ;#7A8E: C6 88
        ld      e,h                                            ;#7A90: 5C
        jp      BIOS_WRTPSG                                    ;#7A91: C3 93 00

PROCESS_SOUND_SPECIAL_MARKER:
        ; Decode special markers (>= 0xFD) in the sound stream
        cp      0FDh                                           ;#7A94: FE FD
        jr      nz,PROCESS_SOUND_OTHER_MARKER                  ;#7A96: 20 10
        inc     hl                                             ;#7A98: 23
        ld      a,(hl)                                         ;#7A99: 7E
        and     7                                              ;#7A9A: E6 07
        ld      (ix+MUSIC_DRIVER_OCTAVE),a                     ;#7A9C: DD 77 05
        xor     (hl)                                           ;#7A9F: AE
        rrca                                                   ;#7AA0: 0F
        rrca                                                   ;#7AA1: 0F
        rrca                                                   ;#7AA2: 0F
        ld      (ix+MUSIC_DRIVER_SUSTAIN_BASE),a               ;#7AA3: DD 77 06
        inc     hl                                             ;#7AA6: 23
        ld      a,(hl)                                         ;#7AA7: 7E
PROCESS_SOUND_OTHER_MARKER:
        ; Decode markers other than 0xFD
        and     0Fh                                            ;#7AA8: E6 0F
        ld      b,a                                            ;#7AAA: 47
        xor     (hl)                                           ;#7AAB: AE
        inc     hl                                             ;#7AAC: 23
        ld      (ix+MUSIC_DRIVER_STREAM_PTR_LO),l              ;#7AAD: DD 75 03
        ld      (ix+MUSIC_DRIVER_STREAM_PTR_HI),h              ;#7AB0: DD 74 04
        rrca                                                   ;#7AB3: 0F
        rrca                                                   ;#7AB4: 0F
        rrca                                                   ;#7AB5: 0F
        rrca                                                   ;#7AB6: 0F
        ld      hl,SOUND_DURATION_TABLE                        ;#7AB7: 21 FE 7A
        call    ADD_HL_A                                       ;#7ABA: CD D3 48
        ld      a,(hl)                                         ;#7ABD: 7E
        ld      (ix+MUSIC_DRIVER_DURATION_BASE),a              ;#7ABE: DD 77 01
        ld      a,b                                            ;#7AC1: 78
        sub     0Ch                                            ;#7AC2: D6 0C
        ld      (ix+MUSIC_DRIVER_SUSTAIN_COUNTER),a            ;#7AC4: DD 77 07
        jr      z,PROCESS_SOUND_SKIP_PITCH_LOOKUP              ;#7AC7: 28 06
        ld      a,(ix+MUSIC_DRIVER_SUSTAIN_BASE)               ;#7AC9: DD 7E 06
        ld      (ix+MUSIC_DRIVER_SUSTAIN_COUNTER),a            ;#7ACC: DD 77 07
PROCESS_SOUND_SKIP_PITCH_LOOKUP:
        ; Skip pitch lookup for command 0x0C
        call    PROCESS_SOUND_UPDATE_CHANNEL_REGS              ;#7ACF: CD 56 7A
        ld      a,b                                            ;#7AD2: 78
        ld      hl,SOUND_PITCH_OFFSET_TABLE                    ;#7AD3: 21 F2 7A
        call    ADD_HL_A                                       ;#7AD6: CD D3 48
        ld      l,(hl)                                         ;#7AD9: 6E
        ld      h,0                                            ;#7ADA: 26 00
        ld      a,(ix+MUSIC_DRIVER_OCTAVE)                     ;#7ADC: DD 7E 05
        or      a                                              ;#7ADF: B7
        jr      z,PROCESS_SOUND_WRITE_PERIOD                   ;#7AE0: 28 04
        ld      b,a                                            ;#7AE2: 47
PROCESS_SOUND_PITCH_SHIFT_LOOP:
        ; Small loop to shift the pitch value in HL
        add     hl,hl                                          ;#7AE3: 29
        djnz    PROCESS_SOUND_PITCH_SHIFT_LOOP                 ;#7AE4: 10 FD
PROCESS_SOUND_WRITE_PERIOD:
        ; Write 12-bit period to PSG frequency registers
        ld      a,c                                            ;#7AE6: 79
        ld      e,h                                            ;#7AE7: 5C
        call    BIOS_WRTPSG                                    ;#7AE8: CD 93 00
        ld      a,c                                            ;#7AEB: 79
        dec     a                                              ;#7AEC: 3D
        ld      e,l                                            ;#7AED: 5D
        jp      BIOS_WRTPSG                                    ;#7AEE: C3 93 00
        db      0FFh                                           ;#7AF1: FF

SOUND_PITCH_OFFSET_TABLE:
        ; Table of pitch/period offsets
        ; Format: FORMAT_PITCH_TABLE
        db      06Ah ; C  (1055 Hz)                            ;#7AF2: 6A
        db      064h ; C# (1118.5 Hz)                          ;#7AF3: 64
        db      05Fh ; D  (1177.5 Hz)                          ;#7AF4: 5F
        db      059h ; D# (1257 Hz)                            ;#7AF5: 59
        db      054h ; E  (1331.5 Hz)                          ;#7AF6: 54
        db      050h ; F  (1398 Hz)                            ;#7AF7: 50
        db      04Bh ; F# (1491.5 Hz)                          ;#7AF8: 4B
        db      047h ; G  (1575.5 Hz)                          ;#7AF9: 47
        db      043h ; G# (1669.5 Hz)                          ;#7AFA: 43
        db      03Fh ; A  (1775.5 Hz)                          ;#7AFB: 3F
        db      03Ch ; A# (1864.5 Hz)                          ;#7AFC: 3C
        db      038h ; B  (1997.5 Hz)                          ;#7AFD: 38

SOUND_DURATION_TABLE:
        ; Table of note durations
        ; Format: FORMAT_DURATION_TABLE
        db      8                                              ;#7AFE: 08
        db      10h                                            ;#7AFF: 10
        db      20h                                            ;#7B00: 20
        db      30h                                            ;#7B01: 30
        db      40h                                            ;#7B02: 40
        db      60h                                            ;#7B03: 60
        db      5                                              ;#7B04: 05
        db      0Ah                                            ;#7B05: 0A
        db      0Fh                                            ;#7B06: 0F
        db      14h                                            ;#7B07: 14
        db      64h                                            ;#7B08: 64
        db      1Eh                                            ;#7B09: 1E
        db      18h                                            ;#7B0A: 18
        db      3Ch                                            ;#7B0B: 3C
        db      50h                                            ;#7B0C: 50
        db      28h                                            ;#7B0D: 28

SOUND_TABLE:
        ; Base of sound pointer table
        dw      SOUND_DATA_TICK                                ;#7B0E: 00 7D
        dw      SOUND_DATA_JUMP                                ;#7B10: DA 7C
        dw      SOUND_DATA_OBSTACLE                            ;#7B12: 38 7D
        dw      SOUND_DATA_CATCH                               ;#7B14: 40 7D
        dw      SOUND_DATA_FALL_HOLE                           ;#7B16: 24 7D
        dw      SOUND_DATA_STAGE_START                         ;#7B18: 18 7D
        dw      SOUND_DATA_STUN_DESCENDING                     ;#7B1A: 06 7D
        dw      SOUND_DATA_STUMBLE                             ;#7B1C: 2F 7E
        dw      SOUND_DATA_DISTANCE_WARNING                    ;#7B1E: E8 7C
        dw      SOUND_DATA_MAIN_THEME                          ;#7B20: 3D 7B
        dw      SOUND_DATA_MAIN_THEME_CH1                      ;#7B22: BD 7B
        dw      SOUND_DATA_TIME_OUT                            ;#7B24: DC 7D
        dw      SOUND_DATA_TIME_OUT_CH1                        ;#7B26: F9 7D
        dw      SOUND_DATA_TIME_OUT_CH2                        ;#7B28: 1C 7E
        dw      SOUND_DATA_STAGE_CLEAR                         ;#7B2A: 93 7C
        dw      SOUND_DATA_STAGE_CLEAR_CH1                     ;#7B2C: B1 7C
        dw      SOUND_DATA_STAGE_CLEAR_CH2                     ;#7B2E: C8 7C
        dw      SOUND_DATA_INTRO_MUSIC                         ;#7B30: 48 7D
        dw      SOUND_DATA_INTRO_MUSIC_CH1                     ;#7B32: 7A 7D
        dw      SOUND_DATA_INTRO_MUSIC_CH2                     ;#7B34: AD 7D
        dw      SOUND_DATA_SILENCE                             ;#7B36: 3C 7B
        dw      SOUND_DATA_SILENCE                             ;#7B38: 3C 7B
        dw      SOUND_DATA_SILENCE                             ;#7B3A: 3C 7B

SOUND_DATA_SILENCE:
        ; Data for Sound 21-23 (Silence/Stop, Size: 1)
        db      0FFh                                           ;#7B3C: FF

SOUND_DATA_MAIN_THEME:
        ; Data for Sound 10 (Main Theme CH0, Size: 128)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7B3D: FD 5A
        NOTE NOTE_B, DURATION_48                               ;#7B3F: 3B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7B40: FD 59
        NOTE NOTE_D, DURATION_32                               ;#7B42: 22
        NOTE NOTE_E, DURATION_16                               ;#7B43: 14
        NOTE NOTE_E, DURATION_96                               ;#7B44: 54
        NOTE NOTE_C, DURATION_48                               ;#7B45: 30
        NOTE NOTE_E, DURATION_32                               ;#7B46: 24
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7B47: 16
        NOTE NOTE_F_SHARP, DURATION_96                         ;#7B48: 56
        NOTE NOTE_A, DURATION_48                               ;#7B49: 39
        NOTE NOTE_G, DURATION_32                               ;#7B4A: 27
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7B4B: FD 5A
        NOTE NOTE_B, DURATION_16                               ;#7B4D: 1B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7B4E: FD 59
        NOTE NOTE_D, DURATION_48                               ;#7B50: 32
        NOTE NOTE_C, DURATION_32                               ;#7B51: 20
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7B52: FD 5A
        NOTE NOTE_B, DURATION_16                               ;#7B54: 1B
        NOTE NOTE_B, DURATION_48                               ;#7B55: 3B
        NOTE NOTE_A, DURATION_48                               ;#7B56: 39
        NOTE NOTE_G, DURATION_64                               ;#7B57: 47
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7B58: FD 59
        NOTE NOTE_D, DURATION_8                                ;#7B5A: 02
        NOTE NOTE_G, DURATION_8                                ;#7B5B: 07
        NOTE NOTE_E, DURATION_8                                ;#7B5C: 04
        NOTE NOTE_G, DURATION_8                                ;#7B5D: 07
        NOTE NOTE_D, DURATION_8                                ;#7B5E: 02
        NOTE NOTE_G, DURATION_8                                ;#7B5F: 07
        NOTE NOTE_E, DURATION_8                                ;#7B60: 04
        NOTE NOTE_G, DURATION_8                                ;#7B61: 07
        NOTE NOTE_D, DURATION_8                                ;#7B62: 02
        NOTE NOTE_G, DURATION_8                                ;#7B63: 07
        NOTE NOTE_E, DURATION_8                                ;#7B64: 04
        NOTE NOTE_G, DURATION_8                                ;#7B65: 07
        NOTE NOTE_D, DURATION_8                                ;#7B66: 02
        NOTE NOTE_G, DURATION_8                                ;#7B67: 07
        NOTE NOTE_E, DURATION_8                                ;#7B68: 04
        NOTE NOTE_G, DURATION_8                                ;#7B69: 07
        NOTE NOTE_D, DURATION_16                               ;#7B6A: 12
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B6B: 06
        NOTE NOTE_HOLD, DURATION_8                             ;#7B6C: 0C
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B6D: 06
        NOTE NOTE_HOLD, DURATION_8                             ;#7B6E: 0C
        NOTE NOTE_D, DURATION_16                               ;#7B6F: 12
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B70: 06
        NOTE NOTE_HOLD, DURATION_8                             ;#7B71: 0C
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B72: 06
        NOTE NOTE_HOLD, DURATION_8                             ;#7B73: 0C
        NOTE NOTE_D, DURATION_8                                ;#7B74: 02
        NOTE NOTE_A, DURATION_8                                ;#7B75: 09
        NOTE NOTE_E, DURATION_8                                ;#7B76: 04
        NOTE NOTE_A, DURATION_8                                ;#7B77: 09
        NOTE NOTE_D, DURATION_8                                ;#7B78: 02
        NOTE NOTE_A, DURATION_8                                ;#7B79: 09
        NOTE NOTE_E, DURATION_8                                ;#7B7A: 04
        NOTE NOTE_A, DURATION_8                                ;#7B7B: 09
        NOTE NOTE_D, DURATION_8                                ;#7B7C: 02
        NOTE NOTE_A, DURATION_8                                ;#7B7D: 09
        NOTE NOTE_E, DURATION_8                                ;#7B7E: 04
        NOTE NOTE_A, DURATION_8                                ;#7B7F: 09
        NOTE NOTE_D, DURATION_16                               ;#7B80: 12
        NOTE NOTE_G, DURATION_8                                ;#7B81: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7B82: 0C
        NOTE NOTE_G, DURATION_8                                ;#7B83: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7B84: 0C
        NOTE NOTE_D, DURATION_16                               ;#7B85: 12
        NOTE NOTE_G, DURATION_8                                ;#7B86: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7B87: 0C
        NOTE NOTE_G, DURATION_8                                ;#7B88: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7B89: 0C
        NOTE NOTE_D, DURATION_8                                ;#7B8A: 02
        NOTE NOTE_G, DURATION_8                                ;#7B8B: 07
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7B8C: 06
        NOTE NOTE_G, DURATION_8                                ;#7B8D: 07
        NOTE NOTE_D, DURATION_8                                ;#7B8E: 02
        NOTE NOTE_G, DURATION_8                                ;#7B8F: 07
        NOTE NOTE_D, DURATION_8                                ;#7B90: 02
        NOTE NOTE_G, DURATION_8                                ;#7B91: 07
        NOTE NOTE_F, DURATION_8                                ;#7B92: 05
        NOTE NOTE_G, DURATION_8                                ;#7B93: 07
        NOTE NOTE_D, DURATION_8                                ;#7B94: 02
        NOTE NOTE_G, DURATION_8                                ;#7B95: 07
        NOTE NOTE_C, DURATION_8                                ;#7B96: 00
        NOTE NOTE_G, DURATION_8                                ;#7B97: 07
        NOTE NOTE_E, DURATION_8                                ;#7B98: 04
        NOTE NOTE_G, DURATION_8                                ;#7B99: 07
        NOTE NOTE_C, DURATION_8                                ;#7B9A: 00
        NOTE NOTE_G, DURATION_8                                ;#7B9B: 07
        NOTE NOTE_C, DURATION_8                                ;#7B9C: 00
        NOTE NOTE_G, DURATION_8                                ;#7B9D: 07
        NOTE NOTE_D_SHARP, DURATION_8                          ;#7B9E: 03
        NOTE NOTE_G, DURATION_8                                ;#7B9F: 07
        NOTE NOTE_C, DURATION_8                                ;#7BA0: 00
        NOTE NOTE_G, DURATION_8                                ;#7BA1: 07
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BA2: FD 5A
        NOTE NOTE_B, DURATION_8                                ;#7BA4: 0B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7BA5: FD 59
        NOTE NOTE_G, DURATION_8                                ;#7BA7: 07
        NOTE NOTE_D, DURATION_8                                ;#7BA8: 02
        NOTE NOTE_G, DURATION_8                                ;#7BA9: 07
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BAA: FD 5A
        NOTE NOTE_B, DURATION_8                                ;#7BAC: 0B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7BAD: FD 59
        NOTE NOTE_G, DURATION_8                                ;#7BAF: 07
        NOTE NOTE_C, DURATION_8                                ;#7BB0: 00
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7BB1: 06
        NOTE NOTE_D, DURATION_8                                ;#7BB2: 02
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7BB3: 06
        NOTE NOTE_C, DURATION_8                                ;#7BB4: 00
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7BB5: 06
        NOTE NOTE_G, DURATION_16                               ;#7BB6: 17
        NOTE NOTE_HOLD, DURATION_16                            ;#7BB7: 1C
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7BB8: 16
        NOTE NOTE_G, DURATION_16                               ;#7BB9: 17
        NOTE NOTE_HOLD, DURATION_32                            ;#7BBA: 2C
        db      0FEh, 0FFh ; Repeat (FF=forever)               ;#7BBB: FE FF

SOUND_DATA_MAIN_THEME_CH1:
        ; Data for Sound 11 (Main Theme CH1, Size: 214)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BBD: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BBF: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BC0: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BC2: 12
        NOTE NOTE_D, DURATION_16                               ;#7BC3: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BC4: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BC6: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BC7: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BC9: 12
        NOTE NOTE_D, DURATION_16                               ;#7BCA: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BCB: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BCD: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BCE: FD 5A
        NOTE NOTE_C, DURATION_16                               ;#7BD0: 10
        NOTE NOTE_C, DURATION_16                               ;#7BD1: 10
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BD2: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BD4: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BD5: FD 5A
        NOTE NOTE_C, DURATION_16                               ;#7BD7: 10
        NOTE NOTE_C, DURATION_16                               ;#7BD8: 10
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BD9: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BDB: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BDC: FD 5A
        NOTE NOTE_E, DURATION_16                               ;#7BDE: 14
        NOTE NOTE_E, DURATION_16                               ;#7BDF: 14
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BE0: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7BE2: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BE3: FD 5A
        NOTE NOTE_E, DURATION_16                               ;#7BE5: 14
        NOTE NOTE_E, DURATION_16                               ;#7BE6: 14
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BE7: FD 5B
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7BE9: 16
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BEA: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BEC: 12
        NOTE NOTE_D, DURATION_16                               ;#7BED: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BEE: FD 5B
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7BF0: 16
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BF1: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BF3: 12
        NOTE NOTE_D, DURATION_16                               ;#7BF4: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BF5: FD 5B
        NOTE NOTE_C, DURATION_16                               ;#7BF7: 10
        NOTE NOTE_A, DURATION_16                               ;#7BF8: 19
        NOTE NOTE_A, DURATION_16                               ;#7BF9: 19
        NOTE NOTE_G, DURATION_16                               ;#7BFA: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BFB: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7BFD: 12
        NOTE NOTE_D, DURATION_16                               ;#7BFE: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7BFF: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C01: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C02: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C04: 12
        NOTE NOTE_D, DURATION_16                               ;#7C05: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C06: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7C08: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C09: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C0B: 12
        NOTE NOTE_D, DURATION_16                               ;#7C0C: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C0D: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C0F: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C10: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C12: 12
        NOTE NOTE_D, DURATION_16                               ;#7C13: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C14: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7C16: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C17: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C19: 12
        NOTE NOTE_D, DURATION_16                               ;#7C1A: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C1B: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C1D: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C1E: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C20: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C21: FD 5B
        NOTE NOTE_B, DURATION_16                               ;#7C23: 1B
        NOTE NOTE_G, DURATION_32                               ;#7C24: 27
        NOTE NOTE_HOLD, DURATION_16                            ;#7C25: 1C
        NOTE NOTE_B, DURATION_16                               ;#7C26: 1B
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C27: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C29: 12
        NOTE NOTE_D, DURATION_16                               ;#7C2A: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C2B: FD 5B
        NOTE NOTE_B, DURATION_16                               ;#7C2D: 1B
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C2E: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C30: 12
        NOTE NOTE_D, DURATION_16                               ;#7C31: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C32: FD 5B
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7C34: 16
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C35: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C37: 12
        NOTE NOTE_D, DURATION_16                               ;#7C38: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C39: FD 5B
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7C3B: 16
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C3C: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C3E: 12
        NOTE NOTE_D, DURATION_16                               ;#7C3F: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C40: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7C42: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C43: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C45: 12
        NOTE NOTE_D, DURATION_16                               ;#7C46: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C47: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7C49: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C4A: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C4C: 12
        NOTE NOTE_D, DURATION_16                               ;#7C4D: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C4E: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C50: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C51: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C53: 12
        NOTE NOTE_D, DURATION_16                               ;#7C54: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C55: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C57: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C58: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C5A: 12
        NOTE NOTE_D, DURATION_16                               ;#7C5B: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C5C: FD 5B
        NOTE NOTE_D, DURATION_16                               ;#7C5E: 12
        NOTE NOTE_G, DURATION_16                               ;#7C5F: 17
        NOTE NOTE_B, DURATION_16                               ;#7C60: 1B
        NOTE NOTE_G, DURATION_16                               ;#7C61: 17
        NOTE NOTE_B, DURATION_16                               ;#7C62: 1B
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C63: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C65: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C66: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C68: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C69: FD 5A
        NOTE NOTE_C, DURATION_16                               ;#7C6B: 10
        NOTE NOTE_E, DURATION_16                               ;#7C6C: 14
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C6D: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C6F: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C70: FD 5A
        NOTE NOTE_C, DURATION_16                               ;#7C72: 10
        NOTE NOTE_E, DURATION_16                               ;#7C73: 14
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C74: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C76: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C77: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C79: 12
        NOTE NOTE_HOLD, DURATION_16                            ;#7C7A: 1C
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C7B: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7C7D: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C7E: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C80: 12
        NOTE NOTE_HOLD, DURATION_16                            ;#7C81: 1C
        NOTE NOTE_D, DURATION_16                               ;#7C82: 12
        NOTE NOTE_HOLD, DURATION_16                            ;#7C83: 1C
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C84: FD 5B
        NOTE NOTE_B, DURATION_16                               ;#7C86: 1B
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C87: FD 5A
        NOTE NOTE_D, DURATION_8                                ;#7C89: 02
        NOTE NOTE_C, DURATION_8                                ;#7C8A: 00
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C8B: FD 5B
        NOTE NOTE_B, DURATION_8                                ;#7C8D: 0B
        NOTE NOTE_A, DURATION_8                                ;#7C8E: 09
        NOTE NOTE_G, DURATION_8                                ;#7C8F: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7C90: 0C
        db      0FEh, 0FFh ; Repeat (FF=forever)               ;#7C91: FE FF

SOUND_DATA_STAGE_CLEAR:
        ; Data for Sound 15 (Stage Clear CH0, Size: 29)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7C93: FD 59
        NOTE NOTE_C, DURATION_20                               ;#7C95: 90
        NOTE NOTE_C, DURATION_15                               ;#7C96: 80
        NOTE NOTE_C, DURATION_5                                ;#7C97: 60
        NOTE NOTE_C, DURATION_20                               ;#7C98: 90
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C99: FD 5A
        NOTE NOTE_B, DURATION_15                               ;#7C9B: 8B
        NOTE NOTE_A, DURATION_5                                ;#7C9C: 69
        NOTE NOTE_G, DURATION_20                               ;#7C9D: 97
        NOTE NOTE_E, DURATION_20                               ;#7C9E: 94
        NOTE NOTE_G, DURATION_20                               ;#7C9F: 97
        NOTE NOTE_E, DURATION_20                               ;#7CA0: 94
        NOTE NOTE_D, DURATION_10                               ;#7CA1: 72
        NOTE NOTE_E, DURATION_10                               ;#7CA2: 74
        NOTE NOTE_F, DURATION_10                               ;#7CA3: 75
        NOTE NOTE_G, DURATION_10                               ;#7CA4: 77
        NOTE NOTE_A, DURATION_10                               ;#7CA5: 79
        NOTE NOTE_G, DURATION_10                               ;#7CA6: 77
        NOTE NOTE_A, DURATION_10                               ;#7CA7: 79
        NOTE NOTE_B, DURATION_10                               ;#7CA8: 7B
        SET_OCTAVE_SUSTAIN 1, 0Ch                              ;#7CA9: FD 61
        NOTE NOTE_C, DURATION_20                               ;#7CAB: 90
        NOTE NOTE_C, DURATION_15                               ;#7CAC: 80
        NOTE NOTE_C, DURATION_5                                ;#7CAD: 60
        NOTE NOTE_C, DURATION_20                               ;#7CAE: 90
        db      0FFh                                           ;#7CAF: FF
        db      0FFh                                           ;#7CB0: FF

SOUND_DATA_STAGE_CLEAR_CH1:
        ; Data for Sound 16 (Stage Clear CH1, Size: 22)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7CB1: FD 5B
        NOTE NOTE_G, DURATION_20                               ;#7CB3: 97
        NOTE NOTE_G, DURATION_20                               ;#7CB4: 97
        NOTE NOTE_G, DURATION_20                               ;#7CB5: 97
        NOTE NOTE_HOLD, DURATION_20                            ;#7CB6: 9C
        NOTE NOTE_G, DURATION_20                               ;#7CB7: 97
        NOTE NOTE_G, DURATION_20                               ;#7CB8: 97
        NOTE NOTE_G, DURATION_20                               ;#7CB9: 97
        NOTE NOTE_HOLD, DURATION_20                            ;#7CBA: 9C
        NOTE NOTE_F, DURATION_20                               ;#7CBB: 95
        NOTE NOTE_D, DURATION_20                               ;#7CBC: 92
        NOTE NOTE_G, DURATION_20                               ;#7CBD: 97
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7CBE: FD 5C
        NOTE NOTE_G, DURATION_20                               ;#7CC0: 97
        SET_OCTAVE_SUSTAIN 3, 0Ch                              ;#7CC1: FD 63
        NOTE NOTE_C, DURATION_20                               ;#7CC3: 90
        NOTE NOTE_G, DURATION_20                               ;#7CC4: 97
        NOTE NOTE_G, DURATION_20                               ;#7CC5: 97
        db      0FFh                                           ;#7CC6: FF
        db      0FFh                                           ;#7CC7: FF

SOUND_DATA_STAGE_CLEAR_CH2:
        ; Data for Sound 17 (Stage Clear CH2, Size: 17)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7CC8: FD 5B
        NOTE NOTE_C, DURATION_20                               ;#7CCA: 90
        NOTE NOTE_C, DURATION_20                               ;#7CCB: 90
        NOTE NOTE_C, DURATION_20                               ;#7CCC: 90
        NOTE NOTE_HOLD, DURATION_20                            ;#7CCD: 9C
        NOTE NOTE_C, DURATION_20                               ;#7CCE: 90
        NOTE NOTE_C, DURATION_20                               ;#7CCF: 90
        NOTE NOTE_C, DURATION_20                               ;#7CD0: 90
        NOTE NOTE_HOLD, DURATION_20                            ;#7CD1: 9C
        NOTE NOTE_HOLD, DURATION_100                           ;#7CD2: AC
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7CD3: FD 5A
        NOTE NOTE_E, DURATION_15                               ;#7CD5: 84
        NOTE NOTE_E, DURATION_5                                ;#7CD6: 64
        NOTE NOTE_E, DURATION_20                               ;#7CD7: 94
        db      0FFh                                           ;#7CD8: FF
        db      0FFh                                           ;#7CD9: FF

SOUND_DATA_JUMP:
        ; Data for Sound 2 (Jump, Size: 14)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 2                                         ;#7CDA: 22
        SOUND 0Dh, 7Fh                                         ;#7CDB: D0 7F
        SOUND 0Bh, 70h                                         ;#7CDD: B0 70
        SOUND 0Bh, 77h                                         ;#7CDF: B0 77
        SOUND 0Ah, 62h                                         ;#7CE1: A0 62
        SOUND 9, 50h                                           ;#7CE3: 90 50
        SOUND 8, 43h                                           ;#7CE5: 80 43
        db      0FFh                                           ;#7CE7: FF

SOUND_DATA_DISTANCE_WARNING:
        ; Data for Sound 9 (Distance < 1000m), Size: 24)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 3                                         ;#7CE8: 23
        SOUND 9, 60h                                           ;#7CE9: 90 60
        SOUND 9, 40h                                           ;#7CEB: 90 40
        SOUND 9, 60h                                           ;#7CED: 90 60
        SOUND 9, 40h                                           ;#7CEF: 90 40
        SOUND 9, 60h                                           ;#7CF1: 90 60
        SOUND 9, 40h                                           ;#7CF3: 90 40
        SOUND 9, 60h                                           ;#7CF5: 90 60
        SOUND 9, 40h                                           ;#7CF7: 90 40
        SOUND 9, 60h                                           ;#7CF9: 90 60
        SOUND 9, 40h                                           ;#7CFB: 90 40
        SOUND 9, 60h                                           ;#7CFD: 90 60
        db      0FFh                                           ;#7CFF: FF

SOUND_DATA_TICK:
        ; Data for Sound 1 (Goal Tally Tick, Size: 6)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 1                                         ;#7D00: 21
        SOUND 0Ah, 25h                                         ;#7D01: A0 25
        SOUND 0Ah, 27h                                         ;#7D03: A0 27
        db      0FFh                                           ;#7D05: FF

SOUND_DATA_STUN_DESCENDING:
        ; Data for Sound 7 (Descending Scale, Size: 18)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 1                                         ;#7D06: 21
        SOUND 0Ch, 0DDh                                        ;#7D07: C0 DD
        SOUND 0Ch, 0BBh                                        ;#7D09: C0 BB
        SOUND 0Bh, 0AAh                                        ;#7D0B: B0 AA
        SOUND 0Bh, 99h                                         ;#7D0D: B0 99
        SOUND 0Ah, 88h                                         ;#7D0F: A0 88
        SOUND 0Ah, 77h                                         ;#7D11: A0 77
        SOUND 9, 66h                                           ;#7D13: 90 66
        SOUND 9, 55h                                           ;#7D15: 90 55
        db      0FFh                                           ;#7D17: FF

SOUND_DATA_STAGE_START:
        ; Data for Sound 6 (Stage Start Jingle, Size: 12)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 2                                         ;#7D18: 22
        SOUND 0Ch, 55h                                         ;#7D19: C0 55
        SOUND 0Ch, 66h                                         ;#7D1B: C0 66
        SOUND 0Ch, 55h                                         ;#7D1D: C0 55
        SOUND 0Bh, 44h                                         ;#7D1F: B0 44
        SOUND 0Ah, 33h                                         ;#7D21: A0 33
        db      0FFh                                           ;#7D23: FF

SOUND_DATA_FALL_HOLE:
        ; Data for Sound 5 (Fall in Hole, Size: 20)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 2                                         ;#7D24: 22
        SOUND 0Eh, 0A5h                                        ;#7D25: E0 A5
        SOUND 0Ch, 0B5h                                        ;#7D27: C0 B5
        SOUND 0Ah, 0C5h                                        ;#7D29: A0 C5
        SOUND 9, 0D5h                                          ;#7D2B: 90 D5
        SOUND 8, 0E5h                                          ;#7D2D: 80 E5
        SOUND 7, 0F5h                                          ;#7D2F: 70 F5
        SOUND 6, 105h                                          ;#7D31: 61 05
        SOUND 5, 125h                                          ;#7D33: 51 25
        SOUND 5, 145h                                          ;#7D35: 51 45
        db      0FFh                                           ;#7D37: FF

SOUND_DATA_OBSTACLE:
        ; Data for Sound 3 (Hit Obstacle, Size: 8)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 1                                         ;#7D38: 21
        SOUND 0Ch, 103h                                        ;#7D39: C1 03
        SOUND 0Ch, 10Dh                                        ;#7D3B: C1 0D
        SOUND 0Ch, 106h                                        ;#7D3D: C1 06
        db      0FFh                                           ;#7D3F: FF

SOUND_DATA_CATCH:
        ; Data for Sound 4 (Catch Fish/Flag, Size: 8)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 1                                         ;#7D40: 21
        SOUND 0Ch, 143h                                        ;#7D41: C1 43
        SOUND 0Ch, 14Dh                                        ;#7D43: C1 4D
        SOUND 0Ch, 146h                                        ;#7D45: C1 46
        db      0FFh                                           ;#7D47: FF

SOUND_DATA_INTRO_MUSIC:
        ; Data for Sound 18 (Demo BGM CH0, Size: 50)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D48: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7D4A: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D4B: FD 59
        NOTE NOTE_D, DURATION_10                               ;#7D4D: 72
        NOTE NOTE_E, DURATION_10                               ;#7D4E: 74
        NOTE NOTE_D, DURATION_10                               ;#7D4F: 72
        NOTE NOTE_G, DURATION_20                               ;#7D50: 97
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7D51: 76
        NOTE NOTE_E, DURATION_10                               ;#7D52: 74
        NOTE NOTE_D, DURATION_30                               ;#7D53: B2
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D54: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7D56: 7B
        NOTE NOTE_G, DURATION_20                               ;#7D57: 97
        NOTE NOTE_G, DURATION_5                                ;#7D58: 67
        NOTE NOTE_A, DURATION_5                                ;#7D59: 69
        NOTE NOTE_B, DURATION_5                                ;#7D5A: 6B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D5B: FD 59
        NOTE NOTE_C, DURATION_5                                ;#7D5D: 60
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D5E: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7D60: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D61: FD 59
        NOTE NOTE_D, DURATION_10                               ;#7D63: 72
        NOTE NOTE_E, DURATION_10                               ;#7D64: 74
        NOTE NOTE_D, DURATION_10                               ;#7D65: 72
        NOTE NOTE_G, DURATION_20                               ;#7D66: 97
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7D67: 76
        NOTE NOTE_E, DURATION_10                               ;#7D68: 74
        NOTE NOTE_D, DURATION_5                                ;#7D69: 62
        NOTE NOTE_E, DURATION_5                                ;#7D6A: 64
        NOTE NOTE_D, DURATION_5                                ;#7D6B: 62
        NOTE NOTE_C, DURATION_5                                ;#7D6C: 60
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D6D: FD 5A
        NOTE NOTE_B, DURATION_5                                ;#7D6F: 6B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D70: FD 59
        NOTE NOTE_C, DURATION_5                                ;#7D72: 60
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D73: FD 5A
        NOTE NOTE_B, DURATION_5                                ;#7D75: 6B
        NOTE NOTE_A, DURATION_5                                ;#7D76: 69
        NOTE NOTE_G, DURATION_20                               ;#7D77: 97
        NOTE NOTE_HOLD, DURATION_20                            ;#7D78: 9C
        db      0FFh                                           ;#7D79: FF

SOUND_DATA_INTRO_MUSIC_CH1:
        ; Data for Sound 19 (Demo BGM CH1, Size: 51)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D7A: FD 5A
        NOTE NOTE_G, DURATION_10                               ;#7D7C: 77
        NOTE NOTE_B, DURATION_10                               ;#7D7D: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D7E: FD 59
        NOTE NOTE_C, DURATION_10                               ;#7D80: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D81: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7D83: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D84: FD 59
        NOTE NOTE_D, DURATION_20                               ;#7D86: 92
        NOTE NOTE_C, DURATION_10                               ;#7D87: 70
        NOTE NOTE_C, DURATION_10                               ;#7D88: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D89: FD 5A
        NOTE NOTE_B, DURATION_30                               ;#7D8B: BB
        NOTE NOTE_G, DURATION_10                               ;#7D8C: 77
        NOTE NOTE_D, DURATION_20                               ;#7D8D: 92
        NOTE NOTE_HOLD, DURATION_20                            ;#7D8E: 9C
        NOTE NOTE_G, DURATION_10                               ;#7D8F: 77
        NOTE NOTE_B, DURATION_10                               ;#7D90: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D91: FD 59
        NOTE NOTE_C, DURATION_10                               ;#7D93: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D94: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7D96: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D97: FD 59
        NOTE NOTE_D, DURATION_20                               ;#7D99: 92
        NOTE NOTE_C, DURATION_10                               ;#7D9A: 70
        NOTE NOTE_C, DURATION_10                               ;#7D9B: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D9C: FD 5A
        NOTE NOTE_B, DURATION_5                                ;#7D9E: 6B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D9F: FD 59
        NOTE NOTE_C, DURATION_5                                ;#7DA1: 60
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DA2: FD 5A
        NOTE NOTE_B, DURATION_5                                ;#7DA4: 6B
        NOTE NOTE_A, DURATION_5                                ;#7DA5: 69
        NOTE NOTE_G, DURATION_5                                ;#7DA6: 67
        NOTE NOTE_A, DURATION_5                                ;#7DA7: 69
        NOTE NOTE_G, DURATION_5                                ;#7DA8: 67
        NOTE NOTE_F_SHARP, DURATION_5                          ;#7DA9: 66
        NOTE NOTE_D, DURATION_20                               ;#7DAA: 92
        NOTE NOTE_HOLD, DURATION_20                            ;#7DAB: 9C
        db      0FFh                                           ;#7DAC: FF

SOUND_DATA_INTRO_MUSIC_CH2:
        ; Data for Sound 20 (Demo BGM CH2, Size: 47)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7DAD: FD 5B
        NOTE NOTE_G, DURATION_10                               ;#7DAF: 77
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7DB0: 76
        NOTE NOTE_E, DURATION_10                               ;#7DB1: 74
        NOTE NOTE_D, DURATION_10                               ;#7DB2: 72
        NOTE NOTE_C, DURATION_10                               ;#7DB3: 70
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7DB4: FD 5C
        NOTE NOTE_B, DURATION_10                               ;#7DB6: 7B
        NOTE NOTE_A, DURATION_10                               ;#7DB7: 79
        NOTE NOTE_G, DURATION_10                               ;#7DB8: 77
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7DB9: FD 5B
        NOTE NOTE_G, DURATION_10                               ;#7DBB: 77
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7DBC: 76
        NOTE NOTE_E, DURATION_10                               ;#7DBD: 74
        NOTE NOTE_D, DURATION_10                               ;#7DBE: 72
        NOTE NOTE_C, DURATION_10                               ;#7DBF: 70
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7DC0: FD 5C
        NOTE NOTE_B, DURATION_10                               ;#7DC2: 7B
        NOTE NOTE_A, DURATION_10                               ;#7DC3: 79
        NOTE NOTE_G, DURATION_10                               ;#7DC4: 77
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7DC5: FD 5B
        NOTE NOTE_G, DURATION_10                               ;#7DC7: 77
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7DC8: 76
        NOTE NOTE_E, DURATION_10                               ;#7DC9: 74
        NOTE NOTE_D, DURATION_10                               ;#7DCA: 72
        NOTE NOTE_C, DURATION_10                               ;#7DCB: 70
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7DCC: FD 5C
        NOTE NOTE_B, DURATION_10                               ;#7DCE: 7B
        NOTE NOTE_A, DURATION_10                               ;#7DCF: 79
        NOTE NOTE_G, DURATION_10                               ;#7DD0: 77
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7DD1: FD 5B
        NOTE NOTE_D, DURATION_10                               ;#7DD3: 72
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7DD4: FD 5C
        NOTE NOTE_D, DURATION_10                               ;#7DD6: 72
        NOTE NOTE_E, DURATION_10                               ;#7DD7: 74
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7DD8: 76
        NOTE NOTE_G, DURATION_10                               ;#7DD9: 77
        NOTE NOTE_HOLD, DURATION_20                            ;#7DDA: 9C
        db      0FFh                                           ;#7DDB: FF

SOUND_DATA_TIME_OUT:
        ; Data for Sound 12 (Time Out CH0, Size: 29)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DDC: FD 59
        NOTE NOTE_E, DURATION_20                               ;#7DDE: 94
        NOTE NOTE_E, DURATION_10                               ;#7DDF: 74
        NOTE NOTE_E, DURATION_10                               ;#7DE0: 74
        NOTE NOTE_E, DURATION_20                               ;#7DE1: 94
        NOTE NOTE_D, DURATION_10                               ;#7DE2: 72
        NOTE NOTE_C, DURATION_10                               ;#7DE3: 70
        NOTE NOTE_F, DURATION_30                               ;#7DE4: B5
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DE5: FD 5A
        NOTE NOTE_F, DURATION_10                               ;#7DE7: 75
        NOTE NOTE_F, DURATION_30                               ;#7DE8: B5
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DE9: FD 59
        NOTE NOTE_F, DURATION_10                               ;#7DEB: 75
        NOTE NOTE_E, DURATION_20                               ;#7DEC: 94
        NOTE NOTE_C, DURATION_10                               ;#7DED: 70
        NOTE NOTE_E, DURATION_10                               ;#7DEE: 74
        NOTE NOTE_D, DURATION_20                               ;#7DEF: 92
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DF0: FD 5A
        NOTE NOTE_A, DURATION_10                               ;#7DF2: 79
        NOTE NOTE_B, DURATION_10                               ;#7DF3: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DF4: FD 59
        NOTE NOTE_C, DURATION_60                               ;#7DF6: D0
        NOTE NOTE_HOLD, DURATION_16                            ;#7DF7: 1C
        db      0FFh                                           ;#7DF8: FF

SOUND_DATA_TIME_OUT_CH1:
        ; Data for Sound 13 (Time Out CH1, Size: 35)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7DF9: FD 5B
        NOTE NOTE_C, DURATION_20                               ;#7DFB: 90
        NOTE NOTE_C, DURATION_10                               ;#7DFC: 70
        NOTE NOTE_C, DURATION_10                               ;#7DFD: 70
        NOTE NOTE_C, DURATION_20                               ;#7DFE: 90
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DFF: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7E01: 7B
        NOTE NOTE_G, DURATION_10                               ;#7E02: 77
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7E03: FD 59
        NOTE NOTE_C, DURATION_30                               ;#7E05: B0
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7E06: FD 5A
        NOTE NOTE_C, DURATION_10                               ;#7E08: 70
        NOTE NOTE_C, DURATION_30                               ;#7E09: B0
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7E0A: FD 59
        NOTE NOTE_C, DURATION_10                               ;#7E0C: 70
        NOTE NOTE_C, DURATION_20                               ;#7E0D: 90
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7E0E: FD 5A
        NOTE NOTE_G, DURATION_10                               ;#7E10: 77
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7E11: FD 59
        NOTE NOTE_C, DURATION_10                               ;#7E13: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7E14: FD 5A
        NOTE NOTE_B, DURATION_20                               ;#7E16: 9B
        NOTE NOTE_F, DURATION_10                               ;#7E17: 75
        NOTE NOTE_G, DURATION_10                               ;#7E18: 77
        NOTE NOTE_G, DURATION_60                               ;#7E19: D7
        NOTE NOTE_HOLD, DURATION_16                            ;#7E1A: 1C
        db      0FFh                                           ;#7E1B: FF

SOUND_DATA_TIME_OUT_CH2:
        ; Data for Sound 14 (Time Out CH2, Size: 19)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7E1C: FD 5B
        NOTE NOTE_G, DURATION_20                               ;#7E1E: 97
        NOTE NOTE_E, DURATION_20                               ;#7E1F: 94
        NOTE NOTE_G, DURATION_20                               ;#7E20: 97
        NOTE NOTE_E, DURATION_20                               ;#7E21: 94
        NOTE NOTE_A, DURATION_20                               ;#7E22: 99
        NOTE NOTE_F, DURATION_20                               ;#7E23: 95
        NOTE NOTE_A, DURATION_20                               ;#7E24: 99
        NOTE NOTE_F, DURATION_20                               ;#7E25: 95
        NOTE NOTE_G, DURATION_20                               ;#7E26: 97
        NOTE NOTE_E, DURATION_20                               ;#7E27: 94
        NOTE NOTE_G, DURATION_20                               ;#7E28: 97
        NOTE NOTE_F, DURATION_20                               ;#7E29: 95
        NOTE NOTE_G, DURATION_20                               ;#7E2A: 97
        NOTE NOTE_G, DURATION_20                               ;#7E2B: 97
        NOTE NOTE_G, DURATION_20                               ;#7E2C: 97
        NOTE NOTE_HOLD, DURATION_20                            ;#7E2D: 9C
        db      0FFh                                           ;#7E2E: FF

SOUND_DATA_STUMBLE:
        ; Data for Sound 8 (Stumble/Seal Bump, Size: 24)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 2                                         ;#7E2F: 22
        SOUND 0Dh, 1EEh                                        ;#7E30: D1 EE
        SOUND 0Dh, 1CCh                                        ;#7E32: D1 CC
        SOUND 0Ch, 1EEh                                        ;#7E34: C1 EE
        SOUND 0Bh, 1FFh                                        ;#7E36: B1 FF
        SOUND 0Ah, 199h                                        ;#7E38: A1 99
        SOUND 9, 188h                                          ;#7E3A: 91 88
        SOUND 8, 177h                                          ;#7E3C: 81 77
        SOUND 7, 166h                                          ;#7E3E: 71 66
        SOUND 6, 177h                                          ;#7E40: 61 77
        SOUND 5, 188h                                          ;#7E42: 51 88
        SOUND 4, 199h                                          ;#7E44: 41 99
        db      0FFh                                           ;#7E46: FF

PADDING:
        ; ROM padding to 16KB boundary
        defs    8000h - $, 0FFh                                ;#7E47
