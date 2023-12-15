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

uint32_t Switchs_read(void)
{
        uint32_t switches = PIO0_REG(SWICH_REG) & SWITCHS_MASK;
        return switches;
}

void Leds_write(uint32_t value)
{
        uint32_t value_to_copy = PIO0_REG(LED_REG) & LED_MASK;
        PIO0_REG(LED_REG) = value | value_to_copy;
}

void Leds_set(uint32_t maskleds)
{

        PIO0_REG(LED_REG) = maskleds;
}

void Leds_clear(uint32_t maskleds)
{
        uint32_t leds_value = PIO0_REG(LED_REG) & LED_MASK;
        PIO0_REG(LED_REG) = maskleds & ~leds_value;
}

bool Key_read(int key_number)
{
        return (PIO0_REG(KEY_REG) & (1 << key_number));
}
