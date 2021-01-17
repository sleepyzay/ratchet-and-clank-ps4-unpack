using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CsvHelper.Configuration.Attributes;

namespace ratchet_and_clank_ps4_csv
{
    class Header
    {
        [Name("Asset Path")]
        public string AssetPath { get; set; }

        [Name("Built Path")]
        public string BuiltPath { get; set; }

        [Name("Install Bucket")]
        public string InstallBucket { get; set; }

        [Name("File Size")]
        public string FileSize { get; set; }

        [Name("Asset Type")]
        public string AssetType { get; set; }

        [Name("Built Type")]
        public string BuiltType { get; set; }

        public string Language { get; set; }

        [Name("Always Loaded")]
        public string AlwaysLoaded { get; set; }

        [Name("Key Asset")]
        public string KeyAsset { get; set; }

        public string RefHash { get; set; }

        public string RefCount { get; set; }

        [Name("Archive File")]
        public string ArchiveFile { get; set; }

        [Name("Segment Offset")]
        public string SegmentOffset { get; set; }
    }
}
