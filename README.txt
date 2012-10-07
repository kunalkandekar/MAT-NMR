		          MAT - Magic Angle Turning
			             2000 - 2001

		      Developed by Kunal Kandekar and Subodh Joshi

* INTRODUCTION
This was undertaken a final-year project for our Bachelor of Engineering (BE)
degree in Instrumentation & Control engineering. We implemented a real-time
embedded control system for "Magic Angle Turning" for specialized Nuclear 
Magnetic Resonance (NMR) experiments.

All (except a vanishingly small minority, e.g. us) of NMR experiments utilize 
something called "Magic Angle Spinning" (MAS). Here, the sample to be analyzed 
is oriented at the magic angle (54.7356 degrees) and spun at very high speeds 
(multiples at KHz) in a ridiculously strong magnetic field. (And I mean 
RIDICULOUSLY; google for "MRI accidents" -- MRI is comparable to NMR)

Our project applied to a very specialized form of experimentation, called Magic
Angle Turning (MAT) where the sample is turned at much lower speeds (30 to
 100 Hz). Since conventional NMR equipment was not designed for MAT, specialized
eqiupment (such as ours) is required.

We wrote the code in raw 8051 assembly, using an Atmel 8051 microcontroller.


* NEAT HACKS
We used the voice coil of a cheap audio speaker (literally ripped out of a PC 
speaker) to precisely modulate pneumatic pressure. Check out "flapper-nozzle"
for it's doable.

Also, check out the "32 bit by 16 bit division" routine. It divides a 32-bit 
number by a 16-bit number on an 8-bit device in raw 8051 assembly. No floating 
point, of course. It takes advantage of a specialized 16-bit by 8-bit division 
instruction our Atmel microcontroller had. With his, we were able to measure 
frequency from inter-interrupt intervals (heheheh, just made that up) up to 2
decimal places of accuracy. This level of accuracy was needed to maintain a 
stable spinning speed, since only a 0.01 variance is tolerable for MAT NMR
experiments.