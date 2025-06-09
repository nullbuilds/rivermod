#pragma pattern_limit 5000000

namespace Riverworld {
    /**
        Encapsulates the flags defining the behavior of a map cell.
    */
    bitfield MapCellFlags {
        bool is_buildable: 1 [[comment("Whether buildings can be placed on this cell")]];
        bool is_boundary: 1 [[comment("Whether this cell will stop units from traversing it")]];
        bool is_river: 1 [[comment("Whether this cell is part of the river; River cells are unwalkable, have animated vertices, and override the cell to a fixed height")]];
        bool is_river_bank: 1 [[comment("Whether this cell is a river bank; river banks have waves and override the cell to a fixed height")]];
        bool is_revealed: 1 [[comment("Whether this cell has been revealed from the fog of war")]];
        unknown_flags: 3 [[comment("The purpose of these bits is unknown")]];
    };
    
    /**
        Represents the data for a single map cell.
    */
    struct MapCell {
        le u8 depth [[color("F45B69"), comment("The depth of the cell's bottom-right vertex (0 = highest position, 255 = lowest)")]];
        le u8 texture_index [[color("F4D06F"), comment("The index of the texture from the MAPLAND list in the LEVEL*.ASM file to assign to this cell")]];
        le u8 [[hidden, comment("Unknown field believed to be precomputed lightmap data for the minimap")]];
        MapCellFlags flags [[color("9DD9D2"), comment("The flags defining the behavior of the map cell")]];
    };
    
    /**
        Contains the cells for a single row of the map.
    */
    struct MapCellRow {
        Riverworld::MapCell cells[512] [[comment("A row of map cells from right to left")]];
    };
    
    /**
        Contains the rows of cells for a map defined by a TOTALMAP.L* or MAP0*.SAV file.
    */
    struct TotalMap {
        Riverworld::MapCellRow cell_rows[512] [[comment("The rows of map cells from top to bottom")]];
    };
}

Riverworld::TotalMap map @0x00;
