using CsvHelper;
using LZ4;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace ratchet_and_clank_ps4_csv
{
    class Program
    {
        static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("Usage: ratchet and clank ps4 csv.exe -path to layout.csv");
            }
            if (args.Length == 1)
            {
                Dictionary<string, uint> fileTypes = new Dictionary<string, uint>()
                {   //fileType          //hash
                    {"actor",           0x8F5B4C77},
                    {"animset",         0x22C426E1},
                    {"atmosphere",      0xDC85AF48},
                    {"cinematic2",      0xD85ED322},
                    {"conduit",         0x6CCA4D54},
                    {"config",          0xCB7A4616},
                    {"level",           0xC68C9514},
                    {"lightgrid",       0xE14FF06E},
                    {"localization",    0x02CE1328},
                    {"material",        0x81CE2D17},
                    {"materialgraph",   0x678EFA27},
                    {"model",           0x882A03DC},
                    {"performanceset",  0x22C426E1},
                    {"soundbank",       0xBAEEC654},
                    {"texture",         0x8C4B013D},
                    {"visualeffect",    0x6DDDD639},
                    {"zone",            0x205E4DB7},
                    {"zone_physics",    0x39159462},
                    {"zone_static",     0x72EE38F2}
                };
                //Console.WriteLine("Hex: {0:X}", fileTypes["actor"]);

                using (var reader = new StreamReader(args[0]))
                using (var csv = new CsvReader(reader, CultureInfo.InvariantCulture))
                {
                    var header = new Header();
                    var records = csv.EnumerateRecords(header);
                    string archiveFolder = Path.GetDirectoryName(args[0]);
                    string[] archivePathArray = Directory.GetFiles(archiveFolder);

                    foreach (var record in records)
                    {
                        foreach (string archivePath in archivePathArray)
                        {
                            if ((archivePath.Contains(record.ArchiveFile)) && ((record.BuiltType == "built") || (record.BuiltType == "stream")))    //second part skips audio files
                            {
                                //creating directory path
                                string outPath = archiveFolder + "\\" + record.AssetPath;                                       //path of outFile
                                string outFolder = outPath.Substring(0, (outPath.Length - Path.GetFileName(outPath).Length));   //folder where outFile will reside
                                if (record.BuiltType == "stream")
                                    outPath += ".stream";

                                Directory.CreateDirectory(outFolder);                                                           //creating outFolder
                                Console.WriteLine(outPath);                                                                     //printing outPath to console

                                using (BinaryReader br = new BinaryReader(File.Open(archivePath, FileMode.Open)))
                                using (BinaryWriter bw = new BinaryWriter(File.Open(outPath, FileMode.Create)))
                                {
                                    br.BaseStream.Seek(Convert.ToInt64(record.SegmentOffset), SeekOrigin.Begin);                //goto file in archive
                                    long fileSize = Convert.ToInt64(record.FileSize);                                         //getting size of file

                                    if (fileTypes.ContainsKey(record.AssetType) == true)    //if the current fileType is in the dictionary decompress
                                    {
                                        var outFileSize = fileSize;
                                        if (record.BuiltType != "stream")
                                        {
                                            var fileHash = br.ReadInt32();
                                            var uncompressedLength = br.ReadInt32();
                                            var uncompressedLength2 = br.ReadInt32();           //null except in texture fileTypes
                                            br.BaseStream.Seek(0x18, SeekOrigin.Current);       //null

                                            outFileSize = uncompressedLength + uncompressedLength2;
                                        }
                                        
                                        //reading compressed byte arraay
                                        var bufferOffset = (br.BaseStream.Position - Convert.ToInt64(record.SegmentOffset));
                                        
                                        byte[] inBuffer = new byte[fileSize - bufferOffset];
                                        for (int i = 0; i < inBuffer.Length; i++)         //0x24 because that is the offset of the compreesed buffer relative to the file offset
                                            inBuffer[i] = br.ReadByte();

                                        var outFile = new byte[outFileSize];
                                        
                                        //write byte array to outfile
                                        if (record.BuiltType != "stream")
                                        {
                                            LZ4Codec.Decode(inBuffer, 0, inBuffer.Length, outFile, 0, outFile.Length);
                                            bw.Write(outFile);
                                        }
                                        else
                                            bw.Write(inBuffer);     //leaving it as is because to decompress it i need data in another file, I can probably bypass it though
                                    }
                                    else
                                    {
                                        //reading file into byte array
                                        byte[] outFile = new byte[fileSize];
                                        for (int i = 0; i < fileSize; i++)
                                        {
                                            outFile[i] = br.ReadByte();
                                        }

                                        //write byte array to outfile
                                        bw.Write(outFile);
                                    }
                                }
                            }
                        }
                    }

                    Console.WriteLine("Extraction Complete.");
                }
            }


            Console.WriteLine("Press any key to continue...");
            Console.ReadLine();
        }
    }
}
