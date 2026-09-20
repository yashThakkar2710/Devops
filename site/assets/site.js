/* Dashboard for the networking curriculum.
   Data comes from window.CURRICULUM (assets/curriculum.js), inlined as a
   script because the file:// protocol blocks the Fetch API.
   Progress lives in localStorage. */
(function () {
  "use strict";

  var STORE = "netcurriculum.progress";
  var THEME = "netcurriculum.theme";
  /* Phase ids that have a page built. Add an id here when its page ships. */
  var BUILT = ["0"];
  var phasesEl = document.getElementById("phases");
  var searchEl = document.getElementById("search");
  var emptyEl = document.getElementById("empty");
  var data = window.CURRICULUM || [];

  function loadDone() {
    try {
      var raw = localStorage.getItem(STORE);
      return new Set(raw ? JSON.parse(raw) : []);
    } catch (e) {
      return new Set();
    }
  }
  function saveDone(set) {
    try {
      localStorage.setItem(STORE, JSON.stringify(Array.from(set)));
    } catch (e) {
      /* private mode or blocked storage - the page still works */
    }
  }

  var done = loadDone();

  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }

  function build() {
    data.forEach(function (phase) {
      var det = el("details", "phase");
      det.dataset.phase = phase.id;
      det.open = true;

      var head = el("summary", "phase-head");
      head.appendChild(el("span", "chev", "▶"));
      head.appendChild(el("span", "phase-id", phase.id));
      head.appendChild(el("span", "phase-title", phase.title));

      var meta = el("div", "phase-meta");
      var count = el("span", "phase-count", "");
      var bar = el("div", "bar");
      var fill = el("div", "bar-fill");
      bar.appendChild(fill);

      /* Per-phase pages are built as each phase begins. Listed explicitly
         so an unbuilt phase shows a note instead of linking to a 404. */
      var viz;
      if (BUILT.indexOf(phase.id) !== -1) {
        viz = el("a", "viz-link", "open page");
        viz.href = "phase-" + phase.id.toLowerCase() + ".html";
        viz.addEventListener("click", function (e) { e.stopPropagation(); });
      } else {
        viz = el("span", "viz-soon", "page not built yet");
      }

      meta.appendChild(viz);
      meta.appendChild(count);
      meta.appendChild(bar);
      head.appendChild(meta);
      det.appendChild(head);

      var list = el("div", "modules");
      phase.modules.forEach(function (mod) {
        var row = el("div", "mod");
        row.dataset.search = (mod.id + " " + mod.title).toLowerCase();

        var box = el("input");
        box.type = "checkbox";
        box.id = "m-" + mod.id;
        box.checked = done.has(mod.id);
        box.addEventListener("change", function () {
          if (box.checked) done.add(mod.id);
          else done.delete(mod.id);
          saveDone(done);
          refresh();
        });

        var label = el("label");
        label.htmlFor = box.id;
        label.appendChild(el("span", "mod-id", mod.id));
        label.appendChild(el("span", "mod-title", mod.title));

        row.appendChild(box);
        row.appendChild(label);
        list.appendChild(row);
      });

      det.appendChild(list);
      det._count = count;
      det._fill = fill;
      phasesEl.appendChild(det);
    });
  }

  function refresh() {
    var total = 0;
    var complete = 0;

    data.forEach(function (phase, i) {
      var det = phasesEl.children[i];
      var n = phase.modules.length;
      var c = phase.modules.filter(function (m) { return done.has(m.id); }).length;
      total += n;
      complete += c;
      det._count.textContent = c + "/" + n + " · ~" + phase.hours + "h";
      det._fill.style.width = (n ? (c / n) * 100 : 0) + "%";
      det.dataset.complete = c === n ? "true" : "false";
    });

    var pct = total ? Math.round((complete / total) * 100) : 0;
    document.getElementById("overall-text").textContent =
      complete + " / " + total + " modules · " + pct + "%";
    document.getElementById("overall-bar").style.width = pct + "%";
  }

  function filter(q) {
    q = q.trim().toLowerCase();
    var anyVisible = false;

    Array.prototype.forEach.call(phasesEl.children, function (det) {
      var shown = 0;
      Array.prototype.forEach.call(det.querySelectorAll(".mod"), function (row) {
        var hit = !q || row.dataset.search.indexOf(q) !== -1;
        row.hidden = !hit;
        if (hit) shown++;
      });
      det.hidden = shown === 0;
      if (shown) anyVisible = true;
      if (q) det.open = true;
    });

    emptyEl.hidden = anyVisible;
  }

  searchEl.addEventListener("input", function () { filter(searchEl.value); });
  searchEl.addEventListener("keydown", function (e) {
    if (e.key === "Escape") { searchEl.value = ""; filter(""); }
  });

  var themeBtn = document.getElementById("theme");
  try {
    var saved = localStorage.getItem(THEME);
    if (saved) document.documentElement.dataset.theme = saved;
  } catch (e) { /* ignore */ }
  themeBtn.addEventListener("click", function () {
    var next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    try { localStorage.setItem(THEME, next); } catch (e) { /* ignore */ }
  });

  if (!data.length) {
    phasesEl.appendChild(
      el("p", "empty", "curriculum.js is empty - run: python tools/gen-curriculum.py")
    );
    return;
  }

  build();
  refresh();
})();
