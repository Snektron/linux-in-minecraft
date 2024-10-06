#!/usr/bin/env python3
import argparse
import os.path
from amulet_nbt import load, ListTag, IntTag, CompoundTag, NamedTag

ap = argparse.ArgumentParser(description="initialize memory data storage nbt with a risc-v image")
ap.add_argument('world_path', type=str, help='Path to minecraft world')
ap.add_argument('--image-path', type=str, default='images/Image', help='Path to image to write to memory')
ap.add_argument('--dtb-path', type=str, default='images/sixtyfourmb.dtb', help='Path to dtb to write to memory')
args = ap.parse_args()

total_words = 256 ** 3
total_mem = total_words * 4
memory = [0] * total_words

print('reading image', args.image_path)
with open(args.image_path, 'rb') as f:
    image = f.read()
assert len(image) % 4 == 0 # No thumb

for i in range(len(image) // 4):
    value = (image[i * 4]) | (image[i * 4 + 1] << 8) | (image[i * 4 + 2] << 16) | (image[i * 4 + 3] << 24)
    memory[i] = value

print('reading dtb', args.dtb_path)
with open(args.dtb_path, 'rb') as f:
    dtb = f.read()

# Linux image is about 2.5MB.
# Place the DTB at a fixed address for easier initializing
# Note that this is the physical address, the virtual address will
# be at 0x83000000.
dtb_offset = 0x3000000
assert i * 4 < dtb_offset
assert len(dtb) + dtb_offset < total_mem

for i in range((len(dtb) + 3) // 4):
    value = (dtb[i * 4]) | (dtb[i * 4 + 1] << 8) | (dtb[i * 4 + 2] << 16) | (dtb[i * 4 + 3] << 24)
    memory[i + dtb_offset // 4] = value

print('creating nbt memory tree')
addr = 0
l0 = ListTag()
for i0 in range(256):
    l1 = ListTag()
    for i1 in range(256):
        l2 = ListTag()
        for i2 in range(256):
            l2.append(IntTag(memory[addr]))
            addr += 1
        l1.append(l2)
    l0.append(l1)

data = NamedTag(CompoundTag({
    'data': CompoundTag({
        'contents': CompoundTag({
            'mem': CompoundTag({
                'rom': l0
            })
        })
    })
}))

out = os.path.join(args.world_path, 'data/command_storage_memory.dat')
print('saving command storage to', out)
data.save_to(out)
