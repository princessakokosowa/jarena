main :: () {
    arena: Arena;
    defer Arena_destroy(*arena);

    {
        arena_type_info := type_info(type_of(arena));

        print("Type information for % struct:\n%\n", arena_type_info.name, << arena_type_info);
    }

    ARRAY_COUNT :: 256;
    ARRAY_SIZE  :: size_of(float) * ARRAY_COUNT;

    ARRAY_EXTENDED_COUNT :: 384;
    ARRAY_EXTENDED_SIZE  :: size_of(float) * ARRAY_EXTENDED_COUNT;

    {
        ptr := Arena_get(*arena, ARRAY_SIZE);

        array: [] float;
        array.count = ARRAY_COUNT;
        array.data  = ptr;

        for *array {
            << it = 2.3 * it_index - 1.1 * it_index;
        }

        print("Using arena itself: %\n", array);
    }

    arena_allocator := Arena_allocator(*arena);

    {
        ptr := alloc(ARRAY_SIZE, arena_allocator);

        array: [] float;
        array.count = ARRAY_COUNT;
        array.data  = ptr;

        for *array {
            << it = 2.1 * it_index - 0.1 * it_index;
        }

        ptr         = realloc(ptr, ARRAY_EXTENDED_SIZE, ARRAY_SIZE, arena_allocator);
        array.count = ARRAY_EXTENDED_COUNT;
        array.data  = ptr;

        print("Using arena allocator, but no new context pushed: %\n", array);
    }

    {
        new_context := context;  // Copy all values from Context.
        new_context.allocator = arena_allocator;

        push_context new_context {
            ptr := alloc(ARRAY_SIZE);

            array: [] float;
            array.count = ARRAY_COUNT;
            array.data = ptr;

            for *array {
                << it = 1.99 * it_index - 0.6 * it_index;
            }

            ptr         = realloc(ptr, ARRAY_EXTENDED_SIZE, ARRAY_SIZE);
            array.count = ARRAY_EXTENDED_COUNT;
            array.data  = ptr;

            print("Using arena allocator, new context pushed: %\n", array);
        }
    }
}

#import "Basic";
#load "Arena.jai";
