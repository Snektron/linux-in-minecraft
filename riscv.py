def assemble(inp, test = False):
    import subprocess
    import tempfile
    import os.path
    import sys

    with tempfile.TemporaryDirectory() as tmpd:
        # This is the most flexible way because eval is annoying and wont let us call other defs
        if isinstance(inp, str):
            # Assume its a path
            ass_path = inp
            with open(ass_path, 'r') as f:
                lines = [line.strip() for line in f.readlines()]
        elif isinstance(inp, list):
            ass_path = os.path.join(tmpd, 'assembly.s')
            lines = inp
            with open(ass_path, 'w') as f:
                f.write('\n'.join(inp))
        else:
            assert False

        elf_path = os.path.join(tmpd, 'assembly.elf')
        bin_path = os.path.join(tmpd, 'assembly.bin')

        try:
            subprocess.run(
                [
                    'zig',
                    'cc',
                    '-target',
                    'riscv32-freestanding-none',
                    '-mcpu=generic_rv32+i+m+a',
                    ass_path,
                    '-c',
                    '-o',
                    elf_path,
                    '-T',
                    './minecraft.ld',
                ],
                check=True,
                capture_output=True,
            )
        except subprocess.CalledProcessError as e:
            print('failed to assemble input:')
            print('    ' + '\n    '.join(lines))
            print(e.stderr.decode('utf-8'), end='')
            print('error:')
            sys.exit(1)

        subprocess.run(
            [
                'llvm-objcopy',
                '-O',
                'binary',
                elf_path,
                bin_path
            ],
            check=True,
        )

        with open(bin_path, 'rb') as f:
            binary = f.read()

        assert len(binary) % 4 == 0 # No thumb

        # Convert to output by converting each 4 bytes to binary
        values = []
        for i in range(len(binary) // 4):
            value = (binary[i * 4]) | (binary[i * 4 + 1] << 8) | (binary[i * 4 + 2] << 16) | (binary[i * 4 + 3] << 24)
            # Minecraft needs signed 32-bit values
            if value >= 2**31:
                value -= 2**32
            values.append(value)
        return values

def run(binary, timermatchl, timermatchh):
    import subprocess
    stdin = '\n'.join([str(v) for v in binary]) + '\nend\n'
    result = subprocess.run(["zig", "build", "validate", "--", str(timermatchl), str(timermatchh)], input=stdin, text=True, capture_output=True)
    if len(result.stderr) > 0:
        print('error:', result.stderr)
    if result.returncode != 0:
        raise ValueError()
    registers = result.stdout.strip().split('\n')
    registers = [int(line) for line in registers]
    registers = [value - 2**32 if value >= 2**31 else value for value in registers]
    return registers

def print_char_json_escape(i):
    if i == ord('@'):
        # For some reason @ doesn't work
        return '?'
    elif i == ord('\t'):
        return '    '
    elif i == ord('\\'):
        return '\\\\\\\\' # The Elder Backslash...
    elif i == ord('"'):
        return '\\\\\\"'
    elif i < 32:
        # Just don't print all of these
        return ''
    elif i <= 127:
        return chr(i)
    return '?'

if __name__ == '__main__':
    print(assemble([
        "addi x1, x0, 123",
        "addi x1, x0, 356",
    ]))
