#include <stdint.h>
#define MINIRV32_IMPLEMENTATION
#define MINI_RV32_RAM_SIZE ((1 << 24) * 4)
#define MINIRV32_DECORATE
#define MINIRV32_HANDLE_MEM_STORE_CONTROL(addr, val) mmio_store(addr, val)
#define MINIRV32_HANDLE_MEM_LOAD_CONTROL(addr, rval) rval = mmio_load(addr);

void mmio_store(uint32_t addr, uint32_t val);
uint32_t mmio_load(uint32_t addr);

#include "mini-rv32ima.h"
