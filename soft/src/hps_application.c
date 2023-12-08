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
// static uint8_t key2_pressed = 0; key 2 is jus on or off not edge detection
static uint8_t key3_pressed = 0;

static bool mode = false; // 0 is manual 1 is automatic
static uint8_t speed = 0;
static bool acquisition_mode = 0; // 0 is not reliable 1 is reliable

static uint32_t nbrs[4];

#define Na 0x20
#define Nb 0x24
#define Nc 0x28
#define Nd 0x2C




// TODO ajouter les offset pour la fgeneration de numeros ou bits seelon notre interface

/* controle reg for nbr generation */
#define nbr_gen_reg 0x18
/* cmd_init_i */
#define reset_to_zero 0x0000
/* cmd_new_nbr_i */
#define new_nbr 0x0000

/* acquisition mode reg */
#define acquisition_mode_reg 0x1C

int main(void){
    
    /* Init peripherals */
    Switchs_init();
    Leds_init();
    Keys_init();
    Segs7_init();

    /* Set Default values on LEDS and hex display */
    Leds_clear(LED_MASK);

     /* display ID on console */
    printf("ID: %lx\n", AXI_LW_REG(0));

    /* display our interface */

    /* set our base mode based on switches */
    uint8_t switches = Switchs_read();

    /* mode is switch 7 0 manual and 1 automatic */
    mode =  (switches >> 7) & 0x1;

    /* speed is switches 8 and 9 */
    speed = switches >> 8;

    /* acquisition mode is switches 0 */
    acquisition_mode = switches & 0x1;

    uint8_t somme;
    uint8_t status;
    uint32_t errors = 0;

     while (true)
    {

        switches = Switchs_read();
        /* leds copy switches */
        Leds_set(switches);



        // TODO on ferait un if pour ca comme ca on les set que qquand les bit de modes changent ou on le fait a chaque boucle ?


        /* get mode, speed and acquisition mode */
        mode =  (switches >> 7) & 0x1;
        /* speed is switches 8 and 9 */
        speed = switches >> 8;
        /* acquisition mode is switches 0 */
        acquisition_mode = switches & 0x1;

        /* set mode */
        AXI_LW_REG(acquisition_mode_reg) = (mode << 5) | speed;




        /* Set all numbers to 0 */
        if ((Key_read(0) == 0) && key0_pressed == 1)
        {
            AXI_LW_REG(nbr_gen_reg) = 1;
            key0_pressed = 0;
        }

        /* in manual mode generate 4 new numbers */
        if (!mode && (Key_read(1) == 0) && key1_pressed == 1)
        {
            AXI_LW_REG(nbr_gen_reg) = 1 << 5;
            key1_pressed = 0;
        }

        /* check if the load key is pressed */
        if ((Key_read(2) == 0) )
        {
            // set reliable acquisition mode
            if(acquisition_mode)
                AXI_LW_REG(acquisition_mode_reg)=1;//notre valeur
            

            nbrs[0] = AXI_LW_REG(Na);
            nbrs[1] = AXI_LW_REG(Nb);
            nbrs[2] = AXI_LW_REG(Nc);
            nbrs[3] = AXI_LW_REG(Nd);

            // disable acquisition mode
           if(acquisition_mode)
                AXI_LW_REG(acquisition_mode_reg)=1;//notre valeur
        
            somme = nbrs[3];
            status = AXI_LW_REG(0x10) & 0x3;
            /* compare number */
            if (somme !=  nbrs[0] + nbrs[1] + nbrs[2]){
                /* couleurs */
                printf("ER : status: %d, somme: %d, nbr_a: %d, nbr_b: %d, nbr_c: %d, nbr_d: %d\n", status, somme, nbrs[0], nbrs[1], nbrs[2], somme);
                printf("ER : nombre d'erreur cumulées: %d\n", ++errors);
            }else{
                printf("OK : status: %d, somme: %d, nbr_a: %d, nbr_b: %d, nbr_c: %d, nbr_d: %d\n", status, somme, nbrs[0], nbrs[1], nbrs[2], somme);
            
            }
        }

        /* check if the keys are pressed */
        if (Key_read(0) == 1)
            key0_pressed = 1;
        if (Key_read(1) == 1)
            key1_pressed = 1;
    
    }
}
