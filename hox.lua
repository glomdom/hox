local op_counter = 0

local function gen_op(reset)
    reset = reset or false

    if reset then
        op_counter = 0
    end

    local result = op_counter
    op_counter = op_counter + 1

    return result
end

local OP_PUSH = gen_op(true)
local OP_PLUS = gen_op()
local OP_MINUS = gen_op()
local OP_DUMP = gen_op()
local OPS = gen_op()

local function push(x)
    return {OP_PUSH, x}
end

local function plus()
    return {OP_PLUS, nil}
end

local function minus()
    return {OP_MINUS, nil}
end

local function dump()
    return {OP_DUMP, nil}
end

local function simulate_program(program)
    local stack = {}

    for _, op in next, program do
        assert(OPS == 4, "simulate_program: too many or too little ops handled")

        if op[1] == OP_PUSH then
            table.insert(stack, op[2])
        elseif op[1] == OP_PLUS then
            local a = table.remove(stack)
            local b = table.remove(stack)

            table.insert(stack, a + b)
        elseif op[1] == OP_MINUS then
            local a = table.remove(stack)
            local b = table.remove(stack)

            table.insert(stack, b - a)
        elseif op[1] == OP_DUMP then
            local a = table.remove(stack)

            print(a)
        else
            assert(false, "unreachable")
        end
    end
end

local program = {
    push(34),
    push(35),
    plus(),
    dump(),
    push(500),
    push(80),
    minus(),
    dump()
}

local function compile_program(program, out_file_path)
    local out = io.open(out_file_path, "w")

    if out == nil then
        error(("failed to open \"%s\" for writing"):format(out_file_path))
    end

    out:write("segment .text\n")
    out:write("dump:\n")
    out:write("    mov     r9, -3689348814741910323\n")
    out:write("    sub     rsp, 40\n")
    out:write("    mov     BYTE [rsp+31], 10\n")
    out:write("    lea     rcx, [rsp+30]\n")
    out:write(".L2:\n")
    out:write("    mov     rax, rdi\n")
    out:write("    lea     r8, [rsp+32]\n")
    out:write("    mul     r9\n")
    out:write("    mov     rax, rdi\n")
    out:write("    sub     r8, rcx\n")
    out:write("    shr     rdx, 3\n")
    out:write("    lea     rsi, [rdx+rdx*4]\n")
    out:write("    add     rsi, rsi\n")
    out:write("    sub     rax, rsi\n")
    out:write("    add     eax, 48\n")
    out:write("    mov     BYTE [rcx], al\n")
    out:write("    mov     rax, rdi\n")
    out:write("    mov     rdi, rdx\n")
    out:write("    mov     rdx, rcx\n")
    out:write("    sub     rcx, 1\n")
    out:write("    cmp     rax, 9\n")
    out:write("    ja      .L2\n")
    out:write("    lea     rax, [rsp+32]\n")
    out:write("    mov     edi, 1\n")
    out:write("    sub     rdx, rax\n")
    out:write("    xor     eax, eax\n")
    out:write("    lea     rsi, [rsp+32+rdx]\n")
    out:write("    mov     rdx, r8\n")
    out:write("    mov     rax, 1\n")
    out:write("    syscall\n")
    out:write("    add     rsp, 40\n")
    out:write("    ret\n")
    out:write("\n")
    out:write("global _start\n")
    out:write("_start:\n")

    for _, op in next, program do
        assert(OPS == 4, "compile_program: too many or too little ops handled")

        if op[1] == OP_PUSH then
            out:write(("    push %d\n"):format(op[2]))
        elseif op[1] == OP_PLUS then
            out:write("    pop rax\n")
            out:write("    pop rbx\n")
            out:write("    add rax, rbx\n")
            out:write("    push rax\n")
        elseif op[1] == OP_MINUS then
            out:write("    pop rax\n")
            out:write("    pop rbx\n")
            out:write("    sub rbx, rax\n")
            out:write("    push rbx\n")
        elseif op[1] == OP_DUMP then
            out:write("    pop rdi\n")
            out:write("    call dump\n")
        end
    end

    out:write("    mov rax, 60\n")
    out:write("    mov rdi, 0\n")
    out:write("    syscall\n")
end

local function usage()
    print("Usage: hox <SUBCOMMAND> [ARGS]")
    print("")
    print("Subcommands:")
    print("  s          simulate program")
    print("  c          compile program")
end

local function call_cmd(cmd)
    io.popen(cmd)
end

local function main()
    if #arg < 1 then
        usage()
        print("\nhox: error: no subcommand provided")
        os.exit(1)
    end

    local subcommand = arg[1]

    if subcommand == "s" then
        simulate_program(program)
    elseif subcommand == "c" then
        compile_program(program, "output.asm")
        call_cmd("nasm -felf64 output.asm -o output.o")
        call_cmd("ld output.o -o output")
    else
        usage()
        print(("\nhox: error: unknown subcommand \"%s\""):match(subcommand))
        os.exit(1)
    end
end

main()