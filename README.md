xLine
=====
> Everything around here is *work in progress*. 
If you feel in a helpful mood, then fork, do your stuff, and submit a pull request !

Easy-to-use command-line utility to get system informations, such as component temperature, battery data, fan speed (soon).
You can also make raw requests to your computer's SMC, using `-s TC0P`, where TC0P (currently, the CPU temperature) can be replaced by whatever you want (see https://github.com/perfaram/xLine/blob/master/SMC_Keys.md)

The available options, except -s : 
 - `-b` to get battery informations
 - `-t` to get temp sensors data

##Copyrights :
#### SMCUtil
 * Original version Copyright (C) 2006 devnull
 * Portions Copyright (C) 2012 Alex Leigh (@alexleigh)
 * Portions Copyright (C) 2013 Michael Wilber
 * Portions Copyright (C) 2013 Jedda Wignall (@jedda)
 * Portions Copyright (C) 2014 Perceval Faramaz (@perfaram)
 * Portions Copyright (C) 2014 Naoya Sato (@stny)

#### BRLOptionParser 
 * Copyright (C) 2013 Stephen Celis (@barrelage)

#### BatKit
 * Copyright (C) 2014 Perceval Faramaz (@perfaram)
