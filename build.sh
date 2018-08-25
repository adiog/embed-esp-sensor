#!/bin/bash

cd $(dirname $0)

set -e
set -o xtrace # uncomment for verbose bash

PROJECT_NAME=esp-project

ESP_SDK_PATH=./esp/sdk
ESP_STD_PATH=./esp/std
ESP_CORE_PATH=./esp/std/cores/esp8266
ESP_VARIANT_PATH=./esp/std/variants/nodemcu
ESP_TOOLS_SDK_PATH=./esp/std/tools/sdk

DEFAULT_DEVICE=`ls -1 /dev/ttyUSB* | head -1`
DEVICE=${1:-${DEFAULT_DEVICE}}
[[ -z "${DEVICE}" ]] && echo "Device not found." && exit 1

TOOL_DIR=${ESP_SDK_PATH}/bin

BUILD_DIR=./build
SOURCE_DIR=./${PROJECT_NAME}

CPP=./src/${PROJECT_NAME}.cpp
ELF=${BUILD_DIR}/${PROJECT_NAME}.elf
BIN=${BUILD_DIR}/${PROJECT_NAME}.bin

ESP_CORE=${BUILD_DIR}/libESPCore.ar

AUTODETECT_SOURCES="`find ${SOURCE_DIR} -name "*.c" -or -name "*.cpp" -or -name "*.cc"` ${CPP}"
AUTODETECT_HEADERS="`find ${SOURCE_DIR} -name "*.h"`"

export PATH=${TOOL_DIR}:$PATH

mkdir -p ${BUILD_DIR}

export CC=xtensa-lx106-elf-gcc
export CXX=xtensa-lx106-elf-g++
export AR=xtensa-lx106-elf-ar
export ESP_SIZE=xtensa-lx106-elf-size
export ESP_TOOL=esptool

INCLUDE_DIR="-I./${PROJECT_NAME}"

ASM_FLAGS="                                               \
    -D__ets__                                             \
    -DICACHE_FLASH                                        \
    -U__STRICT_ANSI__                                     \
    -I${ESP_TOOLS_SDK_PATH}/include                       \
    -I${ESP_TOOLS_SDK_PATH}/lwip2/include                 \
    -I${ESP_TOOLS_SDK_PATH}/libc/xtensa-lx106-elf/include \
    -I${BUILD_DIR}                                        \
    -c                                                    \
    -g                                                    \
    -x assembler-with-cpp                                 \
    -MMD                                                  \
    -mlongcalls                                           \
    -DF_CPU=80000000L                                     \
    -DLWIP_OPEN_SRC                                       \
    -DTCP_MSS=536                                         \
    -DARDUINO=10805                                       \
    -DARDUINO_ESP8266_NODEMCU                             \
    -DARDUINO_ARCH_ESP8266                                \
    -DARDUINO_BOARD=\"ESP8266_NODEMCU\"                   \
    -DESP8266                                             \
    -I${ESP_CORE_PATH}                                    \
    -I${ESP_VARIANT_PATH}                                 \
    ${INCLUDE_DIR}"

C_CORE_FLAGS="                                            \
    -D__ets__                                             \
    -DICACHE_FLASH                                        \
    -U__STRICT_ANSI__                                     \
    -I${ESP_TOOLS_SDK_PATH}/include                       \
    -I${ESP_TOOLS_SDK_PATH}/lwip2/include                 \
    -I${ESP_TOOLS_SDK_PATH}/libc/xtensa-lx106-elf/include \
    -I${BUILD_DIR}                                        \
    -c                                                    \
    -w                                                    \
    -Os                                                   \
    -g                                                    \
    -Wpointer-arith                                       \
    -Wno-implicit-function-declaration                    \
    -Wl,-EL                                               \
    -fno-inline-functions                                 \
    -nostdlib                                             \
    -mlongcalls                                           \
    -mtext-section-literals                               \
    -falign-functions=4                                   \
    -MMD                                                  \
    -std=gnu99                                            \
    -ffunction-sections                                   \
    -fdata-sections                                       \
    -DF_CPU=80000000L                                     \
    -DLWIP_OPEN_SRC                                       \
    -DTCP_MSS=536                                         \
    -DARDUINO=10805                                       \
    -DARDUINO_ESP8266_NODEMCU                             \
    -DARDUINO_ARCH_ESP8266                                \
    -DARDUINO_BOARD=\"ESP8266_NODEMCU\"                   \
    -DESP8266                                             \
    -I${ESP_CORE_PATH}                                    \
    -I${ESP_VARIANT_PATH}                                 \
    ${INCLUDE_DIR}"

CXX_CORE_FLAGS="                                          \
    -D__ets__                                             \
    -DICACHE_FLASH                                        \
    -U__STRICT_ANSI__                                     \
    -I${ESP_TOOLS_SDK_PATH}/include                       \
    -I${ESP_TOOLS_SDK_PATH}/lwip2/include                 \
    -I${ESP_TOOLS_SDK_PATH}/libc/xtensa-lx106-elf/include \
    -I${BUILD_DIR}                                        \
    -c                                                    \
    -w                                                    \
    -Os                                                   \
    -g                                                    \
    -mlongcalls                                           \
    -mtext-section-literals                               \
    -fno-exceptions                                       \
    -fno-rtti                                             \
    -falign-functions=4                                   \
    -std=c++11                                            \
    -MMD                                                  \
    -ffunction-sections                                   \
    -fdata-sections                                       \
    -DF_CPU=80000000L                                     \
    -DLWIP_OPEN_SRC                                       \
    -DTCP_MSS=536                                         \
    -DARDUINO=10805                                       \
    -DARDUINO_ESP8266_NODEMCU                             \
    -DARDUINO_ARCH_ESP8266                                \
    -DARDUINO_BOARD=\"ESP8266_NODEMCU\"                   \
    -DESP8266                                             \
    -I${ESP_CORE_PATH}                                    \
    -I${ESP_VARIANT_PATH}                                 \
    ${INCLUDE_DIR}"

LD_FLAGS_PREFIX="                                         \
    -g                                                    \
    -w                                                    \
    -Os                                                   \
    -nostdlib                                             \
    -Wl,--no-check-sections                               \
    -u call_user_start                                    \
    -u _printf_float                                      \
    -u _scanf_float                                       \
    -Wl,-static                                           \
    -L${ESP_TOOLS_SDK_PATH}/lib                           \
    -L${ESP_TOOLS_SDK_PATH}/ld                            \
    -L${ESP_TOOLS_SDK_PATH}/libc/xtensa-lx106-elf/lib     \
    -T${ESP_TOOLS_SDK_PATH}/ld/eagle.flash.4m1m.ld                                 \
    -Wl,--gc-sections                                     \
    -Wl,-wrap,system_restart_local                        \
    -Wl,-wrap,spi_flash_read"

LD_FLAGS_START_GROUP="-Wl,--start-group"

LD_FLAGS_END_GROUP="                                      \
    -lhal                                                 \
    -lphy                                                 \
    -lpp                                                  \
    -lnet80211                                            \
    -llwip2                                               \
    -lwpa                                                 \
    -lcrypto                                              \
    -lmain                                                \
    -lwps                                                 \
    -laxtls                                               \
    -lespnow                                              \
    -lsmartconfig                                         \
    -lairkiss                                             \
    -lwpa2                                                \
    -lstdc++                                              \
    -lm                                                   \
    -lc                                                   \
    -lgcc                                                 \
    -Wl,--end-group                                       \
    -L${BUILD_DIR}"

#echo ${ESP_TOOLS_SDK_PATH}/libc/xtensa-lx106-elf/lib
#exit 1

function build_esp_core_library() {
  mkdir -p ${BUILD_DIR}/core
  mkdir -p ${BUILD_DIR}/core/spiffs
  mkdir -p ${BUILD_DIR}/core/libb64
  mkdir -p ${BUILD_DIR}/core/umm_malloc

  ${CC} ${ASM_FLAGS} ${ESP_CORE_PATH}/cont.S -o ${BUILD_DIR}/core/cont.S.o

  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/cont_util.c -o ${BUILD_DIR}/core/cont_util.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_eboot_command.c -o ${BUILD_DIR}/core/core_esp8266_eboot_command.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_flash_utils.c -o ${BUILD_DIR}/core/core_esp8266_flash_utils.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_i2s.c -o ${BUILD_DIR}/core/core_esp8266_i2s.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_noniso.c -o ${BUILD_DIR}/core/core_esp8266_noniso.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_phy.c -o ${BUILD_DIR}/core/core_esp8266_phy.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_postmortem.c -o ${BUILD_DIR}/core/core_esp8266_postmortem.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_si2c.c -o ${BUILD_DIR}/core/core_esp8266_si2c.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_timer.c -o ${BUILD_DIR}/core/core_esp8266_timer.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_wiring.c -o ${BUILD_DIR}/core/core_esp8266_wiring.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_waveform.c -o ${BUILD_DIR}/core/core_esp8266_waveform.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_wiring_analog.c -o ${BUILD_DIR}/core/core_esp8266_wiring_analog.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_wiring_digital.c -o ${BUILD_DIR}/core/core_esp8266_wiring_digital.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_wiring_pulse.c -o ${BUILD_DIR}/core/core_esp8266_wiring_pulse.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_wiring_pwm.c -o ${BUILD_DIR}/core/core_esp8266_wiring_pwm.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_wiring_shift.c -o ${BUILD_DIR}/core/core_esp8266_wiring_shift.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/gdb_hooks.c -o ${BUILD_DIR}/core/gdb_hooks.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/heap.c -o ${BUILD_DIR}/core/heap.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/libc_replacements.c -o ${BUILD_DIR}/core/libc_replacements.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/sntp-lwip2.c -o ${BUILD_DIR}/core/sntp-lwip2.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/time.c -o ${BUILD_DIR}/core/time.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/uart.c -o ${BUILD_DIR}/core/uart.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/libb64/cdecode.c -o ${BUILD_DIR}/core/libb64/cdecode.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/libb64/cencode.c -o ${BUILD_DIR}/core/libb64/cencode.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/spiffs/spiffs_cache.c -o ${BUILD_DIR}/core/spiffs/spiffs_cache.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/spiffs/spiffs_check.c -o ${BUILD_DIR}/core/spiffs/spiffs_check.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/spiffs/spiffs_gc.c -o ${BUILD_DIR}/core/spiffs/spiffs_gc.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/spiffs/spiffs_hydrogen.c -o ${BUILD_DIR}/core/spiffs/spiffs_hydrogen.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/spiffs/spiffs_nucleus.c -o ${BUILD_DIR}/core/spiffs/spiffs_nucleus.c.o
  ${CC} ${C_CORE_FLAGS} ${ESP_CORE_PATH}/umm_malloc/umm_malloc.c -o ${BUILD_DIR}/core/umm_malloc/umm_malloc.c.o

  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/Esp.cpp -o ${BUILD_DIR}/core/Esp.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/FS.cpp -o ${BUILD_DIR}/core/FS.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/FunctionalInterrupt.cpp -o ${BUILD_DIR}/core/FunctionalInterrupt.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/HardwareSerial.cpp -o ${BUILD_DIR}/core/HardwareSerial.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/IPAddress.cpp -o ${BUILD_DIR}/core/IPAddress.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/MD5Builder.cpp -o ${BUILD_DIR}/core/MD5Builder.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/Print.cpp -o ${BUILD_DIR}/core/Print.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/Schedule.cpp -o ${BUILD_DIR}/core/Schedule.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/Stream.cpp -o ${BUILD_DIR}/core/Stream.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/StreamString.cpp -o ${BUILD_DIR}/core/StreamString.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/Tone.cpp -o ${BUILD_DIR}/core/Tone.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/Updater.cpp -o ${BUILD_DIR}/core/Updater.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/WMath.cpp -o ${BUILD_DIR}/core/WMath.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/WString.cpp -o ${BUILD_DIR}/core/WString.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/abi.cpp -o ${BUILD_DIR}/core/abi.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/base64.cpp -o ${BUILD_DIR}/core/base64.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/cbuf.cpp -o ${BUILD_DIR}/core/cbuf.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/core_esp8266_main.cpp -o ${BUILD_DIR}/core/core_esp8266_main.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/debug.cpp -o ${BUILD_DIR}/core/debug.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/pgmspace.cpp -o ${BUILD_DIR}/core/pgmspace.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/spiffs_api.cpp -o ${BUILD_DIR}/core/spiffs_api.cpp.o
  ${CXX} ${CXX_CORE_FLAGS} ${ESP_CORE_PATH}/spiffs_hal.cpp -o ${BUILD_DIR}/core/spiffs_hal.cpp.o

  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/cont.S.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/cont_util.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_eboot_command.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_flash_utils.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_i2s.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_noniso.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_phy.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_postmortem.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_si2c.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_timer.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_waveform.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_wiring.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_wiring_analog.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_wiring_digital.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_wiring_pulse.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_wiring_pwm.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_wiring_shift.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/gdb_hooks.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/heap.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/libc_replacements.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/sntp-lwip2.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/time.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/uart.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/libb64/cdecode.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/libb64/cencode.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/spiffs/spiffs_cache.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/spiffs/spiffs_check.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/spiffs/spiffs_gc.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/spiffs/spiffs_hydrogen.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/spiffs/spiffs_nucleus.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/umm_malloc/umm_malloc.c.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/Esp.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/FS.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/FunctionalInterrupt.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/HardwareSerial.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/IPAddress.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/MD5Builder.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/Print.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/Schedule.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/Stream.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/StreamString.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/Tone.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/Updater.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/WMath.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/WString.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/abi.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/base64.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/cbuf.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/core_esp8266_main.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/debug.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/pgmspace.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/spiffs_api.cpp.o
  ${AR} cru ${ESP_CORE} ${BUILD_DIR}/core/spiffs_hal.cpp.o
}

echo "Building ESP Core Library.."
[[ -e ${ESP_CORE} ]]                            \
  && echo "Using cached ESP Core Library.." \
  || build_esp_core_library

echo "Compiling project.."
AUTODETECT_OBJECTS=""
for source in ${AUTODETECT_SOURCES};
do
  OBJ=${BUILD_DIR}/$(basename ${source}).o
  [[ ${source} =~ .*\.cpp ]] \
      && ${CXX} ${CXX_CORE_FLAGS} ${source} -o ${OBJ} \
      || ${CC} ${C_CORE_FLAGS} ${source} -o ${OBJ}
  AUTODETECT_OBJECTS="${AUTODETECT_OBJECTS} ${OBJ}"
done

echo "Linking project.."
${CC}                      \
  ${LD_FLAGS_PREFIX}       \
  -o ${ELF}                \
  ${LD_FLAGS_START_GROUP}  \
    ${AUTODETECT_OBJECTS}  \
    ${ESP_CORE}            \
  ${LD_FLAGS_END_GROUP}

echo "Building elf.."
${ESP_TOOL} -eo ${ESP_STD_PATH}/bootloaders/eboot/eboot.elf -bo ${BIN} -bm dio -bf 40 -bz 4M -bs .text -bp 4096 -ec -eo ${ELF} -bs .irom0.text -bs .text -bs .data -bs .rodata -bc -ec
${ESP_SIZE} -A ${ELF}

echo "Flashing.."
${ESP_TOOL} -cd nodemcu -cb 115200 -cp ${DEVICE} -ca 0x00000 -cf ${BIN}

echo "..done."

