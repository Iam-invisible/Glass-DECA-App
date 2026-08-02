/* Glass — web preview
   A recreation of the iOS app's screens. State is in memory only; nothing is
   stored or sent anywhere, which matches the app's own promise. */

const $ = (s, r = document) => r.querySelector(s);
const el = (t, c, h) => { const n = document.createElement(t); if (c) n.className = c; if (h != null) n.innerHTML = h; return n; };
const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

const CLUSTERS = [
  { id:'marketing',               name:'Marketing',                                  short:'Marketing',        tint:'#2563EB' },
  { id:'finance',                 name:'Finance',                                    short:'Finance',          tint:'#12855C' },
  { id:'hospitality',             name:'Hospitality and Tourism',                    short:'Hospitality',      tint:'#B07407' },
  { id:'businessManagement',      name:'Business Management and Administration',     short:'Business Mgmt',    tint:'#6D4AC4' },
  { id:'entrepreneurship',        name:'Entrepreneurship and Small Business',        short:'Entrepreneurship', tint:'#C8342F' },
  { id:'personalFinancialLiteracy', name:'Personal Financial Literacy',              short:'Personal Finance', tint:'#0E7490' }
];
const clusterOf = id => CLUSTERS.find(c => c.id === id) || CLUSTERS[0];

const ICONS = {
  today:'M12 2a1 1 0 0 1 1 1v1h4a3 3 0 0 1 3 3v11a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3V7a3 3 0 0 1 3-3h4V3a1 1 0 0 1 1-1Zm6 8H6v7a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1v-7Z',
  practice:'M4 5a2 2 0 0 1 2-2h9l5 5v11a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5Zm10 0v4h4l-4-4ZM7 12h10v2H7v-2Zm0 4h7v2H7v-2Z',
  mock:'M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2Zm1 10.6 4 2.3-1 1.7-5-2.9V6h2v6.6Z',
  roleplay:'M12 2a5 5 0 0 1 5 5v3a5 5 0 0 1-10 0V7a5 5 0 0 1 5-5Zm-7 9h2a5 5 0 0 0 10 0h2a7 7 0 0 1-6 6.9V21h-2v-3.1A7 7 0 0 1 5 11Z',
  progress:'M4 20V10h4v10H4Zm6 0V4h4v16h-4Zm6 0v-7h4v7h-4Z',
  settings:'M12 8a4 4 0 1 0 4 4 4 4 0 0 0-4-4Zm9.2 4a7.6 7.6 0 0 0-.1-1.3l2-1.6-2-3.4-2.4 1a7.5 7.5 0 0 0-2.2-1.3L16.1 3h-4l-.4 2.4a7.5 7.5 0 0 0-2.2 1.3l-2.4-1-2 3.4 2 1.6a7.7 7.7 0 0 0 0 2.6l-2 1.6 2 3.4 2.4-1a7.5 7.5 0 0 0 2.2 1.3l.4 2.4h4l.4-2.4a7.5 7.5 0 0 0 2.2-1.3l2.4 1 2-3.4-2-1.6a7.6 7.6 0 0 0 .1-1.3Z',
  flame:'M12 2s5 4.5 5 9a5 5 0 0 1-10 0c0-1.6.6-3 1.3-4.2.4 1 1.2 1.8 2 2 .6-2.5-.3-5-1.3-6.8Z',
  check:'M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2Z',
  target:'M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2Zm0 4a6 6 0 1 1-6 6 6 6 0 0 1 6-6Zm0 3a3 3 0 1 0 3 3 3 3 0 0 0-3-3Z',
  lock:'M12 1a5 5 0 0 1 5 5v3h1a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-9a2 2 0 0 1 2-2h1V6a5 5 0 0 1 5-5Zm3 8V6a3 3 0 0 0-6 0v3h6Z',
  bolt:'M13 2 4 14h6l-1 8 9-12h-6l1-8Z'
};
const svg = (path, cls='') => `<svg class="${cls}" viewBox="0 0 24 24" aria-hidden="true"><path d="${path}"/></svg>`;

/* ---------------- sound ----------------
   The four cues and their volumes are taken from Core/SoundEffects.swift.
   Those levels were matched by A-weighted loudness rather than peak, which is
   why "wrong" sits so much lower than "correct".

   Browsers refuse to play audio before the visitor has interacted with the
   page, so the very first intro may run silent. Every later cue — and the
   Replay intro button, which is itself a click — has sound. */
const SOUND = {
  correct:     { src:'/web/audio/answer-correct.m4a',    volume:1.00 },
  wrong:       { src:'/web/audio/answer-wrong.wav',      volume:0.45 },
  celebration: { src:'/web/audio/badge-celebration.m4a', volume:0.60 },
  intro:       { src:'/web/audio/app-intro.m4a',         volume:1.00 }
};
let soundOn = true;
const players = {};
function play(name) {
  if (!soundOn) return;
  const cue = SOUND[name]; if (!cue) return;
  let a = players[name];
  if (!a) { a = players[name] = new Audio(cue.src); a.volume = cue.volume; }
  a.currentTime = 0;
  a.play().catch(() => {});   // blocked before first interaction; not an error
}
function stopSound(name) { const a = players[name]; if (a) { a.pause(); a.currentTime = 0; } }

/* ---------------- state ---------------- */
const S = {
  screen:'onboarding', tab:'today', dir:1,
  cluster:'marketing', goal:10, reminders:false, reminderTime:'18:30',
  answered:6, streak:12, correct:47, total:63,
  onboard:{ stage:0, done:[] },
  practice:null,
  data:null
};

/* ---------------- chrome ---------------- */
document.querySelectorAll('[data-device]').forEach(b => {
  if (b.tagName !== 'BUTTON') return;
  b.onclick = () => {
    document.querySelectorAll('[data-device]').forEach(x => { if (x.tagName==='BUTTON'){ x.classList.remove('on'); x.setAttribute('aria-pressed','false'); } });
    b.classList.add('on'); b.setAttribute('aria-pressed','true');
    $('#phone').dataset.device = b.dataset.device;
  };
});
document.querySelectorAll('[data-theme]').forEach(b => {
  b.onclick = () => {
    document.querySelectorAll('[data-theme]').forEach(x => { x.classList.remove('on'); x.setAttribute('aria-pressed','false'); });
    b.classList.add('on'); b.setAttribute('aria-pressed','true');
    document.documentElement.dataset.theme = b.dataset.theme;
  };
});
document.documentElement.dataset.theme = 'dark';
$('#sound').onclick = () => {
  soundOn = !soundOn;
  if (!soundOn) Object.keys(players).forEach(stopSound);
  $('#sound').textContent = soundOn ? 'Sound on' : 'Sound off';
  $('#sound').setAttribute('aria-pressed', String(soundOn));
};
$('#restart').onclick = () => {
  stopSound('intro');
  S.onboard = { stage:0, done:[] }; S.practice = null; S.tab = 'today';
  runReveal(() => { S.screen = 'onboarding'; render(); });
};

function dismissGate(withSound) {
  soundOn = withSound;
  $('#sound').textContent = soundOn ? 'Sound on' : 'Sound off';
  $('#sound').setAttribute('aria-pressed', String(soundOn));
  const gate = $('#gate');
  gate.classList.add('gone');
  setTimeout(() => { gate.hidden = true; }, 500);
  runReveal(openApp);
}
$('#begin').onclick      = () => dismissGate(true);
$('#beginQuiet').onclick = () => dismissGate(false);

/* ---------------- the reveal ----------------
   Runs full-screen, before the phone is shown, because it is the app's opening
   and deserves the whole window rather than a 402pt box.

   The technique matches IntroScriptView: a wide round-capped stroke runs along
   the pen's centreline and masks the real letterforms, so what appears is
   always the true Sacramento shape. Tracing the glyph outline would draw the
   letters' edges instead — that is the etched look, not handwriting. */
function buildWordmark() {
  const wrap = el('div','');
  wrap.style.cssText = 'position:absolute;inset:0;display:grid;place-items:center';
  [['--accent',420,-190,-150],['--gold',330,200,190],['--success',280,220,-230]]
    .forEach(([v,size,x,y]) => {
      const b = el('div','blob');
      b.style.cssText = `width:${size}px;height:${size}px;background:var(${v});` +
        `left:calc(50% + ${x}px);top:calc(50% + ${y}px);transform:translate(-50%,-50%)`;
      wrap.appendChild(b);
    });

  // Letterforms are a baked Sacramento outline, produced by the same tool as
  // the pen path and normalised to the same ink box — both report an aspect of
  // 1.1637. An SVG <text> was tried first and came out stretched: getBBox() on
  // text returns the font's layout box, not tight ink bounds.
  const [bx, by, bw, bh] = S.data.glyphBox;
  const SW = bh * 0.095;
  const d = 'M ' + S.data.points
    .map(p => `${(bx + p[0]*bw).toFixed(1)} ${(by + p[1]*bh).toFixed(1)}`).join(' L ');
  // Glass tubing, ported from IntroScriptView's solid(_:) and its three
  // lighting passes. The letter is filled *and* stroked with a round join —
  // stroking the contour alone would give hollow balloon letters (§7.17). Every
  // measurement is expressed against `INF` so it holds at any render size.
  const INF = bh * 0.020;
  const solid = (fill, extra='') =>
    `<path d="${S.data.glyphPath}" fill="${fill}" stroke="${fill}" stroke-width="${INF}"
           stroke-linejoin="round" stroke-linecap="round" ${extra}/>`;

  const box = el('div','word-wrap');
  box.innerHTML = `
    <svg viewBox="${bx - INF*6} ${by - INF*6} ${bw + INF*12} ${bh + INF*12}"
         role="img" aria-label="Glass">
      <defs>
        <mask id="penmask" maskUnits="userSpaceOnUse"
              x="${bx-SW}" y="${by-SW}" width="${bw+SW*2}" height="${bh+SW*2}">
          <path id="pen" d="${d}" stroke-width="${SW}" fill="none"
                stroke="#fff" stroke-linecap="round" stroke-linejoin="round"/>
        </mask>

        <!-- Clips the shading and highlight to the inside of the letter, the
             way .mask(solid(Color.black)) does in the app. -->
        <mask id="inside" maskUnits="userSpaceOnUse"
              x="${bx-INF*4}" y="${by-INF*4}" width="${bw+INF*8}" height="${bh+INF*8}">
          ${solid('#fff')}
        </mask>

        <linearGradient id="glassfill" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0"   stop-color="var(--accent)"/>
          <stop offset=".55" stop-color="var(--accent)" stop-opacity=".68"/>
          <stop offset="1"   stop-color="var(--text-primary)" stop-opacity=".85"/>
        </linearGradient>
        <linearGradient id="sweepgrad" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0"   stop-color="#fff" stop-opacity="0"/>
          <stop offset=".5"  stop-color="#fff" stop-opacity=".9"/>
          <stop offset="1"   stop-color="#fff" stop-opacity="0"/>
        </linearGradient>

        <filter id="fHalo"  x="-40%" y="-40%" width="180%" height="180%">
          <feGaussianBlur stdDeviation="${INF*2.2}"/></filter>
        <filter id="fShade" x="-30%" y="-30%" width="160%" height="160%">
          <feGaussianBlur stdDeviation="${INF*0.48}"/></filter>
        <filter id="fHi"    x="-30%" y="-30%" width="160%" height="160%">
          <feGaussianBlur stdDeviation="${INF*0.36}"/></filter>
        <filter id="fRim"   x="-30%" y="-30%" width="160%" height="160%">
          <feGaussianBlur stdDeviation="${INF*0.15}"/></filter>
        <filter id="fSweep" x="-30%" y="-30%" width="160%" height="160%">
          <feGaussianBlur stdDeviation="${INF*0.6}"/></filter>
      </defs>

      <!-- What has been written so far. -->
      <g id="written" mask="url(#penmask)">
        ${solid('url(#glassfill)')}
        <g mask="url(#inside)">
          <path d="${S.data.glyphPath}" fill="none" stroke="#fff" stroke-opacity=".45"
                stroke-width="${INF*0.5}" stroke-linejoin="round" filter="url(#fRim)"/>
        </g>
      </g>

      <!-- The finished word, flooding in on the peak. Identical geometry, so
           the crossfade is invisible; it exists so the lighting passes and
           anything the pen mask missed arrive together. -->
      <g id="finished" opacity="0">
        <g id="halo" filter="url(#fHalo)" opacity=".38">${solid('var(--accent)')}</g>
        ${solid('url(#glassfill)')}
        <g mask="url(#inside)">
          <!-- Shading hugging the lower-right: a blurred contour pass pushed
               down and clipped inside, which is what gives a flat shape the
               roundness of a rod. -->
          <path d="${S.data.glyphPath}" fill="none" stroke="var(--accent)" stroke-opacity=".95"
                stroke-width="${INF*1.9}" stroke-linejoin="round" filter="url(#fShade)"
                transform="translate(${INF*0.5} ${INF*0.75})" opacity=".95"/>
          <!-- The matching highlight along the upper-left: light running down
               the top of the tube. -->
          <path d="${S.data.glyphPath}" fill="none" stroke="#fff" stroke-opacity=".85"
                stroke-width="${INF*0.75}" stroke-linejoin="round" filter="url(#fHi)"
                transform="translate(${-INF*0.42} ${-INF*0.62})" opacity=".62"/>
          <!-- Bright rim where the glass turns away at the edge. -->
          <path d="${S.data.glyphPath}" fill="none" stroke="#fff" stroke-opacity=".5"
                stroke-width="${INF*0.5}" stroke-linejoin="round" filter="url(#fRim)"
                opacity=".3"/>
          <rect id="sweep" x="${bx - bw}" y="${by - INF*4}"
                width="${bw*0.45}" height="${bh + INF*8}"
                fill="url(#sweepgrad)" filter="url(#fSweep)"/>
        </g>
      </g>
    </svg>`;
  wrap.appendChild(box);
  return wrap;
}

let introRunning = false;
function runReveal(onDone) {
  if (introRunning) return;
  introRunning = true;
  const stage = $('#fullIntro');
  stage.hidden = false;
  stage.classList.remove('gone');
  stage.innerHTML = '';
  stage.appendChild(buildWordmark());

  const done = () => {
    stage.classList.add('gone');
    setTimeout(() => { stage.hidden = true; stage.innerHTML = ''; introRunning = false; }, 600);
    onDone && onDone();
  };
  stage.onclick = done;   // skippable, like the app

  const pen = $('#pen', stage);
  const len = pen.getTotalLength();
  pen.style.strokeDasharray = len;
  play('intro');

  if (reduceMotion) {
    pen.style.strokeDashoffset = 0;
    const fin = $('#finished', stage); if (fin) fin.style.opacity = '1';
    setTimeout(done, 1400);
    return;
  }
  pen.style.strokeDashoffset = len;
  pen.getBoundingClientRect();
  // 2.12s of writing on a gentle symmetric ease, landing on the audio's peak —
  // the same numbers as the app.
  pen.style.transition = 'stroke-dashoffset 2120ms cubic-bezier(.40,0,.40,1)';
  pen.style.strokeDashoffset = 0;

  setTimeout(() => {
    // The reveal: glass floods in on the audio's peak, the written layer hands
    // over to it, and the sweep travels across 0.22s later — the app's beats.
    const fin = $('#finished', stage), writ = $('#written', stage);
    if (fin) { fin.style.transition = 'opacity 650ms ease-out'; fin.style.opacity = '1'; }
    if (writ) { writ.style.transition = 'opacity 500ms ease-out'; writ.style.opacity = '0'; }
    setTimeout(() => {
      const sw = $('#sweep', stage);
      if (sw) {
        sw.style.transition = 'transform 1000ms cubic-bezier(.4,0,.2,1)';
        sw.style.transform = `translateX(${bw * 2.1}px)`;
      }
    }, 220);
    setTimeout(done, 1700);
  }, 2300);
}

function openApp() {
  document.body.classList.remove('gated');
  S.screen = 'onboarding';
  render();
}

/* ---------------- onboarding ----------------
   One continuous surface: each question opens, is answered, then collapses to
   a line that stays visible. The column is the progress indicator. */
const STAGES = [
  { key:'cluster',   label:'Your event' },
  { key:'goal',      label:'Daily goal' },
  { key:'reminders', label:'Reminder' },
  { key:'coaching',  label:'Coaching' }
];

function renderOnboarding() {
  const vp = $('#viewport'); vp.classList.remove('flush'); vp.innerHTML = '';
  $('#tabbar').hidden = true;
  const col = el('div','stack');

  col.appendChild(el('div','header-block',
    `<div class="t-large">Glass</div>
     <div class="t-foot dim">Four quick choices and you're studying. Everything here is editable
     later, and none of it leaves your phone.</div>`));

  STAGES.forEach((st, i) => {
    if (S.onboard.stage === i) col.appendChild(openStage(st, i));
    else if (S.onboard.done.includes(i)) col.appendChild(summaryRow(st, i));
  });

  if (S.onboard.done.length === STAGES.length) {
    const b = el('button','btn','Start studying');
    b.onclick = () => { S.screen='app'; render(); };
    col.appendChild(b);
  } else {
    const skip = el('button','btn secondary','Skip setup — use the defaults');
    skip.style.fontSize = '13px';
    skip.onclick = () => { S.screen='app'; render(); };
    col.appendChild(skip);
  }
  vp.appendChild(col);
}

function summaryRow(st, i) {
  const answers = {
    cluster: clusterOf(S.cluster).name,
    goal: `${S.goal} question${S.goal===1?'':'s'} a day`,
    reminders: S.reminders ? `Every day at ${S.reminderTime}` : 'No reminders',
    coaching: 'Written explanations'
  };
  const b = el('button','summary',
    `${svg(ICONS.check,'tick')}
     <span class="grow"><span class="t-cap dimmer" style="display:block">${st.label}</span>
     <span class="t-callout" style="font-weight:500">${answers[st.key]}</span></span>
     <span class="t-capb" style="color:var(--accent)">Change</span>`);
  b.onclick = () => { S.onboard.stage = i; render(); };
  return b;
}

function openStage(st, i) {
  const c = el('div','card enter');
  c.style.display='flex'; c.style.flexDirection='column'; c.style.gap='13px';
  c.appendChild(el('div','eyebrow',
    `<span class="dot"></span> Step ${i+1} of ${STAGES.length}`));

  const head = (t, d) => el('div','', `<div class="t-title">${t}</div>
      <div class="t-foot dim" style="margin-top:6px">${d}</div>`);

  if (st.key === 'cluster') {
    c.appendChild(head('Which event are you preparing for?',
      'This decides which questions, roleplays and indicators you see first. You can switch any time.'));
    const list = el('div','stack'); list.style.gap='8px';
    CLUSTERS.forEach(cl => {
      const o = el('button', 'opt' + (S.cluster===cl.id ? ' on' : ''),
        `<span class="mark"></span><span class="grow">${cl.name}</span>`);
      o.style.setProperty('--accent', cl.tint);
      o.onclick = () => { S.cluster = cl.id; render(); };
      list.appendChild(o);
    });
    c.appendChild(list);
  }

  if (st.key === 'goal') {
    c.appendChild(head('How many questions a day?',
      'Small and daily beats heroic and rare. Ten takes about five minutes.'));
    c.appendChild(el('div','', `<div style="text-align:center;font-size:46px;font-weight:600;color:var(--accent)" class="num">${S.goal}</div>
      <div class="t-cap dim" style="text-align:center">a day</div>`));
    const chips = el('div','chips');
    [5,10,20,30].forEach(v => {
      const b = el('button','chip' + (S.goal===v?' on':''), v);
      b.onclick = () => { S.goal = v; render(); };
      chips.appendChild(b);
    });
    c.appendChild(chips);
  }

  if (st.key === 'reminders') {
    c.appendChild(head('Want a nudge?',
      "One quiet notification, local to this phone. If you've already hit your goal that day, it stays quiet."));
    const t = el('button','opt' + (S.reminders?' on':''),
      `<span class="mark"></span><span class="grow">Remind me daily</span>`);
    t.onclick = () => { S.reminders = !S.reminders; render(); };
    c.appendChild(t);
    if (S.reminders) {
      const chips = el('div','chips');
      ['16:00','17:30','18:30','20:00'].forEach(v => {
        const b = el('button','chip' + (S.reminderTime===v?' on':''), v);
        b.onclick = () => { S.reminderTime = v; render(); };
        chips.appendChild(b);
      });
      c.appendChild(el('div','t-cap dim','What time?'));
      c.appendChild(chips);
    }
  }

  if (st.key === 'coaching') {
    c.appendChild(head('AI coaching',
      'Explanations generated on the phone itself. Never a server — and never the source of a correct answer, which always comes from the question bank.'));
    c.appendChild(el('div','card',
      `<div class="t-body" style="font-weight:500">This Device Does Not Support AI Feedback</div>
       <div class="t-foot dim" style="margin-top:4px">Practice, mock exams, roleplays and progress all work offline as normal, with written explanations and a manual rubric.</div>`));
  }

  const next = el('button','btn', st.key==='coaching' ? 'Start studying'
                 : (st.key==='reminders' && !S.reminders ? 'Not now' : 'Continue'));
  next.onclick = () => {
    if (!S.onboard.done.includes(i)) S.onboard.done.push(i);
    const nx = STAGES.findIndex((_, k) => !S.onboard.done.includes(k));
    if (nx === -1) { S.screen='app'; } else { S.onboard.stage = nx; }
    render();
  };
  c.appendChild(next);
  return c;
}

/* ---------------- app shell ---------------- */
const TABS = [
  ['today','Today',ICONS.today], ['practice','Practice',ICONS.practice],
  ['mock','Mock',ICONS.mock], ['roleplay','Roleplay',ICONS.roleplay],
  ['progress','Progress',ICONS.progress], ['settings','Settings',ICONS.settings]
];

function renderTabBar() {
  const bar = $('#tabbar'); bar.hidden = false; bar.innerHTML = '';
  TABS.forEach(([id,label,icon]) => {
    const b = el('button', S.tab===id?'on':'', `${svg(icon)}<span>${label}</span>`);
    b.setAttribute('aria-current', S.tab===id ? 'page' : 'false');
    b.onclick = () => {
      if (S.tab === id) return;
      // +1 moving right along the bar, -1 left — set before the tab changes so
      // the transition knows which way to travel, same as RootView.
      S.dir = TABS.findIndex(t => t[0] === id) > TABS.findIndex(t => t[0] === S.tab) ? 1 : -1;
      S.tab = id; S.practice = null; render();
    };
    bar.appendChild(b);
  });
}

function header(title, eyebrow, tint, subtitle) {
  return el('div','header-block',
    `${eyebrow ? `<div class="eyebrow"><span class="dot" style="background:${tint||'var(--accent)'}"></span>${eyebrow}</div>` : ''}
     <div class="t-large">${title}</div>
     ${subtitle ? `<div class="t-foot dim">${subtitle}</div>` : ''}`);
}

function ring(fraction, size, color) {
  const r = size/2 - 6, c = 2*Math.PI*r;
  return `<svg class="ring" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
    <circle cx="${size/2}" cy="${size/2}" r="${r}" stroke="var(--card-sunken)" stroke-width="11"/>
    <circle cx="${size/2}" cy="${size/2}" r="${r}" stroke="${color}" stroke-width="11"
      stroke-dasharray="${c}" stroke-dashoffset="${c*(1-fraction)}"/></svg>`;
}

function renderApp() {
  const vp = $('#viewport'); vp.classList.remove('flush'); vp.innerHTML = '';
  renderTabBar();
  const col = el('div','section');
  ({ today:tabToday, practice:tabPractice, mock:tabMock,
     roleplay:tabRoleplay, progress:tabProgress, settings:tabSettings }[S.tab])(col);

  // Sections rise in sequence — 55ms apart, exactly as appearIn(_:) does.
  if (!reduceMotion) {
    [...col.children].forEach((child, i) => {
      child.classList.add('ap');
      child.style.animationDelay = (i * 55) + 'ms';
    });
    // …and the whole page travels in the direction the tab moved.
    col.classList.add('page-in');
    col.style.setProperty('--dir', S.dir);
  }
  vp.appendChild(col);
  vp.scrollTop = 0;
}

function tabToday(col) {
  const cl = clusterOf(S.cluster);
  const h = new Date().getHours();
  const greet = h < 5 ? 'Still up' : h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
  const left = Math.max(0, S.goal - S.answered);
  col.appendChild(header(greet, cl.name, cl.tint,
    left === 0 ? `Goal met. ${S.streak} days running.`
               : `${left} more to keep a ${S.streak}-day streak alive.`));

  const goal = el('div','card');
  goal.innerHTML = `<div class="row" style="gap:18px">
      <div style="position:relative;flex:none">${ring(S.answered/S.goal, 96, 'var(--accent)')}
        <div style="position:absolute;inset:0;display:grid;place-items:center">
          <div style="text-align:center"><div class="num" style="font-size:26px;font-weight:700">${S.answered}</div>
          <div class="t-cap dimmer">of ${S.goal}</div></div></div></div>
      <div class="grow"><div class="t-headline">Today's goal</div>
        <div class="t-foot dim" style="margin:4px 0 10px">${left} question${left===1?'':'s'} to go.</div>
        <div class="row" style="gap:7px">${svg(ICONS.flame,'tick')}<span class="t-capb" style="color:var(--gold)">${S.streak}-day streak</span></div>
      </div></div>`;
  const go = el('button','btn','Practice now'); go.style.marginTop='14px';
  go.onclick = () => { S.tab='practice'; startPractice(); };
  goal.appendChild(go);
  col.appendChild(goal);

  const acts = el('div','stack');
  [['Quick Think', 'Sixty seconds, one scenario, one answer.', ICONS.bolt],
   ['Mistake notebook', `${S.total - S.correct} questions to revisit.`, ICONS.practice],
   ['Mock exam', 'Full length, timed like the real thing.', ICONS.mock]
  ].forEach(([t,d,ic]) => {
    const c = el('div','card');
    c.innerHTML = `<div class="row">${svg(ic,'tick')}<div class="grow">
      <div class="t-callout" style="font-weight:500">${t}</div>
      <div class="t-cap dim">${d}</div></div></div>`;
    c.querySelector('.tick').style.fill = 'var(--accent)';
    acts.appendChild(c);
  });
  col.appendChild(acts);
}

function tabPractice(col) {
  const cl = clusterOf(S.cluster);
  if (S.practice) return practiceRunner(col);
  const pool = S.data.questions.filter(q => q.cluster === S.cluster);
  col.appendChild(header('Practice', cl.name, cl.tint, `${pool.length} questions in your bank.`));

  const c = el('div','card');
  c.innerHTML = `<div class="t-headline">Quick session</div>
    <div class="t-foot dim" style="margin:5px 0 12px">Ten questions drawn from your cluster, weighted toward what you've missed.</div>`;
  const b = el('button','btn','Start practice');
  b.onclick = startPractice;
  c.appendChild(b);
  col.appendChild(c);

  const browse = el('div','stack');
  browse.appendChild(el('div','t-headline','Browse'));
  ['By cluster','By topic','Performance indicators','Custom practice'].forEach(t => {
    const r = el('div','card'); r.innerHTML = `<div class="spread"><span class="t-callout">${t}</span>
      <span class="dimmer">›</span></div>`;
    browse.appendChild(r);
  });
  col.appendChild(browse);
}

function startPractice() {
  const pool = S.data.questions.filter(q => q.cluster === S.cluster);
  S.practice = { pool, i:0, picked:null, right:0 };
  S.tab = 'practice'; render();
}

function practiceRunner(col) {
  const p = S.practice, q = p.pool[p.i];
  if (!q) {
    play('celebration');
    col.appendChild(header('Session complete', 'Practice', 'var(--accent)',
      `${p.right} of ${p.pool.length} correct.`));
    const b = el('button','btn','Back to Practice');
    b.onclick = () => { S.practice = null; render(); };
    col.appendChild(b);
    return;
  }
  col.appendChild(el('div','', `<div class="spread">
      <span class="t-capb dimmer">Question ${p.i+1} of ${p.pool.length}</span>
      <span class="pill">${clusterOf(q.cluster).short}</span></div>
      <div class="bar" style="margin-top:9px"><i style="width:${(p.i/p.pool.length)*100}%"></i></div>`));

  const card = el('div','card');
  card.appendChild(el('div','t-question', q.text));
  const opts = el('div','stack'); opts.style.cssText = 'gap:8px;margin-top:14px';
  q.choices.forEach((choice, idx) => {
    let cls = 'opt';
    if (p.picked !== null) {
      if (idx === q.correct) cls += ' correct';
      else if (idx === p.picked) cls += ' wrong';
    }
    const o = el('button', cls,
      `<span class="letter">${'ABCD'[idx]}</span><span class="mark"></span><span class="grow">${choice}</span>`);
    if (p.picked !== null) o.disabled = true;
    else o.onclick = () => {
      p.picked = idx;
      const right = idx === q.correct;
      if (right) p.right++;
      play(right ? 'correct' : 'wrong');
      render();
    };
    opts.appendChild(o);
  });
  card.appendChild(opts);
  col.appendChild(card);

  if (p.picked !== null) {
    const right = p.picked === q.correct;
    const fb = el('div','card enter');
    fb.style.borderColor = right ? 'var(--success)' : 'var(--danger)';
    fb.innerHTML = `<div class="t-headline" style="color:${right?'var(--success)':'var(--danger)'}">
        ${right ? 'Correct' : 'Not quite'}</div>
      <div class="t-foot dim" style="margin-top:7px;line-height:1.55">${q.explanation}</div>`;
    col.appendChild(fb);
    const n = el('button','btn', p.i === p.pool.length-1 ? 'Finish' : 'Next question');
    n.onclick = () => { p.i++; p.picked = null; render(); };
    col.appendChild(n);
  }
}

function tabMock(col) {
  col.appendChild(header('Mock Exams','3 attempts','var(--accent)',
    'Full-length practice under real time pressure.'));
  const c = el('div','card');
  c.innerHTML = `<div class="t-headline">New exam</div>
    <div class="t-foot dim" style="margin:5px 0 12px">Set it up the way your competition runs.</div>
    <div class="spread"><span class="t-callout">Questions</span><span class="t-callout num" style="color:var(--accent);font-weight:600">50</span></div>`;
  const chips = el('div','chips'); chips.style.marginTop='9px';
  [10,25,50,100].forEach(v => chips.appendChild(el('button','chip'+(v===50?' on':''), v)));
  c.appendChild(chips);
  const b = el('button','btn','Start mock exam'); b.style.marginTop='14px';
  c.appendChild(b);
  col.appendChild(c);

  const hist = el('div','stack');
  hist.appendChild(el('div','t-headline','Score history'));
  [['Marketing','82','Apr 12'],['Marketing','74','Apr 5'],['Finance','68','Mar 28']].forEach(([c2,s,d]) => {
    const tint = +s >= 80 ? 'var(--success)' : +s >= 70 ? 'var(--gold)' : 'var(--danger)';
    const r = el('div','card');
    r.innerHTML = `<div class="row"><div style="width:46px;height:46px;border-radius:99px;display:grid;place-items:center;background:color-mix(in srgb,${tint} 14%,transparent);color:${tint};font-weight:700" class="num">${s}</div>
      <div class="grow"><div class="t-callout" style="font-weight:500">${c2}</div>
      <div class="t-cap dim">${d} · 50 questions</div></div></div>`;
    hist.appendChild(r);
  });
  col.appendChild(hist);
}

function tabRoleplay(col) {
  const cl = clusterOf(S.cluster);
  col.appendChild(header('Roleplay', cl.name, cl.tint,
    'Judge-style scenarios with prep timers and a rubric.'));
  const qt = el('div','card');
  qt.innerHTML = `<div class="row">${svg(ICONS.bolt,'tick')}<div class="grow">
    <div class="t-headline">Quick Think</div>
    <div class="t-foot dim" style="margin-top:3px">One scenario, sixty seconds, one answer.</div></div></div>`;
  qt.querySelector('.tick').style.fill = 'var(--gold)';
  col.appendChild(qt);

  const list = el('div','stack');
  list.appendChild(el('div','t-headline','Scenarios'));
  [['Retail promotion plan','You are a marketing associate advising a store manager on a slow season.','10 min'],
   ['Customer complaint recovery','A regular guest has had two poor experiences in a row.','10 min'],
   ['New product pricing','The owner wants your recommendation before a spring launch.','10 min']
  ].forEach(([t,d,m]) => {
    const c = el('div','card');
    c.innerHTML = `<div class="t-callout" style="font-weight:500">${t}</div>
      <div class="t-foot dim" style="margin:4px 0 9px">${d}</div>
      <span class="pill">${m} prep</span>`;
    list.appendChild(c);
  });
  col.appendChild(list);
}

function tabProgress(col) {
  const cl = clusterOf(S.cluster);
  const pct = Math.round((S.correct/S.total)*100);
  col.appendChild(header('Progress', cl.name, cl.tint,
    "Everything you've answered, and what it says about exam day."));

  const stats = el('div','card');
  stats.innerHTML = `<div class="row" style="gap:0">
    ${[[pct+'%','Accuracy'],[S.total,'Answered'],[S.streak,'Day streak']].map(([v,l]) =>
      `<div class="grow" style="text-align:center">
        <div class="num" style="font-size:26px;font-weight:700;color:var(--accent)">${v}</div>
        <div class="t-cap dim">${l}</div></div>`).join('')}</div>`;
  col.appendChild(stats);

  const acc = el('div','card');
  acc.innerHTML = `<div class="t-headline" style="margin-bottom:12px">Accuracy by cluster</div>`;
  [['Marketing',82],['Finance',71],['Hospitality',64],['Business Mgmt',58]].forEach(([n,v]) => {
    const tint = v >= 80 ? 'var(--success)' : v >= 65 ? 'var(--gold)' : 'var(--danger)';
    acc.innerHTML += `<div style="margin-bottom:11px">
      <div class="spread" style="margin-bottom:5px"><span class="t-foot">${n}</span>
      <span class="t-capb num" style="color:${tint}">${v}%</span></div>
      <div class="bar"><i style="width:${v}%;background:${tint}"></i></div></div>`;
  });
  col.appendChild(acc);
}

function tabSettings(col) {
  col.appendChild(header('Settings','On this phone only','var(--accent)',
    'No account, no sync, no tracking.'));
  const section = (title, rows) => {
    const s = el('div','stack'); s.style.gap='9px';
    s.appendChild(el('div','t-capb dimmer', title.toUpperCase()));
    const c = el('div','card'); c.style.cssText='display:flex;flex-direction:column;gap:13px';
    rows.forEach((r,i) => {
      if (i) c.appendChild(el('div','divider'));
      c.appendChild(el('div','', `<div class="spread"><div><div class="t-callout">${r[0]}</div>
        ${r[1]?`<div class="t-cap dim" style="margin-top:2px">${r[1]}</div>`:''}</div>
        <span class="t-callout dim">${r[2]||''}</span></div>`));
    });
    s.appendChild(c); return s;
  };
  col.appendChild(section('Study', [
    ['DECA exam / cluster', clusterOf(S.cluster).name, '›'],
    ['Daily question goal', `${S.goal} questions per day`, '›']]));
  col.appendChild(section('Reminders', [
    ['Daily reminder','Local notification only — never sent over the internet.', S.reminders?'On':'Off']]));
  col.appendChild(section('AI feedback', [
    ['This Device Does Not Support AI Feedback','Apple Foundation Models · on device','']]));
  col.appendChild(section('Appearance', [
    ['Theme','','System'], ['Intro style','"glass" written out in script.','Handwritten']]));
  col.appendChild(section('About', [
    ['No account, no tracking','Your questions, answers and statistics never leave this phone.',''],
    ['Sample content','Original practice material — not official DECA Ontario content.',''],
    ['Version','','1.0']]));
}

/* ---------------- boot ---------------- */
function render() {
  if (S.screen === 'onboarding') return renderOnboarding();
  renderApp();
}

fetch('/web/data.json')
  .then(r => r.json())
  .then(d => { S.data = d; render(); })   // renders behind the gate, ready for the hand-off
  .catch(() => {
    $('#viewport').innerHTML =
      '<div class="card"><div class="t-headline">Could not load content</div>' +
      '<div class="t-foot dim" style="margin-top:6px">data.json failed to fetch.</div></div>';
  });
