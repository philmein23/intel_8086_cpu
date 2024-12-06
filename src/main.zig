const std = @import("std");

const Instruction = struct {
    mneumonic: Mneumonic,
    op_code: OpCode,
    operands: [2]Operand,

    pub fn generate_reg_rm_instruct(self: *Instruction, w_bit: u8, d_bit: u8, reg_bits: u8, rm_bits: u8, displacement_byte: ?u16) !void {
        var op_reg = Operand{ .register = undefined };
        op_reg.register = try Instruction.from_reg_bits(w_bit, reg_bits);

        var op_rm = Operand{ .memory = undefined };

        const disp_byte = if (displacement_byte != null) @as(u16, displacement_byte.?) else null;
        switch (rm_bits) {
            0b00000000 => {
                op_rm.memory.p1 = .bx;
                op_rm.memory.p2 = .si;
                op_rm.memory.displacement = disp_byte;
            },
            0b00000001 => {
                op_rm.memory.p1 = .bx;
                op_rm.memory.p2 = .di;
                op_rm.memory.displacement = disp_byte;
            },
            0b00000010 => {
                op_rm.memory.p1 = .bp;
                op_rm.memory.p2 = .si;
                op_rm.memory.displacement = disp_byte;
            },
            0b00000011 => {
                op_rm.memory.p1 = .bp;
                op_rm.memory.p2 = .di;
                op_rm.memory.displacement = disp_byte;
            },
            0b00000100 => {
                op_rm.memory.p1 = .si;
                op_rm.memory.p2 = null;
                op_rm.memory.displacement = disp_byte;
            },
            0b00000101 => {
                op_rm.memory.p1 = .di;
                op_rm.memory.p2 = null;
                op_rm.memory.displacement = disp_byte;
            },
            0b00000110 => {
                op_rm.memory.p1 = .bp;
                op_rm.memory.p2 = null;
                op_rm.memory.displacement = disp_byte;
            },
            0b00000111 => {
                op_rm.memory.p1 = .bx;
                op_rm.memory.p2 = null;
                op_rm.memory.displacement = disp_byte;
            },
            else => return error.UnknownRMRegisterBits,
        }

        if (d_bit == 0b00000000) {
            self.operands[0] = op_rm;
            self.operands[1] = op_reg;
        } else {
            self.operands[0] = op_reg;
            self.operands[1] = op_rm;
        }
    }

    pub fn from_reg_bits(w_bit: u8, register_operand: u8) !Register {
        switch (register_operand) {
            0b00000000 => {
                return if (w_bit == 0b00000000) .al else .ax;
            },
            0b00000001 => {
                return if (w_bit == 0b00000000) .cl else .cx;
            },
            0b00000010 => {
                return if (w_bit == 0b00000000) .dl else .dx;
            },
            0b00000011 => {
                return if (w_bit == 0b00000000) .bl else .bx;
            },
            0b00000100 => {
                return if (w_bit == 0b00000000) .ah else .sp;
            },
            0b00000101 => {
                return if (w_bit == 0b00000000) .ch else .bp;
            },
            0b00000110 => {
                return if (w_bit == 0b00000000) .dh else .si;
            },
            0b00000111 => {
                return if (w_bit == 0b00000000) .bh else .di;
            },
            else => {
                return error.UnknownRegOperand;
            },
        }
    }

    const Mneumonic = enum { mov, none };

    const OpCode = enum(u8) {
        reg_rm,
        imm,
        accum,
        no_op,

        pub fn from_binary(bin: u8) OpCode {
            switch (bin) {
                0b00100010 => {
                    std.debug.print("R/M to/from REG OPCODE:      0b{b:0>6}\n", .{bin});
                    return .reg_rm;
                },
                else => {
                    return .no_op;
                },
            }
        }
    };

    pub fn format(self: *Instruction) ![]const u8 {
        switch (self.op_code) {
            .reg_rm => {
                var buf: [32]u8 = undefined;
                var buf2: [32]u8 = undefined;
                var buf3: [32]u8 = undefined;

                const fmt_slice = try std.fmt.bufPrint(
                    &buf,
                    "mov {s}, {s}\n",
                    .{ switch (self.operands[0]) {
                        .register => |reg| reg.to_str(),
                        .memory => |mem| try std.fmt.bufPrint(&buf3, "[{s}{s}{s}]", .{
                            mem.p1.to_str(),
                            if (mem.p2) |p2| try std.fmt.bufPrint(&buf2, " + {s}", .{p2.to_str()}) else "",
                            if (mem.displacement) |d| if (d > 0) try std.fmt.bufPrint(&buf2, " + {d}", .{d}) else "" else "",
                        }),
                    }, switch (self.operands[1]) {
                        .register => |reg| reg.to_str(),
                        .memory => |mem| try std.fmt.bufPrint(&buf2, "[{s}{s}{s}]", .{
                            mem.p1.to_str(),
                            if (mem.p2) |p2| try std.fmt.bufPrint(&buf3, " + {s}", .{p2.to_str()}) else "",
                            if (mem.displacement) |d| if (d > 0) try std.fmt.bufPrint(&buf3, " + {d}", .{d}) else "" else "",
                        }),
                    } },
                );

                return fmt_slice;
            },
            else => {
                return error.UnknownInstruction;
            },
        }
    }
};

const Operand = union(enum) {
    register: Register,
    memory: MemoryAddress,

    const MemoryAddress = struct {
        displacement: ?u16,
        p1: Register,
        p2: ?Register,
    };
};

const Register = enum {
    al,
    ax,
    cl,
    cx,
    dl,
    dx,
    bl,
    bx,
    ah,
    sp,
    ch,
    bp,
    dh,
    si,
    bh,
    di,

    pub fn to_str(self: Register) []const u8 {
        return switch (self) {
            .al => "al",
            .ax => "ax",
            .cl => "cl",
            .cx => "cx",
            .dl => "dl",
            .dx => "dx",
            .bl => "bl",
            .bx => "bx",
            .ah => "ah",
            .sp => "sp",
            .ch => "ch",
            .bp => "bp",
            .dh => "dh",
            .si => "si",
            .bh => "bh",
            .di => "di",
        };
    }
};

pub fn main() !void {
    const cwd = std.fs.cwd();
    // const file = try cwd.openFile("listing_0037_single_register_mov", .{});
    const file = try cwd.openFile("test_destination-3", .{});
    defer file.close();

    var read_buf: [5]u8 = undefined;

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const num_bytes_read = try reader.read(&read_buf);

    std.debug.print("Buffer read: 0b{b:0>8}, num_bytes_read: {any}\n", .{
        read_buf,
        num_bytes_read,
    });

    const first_byte = read_buf[0];
    const first_six_bits = (first_byte >> 2) & 0b111111;

    // testing
    const first_six_bits_two = (first_byte >> 2) & 0b111101;
    std.debug.print("first six bits:       0b{b:0>8}\n", .{first_six_bits_two});

    const d_bit = (first_byte >> 1) & 0b1;
    std.debug.print("d bit:       0b{b:0>1}\n", .{d_bit});

    const w_bit = (first_byte & 0b1);
    std.debug.print("w bit:       0b{b:0>1}\n", .{w_bit});

    const second_byte = read_buf[1];
    const mod_bits = (second_byte >> 6) & 0b11;
    std.debug.print("mod bits:       0b{b:0>2}\n", .{mod_bits});

    const op_code = Instruction.OpCode.from_binary(first_six_bits);

    var instruction = Instruction{
        .mneumonic = undefined,
        .op_code = op_code,
        .operands = undefined,
    };

    switch (op_code) {
        .reg_rm => {
            instruction.mneumonic = .mov;
        },
        else => {
            instruction.mneumonic = .none;
        },
    }

    const reg_register_bits = (second_byte >> 3) & 0b111;
    std.debug.print("reg register bits:       0b{b:0>3}\n", .{reg_register_bits});

    const rm_register_bits = second_byte & 0b111;
    std.debug.print("rm register bits:       0b{b:0>3}\n", .{rm_register_bits});

    switch (mod_bits) {
        0b00000011 => {
            var op_reg = Operand{ .register = undefined };
            op_reg.register = try Instruction.from_reg_bits(w_bit, reg_register_bits);

            var op_rm = Operand{ .register = undefined };
            op_rm.register = try Instruction.from_reg_bits(w_bit, rm_register_bits);

            if (d_bit == 0b00000000) {
                instruction.operands[0] = op_rm;
                instruction.operands[1] = op_reg;
            } else {
                instruction.operands[0] = op_reg;
                instruction.operands[1] = op_rm;
            }
        },
        0b00000000 => {
            try instruction.generate_reg_rm_instruct(w_bit, d_bit, reg_register_bits, rm_register_bits, null);
        },
        0b00000001 => {
            try instruction.generate_reg_rm_instruct(w_bit, d_bit, reg_register_bits, rm_register_bits, read_buf[2]);
        },
        0b00000010 => {
            // For 16-bit displacement, combine low byte and high byte
            const displacement: u16 = (@as(u16, read_buf[3]) << 8) | @as(u16, read_buf[2]);
            try instruction.generate_reg_rm_instruct(w_bit, d_bit, reg_register_bits, rm_register_bits, displacement);
        },
        else => return error.UnknownModEncoding,
    }

    const writer = std.io.getStdOut().writer();
    const formatted_instr = try instruction.format();
    _ = try writer.write(formatted_instr);

    std.debug.print("Instruction: {s}\n", .{formatted_instr});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
