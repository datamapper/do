module DataObjects
  module Postgres
    module Encoding
      MAP = {
        "Big5"          => "BIG5",
        "GB2312"        => "EUC_CN",
        "EUC-JP"        => "EUC_JP",
        "EUC-KR"        => "EUC_KR",
        "EUC-TW"        => "EUC_TW",
        "GB18030"       => "GB18030",
        "GBK"           => "GBK",
        "ISO-8859-5"    => "ISO_8859_5",
        "ISO-8859-6"    => "ISO_8859_6",
        "ISO-8859-7"    => "ISO_8859_7",
        "ISO-8859-8"    => "ISO_8859_8",
        "KOI8-U"        => "KOI8",
        "ISO-8859-1"    => "LATIN1",
        "ISO-8859-2"    => "LATIN2",
        "ISO-8859-3"    => "LATIN3",
        "ISO-8859-4"    => "LATIN4",
        "ISO-8859-9"    => "LATIN5",
        "ISO-8859-10"   => "LATIN6",
        "ISO-8859-13"   => "LATIN7",
        "ISO-8859-14"   => "LATIN8",
        "ISO-8859-15"   => "LATIN9",
        "ISO-8859-16"   => "LATIN10",
        "Emacs-Mule"    => "MULE_INTERNAL",
        "SJIS"          => "SJIS",
        "US-ASCII"      => "SQL_ASCII",
        "CP949"         => "UHC",
        "UTF-8"         => "UTF8",
        "IBM866"        => "WIN866",
        "Windows-874"   => "WIN874",
        "Windows-1250"  => "WIN1250",
        "Windows-1251"  => "WIN1251",
        "Windows-1252"  => "WIN1252",
        "Windows-1256"  => "WIN1256",
        "Windows-1258"  => "WIN1258"
      }
    end
  end
end
