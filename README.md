#HYFI
![Assembly(Nasm)](https://shields.io)
HYFI is a 64-bit firmware that can roll back from 64-bit to 32 and 16 bits, and also has a command shell
HYFI supports Intel processors from 2nd to 6th generation, and also has IRQ, IDT, PIC. Well, let's get back to the firmware itself—it boots the processor in the mode the user wants.
Let's say the user needs to launch a 16-bit PRoS core. For HYFI to hand control over to the core, we need to tell it by writing a command in the "real mode" shell. 
HYFI already knows that you want to run the core in 16-bit mode, but we haven’t handed control to the core yet. 
To transfer control to our core, we write the "launch" command, and HYFI will load our core at address 0x00100000 (1 megabyte of memory).
