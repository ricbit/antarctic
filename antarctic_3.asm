; Antarctic Adventure (MSX, Konami, 1984, third release)
; Disassembled by Ricardo Bittencourt (bluepenguin@gmail.com)
; Last update at 2026-04-27
;
	output "antarctic_3.rom"
	org 04000h

VRAM_SAT_BASE                    equ     03B00h    ; Sprite Attribute Table base in VRAM (32 entries x 4 bytes)
GFX_BANK2_PATTERN_PART3          equ     05C2Ch    ; Pattern Data Bank 2
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
BIOS_HOOKS                       equ     0FD00h    ; MSX BIOS hook table base (200h bytes of vectors)
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
        ld      hl,BIOS_HOOKS                                  ;#4013: 21 00 FD
        ld      de,BIOS_HOOKS+1                                ;#4016: 11 01 FD
        ld      bc,200h                                        ;#4019: 01 00 02
        ld      (hl),0C9h                                      ;#401C: 36 C9
        ldir                                                   ;#401E: ED B0
        ld      a,0C3h                                         ;#4020: 3E C3
        ld      (HKEYI),a                                      ;#4022: 32 9A FD
        ld      hl,INTERRUPT_HANDLER                           ;#4025: 21 5D 40
        ld      (HKEYI+1),hl                                   ;#4028: 22 9B FD
        ld      sp,STACK                                       ;#402B: 31 00 E4
        ld      hl,GAME_STATE                                  ;#402E: 21 00 E0
        ld      de,GAME_STATE+1                                ;#4031: 11 01 E0
        ld      bc,7FFh                                        ;#4034: 01 FF 07
        ld      (hl),0                                         ;#4037: 36 00
        ldir                                                   ;#4039: ED B0
        ld      a,1                                            ;#403B: 3E 01
        ld      (VBLANK_BUSY_FLAG),a                           ;#403D: 32 05 E0
        call    INIT_HARDWARE                                  ;#4040: CD 9A 44
        di                                                     ;#4043: F3
        xor     a                                              ;#4044: AF
        ld      (VBLANK_BUSY_FLAG),a                           ;#4045: 32 05 E0
        inc     a                                              ;#4048: 3C
        ld      (GAME_STATE),a                                 ;#4049: 32 00 E0
        ld      hl,COPY_PROTECTION                             ;#404C: 21 1F 41
        ld      de,JUMP_TABLE_DISPATCHER                       ;#404F: 11 B2 40
        ld      bc,3                                           ;#4052: 01 03 00
        ldir                                                   ;#4055: ED B0
        call    BIOS_RDVDP                                     ;#4057: CD 3E 01
        ei                                                     ;#405A: FB
WAIT_FOR_INTERRUPT:
        ; Idle loop waiting for interrupt
        jr      WAIT_FOR_INTERRUPT                             ;#405B: 18 FE

INTERRUPT_HANDLER:
        ; Core interupt and timing handler
        push    af                                             ;#405D: F5
        push    bc                                             ;#405E: C5
        push    de                                             ;#405F: D5
        push    hl                                             ;#4060: E5
        di                                                     ;#4061: F3
        call    BIOS_RDVDP                                     ;#4062: CD 3E 01
        ld      a,(GAME_STATE)                                 ;#4065: 3A 00 E0
        or      a                                              ;#4068: B7
        jr      z,MAIN_LOOP_ENTRY                              ;#4069: 28 03
        call    PROCESS_SOUND                                  ;#406B: CD 30 7A
MAIN_LOOP_ENTRY:
        ; Main loop wait/dispatch entry
        ld      a,(GAME_STATE)                                 ;#406E: 3A 00 E0
        cp      ID_STATE_12                                    ;#4071: FE 0C
        jr      nc,SET_VBLANK_BUSY                             ;#4073: 30 1C
        ld      a,(PENGUIN_FALL_TIMER)                         ;#4075: 3A 40 E1
        ld      hl,PENGUIN_STUN_TIMER                          ;#4078: 21 42 E1
        add     a,(hl)                                         ;#407B: 86
        jr      nz,CHECK_TIMER_UPDATE                          ;#407C: 20 03
        call    UPDATE_PENGUIN_ANIMATION                       ;#407E: CD C3 4C
CHECK_TIMER_UPDATE:
        ; Checks if half-second timer needs updating
        call    UPDATE_GAME_TIMER                              ;#4081: CD 71 46
        ld      a,(SAT_MIRROR + SPRITE_PENGUIN + 8 + ATTR_X)   ;#4084: 3A 81 E0
        bit     7,a                                            ;#4087: CB 7F
        ld      a,0                                            ;#4089: 3E 00
        jr      z,UPDATE_SIDE_FLAG                             ;#408B: 28 01
        inc     a                                              ;#408D: 3C
UPDATE_SIDE_FLAG:
        ; Updates the penguin's screen side flag
        ld      (PENGUIN_SIDE_FLAG),a                          ;#408E: 32 FC E0
SET_VBLANK_BUSY:
        ; Sets the VBLANK busy flag
        ld      hl,VBLANK_BUSY_FLAG                            ;#4091: 21 05 E0
        bit     0,(hl)                                         ;#4094: CB 46
        jr      nz,EARLY_RETURN                                ;#4096: 20 14
        ld      (hl),1                                         ;#4098: 36 01
        ei                                                     ;#409A: FB
        call    READ_INPUT                                     ;#409B: CD BC 40
        call    STATE_MACHINE                                  ;#409E: CD 22 41
        di                                                     ;#40A1: F3
        pop     hl                                             ;#40A2: E1
        pop     de                                             ;#40A3: D1
        pop     bc                                             ;#40A4: C1
        xor     a                                              ;#40A5: AF
        ld      (VBLANK_BUSY_FLAG),a                           ;#40A6: 32 05 E0
        pop     af                                             ;#40A9: F1
        ei                                                     ;#40AA: FB
        ret                                                    ;#40AB: C9

EARLY_RETURN:
        ; Returns from interrupt or process
        pop     hl                                             ;#40AC: E1
        pop     de                                             ;#40AD: D1
        pop     bc                                             ;#40AE: C1
        pop     af                                             ;#40AF: F1
        ei                                                     ;#40B0: FB
        ret                                                    ;#40B1: C9

JUMP_TABLE_DISPATCHER:
        ; Dispatcher for inline jump tables (index in A)
        add     a,a                                            ;#40B2: 87
        pop     hl                                             ;#40B3: E1
        call    ADD_HL_A                                       ;#40B4: CD FE 48
        ld      e,(hl)                                         ;#40B7: 5E
        inc     hl                                             ;#40B8: 23
        ld      d,(hl)                                         ;#40B9: 56
        ex      de,hl                                          ;#40BA: EB
        jp      (hl)                                           ;#40BB: E9

READ_INPUT:
        ; Poll Joystick (PSG) or Keyboard (PPI)
        ld      a,(GAME_STATE)                                 ;#40BC: 3A 00 E0
        cp      7                                              ;#40BF: FE 07
        ret     c                                              ;#40C1: D8
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#40C2: 3A 02 E0
        bit     6,a                                            ;#40C5: CB 77
        jr      z,LOAD_DEMO_PLAY_DATA                          ;#40C7: 28 3A
        bit     4,a                                            ;#40C9: CB 67
        jr      nz,READ_KEYBOARD_AS_JOYSTICK                   ;#40CB: 20 10
        ld      a,0Eh                                          ;#40CD: 3E 0E
        call    BIOS_RDPSG                                     ;#40CF: CD 96 00
        cpl                                                    ;#40D2: 2F
        and     3Fh                                            ;#40D3: E6 3F
STORE_INPUT_AND_RET:
        ; Stores input and returns
        ld      hl,CUR_INPUT_KEYS                              ;#40D5: 21 09 E0
        ld      c,(hl)                                         ;#40D8: 4E
        ld      (hl),a                                         ;#40D9: 77
        dec     hl                                             ;#40DA: 2B
        ld      (hl),c                                         ;#40DB: 71
        ret                                                    ;#40DC: C9

READ_KEYBOARD_AS_JOYSTICK:
        ; Reads cursor keys and space, emulating joystick
        ld      a,7                                            ;#40DD: 3E 07
        call    BIOS_SNSMAT                                    ;#40DF: CD 41 01
        cpl                                                    ;#40E2: 2F
        rrca                                                   ;#40E3: 0F
        and     20h                                            ;#40E4: E6 20
        ld      e,a                                            ;#40E6: 5F
        ld      a,8                                            ;#40E7: 3E 08
        call    BIOS_SNSMAT                                    ;#40E9: CD 41 01
        cpl                                                    ;#40EC: 2F
        rrca                                                   ;#40ED: 0F
        rrca                                                   ;#40EE: 0F
        ld      b,a                                            ;#40EF: 47
        and     4                                              ;#40F0: E6 04
        or      e                                              ;#40F2: B3
        ld      c,a                                            ;#40F3: 4F
        ld      a,b                                            ;#40F4: 78
        rrca                                                   ;#40F5: 0F
        rrca                                                   ;#40F6: 0F
        ld      b,a                                            ;#40F7: 47
        and     18h                                            ;#40F8: E6 18
        or      c                                              ;#40FA: B1
        ld      c,a                                            ;#40FB: 4F
        ld      a,b                                            ;#40FC: 78
        rrca                                                   ;#40FD: 0F
        and     3                                              ;#40FE: E6 03
        or      c                                              ;#4100: B1
        jr      STORE_INPUT_AND_RET                            ;#4101: 18 D2

LOAD_DEMO_PLAY_DATA:
        ; Read an input from the demo play data
        ld      de,(INPUT_DEMO_PLAY_PTR)                       ;#4103: ED 5B EC E0
        ld      hl,DEMO_PLAY_TIMING_COUNTER                    ;#4107: 21 EB E0
        inc     (hl)                                           ;#410A: 34
        ld      a,(hl)                                         ;#410B: 7E
        and     1Fh                                            ;#410C: E6 1F
        jr      nz,RETURN_CURRENT_INPUT                        ;#410E: 20 08
        ld      a,(de)                                         ;#4110: 1A
        inc     de                                             ;#4111: 13
        ld      (INPUT_DEMO_PLAY_PTR),de                       ;#4112: ED 53 EC E0
        jr      STORE_INPUT_AND_RET                            ;#4116: 18 BD

RETURN_CURRENT_INPUT:
        ; Input routine exit path returning current keys
        ld      a,(CUR_INPUT_KEYS)                             ;#4118: 3A 09 E0
        and     0Fh                                            ;#411B: E6 0F
        jr      STORE_INPUT_AND_RET                            ;#411D: 18 B6

COPY_PROTECTION:
        ; Crashes if running from RAM
        jp      0                                              ;#411F: C3 00 00

STATE_MACHINE:
        ; Main game state machine loop and frame counter update
        ld      hl,FRAME_COUNTER                               ;#4122: 21 03 E0
        inc     (hl)                                           ;#4125: 34
        call    POLL_CONTROLLER_SELECT                         ;#4126: CD 33 44
        ld      a,(GAME_STATE)                                 ;#4129: 3A 00 E0
        call    JUMP_TABLE_DISPATCHER                          ;#412C: CD B2 40
        dw      DUMMY_RET                                      ;#412F: 4F 41
        dw      GAME_STATE_1_HANDLER                           ;#4131: 50 41
        dw      GAME_STATE_2_HANDLER                           ;#4133: 66 41
        dw      GAME_STATE_3_HANDLER                           ;#4135: 78 41
        dw      GAME_STATE_4_HANDLER                           ;#4137: 83 41
        dw      GAME_STATE_5_HANDLER                           ;#4139: 91 41
        dw      GAME_STATE_6_HANDLER                           ;#413B: 99 41
        dw      GAME_STATE_7_HANDLER                           ;#413D: A0 41
        dw      GAME_STATE_8_HANDLER                           ;#413F: EF 41
        dw      GAME_STATE_9_HANDLER                           ;#4141: 5B 42
        dw      GAME_STATE_10_HANDLER                          ;#4143: 9D 42
        dw      GAME_STATE_11_HANDLER                          ;#4145: B6 42
        dw      GAME_STATE_12_HANDLER                          ;#4147: DC 42
        dw      GAME_STATE_13_HANDLER                          ;#4149: 01 43
        dw      GAME_STATE_14_HANDLER                          ;#414B: 12 43
        dw      GAME_STATE_15_HANDLER                          ;#414D: 08 49

DUMMY_RET:
        ; Simple RET instruction
        ret                                                    ;#414F: C9

GAME_STATE_1_HANDLER:
        ; Game state 1: Init VRAM
        call    INIT_ALL_VDP_PLANES                            ;#4150: CD 8A 58
        ld      a,0Eh                                          ;#4153: 3E 0E
        ld      (VDP_TEMP_AREA),a                              ;#4155: 32 0A E0
        ld      hl,0                                           ;#4158: 21 00 00
        ld      (KONAMI_LOGO_ROW_PTR),hl                       ;#415B: 22 0E E0
        LOAD_VRAM_COLOR b, COLOR_GRAY, COLOR_DARK_BLUE         ;#415E: 06 E4
        call    SET_BACKGROUND_COLOR                           ;#4160: CD E7 44
        jp      INCREMENT_STATE                                ;#4163: C3 0E 44

GAME_STATE_2_HANDLER:
        ; Game state 2: Konami opening scroll
        ld      a,(FRAME_COUNTER)                              ;#4166: 3A 03 E0
        rra                                                    ;#4169: 1F
        ret     nc                                             ;#416A: D0
        call    KONAMI_OPENING_ANIMATION                       ;#416B: CD 96 48
        ret     nz                                             ;#416E: C0
        ld      hl,MSG_SOFTWARE                                ;#416F: 21 39 58
        call    DECOMPRESS_VRAM_INDIRECT                       ;#4172: CD 60 45
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#4175: C3 09 44

GAME_STATE_3_HANDLER:
        ; Game state 3: Pause between openings
        ld      hl,WAIT_TIMER                                  ;#4178: 21 04 E0
        dec     (hl)                                           ;#417B: 35
        ret     nz                                             ;#417C: C0
        call    INIT_TITLE_BACKGROUND                          ;#417D: CD 43 48
        jp      INCREMENT_STATE_WITH_GIVEN_DELAY               ;#4180: C3 0B 44

GAME_STATE_4_HANDLER:
        ; Game state 4: Reveal game logo
        call    TITLE_WINDOW_ANIMATION                         ;#4183: CD 64 48
        ret     c                                              ;#4186: D8
        ld      hl,MSG_PLAY_SELECT                             ;#4187: 21 EE 57
        call    WRITE_VRAM_STREAM                              ;#418A: CD A8 45
        xor     a                                              ;#418D: AF
        jp      INCREMENT_STATE_WITH_GIVEN_DELAY               ;#418E: C3 0B 44

GAME_STATE_5_HANDLER:
        ; Game state 5: Post-logo delay
        ld      hl,WAIT_TIMER                                  ;#4191: 21 04 E0
        dec     (hl)                                           ;#4194: 35
        ret     nz                                             ;#4195: C0
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#4196: C3 09 44

GAME_STATE_6_HANDLER:
        ; Game state 6: Clear sprites and wait for VRAM update
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#4199: CD CB 45
        ret     p                                              ;#419C: F0
        jp      INCREMENT_STATE                                ;#419D: C3 0E 44

GAME_STATE_7_HANDLER:
        ; Game state 7: Prepare demo play
        ld      a,(GAME_SUBSTATE)                              ;#41A0: 3A 01 E0
        call    JUMP_TABLE_DISPATCHER                          ;#41A3: CD B2 40
        dw      INIT_DEMO_PLAY                                 ;#41A6: AC 41
        dw      PREPARE_DEMO_PLAY                              ;#41A8: C3 41
        dw      FINISH_DEMO_PLAY                               ;#41AA: E4 41

INIT_DEMO_PLAY:
        ; Sets up input flags and pointers for demo-play startup
        call    INIT_RAM_AND_VRAM                              ;#41AC: CD 63 44
        ld      hl,INPUT_DEVICE_FLAGS                          ;#41AF: 21 02 E0
        res     6,(hl)                                         ;#41B2: CB B6
        ; 73Ch (1852) ticks at 60 Hz ≈ 30.9 s — demo-play replay length.
        ld      hl,73Ch                                        ;#41B4: 21 3C 07
        ld      (STAGE_DEMO_PLAY_TIMER),hl                     ;#41B7: 22 EE E0
        ld      hl,INPUT_DEMO_PLAY_DATA                        ;#41BA: 21 4A 58
        ld      (INPUT_DEMO_PLAY_PTR),hl                       ;#41BD: 22 EC E0
        jp      GAME_STATE_9_HANDLER                           ;#41C0: C3 5B 42

PREPARE_DEMO_PLAY:
        ; Draws first section of penguin during demo-play sequence
        ld      hl,KONAMI_COPYRIGHT_TEXT+2                     ;#41C3: 21 E1 57
        LOAD_NAME_TABLE de, 6, 10                              ;#41C6: 11 CA 38
        call    WRITE_VRAM_STREAM_WITH_OFFSET                  ;#41C9: CD AC 45
        ld      a,1                                            ;#41CC: 3E 01
        ld      (TIMER_ACTIVE_FLAG),a                          ;#41CE: 32 33 E1
        call    MAIN_GAME_ENGINE                               ;#41D1: CD 4A 4B
        ld      hl,(STAGE_DEMO_PLAY_TIMER)                     ;#41D4: 2A EE E0
        dec     hl                                             ;#41D7: 2B
        ld      (STAGE_DEMO_PLAY_TIMER),hl                     ;#41D8: 22 EE E0
        ld      a,h                                            ;#41DB: 7C
        or      l                                              ;#41DC: B5
        ret     nz                                             ;#41DD: C0
        ld      (TIMER_ACTIVE_FLAG),a                          ;#41DE: 32 33 E1
        jp      INCREMENT_SUBSTATE_WITH_FIXED_DELAY            ;#41E1: C3 17 44

FINISH_DEMO_PLAY:
        ; Clears sprites and transitions to next game state
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#41E4: CD CB 45
        ret     p                                              ;#41E7: F0
        xor     a                                              ;#41E8: AF
        ld      (GAME_STATE),a                                 ;#41E9: 32 00 E0
        jp      INCREMENT_STATE                                ;#41EC: C3 0E 44

GAME_STATE_8_HANDLER:
        ; Game state 8: Demo play mode
        ld      a,(GAME_SUBSTATE)                              ;#41EF: 3A 01 E0
        call    JUMP_TABLE_DISPATCHER                          ;#41F2: CD B2 40
        dw      AUTO_DEMO_PLAY_RESTART                         ;#41F5: FD 41
        dw      TITLE_MENU_INIT                                ;#41F7: 0E 42
        dw      TITLE_MENU_BLINK_UPDATE                        ;#41F9: 21 42
        dw      START_GAME_PREP                                ;#41FB: 51 42

AUTO_DEMO_PLAY_RESTART:
        ; Sets up demo mode and restarts game intro sequence
        call    CLEAR_SPRITES                                  ;#41FD: CD 00 46
        call    CLEAR_NAME_TABLE                               ;#4200: CD B5 44
        call    INIT_TITLE_BACKGROUND                          ;#4203: CD 43 48
        ld      a,CMD_SOUND_INTRO_MUSIC                        ;#4206: 3E 92
        call    PLAY_SOUND_SAFE                                ;#4208: CD C9 79
        jp      INCREMENT_SUBSTATE                             ;#420B: C3 1C 44

TITLE_MENU_INIT:
        ; Initializes blink timer for the "PLAY SELECT" menu
        call    TITLE_WINDOW_ANIMATION                         ;#420E: CD 64 48
        jr      c,TITLE_MENU_INIT                              ;#4211: 38 FB
        ld      hl,MSG_PLAY_SELECT                             ;#4213: 21 EE 57
        call    WRITE_VRAM_STREAM                              ;#4216: CD A8 45
        ld      a,6                                            ;#4219: 3E 06
        ld      (TITLE_BLINK_TIMER),a                          ;#421B: 32 8D E1
        jp      INCREMENT_SUBSTATE                             ;#421E: C3 1C 44

TITLE_MENU_BLINK_UPDATE:
        ; Oscillates the "PLAY SELECT" message visibility
        ld      hl,FRAME_COUNTER                               ;#4221: 21 03 E0
        ld      a,(hl)                                         ;#4224: 7E
        and     7                                              ;#4225: E6 07
        ret     nz                                             ;#4227: C0
        ld      a,(hl)                                         ;#4228: 7E
        bit     3,a                                            ;#4229: CB 5F
        jr      nz,DRAW_PLAY_SELECT                            ;#422B: 20 16
        LOAD_NAME_TABLE de, 16, 0                              ;#422D: 11 00 3A
        ld      bc,20h                                         ;#4230: 01 20 00
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4233: 3A 02 E0
        and     10h                                            ;#4236: E6 10
        rlca                                                   ;#4238: 07
        rlca                                                   ;#4239: 07
        call    ADD_DE_A                                       ;#423A: CD 03 49
        ld      a,1                                            ;#423D: 3E 01
        call    FILL_VRAM                                      ;#423F: CD FD 44
        ret                                                    ;#4242: C9

DRAW_PLAY_SELECT:
        ; Routine to draw the "PLAY SELECT" text
        ld      hl,MSG_PLAY_SELECT                             ;#4243: 21 EE 57
        call    WRITE_VRAM_STREAM                              ;#4246: CD A8 45
        ld      hl,TITLE_BLINK_TIMER                           ;#4249: 21 8D E1
        dec     (hl)                                           ;#424C: 35
        ret     nz                                             ;#424D: C0
        jp      INCREMENT_SUBSTATE_WITH_FIXED_DELAY            ;#424E: C3 17 44

START_GAME_PREP:
        ; Prepare VRAM/RAM and transition to next game state
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#4251: CD CB 45
        ret     p                                              ;#4254: F0
        call    INIT_RAM_AND_VRAM                              ;#4255: CD 63 44
        jp      INCREMENT_STATE                                ;#4258: C3 0E 44

GAME_STATE_9_HANDLER:
        ; Game state 9: Stage setup and HUD refresh
        ld      a,(CURRENT_STAGE)                              ;#425B: 3A E8 E0
        ld      hl,STAGE_DISTANCE_TABLE                        ;#425E: 21 D9 4A
        add     a,a                                            ;#4261: 87
        add     a,a                                            ;#4262: 87
        call    ADD_HL_A                                       ;#4263: CD FE 48
        ld      e,(hl)                                         ;#4266: 5E
        inc     hl                                             ;#4267: 23
        ld      d,(hl)                                         ;#4268: 56
        inc     hl                                             ;#4269: 23
        ld      (STAGE_DISTANCE_HIGH),de                       ;#426A: ED 53 E6 E0
        ld      e,(hl)                                         ;#426E: 5E
        inc     hl                                             ;#426F: 23
        ld      d,(hl)                                         ;#4270: 56
        ld      a,(CURRENT_STAGE_INDEX)                        ;#4271: 3A E1 E0
        ld      hl,STAGE_COMPLETION_FLAGS                      ;#4274: 21 D5 E0
        call    ADD_HL_A                                       ;#4277: CD FE 48
        ld      a,(hl)                                         ;#427A: 7E
        sub     10h                                            ;#427B: D6 10
        jr      c,SET_REMAINING_DISTANCE                       ;#427D: 38 0C
        daa                                                    ;#427F: 27
        ld      c,a                                            ;#4280: 4F
        ld      a,e                                            ;#4281: 7B
        sub     c                                              ;#4282: 91
        jr      nc,BCD_SUB_CARRY                               ;#4283: 30 04
        daa                                                    ;#4285: 27
        dec     d                                              ;#4286: 15
        jr      FINALIZE_DISTANCE_CALC                         ;#4287: 18 01

BCD_SUB_CARRY:
        ; Handle BCD subtraction carry
        daa                                                    ;#4289: 27
FINALIZE_DISTANCE_CALC:
        ; Finalize BCD distance calculation
        ld      e,a                                            ;#428A: 5F
SET_REMAINING_DISTANCE:
        ; Sets the remaining stage distance in BCD
        ld      (REMANING_TIME_BCD),de                         ;#428B: ED 53 E3 E0
        call    REFRESH_HUD                                    ;#428F: CD BA 46
        call    INIT_ALL_VDP_PLANES                            ;#4292: CD 8A 58
        ld      a,ID_STATE_14                                  ;#4295: 3E 0E
        ld      (GAME_STATE),a                                 ;#4297: 32 00 E0
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#429A: C3 09 44

GAME_STATE_10_HANDLER:
        ; Game state 10: Gameplay init
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#429D: CD CB 45
        ret     p                                              ;#42A0: F0
        call    INIT_GAMEPLAY_VARS                             ;#42A1: CD 01 4B
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#42A4: 3A 02 E0
        bit     6,a                                            ;#42A7: CB 77
        ld      a,CMD_SOUND_MAIN_THEME                         ;#42A9: 3E 8A
        call    nz,PLAY_SOUND_SAFE                             ;#42AB: C4 C9 79
        ld      a,1                                            ;#42AE: 3E 01
        ld      (TIMER_ACTIVE_FLAG),a                          ;#42B0: 32 33 E1
        jp      INCREMENT_STATE                                ;#42B3: C3 0E 44

GAME_STATE_11_HANDLER:
        ; Game state 11: Main gameplay loop
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#42B6: 3A 02 E0
        bit     6,a                                            ;#42B9: CB 77
        jr      z,SET_STATE_INTRO                              ;#42BB: 28 1A
        call    MAIN_GAME_ENGINE                               ;#42BD: CD 4A 4B
        ld      hl,(TIME_UP_FLAG)                              ;#42C0: 2A 0C E0
        ld      a,l                                            ;#42C3: 7D
        add     a,h                                            ;#42C4: 84
        ret     z                                              ;#42C5: C8
        ld      a,l                                            ;#42C6: 7D
        ld      hl,TIMER_ACTIVE_FLAG                           ;#42C7: 21 33 E1
        ld      (hl),0                                         ;#42CA: 36 00
        or      a                                              ;#42CC: B7
        ld      a,ID_STATE_12                                  ;#42CD: 3E 0C
        jr      nz,SET_STATE                                   ;#42CF: 20 02
        ld      a,ID_STATE_14                                  ;#42D1: 3E 0E
SET_STATE:
        ; Store A into GAME_STATE (caller sets A to ID_STATE_12 or ID_STATE_14)
        ld      (GAME_STATE),a                                 ;#42D3: 32 00 E0
        ret                                                    ;#42D6: C9

SET_STATE_INTRO:
        ; Sets game state to Stage Intro (7.1)
        LOAD_SUBSTATE hl, ID_STATE_7, ID_SUBSTATE_1            ;#42D7: 21 07 01
        jr      SET_GAME_STATE_HL                              ;#42DA: 18 32

GAME_STATE_12_HANDLER:
        ; Game state 12: Time out sequence
        xor     a                                              ;#42DC: AF
        ld      (TIME_UP_FLAG),a                               ;#42DD: 32 0C E0
        ld      hl,SAT_MIRROR + SPRITE_CLOUD + ATTR_Y          ;#42E0: 21 B8 E0
        ld      de,4                                           ;#42E3: 11 04 00
        ld      b,4                                            ;#42E6: 06 04
CLEAR_CLOUD_SPRITES_Y:
        ; Clear cloud sprite Y positions (hide off-screen)
        ld      (hl),0E0h                                      ;#42E8: 36 E0
        add     hl,de                                          ;#42EA: 19
        djnz    CLEAR_CLOUD_SPRITES_Y                          ;#42EB: 10 FB
        call    SYNC_SPRITE_ATTRIBUTES_ALL                     ;#42ED: CD E3 66
        ; At this point a=0
        ld      (DISTANCE_EVENT_TICK),a                        ;#42F0: 32 E2 E0
        ld      a,CMD_SOUND_TIME_OUT                           ;#42F3: 3E 8C
        call    PLAY_SOUND_SAFE                                ;#42F5: CD C9 79
        ld      hl,MSG_TIME_OUT                                ;#42F8: 21 2E 58
        call    WRITE_VRAM_STREAM                              ;#42FB: CD A8 45
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#42FE: C3 09 44

GAME_STATE_13_HANDLER:
        ; Game state 13: Wait for time-out sound
        ld      a,(MUSIC_VARS_CH0+MUSIC_DRIVER_CONTROL)        ;#4301: 3A 12 E0
        or      a                                              ;#4304: B7
        ret     nz                                             ;#4305: C0
        ld      hl,INPUT_DEVICE_FLAGS                          ;#4306: 21 02 E0
        res     6,(hl)                                         ;#4309: CB B6
        LOAD_SUBSTATE hl, ID_STATE_7, ID_SUBSTATE_2            ;#430B: 21 07 02
SET_GAME_STATE_HL:
        ; Sets main Game State and Substate from HL
        ld      (GAME_STATE),hl                                ;#430E: 22 00 E0
        ret                                                    ;#4311: C9

GAME_STATE_14_HANDLER:
        ; Game state 14: Goal reached sequence
        ld      a,(GAME_SUBSTATE)                              ;#4312: 3A 01 E0
        call    JUMP_TABLE_DISPATCHER                          ;#4315: CD B2 40
        dw      GOAL_PENGUIN_WALK                              ;#4318: 28 43
        dw      GOAL_PROCESS_SCORE                             ;#431A: 3B 43
        dw      GOAL_WAIT_SOUND_1                              ;#431C: 7B 43
        dw      GOAL_PENGUIN_DANCE                             ;#431E: 89 43
        dw      GOAL_WAIT_UNTIL_MUTE                           ;#4320: A6 43
        dw      GOAL_WAIT_SOUND_2                              ;#4322: D0 43
        dw      GOAL_TALLY_TIMER_BONUS                         ;#4324: D9 43
        dw      GOAL_CLEANUP_AND_EXIT                          ;#4326: 00 44

GOAL_PENGUIN_WALK:
        ; Penguin walking towards the flag
        ld      hl,PENGUIN_INPUT_LOCK_TIMER                    ;#4328: 21 F9 E0
        ld      a,(hl)                                         ;#432B: 7E
        or      a                                              ;#432C: B7
        jp      z,INCREMENT_SUBSTATE                           ;#432D: CA 1C 44
        call    UPDATE_THROTTLED_ANIMATION                     ;#4330: CD 18 4C
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4333: 3A F9 E0
        or      a                                              ;#4336: B7
        ret     nz                                             ;#4337: C0
        jp      INCREMENT_SUBSTATE                             ;#4338: C3 1C 44

GOAL_PROCESS_SCORE:
        ; Preliminary score calculation/resetting
        ld      hl,CURRENT_VISIBLE_STAGE                       ;#433B: 21 E0 E0
        ld      a,(hl)                                         ;#433E: 7E
        add     a,1                                            ;#433F: C6 01
        daa                                                    ;#4341: 27
        ld      (hl),a                                         ;#4342: 77
        inc     hl                                             ;#4343: 23
        ; Now hl points to CURRENT_STAGE_INDEX
        ld      a,(hl)                                         ;#4344: 7E
        ld      c,a                                            ;#4345: 4F
        inc     a                                              ;#4346: 3C
        cp      0Ah                                            ;#4347: FE 0A
        jr      c,GOAL_SKIP_TEXT_INIT                          ;#4349: 38 04
        xor     a                                              ;#434B: AF
        ld      (DISTANCE_EVENT_TICK),a                        ;#434C: 32 E2 E0
GOAL_SKIP_TEXT_INIT:
        ; Skip time-bonus text initialization
        ld      (hl),a                                         ;#434F: 77
        ld      a,c                                            ;#4350: 79
        ld      hl,STAGE_COMPLETION_FLAGS                      ;#4351: 21 D5 E0
        call    ADD_HL_A                                       ;#4354: CD FE 48
        ld      a,(REMANING_TIME_BCD)                          ;#4357: 3A E3 E0
        ld      (hl),a                                         ;#435A: 77
        xor     a                                              ;#435B: AF
        ld      (STAGE_GOAL_FLAG),a                            ;#435C: 32 0D E0
        ld      hl,CURRENT_STAGE                               ;#435F: 21 E8 E0
        inc     (hl)                                           ;#4362: 34
        ld      a,(hl)                                         ;#4363: 7E
        cp      0Ah                                            ;#4364: FE 0A
        jr      nz,GOAL_INIT_VICTORY_PENGUIN                   ;#4366: 20 02
        ld      (hl),0                                         ;#4368: 36 00
GOAL_INIT_VICTORY_PENGUIN:
        ; Initialize penguin position/speed for victory
        ld      a,(PENGUIN_X_POS)                              ;#436A: 3A 79 E0
        ld      h,a                                            ;#436D: 67
        ld      l,1                                            ;#436E: 2E 01
        ld      (VICTORY_WADDLE_STEP),hl                       ;#4370: 22 38 E1
        ld      a,13h                                          ;#4373: 3E 13
        ld      (PENGUIN_SPEED),a                              ;#4375: 32 00 E1
        jp      INCREMENT_SUBSTATE                             ;#4378: C3 1C 44

GOAL_WAIT_SOUND_1:
        ; Wait for initial victory sound to finish
        ld      c,0FFh                                         ;#437B: 0E FF
        call    UPDATE_VICTORY_PENGUIN_ANIM                    ;#437D: CD D9 54
        ret     nz                                             ;#4380: C0
        ld      a,0Ch                                          ;#4381: 3E 0C
        ld      (VICTORY_WADDLE_STEP),a                        ;#4383: 32 38 E1
        jp      INCREMENT_SUBSTATE                             ;#4386: C3 1C 44

GOAL_PENGUIN_DANCE:
        ; Victory dance animation
        ld      c,0                                            ;#4389: 0E 00
        ld      a,(PENGUIN_X_POS)                              ;#438B: 3A 79 E0
        ld      h,a                                            ;#438E: 67
        call    UPDATE_VICTORY_PENGUIN_ANIM                    ;#438F: CD D9 54
        ret     nz                                             ;#4392: C0
        call    INIT_GOAL_SPRITES                              ;#4393: CD C7 66
        call    CYCLE_GOAL_PENGUIN_PATTERNS                    ;#4396: CD 1B 55
        call    INIT_GOAL_GRAPHICS                             ;#4399: CD 7F 55
        ld      a,CMD_SOUND_STAGE_CLEAR                        ;#439C: 3E 8F
        call    PLAY_SOUND_SAFE                                ;#439E: CD C9 79
        ld      a,4                                            ;#43A1: 3E 04
        ld      (GAME_SUBSTATE),a                              ;#43A3: 32 01 E0
GOAL_WAIT_UNTIL_MUTE:
        ; Wait for MUSIC_VARS_CH1 to silence, then update goal flag position
        ld      a,(MUSIC_VARS_CH1)                             ;#43A6: 3A 1A E0
        dec     a                                              ;#43A9: 3D
        ret     nz                                             ;#43AA: C0
        call    UPDATE_GOAL_FLAG_POSITION                      ;#43AB: CD BB 55
        ld      a,(CURRENT_STAGE_INDEX)                        ;#43AE: 3A E1 E0
        or      a                                              ;#43B1: B7
        jr      z,CHECK_VICTORY_DANCE_START                    ;#43B2: 28 04
        cp      2                                              ;#43B4: FE 02
        jr      nz,CONTINUE_GOAL_ANIMATION                     ;#43B6: 20 0D
CHECK_VICTORY_DANCE_START:
        ; Check if victory dance should begin
        ld      a,(VICTORY_DANCE_COUNTER)                      ;#43B8: 3A 3A E1
        cp      0Fh                                            ;#43BB: FE 0F
        jr      nz,CONTINUE_GOAL_ANIMATION                     ;#43BD: 20 06
        call    LOAD_VICTORY_GFX                               ;#43BF: CD 31 55
        jp      INCREMENT_SUBSTATE                             ;#43C2: C3 1C 44

CONTINUE_GOAL_ANIMATION:
        ; Continue updating goal animation (victory dance)
        call    UPDATE_VICTORY_DANCE                           ;#43C5: CD 1F 55
        ld      a,(VICTORY_DANCE_COUNTER)                      ;#43C8: 3A 3A E1
        cp      10h                                            ;#43CB: FE 10
        ret     nz                                             ;#43CD: C0
        jr      INCREMENT_SUBSTATE                             ;#43CE: 18 4C

GOAL_WAIT_SOUND_2:
        ; Wait for secondary victory sound
        ld      a,(MUSIC_VARS_CH0+MUSIC_DRIVER_CONTROL)        ;#43D0: 3A 12 E0
        or      a                                              ;#43D3: B7
        ret     nz                                             ;#43D4: C0
        ld      a,10h                                          ;#43D5: 3E 10
        jr      INCREMENT_SUBSTATE_WITH_GIVEN_DELAY            ;#43D7: 18 40

GOAL_TALLY_TIMER_BONUS:
        ; Countdown loop to convert remaining time to score
        ld      hl,WAIT_TIMER                                  ;#43D9: 21 04 E0
        ld      a,(hl)                                         ;#43DC: 7E
        or      a                                              ;#43DD: B7
        jr      z,PROCESS_SCORE_TALLY                          ;#43DE: 28 02
        dec     (hl)                                           ;#43E0: 35
        ret                                                    ;#43E1: C9

PROCESS_SCORE_TALLY:
        ; Handle score addition and sound effect
        ld      a,(FRAME_COUNTER)                              ;#43E2: 3A 03 E0
        and     3                                              ;#43E5: E6 03
        ret     nz                                             ;#43E7: C0
        ld      hl,(REMANING_TIME_BCD)                         ;#43E8: 2A E3 E0
        ld      a,h                                            ;#43EB: 7C
        add     a,l                                            ;#43EC: 85
        jr      z,INCREMENT_SUBSTATE_WITH_FIXED_DELAY          ;#43ED: 28 28
        ld      c,0                                            ;#43EF: 0E 00
        call    DECREMENT_DISTANCE                             ;#43F1: CD 8A 46
        ld      de,100h                                        ;#43F4: 11 00 01
        call    ADD_SCORE                                      ;#43F7: CD 2D 46
        ld      a,ID_SOUND_GOAL_TICK                           ;#43FA: 3E 01
        call    PLAY_SOUND_SAFE                                ;#43FC: CD C9 79
        ret                                                    ;#43FF: C9

GOAL_CLEANUP_AND_EXIT:
        ; Final cleanup before transitioning out of State 14
        call    CLEAR_SPRITES_AND_UPDATE_VRAM                  ;#4400: CD CB 45
        ret     p                                              ;#4403: F0
        ld      a,ID_STATE_8                                   ;#4404: 3E 08
        ld      (GAME_STATE),a                                 ;#4406: 32 00 E0
INCREMENT_STATE_WITH_FIXED_DELAY:
        ; Transition to game after controller selection
        ld      a,50h                                          ;#4409: 3E 50
INCREMENT_STATE_WITH_GIVEN_DELAY:
        ; Increments game state with delay in A
        ld      (WAIT_TIMER),a                                 ;#440B: 32 04 E0
INCREMENT_STATE:
        ; Increments game state
        ld      hl,GAME_STATE                                  ;#440E: 21 00 E0
        inc     (hl)                                           ;#4411: 34
        xor     a                                              ;#4412: AF
        ld      (GAME_SUBSTATE),a                              ;#4413: 32 01 E0
        ret                                                    ;#4416: C9

INCREMENT_SUBSTATE_WITH_FIXED_DELAY:
        ; Increments substate if enough frames passed
        ld      a,50h                                          ;#4417: 3E 50
INCREMENT_SUBSTATE_WITH_GIVEN_DELAY:
        ; Increments substate if A frames passed
        ld      (WAIT_TIMER),a                                 ;#4419: 32 04 E0
INCREMENT_SUBSTATE:
        ; Increments game substate
        ld      hl,GAME_SUBSTATE                               ;#441C: 21 01 E0
        inc     (hl)                                           ;#441F: 34
        ret                                                    ;#4420: C9

DRAW_CONTROLLER_INDICATOR:
        ; Update indicator (Joystick vs Keyboard) on screen (unused)?
        call    WRITE_VRAM_STREAM                              ;#4421: CD A8 45
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4424: 3A 02 E0
        rlca                                                   ;#4427: 07
        and     1                                              ;#4428: E6 01
        add     a,31h                                          ;#442A: C6 31
        LOAD_NAME_TABLE de, 9, 19                              ;#442C: 11 33 39
        call    WRITE_VRAM_BYTE                                ;#442F: CD D0 48
        ret                                                    ;#4432: C9

POLL_CONTROLLER_SELECT:
        ; Checks for '1' or '2' keys to select input device
        ld      a,(SELECT_CONTROLLER_DISABLED)                 ;#4433: 3A 3B E1
        or      a                                              ;#4436: B7
        ret     nz                                             ;#4437: C0
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#4438: 3A 02 E0
        bit     6,a                                            ;#443B: CB 77
        ret     nz                                             ;#443D: C0
        ld      a,0                                            ;#443E: 3E 00
        call    BIOS_SNSMAT                                    ;#4440: CD 41 01
        cpl                                                    ;#4443: 2F
        and     6                                              ;#4444: E6 06
        ld      b,40h                                          ;#4446: 06 40
        cp      2                                              ;#4448: FE 02
        jr      z,POLL_CONTROLLER_DONE                         ;#444A: 28 05
        ld      b,50h                                          ;#444C: 06 50
        cp      4                                              ;#444E: FE 04
        ret     nz                                             ;#4450: C0
POLL_CONTROLLER_DONE:
        ; Controller selection finished
        xor     a                                              ;#4451: AF
        ld      (TIMER_ACTIVE_FLAG),a                          ;#4452: 32 33 E1
        ld      a,b                                            ;#4455: 78
        ld      (INPUT_DEVICE_FLAGS),a                         ;#4456: 32 02 E0
        pop     hl                                             ;#4459: E1
        ld      a,7                                            ;#445A: 3E 07
        ld      (GAME_STATE),a                                 ;#445C: 32 00 E0
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#445F: C3 09 44
        ret                                                    ;#4462: C9

INIT_RAM_AND_VRAM:
        ; Clears work RAM and initializes VDP tables
        ld      hl,CURRENT_SCORE_BCD + BCD_LOW                 ;#4463: 21 43 E0
        ld      de,CURRENT_SCORE_BCD + BCD_LOW + 1             ;#4466: 11 44 E0
        ld      bc,100h                                        ;#4469: 01 00 01
        ld      (hl),0                                         ;#446C: 36 00
        ldir                                                   ;#446E: ED B0
        ld      hl,DEFAULT_GAME_VARS                           ;#4470: 21 91 44
        ld      de,CURRENT_VISIBLE_STAGE                       ;#4473: 11 E0 E0
        ld      bc,9                                           ;#4476: 01 09 00
        ldir                                                   ;#4479: ED B0
        LOAD_VRAM_ADDRESS de, 900h                             ;#447B: 11 00 09
        ld      bc,100h                                        ;#447E: 01 00 01
        ld      a,0F0h                                         ;#4481: 3E F0
        call    FILL_VRAM                                      ;#4483: CD FD 44
        ; Repeat for each of the 10 (0Ah) stages.
        ld      b,0Ah                                          ;#4486: 06 0A
        ld      hl,STAGE_COMPLETION_FLAGS                      ;#4488: 21 D5 E0
INIT_STAGE_COMPLETION_FLAGS:
        ; Initialize stage completion flags to default value
        ld      (hl),5                                         ;#448B: 36 05
        inc     hl                                             ;#448D: 23
        djnz    INIT_STAGE_COMPLETION_FLAGS                    ;#448E: 10 FB
        ret                                                    ;#4490: C9

DEFAULT_GAME_VARS:
        ; Initial values for E0E0h-E0E8h (Flags, Timers)
        db      1 ; CURRENT_VISIBLE_STAGE initial value        ;#4491: 01
        db      0 ; CURRENT_STAGE_INDEX initial value (stage 0) ;#4492: 00
        db      0 ; DISTANCE_EVENT_TICK initial value          ;#4493: 00
        dw      200h ; REMANING_TIME_BCD initial value (start distance) ;#4494: 00 02
        dw      1700h ; STAGE_DISTANCE_BCD initial value       ;#4496: 00 17
        db      0 ; MAP_PROGRESS_LIMIT initial value           ;#4498: 00
        db      0 ; CURRENT_STAGE initial value                ;#4499: 00

INIT_HARDWARE:
        ; Initialize VDP, PSG, and clear VRAM
        call    INIT_VDP_REGISTERS                             ;#449A: CD C3 44
        ld      a,7                                            ;#449D: 3E 07
        ld      e,0B8h                                         ;#449F: 1E B8
        call    BIOS_WRTPSG                                    ;#44A1: CD 93 00
        call    INIT_PSG_PORT_B                                ;#44A4: CD 15 46
        call    MUTE_PSG                                       ;#44A7: CD BD 44
        LOAD_VRAM_ADDRESS de, 0                                ;#44AA: 11 00 00
        ld      bc,VRAM_SIZE                                   ;#44AD: 01 00 40
ZERO_FILL_VRAM_RANGE:
        ; Set A=0 and fill VRAM for DE/BC range
        xor     a                                              ;#44B0: AF
        call    FILL_VRAM                                      ;#44B1: CD FD 44
        ret                                                    ;#44B4: C9

CLEAR_NAME_TABLE:
        ; Clear the VRAM name table (3800h-3AFFh)
        LOAD_NAME_TABLE de, 0, 0                               ;#44B5: 11 00 38
        ld      bc,300h                                        ;#44B8: 01 00 03
        jr      ZERO_FILL_VRAM_RANGE                           ;#44BB: 18 F3

MUTE_PSG:
        ; Stop sound
        ld      a,CMD_SOUND_STOP                               ;#44BD: 3E 95
        call    PLAY_SOUND_SAFE                                ;#44BF: CD C9 79
        ret                                                    ;#44C2: C9

INIT_VDP_REGISTERS:
        ; Copy VDP register values to RAM mirror and write to VDP
        ld      hl,INITIAL_VDP_REGISTERS                       ;#44C3: 21 DF 44
        ld      de,MIRROR_VDP_REGISTERS                        ;#44C6: 11 38 E0
        ld      bc,8                                           ;#44C9: 01 08 00
        ldir                                                   ;#44CC: ED B0
        ld      hl,MIRROR_VDP_REGISTERS                        ;#44CE: 21 38 E0
        ld      d,8                                            ;#44D1: 16 08
        ld      c,0                                            ;#44D3: 0E 00
INIT_VDP_REG_LOOP:
        ; Loop writing VDP registers from mirror
        ld      b,(hl)                                         ;#44D5: 46
        call    BIOS_WRTVDP                                    ;#44D6: CD 47 00
        inc     hl                                             ;#44D9: 23
        inc     c                                              ;#44DA: 0C
        dec     d                                              ;#44DB: 15
        jr      nz,INIT_VDP_REG_LOOP                           ;#44DC: 20 F7
        ret                                                    ;#44DE: C9

INITIAL_VDP_REGISTERS:
        ; Initial VDP register values
        ; Format: FORMAT_VDP_REGISTERS
        db      2, 0E2h, 0Eh, 7Fh, 7, 76h, 3, 0E4h ; VDP Registers initialization table  ;#44DF: 02 E2 0E 7F 07 76 03 E4

SET_BACKGROUND_COLOR:
        ; Write value in B to VDP register 7 (backdrop/text color)
        ld      c,7                                            ;#44E7: 0E 07
        jp      BIOS_WRTVDP                                    ;#44E9: C3 47 00

COPY_RAM_TO_VRAM:
        ; Copy RAM to VRAM
        call    SET_VDP                                        ;#44EC: CD E2 48
        di                                                     ;#44EF: F3
COPY_RAM_TO_VRAM_LOOP:
        ; Loop copying RAM to VRAM
        ld      a,(hl)                                         ;#44F0: 7E
        exx                                                    ;#44F1: D9
        out     (c),a                                          ;#44F2: ED 79
        exx                                                    ;#44F4: D9
        inc     hl                                             ;#44F5: 23
        dec     bc                                             ;#44F6: 0B
        ld      a,b                                            ;#44F7: 78
        or      c                                              ;#44F8: B1
        jr      nz,COPY_RAM_TO_VRAM_LOOP                       ;#44F9: 20 F5
        ei                                                     ;#44FB: FB
        ret                                                    ;#44FC: C9

FILL_VRAM:
        ; Fill VRAM with value
        di                                                     ;#44FD: F3
        ld      h,a                                            ;#44FE: 67
        set     6,d                                            ;#44FF: CB F2
        call    SET_VDP                                        ;#4501: CD E2 48
        res     6,d                                            ;#4504: CB B2
FILL_VRAM_LOOP:
        ; Loop filling VRAM
        ld      a,h                                            ;#4506: 7C
        exx                                                    ;#4507: D9
        out     (c),a                                          ;#4508: ED 79
        exx                                                    ;#450A: D9
        dec     bc                                             ;#450B: 0B
        ld      a,b                                            ;#450C: 78
        or      c                                              ;#450D: B1
        jr      nz,FILL_VRAM_LOOP                              ;#450E: 20 F6
        ei                                                     ;#4510: FB
        ret                                                    ;#4511: C9

FILL_VRAM_STREAM:
        ; Fills VRAM regions from a character-based stream (value, count, addr)
        ld      a,(hl)                                         ;#4512: 7E
        inc     hl                                             ;#4513: 23
        ld      (VRAM_FILL_VALUE),a                            ;#4514: 32 DF E0
        ld      d,39h                                          ;#4517: 16 39
FILL_VRAM_STREAM_LOOP:
        ; Loop over stream entries for VRAM fill
        ld      c,(hl)                                         ;#4519: 4E
        inc     hl                                             ;#451A: 23
        xor     a                                              ;#451B: AF
        cp      c                                              ;#451C: B9
        ret     z                                              ;#451D: C8
        ld      b,a                                            ;#451E: 47
        ld      e,(hl)                                         ;#451F: 5E
        inc     hl                                             ;#4520: 23
        ld      a,e                                            ;#4521: 7B
        cp      20h                                            ;#4522: FE 20
        jr      nc,FILL_VRAM_STREAM_ITER                       ;#4524: 30 01
        inc     d                                              ;#4526: 14
FILL_VRAM_STREAM_ITER:
        ; Next entry in VRAM fill stream
        ld      a,(VRAM_FILL_VALUE)                            ;#4527: 3A DF E0
        push    hl                                             ;#452A: E5
        push    de                                             ;#452B: D5
        call    FILL_VRAM                                      ;#452C: CD FD 44
        pop     de                                             ;#452F: D1
        pop     hl                                             ;#4530: E1
        jr      FILL_VRAM_STREAM_LOOP                          ;#4531: 18 E6

WRITE_VRAM_TILES_STREAM:
        ; Writes tiles to VRAM using a custom stream format
        ; For this routine, the sprite attribute table is just more name-table rows.
        ; Stream format overview:
        ; - Byte 0: header `H` (high nibble seeds row base, low 2 bits select VRAM page).
        ; - Then records: [K, data...] where K is E0h-FFh control, data bytes <E0h.
        ; - Terminator: `00h` in the data loop ends the stream.
        ld      a,(hl)                                         ;#4533: 7E
        or      a                                              ;#4534: B7
        ret     z                                              ;#4535: C8
        and     0F0h                                           ;#4536: E6 F0
        ld      c,a                                            ;#4538: 4F
        ; C stores the high nibble of the header.
        ld      a,(hl)                                         ;#4539: 7E
        inc     hl                                             ;#453A: 23
        and     3                                              ;#453B: E6 03
        add     a,78h                                          ;#453D: C6 78
        ld      d,a                                            ;#453F: 57
        ; D stores 38h, 39h, 3Ah, or 3Bh (with VDP write bit encoding applied).
        ld      a,c                                            ;#4540: 79
WRITE_VRAM_TILES_ADDRESS:
        ; Consume control byte and advance row base
        ld      b,(hl)                                         ;#4541: 46
        ; Lower nibble of B selects column.
        inc     hl                                             ;#4542: 23
        ; Increment row by one (times 32).
        ld      a,20h                                          ;#4543: 3E 20
        add     a,c                                            ;#4545: 81
        ld      c,a                                            ;#4546: 4F
        ; C stores the row (times 32), increment D if carry.
        jr      nc,WRITE_VRAM_TILES_NEXT                       ;#4547: 30 01
        inc     d                                              ;#4549: 14
WRITE_VRAM_TILES_NEXT:
        ; Compute DE and set next VRAM write address
        ld      a,c                                            ;#454A: 79
        add     a,b                                            ;#454B: 80
        sub     0E0h                                           ;#454C: D6 E0
        ; E has row * 32 + column.
        ld      e,a                                            ;#454E: 5F
        call    SET_VDP                                        ;#454F: CD E2 48
WRITE_VRAM_TILES_LOOP:
        ; Emit data bytes until next control/terminator
        ; Format of this stream:
        ; - `00h`: terminator, returns.
        ; - `E0h-FFh`: control, change address.
        ; - `01h-DFh`: writes to VRAM sequentially.
        ld      a,(hl)                                         ;#4552: 7E
        or      a                                              ;#4553: B7
        ret     z                                              ;#4554: C8
        cp      0E0h                                           ;#4555: FE E0
        jr      nc,WRITE_VRAM_TILES_ADDRESS                    ;#4557: 30 E8
        inc     hl                                             ;#4559: 23
        exx                                                    ;#455A: D9
        out     (c),a                                          ;#455B: ED 79
        exx                                                    ;#455D: D9
        jr      WRITE_VRAM_TILES_LOOP                          ;#455E: 18 F2

DECOMPRESS_VRAM_INDIRECT:
        ; Standard entry (Addr in stream)
        ld      e,(hl)                                         ;#4560: 5E
        inc     hl                                             ;#4561: 23
        ld      d,(hl)                                         ;#4562: 56
        inc     hl                                             ;#4563: 23
DECOMPRESS_VRAM_DIRECT:
        ; Entry with Addr in DE (No Mirror)
        ld      c,0                                            ;#4564: 0E 00
        jr      DECOMPRESS_VRAM_SET_VDP                        ;#4566: 18 02

DECOMPRESS_VRAM_DIRECT_MIRROR:
        ; Entry with Addr in DE (Mirrored)
        ld      c,1                                            ;#4568: 0E 01
DECOMPRESS_VRAM_SET_VDP:
        ; Common SET_VDP entry for decompression
        call    SET_VDP                                        ;#456A: CD E2 48
DECOMPRESS_VRAM_DATA_ONLY:
        ; Data-only entry (No SET_VDP call)
        ld      a,(hl)                                         ;#456D: 7E
        inc     hl                                             ;#456E: 23
        cp      80h                                            ;#456F: FE 80
        jr      z,DECOMPRESS_VRAM_INDIRECT                     ;#4571: 28 ED
        or      a                                              ;#4573: B7
        jr      z,DECOMPRESS_VRAM_EXIT                         ;#4574: 28 20
        bit     7,a                                            ;#4576: CB 7F
        jr      nz,DECOMPRESS_VRAM_LITERAL                     ;#4578: 20 0E
        ld      b,a                                            ;#457A: 47
        call    READ_BYTE_WITH_OPTIONAL_MIRROR                 ;#457B: CD 98 45
DECOMPRESS_VRAM_RLE_LOOP:
        ; Loop for RLE decompression
        exx                                                    ;#457E: D9
        out     (c),a                                          ;#457F: ED 79
        exx                                                    ;#4581: D9
        push    hl                                             ;#4582: E5
        pop     hl                                             ;#4583: E1
        djnz    DECOMPRESS_VRAM_RLE_LOOP                       ;#4584: 10 F8
        jr      DECOMPRESS_VRAM_DATA_ONLY                      ;#4586: 18 E5

DECOMPRESS_VRAM_LITERAL:
        ; Handle literal byte sequence during decompression
        res     7,a                                            ;#4588: CB BF
        ld      b,a                                            ;#458A: 47
DECOMPRESS_VRAM_LIT_LOOP:
        ; Loop for literal decompression
        call    READ_BYTE_WITH_OPTIONAL_MIRROR                 ;#458B: CD 98 45
        exx                                                    ;#458E: D9
        out     (c),a                                          ;#458F: ED 79
        exx                                                    ;#4591: D9
        djnz    DECOMPRESS_VRAM_LIT_LOOP                       ;#4592: 10 F7
        jr      DECOMPRESS_VRAM_DATA_ONLY                      ;#4594: 18 D7

DECOMPRESS_VRAM_EXIT:
        ; Exit decompression routine
        ei                                                     ;#4596: FB
        ret                                                    ;#4597: C9

READ_BYTE_WITH_OPTIONAL_MIRROR:
        ; Reads (HL), inc HL, and reverses bits if bit 0 of C is set
        ld      a,(hl)                                         ;#4598: 7E
        inc     hl                                             ;#4599: 23
        bit     0,c                                            ;#459A: CB 41
        ret     z                                              ;#459C: C8
        push    bc                                             ;#459D: C5
        ld      b,8                                            ;#459E: 06 08
        ld      c,a                                            ;#45A0: 4F
BIT_REV_LOOP:
        ; Bits reversal loop for mirror decompression
        rr      c                                              ;#45A1: CB 19
        rla                                                    ;#45A3: 17
        djnz    BIT_REV_LOOP                                   ;#45A4: 10 FB
        pop     bc                                             ;#45A6: C1
        ret                                                    ;#45A7: C9

WRITE_VRAM_STREAM:
        ; Updates VRAM from a data stream with addresses and terminators
        ld      e,(hl)                                         ;#45A8: 5E
        inc     hl                                             ;#45A9: 23
        ld      d,(hl)                                         ;#45AA: 56
        inc     hl                                             ;#45AB: 23
WRITE_VRAM_STREAM_WITH_OFFSET:
        ; Adds DE to VRAM pointer before streaming
        ld      a,(hl)                                         ;#45AC: 7E
        inc     hl                                             ;#45AD: 23
        ld      b,a                                            ;#45AE: 47
        inc     b                                              ;#45AF: 04
        ret     z                                              ;#45B0: C8
        inc     b                                              ;#45B1: 04
        jr      z,WRITE_VRAM_STREAM                            ;#45B2: 28 F4
        call    WRITE_VRAM_BYTE                                ;#45B4: CD D0 48
        inc     de                                             ;#45B7: 13
        jr      WRITE_VRAM_STREAM_WITH_OFFSET                  ;#45B8: 18 F2

REPLICATE_4_BYTE_BLOCK:
        ; Replicate a 4-byte block in memory C times
        push    hl                                             ;#45BA: E5
        ld      b,4                                            ;#45BB: 06 04
REPLICATE_4_BYTE_LOOP:
        ; Loop to copy 4 bytes into destination
        ld      a,(hl)                                         ;#45BD: 7E
        ld      (de),a                                         ;#45BE: 12
        inc     hl                                             ;#45BF: 23
        inc     de                                             ;#45C0: 13
        djnz    REPLICATE_4_BYTE_LOOP                          ;#45C1: 10 FA
        dec     c                                              ;#45C3: 0D
        jr      z,CLEAR_SPRITES_VRAM_DONE                      ;#45C4: 28 03
        pop     hl                                             ;#45C6: E1
        jr      REPLICATE_4_BYTE_BLOCK                         ;#45C7: 18 F1

CLEAR_SPRITES_VRAM_DONE:
        ; Wait animation tile write finished
        pop     bc                                             ;#45C9: C1
        ret                                                    ;#45CA: C9

CLEAR_SPRITES_AND_UPDATE_VRAM:
        ; Clears sprites and conditionally updates VRAM tiles during wait
        call    CLEAR_SPRITES                                  ;#45CB: CD 00 46
        ld      d,38h                                          ;#45CE: 16 38
        ld      hl,WAIT_TIMER                                  ;#45D0: 21 04 E0
        ld      b,18h                                          ;#45D3: 06 18
        bit     6,(hl)                                         ;#45D5: CB 76
        jr      nz,CLEAR_SAT_MIRROR_LOOP                       ;#45D7: 20 08
        ld      a,1Fh                                          ;#45D9: 3E 1F
        sub     (hl)                                           ;#45DB: 96
        ld      e,a                                            ;#45DC: 5F
        set     6,(hl)                                         ;#45DD: CB F6
        jr      CLEAR_SPRITES_VRAM_UPDATE                      ;#45DF: 18 05

CLEAR_SAT_MIRROR_LOOP:
        ; Loop clearing SAT_MIRROR
        res     6,(hl)                                         ;#45E1: CB B6
        dec     (hl)                                           ;#45E3: 35
        ret     m                                              ;#45E4: F8
        ld      e,(hl)                                         ;#45E5: 5E
CLEAR_SPRITES_VRAM_UPDATE:
        ; Select VRAM update offset for wait animation
        ld      a,(GAME_STATE)                                 ;#45E6: 3A 00 E0
        cp      0Ah                                            ;#45E9: FE 0A
        jr      c,CLEAR_SPRITES_VRAM_LOOP                      ;#45EB: 38 06
        ld      a,40h                                          ;#45ED: 3E 40
        add     a,e                                            ;#45EF: 83
        ld      e,a                                            ;#45F0: 5F
        dec     b                                              ;#45F1: 05
        dec     b                                              ;#45F2: 05
CLEAR_SPRITES_VRAM_LOOP:
        ; Loop writing wait animation tiles to VRAM
        xor     a                                              ;#45F3: AF
        call    WRITE_VRAM_BYTE                                ;#45F4: CD D0 48
        ld      a,20h                                          ;#45F7: 3E 20
        call    ADD_DE_A                                       ;#45F9: CD 03 49
        djnz    CLEAR_SPRITES_VRAM_LOOP                        ;#45FC: 10 F5
        xor     a                                              ;#45FE: AF
        ret                                                    ;#45FF: C9

CLEAR_SPRITES:
        ; Clears sprite attribute mirror in RAM and copies to VRAM
        ld      hl,SAT_MIRROR                                  ;#4600: 21 50 E0
        push    hl                                             ;#4603: E5
        ld      b,80h                                          ;#4604: 06 80
CLEAR_SPRITE_ATTR_LOOP:
        ; Loop to zero sprite attribute mirror
        ld      (hl),0                                         ;#4606: 36 00
        inc     hl                                             ;#4608: 23
        djnz    CLEAR_SPRITE_ATTR_LOOP                         ;#4609: 10 FB
        LOAD_SPRITE_ATTR de, 0, 0                              ;#460B: 11 00 3B
        pop     hl                                             ;#460E: E1
        ld      bc,80h                                         ;#460F: 01 80 00
        jp      COPY_RAM_TO_VRAM                               ;#4612: C3 EC 44

INIT_PSG_PORT_B:
        ; Initialize PSG Port B (Register 15)
        ld      e,8Fh                                          ;#4615: 1E 8F
        ld      a,0Fh                                          ;#4617: 3E 0F
        call    BIOS_WRTPSG                                    ;#4619: CD 93 00
        ret                                                    ;#461C: C9

READ_INPUT_EDGE:
        ; Detect new button presses (edge trigger)
        ld      a,(CUR_INPUT_KEYS)                             ;#461D: 3A 09 E0
        ld      b,a                                            ;#4620: 47
        ld      a,(PREV_INPUT_KEYS)                            ;#4621: 3A 08 E0
        and     30h                                            ;#4624: E6 30
        cpl                                                    ;#4626: 2F
        ld      c,a                                            ;#4627: 4F
        ld      a,b                                            ;#4628: 78
        and     30h                                            ;#4629: E6 30
        and     c                                              ;#462B: A1
        ret                                                    ;#462C: C9

ADD_SCORE:
        ; Add value in DE to current BCD score
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#462D: 3A 02 E0
        add     a,a                                            ;#4630: 87
        ret     p                                              ;#4631: F0
        ld      hl,CURRENT_SCORE_BCD + BCD_LOW                 ;#4632: 21 43 E0
        ld      a,(hl)                                         ;#4635: 7E
        add     a,e                                            ;#4636: 83
        daa                                                    ;#4637: 27
        ld      (hl),a                                         ;#4638: 77
        ld      e,a                                            ;#4639: 5F
        inc     hl                                             ;#463A: 23
        ld      a,(hl)                                         ;#463B: 7E
        adc     a,d                                            ;#463C: 8A
        daa                                                    ;#463D: 27
        ld      (hl),a                                         ;#463E: 77
        ld      d,a                                            ;#463F: 57
        inc     hl                                             ;#4640: 23
        jr      nc,ADD_SCORE_DONE                              ;#4641: 30 14
        ld      a,(hl)                                         ;#4643: 7E
        adc     a,0                                            ;#4644: CE 00
        daa                                                    ;#4646: 27
        ld      (hl),a                                         ;#4647: 77
        jr      nc,ADD_SCORE_DONE                              ;#4648: 30 0D
        ld      bc,9999h ; Max score is 999999                 ;#464A: 01 99 99
        ld      (HI_SCORE_BCD + BCD_LOW),bc                    ;#464D: ED 43 40 E0
        ld      (HI_SCORE_BCD + BCD_MID),bc                    ;#4651: ED 43 41 E0
        jr      HUD_DRAW_HI_SCORE                              ;#4655: 18 72

ADD_SCORE_DONE:
        ; Score addition finished
        ld      a,(HI_SCORE_BCD + BCD_HIGH)                    ;#4657: 3A 42 E0
        ld      b,(hl)                                         ;#465A: 46
        sub     (hl)                                           ;#465B: 96
        jr      c,ADD_SCORE_CHECK_HI                           ;#465C: 38 09
        jr      nz,HUD_DRAW_SCORE                              ;#465E: 20 72
        ld      hl,(HI_SCORE_BCD + BCD_LOW)                    ;#4660: 2A 40 E0
        sbc     hl,de                                          ;#4663: ED 52
        jr      nc,HUD_DRAW_SCORE                              ;#4665: 30 6B
ADD_SCORE_CHECK_HI:
        ; Check if score is higher than record
        ld      (HI_SCORE_BCD + BCD_LOW),de                    ;#4667: ED 53 40 E0
        ld      a,b                                            ;#466B: 78
        ld      (HI_SCORE_BCD + BCD_HIGH),a                    ;#466C: 32 42 E0
        jr      HUD_DRAW_HI_SCORE                              ;#466F: 18 58

UPDATE_GAME_TIMER:
        ; Decrement stage timer once per second
        ld      a,(TIMER_ACTIVE_FLAG)                          ;#4671: 3A 33 E1
        or      a                                              ;#4674: B7
        ret     z                                              ;#4675: C8
        ld      hl,(REMANING_TIME_BCD)                         ;#4676: 2A E3 E0
        ld      a,h                                            ;#4679: 7C
        add     a,l                                            ;#467A: 85
        jr      nz,UPDATE_GAME_TIMER_DONE                      ;#467B: 20 05
        inc     a                                              ;#467D: 3C
        ld      (TIME_UP_FLAG),a                               ;#467E: 32 0C E0
        ret                                                    ;#4681: C9

UPDATE_GAME_TIMER_DONE:
        ; Timer update finished
        ld      a,(FRAME_COUNTER)                              ;#4682: 3A 03 E0
        and     3Fh                                            ;#4685: E6 3F
        ret     nz                                             ;#4687: C0
        ld      c,1                                            ;#4688: 0E 01
DECREMENT_DISTANCE:
        ; Decrement remaining distance BCD and refresh HUD
        ld      hl,REMANING_TIME_BCD                           ;#468A: 21 E3 E0
        ld      a,(hl)                                         ;#468D: 7E
        sub     1                                              ;#468E: D6 01
        daa                                                    ;#4690: 27
        ld      (hl),a                                         ;#4691: 77
        inc     hl                                             ;#4692: 23
        ld      a,(hl)                                         ;#4693: 7E
        jr      nc,DECREMENT_DISTANCE_DONE                     ;#4694: 30 04
        sub     1                                              ;#4696: D6 01
        daa                                                    ;#4698: 27
        ld      (hl),a                                         ;#4699: 77
DECREMENT_DISTANCE_DONE:
        ; Distance decrement finished
        dec     hl                                             ;#469A: 2B
        or      a                                              ;#469B: B7
        jr      nz,HUD_DRAW_DISTANCE                           ;#469C: 20 11
        ld      a,(hl)                                         ;#469E: 7E
        cp      11h                                            ;#469F: FE 11
        jr      nc,HUD_DRAW_DISTANCE                           ;#46A1: 30 0C
        dec     c                                              ;#46A3: 0D
        jr      nz,HUD_DRAW_DISTANCE                           ;#46A4: 20 09
        push    af                                             ;#46A6: F5
        push    hl                                             ;#46A7: E5
        ld      a,ID_SOUND_DISTANCE_WARNING                    ;#46A8: 3E 09
        call    PLAY_SOUND_SAFE                                ;#46AA: CD C9 79
        pop     hl                                             ;#46AD: E1
        pop     af                                             ;#46AE: F1
HUD_DRAW_DISTANCE:
        ; Draw remaining distance (4 digits)
        ld      b,2                                            ;#46AF: 06 02
        LOAD_NAME_TABLE de, 1, 7                               ;#46B1: 11 27 38
        ld      hl,REMANING_TIME_HIGH                          ;#46B4: 21 E4 E0
        jp      WRITE_BCD_TO_HUD                               ;#46B7: C3 28 47

REFRESH_HUD:
        ; Redraw all HUD elements (Distance, HI_SCORE Stage, Time, Scores)
        ld      hl,HUD_STATIC_TEXT                             ;#46BA: 21 B0 57
        call    WRITE_VRAM_STREAM                              ;#46BD: CD A8 45
        call    HUD_DRAW_DISTANCE                              ;#46C0: CD AF 46
        call    HUD_DRAW_STAGE_HI_SCORE                        ;#46C3: CD 16 47
        call    HUD_DRAW_STAGE                                 ;#46C6: CD 20 47
HUD_DRAW_HI_SCORE:
        ; Setup for drawing high score after updates
        ld      hl,HI_SCORE_BCD + BCD_HIGH                     ;#46C9: 21 42 E0
        LOAD_NAME_TABLE de, 0, 15                              ;#46CC: 11 0F 38
        call    HUD_DRAW_6_DIGITS                              ;#46CF: CD D8 46
HUD_DRAW_SCORE:
        ; Entry point for HUD score drawing
        LOAD_NAME_TABLE de, 0, 5                               ;#46D2: 11 05 38
        ld      hl,CURRENT_SCORE_BCD + BCD_HIGH                ;#46D5: 21 45 E0
HUD_DRAW_6_DIGITS:
        ; Internal body for drawing 6-digit BCD values
        ld      b,3                                            ;#46D8: 06 03
        jr      WRITE_BCD_TO_HUD                               ;#46DA: 18 4C

UPDATE_STAGE_DISTANCE:
        ; Decrements stage distance counter
        ld      hl,DISTANCE_TICK_TIMER                         ;#46DC: 21 E9 E0
        dec     (hl)                                           ;#46DF: 35
        ret     nz                                             ;#46E0: C0
        ld      a,(PENGUIN_SPEED)                              ;#46E1: 3A 00 E1
        srl     a                                              ;#46E4: CB 3F
        dec     a                                              ;#46E6: 3D
        ld      (hl),a                                         ;#46E7: 77
        ld      hl,STAGE_DISTANCE_HIGH                         ;#46E8: 21 E6 E0
        ld      a,(hl)                                         ;#46EB: 7E
        dec     hl                                             ;#46EC: 2B
        or      (hl)                                           ;#46ED: B6
        jr      nz,DECREMENT_BCD_DIGITS                        ;#46EE: 20 05
        inc     a                                              ;#46F0: 3C
        ld      (STAGE_GOAL_FLAG),a                            ;#46F1: 32 0D E0
        ret                                                    ;#46F4: C9

DECREMENT_BCD_DIGITS:
        ; Loop drawing BCD digits
        ld      a,(hl)                                         ;#46F5: 7E
        sub     1                                              ;#46F6: D6 01
        daa                                                    ;#46F8: 27
        ld      (hl),a                                         ;#46F9: 77
        ld      c,a                                            ;#46FA: 4F
        inc     hl                                             ;#46FB: 23
        jr      nc,DECREMENT_BCD_DIGITS_DONE                   ;#46FC: 30 05
        ld      a,(hl)                                         ;#46FE: 7E
        sub     1                                              ;#46FF: D6 01
        daa                                                    ;#4701: 27
        ld      (hl),a                                         ;#4702: 77
DECREMENT_BCD_DIGITS_DONE:
        ; Digits drawing finished
        ld      a,c                                            ;#4703: 79
        or      a                                              ;#4704: B7
        jr      nz,UPDATE_STAGE_DISTANCE_NEXT                  ;#4705: 20 0C
        or      (hl)                                           ;#4707: B6
        jr      z,UPDATE_STAGE_DISTANCE_NEXT                   ;#4708: 28 09
        ld      a,(hl)                                         ;#470A: 7E
        and     3                                              ;#470B: E6 03
        jr      nz,UPDATE_STAGE_DISTANCE_NEXT                  ;#470D: 20 04
        inc     a                                              ;#470F: 3C
        ld      (STAGE_SEGMENT_TIMER),a                        ;#4710: 32 07 E1
UPDATE_STAGE_DISTANCE_NEXT:
        ; Continue distance update
        call    CHECK_DISTANCE_MILESTONE                       ;#4713: CD F5 52
HUD_DRAW_STAGE_HI_SCORE:
        ; Draw stage HI_SCORE/current stage (4 digits)
        ld      b,2                                            ;#4716: 06 02
        LOAD_NAME_TABLE de, 1, 15                              ;#4718: 11 2F 38
        ld      hl,STAGE_DISTANCE_HIGH                         ;#471B: 21 E6 E0
        jr      WRITE_BCD_TO_HUD                               ;#471E: 18 08

HUD_DRAW_STAGE:
        ; Draw current stage number from CURRENT_VISIBLE_STAGE (1 BCD byte = 2 digits)
        LOAD_NAME_TABLE de, 0, 28                              ;#4720: 11 1C 38
        ld      hl,CURRENT_VISIBLE_STAGE                       ;#4723: 21 E0 E0
        ld      b,1                                            ;#4726: 06 01
WRITE_BCD_TO_HUD:
        ; Core routine to draw BCD bytes as digits to VRAM (dec hl, loop b times)
        ld      a,(hl)                                         ;#4728: 7E
        push    af                                             ;#4729: F5
        and     0Fh                                            ;#472A: E6 0F
        or      10h                                            ;#472C: F6 10
        ld      c,a                                            ;#472E: 4F
        pop     af                                             ;#472F: F1
        and     0F0h                                           ;#4730: E6 F0
        rra                                                    ;#4732: 1F
        rra                                                    ;#4733: 1F
        rra                                                    ;#4734: 1F
        rra                                                    ;#4735: 1F
        or      10h                                            ;#4736: F6 10
        call    WRITE_VRAM_BYTE                                ;#4738: CD D0 48
        inc     de                                             ;#473B: 13
        ld      a,c                                            ;#473C: 79
        call    WRITE_VRAM_BYTE                                ;#473D: CD D0 48
        dec     hl                                             ;#4740: 2B
        inc     de                                             ;#4741: 13
        djnz    WRITE_BCD_TO_HUD                               ;#4742: 10 E4
        ret                                                    ;#4744: C9

UPDATE_STAGE_SEQUENCE:
        ; Pick SEQUENCE_THRESHOLD and SEQUENCE_DATA_PTR for stage + progress
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4745: 3A E0 E0
        and     0Fh                                            ;#4748: E6 0F
        ld      hl,SEQUENCE_TIME_THRESHOLDS                    ;#474A: 21 87 47
        add     a,a                                            ;#474D: 87
        call    ADD_HL_A                                       ;#474E: CD FE 48
        ld      a,(STAGE_DISTANCE_HIGH)                        ;#4751: 3A E6 E0
        and     10h                                            ;#4754: E6 10
        jr      z,UPDATE_STAGE_SEQUENCE_PICK_SUBTASK           ;#4756: 28 01
        inc     hl                                             ;#4758: 23
UPDATE_STAGE_SEQUENCE_PICK_SUBTASK:
        ; Threshold picked; now pick subtask pointer from progress segment
        ld      a,(hl)                                         ;#4759: 7E
        ld      (SEQUENCE_THRESHOLD),a                         ;#475A: 32 8A E1
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#475D: 3A E0 E0
        and     0Fh                                            ;#4760: E6 0F
        ld      hl,SEQUENCE_TASK_TABLE                         ;#4762: 21 C3 47
        add     a,a                                            ;#4765: 87
        call    ADD_HL_A                                       ;#4766: CD FE 48
        ld      e,(hl)                                         ;#4769: 5E
        inc     hl                                             ;#476A: 23
        ld      d,(hl)                                         ;#476B: 56
        ex      de,hl                                          ;#476C: EB
        ld      a,(STAGE_DISTANCE_HIGH)                        ;#476D: 3A E6 E0
        and     0FCh                                           ;#4770: E6 FC
        rrca                                                   ;#4772: 0F
        rrca                                                   ;#4773: 0F
        res     3,a                                            ;#4774: CB 9F
        cp      4                                              ;#4776: FE 04
        jr      c,UPDATE_STAGE_SEQUENCE_INDEX_READY            ;#4778: 38 01
        dec     a                                              ;#477A: 3D
UPDATE_STAGE_SEQUENCE_INDEX_READY:
        ; Progress index settled (with/without -1 adjustment); load subtask pointer
        add     a,a                                            ;#477B: 87
        call    ADD_HL_A                                       ;#477C: CD FE 48
        ld      e,(hl)                                         ;#477F: 5E
        inc     hl                                             ;#4780: 23
        ld      d,(hl)                                         ;#4781: 56
        ex      de,hl                                          ;#4782: EB
        ld      (SEQUENCE_DATA_PTR),hl                         ;#4783: 22 8B E1
        ret                                                    ;#4786: C9

SEQUENCE_TIME_THRESHOLDS:
        ; Sequence threshold table (per time digit, two variants)
        ; Format: FORMAT_SEQUENCE_THRESHOLDS
        ; - 10 pairs: [low_threshold, high_threshold] per time digit (0-9).
        THRESHOLD 80h, 0                                       ;#4787: 80 00
        THRESHOLD 0A0h, 0A0h                                   ;#4789: A0 A0
        THRESHOLD 50h, 50h                                     ;#478B: 50 50
        THRESHOLD 0E0h, 0E0h                                   ;#478D: E0 E0
        THRESHOLD 50h, 50h                                     ;#478F: 50 50
        THRESHOLD 0, 20h                                       ;#4791: 00 20
        THRESHOLD 0E0h, 0E0h                                   ;#4793: E0 E0
        THRESHOLD 20h, 20h                                     ;#4795: 20 20
        THRESHOLD 0, 0                                         ;#4797: 00 00
        THRESHOLD 0FFh, 0FFh                                   ;#4799: FF FF

SEQ_STREAM_FISH_JUMP:
        ; Sequence command stream for fish jump behavior
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_ITEM_PROP 1                                        ;#479B: 01
        SEQ_ITEM_PROP 5                                        ;#479C: 05
        SEQ_IDLE                                               ;#479D: FF
        SEQ_ITEM_PROP 0                                        ;#479E: 00
        SEQ_MOVE_STATE 2                                       ;#479F: 12
        SEQ_ITEM_PROP 5                                        ;#47A0: 05
        SEQ_IDLE                                               ;#47A1: FF
        SEQ_ITEM_PROP 0                                        ;#47A2: 00

SEQ_STREAM_SEAL_MOVE:
        ; Sequence command stream for seal movement behavior
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_MOVE_STATE 1                                       ;#47A3: 11
        SEQ_ITEM_PROP 1                                        ;#47A4: 01
        SEQ_ITEM_PROP 0                                        ;#47A5: 00
        SEQ_MOVE_STATE 2                                       ;#47A6: 12
        SEQ_ITEM_PROP 0                                        ;#47A7: 00
        SEQ_ITEM_PROP 1                                        ;#47A8: 01
        SEQ_MOVE_STATE 2                                       ;#47A9: 12
        SEQ_ITEM_PROP 0                                        ;#47AA: 00

SEQ_STREAM_MIX_A:
        ; Sequence stream A: cycles item-prop entries 0,1,3,5 (mixed item types)
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_ITEM_PROP 0                                        ;#47AB: 00
        SEQ_IDLE                                               ;#47AC: FF
        SEQ_ITEM_PROP 3                                        ;#47AD: 03
        SEQ_MOVE_STATE 1                                       ;#47AE: 11
        SEQ_ITEM_PROP 1                                        ;#47AF: 01
        SEQ_ITEM_PROP 5                                        ;#47B0: 05
        SEQ_IDLE                                               ;#47B1: FF
        SEQ_ITEM_PROP 3                                        ;#47B2: 03

SEQ_STREAM_MIX_B:
        ; Sequence stream B: cycles item-prop entries 0,1,3 (no flag)
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_ITEM_PROP 0                                        ;#47B3: 00
        SEQ_IDLE                                               ;#47B4: FF
        SEQ_ITEM_PROP 3                                        ;#47B5: 03
        SEQ_ITEM_PROP 3                                        ;#47B6: 03
        SEQ_ITEM_PROP 0                                        ;#47B7: 00
        SEQ_MOVE_STATE 1                                       ;#47B8: 11
        SEQ_ITEM_PROP 1                                        ;#47B9: 01
        SEQ_MOVE_STATE 2                                       ;#47BA: 12

SEQ_STREAM_MIX_C:
        ; Sequence stream C: cycles item-prop entries 3,5 (no small holes)
        ; Format: FORMAT_SEQUENCE_COMMANDS
        ; - 00h-0Fh: SEQ_ITEM_PROP n — select entry n from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: SEQ_MOVE_STATE n — set movement state (dispatcher does n & 3,
        ; stored at ITEM_TABLE+1 with ITEM_MOVE_OVERRIDE_FLAG set).
        ; - FFh: SEQ_IDLE — end/idle for this sequence step.
        SEQ_ITEM_PROP 5                                        ;#47BB: 05
        SEQ_IDLE                                               ;#47BC: FF
        SEQ_ITEM_PROP 5                                        ;#47BD: 05
        SEQ_IDLE                                               ;#47BE: FF
        SEQ_ITEM_PROP 3                                        ;#47BF: 03
        SEQ_MOVE_STATE 2                                       ;#47C0: 12
        SEQ_ITEM_PROP 5                                        ;#47C1: 05
        SEQ_IDLE                                               ;#47C2: FF

SEQUENCE_TASK_TABLE:
        ; Subtask-table base per stage; indexed by CURRENT_VISIBLE_STAGE & 0Fh (BCD units)
        dw      SEQUENCE_SUB_TASK_TABLE_A + 20h ; stage 0      ;#47C3: F7 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 0Eh ; stage 1      ;#47C5: E5 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 16h ; stage 2      ;#47C7: ED 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 20h ; stage 3      ;#47C9: F7 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 18h ; stage 4      ;#47CB: EF 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 1Ah ; stage 5      ;#47CD: F1 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 22h ; stage 6      ;#47CF: F9 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 0Eh ; stage 7      ;#47D1: E5 47
        dw      SEQUENCE_SUB_TASK_TABLE_A + 1Ah ; stage 8      ;#47D3: F1 47
        dw      SEQUENCE_SUB_TASK_TABLE_A       ; stage 9      ;#47D5: D7 47

SEQUENCE_SUB_TASK_TABLE_A:
        ; Combined sequence subtask list base
        ; Format: FORMAT_SEQUENCE_SUBTASK_TABLE
        ; - Entries point to SEQ_STREAM_* command streams.
        dw      SEQ_STREAM_MIX_B                               ;#47D7 B3 47
        dw      SEQ_STREAM_FISH_JUMP                           ;#47D9 9B 47
        dw      SEQ_STREAM_MIX_B                               ;#47DB B3 47
        dw      SEQ_STREAM_FISH_JUMP                           ;#47DD 9B 47
        dw      SEQ_STREAM_MIX_C                               ;#47DF BB 47
        dw      SEQ_STREAM_MIX_A                               ;#47E1 AB 47
        dw      SEQ_STREAM_FISH_JUMP                           ;#47E3 9B 47
        dw      SEQ_STREAM_MIX_A                               ;#47E5 AB 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47E7 A3 47
        dw      SEQ_STREAM_MIX_B                               ;#47E9 B3 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47EB A3 47
        dw      SEQ_STREAM_FISH_JUMP                           ;#47ED 9B 47
        dw      SEQ_STREAM_MIX_B                               ;#47EF B3 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47F1 A3 47
        dw      SEQ_STREAM_MIX_A                               ;#47F3 AB 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47F5 A3 47
        dw      SEQ_STREAM_MIX_C                               ;#47F7 BB 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47F9 A3 47
        dw      SEQ_STREAM_MIX_C                               ;#47FB BB 47
        dw      SEQ_STREAM_SEAL_MOVE                           ;#47FD A3 47

CHECK_SEQUENCE_STATUS:
        ; Checks sequence flag and decrements timer
        ld      a,(SEQUENCE_ACTIVE)                            ;#47FF: 3A 8E E1
        rra                                                    ;#4802: 1F
        ret     nc                                             ;#4803: D0
        ld      hl,SEQUENCE_TIMER                              ;#4804: 21 8F E1
        dec     (hl)                                           ;#4807: 35
        jr      nz,START_SEQUENCE_CHECK_DONE                   ;#4808: 20 04
        xor     a                                              ;#480A: AF
        ld      (SEQUENCE_ACTIVE),a                            ;#480B: 32 8E E1
START_SEQUENCE_CHECK_DONE:
        ; Sequence check finished
        ld      c,3                                            ;#480E: 0E 03
        ret                                                    ;#4810: C9

START_SEQUENCE_CHECK:
        ; Entry point for checking if a new periodic sequence (fish/seal) should start
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4811: 3A E0 E0
        and     0Fh                                            ;#4814: E6 0F
        ld      hl,SEQUENCE_TIMER_TABLE                        ;#4816: 21 39 48
        call    ADD_HL_A                                       ;#4819: CD FE 48
        ld      de,(STAGE_DISTANCE_BCD)                        ;#481C: ED 5B E5 E0
        ld      a,d                                            ;#4820: 7A
        cp      4                                              ;#4821: FE 04
        ret     c                                              ;#4823: D8
        ld      a,e                                            ;#4824: 7B
        or      a                                              ;#4825: B7
        ret     nz                                             ;#4826: C0
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4827: 3A E0 E0
        add     a,d                                            ;#482A: 82
        and     3                                              ;#482B: E6 03
        cp      2                                              ;#482D: FE 02
        ret     nz                                             ;#482F: C0
        inc     a                                              ;#4830: 3C
        ld      (SEQUENCE_ACTIVE),a                            ;#4831: 32 8E E1
        ld      a,(hl)                                         ;#4834: 7E
        ld      (SEQUENCE_TIMER),a                             ;#4835: 32 8F E1
        ret                                                    ;#4838: C9

SEQUENCE_TIMER_TABLE:
        ; Sequence timer lookup (per seconds digit)
        ; One byte per entry, 10 entries indexed by (CURRENT_VISIBLE_STAGE & 0Fh).
        ; `START_SEQUENCE_CHECK` loads the selected byte into `SEQUENCE_TIMER` when it
        ; decides to kick off a new periodic sequence (fish/seal). Values: 7, 2, 2, 3,
        ; 3, 4, 4, 5, 6, 6. (Not to be confused with SEQUENCE_TIME_THRESHOLDS,
        ; which really is 10 low/high pairs.)
        ; Format: FORMAT_SEQUENCE_TIMER_TABLE
        TIMER_VALUE 7                                          ;#4839: 07
        TIMER_VALUE 2                                          ;#483A: 02
        TIMER_VALUE 2                                          ;#483B: 02
        TIMER_VALUE 3                                          ;#483C: 03
        TIMER_VALUE 3                                          ;#483D: 03
        TIMER_VALUE 4                                          ;#483E: 04
        TIMER_VALUE 4                                          ;#483F: 04
        TIMER_VALUE 5                                          ;#4840: 05
        TIMER_VALUE 6                                          ;#4841: 06
        TIMER_VALUE 6                                          ;#4842: 06

INIT_TITLE_BACKGROUND:
        ; Initialize title background tiles for title flow
        call    INIT_ALL_VDP_PLANES                            ;#4843: CD 8A 58
        LOAD_VRAM_ADDRESS de, 1080h                            ;#4846: 11 80 10
        ld      bc,180h                                        ;#4849: 01 80 01
        LOAD_VRAM_COLOR a, COLOR_CYAN, COLOR_TRANSPARENT       ;#484C: 3E 70
        call    FILL_VRAM                                      ;#484E: CD FD 44
        xor     a                                              ;#4851: AF
        ld      (VDP_TEMP_AREA),a                              ;#4852: 32 0A E0
        LOAD_VRAM_COLOR b, COLOR_GRAY, COLOR_TRANSPARENT       ;#4855: 06 E0
        call    SET_BACKGROUND_COLOR                           ;#4857: CD E7 44
        ld      de,3800h                                       ;#485A: 11 00 38
        ld      bc,300h                                        ;#485D: 01 00 03
        xor     a                                              ;#4860: AF
        call    FILL_VRAM                                      ;#4861: CD FD 44
TITLE_WINDOW_ANIMATION:
        ; Manages title window tile paging and animation
        ld      hl,VDP_TEMP_AREA                               ;#4864: 21 0A E0
        ld      a,(hl)                                         ;#4867: 7E
        inc     (hl)                                           ;#4868: 34
        cp      17h                                            ;#4869: FE 17
        jr      nc,DRAW_FLOATING_KONAMI_COPYRIGHT              ;#486B: 30 1C
        LOAD_NAME_TABLE de, 4, 5                               ;#486D: 11 85 38
        ld      c,a                                            ;#4870: 4F
        add     a,e                                            ;#4871: 83
        ld      e,a                                            ;#4872: 5F
        ld      a,c                                            ;#4873: 79
        add     a,a                                            ;#4874: 87
        add     a,0B2h                                         ;#4875: C6 B2
        ld      c,a                                            ;#4877: 4F
        ld      b,3                                            ;#4878: 06 03
        xor     a                                              ;#487A: AF
TITLE_WINDOW_ANIMATION_LOOP:
        ; Loop writing title window tiles to VRAM
        call    WRITE_VRAM_BYTE                                ;#487B: CD D0 48
        ld      a,20h                                          ;#487E: 3E 20
        call    ADD_DE_A                                       ;#4880: CD 03 49
        ld      a,c                                            ;#4883: 79
        inc     c                                              ;#4884: 0C
        djnz    TITLE_WINDOW_ANIMATION_LOOP                    ;#4885: 10 F4
        scf                                                    ;#4887: 37
        ret                                                    ;#4888: C9

DRAW_FLOATING_KONAMI_COPYRIGHT:
        ; Loop updating opening animation
        push    af                                             ;#4889: F5
        ld      hl,KONAMI_COPYRIGHT_TEXT                       ;#488A: 21 DF 57
        call    WRITE_VRAM_STREAM                              ;#488D: CD A8 45
        pop     af                                             ;#4890: F1
        cp      34h                                            ;#4891: FE 34
        ret     c                                              ;#4893: D8
        or      a                                              ;#4894: B7
        ret                                                    ;#4895: C9

KONAMI_OPENING_ANIMATION:
        ; Updates VRAM row pointer and writes 3 tiles for Konami logo
        ld      hl,(KONAMI_LOGO_ROW_PTR)                       ;#4896: 2A 0E E0
        ld      de,20h                                         ;#4899: 11 20 00
        add     hl,de                                          ;#489C: 19
        ld      (KONAMI_LOGO_ROW_PTR),hl                       ;#489D: 22 0E E0
        ex      de,hl                                          ;#48A0: EB
        or      a                                              ;#48A1: B7
        LOAD_NAME_TABLE hl, 21, 10                             ;#48A2: 21 AA 3A
        sbc     hl,de                                          ;#48A5: ED 52
        ex      de,hl                                          ;#48A7: EB
        ; Konami logo starts at tile 44h.
        ld      a,44h                                          ;#48A8: 3E 44
        ; c = Konami logo is 3 rows height.
        ; b = First line is 3 cols width.
        ld      bc,303h                                        ;#48AA: 01 03 03
KONAMI_LOGO_WRITE_DONE:
        ; logo tile write finished
        push    de                                             ;#48AD: D5
KONAMI_LOGO_WRITE_LOOP:
        ; Loop writing Konami logo tiles
        call    WRITE_VRAM_BYTE                                ;#48AE: CD D0 48
        inc     de                                             ;#48B1: 13
        inc     a                                              ;#48B2: 3C
        djnz    KONAMI_LOGO_WRITE_LOOP                         ;#48B3: 10 F9
        pop     de                                             ;#48B5: D1
        ld      hl,20h                                         ;#48B6: 21 20 00
        add     hl,de                                          ;#48B9: 19
        ex      de,hl                                          ;#48BA: EB
        ld      h,a                                            ;#48BB: 67
        ; Remaining logo lines are 14 cols width.
        ld      a,0Eh                                          ;#48BC: 3E 0E
        sub     c                                              ;#48BE: 91
        ld      b,a                                            ;#48BF: 47
        ld      a,h                                            ;#48C0: 7C
        dec     c                                              ;#48C1: 0D
        jr      nz,KONAMI_LOGO_WRITE_DONE                      ;#48C2: 20 E9
        ld      bc,0Ch                                         ;#48C4: 01 0C 00
        xor     a                                              ;#48C7: AF
        call    FILL_VRAM                                      ;#48C8: CD FD 44
        ld      hl,VDP_TEMP_AREA                               ;#48CB: 21 0A E0
        dec     (hl)                                           ;#48CE: 35
        ret                                                    ;#48CF: C9

WRITE_VRAM_BYTE:
        ; Writes single byte in A to VRAM at current address
        call    SET_VDP                                        ;#48D0: CD E2 48
        exx                                                    ;#48D3: D9
        out     (c),a                                          ;#48D4: ED 79
        exx                                                    ;#48D6: D9
        ei                                                     ;#48D7: FB
        ret                                                    ;#48D8: C9

READ_VRAM_BYTE:
        ; Reads single byte from VRAM into A
        call    SET_VDP_READ                                   ;#48D9: CD F1 48
        exx                                                    ;#48DC: D9
        in      a,(c)                                          ;#48DD: ED 78
        exx                                                    ;#48DF: D9
        ei                                                     ;#48E0: FB
        ret                                                    ;#48E1: C9

SET_VDP:
        ; Set VDP address
        ex      af,af'                                         ;#48E2: 08
        ex      de,hl                                          ;#48E3: EB
        call    BIOS_SETWRT                                    ;#48E4: CD 53 00
        di                                                     ;#48E7: F3
        ex      de,hl                                          ;#48E8: EB
        exx                                                    ;#48E9: D9
        ld      a,(BIOS_VDP_98)                                ;#48EA: 3A 06 00
        ld      c,a                                            ;#48ED: 4F
        exx                                                    ;#48EE: D9
        ex      af,af'                                         ;#48EF: 08
        ret                                                    ;#48F0: C9

SET_VDP_READ:
        ; Set VDP address for read (BIOS_SETRD variant)
        ex      de,hl                                          ;#48F1: EB
        call    BIOS_SETRD                                     ;#48F2: CD 50 00
        di                                                     ;#48F5: F3
        ex      de,hl                                          ;#48F6: EB
        exx                                                    ;#48F7: D9
        ld      a,(BIOS_VDP_99)                                ;#48F8: 3A 07 00
        ld      c,a                                            ;#48FB: 4F
        exx                                                    ;#48FC: D9
        ret                                                    ;#48FD: C9

ADD_HL_A:
        ; HL = HL + A
        add     a,l                                            ;#48FE: 85
        ld      l,a                                            ;#48FF: 6F
        ret     nc                                             ;#4900: D0
        inc     h                                              ;#4901: 24
        ret                                                    ;#4902: C9

ADD_DE_A:
        ; DE = DE + A
        add     a,e                                            ;#4903: 83
        ld      e,a                                            ;#4904: 5F
        ret     nc                                             ;#4905: D0
        inc     d                                              ;#4906: 14
        ret                                                    ;#4907: C9

GAME_STATE_15_HANDLER:
        ; Game state 15: Antarctic map animation
        ld      a,(GAME_SUBSTATE)                              ;#4908: 3A 01 E0
        call    JUMP_TABLE_DISPATCHER                          ;#490B: CD B2 40
        dw      MAP_INIT                                       ;#490E: 1C 49
        dw      MAP_DRAW_HORIZONTAL_BORDER_TOP                 ;#4910: 36 49
        dw      MAP_DRAW_TILES                                 ;#4912: 3D 49
        dw      MAP_DRAW_HORIZONTAL_BORDER_BOTTOM              ;#4914: 74 49
        dw      MAP_PATH_INIT                                  ;#4916: 90 49
        dw      MAP_UPDATE_PATH                                ;#4918: 9D 49
        dw      MAP_EXIT_WAIT                                  ;#491A: F4 49

MAP_INIT:
        ; Substate 0: Initialize map pointers and background fill
        ld      hl,MAP_DRAW_COMMANDS_TABLE                     ;#491C: 21 01 4A
        ld      (MAP_DATA_PTR),hl                              ;#491F: 22 F2 E0
        LOAD_NAME_TABLE hl, 4, 4                               ;#4922: 21 84 38
        ld      (MAP_VRAM_ADDR),hl                             ;#4925: 22 F0 E0
        LOAD_VRAM_ADDRESS de, 1080h                            ;#4928: 11 80 10
        ld      bc,180h                                        ;#492B: 01 80 01
        LOAD_VRAM_COLOR a, COLOR_WHITE, COLOR_DARK_BLUE        ;#492E: 3E F4
        call    FILL_VRAM                                      ;#4930: CD FD 44
        jp      INCREMENT_SUBSTATE                             ;#4933: C3 1C 44

MAP_DRAW_HORIZONTAL_BORDER_TOP:
        ; Substate 1: Draw first part of UI borders
        LOAD_NAME_TABLE de, 4, 3                               ;#4936: 11 83 38
        ld      a,92h                                          ;#4939: 3E 92
        jr      MAP_DRAW_HORIZONTAL_BORDER_DIRECT              ;#493B: 18 3C

MAP_DRAW_TILES:
        ; Substate 2: Incremental map rendering from data stream
        ld      a,(FRAME_COUNTER)                              ;#493D: 3A 03 E0
        rra                                                    ;#4940: 1F
        ret     c                                              ;#4941: D8
        ld      hl,(MAP_VRAM_ADDR)                             ;#4942: 2A F0 E0
        ld      a,20h                                          ;#4945: 3E 20
        call    ADD_HL_A                                       ;#4947: CD FE 48
        ld      (MAP_VRAM_ADDR),hl                             ;#494A: 22 F0 E0
        ex      de,hl                                          ;#494D: EB
        push    de                                             ;#494E: D5
        ld      a,0Ah                                          ;#494F: 3E 0A
        ld      bc,18h                                         ;#4951: 01 18 00
        call    FILL_VRAM                                      ;#4954: CD FD 44
        pop     de                                             ;#4957: D1
        inc     de                                             ;#4958: 13
        ld      a,4                                            ;#4959: 3E 04
        ld      c,16h                                          ;#495B: 0E 16
        call    FILL_VRAM                                      ;#495D: CD FD 44
        ld      hl,(MAP_DATA_PTR)                              ;#4960: 2A F2 E0
        ld      a,(hl)                                         ;#4963: 7E
        inc     hl                                             ;#4964: 23
        or      a                                              ;#4965: B7
        jp      z,INCREMENT_SUBSTATE                           ;#4966: CA 1C 44
        ld      e,a                                            ;#4969: 5F
        inc     a                                              ;#496A: 3C
        jr      z,MAP_DRAW_UPDATE_PTR                          ;#496B: 28 03
        call    WRITE_VRAM_STREAM_WITH_OFFSET                  ;#496D: CD AC 45
MAP_DRAW_UPDATE_PTR:
        ; Save map data pointer
        ld      (MAP_DATA_PTR),hl                              ;#4970: 22 F2 E0
        ret                                                    ;#4973: C9

MAP_DRAW_HORIZONTAL_BORDER_BOTTOM:
        ; Substate 3: Draw second part of UI borders
        LOAD_NAME_TABLE de, 21, 3                              ;#4974: 11 A3 3A
        ld      a,91h                                          ;#4977: 3E 91
MAP_DRAW_HORIZONTAL_BORDER_DIRECT:
        ; Shared horizontal border drawing routine for map UI
        call    WRITE_VRAM_BYTE                                ;#4979: CD D0 48
        inc     de                                             ;#497C: 13
        ld      bc,18h                                         ;#497D: 01 18 00
        add     a,4                                            ;#4980: C6 04
        push    af                                             ;#4982: F5
        call    FILL_VRAM                                      ;#4983: CD FD 44
        pop     af                                             ;#4986: F1
        sub     2                                              ;#4987: D6 02
        exx                                                    ;#4989: D9
        out     (c),a                                          ;#498A: ED 79
        exx                                                    ;#498C: D9
        jp      INCREMENT_SUBSTATE                             ;#498D: C3 1C 44

MAP_PATH_INIT:
        ; Substate 4: Initialize path pointers and step index
        LOAD_NAME_TABLE hl, 16, 20                             ;#4990: 21 14 3A
        ld      (PATH_VRAM_PTR),hl                             ;#4993: 22 F4 E0
        xor     a                                              ;#4996: AF
        ld      (MAP_STEP_INDEX),a                             ;#4997: 32 F6 E0
        jp      INCREMENT_SUBSTATE                             ;#499A: C3 1C 44

MAP_UPDATE_PATH:
        ; Move penguin icon along path tracking indices
        ld      a,(FRAME_COUNTER)                              ;#499D: 3A 03 E0
        rra                                                    ;#49A0: 1F
        ret     c                                              ;#49A1: D8
        ld      hl,MAP_STEP_INDEX                              ;#49A2: 21 F6 E0
        ld      a,(hl)                                         ;#49A5: 7E
        ld      de,MAP_PATH_DATA                               ;#49A6: 11 B0 4A
        call    ADD_DE_A                                       ;#49A9: CD 03 49
        ld      a,(de)                                         ;#49AC: 1A
        ld      (VRAM_UPDATE_BUFFER),a                         ;#49AD: 32 D0 E0
        cp      20h                                            ;#49B0: FE 20
        jp      z,INCREMENT_SUBSTATE                           ;#49B2: CA 1C 44
        inc     (hl)                                           ;#49B5: 34
        ld      c,97h                                          ;#49B6: 0E 97
        ld      a,(MAP_PROGRESS_LIMIT)                         ;#49B8: 3A E7 E0
        cp      (hl)                                           ;#49BB: BE
        jr      c,MAP_UPDATE_PATH_PROCESS                      ;#49BC: 38 02
        ld      c,0A4h                                         ;#49BE: 0E A4
MAP_UPDATE_PATH_PROCESS:
        ; Process penguin path movement
        ld      hl,VRAM_UPDATE_BUFFER                          ;#49C0: 21 D0 E0
        xor     a                                              ;#49C3: AF
        rrd                                                    ;#49C4: ED 67
        ld      b,a                                            ;#49C6: 47
        ld      a,(hl)                                         ;#49C7: 7E
        ld      hl,MAP_PATH_MOVEMENT_TABLE                     ;#49C8: 21 E1 49
        call    ADD_HL_A                                       ;#49CB: CD FE 48
        ld      de,(PATH_VRAM_PTR)                             ;#49CE: ED 5B F4 E0
        call    JUMP_TO_HL                                     ;#49D2: CD E0 49
        ld      (PATH_VRAM_PTR),de                             ;#49D5: ED 53 F4 E0
        ld      a,b                                            ;#49D9: 78
        add     a,c                                            ;#49DA: 81
        call    WRITE_VRAM_BYTE                                ;#49DB: CD D0 48
        scf                                                    ;#49DE: 37
        ret                                                    ;#49DF: C9

JUMP_TO_HL:
        ; Generic jump via HL helper
        jp      (hl)                                           ;#49E0: E9

MAP_PATH_MOVEMENT_TABLE:
        ; Table of VRAM update handlers for penguin path icon
        ; Indexed-jump dispatch table — NOT unreachable code.
        ; Reached via MAP_PATH_MOVEMENT_TABLE + (high-nibble * 4) of
        ; the MAP_PATH_DATA step byte.
        ld      a,-20h ; UP                                    ;#49E1: 3E E0
        jr      MAP_MOVE_ADJUST_HIGH_BYTE                      ;#49E3: 18 0A
        ld      a,1 ; RIGHT                                    ;#49E5: 3E 01
        jr      MAP_MOVE_ADD_OFFSET                            ;#49E7: 18 07
        ld      a,20h ; DOWN                                   ;#49E9: 3E 20
        jr      MAP_MOVE_ADD_OFFSET                            ;#49EB: 18 03
        ld      a,-1 ; LEFT                                    ;#49ED: 3E FF

MAP_MOVE_ADJUST_HIGH_BYTE:
        ; Adjust high byte for negative offset
        dec     d                                              ;#49EF: 15
MAP_MOVE_ADD_OFFSET:
        ; Add offset to VRAM pointer
        call    ADD_DE_A                                       ;#49F0: CD 03 49
        ret                                                    ;#49F3: C9

MAP_EXIT_WAIT:
        ; Substate 6: Transition delay before state 9
        ld      hl,WAIT_TIMER                                  ;#49F4: 21 04 E0
        dec     (hl)                                           ;#49F7: 35
        ret     nz                                             ;#49F8: C0
        ld      a,ID_STATE_9                                   ;#49F9: 3E 09
        ld      (GAME_STATE),a                                 ;#49FB: 32 00 E0
        jp      INCREMENT_STATE_WITH_FIXED_DELAY               ;#49FE: C3 09 44

MAP_DRAW_COMMANDS_TABLE:
        ; Data block for map drawing VRAM commands
        ; Format: FORMAT_MAP_DRAW_COMMANDS
        ; - Script for drawing the world map screen.
        ; - Each entry: [offset, byte stream..., 0FFh]; offset advances row VRAM ptr (DE).
        ; - Bytes in the stream are written sequentially to VRAM, advancing DE each byte.
        ; - 0FFh terminates the current entry; 00h terminates the whole table.
        db      0FFh                                           ;#4A01: FF
        MAP_COMMANDS 0CEh, "5E5F6061", 0FFh                    ;#4A02: CE 5E 5F 60 61 FF
        MAP_COMMANDS 0EDh, "620F0F0F0F0F636465", 0FFh          ;#4A08: ED 62 0F 0F 0F 0F 0F 63 64 65 FF
        MAP_COMMANDS 8, "6604040404670F0F0F0F0F0F0F68", 0FFh   ;#4A13: 08 66 04 04 04 04 67 0F 0F 0F 0F 0F 0F 0F 68 FF
        MAP_COMMANDS 28h, "696A6488897E0F0F0F0F0F0F0F6B", 0FFh  ;#4A23: 28 69 6A 64 88 89 7E 0F 0F 0F 0F 0F 0F 0F 6B FF
        MAP_COMMANDS 49h, "6C6D7F07800F0F0F0F0F0F0F61", 0FFh   ;#4A33: 49 6C 6D 7F 07 80 0F 0F 0F 0F 0F 0F 0F 61 FF
        MAP_COMMANDS 6Ah, "6781820F0F0F8D8E8F900F0F6E", 0FFh   ;#4A42: 6A 67 81 82 0F 0F 0F 8D 8E 8F 90 0F 0F 6E FF
        MAP_COMMANDS 8Ah, "6F0F0F0F0F0F8C0F0F0F0F0F70", 0FFh   ;#4A51: 8A 6F 0F 0F 0F 0F 0F 8C 0F 0F 0F 0F 0F 70 FF
        MAP_COMMANDS 0ABh, "710F0F83840F0F0F0F0F0F72", 0FFh    ;#4A60: AB 71 0F 0F 83 84 0F 0F 0F 0F 0F 0F 72 FF
        MAP_COMMANDS 0CBh, "730F0F8507860F0F0F0F0F74", 0FFh    ;#4A6E: CB 73 0F 0F 85 07 86 0F 0F 0F 0F 0F 74 FF
        MAP_COMMANDS 0EBh, "6975768A8B870F0F0F0F77", 0FFh      ;#4A7C: EB 69 75 76 8A 8B 87 0F 0F 0F 0F 77 FF
        MAP_COMMANDS 10h, "780F0F0F0F79", 0FFh                 ;#4A89: 10 78 0F 0F 0F 0F 79 FF
        MAP_COMMANDS 30h, "7A757B7C7D", 0FFh                   ;#4A91: 30 7A 75 7B 7C 7D FF
        db      0FFh                                           ;#4A98: FF
        MAP_COMMANDS 67h, "212E342132233429232104041A2B2F2E212D29", 0FFh  ;#4A99: 67 21 2E 34 21 32 23 34 29 23 21 04 04 1A 2B 2F 2E 21 2D 29 FF
        db      0FFh                                           ;#4AAE: FF
        db      00h                                            ;#4AAF: 00

MAP_PATH_DATA:
        ; Data block defining the penguin route coordinates and tile steps
        ; Format: FORMAT_MAP_PATH_DATA
        ; - Each byte is MAP_DIR_* (high nibble 0/4/8/Ch = UP/RIGHT/DOWN/LEFT) OR'd with
        ; a tile index (low nibble 0..Fh).
        ; - MAP_UPDATE_PATH consumes one byte per odd frame: the high nibble indexes
        ; MAP_PATH_MOVEMENT_TABLE to move PATH_VRAM_PTR, and the low nibble is added
        ; to a tile base (97h before MAP_PROGRESS_LIMIT, A4h after) for the VRAM write.
        ; - 20h terminates the path (MAP_UPDATE_PATH leaves the substate).
        MAP_STEP MAP_DIR_LEFT, 4                               ;#4AB0: C4
        MAP_STEP MAP_DIR_LEFT, 4                               ;#4AB1: C4
        MAP_STEP MAP_DIR_LEFT, 0                               ;#4AB2: C0
        MAP_STEP MAP_DIR_UP, 0Bh                               ;#4AB3: 0B
        MAP_STEP MAP_DIR_UP, 2                                 ;#4AB4: 02
        MAP_STEP MAP_DIR_UP, 2                                 ;#4AB5: 02
        MAP_STEP MAP_DIR_LEFT, 5                               ;#4AB6: C5
        MAP_STEP MAP_DIR_UP, 0Ch                               ;#4AB7: 0C
        MAP_STEP MAP_DIR_LEFT, 5                               ;#4AB8: C5
        MAP_STEP MAP_DIR_LEFT, 5                               ;#4AB9: C5
        MAP_STEP MAP_DIR_LEFT, 6                               ;#4ABA: C6
        MAP_STEP MAP_DIR_DOWN, 6                               ;#4ABB: 86
        MAP_STEP MAP_DIR_DOWN, 7                               ;#4ABC: 87
        MAP_STEP MAP_DIR_LEFT, 5                               ;#4ABD: C5
        MAP_STEP MAP_DIR_UP, 2                                 ;#4ABE: 02
        MAP_STEP MAP_DIR_UP, 0Ch                               ;#4ABF: 0C
        MAP_STEP MAP_DIR_UP, 0Ah                               ;#4AC0: 0A
        MAP_STEP MAP_DIR_UP, 9                                 ;#4AC1: 09
        MAP_STEP MAP_DIR_RIGHT, 8                              ;#4AC2: 48
        MAP_STEP MAP_DIR_RIGHT, 3                              ;#4AC3: 43
        MAP_STEP MAP_DIR_UP, 0Ch                               ;#4AC4: 0C
        MAP_STEP MAP_DIR_UP, 0Ch                               ;#4AC5: 0C
        MAP_STEP MAP_DIR_UP, 1                                 ;#4AC6: 01
        MAP_STEP MAP_DIR_RIGHT, 5                              ;#4AC7: 45
        MAP_STEP MAP_DIR_RIGHT, 5                              ;#4AC8: 45
        MAP_STEP MAP_DIR_RIGHT, 5                              ;#4AC9: 45
        MAP_STEP MAP_DIR_RIGHT, 2                              ;#4ACA: 42
        MAP_STEP MAP_DIR_DOWN, 5                               ;#4ACB: 85
        MAP_STEP MAP_DIR_RIGHT, 7                              ;#4ACC: 47
        MAP_STEP MAP_DIR_RIGHT, 2                              ;#4ACD: 42
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4ACE: 82
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4ACF: 82
        MAP_STEP MAP_DIR_DOWN, 5                               ;#4AD0: 85
        MAP_STEP MAP_DIR_RIGHT, 0Bh                            ;#4AD1: 4B
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4AD2: 82
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4AD3: 82
        MAP_STEP MAP_DIR_DOWN, 0Bh                             ;#4AD4: 8B
        MAP_STEP MAP_DIR_LEFT, 4                               ;#4AD5: C4
        MAP_STEP MAP_DIR_DOWN, 2                               ;#4AD6: 82
        MAP_STEP MAP_DIR_DOWN, 0Bh                             ;#4AD7: 8B
        MAP_END                                                ;#4AD8: 20

STAGE_DISTANCE_TABLE:
        ; Data table for stage distances and difficulty settings
        ; Format: FORMAT_STAGE_DISTANCE_TABLE
        ; - 10 entries. Each STAGE_ENTRY writes dist_hi (byte 0), map_offset (byte 1),
        ; and initial timer value (bytes 2-3, little-endian).
        ; - Consumed by stage-init code to set the total distance (dist_hi << 8),
        ; the starting offset into MAP_PATH_DATA, and the initial stage timer.
        STAGE_ENTRY 1500h, 0, 100h                             ;#4AD9: 15 00 00 01
        STAGE_ENTRY 1700h, 3, 120h                             ;#4ADD: 17 03 20 01
        STAGE_ENTRY 1100h, 8, 80h                              ;#4AE1: 11 08 80 00
        STAGE_ENTRY 1200h, 0Ch, 80h                            ;#4AE5: 12 0C 80 00
        STAGE_ENTRY 1200h, 10h, 80h                            ;#4AE9: 12 10 80 00
        STAGE_ENTRY 500h, 15h, 40h                             ;#4AED: 05 15 40 00
        STAGE_ENTRY 2600h, 16h, 165h                           ;#4AF1: 26 16 65 01
        STAGE_ENTRY 1200h, 1Dh, 90h                            ;#4AF5: 12 1D 90 00
        STAGE_ENTRY 1500h, 22h, 100h                           ;#4AF9: 15 22 00 01
        STAGE_ENTRY 1200h, 25h, 90h                            ;#4AFD: 12 25 90 00

INIT_GAMEPLAY_VARS:
        ; Initialize gameplay variables and RAM (clears E0F0-E220, sets timers)
        ld      hl,MAP_VRAM_ADDR                               ;#4B01: 21 F0 E0
        ld      de,MAP_VRAM_ADDR+1                             ;#4B04: 11 F1 E0
        ld      bc,130h                                        ;#4B07: 01 30 01
        ld      (hl),0                                         ;#4B0A: 36 00
        ldir                                                   ;#4B0C: ED B0
        ld      a,10h                                          ;#4B0E: 3E 10
        ld      h,a                                            ;#4B10: 67
        ld      l,a                                            ;#4B11: 6F
        ld      (PENGUIN_SPEED),hl                             ;#4B12: 22 00 E1
        ld      (STAGE_TIMER_VAL),a                            ;#4B15: 32 10 E1
        ld      a,8                                            ;#4B18: 3E 08
        ld      (DEMO_PLAY_MASK_TIMER),a                       ;#4B1A: 32 49 E1
        ld      a,5                                            ;#4B1D: 3E 05
        ld      (DISTANCE_TICK_TIMER),a                        ;#4B1F: 32 E9 E0
        ld      hl,3030h                                       ;#4B22: 21 30 30
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4B25: 3A E0 E0
        rra                                                    ;#4B28: 1F
        jr      nc,INIT_STAGE_GRAPHICS_SEQ                     ;#4B29: 30 03
        ld      hl,3434h                                       ;#4B2B: 21 34 34
INIT_STAGE_GRAPHICS_SEQ:
        ; Init stage graphics sequence
        ld      (ITEM_TICK_PERIOD),hl                          ;#4B2E: 22 0E E1
        ld      a,1                                            ;#4B31: 3E 01
        ld      (SELECT_CONTROLLER_DISABLED),a                 ;#4B33: 32 3B E1
        call    GFX_INIT_BANK1                                 ;#4B36: CD F2 5D
        call    GFX_INIT_BANK2                                 ;#4B39: CD 8F 62
        call    LOAD_MAIN_SPRITE_PATTERNS                      ;#4B3C: CD 56 67
        call    INIT_SPRITES_FROM_STREAM                       ;#4B3F: CD C2 66
        call    INIT_STAGE                                     ;#4B42: CD 44 50
        xor     a                                              ;#4B45: AF
        ld      (SELECT_CONTROLLER_DISABLED),a                 ;#4B46: 32 3B E1
        ret                                                    ;#4B49: C9

MAIN_GAME_ENGINE:
        ; Core game engine loop
        call    CALC_HUD_SPEED_BAR                             ;#4B4A: CD 6A 77
        call    SYNC_SPRITE_ATTRIBUTES_PARTIAL                 ;#4B4D: CD 6B 76
        ld      a,(PENGUIN_FALL_TIMER)                         ;#4B50: 3A 40 E1
        or      a                                              ;#4B53: B7
        jp      nz,HANDLE_PENGUIN_FALL                         ;#4B54: C2 94 4F
        ld      a,(PENGUIN_STUN_TIMER)                         ;#4B57: 3A 42 E1
        or      a                                              ;#4B5A: B7
        jp      nz,HANDLE_PENGUIN_STUN_ANIMATION               ;#4B5B: C2 69 4E
        call    PROCESS_PENGUIN_INPUT_AND_MOVE                 ;#4B5E: CD E0 76
        call    HANDLE_PENGUIN_MOVEMENT                        ;#4B61: CD AC 4B
        call    HANDLE_PENGUIN_DRIFT                           ;#4B64: CD B6 53
        call    HANDLE_COLLISION_FISH                          ;#4B67: CD D2 4D
        call    HANDLE_COLLISION_SEAL                          ;#4B6A: CD 0F 4E
        ld      a,(PENGUIN_FALL_TIMER)                         ;#4B6D: 3A 40 E1
        or      a                                              ;#4B70: B7
        ret     nz                                             ;#4B71: C0
        call    PROCESS_SCENE_TIMER                            ;#4B72: CD 9F 51
        call    UPDATE_STATION_FRAME                           ;#4B75: CD 19 75
        call    UPDATE_STAGE_DISTANCE                          ;#4B78: CD DC 46
        call    UPDATE_STAGE_SEQUENCE                          ;#4B7B: CD 45 47
        call    UPDATE_ITEMS                                   ;#4B7E: CD 27 52
        jp      HANDLE_DEMO_PLAY_MASKING                       ;#4B81: C3 A5 77

PENGUIN_ANIM_TABLE:
        ; Table of sprite pattern indices for penguin
        ; Format: FORMAT_PENGUIN_PATTERN
        ; - Layout: [Top-Left, Bottom-Left, Top-Right, Bottom-Right].
        ; - Used for the main penguin animations (waddling, jumping, etc.).
        PENGUIN_PATTERN 0, 4, 8, 0Ch                           ;#4B84: 00 04 08 0C
        PENGUIN_PATTERN 10h, 14h, 18h, 1Ch                     ;#4B88: 10 14 18 1C
        PENGUIN_PATTERN 20h, 24h, 28h, 2Ch                     ;#4B8C: 20 24 28 2C
        PENGUIN_PATTERN 0, 4, 30h, 34h                         ;#4B90: 00 04 30 34
        PENGUIN_PATTERN 38h, 3Ch, 40h, 44h                     ;#4B94: 38 3C 40 44
        PENGUIN_PATTERN 60h, 64h, 68h, 6Ch                     ;#4B98: 60 64 68 6C
        PENGUIN_PATTERN 20h, 48h, 4Ch, 50h                     ;#4B9C: 20 48 4C 50
        PENGUIN_PATTERN 54h, 14h, 58h, 5Ch                     ;#4BA0: 54 14 58 5C
        PENGUIN_PATTERN 10h, 0A8h, 18h, 0ACh                   ;#4BA4: 10 A8 18 AC
        PENGUIN_PATTERN 0B0h, 24h, 0B4h, 2Ch                   ;#4BA8: B0 24 B4 2C

HANDLE_PENGUIN_MOVEMENT:
        ; Handles joystick input and position updates
        ld      hl,PENGUIN_INPUT_LOCK_TIMER                    ;#4BAC: 21 F9 E0
        ld      a,(hl)                                         ;#4BAF: 7E
        or      a                                              ;#4BB0: B7
        jp      nz,UPDATE_THROTTLED_ANIMATION                  ;#4BB1: C2 18 4C
        call    READ_INPUT_EDGE                                ;#4BB4: CD 1D 46
        jp      nz,INIT_JUMP                                   ;#4BB7: C2 04 4C
        ld      a,b                                            ;#4BBA: 78
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4BBB: ED 5B 78 E0
        call    UPDATE_PENGUIN_POSITION                        ;#4BBF: CD 8C 4C
SWAP_AND_UPDATE_PENGUIN_COORDS:
        ; Swap registers and update penguin coordinates
        ex      de,hl                                          ;#4BC2: EB
UPDATE_PENGUIN_COORDS:
        ; Update penguin X/Y and secondary sprite positions
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#4BC3: CD EC 4B
SYNC_PENGUIN_SPRITES_TO_VRAM:
        ; Prepare and upload penguin sprite attributes to VRAM
        ld      hl,SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y        ;#4BC6: 21 78 E0
        LOAD_SPRITE_ATTR de, 10, 0                             ;#4BC9: 11 28 3B
        ld      bc,10h                                         ;#4BCC: 01 10 00
        call    COPY_RAM_TO_VRAM                               ;#4BCF: CD EC 44
        jp      UPDATE_GOAL_BOB_ANIM                           ;#4BD2: C3 E9 4C

UPDATE_PENGUIN_SPRITE_PATTERNS:
        ; Updates the 4 pattern indices of the 32x32 penguin (SPRITE_PENGUIN..+0Ch)
        exx                                                    ;#4BD5: D9
        ld      hl,PENGUIN_ANIM_TABLE                          ;#4BD6: 21 84 4B
        call    ADD_HL_A                                       ;#4BD9: CD FE 48
        ld      de,SAT_MIRROR + SPRITE_PENGUIN + ATTR_PATT     ;#4BDC: 11 7A E0
        ld      b,4                                            ;#4BDF: 06 04
UPDATE_PENGUIN_PATT_LOOP:
        ; Loop to copy 4 pattern indices
        ld      a,(hl)                                         ;#4BE1: 7E
        ld      (de),a                                         ;#4BE2: 12
        ld      a,4                                            ;#4BE3: 3E 04
        add     a,e                                            ;#4BE5: 83
        ld      e,a                                            ;#4BE6: 5F
        inc     hl                                             ;#4BE7: 23
        djnz    UPDATE_PENGUIN_PATT_LOOP                       ;#4BE8: 10 F7
        exx                                                    ;#4BEA: D9
        ret                                                    ;#4BEB: C9

UPDATE_PENGUIN_MULTI_SPRITE_COORDS:
        ; Updates coordinates for 32x32 penguin (SAT slots 10-13, SPRITE_PENGUIN..+0Ch)
        ld      d,h                                            ;#4BEC: 54
        ld      (SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y),hl      ;#4BED: 22 78 E0
        ld      a,h                                            ;#4BF0: 7C
        add     a,10h                                          ;#4BF1: C6 10
        ld      h,a                                            ;#4BF3: 67
        ld      (SAT_MIRROR + SPRITE_PENGUIN + 4 + ATTR_Y),hl  ;#4BF4: 22 7C E0
        ld      a,l                                            ;#4BF7: 7D
        add     a,10h                                          ;#4BF8: C6 10
        ld      l,a                                            ;#4BFA: 6F
        ld      e,a                                            ;#4BFB: 5F
        ld      (SAT_MIRROR + SPRITE_PENGUIN + 8 + ATTR_Y),de  ;#4BFC: ED 53 80 E0
        ld      (SAT_MIRROR + SPRITE_PENGUIN + 0Ch + ATTR_Y),hl ;#4C00: 22 84 E0
        ret                                                    ;#4C03: C9

INIT_JUMP:
        ; Initialize penguin jump sequence and sound
        ld      a,ID_SOUND_JUMP                                ;#4C04: 3E 02
        call    PLAY_SOUND_SAFE                                ;#4C06: CD C9 79
        ld      a,b                                            ;#4C09: 78
        and     0Ch                                            ;#4C0A: E6 0C
        jr      z,SET_JUMP_DIR                                 ;#4C0C: 28 05
        ld      a,(PENGUIN_MOVE_STATE)                         ;#4C0E: 3A FA E0
        and     3                                              ;#4C11: E6 03
SET_JUMP_DIR:
        ; Set jump direction based on move state
        ld      (PENGUIN_JUMP_STATE),a                         ;#4C13: 32 FB E0
        jr      UPDATE_ANIMATION_STEP                          ;#4C16: 18 06

UPDATE_THROTTLED_ANIMATION:
        ; Updates animation every 4th frame
        ld      a,(FRAME_COUNTER)                              ;#4C18: 3A 03 E0
        and     3                                              ;#4C1B: E6 03
        ret     nz                                             ;#4C1D: C0
UPDATE_ANIMATION_STEP:
        ; Increments animation frame and updates patterns/position
        ld      a,(hl)                                         ;#4C1E: 7E
        inc     (hl)                                           ;#4C1F: 34
        cp      0Bh                                            ;#4C20: FE 0B
        jr      nz,CALC_ANIM_FRAME_INDEX                       ;#4C22: 20 02
        ld      (hl),0                                         ;#4C24: 36 00
CALC_ANIM_FRAME_INDEX:
        ; Calculate animation frame index
        push    af                                             ;#4C26: F5
        ld      c,0                                            ;#4C27: 0E 00
        cp      0Bh                                            ;#4C29: FE 0B
        jr      z,SET_ANIM_PATTERN_INDEX                       ;#4C2B: 28 07
        ld      c,10h                                          ;#4C2D: 0E 10
        rra                                                    ;#4C2F: 1F
        jr      c,SET_ANIM_PATTERN_INDEX                       ;#4C30: 38 02
        ld      c,0Ch                                          ;#4C32: 0E 0C
SET_ANIM_PATTERN_INDEX:
        ; Set calculated pattern index
        ld      a,c                                            ;#4C34: 79
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4C35: CD D5 4B
        pop     af                                             ;#4C38: F1
        ld      hl,PENGUIN_JUMP_Y_OFFSETS                      ;#4C39: 21 80 4C
        call    ADD_HL_A                                       ;#4C3C: CD FE 48
        ld      a,(hl)                                         ;#4C3F: 7E
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4C40: ED 5B 78 E0
        add     a,e                                            ;#4C44: 83
        ld      e,a                                            ;#4C45: 5F
        ld      hl,PENGUIN_JUMP_STATE                          ;#4C46: 21 FB E0
        ld      a,(hl)                                         ;#4C49: 7E
        dec     a                                              ;#4C4A: 3D
        jr      z,JUMP_MOVE_LEFT_STEP                          ;#4C4B: 28 23
        dec     a                                              ;#4C4D: 3D
        jr      z,JUMP_MOVE_RIGHT_STEP                         ;#4C4E: 28 28
UPDATE_JUMP_SPRITES:
        ; Update sprite coordinates after jump
        ex      de,hl                                          ;#4C50: EB
        call    UPDATE_PENGUIN_COORDS                          ;#4C51: CD C3 4B
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4C54: 3A F9 E0
        or      a                                              ;#4C57: B7
        ret     nz                                             ;#4C58: C0
        call    CHECK_ITEM_COLLISIONS                          ;#4C59: CD 49 4D
        ld      a,(PENGUIN_FALL_TIMER)                         ;#4C5C: 3A 40 E1
        ld      hl,PENGUIN_STUN_TIMER                          ;#4C5F: 21 42 E1
        add     a,(hl)                                         ;#4C62: 86
        ret     nz                                             ;#4C63: C0
        ld      hl,COLLISION_PROCESSED_FLAG                    ;#4C64: 21 32 E1
        cp      (hl)                                           ;#4C67: BE
        ret     z                                              ;#4C68: C8
        ld      (hl),a                                         ;#4C69: 77
        ld      de,30h                                         ;#4C6A: 11 30 00
        jp      ADD_SCORE                                      ;#4C6D: C3 2D 46

JUMP_MOVE_LEFT_STEP:
        ; Horizontal shift left during jump
        call    MOVE_PENGUIN_LEFT                              ;#4C70: CD 9C 4C
        call    MOVE_PENGUIN_LEFT                              ;#4C73: CD 9C 4C
        jr      UPDATE_JUMP_SPRITES                            ;#4C76: 18 D8

JUMP_MOVE_RIGHT_STEP:
        ; Horizontal shift right during jump
        call    MOVE_PENGUIN_RIGHT                             ;#4C78: CD B9 4C
        call    MOVE_PENGUIN_RIGHT                             ;#4C7B: CD B9 4C
        jr      UPDATE_JUMP_SPRITES                            ;#4C7E: 18 D0

PENGUIN_JUMP_Y_OFFSETS:
        ; Table of signed Y-offsets for jumping (12 bytes)
        ; Format: FORMAT_JUMP_Y_OFFSETS
        JUMP_Y_OFFSET -4                                       ;#4C80: FC
        JUMP_Y_OFFSET -3                                       ;#4C81: FD
        JUMP_Y_OFFSET -3                                       ;#4C82: FD
        JUMP_Y_OFFSET -2                                       ;#4C83: FE
        JUMP_Y_OFFSET -1                                       ;#4C84: FF
        JUMP_Y_OFFSET -1                                       ;#4C85: FF
        JUMP_Y_OFFSET 1                                        ;#4C86: 01
        JUMP_Y_OFFSET 1                                        ;#4C87: 01
        JUMP_Y_OFFSET 2                                        ;#4C88: 02
        JUMP_Y_OFFSET 3                                        ;#4C89: 03
        JUMP_Y_OFFSET 3                                        ;#4C8A: 03
        JUMP_Y_OFFSET 4                                        ;#4C8B: 04

UPDATE_PENGUIN_POSITION:
        ; Handle player input and update X coordinate
        and     0Ch                                            ;#4C8C: E6 0C
        ret     z                                              ;#4C8E: C8
        ld      hl,PENGUIN_MOVE_STATE                          ;#4C8F: 21 FA E0
        cp      0Ch                                            ;#4C92: FE 0C
        jr      z,HANDLE_SIMULTANEOUS_LR                       ;#4C94: 28 10
        res     7,(hl)                                         ;#4C96: CB BE
        cp      4                                              ;#4C98: FE 04
        jr      nz,MOVE_PENGUIN_RIGHT                          ;#4C9A: 20 1D
MOVE_PENGUIN_LEFT:
        ; Updates X (in D) if > 20, sets direction flags
        ld      a,d                                            ;#4C9C: 7A
        cp      14h                                            ;#4C9D: FE 14
        ret     c                                              ;#4C9F: D8
        dec     d                                              ;#4CA0: 15
        set     0,(hl)                                         ;#4CA1: CB C6
        res     1,(hl)                                         ;#4CA3: CB 8E
        ret                                                    ;#4CA5: C9

HANDLE_SIMULTANEOUS_LR:
        ; Handle simultaneous Left/Right input
        ld      a,(hl)                                         ;#4CA6: 7E
        or      a                                              ;#4CA7: B7
        ret     z                                              ;#4CA8: C8
        bit     7,a                                            ;#4CA9: CB 7F
        jr      z,MAINTAIN_CURRENT_DIRECTION                   ;#4CAB: 28 06
        bit     0,a                                            ;#4CAD: CB 47
        jr      nz,MOVE_PENGUIN_LEFT                           ;#4CAF: 20 EB
        jr      MOVE_PENGUIN_RIGHT                             ;#4CB1: 18 06

MAINTAIN_CURRENT_DIRECTION:
        ; Maintain current direction flag
        set     7,(hl)                                         ;#4CB3: CB FE
        bit     1,a                                            ;#4CB5: CB 4F
        jr      nz,MOVE_PENGUIN_LEFT                           ;#4CB7: 20 E3
MOVE_PENGUIN_RIGHT:
        ; Updates X (in D) if < 204, sets direction flags
        ld      a,d                                            ;#4CB9: 7A
        cp      0CCh                                           ;#4CBA: FE CC
        ret     nc                                             ;#4CBC: D0
        set     1,(hl)                                         ;#4CBD: CB CE
        res     0,(hl)                                         ;#4CBF: CB 86
        inc     d                                              ;#4CC1: 14
        ret                                                    ;#4CC2: C9

UPDATE_PENGUIN_ANIMATION:
        ; Update penguin waddling animation
        ld      hl,PENGUIN_INPUT_LOCK_TIMER                    ;#4CC3: 21 F9 E0
        ld      a,(PENGUIN_ANIM_HOLD_FLAG)                     ;#4CC6: 3A 30 E1
        or      (hl)                                           ;#4CC9: B6
        ret     nz                                             ;#4CCA: C0
        ld      a,(FRAME_COUNTER)                              ;#4CCB: 3A 03 E0
        and     7                                              ;#4CCE: E6 07
        ret     nz                                             ;#4CD0: C0
UPDATE_PENGUIN_SPRITES:
        ; General update for penguin sprites
        ld      hl,PENGUIN_ANIM_FRAME                          ;#4CD1: 21 F8 E0
        inc     (hl)                                           ;#4CD4: 34
        ld      a,(hl)                                         ;#4CD5: 7E
        ld      c,0                                            ;#4CD6: 0E 00
        rra                                                    ;#4CD8: 1F
        jr      nc,APPLY_WALK_ANIM_PATTERN                     ;#4CD9: 30 07
        ld      c,4                                            ;#4CDB: 0E 04
        rra                                                    ;#4CDD: 1F
        jr      nc,APPLY_WALK_ANIM_PATTERN                     ;#4CDE: 30 02
        ld      c,8                                            ;#4CE0: 0E 08
APPLY_WALK_ANIM_PATTERN:
        ; Apply calculated walking animation pattern
        ld      a,c                                            ;#4CE2: 79
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4CE3: CD D5 4B
        jp      SYNC_PENGUIN_SPRITES_TO_VRAM                   ;#4CE6: C3 C6 4B

UPDATE_GOAL_BOB_ANIM:
        ; Logic for penguin bobbing animation at the finish line
        ld      hl,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4CE9: 2A 78 E0
        ld      a,l                                            ;#4CEC: 7D
        add     a,1Eh                                          ;#4CED: C6 1E
        ld      l,a                                            ;#4CEF: 6F
        ld      c,a                                            ;#4CF0: 4F
        ld      a,h                                            ;#4CF1: 7C
        add     a,10h                                          ;#4CF2: C6 10
        ld      b,a                                            ;#4CF4: 47
        ld      de,GOAL_PENGUIN_BOB_Y-1                        ;#4CF5: 11 29 4D
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4CF8: 3A F9 E0
        or      a                                              ;#4CFB: B7
        jr      nz,APPLY_BOB_OFFSET                            ;#4CFC: 20 09
        ld      de,GOAL_PENGUIN_BOB_Y+9                        ;#4CFE: 11 33 4D
        ld      a,(PENGUIN_EVENT_TIMER)                        ;#4D01: 3A 43 E1
        or      a                                              ;#4D04: B7
        jr      z,BUFFER_PENGUIN_ATTRS                         ;#4D05: 28 10
APPLY_BOB_OFFSET:
        ; Apply bobbing Y-offset to penguin position
        ex      de,hl                                          ;#4D07: EB
        call    ADD_HL_A                                       ;#4D08: CD FE 48
        ld      l,(hl)                                         ;#4D0B: 6E
        ld      a,d                                            ;#4D0C: 7A
        add     a,l                                            ;#4D0D: 85
        ld      d,a                                            ;#4D0E: 57
        ld      a,b                                            ;#4D0F: 78
        sub     l                                              ;#4D10: 95
        ld      b,a                                            ;#4D11: 47
        ld      e,0AEh                                         ;#4D12: 1E AE
        ld      c,0AEh                                         ;#4D14: 0E AE
        ex      de,hl                                          ;#4D16: EB
BUFFER_PENGUIN_ATTRS:
        ; Store calculated shadow attributes into SAT_MIRROR slots 20-21
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_Y),hl       ;#4D17: 22 A0 E0
        ; Packed 2-byte write: sprite-21 Y + X. The penguin shadow is rendered as two
        ; sprites side by side — sprite 20 (SPRITE_SHADOW) is the left half, sprite 21
        ; is the right half. Both share the SAT_MIRROR slots E0A0..E0A7.
        ld      (SAT_MIRROR + SPRITE_21 + ATTR_Y),bc           ;#4D1A: ED 43 A4 E0
COPY_PENGUIN_ATTRS_TO_VRAM:
        ; Upload penguin attribute buffer to VRAM
        ld      hl,SAT_MIRROR + SPRITE_SHADOW + ATTR_Y         ;#4D1E: 21 A0 E0
        LOAD_SPRITE_ATTR de, 20, 0                             ;#4D21: 11 50 3B
        ld      bc,8                                           ;#4D24: 01 08 00
        jp      COPY_RAM_TO_VRAM                               ;#4D27: C3 EC 44

GOAL_PENGUIN_BOB_Y:
        ; Penguin bobbing Y-offsets during goal sequence
        ; Format: FORMAT_BOB_Y_OFFSETS
        BOB_Y_OFFSET 1                                         ;#4D2A: 01
        BOB_Y_OFFSET 2                                         ;#4D2B: 02
        BOB_Y_OFFSET 2                                         ;#4D2C: 02
        BOB_Y_OFFSET 3                                         ;#4D2D: 03
        BOB_Y_OFFSET 3                                         ;#4D2E: 03
        BOB_Y_OFFSET 3                                         ;#4D2F: 03
        BOB_Y_OFFSET 3                                         ;#4D30: 03
        BOB_Y_OFFSET 3                                         ;#4D31: 03
        BOB_Y_OFFSET 2                                         ;#4D32: 02
        BOB_Y_OFFSET 2                                         ;#4D33: 02
        BOB_Y_OFFSET 1                                         ;#4D34: 01
        BOB_Y_OFFSET 1                                         ;#4D35: 01
        BOB_Y_OFFSET 2                                         ;#4D36: 02
        BOB_Y_OFFSET 2                                         ;#4D37: 02
        BOB_Y_OFFSET 3                                         ;#4D38: 03
        BOB_Y_OFFSET 2                                         ;#4D39: 02
        BOB_Y_OFFSET 2                                         ;#4D3A: 02
        BOB_Y_OFFSET 1                                         ;#4D3B: 01
        BOB_Y_OFFSET 0                                         ;#4D3C: 00
        BOB_Y_OFFSET 1                                         ;#4D3D: 01
        BOB_Y_OFFSET 2                                         ;#4D3E: 02
        BOB_Y_OFFSET 2                                         ;#4D3F: 02
        BOB_Y_OFFSET 2                                         ;#4D40: 02
        BOB_Y_OFFSET 1                                         ;#4D41: 01
        BOB_Y_OFFSET 0                                         ;#4D42: 00
        BOB_Y_OFFSET 1                                         ;#4D43: 01
        BOB_Y_OFFSET 2                                         ;#4D44: 02
        BOB_Y_OFFSET 2                                         ;#4D45: 02
        BOB_Y_OFFSET 2                                         ;#4D46: 02
        BOB_Y_OFFSET 1                                         ;#4D47: 01
        BOB_Y_OFFSET 0                                         ;#4D48: 00

CHECK_ITEM_COLLISIONS:
        ; Walk ITEM_TABLE and check item collisions vs penguin
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4D49: 3A F9 E0
        or      a                                              ;#4D4C: B7
        ret     nz                                             ;#4D4D: C0
        ld      b,4                                            ;#4D4E: 06 04
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#4D50: 3A E0 E0
        cp      5                                              ;#4D53: FE 05
        jr      c,COLLISION_CHECK_LOOP_ENTRY                   ;#4D55: 38 01
        inc     b                                              ;#4D57: 04
COLLISION_CHECK_LOOP_ENTRY:
        ; Setup HL and B for item collision loop
        ld      hl,ITEM_TABLE                                  ;#4D58: 21 12 E1
COLLISION_CHECK_LOOP:
        ; Main item collision loop
        ld      a,(hl)                                         ;#4D5B: 7E
        cp      0Dh                                            ;#4D5C: FE 0D
        ld      a,5                                            ;#4D5E: 3E 05
        jr      nz,COLLISION_NEXT_ENTITY                       ;#4D60: 20 2D
        inc     hl                                             ;#4D62: 23
        ld      c,(hl)                                         ;#4D63: 4E
        inc     hl                                             ;#4D64: 23
        inc     hl                                             ;#4D65: 23
        inc     hl                                             ;#4D66: 23
        ld      e,(hl)                                         ;#4D67: 5E
        inc     hl                                             ;#4D68: 23
        ld      d,(hl)                                         ;#4D69: 56
        ex      de,hl                                          ;#4D6A: EB
        dec     a                                              ;#4D6B: 3D
        cp      c                                              ;#4D6C: B9
        ld      a,(PENGUIN_X_POS)                              ;#4D6D: 3A 79 E0
        jr      nc,COLLISION_BRANCH_X                          ;#4D70: 30 08
        sub     (hl)                                           ;#4D72: 96
        inc     hl                                             ;#4D73: 23
        cp      (hl)                                           ;#4D74: BE
        jp      c,HANDLE_COLLISION_FLAG                        ;#4D75: DA 1C 50
        jr      COLLISION_SKIP_ENTITY                          ;#4D78: 18 13

COLLISION_BRANCH_X:
        ; Check X-coordinate collision
        ld      c,(hl)                                         ;#4D7A: 4E
        dec     c                                              ;#4D7B: 0D
        jr      z,COLLISION_BRANCH_Y                           ;#4D7C: 28 08
        ld      c,a                                            ;#4D7E: 4F
        sub     (hl)                                           ;#4D7F: 96
        inc     hl                                             ;#4D80: 23
        cp      (hl)                                           ;#4D81: BE
        jp      c,HANDLE_COLLISION_FALL                        ;#4D82: DA 4B 4F
        ld      a,c                                            ;#4D85: 79
COLLISION_BRANCH_Y:
        ; Check Y-coordinate collision
        inc     hl                                             ;#4D86: 23
        sub     (hl)                                           ;#4D87: 96
        inc     hl                                             ;#4D88: 23
        cp      (hl)                                           ;#4D89: BE
        jp      c,HANDLE_COLLISION_HOLE                        ;#4D8A: DA 26 4E
COLLISION_SKIP_ENTITY:
        ; Skip currently checked entity
        ex      de,hl                                          ;#4D8D: EB
        xor     a                                              ;#4D8E: AF
COLLISION_NEXT_ENTITY:
        ; Advance to next entity in table
        inc     a                                              ;#4D8F: 3C
        call    ADD_HL_A                                       ;#4D90: CD FE 48
        djnz    COLLISION_CHECK_LOOP                           ;#4D93: 10 C6
        ret                                                    ;#4D95: C9

CHECK_COLLISIONS_WHILE_LOCKED:
        ; Secondary collision check while input is locked (stun/fall/goal-walk)
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4D96: 3A F9 E0
        or      a                                              ;#4D99: B7
        ret     z                                              ;#4D9A: C8
        ld      b,5                                            ;#4D9B: 06 05
        ld      hl,ITEM_TABLE                                  ;#4D9D: 21 12 E1
LOCKED_COLLISION_LOOP:
        ; Loop body of CHECK_COLLISIONS_WHILE_LOCKED (one ITEM_TABLE slot per iteration)
        ld      a,(hl)                                         ;#4DA0: 7E
        inc     hl                                             ;#4DA1: 23
        cp      0Dh                                            ;#4DA2: FE 0D
        ld      a,5                                            ;#4DA4: 3E 05
        jr      nz,LOCKED_COLLISION_NEXT                       ;#4DA6: 20 14
        ex      de,hl                                          ;#4DA8: EB
        ld      a,(de)                                         ;#4DA9: 1A
        cp      5                                              ;#4DAA: FE 05
        add     a,a                                            ;#4DAC: 87
        ld      hl,LOCKED_COLLISION_TABLE                      ;#4DAD: 21 C8 4D
        call    ADD_HL_A                                       ;#4DB0: CD FE 48
        ld      a,(PENGUIN_X_POS)                              ;#4DB3: 3A 79 E0
        sub     (hl)                                           ;#4DB6: 96
        inc     hl                                             ;#4DB7: 23
        cp      (hl)                                           ;#4DB8: BE
        jr      c,LOCKED_COLLISION_MATCH                       ;#4DB9: 38 07
        ex      de,hl                                          ;#4DBB: EB
LOCKED_COLLISION_NEXT:
        ; Advance to the next ITEM_TABLE slot
        call    ADD_HL_A                                       ;#4DBC: CD FE 48
        djnz    LOCKED_COLLISION_LOOP                          ;#4DBF: 10 DF
        ret                                                    ;#4DC1: C9

LOCKED_COLLISION_MATCH:
        ; On match, set COLLISION_PROCESSED_FLAG and return
        ld      a,1                                            ;#4DC2: 3E 01
        ld      (COLLISION_PROCESSED_FLAG),a                   ;#4DC4: 32 32 E1
        ret                                                    ;#4DC7: C9

LOCKED_COLLISION_TABLE:
        ; X-range pairs (low_x, width) used by CHECK_COLLISIONS_WHILE_LOCKED
        ; Format: LOCKED_COLLISION
        LOCKED_COLLISION 58h, 30h                              ;#4DC8: 58 30
        LOCKED_COLLISION 18h, 30h                              ;#4DCA: 18 30
        LOCKED_COLLISION 98h, 30h                              ;#4DCC: 98 30
        LOCKED_COLLISION 2Ch, 58h                              ;#4DCE: 2C 58
        LOCKED_COLLISION 64h, 58h                              ;#4DD0: 64 58

HANDLE_COLLISION_FISH:
        ; Mid-air fish catch via CURRENT_ENTITY_POINTER: +300, jingle, hides SPRITE_ITEM
        ; Skip processing while stun/fall state is active (early-return gate).
        ld      a,(PENGUIN_STUN_TIMER)                         ;#4DD2: 3A 42 E1
        ld      hl,PENGUIN_FALL_TIMER                          ;#4DD5: 21 40 E1
        add     a,(hl)                                         ;#4DD8: 86
        ret     nz                                             ;#4DD9: C0
        ; Load active obstacle entity pointer and discard hidden entries (Y=E0h).
        ld      de,(CURRENT_ENTITY_POINTER)                    ;#4DDA: ED 5B 88 E1
        ld      a,e                                            ;#4DDE: 7B
        cp      0E0h                                           ;#4DDF: FE E0
        ret     z                                              ;#4DE1: C8
        ; Near-field collision math against penguin sprite coordinates.
        ld      hl,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4DE2: 2A 78 E0
        ; Fast horizontal reject: a = obstacle_x - penguin_x, ret if |X diff| >= 10.
        sub     l                                              ;#4DE5: 95
        ld      e,a                                            ;#4DE6: 5F
        sub     0Ah                                            ;#4DE7: D6 0A
        ret     nc                                             ;#4DE9: D0
        ; Weighted X/Y threshold test; carry indicates overlap.
        ld      a,13h                                          ;#4DEA: 3E 13
        add     a,e                                            ;#4DEC: 83
        ld      l,a                                            ;#4DED: 6F
        ld      a,e                                            ;#4DEE: 7B
        add     a,a                                            ;#4DEF: 87
        add     a,17h                                          ;#4DF0: C6 17
        ld      e,a                                            ;#4DF2: 5F
        ld      a,d                                            ;#4DF3: 7A
        sub     h                                              ;#4DF4: 94
        sub     l                                              ;#4DF5: 95
        add     a,e                                            ;#4DF6: 83
        ret     nc                                             ;#4DF7: D0
        ; Item-catch collision response: play catch SFX, hide item sprite, +300.
        ld      a,ID_SOUND_CATCH_FISH                          ;#4DF8: 3E 07
        call    PLAY_SOUND_SAFE                                ;#4DFA: CD C9 79
        ld      hl,SAT_MIRROR + SPRITE_ITEM + ATTR_Y           ;#4DFD: 21 8C E0
        ld      de,FISH_POS_STATE                              ;#4E00: 11 83 E1
        call    HIDE_DYNAMIC_SPRITE                            ;#4E03: CD C5 76
        call    SYNC_SPRITE_LOOP                               ;#4E06: CD 70 76
        ld      de,300h                                        ;#4E09: 11 00 03
        jp      ADD_SCORE                                      ;#4E0C: C3 2D 46

HANDLE_COLLISION_SEAL:
        ; Seal collision: fires when SPRITE_OBSTACLE Y == 8Fh (seal-on-ground)
        ld      hl,(SAT_MIRROR + SPRITE_OBSTACLE + ATTR_Y)     ;#4E0F: 2A 90 E0
        ld      a,l                                            ;#4E12: 7D
        ; Y-position gate: obstacle must be at Y=8Fh (on-road row) for heavy-stumble.
        cp      8Fh                                            ;#4E13: FE 8F
        ret     nz                                             ;#4E15: C0
        ld      a,(PENGUIN_X_POS)                              ;#4E16: 3A 79 E0
        ld      l,a                                            ;#4E19: 6F
        ld      a,h                                            ;#4E1A: 7C
        sub     l                                              ;#4E1B: 95
        ; Preserve signed X relation (flags) before range transform.
        push    af                                             ;#4E1C: F5
        sub     18h                                            ;#4E1D: D6 18
        add     a,23h                                          ;#4E1F: C6 23
        ; Carry branch enters HANDLE_STUMBLE_LARGE for heavy obstacle collisions.
        jp      c,HANDLE_STUMBLE_LARGE                         ;#4E21: DA 3A 4E
        pop     af                                             ;#4E24: F1
        ret                                                    ;#4E25: C9

HANDLE_COLLISION_HOLE:
        ; Hole-collision stun branch: plays STUN_1, joins START_PENGUIN_STUN
        ; One-shot guard: ensures stun fires only once per collision event.
        ld      a,(STUMBLE_PROCESSED_FLAG)                     ;#4E26: 3A 35 E1
        or      a                                              ;#4E29: B7
        ret     nz                                             ;#4E2A: C0
        ld      a,ID_SOUND_STUN_1                              ;#4E2B: 3E 03
        call    PLAY_SOUND_SAFE                                ;#4E2D: CD C9 79
        ; Base timer seed for normal stun response.
        ld      hl,101h                                        ;#4E30: 21 01 01
        ld      a,(PENGUIN_MOVE_STATE)                         ;#4E33: 3A FA E0
        cpl                                                    ;#4E36: 2F
        rra                                                    ;#4E37: 1F
        jr      START_PENGUIN_STUN                             ;#4E38: 18 16

HANDLE_STUMBLE_LARGE:
        ; Stumble handler for large object (Seal) collisions
        ; Stores stumble marker, plays stumble SFX, and derives timer variant.
        ld      hl,101h                                        ;#4E3A: 21 01 01
        ld      (STUMBLE_OBSTACLE_ADDR),hl                     ;#4E3D: 22 36 E1
        ld      a,ID_SOUND_SEAL_COLLISION                      ;#4E40: 3E 08
        call    PLAY_SOUND_SAFE                                ;#4E42: CD C9 79
        ld      hl,102h                                        ;#4E45: 21 02 01
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4E48: 3A F9 E0
        or      a                                              ;#4E4B: B7
        jr      z,STUMBLE_LARGE_DONE                           ;#4E4C: 28 01
        inc     l                                              ;#4E4E: 2C
STUMBLE_LARGE_DONE:
        ; Stumble logic finished
        pop     af                                             ;#4E4F: F1
START_PENGUIN_STUN:
        ; Initiate the penguin stun sequence
        ; Writes stun timer/pattern, refreshes sprites, resets speed (shared stun path).
        ld      (PENGUIN_STUN_TIMER),hl                        ;#4E50: 22 42 E1
        ld      a,20h                                          ;#4E53: 3E 20
        jr      nc,START_PENGUIN_STUN_DONE                     ;#4E55: 30 02
        ld      a,24h                                          ;#4E57: 3E 24
START_PENGUIN_STUN_DONE:
        ; Stun initialization finished
        ld      (PENGUIN_STUN_PATTERN),a                       ;#4E59: 32 44 E1
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4E5C: CD D5 4B
        call    SYNC_PENGUIN_SPRITES_TO_VRAM                   ;#4E5F: CD C6 4B
        ld      hl,1313h                                       ;#4E62: 21 13 13
        ld      (PENGUIN_SPEED),hl                             ;#4E65: 22 00 E1
        ret                                                    ;#4E68: C9

HANDLE_PENGUIN_STUN_ANIMATION:
        ; Updates penguin position during stun state (every 4th frame)
        ld      a,(FRAME_COUNTER)                              ;#4E69: 3A 03 E0
        and     3                                              ;#4E6C: E6 03
        ret     nz                                             ;#4E6E: C0
        ld      hl,PENGUIN_STUN_TIMER                          ;#4E6F: 21 42 E1
        ld      a,(hl)                                         ;#4E72: 7E
        cp      3                                              ;#4E73: FE 03
        jp      z,STUN_RECOVERY_ANIMATION                      ;#4E75: CA 01 4F
        inc     hl                                             ;#4E78: 23
        ld      a,(hl)                                         ;#4E79: 7E
        inc     (hl)                                           ;#4E7A: 34
        ld      hl,PENGUIN_STUN_Y_OFFSETS-1                    ;#4E7B: 21 EC 4E
        call    ADD_HL_A                                       ;#4E7E: CD FE 48
        ld      c,(hl)                                         ;#4E81: 4E
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4E82: ED 5B 78 E0
STUN_X_MOVE_LOOP:
        ; Loop to apply horizontal shift based on stun timer
        ld      hl,VRAM_UPDATE_BUFFER                          ;#4E86: 21 D0 E0
        ld      a,(PENGUIN_STUN_PATTERN)                       ;#4E89: 3A 44 E1
        bit     2,a                                            ;#4E8C: CB 57
        call    z,STUMBLE_MOVE_LEFT_3X                         ;#4E8E: CC E2 4E
        call    nz,STUMBLE_MOVE_RIGHT_3X                       ;#4E91: C4 D9 4E
        ld      hl,PENGUIN_STUN_TIMER                          ;#4E94: 21 42 E1
        ld      a,(hl)                                         ;#4E97: 7E
        dec     a                                              ;#4E98: 3D
        jr      z,STUN_APPLY_Y_OFFSET                          ;#4E99: 28 03
        dec     (hl)                                           ;#4E9B: 35
        jr      STUN_X_MOVE_LOOP                               ;#4E9C: 18 E8

STUN_APPLY_Y_OFFSET:
        ; Apply vertical offset from data table and update sprite
        ex      de,hl                                          ;#4E9E: EB
        ld      a,l                                            ;#4E9F: 7D
        add     a,c                                            ;#4EA0: 81
        ld      l,a                                            ;#4EA1: 6F
        call    UPDATE_PENGUIN_COORDS                          ;#4EA2: CD C3 4B
        ld      a,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)       ;#4EA5: 3A 78 E0
        cp      90h                                            ;#4EA8: FE 90
        jr      nz,SPAWN_ITEM_SKIP_STUN                        ;#4EAA: 20 1F
PLAY_STUN_2_AND_ADVANCE:
        ; Play STUN_2 SFX, render road, advance stage segment after stun landing
        ld      a,ID_SOUND_STUN_2                              ;#4EAC: 3E 04
        call    PLAY_SOUND_SAFE                                ;#4EAE: CD C9 79
        call    RENDER_LEFT_ROAD_FRAME                         ;#4EB1: CD B0 51
        call    ADVANCE_STAGE_SEGMENT_DATA                     ;#4EB4: CD B9 51
        xor     a                                              ;#4EB7: AF
        ld      b,a                                            ;#4EB8: 47
        ld      hl,STUMBLE_OBSTACLE_ADDR                       ;#4EB9: 21 36 E1
        cp      (hl)                                           ;#4EBC: BE
        jr      z,SPAWN_ITEM_ENTRY                             ;#4EBD: 28 05
        ld      (hl),a                                         ;#4EBF: 77
        inc     a                                              ;#4EC0: 3C
        ld      (STUMBLE_PROCESSED_FLAG),a                     ;#4EC1: 32 35 E1
SPAWN_ITEM_ENTRY:
        ; Entry point in the collision handler for spawning fish/items
        call    CHECK_AND_SPAWN_ITEM                           ;#4EC4: CD DA 51
        xor     a                                              ;#4EC7: AF
        ld      (STUMBLE_PROCESSED_FLAG),a                     ;#4EC8: 32 35 E1
SPAWN_ITEM_SKIP_STUN:
        ; Skip item spawning
        ld      hl,PENGUIN_EVENT_TIMER                         ;#4ECB: 21 43 E1
        ld      a,(hl)                                         ;#4ECE: 7E
        sub     15h                                            ;#4ECF: D6 15
        ret     nz                                             ;#4ED1: C0
        ld      (hl),a                                         ;#4ED2: 77
        dec     hl                                             ;#4ED3: 2B
        ld      (hl),a                                         ;#4ED4: 77
        ld      (FISH_POS_GUARD_FLAG),a                        ;#4ED5: 32 37 E1
        ret                                                    ;#4ED8: C9

STUMBLE_MOVE_RIGHT_3X:
        ; Forceful right movement during stumble
        call    MOVE_PENGUIN_RIGHT                             ;#4ED9: CD B9 4C
        call    MOVE_PENGUIN_RIGHT                             ;#4EDC: CD B9 4C
        jp      MOVE_PENGUIN_RIGHT                             ;#4EDF: C3 B9 4C

STUMBLE_MOVE_LEFT_3X:
        ; Forceful left movement during stumble
        call    MOVE_PENGUIN_LEFT                              ;#4EE2: CD 9C 4C
        call    MOVE_PENGUIN_LEFT                              ;#4EE5: CD 9C 4C
        call    MOVE_PENGUIN_LEFT                              ;#4EE8: CD 9C 4C
        xor     a                                              ;#4EEB: AF
        ret                                                    ;#4EEC: C9

PENGUIN_STUN_Y_OFFSETS:
        ; Y-offsets for penguin stun/stumble animation
        ; Format: FORMAT_STUN_Y_OFFSETS
        STUN_Y_OFFSET -3                                       ;#4EED: FD
        STUN_Y_OFFSET -2                                       ;#4EEE: FE
        STUN_Y_OFFSET -2                                       ;#4EEF: FE
        STUN_Y_OFFSET -1                                       ;#4EF0: FF
        STUN_Y_OFFSET 1                                        ;#4EF1: 01
        STUN_Y_OFFSET 2                                        ;#4EF2: 02
        STUN_Y_OFFSET 2                                        ;#4EF3: 02
        STUN_Y_OFFSET 3                                        ;#4EF4: 03
        STUN_Y_OFFSET -2                                       ;#4EF5: FE
        STUN_Y_OFFSET -2                                       ;#4EF6: FE
        STUN_Y_OFFSET -1                                       ;#4EF7: FF
        STUN_Y_OFFSET 1                                        ;#4EF8: 01
        STUN_Y_OFFSET 2                                        ;#4EF9: 02
        STUN_Y_OFFSET 2                                        ;#4EFA: 02
        STUN_Y_OFFSET -2                                       ;#4EFB: FE
        STUN_Y_OFFSET -2                                       ;#4EFC: FE
        STUN_Y_OFFSET -1                                       ;#4EFD: FF
        STUN_Y_OFFSET 1                                        ;#4EFE: 01
        STUN_Y_OFFSET 2                                        ;#4EFF: 02
        STUN_Y_OFFSET 2                                        ;#4F00: 02

STUN_RECOVERY_ANIMATION:
        ; Handle stun recovery animation phase
        ld      hl,PENGUIN_INPUT_LOCK_TIMER                    ;#4F01: 21 F9 E0
        ld      a,(hl)                                         ;#4F04: 7E
        inc     (hl)                                           ;#4F05: 34
        cp      0Bh                                            ;#4F06: FE 0B
        jr      nz,APPLY_STUN_SPRITE_UPDATE                    ;#4F08: 20 02
        ld      (hl),0                                         ;#4F0A: 36 00
APPLY_STUN_SPRITE_UPDATE:
        ; Apply sprite updates during stun recovery
        push    af                                             ;#4F0C: F5
        ld      a,(PENGUIN_STUN_PATTERN)                       ;#4F0D: 3A 44 E1
        ld      c,a                                            ;#4F10: 4F
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4F11: CD D5 4B
        pop     af                                             ;#4F14: F1
        ld      hl,PENGUIN_JUMP_Y_OFFSETS                      ;#4F15: 21 80 4C
        call    ADD_HL_A                                       ;#4F18: CD FE 48
        ld      a,(hl)                                         ;#4F1B: 7E
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4F1C: ED 5B 78 E0
        add     a,e                                            ;#4F20: 83
        ld      e,a                                            ;#4F21: 5F
        bit     2,c                                            ;#4F22: CB 51
        ld      hl,VRAM_UPDATE_BUFFER                          ;#4F24: 21 D0 E0
        call    z,STUMBLE_MOVE_LEFT_3X                         ;#4F27: CC E2 4E
        call    nz,STUMBLE_MOVE_RIGHT_3X                       ;#4F2A: C4 D9 4E
        ex      de,hl                                          ;#4F2D: EB
        call    UPDATE_PENGUIN_COORDS                          ;#4F2E: CD C3 4B
        ld      a,(PENGUIN_INPUT_LOCK_TIMER)                   ;#4F31: 3A F9 E0
        or      a                                              ;#4F34: B7
        ret     nz                                             ;#4F35: C0
        ld      a,1                                            ;#4F36: 3E 01
        ld      (STUMBLE_PROCESSED_FLAG),a                     ;#4F38: 32 35 E1
        call    PLAY_STUN_2_AND_ADVANCE                        ;#4F3B: CD AC 4E
        xor     a                                              ;#4F3E: AF
        ld      (STUMBLE_PROCESSED_FLAG),a                     ;#4F3F: 32 35 E1
        dec     hl                                             ;#4F42: 2B
        inc     a                                              ;#4F43: 3C
        ld      (hl),a                                         ;#4F44: 77
        ld      a,ID_SOUND_STUN_2                              ;#4F45: 3E 04
        call    PLAY_SOUND_SAFE                                ;#4F47: CD C9 79
        ret                                                    ;#4F4A: C9

HANDLE_COLLISION_FALL:
        ; Handle collision that causes falling (e.g. hole)
        ld      hl,1                                           ;#4F4B: 21 01 00
        ld      (PENGUIN_FALL_TIMER),hl                        ;#4F4E: 22 40 E1
        xor     a                                              ;#4F51: AF
        ld      (PENGUIN_STUN_TIMER),a                         ;#4F52: 32 42 E1
        ld      a,0FFh                                         ;#4F55: 3E FF
        ld      (PENGUIN_ANIM_FRAME),a                         ;#4F57: 32 F8 E0
        ld      a,ID_SOUND_FALL_HOLE                           ;#4F5A: 3E 05
        call    PLAY_SOUND_SAFE                                ;#4F5C: CD C9 79
        ld      hl,SAT_MIRROR + SPRITE_6 + ATTR_Y              ;#4F5F: 21 68 E0
        ld      bc,4B6h                                        ;#4F62: 01 B6 04
HIDE_AUX_SPRITES_LOOP:
        ; Park aux-sprite buffer (sprites 6-9) off-screen (Y=B6h) during fall
        ld      (hl),c                                         ;#4F65: 71
        ld      a,4                                            ;#4F66: 3E 04
        call    ADD_HL_A                                       ;#4F68: CD FE 48
        djnz    HIDE_AUX_SPRITES_LOOP                          ;#4F6B: 10 F8
SET_PENGUIN_FALL_COORDS:
        ; Set penguin coordinates for fall sequence
        ld      hl,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4F6D: 2A 78 E0
        ld      l,9Fh                                          ;#4F70: 2E 9F
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#4F72: CD EC 4B
        ld      a,10h                                          ;#4F75: 3E 10
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4F77: CD D5 4B
        ld      a,0E0h                                         ;#4F7A: 3E E0
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_Y),a        ;#4F7C: 32 A0 E0
        ld      hl,0E0h * 256 + COLOR_DARK_YELLOW              ;#4F7F: 21 0A E0
        ; Packed 2-byte write: the slot for shadow is reused as yellow penguin's legs.
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_COLOR),hl   ;#4F82: 22 A3 E0
SYNC_AUX_SPRITES_TO_VRAM:
        ; Copy 32-byte aux-sprite buffer (E068, sprites 6-13) to VRAM
        ld      hl,SAT_MIRROR + SPRITE_6 + ATTR_Y              ;#4F85: 21 68 E0
        LOAD_SPRITE_ATTR de, 6, 0                              ;#4F88: 11 18 3B
        ld      bc,20h                                         ;#4F8B: 01 20 00
        call    COPY_RAM_TO_VRAM                               ;#4F8E: CD EC 44
        jp      COPY_PENGUIN_ATTRS_TO_VRAM                     ;#4F91: C3 1E 4D

HANDLE_PENGUIN_FALL:
        ; Handle penguin fall state (increments anim counter, waits for input)
        ld      hl,PENGUIN_FALL_ANIM_COUNTER                   ;#4F94: 21 41 E1
        inc     (hl)                                           ;#4F97: 34
        res     7,(hl)                                         ;#4F98: CB BE
        ld      a,(hl)                                         ;#4F9A: 7E
        cp      20h                                            ;#4F9B: FE 20
        jr      c,SET_PENGUIN_FALL_COORDS                      ;#4F9D: 38 CE
        call    READ_INPUT_EDGE                                ;#4F9F: CD 1D 46
        jr      nz,PENGUIN_FALL_LOOP                           ;#4FA2: 20 3E
        ld      a,(FRAME_COUNTER)                              ;#4FA4: 3A 03 E0
        ld      c,a                                            ;#4FA7: 4F
        and     7                                              ;#4FA8: E6 07
        ret     nz                                             ;#4FAA: C0
        ; Fall-recovery branch table — picks one of three (a, b, de) tuples by
        ; FRAME_COUNTER bits 3 and 4 (each phase lasts 8 frames).
        ; In this branch, the shadow sprites are used from the penguin's legs.
        ; The values feed INIT_FALL_RECOVERY:
        ; a = shadow X offset added to penguin_X
        ; b + 10h = final shadow Y
        ; d = penguin body pattern;
        ; e = legs pattern.
        ; frame 0 (bit 3 = 0):           a=8,    b=99h, d=14h, e=70h
        ld      a,8                                            ;#4FAB: 3E 08
        ld      b,99h                                          ;#4FAD: 06 99
        ld      de,1470h                                       ;#4FAF: 11 70 14
        bit     3,c                                            ;#4FB2: CB 59
        jr      z,INIT_FALL_RECOVERY                           ;#4FB4: 28 10
        ; frame 1 (bit 3 = 1, bit 4 = 0): a=4,    b=96h, d=18h, e=74h
        ld      a,4                                            ;#4FB6: 3E 04
        ld      b,96h                                          ;#4FB8: 06 96
        ld      de,1874h                                       ;#4FBA: 11 74 18
        bit     4,c                                            ;#4FBD: CB 61
        jr      z,INIT_FALL_RECOVERY                           ;#4FBF: 28 05
        ; frame 2 (bits 3+4 both set):    a=0Bh, (b kept from frame 1), d=1Ch, e=78h
        ld      a,0Bh                                          ;#4FC1: 3E 0B
        ld      de,1C78h                                       ;#4FC3: 11 78 1C
INIT_FALL_RECOVERY:
        ; Initialize recovery after falling
        ld      hl,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#4FC6: 2A 78 E0
        ld      l,b                                            ;#4FC9: 68
        add     a,h                                            ;#4FCA: 84
        ld      c,a                                            ;#4FCB: 4F
        ld      a,b                                            ;#4FCC: 78
        ld      b,e                                            ;#4FCD: 43
        ; Packed 2-byte write: shadow X (E0A1) + shadow pattern (E0A2).
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_X),bc       ;#4FCE: ED 43 A1 E0
        add     a,10h                                          ;#4FD2: C6 10
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_Y),a        ;#4FD4: 32 A0 E0
        push    de                                             ;#4FD7: D5
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#4FD8: CD EC 4B
        pop     af                                             ;#4FDB: F1
        call    UPDATE_PENGUIN_SPRITE_PATTERNS                 ;#4FDC: CD D5 4B
        jp      SYNC_AUX_SPRITES_TO_VRAM                       ;#4FDF: C3 85 4F

PENGUIN_FALL_LOOP:
        ; Loop for penguin falling animation
        xor     a                                              ;#4FE2: AF
        ld      (PENGUIN_FALL_TIMER),a                         ;#4FE3: 32 40 E1
        ld      (PENGUIN_ANIM_FRAME),a                         ;#4FE6: 32 F8 E0
        ld      hl,313h                                        ;#4FE9: 21 13 03
        ld      (PENGUIN_SPEED),hl                             ;#4FEC: 22 00 E1
        ld      a,(PENGUIN_X_POS)                              ;#4FEF: 3A 79 E0
        push    af                                             ;#4FF2: F5
        ld      hl,SPRITE_INIT_TABLE+1                         ;#4FF3: 21 F0 66
        ld      de,SAT_MIRROR + SPRITE_6 + ATTR_Y              ;#4FF6: 11 68 E0
        ld      c,4                                            ;#4FF9: 0E 04
        call    REPLICATE_4_BYTE_BLOCK                         ;#4FFB: CD BA 45
        ld      b,4                                            ;#4FFE: 06 04
HIDE_AUX_SPRITES_DATA_LOOP:
        ; Replicate SPRITE_INIT_TABLE bytes across 4 aux-sprite slots (PENGUIN_FALL_LOOP)
        ld      c,(hl)                                         ;#5000: 4E
        inc     hl                                             ;#5001: 23
        push    bc                                             ;#5002: C5
        call    REPLICATE_4_BYTE_BLOCK                         ;#5003: CD BA 45
        pop     bc                                             ;#5006: C1
        djnz    HIDE_AUX_SPRITES_DATA_LOOP                     ;#5007: 10 F7
        pop     hl                                             ;#5009: E1
        ld      l,90h                                          ;#500A: 2E 90
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#500C: CD EC 4B
        ld      hl,0A0h + COLOR_DARK_BLUE * 256                ;#500F: 21 A0 04
        ; Packed 2-byte write: shadow pattern A0h (low) + shadow color 4 dark blue (high).
        ld      (SAT_MIRROR + SPRITE_SHADOW + ATTR_PATT),hl    ;#5012: 22 A2 E0
        call    SYNC_PENGUIN_SPRITES_TO_VRAM                   ;#5015: CD C6 4B
        call    SYNC_SPRITE_ATTRIBUTES_ALL                     ;#5018: CD E3 66
        ret                                                    ;#501B: C9

HANDLE_COLLISION_FLAG:
        ; Road-flag pickup (SEQ_ITEM_PROP 5/6): +500, jingle, draws the tile stream
        ex      de,hl                                          ;#501C: EB
        dec     hl                                             ;#501D: 2B
        dec     hl                                             ;#501E: 2B
        ld      d,(hl)                                         ;#501F: 56
        dec     hl                                             ;#5020: 2B
        ld      e,(hl)                                         ;#5021: 5E
        dec     hl                                             ;#5022: 2B
        dec     hl                                             ;#5023: 2B
        ld      (hl),0                                         ;#5024: 36 00
        ex      de,hl                                          ;#5026: EB
        inc     hl                                             ;#5027: 23
        ld      de,ITEM_PICKUP_TILE_BUFFER                     ;#5028: 11 A0 E1
        ld      bc,0Dh                                         ;#502B: 01 0D 00
        ldir                                                   ;#502E: ED B0
        xor     a                                              ;#5030: AF
        ld      (de),a                                         ;#5031: 12
        ld      a,ID_SOUND_CATCH_FLAG                          ;#5032: 3E 06
        call    PLAY_SOUND_SAFE                                ;#5034: CD C9 79
        ld      hl,ITEM_PICKUP_TILE_BUFFER                     ;#5037: 21 A0 E1
        call    WRITE_VRAM_TILES_STREAM                        ;#503A: CD 33 45
        ld      de,500h                                        ;#503D: 11 00 05
        call    ADD_SCORE                                      ;#5040: CD 2D 46
        ret                                                    ;#5043: C9

INIT_STAGE:
        ; Initialize stage-specific BCD values and timers
        ld      a,(CURRENT_STAGE_INDEX)                        ;#5044: 3A E1 E0
        ld      hl,STAGE_VISUAL_THEME_TABLE                    ;#5047: 21 95 51
        call    ADD_HL_A                                       ;#504A: CD FE 48
        ld      a,COLOR_CYAN                                   ;#504D: 3E 07
        bit     0,(hl)                                         ;#504F: CB 46
        jr      z,INIT_STAGE_SET_SKY_COLOR                     ;#5051: 28 02
        ld      a,COLOR_LIGHT_RED                              ;#5053: 3E 09
INIT_STAGE_SET_SKY_COLOR:
        ; Set stage sky color attribute
        ld      (SKY_COLOR),a                                  ;#5055: 32 0C E1
        ld      a,(hl)                                         ;#5058: 7E
        ld      hl,GFX_STARTUP_COLOR_TABLE_TAIL                ;#5059: 21 E4 5D
        LOAD_VRAM_WRITE de, 2246h                              ;#505C: 11 46 62
        or      a                                              ;#505F: B7
        jr      z,LOAD_STAGE_TILES_AND_COLORS                  ;#5060: 28 06
        ld      hl,GFX_STAGE_NIGHT_TILES                       ;#5062: 21 EF 5D
        ld      de,GFX_STAGE_NIGHT_COLORS                      ;#5065: 11 63 62
LOAD_STAGE_TILES_AND_COLORS:
        ; Load stage tiles and colors to VRAM
        push    de                                             ;#5068: D5
        LOAD_VRAM_WRITE de, 588h                               ;#5069: 11 88 45
        call    DECOMPRESS_VRAM_DIRECT                         ;#506C: CD 64 45
        pop     hl                                             ;#506F: E1
        LOAD_VRAM_WRITE de, 0F78h                              ;#5070: 11 78 4F
        call    DECOMPRESS_VRAM_DIRECT                         ;#5073: CD 64 45
        LOAD_NAME_TABLE de, 3, 0                               ;#5076: 11 60 38
        ld      bc,0E0h                                        ;#5079: 01 E0 00
        ld      a,(SKY_COLOR)                                  ;#507C: 3A 0C E1
        call    FILL_VRAM                                      ;#507F: CD FD 44
        LOAD_NAME_TABLE de, 10, 0                              ;#5082: 11 40 39
        ld      bc,1C0h                                        ;#5085: 01 C0 01
        LOAD_VRAM_COLOR a, COLOR_TRANSPARENT, COLOR_WHITE      ;#5088: 3E 0F
        call    FILL_VRAM                                      ;#508A: CD FD 44
        ld      hl,ROAD_ICE_RIGHT_1_FILL                       ;#508D: 21 51 72
        call    UPLOAD_ROAD_SEGMENT_TO_VRAM                    ;#5090: CD F2 50
        ld      hl,ROAD_ICE_LEFT_1_FILL                        ;#5093: 21 8E 72
        call    UPLOAD_ROAD_SEGMENT_TO_VRAM                    ;#5096: CD F2 50
        ld      hl,STAGE_SEGMENT_SEQUENCES                     ;#5099: 21 45 51
        ld      a,(CURRENT_STAGE_INDEX)                        ;#509C: 3A E1 E0
        add     a,a                                            ;#509F: 87
        add     a,a                                            ;#50A0: 87
        add     a,a                                            ;#50A1: 87
        call    ADD_HL_A                                       ;#50A2: CD FE 48
        ld      (CURRENT_STAGE_DATA_PTR),hl                    ;#50A5: 22 0A E1
        xor     a                                              ;#50A8: AF
        ld      (ACTIVE_ROAD_FRAME),a                          ;#50A9: 32 02 E1
        ld      (STAGE_SEGMENT_INDEX),a                        ;#50AC: 32 08 E1
        ld      hl,ROAD_ICE_RIGHT_1                            ;#50AF: 21 49 72
        ld      (ACTIVE_ROAD_PTR_RIGHT),hl                     ;#50B2: 22 03 E1
        ld      hl,ROAD_ICE_LEFT_1                             ;#50B5: 21 86 72
        ld      (ACTIVE_ROAD_PTR_LEFT),hl                      ;#50B8: 22 05 E1
        call    RENDER_LEFT_ROAD_FRAME                         ;#50BB: CD B0 51
        call    CALC_STAGE_SEGMENT_ADDR                        ;#50BE: CD C0 51
        ret                                                    ;#50C1: C9

PROCESS_ROAD_SEGMENT_ADVANCE:
        ; Advance to next road data segment and trigger VRAM update
        ld      hl,STAGE_SEGMENT_INDEX                         ;#50C2: 21 08 E1
        ld      a,(hl)                                         ;#50C5: 7E
        inc     (hl)                                           ;#50C6: 34
        ld      hl,(CURRENT_STAGE_DATA_PTR)                    ;#50C7: 2A 0A E1
        call    ADD_HL_A                                       ;#50CA: CD FE 48
        ld      a,(hl)                                         ;#50CD: 7E
        cp      0FFh                                           ;#50CE: FE FF
        ret     z                                              ;#50D0: C8
        ld      (ROAD_SEGMENT_INDEX),a                         ;#50D1: 32 09 E1
        ld      bc,ACTIVE_ROAD_PTR_RIGHT                       ;#50D4: 01 03 E1
        bit     0,a                                            ;#50D7: CB 47
        jr      z,STORE_ROAD_SEG_SKIP_BC                       ;#50D9: 28 02
        inc     bc                                             ;#50DB: 03
        inc     bc                                             ;#50DC: 03
STORE_ROAD_SEG_SKIP_BC:
        ; Skip register BC store
        add     a,a                                            ;#50DD: 87
        ld      hl,STAGE_SEGMENT_DEFINITIONS                   ;#50DE: 21 41 72
        call    ADD_HL_A                                       ;#50E1: CD FE 48
        ld      a,(hl)                                         ;#50E4: 7E
        ld      e,a                                            ;#50E5: 5F
        ld      (bc),a                                         ;#50E6: 02
        inc     hl                                             ;#50E7: 23
        inc     bc                                             ;#50E8: 03
        ld      a,(hl)                                         ;#50E9: 7E
        ld      d,a                                            ;#50EA: 57
        ld      (bc),a                                         ;#50EB: 02
        ex      de,hl                                          ;#50EC: EB
        ld      a,8                                            ;#50ED: 3E 08
        call    ADD_HL_A                                       ;#50EF: CD FE 48
UPLOAD_ROAD_SEGMENT_TO_VRAM:
        ; Decompresses and uploads a block of road graphics to VRAM
        call    FILL_VRAM_STREAM                               ;#50F2: CD 12 45
        call    WRITE_VRAM_STREAM                              ;#50F5: CD A8 45
        ld      e,(hl)                                         ;#50F8: 5E
UPLOAD_ROAD_SEG_DONE:
        ; Road segment upload finished
        ld      a,(SKY_COLOR)                                  ;#50F9: 3A 0C E1
        ld      c,a                                            ;#50FC: 4F
        ld      b,10h                                          ;#50FD: 06 10
        ld      d,0E1h                                         ;#50FF: 16 E1
INIT_VRAM_LOOP:
        ; Loop through VRAM stream data
        inc     hl                                             ;#5101: 23
        ld      a,(hl)                                         ;#5102: 7E
        or      a                                              ;#5103: B7
        jr      nz,INIT_VRAM_WRITE_VAL                         ;#5104: 20 01
        ld      a,c                                            ;#5106: 79
INIT_VRAM_WRITE_VAL:
        ; Write default value to VRAM stream
        ld      (de),a                                         ;#5107: 12
        inc     de                                             ;#5108: 13
        djnz    INIT_VRAM_LOOP                                 ;#5109: 10 F6
INIT_VRAM_DONE:
        ; VRAM initialization finished
        LOAD_NAME_TABLE de, 9, 0                               ;#510B: 11 20 39
        ld      (VRAM_STREAM_PTR),de                           ;#510E: ED 53 4E E1
        ld      a,0FFh                                         ;#5112: 3E FF
        ld      (VRAM_STREAM_STATUS),a                         ;#5114: 32 70 E1
        ld      hl,VRAM_STREAM_PTR                             ;#5117: 21 4E E1
        call    WRITE_VRAM_STREAM                              ;#511A: CD A8 45
        xor     a                                              ;#511D: AF
        ret                                                    ;#511E: C9

UPDATE_STAGE_OBJECTS_LOGIC:
        ; Update stage objects and check flags
        call    CHECK_FLICKER_TIMER                            ;#511F: CD 51 53
        ld      hl,STAGE_SEGMENT_TIMER                         ;#5122: 21 07 E1
        ld      a,(hl)                                         ;#5125: 7E
        dec     a                                              ;#5126: 3D
        ret     nz                                             ;#5127: C0
        ld      a,(ACTIVE_ROAD_FRAME)                          ;#5128: 3A 02 E1
        dec     a                                              ;#512B: 3D
        ret     nz                                             ;#512C: C0
        ld      (hl),a                                         ;#512D: 77
        call    PROCESS_ROAD_SEGMENT_ADVANCE                   ;#512E: CD C2 50
        or      a                                              ;#5131: B7
        ret     nz                                             ;#5132: C0
        ld      hl,(ACTIVE_ROAD_PTR_RIGHT)                     ;#5133: 2A 03 E1
        ld      a,(ROAD_SEGMENT_INDEX)                         ;#5136: 3A 09 E1
        bit     0,a                                            ;#5139: CB 47
        jr      z,FETCH_SEGMENT_DATA_PTR                       ;#513B: 28 03
        ld      hl,(ACTIVE_ROAD_PTR_LEFT)                      ;#513D: 2A 05 E1
FETCH_SEGMENT_DATA_PTR:
        ; Fetch pointer to segment data (index 0)
        xor     a                                              ;#5140: AF
        call    CALC_SEGMENT_ADDR_OFFSET                       ;#5141: CD C3 51
        ret                                                    ;#5144: C9

STAGE_SEGMENT_SEQUENCES:
        ; Stage segment-sequence table (stages 0-8 use 4 bytes; stage 9 uses 8).
        ; Used by INIT_STAGE to select color/gfx bank.
        STAGE_SEGMENTS 2,    3,    0,    1     ; Stage 0 (positions 0..3) ;#5145: 02 03 00 01
        STAGE_SEGMENTS 77h,  77h,  77h,  77h   ; Stage 0 (positions 4..7) ;#5149: 77 77 77 77
        STAGE_SEGMENTS 3,    2,    1,    0     ; Stage 1 (positions 0..3) ;#514D: 03 02 01 00
        STAGE_SEGMENTS 77h,  77h,  77h,  77h   ; Stage 1 (positions 4..7) ;#5151: 77 77 77 77
        STAGE_SEGMENTS 3,    0FFh, 1,    77h   ; Stage 2 (positions 0..3) ;#5155: 03 FF 01 77
        STAGE_SEGMENTS 77h,  77h,  77h,  77h   ; Stage 2 (positions 4..7) ;#5159: 77 77 77 77
        STAGE_SEGMENTS 0FFh, 2,    0,    77h   ; Stage 3 (positions 0..3) ;#515D: FF 02 00 77
        STAGE_SEGMENTS 77h,  77h,  77h,  77h   ; Stage 3 (positions 4..7) ;#5161: 77 77 77 77
        STAGE_SEGMENTS 3,    0FFh, 1,    77h   ; Stage 4 (positions 0..3) ;#5165: 03 FF 01 77
        STAGE_SEGMENTS 77h,  77h,  77h,  77h   ; Stage 4 (positions 4..7) ;#5169: 77 77 77 77
        STAGE_SEGMENTS 0FFh, 77h,  77h,  77h   ; Stage 5 (positions 0..3) ;#516D: FF 77 77 77
        STAGE_SEGMENTS 77h,  77h,  77h,  77h   ; Stage 5 (positions 4..7) ;#5171: 77 77 77 77
        STAGE_SEGMENTS 2,    3,    0,    2     ; Stage 6 (positions 0..3) ;#5175: 02 03 00 02
        STAGE_SEGMENTS 1,    0,    0FFh, 77h   ; Stage 6 (positions 4..7) ;#5179: 01 00 FF 77
        STAGE_SEGMENTS 2,    0FFh, 0,    77h   ; Stage 7 (positions 0..3) ;#517D: 02 FF 00 77
        STAGE_SEGMENTS 77h,  77h,  77h,  77h   ; Stage 7 (positions 4..7) ;#5181: 77 77 77 77
        STAGE_SEGMENTS 2,    0,    3,    1     ; Stage 8 (positions 0..3) ;#5185: 02 00 03 01
        STAGE_SEGMENTS 77h,  77h,  77h,  77h   ; Stage 8 (positions 4..7) ;#5189: 77 77 77 77
        STAGE_SEGMENTS 0FFh, 3,    1,    77h   ; Stage 9 (positions 0..3) ;#518D: FF 03 01 77
        STAGE_SEGMENTS 77h,  77h,  77h,  77h   ; Stage 9 (positions 4..7) ;#5191: 77 77 77 77
STAGE_VISUAL_THEME_TABLE:
        ; Table of visual style indices (0=Day/Blue, 1=Night/Red) per stage.
        ; Format: FORMAT_SKY_COLOR
        db      SKY_DAY_BLUE                                   ;#5195: 00
        db      SKY_DAY_BLUE                                   ;#5196: 00
        db      SKY_NIGHT_RED                                  ;#5197: 01
        db      SKY_DAY_BLUE                                   ;#5198: 00
        db      SKY_NIGHT_RED                                  ;#5199: 01
        db      SKY_NIGHT_RED                                  ;#519A: 01
        db      SKY_DAY_BLUE                                   ;#519B: 00
        db      SKY_DAY_BLUE                                   ;#519C: 00
        db      SKY_NIGHT_RED                                  ;#519D: 01
        db      SKY_DAY_BLUE                                   ;#519E: 00

PROCESS_SCENE_TIMER:
        ; Decrements PENGUIN_SPEED timer, triggers events
        ld      hl,PENGUIN_SPEED                               ;#519F: 21 00 E1
        ld      c,(hl)                                         ;#51A2: 4E
        inc     hl                                             ;#51A3: 23
        dec     (hl)                                           ;#51A4: 35
        jr      z,RESET_SCENE_TIMER_AND_ADVANCE                ;#51A5: 28 11
        ld      a,(hl)                                         ;#51A7: 7E
        cp      3                                              ;#51A8: FE 03
        jp      z,UPDATE_STAGE_OBJECTS_LOGIC                   ;#51AA: CA 1F 51
        dec     a                                              ;#51AD: 3D
        jr      nz,ADVANCE_STAGE_SEG_DONE                      ;#51AE: 20 1F
RENDER_LEFT_ROAD_FRAME:
        ; Render left road slot current-frame pattern via WRITE_VRAM_TILES_STREAM
        ld      hl,(ACTIVE_ROAD_PTR_LEFT)                      ;#51B0: 2A 05 E1
        ld      a,(ACTIVE_ROAD_FRAME)                          ;#51B3: 3A 02 E1
        jr      CALC_SEGMENT_ADDR_OFFSET                       ;#51B6: 18 0B

RESET_SCENE_TIMER_AND_ADVANCE:
        ; Reset timer and advance stage data
        ld      (hl),c                                         ;#51B8: 71
ADVANCE_STAGE_SEGMENT_DATA:
        ; Increment segment counter and load patterns
        ld      hl,ACTIVE_ROAD_FRAME                           ;#51B9: 21 02 E1
        ld      a,(hl)                                         ;#51BC: 7E
        inc     (hl)                                           ;#51BD: 34
        res     2,(hl)                                         ;#51BE: CB 96
CALC_STAGE_SEGMENT_ADDR:
        ; Calculate address of stage segment data
        ld      hl,(ACTIVE_ROAD_PTR_RIGHT)                     ;#51C0: 2A 03 E1
CALC_SEGMENT_ADDR_OFFSET:
        ; Calculate address of stage segment data with offset A
        add     a,a                                            ;#51C3: 87
        call    ADD_HL_A                                       ;#51C4: CD FE 48
        ld      e,(hl)                                         ;#51C7: 5E
        inc     hl                                             ;#51C8: 23
        ld      d,(hl)                                         ;#51C9: 56
        ex      de,hl                                          ;#51CA: EB
        call    WRITE_VRAM_TILES_STREAM                        ;#51CB: CD 33 45
        ret                                                    ;#51CE: C9

ADVANCE_STAGE_SEG_DONE:
        ; Stage segment advancement finished
        ld      b,0                                            ;#51CF: 06 00
        dec     a                                              ;#51D1: 3D
        jr      z,CHECK_AND_SPAWN_ITEM                         ;#51D2: 28 06
        inc     b                                              ;#51D4: 04
        srl     c                                              ;#51D5: CB 39
        ld      a,(hl)                                         ;#51D7: 7E
        cp      c                                              ;#51D8: B9
        ret     nz                                             ;#51D9: C0
CHECK_AND_SPAWN_ITEM:
        ; Periodically check and spawn fish/flags
        ld      hl,ITEM_TABLE                                  ;#51DA: 21 12 E1
        ld      c,b                                            ;#51DD: 48
        ld      b,4                                            ;#51DE: 06 04
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#51E0: 3A E0 E0
        cp      5                                              ;#51E3: FE 05
        jr      c,SPAWN_ITEM_LOOP_NEXT                         ;#51E5: 38 01
        inc     b                                              ;#51E7: 04
SPAWN_ITEM_LOOP_NEXT:
        ; Next iteration of item spawn loop
        ld      a,c                                            ;#51E8: 79
        or      a                                              ;#51E9: B7
        jr      z,SPAWN_ITEM_CHECK_SLOT                        ;#51EA: 28 07
        ld      a,(hl)                                         ;#51EC: 7E
        cp      0Bh                                            ;#51ED: FE 0B
        ld      a,6                                            ;#51EF: 3E 06
        jr      c,SPAWN_ITEM_SKIP                              ;#51F1: 38 22
SPAWN_ITEM_CHECK_SLOT:
        ; Check if item slot is free
        ld      a,(hl)                                         ;#51F3: 7E
        or      a                                              ;#51F4: B7
        ld      a,6                                            ;#51F5: 3E 06
        jr      z,SPAWN_ITEM_SKIP                              ;#51F7: 28 1C
        inc     (hl)                                           ;#51F9: 34
        ld      a,(hl)                                         ;#51FA: 7E
        cp      10h                                            ;#51FB: FE 10
        jr      c,SPAWN_ITEM_INIT                              ;#51FD: 38 02
        ld      (hl),0                                         ;#51FF: 36 00
SPAWN_ITEM_INIT:
        ; Initialize new item in slot
        inc     hl                                             ;#5201: 23
        inc     hl                                             ;#5202: 23
        ld      e,(hl)                                         ;#5203: 5E
        inc     hl                                             ;#5204: 23
        ld      d,(hl)                                         ;#5205: 56
        ex      de,hl                                          ;#5206: EB
        push    de                                             ;#5207: D5
        push    bc                                             ;#5208: C5
        call    WRITE_VRAM_TILES_STREAM                        ;#5209: CD 33 45
        pop     bc                                             ;#520C: C1
        pop     de                                             ;#520D: D1
        inc     hl                                             ;#520E: 23
        ex      de,hl                                          ;#520F: EB
        ld      (hl),d                                         ;#5210: 72
        dec     hl                                             ;#5211: 2B
        ld      (hl),e                                         ;#5212: 73
        ld      a,4                                            ;#5213: 3E 04
SPAWN_ITEM_SKIP:
        ; Skip to next slot
        call    ADD_HL_A                                       ;#5215: CD FE 48
        djnz    SPAWN_ITEM_LOOP_NEXT                           ;#5218: 10 CE
        call    CHECK_SPECIAL_ITEM_COLLISION                   ;#521A: CD EF 75
        call    HANDLE_SPECIAL_ITEM_EVENT                      ;#521D: CD 42 78
        call    CHECK_ITEM_COLLISIONS                          ;#5220: CD 49 4D
        call    CHECK_COLLISIONS_WHILE_LOCKED                  ;#5223: CD 96 4D
        ret                                                    ;#5226: C9

UPDATE_ITEMS:
        ; Main loop for updating items and sequences
        call    START_SEQUENCE_CHECK                           ;#5227: CD 11 48
        ld      hl,(STAGE_DISTANCE_BCD)                        ;#522A: 2A E5 E0
        ld      a,h                                            ;#522D: 7C
        and     a                                              ;#522E: A7
        jr      nz,TICK_ITEM_TIMER                             ;#522F: 20 04
        ld      a,l                                            ;#5231: 7D
        cp      86h                                            ;#5232: FE 86
        ret     c                                              ;#5234: D8
TICK_ITEM_TIMER:
        ; Tick item-timer countdown; reload from period and walk ITEM_TABLE on expiry
        ld      hl,ITEM_TICK_PERIOD                            ;#5235: 21 0E E1
        ld      a,(hl)                                         ;#5238: 7E
        inc     hl                                             ;#5239: 23
        dec     (hl)                                           ;#523A: 35
        ret     nz                                             ;#523B: C0
        ld      (hl),a                                         ;#523C: 77
        ld      hl,ITEM_TABLE                                  ;#523D: 21 12 E1
        ld      b,3                                            ;#5240: 06 03
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#5242: 3A E0 E0
        cp      5                                              ;#5245: FE 05
        jr      c,CHECK_ACTIVE_ITEM_SLOT                       ;#5247: 38 01
        inc     b                                              ;#5249: 04
CHECK_ACTIVE_ITEM_SLOT:
        ; Check for active item slot
        ld      a,(hl)                                         ;#524A: 7E
        or      a                                              ;#524B: B7
        jr      z,UPDATE_ITEM_STATE                            ;#524C: 28 08
        ld      a,6                                            ;#524E: 3E 06
        call    ADD_HL_A                                       ;#5250: CD FE 48
        djnz    CHECK_ACTIVE_ITEM_SLOT                         ;#5253: 10 F5
        ret                                                    ;#5255: C9

UPDATE_ITEM_STATE:
        ; Update state of active item
        ; Runs periodically for entities spawned by START_SEQUENCE_CHECK. Processes
        ; 8-byte command streams divided into 4-byte packets. Instruction set (1 byte):
        ; - 00h-0Fh: Select entry from ITEM_PROPERTIES_TABLE.
        ; - 10h-1Fh: Set movement state (stored at ITEM_TABLE + 0).
        ; - FFh: End of sequence/Idle.
        inc     (hl)                                           ;#5256: 34
        inc     hl                                             ;#5257: 23
        ex      de,hl                                          ;#5258: EB
        ld      hl,ITEM_COMMAND_INDEX                          ;#5259: 21 11 E1
        inc     (hl)                                           ;#525C: 34
        res     3,(hl)                                         ;#525D: CB 9E
        ld      a,(hl)                                         ;#525F: 7E
        ld      hl,(SEQUENCE_DATA_PTR)                         ;#5260: 2A 8B E1
        call    ADD_HL_A                                       ;#5263: CD FE 48
        ld      c,(hl)                                         ;#5266: 4E
        push    de                                             ;#5267: D5
        call    CHECK_SEQUENCE_STATUS                          ;#5268: CD FF 47
        pop     de                                             ;#526B: D1
        ld      a,c                                            ;#526C: 79
        inc     a                                              ;#526D: 3C
        jr      z,STORE_ITEM_STATE                             ;#526E: 28 3E
        dec     a                                              ;#5270: 3D
        bit     4,a                                            ;#5271: CB 67
        jr      z,SET_ITEM_MOVE_OVERRIDE_DONE                  ;#5273: 28 0C
        ld      hl,ITEM_MOVE_OVERRIDE_FLAG                     ;#5275: 21 90 E1
        ld      (hl),1                                         ;#5278: 36 01
        inc     hl                                             ;#527A: 23
        and     3                                              ;#527B: E6 03
        ld      c,a                                            ;#527D: 4F
        ld      (hl),a                                         ;#527E: 77
        jr      PROCESS_ITEM_MOVEMENT                          ;#527F: 18 0B

SET_ITEM_MOVE_OVERRIDE_DONE:
        ; Item-move override setup finished
        ld      a,c                                            ;#5281: 79
        or      a                                              ;#5282: B7
        jr      z,PROCESS_ITEM_MOVEMENT                        ;#5283: 28 07
        ld      a,(PENGUIN_SIDE_FLAG)                          ;#5285: 3A FC E0
        or      a                                              ;#5288: B7
        jr      z,PROCESS_ITEM_MOVEMENT                        ;#5289: 28 01
        inc     c                                              ;#528B: 0C
PROCESS_ITEM_MOVEMENT:
        ; Handle movement for item
        ex      de,hl                                          ;#528C: EB
        call    SAVE_ITEM_DATA                                 ;#528D: CD B2 52
        ld      a,(ITEM_MOVE_OVERRIDE_FLAG)                    ;#5290: 3A 90 E1
        rra                                                    ;#5293: 1F
        ret     nc                                             ;#5294: D0
        ld      a,(ITEM_MOVE_TOGGLE)                           ;#5295: 3A 91 E1
        cpl                                                    ;#5298: 2F
        and     3                                              ;#5299: E6 03
        ld      c,a                                            ;#529B: 4F
        ld      hl,ITEM_DATA_LATCH                             ;#529C: 21 2A E1
        ld      a,(hl)                                         ;#529F: 7E
        or      a                                              ;#52A0: B7
        jr      nz,CLEAR_ITEM_MOVE_OVERRIDE                    ;#52A1: 20 05
        inc     (hl)                                           ;#52A3: 34
        inc     hl                                             ;#52A4: 23
        call    SAVE_ITEM_DATA                                 ;#52A5: CD B2 52
CLEAR_ITEM_MOVE_OVERRIDE:
        ; Clears ITEM_MOVE_OVERRIDE_FLAG at end of item-state update (legacy name)
        ld      hl,ITEM_MOVE_OVERRIDE_FLAG                     ;#52A8: 21 90 E1
        ld      (hl),0                                         ;#52AB: 36 00
        ret                                                    ;#52AD: C9

STORE_ITEM_STATE:
        ; Store updated item state
        ex      de,hl                                          ;#52AE: EB
        dec     hl                                             ;#52AF: 2B
        ld      (hl),a                                         ;#52B0: 77
        ret                                                    ;#52B1: C9

SAVE_ITEM_DATA:
        ; Save item data to table
        ld      (hl),c                                         ;#52B2: 71
        inc     hl                                             ;#52B3: 23
        ld      de,ITEM_PROPERTIES_TABLE                       ;#52B4: 11 CB 52
        ld      a,c                                            ;#52B7: 79
        add     a,a                                            ;#52B8: 87
        ld      c,a                                            ;#52B9: 4F
        add     a,a                                            ;#52BA: 87
        add     a,c                                            ;#52BB: 81
        call    ADD_DE_A                                       ;#52BC: CD 03 49
        ld      a,(de)                                         ;#52BF: 1A
        ld      (hl),a                                         ;#52C0: 77
        inc     de                                             ;#52C1: 13
        inc     hl                                             ;#52C2: 23
        ld      a,(de)                                         ;#52C3: 1A
        ld      (hl),a                                         ;#52C4: 77
        inc     de                                             ;#52C5: 13
        inc     hl                                             ;#52C6: 23
        ld      (hl),e                                         ;#52C7: 73
        inc     hl                                             ;#52C8: 23
        ld      (hl),d                                         ;#52C9: 72
        ret                                                    ;#52CA: C9

ITEM_PROPERTIES_TABLE:
        ; Per-item anim ptr + 2 (low_x, width) X-range pairs; see INTERNALS.md
        ; Format: FORMAT_ITEM_PROPERTIES
        ; - 6 bytes per entry: animation ptr (word, LE) then four collision bytes
        ; consumed by COLLISION_CHECK_LOOP as two (low_x, width) X-range pairs.
        ; - Small hole: x1=1 (skip-X sentinel) routes straight to stun; (w1, x2) =
        ; stun (low_x, width), w2 unused. Big hole: (x1, w1) = fall zone,
        ; (x2, w2) = stun zone. Flag: (x1, w1) = pickup zone, (x2, w2) unused.
        ; - See INTERNALS.md for the full overloaded layout.
        ITEM_PROP ANIM_SMALL_HOLE_CENTER, 1, 53h, 3Ah, 0       ;#52CB: 19 6F 01 53 3A 00
        ITEM_PROP ANIM_SMALL_HOLE_LEFT, 1, 13h, 3Bh, 0         ;#52D1: D2 6F 01 13 3B 00
        ITEM_PROP ANIM_SMALL_HOLE_RIGHT, 1, 92h, 3Bh, 0        ;#52D7: 91 70 01 92 3B 00
        ITEM_PROP ANIM_BIG_HOLE_LEFT, 2Bh, 5Bh, 10h, 90h       ;#52DD: E9 6B 2B 5B 10 90
        ITEM_PROP ANIM_BIG_HOLE_RIGHT, 64h, 53h, 48h, 88h      ;#52E3: 85 6D 64 53 48 88
        ITEM_PROP ANIM_FLAG_RIGHT, 80h, 2Ch, 0, 0              ;#52E9: C8 71 80 2C 00 00
        ITEM_PROP ANIM_FLAG_LEFT, 2Eh, 2Ch, 0, 0               ;#52EF: 50 71 2E 2C 00 00

CHECK_DISTANCE_MILESTONE:
        ; Checks distance for periodic events
        ld      hl,(STAGE_DISTANCE_BCD)                        ;#52F5: 2A E5 E0
        ld      a,h                                            ;#52F8: 7C
        and     1                                              ;#52F9: E6 01
        ret     z                                              ;#52FB: C8
        ld      a,l                                            ;#52FC: 7D
        cp      82h                                            ;#52FD: FE 82
        ret     nz                                             ;#52FF: C0
        ld      hl,DISTANCE_EVENT_TICK                         ;#5300: 21 E2 E0
        ld      a,(hl)                                         ;#5303: 7E
        inc     (hl)                                           ;#5304: 34
        srl     a                                              ;#5305: CB 3F
        push    af                                             ;#5307: F5
        ld      hl,DISTANCE_EVENT_TABLE                        ;#5308: 21 E1 53
        call    ADD_HL_A                                       ;#530B: CD FE 48
        pop     af                                             ;#530E: F1
        ld      a,(hl)                                         ;#530F: 7E
        jr      c,DECODE_DISTANCE_EVENT_NIBBLE                 ;#5310: 38 04
        rra                                                    ;#5312: 1F
        rra                                                    ;#5313: 1F
        rra                                                    ;#5314: 1F
        rra                                                    ;#5315: 1F
DECODE_DISTANCE_EVENT_NIBBLE:
        ; Decode one 4-bit nibble from DISTANCE_EVENT_TABLE
        ld      c,a                                            ;#5316: 4F
        and     3                                              ;#5317: E6 03
        cp      3                                              ;#5319: FE 03
        ret     z                                              ;#531B: C8
        bit     3,c                                            ;#531C: CB 59
        jr      z,SET_DISTANCE_EVENT_INDEX                     ;#531E: 28 02
        set     1,a                                            ;#5320: CB CF
SET_DISTANCE_EVENT_INDEX:
        ; Store decoded index in DISTANCE_EVENT_INDEX (+ secondary-slot flag)
        ld      hl,DISTANCE_EVENT_INDEX                        ;#5322: 21 94 E1
        ld      (hl),a                                         ;#5325: 77
        inc     hl                                             ;#5326: 23
        bit     2,c                                            ;#5327: CB 51
        jr      z,PROCESS_DYNAMIC_OBJ_ITER                     ;#5329: 28 02
        ld      (hl),2                                         ;#532B: 36 02
PROCESS_DYNAMIC_OBJ_ITER:
        ; Next dynamic object iteration
        inc     hl                                             ;#532D: 23
        ld      (hl),1                                         ;#532E: 36 01
        inc     hl                                             ;#5330: 23
        ld      (hl),0                                         ;#5331: 36 00
        inc     hl                                             ;#5333: 23
        ld      a,(PENGUIN_SPEED)                              ;#5334: 3A 00 E1
        srl     a                                              ;#5337: CB 3F
        srl     a                                              ;#5339: CB 3F
        ld      (hl),a                                         ;#533B: 77
        call    PREPARE_CURVE_OVERLAY_ICE                      ;#533C: CD C6 54
DRAW_DISTANCE_EVENT_STREAM:
        ; Draw the stream selected by DISTANCE_EVENT_INDEX (entries 0-3)
        ld      hl,DISTANCE_EVENT_STREAMS                      ;#533F: 21 02 54
WRITE_VRAM_STREAM_INDEXED:
        ; Loads a stream pointer from HL[index*2] and writes to VRAM
        ld      a,(DISTANCE_EVENT_INDEX)                       ;#5342: 3A 94 E1
        add     a,a                                            ;#5345: 87
        call    ADD_HL_A                                       ;#5346: CD FE 48
        ld      e,(hl)                                         ;#5349: 5E
        inc     hl                                             ;#534A: 23
        ld      d,(hl)                                         ;#534B: 56
        ex      de,hl                                          ;#534C: EB
        call    WRITE_VRAM_STREAM                              ;#534D: CD A8 45
        ret                                                    ;#5350: C9

CHECK_FLICKER_TIMER:
        ; Check if flicker timer is active
        ld      a,(PENGUIN_DRIFT_FLAG)                         ;#5351: 3A 96 E1
        or      a                                              ;#5354: B7
        ret     z                                              ;#5355: C8
        ld      bc,1Fh                                         ;#5356: 01 1F 00
        ld      a,(DISTANCE_EVENT_INDEX)                       ;#5359: 3A 94 E1
        rra                                                    ;#535C: 1F
        jr      c,FLICKER_BUFFER_SHIFT                         ;#535D: 38 10
        ld      a,(FLICKER_SPRITE_BUFFER)                      ;#535F: 3A 50 E1
        ld      hl,FLICKER_SPRITE_BUFFER+1                     ;#5362: 21 51 E1
        ld      de,FLICKER_SPRITE_BUFFER                       ;#5365: 11 50 E1
        ldir                                                   ;#5368: ED B0
        ld      (FLICKER_BUFFER_LAST),a                        ;#536A: 32 6F E1
        jr      UPDATE_MISC_TASKS                              ;#536D: 18 0E

FLICKER_BUFFER_SHIFT:
        ; Shifts sprite attribute history buffer to create flickering effect
        ld      a,(FLICKER_BUFFER_LAST)                        ;#536F: 3A 6F E1
        ld      hl,FLICKER_BUFFER_LAST-1                       ;#5372: 21 6E E1
        ld      de,FLICKER_BUFFER_LAST                         ;#5375: 11 6F E1
        lddr                                                   ;#5378: ED B8
        ld      (FLICKER_SPRITE_BUFFER),a                      ;#537A: 32 50 E1
UPDATE_MISC_TASKS:
        ; Tick the 16-frame pacer (E197); run secondary-slot direction toggle
        call    INIT_VRAM_DONE                                 ;#537D: CD 0B 51
        ld      hl,MISC_TICK_PACER                             ;#5380: 21 97 E1
        inc     (hl)                                           ;#5383: 34
        ld      a,(hl)                                         ;#5384: 7E
        and     0Fh                                            ;#5385: E6 0F
        jr      nz,CHECK_DISTANCE_PERIODIC                     ;#5387: 20 10
        dec     hl                                             ;#5389: 2B
        dec     hl                                             ;#538A: 2B
        cp      (hl)                                           ;#538B: BE
        jr      z,CHECK_DISTANCE_PERIODIC                      ;#538C: 28 0B
        dec     (hl)                                           ;#538E: 35
        jr      nz,CHECK_DISTANCE_PERIODIC                     ;#538F: 20 08
        dec     hl                                             ;#5391: 2B
        ld      a,(hl)                                         ;#5392: 7E
        xor     1                                              ;#5393: EE 01
        ld      (hl),a                                         ;#5395: 77
        call    DRAW_DISTANCE_EVENT_STREAM                     ;#5396: CD 3F 53
CHECK_DISTANCE_PERIODIC:
        ; Even-hundreds distance milestone (low<45h, every 16 frames)
        ld      hl,(STAGE_DISTANCE_BCD)                        ;#5399: 2A E5 E0
        ld      a,h                                            ;#539C: 7C
        and     1                                              ;#539D: E6 01
        ret     nz                                             ;#539F: C0
        ld      a,l                                            ;#53A0: 7D
        cp      45h                                            ;#53A1: FE 45
        ret     nc                                             ;#53A3: D0
        ld      hl,MISC_TICK_PACER                             ;#53A4: 21 97 E1
        ld      a,(hl)                                         ;#53A7: 7E
        and     0Fh                                            ;#53A8: E6 0F
        ret     nz                                             ;#53AA: C0
        dec     hl                                             ;#53AB: 2B
        ld      (hl),a                                         ;#53AC: 77
        ld      hl,DISTANCE_EVENT_STREAMS+8                    ;#53AD: 21 0A 54
        call    WRITE_VRAM_STREAM_INDEXED                      ;#53B0: CD 42 53
        call    PREPARE_CURVE_OVERLAY_WATER                    ;#53B3: CD C1 54
HANDLE_PENGUIN_DRIFT:
        ; Auto X-drift driven by latest distance-milestone scenery side; see INTERNALS.md
        ld      hl,PENGUIN_DRIFT_FLAG                          ;#53B6: 21 96 E1
        ld      a,(hl)                                         ;#53B9: 7E
        or      a                                              ;#53BA: B7
        ret     z                                              ;#53BB: C8
        inc     hl                                             ;#53BC: 23
        inc     hl                                             ;#53BD: 23
        dec     (hl)                                           ;#53BE: 35
        ret     nz                                             ;#53BF: C0
        ld      a,(PENGUIN_SPEED)                              ;#53C0: 3A 00 E1
        srl     a                                              ;#53C3: CB 3F
        srl     a                                              ;#53C5: CB 3F
        ld      (hl),a                                         ;#53C7: 77
        ld      hl,DEBUG_FLAGS                                 ;#53C8: 21 D1 E0
        ld      de,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)      ;#53CB: ED 5B 78 E0
        ld      a,(DISTANCE_EVENT_INDEX)                       ;#53CF: 3A 94 E1
        rra                                                    ;#53D2: 1F
        jr      c,DRIFT_MOVE_RIGHT                             ;#53D3: 38 06
        call    MOVE_PENGUIN_LEFT                              ;#53D5: CD 9C 4C
        jp      SWAP_AND_UPDATE_PENGUIN_COORDS                 ;#53D8: C3 C2 4B

DRIFT_MOVE_RIGHT:
        ; Right-direction branch of HANDLE_PENGUIN_DRIFT
        call    MOVE_PENGUIN_RIGHT                             ;#53DB: CD B9 4C
        jp      SWAP_AND_UPDATE_PENGUIN_COORDS                 ;#53DE: C3 C2 4B

DISTANCE_EVENT_TABLE:
        ; Table of event flags based on distance (FF=End)
        ; Format: FORMAT_DISTANCE_EVENT
        ; - Each nibble: bits 0-1 = sign index (0..2; 3=skip), bit 2 = secondary-slot
        ; flag, bit 3 = forces bit 1 of the index (8h=index 2, Fh and 9h skip).
        DISTANCE_EVENT 0Fh, 8                                  ;#53E1: F8
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53E2: FF
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53E3: FF
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53E4: FF
        DISTANCE_EVENT 9, 9                                    ;#53E5: 99
        DISTANCE_EVENT 0Fh, 8                                  ;#53E6: F8
        DISTANCE_EVENT 8, 0Fh                                  ;#53E7: 8F
        DISTANCE_EVENT 0Fh, 9                                  ;#53E8: F9
        DISTANCE_EVENT 0Fh, 9                                  ;#53E9: F9
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53EA: FF
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53EB: FF
        DISTANCE_EVENT 8, 8                                    ;#53EC: 88
        DISTANCE_EVENT 1, 0Fh                                  ;#53ED: 1F
        DISTANCE_EVENT 0Fh, 9                                  ;#53EE: F9
        DISTANCE_EVENT 0Fh, 9                                  ;#53EF: F9
        DISTANCE_EVENT 0, 0Fh                                  ;#53F0: 0F
        DISTANCE_EVENT 1, 0Fh                                  ;#53F1: 1F
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53F2: FF
        DISTANCE_EVENT 8, 0Fh                                  ;#53F3: 8F
        DISTANCE_EVENT 9, 9                                    ;#53F4: 99
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53F5: FF
        DISTANCE_EVENT 8, 1                                    ;#53F6: 81
        DISTANCE_EVENT 0, 0Fh                                  ;#53F7: 0F
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53F8: FF
        DISTANCE_EVENT 0Fh, 8                                  ;#53F9: F8
        DISTANCE_EVENT 8, 0Fh                                  ;#53FA: 8F
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53FB: FF
        DISTANCE_EVENT 8, 0Fh                                  ;#53FC: 8F
        DISTANCE_EVENT 9, 9                                    ;#53FD: 99
        DISTANCE_EVENT 0Fh, 0Fh                                ;#53FE: FF
        DISTANCE_EVENT 0Fh, 0                                  ;#53FF: F0
        DISTANCE_EVENT 9, 9                                    ;#5400: 99
        DISTANCE_EVENT 0Fh, 0Fh                                ;#5401: FF

DISTANCE_EVENT_STREAMS:
        ; 8-entry pointer table of distance-milestone VRAM streams
        dw      STREAM_ICE_LEFT                                ;#5402: 12 54
        dw      STREAM_ICE_RIGHT                               ;#5404: 23 54
        dw      STREAM_WATER_CURVE_LEFT                        ;#5406: 45 54
        dw      STREAM_WATER_CURVE_RIGHT                       ;#5408: 64 54
        dw      STREAM_SMALL_ICE                               ;#540A: 34 54
        dw      STREAM_SMALL_ICE                               ;#540C: 34 54
        dw      STREAM_WATER_STRAIGHT_RIGHT                    ;#540E: A2 54
        dw      STREAM_WATER_STRAIGHT_LEFT                     ;#5410: 83 54

STREAM_ICE_LEFT:
        ; VRAM stream for ice patch (left-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#5412: 49 39
        VRAM_TILES "1414131315303031101010323323"              ;#5414: 14 14 13 13 15 30 30 31 10 10 10 32 33 23
        STREAM_BLOCK_END                                       ;#5422: FF

STREAM_ICE_RIGHT:
        ; VRAM stream for ice patch (right-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#5423: 49 39
        VRAM_TILES "2374321010103130301513131414"              ;#5425: 23 74 32 10 10 10 31 30 30 15 13 13 14 14
        STREAM_BLOCK_END                                       ;#5433: FF

STREAM_SMALL_ICE:
        ; VRAM stream for small ice patch
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#5434: 49 39
        VRAM_TILES "1514131252100F0F101112131415"              ;#5436: 15 14 13 12 52 10 0F 0F 10 11 12 13 14 15
        STREAM_BLOCK_END                                       ;#5444: FF

STREAM_WATER_CURVE_LEFT:
        ; VRAM stream for curved water (left-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#5445: 49 39
        VRAM_TILES "14141313153030311010104147535354"          ;#5447: 14 14 13 13 15 30 30 31 10 10 10 41 47 53 53 54
        VRAM_TILES "54545454545454"                            ;#5457: 54 54 54 54 54 54 54
        STREAM_NEXT_BLOCK                                      ;#545E: FE
        VRAM_NAME_TABLE 0Bh, 12h                               ;#545F: 72 39
        VRAM_TILES "0F3E"                                      ;#5461: 0F 3E
        STREAM_BLOCK_END                                       ;#5463: FF

STREAM_WATER_CURVE_RIGHT:
        ; VRAM stream for curved water (right-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 0                                 ;#5464: 40 39
        VRAM_TILES "54545454545454545353888210101031"          ;#5466: 54 54 54 54 54 54 54 54 53 53 88 82 10 10 10 31
        VRAM_TILES "30301513131414"                            ;#5476: 30 30 15 13 13 14 14
        STREAM_NEXT_BLOCK                                      ;#547D: FE
        VRAM_NAME_TABLE 0Bh, 0Ch                               ;#547E: 6C 39
        VRAM_TILES "7F0F"                                      ;#5480: 7F 0F
        STREAM_BLOCK_END                                       ;#5482: FF

STREAM_WATER_STRAIGHT_LEFT:
        ; VRAM stream for straight water (left-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 0                                 ;#5483: 40 39
        VRAM_TILES "040404040404040404040404047D7A0F"          ;#5485: 04 04 04 04 04 04 04 04 04 04 04 04 04 7D 7A 0F
        VRAM_TILES "0F101112131415"                            ;#5495: 0F 10 11 12 13 14 15
        STREAM_NEXT_BLOCK                                      ;#549C: FE
        VRAM_NAME_TABLE 0Bh, 0Ch                               ;#549D: 6C 39
        VRAM_TILES "7978"                                      ;#549F: 79 78
        STREAM_BLOCK_END                                       ;#54A1: FF

STREAM_WATER_STRAIGHT_RIGHT:
        ; VRAM stream for straight water (right-facing)
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 9                                 ;#54A2: 49 39
        VRAM_TILES "1514131252100F0F393C040404040404"          ;#54A4: 15 14 13 12 52 10 0F 0F 39 3C 04 04 04 04 04 04
        VRAM_TILES "04040404040404"                            ;#54B4: 04 04 04 04 04 04 04
        STREAM_NEXT_BLOCK                                      ;#54BB: FE
        VRAM_NAME_TABLE 0Bh, 12h                               ;#54BC: 72 39
        VRAM_TILES "3738"                                      ;#54BE: 37 38
        STREAM_BLOCK_END                                       ;#54C0: FF

PREPARE_CURVE_OVERLAY_WATER:
        ; Set HL=ROAD_WATER_RIGHT_1_INIT for the curve-tile overlay write
        ld      hl,ROAD_WATER_RIGHT_1_INIT                     ;#54C1: 21 E7 72
        jr      UPDATE_CURVE_OVERLAY_SEGMENT                   ;#54C4: 18 03

PREPARE_CURVE_OVERLAY_ICE:
        ; Set HL=ROAD_ICE_RIGHT_1_INIT for the curve-tile overlay write
        ld      hl,ROAD_ICE_RIGHT_1_INIT                       ;#54C6: 21 75 72
UPDATE_CURVE_OVERLAY_SEGMENT:
        ; Upload curve road-segment tiles when DISTANCE_EVENT_INDEX bit 1 is set
        ld      a,(DISTANCE_EVENT_INDEX)                       ;#54C9: 3A 94 E1
        bit     1,a                                            ;#54CC: CB 4F
        ret     z                                              ;#54CE: C8
        rra                                                    ;#54CF: 1F
        ld      a,(hl)                                         ;#54D0: 7E
        jr      nc,UPDATE_CURVE_OVERLAY_DONE                   ;#54D1: 30 02
        sub     10h                                            ;#54D3: D6 10
UPDATE_CURVE_OVERLAY_DONE:
        ; Rejoin point in UPDATE_CURVE_OVERLAY_SEGMENT after the curve-flag check
        ld      e,a                                            ;#54D5: 5F
        jp      UPLOAD_ROAD_SEG_DONE                           ;#54D6: C3 F9 50

UPDATE_VICTORY_PENGUIN_ANIM:
        ; Update penguin waddling animation during goal sequence
        ld      a,(FRAME_COUNTER)                              ;#54D9: 3A 03 E0
        and     3                                              ;#54DC: E6 03
        ret     nz                                             ;#54DE: C0
        inc     c                                              ;#54DF: 0C
        jr      nz,CALC_VICTORY_WADDLE_OFFSET                  ;#54E0: 20 26
        ld      a,(VICTORY_WADDLE_BASE_X)                      ;#54E2: 3A 39 E1
        ld      c,a                                            ;#54E5: 4F
        xor     a                                              ;#54E6: AF
        ld      b,a                                            ;#54E7: 47
        ld      hl,70h                                         ;#54E8: 21 70 00
        sbc     hl,bc                                          ;#54EB: ED 42
        ld      a,(VICTORY_WADDLE_STEP)                        ;#54ED: 3A 38 E1
        ld      b,a                                            ;#54F0: 47
        ld      e,l                                            ;#54F1: 5D
        ld      d,h                                            ;#54F2: 54
VICTORY_CALC_LOOP:
        ; Loop for victory waddle calculation
        add     hl,de                                          ;#54F3: 19
        djnz    VICTORY_CALC_LOOP                              ;#54F4: 10 FD
        ld      a,h                                            ;#54F6: 7C
        rlca                                                   ;#54F7: 07
        rlca                                                   ;#54F8: 07
        rlca                                                   ;#54F9: 07
        rlca                                                   ;#54FA: 07
        and     0F0h                                           ;#54FB: E6 F0
        ld      e,a                                            ;#54FD: 5F
        ld      a,l                                            ;#54FE: 7D
        rrca                                                   ;#54FF: 0F
        rrca                                                   ;#5500: 0F
        rrca                                                   ;#5501: 0F
        rrca                                                   ;#5502: 0F
        and     0Fh                                            ;#5503: E6 0F
        or      e                                              ;#5505: B3
        add     a,c                                            ;#5506: 81
        ld      h,a                                            ;#5507: 67
CALC_VICTORY_WADDLE_OFFSET:
        ; Calculate new Y-offset for waddle effect
        ld      a,(SAT_MIRROR + SPRITE_PENGUIN + ATTR_Y)       ;#5508: 3A 78 E0
        dec     a                                              ;#550B: 3D
        ld      l,a                                            ;#550C: 6F
        call    UPDATE_PENGUIN_MULTI_SPRITE_COORDS             ;#550D: CD EC 4B
        call    UPDATE_PENGUIN_SPRITES                         ;#5510: CD D1 4C
        ld      hl,VICTORY_WADDLE_STEP                         ;#5513: 21 38 E1
        inc     (hl)                                           ;#5516: 34
        ld      a,10h                                          ;#5517: 3E 10
        cp      (hl)                                           ;#5519: BE
        ret                                                    ;#551A: C9

CYCLE_GOAL_PENGUIN_PATTERNS:
        ; Cycle penguin sprite patterns during victory dance
        xor     a                                              ;#551B: AF
        ld      (VICTORY_DANCE_COUNTER),a                      ;#551C: 32 3A E1
UPDATE_VICTORY_DANCE:
        ; Update victory dance animation counter
        ld      hl,VICTORY_DANCE_COUNTER                       ;#551F: 21 3A E1
        ld      a,(hl)                                         ;#5522: 7E
        inc     (hl)                                           ;#5523: 34
        ld      hl,VICTORY_DANCE_FRAME_1                       ;#5524: 21 4C 55
        rra                                                    ;#5527: 1F
        jr      nc,SET_VICTORY_FRAME_2                         ;#5528: 30 03
        ld      hl,VICTORY_DANCE_FRAME_2                       ;#552A: 21 60 55
SET_VICTORY_FRAME_2:
        ; Select second frame of victory dance
        call    WRITE_VRAM_TILES_STREAM                        ;#552D: CD 33 45
        ret                                                    ;#5530: C9

LOAD_VICTORY_GFX:
        ; Load supplementary sprite data for victory sequence
        ld      hl,VICTORY_SPRITE_PATTERNS                     ;#5531: 21 81 6B
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5534: CD 60 45
        ld      hl,GOAL_FLAG_ATTRIBUTES                        ;#5537: 21 46 67
        ld      de,SAT_MIRROR + SPRITE_AUX + ATTR_Y            ;#553A: 11 6C E0
        ld      bc,10h                                         ;#553D: 01 10 00
        ldir                                                   ;#5540: ED B0
        call    SYNC_SPRITE_ATTRIBUTES_ALL                     ;#5542: CD E3 66
        ld      hl,VICTORY_DANCE_FRAME_3                       ;#5545: 21 6A 55
        call    WRITE_VRAM_TILES_STREAM                        ;#5548: CD 33 45
        ret                                                    ;#554B: C9

VICTORY_DANCE_FRAME_1:
        ; Victory dance tile-stream frame 1
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 8                              ;#554C: E1
        VRAM_TILE_COLUMN 0Fh                                   ;#554D: EF
        VRAM_TILES "B6B7"                                      ;#554E: B6 B7
        VRAM_TILE_COLUMN 0Eh                                   ;#5550: EE
        VRAM_TILES "B8B9BABB"                                  ;#5551: B8 B9 BA BB
        VRAM_TILE_COLUMN 0Eh                                   ;#5555: EE
        VRAM_TILES "BEBFC0BC"                                  ;#5556: BE BF C0 BC
        VRAM_TILE_COLUMN 0Eh                                   ;#555A: EE
        VRAM_TILES "C3C4C5C6"                                  ;#555B: C3 C4 C5 C6
        db      00h                                            ;#555F: 00

VICTORY_DANCE_FRAME_2:
        ; Victory dance tile-stream frame 2
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3A00h, 1                              ;#5560: 02
        VRAM_TILE_COLUMN 0Eh                                   ;#5561: EE
        VRAM_TILES "C2"                                        ;#5562: C2
        VRAM_TILE_COLUMN 0Eh                                   ;#5563: EE
        VRAM_TILES "BDC1"                                      ;#5564: BD C1
        VRAM_TILE_COLUMN 0Eh                                   ;#5566: EE
        VRAM_TILES "C7C8"                                      ;#5567: C7 C8
        db      00h                                            ;#5569: 00

VICTORY_DANCE_FRAME_3:
        ; Victory dance tile-stream frame 3 (penguin on pedestal)
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 8                              ;#556A: E1
        VRAM_TILE_COLUMN 0Eh                                   ;#556B: EE
        VRAM_TILES "D2D5D8"                                    ;#556C: D2 D5 D8
        VRAM_TILE_COLUMN 0Eh                                   ;#556F: EE
        VRAM_TILES "D3D6D9DB"                                  ;#5570: D3 D6 D9 DB
        VRAM_TILE_COLUMN 0Eh                                   ;#5574: EE
        VRAM_TILES "D4D7DADC"                                  ;#5575: D4 D7 DA DC
        VRAM_TILE_COLUMN 0Eh                                   ;#5579: EE
        VRAM_TILES "DDDEDF0F"                                  ;#557A: DD DE DF 0F
        db      00h                                            ;#557E: 00

INIT_GOAL_GRAPHICS:
        ; Decompress and initialize goal-specific VRAM graphics
        ld      hl,GFX_GOAL_COLOR_PATCH                        ;#557F: 21 50 66
        LOAD_VRAM_WRITE de, 1100h                              ;#5582: 11 00 51
        call    DECOMPRESS_VRAM_DIRECT                         ;#5585: CD 64 45
        ld      hl,COUNTRY_NAME_POINTERS                       ;#5588: 21 D9 55
        ld      a,(CURRENT_STAGE_INDEX)                        ;#558B: 3A E1 E0
        ld      c,a                                            ;#558E: 4F
        add     a,a                                            ;#558F: 87
        call    ADD_HL_A                                       ;#5590: CD FE 48
        ld      e,(hl)                                         ;#5593: 5E
        inc     hl                                             ;#5594: 23
        ld      d,(hl)                                         ;#5595: 56
        ex      de,hl                                          ;#5596: EB
        call    WRITE_VRAM_STREAM                              ;#5597: CD A8 45
        ld      hl,FLAG_PTR_TABLE                              ;#559A: 21 5C 56
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#559D: 3A E0 E0
        and     0Fh                                            ;#55A0: E6 0F
        add     a,a                                            ;#55A2: 87
        call    ADD_HL_A                                       ;#55A3: CD FE 48
        ld      e,(hl)                                         ;#55A6: 5E
        inc     hl                                             ;#55A7: 23
        ld      d,(hl)                                         ;#55A8: 56
        ex      de,hl                                          ;#55A9: EB
        ld      de,GFX_FLAG_VRAM_DEST                          ;#55AA: 11 40 5F
        call    DECOMPRESS_VRAM_DIRECT                         ;#55AD: CD 64 45
        ld      a,(hl)                                         ;#55B0: 7E
        ld      (SAT_MIRROR + SPRITE_4 + ATTR_COLOR),a         ;#55B1: 32 63 E0
        inc     hl                                             ;#55B4: 23
        ld      a,(hl)                                         ;#55B5: 7E
        ld      (SAT_MIRROR + SPRITE_5 + ATTR_COLOR),a         ;#55B6: 32 67 E0
        jr      SYNC_GOAL_FLAG_SPRITES                         ;#55B9: 18 11

UPDATE_GOAL_FLAG_POSITION:
        ; Handle the flag ascending/positioning logic
        ld      a,(SAT_MIRROR + SPRITE_4 + ATTR_Y)             ;#55BB: 3A 60 E0
        sub     2                                              ;#55BE: D6 02
        cp      36h                                            ;#55C0: FE 36
        ret     z                                              ;#55C2: C8
        ld      (SAT_MIRROR + SPRITE_4 + ATTR_Y),a             ;#55C3: 32 60 E0
        ld      (SAT_MIRROR + SPRITE_5 + ATTR_Y),a             ;#55C6: 32 64 E0
        ld      (SAT_MIRROR + SPRITE_6 + ATTR_Y),a             ;#55C9: 32 68 E0
SYNC_GOAL_FLAG_SPRITES:
        ; Copy flag sprite attributes to VRAM
        ld      hl,SAT_MIRROR + SPRITE_4 + ATTR_Y              ;#55CC: 21 60 E0
        LOAD_SPRITE_ATTR de, 4, 0                              ;#55CF: 11 10 3B
        ld      bc,0Ch                                         ;#55D2: 01 0C 00
        call    COPY_RAM_TO_VRAM                               ;#55D5: CD EC 44
        ret                                                    ;#55D8: C9

COUNTRY_NAME_POINTERS:
        ; Table of pointers to country name strings (Japan to South Pole)
        dw      TXT_FRANCE                                     ;#55D9: 05 56
        dw      TXT_USA                                        ;#55DB: 20 56
        dw      TXT_SOUTH_POLE                                 ;#55DD: 49 56
        dw      TXT_USA                                        ;#55DF: 20 56
        dw      TXT_USA                                        ;#55E1: 20 56
        dw      TXT_ARGENTINA                                  ;#55E3: 28 56
        dw      TXT_UK                                         ;#55E5: 36 56
        dw      TXT_JAPAN                                      ;#55E7: ED 55
        dw      TXT_AUSTRALIA                                  ;#55E9: F7 55
        dw      TXT_AUSTRALIA                                  ;#55EB: F7 55

TXT_JAPAN:
        ; "JAPAN" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 13                                  ;#55ED: CD 3A
        abyte -20h "@JAPAN@"                                   ;#55EF: 20 2A 21 30 21 2E 20
        db      0FFh                                           ;#55F6: FF

TXT_AUSTRALIA:
        ; "AUSTRALIA" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 11                                  ;#55F7: CB 3A
        abyte -20h "@AUSTRALIA@"                               ;#55F9: 20 21 35 33 34 32 21 2C 29 21 20
        db      0FFh                                           ;#5604: FF

TXT_FRANCE:
        ; "FRANCE" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 12                                  ;#5605: CC 3A
        abyte -20h "@", 0E9h, "RANCE@"                         ;#5607: 20 C9 32 21 2E 23 25 20
        db      0FFh                                           ;#560F: FF

TXT_NEW_ZEALAND:
        ; "NEW ZEALAND" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 10                                  ;#5610: CA 3A
        abyte -20h "@NE", 0EAh, "/", 0EBh, "EALAND@"           ;#5612: 20 2E 25 CA 0F CB 25 21 2C 21 2E 24 20
        db      0FFh                                           ;#561F: FF

TXT_USA:
        ; "USA" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 14                                  ;#5620: CE 3A
        abyte -20h "@USA@"                                     ;#5622: 20 35 33 21 20
        db      0FFh                                           ;#5627: FF

TXT_ARGENTINA:
        ; "ARGENTINA" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 11                                  ;#5628: CB 3A
        abyte -20h "@ARGENTINA@"                               ;#562A: 20 21 32 27 25 2E 34 29 2E 21 20
        db      0FFh                                           ;#5635: FF

TXT_UK:
        ; "UNITED KINGDOM" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 8                                   ;#5636: C8 3A
        abyte -20h "@UNITED/KINGDOM@"                          ;#5638: 20 35 2E 29 34 25 24 0F 2B 29 2E 27 24 2F 2D 20
        db      0FFh                                           ;#5648: FF

TXT_SOUTH_POLE:
        ; "SOUTH POLE" entry (name-table coord + string)
        TXT_NAME_TABLE 22, 8                                   ;#5649: C8 3A
        abyte -20h "@THE/SOUTH/POLE@"                          ;#564B: 20 34 28 25 0F 33 2F 35 34 28 0F 30 2F 2C 25 20
        db      0FFh                                           ;#565B: FF

FLAG_PTR_TABLE:
        ; Pointer table for finish line flag graphics (indexed by last time digit 0-9).
        dw      FLAG_DATA_AUSTRALIA                            ;#565C: 89 56
        dw      FLAG_DATA_FRANCE                               ;#565E: B8 56
        dw      FLAG_DATA_USA                                  ;#5660: F1 56
        dw      FLAG_DATA_SOUTH_POLE                           ;#5662: 75 57
        dw      FLAG_DATA_USA                                  ;#5664: F1 56
        dw      FLAG_DATA_USA                                  ;#5666: F1 56
        dw      FLAG_DATA_ARGENTINA                            ;#5668: 15 57
        dw      FLAG_DATA_UK                                   ;#566A: 38 57
        dw      FLAG_DATA_JAPAN                                ;#566C: 70 56
        dw      FLAG_DATA_AUSTRALIA                            ;#566E: 89 56

FLAG_DATA_JAPAN:
        ; Japan flag graphics (red circle on white)
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "0200820307030F82070309008280C003"             ;#5670: 02 00 82 03 07 03 0F 82 07 03 09 00 82 80 C0 03
        dh      "E082C0802700"                                 ;#5680: E0 82 C0 80 27 00
        db      00h                                            ;#5686: 00 06 0F
        FLAG_COLORS COLOR_DARK_RED, COLOR_WHITE                ;#5687

FLAG_DATA_AUSTRALIA:
        ; Australia flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "87CC6D0CFF0C6DCC090087C08000C000"             ;#5689: 87 CC 6D 0C FF 0C 6D CC 09 00 87 C0 80 00 C0 00
        dh      "80C00900070002FF02FB01FF0400893F"             ;#5699: 80 C0 09 00 07 00 02 FF 02 FB 01 FF 04 00 89 3F
        dh      "3B3F3D2F3B3FFFF703FF0400"                     ;#56A9: 3B 3F 3D 2F 3B 3F FF F7 03 FF 04 00
        db      00h                                            ;#56B5: 00 06 0D
        FLAG_COLORS COLOR_DARK_RED, COLOR_MAGENTA              ;#56B6

FLAG_DATA_FRANCE:
        ; France flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "10000C3F04000CF81400"                         ;#56B8: 10 00 0C 3F 04 00 0C F8 14 00
        db      00h                                            ;#56C2: 00 06 04
        FLAG_COLORS COLOR_DARK_RED, COLOR_DARK_BLUE            ;#56C3

FLAG_DATA_NEW_ZEALAND:
        ; New Zealand flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "87CC6D0CFF0C6DCC090087C08000C000"             ;#56C5: 87 CC 6D 0C FF 0C 6D CC 09 00 87 C0 80 00 C0 00
        dh      "80C00900070005FF04008C3F3F373F3B"             ;#56D5: 80 C0 09 00 07 00 05 FF 04 00 8C 3F 3F 37 3F 3B
        dh      "2F3FFFFFF7FFFF0400"                           ;#56E5: 2F 3F FF FF F7 FF FF 04 00
        db      00h                                            ;#56EE: 00 06 0D
        FLAG_COLORS COLOR_DARK_RED, COLOR_MAGENTA              ;#56EF

FLAG_DATA_USA:
        ; USA flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "070085FF00FF00FF05008BFF00FF00FF"             ;#56F1: 07 00 85 FF 00 FF 00 FF 05 00 8B FF 00 FF 00 FF
        dh      "00FF00FF00FF04008655AA55AA55AA1A"             ;#5701: 00 FF 00 FF 00 FF 04 00 86 55 AA 55 AA 55 AA 1A
        dh      "00"                                           ;#5711: 00
        db      00h                                            ;#5712: 00 06 04
        FLAG_COLORS COLOR_DARK_RED, COLOR_DARK_BLUE            ;#5713

FLAG_DATA_ARGENTINA:
        ; Argentina flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "040084010303010C008480C0C0800800"             ;#5715: 04 00 84 01 03 03 01 0C 00 84 80 C0 C0 80 08 00
        dh      "04FF040004FF040004FF040004FF0400"             ;#5725: 04 FF 04 00 04 FF 04 00 04 FF 04 00 04 FF 04 00
        db      00h                                            ;#5735: 00 0A 07
        FLAG_COLORS COLOR_DARK_YELLOW, COLOR_CYAN              ;#5736

FLAG_DATA_UK:
        ; United Kingdom flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "8C6131190D01FFFF010D19316104008C"             ;#5738: 8C 61 31 19 0D 01 FF FF 01 0D 19 31 61 04 00 8C
        dh      "868C98B080FFFF80B0988C860400840C"             ;#5748: 86 8C 98 B0 80 FF FF 80 B0 98 8C 86 04 00 84 0C
        dh      "84C0E0040084E0C0840C040084302103"             ;#5758: 84 C0 E0 04 00 84 E0 C0 84 0C 04 00 84 30 21 03
        dh      "07040084070321300400"                         ;#5768: 07 04 00 84 07 03 21 30 04 00
        db      00h                                            ;#5772: 00 08 05
        FLAG_COLORS COLOR_MED_RED, COLOR_LIGHT_BLUE            ;#5773

FLAG_DATA_SOUTH_POLE:
        ; South Pole flag graphics
        ; Format: FORMAT_FLAG_DATA
        ; - Compressed sprite pattern data for the flags at the end of each stage.
        ; - The format uses bit-packed RLE and literal sequences.
        ; - Terminated by a 00h byte, followed by 2 bytes for the flag's sprite colors.
        dh      "8B03040A0C2C3E1808080C0705008BC0"             ;#5775: 8B 03 04 0A 0C 2C 3E 18 08 08 0C 07 05 00 8B C0
        dh      "20501030781C141030E0050085000002"             ;#5785: 20 50 10 30 78 1C 14 10 30 E0 05 00 85 00 00 02
        dh      "010303008300001805008500004080C0"             ;#5795: 01 03 03 00 83 00 00 18 05 00 85 00 00 40 80 C0
        dh      "0300830000180500"                             ;#57A5: 03 00 83 00 00 18 05 00
        db      00h                                            ;#57AD: 00 01 0A
        FLAG_COLORS COLOR_BLACK, COLOR_DARK_YELLOW             ;#57AE

HUD_STATIC_TEXT:
        ; Static HUD labels and sign graphics (e.g. "KM", "STAGE")
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 0, 0Ch                                 ;#57B0: 0C 38
        abyte -20h "HI@"                                       ;#57B2: 28 29 20
        STREAM_NEXT_BLOCK                                      ;#57B5: FE
        VRAM_NAME_TABLE 0, 16h                                 ;#57B6: 16 38
        abyte -20h "STAGE@"                                    ;#57B8: 33 34 21 27 25 20
        STREAM_NEXT_BLOCK                                      ;#57BE: FE
        VRAM_NAME_TABLE 1, 2                                   ;#57BF: 22 38
        abyte -20h "TIME@"                                     ;#57C1: 34 29 2D 25 20
        STREAM_NEXT_BLOCK                                      ;#57C6: FE
        VRAM_NAME_TABLE 1, 0Ch                                 ;#57C7: 2C 38
        abyte -20h "XZ[    `a"                                 ;#57C9: 38 3A 3B 00 00 00 00 40 41
        STREAM_NEXT_BLOCK                                      ;#57D2: FE
        VRAM_NAME_TABLE 1, 16h                                 ;#57D3: 36 38
        abyte -20h "FQW"                                       ;#57D5: 26 31 37
        STREAM_NEXT_BLOCK                                      ;#57D8: FE
        VRAM_NAME_TABLE 0, 2                                   ;#57D9: 02 38
        abyte -20h "1P@"                                       ;#57DB: 11 30 20
        STREAM_BLOCK_END                                       ;#57DE: FF

KONAMI_COPYRIGHT_TEXT:
        ; Copyright text stream ("© 1984") for opening animation
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 8, 0Ah                                 ;#57DF: 0A 39
        abyte -20h ":KONAMI 1984"                              ;#57E1: 1A 2B 2F 2E 21 2D 29 00 11 19 18 14
        STREAM_BLOCK_END                                       ;#57ED: FF

MSG_PLAY_SELECT:
        ; VRAM message stream for title/logo
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 0Dh, 0Bh                               ;#57EE: AB 39
        abyte -20h "PLAY SELECT"                               ;#57F0: 30 2C 21 39 00 33 25 2C 25 23 34
        STREAM_NEXT_BLOCK                                      ;#57FB: FE
        VRAM_NAME_TABLE 10h, 6                                 ;#57FC: 06 3A
        abyte -20h "1@", 5Ch, "]  PLAY ^_ JOYSTICK"            ;#57FE: 11 20 3C 3D 00 00 30 2C 21 39 00 3E 3F 00 2A 2F 39 33 34 29 23 2B
        STREAM_NEXT_BLOCK                                      ;#5814: FE
        VRAM_NAME_TABLE 12h, 6                                 ;#5815: 46 3A
        abyte -20h "2@", 5Ch, "]  PLAY ^_ KEYBOARD"            ;#5817: 12 20 3C 3D 00 00 30 2C 21 39 00 3E 3F 00 2B 25 39 22 2F 21 32 24
        STREAM_BLOCK_END                                       ;#582D: FF

MSG_TIME_OUT:
        ; Stream starting with STAGE message
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 7, 0Ch                                 ;#582E: EC 38
        abyte -20h "TIME OUT"                                  ;#5830: 34 29 2D 25 00 2F 35 34
        STREAM_BLOCK_END                                       ;#5838: FF

MSG_SOFTWARE:
        ; Stream with "SOFTWARE" message
        ; Format: FORMAT_VRAM_STREAM_TEXT
        ; - Same block/address control as FORMAT_VRAM_STREAM.
        ; - Payload bytes use offset for readable ASCII-like text output.
        VRAM_NAME_TABLE 0Ah, 0Ah                               ;#5839: 4A 39
        abyte -20h ",=", 0A0h, 8Ch, "Y", 0A8h, "SO;T<ARE "     ;#583B: 0C 1D 80 6C 39 88 33 2F 1B 34 1C 21 32 25 00

INPUT_DEMO_PLAY_DATA:
        ; Stored inputs used for demo play
        ; Format: FORMAT_INPUT_DEMO_PLAY
        INPUT_DEMO_PLAY KEY_NONE                               ;#584A: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#584B: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#584C: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#584D: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#584E: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#584F: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#5850: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#5851: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#5852: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#5853: 00
        INPUT_DEMO_PLAY KEY_NONE                               ;#5854: 00
        INPUT_DEMO_PLAY KEY_UP                                 ;#5855: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5856: 09
        INPUT_DEMO_PLAY KEY_UP                                 ;#5857: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5858: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#5859: 11
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT                      ;#585A: 05
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT                      ;#585B: 05
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#585C: 09
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#585D: 09
        INPUT_DEMO_PLAY KEY_UP                                 ;#585E: 01
        INPUT_DEMO_PLAY KEY_DOWN | KEY_LEFT                    ;#585F: 06
        INPUT_DEMO_PLAY KEY_LEFT                               ;#5860: 04
        INPUT_DEMO_PLAY KEY_SPACE                              ;#5861: 10
        INPUT_DEMO_PLAY KEY_UP                                 ;#5862: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5863: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#5864: 11
        INPUT_DEMO_PLAY KEY_SPACE                              ;#5865: 10
        INPUT_DEMO_PLAY KEY_UP                                 ;#5866: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5867: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5868: 09
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#5869: 09
        INPUT_DEMO_PLAY KEY_UP                                 ;#586A: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT                      ;#586B: 05
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT | KEY_SPACE          ;#586C: 15
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#586D: 09
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT | KEY_SPACE         ;#586E: 19
        INPUT_DEMO_PLAY KEY_UP                                 ;#586F: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5870: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_LEFT                      ;#5871: 05
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#5872: 11
        INPUT_DEMO_PLAY KEY_UP                                 ;#5873: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5874: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5875: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#5876: 11
        INPUT_DEMO_PLAY KEY_UP                                 ;#5877: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5878: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5879: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#587A: 11
        INPUT_DEMO_PLAY KEY_UP                                 ;#587B: 01
        INPUT_DEMO_PLAY KEY_NONE                               ;#587C: 00
        INPUT_DEMO_PLAY KEY_RIGHT | KEY_SPACE                  ;#587D: 18
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT | KEY_SPACE         ;#587E: 19
        INPUT_DEMO_PLAY KEY_UP | KEY_RIGHT                     ;#587F: 09
        INPUT_DEMO_PLAY KEY_UP                                 ;#5880: 01
        INPUT_DEMO_PLAY KEY_UP | KEY_SPACE                     ;#5881: 11
        INPUT_DEMO_PLAY KEY_UP                                 ;#5882: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5883: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5884: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5885: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5886: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5887: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5888: 01
        INPUT_DEMO_PLAY KEY_UP                                 ;#5889: 01

INIT_ALL_VDP_PLANES:
        ; Sets up all three VDP pattern planes
        LOAD_VRAM_ADDRESS de, 0                                ;#588A: 11 00 00
        call    INIT_VDP_PLANE                                 ;#588D: CD 9C 58
        LOAD_VRAM_ADDRESS de, 800h                             ;#5890: 11 00 08
        call    INIT_VDP_PLANE                                 ;#5893: CD 9C 58
        LOAD_VRAM_ADDRESS de, 1000h                            ;#5896: 11 00 10
        jp      INIT_VDP_PLANE                                 ;#5899: C3 9C 58

INIT_VDP_PLANE:
        ; Sets up a single VDP pattern plane
        push    de                                             ;#589C: D5
        xor     a                                              ;#589D: AF
        ; This loop seeds solid color tiles for each MSX palette color index.
        ld      c,10h                                          ;#589E: 0E 10
VDP_INIT_COLOR_BLOCK:
        ; Outer loop for clearing VRAM plane
        ld      b,8                                            ;#58A0: 06 08
VDP_INIT_COLOR_BLOCK_LINE:
        ; Inner loop for clearing VRAM plane
        call    WRITE_VRAM_BYTE                                ;#58A2: CD D0 48
        inc     de                                             ;#58A5: 13
        djnz    VDP_INIT_COLOR_BLOCK_LINE                      ;#58A6: 10 FA
        inc     a                                              ;#58A8: 3C
        dec     c                                              ;#58A9: 0D
        jr      nz,VDP_INIT_COLOR_BLOCK                        ;#58AA: 20 F4
        ld      bc,270h                                        ;#58AC: 01 70 02
        LOAD_VRAM_COLOR a, COLOR_WHITE, COLOR_TRANSPARENT      ;#58AF: 3E F0
        call    FILL_VRAM                                      ;#58B1: CD FD 44
        ld      hl,GFX_STARTUP_COLOR_TABLE                     ;#58B4: 21 B0 5D
        call    DECOMPRESS_VRAM_DATA_ONLY                      ;#58B7: CD 6D 45
        ld      b,16h                                          ;#58BA: 06 16
VDP_INIT_COLOR_LOOP:
        ; Loop for decompressing startup patterns
        ld      hl,GFX_STARTUP_COLOR_TABLE_LOOP                ;#58BC: 21 E6 5D
        push    bc                                             ;#58BF: C5
        call    DECOMPRESS_VRAM_DATA_ONLY                      ;#58C0: CD 6D 45
        pop     bc                                             ;#58C3: C1
        djnz    VDP_INIT_COLOR_LOOP                            ;#58C4: 10 F6
        pop     de                                             ;#58C6: D1
        LOAD_VRAM_WRITE hl, 2000h                              ;#58C7: 21 00 60
        add     hl,de                                          ;#58CA: 19
        ex      de,hl                                          ;#58CB: EB
        ld      hl,GFX_STARTUP_PATTERNS                        ;#58CC: 21 DB 58
        call    DECOMPRESS_VRAM_DIRECT                         ;#58CF: CD 64 45
        ld      hl,GFX_STARTUP_PATT_EXTRA1                     ;#58D2: 21 5B 5C
        call    DECOMPRESS_VRAM_DATA_ONLY                      ;#58D5: CD 6D 45
        ; Fallthrough: GFX_STARTUP_PATT_EXTRA2
        jp      DECOMPRESS_VRAM_DATA_ONLY                      ;#58D8: C3 6D 45

GFX_STARTUP_PATTERNS:
        ; Main startup patterns
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "4000400083001C22036385221C001838"             ;#58DB: 40 00 40 00 83 00 1C 22 03 63 85 22 1C 00 18 38
        dh      "0418AE7E003E63030E3C707F003E6303"             ;#58EB: 04 18 AE 7E 00 3E 63 03 0E 3C 70 7F 00 3E 63 03
        dh      "0E03633E000E1E3666667F06007F607E"             ;#58FB: 0E 03 63 3E 00 0E 1E 36 66 66 7F 06 00 7F 60 7E
        dh      "6303633E003E63607E63633E007F6306"             ;#590B: 63 03 63 3E 00 3E 63 60 7E 63 63 3E 00 7F 63 06
        dh      "0C031890003E63633E63633E003E6363"             ;#591B: 0C 03 18 90 00 3E 63 63 3E 63 63 3E 00 3E 63 63
        dh      "3F03633EA03C4299A1A199423C007F60"             ;#592B: 3F 03 63 3E A0 3C 42 99 A1 A1 99 42 3C 00 7F 60
        dh      "607E6060600063636B6B7F7722000000"             ;#593B: 60 7E 60 60 60 00 63 63 6B 6B 7F 77 22 00 00 00
        dh      "FF0000000010000400817E0400921C36"             ;#594B: FF 00 00 00 00 10 00 04 00 81 7E 04 00 92 1C 36
        dh      "63637F6363007E63637E63637E003E63"             ;#595B: 63 63 7F 63 63 00 7E 63 63 7E 63 63 7E 00 3E 63
        dh      "036085633E007C6603639B667C007F60"             ;#596B: 03 60 85 63 3E 00 7C 66 03 63 9B 66 7C 00 7F 60
        dh      "607E60607F00EEAA8AEA2EA8E8003E63"             ;#597B: 60 7E 60 60 7F 00 EE AA 8A EA 2E A8 E8 00 3E 63
        dh      "606763633F000363817F036382003C05"             ;#598B: 60 67 63 63 3F 00 03 63 81 7F 03 63 82 00 3C 05
        dh      "18833C001F04068B663C0063666C787C"             ;#599B: 18 83 3C 00 1F 04 06 8B 66 3C 00 63 66 6C 78 7C
        dh      "6E67000660937F0063777F7F6B636300"             ;#59AB: 6E 67 00 06 60 93 7F 00 63 77 7F 7F 6B 63 63 00
        dh      "63737B7F6F6763003E0563833E007E03"             ;#59BB: 63 73 7B 7F 6F 67 63 00 3E 05 63 83 3E 00 7E 03
        dh      "639D7E606000EE8888EE8888EE007E63"             ;#59CB: 63 9D 7E 60 60 00 EE 88 88 EE 88 88 EE 00 7E 63
        dh      "63627C6663003E63603E03633E007E06"             ;#59DB: 63 62 7C 66 63 00 3E 63 60 3E 03 63 3E 00 7E 06
        dh      "1881000663823E00046385361C0800C0"             ;#59EB: 18 81 00 06 63 82 3E 00 04 63 85 36 1C 08 00 C0
        dh      "05A083C000F303DB88F3D3DB0066667E"             ;#59FB: 05 A0 83 C0 00 F3 03 DB 88 F3 D3 DB 00 66 66 7E
        dh      "3C03188D00DF1A18CC0616DE00F86060"             ;#5A0B: 3C 03 18 8D 00 DF 1A 18 CC 06 16 DE 00 F8 60 60
        dh      "670360A8000040495A73525900000092"             ;#5A1B: 67 03 60 A8 00 00 40 49 5A 73 52 59 00 00 00 92
        dh      "52CE02DC000002008AAAAADA00000848"             ;#5A2B: 52 CE 02 DC 00 00 02 00 8A AA AA DA 00 00 08 48
        dh      "EE4A4A6A000020242D39292D040001F0"             ;#5A3B: EE 4A 4A 6A 00 00 20 24 2D 39 29 2D 04 00 01 F0
        dh      "0350010007EE010007E00E0082070F06"             ;#5A4B: 03 50 01 00 07 EE 01 00 07 E0 0E 00 82 07 0F 06
        dh      "0082F8F0043E043F8B1F3F7FFFFEFCF8"             ;#5A5B: 00 82 F8 F0 04 3E 04 3F 8B 1F 3F 7F FF FE FC F8
        dh      "F0E0C0800300023E0500831F7FFB0500"             ;#5A6B: F0 E0 C0 80 03 00 02 3E 05 00 83 1F 7F FB 05 00
        dh      "830FCFEF05008378FCBC0500833F7FF3"             ;#5A7B: 83 0F CF EF 05 00 83 78 FC BC 05 00 83 3F 7F F3
        dh      "05008387C7C7050083BCFEDF05008878"             ;#5A8B: 05 00 83 87 C7 C7 05 00 83 BC FE DF 05 00 88 78
        dh      "FCBC60F0F0600003F0023F063E88F8FC"             ;#5A9B: FC BC 60 F0 F0 60 00 03 F0 02 3F 06 3E 88 F8 FC
        dh      "FE7F3F1F0F07033E857EFCFCF8E005F1"             ;#5AAB: FE 7F 3F 1F 0F 07 03 3E 85 7E FC FC F8 E0 05 F1
        dh      "83FB7F1F06EF82CF0F081E88E1033FF1"             ;#5ABB: 83 FB 7F 1F 06 EF 82 CF 0F 08 1E 88 E1 03 3F F1
        dh      "E1F37F1E07E781F7088F081E82F1F204"             ;#5ACB: E1 F3 7F 1E 07 E7 81 F7 08 8F 08 1E 82 F1 F2 04
        dh      "F597F2F1E010C868C82810E00000082E"             ;#5ADB: F5 97 F2 F1 E0 10 C8 68 C8 28 10 E0 00 00 08 2E
        dh      "6F7F3F7F0003070FDF03FF8300E0FC05"             ;#5AEB: 6F 7F 3F 7F 00 03 07 0F DF 03 FF 83 00 E0 FC 05
        dh      "FF040090E0F0FCFF0003030001010307"             ;#5AFB: FF 04 00 90 E0 F0 FC FF 00 03 03 00 01 01 03 07
        dh      "C08087E704FF030085C0F0FCFFFF0400"             ;#5B0B: C0 80 87 E7 04 FF 03 00 85 C0 F0 FC FF FF 04 00
        dh      "89C0E0E0F01018181D1D030F021F023F"             ;#5B1B: 89 C0 E0 E0 F0 10 18 18 1D 1D 03 0F 02 1F 02 3F
        dh      "027F02FF02F803E003F0830703010500"             ;#5B2B: 02 7F 02 FF 02 F8 03 E0 03 F0 83 07 03 01 05 00
        dh      "8880CEFF7F0F0F1F0003F803FC8EFFC0"             ;#5B3B: 88 80 CE FF 7F 0F 0F 1F 00 03 F8 03 FC 8E FF C0
        dh      "003E3F03030706061F1F0F8F03CF890F"             ;#5B4B: 00 3E 3F 03 03 07 06 06 1F 1F 0F 8F 03 CF 89 0F
        dh      "0080C0C0E0E0F0F0037F85FF7F7F5F4C"             ;#5B5B: 00 80 C0 C0 E0 E0 F0 F0 03 7F 85 FF 7F 7F 5F 4C
        dh      "06F002F8027F043F847F7FF8FC03F003"             ;#5B6B: 06 F0 02 F8 02 7F 04 3F 84 7F 7F F8 FC 03 F0 03
        dh      "E0037F873F3F1F1F0FC08003008380C0"             ;#5B7B: E0 03 7F 87 3F 3F 1F 1F 0F C0 80 03 00 83 80 C0
        dh      "C004FF841F07000003FF97FE3E1CC000"             ;#5B8B: C0 04 FF 84 1F 07 00 00 03 FF 97 FE 3E 1C C0 00
        dh      "FFFFFEFEFCFCF8F00F07070303071F1F"             ;#5B9B: FF FF FE FE FC FC F8 F0 0F 07 07 03 03 07 1F 1F
        dh      "F0F004E082C080031F820F07030005FF"             ;#5BAB: F0 F0 04 E0 82 C0 80 03 1F 82 0F 07 03 00 05 FF
        dh      "83FEF00005FF8338000085FEFCF8E080"             ;#5BBB: 83 FE F0 00 05 FF 83 38 00 00 85 FE FC F8 E0 80
        dh      "03008A7F67010307070F0F80C003E084"             ;#5BCB: 03 00 8A 7F 67 01 03 07 07 0F 0F 80 C0 03 E0 84
        dh      "C0C0800F051F8F0F0F80FCF8F1F3F3FF"             ;#5BDB: C0 C0 80 0F 05 1F 8F 0F 0F 80 FC F8 F1 F3 F3 FF
        dh      "FF010F1F3F3F07FF84FDFCFCF805FF84"             ;#5BEB: FF 01 0F 1F 3F 3F 07 FF 84 FD FC FC F8 05 FF 84
        dh      "3F1F03F804F089301000FFFF7F3F1F0F"             ;#5BFB: 3F 1F 03 F8 04 F0 89 30 10 00 FF FF 7F 3F 1F 0F
        dh      "030384070F1F0F0307050088010FFF00"             ;#5C0B: 03 03 84 07 0F 1F 0F 03 07 05 00 88 01 0F FF 00
        dh      "0001033F06FF857F3F01000006FF821F"             ;#5C1B: 00 01 03 3F 06 FF 85 7F 3F 01 00 00 06 FF 82 1F
        dh      "008340E040050098E0A080"                       ;#5C2B: 00 83 40 E0 40 05 00 98 E0 A0 80
        ret     po                                             ;#5C36: E0
        jr      nz,5BE1h                                       ;#5C37: 20 A8
        ret     pe                                             ;#5C39: E8
        nop                                                    ;#5C3A: 00
        xor     0AAh                                           ;#5C3B: EE AA
        xor     d                                              ;#5C3D: AA
        xor     d                                              ;#5C3E: AA
        jp      pe,8E8Ah                                       ;#5C3F: EA 8A 8E
        nop                                                    ;#5C42: 00
        adc     a,(hl)                                         ;#5C43: 8E
        adc     a,b                                            ;#5C44: 88
        adc     a,b                                            ;#5C45: 88
        adc     a,(hl)                                         ;#5C46: 8E
        adc     a,b                                            ;#5C47: 88
        adc     a,b                                            ;#5C48: 88
        xor     0                                              ;#5C49: EE 00
        ex      af,af'                                         ;#5C4B: 08
        nop                                                    ;#5C4C: 00
        dec     b                                              ;#5C4D: 05
        nop                                                    ;#5C4E: 00
        ld      b,0Fh                                          ;#5C4F: 06 0F
        ld      a,(bc)                                         ;#5C51: 0A
        nop                                                    ;#5C52: 00
        ld      b,0F0h                                         ;#5C53: 06 F0
        ld      a,(bc)                                         ;#5C55: 0A
        nop                                                    ;#5C56: 00
        ld      b,0FFh                                         ;#5C57: 06 FF
        dec     b                                              ;#5C59: 05
        nop                                                    ;#5C5A: 00

GFX_STARTUP_PATT_EXTRA1:
        ; Supplemental startup patterns
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "06C004FF10C00C0004FF060008030307"             ;#5C5B: 06 C0 04 FF 10 C0 0C 00 04 FF 06 00 08 03 03 07
        dh      "050002FF04E084C000FFFF13C006E005"             ;#5C6B: 05 00 02 FF 04 E0 84 C0 00 FF FF 13 C0 06 E0 05
        dh      "C0"                                           ;#5C7B: C0
        db      0                                              ;#5C7C: 00

GFX_STARTUP_PATT_EXTRA2:
        ; Supplemental startup patterns
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "0103070102030207030F831F1E1E033F"             ;#5C7D: 01 03 07 01 02 03 02 07 03 0F 83 1F 1E 1E 03 3F
        dh      "8D7C78F8E0E0F0F0F8F8787C3C3C03FE"             ;#5C8D: 8D 7C 78 F8 E0 E0 F0 F0 F8 F8 78 7C 3C 3C 03 FE
        dh      "831F0F0F0600843B3F3F3B053901B903"             ;#5C9D: 83 1F 0F 0F 06 00 84 3B 3F 3F 3B 05 39 01 B9 03
        dh      "00860307071F9FDF05C782C3C106008A"             ;#5CAD: 00 86 03 07 07 1F 9F DF 05 C7 82 C3 C1 06 00 8A
        dh      "C7CFCF000F1F9CDFCFC7060083C3E3E3"             ;#5CBD: C7 CF CF 00 0F 1F 9C DF CF C7 06 00 83 C3 E3 E3
        dh      "03F38473F3F3BB06008A18B9FBF3C383"             ;#5CCD: 03 F3 84 73 F3 F3 BB 06 00 8A 18 B9 FB F3 C3 83
        dh      "83818180060003FB84C08080C003F886"             ;#5CDD: 83 81 81 80 06 00 03 FB 84 C0 80 80 C0 03 F8 86
        dh      "00010363E1E003FB03E394F3FB7B3B00"             ;#5CED: 00 01 03 63 E1 E0 03 FB 03 E3 94 F3 FB 7B 3B 00
        dh      "00808000008F9FBFBCB8B8BCBF9F8F06"             ;#5CFD: 00 80 80 00 00 8F 9F BF BC B8 B8 BC BF 9F 8F 06
        dh      "0003800400038002030207030F831F1E"             ;#5D0D: 00 03 80 04 00 03 80 02 03 02 07 03 0F 83 1F 1E
        dh      "1E033F8D7C78F8E0E0F0F0F8F8787C3C"             ;#5D1D: 1E 03 3F 8D 7C 78 F8 E0 E0 F0 F0 F8 F8 78 7C 3C
        dh      "3C03FE831F0F0F06008B1E3F7F797070"             ;#5D2D: 3C 03 FE 83 1F 0F 0F 06 00 8B 1E 3F 7F 79 70 70
        dh      "787F3F9E0005E001EF03E703E383E1E1"             ;#5D3D: 78 7F 3F 9E 00 05 E0 01 EF 03 E7 03 E3 83 E1 E1
        dh      "E006008A1E1CBCBDB9F9F9F0F0E00600"             ;#5D4D: E0 06 00 8A 1E 1C BC BD B9 F9 F9 F0 F0 E0 06 00
        dh      "8A3CFEEEC7FFFFC0E7FF3E060084767F"             ;#5D5D: 8A 3C FE EE C7 FF FF C0 E7 FF 3E 06 00 84 76 7F
        dh      "7F7B0673030086060E0E3F3FBF038E84"             ;#5D6D: 7F 7B 06 73 03 00 86 06 0E 0E 3F 3F BF 03 8E 84
        dh      "8F8F8783060003B9043983BD9F8E0600"             ;#5D7D: 8F 8F 87 83 06 00 03 B9 04 39 83 BD 9F 8E 06 00
        dh      "85DCDDDFDFDE05DC06008AC3CFCEDC1F"             ;#5D8D: 85 DC DD DF DF DE 05 DC 06 00 8A C3 CF CE DC 1F
        dh      "1F1C0E0F0306008AC0E0E070F0F00070"             ;#5D9D: 1F 1C 0E 0F 03 06 00 8A C0 E0 E0 70 F0 F0 00 70
        dh      "F0E0"                                         ;#5DAD: F0 E0
        db      0                                              ;#5DAF: 00

GFX_STARTUP_COLOR_TABLE:
        ; Startup color table data for clearing plane
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "18F478F470F450F72074281F2060106A"             ;#5DB0: 18 F4 78 F4 70 F4 50 F7 20 74 28 1F 20 60 10 6A
        dh      "38EF021E061F02EF067F0AE70BEF061F"             ;#5DC0: 38 EF 02 1E 06 1F 02 EF 06 7F 0A E7 0B EF 06 1F
        dh      "05EF386F0216061F026F067F0A670B6F"             ;#5DD0: 05 EF 38 6F 02 16 06 1F 02 6F 06 7F 0A 67 0B 6F
        dh      "061F056F"                                     ;#5DE0: 06 1F 05 6F

GFX_STARTUP_COLOR_TABLE_TAIL:
        ; Startup clear tail stream entry (falls into loop filler)
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "0817"                                         ;#5DE4: 08 17

GFX_STARTUP_COLOR_TABLE_LOOP:
        ; Repeating color-table filler
        ; Fallthrough from GFX_STARTUP_COLOR_TABLE.
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "0AF1037102510141"                             ;#5DE6: 0A F1 03 71 02 51 01 41
        db      0                                              ;#5DEE: 00

GFX_STAGE_NIGHT_TILES:
        ; Night-stage tile-pattern patch (loaded by INIT_STAGE_SET_SKY_COLOR)
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "0819"                                         ;#5DEF: 08 19
        db      0                                              ;#5DF1: 00

GFX_INIT_BANK1:
        ; Decompress bank-1 patterns and colors at stage start
        ld      hl,GFX_BANK1_PATTERN                           ;#5DF2: 21 22 5E
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5DF5: CD 60 45
        ld      hl,GFX_BANK1_PATTERN+2                         ;#5DF8: 21 24 5E
        LOAD_VRAM_WRITE de, 2A88h                              ;#5DFB: 11 88 6A
        call    DECOMPRESS_VRAM_DIRECT_MIRROR                  ;#5DFE: CD 68 45
        ; Fallthrough: GFX_BANK1_PATTERN_PART2
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5E01: CD 60 45
        ld      hl,GFX_BANK1_COLOR_EXTRA                       ;#5E04: 21 AA 61
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5E07: CD 60 45
        ld      hl,GFX_BANK1_COLOR+2                           ;#5E0A: 21 B1 61
        LOAD_VRAM_WRITE de, 0A88h                              ;#5E0D: 11 88 4A
        call    DECOMPRESS_VRAM_DIRECT                         ;#5E10: CD 64 45
        ; Fallthrough: GFX_BANK1_COLOR_PART2
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5E13: CD 60 45
        ld      hl,GFX_BANK1_COLOR                             ;#5E16: 21 AF 61
        call    DECOMPRESS_VRAM_INDIRECT                       ;#5E19: CD 60 45
        ld      hl,GFX_BANK1_COLOR_EXTRA2                      ;#5E1C: 21 80 62
        jp      DECOMPRESS_VRAM_INDIRECT                       ;#5E1F: C3 60 45

GFX_BANK1_PATTERN:
        ; Bank 1 patterns: stage init (loaded by GFX_INIT_BANK1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 2880h                                      ;#5E22: 80 68
        dh      "8200FF070084FF0007FF0400A5FF00FF"             ;#5E24: 82 00 FF 07 00 84 FF 00 07 FF 04 00 A5 FF 00 FF
        dh      "FF0000FF00FF0000FF00FFFF00FF00FF"             ;#5E34: FF 00 00 FF 00 FF 00 00 FF 00 FF FF 00 FF 00 FF
        dh      "FF00FFFF00FF0000FF0000FF00031FFF"             ;#5E44: FF 00 FF FF 00 FF 00 00 FF 00 00 FF 00 03 1F FF
        dh      "1502030003FF8255AA030003FF890583"             ;#5E54: 15 02 03 00 03 FF 82 55 AA 03 00 03 FF 89 05 83
        dh      "1FFF0000FFFF0003FF8C0000FFFF00E0"             ;#5E64: 1F FF 00 00 FF FF 00 03 FF 8C 00 00 FF FF 00 E0
        dh      "FFFF0000FFFF030001FF030087FF0000"             ;#5E74: FF FF 00 00 FF FF 03 00 01 FF 03 00 87 FF 00 00
        dh      "FFFF2A05060089AA54031FFF2A050000"             ;#5E84: FF FF 2A 05 06 00 89 AA 54 03 1F FF 2A 05 00 00
        dh      "04FF85AA5522000003FF8BAA50070000"             ;#5E94: 04 FF 85 AA 55 22 00 00 03 FF 8B AA 50 07 00 00
        dh      "FFFFE01FFFFF030082FF0003FF030089"             ;#5EA4: FF FF E0 1F FF FF 03 00 82 FF 00 03 FF 03 00 89
        dh      "FFFF00FFFF00000F0104008817FFFF55"             ;#5EB4: FF FF 00 FF FF 00 00 0F 01 04 00 88 17 FF FF 55
        dh      "2A05000003FF8355AA110500820F0204"             ;#5EC4: 2A 05 00 00 03 FF 83 55 AA 11 05 00 82 0F 02 04
        dh      "00881FFFFFAA54031F0003FF010003FF"             ;#5ED4: 00 88 1F FF FF AA 54 03 1F 00 03 FF 01 00 03 FF
        dh      "010003FF860000FFFFAA55070004FF85"             ;#5EE4: 01 00 03 FF 86 00 00 FF FF AA 55 07 00 04 FF 85
        dh      "A8473F000003FF8800FFFF000FFF1502"             ;#5EF4: A8 47 3F 00 00 03 FF 88 00 FF FF 00 0F FF 15 02
        dh      "040003FF8900E0FFFF00FF00FFFF0400"             ;#5F04: 04 00 03 FF 89 00 E0 FF FF 00 FF 00 FF FF 04 00
        dh      "84FF0000FF0A0001FF0400843F00FFFF"             ;#5F14: 84 FF 00 00 FF 0A 00 01 FF 04 00 84 3F 00 FF FF
        dh      "03008A80FF0000FF7F1F0F0301030005"             ;#5F24: 03 00 8A 80 FF 00 00 FF 7F 1F 0F 03 01 03 00 05
        dh      "FF857F3F0F0701060003FF8D"                     ;#5F34: FF 85 7F 3F 0F 07 01 06 00 03 FF 8D

GFX_FLAG_VRAM_DEST:
        ; VRAM destination address constant for flag decompression
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "3F1F0703"                                     ;#5F40: 3F 1F 07 03
        db      0                                              ;#5F44: 00
        dh      "FF7F1F0F0701000007FF857F1F0F0701"             ;#5F45: FF 7F 1F 0F 07 01 00 00 07 FF 85 7F 1F 0F 07 01
        dh      "040006FF827F3F04FF911F070300070F"             ;#5F55: 04 00 06 FF 82 7F 3F 04 FF 91 1F 07 03 00 07 0F
        dh      "1F1F1F0F0703FF3F0F0301030084FF7F"             ;#5F65: 1F 1F 1F 0F 07 03 FF 3F 0F 03 01 03 00 84 FF 7F
        dh      "1F0F04000600021F05FF030003FF827F"             ;#5F75: 1F 0F 04 00 06 00 02 1F 05 FF 03 00 03 FF 82 7F
        dh      "1F"                                           ;#5F85: 1F

GFX_FLAG_BANK_DATA:
        ; Bank graphics data continuation
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "030003FF0500907F1F0F1F3F0F070107"             ;#5F86: 03 00 03 FF 05 00 90 7F 1F 0F 1F 3F 0F 07 01 07
        dh      "0F1F3F070300000400020105FF873F1F"             ;#5F96: 0F 1F 3F 07 03 00 00 04 00 02 01 05 FF 87 3F 1F
        dh      "3F7FFF00030900820103030083010307"             ;#5FA6: 3F 7F FF 00 03 09 00 82 01 03 03 00 83 01 03 07
        dh      "0500017F053F821F0F06FF067F8C1F0F"             ;#5FB6: 05 00 01 7F 05 3F 82 1F 0F 06 FF 06 7F 8C 1F 0F
        dh      "07017F1F0F030100030703FF053F"                 ;#5FC6: 07 01 7F 1F 0F 03 01 00 03 07 03 FF 05 3F
        db      0                                              ;#5FD4: 00

GFX_BANK1_PATTERN_PART2:
        ; Bank 1 patterns part 2: stage init (continuation of GFX_BANK1_PATTERN)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 2C90h                                      ;#5FD5: 90 6C
        dh      "0B0001FF0B000103070001FF070001F0"             ;#5FD7: 0B 00 01 FF 0B 00 01 03 07 00 01 FF 07 00 01 F0
        dh      "0400011F070001FF0400823FFF060002"             ;#5FE7: 04 00 01 1F 07 00 01 FF 04 00 82 3F FF 06 00 02
        dh      "FF060082FCFF050082010F060002FF06"             ;#5FF7: FF 06 00 82 FC FF 05 00 82 01 0F 06 00 02 FF 06
        dh      "0082F0FE060004FF1300010F070001C0"             ;#6007: 00 82 F0 FE 06 00 04 FF 13 00 01 0F 07 00 01 C0
        dh      "040001F80300820F7F06008280F00900"             ;#6017: 04 00 01 F8 03 00 82 0F 7F 06 00 82 80 F0 09 00
        dh      "0103070001E00700010F070001C00400"             ;#6027: 01 03 07 00 01 E0 07 00 01 0F 07 00 01 C0 04 00
        dh      "017F030F040001FE03F01F0001010700"             ;#6037: 01 7F 03 0F 04 00 01 FE 03 F0 1F 00 01 01 07 00
        dh      "018007000107070001E00B0001F80700"             ;#6047: 01 80 07 00 01 07 07 00 01 E0 0B 00 01 F8 07 00
        dh      "011F0400017F070001FE090002070600"             ;#6057: 01 1F 04 00 01 7F 07 00 01 FE 09 00 02 07 06 00
        dh      "85E0E0001F1F060002FF060002F80500"             ;#6067: 85 E0 E0 00 1F 1F 06 00 02 FF 06 00 02 F8 05 00
        dh      "021F060002F8060002FF0A0001030700"             ;#6077: 02 1F 06 00 02 F8 06 00 02 FF 0A 00 01 03 07 00
        dh      "01C00300847F7FFF7F040084FEFEFFFE"             ;#6087: 01 C0 03 00 84 7F 7F FF 7F 04 00 84 FE FE FF FE
        dh      "040004FF160002040A00023006000203"             ;#6097: 04 00 04 FF 16 00 02 04 0A 00 02 30 06 00 02 03
        dh      "030002C0090004F00C0006FF038001C0"             ;#60A7: 03 00 02 C0 09 00 04 F0 0C 00 06 FF 03 80 01 C0
        dh      "030E020803000203040202000100030F"             ;#60B7: 03 0E 02 08 03 00 02 03 04 02 02 00 01 00 03 0F
        dh      "0109040003E001200400937BE0E4E4E0"             ;#60C7: 01 09 04 00 03 E0 01 20 04 00 93 7B E0 E4 E4 E0
        dh      "E09800F6FFBFBFFFFF53003070770BF8"             ;#60D7: E0 98 00 F6 FF BF BF FF FF 53 00 30 70 77 0B F8
        dh      "87E00026EEEFFFFF049F04FF88FECC00"             ;#60E7: 87 E0 00 26 EE EF FF FF 04 9F 04 FF 88 FE CC 00
        dh      "24EEEFFF870F7F9B6F03010000226363"             ;#60F7: 24 EE EF FF 87 0F 7F 9B 6F 03 01 00 00 22 63 63
        dh      "F3F7F7FFFFDD8800DBFFFF0000026363"             ;#6107: F3 F7 F7 FF FF DD 88 00 DB FF FF 00 00 02 63 63
        dh      "F3F7F703FF07FE09FF82C381030002FF"             ;#6117: F3 F7 F7 03 FF 07 FE 09 FF 82 C3 81 03 00 02 FF
        dh      "010F0CFF010003FF85F7C782000003FF"             ;#6127: 01 0F 0C FF 01 00 03 FF 85 F7 C7 82 00 00 03 FF
        dh      "071F09FF07C308FF01F80DF70BFC0100"             ;#6137: 07 1F 09 FF 07 C3 08 FF 01 F8 0D F7 0B FC 01 00
        dh      "08FF847F22000004F78477220000024F"             ;#6147: 08 FF 84 7F 22 00 00 04 F7 84 77 22 00 00 02 4F
        dh      "067F0103150182030F04008480C0E0FF"             ;#6157: 06 7F 01 03 15 01 82 03 0F 04 00 84 80 C0 E0 FF
        dh      "0500820FFF050093F8E74D1800000F1F"             ;#6167: 05 00 82 0F FF 05 00 93 F8 E7 4D 18 00 00 0F 1F
        dh      "FAEBC5800000F0FC3FDC6803008503FF"             ;#6177: FA EB C5 80 00 00 F0 FC 3F DC 68 03 00 85 03 FF
        dh      "FFB5160500031F013F040004FF040084"             ;#6187: FF B5 16 05 00 03 1F 01 3F 04 00 04 FF 04 00 84
        dh      "C0FCFCFF040084FFEFFFF7040084FFD3"             ;#6197: C0 FC FC FF 04 00 84 FF EF FF F7 04 00 84 FF D3
        dh      "FDCE"                                         ;#61A7: FD CE
        db      0                                              ;#61A9: 00

GFX_BANK1_COLOR_EXTRA:
        ; Bank 1 color patch: stage init (small extra for GFX_INIT_BANK1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 2A98h                                      ;#61AA: 98 6A
        dh      "1000"                                         ;#61AC: 10 00
        db      0                                              ;#61AE: 00

GFX_BANK1_COLOR:
        ; Bank 1 colors: stage init (loaded by GFX_INIT_BANK1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 880h                                       ;#61AF: 80 48
        dh      "78EF78EF38EF604F064F821F412C4F82"             ;#61B1: 78 EF 78 EF 38 EF 60 4F 06 4F 82 1F 41 2C 4F 82
        dh      "1F410A4F181F024F03410A4F01410341"             ;#61C1: 1F 41 0A 4F 18 1F 02 4F 03 41 0A 4F 01 41 03 41
        dh      "0B4F021F054F0341"                             ;#61D1: 0B 4F 02 1F 05 4F 03 41
        db      0                                              ;#61D9: 00

GFX_BANK1_COLOR_PART2:
        ; Bank 1 colors part 2: stage init (continuation of GFX_BANK1_COLOR)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 0C90h                                      ;#61DA: 90 4C
        dh      "704F304F201F024F0241064F0241044F"             ;#61DC: 70 4F 30 4F 20 1F 02 4F 02 41 06 4F 02 41 04 4F
        dh      "785F305F01EF075F01EF075F01EF075F"             ;#61EC: 78 5F 30 5F 01 EF 07 5F 01 EF 07 5F 01 EF 07 5F
        dh      "4C3F04EF033F05EF023F06EF109F028F"             ;#61FC: 4C 3F 04 EF 03 3F 05 EF 02 3F 06 EF 10 9F 02 8F
        dh      "0689089F048F0B89046F039F0497069F"             ;#620C: 06 89 08 9F 04 8F 0B 89 04 6F 03 9F 04 97 06 9F
        dh      "036F039F0F96039F076F019F05F60396"             ;#621C: 03 6F 03 9F 0F 96 03 9F 07 6F 01 9F 05 F6 03 96
        dh      "076E018E09971F9F088F2097039F0D96"             ;#622C: 07 6E 01 8E 09 97 1F 9F 08 8F 20 97 03 9F 0D 96
        dh      "0B760D9F0396059F08961717011F08F7"             ;#623C: 0B 76 0D 9F 03 96 05 9F 08 96 17 17 01 1F 08 F7
        dh      "07F701F405F703F404F704F404F704F4"             ;#624C: 07 F7 01 F4 05 F7 03 F4 04 F7 04 F4 04 F7 04 F4
        dh      "03F705F428F7"                                 ;#625C: 03 F7 05 F4 28 F7
        db      0                                              ;#6262: 00

GFX_STAGE_NIGHT_COLORS:
        ; Night-stage color patch (paired with GFX_STAGE_NIGHT_TILES)
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "1719011F08F907F901F405F903F404F9"             ;#6263: 17 19 01 1F 08 F9 07 F9 01 F4 05 F9 03 F4 04 F9
        dh      "04F404F904F403F905F428F9"                     ;#6273: 04 F4 04 F9 04 F4 03 F9 05 F4 28 F9
        db      0                                              ;#627F: 00

GFX_BANK1_COLOR_EXTRA2:
        ; Bank 1 color patch 2: stage init (final extra for GFX_INIT_BANK1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 0A98h                                      ;#6280: 98 4A
        dh      "044F01410344034F01410444"                     ;#6282: 04 4F 01 41 03 44 03 4F 01 41 04 44
        db      0                                              ;#628E: 00

GFX_INIT_BANK2:
        ; Decompress bank-2 patterns and colors at stage start
        ld      hl,GFX_BANK2_PATTERN_PART1                     ;#628F: 21 C5 62
        call    DECOMPRESS_VRAM_INDIRECT                       ;#6292: CD 60 45
        ; Fallthrough: GFX_BANK2_COLOR_PART2
        call    DECOMPRESS_VRAM_INDIRECT                       ;#6295: CD 60 45
        ld      hl,GFX_BANK2_PATTERN_PART3                     ;#6298: 21 2C 5C
        call    DECOMPRESS_VRAM_DATA_ONLY                      ;#629B: CD 6D 45
        ld      hl,GFX_BANK2_PATTERN_PART1+2                   ;#629E: 21 C7 62
        LOAD_VRAM_WRITE de, 32B0h                              ;#62A1: 11 B0 72
        call    DECOMPRESS_VRAM_DIRECT_MIRROR                  ;#62A4: CD 68 45
        ld      hl,GFX_BANK2_PATTERN_PART4                     ;#62A7: 21 55 66
        call    DECOMPRESS_VRAM_INDIRECT                       ;#62AA: CD 60 45
        ld      hl,GFX_BANK2_COLOR_PART1                       ;#62AD: 21 79 65
        call    DECOMPRESS_VRAM_INDIRECT                       ;#62B0: CD 60 45
        ; Fallthrough: GFX_BANK2_COLOR_PART2
        call    DECOMPRESS_VRAM_INDIRECT                       ;#62B3: CD 60 45
        ld      hl,GFX_BANK2_COLOR_PART1+2                     ;#62B6: 21 7B 65
        LOAD_VRAM_WRITE de, 12B0h                              ;#62B9: 11 B0 52
        call    DECOMPRESS_VRAM_DIRECT                         ;#62BC: CD 64 45
        ld      hl,GFX_BANK2_COLOR_PART3                       ;#62BF: 21 B3 66
        jp      DECOMPRESS_VRAM_INDIRECT                       ;#62C2: C3 60 45

GFX_BANK2_PATTERN_PART1:
        ; Bank 2 patterns part 1: stage init (loaded by GFX_INIT_BANK2)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 3200h                                      ;#62C5: 00 72
        dh      "857F1F0F0301030005FF857F3F0F0701"             ;#62C7: 85 7F 1F 0F 03 01 03 00 05 FF 85 7F 3F 0F 07 01
        dh      "060003FF8D3F1F070300FF7F1F0F0701"             ;#62D7: 06 00 03 FF 8D 3F 1F 07 03 00 FF 7F 1F 0F 07 01
        dh      "000007FF857F1F0F0701040005FF837F"             ;#62E7: 00 00 07 FF 85 7F 1F 0F 07 01 04 00 05 FF 83 7F
        dh      "1F0F03FF857F1F0F070104FF861F0703"             ;#62F7: 1F 0F 03 FF 85 7F 1F 0F 07 01 04 FF 86 1F 07 03
        dh      "00FF7F060085FFFF0F0301030004FF04"             ;#6307: 00 FF 7F 06 00 85 FF FF 0F 03 01 03 00 04 FF 04
        dh      "0005FF8D7F00000103070F0F1F000001"             ;#6317: 00 05 FF 8D 7F 00 00 01 03 07 0F 0F 1F 00 00 01
        dh      "0306008407070F1F0500870103070F0F"             ;#6327: 03 06 00 84 07 07 0F 1F 05 00 87 01 03 07 0F 0F
        dh      "1F3F03FF017F0A3F921F0F7F1F0F0301"             ;#6337: 1F 3F 03 FF 01 7F 0A 3F 92 1F 0F 7F 1F 0F 03 01
        dh      "0003073F3F1F0F07010000"                       ;#6347: 00 03 07 3F 3F 1F 0F 07 01 00 00
        db      0                                              ;#6352: 00

GFX_BANK2_PATTERN_PART2:
        ; Bank 2 patterns part 2: stage init
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 3360h                                      ;#6353: 60 73
        dh      "030005FF010007FF02000DFF04008503"             ;#6355: 03 00 05 FF 01 00 07 FF 02 00 0D FF 04 00 85 03
        dh      "00000F7F030086F80000F0FF01040096"             ;#6365: 00 00 0F 7F 03 00 86 F8 00 00 F0 FF 01 04 00 96
        dh      "010F00FF3F00000FFFFF3FFFFCF8C000"             ;#6375: 01 0F 00 FF 3F 00 00 0F FF FF 3F FF FC F8 C0 00
        dh      "F0FFFFF0C080030084F8FF1F03030083"             ;#6385: F0 FF FF F0 C0 80 03 00 84 F8 FF 1F 03 03 00 83
        dh      "1FFF03030085E00000E0FE06008280F0"             ;#6395: 1F FF 03 03 00 85 E0 00 00 E0 FE 06 00 82 80 F0
        dh      "0300010F06008607FFFF07000003FF87"             ;#63A5: 03 00 01 0F 06 00 86 07 FF FF 07 00 00 03 FF 87
        dh      "FCF0FF0F00C080030083C0F07F070089"             ;#63B5: FC F0 FF 0F 00 C0 80 03 00 83 C0 F0 7F 07 00 89
        dh      "F0FCF8F0C000FCFF07070001FF030082"             ;#63C5: F0 FC F8 F0 C0 00 FC FF 07 07 00 01 FF 03 00 82
        dh      "FF0F0400860F7FFFFF7F0C040002FF03"             ;#63D5: FF 0F 04 00 86 0F 7F FF FF 7F 0C 04 00 02 FF 03
        dh      "3F030002FF03F802FF0D0F010003FF01"             ;#63E5: 3F 03 00 02 FF 03 F8 02 FF 0D 0F 01 00 03 FF 01
        dh      "FC0BF001FF08070300010F04FF010F04"             ;#63F5: FC 0B F0 01 FF 08 07 03 00 01 0F 04 FF 01 0F 04
        dh      "F784F0C00000071F070F010007F00200"             ;#6405: F7 84 F0 C0 00 00 07 1F 07 0F 01 00 07 F0 02 00
        dh      "07F802F006F08200C0060F82000306F0"             ;#6415: 07 F8 02 F0 06 F0 82 00 C0 06 0F 82 00 03 06 F0
        dh      "820F3F060F01FF047F010F0500850303"             ;#6425: 82 0F 3F 06 0F 01 FF 04 7F 01 0F 05 00 85 03 03
        dh      "0F0F030B008EC0C0F0F0C00000010707"             ;#6435: 0F 0F 03 0B 00 8E C0 C0 F0 F0 C0 00 00 01 07 07
        dh      "1F1F01FF09008C80E0E0F8F880000007"             ;#6445: 1F 1F 01 FF 09 00 8C 80 E0 E0 F8 F8 80 00 00 07
        dh      "1FF0E0040084E0F81F070600040F8500"             ;#6455: 1F F0 E0 04 00 84 E0 F8 1F 07 06 00 04 0F 85 00
        dh      "073FF8C0040084E0FC1F03070004F084"             ;#6465: 07 3F F8 C0 04 00 84 E0 FC 1F 03 07 00 04 F0 84
        dh      "FFFF3F01040004FF040084FFFFFC8004"             ;#6475: FF FF 3F 01 04 00 04 FF 04 00 84 FF FF FC 80 04
        dh      "00830F0F03050003FF011F040003FF01"             ;#6485: 00 83 0F 0F 03 05 00 03 FF 01 1F 04 00 03 FF 01
        dh      "F8040083F0F0C00900830F7FF806FF03"             ;#6495: F8 04 00 83 F0 F0 C0 09 00 83 0F 7F F8 06 FF 03
        dh      "0006FF020003FF050083FFFF3F050083"             ;#64A5: 00 06 FF 02 00 03 FF 05 00 83 FF FF 3F 05 00 83
        dh      "FFFFFC050008F0040004FF080F068082"             ;#64B5: FF FF FC 05 00 08 F0 04 00 04 FF 08 0F 06 80 82
        dh      "C0E0058083C000000608820C0F050801"             ;#64C5: C0 E0 05 80 83 C0 00 00 06 08 82 0C 0F 05 08 01
        dh      "0F0F009B0F0000071F3F7C78F2F2F0E0"             ;#64D5: 0F 0F 00 9B 0F 00 00 07 1F 3F 7C 78 F2 F2 F0 E0
        dh      "F8FC3E1E4F4F0F000001070F1F3C3005"             ;#64E5: F8 FC 3E 1E 4F 4F 0F 00 00 01 07 0F 1F 3C 30 05
        dh      "F883FCF0C0051F833F0F03870080E0F0"             ;#64F5: F8 83 FC F0 C0 05 1F 83 3F 0F 03 87 00 80 E0 F0
        dh      "F81C0C06800A0007010200058083C0C0"             ;#6505: F8 1C 0C 06 80 0A 00 07 01 02 00 05 80 83 C0 C0
        dh      "E0050183030307038098C04060A0E030"             ;#6515: E0 05 01 83 03 03 07 03 80 98 C0 40 60 A0 E0 30
        dh      "3C1F0F07030100000101030703000070"             ;#6525: 3C 1F 0F 07 03 01 00 00 01 01 03 07 03 00 00 70
        dh      "FFE303FF85000006FFE703FF03008880"             ;#6535: FF E3 03 FF 85 00 00 06 FF E7 03 FF 03 00 88 80
        dh      "80C0E0C000000103000101030088F07F"             ;#6545: 80 C0 E0 C0 00 00 01 03 00 01 01 03 00 88 F0 7F
        dh      "337FFFFF000098007F60607E60606000"             ;#6555: 33 7F FF FF 00 00 98 00 7F 60 60 7E 60 60 60 00
        dh      "63636B6B7F7722007F070E1C38707F06"             ;#6565: 63 63 6B 6B 7F 77 22 00 7F 07 0E 1C 38 70 7F 06
        dh      "000260"                                       ;#6575: 00 02 60
        db      0                                              ;#6578: 00

GFX_BANK2_COLOR_PART1:
        ; Bank 2 colors part 1: stage init (loaded by GFX_INIT_BANK2)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1200h                                      ;#6579: 00 52
        dh      "704F201F064F0841084F021F0241064F"             ;#657B: 70 4F 20 1F 06 4F 08 41 08 4F 02 1F 02 41 06 4F
        db      0                                              ;#658B: 00

GFX_BANK2_COLOR_PART2:
        ; Bank 2 colors part 2: stage init (continuation of PART1)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1360h                                      ;#658C: 60 53
        dh      "264F021F064F021F054F031F044F041F"             ;#658E: 26 4F 02 1F 06 4F 02 1F 05 4F 03 1F 04 4F 04 1F
        dh      "044F041F044F041F044F041F044F541F"             ;#659E: 04 4F 04 1F 04 4F 04 1F 04 4F 04 1F 04 4F 54 1F
        dh      "064F0241064F0241034F05410641024F"             ;#65AE: 06 4F 02 41 06 4F 02 41 03 4F 05 41 06 41 02 4F
        dh      "054F0341074102F40954071F041D041F"             ;#65BE: 05 4F 03 41 07 41 02 F4 09 54 07 1F 04 1D 04 1F
        dh      "0E45014F0745024F0745024F0645025F"             ;#65CE: 0E 45 01 4F 07 45 02 4F 07 45 02 4F 06 45 02 5F
        dh      "0645025F0645024F0645051D031F04EF"             ;#65DE: 06 45 02 5F 06 45 02 4F 06 45 05 1D 03 1F 04 EF
        dh      "065F02FE04F504EF045F04EF045F03FE"             ;#65EE: 06 5F 02 FE 04 F5 04 EF 04 5F 04 EF 04 5F 03 FE
        dh      "05F504EF045F04EF02E502F504EF02E5"             ;#65FE: 05 F5 04 EF 04 5F 04 EF 02 E5 02 F5 04 EF 02 E5
        dh      "02F506EF025F03EF02E503F503EF02E5"             ;#660E: 02 F5 06 EF 02 5F 03 EF 02 E5 03 F5 03 EF 02 E5
        dh      "03F506EF6A5F183F17EF01E105EF01E1"             ;#661E: 03 F5 06 EF 6A 5F 18 3F 17 EF 01 E1 05 EF 01 E1
        dh      "121F1A1F0216061F0216471F054F031F"             ;#662E: 12 1F 1A 1F 02 16 06 1F 02 16 47 1F 05 4F 03 1F
        dh      "054F031F054F031F054F031F054F031F"             ;#663E: 05 4F 03 1F 05 4F 03 1F 05 4F 03 1F 05 4F 03 1F
        dh      "054F"                                         ;#664E: 05 4F

GFX_GOAL_COLOR_PATCH:
        ; Goal-scene color patch (loaded by INIT_GOAL_GRAPHICS at the goal)
        ; Format: FORMAT_GFX
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        dh      "784F784F"                                     ;#6650: 78 4F 78 4F
        db      0                                              ;#6654: 00

GFX_BANK2_PATTERN_PART4:
        ; Bank 2 patterns part 4: stage init (loaded by GFX_INIT_BANK2)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 3690h                                      ;#6655: 90 76
        dh      "82020502000607020106020301030084"             ;#6657: 82 02 05 02 00 06 07 02 01 06 02 03 01 03 00 84
        dh      "2757070706FF82070109008380402004"             ;#6667: 27 57 07 07 06 FF 82 07 01 09 00 83 80 40 20 04
        dh      "FF02FE83FCFEFE04FF8B7F3F1F1F0F07"             ;#6677: FF 02 FE 83 FC FE FE 04 FF 8B 7F 3F 1F 1F 0F 07
        dh      "01000204080300038002C084E0F0F8C0"             ;#6687: 01 00 02 04 08 03 00 03 80 02 C0 84 E0 F0 F8 C0
        dh      "0400980001010100000000F8F0E0FF00"             ;#6697: 04 00 98 00 01 01 01 00 00 00 00 F8 F0 E0 FF 00
        dh      "00000000F0FCF800000000"                       ;#66A7: 00 00 00 00 F0 FC F8 00 00 00 00
        db      0                                              ;#66B2: 00

GFX_BANK2_COLOR_PART3:
        ; Bank 2 colors part 3: stage init (loaded by GFX_INIT_BANK2)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1690h                                      ;#66B3: 90 56
        dh      "581F03AF014F05AF02A40D4F"                     ;#66B5: 58 1F 03 AF 01 4F 05 AF 02 A4 0D 4F
        db      0                                              ;#66C1: 00

INIT_SPRITES_FROM_STREAM:
        ; Initialize quaternary stage VRAM graphics (Sprite data stream)
        ld      hl,SPRITE_INIT_TABLE                           ;#66C2: 21 EF 66
        jr      CLEAR_AND_INIT_SPRITE_ATTRS                    ;#66C5: 18 03

INIT_GOAL_SPRITES:
        ; Reset sprite attributes and initialize goal sequence sprites
        ld      hl,GOAL_SPRITE_DATA                            ;#66C7: 21 2C 67
CLEAR_AND_INIT_SPRITE_ATTRS:
        ; Clear SAT mirror, then init from HL stream ([Count][Y,X,Pat,Col]..., 00=End)
        push    hl                                             ;#66CA: E5
        ld      hl,SAT_MIRROR                                  ;#66CB: 21 50 E0
        push    hl                                             ;#66CE: E5
        ld      b,80h                                          ;#66CF: 06 80
INIT_SPRITE_ATTRS_CLEAR:
        ; Clear sprite attribute mirror loop
        ld      (hl),0                                         ;#66D1: 36 00
        inc     hl                                             ;#66D3: 23
        djnz    INIT_SPRITE_ATTRS_CLEAR                        ;#66D4: 10 FB
        pop     de                                             ;#66D6: D1
        pop     hl                                             ;#66D7: E1
INIT_SPRITE_ATTRS_LOOP:
        ; Internal loop for processing sprite attribute stream
        ld      a,(hl)                                         ;#66D8: 7E
        inc     hl                                             ;#66D9: 23
        or      a                                              ;#66DA: B7
        jr      z,SYNC_SPRITE_ATTRIBUTES_ALL                   ;#66DB: 28 06
        ld      c,a                                            ;#66DD: 4F
        call    REPLICATE_4_BYTE_BLOCK                         ;#66DE: CD BA 45
        jr      INIT_SPRITE_ATTRS_LOOP                         ;#66E1: 18 F5

SYNC_SPRITE_ATTRIBUTES_ALL:
        ; Sync all 32 sprite attributes to VRAM
        ld      hl,SAT_MIRROR                                  ;#66E3: 21 50 E0
        ld      de,VRAM_SAT_BASE                               ;#66E6: 11 00 3B
        ld      bc,80h                                         ;#66E9: 01 80 00
        jp      COPY_RAM_TO_VRAM                               ;#66EC: C3 EC 44

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
        SPRITE_ATTR_REPT 0Ah, 0E0h, 0, 7Ch, COLOR_TRANSPARENT  ;#66EF: 0A E0 00 7C 00
        SPRITE_ATTR_REPT 1, 90h, 70h, 0, COLOR_BLACK           ;#66F4: 01 90 70 00 01
        SPRITE_ATTR_REPT 1, 90h, 80h, 4, COLOR_BLACK           ;#66F9: 01 90 80 04 01
        SPRITE_ATTR_REPT 1, 0A0h, 70h, 8, COLOR_BLACK          ;#66FE: 01 A0 70 08 01
        SPRITE_ATTR_REPT 1, 0A0h, 80h, 0Ch, COLOR_BLACK        ;#6703: 01 A0 80 0C 01
        SPRITE_ATTR_REPT 1, 0E0h, 0, 0D4h, COLOR_DARK_YELLOW   ;#6708: 01 E0 00 D4 0A
        SPRITE_ATTR_REPT 1, 0E0h, 0, 0, COLOR_MED_RED          ;#670D: 01 E0 00 00 08
        SPRITE_ATTR_REPT 1, 0E0h, 0, 7Ch, COLOR_BLACK          ;#6712: 01 E0 00 7C 01
        SPRITE_ATTR_REPT 3, 0E0h, 0, 7Ch, COLOR_DARK_RED       ;#6717: 03 E0 00 7C 06
        SPRITE_ATTR_REPT 1, 0AEh, 70h, 0A0h, COLOR_DARK_BLUE   ;#671C: 01 AE 70 A0 04
        SPRITE_ATTR_REPT 1, 0AEh, 80h, 0A4h, COLOR_DARK_BLUE   ;#6721: 01 AE 80 A4 04
        SPRITE_ATTR_REPT 8, 8, 0, 70h, COLOR_TRANSPARENT       ;#6726: 08 08 00 70 00
        db      00h                                            ;#672B: 00

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
        SPRITE_ATTR_REPT 4, 4Fh, 80h, 7Ch, COLOR_TRANSPARENT   ;#672C: 04 4F 80 7C 00
        SPRITE_ATTR_REPT 1, 52h, 80h, 0E8h, COLOR_TRANSPARENT  ;#6731: 01 52 80 E8 00
        SPRITE_ATTR_REPT 1, 52h, 80h, 0ECh, COLOR_TRANSPARENT  ;#6736: 01 52 80 EC 00
        SPRITE_ATTR_REPT 1, 52h, 80h, 0E4h, COLOR_WHITE        ;#673B: 01 52 80 E4 0F
        SPRITE_ATTR_REPT 1, 7Fh, 78h, 0D0h, COLOR_DARK_YELLOW  ;#6740: 01 7F 78 D0 0A
        db      00h                                            ;#6745: 00

GOAL_FLAG_ATTRIBUTES:
        ; Initial sprite attributes for the 4 goal-scene flags (4 x 4 bytes)
        ; Format: FORMAT_SPRITE_ATTR
        ; - Single 4-byte block for one hardware sprite: [Y, X, Pattern, Color].
        ; - Coordinates are screen-relative (Y=208 or E0h hides the sprite).
        SPRITE_ATTR 7Fh, 70h, 0F0h, COLOR_DARK_YELLOW          ;#6746: 7F 70 F0 0A
        SPRITE_ATTR 87h, 78h, 0F4h, COLOR_DARK_YELLOW          ;#674A: 87 78 F4 0A
        SPRITE_ATTR 77h, 70h, 0F8h, COLOR_BLACK                ;#674E: 77 70 F8 01
        SPRITE_ATTR 77h, 80h, 0FCh, COLOR_BLACK                ;#6752: 77 80 FC 01

LOAD_MAIN_SPRITE_PATTERNS:
        ; Initialize tertiary stage VRAM graphics (Entry point)
        ld      hl,MAIN_SPRITE_PATTERNS                        ;#6756: 21 5C 67
        jp      DECOMPRESS_VRAM_INDIRECT                       ;#6759: C3 60 45

MAIN_SPRITE_PATTERNS:
        ; Sprite patterns: stage init (loaded by LOAD_MAIN_SPRITE_PATTERNS)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1800h                                      ;#675C: 00 58
        dh      "0D0083030F1F03008A030F1B376F5FFF"             ;#675E: 0D 00 83 03 0F 1F 03 00 8A 03 0F 1B 37 6F 5F FF
        dh      "FFBFBF03FF030086C0F0F8FCFEFE07FF"             ;#676E: FF BF BF 03 FF 03 00 86 C0 F0 F8 FC FE FE 07 FF
        dh      "0D0086C0E0F03F706007010300830303"             ;#677E: 0D 00 86 C0 E0 F0 3F 70 60 07 01 03 00 83 03 03
        dh      "000CFF847FFFE3010CFF87FEFFC780F8"             ;#678E: 00 0C FF 84 7F FF E3 01 0C FF 87 FE FF C7 80 F8
        dh      "18080680040082C0C00B000501010303"             ;#679E: 18 08 06 80 04 00 82 C0 C0 0B 00 05 01 01 03 03
        dh      "008A071F376FDFBFFFFFBFBF03FF0300"             ;#67AE: 00 8A 07 1F 37 6F DF BF FF FF BF BF 03 FF 03 00
        dh      "85C0F0F8FCFC03FE05FF0C008BE0F0F8"             ;#67BE: 85 C0 F0 F8 FC FC 03 FE 05 FF 0C 00 8B E0 F0 F8
        dh      "F8070F1F3E383020090008FF887F7F3F"             ;#67CE: F8 07 0F 1F 3E 38 30 20 09 00 08 FF 88 7F 7F 3F
        dh      "1F7F7700000DFF86FD39080C00000780"             ;#67DE: 1F 7F 77 00 00 0D FF 86 FD 39 08 0C 00 00 07 80
        dh      "8600C0E0A0E0E00C0084071F3F7F0300"             ;#67EE: 86 00 C0 E0 A0 E0 E0 0C 00 84 07 1F 3F 7F 03 00
        dh      "8A030F1B372F6F7F7FDFBF03FF030084"             ;#67FE: 8A 03 0F 1B 37 2F 6F 7F 7F DF BF 03 FF 03 00 84
        dh      "E0F8FCFE09FF0A000680836000000701"             ;#680E: E0 F8 FC FE 09 FF 0A 00 06 80 83 60 00 00 07 01
        dh      "860003070507070DFF83BF9C1008FF8F"             ;#681E: 86 00 03 07 05 07 07 0D FF 83 BF 9C 10 08 FF 8F
        dh      "FEFEFCF8FEEE0000E0F0F8381C0C0409"             ;#682E: FE FE FC F8 FE EE 00 00 E0 F0 F8 38 1C 0C 04 09
        dh      "00833F7060050185020607070303000C"             ;#683E: 00 83 3F 70 60 05 01 85 02 06 07 07 03 03 00 0C
        dh      "FF843F0F01000CFF87FEF8E080F81808"             ;#684E: FF 84 3F 0F 01 00 0C FF 87 FE F8 E0 80 F8 18 08
        dh      "0580854060E0E0C00D00862030181F0F"             ;#685E: 05 80 85 40 60 E0 E0 C0 0D 00 86 20 30 18 1F 0F
        dh      "0703008A030F1B376F5FFFFFBFBF03FF"             ;#686E: 07 03 00 8A 03 0F 1B 37 6F 5F FF FF BF BF 03 FF
        dh      "030086C0F0F8FCFEFE07FF0A0089040C"             ;#687E: 03 00 86 C0 F0 F8 FC FE FE 07 FF 0A 00 89 04 0C
        dh      "1CF8F0E0030000050185020607070303"             ;#688E: 1C F8 F0 E0 03 00 00 05 01 85 02 06 07 07 03 03
        dh      "000CFF847F1F07010CFF87FCF08000C0"             ;#689E: 00 0C FF 84 7F 1F 07 01 0C FF 87 FC F0 80 00 C0
        dh      "00000580854060E0E0C0060084E0F8FC"             ;#68AE: 00 00 05 80 85 40 60 E0 E0 C0 06 00 84 E0 F8 FC
        dh      "FE09FF0900058083E0F06003010C0006"             ;#68BE: FE 09 FF 09 00 05 80 83 E0 F0 60 03 01 0C 00 06
        dh      "FF8A7F7F3F3F1F1F0E0C080007FF84FE"             ;#68CE: FF 8A 7F 7F 3F 3F 1F 1F 0E 0C 08 00 07 FF 84 FE
        dh      "FEFCB8050083F8FC0C1600050182070F"             ;#68DE: FE FC B8 05 00 83 F8 FC 0C 16 00 05 01 82 07 0F
        dh      "03008A071F376FDFBFFFFFBFBF03FF83"             ;#68EE: 03 00 8A 07 1F 37 6F DF BF FF FF BF BF 03 FF 83
        dh      "1F3F300D0007FF857F7F3F1B01040006"             ;#68FE: 1F 3F 30 0D 00 07 FF 85 7F 7F 3F 1B 01 04 00 06
        dh      "FF8BFEFEFCFCF8F8F03010000C038018"             ;#690E: FF 8B FE FE FC FC F8 F8 F0 30 10 00 0C 03 80 18
        dh      "00841E3F3F03030089030F1B376F5FFF"             ;#691E: 00 84 1E 3F 3F 03 03 00 89 03 0F 1B 37 6F 5F FF
        dh      "DFDF04FF030086C0F0F8FCFEFE07FF0C"             ;#692E: DF DF 04 FF 03 00 86 C0 F0 F8 FC FE FE 07 FF 0C
        dh      "008578FCFCC0010F0008FF825F0F0307"             ;#693E: 00 85 78 FC FC C0 01 0F 00 08 FF 82 5F 0F 03 07
        dh      "8303010108FF82FAF003E08480000080"             ;#694E: 83 03 01 01 08 FF 82 FA F0 03 E0 84 80 00 00 80
        dh      "1700862070D8F8F8700A0086040E1B1F"             ;#695E: 17 00 86 20 70 D8 F8 F8 70 0A 00 86 04 0E 1B 1F
        dh      "1F0E050004780138120086040E1B1F1F"             ;#696E: 1F 0E 05 00 04 78 01 38 12 00 86 04 0E 1B 1F 1F
        dh      "0E0A00862070D8F8F8700300040F010E"             ;#697E: 0E 0A 00 86 20 70 D8 F8 F8 70 03 00 04 0F 01 0E
        dh      "2D00830301010E00858080A0C0200900"             ;#698E: 2D 00 83 03 01 01 0E 00 85 80 80 A0 C0 20 09 00
        dh      "88030701000001000108008780C0E0E0"             ;#699E: 88 03 07 01 00 00 01 00 01 08 00 87 80 C0 E0 E0
        dh      "6060C0080086071F377F3F0C0A000180"             ;#69AE: 60 60 C0 08 00 86 07 1F 37 7F 3F 0C 0A 00 01 80
        dh      "03E087F07030181C101004008930383C"             ;#69BE: 03 E0 87 F0 70 30 18 1C 10 10 04 00 89 30 38 3C
        dh      "3F1F3F2F27030A0086800888FEF0800B"             ;#69CE: 3F 1F 3F 2F 27 03 0A 00 86 80 08 88 FE F0 80 0B
        dh      "008501010503040A0083C080800C0087"             ;#69DE: 00 85 01 01 05 03 04 0A 00 83 C0 80 80 0C 00 87
        dh      "01030707060603090088C0E080000080"             ;#69EE: 01 03 07 07 06 06 03 09 00 88 C0 E0 80 00 00 80
        dh      "0080070001010307870F0E0C18380808"             ;#69FE: 00 80 07 00 01 01 03 07 87 0F 0E 0C 18 38 08 08
        dh      "050086E0F8ECFEFC300C00860180817F"             ;#6A0E: 05 00 86 E0 F8 EC FE FC 30 0C 00 86 01 80 81 7F
        dh      "0F010700890C1C3CFCF8FCF4E4C00600"             ;#6A1E: 0F 01 07 00 89 0C 1C 3C FC F8 FC F4 E4 C0 06 00
        dh      "8207070D00017F03FF0C0001FE03FF0D"             ;#6A2E: 82 07 07 0D 00 01 7F 03 FF 0C 00 01 FE 03 FF 0D
        dh      "0082E0E0100087C0F0F8FCFCFEFE06FF"             ;#6A3E: 00 82 E0 E0 10 00 87 C0 F0 F8 FC FC FE FE 06 FF
        dh      "0700890C1C3CF8F8F0C000800BFF85FE"             ;#6A4E: 07 00 89 0C 1C 3C F8 F8 F0 C0 00 80 0B FF 85 FE
        dh      "FCFC3808068084B8F8F0E00D00893038"             ;#6A5E: FC FC 38 08 06 80 84 B8 F8 F0 E0 0D 00 89 30 38
        dh      "3C1F1F0F030001030088030F1B372F7F"             ;#6A6E: 3C 1F 1F 0F 03 00 01 03 00 88 03 0F 1B 37 2F 7F
        dh      "5FDF05FF0601841D1F0F0706000BFF85"             ;#6A7E: 5F DF 05 FF 06 01 84 1D 1F 0F 07 06 00 0B FF 85
        dh      "7F3F3F1C100600880600201329010906"             ;#6A8E: 7F 3F 3F 1C 10 06 00 88 06 00 20 13 29 01 09 06
        dh      "080088600004C894809060040085030F"             ;#6A9E: 08 00 88 60 00 04 C8 94 80 90 60 04 00 85 03 0F
        dh      "1F3F3F097F870000C0F0F8FCFC09FE08"             ;#6AAE: 1F 3F 3F 09 7F 87 00 00 C0 F0 F8 FC FC 09 FE 08
        dh      "0088060C20132911290608008F603004"             ;#6ABE: 00 88 06 0C 20 13 29 11 29 06 08 00 8F 60 30 04
        dh      "C8948894600101030D1E3F3F037F03FE"             ;#6ACE: C8 94 88 94 60 01 01 03 0D 1E 3F 3F 03 7F 03 FE
        dh      "84FCF0607F0BFF813F060085030F3F7F"             ;#6ADE: 84 FC F0 60 7F 0B FF 81 3F 06 00 85 03 0F 3F 7F
        dh      "7F08FF030085C0F0FCFEFE08FF81FE0B"             ;#6AEE: 7F 08 FF 03 00 85 C0 F0 FC FE FE 08 FF 81 FE 0B
        dh      "FF81FC0300878080C0B078FCFC03FE03"             ;#6AFE: FF 81 FC 03 00 87 80 80 C0 B0 78 FC FC 03 FE 03
        dh      "7F833F0F06080086030F380C07030A00"             ;#6B0E: 7F 83 3F 0F 06 08 00 86 03 0F 38 0C 07 03 0A 00
        dh      "86C0F01C30E0C007008B0404CCDF7F3F"             ;#6B1E: 86 C0 F0 1C 30 E0 C0 07 00 8B 04 04 CC DF 7F 3F
        dh      "7FFF3F0D1007008940C08080C0E0F080"             ;#6B2E: 7F FF 3F 0D 10 07 00 89 40 C0 80 80 C0 E0 F0 80
        dh      "800B00851FFF7F3F030B0085C0F0FFFE"             ;#6B3E: 80 0B 00 85 1F FF 7F 3F 03 0B 00 85 C0 F0 FF FE
        dh      "F00C00840F3F1F070D0083F0FCC00D00"             ;#6B4E: F0 0C 00 84 0F 3F 1F 07 0D 00 83 F0 FC C0 0D 00
        dh      "83070F070D008380F0000CFF04000CFF"             ;#6B5E: 83 07 0F 07 0D 00 83 80 F0 00 0C FF 04 00 0C FF
        dh      "0400060084030F1F1F0C0084C0F0F8F8"             ;#6B6E: 04 00 06 00 84 03 0F 1F 1F 0C 00 84 C0 F0 F8 F8
        dh      "0600"                                         ;#6B7E: 06 00
        db      0                                              ;#6B80: 00

VICTORY_SPRITE_PATTERNS:
        ; Victory-dance sprite patterns (loaded by LOAD_VICTORY_GFX at the goal)
        ; Format: FORMAT_GFX_WITH_HEADER
        ; - Header (2 bytes): VRAM target in SET_VDP form.
        ; - Body: Stream of blocks starting with Control Byte C:
        ; - If 01h <= C <= 7Fh: RLE. Repeat the next byte C times.
        ; - If 81h <= C <= FFh: Literal. Copy the next (C & 7Fh) bytes.
        ; - If C == 00h: End of stream.
        VDP_ADDRESS 1F80h                                      ;#6B81: 80 5F
        dh      "0400860F1F1B1D1C0F0A0086F0F8DCBE"             ;#6B83: 04 00 86 0F 1F 1B 1D 1C 0F 0A 00 86 F0 F8 DC BE
        dh      "7CF006000B0084030707030C0085C0C0"             ;#6B93: 7C F0 06 00 0B 00 84 03 07 07 03 0C 00 85 C0 C0
        dh      "C08000A000383C0F0F06040000000000"             ;#6BA3: C0 80 00 A0 00 38 3C 0F 0F 06 04 00 00 00 00 00
        dh      "000000000000FEFFFF1F0F0700000000"             ;#6BB3: 00 00 00 00 00 00 FE FF FF 1F 0F 07 00 00 00 00
        dh      "00000000A000000080C1C3E7EF000000"             ;#6BC3: 00 00 00 00 A0 00 00 00 80 C1 C3 E7 EF 00 00 00
        dh      "00000000000000008080808080000000"             ;#6BD3: 00 00 00 00 00 00 00 00 80 80 80 80 80 00 00 00
        dh      "0000000000"                                   ;#6BE3: 00 00 00 00 00
        db      0                                              ;#6BE8: 00

ANIM_BIG_HOLE_LEFT:
        ; HUD spawn/pickup tile-stream for the big hole on the left lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#6BE9: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6BEA: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6BEB: EF
        VRAM_TILES "93"                                        ;#6BEC: 93
        db      00h                                            ;#6BED: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6BEE: 41
        VRAM_TILE_COLUMN 0Eh                                   ;#6BEF: EE
        VRAM_TILES "A195A2"                                    ;#6BF0: A1 95 A2
        db      00h                                            ;#6BF3: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6BF4: 41
        VRAM_TILE_COLUMN 0Eh                                   ;#6BF5: EE
        VRAM_TILES "0F0F0F"                                    ;#6BF6: 0F 0F 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#6BF9: EE
        VRAM_TILES "9898A3"                                    ;#6BFA: 98 98 A3
        db      00h                                            ;#6BFD: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#6BFE: 61
        VRAM_TILE_COLUMN 0Eh                                   ;#6BFF: EE
        VRAM_TILES "0F0F0F"                                    ;#6C00: 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6C03: ED
        VRAM_TILES "999A9A9B"                                  ;#6C04: 99 9A 9A 9B
        db      00h                                            ;#6C08: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#6C09: 81
        VRAM_TILE_COLUMN 0Dh                                   ;#6C0A: ED
        VRAM_TILES "0F0F0F0F"                                  ;#6C0B: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6C0F: EC
        VRAM_TILES "A49D9D9D9DA5"                              ;#6C10: A4 9D 9D 9D 9D A5
        db      00h                                            ;#6C16: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#6C17: A1
        VRAM_TILE_COLUMN 0Ch                                   ;#6C18: EC
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6C19: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ah                                   ;#6C1F: EA
        VRAM_TILES "A8AA9F9F9F9F9FABA7"                        ;#6C20: A8 AA 9F 9F 9F 9F 9F AB A7
        db      00h                                            ;#6C29: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#6C2A: C1
        VRAM_TILE_COLUMN 0Ah                                   ;#6C2B: EA
        VRAM_TILES "0F0F0F0F0F0F0F0F0F"                        ;#6C2C: 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#6C35: E9
        VRAM_TILES "70826C6C6C6C6C6C8371"                      ;#6C36: 70 82 6C 6C 6C 6C 6C 6C 83 71
        db      00h                                            ;#6C40: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#6C41: E1
        VRAM_TILE_COLUMN 9                                     ;#6C42: E9
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F"                      ;#6C43: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 8                                     ;#6C4D: E8
        VRAM_TILE_COLUMN 7                                     ;#6C4E: E7
        VRAM_TILES "7273848B6D6D6D6D6D6D8E8675"                ;#6C4F: 72 73 84 8B 6D 6D 6D 6D 6D 6D 8E 86 75
        db      00h                                            ;#6C5C: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#6C5D: 22
        VRAM_TILE_COLUMN 7                                     ;#6C5E: E7
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F"                ;#6C5F: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 6                                     ;#6C6C: E6
        VRAM_TILES "727384906E6E6E6E6E6E6E91047478"            ;#6C6D: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 91 04 74 78
        VRAM_TILE_COLUMN 5                                     ;#6C7C: E5
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F8D6F7B7C"          ;#6C7D: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 8D 6F 7B 7C
        VRAM_TILES "7D"                                        ;#6C8D: 7D
        db      00h                                            ;#6C8E: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#6C8F: 42
        VRAM_TILE_COLUMN 6                                     ;#6C90: E6
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"            ;#6C91: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 5                                     ;#6CA0: E5
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E928675"          ;#6CA1: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 92 86 75
        VRAM_TILES "0F"                                        ;#6CB1: 0F
        VRAM_TILE_COLUMN 4                                     ;#6CB2: E4
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F6F8C87"          ;#6CB3: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 6F 8C 87
        VRAM_TILES "7E7F"                                      ;#6CC3: 7E 7F
        db      00h                                            ;#6CC5: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#6CC6: 62
        VRAM_TILE_COLUMN 5                                     ;#6CC7: E5
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6CC8: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 4                                     ;#6CD8: E4
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E6E9104"          ;#6CD9: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 91 04
        VRAM_TILES "7478"                                      ;#6CE9: 74 78
        VRAM_TILE_COLUMN 3                                     ;#6CEB: E3
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F6F6F8D"          ;#6CEC: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F 8D
        VRAM_TILES "6F7B7C7D"                                  ;#6CFC: 6F 7B 7C 7D
        db      00h                                            ;#6D00: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#6D01: 82
        VRAM_TILE_COLUMN 4                                     ;#6D02: E4
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6D03: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F"                                      ;#6D13: 0F 0F
        VRAM_TILE_COLUMN 3                                     ;#6D15: E3
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E6E6E6E"          ;#6D16: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E
        VRAM_TILES "9286750F"                                  ;#6D26: 92 86 75 0F
        VRAM_TILE_COLUMN 2                                     ;#6D2A: E2
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F6F6F6F"          ;#6D2B: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F
        VRAM_TILES "6F8C877E7F"                                ;#6D3B: 6F 8C 87 7E 7F
        db      00h                                            ;#6D40: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#6D41: A2
        VRAM_TILE_COLUMN 3                                     ;#6D42: E3
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6D43: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F0F"                                    ;#6D53: 0F 0F 0F
        VRAM_TILE_COLUMN 2                                     ;#6D56: E2
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E6E6E6E"          ;#6D57: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E
        VRAM_TILES "6E91047478"                                ;#6D67: 6E 91 04 74 78
        db      00h                                            ;#6D6C: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#6D6D: C2
        VRAM_TILE_COLUMN 2                                     ;#6D6E: E2
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6D6F: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F0F0F0F"                                ;#6D7F: 0F 0F 0F 0F 0F
        db      00h                                            ;#6D84: 00

ANIM_BIG_HOLE_RIGHT:
        ; HUD spawn/pickup tile-stream for the big hole on the right lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#6D85: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6D86: 41
        VRAM_TILE_COLUMN 10h                                   ;#6D87: F0
        VRAM_TILES "93"                                        ;#6D88: 93
        db      00h                                            ;#6D89: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6D8A: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6D8B: EF
        VRAM_TILES "949596"                                    ;#6D8C: 94 95 96
        db      00h                                            ;#6D8F: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6D90: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6D91: EF
        VRAM_TILES "0F0F0F"                                    ;#6D92: 0F 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6D95: EF
        VRAM_TILES "979898"                                    ;#6D96: 97 98 98
        db      00h                                            ;#6D99: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#6D9A: 61
        VRAM_TILE_COLUMN 0Fh                                   ;#6D9B: EF
        VRAM_TILES "0F0F0F"                                    ;#6D9C: 0F 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6D9F: EF
        VRAM_TILES "999A9A9B"                                  ;#6DA0: 99 9A 9A 9B
        db      00h                                            ;#6DA4: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#6DA5: 81
        VRAM_TILE_COLUMN 0Fh                                   ;#6DA6: EF
        VRAM_TILES "0F0F0F0F"                                  ;#6DA7: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#6DAB: EE
        VRAM_TILES "9C9D9D9D9D9E"                              ;#6DAC: 9C 9D 9D 9D 9D 9E
        db      00h                                            ;#6DB2: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#6DB3: A1
        VRAM_TILE_COLUMN 0Eh                                   ;#6DB4: EE
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6DB5: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6DBB: ED
        VRAM_TILES "A6AA9F9F9F9F9FABA7"                        ;#6DBC: A6 AA 9F 9F 9F 9F 9F AB A7
        db      00h                                            ;#6DC5: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#6DC6: C1
        VRAM_TILE_COLUMN 0Dh                                   ;#6DC7: ED
        VRAM_TILES "0F0F0F0F0F0F0F0F0F"                        ;#6DC8: 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6DD1: ED
        VRAM_TILES "70826C6C6C6C6C6C8377"                      ;#6DD2: 70 82 6C 6C 6C 6C 6C 6C 83 77
        db      00h                                            ;#6DDC: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#6DDD: E1
        VRAM_TILE_COLUMN 0Dh                                   ;#6DDE: ED
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F"                      ;#6DDF: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6DE9: ED
        VRAM_TILE_COLUMN 0Ch                                   ;#6DEA: EC
        VRAM_TILES "7689886D6D6D6D6D6D6D8E8675"                ;#6DEB: 76 89 88 6D 6D 6D 6D 6D 6D 6D 8E 86 75
        db      00h                                            ;#6DF8: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#6DF9: 22
        VRAM_TILE_COLUMN 0Ch                                   ;#6DFA: EC
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F"                ;#6DFB: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6E08: EC
        VRAM_TILES "76898F6E6E6E6E6E6E6E91047478"              ;#6E09: 76 89 8F 6E 6E 6E 6E 6E 6E 6E 91 04 74 78
        VRAM_TILE_COLUMN 0Bh                                   ;#6E17: EB
        VRAM_TILES "808193856F6F6F6F6F6F6F8D6F7B7C7D"          ;#6E18: 80 81 93 85 6F 6F 6F 6F 6F 6F 6F 8D 6F 7B 7C 7D
        db      00h                                            ;#6E28: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#6E29: 42
        VRAM_TILE_COLUMN 0Ch                                   ;#6E2A: EC
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F"              ;#6E2B: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Bh                                   ;#6E39: EB
        VRAM_TILES "727384906E6E6E6E6E6E6E6E91047478"          ;#6E3A: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 91 04 74 78
        VRAM_TILE_COLUMN 0Ah                                   ;#6E4A: EA
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F8D6F7B"          ;#6E4B: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 8D 6F 7B
        VRAM_TILES "7C7D"                                      ;#6E5B: 7C 7D
        db      00h                                            ;#6E5D: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#6E5E: 62
        VRAM_TILE_COLUMN 0Bh                                   ;#6E5F: EB
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6E60: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ah                                   ;#6E70: EA
        VRAM_TILES "0F76898F6E6E6E6E6E6E6E6E6E6E9104"          ;#6E71: 0F 76 89 8F 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 91 04
        VRAM_TILES "7478"                                      ;#6E81: 74 78
        VRAM_TILE_COLUMN 0Ah                                   ;#6E83: EA
        VRAM_TILES "8081938D6F6F6F6F6F6F6F6F6F6F8D6F"          ;#6E84: 80 81 93 8D 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F 8D 6F
        VRAM_TILES "7B7C7D"                                    ;#6E94: 7B 7C 7D
        db      00h                                            ;#6E97: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#6E98: 82
        VRAM_TILE_COLUMN 0Bh                                   ;#6E99: EB
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6E9A: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F"                                        ;#6EAA: 0F
        VRAM_TILE_COLUMN 0Ah                                   ;#6EAB: EA
        VRAM_TILES "727384906E6E6E6E6E6E6E6E6E6E6E91"          ;#6EAC: 72 73 84 90 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 91
        VRAM_TILES "047478"                                    ;#6EBC: 04 74 78
        VRAM_TILE_COLUMN 9                                     ;#6EBF: E9
        VRAM_TILES "797A8A858C6F6F6F6F6F6F6F6F6F6F6F"          ;#6EC0: 79 7A 8A 85 8C 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F 6F
        VRAM_TILES "8D6F7B7C7D"                                ;#6ED0: 8D 6F 7B 7C 7D
        db      00h                                            ;#6ED5: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#6ED6: A2
        VRAM_TILE_COLUMN 0Ah                                   ;#6ED7: EA
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6ED8: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F0F"                                    ;#6EE8: 0F 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#6EEB: E9
        VRAM_TILES "0F76898F6E6E6E6E6E6E6E6E6E6E6E6E"          ;#6EEC: 0F 76 89 8F 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E 6E
        VRAM_TILES "6E91047778"                                ;#6EFC: 6E 91 04 77 78
        db      00h                                            ;#6F01: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#6F02: C2
        VRAM_TILE_COLUMN 0Ah                                   ;#6F03: EA
        VRAM_TILES "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"          ;#6F04: 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILES "0F0F0F0F"                                  ;#6F14: 0F 0F 0F 0F
        db      00h                                            ;#6F18: 00

ANIM_SMALL_HOLE_CENTER:
        ; HUD spawn/pickup tile-stream for the small hole in the center lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#6F19: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6F1A: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6F1B: EF
        VRAM_TILES "AFB0"                                      ;#6F1C: AF B0
        db      00h                                            ;#6F1E: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6F1F: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6F20: EF
        VRAM_TILES "94A2"                                      ;#6F21: 94 A2
        db      00h                                            ;#6F23: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6F24: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6F25: EF
        VRAM_TILES "0F0F"                                      ;#6F26: 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6F28: EF
        VRAM_TILES "BFC0"                                      ;#6F29: BF C0
        db      00h                                            ;#6F2B: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#6F2C: 61
        VRAM_TILE_COLUMN 0Fh                                   ;#6F2D: EF
        VRAM_TILES "0F0F"                                      ;#6F2E: 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6F30: EF
        VRAM_TILES "B7B8"                                      ;#6F31: B7 B8
        db      00h                                            ;#6F33: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#6F34: 81
        VRAM_TILE_COLUMN 0Fh                                   ;#6F35: EF
        VRAM_TILES "0F0F"                                      ;#6F36: 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6F38: EF
        VRAM_TILES "BCBD"                                      ;#6F39: BC BD
        db      00h                                            ;#6F3B: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#6F3C: A1
        VRAM_TILE_COLUMN 0Fh                                   ;#6F3D: EF
        VRAM_TILES "0F0F"                                      ;#6F3E: 0F 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#6F40: EF
        VRAM_TILES "C1C2"                                      ;#6F41: C1 C2
        db      00h                                            ;#6F43: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#6F44: C1
        VRAM_TILE_COLUMN 0Fh                                   ;#6F45: EF
        VRAM_TILES "0F0F"                                      ;#6F46: 0F 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#6F48: EE
        VRAM_TILES "94959596"                                  ;#6F49: 94 95 95 96
        db      00h                                            ;#6F4D: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#6F4E: E1
        VRAM_TILE_COLUMN 0Eh                                   ;#6F4F: EE
        VRAM_TILES "0F0F0F0F"                                  ;#6F50: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 1Fh                                   ;#6F54: FF
        VRAM_TILE_COLUMN 0Eh                                   ;#6F55: EE
        VRAM_TILES "97989899"                                  ;#6F56: 97 98 98 99
        db      00h                                            ;#6F5A: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#6F5B: 22
        VRAM_TILE_COLUMN 0Eh                                   ;#6F5C: EE
        VRAM_TILES "0F0F0F0F"                                  ;#6F5D: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#6F61: EE
        VRAM_TILES "9A98989B"                                  ;#6F62: 9A 98 98 9B
        VRAM_TILE_COLUMN 0Eh                                   ;#6F66: EE
        VRAM_TILES "ABAAAAAC"                                  ;#6F67: AB AA AA AC
        db      00h                                            ;#6F6B: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#6F6C: 42
        VRAM_TILE_COLUMN 0Eh                                   ;#6F6D: EE
        VRAM_TILES "0F0F0F0F"                                  ;#6F6E: 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6F72: ED
        VRAM_TILES "9C9D98989E9F"                              ;#6F73: 9C 9D 98 98 9E 9F
        VRAM_TILE_COLUMN 0Dh                                   ;#6F79: ED
        VRAM_TILES "A3A4A1A1A5A6"                              ;#6F7A: A3 A4 A1 A1 A5 A6
        db      00h                                            ;#6F80: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#6F81: 62
        VRAM_TILE_COLUMN 0Dh                                   ;#6F82: ED
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6F83: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6F89: ED
        VRAM_TILES "9A989898989B"                              ;#6F8A: 9A 98 98 98 98 9B
        VRAM_TILE_COLUMN 0Dh                                   ;#6F90: ED
        VRAM_TILES "ABA1A8A8A1AC"                              ;#6F91: AB A1 A8 A8 A1 AC
        db      00h                                            ;#6F97: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#6F98: 82
        VRAM_TILE_COLUMN 0Dh                                   ;#6F99: ED
        VRAM_TILES "0F0F0F0F0F0F"                              ;#6F9A: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6FA0: EC
        VRAM_TILES "9C9D989898989E9F"                          ;#6FA1: 9C 9D 98 98 98 98 9E 9F
        VRAM_TILE_COLUMN 0Ch                                   ;#6FA9: EC
        VRAM_TILES "A3A4A8A9A9A9A5A6"                          ;#6FAA: A3 A4 A8 A9 A9 A9 A5 A6
        db      00h                                            ;#6FB2: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#6FB3: A2
        VRAM_TILE_COLUMN 0Ch                                   ;#6FB4: EC
        VRAM_TILES "0F0F0F0F0F0F0F0F"                          ;#6FB5: 0F 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6FBD: EC
        VRAM_TILES "9A9898989898989B"                          ;#6FBE: 9A 98 98 98 98 98 98 9B
        db      00h                                            ;#6FC6: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#6FC7: C2
        VRAM_TILE_COLUMN 0Ch                                   ;#6FC8: EC
        VRAM_TILES "0F0F0F0F0F0F0F0F"                          ;#6FC9: 0F 0F 0F 0F 0F 0F 0F 0F
        db      00h                                            ;#6FD1: 00

ANIM_SMALL_HOLE_LEFT:
        ; HUD spawn/pickup tile-stream for the small hole on the left lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#6FD2: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6FD3: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#6FD4: EF
        VRAM_TILES "B2"                                        ;#6FD5: B2
        db      00h                                            ;#6FD6: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6FD7: 41
        VRAM_TILE_COLUMN 0Eh                                   ;#6FD8: EE
        VRAM_TILES "B40F"                                      ;#6FD9: B4 0F
        db      00h                                            ;#6FDB: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#6FDC: 41
        VRAM_TILE_COLUMN 0Eh                                   ;#6FDD: EE
        VRAM_TILES "0F"                                        ;#6FDE: 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6FDF: ED
        VRAM_TILES "BFB6"                                      ;#6FE0: BF B6
        db      00h                                            ;#6FE2: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#6FE3: 61
        VRAM_TILE_COLUMN 0Dh                                   ;#6FE4: ED
        VRAM_TILES "0F0F"                                      ;#6FE5: 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#6FE7: ED
        VRAM_TILES "BABB"                                      ;#6FE8: BA BB
        db      00h                                            ;#6FEA: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#6FEB: 81
        VRAM_TILE_COLUMN 0Dh                                   ;#6FEC: ED
        VRAM_TILES "0F0F"                                      ;#6FED: 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#6FEF: EC
        VRAM_TILES "BEBE"                                      ;#6FF0: BE BE
        db      00h                                            ;#6FF2: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#6FF3: A1
        VRAM_TILE_COLUMN 0Ch                                   ;#6FF4: EC
        VRAM_TILES "0F0F"                                      ;#6FF5: 0F 0F
        VRAM_TILE_COLUMN 0Bh                                   ;#6FF7: EB
        VRAM_TILES "C1C3C2"                                    ;#6FF8: C1 C3 C2
        db      00h                                            ;#6FFB: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#6FFC: C1
        VRAM_TILE_COLUMN 0Bh                                   ;#6FFD: EB
        VRAM_TILES "0F0F0F"                                    ;#6FFE: 0F 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#7001: E9
        VRAM_TILES "9495959596"                                ;#7002: 94 95 95 95 96
        db      00h                                            ;#7007: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#7008: E1
        VRAM_TILE_COLUMN 9                                     ;#7009: E9
        VRAM_TILES "0F0F0F0F0F"                                ;#700A: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 1Fh                                   ;#700F: FF
        VRAM_TILE_COLUMN 8                                     ;#7010: E8
        VRAM_TILES "9798989899"                                ;#7011: 97 98 98 98 99
        db      00h                                            ;#7016: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#7017: 22
        VRAM_TILE_COLUMN 8                                     ;#7018: E8
        VRAM_TILES "0F0F0F0F0F"                                ;#7019: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 7                                     ;#701E: E7
        VRAM_TILES "9A9898989B"                                ;#701F: 9A 98 98 98 9B
        VRAM_TILE_COLUMN 7                                     ;#7024: E7
        VRAM_TILES "ABAAAAAAAC"                                ;#7025: AB AA AA AA AC
        db      00h                                            ;#702A: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#702B: 42
        VRAM_TILE_COLUMN 7                                     ;#702C: E7
        VRAM_TILES "0F0F0F0F0F"                                ;#702D: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 6                                     ;#7032: E6
        VRAM_TILES "9A9898989E9F"                              ;#7033: 9A 98 98 98 9E 9F
        VRAM_TILE_COLUMN 6                                     ;#7039: E6
        VRAM_TILES "A0A1A1A1A5A6"                              ;#703A: A0 A1 A1 A1 A5 A6
        db      00h                                            ;#7040: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#7041: 62
        VRAM_TILE_COLUMN 6                                     ;#7042: E6
        VRAM_TILES "0F0F0F0F0F0F"                              ;#7043: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 5                                     ;#7049: E5
        VRAM_TILES "9A989898989B0F"                            ;#704A: 9A 98 98 98 98 9B 0F
        VRAM_TILE_COLUMN 5                                     ;#7051: E5
        VRAM_TILES "A0A1A8A8A1A2"                              ;#7052: A0 A1 A8 A8 A1 A2
        db      00h                                            ;#7058: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#7059: 82
        VRAM_TILE_COLUMN 5                                     ;#705A: E5
        VRAM_TILES "0F0F0F0F0F0F"                              ;#705B: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 4                                     ;#7061: E4
        VRAM_TILES "9A989898989E9F"                            ;#7062: 9A 98 98 98 98 9E 9F
        VRAM_TILE_COLUMN 4                                     ;#7069: E4
        VRAM_TILES "A0A1A8A8A1A2A6"                            ;#706A: A0 A1 A8 A8 A1 A2 A6
        db      00h                                            ;#7071: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#7072: A2
        VRAM_TILE_COLUMN 4                                     ;#7073: E4
        VRAM_TILES "0F0F0F0F0F0F0F"                            ;#7074: 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 3                                     ;#707B: E3
        VRAM_TILES "9A9898989898989B0F"                        ;#707C: 9A 98 98 98 98 98 98 9B 0F
        db      00h                                            ;#7085: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#7086: C2
        VRAM_TILE_COLUMN 3                                     ;#7087: E3
        VRAM_TILES "0F0F0F0F0F0F0F0F"                          ;#7088: 0F 0F 0F 0F 0F 0F 0F 0F
        db      00h                                            ;#7090: 00

ANIM_SMALL_HOLE_RIGHT:
        ; HUD spawn/pickup tile-stream for the small hole on the right lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#7091: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7092: 41
        VRAM_TILE_COLUMN 10h                                   ;#7093: F0
        VRAM_TILES "B1"                                        ;#7094: B1
        db      00h                                            ;#7095: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7096: 41
        VRAM_TILE_COLUMN 10h                                   ;#7097: F0
        VRAM_TILES "0FB3"                                      ;#7098: 0F B3
        db      00h                                            ;#709A: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#709B: 41
        VRAM_TILE_COLUMN 11h                                   ;#709C: F1
        VRAM_TILES "0F"                                        ;#709D: 0F
        VRAM_TILE_COLUMN 11h                                   ;#709E: F1
        VRAM_TILES "B5C0"                                      ;#709F: B5 C0
        db      00h                                            ;#70A1: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#70A2: 61
        VRAM_TILE_COLUMN 11h                                   ;#70A3: F1
        VRAM_TILES "0F0F"                                      ;#70A4: 0F 0F
        VRAM_TILE_COLUMN 11h                                   ;#70A6: F1
        VRAM_TILES "B9BA"                                      ;#70A7: B9 BA
        db      00h                                            ;#70A9: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#70AA: 81
        VRAM_TILE_COLUMN 11h                                   ;#70AB: F1
        VRAM_TILES "0F0F"                                      ;#70AC: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#70AE: F2
        VRAM_TILES "BEBE"                                      ;#70AF: BE BE
        db      00h                                            ;#70B1: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#70B2: A1
        VRAM_TILE_COLUMN 12h                                   ;#70B3: F2
        VRAM_TILES "0F0F"                                      ;#70B4: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#70B6: F2
        VRAM_TILES "C1C3C2"                                    ;#70B7: C1 C3 C2
        db      00h                                            ;#70BA: 00
        VRAM_TILE_HEADER 3900h, 7                              ;#70BB: C1
        VRAM_TILE_COLUMN 12h                                   ;#70BC: F2
        VRAM_TILES "0F0F0F"                                    ;#70BD: 0F 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#70C0: F2
        VRAM_TILES "9495959596"                                ;#70C1: 94 95 95 95 96
        db      00h                                            ;#70C6: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#70C7: E1
        VRAM_TILE_COLUMN 12h                                   ;#70C8: F2
        VRAM_TILES "0F0F0F0F0F"                                ;#70C9: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 1Fh                                   ;#70CE: FF
        VRAM_TILE_COLUMN 13h                                   ;#70CF: F3
        VRAM_TILES "9798989899"                                ;#70D0: 97 98 98 98 99
        db      00h                                            ;#70D5: 00
        VRAM_TILE_HEADER 3A00h, 2                              ;#70D6: 22
        VRAM_TILE_COLUMN 13h                                   ;#70D7: F3
        VRAM_TILES "0F0F0F0F0F"                                ;#70D8: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 14h                                   ;#70DD: F4
        VRAM_TILES "9A9898989B"                                ;#70DE: 9A 98 98 98 9B
        VRAM_TILE_COLUMN 14h                                   ;#70E3: F4
        VRAM_TILES "ABAAAAAAAC"                                ;#70E4: AB AA AA AA AC
        db      00h                                            ;#70E9: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#70EA: 42
        VRAM_TILE_COLUMN 14h                                   ;#70EB: F4
        VRAM_TILES "0F0F0F0F0F"                                ;#70EC: 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 14h                                   ;#70F1: F4
        VRAM_TILES "9C9D9898989E"                              ;#70F2: 9C 9D 98 98 98 9E
        VRAM_TILE_COLUMN 14h                                   ;#70F8: F4
        VRAM_TILES "A3A4A1A1A1A2"                              ;#70F9: A3 A4 A1 A1 A1 A2
        db      00h                                            ;#70FF: 00
        VRAM_TILE_HEADER 3A00h, 4                              ;#7100: 62
        VRAM_TILE_COLUMN 14h                                   ;#7101: F4
        VRAM_TILES "0F0F0F0F0F0F"                              ;#7102: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 14h                                   ;#7108: F4
        VRAM_TILES "0F9A989898989B"                            ;#7109: 0F 9A 98 98 98 98 9B
        VRAM_TILE_COLUMN 15h                                   ;#7110: F5
        VRAM_TILES "A0A1A8A8A1A2"                              ;#7111: A0 A1 A8 A8 A1 A2
        db      00h                                            ;#7117: 00
        VRAM_TILE_HEADER 3A00h, 5                              ;#7118: 82
        VRAM_TILE_COLUMN 15h                                   ;#7119: F5
        VRAM_TILES "0F0F0F0F0F0F"                              ;#711A: 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 15h                                   ;#7120: F5
        VRAM_TILES "9C9D989898989E"                            ;#7121: 9C 9D 98 98 98 98 9E
        VRAM_TILE_COLUMN 15h                                   ;#7128: F5
        VRAM_TILES "A3A4A8A9A8A1A2"                            ;#7129: A3 A4 A8 A9 A8 A1 A2
        db      00h                                            ;#7130: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#7131: A2
        VRAM_TILE_COLUMN 15h                                   ;#7132: F5
        VRAM_TILES "0F0F0F0F0F0F0F"                            ;#7133: 0F 0F 0F 0F 0F 0F 0F
        VRAM_TILE_COLUMN 15h                                   ;#713A: F5
        VRAM_TILES "0F9A9898989898989B"                        ;#713B: 0F 9A 98 98 98 98 98 98 9B
        db      00h                                            ;#7144: 00
        VRAM_TILE_HEADER 3A00h, 7                              ;#7145: C2
        VRAM_TILE_COLUMN 16h                                   ;#7146: F6
        VRAM_TILES "0F0F0F0F0F0F0F0F"                          ;#7147: 0F 0F 0F 0F 0F 0F 0F 0F
        db      00h                                            ;#714F: 00

ANIM_FLAG_LEFT:
        ; HUD spawn/pickup tile-stream for the flag on the left lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#7150: 00
        db      00h                                            ;#7151: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7152: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#7153: EF
        VRAM_TILES "C6"                                        ;#7154: C6
        db      00h                                            ;#7155: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#7156: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#7157: EF
        VRAM_TILES "C7"                                        ;#7158: C7
        db      00h                                            ;#7159: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#715A: 41
        VRAM_TILE_COLUMN 0Fh                                   ;#715B: EF
        VRAM_TILES "0F"                                        ;#715C: 0F
        VRAM_TILE_COLUMN 0Fh                                   ;#715D: EF
        VRAM_TILES "C9"                                        ;#715E: C9
        db      00h                                            ;#715F: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#7160: 61
        VRAM_TILE_COLUMN 0Fh                                   ;#7161: EF
        VRAM_TILES "0F"                                        ;#7162: 0F
        VRAM_TILE_COLUMN 0Eh                                   ;#7163: EE
        VRAM_TILES "CE"                                        ;#7164: CE
        db      00h                                            ;#7165: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#7166: 81
        VRAM_TILE_COLUMN 0Dh                                   ;#7167: ED
        VRAM_TILES "C8CA"                                      ;#7168: C8 CA
        VRAM_TILE_COLUMN 0Dh                                   ;#716A: ED
        VRAM_TILES "CFCB"                                      ;#716B: CF CB
        db      00h                                            ;#716D: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#716E: 81
        VRAM_TILE_COLUMN 0Dh                                   ;#716F: ED
        VRAM_TILES "0F0F"                                      ;#7170: 0F 0F
        VRAM_TILE_COLUMN 0Dh                                   ;#7172: ED
        VRAM_TILES "CC0F"                                      ;#7173: CC 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#7175: EC
        VRAM_TILES "A1CD"                                      ;#7176: A1 CD
        db      00h                                            ;#7178: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#7179: A1
        VRAM_TILE_COLUMN 0Dh                                   ;#717A: ED
        VRAM_TILES "0F"                                        ;#717B: 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#717C: EC
        VRAM_TILES "0F0F"                                      ;#717D: 0F 0F
        VRAM_TILE_COLUMN 0Ch                                   ;#717F: EC
        VRAM_TILES "03AD"                                      ;#7180: 03 AD
        VRAM_TILE_COLUMN 0Bh                                   ;#7182: EB
        VRAM_TILES "B5B1"                                      ;#7183: B5 B1
        db      00h                                            ;#7185: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#7186: E1
        VRAM_TILE_COLUMN 0Ch                                   ;#7187: EC
        VRAM_TILES "0F0F"                                      ;#7188: 0F 0F
        VRAM_TILE_COLUMN 0Bh                                   ;#718A: EB
        VRAM_TILES "AEAE"                                      ;#718B: AE AE
        VRAM_TILE_COLUMN 0Bh                                   ;#718D: EB
        VRAM_TILES "0303"                                      ;#718E: 03 03
        VRAM_TILE_COLUMN 0Ah                                   ;#7190: EA
        VRAM_TILES "7FB0"                                      ;#7191: 7F B0
        db      00h                                            ;#7193: 00
        db      00h                                            ;#7194: 00
        VRAM_TILE_HEADER 3A00h, 1                              ;#7195: 02
        VRAM_TILE_COLUMN 0Bh                                   ;#7196: EB
        VRAM_TILES "0F0F"                                      ;#7197: 0F 0F
        VRAM_TILE_COLUMN 0Bh                                   ;#7199: EB
        VRAM_TILES "0F0F"                                      ;#719A: 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#719C: E9
        VRAM_TILES "AF0303"                                    ;#719D: AF 03 03
        VRAM_TILE_COLUMN 9                                     ;#71A0: E9
        VRAM_TILES "AF0303"                                    ;#71A1: AF 03 03
        VRAM_TILE_COLUMN 8                                     ;#71A4: E8
        VRAM_TILES "7FB2"                                      ;#71A5: 7F B2
        db      00h                                            ;#71A7: 00
        db      00h                                            ;#71A8: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#71A9: 42
        VRAM_TILE_COLUMN 9                                     ;#71AA: E9
        VRAM_TILES "0F0F0F"                                    ;#71AB: 0F 0F 0F
        VRAM_TILE_COLUMN 9                                     ;#71AE: E9
        VRAM_TILES "0F0F0F"                                    ;#71AF: 0F 0F 0F
        VRAM_TILE_COLUMN 8                                     ;#71B2: E8
        VRAM_TILES "0F0F"                                      ;#71B3: 0F 0F
        VRAM_TILE_COLUMN 5                                     ;#71B5: E5
        VRAM_TILES "030303"                                    ;#71B6: 03 03 03
        VRAM_TILE_COLUMN 5                                     ;#71B9: E5
        VRAM_TILES "030303"                                    ;#71BA: 03 03 03
        db      00h                                            ;#71BD: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#71BE: A2
        VRAM_TILE_COLUMN 5                                     ;#71BF: E5
        VRAM_TILES "0F0F0F"                                    ;#71C0: 0F 0F 0F
        VRAM_TILE_COLUMN 5                                     ;#71C3: E5
        VRAM_TILES "0F0F0F"                                    ;#71C4: 0F 0F 0F
        db      00h                                            ;#71C7: 00

ANIM_FLAG_RIGHT:
        ; HUD spawn/pickup tile-stream for the flag on the right lane
        ; Format: FORMAT_SPECIAL_ITEM_TEXT_DATA
        ; - Each snippet: mini WRITE_VRAM_TILES_STREAM (header, ctrl/data, 00h term).
        ; - SPAWN_ITEM_INIT plays one snippet per tick, advancing past the 00h.
        ; - Byte 0 is always 00h: first spawn call lands on it as a no-op.
        ; - HANDLE_COLLISION_FLAG copies 13 bytes from (ptr+1) into
        ; - ITEM_PICKUP_TILE_BUFFER, then calls WRITE_VRAM_TILES_STREAM.
        db      00h                                            ;#71C8: 00
        db      00h                                            ;#71C9: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#71CA: 41
        VRAM_TILE_COLUMN 10h                                   ;#71CB: F0
        VRAM_TILES "C6"                                        ;#71CC: C6
        db      00h                                            ;#71CD: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#71CE: 41
        VRAM_TILE_COLUMN 10h                                   ;#71CF: F0
        VRAM_TILES "C8"                                        ;#71D0: C8
        db      00h                                            ;#71D1: 00
        VRAM_TILE_HEADER 3900h, 3                              ;#71D2: 41
        VRAM_TILE_COLUMN 10h                                   ;#71D3: F0
        VRAM_TILES "0F"                                        ;#71D4: 0F
        VRAM_TILE_COLUMN 11h                                   ;#71D5: F1
        VRAM_TILES "C9"                                        ;#71D6: C9
        db      00h                                            ;#71D7: 00
        VRAM_TILE_HEADER 3900h, 4                              ;#71D8: 61
        VRAM_TILE_COLUMN 11h                                   ;#71D9: F1
        VRAM_TILES "0F"                                        ;#71DA: 0F
        VRAM_TILE_COLUMN 11h                                   ;#71DB: F1
        VRAM_TILES "CE"                                        ;#71DC: CE
        db      00h                                            ;#71DD: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#71DE: 81
        VRAM_TILE_COLUMN 11h                                   ;#71DF: F1
        VRAM_TILES "C8CA"                                      ;#71E0: C8 CA
        VRAM_TILE_COLUMN 11h                                   ;#71E2: F1
        VRAM_TILES "CFCB"                                      ;#71E3: CF CB
        db      00h                                            ;#71E5: 00
        VRAM_TILE_HEADER 3900h, 5                              ;#71E6: 81
        VRAM_TILE_COLUMN 11h                                   ;#71E7: F1
        VRAM_TILES "0F0F"                                      ;#71E8: 0F 0F
        VRAM_TILE_COLUMN 11h                                   ;#71EA: F1
        VRAM_TILES "0FCC"                                      ;#71EB: 0F CC
        VRAM_TILE_COLUMN 11h                                   ;#71ED: F1
        VRAM_TILES "A1CD"                                      ;#71EE: A1 CD
        db      00h                                            ;#71F0: 00
        VRAM_TILE_HEADER 3900h, 6                              ;#71F1: A1
        VRAM_TILE_COLUMN 12h                                   ;#71F2: F2
        VRAM_TILES "0F"                                        ;#71F3: 0F
        VRAM_TILE_COLUMN 11h                                   ;#71F4: F1
        VRAM_TILES "0F0F"                                      ;#71F5: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#71F7: F2
        VRAM_TILES "AF03"                                      ;#71F8: AF 03
        VRAM_TILE_COLUMN 12h                                   ;#71FA: F2
        VRAM_TILES "B2"                                        ;#71FB: B2
        db      00h                                            ;#71FC: 00
        VRAM_TILE_HEADER 3900h, 8                              ;#71FD: E1
        VRAM_TILE_COLUMN 12h                                   ;#71FE: F2
        VRAM_TILES "0F0F"                                      ;#71FF: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#7201: F2
        VRAM_TILES "0FAEAE"                                    ;#7202: 0F AE AE
        VRAM_TILE_COLUMN 13h                                   ;#7205: F3
        VRAM_TILES "0303"                                      ;#7206: 03 03
        VRAM_TILE_COLUMN 12h                                   ;#7208: F2
        VRAM_TILES "7FB0"                                      ;#7209: 7F B0
        db      00h                                            ;#720B: 00
        db      00h                                            ;#720C: 00
        VRAM_TILE_HEADER 3A00h, 1                              ;#720D: 02
        VRAM_TILE_COLUMN 13h                                   ;#720E: F3
        VRAM_TILES "0F0F"                                      ;#720F: 0F 0F
        VRAM_TILE_COLUMN 13h                                   ;#7211: F3
        VRAM_TILES "0F0F"                                      ;#7212: 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#7214: F2
        VRAM_TILES "0FAF0303"                                  ;#7215: 0F AF 03 03
        VRAM_TILE_COLUMN 13h                                   ;#7219: F3
        VRAM_TILES "AF0303"                                    ;#721A: AF 03 03
        VRAM_TILE_COLUMN 12h                                   ;#721D: F2
        VRAM_TILES "7FB2"                                      ;#721E: 7F B2
        db      00h                                            ;#7220: 00
        db      00h                                            ;#7221: 00
        VRAM_TILE_HEADER 3A00h, 3                              ;#7222: 42
        VRAM_TILE_COLUMN 13h                                   ;#7223: F3
        VRAM_TILES "0F0F0F"                                    ;#7224: 0F 0F 0F
        VRAM_TILE_COLUMN 13h                                   ;#7227: F3
        VRAM_TILES "0F0F0F"                                    ;#7228: 0F 0F 0F
        VRAM_TILE_COLUMN 12h                                   ;#722B: F2
        VRAM_TILES "0F0F"                                      ;#722C: 0F 0F
        VRAM_TILE_COLUMN 18h                                   ;#722E: F8
        VRAM_TILES "030303"                                    ;#722F: 03 03 03
        VRAM_TILE_COLUMN 18h                                   ;#7232: F8
        VRAM_TILES "030303"                                    ;#7233: 03 03 03
        db      00h                                            ;#7236: 00
        VRAM_TILE_HEADER 3A00h, 6                              ;#7237: A2
        VRAM_TILE_COLUMN 18h                                   ;#7238: F8
        VRAM_TILES "0F0F0F"                                    ;#7239: 0F 0F 0F
        VRAM_TILE_COLUMN 18h                                   ;#723C: F8
        VRAM_TILES "0F0F0F"                                    ;#723D: 0F 0F 0F
        db      00h                                            ;#7240: 00

STAGE_SEGMENT_DEFINITIONS:
        ; Pointer table for road segment data (4 entries)
        dw      ROAD_ICE_RIGHT_1                               ;#7241: 49 72
        dw      ROAD_ICE_LEFT_1                                ;#7243: 86 72
        dw      ROAD_WATER_RIGHT_1                             ;#7245: C3 72
        dw      ROAD_WATER_LEFT_1                              ;#7247: F8 72

ROAD_ICE_RIGHT_1:
        ; Ice road, right slot — root (4 frame ptrs + fill + paint + init)
        dw      ROAD_ICE_RIGHT_2                               ;#7249: 2D 73
        dw      ROAD_ICE_RIGHT_3                               ;#724B: 55 73
        dw      ROAD_ICE_RIGHT_4                               ;#724D: 6D 73
        dw      ROAD_ICE_RIGHT_5                               ;#724F: 8E 73

ROAD_ICE_RIGHT_1_FILL:
        ; Ice road, right slot — perspective background fill (right half)
        ; Format: FORMAT_VRAM_FILL_STREAM
        ; - First byte: fill value (tile index to paint).
        ; - Then pairs: [count, addr_lo]. Each pair paints one horizontal strip.
        ; - Addr base is 39xx; high byte auto-increments when addr_lo < 20h.
        ; - Count 00h terminates the stream.
        ROAD_FILL_VALUE 0Fh                                    ;#7251: 0F
        ROAD_FILL_RUN 0Fh, 51h                                 ;#7252: 0F 51
        ROAD_FILL_RUN 0Eh, 72h                                 ;#7254: 0E 72
        ROAD_FILL_RUN 0Dh, 93h                                 ;#7256: 0D 93
        ROAD_FILL_RUN 0Bh, 0B5h                                ;#7258: 0B B5
        ROAD_FILL_RUN 0Ah, 0D6h                                ;#725A: 0A D6
        ROAD_FILL_RUN 9, 0F7h                                  ;#725C: 09 F7
        ROAD_FILL_RUN 8, 18h                                   ;#725E: 08 18
        ROAD_FILL_RUN 6, 3Ah                                   ;#7260: 06 3A
        ROAD_FILL_RUN 5, 5Bh                                   ;#7262: 05 5B
        ROAD_FILL_RUN 3, 7Dh                                   ;#7264: 03 7D
        ROAD_FILL_RUN 2, 9Eh                                   ;#7266: 02 9E
        ROAD_FILL_RUN 1, 0BFh                                  ;#7268: 01 BF
        db      00h                                            ;#726A: 00

ROAD_ICE_RIGHT_1_VRAM:
        ; Ice road, right slot — name-table paint pass (road tiles)
        ; Fallthrough from ROAD_ICE_RIGHT_1_FILL (WRITE_VRAM_STREAM step of UPLOAD).
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 11h                               ;#726B: 51 39
        VRAM_TILES "0F101112131415"                            ;#726D: 0F 10 11 12 13 14 15
        STREAM_BLOCK_END                                       ;#7274: FF

ROAD_ICE_RIGHT_1_INIT:
        ; Ice road, right slot — E1xx color/lane init buffer
        ; Format: FORMAT_ROAD_SEGMENT_INIT
        ROAD_SEGMENT_HEADER 60h                                ;#7275: 60
        ROAD_SEGMENT_ROW 0, 0, 0, 0F3h                         ;#7276: 00 00 00 F3
        ROAD_SEGMENT_ROW 0F4h, 0F3h, 0F7h, 0F5h                ;#727A: F4 F3 F7 F5
        ROAD_SEGMENT_ROW 0F6h, 0F4h, 0F3h, 0F7h                ;#727E: F6 F4 F3 F7
        ROAD_SEGMENT_ROW 0F5h, 0F6h, 0, 0                      ;#7282: F5 F6 00 00

ROAD_ICE_LEFT_1:
        ; Ice road, left slot — root (4 frame ptrs + fill + paint + init)
        dw      ROAD_ICE_LEFT_2                                ;#7286: A6 73
        dw      ROAD_ICE_LEFT_3                                ;#7288: CE 73
        dw      ROAD_ICE_LEFT_4                                ;#728A: E6 73
        dw      ROAD_ICE_LEFT_5                                ;#728C: 07 74

ROAD_ICE_LEFT_1_FILL:
        ; Ice road, left slot — perspective background fill (left half)
        ; Format: FORMAT_VRAM_FILL_STREAM
        ; - First byte: fill value (tile index to paint).
        ; - Then pairs: [count, addr_lo]. Each pair paints one horizontal strip.
        ; - Addr base is 39xx; high byte auto-increments when addr_lo < 20h.
        ; - Count 00h terminates the stream.
        ROAD_FILL_VALUE 0Fh                                    ;#728E: 0F
        ROAD_FILL_RUN 0Fh, 40h                                 ;#728F: 0F 40
        ROAD_FILL_RUN 0Eh, 60h                                 ;#7291: 0E 60
        ROAD_FILL_RUN 0Dh, 80h                                 ;#7293: 0D 80
        ROAD_FILL_RUN 0Bh, 0A0h                                ;#7295: 0B A0
        ROAD_FILL_RUN 0Ah, 0C0h                                ;#7297: 0A C0
        ROAD_FILL_RUN 9, 0E0h                                  ;#7299: 09 E0
        ROAD_FILL_RUN 8, 0                                     ;#729B: 08 00
        ROAD_FILL_RUN 6, 20h                                   ;#729D: 06 20
        ROAD_FILL_RUN 5, 40h                                   ;#729F: 05 40
        ROAD_FILL_RUN 3, 60h                                   ;#72A1: 03 60
        ROAD_FILL_RUN 2, 80h                                   ;#72A3: 02 80
        ROAD_FILL_RUN 1, 0A0h                                  ;#72A5: 01 A0
        db      00h                                            ;#72A7: 00

ROAD_ICE_LEFT_1_VRAM:
        ; Ice road, left slot — name-table paint pass (road tiles)
        ; Fallthrough from ROAD_ICE_LEFT_1_FILL (WRITE_VRAM_STREAM step of UPLOAD).
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 8                                 ;#72A8: 48 39
        VRAM_TILES "1514131252100F"                            ;#72AA: 15 14 13 12 52 10 0F
        STREAM_BLOCK_END                                       ;#72B1: FF

ROAD_ICE_LEFT_1_INIT:
        ; Ice road, left slot — E1xx color/lane init buffer
        ; Fallthrough from ROAD_ICE_LEFT_1_VRAM (read after WRITE_VRAM_STREAM returns).
        ; Format: FORMAT_ROAD_SEGMENT_INIT
        ROAD_SEGMENT_HEADER 50h                                ;#72B2: 50
        ROAD_SEGMENT_ROW 0F3h, 0F5h, 0F6h, 0F4h                ;#72B3: F3 F5 F6 F4
        ROAD_SEGMENT_ROW 0F5h, 0F7h, 0F6h, 0F4h                ;#72B7: F5 F7 F6 F4
        ROAD_SEGMENT_ROW 0F4h, 0F3h, 0F5h, 0F6h                ;#72BB: F4 F3 F5 F6
        ROAD_SEGMENT_ROW 0F4h, 0F5h, 0F6h, 0                   ;#72BF: F4 F5 F6 00

ROAD_WATER_RIGHT_1:
        ; Water road, right slot — root (4 frame ptrs + fill + paint + init)
        dw      ROAD_WATER_RIGHT_2                             ;#72C3: 1F 74
        dw      ROAD_WATER_RIGHT_3                             ;#72C5: 40 74
        dw      ROAD_WATER_RIGHT_4                             ;#72C7: 61 74
        dw      ROAD_WATER_RIGHT_5                             ;#72C9: 7F 74

ROAD_WATER_RIGHT_1_FILL:
        ; Water road, right slot — perspective background fill (right half)
        ; Fallthrough from ROAD_WATER_RIGHT_1 frame ptrs (FILL_VRAM_STREAM input).
        ; Format: FORMAT_VRAM_FILL_STREAM
        ; - First byte: fill value (tile index to paint).
        ; - Then pairs: [count, addr_lo]. Each pair paints one horizontal strip.
        ; - Addr base is 39xx; high byte auto-increments when addr_lo < 20h.
        ; - Count 00h terminates the stream.
        ROAD_FILL_VALUE 4                                      ;#72CB: 04
        ROAD_FILL_RUN 0Dh, 53h                                 ;#72CC: 0D 53
        ROAD_FILL_RUN 0Ch, 74h                                 ;#72CE: 0C 74
        ROAD_FILL_RUN 0Ah, 96h                                 ;#72D0: 0A 96
        ROAD_FILL_RUN 9, 0B7h                                  ;#72D2: 09 B7
        ROAD_FILL_RUN 7, 0D9h                                  ;#72D4: 07 D9
        ROAD_FILL_RUN 6, 0FAh                                  ;#72D6: 06 FA
        ROAD_FILL_RUN 5, 1Bh                                   ;#72D8: 05 1B
        ROAD_FILL_RUN 3, 3Dh                                   ;#72DA: 03 3D
        db      00h                                            ;#72DC: 00

ROAD_WATER_RIGHT_1_VRAM:
        ; Water road, right slot — name-table paint pass (road tiles)
        ; Fallthrough from ROAD_WATER_RIGHT_1_FILL (WRITE_VRAM_STREAM step of UPLOAD).
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 11h                               ;#72DD: 51 39
        VRAM_TILES "393C"                                      ;#72DF: 39 3C
        STREAM_NEXT_BLOCK                                      ;#72E1: FE
        VRAM_NAME_TABLE 0Bh, 12h                               ;#72E2: 72 39
        VRAM_TILES "3738"                                      ;#72E4: 37 38
        STREAM_BLOCK_END                                       ;#72E6: FF

ROAD_WATER_RIGHT_1_INIT:
        ; Water road, right slot — E1xx color/lane init buffer
        ; Format: FORMAT_ROAD_SEGMENT_INIT
        ROAD_SEGMENT_HEADER 60h                                ;#72E7: 60
        ROAD_SEGMENT_ROW 0, 0, 0, 0                            ;#72E8: 00 00 00 00
        ROAD_SEGMENT_ROW 0F8h, 0FCh, 0F9h, 0FBh                ;#72EC: F8 FC F9 FB
        ROAD_SEGMENT_ROW 0FCh, 0F9h, 0F9h, 0F9h                ;#72F0: FC F9 F9 F9
        ROAD_SEGMENT_ROW 0FBh, 0FAh, 0, 0                      ;#72F4: FB FA 00 00

ROAD_WATER_LEFT_1:
        ; Water road, left slot — root (4 frame ptrs + fill + paint + init)
        dw      ROAD_WATER_LEFT_2                              ;#72F8: 9C 74
        dw      ROAD_WATER_LEFT_3                              ;#72FA: BD 74
        dw      ROAD_WATER_LEFT_4                              ;#72FC: DE 74
        dw      ROAD_WATER_LEFT_5                              ;#72FE: FC 74

ROAD_WATER_LEFT_1_FILL:
        ; Water road, left slot — perspective background fill (left half)
        ; Fallthrough from ROAD_WATER_LEFT_1 frame ptrs (FILL_VRAM_STREAM input).
        ; Format: FORMAT_VRAM_FILL_STREAM
        ; - First byte: fill value (tile index to paint).
        ; - Then pairs: [count, addr_lo]. Each pair paints one horizontal strip.
        ; - Addr base is 39xx; high byte auto-increments when addr_lo < 20h.
        ; - Count 00h terminates the stream.
        ROAD_FILL_VALUE 4                                      ;#7300: 04
        ROAD_FILL_RUN 0Dh, 40h                                 ;#7301: 0D 40
        ROAD_FILL_RUN 0Ch, 60h                                 ;#7303: 0C 60
        ROAD_FILL_RUN 0Ah, 80h                                 ;#7305: 0A 80
        ROAD_FILL_RUN 9, 0A0h                                  ;#7307: 09 A0
        ROAD_FILL_RUN 7, 0C0h                                  ;#7309: 07 C0
        ROAD_FILL_RUN 6, 0E0h                                  ;#730B: 06 E0
        ROAD_FILL_RUN 5, 0                                     ;#730D: 05 00
        ROAD_FILL_RUN 3, 20h                                   ;#730F: 03 20
        db      00h                                            ;#7311: 00

ROAD_WATER_LEFT_1_VRAM:
        ; Water road, left slot — name-table paint pass (road tiles)
        ; Fallthrough from ROAD_WATER_LEFT_1_FILL (WRITE_VRAM_STREAM step of UPLOAD).
        ; Format: FORMAT_VRAM_STREAM
        ; - Format: block [ vdp_addr data... ]
        ; - FEh starts a new block (addr + data).
        ; - FFh terminates the stream.
        VRAM_NAME_TABLE 0Ah, 0Dh                               ;#7312: 4D 39
        VRAM_TILES "7D7A"                                      ;#7314: 7D 7A
        STREAM_NEXT_BLOCK                                      ;#7316: FE
        VRAM_NAME_TABLE 0Bh, 0Ch                               ;#7317: 6C 39
        VRAM_TILES "7978"                                      ;#7319: 79 78
        STREAM_BLOCK_END                                       ;#731B: FF

ROAD_WATER_LEFT_1_INIT:
        ; Water road, left slot — E1xx color/lane init buffer
        ; Fallthrough from ROAD_WATER_LEFT_1_VRAM (read after WRITE_VRAM_STREAM returns).
        ; Format: FORMAT_ROAD_SEGMENT_INIT
        ROAD_SEGMENT_HEADER 50h                                ;#731C: 50
        ROAD_SEGMENT_ROW 0, 0, 0, 0F8h                         ;#731D: 00 00 00 F8
        ROAD_SEGMENT_ROW 0FBh, 0F9h, 0FCh, 0FBh                ;#7321: FB F9 FC FB
        ROAD_SEGMENT_ROW 0F9h, 0FBh, 0FCh, 0FAh                ;#7325: F9 FB FC FA
        ROAD_SEGMENT_ROW 0, 0, 0, 0                            ;#7329: 00 00 00 00

ROAD_ICE_RIGHT_2:
        ; Ice road, right slot — animation frame 1/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#732D: 21
        VRAM_TILE_COLUMN 18h                                   ;#732E: F8
        VRAM_TILES "1315121212141414"                          ;#732F: 13 15 12 12 12 14 14 14
        VRAM_TILE_COLUMN 15h                                   ;#7337: F5
        VRAM_TILES "16171819191A1B1C1C1C1C"                    ;#7338: 16 17 18 19 19 1A 1B 1C 1C 1C 1C
        VRAM_TILE_COLUMN 17h                                   ;#7343: F7
        VRAM_TILES "1D1E1F1F1F20212223"                        ;#7344: 1D 1E 1F 1F 1F 20 21 22 23
        VRAM_TILE_COLUMN 1Ah                                   ;#734D: FA
        VRAM_TILES "0F2425262626"                              ;#734E: 0F 24 25 26 26 26
        db      00h                                            ;#7354: 00

ROAD_ICE_RIGHT_3:
        ; Ice road, right slot — animation frame 2/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#7355: 21
        VRAM_TILE_COLUMN 1Ah                                   ;#7356: FA
        VRAM_TILES "15"                                        ;#7357: 15
        VRAM_TILE_COLUMN 15h                                   ;#7358: F5
        VRAM_TILES "27282929192A"                              ;#7359: 27 28 29 29 19 2A
        VRAM_TILE_COLUMN 17h                                   ;#735F: F7
        VRAM_TILES "2B2B1E1F2829192D"                          ;#7360: 2B 2B 1E 1F 28 29 19 2D
        VRAM_TILE_COLUMN 1Ah                                   ;#7368: FA
        VRAM_TILES "2E2626"                                    ;#7369: 2E 26 26
        db      00h                                            ;#736C: 00

ROAD_ICE_RIGHT_4:
        ; Ice road, right slot — animation frame 3/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#736D: 21
        VRAM_TILE_COLUMN 18h                                   ;#736E: F8
        VRAM_TILES "151515121212"                              ;#736F: 15 15 15 12 12 12
        VRAM_TILE_COLUMN 15h                                   ;#7375: F5
        VRAM_TILES "16171819192F1B1C2222"                      ;#7376: 16 17 18 19 19 2F 1B 1C 22 22
        VRAM_TILE_COLUMN 17h                                   ;#7380: F7
        VRAM_TILES "1D1E1F1F1F202122"                          ;#7381: 1D 1E 1F 1F 1F 20 21 22
        VRAM_TILE_COLUMN 1Ah                                   ;#7389: FA
        VRAM_TILES "0F2425"                                    ;#738A: 0F 24 25
        db      00h                                            ;#738D: 00

ROAD_ICE_RIGHT_5:
        ; Ice road, right slot — animation frame 4/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#738E: 21
        VRAM_TILE_COLUMN 1Ah                                   ;#738F: FA
        VRAM_TILES "12"                                        ;#7390: 12
        VRAM_TILE_COLUMN 15h                                   ;#7391: F5
        VRAM_TILES "27282929192D"                              ;#7392: 27 28 29 29 19 2D
        VRAM_TILE_COLUMN 17h                                   ;#7398: F7
        VRAM_TILES "2B2B1E1F2C29192D"                          ;#7399: 2B 2B 1E 1F 2C 29 19 2D
        VRAM_TILE_COLUMN 1Ah                                   ;#73A1: FA
        VRAM_TILES "2E2626"                                    ;#73A2: 2E 26 26
        db      00h                                            ;#73A5: 00

ROAD_ICE_LEFT_2:
        ; Ice road, left slot — animation frame 1/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#73A6: 21
        VRAM_TILE_COLUMN 0                                     ;#73A7: E0
        VRAM_TILES "1414141212121513"                          ;#73A8: 14 14 14 12 12 12 15 13
        VRAM_TILE_COLUMN 0                                     ;#73B0: E0
        VRAM_TILES "5D5D5D5D5C5B5A5A595857"                    ;#73B1: 5D 5D 5D 5D 5C 5B 5A 5A 59 58 57
        VRAM_TILE_COLUMN 0                                     ;#73BC: E0
        VRAM_TILES "646362616060605F5E"                        ;#73BD: 64 63 62 61 60 60 60 5F 5E
        VRAM_TILE_COLUMN 0                                     ;#73C6: E0
        VRAM_TILES "67676766650F"                              ;#73C7: 67 67 67 66 65 0F
        db      00h                                            ;#73CD: 00

ROAD_ICE_LEFT_3:
        ; Ice road, left slot — animation frame 2/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#73CE: 21
        VRAM_TILE_COLUMN 5                                     ;#73CF: E5
        VRAM_TILES "14"                                        ;#73D0: 14
        VRAM_TILE_COLUMN 5                                     ;#73D1: E5
        VRAM_TILES "6B5A6A6A6968"                              ;#73D2: 6B 5A 6A 6A 69 68
        VRAM_TILE_COLUMN 1                                     ;#73D8: E1
        VRAM_TILES "6E5A6A69605F6C6C"                          ;#73D9: 6E 5A 6A 69 60 5F 6C 6C
        VRAM_TILE_COLUMN 3                                     ;#73E1: E3
        VRAM_TILES "67676F"                                    ;#73E2: 67 67 6F
        db      00h                                            ;#73E5: 00

ROAD_ICE_LEFT_4:
        ; Ice road, left slot — animation frame 3/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#73E6: 21
        VRAM_TILE_COLUMN 2                                     ;#73E7: E2
        VRAM_TILES "121212151515"                              ;#73E8: 12 12 12 15 15 15
        VRAM_TILE_COLUMN 1                                     ;#73EE: E1
        VRAM_TILES "63635D5C705A5A595857"                      ;#73EF: 63 63 5D 5C 70 5A 5A 59 58 57
        VRAM_TILE_COLUMN 1                                     ;#73F9: E1
        VRAM_TILES "6362616060605F5E"                          ;#73FA: 63 62 61 60 60 60 5F 5E
        VRAM_TILE_COLUMN 3                                     ;#7402: E3
        VRAM_TILES "66650F"                                    ;#7403: 66 65 0F
        db      00h                                            ;#7406: 00

ROAD_ICE_LEFT_5:
        ; Ice road, left slot — animation frame 4/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 2                              ;#7407: 21
        VRAM_TILE_COLUMN 5                                     ;#7408: E5
        VRAM_TILES "12"                                        ;#7409: 12
        VRAM_TILE_COLUMN 5                                     ;#740A: E5
        VRAM_TILES "6E5A6A6A6968"                              ;#740B: 6E 5A 6A 6A 69 68
        VRAM_TILE_COLUMN 1                                     ;#7411: E1
        VRAM_TILES "6E5A6A6D605F6C6C"                          ;#7412: 6E 5A 6A 6D 60 5F 6C 6C
        VRAM_TILE_COLUMN 3                                     ;#741A: E3
        VRAM_TILES "67676F"                                    ;#741B: 67 67 6F
        db      00h                                            ;#741E: 00

ROAD_WATER_RIGHT_2:
        ; Water road, right slot — animation frame 1/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#741F: 61
        VRAM_TILE_COLUMN 13h                                   ;#7420: F3
        VRAM_TILES "494336"                                    ;#7421: 49 43 36
        VRAM_TILE_COLUMN 15h                                   ;#7424: F5
        VRAM_TILES "3748"                                      ;#7425: 37 48
        VRAM_TILE_COLUMN 16h                                   ;#7427: F6
        VRAM_TILES "3B4236"                                    ;#7428: 3B 42 36
        VRAM_TILE_COLUMN 18h                                   ;#742B: F8
        VRAM_TILES "3738"                                      ;#742C: 37 38
        VRAM_TILE_COLUMN 18h                                   ;#742E: F8
        VRAM_TILES "0F0F54"                                    ;#742F: 0F 0F 54
        VRAM_TILE_COLUMN 1Ah                                   ;#7432: FA
        VRAM_TILES "504704"                                    ;#7433: 50 47 04
        VRAM_TILE_COLUMN 1Bh                                   ;#7436: FB
        VRAM_TILES "4248040404"                                ;#7437: 42 48 04 04 04
        VRAM_TILE_COLUMN 1Eh                                   ;#743C: FE
        VRAM_TILES "4243"                                      ;#743D: 42 43
        db      00h                                            ;#743F: 00

ROAD_WATER_RIGHT_3:
        ; Water road, right slot — animation frame 2/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#7440: 61
        VRAM_TILE_COLUMN 13h                                   ;#7441: F3
        VRAM_TILES "0F4504"                                    ;#7442: 0F 45 04
        VRAM_TILE_COLUMN 16h                                   ;#7445: F6
        VRAM_TILES "38"                                        ;#7446: 38
        VRAM_TILE_COLUMN 16h                                   ;#7447: F6
        VRAM_TILES "4A4C04"                                    ;#7448: 4A 4C 04
        VRAM_TILE_COLUMN 17h                                   ;#744B: F7
        VRAM_TILES "374438"                                    ;#744C: 37 44 38
        VRAM_TILE_COLUMN 1Ah                                   ;#744F: FA
        VRAM_TILES "4041"                                      ;#7450: 40 41
        VRAM_TILE_COLUMN 1Ah                                   ;#7452: FA
        VRAM_TILES "0F4243"                                    ;#7453: 0F 42 43
        VRAM_TILE_COLUMN 1Bh                                   ;#7456: FB
        VRAM_TILES "0F51"                                      ;#7457: 0F 51
        VRAM_TILE_COLUMN 1Dh                                   ;#7459: FD
        VRAM_TILES "444504"                                    ;#745A: 44 45 04
        VRAM_TILE_COLUMN 1Eh                                   ;#745D: FE
        VRAM_TILES "464D"                                      ;#745E: 46 4D
        db      00h                                            ;#7460: 00

ROAD_WATER_RIGHT_4:
        ; Water road, right slot — animation frame 3/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#7461: 61
        VRAM_TILE_COLUMN 14h                                   ;#7462: F4
        VRAM_TILES "4F"                                        ;#7463: 4F
        VRAM_TILE_COLUMN 15h                                   ;#7464: F5
        VRAM_TILES "403D"                                      ;#7465: 40 3D
        VRAM_TILE_COLUMN 16h                                   ;#7467: F6
        VRAM_TILES "0F354D"                                    ;#7468: 0F 35 4D
        VRAM_TILE_COLUMN 17h                                   ;#746B: F7
        VRAM_TILES "4B4E04"                                    ;#746C: 4B 4E 04
        VRAM_TILE_COLUMN 19h                                   ;#746F: F9
        VRAM_TILES "4A4B"                                      ;#7470: 4A 4B
        VRAM_TILE_COLUMN 1Fh                                   ;#7472: FF
        VRAM_TILE_COLUMN 1Ch                                   ;#7473: FC
        VRAM_TILES "0F4041"                                    ;#7474: 0F 40 41
        VRAM_TILE_COLUMN 1Dh                                   ;#7477: FD
        VRAM_TILES "0F4252"                                    ;#7478: 0F 42 52
        VRAM_TILE_COLUMN 1Eh                                   ;#747B: FE
        VRAM_TILES "4E53"                                      ;#747C: 4E 53
        db      00h                                            ;#747E: 00

ROAD_WATER_RIGHT_5:
        ; Water road, right slot — animation frame 4/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#747F: 61
        VRAM_TILE_COLUMN 14h                                   ;#7480: F4
        VRAM_TILES "3F36"                                      ;#7481: 3F 36
        VRAM_TILE_COLUMN 15h                                   ;#7483: F5
        VRAM_TILES "463A"                                      ;#7484: 46 3A
        VRAM_TILE_COLUMN 18h                                   ;#7486: F8
        VRAM_TILES "36"                                        ;#7487: 36
        VRAM_TILE_COLUMN 17h                                   ;#7488: F7
        VRAM_TILES "0F3750"                                    ;#7489: 0F 37 50
        VRAM_TILE_COLUMN 18h                                   ;#748C: F8
        VRAM_TILES "4F554504"                                  ;#748D: 4F 55 45 04
        VRAM_TILE_COLUMN 1Ah                                   ;#7491: FA
        VRAM_TILES "464C49"                                    ;#7492: 46 4C 49
        VRAM_TILE_COLUMN 1Fh                                   ;#7495: FF
        VRAM_TILE_COLUMN 1Fh                                   ;#7496: FF
        VRAM_TILES "43"                                        ;#7497: 43
        VRAM_TILE_COLUMN 1Eh                                   ;#7498: FE
        VRAM_TILES "0F0F"                                      ;#7499: 0F 0F
        db      00h                                            ;#749B: 00

ROAD_WATER_LEFT_2:
        ; Water road, left slot — animation frame 1/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#749C: 61
        VRAM_TILE_COLUMN 0Ah                                   ;#749D: EA
        VRAM_TILES "77848A"                                    ;#749E: 77 84 8A
        VRAM_TILE_COLUMN 9                                     ;#74A1: E9
        VRAM_TILES "8978"                                      ;#74A2: 89 78
        VRAM_TILE_COLUMN 7                                     ;#74A4: E7
        VRAM_TILES "77837C"                                    ;#74A5: 77 83 7C
        VRAM_TILE_COLUMN 6                                     ;#74A8: E6
        VRAM_TILES "7978"                                      ;#74A9: 79 78
        VRAM_TILE_COLUMN 5                                     ;#74AB: E5
        VRAM_TILES "6A0F0F"                                    ;#74AC: 6A 0F 0F
        VRAM_TILE_COLUMN 3                                     ;#74AF: E3
        VRAM_TILES "045D66"                                    ;#74B0: 04 5D 66
        VRAM_TILE_COLUMN 0                                     ;#74B3: E0
        VRAM_TILES "0404045E58"                                ;#74B4: 04 04 04 5E 58
        VRAM_TILE_COLUMN 0                                     ;#74B9: E0
        VRAM_TILES "5958"                                      ;#74BA: 59 58
        db      00h                                            ;#74BC: 00

ROAD_WATER_LEFT_3:
        ; Water road, left slot — animation frame 2/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#74BD: 61
        VRAM_TILE_COLUMN 0Ah                                   ;#74BE: EA
        VRAM_TILES "04860F"                                    ;#74BF: 04 86 0F
        VRAM_TILE_COLUMN 9                                     ;#74C2: E9
        VRAM_TILES "79"                                        ;#74C3: 79
        VRAM_TILE_COLUMN 7                                     ;#74C4: E7
        VRAM_TILES "048D8B"                                    ;#74C5: 04 8D 8B
        VRAM_TILE_COLUMN 6                                     ;#74C8: E6
        VRAM_TILES "798578"                                    ;#74C9: 79 85 78
        VRAM_TILE_COLUMN 4                                     ;#74CC: E4
        VRAM_TILES "5756"                                      ;#74CD: 57 56
        VRAM_TILE_COLUMN 3                                     ;#74CF: E3
        VRAM_TILES "59580F"                                    ;#74D0: 59 58 0F
        VRAM_TILE_COLUMN 3                                     ;#74D3: E3
        VRAM_TILES "670F"                                      ;#74D4: 67 0F
        VRAM_TILE_COLUMN 0                                     ;#74D6: E0
        VRAM_TILES "045B5A"                                    ;#74D7: 04 5B 5A
        VRAM_TILE_COLUMN 0                                     ;#74DA: E0
        VRAM_TILES "635C"                                      ;#74DB: 63 5C
        db      00h                                            ;#74DD: 00

ROAD_WATER_LEFT_4:
        ; Water road, left slot — animation frame 3/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#74DE: 61
        VRAM_TILE_COLUMN 0Bh                                   ;#74DF: EB
        VRAM_TILES "90"                                        ;#74E0: 90
        VRAM_TILE_COLUMN 9                                     ;#74E1: E9
        VRAM_TILES "7E81"                                      ;#74E2: 7E 81
        VRAM_TILE_COLUMN 7                                     ;#74E4: E7
        VRAM_TILES "8E760F"                                    ;#74E5: 8E 76 0F
        VRAM_TILE_COLUMN 6                                     ;#74E8: E6
        VRAM_TILES "048F8C"                                    ;#74E9: 04 8F 8C
        VRAM_TILE_COLUMN 5                                     ;#74EC: E5
        VRAM_TILES "6160"                                      ;#74ED: 61 60
        VRAM_TILE_COLUMN 1Fh                                   ;#74EF: FF
        VRAM_TILE_COLUMN 1                                     ;#74F0: E1
        VRAM_TILES "57560F"                                    ;#74F1: 57 56 0F
        VRAM_TILE_COLUMN 0                                     ;#74F4: E0
        VRAM_TILES "68580F"                                    ;#74F5: 68 58 0F
        VRAM_TILE_COLUMN 0                                     ;#74F8: E0
        VRAM_TILES "6964"                                      ;#74F9: 69 64
        db      00h                                            ;#74FB: 00

ROAD_WATER_LEFT_5:
        ; Water road, left slot — animation frame 4/4
        ; Format: FORMAT_VRAM_TILES_STREAM
        ; - Byte 0 is a header: high nibble seeds row, low 2 bits pick VRAM page.
        ; - Then repeating [ctrl, data...] records.
        ; - ctrl E0h-FFh computes/selects the next VRAM target for SET_VDP.
        ; - Data bytes <E0h are written sequentially to VRAM.
        ; - Terminator: 00h ends the stream.
        VRAM_TILE_HEADER 3900h, 4                              ;#74FC: 61
        VRAM_TILE_COLUMN 0Ah                                   ;#74FD: EA
        VRAM_TILES "7780"                                      ;#74FE: 77 80
        VRAM_TILE_COLUMN 9                                     ;#7500: E9
        VRAM_TILES "7B87"                                      ;#7501: 7B 87
        VRAM_TILE_COLUMN 7                                     ;#7503: E7
        VRAM_TILES "77"                                        ;#7504: 77
        VRAM_TILE_COLUMN 6                                     ;#7505: E6
        VRAM_TILES "91780F"                                    ;#7506: 91 78 0F
        VRAM_TILE_COLUMN 4                                     ;#7509: E4
        VRAM_TILES "045B6B65"                                  ;#750A: 04 5B 6B 65
        VRAM_TILE_COLUMN 3                                     ;#750E: E3
        VRAM_TILES "5F625C"                                    ;#750F: 5F 62 5C
        VRAM_TILE_COLUMN 1Fh                                   ;#7512: FF
        VRAM_TILE_COLUMN 0                                     ;#7513: E0
        VRAM_TILES "59"                                        ;#7514: 59
        VRAM_TILE_COLUMN 0                                     ;#7515: E0
        VRAM_TILES "0F0F"                                      ;#7516: 0F 0F
        db      00h                                            ;#7518: 00

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
        ld      hl,(STAGE_DISTANCE_BCD)                        ;#7519: 2A E5 E0
        ld      a,h                                            ;#751C: 7C
        or      a                                              ;#751D: B7
        ret     nz                                             ;#751E: C0
        ld      a,l                                            ;#751F: 7D
        and     1Fh                                            ;#7520: E6 1F
        ret     nz                                             ;#7522: C0
        ld      a,l                                            ;#7523: 7D
        rlca                                                   ;#7524: 07
        rlca                                                   ;#7525: 07
        rlca                                                   ;#7526: 07
        add     a,a                                            ;#7527: 87
        ld      hl,STATION_FRAMES                              ;#7528: 21 5F 75
        call    ADD_HL_A                                       ;#752B: CD FE 48
        ld      e,(hl)                                         ;#752E: 5E
        inc     hl                                             ;#752F: 23
        ld      d,(hl)                                         ;#7530: 56
        ex      de,hl                                          ;#7531: EB
        ld      a,(hl)                                         ;#7532: 7E
        and     0F0h                                           ;#7533: E6 F0
        ld      c,a                                            ;#7535: 4F
        ld      a,(hl)                                         ;#7536: 7E
        inc     hl                                             ;#7537: 23
        and     3                                              ;#7538: E6 03
        add     a,78h                                          ;#753A: C6 78
        ld      d,a                                            ;#753C: 57
        ld      a,c                                            ;#753D: 79
STATION_FRAME_HEADER_LOOP:
        ; Start of VRAM header processing
        ld      b,(hl)                                         ;#753E: 46
        inc     hl                                             ;#753F: 23
        ld      a,20h                                          ;#7540: 3E 20
        add     a,c                                            ;#7542: 81
        ld      c,a                                            ;#7543: 4F
        jr      nc,STATION_FRAME_ADDR_CALC                     ;#7544: 30 01
        inc     d                                              ;#7546: 14
STATION_FRAME_ADDR_CALC:
        ; Carry-adjusted VRAM address calculation
        ld      a,c                                            ;#7547: 79
        add     a,b                                            ;#7548: 80
        sub     0E0h                                           ;#7549: D6 E0
        ld      e,a                                            ;#754B: 5F
        call    SET_VDP                                        ;#754C: CD E2 48
STATION_FRAME_TILE_LOOP:
        ; Emit tile bytes (with +40h offset) until 00h or next E0-FF header
        ld      a,(hl)                                         ;#754F: 7E
        or      a                                              ;#7550: B7
        ret     z                                              ;#7551: C8
        cp      0E0h                                           ;#7552: FE E0
        jr      nc,STATION_FRAME_HEADER_LOOP                   ;#7554: 30 E8
        inc     hl                                             ;#7556: 23
        add     a,40h                                          ;#7557: C6 40
        exx                                                    ;#7559: D9
        out     (c),a                                          ;#755A: ED 79
        exx                                                    ;#755C: D9
        jr      STATION_FRAME_TILE_LOOP                        ;#755D: 18 F0

STATION_FRAMES:
        ; Pointer table for end-stage station/house zoom-in frames (0=farthest, 4=closest)
        dw      STATION_FRAME_4                                ;#755F: A4 75
        dw      STATION_FRAME_3                                ;#7561: 81 75
        dw      STATION_FRAME_2                                ;#7563: 73 75
        dw      STATION_FRAME_1                                ;#7565: 6E 75
        dw      STATION_FRAME_0                                ;#7567: 69 75

STATION_FRAME_0:
        ; End-stage station, zoom level 0 (farthest, 2 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3900h, 2                          ;#7569: 21
        STATION_FRAME_INNER_HEADER 0Fh                         ;#756A: EF
        VRAM_TILES "9091"                                      ;#756B: 90 91
        db      00h                                            ;#756D: 00

STATION_FRAME_1:
        ; End-stage station, zoom level 1 (2 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3900h, 2                          ;#756E: 21
        STATION_FRAME_INNER_HEADER 0Fh                         ;#756F: EF
        VRAM_TILES "9293"                                      ;#7570: 92 93
        db      00h                                            ;#7572: 00

STATION_FRAME_2:
        ; End-stage station, zoom level 2 (9 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3900h, 1                          ;#7573: 01
        STATION_FRAME_INNER_HEADER 0Fh                         ;#7574: EF
        VRAM_TILES "AF"                                        ;#7575: AF
        STATION_FRAME_INNER_HEADER 0Eh                         ;#7576: EE
        VRAM_TILES "94969698"                                  ;#7577: 94 96 96 98
        STATION_FRAME_INNER_HEADER 0Eh                         ;#757B: EE
        VRAM_TILES "9597979A"                                  ;#757C: 95 97 97 9A
        db      00h                                            ;#7580: 00

STATION_FRAME_3:
        ; End-stage station, zoom level 3 (27 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3800h, 8                          ;#7581: E0
        STATION_FRAME_INNER_HEADER 0Fh                         ;#7582: EF
        VRAM_TILES "AF"                                        ;#7583: AF
        STATION_FRAME_INNER_HEADER 0Fh                         ;#7584: EF
        VRAM_TILES "B1B2"                                      ;#7585: B1 B2
        STATION_FRAME_INNER_HEADER 0Dh                         ;#7587: ED
        VRAM_TILES "9D9B9C9C9C9B"                              ;#7588: 9D 9B 9C 9C 9C 9B
        STATION_FRAME_INNER_HEADER 0Dh                         ;#758E: ED
        VRAM_TILES "C89EA4A6A8A1"                              ;#758F: C8 9E A4 A6 A8 A1
        STATION_FRAME_INNER_HEADER 0Dh                         ;#7595: ED
        VRAM_TILES "C89FA5A7A9C9"                              ;#7596: C8 9F A5 A7 A9 C9
        STATION_FRAME_INNER_HEADER 0Dh                         ;#759C: ED
        VRAM_TILES "A3A0A0A0ADA0"                              ;#759D: A3 A0 A0 A0 AD A0
        db      00h                                            ;#75A3: 00

STATION_FRAME_4:
        ; End-stage station, zoom level 4 (closest, 64 tiles)
        ; Format: FORMAT_STATION_FRAME_STREAM
        ; - Used by STATION_FRAME_0..4 for progressive zoom levels of the goal station.
        ; - First byte packs the base offset (high nibble) and row select (low 2 bits).
        ; - Then a sequence of header bytes (E0-FF) and tile bytes (<E0).
        ; - Header bytes update the VRAM target for the following tile run.
        ; - Each tile byte gets +40h added before being written to VRAM.
        ; - Terminator: 00h.
        STATION_FRAME_HEADER 3800h, 7                          ;#75A4: C0
        STATION_FRAME_INNER_HEADER 0Fh                         ;#75A5: EF
        VRAM_TILES "71"                                        ;#75A6: 71
        STATION_FRAME_INNER_HEADER 0Fh                         ;#75A7: EF
        VRAM_TILES "B0"                                        ;#75A8: B0
        STATION_FRAME_INNER_HEADER 0Fh                         ;#75A9: EF
        VRAM_TILES "B1B2"                                      ;#75AA: B1 B2
        STATION_FRAME_INNER_HEADER 0Bh                         ;#75AC: EB
        VRAM_TILES "9D9D9B9B9B9C9C9C9C9B"                      ;#75AD: 9D 9D 9B 9B 9B 9C 9C 9C 9C 9B
        STATION_FRAME_INNER_HEADER 0Bh                         ;#75B7: EB
        VRAM_TILES "C8C8C9C9C9C9C9A2A2C9"                      ;#75B8: C8 C8 C9 C9 C9 C9 C9 A2 A2 C9
        STATION_FRAME_INNER_HEADER 0Bh                         ;#75C2: EB
        VRAM_TILES "C8C8C9AAC9AAC999C9C9"                      ;#75C3: C8 C8 C9 AA C9 AA C9 99 C9 C9
        STATION_FRAME_INNER_HEADER 0Bh                         ;#75CD: EB
        VRAM_TILES "C8C8C9ABC9ABC999C9C9"                      ;#75CE: C8 C8 C9 AB C9 AB C9 99 C9 C9
        STATION_FRAME_INNER_HEADER 0Bh                         ;#75D8: EB
        VRAM_TILES "C8C8C9C9C9C9C9AEC9C9"                      ;#75D9: C8 C8 C9 C9 C9 C9 C9 AE C9 C9
        STATION_FRAME_INNER_HEADER 0Bh                         ;#75E3: EB
        VRAM_TILES "A3A3ACA0A0ACAC9AA0AC"                      ;#75E4: A3 A3 AC A0 A0 AC AC 9A A0 AC
        db      00h                                            ;#75EE: 00

CHECK_SPECIAL_ITEM_COLLISION:
        ; Detects collision with type-7 small-hole occupants (fish / seal)
        ld      hl,FISH_POS_STATE                              ;#75EF: 21 83 E1
        ld      a,(hl)                                         ;#75F2: 7E
        and     0E3h                                           ;#75F3: E6 E3
        ret     nz                                             ;#75F5: C0
        ld      de,ITEM_TABLE_TYPE_BASE                        ;#75F6: 11 13 E1
        ld      b,3                                            ;#75F9: 06 03
CHECK_SPECIAL_ITEM_COLLISION_LOOP:
        ; Loop for checking item collisions
        ld      a,(de)                                         ;#75FB: 1A
        cp      3                                              ;#75FC: FE 03
        jr      nc,SKIP_ITEM_CHECK                             ;#75FE: 30 07
        dec     de                                             ;#7600: 1B
        ld      a,(de)                                         ;#7601: 1A
        cp      7                                              ;#7602: FE 07
        jr      z,ITEM_FOUND_COLLISION                         ;#7604: 28 09
        inc     de                                             ;#7606: 13
SKIP_ITEM_CHECK:
        ; Skip current item check
        ld      a,6                                            ;#7607: 3E 06
        call    ADD_DE_A                                       ;#7609: CD 03 49
        djnz    CHECK_SPECIAL_ITEM_COLLISION_LOOP              ;#760C: 10 ED
        ret                                                    ;#760E: C9

ITEM_FOUND_COLLISION:
        ; Item found, handle collision logic
        ld      (ITEM_COLLISION_PTR),de                        ;#760F: ED 53 81 E1
        inc     de                                             ;#7613: 13
        ld      a,(SEQUENCE_THRESHOLD)                         ;#7614: 3A 8A E1
        ld      c,a                                            ;#7617: 4F
        ld      a,(FRAME_COUNTER)                              ;#7618: 3A 03 E0
        cp      c                                              ;#761B: B9
        jr      nc,NO_COLLISION_RESET                          ;#761C: 30 39
        ld      a,(CUR_INPUT_KEYS)                             ;#761E: 3A 09 E0
        and     0Ch                                            ;#7621: E6 0C
        jr      z,HANDLE_IDLE_ITEM_ANIM                        ;#7623: 28 04
        bit     2,a                                            ;#7625: CB 57
        jr      SET_FISH_POS_FRAME                             ;#7627: 18 09

HANDLE_IDLE_ITEM_ANIM:
        ; Handle idle animation for item
        ld      a,(ITEM_IDLE_ANIM_COUNTER)                     ;#7629: 3A 85 E1
        inc     a                                              ;#762C: 3C
        ld      (ITEM_IDLE_ANIM_COUNTER),a                     ;#762D: 32 85 E1
        bit     0,a                                            ;#7630: CB 47
SET_FISH_POS_FRAME:
        ; Set fish position frame
        ld      a,90h                                          ;#7632: 3E 90
        set     0,(hl)                                         ;#7634: CB C6
        jr      z,UPDATE_ITEM_SPRITE_ATTRS                     ;#7636: 28 04
        ld      a,80h                                          ;#7638: 3E 80
        rlc     (hl)                                           ;#763A: CB 06
UPDATE_ITEM_SPRITE_ATTRS:
        ; Update item sprite attributes
        ld      c,a                                            ;#763C: 4F
        ld      hl,SAT_MIRROR + SPRITE_ITEM + ATTR_Y           ;#763D: 21 8C E0
        ld      a,(de)                                         ;#7640: 1A
        ld      d,c                                            ;#7641: 51
        cp      1                                              ;#7642: FE 01
        ld      bc,7A66h                                       ;#7644: 01 66 7A
        jr      c,SET_SPRITE_Y_OFFSETS                         ;#7647: 38 04
        jr      z,SET_SPRITE_Y_ALT                             ;#7649: 28 04
        ld      b,92h                                          ;#764B: 06 92
SET_SPRITE_Y_OFFSETS:
        ; Set sprite Y offsets
        jr      STORE_SPRITE_ATTRS                             ;#764D: 18 02

SET_SPRITE_Y_ALT:
        ; Set alternate sprite Y offset
        ld      b,64h                                          ;#764F: 06 64
STORE_SPRITE_ATTRS:
        ; Store sprite attributes to buffer
        ld      (hl),c                                         ;#7651: 71
        inc     hl                                             ;#7652: 23
        ld      (hl),b                                         ;#7653: 70
        inc     hl                                             ;#7654: 23
        ld      (hl),d                                         ;#7655: 72
        ret                                                    ;#7656: C9

NO_COLLISION_RESET:
        ; Reset collision state if no item found
        xor     a                                              ;#7657: AF
        ld      (FISH_POS_VRAM_SELECT),a                       ;#7658: 32 92 E1
        ld      a,(de)                                         ;#765B: 1A
        cp      1                                              ;#765C: FE 01
        jr      c,MARK_COLLISION_TYPE_1                        ;#765E: 38 05
        jr      z,MARK_COLLISION_TYPE_2                        ;#7660: 28 06
        set     5,(hl)                                         ;#7662: CB EE
        ret                                                    ;#7664: C9

MARK_COLLISION_TYPE_1:
        ; Mark collision flag (type 1)
        set     6,(hl)                                         ;#7665: CB F6
        ret                                                    ;#7667: C9

MARK_COLLISION_TYPE_2:
        ; Mark collision flag (type 2)
        set     7,(hl)                                         ;#7668: CB FE
        ret                                                    ;#766A: C9

SYNC_SPRITE_ATTRIBUTES_PARTIAL:
        ; Upload sprite attribute subset to VRAM
        ld      a,(FRAME_COUNTER)                              ;#766B: 3A 03 E0
        rra                                                    ;#766E: 1F
        ret     c                                              ;#766F: D8
SYNC_SPRITE_LOOP:
        ; Loop entry for iterating through dynamic sprite attributes
        ld      hl,(SAT_MIRROR + SPRITE_ITEM + ATTR_Y)         ;#7670: 2A 8C E0
        ld      (CURRENT_ENTITY_POINTER),hl                    ;#7673: 22 88 E1
        ld      hl,SAT_MIRROR + SPRITE_ITEM + ATTR_Y           ;#7676: 21 8C E0
        LOAD_SPRITE_ATTR de, 15, 0                             ;#7679: 11 3C 3B
        ld      bc,4                                           ;#767C: 01 04 00
        call    COPY_RAM_TO_VRAM                               ;#767F: CD EC 44
        ld      de,FISH_POS_STATE                              ;#7682: 11 83 E1
        ld      a,(de)                                         ;#7685: 1A
        and     3                                              ;#7686: E6 03
        ret     z                                              ;#7688: C8
        ld      hl,SAT_MIRROR + SPRITE_ITEM + ATTR_PATT        ;#7689: 21 8E E0
        call    SYNC_ANIMATION_TIMER                           ;#768C: CD CD 76
        ld      a,(de)                                         ;#768F: 1A
        dec     hl                                             ;#7690: 2B
        rra                                                    ;#7691: 1F
        jr      c,MAX_ANIMATION_COUNTER                        ;#7692: 38 04
        dec     (hl)                                           ;#7694: 35
        dec     (hl)                                           ;#7695: 35
        jr      SYNC_ANIMATION_COMMON_ENTRY                    ;#7696: 18 02

MAX_ANIMATION_COUNTER:
        ; Max out animation counter
        inc     (hl)                                           ;#7698: 34
        inc     (hl)                                           ;#7699: 34
SYNC_ANIMATION_COMMON_ENTRY:
        ; Common entry for animation sync
        push    hl                                             ;#769A: E5
        ld      hl,FISH_POS_COUNTER                            ;#769B: 21 84 E1
        inc     (hl)                                           ;#769E: 34
        ld      a,(hl)                                         ;#769F: 7E
        pop     hl                                             ;#76A0: E1
        dec     hl                                             ;#76A1: 2B
        cp      8                                              ;#76A2: FE 08
        jr      c,DEC_ANIMATION_COUNTERS                       ;#76A4: 38 15
        cp      10h                                            ;#76A6: FE 10
        ret     c                                              ;#76A8: D8
        jr      z,ADVANCE_ANIMATION_PHASE                      ;#76A9: 28 13
        cp      22h                                            ;#76AB: FE 22
        jr      nc,HIDE_DYNAMIC_SPRITE                         ;#76AD: 30 16
        ld      c,5                                            ;#76AF: 0E 05
        cp      1Ah                                            ;#76B1: FE 1A
        jr      c,UPDATE_ANIM_FRAME_OFFSET                     ;#76B3: 38 02
        inc     c                                              ;#76B5: 0C
        inc     c                                              ;#76B6: 0C
UPDATE_ANIM_FRAME_OFFSET:
        ; Add offset to animation frame
        ld      a,(hl)                                         ;#76B7: 7E
        add     a,c                                            ;#76B8: 81
        ld      (hl),a                                         ;#76B9: 77
        ret                                                    ;#76BA: C9

DEC_ANIMATION_COUNTERS:
        ; Decrement animation counters
        dec     (hl)                                           ;#76BB: 35
        dec     (hl)                                           ;#76BC: 35
        ret                                                    ;#76BD: C9

ADVANCE_ANIMATION_PHASE:
        ; Advance to next animation phase
        inc     hl                                             ;#76BE: 23
        inc     hl                                             ;#76BF: 23
        ld      a,(hl)                                         ;#76C0: 7E
        add     a,8                                            ;#76C1: C6 08
        ld      (hl),a                                         ;#76C3: 77
        ret                                                    ;#76C4: C9

HIDE_DYNAMIC_SPRITE:
        ; Hide a dynamic sprite and clear its RAM entry
        ld      (hl),0E0h                                      ;#76C5: 36 E0
        xor     a                                              ;#76C7: AF
        ld      (de),a                                         ;#76C8: 12
        inc     de                                             ;#76C9: 13
        ld      (de),a                                         ;#76CA: 12
        jr      SYNC_SPRITE_LOOP                               ;#76CB: 18 A3

SYNC_ANIMATION_TIMER:
        ; Sync animation with global timer
        ld      a,(FRAME_COUNTER)                              ;#76CD: 3A 03 E0
        and     0Fh                                            ;#76D0: E6 0F
        ret     nz                                             ;#76D2: C0
        ld      a,(hl)                                         ;#76D3: 7E
        srl     a                                              ;#76D4: CB 3F
        srl     a                                              ;#76D6: CB 3F
        srl     a                                              ;#76D8: CB 3F
        ccf                                                    ;#76DA: 3F
        rla                                                    ;#76DB: 17
        rla                                                    ;#76DC: 17
        rla                                                    ;#76DD: 17
        ld      (hl),a                                         ;#76DE: 77
        ret                                                    ;#76DF: C9

PROCESS_PENGUIN_INPUT_AND_MOVE:
        ; Handle keyboard/joystick and update penguin position
        call    HANDLE_SPEED_INPUT                             ;#76E0: CD 2B 77
        ld      a,(PENGUIN_SPEED)                              ;#76E3: 3A 00 E1
        or      a                                              ;#76E6: B7
        rra                                                    ;#76E7: 1F
        ld      (DEMO_PLAY_MASK_RELOAD),a                      ;#76E8: 32 48 E1
        ld      a,(STAGE_DISTANCE_HIGH)                        ;#76EB: 3A E6 E0
        and     0Ch                                            ;#76EE: E6 0C
        ld      a,2Ch                                          ;#76F0: 3E 2C
        jr      nz,SPEED_FORCE_LOW_GEAR                        ;#76F2: 20 02
        add     a,4                                            ;#76F4: C6 04
SPEED_FORCE_LOW_GEAR:
        ; Branch for handling low distance speed override
        ld      c,a                                            ;#76F6: 4F
        ld      a,(CURRENT_VISIBLE_STAGE)                      ;#76F7: 3A E0 E0
        and     0F0h                                           ;#76FA: E6 F0
        jr      z,CALC_ITEM_TICK_PERIOD                        ;#76FC: 28 0C
        and     0E0h                                           ;#76FE: E6 E0
        jr      z,SPEED_DEC_VERY_FAST                          ;#7700: 28 04
        ld      a,c                                            ;#7702: 79
        sub     4                                              ;#7703: D6 04
        ld      c,a                                            ;#7705: 4F
SPEED_DEC_VERY_FAST:
        ; Reduce speed context A
        ld      a,c                                            ;#7706: 79
        sub     4                                              ;#7707: D6 04
        ld      c,a                                            ;#7709: 4F
CALC_ITEM_TICK_PERIOD:
        ; Adjust item-tick period from PENGUIN_SPEED
        ld      a,(PENGUIN_SPEED)                              ;#770A: 3A 00 E1
        cp      0Ch                                            ;#770D: FE 0C
        jr      c,SPEED_DEC_FAST                               ;#770F: 38 0D
        and     0Ch                                            ;#7711: E6 0C
        jr      z,SPEED_DEC_SLOW                               ;#7713: 28 11
        cp      0Ch                                            ;#7715: FE 0C
        jr      z,SET_ITEM_TICK_PERIOD                         ;#7717: 28 09
        ld      a,c                                            ;#7719: 79
STORE_ITEM_TICK_PERIOD:
        ; Store final item-tick period to ITEM_TICK_PERIOD
        ld      (ITEM_TICK_PERIOD),a                           ;#771A: 32 0E E1
        ret                                                    ;#771D: C9

SPEED_DEC_FAST:
        ; Reduce speed context B
        ld      a,c                                            ;#771E: 79
        sub     4                                              ;#771F: D6 04
        ld      c,a                                            ;#7721: 4F
SET_ITEM_TICK_PERIOD:
        ; Set calculated item-tick period (shared tail of CALC_ITEM_TICK_PERIOD)
        ld      a,c                                            ;#7722: 79
        sub     4                                              ;#7723: D6 04
        ld      c,a                                            ;#7725: 4F
SPEED_DEC_SLOW:
        ; Reduce speed context C
        ld      a,c                                            ;#7726: 79
        sub     4                                              ;#7727: D6 04
        jr      STORE_ITEM_TICK_PERIOD                         ;#7729: 18 EF

HANDLE_SPEED_INPUT:
        ; Process input keys and dispatch speed handler
        ld      a,(CUR_INPUT_KEYS)                             ;#772B: 3A 09 E0
        and     3                                              ;#772E: E6 03
        call    JUMP_TABLE_DISPATCHER                          ;#7730: CD B2 40
        ; Dispatch table for Up/Down input (Bit 0=Up, Bit 1=Down)
        ; 00: None (Coast)
        ; 01: Up (Accelerate)
        ; 02: Down (Brake)
        ; 03: Up+Down (Coast)
        dw      HANDLE_SPEED_COAST                             ;#7733: 69 77
        dw      HANDLE_SPEED_UP                                ;#7735: 3B 77
        dw      HANDLE_SPEED_DOWN                              ;#7737: 53 77
        dw      HANDLE_SPEED_COAST                             ;#7739: 69 77

HANDLE_SPEED_UP:
        ; Handle 'Up' input (Accelerate)
        ld      hl,SPEED_ACCEL_DELAY-1                         ;#773B: 21 FD E0
        xor     a                                              ;#773E: AF
        ld      (hl),a                                         ;#773F: 77
        inc     hl                                             ;#7740: 23
        inc     hl                                             ;#7741: 23
        ld      (hl),a                                         ;#7742: 77
        dec     hl                                             ;#7743: 2B
        inc     (hl)                                           ;#7744: 34
        ld      a,(hl)                                         ;#7745: 7E
        sub     0Ch                                            ;#7746: D6 0C
        ret     nz                                             ;#7748: C0
        ld      (hl),a                                         ;#7749: 77
        ld      hl,PENGUIN_SPEED                               ;#774A: 21 00 E1
        ld      a,(hl)                                         ;#774D: 7E
        cp      9                                              ;#774E: FE 09
        ret     c                                              ;#7750: D8
        dec     (hl)                                           ;#7751: 35
        ret                                                    ;#7752: C9

HANDLE_SPEED_DOWN:
        ; Handle 'Down' input (Brake)
        ld      hl,SPEED_ACCEL_DELAY-1                         ;#7753: 21 FD E0
        xor     a                                              ;#7756: AF
        ld      (hl),a                                         ;#7757: 77
        inc     hl                                             ;#7758: 23
        ld      (hl),a                                         ;#7759: 77
        inc     hl                                             ;#775A: 23
        inc     (hl)                                           ;#775B: 34
        ld      a,(hl)                                         ;#775C: 7E
        sub     4                                              ;#775D: D6 04
        ret     nz                                             ;#775F: C0
        ld      (hl),a                                         ;#7760: 77
        ld      hl,PENGUIN_SPEED                               ;#7761: 21 00 E1
        ld      a,(hl)                                         ;#7764: 7E
        cp      13h                                            ;#7765: FE 13
        ret     nc                                             ;#7767: D0
        inc     (hl)                                           ;#7768: 34
HANDLE_SPEED_COAST:
        ; Handle no Up/Down input
        ret                                                    ;#7769: C9

CALC_HUD_SPEED_BAR:
        ; Build HUD speed-bar tile run from PENGUIN_SPEED into HUD_SPEED_BAR_TILES
        ld      a,(PENGUIN_FALL_TIMER)                         ;#776A: 3A 40 E1
        ld      hl,PENGUIN_STUN_TIMER                          ;#776D: 21 42 E1
        add     a,(hl)                                         ;#7770: 86
        ld      hl,HUD_SPEED_BAR_TILES                         ;#7771: 21 71 E1
        jr      nz,CALC_HUD_SPEED_BAR_PAD                      ;#7774: 20 1F
        ld      a,(PENGUIN_SPEED)                              ;#7776: 3A 00 E1
        ld      b,a                                            ;#7779: 47
        and     1                                              ;#777A: E6 01
        add     a,42h                                          ;#777C: C6 42
        ld      c,a                                            ;#777E: 4F
        ld      a,b                                            ;#777F: 78
        rra                                                    ;#7780: 1F
        cpl                                                    ;#7781: 2F
        and     0Fh                                            ;#7782: E6 0F
        sub     6                                              ;#7784: D6 06
        jr      z,CALC_HUD_SPEED_BAR_STORE                     ;#7786: 28 06
        ld      b,a                                            ;#7788: 47
CALC_HUD_SPEED_BAR_LOOP:
        ; Inner loop writing 42h tiles for the speed-bar fill
        ld      (hl),42h                                       ;#7789: 36 42
        inc     hl                                             ;#778B: 23
        djnz    CALC_HUD_SPEED_BAR_LOOP                        ;#778C: 10 FB
CALC_HUD_SPEED_BAR_STORE:
        ; Write the trailing animated tile (42h or 43h, alternating with speed)
        ld      (hl),c                                         ;#778E: 71
        inc     hl                                             ;#778F: 23
        ld      a,l                                            ;#7790: 7D
        cp      78h                                            ;#7791: FE 78
        jr      z,SYNC_HUD_SPEED_BAR                           ;#7793: 28 04
CALC_HUD_SPEED_BAR_PAD:
        ; Pad remaining slots with 0 until end of buffer
        ld      c,0                                            ;#7795: 0E 00
        jr      CALC_HUD_SPEED_BAR_STORE                       ;#7797: 18 F5

SYNC_HUD_SPEED_BAR:
        ; Copy HUD_SPEED_BAR_TILES to name table row 1, col 25
        ld      hl,HUD_SPEED_BAR_TILES                         ;#7799: 21 71 E1
        LOAD_NAME_TABLE de, 1, 25                              ;#779C: 11 39 38
        ld      bc,6                                           ;#779F: 01 06 00
        jp      COPY_RAM_TO_VRAM                               ;#77A2: C3 EC 44

HANDLE_DEMO_PLAY_MASKING:
        ; Places 4 invisible sprites to mask other sprites (5th sprite limit)
        ld      a,(INPUT_DEVICE_FLAGS)                         ;#77A5: 3A 02 E0
        bit     6,a                                            ;#77A8: CB 77
        ret     z                                              ;#77AA: C8
        ld      b,4                                            ;#77AB: 06 04
        ld      de,SAT_MIRROR + SPRITE_CLOUD + ATTR_Y          ;#77AD: 11 B8 E0
        ld      hl,DEMO_PLAY_MASK_FLAGS                        ;#77B0: 21 4A E1
DEMO_PLAY_MASK_LOOP:
        ; Loop for demo play masking
        ld      a,(hl)                                         ;#77B3: 7E
        or      a                                              ;#77B4: B7
        ld      a,4                                            ;#77B5: 3E 04
        jr      nz,DEMO_PLAY_MASK_NEXT                         ;#77B7: 20 1B
        push    hl                                             ;#77B9: E5
        inc     (hl)                                           ;#77BA: 34
        ld      hl,DEMO_PLAY_MASK_COORDS_DATA-2                ;#77BB: 21 38 78
        ld      a,b                                            ;#77BE: 78
        add     a,a                                            ;#77BF: 87
        call    ADD_HL_A                                       ;#77C0: CD FE 48
        ld      a,(hl)                                         ;#77C3: 7E
        ld      (de),a                                         ;#77C4: 12
        inc     hl                                             ;#77C5: 23
        inc     de                                             ;#77C6: 13
        ld      a,(hl)                                         ;#77C7: 7E
        ld      (de),a                                         ;#77C8: 12
        inc     de                                             ;#77C9: 13
        ld      a,0E0h                                         ;#77CA: 3E E0
        ld      (de),a                                         ;#77CC: 12
        inc     de                                             ;#77CD: 13
        ld      a,0Fh                                          ;#77CE: 3E 0F
        ld      (de),a                                         ;#77D0: 12
        ld      a,1                                            ;#77D1: 3E 01
        pop     hl                                             ;#77D3: E1
DEMO_PLAY_MASK_NEXT:
        ; Next demo play mask entry
        call    ADD_DE_A                                       ;#77D4: CD 03 49
        inc     hl                                             ;#77D7: 23
        djnz    DEMO_PLAY_MASK_LOOP                            ;#77D8: 10 D9
        ld      hl,DEMO_PLAY_MASK_TIMER                        ;#77DA: 21 49 E1
        dec     (hl)                                           ;#77DD: 35
        ret     nz                                             ;#77DE: C0
        ld      a,(DEMO_PLAY_MASK_RELOAD)                      ;#77DF: 3A 48 E1
        ld      (hl),a                                         ;#77E2: 77
        ld      b,0                                            ;#77E3: 06 00
        ld      hl,DEMO_PLAY_MASK_FLAGS                        ;#77E5: 21 4A E1
        ld      de,SAT_MIRROR + SPRITE_CLOUD + ATTR_Y          ;#77E8: 11 B8 E0
PROCESS_NEXT_CLOUD_SPRITE:
        ; Loop entry for processing the 4 cloud sprites
        ld      a,(hl)                                         ;#77EB: 7E
        or      a                                              ;#77EC: B7
        jr      z,ADVANCE_CLOUD_SPRITE_PTRS                    ;#77ED: 28 2F
        ld      a,(de)                                         ;#77EF: 1A
        cp      8                                              ;#77F0: FE 08
        jr      nz,ANIMATE_CLOUD_SPRITES                       ;#77F2: 20 07
        ld      a,0D1h                                         ;#77F4: 3E D1
        ld      (de),a                                         ;#77F6: 12
        ld      (hl),0                                         ;#77F7: 36 00
        jr      ADVANCE_CLOUD_SPRITE_PTRS                      ;#77F9: 18 23

ANIMATE_CLOUD_SPRITES:
        ; Handles bobbing animation for Cloud sprites
        push    de                                             ;#77FB: D5
        inc     (hl)                                           ;#77FC: 34
        ex      de,hl                                          ;#77FD: EB
        dec     (hl)                                           ;#77FE: 35
        push    de                                             ;#77FF: D5
        ld      de,CLOUD_ANIMATION_OFFSETS                     ;#7800: 11 36 78
        ld      a,b                                            ;#7803: 78
        call    ADD_DE_A                                       ;#7804: CD 03 49
        ld      a,(de)                                         ;#7807: 1A
        inc     hl                                             ;#7808: 23
        add     a,(hl)                                         ;#7809: 86
        ld      (hl),a                                         ;#780A: 77
        ex      de,hl                                          ;#780B: EB
        pop     hl                                             ;#780C: E1
        ld      a,(hl)                                         ;#780D: 7E
        cp      0Ch                                            ;#780E: FE 0C
        ld      a,0DCh                                         ;#7810: 3E DC
        jr      z,UPDATE_CLOUD_SPRITE_ATTR                     ;#7812: 28 07
        ld      a,(hl)                                         ;#7814: 7E
        cp      18h                                            ;#7815: FE 18
        ld      a,0D8h                                         ;#7817: 3E D8
        jr      nz,CLOUD_SPRITE_RESTORE_PTR                    ;#7819: 20 02
UPDATE_CLOUD_SPRITE_ATTR:
        ; Updates a specific attribute at offset 1 during specific animation frames
        inc     de                                             ;#781B: 13
        ld      (de),a                                         ;#781C: 12
CLOUD_SPRITE_RESTORE_PTR:
        ; Restores the sprite pointer (DE) from the stack after potential updates
        pop     de                                             ;#781D: D1
ADVANCE_CLOUD_SPRITE_PTRS:
        ; Advances the pointers to the next sprite in the batch of 4
        ld      a,4                                            ;#781E: 3E 04
        call    ADD_DE_A                                       ;#7820: CD 03 49
        inc     hl                                             ;#7823: 23
        ld      a,4                                            ;#7824: 3E 04
        inc     b                                              ;#7826: 04
        cp      b                                              ;#7827: B8
        jr      nz,PROCESS_NEXT_CLOUD_SPRITE                   ;#7828: 20 C1
        ld      hl,SAT_MIRROR + SPRITE_CLOUD + ATTR_Y          ;#782A: 21 B8 E0
        LOAD_SPRITE_ATTR de, 26, 0                             ;#782D: 11 68 3B
        ld      bc,10h                                         ;#7830: 01 10 00
        jp      COPY_RAM_TO_VRAM                               ;#7833: C3 EC 44

CLOUD_ANIMATION_OFFSETS:
        ; Per-frame Y deltas for cloud sprite bobbing (4 signed bytes)
        ; Format: FORMAT_CLOUD_OFFSETS
        CLOUD_OFFSET -1                                        ;#7836: FF
        CLOUD_OFFSET 1                                         ;#7837: 01
        CLOUD_OFFSET -2                                        ;#7838: FE
        CLOUD_OFFSET 2                                         ;#7839: 02

DEMO_PLAY_MASK_COORDS_DATA:
        ; Demo play-mask sprite (Y, X) pairs (4 sprites x 2 unsigned bytes)
        ; Format: FORMAT_SPRITE_YX_PAIRS
        SPRITE_YX 38h, 98h                                     ;#783A: 38 98
        SPRITE_YX 37h, 58h                                     ;#783C: 37 58
        SPRITE_YX 3Ch, 7Ch                                     ;#783E: 3C 7C
        SPRITE_YX 3Ah, 74h                                     ;#7840: 3A 74

HANDLE_SPECIAL_ITEM_EVENT:
        ; Processes effect of special item collision
        ld      a,(FISH_POS_STATE)                             ;#7842: 3A 83 E1
        and     0E0h                                           ;#7845: E6 E0
        ret     z                                              ;#7847: C8
        ld      hl,(ITEM_COLLISION_PTR)                        ;#7848: 2A 81 E1
        ld      a,(hl)                                         ;#784B: 7E
        ld      hl,FISH_POS_STATE                              ;#784C: 21 83 E1
        sub     0Fh                                            ;#784F: D6 0F
        jr      nz,LOAD_ITEM_ANIM_PTR                          ;#7851: 20 08
        ld      (hl),a                                         ;#7853: 77
        ld      hl,ITEM_POS_OFFSCREEN                          ;#7854: 21 BD 79
        ld      b,4                                            ;#7857: 06 04
        jr      INIT_ANIM_BUFFER_PTRS                          ;#7859: 18 3C

LOAD_ITEM_ANIM_PTR:
        ; Load pointer to animation data
        ld      hl,ITEM_ANIM_SEAL_TABLE                        ;#785B: 21 C1 78
        add     a,8                                            ;#785E: C6 08
        ld      b,a                                            ;#7860: 47
        add     a,a                                            ;#7861: 87
        call    ADD_HL_A                                       ;#7862: CD FE 48
        ld      e,(hl)                                         ;#7865: 5E
        inc     hl                                             ;#7866: 23
        ld      d,(hl)                                         ;#7867: 56
        ld      a,b                                            ;#7868: 78
        ld      b,4                                            ;#7869: 06 04
        cp      6                                              ;#786B: FE 06
        jr      c,CHECK_ANIM_FRAME_INDEX                       ;#786D: 38 0C
        ld      hl,FISH_POS_GUARD_FLAG                         ;#786F: 21 37 E1
        bit     0,(hl)                                         ;#7872: CB 46
        jr      nz,CHECK_ANIM_FRAME_INDEX                      ;#7874: 20 05
        ld      hl,FISH_POS_VRAM_SELECT                        ;#7876: 21 92 E1
        ld      (hl),1                                         ;#7879: 36 01
CHECK_ANIM_FRAME_INDEX:
        ; Check animation frame index validity
        cp      3                                              ;#787B: FE 03
        ex      de,hl                                          ;#787D: EB
        ld      d,0Ch                                          ;#787E: 16 0C
        jr      nc,CALC_ANIM_SOURCE_ADDR                       ;#7880: 30 04
        ld      d,6                                            ;#7882: 16 06
        ld      b,2                                            ;#7884: 06 02
CALC_ANIM_SOURCE_ADDR:
        ; Calculate source address for animation data
        ld      a,(FISH_POS_STATE)                             ;#7886: 3A 83 E1
        cp      40h                                            ;#7889: FE 40
        jr      z,INIT_ANIM_BUFFER_PTRS                        ;#788B: 28 0A
        jr      c,CALC_ANIM_SOURCE_NEXT                        ;#788D: 38 04
        ld      a,d                                            ;#788F: 7A
        call    ADD_HL_A                                       ;#7890: CD FE 48
CALC_ANIM_SOURCE_NEXT:
        ; Next animation source calculation step
        ld      a,d                                            ;#7893: 7A
        call    ADD_HL_A                                       ;#7894: CD FE 48
INIT_ANIM_BUFFER_PTRS:
        ; Initialize pointers for animation buffer copy
        ld      de,SAT_MIRROR + SPRITE_OBSTACLE + ATTR_Y       ;#7897: 11 90 E0
        push    de                                             ;#789A: D5
ANIM_FRAME_COPY_LOOP:
        ; Outer loop for copying animation frame data
        ld      c,3                                            ;#789B: 0E 03
ANIM_BYTE_COPY_LOOP:
        ; Inner loop for copying attribute bytes
        ld      a,(hl)                                         ;#789D: 7E
        ld      (de),a                                         ;#789E: 12
        inc     hl                                             ;#789F: 23
        inc     de                                             ;#78A0: 13
        dec     c                                              ;#78A1: 0D
        jr      nz,ANIM_BYTE_COPY_LOOP                         ;#78A2: 20 F9
        inc     de                                             ;#78A4: 13
        djnz    ANIM_FRAME_COPY_LOOP                           ;#78A5: 10 F4
        pop     hl                                             ;#78A7: E1
        ld      c,10h                                          ;#78A8: 0E 10
        ld      a,(FISH_POS_VRAM_SELECT)                       ;#78AA: 3A 92 E1
        rra                                                    ;#78AD: 1F
        ld      de,VRAM_SAT_BASE                               ;#78AE: 11 00 3B
        jr      nc,UPLOAD_ANIM_TO_VRAM_HIGH                    ;#78B1: 30 06
        call    COPY_RAM_TO_VRAM                               ;#78B3: CD EC 44
        ld      hl,SAT_MIRROR                                  ;#78B6: 21 50 E0
UPLOAD_ANIM_TO_VRAM_HIGH:
        ; Upload animation data to high VRAM address
        LOAD_SPRITE_ATTR de, 16, 0                             ;#78B9: 11 40 3B
        ld      c,10h                                          ;#78BC: 0E 10
        jp      COPY_RAM_TO_VRAM                               ;#78BE: C3 EC 44

ITEM_ANIM_SEAL_TABLE:
        ; Pointer table for seal-approach animation frames (9 entries)
        dw      ITEM_ANIM_SEAL_0                               ;#78C1: D3 78
        dw      ITEM_ANIM_SEAL_1                               ;#78C3: E5 78
        dw      ITEM_ANIM_SEAL_2                               ;#78C5: F7 78
        dw      ITEM_ANIM_SEAL_3                               ;#78C7: 09 79
        dw      ITEM_ANIM_SEAL_4                               ;#78C9: 2D 79
        dw      ITEM_ANIM_SEAL_5                               ;#78CB: 51 79
        dw      ITEM_ANIM_SEAL_6                               ;#78CD: 75 79
        dw      ITEM_ANIM_SEAL_7                               ;#78CF: 99 79
        dw      ITEM_POS_OFFSCREEN                             ;#78D1: BD 79

ITEM_ANIM_SEAL_0:
        ; Seal approach frame 0 (farthest; 3 positions x 2 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 67h, 78h, 7Ch                        ;#78D3: 67 78 7C
        SPRITE_ANIM_FRAME 67h, 78h, 0E8h                       ;#78D6: 67 78 E8
        SPRITE_ANIM_FRAME 67h, 90h, 7Ch                        ;#78D9: 67 90 7C
        SPRITE_ANIM_FRAME 67h, 90h, 0E8h                       ;#78DC: 67 90 E8
        SPRITE_ANIM_FRAME 67h, 60h, 7Ch                        ;#78DF: 67 60 7C
        SPRITE_ANIM_FRAME 67h, 60h, 0E8h                       ;#78E2: 67 60 E8

ITEM_ANIM_SEAL_1:
        ; Seal approach frame 1 (3 positions x 2 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 6Ch, 78h, 0B8h                       ;#78E5: 6C 78 B8
        SPRITE_ANIM_FRAME 6Ch, 78h, 0BCh                       ;#78E8: 6C 78 BC
        SPRITE_ANIM_FRAME 6Ch, 94h, 0B8h                       ;#78EB: 6C 94 B8
        SPRITE_ANIM_FRAME 6Ch, 94h, 0BCh                       ;#78EE: 6C 94 BC
        SPRITE_ANIM_FRAME 6Ch, 5Bh, 0B8h                       ;#78F1: 6C 5B B8
        SPRITE_ANIM_FRAME 6Ch, 5Bh, 0BCh                       ;#78F4: 6C 5B BC

ITEM_ANIM_SEAL_2:
        ; Seal approach frame 2 (3 positions x 2 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 78h, 78h, 0B8h                       ;#78F7: 78 78 B8
        SPRITE_ANIM_FRAME 78h, 78h, 0BCh                       ;#78FA: 78 78 BC
        SPRITE_ANIM_FRAME 78h, 9Dh, 0B8h                       ;#78FD: 78 9D B8
        SPRITE_ANIM_FRAME 78h, 9Dh, 0BCh                       ;#7900: 78 9D BC
        SPRITE_ANIM_FRAME 78h, 53h, 0B8h                       ;#7903: 78 53 B8
        SPRITE_ANIM_FRAME 78h, 53h, 0BCh                       ;#7906: 78 53 BC

ITEM_ANIM_SEAL_3:
        ; Seal approach frame 3 (3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 7Bh, 78h, 0C0h                       ;#7909: 7B 78 C0
        SPRITE_ANIM_FRAME 8Bh, 70h, 0C4h                       ;#790C: 8B 70 C4
        SPRITE_ANIM_FRAME 7Bh, 78h, 0C8h                       ;#790F: 7B 78 C8
        SPRITE_ANIM_FRAME 8Bh, 80h, 0CCh                       ;#7912: 8B 80 CC
        SPRITE_ANIM_FRAME 7Bh, 0A4h, 0C0h                      ;#7915: 7B A4 C0
        SPRITE_ANIM_FRAME 8Bh, 9Ch, 0C4h                       ;#7918: 8B 9C C4
        SPRITE_ANIM_FRAME 7Bh, 0A4h, 0C8h                      ;#791B: 7B A4 C8
        SPRITE_ANIM_FRAME 8Bh, 0ACh, 0CCh                      ;#791E: 8B AC CC
        SPRITE_ANIM_FRAME 7Bh, 4Ch, 0C0h                       ;#7921: 7B 4C C0
        SPRITE_ANIM_FRAME 8Bh, 44h, 0C4h                       ;#7924: 8B 44 C4
        SPRITE_ANIM_FRAME 7Bh, 4Ch, 0C8h                       ;#7927: 7B 4C C8
        SPRITE_ANIM_FRAME 8Bh, 54h, 0CCh                       ;#792A: 8B 54 CC

ITEM_ANIM_SEAL_4:
        ; Seal approach frame 4 (3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 86h, 78h, 0C0h                       ;#792D: 86 78 C0
        SPRITE_ANIM_FRAME 96h, 70h, 0C4h                       ;#7930: 96 70 C4
        SPRITE_ANIM_FRAME 86h, 78h, 0C8h                       ;#7933: 86 78 C8
        SPRITE_ANIM_FRAME 96h, 80h, 0CCh                       ;#7936: 96 80 CC
        SPRITE_ANIM_FRAME 86h, 0ACh, 0C0h                      ;#7939: 86 AC C0
        SPRITE_ANIM_FRAME 96h, 0A4h, 0C4h                      ;#793C: 96 A4 C4
        SPRITE_ANIM_FRAME 86h, 0ACh, 0C8h                      ;#793F: 86 AC C8
        SPRITE_ANIM_FRAME 96h, 0B4h, 0CCh                      ;#7942: 96 B4 CC
        SPRITE_ANIM_FRAME 86h, 44h, 0C0h                       ;#7945: 86 44 C0
        SPRITE_ANIM_FRAME 96h, 3Ch, 0C4h                       ;#7948: 96 3C C4
        SPRITE_ANIM_FRAME 86h, 44h, 0C8h                       ;#794B: 86 44 C8
        SPRITE_ANIM_FRAME 96h, 4Ch, 0CCh                       ;#794E: 96 4C CC

ITEM_ANIM_SEAL_5:
        ; Seal approach frame 5 (3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 8Fh, 78h, 0C0h                       ;#7951: 8F 78 C0
        SPRITE_ANIM_FRAME 9Fh, 70h, 0C4h                       ;#7954: 9F 70 C4
        SPRITE_ANIM_FRAME 8Fh, 78h, 0C8h                       ;#7957: 8F 78 C8
        SPRITE_ANIM_FRAME 9Fh, 80h, 0CCh                       ;#795A: 9F 80 CC
        SPRITE_ANIM_FRAME 8Fh, 0B2h, 0C0h                      ;#795D: 8F B2 C0
        SPRITE_ANIM_FRAME 9Fh, 0AAh, 0C4h                      ;#7960: 9F AA C4
        SPRITE_ANIM_FRAME 8Fh, 0B2h, 0C8h                      ;#7963: 8F B2 C8
        SPRITE_ANIM_FRAME 9Fh, 0BAh, 0CCh                      ;#7966: 9F BA CC
        SPRITE_ANIM_FRAME 8Fh, 3Eh, 0C0h                       ;#7969: 8F 3E C0
        SPRITE_ANIM_FRAME 9Fh, 36h, 0C4h                       ;#796C: 9F 36 C4
        SPRITE_ANIM_FRAME 8Fh, 3Eh, 0C8h                       ;#796F: 8F 3E C8
        SPRITE_ANIM_FRAME 9Fh, 46h, 0CCh                       ;#7972: 9F 46 CC

ITEM_ANIM_SEAL_6:
        ; Seal approach frame 6 (3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 98h, 78h, 0C0h                       ;#7975: 98 78 C0
        SPRITE_ANIM_FRAME 0A8h, 70h, 0C4h                      ;#7978: A8 70 C4
        SPRITE_ANIM_FRAME 98h, 78h, 0C8h                       ;#797B: 98 78 C8
        SPRITE_ANIM_FRAME 0A8h, 80h, 0CCh                      ;#797E: A8 80 CC
        SPRITE_ANIM_FRAME 98h, 0B8h, 0C0h                      ;#7981: 98 B8 C0
        SPRITE_ANIM_FRAME 0A8h, 0B0h, 0C4h                     ;#7984: A8 B0 C4
        SPRITE_ANIM_FRAME 98h, 0B8h, 0C8h                      ;#7987: 98 B8 C8
        SPRITE_ANIM_FRAME 0A8h, 0C0h, 0CCh                     ;#798A: A8 C0 CC
        SPRITE_ANIM_FRAME 98h, 38h, 0C0h                       ;#798D: 98 38 C0
        SPRITE_ANIM_FRAME 0A8h, 30h, 0C4h                      ;#7990: A8 30 C4
        SPRITE_ANIM_FRAME 98h, 38h, 0C8h                       ;#7993: 98 38 C8
        SPRITE_ANIM_FRAME 0A8h, 40h, 0CCh                      ;#7996: A8 40 CC

ITEM_ANIM_SEAL_7:
        ; Seal approach frame 7 (closest; 3 positions x 4 sprites: center, right, left)
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 0A1h, 78h, 0C0h                      ;#7999: A1 78 C0
        SPRITE_ANIM_FRAME 0B1h, 70h, 0C4h                      ;#799C: B1 70 C4
        SPRITE_ANIM_FRAME 0A1h, 78h, 0C8h                      ;#799F: A1 78 C8
        SPRITE_ANIM_FRAME 0B1h, 80h, 0CCh                      ;#79A2: B1 80 CC
        SPRITE_ANIM_FRAME 0A1h, 0BEh, 0C0h                     ;#79A5: A1 BE C0
        SPRITE_ANIM_FRAME 0B1h, 0B6h, 0C4h                     ;#79A8: B1 B6 C4
        SPRITE_ANIM_FRAME 0A1h, 0BEh, 0C8h                     ;#79AB: A1 BE C8
        SPRITE_ANIM_FRAME 0B1h, 0C6h, 0CCh                     ;#79AE: B1 C6 CC
        SPRITE_ANIM_FRAME 0A1h, 32h, 0C0h                      ;#79B1: A1 32 C0
        SPRITE_ANIM_FRAME 0B1h, 2Ah, 0C4h                      ;#79B4: B1 2A C4
        SPRITE_ANIM_FRAME 0A1h, 32h, 0C8h                      ;#79B7: A1 32 C8
        SPRITE_ANIM_FRAME 0B1h, 3Ah, 0CCh                      ;#79BA: B1 3A CC

ITEM_POS_OFFSCREEN:
        ; Off-screen/reset position
        ; Format: FORMAT_ITEM_ANIM_SPRITES
        ; - Each entry is a 3-byte sprite attribute without color.
        ; - Frames are contiguous; code picks 2-sprite (6B) or 4-sprite (12B) frames.
        SPRITE_ANIM_FRAME 0E0h, 0, 0                           ;#79BD: E0 00 00
        SPRITE_ANIM_FRAME 0E0h, 0, 0                           ;#79C0: E0 00 00
        SPRITE_ANIM_FRAME 0E0h, 0, 0                           ;#79C3: E0 00 00
        SPRITE_ANIM_FRAME 0E0h, 0, 0                           ;#79C6: E0 00 00

PLAY_SOUND_SAFE:
        ; Start sound track (Saves registers, disables INT)
        di                                                     ;#79C9: F3
        push    hl                                             ;#79CA: E5
        push    de                                             ;#79CB: D5
        push    bc                                             ;#79CC: C5
        push    af                                             ;#79CD: F5
        call    PLAY_SOUND                                     ;#79CE: CD D7 79
        pop     af                                             ;#79D1: F1
        pop     bc                                             ;#79D2: C1
        pop     de                                             ;#79D3: D1
        pop     hl                                             ;#79D4: E1
        ei                                                     ;#79D5: FB
        ret                                                    ;#79D6: C9

PLAY_SOUND:
        ; Start sound track
        ld      b,2                                            ;#79D7: 06 02
        ld      hl,MUSIC_VARS_CH0+MUSIC_DRIVER_CONTROL         ;#79D9: 21 12 E0
        cp      8Ah                                            ;#79DC: FE 8A
        jr      c,PLAY_SOUND_SELECT_CH2                        ;#79DE: 38 07
        cp      8Ch                                            ;#79E0: FE 8C
        jr      c,PLAY_SOUND_CHECK_PRIORITY                    ;#79E2: 38 07
        inc     b                                              ;#79E4: 04
        jr      PLAY_SOUND_CHECK_PRIORITY                      ;#79E5: 18 04

PLAY_SOUND_SELECT_CH2:
        ; Sets the target channel to Channel 2 for high-priority sounds
        dec     b                                              ;#79E7: 05
        ld      hl,MUSIC_VARS_CH2+MUSIC_DRIVER_CONTROL         ;#79E8: 21 26 E0
PLAY_SOUND_CHECK_PRIORITY:
        ; Checks if the requested sound has higher priority than the currently playing one
        cp      (hl)                                           ;#79EB: BE
        jr      c,PLAY_SOUND_DONE                              ;#79EC: 38 23
        ld      c,a                                            ;#79EE: 4F
        and     3Fh                                            ;#79EF: E6 3F
        add     a,a                                            ;#79F1: 87
        ld      de,SOUND_TABLE-2                               ;#79F2: 11 52 7B
        call    ADD_DE_A                                       ;#79F5: CD 03 49
PLAY_SOUND_INIT_CHANNEL_DATA:
        ; Initialize channel data pointers from sound table
        dec     hl                                             ;#79F8: 2B
        dec     hl                                             ;#79F9: 2B
        ld      (hl),1                                         ;#79FA: 36 01
        inc     hl                                             ;#79FC: 23
        ld      (hl),1                                         ;#79FD: 36 01
        inc     hl                                             ;#79FF: 23
        ld      a,c                                            ;#7A00: 79
        ld      (hl),a                                         ;#7A01: 77
        inc     hl                                             ;#7A02: 23
        ld      a,(de)                                         ;#7A03: 1A
        ld      (hl),a                                         ;#7A04: 77
        inc     hl                                             ;#7A05: 23
        inc     de                                             ;#7A06: 13
        ld      a,(de)                                         ;#7A07: 1A
        ld      (hl),a                                         ;#7A08: 77
        ld      a,8                                            ;#7A09: 3E 08
        call    ADD_HL_A                                       ;#7A0B: CD FE 48
        inc     de                                             ;#7A0E: 13
        djnz    PLAY_SOUND_INIT_CHANNEL_DATA                   ;#7A0F: 10 E7
PLAY_SOUND_DONE:
        ; Sound priority check finished
        ret                                                    ;#7A11: C9

PLAY_SOUND_HANDLE_REPEAT:
        ; Process the repeat/loop command in sound data
        inc     hl                                             ;#7A12: 23
        ld      a,(hl)                                         ;#7A13: 7E
        inc     a                                              ;#7A14: 3C
        jr      z,PLAY_SOUND_FETCH_STATUS                      ;#7A15: 28 10
        inc     (ix+MUSIC_DRIVER_REPEAT_COUNT)                 ;#7A17: DD 34 09
        dec     a                                              ;#7A1A: 3D
        cp      (ix+MUSIC_DRIVER_REPEAT_COUNT)                 ;#7A1B: DD BE 09
        jr      nz,PLAY_SOUND_FETCH_STATUS                     ;#7A1E: 20 07
        xor     a                                              ;#7A20: AF
        ld      (ix+MUSIC_DRIVER_REPEAT_COUNT),a               ;#7A21: DD 77 09
        jp      PROCESS_SOUND_END_OF_SOUND                     ;#7A24: C3 AA 7A

PLAY_SOUND_FETCH_STATUS:
        ; Resume processing by fetching current channel status
        ld      a,(ix+MUSIC_DRIVER_CONTROL)                    ;#7A27: DD 7E 02
        push    bc                                             ;#7A2A: C5
        call    PLAY_SOUND                                     ;#7A2B: CD D7 79
        pop     bc                                             ;#7A2E: C1
        ret                                                    ;#7A2F: C9

PROCESS_SOUND:
        ; Entry point for periodic sound engine update (interrupt driven)
        ld      a,7                                            ;#7A30: 3E 07
        call    BIOS_RDPSG                                     ;#7A32: CD 96 00
        and     0B8h                                           ;#7A35: E6 B8
        ld      e,a                                            ;#7A37: 5F
        ld      a,7                                            ;#7A38: 3E 07
        call    BIOS_WRTPSG                                    ;#7A3A: CD 93 00
        ld      c,1                                            ;#7A3D: 0E 01
        ld      ix,MUSIC_VARS_CH0                              ;#7A3F: DD 21 10 E0
        exx                                                    ;#7A43: D9
        ld      b,3                                            ;#7A44: 06 03
        ld      de,0Ah                                         ;#7A46: 11 0A 00
PROCESS_SOUND_CHANNEL_LOOP:
        ; Loop entry for processing the three PSG sound channels
        exx                                                    ;#7A49: D9
        ld      a,(ix+MUSIC_DRIVER_CONTROL)                    ;#7A4A: DD 7E 02
        or      a                                              ;#7A4D: B7
        call    nz,PROCESS_SOUND_CHANNEL                       ;#7A4E: C4 5A 7A
        inc     c                                              ;#7A51: 0C
        inc     c                                              ;#7A52: 0C
        exx                                                    ;#7A53: D9
        add     ix,de                                          ;#7A54: DD 19
        djnz    PROCESS_SOUND_CHANNEL_LOOP                     ;#7A56: 10 F1
        exx                                                    ;#7A58: D9
        ret                                                    ;#7A59: C9

PROCESS_SOUND_CHANNEL:
        ; Process the current state of a single sound channel
        jp      m,PROCESS_SOUND_DECREMENT_TIMER                ;#7A5A: FA B1 7A
        dec     (ix)                                           ;#7A5D: DD 35 00
        ret     nz                                             ;#7A60: C0
PROCESS_SOUND_READ_NEXT_BYTE:
        ; Fetch and decode the next byte from the sound stream
        ld      l,(ix+MUSIC_DRIVER_STREAM_PTR_LO)              ;#7A61: DD 6E 03
        ld      h,(ix+MUSIC_DRIVER_STREAM_PTR_HI)              ;#7A64: DD 66 04
        ld      a,(hl)                                         ;#7A67: 7E
        cp      0FEh                                           ;#7A68: FE FE
        jr      z,PLAY_SOUND_HANDLE_REPEAT                     ;#7A6A: 28 A6
        jr      nc,PROCESS_SOUND_END_OF_SOUND                  ;#7A6C: 30 3C
        bit     7,(ix+MUSIC_DRIVER_CONTROL)                    ;#7A6E: DD CB 02 7E
        jp      nz,PROCESS_SOUND_SPECIAL_MARKER                ;#7A72: C2 DA 7A
        and     0F0h                                           ;#7A75: E6 F0
        cp      20h                                            ;#7A77: FE 20
        jr      nz,PROCESS_SOUND_SKIP_SET_VOL                  ;#7A79: 20 07
        ld      a,(hl)                                         ;#7A7B: 7E
        and     0Fh                                            ;#7A7C: E6 0F
        ld      (ix+MUSIC_DRIVER_DURATION_BASE),a              ;#7A7E: DD 77 01
        inc     hl                                             ;#7A81: 23
PROCESS_SOUND_SKIP_SET_VOL:
        ; Skip setting the volume if the command is not 0x20
        ld      a,(hl)                                         ;#7A82: 7E
        and     0F0h                                           ;#7A83: E6 F0
        ld      b,a                                            ;#7A85: 47
        xor     (hl)                                           ;#7A86: AE
        ld      d,a                                            ;#7A87: 57
        inc     hl                                             ;#7A88: 23
        ld      e,(hl)                                         ;#7A89: 5E
        inc     hl                                             ;#7A8A: 23
        ld      (ix+MUSIC_DRIVER_STREAM_PTR_LO),l              ;#7A8B: DD 75 03
        ld      (ix+MUSIC_DRIVER_STREAM_PTR_HI),h              ;#7A8E: DD 74 04
        ex      de,hl                                          ;#7A91: EB
        call    PROCESS_SOUND_WRITE_PERIOD                     ;#7A92: CD 2C 7B
        ld      a,b                                            ;#7A95: 78
        rrca                                                   ;#7A96: 0F
        rrca                                                   ;#7A97: 0F
        rrca                                                   ;#7A98: 0F
        rrca                                                   ;#7A99: 0F
        and     0Fh                                            ;#7A9A: E6 0F
PROCESS_SOUND_UPDATE_CHANNEL_REGS:
        ; Updates channel state pointers and duration counters
        ld      h,a                                            ;#7A9C: 67
        ld      a,(ix+MUSIC_DRIVER_DURATION_BASE)              ;#7A9D: DD 7E 01
        ld      (ix),a                                         ;#7AA0: DD 77 00
        add     a,3                                            ;#7AA3: C6 03
        ld      (ix+MUSIC_DRIVER_SUSTAIN_TIMER),a              ;#7AA5: DD 77 08
        jr      PROCESS_SOUND_WRITE_VOLUME                     ;#7AA8: 18 28

PROCESS_SOUND_END_OF_SOUND:
        ; Handle the end of a sound data stream
        xor     a                                              ;#7AAA: AF
        ld      (ix+MUSIC_DRIVER_CONTROL),a                    ;#7AAB: DD 77 02
        ld      h,a                                            ;#7AAE: 67
        jr      PROCESS_SOUND_WRITE_VOLUME                     ;#7AAF: 18 21

PROCESS_SOUND_DECREMENT_TIMER:
        ; Logic to decrement the main sound duration timer
        dec     (ix)                                           ;#7AB1: DD 35 00
        jr      z,PROCESS_SOUND_READ_NEXT_BYTE                 ;#7AB4: 28 AB
        dec     (ix+MUSIC_DRIVER_SUSTAIN_TIMER)                ;#7AB6: DD 35 08
        ld      a,(ix+MUSIC_DRIVER_SUSTAIN_TIMER)              ;#7AB9: DD 7E 08
        cp      (ix)                                           ;#7ABC: DD BE 00
        jr      nz,PROCESS_SOUND_DECREMENT_TIMER2              ;#7ABF: 20 05
        cp      1                                              ;#7AC1: FE 01
        jr      c,PROCESS_SOUND_RESET_TIMER2                   ;#7AC3: 38 04
        ret                                                    ;#7AC5: C9

PROCESS_SOUND_DECREMENT_TIMER2:
        ; Logic to decrement the secondary duration timer
        dec     (ix+MUSIC_DRIVER_SUSTAIN_TIMER)                ;#7AC6: DD 35 08
PROCESS_SOUND_RESET_TIMER2:
        ; Reset the secondary timer from the initial value
        ld      a,(ix+MUSIC_DRIVER_SUSTAIN_COUNTER)            ;#7AC9: DD 7E 07
        dec     a                                              ;#7ACC: 3D
        ret     m                                              ;#7ACD: F8
        ld      (ix+MUSIC_DRIVER_SUSTAIN_COUNTER),a            ;#7ACE: DD 77 07
        ld      h,a                                            ;#7AD1: 67
PROCESS_SOUND_WRITE_VOLUME:
        ; Write volume to current PSG channel
        ld      a,c                                            ;#7AD2: 79
        rrca                                                   ;#7AD3: 0F
        add     a,88h                                          ;#7AD4: C6 88
        ld      e,h                                            ;#7AD6: 5C
        jp      BIOS_WRTPSG                                    ;#7AD7: C3 93 00

PROCESS_SOUND_SPECIAL_MARKER:
        ; Decode special markers (>= 0xFD) in the sound stream
        cp      0FDh                                           ;#7ADA: FE FD
        jr      nz,PROCESS_SOUND_OTHER_MARKER                  ;#7ADC: 20 10
        inc     hl                                             ;#7ADE: 23
        ld      a,(hl)                                         ;#7ADF: 7E
        and     7                                              ;#7AE0: E6 07
        ld      (ix+MUSIC_DRIVER_OCTAVE),a                     ;#7AE2: DD 77 05
        xor     (hl)                                           ;#7AE5: AE
        rrca                                                   ;#7AE6: 0F
        rrca                                                   ;#7AE7: 0F
        rrca                                                   ;#7AE8: 0F
        ld      (ix+MUSIC_DRIVER_SUSTAIN_BASE),a               ;#7AE9: DD 77 06
        inc     hl                                             ;#7AEC: 23
        ld      a,(hl)                                         ;#7AED: 7E
PROCESS_SOUND_OTHER_MARKER:
        ; Decode markers other than 0xFD
        and     0Fh                                            ;#7AEE: E6 0F
        ld      b,a                                            ;#7AF0: 47
        xor     (hl)                                           ;#7AF1: AE
        inc     hl                                             ;#7AF2: 23
        ld      (ix+MUSIC_DRIVER_STREAM_PTR_LO),l              ;#7AF3: DD 75 03
        ld      (ix+MUSIC_DRIVER_STREAM_PTR_HI),h              ;#7AF6: DD 74 04
        rrca                                                   ;#7AF9: 0F
        rrca                                                   ;#7AFA: 0F
        rrca                                                   ;#7AFB: 0F
        rrca                                                   ;#7AFC: 0F
        ld      hl,SOUND_DURATION_TABLE                        ;#7AFD: 21 44 7B
        call    ADD_HL_A                                       ;#7B00: CD FE 48
        ld      a,(hl)                                         ;#7B03: 7E
        ld      (ix+MUSIC_DRIVER_DURATION_BASE),a              ;#7B04: DD 77 01
        ld      a,b                                            ;#7B07: 78
        sub     0Ch                                            ;#7B08: D6 0C
        ld      (ix+MUSIC_DRIVER_SUSTAIN_COUNTER),a            ;#7B0A: DD 77 07
        jr      z,PROCESS_SOUND_SKIP_PITCH_LOOKUP              ;#7B0D: 28 06
        ld      a,(ix+MUSIC_DRIVER_SUSTAIN_BASE)               ;#7B0F: DD 7E 06
        ld      (ix+MUSIC_DRIVER_SUSTAIN_COUNTER),a            ;#7B12: DD 77 07
PROCESS_SOUND_SKIP_PITCH_LOOKUP:
        ; Skip pitch lookup for command 0x0C
        call    PROCESS_SOUND_UPDATE_CHANNEL_REGS              ;#7B15: CD 9C 7A
        ld      a,b                                            ;#7B18: 78
        ld      hl,SOUND_PITCH_OFFSET_TABLE                    ;#7B19: 21 38 7B
        call    ADD_HL_A                                       ;#7B1C: CD FE 48
        ld      l,(hl)                                         ;#7B1F: 6E
        ld      h,0                                            ;#7B20: 26 00
        ld      a,(ix+MUSIC_DRIVER_OCTAVE)                     ;#7B22: DD 7E 05
        or      a                                              ;#7B25: B7
        jr      z,PROCESS_SOUND_WRITE_PERIOD                   ;#7B26: 28 04
        ld      b,a                                            ;#7B28: 47
PROCESS_SOUND_PITCH_SHIFT_LOOP:
        ; Small loop to shift the pitch value in HL
        add     hl,hl                                          ;#7B29: 29
        djnz    PROCESS_SOUND_PITCH_SHIFT_LOOP                 ;#7B2A: 10 FD
PROCESS_SOUND_WRITE_PERIOD:
        ; Write 12-bit period to PSG frequency registers
        ld      a,c                                            ;#7B2C: 79
        ld      e,h                                            ;#7B2D: 5C
        call    BIOS_WRTPSG                                    ;#7B2E: CD 93 00
        ld      a,c                                            ;#7B31: 79
        dec     a                                              ;#7B32: 3D
        ld      e,l                                            ;#7B33: 5D
        jp      BIOS_WRTPSG                                    ;#7B34: C3 93 00
        db      0FFh                                           ;#7B37: FF

SOUND_PITCH_OFFSET_TABLE:
        ; Table of pitch/period offsets
        ; Format: FORMAT_PITCH_TABLE
        db      06Ah ; C  (1055 Hz)                            ;#7B38: 6A
        db      064h ; C# (1118.5 Hz)                          ;#7B39: 64
        db      05Fh ; D  (1177.5 Hz)                          ;#7B3A: 5F
        db      059h ; D# (1257 Hz)                            ;#7B3B: 59
        db      054h ; E  (1331.5 Hz)                          ;#7B3C: 54
        db      050h ; F  (1398 Hz)                            ;#7B3D: 50
        db      04Bh ; F# (1491.5 Hz)                          ;#7B3E: 4B
        db      047h ; G  (1575.5 Hz)                          ;#7B3F: 47
        db      043h ; G# (1669.5 Hz)                          ;#7B40: 43
        db      03Fh ; A  (1775.5 Hz)                          ;#7B41: 3F
        db      03Ch ; A# (1864.5 Hz)                          ;#7B42: 3C
        db      038h ; B  (1997.5 Hz)                          ;#7B43: 38

SOUND_DURATION_TABLE:
        ; Table of note durations
        ; Format: FORMAT_DURATION_TABLE
        db      8                                              ;#7B44: 08
        db      10h                                            ;#7B45: 10
        db      20h                                            ;#7B46: 20
        db      30h                                            ;#7B47: 30
        db      40h                                            ;#7B48: 40
        db      60h                                            ;#7B49: 60
        db      5                                              ;#7B4A: 05
        db      0Ah                                            ;#7B4B: 0A
        db      0Fh                                            ;#7B4C: 0F
        db      14h                                            ;#7B4D: 14
        db      64h                                            ;#7B4E: 64
        db      1Eh                                            ;#7B4F: 1E
        db      18h                                            ;#7B50: 18
        db      3Ch                                            ;#7B51: 3C
        db      50h                                            ;#7B52: 50
        db      28h                                            ;#7B53: 28

SOUND_TABLE:
        ; Base of sound pointer table
        dw      SOUND_DATA_TICK                                ;#7B54: 46 7D
        dw      SOUND_DATA_JUMP                                ;#7B56: 20 7D
        dw      SOUND_DATA_OBSTACLE                            ;#7B58: 7E 7D
        dw      SOUND_DATA_CATCH                               ;#7B5A: 86 7D
        dw      SOUND_DATA_FALL_HOLE                           ;#7B5C: 6A 7D
        dw      SOUND_DATA_STAGE_START                         ;#7B5E: 5E 7D
        dw      SOUND_DATA_STUN_DESCENDING                     ;#7B60: 4C 7D
        dw      SOUND_DATA_STUMBLE                             ;#7B62: 75 7E
        dw      SOUND_DATA_DISTANCE_WARNING                    ;#7B64: 2E 7D
        dw      SOUND_DATA_MAIN_THEME                          ;#7B66: 83 7B
        dw      SOUND_DATA_MAIN_THEME_CH1                      ;#7B68: 03 7C
        dw      SOUND_DATA_TIME_OUT                            ;#7B6A: 22 7E
        dw      SOUND_DATA_TIME_OUT_CH1                        ;#7B6C: 3F 7E
        dw      SOUND_DATA_TIME_OUT_CH2                        ;#7B6E: 62 7E
        dw      SOUND_DATA_STAGE_CLEAR                         ;#7B70: D9 7C
        dw      SOUND_DATA_STAGE_CLEAR_CH1                     ;#7B72: F7 7C
        dw      SOUND_DATA_STAGE_CLEAR_CH2                     ;#7B74: 0E 7D
        dw      SOUND_DATA_INTRO_MUSIC                         ;#7B76: 8E 7D
        dw      SOUND_DATA_INTRO_MUSIC_CH1                     ;#7B78: C0 7D
        dw      SOUND_DATA_INTRO_MUSIC_CH2                     ;#7B7A: F3 7D
        dw      SOUND_DATA_SILENCE                             ;#7B7C: 82 7B
        dw      SOUND_DATA_SILENCE                             ;#7B7E: 82 7B
        dw      SOUND_DATA_SILENCE                             ;#7B80: 82 7B

SOUND_DATA_SILENCE:
        ; Data for Sound 21-23 (Silence/Stop, Size: 1)
        db      0FFh                                           ;#7B82: FF

SOUND_DATA_MAIN_THEME:
        ; Data for Sound 10 (Main Theme CH0, Size: 128)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7B83: FD 5A
        NOTE NOTE_B, DURATION_48                               ;#7B85: 3B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7B86: FD 59
        NOTE NOTE_D, DURATION_32                               ;#7B88: 22
        NOTE NOTE_E, DURATION_16                               ;#7B89: 14
        NOTE NOTE_E, DURATION_96                               ;#7B8A: 54
        NOTE NOTE_C, DURATION_48                               ;#7B8B: 30
        NOTE NOTE_E, DURATION_32                               ;#7B8C: 24
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7B8D: 16
        NOTE NOTE_F_SHARP, DURATION_96                         ;#7B8E: 56
        NOTE NOTE_A, DURATION_48                               ;#7B8F: 39
        NOTE NOTE_G, DURATION_32                               ;#7B90: 27
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7B91: FD 5A
        NOTE NOTE_B, DURATION_16                               ;#7B93: 1B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7B94: FD 59
        NOTE NOTE_D, DURATION_48                               ;#7B96: 32
        NOTE NOTE_C, DURATION_32                               ;#7B97: 20
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7B98: FD 5A
        NOTE NOTE_B, DURATION_16                               ;#7B9A: 1B
        NOTE NOTE_B, DURATION_48                               ;#7B9B: 3B
        NOTE NOTE_A, DURATION_48                               ;#7B9C: 39
        NOTE NOTE_G, DURATION_64                               ;#7B9D: 47
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7B9E: FD 59
        NOTE NOTE_D, DURATION_8                                ;#7BA0: 02
        NOTE NOTE_G, DURATION_8                                ;#7BA1: 07
        NOTE NOTE_E, DURATION_8                                ;#7BA2: 04
        NOTE NOTE_G, DURATION_8                                ;#7BA3: 07
        NOTE NOTE_D, DURATION_8                                ;#7BA4: 02
        NOTE NOTE_G, DURATION_8                                ;#7BA5: 07
        NOTE NOTE_E, DURATION_8                                ;#7BA6: 04
        NOTE NOTE_G, DURATION_8                                ;#7BA7: 07
        NOTE NOTE_D, DURATION_8                                ;#7BA8: 02
        NOTE NOTE_G, DURATION_8                                ;#7BA9: 07
        NOTE NOTE_E, DURATION_8                                ;#7BAA: 04
        NOTE NOTE_G, DURATION_8                                ;#7BAB: 07
        NOTE NOTE_D, DURATION_8                                ;#7BAC: 02
        NOTE NOTE_G, DURATION_8                                ;#7BAD: 07
        NOTE NOTE_E, DURATION_8                                ;#7BAE: 04
        NOTE NOTE_G, DURATION_8                                ;#7BAF: 07
        NOTE NOTE_D, DURATION_16                               ;#7BB0: 12
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7BB1: 06
        NOTE NOTE_HOLD, DURATION_8                             ;#7BB2: 0C
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7BB3: 06
        NOTE NOTE_HOLD, DURATION_8                             ;#7BB4: 0C
        NOTE NOTE_D, DURATION_16                               ;#7BB5: 12
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7BB6: 06
        NOTE NOTE_HOLD, DURATION_8                             ;#7BB7: 0C
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7BB8: 06
        NOTE NOTE_HOLD, DURATION_8                             ;#7BB9: 0C
        NOTE NOTE_D, DURATION_8                                ;#7BBA: 02
        NOTE NOTE_A, DURATION_8                                ;#7BBB: 09
        NOTE NOTE_E, DURATION_8                                ;#7BBC: 04
        NOTE NOTE_A, DURATION_8                                ;#7BBD: 09
        NOTE NOTE_D, DURATION_8                                ;#7BBE: 02
        NOTE NOTE_A, DURATION_8                                ;#7BBF: 09
        NOTE NOTE_E, DURATION_8                                ;#7BC0: 04
        NOTE NOTE_A, DURATION_8                                ;#7BC1: 09
        NOTE NOTE_D, DURATION_8                                ;#7BC2: 02
        NOTE NOTE_A, DURATION_8                                ;#7BC3: 09
        NOTE NOTE_E, DURATION_8                                ;#7BC4: 04
        NOTE NOTE_A, DURATION_8                                ;#7BC5: 09
        NOTE NOTE_D, DURATION_16                               ;#7BC6: 12
        NOTE NOTE_G, DURATION_8                                ;#7BC7: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7BC8: 0C
        NOTE NOTE_G, DURATION_8                                ;#7BC9: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7BCA: 0C
        NOTE NOTE_D, DURATION_16                               ;#7BCB: 12
        NOTE NOTE_G, DURATION_8                                ;#7BCC: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7BCD: 0C
        NOTE NOTE_G, DURATION_8                                ;#7BCE: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7BCF: 0C
        NOTE NOTE_D, DURATION_8                                ;#7BD0: 02
        NOTE NOTE_G, DURATION_8                                ;#7BD1: 07
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7BD2: 06
        NOTE NOTE_G, DURATION_8                                ;#7BD3: 07
        NOTE NOTE_D, DURATION_8                                ;#7BD4: 02
        NOTE NOTE_G, DURATION_8                                ;#7BD5: 07
        NOTE NOTE_D, DURATION_8                                ;#7BD6: 02
        NOTE NOTE_G, DURATION_8                                ;#7BD7: 07
        NOTE NOTE_F, DURATION_8                                ;#7BD8: 05
        NOTE NOTE_G, DURATION_8                                ;#7BD9: 07
        NOTE NOTE_D, DURATION_8                                ;#7BDA: 02
        NOTE NOTE_G, DURATION_8                                ;#7BDB: 07
        NOTE NOTE_C, DURATION_8                                ;#7BDC: 00
        NOTE NOTE_G, DURATION_8                                ;#7BDD: 07
        NOTE NOTE_E, DURATION_8                                ;#7BDE: 04
        NOTE NOTE_G, DURATION_8                                ;#7BDF: 07
        NOTE NOTE_C, DURATION_8                                ;#7BE0: 00
        NOTE NOTE_G, DURATION_8                                ;#7BE1: 07
        NOTE NOTE_C, DURATION_8                                ;#7BE2: 00
        NOTE NOTE_G, DURATION_8                                ;#7BE3: 07
        NOTE NOTE_D_SHARP, DURATION_8                          ;#7BE4: 03
        NOTE NOTE_G, DURATION_8                                ;#7BE5: 07
        NOTE NOTE_C, DURATION_8                                ;#7BE6: 00
        NOTE NOTE_G, DURATION_8                                ;#7BE7: 07
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BE8: FD 5A
        NOTE NOTE_B, DURATION_8                                ;#7BEA: 0B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7BEB: FD 59
        NOTE NOTE_G, DURATION_8                                ;#7BED: 07
        NOTE NOTE_D, DURATION_8                                ;#7BEE: 02
        NOTE NOTE_G, DURATION_8                                ;#7BEF: 07
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7BF0: FD 5A
        NOTE NOTE_B, DURATION_8                                ;#7BF2: 0B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7BF3: FD 59
        NOTE NOTE_G, DURATION_8                                ;#7BF5: 07
        NOTE NOTE_C, DURATION_8                                ;#7BF6: 00
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7BF7: 06
        NOTE NOTE_D, DURATION_8                                ;#7BF8: 02
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7BF9: 06
        NOTE NOTE_C, DURATION_8                                ;#7BFA: 00
        NOTE NOTE_F_SHARP, DURATION_8                          ;#7BFB: 06
        NOTE NOTE_G, DURATION_16                               ;#7BFC: 17
        NOTE NOTE_HOLD, DURATION_16                            ;#7BFD: 1C
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7BFE: 16
        NOTE NOTE_G, DURATION_16                               ;#7BFF: 17
        NOTE NOTE_HOLD, DURATION_32                            ;#7C00: 2C
        db      0FEh, 0FFh ; Repeat (FF=forever)               ;#7C01: FE FF

SOUND_DATA_MAIN_THEME_CH1:
        ; Data for Sound 11 (Main Theme CH1, Size: 214)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C03: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C05: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C06: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C08: 12
        NOTE NOTE_D, DURATION_16                               ;#7C09: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C0A: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C0C: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C0D: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C0F: 12
        NOTE NOTE_D, DURATION_16                               ;#7C10: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C11: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C13: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C14: FD 5A
        NOTE NOTE_C, DURATION_16                               ;#7C16: 10
        NOTE NOTE_C, DURATION_16                               ;#7C17: 10
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C18: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C1A: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C1B: FD 5A
        NOTE NOTE_C, DURATION_16                               ;#7C1D: 10
        NOTE NOTE_C, DURATION_16                               ;#7C1E: 10
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C1F: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C21: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C22: FD 5A
        NOTE NOTE_E, DURATION_16                               ;#7C24: 14
        NOTE NOTE_E, DURATION_16                               ;#7C25: 14
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C26: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C28: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C29: FD 5A
        NOTE NOTE_E, DURATION_16                               ;#7C2B: 14
        NOTE NOTE_E, DURATION_16                               ;#7C2C: 14
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C2D: FD 5B
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7C2F: 16
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C30: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C32: 12
        NOTE NOTE_D, DURATION_16                               ;#7C33: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C34: FD 5B
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7C36: 16
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C37: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C39: 12
        NOTE NOTE_D, DURATION_16                               ;#7C3A: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C3B: FD 5B
        NOTE NOTE_C, DURATION_16                               ;#7C3D: 10
        NOTE NOTE_A, DURATION_16                               ;#7C3E: 19
        NOTE NOTE_A, DURATION_16                               ;#7C3F: 19
        NOTE NOTE_G, DURATION_16                               ;#7C40: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C41: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C43: 12
        NOTE NOTE_D, DURATION_16                               ;#7C44: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C45: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C47: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C48: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C4A: 12
        NOTE NOTE_D, DURATION_16                               ;#7C4B: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C4C: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7C4E: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C4F: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C51: 12
        NOTE NOTE_D, DURATION_16                               ;#7C52: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C53: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C55: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C56: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C58: 12
        NOTE NOTE_D, DURATION_16                               ;#7C59: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C5A: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7C5C: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C5D: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C5F: 12
        NOTE NOTE_D, DURATION_16                               ;#7C60: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C61: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C63: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C64: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C66: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C67: FD 5B
        NOTE NOTE_B, DURATION_16                               ;#7C69: 1B
        NOTE NOTE_G, DURATION_32                               ;#7C6A: 27
        NOTE NOTE_HOLD, DURATION_16                            ;#7C6B: 1C
        NOTE NOTE_B, DURATION_16                               ;#7C6C: 1B
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C6D: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C6F: 12
        NOTE NOTE_D, DURATION_16                               ;#7C70: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C71: FD 5B
        NOTE NOTE_B, DURATION_16                               ;#7C73: 1B
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C74: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C76: 12
        NOTE NOTE_D, DURATION_16                               ;#7C77: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C78: FD 5B
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7C7A: 16
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C7B: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C7D: 12
        NOTE NOTE_D, DURATION_16                               ;#7C7E: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C7F: FD 5B
        NOTE NOTE_F_SHARP, DURATION_16                         ;#7C81: 16
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C82: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C84: 12
        NOTE NOTE_D, DURATION_16                               ;#7C85: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C86: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7C88: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C89: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C8B: 12
        NOTE NOTE_D, DURATION_16                               ;#7C8C: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C8D: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7C8F: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C90: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C92: 12
        NOTE NOTE_D, DURATION_16                               ;#7C93: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C94: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C96: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C97: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7C99: 12
        NOTE NOTE_D, DURATION_16                               ;#7C9A: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7C9B: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7C9D: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7C9E: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7CA0: 12
        NOTE NOTE_D, DURATION_16                               ;#7CA1: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7CA2: FD 5B
        NOTE NOTE_D, DURATION_16                               ;#7CA4: 12
        NOTE NOTE_G, DURATION_16                               ;#7CA5: 17
        NOTE NOTE_B, DURATION_16                               ;#7CA6: 1B
        NOTE NOTE_G, DURATION_16                               ;#7CA7: 17
        NOTE NOTE_B, DURATION_16                               ;#7CA8: 1B
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7CA9: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7CAB: 12
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7CAC: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7CAE: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7CAF: FD 5A
        NOTE NOTE_C, DURATION_16                               ;#7CB1: 10
        NOTE NOTE_E, DURATION_16                               ;#7CB2: 14
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7CB3: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7CB5: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7CB6: FD 5A
        NOTE NOTE_C, DURATION_16                               ;#7CB8: 10
        NOTE NOTE_E, DURATION_16                               ;#7CB9: 14
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7CBA: FD 5B
        NOTE NOTE_G, DURATION_16                               ;#7CBC: 17
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7CBD: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7CBF: 12
        NOTE NOTE_HOLD, DURATION_16                            ;#7CC0: 1C
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7CC1: FD 5B
        NOTE NOTE_A, DURATION_16                               ;#7CC3: 19
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7CC4: FD 5A
        NOTE NOTE_D, DURATION_16                               ;#7CC6: 12
        NOTE NOTE_HOLD, DURATION_16                            ;#7CC7: 1C
        NOTE NOTE_D, DURATION_16                               ;#7CC8: 12
        NOTE NOTE_HOLD, DURATION_16                            ;#7CC9: 1C
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7CCA: FD 5B
        NOTE NOTE_B, DURATION_16                               ;#7CCC: 1B
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7CCD: FD 5A
        NOTE NOTE_D, DURATION_8                                ;#7CCF: 02
        NOTE NOTE_C, DURATION_8                                ;#7CD0: 00
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7CD1: FD 5B
        NOTE NOTE_B, DURATION_8                                ;#7CD3: 0B
        NOTE NOTE_A, DURATION_8                                ;#7CD4: 09
        NOTE NOTE_G, DURATION_8                                ;#7CD5: 07
        NOTE NOTE_HOLD, DURATION_8                             ;#7CD6: 0C
        db      0FEh, 0FFh ; Repeat (FF=forever)               ;#7CD7: FE FF

SOUND_DATA_STAGE_CLEAR:
        ; Data for Sound 15 (Stage Clear CH0, Size: 29)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7CD9: FD 59
        NOTE NOTE_C, DURATION_20                               ;#7CDB: 90
        NOTE NOTE_C, DURATION_15                               ;#7CDC: 80
        NOTE NOTE_C, DURATION_5                                ;#7CDD: 60
        NOTE NOTE_C, DURATION_20                               ;#7CDE: 90
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7CDF: FD 5A
        NOTE NOTE_B, DURATION_15                               ;#7CE1: 8B
        NOTE NOTE_A, DURATION_5                                ;#7CE2: 69
        NOTE NOTE_G, DURATION_20                               ;#7CE3: 97
        NOTE NOTE_E, DURATION_20                               ;#7CE4: 94
        NOTE NOTE_G, DURATION_20                               ;#7CE5: 97
        NOTE NOTE_E, DURATION_20                               ;#7CE6: 94
        NOTE NOTE_D, DURATION_10                               ;#7CE7: 72
        NOTE NOTE_E, DURATION_10                               ;#7CE8: 74
        NOTE NOTE_F, DURATION_10                               ;#7CE9: 75
        NOTE NOTE_G, DURATION_10                               ;#7CEA: 77
        NOTE NOTE_A, DURATION_10                               ;#7CEB: 79
        NOTE NOTE_G, DURATION_10                               ;#7CEC: 77
        NOTE NOTE_A, DURATION_10                               ;#7CED: 79
        NOTE NOTE_B, DURATION_10                               ;#7CEE: 7B
        SET_OCTAVE_SUSTAIN 1, 0Ch                              ;#7CEF: FD 61
        NOTE NOTE_C, DURATION_20                               ;#7CF1: 90
        NOTE NOTE_C, DURATION_15                               ;#7CF2: 80
        NOTE NOTE_C, DURATION_5                                ;#7CF3: 60
        NOTE NOTE_C, DURATION_20                               ;#7CF4: 90
        db      0FFh                                           ;#7CF5: FF
        db      0FFh                                           ;#7CF6: FF

SOUND_DATA_STAGE_CLEAR_CH1:
        ; Data for Sound 16 (Stage Clear CH1, Size: 22)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7CF7: FD 5B
        NOTE NOTE_G, DURATION_20                               ;#7CF9: 97
        NOTE NOTE_G, DURATION_20                               ;#7CFA: 97
        NOTE NOTE_G, DURATION_20                               ;#7CFB: 97
        NOTE NOTE_HOLD, DURATION_20                            ;#7CFC: 9C
        NOTE NOTE_G, DURATION_20                               ;#7CFD: 97
        NOTE NOTE_G, DURATION_20                               ;#7CFE: 97
        NOTE NOTE_G, DURATION_20                               ;#7CFF: 97
        NOTE NOTE_HOLD, DURATION_20                            ;#7D00: 9C
        NOTE NOTE_F, DURATION_20                               ;#7D01: 95
        NOTE NOTE_D, DURATION_20                               ;#7D02: 92
        NOTE NOTE_G, DURATION_20                               ;#7D03: 97
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7D04: FD 5C
        NOTE NOTE_G, DURATION_20                               ;#7D06: 97
        SET_OCTAVE_SUSTAIN 3, 0Ch                              ;#7D07: FD 63
        NOTE NOTE_C, DURATION_20                               ;#7D09: 90
        NOTE NOTE_G, DURATION_20                               ;#7D0A: 97
        NOTE NOTE_G, DURATION_20                               ;#7D0B: 97
        db      0FFh                                           ;#7D0C: FF
        db      0FFh                                           ;#7D0D: FF

SOUND_DATA_STAGE_CLEAR_CH2:
        ; Data for Sound 17 (Stage Clear CH2, Size: 17)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7D0E: FD 5B
        NOTE NOTE_C, DURATION_20                               ;#7D10: 90
        NOTE NOTE_C, DURATION_20                               ;#7D11: 90
        NOTE NOTE_C, DURATION_20                               ;#7D12: 90
        NOTE NOTE_HOLD, DURATION_20                            ;#7D13: 9C
        NOTE NOTE_C, DURATION_20                               ;#7D14: 90
        NOTE NOTE_C, DURATION_20                               ;#7D15: 90
        NOTE NOTE_C, DURATION_20                               ;#7D16: 90
        NOTE NOTE_HOLD, DURATION_20                            ;#7D17: 9C
        NOTE NOTE_HOLD, DURATION_100                           ;#7D18: AC
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D19: FD 5A
        NOTE NOTE_E, DURATION_15                               ;#7D1B: 84
        NOTE NOTE_E, DURATION_5                                ;#7D1C: 64
        NOTE NOTE_E, DURATION_20                               ;#7D1D: 94
        db      0FFh                                           ;#7D1E: FF
        db      0FFh                                           ;#7D1F: FF

SOUND_DATA_JUMP:
        ; Data for Sound 2 (Jump, Size: 14)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 2                                         ;#7D20: 22
        SOUND 0Dh, 7Fh                                         ;#7D21: D0 7F
        SOUND 0Bh, 70h                                         ;#7D23: B0 70
        SOUND 0Bh, 77h                                         ;#7D25: B0 77
        SOUND 0Ah, 62h                                         ;#7D27: A0 62
        SOUND 9, 50h                                           ;#7D29: 90 50
        SOUND 8, 43h                                           ;#7D2B: 80 43
        db      0FFh                                           ;#7D2D: FF

SOUND_DATA_DISTANCE_WARNING:
        ; Data for Sound 9 (Distance < 1000m), Size: 24)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 3                                         ;#7D2E: 23
        SOUND 9, 60h                                           ;#7D2F: 90 60
        SOUND 9, 40h                                           ;#7D31: 90 40
        SOUND 9, 60h                                           ;#7D33: 90 60
        SOUND 9, 40h                                           ;#7D35: 90 40
        SOUND 9, 60h                                           ;#7D37: 90 60
        SOUND 9, 40h                                           ;#7D39: 90 40
        SOUND 9, 60h                                           ;#7D3B: 90 60
        SOUND 9, 40h                                           ;#7D3D: 90 40
        SOUND 9, 60h                                           ;#7D3F: 90 60
        SOUND 9, 40h                                           ;#7D41: 90 40
        SOUND 9, 60h                                           ;#7D43: 90 60
        db      0FFh                                           ;#7D45: FF

SOUND_DATA_TICK:
        ; Data for Sound 1 (Goal Tally Tick, Size: 6)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 1                                         ;#7D46: 21
        SOUND 0Ah, 25h                                         ;#7D47: A0 25
        SOUND 0Ah, 27h                                         ;#7D49: A0 27
        db      0FFh                                           ;#7D4B: FF

SOUND_DATA_STUN_DESCENDING:
        ; Data for Sound 7 (Descending Scale, Size: 18)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 1                                         ;#7D4C: 21
        SOUND 0Ch, 0DDh                                        ;#7D4D: C0 DD
        SOUND 0Ch, 0BBh                                        ;#7D4F: C0 BB
        SOUND 0Bh, 0AAh                                        ;#7D51: B0 AA
        SOUND 0Bh, 99h                                         ;#7D53: B0 99
        SOUND 0Ah, 88h                                         ;#7D55: A0 88
        SOUND 0Ah, 77h                                         ;#7D57: A0 77
        SOUND 9, 66h                                           ;#7D59: 90 66
        SOUND 9, 55h                                           ;#7D5B: 90 55
        db      0FFh                                           ;#7D5D: FF

SOUND_DATA_STAGE_START:
        ; Data for Sound 6 (Stage Start Jingle, Size: 12)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 2                                         ;#7D5E: 22
        SOUND 0Ch, 55h                                         ;#7D5F: C0 55
        SOUND 0Ch, 66h                                         ;#7D61: C0 66
        SOUND 0Ch, 55h                                         ;#7D63: C0 55
        SOUND 0Bh, 44h                                         ;#7D65: B0 44
        SOUND 0Ah, 33h                                         ;#7D67: A0 33
        db      0FFh                                           ;#7D69: FF

SOUND_DATA_FALL_HOLE:
        ; Data for Sound 5 (Fall in Hole, Size: 20)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 2                                         ;#7D6A: 22
        SOUND 0Eh, 0A5h                                        ;#7D6B: E0 A5
        SOUND 0Ch, 0B5h                                        ;#7D6D: C0 B5
        SOUND 0Ah, 0C5h                                        ;#7D6F: A0 C5
        SOUND 9, 0D5h                                          ;#7D71: 90 D5
        SOUND 8, 0E5h                                          ;#7D73: 80 E5
        SOUND 7, 0F5h                                          ;#7D75: 70 F5
        SOUND 6, 105h                                          ;#7D77: 61 05
        SOUND 5, 125h                                          ;#7D79: 51 25
        SOUND 5, 145h                                          ;#7D7B: 51 45
        db      0FFh                                           ;#7D7D: FF

SOUND_DATA_OBSTACLE:
        ; Data for Sound 3 (Hit Obstacle, Size: 8)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 1                                         ;#7D7E: 21
        SOUND 0Ch, 103h                                        ;#7D7F: C1 03
        SOUND 0Ch, 10Dh                                        ;#7D81: C1 0D
        SOUND 0Ch, 106h                                        ;#7D83: C1 06
        db      0FFh                                           ;#7D85: FF

SOUND_DATA_CATCH:
        ; Data for Sound 4 (Catch Fish/Flag, Size: 8)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 1                                         ;#7D86: 21
        SOUND 0Ch, 143h                                        ;#7D87: C1 43
        SOUND 0Ch, 14Dh                                        ;#7D89: C1 4D
        SOUND 0Ch, 146h                                        ;#7D8B: C1 46
        db      0FFh                                           ;#7D8D: FF

SOUND_DATA_INTRO_MUSIC:
        ; Data for Sound 18 (Demo BGM CH0, Size: 50)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D8E: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7D90: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7D91: FD 59
        NOTE NOTE_D, DURATION_10                               ;#7D93: 72
        NOTE NOTE_E, DURATION_10                               ;#7D94: 74
        NOTE NOTE_D, DURATION_10                               ;#7D95: 72
        NOTE NOTE_G, DURATION_20                               ;#7D96: 97
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7D97: 76
        NOTE NOTE_E, DURATION_10                               ;#7D98: 74
        NOTE NOTE_D, DURATION_30                               ;#7D99: B2
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7D9A: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7D9C: 7B
        NOTE NOTE_G, DURATION_20                               ;#7D9D: 97
        NOTE NOTE_G, DURATION_5                                ;#7D9E: 67
        NOTE NOTE_A, DURATION_5                                ;#7D9F: 69
        NOTE NOTE_B, DURATION_5                                ;#7DA0: 6B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DA1: FD 59
        NOTE NOTE_C, DURATION_5                                ;#7DA3: 60
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DA4: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7DA6: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DA7: FD 59
        NOTE NOTE_D, DURATION_10                               ;#7DA9: 72
        NOTE NOTE_E, DURATION_10                               ;#7DAA: 74
        NOTE NOTE_D, DURATION_10                               ;#7DAB: 72
        NOTE NOTE_G, DURATION_20                               ;#7DAC: 97
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7DAD: 76
        NOTE NOTE_E, DURATION_10                               ;#7DAE: 74
        NOTE NOTE_D, DURATION_5                                ;#7DAF: 62
        NOTE NOTE_E, DURATION_5                                ;#7DB0: 64
        NOTE NOTE_D, DURATION_5                                ;#7DB1: 62
        NOTE NOTE_C, DURATION_5                                ;#7DB2: 60
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DB3: FD 5A
        NOTE NOTE_B, DURATION_5                                ;#7DB5: 6B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DB6: FD 59
        NOTE NOTE_C, DURATION_5                                ;#7DB8: 60
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DB9: FD 5A
        NOTE NOTE_B, DURATION_5                                ;#7DBB: 6B
        NOTE NOTE_A, DURATION_5                                ;#7DBC: 69
        NOTE NOTE_G, DURATION_20                               ;#7DBD: 97
        NOTE NOTE_HOLD, DURATION_20                            ;#7DBE: 9C
        db      0FFh                                           ;#7DBF: FF

SOUND_DATA_INTRO_MUSIC_CH1:
        ; Data for Sound 19 (Demo BGM CH1, Size: 51)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DC0: FD 5A
        NOTE NOTE_G, DURATION_10                               ;#7DC2: 77
        NOTE NOTE_B, DURATION_10                               ;#7DC3: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DC4: FD 59
        NOTE NOTE_C, DURATION_10                               ;#7DC6: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DC7: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7DC9: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DCA: FD 59
        NOTE NOTE_D, DURATION_20                               ;#7DCC: 92
        NOTE NOTE_C, DURATION_10                               ;#7DCD: 70
        NOTE NOTE_C, DURATION_10                               ;#7DCE: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DCF: FD 5A
        NOTE NOTE_B, DURATION_30                               ;#7DD1: BB
        NOTE NOTE_G, DURATION_10                               ;#7DD2: 77
        NOTE NOTE_D, DURATION_20                               ;#7DD3: 92
        NOTE NOTE_HOLD, DURATION_20                            ;#7DD4: 9C
        NOTE NOTE_G, DURATION_10                               ;#7DD5: 77
        NOTE NOTE_B, DURATION_10                               ;#7DD6: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DD7: FD 59
        NOTE NOTE_C, DURATION_10                               ;#7DD9: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DDA: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7DDC: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DDD: FD 59
        NOTE NOTE_D, DURATION_20                               ;#7DDF: 92
        NOTE NOTE_C, DURATION_10                               ;#7DE0: 70
        NOTE NOTE_C, DURATION_10                               ;#7DE1: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DE2: FD 5A
        NOTE NOTE_B, DURATION_5                                ;#7DE4: 6B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7DE5: FD 59
        NOTE NOTE_C, DURATION_5                                ;#7DE7: 60
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7DE8: FD 5A
        NOTE NOTE_B, DURATION_5                                ;#7DEA: 6B
        NOTE NOTE_A, DURATION_5                                ;#7DEB: 69
        NOTE NOTE_G, DURATION_5                                ;#7DEC: 67
        NOTE NOTE_A, DURATION_5                                ;#7DED: 69
        NOTE NOTE_G, DURATION_5                                ;#7DEE: 67
        NOTE NOTE_F_SHARP, DURATION_5                          ;#7DEF: 66
        NOTE NOTE_D, DURATION_20                               ;#7DF0: 92
        NOTE NOTE_HOLD, DURATION_20                            ;#7DF1: 9C
        db      0FFh                                           ;#7DF2: FF

SOUND_DATA_INTRO_MUSIC_CH2:
        ; Data for Sound 20 (Demo BGM CH2, Size: 47)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7DF3: FD 5B
        NOTE NOTE_G, DURATION_10                               ;#7DF5: 77
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7DF6: 76
        NOTE NOTE_E, DURATION_10                               ;#7DF7: 74
        NOTE NOTE_D, DURATION_10                               ;#7DF8: 72
        NOTE NOTE_C, DURATION_10                               ;#7DF9: 70
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7DFA: FD 5C
        NOTE NOTE_B, DURATION_10                               ;#7DFC: 7B
        NOTE NOTE_A, DURATION_10                               ;#7DFD: 79
        NOTE NOTE_G, DURATION_10                               ;#7DFE: 77
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7DFF: FD 5B
        NOTE NOTE_G, DURATION_10                               ;#7E01: 77
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7E02: 76
        NOTE NOTE_E, DURATION_10                               ;#7E03: 74
        NOTE NOTE_D, DURATION_10                               ;#7E04: 72
        NOTE NOTE_C, DURATION_10                               ;#7E05: 70
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7E06: FD 5C
        NOTE NOTE_B, DURATION_10                               ;#7E08: 7B
        NOTE NOTE_A, DURATION_10                               ;#7E09: 79
        NOTE NOTE_G, DURATION_10                               ;#7E0A: 77
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7E0B: FD 5B
        NOTE NOTE_G, DURATION_10                               ;#7E0D: 77
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7E0E: 76
        NOTE NOTE_E, DURATION_10                               ;#7E0F: 74
        NOTE NOTE_D, DURATION_10                               ;#7E10: 72
        NOTE NOTE_C, DURATION_10                               ;#7E11: 70
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7E12: FD 5C
        NOTE NOTE_B, DURATION_10                               ;#7E14: 7B
        NOTE NOTE_A, DURATION_10                               ;#7E15: 79
        NOTE NOTE_G, DURATION_10                               ;#7E16: 77
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7E17: FD 5B
        NOTE NOTE_D, DURATION_10                               ;#7E19: 72
        SET_OCTAVE_SUSTAIN 4, 0Bh                              ;#7E1A: FD 5C
        NOTE NOTE_D, DURATION_10                               ;#7E1C: 72
        NOTE NOTE_E, DURATION_10                               ;#7E1D: 74
        NOTE NOTE_F_SHARP, DURATION_10                         ;#7E1E: 76
        NOTE NOTE_G, DURATION_10                               ;#7E1F: 77
        NOTE NOTE_HOLD, DURATION_20                            ;#7E20: 9C
        db      0FFh                                           ;#7E21: FF

SOUND_DATA_TIME_OUT:
        ; Data for Sound 12 (Time Out CH0, Size: 29)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7E22: FD 59
        NOTE NOTE_E, DURATION_20                               ;#7E24: 94
        NOTE NOTE_E, DURATION_10                               ;#7E25: 74
        NOTE NOTE_E, DURATION_10                               ;#7E26: 74
        NOTE NOTE_E, DURATION_20                               ;#7E27: 94
        NOTE NOTE_D, DURATION_10                               ;#7E28: 72
        NOTE NOTE_C, DURATION_10                               ;#7E29: 70
        NOTE NOTE_F, DURATION_30                               ;#7E2A: B5
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7E2B: FD 5A
        NOTE NOTE_F, DURATION_10                               ;#7E2D: 75
        NOTE NOTE_F, DURATION_30                               ;#7E2E: B5
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7E2F: FD 59
        NOTE NOTE_F, DURATION_10                               ;#7E31: 75
        NOTE NOTE_E, DURATION_20                               ;#7E32: 94
        NOTE NOTE_C, DURATION_10                               ;#7E33: 70
        NOTE NOTE_E, DURATION_10                               ;#7E34: 74
        NOTE NOTE_D, DURATION_20                               ;#7E35: 92
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7E36: FD 5A
        NOTE NOTE_A, DURATION_10                               ;#7E38: 79
        NOTE NOTE_B, DURATION_10                               ;#7E39: 7B
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7E3A: FD 59
        NOTE NOTE_C, DURATION_60                               ;#7E3C: D0
        NOTE NOTE_HOLD, DURATION_16                            ;#7E3D: 1C
        db      0FFh                                           ;#7E3E: FF

SOUND_DATA_TIME_OUT_CH1:
        ; Data for Sound 13 (Time Out CH1, Size: 35)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7E3F: FD 5B
        NOTE NOTE_C, DURATION_20                               ;#7E41: 90
        NOTE NOTE_C, DURATION_10                               ;#7E42: 70
        NOTE NOTE_C, DURATION_10                               ;#7E43: 70
        NOTE NOTE_C, DURATION_20                               ;#7E44: 90
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7E45: FD 5A
        NOTE NOTE_B, DURATION_10                               ;#7E47: 7B
        NOTE NOTE_G, DURATION_10                               ;#7E48: 77
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7E49: FD 59
        NOTE NOTE_C, DURATION_30                               ;#7E4B: B0
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7E4C: FD 5A
        NOTE NOTE_C, DURATION_10                               ;#7E4E: 70
        NOTE NOTE_C, DURATION_30                               ;#7E4F: B0
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7E50: FD 59
        NOTE NOTE_C, DURATION_10                               ;#7E52: 70
        NOTE NOTE_C, DURATION_20                               ;#7E53: 90
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7E54: FD 5A
        NOTE NOTE_G, DURATION_10                               ;#7E56: 77
        SET_OCTAVE_SUSTAIN 1, 0Bh                              ;#7E57: FD 59
        NOTE NOTE_C, DURATION_10                               ;#7E59: 70
        SET_OCTAVE_SUSTAIN 2, 0Bh                              ;#7E5A: FD 5A
        NOTE NOTE_B, DURATION_20                               ;#7E5C: 9B
        NOTE NOTE_F, DURATION_10                               ;#7E5D: 75
        NOTE NOTE_G, DURATION_10                               ;#7E5E: 77
        NOTE NOTE_G, DURATION_60                               ;#7E5F: D7
        NOTE NOTE_HOLD, DURATION_16                            ;#7E60: 1C
        db      0FFh                                           ;#7E61: FF

SOUND_DATA_TIME_OUT_CH2:
        ; Data for Sound 14 (Time Out CH2, Size: 19)
        ; Format: FORMAT_SOUND_MUSIC
        ; - 0FDh <param>: Set octave (param & 7) and sustain (param >> 3).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: Note byte (hi nibble = duration index, lo nibble = pitch index).
        ; Pitch index >= 0Ch is treated as a special/rest variant.
        SET_OCTAVE_SUSTAIN 3, 0Bh                              ;#7E62: FD 5B
        NOTE NOTE_G, DURATION_20                               ;#7E64: 97
        NOTE NOTE_E, DURATION_20                               ;#7E65: 94
        NOTE NOTE_G, DURATION_20                               ;#7E66: 97
        NOTE NOTE_E, DURATION_20                               ;#7E67: 94
        NOTE NOTE_A, DURATION_20                               ;#7E68: 99
        NOTE NOTE_F, DURATION_20                               ;#7E69: 95
        NOTE NOTE_A, DURATION_20                               ;#7E6A: 99
        NOTE NOTE_F, DURATION_20                               ;#7E6B: 95
        NOTE NOTE_G, DURATION_20                               ;#7E6C: 97
        NOTE NOTE_E, DURATION_20                               ;#7E6D: 94
        NOTE NOTE_G, DURATION_20                               ;#7E6E: 97
        NOTE NOTE_F, DURATION_20                               ;#7E6F: 95
        NOTE NOTE_G, DURATION_20                               ;#7E70: 97
        NOTE NOTE_G, DURATION_20                               ;#7E71: 97
        NOTE NOTE_G, DURATION_20                               ;#7E72: 97
        NOTE NOTE_HOLD, DURATION_20                            ;#7E73: 9C
        db      0FFh                                           ;#7E74: FF

SOUND_DATA_STUMBLE:
        ; Data for Sound 8 (Stumble/Seal Bump, Size: 24)
        ; Format: FORMAT_SOUND_SFX
        ; - 20h-2Fh: Set base duration (low nibble).
        ; - 0FEh <count>: Repeat track. 0FFh repeats forever.
        ; - 0FFh: End of stream.
        ; - Otherwise: 2-byte tone entry.
        ; Byte 0: volume (hi nibble) + period high nibble (lo nibble).
        ; Byte 1: period low byte.
        SET_DURATION 2                                         ;#7E75: 22
        SOUND 0Dh, 1EEh                                        ;#7E76: D1 EE
        SOUND 0Dh, 1CCh                                        ;#7E78: D1 CC
        SOUND 0Ch, 1EEh                                        ;#7E7A: C1 EE
        SOUND 0Bh, 1FFh                                        ;#7E7C: B1 FF
        SOUND 0Ah, 199h                                        ;#7E7E: A1 99
        SOUND 9, 188h                                          ;#7E80: 91 88
        SOUND 8, 177h                                          ;#7E82: 81 77
        SOUND 7, 166h                                          ;#7E84: 71 66
        SOUND 6, 177h                                          ;#7E86: 61 77
        SOUND 5, 188h                                          ;#7E88: 51 88
        SOUND 4, 199h                                          ;#7E8A: 41 99
        db      0FFh                                           ;#7E8C: FF

PADDING:
        ; ROM padding to 16KB boundary
        defs    348, 0FFh                                      ;#7E8D

MYSTERY_DATA:
        ; Unknown data in unknown encoding. Easter egg?
        db      0ACh, 88h, 82h, 0B7h                           ;#7FE9: AC 88 82 B7
        db      9Dh, 81h, 0B7h, 8Fh                            ;#7FED: 9D 81 B7 8F
        db      0, 87h, 0B3h, 86h                              ;#7FF1: 00 87 B3 86
        db      0ACh, 94h, 0, 87h                              ;#7FF5: AC 94 00 87
        db      0B3h, 86h, 0B5h, 88h                           ;#7FF9: B3 86 B5 88
        db      14h, 1, 0AAh                                   ;#7FFD: 14 01 AA
