const std = @import("std");

const Instruction = struct {
    op_code: OpCode,
    operands: [2]Operand,

    pub fn set_reg_field_encoding(w_bit: u8, register_operand: u8) !Register {
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

    const OpCode = enum(u6) {
        mov,
        no_op,

        pub fn from_binary(bin: u6) OpCode {
            switch (bin) {
                0b100010 => {
                    std.debug.print("Reg-to-reg OPCODE:      0b{b:0>6}\n", .{bin});
                    return .mov;
                },
                else => {
                    return .no_op;
                },
            }
        }

        pub fn to_str(self: OpCode) []const u8 {
            switch (self) {
                .mov => {
                    return "mov";
                },
                else => {
                    return "nada";
                },
            }
        }
    };

    pub fn format(self: *Instruction) ![]const u8 {
        switch (self.op_code) {
            .mov => {
                var buf: [32]u8 = undefined;

                const fmt_slice = try std.fmt.bufPrint(&buf, "{s} {s}, {s}", .{
                    self.op_code.to_str(),
                    self.operands[0].register.to_str(),
                    self.operands[1].register.to_str(),
                });

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

    const MemoryAddress = struct {};
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
    const file = try cwd.openFile("listing_0038_many_register_mov", .{});
    defer file.close();

    var read_buf: [22]u8 = undefined;

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const num_bytes_read = try reader.read(&read_buf);

    const first_byte = read_buf[0];
    const first_six_bits = (first_byte >> 2) & 0b111111;

    const d_bit = (first_byte >> 1) & 0b1;
    std.debug.print("d bit:       0b{b:0>1}\n", .{d_bit});

    const w_bit = (first_byte & 0b1);
    std.debug.print("w bit:       0b{b:0>1}\n", .{w_bit});

    const second_byte = read_buf[1];
    const mod_bits = (second_byte >> 6) & 0b11;
    std.debug.print("mod bits:       0b{b:0>2}\n", .{mod_bits});

    const bits: u6 = @intCast(first_six_bits);
    const op_code = Instruction.OpCode.from_binary(bits);

    var instruction = Instruction{
        .op_code = op_code,
        .operands = undefined,
    };

    const reg_register_bits = (second_byte >> 3) & 0b111;
    std.debug.print("reg register bits:       0b{b:0>3}\n", .{reg_register_bits});

    const rm_register_bits = second_byte & 0b111;
    std.debug.print("rm register bits:       0b{b:0>3}\n", .{rm_register_bits});

    switch (mod_bits) {
        0b00000011 => {
            var op_reg = Operand{ .register = undefined };
            op_reg.register = try Instruction.set_reg_field_encoding(w_bit, reg_register_bits);

            var op_rm = Operand{ .register = undefined };
            op_rm.register = try Instruction.set_reg_field_encoding(w_bit, rm_register_bits);

            if (d_bit == 0b00000000) {
                instruction.operands[0] = op_rm;
                instruction.operands[1] = op_reg;
            } else {
                instruction.operands[0] = op_reg;
                instruction.operands[1] = op_rm;
            }
        },
        0b00000000 => {},
        0b00000001 => {},
        0b00000010 => {},
        else => return error.UnknownModEncoding,
    }

    std.debug.print("Buffer read: {b}, num_bytes_read: {any}\n", .{
        read_buf,
        num_bytes_read,
    });

    std.debug.print("Instruction: {s}\n", .{try instruction.format()});
    // character encoding for asm instruction looks unreadable - not sure how to fix
    // const write_file = try cwd.createFile("mov_single_register.asm", .{ .read = true });
    // defer write_file.close();

    // var buf_writer = std.io.bufferedWriter(write_file.writer());
    // const writer = buf_writer.writer();
    //
    // const writer = write_file.writer();

    // var fmt_instruction_buf: [100]u8 = undefined;
    //
    // const fmt_slice = try std.fmt.bufPrint(&fmt_instruction_buf, "{s}\n", .{try instruction.format()});

    // try writer.writeAll("bits 16\n");
    // try writer.writeAll(fmt_slice);

    // try buf_writer.flush();

    // std.debug.print("BufWriter wrikkte - written: {any}\n", .{
    //     num_bytes_written,
    // });
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
