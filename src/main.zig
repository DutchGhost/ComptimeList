const std = @import("std");
const mem = std.mem;

pub fn ComptimeList(comptime T: type) type {
    return struct {
        const Self = @This();

        slice: []T,
        idx: usize = 0,

        pub fn init(comptime size: usize) Self {
            comptime var array: [size]T = undefined;

            return Self{ .slice = &array };
        }

        pub fn fromSlice(comptime slice: []const T) Self {
            var self = Self.init(slice.len);
            mem.copy(T, self.slice, slice);
            return self;
        }

        pub fn len(comptime self: *const Self) usize {
            return self.idx;
        }

        pub fn isEmpty(comptime self: *const Self) bool {
            return self.idx == 0;
        }

        pub fn append(comptime self: *Self, value: T) !void {
            if (self.needsGrowFor(1)) {
                self.grow(1);
            }

            self.slice[self.idx] = value;
            self.idx += 1;
        }

        pub fn appendSlice(comptime self: *Self, slice: []const T) !void {
            if (self.needsGrowFor(slice.len)) {
                self.grow(slice.len);
            }

            mem.copy(T, self.slice[self.idx..], slice);
            self.idx += slice.len;
        }

        pub fn pop(comptime self: *Self) ?T {
            if (self.isEmpty()) {
                return null;
            } else {
                const popped = self.slice[self.idx];
                self.idx -= 1;
                return popped;
            }
        }

        pub fn asConstSlice(comptime self: *const Self) []const T {
            return self.slice[0..self.idx];
        }

        pub fn asSlice(comptime self: *Self) []T {
            return self.slice[0..self.idx];
        }

        fn needsGrowFor(comptime self: *const Self, comptime size: usize) bool {
            return self.idx + size >= self.slice.len;
        }

        fn grow(comptime self: *Self, comptime size: usize) void {
            const length = self.slice.len;
            const requiredLength = length + size;
            const newLength = blk: {
                var new = length * 2;

                while (new <= requiredLength) : ({
                    new *= 2;
                }) {}

                break :blk new;
            };

            comptime var new: [newLength]T = undefined;

            mem.copy(T, new[0..], self.slice);
            self.slice = &new;
        }
    };
}

const testing = @import("std").testing;

test "push test" {
    comptime {
        var list = ComptimeList(usize).init(1);

        try list.append(20);
        try list.append(30);

        try testing.expectEqualSlices(usize, list.asConstSlice(), &.{ 20, 30 });
    }
}

test "appendSlice" {
    comptime {
        var list = ComptimeList(usize).init(1);

        try list.appendSlice(&.{ 20, 30, 40, 50, 60, 70, 80 });
        try testing.expectEqual(list.len(), 7);
        try testing.expectEqualSlices(usize, list.asConstSlice(), &.{ 20, 30, 40, 50, 60, 70, 80 });
    }
}
