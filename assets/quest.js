// This week's two books, the reading mission, and the shelf that opens once the report photo is in.
// Everything Simon does here stays on this iPad (localStorage + IndexedDB); the guardian's GitHub link
// is what tells the weekly job (.claude/skills/weekly-books) that the book is finished.
(function () {
  'use strict';

  var dataEl = document.getElementById('quest-data');
  var quest = document.getElementById('quest');
  if (!dataEl || !quest) return;
  var DATA = JSON.parse(dataEl.textContent);
  var weekly = DATA.weekly || {};
  var books = weekly.books || [];
  var KEY = 'readcheck:quest:v1';
  var $ = function (sel, root) { return (root || document).querySelector(sel); };
  var $$ = function (sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); };
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // ---------- dates (local time, YYYY-MM-DD) ----------
  function ymd(d) { return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0'); }
  function parse(s) { var p = String(s).split('-'); return new Date(+p[0], +p[1] - 1, +p[2]); }
  var today = ymd(new Date());
  function nextSaturday(after) {
    var d = parse(after);
    do { d.setDate(d.getDate() + 1); } while (d.getDay() !== 6);
    return ymd(d);
  }
  function korDate(s) { var d = parse(s); return (d.getMonth() + 1) + '월 ' + d.getDate() + '일 ' + '일월화수목금토'[d.getDay()] + '요일'; }

  // 이/가, 은/는 after a Korean word.
  function hasFinal(word) {
    var c = String(word).trim().slice(-1).charCodeAt(0);
    return c >= 0xac00 && c <= 0xd7a3 && (c - 0xac00) % 28 !== 0;
  }
  function iga(w) { return w + (hasFinal(w) ? '이' : '가'); }
  function gradeLabel(g) {
    var m = String(g || '').match(/^(초|중|고)(\d)$/);
    if (!m) return '초등학생';
    return { 초: '초등학교', 중: '중학교', 고: '고등학교' }[m[1]] + ' ' + m[2] + '학년';
  }

  // ---------- state ----------
  var state;
  try { state = JSON.parse(localStorage.getItem(KEY) || 'null'); } catch (e) { state = null; }
  state = state || { history: [] };
  state.history = state.history || [];
  function save() { try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) { /* private mode: works until reload */ } }

  // ---------- report photo in IndexedDB ----------
  function db() {
    return new Promise(function (resolve, reject) {
      if (!window.indexedDB) { reject(new Error('no indexedDB')); return; }
      var req = indexedDB.open('simon-books', 1);
      req.onupgradeneeded = function () { req.result.createObjectStore('reports'); };
      req.onsuccess = function () { resolve(req.result); };
      req.onerror = function () { reject(req.error); };
    });
  }
  function putPhoto(slug, blob) {
    return db().then(function (d) {
      return new Promise(function (resolve, reject) {
        var tx = d.transaction('reports', 'readwrite');
        tx.objectStore('reports').put(blob, slug);
        tx.oncomplete = resolve; tx.onerror = function () { reject(tx.error); };
      });
    });
  }
  function getPhoto(slug) {
    return db().then(function (d) {
      return new Promise(function (resolve) {
        var req = d.transaction('reports').objectStore('reports').get(slug);
        req.onsuccess = function () { resolve(req.result || null); };
        req.onerror = function () { resolve(null); };
      });
    }).catch(function () { return null; });
  }

  // Phone photos are huge; 1600 px on the long side is plenty to read handwriting.
  function shrink(file) {
    return new Promise(function (resolve) {
      var url = URL.createObjectURL(file);
      var img = new Image();
      img.onload = function () {
        var scale = Math.min(1, 1600 / Math.max(img.naturalWidth, img.naturalHeight));
        var c = document.createElement('canvas');
        c.width = Math.round(img.naturalWidth * scale); c.height = Math.round(img.naturalHeight * scale);
        c.getContext('2d').drawImage(img, 0, 0, c.width, c.height);
        URL.revokeObjectURL(url);
        c.toBlob(function (b) { resolve(b || file); }, 'image/jpeg', 0.86);
      };
      img.onerror = function () { URL.revokeObjectURL(url); resolve(file); };
      img.src = url;
    });
  }

  // ---------- the 3D book ----------
  function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }

  // The spine takes the colour of the cover's left edge, so each book looks like itself from the side.
  function paintSpine(stage) {
    var img = $('.front img', stage);
    if (!img) return;
    function go() {
      try {
        var c = document.createElement('canvas'); c.width = 8; c.height = 32;
        var x = c.getContext('2d');
        x.drawImage(img, 0, 0, Math.max(1, img.naturalWidth * 0.05), img.naturalHeight, 0, 0, 8, 32);
        var px = x.getImageData(0, 0, 8, 32).data, r = 0, g = 0, b = 0, n = px.length / 4;
        for (var i = 0; i < px.length; i += 4) { r += px[i]; g += px[i + 1]; b += px[i + 2]; }
        r = Math.round(r / n); g = Math.round(g / n); b = Math.round(b / n);
        stage.style.setProperty('--spine', 'rgb(' + r + ',' + g + ',' + b + ')');
        stage.style.setProperty('--spine-ink', (0.299 * r + 0.587 * g + 0.114 * b) > 150 ? '#1f2a5c' : '#fff');
      } catch (e) { /* tainted canvas: keep the default spine */ }
    }
    if (img.complete && img.naturalWidth) go(); else img.addEventListener('load', go, { once: true });
  }

  function wireBook(stage) {
    var el = $('.book3d', stage), b3 = $('.b3', stage);
    if (!el || el.dataset.wired) return;
    el.dataset.wired = '1';
    var FRONT = -26, BACK = 154;
    var ry = FRONT, rx = 3, start = null;
    function set() { b3.style.setProperty('--ry', ry + 'deg'); b3.style.setProperty('--rx', rx + 'deg'); }
    function facingBack() { return Math.cos((ry - FRONT) * Math.PI / 180) < 0; }
    function sync() {
      var back = facingBack();
      stage.classList.toggle('is-flipped', back);
      el.setAttribute('aria-pressed', String(back));
    }
    function poke() {
      stage.classList.remove('is-poked'); void stage.offsetWidth; stage.classList.add('is-poked');
    }
    function flip() {
      ry += facingBack() ? 180 : 180; // always turn the same way, like turning a real book over
      set(); sync(); poke();
    }
    function snap() {
      var base = facingBack() ? BACK : FRONT;
      ry = base + 360 * Math.round((ry - base) / 360); rx = 3; set(); sync();
    }
    el.addEventListener('pointerdown', function (e) {
      if (e.button > 0) return;
      start = { x: e.clientX, y: e.clientY, ry: ry, rx: rx, moved: false, id: e.pointerId };
    });
    el.addEventListener('pointermove', function (e) {
      if (!start) return;
      var dx = e.clientX - start.x, dy = e.clientY - start.y;
      if (!start.moved) {
        if (Math.abs(dx) < 6 && Math.abs(dy) < 6) return;
        start.moved = true; el.classList.add('is-dragging');
        try { el.setPointerCapture(start.id); } catch (err) { /* ignore */ }
      }
      ry = start.ry + dx * 0.7; rx = clamp(start.rx - dy * 0.3, -24, 24); set();
    });
    function end() {
      if (!start) return;
      var moved = start.moved; start = null;
      el.classList.remove('is-dragging');
      if (moved) snap(); else flip();
    }
    el.addEventListener('pointerup', end);
    el.addEventListener('pointercancel', function () { if (start) { start.moved = true; end(); } });
    el.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); flip(); }
      if (e.key === 'ArrowLeft') { ry -= 25; set(); sync(); }
      if (e.key === 'ArrowRight') { ry += 25; set(); sync(); }
    });
    el.addEventListener('animationend', function () { el.classList.remove('drop'); });
    stage.addEventListener('animationend', function () { stage.classList.remove('is-poked'); });
    paintSpine(stage);
    set();
  }

  // ---------- views ----------
  var views = { choose: $('[data-view=choose]'), read: $('[data-view=read]'), done: $('[data-view=done]') };
  function show(name) {
    Object.keys(views).forEach(function (k) { views[k].hidden = k !== name; });
    var zone = document.getElementById('shelf');
    var locked = name === 'read';
    zone.classList.toggle('is-locked', locked);
    $('[data-lock]', zone).hidden = !locked;
  }

  function bookBy(slug) { return books.filter(function (b) { return b.slug === slug; })[0]; }

  function promptFor(b) {
    return [
      '너는 ' + gradeLabel(weekly.grade) + ' 시몬의 독서 친구야. 시몬이 ' + b.author + '의 「' + b.title + '」' + (hasFinal(b.title) ? '을' : '를') + ' 다 읽고 종이에 손으로 독후감을 썼어. 사진을 함께 올릴게.',
      '책 소개: ' + (b.about || ''),
      '',
      '먼저 사진 속 독후감을 그대로 옮겨 적어 줘. 글씨를 읽기 어려운 곳은 [?]로 두고 시몬에게 물어봐.',
      '그다음 아래 순서로 대화해 줘. 한 번에 질문은 하나만 하고, 시몬이 대답하면 다음으로 넘어가.',
      '1. 독후감에서 시몬이 가장 하고 싶은 말을 한 문장으로 다시 말해 보게 해 줘.',
      '2. 그렇게 생각한 까닭을 책 속 장면이나 문장에서 찾게 해 줘.',
      '3. 다른 사람이라면 어떻게 생각할지 반대 의견을 하나 들려주고, 시몬이 어떻게 대답할지 물어봐 줘.',
      '4. 이야기의 처음, 가운데, 끝이 어떻게 이어지는지 시몬의 말로 정리하게 해 줘.',
      '5. 마지막으로 독후감에서 잘한 점 두 가지와 다음에 해 볼 점 한 가지를 알려 줘.',
      '',
      '답을 먼저 알려 주지 말고, 시몬이 스스로 생각하도록 물어봐 줘. 쉬운 말로, 다정하게 이야기해 줘.'
    ].join('\n');
  }

  function markdownFor(b, started, finished) {
    function q(s) { return JSON.stringify(String(s || '').trim()); }
    var lines = ['---', 'title: ' + q(b.title), 'author: ' + q(b.author), 'status: finished'];
    if (b.genre) lines.push('genre: ' + q(b.genre));
    if (b.pages) lines.push('pages: ' + Number(b.pages));
    if (started) lines.push('started: ' + started);
    lines.push('finished: ' + finished, 'summary: ' + q(b.about));
    if (b.cover) lines.push('cover: ' + q(b.cover));
    if (b.isbn) lines.push('isbn: ' + q(b.isbn));
    if (b.buddy) lines.push('buddy: ' + q(b.buddy));
    if (b.buddy_art) lines.push('buddy_art: ' + q(b.buddy_art));
    if (b.book_type) lines.push('book_type: ' + b.book_type);
    if (b.size_mm) lines.push('size_mm: [' + b.size_mm.join(', ') + ']');
    lines.push('published: true', '---', '');
    return lines.join('\n') + '\n';
  }

  var photoUrl = null;
  function renderRead() {
    var b = state.pickBook;
    var stageWrap = $('[data-read-stage]');
    var src = $('.pick[data-slug="' + b.slug + '"] .stage');
    stageWrap.textContent = '';
    if (src) {
      var clone = src.cloneNode(true);
      $$('[data-wired]', clone).forEach(function (n) { n.removeAttribute('data-wired'); });
      $('.book3d', clone).classList.remove('drop');
      stageWrap.replaceWith(clone);
      clone.setAttribute('data-read-stage', '');
      wireBook(clone);
    } else {
      // The week moved on before this book was finished: draw it from what was saved.
      stageWrap.className = 'stage';
      stageWrap.style.cssText = '--w:' + b.size_mm[0] + ';--h:' + b.size_mm[1] + ';--d:' + b.size_mm[2];
      stageWrap.innerHTML = (b.buddy_art ? '<img class="buddy" alt="">' : '') +
        '<div class="book3d" tabindex="0" role="button" aria-pressed="false"><div class="b3"><div class="face front"><img alt="" draggable="false"></div>' +
        '<div class="face back"><p class="back-power"></p><p class="back-about"></p></div><div class="face spine"><span></span></div>' +
        '<div class="face edge"></div><div class="face top"></div><div class="face bottom"></div></div></div>';
      if (b.buddy_art) $('.buddy', stageWrap).src = DATA.base + b.buddy_art;
      $('.front img', stageWrap).src = DATA.base + b.cover;
      $('.back-power', stageWrap).textContent = b.power || '';
      $('.back-about', stageWrap).textContent = b.about || '';
      $('.spine span', stageWrap).textContent = b.title;
      $('.book3d', stageWrap).setAttribute('aria-label', b.title + ' 뒤집어 보기');
      wireBook(stageWrap);
    }
    $('[data-read-title]').textContent = b.title + ' 읽는 중';
    $('[data-read-sub]').textContent = iga(b.buddy || '책콩') + ' 책 위에서 기다려요. 다 읽고 독후감을 쓰면 함께 책장으로 가요.';
    $('[data-prompt]').textContent = promptFor(b);
    syncSteps();
    if (state.photo) getPhoto(b.slug).then(function (blob) { if (blob) showPhoto(blob); });
  }

  function syncSteps() {
    var li = function (s) { return $('.mission [data-step=' + s + ']'); };
    li('write').classList.toggle('is-done', !!state.written || !!state.photo);
    li('photo').classList.toggle('is-done', !!state.photo);
    li('talk').classList.toggle('is-locked', !state.photo);
    $('[data-copy-prompt]').disabled = !state.photo;
    $('[data-shelve]').disabled = !state.photo;
    $('[data-repick-wrap]').hidden = !!state.photo;
  }

  var photoBlob = null;
  function showPhoto(blob) {
    photoBlob = blob;
    if (photoUrl) URL.revokeObjectURL(photoUrl);
    photoUrl = URL.createObjectURL(blob);
    var img = $('[data-photo-preview]');
    img.src = photoUrl; img.hidden = false;
    var file = new File([blob], 'report.jpg', { type: 'image/jpeg' });
    var share = $('[data-share]');
    share.hidden = !(navigator.canShare && navigator.canShare({ files: [file] }));
  }

  function renderDone() {
    var last = state.history[state.history.length - 1];
    if (!last) { show('choose'); return; }
    var nextDay = weekly.proposed && weekly.proposed > last.doneAt ? weekly.proposed : nextSaturday(last.doneAt);
    var img = $('[data-done-buddy]');
    if (last.buddy_art) { img.src = DATA.base + last.buddy_art; img.alt = last.buddy || ''; img.hidden = false; } else img.hidden = true;
    $('[data-done-title]').textContent = iga(last.buddy || '책콩') + ' 책장에 왔어요!';
    $('[data-done-sub]').textContent = '다음 책 두 권은 ' + korDate(nextDay) + '에 와요.';
    var onServer = (DATA.shelf || []).some(function (s) { return s.slug === last.slug || s.title === last.title; });
    $('[data-guardian]').hidden = onServer;
    var md = markdownFor(last, last.pickedAt, last.doneAt);
    $('[data-github]').href = 'https://github.com/' + DATA.repo + '/new/main/_books?filename=' + encodeURIComponent(last.slug + '.md') + '&value=' + encodeURIComponent(md);
  }

  // ---------- shelf: server books plus ones finished on this iPad but not saved yet ----------
  function renderShelf() {
    var dex = $('[data-dex]');
    $$('li.local, li.placeholder', dex).forEach(function (n) { n.remove(); });
    var server = DATA.shelf || [];
    state.history.forEach(function (h) {
      if (server.some(function (s) { return s.slug === h.slug || s.title === h.title; })) return;
      var li = document.createElement('li'); li.className = 'local';
      li.innerHTML = '<span class="slot"><img class="mini-cover" alt=""><img class="mini-buddy" alt=""></span><span class="no"></span><span class="name"></span>';
      $('.mini-cover', li).src = DATA.base + h.cover;
      if (h.buddy_art) $('.mini-buddy', li).src = DATA.base + h.buddy_art; else $('.mini-buddy', li).remove();
      $('.name', li).textContent = h.title;
      dex.append(li);
    });
    var items = $$('li', dex);
    items.forEach(function (li, i) { var no = $('.no', li); if (no) no.textContent = 'No.' + (i + 1); });
    $('[data-shelf-count]').textContent = items.length ? '모은 책 ' + items.length + '권' : '다 읽은 책이 여기에 모여요';
    for (var k = items.length; k < Math.max(4, items.length + 1); k++) {
      var ph = document.createElement('li'); ph.className = 'placeholder'; ph.setAttribute('aria-hidden', 'true');
      ph.innerHTML = '<span class="slot empty-slot">?</span>';
      dex.append(ph);
    }
  }

  function decide() {
    if (state.pick && !state.doneAt && state.pickBook) { show('read'); renderRead(); return; }
    var last = state.history[state.history.length - 1];
    var waiting = last && (!weekly.proposed || last.week === weekly.proposed || today < weekly.proposed);
    if (waiting) { show('done'); renderDone(); return; }
    if (!books.length) { quest.hidden = true; return; }
    if (state.week !== weekly.proposed) { state = { history: state.history, week: weekly.proposed }; save(); }
    show('choose');
  }

  // ---------- actions ----------
  $$('.pick .stage').forEach(wireBook);

  quest.addEventListener('click', function (e) {
    var t = e.target.closest('button');
    if (!t) return;
    if (t.hasAttribute('data-choose')) {
      var b = bookBy(t.getAttribute('data-choose'));
      if (!b) return;
      state = { history: state.history, week: weekly.proposed, pick: b.slug, pickBook: b, pickedAt: today };
      save();
      var card = t.closest('.pick');
      card.classList.add('is-chosen');
      setTimeout(function () { show('read'); renderRead(); renderShelf(); window.scrollTo({ top: 0, behavior: reduce ? 'auto' : 'smooth' }); }, reduce ? 0 : 450);
    }
    if (t.hasAttribute('data-mark-written')) { state.written = true; save(); syncSteps(); }
    if (t.hasAttribute('data-repick')) {
      state = { history: state.history, week: weekly.proposed }; save();
      location.reload();
    }
    if (t.hasAttribute('data-copy-prompt')) copy($('[data-prompt]').textContent, t);
    if (t.hasAttribute('data-share') && photoBlob) {
      var file = new File([photoBlob], (state.pick || 'report') + '-독후감.jpg', { type: 'image/jpeg' });
      navigator.share({ files: [file], text: $('[data-prompt]').textContent, title: state.pickBook.title + ' 독후감' }).catch(function () { /* closed */ });
    }
    if (t.hasAttribute('data-shelve') && state.photo) {
      var pb = state.pickBook;
      state.history.push({ slug: pb.slug, title: pb.title, author: pb.author, genre: pb.genre, pages: pb.pages, about: pb.about, isbn: pb.isbn,
        cover: pb.cover, buddy: pb.buddy, buddy_art: pb.buddy_art, book_type: pb.book_type, size_mm: pb.size_mm,
        week: state.week, pickedAt: state.pickedAt, doneAt: today });
      state.doneAt = today;
      save();
      show('done'); renderDone(); renderShelf();
      window.scrollTo({ top: 0, behavior: reduce ? 'auto' : 'smooth' });
    }
  });

  $('[data-photo-input]').addEventListener('change', function (e) {
    var f = e.target.files && e.target.files[0];
    if (!f) return;
    shrink(f).then(function (blob) {
      showPhoto(blob);
      return putPhoto(state.pick, blob).catch(function () { /* still usable this visit */ });
    }).then(function () {
      state.photo = true; state.written = true; save(); syncSteps();
    });
    e.target.value = '';
  });

  function copy(text, btn) {
    function done() { var old = btn.textContent; btn.textContent = '복사했어요'; setTimeout(function () { btn.textContent = old; }, 1600); }
    if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(text).then(done, fallback); else fallback();
    function fallback() {
      var ta = document.createElement('textarea'); ta.value = text; ta.setAttribute('readonly', ''); ta.style.position = 'fixed'; ta.style.opacity = '0';
      document.body.append(ta); ta.select(); ta.setSelectionRange(0, text.length);
      try { document.execCommand('copy'); done(); } catch (err) { /* nothing more to try */ }
      ta.remove();
    }
  }

  decide();
  renderShelf();
})();
