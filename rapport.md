
\center

# **Laboratoire 3: Conception d’une interface simple**

\hfill\break

\hfill\break

Département: **TIC**

Unité d'enseignement: **ARE**

\hfill\break

\hfill\break

\hfill\break

\hfill\break

\hfill\break

\hfill\break

\hfill\break

\hfill\break

\hfill\break

\raggedright

Auteur(s):

- **BOUGNON-PEIGNE Kévin**
- **CECCHET Costantino**

Professeur:

- **MESSERLI Etienne**
  
Assistant:

- **CONVERS Anthony**

Date:

- **Novembre 2023**

\pagebreak

## Sommaire

- [Introduction](#introduction)

- [Conception de l'interface](#conception-de-linterface)

  - [Plan d'adressage](#plan-dadressage)

  - [Réalisation du circuit](#réalisation-du-circuit)

    - [Canal d'écriture](#canal-décriture)

    - [Canal de lecture](#canal-de-lecture)

    - [Machine d'état pour l'écriture de la MAX10](#machine-détat-pour-lécriture-de-la-max10)

  - [Synthèse](#synthèse)

- [Simulation](#simulation)

- [Programme C](#programme-c)

- [Conclusion](#conclusion)

- [Annexe(s)](#annexes)

\pagebreak

## **Introduction**

Pour ce laboratoire, il est demandé de réaliser une interface simple, connectée sur le bus Avalon interconnectant l'HPS (microcontroller) et l'FPGA de la carte DE1-SoC.

L'arborescence de fichiers de base du projet a été fourni par les responsables de cours.

\hfill\break

## **Conception de l'interface**

### **Plan d'adressage**

Comme le montre le bloc de l'interface a concevoir:

\center

![bloc_schem.png](_pics/bloc_schem.png){ width=90% }

\raggedright

\hfill\break

Elle ne reçoit que 14bits pour l'adresse.

Ceci s'explique par le fait que le bus de données est sur **32bits**. Dès lors, une valeur 32bits doit pouvoir s'adresser de telles façons à accèder à chacun de ces bytes, soit:

\small

```shell
|   REGISTRE     32     BITS    |
| ----------------------------- |
| BYTE3 | BYTE2 | BYTE1 | BYTE0 |
|      0x3     0x2     0x1     0x0 Offset à partir de l'adr. de base du reg.
```

\normalsize

\hfill\break

Ce faisant, les adresses dans le plan d'adressage doivent être alignées sur 2bits, autrement dit, alignées sur 4. **Ce qui enlève les 2 premiers bits de poids faibles.**

\pagebreak

Ensuite, le manuel de référence technique du processeur nous indique que le bus Avalon débute à l'adresse 0xFF20'0000, avec une mémoire allouée de 2MB. **Il en est déduisible que les 11 derniers bits de poids forts sont décodés par ce dernier.**

De plus, la zone attribuée aux étudiants est présenté avec le tableau ci-dessous:

\center

\small

| Offset on bus AXI lightweight HPS2FGPA | Fonctionnalités |
| :-------------: | --------------- |
| 0x00_0000 - 0x00_0003 | Constante ID 32Bits (Read only) |
| 0x00_0004 - 0x00_FFFF | reserved |
| **0x01_0000 - 0x01_FFFF** | **Zone à disposition des étudiants** |
| 0x02_0000 - 0x1F_FFFF | not used |

\normalsize

\raggedright

Une constante ID de 32bits est retrouvée, mais cette dernière est implémentée par le *design* des responsables de cours. De fait, l'interface à concevoir est derrière le *design* sus-mentionné **et donc, les bits utilisés par l'interface à concevoir sont alors les 14bits d'adresse 15 à 2.**

\hfill\break

Le plan d'adressage a ensuite été définit comme suit:

| Address (CPU Side) [16..0] | Address (Itf side) [15..2] | Definition | R/W |
| :----------: | :---------: | :------------- | :-: |
| 0x1_0000 | 0x0000 | Constant ID (**0xDEADBEEF**) | R |
| 0x1_0004 | 0x0001 | Constant 2 (Debug) | R/W |
| 0x1_0008 | 0x0002 | IN: Switches | R |
| 0x1_0010 | 0x0004 | IN: Keys | R |
| 0x1_0020 | 0x0008 | OUT: LEDs | R/W |
| 0x1_0040 | 0x0010 | OUT: MAX10-LEDs | R/W |
| 0x1_0080 | 0x0020 | OUT: MAX10-cfg (status[5..4] + sel[3..0]) | R/W[^1] |
| 0x1_0100 | 0x0040 | IN: MAX10-busy (write\_enable) | R |
| 0x1_0200 | 0x0080 | *reserved* | - |
| 0x1_0400 | 0x0100 | *reserved* | - |
| 0x1_.... | 0x0... | *reserved* | - |
| 0x1_.... | 0x0... | *reserved* | - |
| 0x1_FFF8 | 0x0800 | *reserved* | - |
| 0x1_FFFC | 0x1000 | *reserved* | - |

[^1]: *status* est *read only*, car ces bits indiquent si la MAX10 est prête à l'emploi ou non.

\pagebreak

Justification du plan d'adressage:

\hfill\break

- La première constante permet d'identifier l'interface à concevoir, conformément à la donnée du laboratoire.

- La seconde n'est présente qu'à des fins de vérifications intermédiaires, portant sur la lecture et l'écriture sur le bus.

- Les entrées utilisateurs (switches & bouttons) ont été séparées, afin d'éviter d'effectuer du masquage et des shift pour obtenir le périphérique désiré.

- Comme il a été définit un registre 32bits pour les LEDs de la MAX10, les LEDs de la DE1SOC se trouvent également isolée dans une adresse.

- Pour les bits de configuration de la MAX10, ils ont été groupés. L'ordre était de mettre les bits de status au plus haut (selon les éventuels autres bits de config.), car ces derniers ne seront utilisés qu'à l'enclenchement du programme.

  Les bits de sélection de la zone active de la MAX10 est au plus bas, pour n'avoir qu'à faire un masquage pour obtenir la valeur.

- Pour finir, le bit *"busy"* représentant le *write\_enable* a été isolé, afin que le programme puisse attendre sur la fin d'écriture avec une simple boucle:

```c
    while( BUSY_REG ) ;
```

\hfill\break

Quant aux adresses, avec le nombre de registres définis et la taille à disposition, il a été décidé de faire en sorte de n'avoir qu'un bit actif par registre.

\pagebreak

### **Réalisation du circuit**

La circuiterie a été coupée en 3 parties majeures; **lecture**, **écriture** et une troisième pour la gestion de la **validité d'écriture sur la MAX10** (signal *lp36_we_o*).

\center

![interface_split](_pics/interface_split.jpg){ width=90% }

\raggedright

\hfill\break

*Note:* Les interrupteurs et les boutons arrivant sur l'interface ont été syncronisés au niveau de la DE1. Ceci dans le but de ne pas perturber la simulation, lorsque l'on change la valeur de ces derniers entre 2 lectures consécutives.

\hfill\break

De plus, comme les portes trois-états ne sont pas disponibles dans une puce FPGA, il faut passer par du dé/multiplexage.

\pagebreak

#### **Canal d'écriture**

\

Ce canal possède un DEMUX qui permet de choisir lequel des 4 registres écrivables (voir tableau en titre **[Plan d'adressage](#plan-dadressage)**) sera écrit.

\hfill\break

Le schéma résultant se présente ainsi:

\center

![demux_write](_pics/write.png){ width=70% }

\raggedright

\hfill\break

Dans la description du *design*, c'est ce canal qui traite le reset des différents registres.

\hfill\break

*Remarque:* Le registre de la constante ID de **debug** se reset à sa valeur initiale (`0xCAFE0369`) et non pas à 0.

\pagebreak

#### **Canal de lecture**

\

Pour celui de lecture, c'est un MUX qui permet de choisir parmis les 9 registres lisibles (voir tableau en titre **[Plan d'adressage](#plan-dadressage)**) celui qui sera lu.

\hfill\break

En voici son schéma:

\center

![mux_read](_pics/read.png){ width=70% }

\raggedright

\hfill\break

Lors de la lecture d'une donnée, un décalage d'une période d'horloge est effectuée pour obtenir le signal *read_datavalid*. 

\pagebreak

#### **Machine d'état pour l'écriture de la MAX10**

\

Pour l'écriture de la MAX10, la création d'une machine d'état est nécessaire. 

Selon les spécifications du bus, le signal *lp36_we* doit être actif pendant une période **d'au moins 1\[us\]**, afin de valider une écriture fiable des bits de sélections et des données des LEDs de la MAX10.

\hfill\break

Voici le diagramme de la machine d'état, où les '0' et '1' isolés sont les valeurs de *lp36\_enable* à chaque état:

\center

![mss](_pics/MSS.jpg){ width=60% }

\raggedright

\hfill\break

Pendant cette période de 1\[us\], le bit de *busyness* de notre interface est maintenu actif.

Comme il sera possible de le voir en **[annexes](#mesures-write-enable)**, grâce à quelques mesures, le signal peut avoir quelques perturbations et a alors une légère gigue.

C'est pourquoi, une marge de 10% (purement subjectif) a été prise en considération, lors du calcul de la limite à compter.

\hfill\break

Pour la gestion de la *SM*, un compteur est implémenté, afin de compter le nombre de cycle nécessaire au maintien du signal.

\pagebreak

Initialement, la limite a compté respecte la règle: $\frac{T_{maintien}}{T_{clk}}$. Toutefois, comme le montre le diagramme d'état, le maintien du signal est fait dans 2 états, il faut donc diviser par le nombre d'états dans lesquels le maintien est fait.

\hfill\break

Le calcul est alors:

\center

$Limit = \frac{T_{maintien}}{T_{clk} * N_{states}}$

avec: $T_{maintien}=1.1[us]$, $T_{clk}=\frac{1}{50'000'000}=20[ns]$ et $N_{states}=2$.

\hfill\break

\raggedright

Et donc, avec transformation des valeurs en \[ns\], on obtient:

\center

$Limit = \frac{1'100}{20 * 2} = 27.5 \approx 28$

\hfill\break

$RealT_{maintien} = 28 * 20 * 2 = 1'120[ns] => 1.12[us]$

\raggedright

\pagebreak

### Synthèse

Après discussion avec l'enseignant, la vue RTL et la quantité de logique ne sont plus très parlantes, de part l'explosion de logiques. Cependant, une autre information, permettant un contrôle plus approchable, est la quantité de registres dédiées au *design*.

\hfill\break

Sous le report de synthétisation: `Fitter > Resource Section > Resource Utilization by Entity`, à l'aide du filtre et en cherchant *avl_user_interface*, on trouve cette information:

\center

![dedicated_registers](_pics/DedicatedLogicRegisters.png){ width=95% }

\raggedright

\hfill\break

Chaque registre peut être compté, afin de retrouver la valeur présente ci-dessus:

| Column 1 | Size (bits) | Column 2 | Size (bits) |
| :--------------- | :--: | :----------- | :--: |
| Constante ID de debug | **32** | Sel + Status | **6** |
| Données pour LP36 | **32** | Machine d'états  | **3** |
| Registre de lecture | **32** | CS d'écriture sur MAX10 | **1** |
| Données des LEDs sur DE1SoC | **10** | *write enable* | **1** |
| Compteur de tempo. | **6** | / | / |

\hfill\break

Ce qui amène alors à:

$Dedicated Logic Registers = 32 + 32 + 32 + 10 + 6 + 6 + 3 + 1 + 1 = \boldsymbol 123$

\hfill\break

Les constantes, tel que la constante ID du périphérique, sont connectées en dures et ne comptent alors pas dans le compte de registres.

\pagebreak

## **Simulation**

Différentes phases de simulations ont été exécutées. Ces dernières peuvent être représentées avec les séquences sauvegardées, à l'aide de la console.

\hfill\break

Voici leur test respectif:

0. Test des lectures des IDs, ainsi que l'écriture de la constante de debug

  - Test de deux lectures consécutives, en forçant les signaux nécessaires

1. Test des lectures des entrées utilisateurs: Bouttons et interrupteurs

2. Test de l'écriture et relecture des LEDs de la DE1

3. Test de l'écriture, relecture des LEDs sur la MAX10, ainsi que le maintien de *lp36_we* soit active pendant 1\[us\]

\hfill\break

Pour ne pas surcharger le rapport, l'analyse des chronogrammes, avec effet sur la console est annexé à la **[fin](#simulation-chronogrammes-et-consoles)**.

\pagebreak

## **Programme C**

Pour le programme, la base a été reprise du dernier laboratoire.

\hfill\break

En prémice du programme principale, un programme de test a été écrit (fichier: test_program.c.bak). Ceci dans le but de tester les accès aux différents registres, ainsi que leur utilisation propre (gestion luminosité des LEDs, lecture des interrupteurs, ...).

\hfill\break

Un module **interface** implemente les fonctions de lecture et d'écriture de l'interface, afin de satisfaire les contraintes décrites par la donnéedu labo. .

Le module se contente du minimum pour cette interface, mais elle est facilement modulable.

\hfill\break

Selon la compréhension du cahier des charges, voici quelques clarifications quant au comportement du programme:

- Pression sur KEY3 -> extinction des LEDs

  Pour satisfaire ce point, il semblait plus naturel de garder les LEDs éteintes, tant que le bouton était maintenu pressé. À noter que durant la présentation, un pseudo PWM entre allumage et extinction de LEDs se créait sur la zone active de la MAX10.

- Pression sur KEY2 -> Shift d'une taille de byte sur la gauche

  Le mode décale la valeur des switchs de 8bits, tout en gardant les états des LEDs précédents. De plus, les autres LEDs que le groupe de 8bits sur lesquels les switchs sont reportés sont éteintes si KEY3 est pressé.

\pagebreak

## **Conclusion**

Pour conclure, le laboratoire a été réalisé avec succès! Le cahier des charges est rempli et tant le *design*, que le programme, sont tout 2 facilement modifiables si besoin.

\hfill\break

Après rédaction du rapport, 1 mitigation possibles serait de:

- Grouper les états responsables du maintien de *lp36_we* en un seul, de sorte à compter avec une résolution de 1 le nombre de cycle pour atteindre la limite.

\hfill\break

## Annexe(s)

- [Simulation: Chronogrammes et Consoles](#simulation-chronogrammes-et-consoles)

  - [IDs contrôle](#ids-contrôle)

  - [Lecture des entrées utilisateurs](#lecture-des-entrées-utilisateurs)

  - [Écriture/Relecture des LEDs sur DE1SoC](#écriturerelecture-des-leds-sur-de1soc)

  - [Maintien du write enable d’écriture sur MAX10](#maintien-du-write-enable-décriture-sur-max10)

- [Mesures write enable](#mesures-write-enable)

  - [Write enable de 1.1us - 1](#write-enable-de-1.1us---1)

  - [Write enable de 1.1us - 2](#write-enable-de-1.1us---2)

  - [Write enable de 1us](#write-enable-de-1us)

  - [Indication sur la mesure](#indication-sur-la-mesure)

\pagebreak

### Simulation: Chronogrammes et Consoles

\hfill\break

#### IDs contrôle

\

\center

![chrono00_id_rd](_pics/simu00_id_rd.png){ width=80% }

\raggedright

Ici, il est constaté que la valeur lue de l'ID (côté étudiant) est faite correctement et que le bit de *read_datavalid* est active, un coup d'horloge après *read_i*.

\hfill\break

\center

![chrono00_id_rdwr](_pics/simu01_id_rdwr.png){ width=80% }

\raggedright

Ce chronogramme permet de voir que la lecture, la modification et la relecture de la constante de *debug* fonctionne.

\hfill\break

\center

![chrono00_id_consec_rd](_pics/simu02_ids_doublerd.png){ width=80% }

\raggedright

En forçant les valeurs de *read_i* et de *avl_address_i*, le dernier chronogramme montre que la lecture consécutive de deux registres différents fonctionnent.

\pagebreak

\center

![simu00_console](_pics/simu00_2_console.png){ width=80% }

\raggedright

Sur la console, ces instructions permettent de confirmer que seul les bits 15 à 2 sont utilisés pour adresser l'interface.

\hfill\break

#### Lecture des entrées utilisateurs

\

\center

![chrono01_inputs](_pics/simu03_inputs.png){ width=80% }

\raggedright

Ce chronogramme permet de valider que les valeurs des interrupteurs et des boutons sont bien reportées, lors de leur lecture.

\hfill\break

Ce qui est validé, également avec la console ci-dessous:

\center

![simu01_console](_pics/simu03_console.png){ width=75% }

\raggedright

\pagebreak

#### Écriture/Relecture des LEDs sur DE1SoC

\

\center

![simu02_console](_pics/simu04_console.png){ width=80% }

\raggedright

\center

![console_led0_de1soc](_pics/simu04_de1_leds_0x1.png){ width=70% }

\raggedright

\center

![console_led1_de1soc](_pics/simu04_de1_leds_0x2.png){ width=70% }

\raggedright

\center

![console_led7_de1soc](_pics/simu04_de1_leds_0x8.png){ width=70% }

\raggedright

\hfill\break

Le chronogramme et les consoles vérifient le fonctionnement souhaité, transmis par les chronogrammes du bus Avalon (dans le dossier /doc, mis à disposition).

\pagebreak

#### Maintien du *write enable* d'écriture sur MAX10

\

\center

![chrono03_we](_pics/simu05_max10_we.png){ width=96% }

\raggedright

Le bit *write enable* est simulé correctement à 1'120\[ns\], comme calculé au titre **[Machine d'état pour l'écriture de la MAX10](#machine-détat-pour-lécriture-de-la-max10)**.

\hfill\break

\center

![simu03_console](_pics/simu05_console.png){ width=80% }

La console permet de voir que passer le délai de 1.12\[us\], le registre du *write enable* (ou appelé *busy* dans la solution adoptée) redescend bien à 0.

\raggedright

\pagebreak

### Mesures *write enable*

#### *Write enable* de 1.1us - 1

\

\center

![1us_m0](_pics/1us_meas0.jpg){ width=69% }

\raggedright

\hfill\break

#### *Write enable* de 1.1us - 2

\

\center

![1us_m1](_pics/1us_meas1.jpg){ width=69% }

\raggedright

Comme mentionné en titre **[Machine d’état pour l’écriture de la MAX10](#machine-détat-pour-lécriture-de-la-max10)**, on voit que sur 1.12\[us\], on retrouve une légère fluctuation.

En prenant la mesure initiale (voir page suivante), il serait alors possible de descendre en dessous de la \[us\].

\pagebreak

#### *Write enable* de 1us

\

\center

![1us_m1](_pics/1us_meas_precise.jpg){ width=80% }

\raggedright

\hfill\break

#### Indication sur la mesure

\

\center

![schema_meas](_pics/gpio1.png){ width=57% }

\raggedright

\hfill\break

Pour effectuer les mesures, la sonde d'un oscilloscope a été planté en pin n°2, avec un point de référence en pin n°12, à la masse.
