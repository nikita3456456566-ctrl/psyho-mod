#pragma once
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <cstdint>

namespace PSY {
class Memory {
public:
    static bool Read(uint64_t addr, void* out, size_t size) {
        if (!addr || !out || !size) return false;
        vm_size_t read_bytes = 0;
        kern_return_t kr = vm_read_overwrite(
            mach_task_self(),
            (vm_address_t)addr,
            (vm_size_t)size,
            (vm_address_t)out,
            &read_bytes
        );
        return (kr == KERN_SUCCESS) && (read_bytes == size);
    }

    template<typename T>
    static T Read(uint64_t addr) {
        T val{};
        Read(addr, &val, sizeof(T));
        return val;
    }
};
}
