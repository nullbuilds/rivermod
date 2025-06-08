#pragma magic [ 50 4F 53 00 ] @0x00

import std.mem;
import std.sys;

namespace Riverworld {
    using Chunk;
    
    /**
        Represents the type of a chunk.
    */
    enum ChunkType: u32 {
        Character =  0x53524550, // PERS
        Vegetation = 0x45474556, // VEGE
        Territory =  0x52524554, // TERR
        Individual = 0x49444E49, // INDI
        Building =   0x49544142, // BATI
        Vehicle =    0x49484556, // VEHI
        Resource =   0x42534552, // RESB
    };
    
    /**
        Formats a coordinate by converting it into a float.
        @param coordinate to convert
        @return the formatted string
    */
    fn convert_coordinate(u32 coordinate) {
        return float(coordinate) / 65536.0;
    };
    
    /**
        Represents an entity with a position on the map.
    */
    struct Entity {
        le u32 id [[color("0000FF"), comment("The ID of the entity to place; 1-indexed using the order their structs are defined in the level ASM file")]];
        le u32 [[hidden, comment("Unknown field; changing these bytes doesn't appear to do anything - possibly type or object-specific parameter")]];
        le u32 x [[color("FF0000"), format("Riverworld::convert_coordinate"), comment("Where to place the entity horizontally relative to the left of the map expressed as a fraction over 65536")]];
        le u32 y [[color("00FF00"), format("Riverworld::convert_coordinate"), comment("Where to place the entity vertically relative to the top of the map expressed as a fraction over 65536")]];
    };
    
    /**
        Represents a set of resource nodes.
    */
    struct ResourceNodesChunk {
        le u32 entries [[color("800080"), comment("The number of resource nodes in this chunk")]];
        Entity resource_nodes[entries];
    };
    
    /**
        Represents a set of vehicles.
    */
    struct VehiclesChunk {
        le u32 entries [[color("800080"), comment("The number of vehicles in this chunk")]];
        Entity vehicles[entries];
    };
    
    /**
        Represents a set of buildings.
    */
    struct BuildingsChunk {
        le u32 entries [[color("800080"), comment("The number of buildings in this chunk")]];
        Entity buildings[entries];
    };
    
    /**
        Represents a set of citizens.
    */
    struct IndividualsChunk {
        le u32 entries [[color("800080"), comment("The number of citizens in this chunk")]];
        Entity individuals[entries];
    };
    
    /**
        Represents a territory.
    */
    struct Territory {
        Entity grailstone [[comment("The territory's grail stone")]];
        le u128 [[hidden, comment("Unknown field(s)")]];
        Chunk individuals;
        Chunk buildings;
        Chunk vehicles;
        Chunk resource_nodes;
    };
    
    /**
        Represents a set of territories.
    */
    struct TerritoriesChunk {
        le u32 entries [[color("800080"), comment("The number of territories in this chunk")]];
        Territory territories[entries];
    };
    
    /**
        Represents vegetation.
    */
    struct VegetationChunk {
        u8 unknown[40] [[hidden, comment("Unclear what this represents; changing most bytes causes a crash")]];
    };
    
    /**
        Represents a set of characters.
    */
    struct CharacterChunk {
        le u32 entries [[color("800080"), comment("The number of characters in this chunk")]];
        Entity characters[entries];
    };
    
    /**
        Represents a chunk of data.
    */
    struct Chunk {
        ChunkType type [[color("FFDB58"), comment("The type of data in this chunk")]];
        
        match (type) {
            (Riverworld::ChunkType::Character): Riverworld::CharacterChunk chunk;
            (Riverworld::ChunkType::Vegetation): Riverworld::VegetationChunk chunk;
            (Riverworld::ChunkType::Territory): Riverworld::TerritoriesChunk chunk;
            (Riverworld::ChunkType::Individual): Riverworld::IndividualsChunk chunk;
            (Riverworld::ChunkType::Building): Riverworld::BuildingsChunk chunk;
            (Riverworld::ChunkType::Vehicle): Riverworld::VehiclesChunk chunk;
            (Riverworld::ChunkType::Resource): Riverworld::ResourceNodesChunk chunk;
        }
    };
    
    /**
        Represents a position file.
    */
    struct Position {
        char magic[4] [[comment("Unclear if this is a file magic or chunk type")]];
        std::assert(magic == "POS\0", "XY files must start with POS\00");
        
        Chunk chunk[while(std::mem::read_unsigned($, 4) != 0x494E4946)];
    };
}    

Riverworld::Position position @0x00;
