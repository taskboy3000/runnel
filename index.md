# Project Structure

## 1. Git Metadata
- `.git/`: Git repository metadata
  - `config`, `description`, `HEAD`: Git configuration files
  - `objects/`: Stored Git objects
  - `refs/`: Reference pointers to commits

## 2. Application Code
- `lib/`: Perl modules
  - `Runnel.pm`: Main application module
  - `Controller/`: Request handlers
    - `Players.pm`, `Playlists.pm`, `Songs.pm`
  - `Catalog.pm`: Catalog functionality
  - `Playlist.pm`: Playlist entity
  - `Service/`: Business logic services
    - `SongSearch.pm`: Song search service
    - `PlaylistManager.pm`: Playlist management service
- `script/runnel`: Application entry point
- `public/`: Static assets
  - `css/`: Stylesheets
  - `js/`: JavaScript files
    - `Player.js`: Audio playback
    - `Playlist.js`: Playlist management
    - `Template.js`: Template rendering
    - `InputValidator.js`: Input validation
    - `app.js`: Application entry
  - `index.html`: Main HTML file

## 3. Templates
- `templates/`: HTML templates
  - `layouts/`: Shared layouts
  - `songs/`, `playlists/`, `players/`: Content-specific templates

## 4. Documentation
- `README.md`: Project overview
- `LICENCE.txt`: License information
- `plan.md`: Development roadmap
- `architectural_concerns.md`: Technical design notes

## 5. Configuration
- `runnel-dist.yml`: Distribution configuration
- `cpanfile`: Perl dependency list
- `package.json`: Node.js configuration
- `babel.config.js`: Babel transpilation config
- `t/jest.config.js`: Jest test configuration

## 6. Technology Stack
- **Backend**: Perl (Mojolicious framework, CPAN dependencies)
- **Frontend**: HTML, CSS, JavaScript (with Sortable.js library)
- **Version Control**: Git
- **Testing**: Perl test scripts (`basic.t`), Jest for JavaScript
- **Workspace**: VS Code configuration (`Runnel.code-workspace`)

## 7. Development
- `.gitignore`: File exclusion patterns
- `basic.t`: Test script
- `plan.md`: An empheral document that covers the plan for the current development task

## 8. Testing
### Perl Tests
- `t/basic.t`: Integration tests for main app
- `t/Catalog.t`: Unit tests for Runnel::Catalog
- `t/Playlist.t`: Unit tests for Runnel::Playlist
- `t/Service/SongSearch.t`: Unit tests for song search service
- `t/Service/PlaylistManager.t`: Unit tests for playlist manager
- `t/fake_catalog/`: Test data with fake mp3 files
- `t/runnel-test.yml`: Test configuration

### JavaScript Tests
- `public/js/t/*.test.js`: Jest test files for JavaScript modules
- `t/jest.config.js`: Jest configuration
- `t/babel.config.js`: Babel configuration for ES modules
- Run with `npm test` (Jest) or `script/runnel test` (Perl)