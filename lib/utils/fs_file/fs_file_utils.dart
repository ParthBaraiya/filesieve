import 'dart:io';

import 'fs_file.dart';

abstract class FsFileUtils {
  /// Params:
  /// - [extension] - file extension without `.`.
  static String getMimeFromExtension(String extension) {
    return extensionToMimeType[extension.toLowerCase()] ??
        "application/octet-stream";
  }

  /// Params:
  /// - [extension] - file extension without `.`.
  static String resolveFileIcon(String extension) {
    return fileTypeToSvgPath[extension.toLowerCase()] ??
        'assets/file_icons/file.svg';
  }

  /// Params:
  /// - [extension] - file extension without `.`.
  static bool isImage(String? extension) {
    if (extension == null) return false;
    return FsFileExtensions._imageExts.contains(extension.toLowerCase());
  }

  static bool isSVG(String extension) {
    return extension == FsFileExtensions.svg;
  }

  /// Params:
  /// - [extension] - file extension without `.`.
  static bool isCroppableImage(String extension) {
    return FsFileExtensions._flutterCroppableExts.contains(
      extension.toLowerCase(),
    );
  }

  /// Params:
  /// - [extension] - file extension without `.`.
  static bool canPreviewImageByDefault(String? extension) {
    return FsFileExtensions._flutterCroppableExts.contains(
      extension?.toLowerCase() ?? '',
    );
  }

  /// Params:
  /// - [extension] - file extension without `.`.
  static bool isAudio(String? extension) {
    if (extension == null) return false;
    return FsFileExtensions._audioExts.contains(extension.toLowerCase());
  }

  /// Params:
  /// - [extension] - file extension without `.`.
  static bool isVideo(String? extension) {
    if (extension == null) return false;
    return FsFileExtensions._videoExts.contains(extension.toLowerCase());
  }

  /// Params:
  /// - [extension] - file extension without `.`.
  static bool isArchive(String? extension) {
    if (extension == null) return false;
    return FsFileExtensions._archiveExts.contains(extension.toLowerCase());
  }

  static bool isXLSX(FsFile file) {
    return file.extension?.toLowerCase() == FsFileExtensions.xlsx;
  }

  static bool isPlayableVideo(String? extension) {
    return extension?.toLowerCase() == FsFileExtensions.mp4;
  }
}

abstract class FsFileExtensions {
  static const _imageExts = [
    jpg,
    jpeg,
    png,
    gif,
    webp,
    bmp,
    svg,
    heic,
    heif,
    avif,
  ];

  static final _flutterCroppableExts = [
    jpg,
    jpeg,
    png,
    if (Platform.isIOS) ...{heic, heif},
  ];

  static const _audioExts = [
    mp3,
    wav,
    aac,
    m4a,
    ogg,
    opus,
    flac,
    amr,
    mid,
    midi,
  ];

  static const _videoExts = [
    mp4,
    m4v,
    mov,
    avi,
    wmv,
    flv,
    mkv,
    webm,
    g3p,
    g3p2,
    mpeg,
    mpg,
  ];

  static const _archiveExts = [zip, rar, sevenZ, tar, gz, iso, dmg];

  // Images
  static const String jpg = 'jpg';
  static const String jpeg = 'jpeg';
  static const String png = 'png';
  static const String gif = 'gif';
  static const String webp = 'webp';
  static const String bmp = 'bmp';
  static const String svg = 'svg';
  static const String heic = 'heic';
  static const String heif = 'heif';
  static const String avif = 'avif';
  static const String ai = 'ai';
  static const String psd = 'psd';
  static const String raw = 'raw';
  static const String tiff = 'tiff';

  // Video
  static const String mp4 = 'mp4';
  static const String m4v = 'm4v';
  static const String mov = 'mov';
  static const String avi = 'avi';
  static const String wmv = 'wmv';
  static const String flv = 'flv';
  static const String mkv = 'mkv';
  static const String webm = 'webm';
  static const String g3p = '3gp';
  static const String g3p2 = '3g2';
  static const String mpeg = 'mpeg';
  static const String mpg = 'mpg';

  // Audio
  static const String mp3 = 'mp3';
  static const String wav = 'wav';
  static const String aac = 'aac';
  static const String m4a = 'm4a';
  static const String ogg = 'ogg';
  static const String opus = 'opus';
  static const String flac = 'flac';
  static const String amr = 'amr';
  static const String mid = 'mid';
  static const String midi = 'midi';
  static const String wma = 'wma';

  // Documents
  static const String pdf = 'pdf';
  static const String txt = 'txt';
  static const String rtf = 'rtf';
  static const String rss = 'rss';
  static const String java = 'java';

  // Microsoft Office
  static const String doc = 'doc';
  static const String docx = 'docx';
  static const String xls = 'xls';
  static const String xlsx = 'xlsx';
  static const String ppt = 'ppt';
  static const String pptx = 'pptx';

  // OpenDocument
  static const String odt = 'odt';
  static const String ods = 'ods';
  static const String odp = 'odp';

  // Web & Markup
  static const String html = 'html';
  static const String htm = 'htm';
  static const String css = 'css';
  static const String js = 'js';
  static const String json = 'json';
  static const String xml = 'xml';
  static const String yaml = 'yaml';
  static const String yml = 'yml';

  // Archives
  static const String zip = 'zip';
  static const String rar = 'rar';
  static const String sevenZ = '7z';
  static const String tar = 'tar';
  static const String gz = 'gz';
  static const String iso = 'iso';
  static const String dmg = 'dmg';

  // Others
  static const String csv = 'csv';
  static const String apk = 'apk';
  static const String exe = 'exe';
  static const String dll = 'dll';

  // Design / CAD / Office misc
  static const String eps = 'eps';
  static const String dwg = 'dwg';
  static const String mdb = 'mdb';
  static const String pub = 'pub';
  static const String ps = 'ps';
  static const String crd = 'crd';
}

// TODO(parth): Update this to include proper thunbnail icons as well based on
// extensions.
const extensionToMimeType = {
  // Images
  FsFileExtensions.jpg: 'image/jpeg',
  FsFileExtensions.jpeg: 'image/jpeg',
  FsFileExtensions.png: 'image/png',
  FsFileExtensions.gif: 'image/gif',
  FsFileExtensions.webp: 'image/webp',
  FsFileExtensions.bmp: 'image/bmp',
  FsFileExtensions.svg: 'image/svg+xml',
  FsFileExtensions.heic: 'image/heic',
  FsFileExtensions.heif: 'image/heif',
  FsFileExtensions.avif: 'image/avif',
  FsFileExtensions.ai: 'application/postscript',
  FsFileExtensions.psd: 'image/vnd.adobe.photoshop',
  FsFileExtensions.raw: 'image/raw',
  FsFileExtensions.tiff: 'image/tiff',

  // Video
  FsFileExtensions.mp4: 'video/mp4',
  FsFileExtensions.m4v: 'video/x-m4v',
  FsFileExtensions.mov: 'video/quicktime',
  FsFileExtensions.avi: 'video/x-msvideo',
  FsFileExtensions.wmv: 'video/x-ms-wmv',
  FsFileExtensions.flv: 'video/x-flv',
  FsFileExtensions.mkv: 'video/x-matroska',
  FsFileExtensions.webm: 'video/webm',
  FsFileExtensions.g3p: 'video/3gpp',
  FsFileExtensions.g3p2: 'video/3gpp2',
  FsFileExtensions.mpeg: 'video/mpeg',
  FsFileExtensions.mpg: 'video/mpeg',

  // Audio
  FsFileExtensions.mp3: 'audio/mpeg',
  FsFileExtensions.wav: 'audio/wav',
  FsFileExtensions.aac: 'audio/aac',
  FsFileExtensions.m4a: 'audio/mp4',
  FsFileExtensions.ogg: 'audio/ogg',
  FsFileExtensions.opus: 'audio/opus',
  FsFileExtensions.flac: 'audio/flac',
  FsFileExtensions.amr: 'audio/amr',
  FsFileExtensions.mid: 'audio/midi',
  FsFileExtensions.midi: 'audio/midi',
  FsFileExtensions.wma: 'audio/x-ms-wma',

  // Documents
  FsFileExtensions.pdf: 'application/pdf',
  FsFileExtensions.txt: 'text/plain',
  FsFileExtensions.rtf: 'application/rtf',
  FsFileExtensions.rss: 'application/rss+xml',
  FsFileExtensions.java: 'text/x-java-source',

  // Microsoft Office
  FsFileExtensions.doc: 'application/msword',
  FsFileExtensions.docx:
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  FsFileExtensions.xls: 'application/vnd.ms-excel',
  FsFileExtensions.xlsx:
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  FsFileExtensions.ppt: 'application/vnd.ms-powerpoint',
  FsFileExtensions.pptx:
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',

  // OpenDocument
  FsFileExtensions.odt: 'application/vnd.oasis.opendocument.text',
  FsFileExtensions.ods: 'application/vnd.oasis.opendocument.spreadsheet',
  FsFileExtensions.odp: 'application/vnd.oasis.opendocument.presentation',

  // Web & Markup
  FsFileExtensions.html: 'text/html',
  FsFileExtensions.htm: 'text/html',
  FsFileExtensions.css: 'text/css',
  FsFileExtensions.js: 'application/javascript',
  FsFileExtensions.json: 'application/json',
  FsFileExtensions.xml: 'application/xml',
  FsFileExtensions.yaml: 'application/x-yaml',
  FsFileExtensions.yml: 'application/x-yaml',

  // Archives
  FsFileExtensions.zip: 'application/zip',
  FsFileExtensions.rar: 'application/vnd.rar',
  FsFileExtensions.sevenZ: 'application/x-7z-compressed',
  FsFileExtensions.tar: 'application/x-tar',
  FsFileExtensions.gz: 'application/gzip',
  FsFileExtensions.iso: 'application/x-iso9660-image',
  FsFileExtensions.dmg: 'application/x-apple-diskimage',

  // Others
  FsFileExtensions.csv: 'text/csv',
  FsFileExtensions.apk: 'application/vnd.android.package-archive',
  FsFileExtensions.exe: 'application/vnd.microsoft.portable-executable',
  FsFileExtensions.dll: 'application/x-msdownload',

  // Design / CAD / Office misc
  FsFileExtensions.eps: 'application/postscript',
  FsFileExtensions.dwg: 'image/vnd.dwg',
  FsFileExtensions.mdb: 'application/x-msaccess',
  FsFileExtensions.pub: 'application/x-mspublisher',
  FsFileExtensions.ps: 'application/postscript',
  FsFileExtensions.crd: 'application/x-mscardfile',
};

const Map<String, String> fileTypeToSvgPath = {
  // ───────────── Images ─────────────
  FsFileExtensions.jpg: 'assets/file_icons/jpg.svg',
  FsFileExtensions.jpeg: 'assets/file_icons/jpg.svg',
  FsFileExtensions.png: 'assets/file_icons/png.svg',
  FsFileExtensions.gif: 'assets/file_icons/gif.svg',
  FsFileExtensions.webp: 'assets/file_icons/image.svg',
  FsFileExtensions.bmp: 'assets/file_icons/bmp.svg',
  FsFileExtensions.svg: 'assets/file_icons/svg.svg',
  FsFileExtensions.heic: 'assets/file_icons/image.svg',
  FsFileExtensions.heif: 'assets/file_icons/image.svg',
  FsFileExtensions.avif: 'assets/file_icons/image.svg',
  FsFileExtensions.ai: 'assets/file_icons/ai.svg',
  FsFileExtensions.psd: 'assets/file_icons/psd.svg',
  FsFileExtensions.raw: 'assets/file_icons/raw.svg',
  FsFileExtensions.tiff: 'assets/file_icons/tiff.svg',

  // ───────────── Video ─────────────
  FsFileExtensions.mp4: 'assets/file_icons/mp4.svg',
  FsFileExtensions.m4v: 'assets/file_icons/video.svg',
  FsFileExtensions.mov: 'assets/file_icons/mov.svg',
  FsFileExtensions.avi: 'assets/file_icons/avi.svg',
  FsFileExtensions.wmv: 'assets/file_icons/video.svg',
  FsFileExtensions.flv: 'assets/file_icons/flv.svg',
  FsFileExtensions.mkv: 'assets/file_icons/video.svg',
  FsFileExtensions.webm: 'assets/file_icons/video.svg',
  FsFileExtensions.g3p: 'assets/file_icons/video.svg',
  FsFileExtensions.g3p2: 'assets/file_icons/video.svg',
  FsFileExtensions.mpeg: 'assets/file_icons/mpeg.svg',
  FsFileExtensions.mpg: 'assets/file_icons/mpeg.svg',

  // ───────────── Audio ─────────────
  FsFileExtensions.mp3: 'assets/file_icons/mp3.svg',
  FsFileExtensions.wav: 'assets/file_icons/wav.svg',
  FsFileExtensions.aac: 'assets/file_icons/mp3.svg',
  FsFileExtensions.m4a: 'assets/file_icons/mp3.svg',
  FsFileExtensions.ogg: 'assets/file_icons/mp3.svg',
  FsFileExtensions.opus: 'assets/file_icons/mp3.svg',
  FsFileExtensions.flac: 'assets/file_icons/mp3.svg',
  FsFileExtensions.amr: 'assets/file_icons/mp3.svg',
  FsFileExtensions.mid: 'assets/file_icons/mid.svg',
  FsFileExtensions.midi: 'assets/file_icons/mid.svg',
  FsFileExtensions.wma: 'assets/file_icons/wma.svg',

  // ───────────── Documents ─────────────
  FsFileExtensions.pdf: 'assets/file_icons/pdf.svg',
  FsFileExtensions.txt: 'assets/file_icons/txt.svg',
  FsFileExtensions.rtf: 'assets/file_icons/txt.svg',
  FsFileExtensions.rss: 'assets/file_icons/rss.svg',
  FsFileExtensions.java: 'assets/file_icons/java.svg',

  // ───────────── Microsoft Office ─────────────
  FsFileExtensions.doc: 'assets/file_icons/doc.svg',
  FsFileExtensions.docx: 'assets/file_icons/docx.svg',
  FsFileExtensions.xls: 'assets/file_icons/xsl.svg',
  FsFileExtensions.xlsx: 'assets/file_icons/xsl.svg',
  FsFileExtensions.ppt: 'assets/file_icons/ppt.svg',
  FsFileExtensions.pptx: 'assets/file_icons/ppt.svg',

  // ───────────── OpenDocument ─────────────
  FsFileExtensions.odt: 'assets/file_icons/doc.svg',
  FsFileExtensions.ods: 'assets/file_icons/xsl.svg',
  FsFileExtensions.odp: 'assets/file_icons/ppt.svg',

  // ───────────── Web & Markup ─────────────
  FsFileExtensions.html: 'assets/file_icons/html.svg',
  FsFileExtensions.htm: 'assets/file_icons/html.svg',
  FsFileExtensions.css: 'assets/file_icons/html.svg',
  FsFileExtensions.js: 'assets/file_icons/html.svg',
  FsFileExtensions.json: 'assets/file_icons/xml.svg',
  FsFileExtensions.xml: 'assets/file_icons/xml.svg',
  FsFileExtensions.yaml: 'assets/file_icons/xml.svg',
  FsFileExtensions.yml: 'assets/file_icons/xml.svg',

  // ───────────── Archives ─────────────
  FsFileExtensions.zip: 'assets/file_icons/zip.svg',
  FsFileExtensions.rar: 'assets/file_icons/rar.svg',
  FsFileExtensions.sevenZ: 'assets/file_icons/zip.svg',
  FsFileExtensions.tar: 'assets/file_icons/zip.svg',
  FsFileExtensions.gz: 'assets/file_icons/zip.svg',
  FsFileExtensions.iso: 'assets/file_icons/iso.svg',
  FsFileExtensions.dmg: 'assets/file_icons/dmg.svg',

  // ───────────── Executables / Others ─────────────
  FsFileExtensions.apk: 'assets/file_icons/exe.svg',
  FsFileExtensions.exe: 'assets/file_icons/exe.svg',
  FsFileExtensions.dll: 'assets/file_icons/dll.svg',

  // ───────────── Design / CAD / Office misc ─────────────
  FsFileExtensions.eps: 'assets/file_icons/eps.svg',
  FsFileExtensions.dwg: 'assets/file_icons/dwg.svg',
  FsFileExtensions.mdb: 'assets/file_icons/mdb.svg',
  FsFileExtensions.pub: 'assets/file_icons/pub.svg',
  FsFileExtensions.ps: 'assets/file_icons/ps.svg',
  FsFileExtensions.crd: 'assets/file_icons/crd.svg',
};
