import io, re, sys

if len(sys.argv) == 2:
    output_dir = sys.argv[1]
else:
    print("Usage: cat <file> | python3 {} <output-dir>".format(sys.argv[0]), file=sys.stderr)
    sys.exit(2)

with io.open(sys.stdin.fileno(),'r',encoding='latin-1') as input:
    for line in input:
        result = re.match(r'^1\s+\d+\s+\d+\s+\d+\s+([a-zA-Z0-9]+).*$', line)
        if result:
            code = result.group(1)
            filename = "{}/{}.apt.dat".format(output_dir, code)
            with open(filename, 'w') as output:
                print(line, file=output, end='')
                for line in input:
                    if re.match(r'^\s+$', line):
                        break
                    print(line, file=output, end='')
