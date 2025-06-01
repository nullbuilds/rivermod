import std.ctype;
import std.mem;
import std.string;
import std.sys;

namespace Riverworld {
    /**
        Structure representing a Riverworld.ini file.
    */
    struct RiverworldIni {
        char disc_drive_letter [[comment("The upper-case drive-letter of the disc drive to check for the game's CD")]];
        std::assert(std::ctype::isupper(disc_drive_letter), "The disc drive letter must be an upper-case letter; was decimal code " + std::string::to_string(u8(disc_drive_letter)));
        
        char colon [[hidden, comment("An ASCII colon character")]];
        std::assert(colon == ':', "The drive leter must be followed by a colon; was decimal code " + std::string::to_string(u8(colon)));
        
        char carriage_return [[hidden, comment("An ASCII carriage return character")]];
        std::assert(carriage_return == 0x0D, "The drive leter and colon must be followed by a carriage return; was decimal code " + std::string::to_string(u8(carriage_return)));
        
        char line_feed [[hidden, comment("An ASCII line feed character")]];
        std::assert(line_feed == 0x0A, "The carriage return must be followed by a line feed; was decimal code " + std::string::to_string(u8(line_feed)));
        
        char substitute [[hidden, comment("Assumed to always be an ASCII substitute character but the purpose is unknown")]];
        std::assert_warn(substitute == 0x1A, "The 5th byte was not 0x1A as assumed; was decimal code " + std::string::to_string(u8(substitute)));
        
        std::assert_warn(std::mem::size() <= 5, "More than the expected 5 bytes were present; had " + std::string::to_string(std::mem::size()));
    };
}

Riverworld::RiverworldIni ini @ 0x00;
