/*****************************************************************************************
 * HEIG-VD
 * Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
 * School of Business and Engineering in Canton de Vaud
 *****************************************************************************************
 * REDS Institute
 * Reconfigurable Embedded Digital Systems
 *****************************************************************************************
 *
 * File                 : pio_function.c
 * Author               :
 * Date                 :
 *
 * Context              : ARE lab
 *
 *****************************************************************************************
 * Brief: Pio function
 *
 *****************************************************************************************
 * Modifications :
 * Ver    Date        Student      Comments
 * 1.0    6.10.2023   CCO          Labo 2
 * 1.1    17.10.2023  CCO          Labo 2 - correction
 *****************************************************************************************/
#include <stdint.h>
#include <stdbool.h>
#include "pio_function.h"
#include "7seg_alphanum.h"

void Switchs_init(void)
{
        PIO0_REG(DIR_ADDR_OFFSET) &= ~SWITCHS_BITS;
}

void Leds_init(void)
{
        PIO0_REG(DIR_ADDR_OFFSET) |= LEDS_BITS;
}

void Keys_init(void)
{
        PIO0_REG(DIR_ADDR_OFFSET) &= ~KEYS_BITS;
}

void Segs7_init(void)
{
        PIO1_REG(DIR_ADDR_OFFSET) |= SEG7_BITS;
        PIO1_REG(SET_ADDR_OFFSET) |= SEG7_BITS;
}

uint32_t Switchs_read(void)
{
        uint32_t switches = PIO0_ADDR & SWITCHS_BITS;
        return switches;
}

void Leds_write(uint32_t value)
{
        uint32_t value_to_copy = PIO0_ADDR & ~LEDS_BITS;
        PIO0_REG(SET_ADDR_OFFSET) = (value << LED_REG) | value_to_copy;
}

void Leds_set(uint32_t maskleds)
{
	PIO0_REG(CLR_ADDR_OFFSET) = LEDS_BITS;
        PIO0_REG(SET_ADDR_OFFSET) = maskleds << LED_REG;
}

void Leds_clear(uint32_t maskleds)
{
    PIO0_REG(CLR_ADDR_OFFSET) = maskleds << LED_REG;
}


void Leds_toggle(uint32_t maskleds)
{
	uint32_t leds_value = PIO0_ADDR & LEDS_BITS;
        PIO0_REG(CLR_ADDR_OFFSET) = leds_value & (maskleds << LED_REG);
        PIO0_REG(SET_ADDR_OFFSET) = ~leds_value & (maskleds << LED_REG);
}

bool Key_read(int key_number)
{
        return (PIO0_ADDR & (1 << (key_number + KEY_REG)));
}

void Seg7_write(int seg7_number, uint32_t value)
{
        PIO1_REG(SET_ADDR_OFFSET) = SEG7_VALUE <<(seg7_number * SEG7_REG_OFFSET);
        PIO1_REG(CLR_ADDR_OFFSET) = value << (seg7_number * SEG7_REG_OFFSET);
}

void Seg7_write_hex(int seg7_number, uint32_t value)
{
        Seg7_write(seg7_number, hexa[value]);
}
