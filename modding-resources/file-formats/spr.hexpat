import std.core;
import std.mem;

namespace Riverworld {
    /**
        Represents a single color-indexed sprite.
    */
    struct Sprite {
        le u8 width [[color("FF0000"), comment("The number of columns in the sprite")]];
        le u8 [[hidden, comment("Unknown field")]];
        le u8 height [[color("00FF00"), comment("The number of rows in the sprite")]];
        le u8 [[hidden, comment("Unknown field")]];
        le u8 pixels[width * height] [[color("5D76CB"), comment("The pixel data in left-right/top-down format expressed as indices into a color table where 0 is transparent.")]];
    };
    
    /**
        Represents a collection of sprites.
    */
    struct SpriteSheet {
        le u16 header_length [[color("FF00FF"), comment("The length of the SPR header in bytes.")]];
        u8 header_bytes[header_length - 2] [[hidden, comment("Unknown SPR header contents")]];
        
        // It isn't currently known how to parse the header or how the game knows how many entries are
        // in the offset table. As a hack, assume the first entry points to the sprite immediate following
        // the offset table and use its offset to determine where the table ends.
        le u16 offset_table_end = $ + std::mem::read_unsigned($, 2, std::mem::Endian::Little);
        le u16 sprite_offset_table[while($ < offset_table_end)] [[color("B6B0FF"), comment("The number bytes from the start of this table where the index's sprite data starts")]];
        
        Sprite sprites[std::core::member_count(sprite_offset_table)];
    };
}

Riverworld::SpriteSheet sheet @ 0x0;
