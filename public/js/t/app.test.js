import { Playlist } from '../Playlist.js';
import { validateSearchTerm } from '../InputValidator.js';
import * as app from '../app.js';

describe('InputValidator', () => {
  test('returns trimmed string for valid input', () => {
    expect(validateSearchTerm('foo')).toBe('foo');
    expect(validateSearchTerm('  bar  ')).toBe('bar');
  });

  test('returns null for empty/whitespace', () => {
    expect(validateSearchTerm('')).toBeNull();
    expect(validateSearchTerm('   ')).toBeNull();
  });

  test('returns null for invalid types', () => {
    expect(validateSearchTerm(null)).toBeNull();
    expect(validateSearchTerm(123)).toBeNull();
  });

  test('returns null for string over 255 chars', () => {
    expect(validateSearchTerm('a'.repeat(256))).toBeNull();
  });

  test('accepts exactly 255 chars', () => {
    const max = 'a'.repeat(255);
    expect(validateSearchTerm(max)).toBe(max);
  });

  test('preserves special characters', () => {
    expect(validateSearchTerm("Robert'; DROP TABLE songs--")).toBe("Robert'; DROP TABLE songs--");
  });

  test('accepts single character and unicode', () => {
    expect(validateSearchTerm('A')).toBe('A');
    expect(validateSearchTerm('rock 🎸')).toBe('rock 🎸');
  });
});

describe('songSearchFormHandler', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div class="content controller songs">
        <form id="song-search">
          <input type="text" name="search" value="test">
        </form>
        <section class="songs">
          <div class="card-body"></div>
          <table id="song-list"></table>
        </section>
      </div>
      <div id="toast-notice">
        <div class="toast-body"></div>
      </div>
    `;

    global.bootstrap = {
      Toast: jest.fn().mockImplementation(() => ({ show: jest.fn() }))
    };

    global.fetch = jest.fn().mockResolvedValue({
      text: () => Promise.resolve('<p>Results</p>'),
      json: () => Promise.resolve({})
    });
  });

  test('calls preventDefault on event', () => {
    const event = { preventDefault: jest.fn() };
    app.songSearchFormHandler(event);
    expect(event.preventDefault).toHaveBeenCalled();
  });

  test('calls loadSongsTable when term is empty', () => {
    document.querySelector('input[name=search]').value = '';
    global.fetch.mockClear();
    app.songSearchFormHandler({ preventDefault: jest.fn() });
    expect(global.fetch).toHaveBeenCalledWith('/songs/songs_table');
  });
});

describe('loadSongsTable', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <section class="songs">
        <div class="card-body"></div>
      </section>
    `;
    global.fetch = jest.fn().mockResolvedValue({
      text: () => Promise.resolve('<table></table>')
    });
  });

  test('fetches songs table from /songs/songs_table', () => {
    app.loadSongsTable();
    expect(global.fetch).toHaveBeenCalledWith('/songs/songs_table');
  });

  test('renders response to card-body', async () => {
    const html = '<table><tr><td>Song</td></tr></table>';
    global.fetch.mockResolvedValue({
      text: () => Promise.resolve(html)
    });

    app.loadSongsTable();
    await new Promise(r => setTimeout(r, 10));
    expect(document.querySelector('.card-body').innerHTML).toContain('Song');
  });

  test('does nothing when card-body is not present', () => {
    document.body.innerHTML = '<div>No card body</div>';
    app.loadSongsTable();
    expect(global.fetch).not.toHaveBeenCalled();
  });
});

describe('handleMediaAddsAsynchronously', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <section class="songs">
        <table id="song-list">
          <tbody>
            <tr><td><a href="/songs/add/1">Add</a></td></tr>
          </tbody>
        </table>
      </section>
    `;
    global.fetch = jest.fn().mockResolvedValue({
      json: () => Promise.resolve({ msg: 'Added' })
    });
  });

  test('attaches click handlers to anchors', () => {
    app.handleMediaAddsAsynchronously();
    const anchors = document.querySelectorAll('a');
    anchors.forEach(a => expect(a.onclick).toBeDefined());
  });

  test('click fetches with correct headers', async () => {
    app.handleMediaAddsAsynchronously();
    document.querySelector('a').click();
    await new Promise(r => setTimeout(r, 10));
    expect(global.fetch).toHaveBeenCalledWith('/songs/add/1', expect.objectContaining({
      headers: { "Accept": "application/json" }
    }));
  });

  test('does nothing when no anchors found', () => {
    document.body.innerHTML = '<div>No links</div>';
    expect(() => app.handleMediaAddsAsynchronously()).not.toThrow();
  });
});

describe('updatePlaylistCount', () => {
  beforeEach(() => {
    document.body.innerHTML = '<span id="playlist-count">0</span>';
    global.fetch = jest.fn().mockResolvedValue({
      json: () => Promise.resolve([1, 2, 3])
    });
  });

  test('fetches /playlists/current', async () => {
    await app.updatePlaylistCount();
    expect(global.fetch).toHaveBeenCalledWith('/playlists/current', expect.anything());
  });

  test('updates badge text', async () => {
    await app.updatePlaylistCount();
    expect(document.getElementById('playlist-count').textContent).toBe('3');
  });

  test('handles missing badge', async () => {
    document.body.innerHTML = '<div>No badge</div>';
    await expect(app.updatePlaylistCount()).resolves.not.toThrow();
  });
});

describe('showToastNotice', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div id="toast-notice">
        <div class="toast-body"></div>
      </div>
    `;
    global.bootstrap = {
      Toast: jest.fn().mockImplementation(() => ({ show: jest.fn() }))
    };
  });

  test('updates toast body', () => {
    app.showToastNotice('Test message');
    expect(document.querySelector('.toast-body').innerHTML).toBe('Test message');
  });

  test('creates and shows toast', () => {
    app.showToastNotice('Test');
    expect(global.bootstrap.Toast).toHaveBeenCalled();
  });

  test('handles missing bootstrap', () => {
    delete global.bootstrap;
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
    app.showToastNotice('Test');
    expect(warnSpy).toHaveBeenCalled();
    warnSpy.mockRestore();
  });

  test('handles missing toast element', () => {
    document.body.innerHTML = '<div>No toast</div>';
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
    app.showToastNotice('Test');
    expect(warnSpy).toHaveBeenCalled();
    warnSpy.mockRestore();
  });
});

describe('init', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div class="content controller songs">
        <section class="songs">
          <div class="card-body"></div>
        </section>
      </div>
    `;
    global.window.Runnel = undefined;
    global.fetch = jest.fn().mockResolvedValue({
      text: () => Promise.resolve('<p></p>'),
      json: () => Promise.resolve([])
    });
  });

  test('creates Runnel namespace', () => {
    app.init();
    expect(window.Runnel).toBeDefined();
  });

  test('does not error without controller', () => {
    document.body.innerHTML = '<div>No controller</div>';
    expect(() => app.init()).not.toThrow();
  });
});
