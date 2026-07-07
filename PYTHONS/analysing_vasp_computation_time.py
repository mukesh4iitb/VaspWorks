## source: Search LOOP keyword here: https://vasp.at/tutorials/latest/magnetism/part1/

print("\nusing loop_time.txt:")

with open("OUTCAR") as infile, open("loop_time.txt", "w") as outfile:
    for line in infile:
        if "LOOP:" in line:
            outfile.write(line)

with open("loop_time.txt") as f:
    lines=f.readlines()

cpu_time = []
real_time = []
for line in lines:
    parts = line.split()
    cpu_time.append(float(parts[3].strip(":")))
    real_time.append(float(parts[-1]))

print("cpu_time:", sum(cpu_time))
print("real_time:", sum(real_time))



print("\nusing loopp_time.txt:")

with open("OUTCAR") as infile, open("loop_time.txt", "w") as outfile:
    for line in infile:
        if "LOOP:" in line:
            outfile.write(line)

with open("loopp_time.txt") as f:
    lines=f.readlines()

cpu_time = []
real_time = []
for line in lines:
    parts = line.split()
    cpu_time.append(float(parts[3].strip(":")))
    real_time.append(float(parts[-1]))

print("cpu_time:", sum(cpu_time))
print("real_time:", sum(real_time))
print("\nLatter (on using LOOP+:) is very close to the time reported by VASP. It is litter lower that VASP reproted time as few seconds are required to wrap-up all the calculation and writing files.")
print("\nFurther, note that time using LOOP: is a bit more lower than that of LOOP+ as each iteration required sometimet after completing the electronic loop to go the next ionic loop.\n")
