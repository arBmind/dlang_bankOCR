module bankOCR;

//
// User Story 1
//
enum int[string] numbers = [
    " _ " ~
    "| |" ~
    "|_|": 0,

    "   " ~
    "  |" ~
    "  |": 1,

    " _ " ~
    " _|" ~
    "|_ ": 2,

    " _ " ~
    " _|" ~
    " _|": 3,

    "   " ~
    "|_|" ~
    "  |": 4,

    " _ " ~
    "|_ " ~
    " _|": 5,
    
    " _ " ~
    "|_ " ~
    "|_|": 6,

    " _ " ~
    "  |" ~
    "  |": 7,
        
    " _ " ~
    "|_|" ~
    "|_|": 8,

    " _ " ~
    "|_|" ~
    " _|": 9,
];

auto scanNumberStrings(in string str) {
    import std.algorithm : map;
    import std.conv : to;
    import std.range : array, chunks, join, transposed;
    import std.string : splitLines;

    return splitLines(str)
        .map!(l => chunks(l, 3))().array.transposed()
        .map!(c => c.array[0..3].join.to!string)().array;
}

auto toNumbers(in string[] nums) {
    import std.algorithm : map;
    import std.range : array;

    return nums.map!(l => numbers.get(l, -1))().array;
}

auto scanLines(in string str) {
    return scanNumberStrings(str).toNumbers();
}

@safe unittest {
   assert(scanLines(
        " _  _ \n" ~
        "  || |\n" ~
        "  | _|\n" ~
        "      ") == [7, -1]);

    assert(scanLines(
        "    _  _     _  _  _  _  _ \n" ~
        "  | _| _||_||_ |_   ||_||_|\n" ~
        "  ||_  _|  | _||_|  ||_| _|\n" ~
        "                           ") == [1, 2, 3, 4, 5, 6, 7, 8, 9]);
}

//
// User Story 2
//
auto isChecksumValid(in int[] v) {
    import std.algorithm : fold, map, sum;
    import std.range : enumerate;

    //return 0 == v.enumerate.map!(e => (v.length - e.index)*e.value).sum() % 11;
    return 0 == v.enumerate.fold!((a, e) => a + (v.length - e.index)*e.value)(0uL) % 11;
}

@safe unittest {
    assert(isLegal([1,2,3,4,5,6,7,8,9]));
    assert(isChecksumValid([1,2,3,4,5,6,7,8,9]));
}

//
// User Story 3
//
auto isLegal(in int[] v) {
    import std.algorithm : all;
    return v.all!"a >= 0"();
}

auto toString(in const(int[]) v) {
    import std.algorithm : map;
    import std.conv : to;
    return v.map!(e => e < 0 ? '?' : cast(char)('0'+e))().to!string;
}

auto toOutput(in int[] v) {
    if (!isLegal(v)) return toString(v) ~ " ILL";
    if (!isChecksumValid(v)) return toString(v) ~ " ERR";
    return toString(v);
}

@safe unittest {
    assert("457508000" == toOutput([4,5,7,5,0,8,0,0,0]));
    assert("664371495 ERR" == toOutput([6,6,4,3,7,1,4,9,5]));
    assert("86110??36 ILL" == toOutput([8,6,1,1,0,-1,-1,3,6]));
}

//
// User Story 4 - fix error only
//
enum int[][int] alternatives = [
    0: [8],
    1: [7],
    2: [],
    3: [9],
    4: [],
    5: [6, 9],
    6: [5, 8],
    7: [1],
    8: [0, 6, 9],
    9: [3, 5, 8],
];

auto validAlternatives(int[] v) {
    import std.algorithm : each;
    import std.array : array;
    int[][] result;

    void replaceDigit(ref int d) {
        const s = d;
        scope(exit) d = s;
        void checkAlternative(int a) {
            d = a;
            if (isChecksumValid(v)) result ~= v.array;
        }
        alternatives[d].each!checkAlternative();
    }

    v.each!replaceDigit();
    return result;
}

@safe unittest {
    assert(validAlternatives(
            [4, 9, 0, 0, 6, 7, 7, 1, 5])
        == [[4, 9, 0, 8, 6, 7, 7, 1, 5], 
            [4, 9, 0, 0, 6, 7, 1, 1, 5], 
            [4, 9, 0, 0, 6, 7, 7, 1, 9]]);
}

//
// User Story 4 - fix illegal & error
//
auto horVariants(in string str) {
    import std.algorithm : map;
    import std.range : array;
    return [1,4,7].map!((i) {
        auto dup = str.dup;
        dup[i] = str[i]=='_' ? ' ' : '_';
        return dup.idup;
    }).array;
}
auto verVariants(in string str) {
    import std.algorithm : map;
    import std.range : array;
    return [3,5,6,8].map!((i) {
        auto dup = str.dup;
        dup[i] = str[i]=='|' ? ' ' : '|';
        return dup.idup;
    })().array;
}

auto buildAlternativeNumbers() {
    int[][string] result;
    foreach (key, value; numbers) {
        foreach (sub; horVariants(key) ~ verVariants(key)) {
            if (sub in result) 
                result[sub] ~= value;
            else result[sub] = [value];
        }
    }
    return result;
}

enum int[][string] alternativeNumbers = buildAlternativeNumbers();

auto validAlternativeNumbers(int[] v, in string[] str) {
    import std.algorithm : each;
    import std.array : array;

    int[][] result;
    foreach(i, ref d; v) {
        const bd = d;
        scope(exit) d = bd;
        if (str[i] in alternativeNumbers)
            foreach (a; alternativeNumbers[str[i]]) {
                d = a;
                if (isLegal(v) && isChecksumValid(v)) result ~= v.array;
            }
    }
    return result;
}

auto toValidNumbers(in string str) {
    import std.algorithm : map;
    import std.range : join;
    const numStrings = scanNumberStrings(str);
    const orig = toNumbers(numStrings);
    if (!isLegal(orig)) {
        const alt = validAlternativeNumbers(orig.dup, numStrings);
        if (alt.length == 0) return toString(orig) ~ " ILL";
        if (alt.length == 1) return toString(alt[0]) ~ " FIXED " ~ toString(orig);
        return toString(orig) ~ " AMB " ~ alt.map!toString.join(", ");
    }
    if (!isChecksumValid(orig)) {
        const alt = validAlternatives(orig.dup);
        if (alt.length == 0) return toString(orig) ~ " ERR";
        if (alt.length == 1) return toString(alt[0]) ~ " FIXED " ~ toString(orig);
        return toString(orig) ~ " AMB " ~ alt.map!toString.join(", ");
    }
    return toString(orig);
}

@safe unittest {
    assert(toValidNumbers(
        "    _  _     _  _  _  _  _ \n" ~
        "  | _| _||_| _ |_   ||_||_|\n" ~
        "  ||_  _|  | _||_|  ||_| _ ")
        == "1234?678? ILL");

    assert(toValidNumbers(
        " _  _  _  _  _  _  _  _  _ \n" ~
        "|_||_||_||_||_||_||_||_||_|\n" ~
        " _| _| _| _| _| _| _| _| _|")
        == "999999999 AMB 899999999, 993999999, 999959999");

    assert(toValidNumbers(
        "    _  _  _  _  _  _     _ \n" ~
        "|_||_|| || ||_   |  |  ||_ \n" ~
        "  | _||_||_||_|  |  |  | _|")
        == "490067715 AMB 490867715, 490067115, 490067719");

    assert(toValidNumbers(
        "    _  _     _  _  _  _  _ \n" ~
        " _| _| _||_||_ |_   ||_||_|\n" ~
        "  ||_  _|  | _||_|  ||_| _|")
        == "123456789 FIXED ?23456789");
                
    assert(toValidNumbers(
        " _     _  _  _  _  _  _    \n" ~
        "| || || || || || || ||_   |\n" ~
        "|_||_||_||_||_||_||_| _|  |")
        == "000000051 FIXED 0?0000051");
                
    assert(toValidNumbers(
        "    _  _  _  _  _  _     _ \n" ~
        "|_||_|| ||_||_   |  |  | _ \n" ~
        "  | _||_||_||_|  |  |  | _|")
        == "490867715 FIXED 49086771?");
}