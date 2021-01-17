using CsvHelper;
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
            using (var reader = new StreamReader(args[0]))
            using (var csv = new CsvReader(reader, CultureInfo.InvariantCulture))
            {
                var header = new Header();
                var records = csv.EnumerateRecords(header);
                string archiveFolder = Path.GetDirectoryName(args[0]);
                string[] archivePathArray = Directory.GetFiles(archiveFolder);

                Console.WriteLine(archiveFolder);

                foreach (var record in records)
                {
                    foreach (string archivePath in archivePathArray)
                    {
                        if ((archivePath.Contains(record.ArchiveFile)) && (record.BuiltType == "built"))
                        {
                            //creating directory path
                            string outPath = archiveFolder + "\\" + record.AssetPath;
                            string outFolder = outPath.Substring(0, (outPath.Length - Path.GetFileName(outPath).Length));
                            Directory.CreateDirectory(outFolder);
                            Console.WriteLine(outPath);

                            using (BinaryReader br = new BinaryReader(File.Open(archivePath, FileMode.Open)))
                            using (BinaryWriter bw = new BinaryWriter(File.Open(outPath, FileMode.Create)))
                            {
                                //goto beginning of file
                                br.BaseStream.Seek(Convert.ToInt64(record.SegmentOffset), SeekOrigin.Begin);
                                long fileSize = Convert.ToInt64(record.FileSize);

                                //reading file into byte array
                                byte[] outFile = new byte[fileSize];
                                for (int i = 0; i < fileSize; i++)
                                {
                                    outFile[i] = br.ReadByte();
                                }

                                //writing file
                                bw.Write(outFile);
                            }
                        }
                    }
                }
            }
            Console.ReadLine();
        }
    }
}
