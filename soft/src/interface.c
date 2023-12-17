#include <stdint.h>
#include <stdbool.h>
#include "interface.h"

uint32_t Switchs_read(void)
{
        uint32_t switches = PIO0_REG(SWICH_REG) & SWITCHS_MASK;
        return switches;
}

void Leds_set(uint32_t maskleds)
{

        PIO0_REG(LED_REG) = maskleds;
}

bool Key_read(int key_number)
{
        return (PIO0_REG(KEY_REG) & (1 << key_number));
}
