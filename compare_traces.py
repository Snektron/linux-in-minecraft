#!/usr/bin/env python3
import argparse
import sys

ap = argparse.ArgumentParser()
ap.add_argument('expected', type=str)
ap.add_argument('actual', type=str)
args = ap.parse_args()

def read_minirv_trace(path):
    trace = {}
    with open(path, 'r') as f:
        lines = f.readlines()
    for line in lines:
        parts = line.strip().replace(']', '').replace('[', '').split(' ')
        pc = int(parts[1], 16)
        inst = int(parts[2], 0)
        cycle = int(parts[3])
        regs = [int(x.split(':')[1], 16) for x in parts[4:]]
        trace[cycle] = (pc, inst, regs)
    return trace

def read_minecraft_trace(path):
    trace = {}
    with open(path, 'r') as f:
        lines = f.readlines()

    start = 0
    for i, line in enumerate(lines):
        if 'executing -2147483648 cycle 0' in line:
            start = i

    cycle = None
    regs = [0] * 32
    for line in lines[start:]:
        try:
            a = line.index('[CHAT]')
        except ValueError:
            continue

        line = line[a:].strip()
        if 'machine state:' in line:
            parts = line.replace('=',' ').split(' ')
            inst = int(parts[4])
            pc = int(parts[6])
            cycle = int(parts[12])
            if pc < 0:
                pc += 2**32
            if inst < 0:
                inst += 2**32
            if cycle < 0:
                cycle += 2**32
        elif any(x in line for x in ['x00', 'x08', 'x16', 'x24']):
            parts = line.replace('=',' ').replace('x', '').split(' ')
            for i in range(1, 16, 2):
                regs[int(parts[i])] = int(parts[i + 1])
            if 'x24' in line:
                trace[cycle] = (pc, inst, [r + 2**32 if r < 0 else r for r in regs])
    return trace

expected = read_minirv_trace(args.expected)
actual = read_minecraft_trace(args.actual)

# print(actual[73817])
# print(expected[73817])

expected_cycles = max(expected.keys())
actual_cycles = max(actual.keys())

print(expected_cycles, actual_cycles)
for cycle in range(min(expected_cycles, actual_cycles)):
    e_pc, e_inst, e_regs = expected[cycle]
    a_pc, ax_inst, a_regs = actual[cycle]
    a_inst = actual[cycle + 1][1]
    if e_pc != a_pc:
        print(f'{cycle} PC differs: expected={e_pc} actual={a_pc}')
        break
    if e_inst != a_inst:
        print(f'{cycle} INST differs: expected={e_inst} actual={a_inst}')
        break
    if e_regs != a_regs:
        print(f'{cycle} REGS differ:')
        print('expected:', ' '.join([f'x{i}={v}' for i, v in enumerate(e_regs)]))
        print('actual  :', ' '.join([f'x{i}={v}' for i, v in enumerate(a_regs)]))
        print(ax_inst)
        break
