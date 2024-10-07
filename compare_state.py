#!/usr/bin/env python3
import argparse
import os.path
import sys
from amulet_nbt import load

ap = argparse.ArgumentParser()
ap.add_argument('world_path', type=str, help='Path to minecraft world')
args = ap.parse_args()

class State:
    def __init__(self, state, registers, memory):
        self.state = state
        self.registers = registers
        self.memory = memory

def load_reference_state():
    with open('state/machine.state', 'r') as f:
        lines = f.readlines()

    registers = [-999999999999] * 32
    state = {}
    for line in lines:
        name, value = line.strip().split(' ')
        value = int(value)
        if name.startswith('x'):
            registers[int(name[1:])] = value
        else:
            state[name] = value

    with open('state/memory.dump', 'rb') as f:
        binary = f.read()

    assert len(binary) == (1 << 24) * 4

    memory = []
    for i in range(len(binary) // 4):
        value = (binary[i * 4]) | (binary[i * 4 + 1] << 8) | (binary[i * 4 + 2] << 16) | (binary[i * 4 + 3] << 24)
        memory.append(value)

    return State(state, registers, memory)

def load_minecraft_state():
    data = load(os.path.join(args.world_path, 'data/command_storage_riscv.dat'))
    checkpoint = data.compound.get('data').get('contents').get('checkpoint')

    registers = [-999999999999] * 32
    for name, value in checkpoint.get('registers').items():
        intval = int(value)
        if intval < 0:
            intval += 2**32
        registers[int(name[1:])] = intval

    mem = checkpoint.get('mem')
    memory = [0] * (1 << 24)

    addr = 0
    for l0 in mem:
        for l1 in l0:
            for l2 in l1:
                intval = int(l2)
                if intval < 0:
                    intval += 2**32
                memory[addr] = intval
                addr += 1

    state = {}
    for key, value in checkpoint.items():
        if key not in ['mem', 'registers']:
            intval = int(value)
            if intval < 0:
                intval += 2**32
            state[key] = intval

    return State(state, registers, memory)

print('loading reference state')
expected = load_reference_state()
print('loading minecraft state')
actual = load_minecraft_state()

if expected.state['totalcycles'] != actual.state['totalcycles']:
    print(f'warning: expected snapshot was taken at cycle {expected.state["totalcycles"]}')
    print(f'and actual snapshot at cycle {actual.state["totalcycles"]}')

registers_ok = True
for i in range(32):
    if expected.registers[i] != actual.registers[i]:
        print(f'register mismatch for x{i}: expected={expected.registers[i]}, actual={actual.registers[i]}')
        registers_ok = False
if registers_ok:
    print('registers ok')

state_ok = True
for key in expected.state.keys():
    e = expected.state[key]
    a = actual.state[key]
    if e != a:
        print(f'state mismatch for {key}: expected={e}, actual={a}')
        state_ok = False
if state_ok:
    print('state ok')

memory_errors = 0
for i in range(1 << 24):
    e = expected.memory[i]
    a = actual.memory[i]
    if e != a:
        memory_errors += 1
        if memory_errors <= 10:
            print(f'memory mismatch at {i}: expected={e}, actual={a}')

if memory_errors == 0:
    print('memory ok')
else:
    print(f'{memory_errors} memory errors')

if memory_errors != 0 or not registers_ok or not state_ok:
    sys.exit(1)
