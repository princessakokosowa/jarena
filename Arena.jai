ARENA_DEFAULT_SIZE      :: 65536;
ARENA_DEFAULT_ALIGNMENT :: 8;

align :: (size: int, alignment: int) -> int {
    mask := ~(alignment - 1);
    _    := size + (alignment - 1);

    return _ & mask;
}

Arena :: struct {
    alignment: int = ARENA_DEFAULT_ALIGNMENT;
    size     : int = ARENA_DEFAULT_SIZE;

    occupied: int = 0;
    last    : int = 0;
    ptr     : *u8 = null;

    should_overwrite: bool = false;
};

arena_allocator_proc :: (mode: Allocator_Mode, size_to_be_allocated_or_resized: s64, old_size: s64, ptr_to_be_resized_or_freed: *void, proc_data: *void) -> *void {
    arena := cast(*Arena) proc_data;

    if #complete mode == {
      case .FREE;
        return null;
      case .RESIZE;
        Basic.assert(ptr_to_be_resized_or_freed != null);

        is_this_the_previous_allocation := arena.ptr + arena.last == cast(*u8) ptr_to_be_resized_or_freed;
        if is_this_the_previous_allocation {
            previous_allocation_size := arena.occupied - arena.last;
            allocation_size          := size_to_be_allocated_or_resized - previous_allocation_size;
            aligned_allocation_size  := align(allocation_size, ARENA_DEFAULT_ALIGNMENT);

            Basic.assert(arena.occupied + aligned_allocation_size <= arena.size);

            arena.occupied += aligned_allocation_size;

            return ptr_to_be_resized_or_freed;
        }

        Basic.assert(arena.occupied + size_to_be_allocated_or_resized <= arena.size);

        aligned_allocation_size := align(size_to_be_allocated_or_resized, ARENA_DEFAULT_ALIGNMENT);
        chunk                   := arena.ptr + arena.occupied;

        arena.occupied += aligned_allocation_size;

        for 0..size_to_be_allocated_or_resized - 1 {
            chunk[it] = (cast(*u8) ptr_to_be_resized_or_freed)[it];
        }

        return chunk;
      case .ALLOCATE;
        Basic.assert(arena.occupied + size_to_be_allocated_or_resized <= arena.size);

        if !arena.ptr arena.ptr = alloc(arena.size);

        aligned_allocation_size := align(size_to_be_allocated_or_resized, ARENA_DEFAULT_ALIGNMENT);
        chunk                   := arena.ptr + arena.occupied;

        arena.last     =  arena.occupied;
        arena.occupied += aligned_allocation_size;

        return chunk;

      case .STARTUP;
        #through;
      case .SHUTDOWN;
        Basic.assert(false, "Starting up and shutting down the underlying implementation is not supported!.\n");

        return null;

      case .THREAD_START;
        #through;
      case .THREAD_STOP;
        Basic.assert(false, "Multithreaded access is not supported!.\n");

        return null;

      case .CREATE_HEAP;
        #through;
      case .DESTROY_HEAP;
        Basic.assert(false, "Creating and destroying heaps in the underlying implementation is not supported!.\n");

        return null;

      case .IS_THIS_YOURS;
        #through;

      case .CAPS;
        Basic.assert(false, "Querying for caps is not supported!.\n");

        return null;
    }
}

Arena_destroy :: (arena: *Arena) {
    if arena.ptr free(arena.ptr);

    << arena = Arena.{};

    arena.alignment        = ARENA_DEFAULT_ALIGNMENT;
    arena.size             = ARENA_DEFAULT_SIZE;
    arena.should_overwrite = false;
}

Arena_get :: (arena: *Arena, size_to_be_allocated: int) -> *void {
    return arena_allocator_proc(Allocator_Mode.ALLOCATE, size_to_be_allocated, 0, null, cast(*void) arena);
}

Arena_allocator :: (arena: *Arena) -> Allocator {
    return .{
        proc = arena_allocator_proc,
        data = arena,
    };
}

Basic :: #import "Basic";
