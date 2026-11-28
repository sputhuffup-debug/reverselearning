# Just enough Java for Ghidra scripts

This primer teaches the Java you need for [Day 5](../day5-training.md)'s scripts, and nothing more. It is for students who have never written Java; it assumes basic C. Reading time: about 30 minutes.

Later scripting days build on the same basics. Numbers, hex and XOR are covered in [01: Numbers and data](01-numbers-and-data.md), and record layouts in [07: Data in memory](07-data-in-memory.md).

## Java in one paragraph

Java looks like C: braces, semicolons, `if`, `for`, `while`, and the same arithmetic. The differences that matter today are classes, objects and a few stricter rules about types. Ghidra compiles your script with the kit's JDK (Java Development Kit, the compiler and runtime) each time you run it.

## A script is a class with a run() method

A class is a named bundle of code and data. Every Java file holds one public class, and the class name must match the file name exactly. A Ghidra script is a class that extends `GhidraScript`, which means it starts with everything `GhidraScript` already has.

```java
import ghidra.app.script.GhidraScript;

public class HelloCourse extends GhidraScript {

    @Override
    protected void run() throws Exception {
        println("Hello from " + currentProgram.getName());
    }
}
```

- **`import`** names a class from another package (a folder of classes), so you can use its short name. Without the import line, `GhidraScript` is unknown and the file does not compile.
- **`run()`** is a method, Java's word for a function that belongs to a class. Ghidra calls `run()` when you click Run Script.
- **`@Override`** tells the compiler that this method replaces one from `GhidraScript`. If you misspell `run`, the compiler reports an error instead of silently ignoring your method.
- **`throws Exception`** says the method may stop with an error. Ghidra catches it and prints it in the console.
- **`println`** is `GhidraScript`'s method for printing to the console. Plain Java programs use `System.out.println`, as the examples below do.

The examples in this primer are plain Java with a `main` method, so you can try them outside Ghidra if you like. Inside a script, put the lines in `run()` and use `println`.

## Variables and types

A variable has a type that never changes. Java checks types when it compiles, and refuses to lose data silently.

| Type | Size | Range or meaning | Example |
| --- | --- | --- | --- |
| `byte` | 1 byte | -128 to 127 (signed) | `byte b = 0x41;` |
| `int` | 4 bytes | about ±2.1 billion | `int count = 0;` |
| `long` | 8 bytes | 64-bit signed | `long addr = 0x140001450L;` |
| `boolean` | | `true` or `false` | `boolean found = false;` |
| `char` | 2 bytes | one character | `char c = 'A';` |
| `String` | object | text | `String name = "strcmp";` |

Java's `long` is always 8 bytes, unlike C's `long` on Windows. A number above the `int` range needs an `L` suffix, as in `0x140001450L`. Java has no unsigned types.

**Bytes are signed.** In C you would read program bytes as `unsigned char`. In Java a `byte` holding `0xC3` reads as -61. Mask it with `& 0xff` to get 0 to 255 before printing or comparing it:

```java
public class SignedBytes {
    public static void main(String[] args) {
        byte b = (byte) 0xC3;
        System.out.println(b);          // -61
        System.out.println(b & 0xff);   // 195
    }
}
```

## Arrays

An array has a fixed length, set when you create it. Indexes start at 0, and `.length` gives the count. Reading past the end throws an `ArrayIndexOutOfBoundsException` instead of reading random memory.

```java
int[] sizes = new int[4];                 // four ints, all 0
byte[] data = { 0x10, 0x20, 0x30 };       // three bytes
System.out.println(data.length);          // 3
```

## Control flow: if, for, while, for-each

These work as in C, except that conditions must be `boolean`. `if (count)` does not compile; write `if (count != 0)`.

```java
public class Loops {
    public static void main(String[] args) {
        int[] values = { 3, 9, 1 };
        for (int i = 0; i < values.length; i++) {
            System.out.println("values[" + i + "] = " + values[i]);
        }
        int n = 8;
        while (n > 1) {
            n = n / 2;
        }
        for (int v : values) {           // for-each: v takes each element in turn
            if (v > 5) {
                System.out.println("big " + v);
            } else {
                System.out.println("small " + v);
            }
        }
    }
}
```

The for-each loop (`for (Type x : collection)`) works on arrays and on any `Iterable`. An `Iterable` is an object that hands out its elements one by one. Lists, sets and many Ghidra results are `Iterable`. Use the counting `for` when you need the index.

## Objects, methods and null

An object is a value built from a class, such as a `String` or a Ghidra `Function`. You call its methods with a dot: `name.length()`, `name.toUpperCase()`. A variable of a class type holds a reference to an object, which is like a C pointer you cannot do arithmetic on.

`null` means "no object". Many lookups return `null` when they find nothing. Calling a method on `null` throws a `NullPointerException`, so check first:

```java
String found = lookup();        // lookup is any method that may return null
if (found == null) {
    System.out.println("not found");
    return;                     // leave run() early
}
System.out.println(found.length());
```

`instanceof` tests what kind of object you have. Some methods return a general `Object`, and you check before treating it as a `String`:

```java
Object value = "Access granted!";
if (value instanceof String) {
    String text = (String) value;
    System.out.println("string of length " + text.length());
}
```

## Strings

`+` joins strings, and turns numbers and objects into text along the way. For text built in a loop, a `StringBuilder` is cheaper: append to it, then call `toString()` once.

```java
String line = "found " + 3 + " calls";      // "found 3 calls"
StringBuilder sb = new StringBuilder();
sb.append('k').append('e').append('y');
String key = sb.toString();                 // "key"
```

Compare strings with `.equals`, never with `==`. `==` asks whether two variables refer to the same object, which can be false for equal text. Write `name.equals("strcmp")`.

## Hex formatting

| Call | Result | Notes |
| --- | --- | --- |
| `Long.toHexString(0x140001450L)` | `140001450` | lowercase, no `0x` |
| `Integer.toHexString(255)` | `ff` | |
| `Integer.toHexString(b)` with `b` = byte `0xC3` | `ffffffc3` | the byte is widened with its sign; mask first |
| `Integer.toHexString(b & 0xff)` | `c3` | |
| `String.format("%x", 255)` | `ff` | |
| `String.format("%08x", 255)` | `000000ff` | padded to 8 digits |
| `String.format("[%-6s][%3d]", "main", 7)` | `[main  ][  7]` | `-` aligns left; numbers align right |

`String.format` uses the same `%` codes as C's `printf`: `%d`, `%x`, `%s`, `%c`, plus widths.

## Operators

| Operator | Meaning | Example | Result |
| --- | --- | --- | --- |
| `/` | integer division, rounds toward zero | `7 / 2`, `-7 / 2` | `3`, `-3` |
| `%` | remainder, takes the sign of the left side | `7 % 2`, `-7 % 2` | `1`, `-1` |
| `^` | XOR | `0x41 ^ 0x20` | `0x61` |
| `&` | AND | `0xC3 & 0x0F` | `0x03` |
| `\|` | OR | `0x40 \| 0x01` | `0x41` |
| `<<` | shift left | `1 << 4` | `16` |
| `>>` | shift right, copying the sign bit | `-16 >> 2` | `-4` |
| `>>>` | shift right, filling with zeros | `-16 >>> 28` | `15` |
| `==`, `!=` | equal, not equal (numbers, null) | `f != null` | `true` or `false` |
| `&&`, `\|\|`, `!` | logical AND, OR, NOT | `a > 0 && a < 10` | `true` or `false` |

Arithmetic on `byte`, `short` and `char` happens in `int`, so the result is an `int`. That is why storing it back in a byte needs a cast.

## Casting

A cast converts a value to another type by writing the type in parentheses. Narrowing casts drop the high bits without any warning.

```java
long big = 0x140001450L;
int low = (int) big;            // keeps the low 32 bits: 0x40001450
byte b = (byte) 0x1C3;          // keeps the low 8 bits: 0xC3, which reads as -61
char c = (char) 72;             // 'H'
```

Here is a generic example that puts several pieces together: XOR every byte of an array with a key, mask, and build a string. It is plain Java with made-up data.

```java
public class XorDemo {
    public static void main(String[] args) {
        byte[] enc = { 0x2a, 0x07, 0x0e, 0x0e, 0x0d };
        int key = 0x62;
        StringBuilder sb = new StringBuilder();
        for (byte e : enc) {
            int plain = (e & 0xff) ^ key;
            sb.append((char) plain);
        }
        System.out.println(sb.toString());                  // Hello
        System.out.println(String.format("key = 0x%02x", key));
    }
}
```

## Lists and sets

An array cannot grow. When you don't know the count in advance, use a `List`, which grows as you add. A `Set` keeps each value only once, which is handy for "have I seen this already?".

```java
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class Collections101 {
    public static void main(String[] args) {
        List<String> names = new ArrayList<>();
        names.add("main");
        names.add("decode");
        System.out.println(names.size() + " " + names.get(0));   // 2 main

        Set<Long> seen = new HashSet<>();
        seen.add(0x1000L);
        boolean isNew = seen.add(0x1000L);                       // false: already there
        System.out.println(isNew + " " + seen.contains(0x1000L)); // false true

        for (String n : names) {
            System.out.println(n);
        }
    }
}
```

The type in angle brackets says what the collection holds. Collections hold objects, so use `Long` and `Integer` rather than `long` and `int` there; Java converts between them for you. `isEmpty()` tells you whether anything was added.

## Exceptions

An exception is Java's way of reporting an error at run time, such as a `NullPointerException` or an `ArrayIndexOutOfBoundsException`. It stops the current method and travels up to its caller, until something catches it.

In a script, Ghidra catches it and prints its name and a stack trace. The top lines that name your script's file give the line number. You rarely need `try`/`catch` today, because `run()` already declares `throws Exception`.

## Reading a compiler error

When the script does not compile, the console shows messages in the form `file:line: error: message`, with a caret (`^`) under the spot. Fix the first error first; later ones are often side effects.

```text
Broken.java:3: error: ';' expected
        int count = 0
                     ^
Broken.java:4: error: incompatible types: possible lossy conversion from int to byte
        byte b = 200;
                 ^
Broken.java:6: error: cannot find symbol
        System.out.println(nmae);
                           ^
  symbol:   variable nmae
```

- **`';' expected`**: a missing semicolon at the end of the line shown, or just before it.
- **`possible lossy conversion`**: the value does not fit the type. Add a cast if you mean it, or use a wider type.
- **`cannot find symbol`**: a typo in a name, a method that doesn't exist on that type, or a missing `import`.

## The Ghidra objects you will meet

Each object in a script stands for something you can click on in the CodeBrowser. You get them from methods your script inherits, and you call their methods to ask questions. These are the main ones on Day 5:

| Object | What it represents | API page |
| --- | --- | --- |
| `Program` | The open program; your script reaches it as `currentProgram` | [Program](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/Program.html) |
| `Address` | One location in the program, shown in hex like the Listing | [Address](https://ghidra.re/ghidra_docs/api/ghidra/program/model/address/Address.html) |
| `Function` | One function from the Symbol Tree: its name, entry point and body | [Function](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/Function.html) |
| `Instruction` | One line of disassembly: mnemonic, operands and its own references | [Instruction](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/Instruction.html) |
| `Reference` | One arrow from the references window: a "from" and a "to" address | [Reference](https://ghidra.re/ghidra_docs/api/ghidra/program/model/symbol/Reference.html) |
| `Data` | One defined data item, such as a string or a pointer | [Data](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/Data.html) |
| `Scalar` | A plain number inside an instruction's operand, such as `0x5a` | [Scalar](https://ghidra.re/ghidra_docs/api/ghidra/program/model/scalar/Scalar.html) |

A few Java facts help with these:

- **Addresses are objects, not numbers.** You can't use `+` on an `Address`; it has its own methods for moving and comparing. Compare two addresses with `.equals`, like strings.
- **Lookups can return `null`.** "The function containing this address" or "the data at this address" may not exist. Check for `null` before calling a method.
- **Results come as arrays or iterables.** Some calls return an array such as `Reference[]`, and others an iterator object. For-each works on both.
- **Numbers come back as `long`.** Offsets and scalar values are 64-bit. Cast to `int` only when you know the value fits, such as a length.
- **The flat API.** Most helper methods, like `getFunctionContaining` and `getBytes`, come from [FlatProgramAPI](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html). Your script can call them directly, without a dot in front.

The full API is at [ghidra.re/ghidra_docs/api](https://ghidra.re/ghidra_docs/api/). The Script Manager's Help button opens the same documentation offline. [Day 5](../day5-training.md), Module 1A, shows how to open the Script Manager, edit a skeleton and find these pages.

## Check yourself

1. What must the class name of `Day5ListFunctions.java` be?
2. What does `@Override` protect you from?
3. A `byte` holds `0xF0`. What does `System.out.println(b)` print, and how do you get 240?
4. What are `17 / 5` and `17 % 5` in Java?
5. Why does `if (name == "strcmp")` sometimes fail when `name` holds that text?
6. A method may return `null`. What happens if you call a method on its result without checking?
7. The console shows `MyScript.java:14: error: cannot find symbol`. Name two likely causes.
8. What does `Long.toHexString(0x140001000L)` return?

<details><summary>Answers</summary>

1. `Day5ListFunctions`, exactly, including the capitals.
2. From misspelling or mis-declaring the method you mean to replace. The compiler reports an error instead of ignoring it.
3. It prints `-16`, because Java bytes are signed. `b & 0xff` gives 240.
4. `3` and `2`. Integer division drops the fraction.
5. `==` compares whether two variables refer to the same object, not the text. Use `name.equals("strcmp")`.
6. A `NullPointerException` stops the script, and the console shows a stack trace.
7. A typo in a variable or method name, a missing `import`, or a method that doesn't exist on that type.
8. `"140001000"`: lowercase hex digits, with no `0x` prefix.

</details>
