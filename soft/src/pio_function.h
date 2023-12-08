/*****************************************************************************************
 * HEIG-VD
 * Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
 * School of Business and Engineering in Canton de Vaud
 *****************************************************************************************
 * REDS Institute
 * Reconfigurable Embedded Digital Systems
 *****************************************************************************************
 *
 * File                 : pio_function.h
 * Author               : Anthony Convers
 * Date                 : 27.07.2022
 *
 * Context              : ARE lab
 *
 *****************************************************************************************
 * Brief: Header file for pio function
 *
 *****************************************************************************************
 * Modifications :
 * Ver    Date        Student      Comments
 * 0.0    27.07.2022  ACS           Initial version.
 * 1.0    6.10.2023   CCO           Labo 2
 * 1.1    17.10.2023  CCO           Labo 2 - correction
 *****************************************************************************************/
#include <stdint.h>
#include <stdbool.h>
#include "axi_lw.h"

// Base address
#define PIO_CORE0_BASE_ADD (AXI_LW_HPS_FPGA_BASE_ADD + 0x100)
#define PIO_CORE1_BASE_ADD (AXI_LW_HPS_FPGA_BASE_ADD + 0x120)

#define PIO0_ADDR *(volatile uint32_t *)PIO_CORE0_BASE_ADD
#define PIO1_ADDR *(volatile uint32_t *)PIO_CORE1_BASE_ADD

// ACCESS MACROS
#define PIO0_REG(_x_) *(volatile uint32_t *)(PIO_CORE0_BASE_ADD + _x_)
#define PIO1_REG(_x_) *(volatile uint32_t *)(PIO_CORE1_BASE_ADD + _x_)

// direction reg for PIO
#define DIR_ADDR_OFFSET 0x4 // 0 = input 1 = output
// out set reg for PIO
#define SET_ADDR_OFFSET 0x10 
// out clear reg for PIO
#define CLR_ADDR_OFFSET 0x14

// switchs
#define SWITCHS_BITS 0x000003FF
#define SWICH_REG 0x8
#define SWITCHS_MASK 0x3FF

// leds
#define LEDS_BITS 0x000FFc00
#define LED_REG 0xC
#define LED_MASK 0x3FF

// keys
#define KEYS_BITS 0x01D00000
#define KEY_REG 0x4
#define KEY_MASK 0xF
#define KEY0 0x1 << 0x14
#define KEY1 0x1 << 0x15
#define KEY2 0x1 << 0x16
#define KEY3 0x1 << 0x17

// 7-segments
#define SEG7_BITS 0x0FFFFFFF
#define SEG7_VALUE 0x7F
#define SEG7_REG_OFFSET 0x7
#define SEG7_0_REG 0x0
#define SEG7_1_REG SEG7_0_REG << SEG7_REG_OFFSET 
#define SEG7_2_REG SEG7_1_REG << SEG7_REG_OFFSET
#define SEG7_3_REG SEG7_2_REG << SEG7_REG_OFFSET

#define SEG7_0_BITS ((1 << SEG7_REG_OFFSET) - 1)
#define SEG7_1_BITS (SEG7_0_BITS << SEG7_REG_OFFSET)
#define SEG7_2_BITS (SEG7_1_BITS << SEG7_REG_OFFSET)
#define SEG7_3_BITS (SEG7_2_BITS << SEG7_REG_OFFSET)


//***************************//
//****** Init function ******//

// Swicths_init function : Initialize all Switchs in PIO core (SW9 to SW0)
void Switchs_init(void);

// Leds_init function : Initialize all Leds in PIO core (LED9 to LED0)
void Leds_init(void);

// Keys_init function : Initialize all Keys in PIO core (KEY3 to KEY0)
void Keys_init(void);

// Segs7_init function : Initialize all 7-segments display in PIO core (HEX3 to HEX0)
void Segs7_init(void);

//***********************************//
//****** Global usage function ******//

// Switchs_read function : Read the switchs value
// Parameter : None
// Return : Value of all Switchs (SW9 to SW0)
uint32_t Switchs_read(void);

// Leds_write function : Write a value to all Leds (LED9 to LED0)
// Parameter : "value"= data to be applied to all Leds
// Return : None
void Leds_write(uint32_t value);

// Leds_set function : Set to ON some or all Leds (LED9 to LED0)
// Parameter : "maskleds"= Leds selected to apply a set (maximum 0x3FF)
// Return : None
void Leds_set(uint32_t maskleds);

// Leds_clear function : Clear to OFF some or all Leds (LED9 to LED0)
// Parameter : "maskleds"= Leds selected to apply a clear (maximum 0x3FF)
// Return : None
void Leds_clear(uint32_t maskleds);

// Leds_toggle function : Toggle the curent value of some or all Leds (LED9 to LED0)
// Parameter : "maskleds"= Leds selected to apply a toggle (maximum 0x3FF)
// Return : None
void Leds_toggle(uint32_t maskleds);

// Key_read function : Read one Key status, pressed or not (KEY0 or KEY1 or KEY2 or KEY3)
// Parameter : "key_number"= select the key number to read, from 0 to 3
// Return : True(1) if key is pressed, and False(0) if key is not pressed
bool Key_read(int key_number);

// Seg7_write function : Write digit segment value to one 7-segments display (HEX0 or HEX1 or HEX2 or HEX3)
// Parameter : "seg7_number"= select the 7-segments number, from 0 to 3
// Parameter : "value"= digit segment value to be applied on the selected 7-segments (maximum 0x7F to switch ON all segments)
// Return : None
void Seg7_write(int seg7_number, uint32_t value);

// Seg7_write_hex function : Write an Hexadecimal value to one 7-segments display (HEX0 or HEX1 or HEX2 or HEX3)
// Parameter : "seg7_number"= select the 7-segments number, from 0 to 3
// Parameter : "value"= Hexadecimal value to be display on the selected 7-segments, form 0x0 to 0xF
// Return : None
void Seg7_write_hex(int seg7_number, uint32_t value);

//***********************************//

