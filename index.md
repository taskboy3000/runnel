# Project Structure

## Overview
A brain-dead MP3 streamer using HTML5, Perl (Mojolicious), and minimal JavaScript.

## File Map

### Perl Modules (`lib/`)
| File | Purpose |
|------|---------|
| `lib/Runnel.pm` | Main Mojolicious app: routes, helpers (`catalog`, `playlist`, `song_search`, `playlist_manager`) |
| `lib/Runnel/Controller.pm` | Base controller with `short_name` helper |
| `lib/Runnel/Controller/Players.pm` | Player state endpoints (current song, play/pause) |
| `lib/Runnel/Controller/Playlists.pm` | Playlist CRUD endpoints |
| `lib/Runnel/Controller/Songs.pm` | Song browse and search endpoints |
| `lib/Runnel/Catalog.pm` | MP3 scanning, catalog caching, song/artist indexing (Tree::Trie) |
| `lib/Runnel/Playlist.pm` | Current playback queue and state model |
| `lib/Runnel/Service/SongSearch.pm` | Full-text song search using Trie |
| `lib/Runnel/Service/PlaylistManager.pm` | Playlist CRUD operations service |
| `lib/Runnel/Command.pm` | Base class for custom Mojolicious commands |
| `lib/Runnel/Command/scan.pm` | CLI command: `script/runnel scan` to index MP3 files |

### Templates (`templates/`)
| File | Purpose |
|------|---------|
| `templates/layouts/default.html.ep` | Base HTML layout with navbar |
| `templates/songs/index.html.ep` | Song browse UI |
| `templates/songs/fragments/song_table.html.ep` | Song table partial (AJAX) |
| `templates/playlists/show_current.html.ep` | Current playlist display |
| `templates/playlists/fragments/playlist_table.html.ep` | Playlist table partial (AJAX) |
| `templates/players/index.html.ep` | Player controls UI |

### Static Assets (`public/`)
| File | Purpose |
|------|---------|
| `public/index.html` | Main SPA entry point |
| `public/js/app.js` | App init, routing, event binding |
| `public/js/Player.js` | HTML5 Audio API playback controller |
| `public/js/Playlist.js` | Playlist management, Sortable.js integration |
| `public/js/Template.js` | Client-side template rendering |
| `public/js/InputValidator.js` | Form input validation |
| `public/js/contrib/sortable.min.js` | SortableJS drag-and-drop library |
| `public/css/app.css` | Custom styles |
| `public/css/contrib/sortable.min.css` | Sortable.js styles |

### JavaScript Tests (`public/js/t/`)
| File | Purpose |
|------|---------|
| `public/js/t/app.test.js` | Jest tests for app.js |
| `public/js/t/Player.test.js` | Jest tests for Player.js |
| `public/js/t/Playlist.test.js` | Jest tests for Playlist.js |
| `public/js/t/Template.test.js` | Jest tests for Template.js |

### Perl Tests (`t/`)
| File | Purpose |
|------|---------|
| `t/basic.t` | Integration tests |
| `t/Catalog.t` | Runnel::Catalog unit tests |
| `t/Playlist.t` | Runnel::Playlist unit tests |
| `t/Service/SongSearch.t` | SongSearch service tests |
| `t/Service/PlaylistManager.t` | PlaylistManager service tests |

### Test Support
| File | Purpose |
|------|---------|
| `t/runnel-test.yml` | Test config (points to fake catalog) |
| `t/babel.config.js` | Babel config for JS test transpilation |
| `t/jest.config.js` | Jest configuration |
| `t/fake_catalog/test.mp3` | Fake MP3 test fixture |
| `t/fake_catalog/test1.mp3` | Fake MP3 test fixture |
| `t/fake_catalog/test2.mp3` | Fake MP3 test fixture |
| `t/fake_catalog/test3.mp3` | Fake MP3 test fixture |

### Configuration (Root)
| File | Purpose |
|------|---------|
| `runnel.yml` | Main config: music dir, port, etc. |
| `runnel-dist.yml` | Production/deployment config |
| `cpanfile` | Perl dependencies |
| `package.json` | Node dependencies (Jest, Babel, Sortable) |
| `package-lock.json` | Locked Node dependency versions |
| `Makefile` | Build targets: test, cover, report, indent, critic |
| `script/runnel` | CLI entry point for Mojolicious commands |
| `cache/catalog.json` | Cached MP3 catalog with metadata |

### Configuration Options (`runnel.yml`)
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `mp3BaseDirectory` | string | (required) | Path to the directory containing MP3 files |
| `secrets` | string | (required) | Secret key for Mojolicious session management |
| `scan_interval` | integer | 60 | Interval in seconds between catalog scans. Minimum value is 60 seconds; values below 60 will be ignored and default to 60. |

### Other Root Files
| File | Purpose |
|------|---------|
| `AGENTS.md` | AI agent guidelines and coding standards |
| `README.md` | Project overview and usage |
| `LICENCE.txt` | CC BY 4.0 license |
| `DO_NOT_PUSH` | Warning: do not push to remote |
| `Runnel.code-workspace` | VSCode workspace config |
| `.gitignore` | Git ignore rules |
