arm-cx2450x-linux-gnueabi-gcc -g -o tuxwetter tuxwetter.c gfx.c io.c text.c parser.c php.c http.c jpeg.c fb_display.c resize.c pngw.c gif.c -L$PREFIX/lib -I$PREFIX/include -I$PREFIX/include/freetype2 -I$PREFIX/include/freetype2 -O2 -lfreetype -lz -ljpeg  -lpng -lungif gifdecomp.c
