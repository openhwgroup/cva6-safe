import argparse
from string import Template
import functools

cpus_template = Template("""  cpus {
    #address-cells = <1>;
    #size-cells = <0>;
    timebase-frequency = <32768>; // 32.768 kHz
${cpu_instances}
  };""")

cpu_template = Template("""    CPU${cpuid}: cpu@${cpuid} {
      clock-frequency = <50000000>; // 50 MHz
      device_type = "cpu";
      reg = <${cpuid}>;
      status = "okay";
      compatible = "eth, ariane", "riscv";
      riscv,isa = "${isa}";
      mmu-type = "riscv,${mmu}";
      tlb-split;
      // HLIC - hart local interrupt controller
      CPU${cpuid}_intc: interrupt-controller {
        #interrupt-cells = <1>;
        interrupt-controller;
        compatible = "riscv,cpu-intc";
      };
    };""")

mem_template = Template("""  memory@${mbase} {
    device_type = "memory";
    reg = <0x0 0x${mbase} 0x0 0x${msize}>;
  };""")

interrupts_extended_template = Template(
  "<&CPU${cpuid}_intc ${int1} &CPU${cpuid}_intc ${int2}>")

clint_template = Template("""    clint@2000000 {
      compatible = "riscv,clint0";
      interrupts-extended = ${ints};
      reg = <0x0 0x2000000 0x0 0xc0000>;
      reg-names = "control";
    };""")

plic_template = Template("""    // PLIC needs to be disabeld for tandem verification
    PLIC0: interrupt-controller@c000000 {
      #address-cells = <0>;
      #interrupt-cells = <1>;
      compatible = "sifive,plic-1.0.0", "riscv,plic0";
      interrupt-controller;
      interrupts-extended = ${ints};
      reg = <0x0 0xc000000 0x0 0x4000000>;
      riscv,max-priority = <7>;
      riscv,ndev = <2>;
    };""")
  
root_template = Template("""/dts-v1/;

/ {
  #address-cells = <2>;
  #size-cells = <2>;
  compatible = "eth,ariane-bare-dev";
  model = "eth,ariane-bare";
${cpus}
${mem}
  soc {
    #address-cells = <2>;
    #size-cells = <2>;
    compatible = "eth,ariane-bare-soc", "simple-bus";
    ranges;
${clint}
${plic}
    // Specifying the interrupt controller in the devicetree is not necessary.
    // Furthermore, the IRQ 65535 will cause a `hwirq 0xffff is too large` during
    // Linux boot (occured with mainline linux 5.14.0).
    // debug-controller@0 {
    //   compatible = "riscv,debug-013";
    //   interrupts-extended = <&CPU0_intc 65535>;
    //   reg = <0x0 0x0 0x0 0x1000>;
    //   reg-names = "control";
    // };
    uart@10000000 {
      compatible = "ns16550a";
      reg = <0x0 0x10000000 0x0 0x1000>;
      clock-frequency = <50000000>;
      current-speed = <115200>;
      interrupt-parent = <&PLIC0>;
      interrupts = <1>;
      reg-shift = <2>; // regs are spaced on 32 bit boundary
      reg-io-width = <4>; // only 32-bit access are supported
    };
    timer@18000000 {
      compatible = "pulp,apb_timer";
      interrupts = <0x00000004 0x00000005 0x00000006 0x00000007>;
      reg = <0x00000000 0x18000000 0x00000000 0x00001000>;
      interrupt-parent = <&PLIC0>;
      reg-names = "control";
    };
  };
};
""")

parser = argparse.ArgumentParser(
  prog='gen_dts',
  description='DTS generator for RISC-V AMP configurations',
  epilog='Contact: Daniel Gracia Pérez <daniel.gracia-perez@thalesgroup.com>'
)

parser.add_argument('ofile', nargs=1, help="Output file name")
parser.add_argument('-n', '--num-cores', dest="ncores", default=1, type=int,
  help='Number of cores (default = 1)')
parser.add_argument('-i', '--isa', dest="isa", default='rv32imac',
  help='ISA of the cores (default = "rv32imac")')
parser.add_argument('-m', '--mmu', dest="mmu", default='sv32',
  help='MMU configuration (default = "sv32")')
parser.add_argument('--mem-base-address', dest='mbase',
  default=0x80000000, type=functools.wraps(int)(lambda x: int(x,0)),
  help="Base address of the memory (default = 0x80000000)")
parser.add_argument('--mem-size', dest='msize',
  default=0x10000000, type=functools.wraps(int)(lambda x: int(x,0)),
  help="Memory size in hexadecimal format (default = 0x10000000)")

args = parser.parse_args()

with open(args.ofile[0], "w") as f:
    cpu_insts = ''
    for i in range(args.ncores):
        cpu_inst = cpu_template.substitute(cpuid=i, isa=args.isa, mmu=args.mmu)
        if i == 0:
            cpu_insts = cpu_insts + cpu_inst
        else:
            cpu_insts = cpu_insts + "\n" + cpu_inst
    cpus = cpus_template.substitute(cpu_instances=cpu_insts)
    mem = mem_template.substitute(
        mbase=f'{args.mbase:x}', msize=f'{args.msize:x}')
    clint_ints = ''
    for i in range(args.ncores):
        if i > 0:
            clint_ints = clint_ints + ','
        clint_ints = clint_ints + interrupts_extended_template.substitute(
            cpuid=i, int1=3, int2=7)
    clint = clint_template.substitute(ints=clint_ints)
    plic_ints = ''
    for i in range(args.ncores):
        if i > 0:
            plic_ints = plic_ints + ','
        plic_ints = plic_ints + interrupts_extended_template.substitute(
            cpuid=i, int1=11, int2=9)
    plic = plic_template.substitute(ints=plic_ints)
    root = root_template.substitute(
        cpus=cpus, mem=mem, clint=clint, plic=plic)
    f.write(root)
