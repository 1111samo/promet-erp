{**************************************************************************************************}
{                                                                                                  }
{  Y core library (Ycl)                                                                            }
{                                                                                                  }
{  YclZlib - zlib, gzip stream classes - resource strings                                          }
{                                                                                                  }
{  The contents of this file are subject to the Y Library Public License Version 1.0 (the          }
{  "License"); you may not use this file except in compliance with the License. You may obtain a   }
{  copy of the License at http://delphi.pjh2.de/                                                   }
{                                                                                                  }
{  Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF  }
{  ANY KIND, either express or implied. See the License for the specific language governing        }
{  rights and limitations under the License.                                                       }
{                                                                                                  }
{  The Original Code is: YclZlib.rs.                                                               }
{  The Initial Developer of the Original Code is Peter J. Haas (libs@pjh2.de). Portions created    }
{  by Peter J. Haas are Copyright (C) 2002-2005 Peter J. Haas. All Rights Reserved.                }
{                                                                                                  }
{  Contributor(s):                                                                                 }
{                                                                                                  }
{  You may retrieve the latest version of this file at the homepage of  Peter J. Haas, located at  }
{  http://delphi.pjh2.de/                                                                          }
{                                                                                                  }
{**************************************************************************************************}

  // zlib
  RsZlibNeedDict     = 'Ben�tige Verzeichnis';
  RsZlibStreamEnd    = 'Stream Ende';
  RsZlibOK           = '';
  RsZlibErrNo        = 'Dateifehler';
  RsZlibStreamError  = 'Streamfehler';
  RsZlibDataError    = 'Datenfehler';
  RsZlibMemError     = 'Unzureichender Speicherplatz';
  RsZlibBufError     = 'Puffer Fehler';
  RsZlibVersionError = 'Inkompatible Version';
  RsZlibUnknownError = 'Unbekannter zlib Fehler';
  RsZlibNoSetSize    = 'TZLibStream unterst�tzt kein Setzen der Streamgr��e.';
  RsZlibNoSeek       = 'TZLibStream unterst�tzt keinen wahlfreien Zugriff.';
  RsZlibNoWrite      = 'TZLibReader unterst�tzt kein Schreiben.';
  RsZlibNoRead       = 'TZLibWriter unterst�tzt kein Lesen.';

  // gzip
  RsGzipNoSetSize    = 'gzip stream unterst�tzt kein Setzen der Streamgr��e.';
  RsGzipNoSeek       = 'gzip stream unterst�tzt keinen wahlfreien Zugriff.';
  RsGzipNoWrite      = 'gzip reader unterst�tzt kein Schreiben.';
  RsGzipNoRead       = 'gzip writer unterst�tzt kein Lesen.';

  RsGzipNoGZipStream          = 'Kein gzip stream';
  RsGzipNoDeflate             = 'Keine deflate Kompression';
  RsGzipMultipartNotSupported = 'Multipart gzip Dateien werden nicht unterst�tzt';
  RsGzipEncryptedNotSupported = 'Verschl�sselte gzip Dateien werden nicht unterst�tzt';
  RsGzipUnknownFlags          = 'Unbekannte Attribute';
  RsGzipCRCError              = 'Checksummenfehler';
  RsGzipSizeError             = 'Fehlerhafte Angabe f�r unkomprimierte Gr��e';

