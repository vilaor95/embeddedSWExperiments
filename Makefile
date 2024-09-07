OUT = out
ELF = $(OUT).elf
BIN = $(OUT).bin

STMPROG = st-flash
STMUTIL = st-util

LINKER_FILE = linker.ld

CC = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy

C_OBJECTS = main.o
S_OBJECTS = startup.o

# Specs
SPECS = nosys.specs

# Debug flags
DBGFLAGS = 

# Target settings
TARGET=STM32F446xx
FPUFLAGS = -mfpu=fpv4-sp-d16 -mfloat-abi=hard

INCFLAGS = -Icmsis_f4/Include 

# Build flags
CCFLAGS = -mcpu=cortex-m4 \
	  $(DBGFLAGS) \
	  -std=gnu11 \
	  -D$(TARGET) \
	  --specs=$(SPECS) \
	  $(FPUFLAGS) \
	  -mthumb \
	  $(INCFLAGS) \
	  -ffunction-sections \
	  -fdata-sections \
	  -nostdlib \
	  -g -O0

ASFLAGS = -mcpu=cortex-m4 \
	  $(DBGFLAGS) \
	  --specs=$(SPECS) \
	  $(FPUFLGAS) \
	  -mthumb \
          -nostdlib \
	  -g

# Removed -Wl,--gc-sections for testing purposes
LDFLAGS = -mcpu=cortex-m4 \
	  -T$(LINKER_FILE) \
	  --specs=$(SPECS) \
	  -Wl,-Map=out.map \
	  -Wl,--print-memory-usage \
	  -static $(FPUFLAGS) \
	  -mthumb \
	  -Wl,--start-group \
	  -lc -lm \
	  -Wl,--end-group \
	  -nostdlib

all: cmsis cmsis_f4 $(ELF)

%.o: %.c
	$(CC) $(CCFLAGS) -c -o $@ $<

%.o: %.s
	$(CC) $(ASFLAGS) -c -o $@ $<

$(ELF): $(C_OBJECTS) $(S_OBJECTS) $(LINKER_FILE)
	$(CC) -o $@ $(C_OBJECTS) $(S_OBJECTS) $(LDFLAGS)

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@
.PHONY: flash
flash: $(BIN)
	$(STMPROG) write $< 0x8000000

.PHONY: debug
debug: flash
	$(STMUTIL) &
	arm-none-eabi-gdb $(ELF) -ex 'target extended-remote localhost:4242'
	killall $(STMUTIL)

cmsis:
	git clone --depth 1 -b 5.9.0 https://github.com/ARM-software/CMSIS_5 $@

cmsis_f4:
	git clone --depth 1 https://github.com/STMicroelectronics/cmsis_device_f4 $@

.PHONY: clean
clean:
	- rm $(ELF) $(BIN) $(C_OBJECTS) $(S_OBJECTS)
