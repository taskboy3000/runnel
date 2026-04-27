# AI Agent Guidelines

## Project Overview
- Name: runnel
- Author: Joe Johnston <jjohn@taskboy.com>
- Purpose: A brain-dead MP3 streamer written in HTML5 with minimal javascript
- License: CC BY 4.0
- The structure of this app: ./index.md

## Coding Standards
- Always make a plan.md before working on implementation
- Each step in a plan should be small and not break the build
- Always ask the user to approve of each change when a step is completed
- Use Perl best practices with Mojolicious framework
- Perl modules 'use' statements should be sorted.  Pragma statements like 'use strict', 'use warnings', 'use experimental', 'use lib' should not be re-ordered.  Don't change the user's order of pragmas. 
- Follow PS1 standard for Perl code formatting
- Use explicit package declarations
- Maintain 2 spaces per indent
- Avoid bareword filehandles
- Add perl module dependencies to cpanfile
- Use cpanm --installdeps . to install module dependencies
- Indent perl code with perltidy using: `make indent`
- Get perl test coverage using: `make cover && make report`

## Testing
- All new features require unit tests in `t/`
- Use Test::More for test scripts
- Ensure 100% test coverage for public APIs
- Validate input sanitization

## Collaboration
- When a prompt requires it, ask the user clarifying questions.
- Never do git commit or git push. The user has to do this manually
- Make plans with small, isolated steps that do not break the codebase
- Never execute a step in a plan without permission from the user
- Plans should attempt to reduce technical debt when possible
- Run `script/runnel test` before merging
- Document changes in index.md

## Tools
- Use `grep` for code searches
- Use `read` for file inspection
- Use `edit` for tool use
- Use `bash` for system commands
- Run `perl -Ilib -wc <file>` to check Perl syntax
- Run `perlcritic file.pl` to get opinions about coding style on .pl and .pm files

## Perl Best Practices for File I/O
- Use lexical filehandles: `open(my $fh, '>', $file)` not `open(FH, '>', $file)`
- Always use `or die "$file: $!"` for open failures (note `$!` not `$1`)
- Use File::Temp for tests: `File::Temp->new(UNLINK => 0, SUFFIX => '.json')` to get temp file path
- Slurp file with lexical handle: use `local $/ = undef` block
- Return perl idiomatic boolean types: prefer `return 1` for success and `return` for failure; Avoid returning `undef`

## Workflow
1. Read index.md to understand the project structure and file locations before implementing any plan
2. Edit files using `edit` tool
3. Verify changes with `read` tool
4. Run tests with `script/runnel test`