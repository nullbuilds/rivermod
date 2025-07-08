#pragma magic [44 45 47 52] @0x00

import std.mem;
import std.string;
import std.sys;

namespace Riverworld {
    using Chunk;
    
    /**
        Defines the possible chunk data types.
    */
    enum ChunkType: u32 {
        ModelDefinition = 0x52474544, // DEGR
        Element =         0x4D454C45, // ELEM
        Object =          0x454A424F, // OBJE
        Vertices =        0x54524556, // VERT
        Normals =         0x4D524F4E, // NORM
        Faces =           0x45434146, // FACE
        Materials =       0x4554414D, // MATE
        Attributes =      0x52545441, // ATTR
        TextureMaps =     0x5350414D, // MAPS
        Animations =      0x4D494E41, // ANIM
    };
    
    /**
        Defines a set of data assumed to be related to animation.
    */
    struct Animations {
        le u8 unknown_fields[160] [[hidden, comment("Unknown field(s); always 160 bytes; beleived to be an array of 10 16-byte structures; possibly animation frame times")]];
    };
    
    /**
        Represents a texture file name.
    */
    struct TextureMap {
        char file_name[] [[color("AAFFC3"), comment("The null-terminated file name of the texture; relative to the GIFS directory; some file names have non-printable characters like new lines which the game seems to ignore; most textures are listed here with the .GIF extension which the game seems to internally replace with .PNG")]];
    };
    
    /**
        Defines an indexed list of texture file names.
    */
    struct TextureMaps {
        le u16 texture_count [[color("46F0F0"), comment("The number of texture maps this chunk contains")]];
        TextureMap texture_maps[texture_count] [[comment("The list of texture file names; relative to the GIFS directory")]];
    };
    
    /**
        Defines the color key flags for a material. Unknown if this serves any other purpose.
    */
    bitfield MaterialAttributesColorKeyFlags {
        bool color_key_on_black: 1 [[comment("Whether to make black pixels clear")]];
    };
    
    /**
        Defines a material attribute.
    */
    struct MaterialAttributes {
        le u8 render_flags [[color("9A6324"), comment("Unknown render flags; a value of 2 seems to indicate solid and 7 seems to indicate semi-transparent")]];
        std::assert_warn(render_flags == 2, "Material render flags were assumed to always be 2; was + " + std::string::to_string(render_flags));
        
        MaterialAttributesColorKeyFlags color_key_flags [[color("FFFAC8"), comment("Flags concerning the color key of the material; unknown if this contains other data")]];
        
        le u8 texture_map_index [[color("800000"), comment("The 0-indexed index of the texture to use from the MAPS array")]];
    };
    
    /**
        Defines a set of materials.
    */
    struct Materials {
        le u16 material_count [[color("46F0F0"), comment("The number of materials this chunk contains")]];
        Chunk attributes[material_count] [[comment("The material attributes")]];
    };
    
    /**
        Converts an encoded U/V coordinate to a float.
        @param coordinate the U or V coordinate to convert
        @return the converted coordinate
    */
    fn convert_uv_coordinate(le u8 coordinate) {
        return float(coordinate) / 255.0;
    };
    
    /**
        Defines the UV coordinates of a face vertex.
    */
    struct UvCoordinates {
        le u8 [[hidden, comment("Unknown field(s); setting this to anything other than 0 causes strange UV and vertex distortion")]];
        le u8 u [[color("E6194B"), format("Riverworld::convert_uv_coordinate"), comment("The U coordinate expressed as a fraction over 255; 0 = left of the texture")]];
        le u8 [[hidden, comment("Unknown field(s); setting this to anything other than 0 causes strange UV and vertex distortion")]];
        le u8 v [[color("3CB44B"), format("Riverworld::convert_uv_coordinate"), comment("The V coordinate expressed as a fraction over 255; 0 = top of the texture")]];
    };
    
    /**
        Defines the index of a vertex for a face.
    */
    struct FaceVertexIndex {
        le u8 unknown_field [[hidden, comment("Unknown field(s); assumed to always be 0")]];
        std::assert_warn(unknown_field == 0, "Vertex index unknown field was expected to be 0; was " + std::string::to_string(unknown_field));
        le u8 index [[color("F032E6"), comment("The index of the vertex in the VERT chunks before the FACE section")]];
    };
    
    /**
        The flags describing a face.
    */
    bitfield FaceFlags {
        bool is_double_sided: 1 [[comment("Whether the face is double-sided or not")]];
    };
    
    /**
        Defines a singls face. Faces can either be a triangle or a quad. Note that faces sharing a vertex can define different UV coordinates for that vertex. It appears that Riverworld does honor the different coordinates per vertex so each face likely needs to be treated as a separate surface for this to work on modern hardware.
    */
    struct Face {
        FaceFlags flags [[color("F032E6"), comment("Describes the behavior of the face")]];
        
        le u8 vertex_count [[color("BCF60C"), comment("Indicates how many vertices in this face's vertex array are actually used; assumed to always be 3 or 4")]];
        std::assert_warn(vertex_count == 3 || vertex_count == 4, "Face vertex count was expected to be 3 or 4; was " + std::string::to_string(vertex_count));
        
        le u8 material_index [[color("008080"), comment("The index of the material to use for this face; appears to be 1-indexed")]];
        std::assert_warn(material_index != 0, "Face material index was not expected to be 0");
        
        FaceVertexIndex vertices[4] [[comment("The indices of the vertice of the face in clockwise order (notable since modern hardware typically requires counter-clockwise order); when the face uses 3 vertices it's assumed the last vertex index will always be 0; when the face is a quad, the two triangles use indices [0, 1, 2] and [3, 0, 2] respecitively")]];
        if (vertex_count == 3) {
            std::assert_warn(vertices[3].index == 0, "Face uses only 3 vertices but the 4th vertex index was not 0; was " + std::string::to_string(vertices[3].index));
        }
        
        UvCoordinates uv_coordinates[4] [[comment("The UV coorinates of the face; when the face uses 3 vertices it's assumed the last UV coordinate will always be 0")]];
        if (vertex_count == 3) {
            std::assert_warn(uv_coordinates[3].u == 0 && uv_coordinates[3].v == 0, "Face uses only 3 vertices but the 4th UV coordinate was not [0, 0]; was [" + std::string::to_string(uv_coordinates[3].u) + ", " + std::string::to_string(uv_coordinates[3].v) + "]");
        }
        
        le u8 unknown_fields[4] [[hidden, comment("Unknown field(s); assumed to have something to do with UV mapping; the first byte is assumed to always be 0")]];
        std::assert_warn(unknown_fields[0] == 0, "Assumed the first byte of a face unknown field to always be 0; was " + std::string::to_string(unknown_fields[0]));
    };
    
    /**
        Defines a group of faces.
    */
    struct Faces {
        le u16 face_count [[color("46F0F0"), comment("The number of faces in this group")]];
        Face faces[face_count] [[comment("The faces of this group")]];
    };
    
    /**
        Defines a single normal. It is unclear what format normals are in. They are assumed to be integer vectors that must be manually normalized.
    */
    struct Normal {
        le s16 x [[color("E6194B"), comment("The X axis")]];
        le s16 y [[color("3CB44B"), comment("The Y axis")]];
        le s16 z [[color("4363D8"), comment("The Z axis")]];
    };
    
    /**
        Defines a group of normals. Each normal corresponds to the vertex of the same index from the paired vertex set.
    */
    struct Normals {
        le u16 normal_count [[color("46F0F0"), comment("The number of normals in this group")]];
        Normal normals[normal_count] [[comment("The normals of this group")]];
    };
    
    /**
        Defines a single vertex. Note that Riverworld uses the -Y axis as up not +Y or Z.
    */
    struct Vertex {
        le s16 x [[color("E6194B"), comment("The X axis")]];
        le s16 y [[color("3CB44B"), comment("The Y axis")]];
        le s16 z [[color("4363D8"), comment("The Z axis")]];
    };
    
    /**
        Defines a group of vertices.
    */
    struct Vertices {
        le u16 vertex_count [[color("46F0F0"), comment("The number of vertices in this group")]];
        Vertex vertices[vertex_count] [[comment("The vertices of this group")]];
    };
    
    /**
        Defines a pairing of a vertices chunk and its corresponding normals chunk.
    */
    struct VertexNormalChunkPair {
        Chunk vertices_chunk [[comment("The vertices chunk")]];
        std::assert(vertices_chunk.type == Riverworld::ChunkType::Vertices, "Expected a vertices chunk; was " + std::string::to_string(vertices_chunk.type));
        Chunk normals_chunk [[comment("The normals chunk for the vertices chunk")]];
        std::assert(normals_chunk.type == Riverworld::ChunkType::Normals, "Expected a normals chunk; was " + std::string::to_string(normals_chunk.type));
    };
    
    /**
        Defines an object within the model. Some models are composed of a single object but others are split into multiple objects. Models contain multiple sets of vertices and normals but only a single set of faces. It's unknown why vertices and normals are broken into smaller sets rather than one each.
    */
    struct Object {
        le u16 vertex_group_count [[color("911EB4"), comment("The number of vertex group chunks in this object")]];
        VertexNormalChunkPair vertex_normal_chunk_pairs[vertex_group_count] [[comment("The pairs of corresponding vertex and normal chunks")]];
        Chunk face_chunk [[comment("The face chunk of the object")]];
        std::assert(face_chunk.type == Riverworld::ChunkType::Faces, "Expected a faces chunk; was " + std::string::to_string(face_chunk.type));
    };
    
    /**
        Defines the data for an element. Most models have a single element but some contain multiple elements with seemingly identical models just with minor offsets for an unknown reason.
    */
    struct Element {
        le u16 child_count [[color("F58231"), comment("The number of child chunks in this chunk")]];
        le u16 [[hidden, comment("Unknown field(s)")]];
        Chunk children[child_count] [[comment("The child chunks of this chunk")]];
    };
    
    /**
        Defines the data for a model definition.
    */
    struct ModelDefinition {
        le u16 child_count [[color("F58231"), comment("The number of child chunks in this chunk")]];
        Chunk children[child_count] [[comment("The child chunks of this chunk")]];
    };
    
    /**
        Represents a typed chunk of data.
    */
    struct Chunk {
        ChunkType type [[color("FFE119"), comment("The type of chunk")]];
        le u32 chunk_size [[color("FABEBE"), comment("The size of the chunk including the 8 byte header")]];
        
        match (type) {
            (Riverworld::ChunkType::ModelDefinition): ModelDefinition data;
            (Riverworld::ChunkType::Element): Element data;
            (Riverworld::ChunkType::Object): Object data;
            (Riverworld::ChunkType::Vertices): Vertices data;
            (Riverworld::ChunkType::Normals): Normals data;
            (Riverworld::ChunkType::Faces): Faces data;
            (Riverworld::ChunkType::Materials): Materials data;
            (Riverworld::ChunkType::Attributes): MaterialAttributes data;
            (Riverworld::ChunkType::TextureMaps): TextureMaps data;
            (Riverworld::ChunkType::Animations): Animations data;
        }
        
        le u8 extra_bytes[while($ < addressof(type) + chunk_size)] [[comment("Extra bytes following the structured data of a chunk; it is unclear why some chunks do this and is seemingly random")]];
    };
    
    /**
        Represents a model file.
    */
    struct Model {
        Chunk chunks[while(!std::mem::eof())];
    };
}

Riverworld::Model model @0x00;
