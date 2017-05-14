
void main(string[] args) {
    import std.getopt;
    string filename;
    auto argInfo = getopt(args,
        "file", "scanned ascii file", &filename
    );
    if (argInfo.helpWanted || filename.length == 0) {
        defaultGetoptPrinter("bankOCR coding kata solution in D.", argInfo.options);
        return;
    }
    import std.file : readText;
    const text = readText(filename);
    import std.string : splitLines;
    import std.range : chunks;
    import std.array : join;
    foreach (chunk; text.splitLines().chunks(4)) {
        import std.stdio : writeln;
        import bankOCR : toValidNumbers;
        writeln(chunk.join('\n').toValidNumbers());
    }
}
