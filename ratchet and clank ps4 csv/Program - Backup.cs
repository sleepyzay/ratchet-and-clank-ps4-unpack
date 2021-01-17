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
                string fileFolder = Path.GetDirectoryName(args[0]);
                string[] filePathArray = Directory.GetFiles(fileFolder);

                Console.WriteLine(fileFolder);

                foreach (var record in records)
                {
                    foreach (string filePath in filePathArray)
                    {
                        if (filePath.Contains(record.ArchiveFile))
                        {
                            //creating directory path
                            string outPath = fileFolder + "\\" + record.AssetPath;
                            string outFolder = outPath.Substring(0, (outPath.Length - Path.GetFileName(outPath).Length));
                            Directory.CreateDirectory(outFolder);
                            Console.WriteLine(outPath);
                            

                            byte[] outFile;

                            //reading file into byte array
                            using (BinaryReader br = new BinaryReader(File.Open(filePath, FileMode.Open)))
                            {
                                br.BaseStream.Seek(Convert.ToInt64(record.SegmentOffset), SeekOrigin.Begin);
                                long fileSize = Convert.ToInt64(record.FileSize);

                                outFile = new byte[fileSize];
                                for (int i = 0; i < fileSize; i++)
                                {
                                    outFile[i] = br.ReadByte();
                                }
                            }

                            //writing file
                            using (BinaryWriter bw = new BinaryWriter(File.Open(outPath, FileMode.Create)))
                            {
                                bw.Write(outFile);
                            }
                            //using (FileStream fs = File.Create(outPath))
                            //{
                            //    File.WriteAllBytes(outPath, outFile);
                            //}

                        }
                    }
                }
            }
            Console.ReadLine();
        }
    }
}
