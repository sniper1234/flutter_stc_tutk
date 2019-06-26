# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

# Sets the minimum version of CMake required to build the native library.

cmake_minimum_required(VERSION 3.4.1)

# Creates and names a library, sets it as either STATIC
# or SHARED, and provides the relative paths to its source code.
# You can define multiple libraries, and CMake builds them for you.
# Gradle automatically packages shared libraries with your APK.

#set(libs_DIR src/main/jniLibs/${ANDROID_ABI})
#set(libs_include_DIR src/main/cpp)
#include_directories(${lib_include_DIR})
#link_directories(${libs_DIR})

include_directories(src/main/cpp/)


add_library( # Sets the name of the library.
        native-lib

        # Sets the library as a shared library.
        SHARED

        # Provides a relative path to your source file(s).
        src/main/cpp/native-lib.cpp)


target_link_libraries(native-lib
        AVAPIs)
target_link_libraries(native-lib
        IOTCAPIs)


# Searches for a specified prebuilt library and stores the path as a
# variable. Because CMake includes system libraries in the search path by
# default, you only need to specify the name of the public NDK library
# you want to add. CMake verifies that the library exists before
# completing its build.

find_library( # Sets the name of the path variable.
        log-lib

        # Specifies the name of the NDK library that
        # you want CMake to locate.
        log)


# Specifies libraries CMake should link to your target library. You
# can link multiple libraries, such as libraries you define in this
# build script, prebuilt third-party libraries, or system libraries.

#target_link_libraries( # Specifies the target library.
#        native-lib
#
#        # Links the target library to the log library
#        # included in the NDK.
#        ${log-lib})


#add_library( # Sets the name of the library.
#        ffmpeg_decoder
#
#        # Sets the library as a shared library.
#        SHARED
#
#        # Provides a relative path to your source file(s).
#        src/main/cpp/com_tutk_client_FFMPEG_Decoder.cpp)

# Searches for a specified prebuilt library and stores the path as a
# variable. Because CMake includes system libraries in the search path by
# default, you only need to specify the name of the public NDK library
# you want to add. CMake verifies that the library exists before
# completing its build.

#find_library( # Sets the name of the path variable.
#        log-lib
#
#        # Specifies the name of the NDK library that
#        # you want CMake to locate.
#        log)

add_library(AVAPIs SHARED IMPORTED)
set_target_properties(AVAPIs PROPERTIES IMPORTED_LOCATION ../../../../libs/${ANDROID_ABI}/libAVAPIs.so)

add_library(IOTCAPIs SHARED IMPORTED)
set_target_properties(IOTCAPIs PROPERTIES IMPORTED_LOCATION ../../../../libs/${ANDROID_ABI}/libIOTCAPIs.so)


add_library(avcodec SHARED IMPORTED)
set_target_properties(avcodec PROPERTIES IMPORTED_LOCATION ../../../../libs/${ANDROID_ABI}/libavcodec.so)

add_library(avformat SHARED IMPORTED)
set_target_properties(avformat PROPERTIES IMPORTED_LOCATION ../../../../libs/${ANDROID_ABI}/libavformat.so)

add_library(avutil SHARED IMPORTED)
set_target_properties(avutil PROPERTIES IMPORTED_LOCATION ../../../../libs/${ANDROID_ABI}/libavutil.so)

add_library(swscale SHARED IMPORTED)
set_target_properties(swscale PROPERTIES IMPORTED_LOCATION ../../../../libs/${ANDROID_ABI}/libswscale.so)

target_link_libraries(native-lib
        AVAPIs
        IOTCAPIs
        avcodec
        avformat
        avutil
        swscale
        -landroid # Add this.
        ${log-lib})