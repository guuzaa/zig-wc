# wc - Word Count Utility in Zig

A modern implementation of the classic Unix `wc` utility written in the Zig programming language. This tool counts lines, words, and characters in text files or from standard input.

## Features

- Count lines, words, and characters in files or from stdin
- Selectively display only the counts you need
- Process multiple files at once with totals
- Clean, modular codebase with comprehensive test coverage

## Installation

### Prerequisites

- Zig compiler (0.13 or later recommended)

### Building from Source

Clone the repository and build using Zig's build system:

```bash
git clone https://github.com/yourusername/wc.git
cd wc
zig build
```

The executable will be available at `zig-out/bin/wc`.

### Installing System-wide

```bash
zig build install
```

## Usage

```
Usage: wc [OPTION]... [FILE]...
Print newline, word, and byte counts for each FILE, and a total line if
more than one FILE is specified. If no FILE is specified, read standard input.

Options:
  -c      print the byte counts
  -l      print the newline counts
  -w      print the word counts
  -h, --help  display this help and exit

With no options, print line, word, and byte counts.
```

### Examples

Count lines, words, and characters in a file:
```bash
wc file.txt
```

Count only lines in multiple files:
```bash
wc -l file1.txt file2.txt
```

Count words from standard input:
```bash
cat file.txt | wc -w
```

## Project Structure

- `src/main.zig`: Entry point and main program flow
- `src/counter.zig`: Core counting functionality
- `src/options.zig`: Command-line options handling
- `src/formatter.zig`: Output formatting
- `src/cli.zig`: Command-line argument parsing
- `build.zig`: Build configuration

## Development

### Running Tests

```bash
zig build test
```

### Building with Different Optimization Levels

```bash
# Debug build
zig build -Doptimize=Debug

# Release build
zig build -Doptimize=ReleaseFast
```

## How It Works

The program reads input either from files specified on the command line or from standard input if no files are provided. It counts:

- **Lines**: The number of newline characters (`\n`)
- **Words**: Sequences of non-whitespace characters
- **Characters**: The total number of bytes

For each file, it displays the requested counts along with the filename. If multiple files are processed, a total line is displayed at the end.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Unlicense License - see the `LICENSE.txt` file for details.
