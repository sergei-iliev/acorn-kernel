![Acorn kernel](screenshots/logo.jpg)

##### The main objective behind Acorn kernel is creating an open source,robust micro kernel for 8bit Atmel AVR microprocessors written entirely in Assembler. 
##### The kernel by itself is a static preemptive operating system which basically means:
##### * Any number of tasks can be accurately defined before run time and when the system starts up all tasks are created and this number does not change.
* A so called "scheduler" organizes the tasks execution as each task is given a time quantum to execute its code based on interrupt or software driven events
* Provides synchronization primitives which are used for intertask communication, resource counting and task critical section protection.

##### The operating system is logically divided into general and executive levels. Such division separates the system structures and procedures as to who and what can call them thus making the code development easier.
The development path being pursued is simplicity and easy to understand and apply methodology. In this regard help and collaboration from engineers as well as hobbyists is needed to bring this project to perfection.
