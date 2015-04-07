Known SMC Registers
===================
This document details known SMC register keys for Apple hardware.

Working out new registers
-------------

These registers were figured out with a bit of web sleuthing, and the excellent [smc\_util](https://github.com/alexleigh/smc_util) by [Alex Leigh](https://github.com/alexleigh), which can be used to list all registers and data types available on your system.
It cannot hurt to take a look on these pages also : 
http://www.parhelia.ch/blog/statics/k3_keys.html


Submission
-------------

Should you figure registers that aren't listed here (non listed hardware/missing), and you want to share them, [contact me here](http://jedda.me/contact-jedda/), and i'll be happy to include them in this list.

Hardware List
-------------
> This needs to be cleaned

*%* **ALWAYS** *BEGINS AT 0*

- *TC%D* - CPU % Diode
- *TC%H* - CPU % Heatsink
- *TC%P* - CPU % Proximity
- *TC%C* - CPU % Core
- *TCAH* - CPU A Heatsink
- *TCBH* - CPU B Heatsink
- *TH%P* - Drive Bay %
- *TN0D* - Northbridge Diode
- *TN0P* - Northbridge Proximity
- *TW0P* - Wireless Module
- *F%Ac* - Fan % Speed
- *TA%P* - Ambient Air %
- *TI%P* - Thunderbolt % Proximity
- *TM0S* - Memory Slot 1
- *TMBS* - Memory Slot 2
- *TM0P* - Memory Slots Proximity
- *TN0H* - Memory Controller Heatsink
- *TP0P* - Platform Controller Hub Proximity
- *TPCD* - Platform Controller Hub Diode
- *Tp%C* - Power Supply %
- *Tp0C* - Power Supply Inlet
- *Tp1C* - Power Supply Secondary
- *TB0T* Battery TS_MAX Temp
- *TB1T* Battery TS1 Temp
- *TB2T* Battery TS2 Temp
- *TB3T* Battery Temp
- *TC0D* CPU 0 Die Temp
- *TC0P* CPU 0 Proximity Temp
- *TG0D* GPU Die – Digital
- *TG0P* GPU 0 Proximity Temp
- *TG0T* GPU 0 Die – Analog Temp
- *TG0H* Left Heat Pipe/Fin Stack Proximity Temp
- *TG1H* Left Heat Pipe/Fin Stack Proximity Temp
- *TN0P* MCP Proximity
- *TN0D* MCP Digital
- *Th2H* Right Fin Stack Proximity Temp
- *Tm0P* Battery Charger Proximity Temp
- *Ts0P* Palm Rest Temp
