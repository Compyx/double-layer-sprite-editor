# vim: set noet ts=8

ASM=64tass
ASM_FLAGS=-C -a
X64=/usr/local/bin/x64
X64_FLAGS=

TARGET=dlse.prg
SOURCES=main.asm dialog.asm edit.asm view.asm zoom.asm
DATA=

all: $(TARGET)

$(TARGET): $(SOURCES) $(DATA)
	$(ASM) $(ASM_FLAGS) -o $(TARGET) main.asm


x64: $(TARGET)
	$(X64) $(X64_FLAGS) $(TARGET)


