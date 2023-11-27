# Makefile

# 获取当前目录及其所有子目录下的所有.s文件
SOURCE_FILES := $(shell find . -type f -name "*.s")

# 将.s文件重命名为.asm文件
ASM_FILES := $(patsubst %.s, %.asm, $(SOURCE_FILES))

all: rename

rename: $(ASM_FILES)
	@echo "Files renamed to .asm successfully."

%.asm: %.s
	mv $< $@

revert: $(SOURCE_FILES)
	@echo "Files reverted to .s successfully."

%.s: %.asm
	mv $< $@

.PHONY: all rename revert
