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
- Use `edit` for precise changes
- Use `bash` for system commands

## Workflow
1. Edit files using `edit` tool
2. Verify changes with `read` tool
3. Run tests with `script/runnel test`