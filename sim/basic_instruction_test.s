.section .text
.global _start

_start:
    # Set up our base memory pointer at address 0x400 (1024)
    # This is safely out of the way of the program text and the end of RAM.
    li x10, 0x400 

    # ==========================================
    # TEST 1: Full Word Store and Load (sw, lw)
    # ==========================================
    li x1, 0xDEADBEEF
    sw x1, 0(x10)
    nop                 # Hazard buffer
    lw x2, 0(x10)       # EXPECTED: x2 = 0xDEADBEEF

    # ==========================================
    # TEST 2: Half-Word Sign & Zero Extension (sh, lh, lhu)
    # ==========================================
    # 0xFACE has the top bit (bit 15) set to 1, which tests sign extension.
    li x3, 0xFACE
    sh x3, 4(x10)
    nop                 # Hazard buffer
    lh x4, 4(x10)       # EXPECTED: x4 = 0xFFFFFACE (Sign-extended)
    lhu x5, 4(x10)      # EXPECTED: x5 = 0x0000FACE (Zero-extended)

    # ==========================================
    # TEST 3: Byte Sign & Zero Extension (sb, lb, lbu)
    # ==========================================
    # 0xFA has the top bit (bit 7) set to 1, testing byte sign extension.
    li x6, 0xFA
    sb x6, 8(x10)
    nop                 # Hazard buffer
    lb x7, 8(x10)       # EXPECTED: x7 = 0xFFFFFFFA (Sign-extended)
    lbu x8, 8(x10)      # EXPECTED: x8 = 0x000000FA (Zero-extended)

    # ==========================================
    # TEST 4: Byte Overwrite & Endianness Check
    # ==========================================
    # We write a full word, then use 'sb' to overwrite a single byte inside it.
    # Because RISC-V is Little-Endian, storing to offset +1 modifies the 2nd byte.
    li x9, 0x11223344
    sw x9, 12(x10)
    li x11, 0x99
    sb x11, 13(x10)     # Overwrite the '33' byte with '99'
    nop                 # Hazard buffer
    lw x12, 12(x10)     # EXPECTED: x12 = 0x11229944

    # ==========================================
    # INFINITE TRAP
    # ==========================================
loop:
    j loop