The easiest way to create a function written in a language which doesn't have an FDK is to use hotwrap.

You include the hotwrap binary in the function image and run a command line application.  This will read the input on STDIN and send back output on STDOUT.

Which is fine if you already have a command line application.  Otherwise you're going to need to create one, or many, depending on how many functions you need to create.

So it might be easier if you could just write your functions in your chosen language.
Since there isn't an FDK (otherwise you'd just use that), you're going to need to set up some equivalent machinery.
