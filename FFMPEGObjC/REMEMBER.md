## Things to remember when reproducing Things

### Header and lib files
Include header and lib files from 

headerfiles: "/usr/local/Cellar/ffmpeg/2.8/include"
lib: "/usr/local/Cellar/ffmpeg/2.8/lib" (use the .a files)

Just drag them to the project and remember to set the "Header Search Path", here it is: $(SRCROOT)/FFMPEGObjC/include

### Linker flags
Remember to set theese linker flags (Other linker flags)

-liconv
-lz

they where causing these errors:

(liconv)
Undefined symbols for architecture x86_64:
"_iconv", referenced from:
_avcodec_decode_subtitle2 in libavcodec.a(utils.o)
"_iconv_close", referenced from:
_avcodec_open2 in libavcodec.a(utils.o)
_avcodec_decode_subtitle2 in libavcodec.a(utils.o)
"_iconv_open", referenced from:
_avcodec_open2 in libavcodec.a(utils.o)
_avcodec_decode_subtitle2 in libavcodec.a(utils.o)
"_uncompress", referenced from:
_id3v2_read_internal in libavformat.a(id3v2.o)
_svq3_decode_init in libavcodec.a(svq3.o)
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)

(lz)
Undefined symbols for architecture x86_64:
"_uncompress", referenced from:
_id3v2_read_internal in libavformat.a(id3v2.o)
_svq3_decode_init in libavcodec.a(svq3.o)
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)

