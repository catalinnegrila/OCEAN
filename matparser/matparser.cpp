#include <stdio.h>
#include <assert.h>
#include <stdint.h>
#include <zlib.h>
#include <vector>
#include <string>

#pragma pack(1)

#define VERBOSE

struct MatHeader
{
    uint8_t signature[116];
    uint64_t offset;
    uint16_t version;
    uint16_t endian;

    void Print() const
    {
        printf("Signature: '%.116s'\n", signature);
        printf("Subsystem offset: 0x%llx\n", offset);
        printf("Version: 0x%x\n", version);
        printf("Endian: %.2s\n", (char*)&endian);
    }
};

enum MatDataType : uint32_t
{
    miINT8      = 1, // 8 bit, signed
    miUINT8     = 2, // 8 bit, unsigned
    miINT16     = 3, // 16-bit, signed
    miUINT16    = 4, // 16-bit, unsigned
    miINT32     = 5, // 32-bit, signed
    miUINT32    = 6, // 32-bit, unsigned
    miSINGLE    = 7, // IEEE 754 single format
    // 8 -- Reserved
    miDOUBLE    = 9, // IEEE 754 double format
    // 10 -- Reserved
    // 11 -- Reserved
    miINT64     = 12, // 64-bit, signed
    miUINT64    = 13, // 64-bit, unsigned
    miMATRIX    = 14, // MATLAB array
    miCOMPRESSED = 15, // Compressed Data
    miUTF8      = 16, // Unicode UTF-8 Encoded Character Data
    miUTF16     = 17, // Unicode UTF-16 Encoded Character Data
    miUTF32     = 18, // Unicode UTF-32 Encoded Character Data
};

size_t MatDataTypeToSize(MatDataType dataType)
{
    switch (dataType)
    {
    case miINT8:
    case miUINT8:
        return 1;

    case miINT16:
    case miUINT16:
        return 2;

    case miINT32:
    case miUINT32:
        return 4;

    case miSINGLE:
        return 4;
    case miDOUBLE:
        return 8;

    case miINT64:
    case miUINT64:
        return 8;

    default:
        return 0;
    }
}

const char* MatDataTypeToString(MatDataType dataType)
{
#define TOSTRING(val) case val: return #val;
    switch (dataType)
    {
    TOSTRING(miINT8)
    TOSTRING(miUINT8)
    TOSTRING(miINT16)
    TOSTRING(miUINT16)
    TOSTRING(miINT32)
    TOSTRING(miUINT32)
    TOSTRING(miSINGLE)
    TOSTRING(miDOUBLE)
    TOSTRING(miINT64)
    TOSTRING(miUINT64)
    TOSTRING(miMATRIX)
    TOSTRING(miCOMPRESSED)
    TOSTRING(miUTF8)
    TOSTRING(miUTF16)
    TOSTRING(miUTF32)    
    default:
        return "Invalid";
    }
#undef TOSTRING
}

struct MatDataElementHeader
{
    MatDataType dataType;
    uint32_t numberOfBytes;

    void Print() const
    {
#ifdef VERBOSE
        printf("\nData Element: %s (%u) size %u\n", MatDataTypeToString(dataType), dataType, numberOfBytes);
#endif
    }
};

enum MatMatrixClass : uint8_t
{
    mxCELL_CLASS    = 1, // Cell array
    mxSTRUCT_CLASS  = 2, // Structure
    mxOBJECT_CLASS  = 3, // Object
    mxCHAR_CLASS    = 4, // Character array
    mxSPARSE_CLASS  = 5, // Sparse array
    mxDOUBLE_CLASS  = 6, // Double precision array
    mxSINGLE_CLASS  = 7, // Single precision array
    mxINT8_CLASS    = 8, // 8-bit, signed integer
    mxUINT8_CLASS   = 9, // 8-bit, unsigned integer
    mxINT16_CLASS   = 10, // 16-bit, signed integer
    mxUINT16_CLASS  = 11, // 16-bit, unsigned integer
    mxINT32_CLASS   = 12, // 32-bit, signed integer
    mxUINT32_CLASS  = 13, // 32-bit, unsigned integer
    mxINT64_CLASS   = 14, // 64-bit, signed integer
    mxUINT64_CLASS  = 15 // 64-bit, unsigned integer
};

const char* MatMatrixClassToString(MatMatrixClass matrixClass)
{
#define TOSTRING(val) case val: return #val;
    switch (matrixClass)
    {
    TOSTRING(mxCELL_CLASS)
    TOSTRING(mxSTRUCT_CLASS)
    TOSTRING(mxOBJECT_CLASS)
    TOSTRING(mxCHAR_CLASS)
    TOSTRING(mxSPARSE_CLASS)
    TOSTRING(mxDOUBLE_CLASS)
    TOSTRING(mxSINGLE_CLASS)
    TOSTRING(mxINT8_CLASS)
    TOSTRING(mxUINT8_CLASS)
    TOSTRING(mxINT16_CLASS)
    TOSTRING(mxUINT16_CLASS)
    TOSTRING(mxINT32_CLASS)
    TOSTRING(mxUINT32_CLASS)
    TOSTRING(mxINT64_CLASS)
    TOSTRING(mxUINT64_CLASS)
    default:
        return "Invalid";
    }
#undef TOSTRING
}

struct MatArrayFlagsSubelement
{
    MatMatrixClass matrixClass;
    union {
        struct {
            unsigned undefined : 4;
            unsigned complex : 1;
            unsigned global : 1;
            unsigned logical : 1;
        };
        uint8_t packed;
    } flags;
    uint16_t undefined;
    uint32_t maxNonZero;

    void Print() const
    {
#ifdef VERBOSE
        printf("ArrayFlags: %s (%u)\n", MatMatrixClassToString(matrixClass), matrixClass);
#endif
    }
};

class MatFile
{
private:
    std::vector<uint8_t> data;
    size_t cursor;

public:
    MatFile(const char* path);
    virtual ~MatFile();

    bool EndOfFile() const;
    void Skip(size_t numberOfBytes);
    MatDataElementHeader ReadDataElementHeader();

    template <class T>
    T ReadPrimitive()
    {
        const T& val = *(const T*)&data[cursor];
        cursor += sizeof(T);
        assert(cursor <= data.size());
        return val;
    }

    template <class T>
    T ReadBlock()
    {
        T block = ReadPrimitive<T>();
        block.Print();
        return block;
    }

    void ReadMem(char* buffer, size_t count)
    {
        memcpy(buffer, &data[cursor], count);
        cursor += count;
        assert(cursor <= data.size());
    }

    void Save(const char* path) const;
};

MatFile::MatFile(const char* path) : cursor(0)
{
    printf("Reading file: %s\n", path);
    FILE* fp = fopen(path, "r+b");
    assert(fp != nullptr);

    fseek(fp, 0, SEEK_END);
    long int fileSize = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    printf("File size: %lu\n", fileSize);
    data.resize(fileSize);
    fread(data.data(), fileSize, 1, fp);
    fclose(fp);

    ReadBlock<MatHeader>();
}

MatFile::~MatFile()
{
}

void MatFile::Save(const char* path) const
{
    printf("Writing file: %s\n", path);
    FILE* fp = fopen(path, "w+b");
    assert(fp != nullptr);

    printf("File size: %lu\n", data.size());
    fwrite(data.data(), data.size(), 1, fp);
    fclose(fp);
}

bool MatFile::EndOfFile() const
{
    assert(cursor <= data.size());
    return cursor == data.size();
}

void MatFile::Skip(size_t numberOfBytes)
{
    assert(cursor + numberOfBytes <= data.size());
    cursor += numberOfBytes;
}

MatDataElementHeader MatFile::ReadDataElementHeader()
{
    MatDataElementHeader header;
    for (;;)
    {
        cursor = ((cursor + 7) & ~7);
        assert((cursor % 8) == 0);
        if (((uint16_t*)&data[cursor])[1] != 0)
        {
            header.dataType = (MatDataType)ReadPrimitive<uint16_t>();
            header.numberOfBytes = ReadPrimitive<uint16_t>();
        }
        else
        {
            header.dataType = ReadPrimitive<MatDataType>();
            header.numberOfBytes = ReadPrimitive<uint32_t>();
        }
        header.Print();

        if (header.dataType == miCOMPRESSED)
        {
            uLongf uncompressedLen = header.numberOfBytes * 20;
            std::vector<uint8_t> uncompressed;
            uncompressed.resize(uncompressedLen);
            int ret = uncompress(uncompressed.data(), &uncompressedLen, (Bytef*)&data[cursor], header.numberOfBytes);
    #define LOG_Z_ERROR(err) if (ret == err) printf("Uncompress returned %s\n", #err)
            LOG_Z_ERROR(Z_MEM_ERROR);
            LOG_Z_ERROR(Z_BUF_ERROR);
            LOG_Z_ERROR(Z_DATA_ERROR);
    #undef LOG_Z_ERROR
            assert(ret == Z_OK);
            uncompressed.resize(uncompressedLen);

            cursor -= sizeof(MatDataElementHeader);
            size_t compressedLen = sizeof(MatDataElementHeader) + header.numberOfBytes;
            size_t remainingLen = data.size() - cursor - compressedLen;
            assert(uncompressedLen > compressedLen);
            data.resize(data.size() - compressedLen + uncompressedLen);
            memcpy(&data[cursor + uncompressedLen], &data[cursor + compressedLen], remainingLen);
            memcpy(&data[cursor], uncompressed.data(), uncompressedLen);
        }
        else
        {
            break;
        }
    }
    return header;
}

size_t g_currentField = (size_t)-1;
std::string g_arrayName;
std::vector<std::string> g_fieldNames;

void ReadMatrixStruct(MatFile& mat)
{
    MatDataElementHeader fieldNameLengthHeader = mat.ReadDataElementHeader();
    assert(fieldNameLengthHeader.dataType == miINT32);
    assert(fieldNameLengthHeader.numberOfBytes == sizeof(int32_t));
    int32_t fieldNameLength = mat.ReadPrimitive<int32_t>();
    printf("\n");

    MatDataElementHeader fieldNamesHeader = mat.ReadDataElementHeader();
    assert(fieldNamesHeader.dataType == miINT8);
    assert(fieldNamesHeader.numberOfBytes % fieldNameLength == 0);
    int32_t fieldNameCount = fieldNamesHeader.numberOfBytes / fieldNameLength;

    std::string fieldName;
    fieldName.resize(fieldNameLength);
    for (int32_t i = 0; i < fieldNameCount; i++)
    {
        mat.ReadMem(&fieldName[0], fieldName.size());
        printf("[%02d]: '%s'\n", i, fieldName.c_str());
        g_fieldNames.push_back(fieldName);
    }
    g_currentField = 0;
}

void ReadMatrixChar(MatFile& mat)
{
    MatDataElementHeader header = mat.ReadDataElementHeader();
    assert(header.dataType == miUTF8);

    std::string charName;
    charName.resize(header.numberOfBytes);
    mat.ReadMem(&charName[0], charName.size());
    printf("%s '%s'\n", MatDataTypeToString(header.dataType), charName.c_str());
}

void ReadMatrixDouble(MatFile& mat)
{
    MatDataElementHeader header = mat.ReadDataElementHeader();
    size_t dataTypeSize = MatDataTypeToSize(header.dataType);
    assert(dataTypeSize != 0);
    printf("%s\n", MatDataTypeToString(header.dataType));
    mat.Skip(header.numberOfBytes);
}

void ReadMatrix(MatFile& mat)
{
    MatDataElementHeader arrayFlagsHeader = mat.ReadDataElementHeader();
    assert(arrayFlagsHeader.dataType == miUINT32);
    assert(arrayFlagsHeader.numberOfBytes == 2 * sizeof(uint32_t));
    MatArrayFlagsSubelement arrayFlags = mat.ReadBlock<MatArrayFlagsSubelement>();

    printf("\n");
    if (!g_fieldNames.empty())
    {
        assert(g_currentField < g_fieldNames.size());
        printf("%s.%s: ", g_arrayName.c_str(), g_fieldNames[g_currentField].c_str());
        g_currentField++;
    }

    {
        MatDataElementHeader dimensionHeader = mat.ReadDataElementHeader();
        assert(dimensionHeader.dataType == miINT32);
        uint32_t dimensions = dimensionHeader.numberOfBytes / sizeof(uint32_t);
        for (uint32_t i = 0; i < dimensions; i++)
        {
            printf("%d", mat.ReadPrimitive<int32_t>());
            if (i < dimensions - 1)
                printf("-by-");
        }
        printf(", ");
    }

    {
        MatDataElementHeader arrayNameHeader = mat.ReadDataElementHeader();
        assert(arrayNameHeader.dataType == miINT8);
        if (arrayNameHeader.numberOfBytes > 0)
        {
            g_arrayName.resize(arrayNameHeader.numberOfBytes);
            mat.ReadMem(&g_arrayName[0], g_arrayName.size());
            printf("'%s' ", g_arrayName.c_str());
        }
    }

    switch (arrayFlags.matrixClass)
    {
        case mxSTRUCT_CLASS:
            ReadMatrixStruct(mat);
            break;

        case mxCHAR_CLASS:
            ReadMatrixChar(mat);
            break;

        case mxDOUBLE_CLASS:
            ReadMatrixDouble(mat);
            break;

        default:
            printf("Unsupported matrix type!\n");
            assert(0);
    }
}

int main()
{
    //MatFile mat("fctd_grid_uncompressed.mat");
    MatFile mat("epsi_grid_uncompressed.mat");

    while (!mat.EndOfFile())
    {
        MatDataElementHeader element = mat.ReadDataElementHeader();
        if (element.dataType == miMATRIX)
        {
            ReadMatrix(mat);
        }
        else
        {
            mat.Skip(element.numberOfBytes);
        }
    }
    //mat.Save("fctd_test.mat");
    return 0;
}