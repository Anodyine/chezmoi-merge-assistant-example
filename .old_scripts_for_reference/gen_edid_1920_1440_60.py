import struct

def generate_1440p_edid(output_file):
    # Standard 128-byte EDID Header
    edid = bytearray([0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00])
    
    # ID Manufacturer Name: "GGL" (Google/Omarchy)
    edid.extend([0x1C, 0x4C]) 
    edid.extend([0x01, 0x00]) # ID Product Code
    edid.extend([0x00, 0x00, 0x00, 0x00]) # ID Serial Number
    edid.extend([0x01, 0x1F]) # Week 1, Year 2021
    edid.extend([0x01, 0x03]) # EDID Ver 1.3
    edid.extend([0x80, 0x3C, 0x22, 0x78, 0xEA]) # Digital, 60cm x 34cm, Gamma 2.2
    edid.extend([0xEE, 0x91, 0xA3, 0x54, 0x4C, 0x99, 0x26, 0x0F, 0x50, 0x54]) 
    edid.extend([0x00, 0x00, 0x00]) # Established Timings (None)
    
    # Standard Timings (Padding)
    edid.extend([0x01, 0x01] * 8)

    # Detailed Timing Descriptor: 1920x1440 @ 60Hz (CVT-RB)
    # Clock: 174.25 MHz -> 17425
    # H: 1920 active, 160 blank (Total 2080)
    # V: 1440 active, 41 blank (Total 1481)
    pixel_clock = 17425
    
    # Pack the DTD (18 bytes total)
    dtd = struct.pack("<HBBBBBBBBBBBBBBBB", 
        pixel_clock,
        0x80,       # H active LSB (1920 & 0xFF)
        0xA0,       # H blank LSB (160 & 0xFF)
        0x70,       # H active/blank MSB ((1920>>8)<<4 | (160>>8))
        0xA0,       # V active LSB (1440 & 0xFF)
        0x29,       # V blank LSB (41 & 0xFF)
        0x50,       # V active/blank MSB ((1440>>8)<<4 | (41>>8))
        0x30,       # H sync offset LSB (48)
        0x20,       # H sync pulse LSB (32)
        0x38,       # V sync offset/pulse LSB (3/8)
        0x00,       # Sync MSBs
        0x00, 0x00, 0x00, # Image size (ignored)
        0x00, 0x00, # Border
        0x1E        # Flags: Digital, Sync+, No Interlace
    )
    edid.extend(dtd)

    # Descriptor 2: Monitor Name "OMARCHY"
    edid.extend([0x00, 0x00, 0x00, 0xFC, 0x00, 0x4F, 0x4D, 0x41, 0x52, 0x43, 0x48, 0x59, 0x0A, 0x20, 0x20, 0x20, 0x20, 0x20])
    # Descriptor 3: Range Limits
    edid.extend([0x00, 0x00, 0x00, 0xFD, 0x00, 0x38, 0x4B, 0x1E, 0x5A, 0x11, 0x00, 0x0A, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20])
    # Descriptor 4: Padding
    edid.extend([0x00, 0x00, 0x00, 0x10, 0x00, 0x0A, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20])
    
    edid.append(0x00) # Extension flag
    
    # Checksum
    checksum = (256 - (sum(edid) % 256)) % 256
    edid.append(checksum)

    with open(output_file, "wb") as f:
        f.write(edid)
    print(f"Generated {output_file} successfully.")

if __name__ == "__main__":
    generate_1440p_edid("edid-1920-1440-60.bin")