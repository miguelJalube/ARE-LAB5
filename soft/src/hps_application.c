/*****************************************************************************************
 * HEIG-VD
 * Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
 * School of Business and Engineering in Canton de Vaud
 *****************************************************************************************
 * REDS Institute
 * Reconfigurable Embedded Digital Systems
 *****************************************************************************************
 *
 * File                 : hps_application.c
 * Author               :
 * Date                 :
 *
 * Context              : ARE lab
 *
 *****************************************************************************************
 * Brief: Conception d'une interface évoluée sur le bus Avalon avec la carte DE1-SoC
 *
 *****************************************************************************************
 * Modifications :
 * Ver    Date        Student      Comments
 * 1.0    8.12.2023   CCO JML      first version of lab 5 application
 *
 *****************************************************************************************/
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include "axi_lw.h"
#include "pio_function.h"

int __auto_semihosting;

/* Used key's */
static uint8_t key0_pressed = 0;
static uint8_t key1_pressed = 0;

static bool mode = false; // 0 is manual 1 is automatic
static uint8_t speed = 0;
static bool acquisition_mode = 0; // 0 is not reliable 1 is reliable

static uint32_t nbrs[4];

#define Na 0x20
#define Nb 0x24
#define Nc 0x28
#define Nd 0x2C

#define NB_BITS_MASK 0x3FFFFF
#define NB_BITS_CODE_MASK 0xC00000

#define INIT_GEN_REG 0x10
#define GEN_BIT 0x10
#define RESET_BIT 0x01

#define MODE_DELAY_REG 0x14

/* controle reg for nbr generation */
#define nbr_gen_reg 0x18
/* cmd_init_i */
#define reset_to_zero 0x0000
/* cmd_new_nbr_i */
#define new_nbr 0x0000

/* acquisition mode reg */
#define acquisition_mode_reg 0x1C

/**
 * @brief Select mode based on switches
 *
 * @param switches
 * @return true if automatic mode
 */
bool mode_select(uint32_t switches)
{
    return (switches >> 7) & 0x1;
}

/**
 * @brief Select speed based on switches
 *
 * @param switches
 * @return speed
 */
uint8_t speed_select(uint32_t switches)
{
    return switches >> 8;
}

/**
 * @brief Select acquisition mode based on switches
 *
 * @param switches
 * @return true if reliable
 */
bool acquisition_mode_select(uint32_t switches)
{
    return switches & 0x1;
}

/**
 * @brief Set mode and speed
 *
 * @param mode
 * @param speed
 */
void mode_set(bool mode, uint8_t speed)
{
    PIO0_REG(MODE_DELAY_REG) = (mode << 5) | speed;
}

/**
 * @brief Get status
 *
 * @return status
 */
uint8_t get_status()
{
    return PIO0_REG(INIT_GEN_REG) ;
}

int main(void)
{

    /* display ID on console */
    printf("ID: %lx\n", AXI_LW_REG(0));

    /* display our ID */
    printf("ID: %lx\n", PIO0_ADDR);

    /* Set Default values on LEDS and hex display */
    Leds_set(0x0);

    /* set our base mode based on switches */

    uint32_t switches;
    uint32_t status;
    uint32_t errors = 0;

    while (true)
    {

        switches = Switchs_read();

        /* leds copy switches */
        Leds_set(switches);

        /* get mode, speed and acquisition mode */
        mode = mode_select(switches);
        /* speed is switches 8 and 9 */
        speed = speed_select(switches);
        /* acquisition mode is switches 0 */
        acquisition_mode = acquisition_mode_select(switches);
        /* set mode */
        mode_set(mode, speed);

        /* Set all numbers to 0 */
        if ((Key_read(0) == 0) && key0_pressed == 1)
        {
            PIO0_REG(INIT_GEN_REG) = RESET_BIT;
            key0_pressed = 0;
        }

        /* in manual mode generate 4 new numbers */
        if (!mode && (Key_read(1) == 0) && key1_pressed == 1)
        {
            PIO0_REG(INIT_GEN_REG) = GEN_BIT;
            key1_pressed = 0;
            PIO0_REG(INIT_GEN_REG) = 0x0;
        }

        /* check if the load key is pressed */
        if ((Key_read(2) == 0))
        {
            /* set reliable acquisition mode ask for a picture of the system */
            if (acquisition_mode)
                PIO0_REG(acquisition_mode_reg) = 0x1;

            /* get the numbers */

            /*
             * we could use a for loop to read N numbers using numbers offset instead of addresses if they are contigous in memory
             for (int i = 0; i < N; i++)
                nbrs[i] = AXI_LW_REG(Na + i * 4) && NB_BITS_MASK;
            */

            nbrs[0] = PIO0_REG(Na) & NB_BITS_MASK;
            nbrs[1] = PIO0_REG(Nb) & NB_BITS_MASK;
            nbrs[2] = PIO0_REG(Nc) & NB_BITS_MASK;

            /* Nd is the sum */
            nbrs[3] = PIO0_REG(Nd) & NB_BITS_MASK;

            status = get_status();

            if (acquisition_mode)
                PIO0_REG(acquisition_mode_reg) = 0x0;

            /* compare the numbers */
            if (nbrs[3] != nbrs[0] + nbrs[1] + nbrs[2])
            {
                printf("ER : status: %ld, somme: %ld, nbr_a: %ld, nbr_b: %ld, nbr_c: %ld, nbr_d: %ld\n", status, nbrs[3], nbrs[0], nbrs[1], nbrs[2], nbrs[3]);
                printf("ER : nombre d'erreur cumulées: %ld\n", ++errors);
            }
            else
            {
                printf("OK : status: %ld, somme: %ld, nbr_a: %ld, nbr_b: %ld, nbr_c: %ld, nbr_d: %ld\n", status, nbrs[3], nbrs[0], nbrs[1], nbrs[2], nbrs[3]);
            }
        }

        /* check if the keys are pressed */
        if (Key_read(0) == 1)
            key0_pressed = 1;
        if (Key_read(1) == 1)
            key1_pressed = 1;
    }
}
