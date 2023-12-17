#include <stdint.h>
#include <stdbool.h>
#include "axi_lw.h"

// Base address
#define PIO_CORE0_BASE_ADD (AXI_LW_HPS_FPGA_BASE_ADD + 0x10000)

#define PIO0_ADDR *(volatile uint32_t *)PIO_CORE0_BASE_ADD

// ACCESS MACROS
#define PIO0_REG(_x_) *(volatile uint32_t *)((PIO_CORE0_BASE_ADD + _x_))

// switchs
#define SWICH_REG 0x8
#define SWITCHS_MASK 0x3FF

// leds
#define LED_REG 0xC
#define LED_MASK 0x3FF

// keys
#define KEY_REG 0x4
#define KEY_MASK 0xF
#define KEY0 0x1 << 0x0
#define KEY1 0x1 << 0x1
#define KEY2 0x1 << 0x2
#define KEY3 0x1 << 0x3

//***********************************//
//****** Global usage function ******//

// Switchs_read function : Read the switchs value
// Parameter : None
// Return : Value of all Switchs (SW9 to SW0)
uint32_t Switchs_read(void);


// Leds_set function : Set to ON some or all Leds (LED9 to LED0)
// Parameter : "maskleds"= Leds selected to apply a set (maximum 0x3FF)
// Return : None
void Leds_set(uint32_t maskleds);


// Key_read function : Read one Key status, pressed or not (KEY0 or KEY1 or KEY2 or KEY3)
// Parameter : "key_number"= select the key number to read, from 0 to 3
// Return : True(1) if key is pressed, and False(0) if key is not pressed
bool Key_read(int key_number);


//***********************************//

