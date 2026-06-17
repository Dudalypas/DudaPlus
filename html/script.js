let listings = [];
let nextRefresh = 0;
let currentDetail = null;
let activeTab = 'Visi';

const TAB_RARITY = {
  Paprasti: 1,
  Neįprasti: 2,
  Reti: 3,
  Epic: 4,
  Legendary: 5
};

const resourceName = (typeof GetParentResourceName === 'function')
    ? GetParentResourceName()
    : 'dudaplus';

function post(action, data) {
    fetch(`https://${resourceName}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {})
    });
}

function setRowVisible(rowId, visible) {
  const row = document.getElementById(rowId);
  if (row) row.style.display = visible ? '' : 'none';
}

function formatKm(km) {
  if (km === null || km === undefined) return '';
  const n = Number(km);
  if (!Number.isFinite(n)) return '';
  return n.toLocaleString('lt-LT') + ' km';
}

function rarityLabel(r) {
  const map = {
    1: 'Common',
    2: 'Uncommon',
    3: 'Rare',
    4: 'Epic',
    5: 'Legendary'
  };
  return map[Number(r)] || '';
}

function conditionFromWear(wear) {
  const w = Number(wear);
  if (!Number.isFinite(w)) return '';
  if (w <= 0.05) return 'Ideal';
  if (w <= 0.25) return 'Good';
  if (w <= 0.55) return 'Average';
  if (w <= 0.80) return 'Worn';
  return 'Critical';
}

// If you don’t send labels from server, you can map ids here.
const damageLabels = {
  broken_turbo: 'Broken turbo',
  worn_tires: 'Worn tires',
  bent_suspension: 'Bent suspension arm',
  warped_rotors: 'Warped rotors',
  bad_alignment: 'Bad alignment'
};

function setText(id, text) {
  const el = document.getElementById(id);
  if (el) el.textContent = text;
}

function getEl(id) {
  return document.getElementById(id);
}

function getFilteredListings() {
  if (!Array.isArray(listings) || listings.length === 0) return [];

  if (activeTab === 'Visi') {
    return listings.slice(0, 30);
  }

  const rarity = TAB_RARITY[activeTab];
  if (!rarity) return [];

  return listings
    .filter((l) => Number(l && l.rarity) === rarity)
    .slice(0, 6);
}

function renderTabs() {
  const tabs = document.querySelectorAll('#marketTabs li');
  tabs.forEach((tab) => {
    tab.classList.toggle('active', tab.dataset.tab === activeTab);
  });
}

function setupTabs() {
  const tabs = document.querySelectorAll('#marketTabs li');
  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      const nextTab = tab.dataset.tab;
      if (!nextTab || nextTab === activeTab) return;
      activeTab = nextTab;
      renderTabs();
      renderGrid();
    });
  });
  renderTabs();
}

function renderDetailCondition(listing) {
  const vcond = listing && listing.vcondition ? listing.vcondition : null;

  // rarity
  const rLabel = rarityLabel(listing && listing.rarity);
  setText('detailRarity', rLabel);
  setRowVisible('rowRarity', !!rLabel);

  // mileage (no ?? for max compatibility)
  const kmVal = (listing && listing.mileageKm != null)
    ? listing.mileageKm
    : (vcond && vcond.mileageKm != null ? vcond.mileageKm : null);

  const kmText = formatKm(kmVal);
  setText('detailMileage', kmText);
  setRowVisible('rowMileage', !!kmText);

  // condition (wear)
  const percentVal = (listing && listing.conditionPercent != null)
    ? Number(listing.conditionPercent)
    : (vcond && vcond.conditionPercent != null)
        ? Number(vcond.conditionPercent)
        : (vcond && vcond.wear != null ? Number(vcond.wear) : null);

  let condLabel = (listing && listing.conditionLabel) || (vcond && vcond.conditionLabel) || null;
  if (!condLabel && percentVal != null) {
    condLabel = conditionFromWear(percentVal);
  }

  let condText = condLabel || '';
  if (percentVal != null && Number.isFinite(percentVal)) {
    const pct = Math.round(percentVal * 100);
    condText = condText ? `${condText} (${pct}%)` : `${pct}%`;
  }
  setText('detailCondition', condText);
  setRowVisible('rowCondition', !!condText);

  // damages
  const ul = getEl('detailDamages');
  if (ul) ul.innerHTML = '';

  const damages = (vcond && Array.isArray(vcond.damages)) ? vcond.damages : [];

  if (ul && damages.length > 0) {
    for (const d of damages) {
      const li = document.createElement('li');
      const label = (d && d.label) || damageLabels[d && d.id] || (d && d.id) || 'Unknown';
      const sevNum = d && d.sev != null ? Number(d.sev) : null;
      const sev = (sevNum != null && Number.isFinite(sevNum)) ? ` (${Math.round(sevNum * 100)}%)` : '';
      li.textContent = label + sev;
      ul.appendChild(li);
    }
    setRowVisible('rowDamages', true);
  } else {
    setRowVisible('rowDamages', false);
  }

  const summary = (listing && listing.damageSummary) || (vcond && vcond.damageSummary) || null;
  if (summary) {
    const count = Number(summary.count) || 0;
    const avg = summary.avgSeverity != null ? Math.round(Number(summary.avgSeverity) * 100) : null;
    const text = count > 0
      ? `${count} vnt${avg != null ? ` (avg ${avg}%)` : ''}`
      : 'Nėra';
    setText('detailDamageSummary', text);
    setRowVisible('rowDamageSummary', true);
  } else {
    setRowVisible('rowDamageSummary', false);
  }
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'open') {
        document.getElementById('app').style.display = 'block';
    }

    if (data.action === 'close') {
        document.getElementById('app').style.display = 'none';
        closeDetail && closeDetail();   // if you use the detail modal
    }

    if (data.action === 'setListings') {
        listings = data.listings || [];
        nextRefresh = data.nextRefresh || 0;
        renderGrid();
    }
});

function renderGrid() {
    const grid = document.getElementById('grid');
    if (!grid) return;
    grid.innerHTML = '';

    if (!listings || !listings.length) {
        grid.innerHTML = '<p>Siuo metu pasiulymu nera.</p>';
        return;
    }

    const subset = getFilteredListings();

    if (!subset.length) {
        grid.innerHTML = '<p>Nėra skelbimų pasirinktai kategorijai.</p>';
        return;
    }

    subset.forEach((l) => {
        const card = document.createElement('div');
        card.className = 'market-card';
        card.onclick = () => openDetail(l);   // if you use the detail modal

        // IMAGE
        const imgWrap = document.createElement('div');
        imgWrap.className = 'market-card-img';

        const img = document.createElement('img');
        img.alt = l.label;
        img.onerror = () => {
            if (!img.dataset.fallback) {
                img.dataset.fallback = '1';
                img.src = 'img/default.png';
            }
        };
        img.src = l.image || `img/${l.model}.png`;

        imgWrap.appendChild(img);
        card.appendChild(imgWrap);

        // BOTTOM BAND
        const bottom = document.createElement('div');
        bottom.className = 'market-card-bottom';

        const info = document.createElement('div');
        info.className = 'market-card-info';

        const title = document.createElement('div');
        title.className = 'market-card-title';
        title.textContent = l.label;

        const meta = document.createElement('div');
        meta.className = 'market-card-meta';

        info.appendChild(title);
        info.appendChild(meta);

        const priceWrap = document.createElement('div');
        priceWrap.className = 'market-card-price-wrap';

        const price = document.createElement('div');
        price.className = 'market-card-price';
        price.textContent = `${Number(l.price || 0).toLocaleString('lt-LT')} €`;

        priceWrap.appendChild(price);

        bottom.appendChild(info);
        bottom.appendChild(priceWrap);

        card.appendChild(bottom);
        grid.appendChild(card);
    });
}

function buyVehicle(listingId) {
    fetch(`https://${resourceName}/buyVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ listingId }),
    }).then(() => {});
}

document.getElementById('closeBtn').addEventListener('click', () => {
    fetch(`https://${resourceName}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    }).then(() => {
        document.getElementById('app').style.display = 'none';
    }).catch((err) => {
        console.log('NUI fetch error:', err);
    });
});

// NUI callbacks mapping
window.addEventListener('load', () => {
    setupTabs();
    setInterval(updateTimer, 1000);
});

function updateTimer() {
    if (!nextRefresh) return;
    const el = document.getElementById('timer');
    const now = Math.floor(Date.now() / 1000);
    let remaining = nextRefresh - now;
    if (remaining < 0) remaining = 0;

    const mins = Math.floor(remaining / 60);
    const secs = remaining % 60;
    el.textContent = `Refresh in ${mins}m ${secs}s`;
}

function openDetail(listing) {
    currentDetail = listing;

    const overlay = document.getElementById('detailOverlay');
    const card    = document.getElementById('detailCard');

    document.getElementById('detailTitle').textContent = listing.label;
    document.getElementById('detailPrice').textContent = `${listing.price.toLocaleString()} €`;
    document.getElementById('detailLocation').textContent = listing.location || '-';  // NEW: location field
    document.getElementById('detailColor').textContent = listing.color ? listing.color.label : '-'; // NEW: color field
    
    // specs on the left
    document.getElementById('detailClass').textContent  = listing.class || '-';
    const img = document.getElementById('detailImage');
    img.onerror = () => {
        if (!img.dataset.fallback) {
            img.dataset.fallback = '1';
            img.src = 'img/default.png';
        }
    };
    img.dataset.fallback = '';
    img.src = listing.image || `img/${listing.model}.png`;
         
    renderDetailCondition(listing);

    overlay.style.display = 'block';
    card.style.display = 'block';
}


function closeDetail() {
    document.getElementById('detailOverlay').style.display = 'none';
    document.getElementById('detailCard').style.display = 'none';
    currentDetail = null;
}

// close events
document.getElementById('detailOverlay').addEventListener('click', closeDetail);
document.getElementById('detailClose').addEventListener('click', closeDetail);

// buy from detail
document.getElementById('detailBuy').addEventListener('click', () => {
    if (!currentDetail) return;
    post('buyVehicle', { listingId: currentDetail.id });
    closeDetail()
});

document.addEventListener('keydown', (e) => {
    // F7 = keyCode 118, code "F7"
    if (e.code === 'F7' || e.key === 'F7' || e.keyCode === 118 || e.key === 'Escape' || e.code === 'Escape' || e.keyCode === 27) {
        post('close', {});
    }
});

