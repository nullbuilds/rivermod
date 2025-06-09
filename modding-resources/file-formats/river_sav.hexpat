import std.ctype;
import std.string;
import std.sys;

namespace Riverworld {
    /**
        Formats a cstring for display by removing the null-terminator.
        @param cstring the string to format
        @return the formatted string
    */
    fn _format_cstring(str cstring) {
        return std::string::substr(cstring, 0,  std::string::length(cstring) - 1);
    };
    
    /**
        Asserts a save name complies with the constraints set by the game.
        @param string the raw save name string
    */
    fn _validate_save_name(str string) {
        le u32 string_length = std::string::length(string);
        
        char last_character = string[string_length - 1];
        std::assert(last_character == 0, "The last byte of a save name must be null; was " + std::string::to_string(u8(last_character)));
        
        for (u8 index = 0, index < string_length - 1, index += 1) {
            char character = string[index];
            std::assert(std::ctype::isalnum(character), "Save names must only contain alpha-numeric characters and the null terminator; found character with code " + std::string::to_string(u8(character)));
        }
    };
    
    /**
        Structure representing a RIVER000.SAV file. Note: MAP00.SAV files use a different format.
    */
    struct RiverSave {
        le u32 [[highlight_hidden, comment("Unknown field; always appears to be 1")]];
        
        le u32 save_name_length [[comment("The length in bytes of the save name including the null terminator")]];
        std::assert(save_name_length > 0, "A save name's length cannot be 0");
        std::assert(save_name_length <= 17, "The length of a save name cannot exceed 17 bytes; length was " + std::string::to_string(save_name_length));
        
        char save_name_string[save_name_length] [[format_read("Riverworld::_format_cstring"), comment("The null-terminated name of the save")]];
        Riverworld::_validate_save_name(save_name_string);
    };
}

Riverworld::RiverSave save @ 0x00;
