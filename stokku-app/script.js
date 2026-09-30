/**
 * STOKKU DESKTOP SUITE - JAVASCRIPT CONTROLLER
 * Menangani Role-Based Access Control:
 * - MANAGER: Hak akses penuh, dapat mengubah harga produk, persetujuan perubahan harga, kelola toko.
 * - ADMIN: Hanya input stok/produk baru & lihat total stok. Terkunci dari edit data/harga setelah disimpan.
 */

document.addEventListener('DOMContentLoaded', () => {
  // ============================================================
  // APP STATE
  // ============================================================
  let currentRole = 'manager'; // 'manager' | 'admin'
  let currentView = 'viewRoleSelector'; // 'viewRoleSelector' | 'viewLogin' | 'viewAppMain'
  let currentTab = 'tab-dashboard';

  // Master Data Produk
  const productsData = [
    {
      id: 1,
      name: 'Minyak Goreng 1L',
      sku: 'SKU: MK-001',
      category: 'Sembako',
      wholesalePrice: 'Rp 12.000',
      retailPrice: 'Rp 14.500',
      status: 'kritis',
      statusLabel: 'Kritis',
      stock: 2
    },
    {
      id: 2,
      name: 'Beras Premium 5kg',
      sku: 'SKU: BR-005',
      category: 'Sembako',
      wholesalePrice: 'Rp 58.000',
      retailPrice: 'Rp 68.000',
      status: 'menipis',
      statusLabel: 'Menipis',
      stock: 5
    },
    {
      id: 3,
      name: 'Gula Pasir 1kg',
      sku: 'SKU: GL-010',
      category: 'Sembako',
      wholesalePrice: 'Rp 12.500',
      retailPrice: 'Rp 14.500',
      status: 'aman',
      statusLabel: 'Stok Aman',
      stock: 45
    },
    {
      id: 4,
      name: 'Teh Celup Kotak',
      sku: 'SKU: TH-022',
      category: 'Minuman',
      wholesalePrice: 'Rp 4.800',
      retailPrice: 'Rp 6.500',
      status: 'aman',
      statusLabel: 'Stok Aman',
      stock: 30
    },
    {
      id: 5,
      name: 'Kopi Sachet 10pcs',
      sku: 'SKU: KP-031',
      category: 'Minuman',
      wholesalePrice: 'Rp 9.500',
      retailPrice: 'Rp 12.000',
      status: 'aman',
      statusLabel: 'Stok Aman',
      stock: 25
    },
    {
      id: 6,
      name: 'Keripik Singkong Balado',
      sku: 'SKU: SN-014',
      category: 'Snack',
      wholesalePrice: 'Rp 6.500',
      retailPrice: 'Rp 9.000',
      status: 'aman',
      statusLabel: 'Stok Aman',
      stock: 50
    }
  ];

  // DOM Elements
  const viewRoleSelector = document.getElementById('viewRoleSelector');
  const viewLogin = document.getElementById('viewLogin');
  const viewAppMain = document.getElementById('viewAppMain');

  const cardRoleManager = document.getElementById('cardRoleManager');
  const cardRoleAdmin = document.getElementById('cardRoleAdmin');
  const btnConfirmRole = document.getElementById('btnConfirmRole');

  const desktopLoginForm = document.getElementById('desktopLoginForm');
  const inputLoginEmail = document.getElementById('inputLoginEmail');
  const inputLoginPassword = document.getElementById('inputLoginPassword');
  const loginRoleBadgeTag = document.getElementById('loginRoleBadgeTag');
  const loginRoleTextDesc = document.getElementById('loginRoleTextDesc');
  const btnBackToRoleSelector = document.getElementById('btnBackToRoleSelector');
  const btnLoadDemoCreds = document.getElementById('btnLoadDemoCreds');

  const sidebarAvatar = document.getElementById('sidebarAvatar');
  const sidebarUserName = document.getElementById('sidebarUserName');
  const sidebarRoleBadge = document.getElementById('sidebarRoleBadge');
  const topbarPageTitle = document.getElementById('topbarPageTitle');
  const topbarPageSubtitle = document.getElementById('topbarPageSubtitle');
  const topbarRolePermissionTag = document.getElementById('topbarRolePermissionTag');
  const btnTopbarAddProduct = document.getElementById('btnTopbarAddProduct');
  const btnSidebarLogout = document.getElementById('btnSidebarLogout');

  const dashboardRoleAlert = document.getElementById('dashboardRoleAlert');
  const managerApprovalSection = document.getElementById('managerApprovalSection');
  const dashTotalStock = document.getElementById('dashTotalStock');
  const dashLowStockCount = document.getElementById('dashLowStockCount');
  const dashTotalSku = document.getElementById('dashTotalSku');
  const dashRoleLabel = document.getElementById('dashRoleLabel');
  const dashRoleSubtext = document.getElementById('dashRoleSubtext');

  const desktopProductTableBody = document.getElementById('desktopProductTableBody');
  const dashboardAttentionTableBody = document.getElementById('dashboardAttentionTableBody');
  const desktopProductSearch = document.getElementById('desktopProductSearch');
  const desktopCategoryFilter = document.getElementById('desktopCategoryFilter');
  const desktopStockFilter = document.getElementById('desktopStockFilter');
  const productTableRoleInfo = document.getElementById('productTableRoleInfo');

  const desktopFormAddProduct = document.getElementById('desktopFormAddProduct');
  const modalEditPrice = document.getElementById('modalEditPrice');
  const formSubmitPriceChange = document.getElementById('formSubmitPriceChange');
  const btnCloseEditPriceModal = document.getElementById('btnCloseEditPriceModal');
  const btnCancelEditPrice = document.getElementById('btnCancelEditPrice');

  const desktopToast = document.getElementById('desktopToast');
  const toastMessage = document.getElementById('toastMessage');
  const toastIcon = document.getElementById('toastIcon');

  /**
   * Tampilkan Toast Notification
   */
  function showToast(msg, icon = '✓') {
    if (!desktopToast) return;
    toastMessage.innerText = msg;
    toastIcon.innerText = icon;
    desktopToast.classList.add('show');
    clearTimeout(window.desktopToastTimer);
    window.desktopToastTimer = setTimeout(() => {
      desktopToast.classList.remove('show');
    }, 3200);
  }

  /**
   * Pindah Tampilan Utama (RoleSelector vs Login vs AppMain)
   */
  function switchDesktopView(viewName) {
    currentView = viewName;
    document.querySelectorAll('.desktop-view').forEach(view => {
      view.classList.remove('active-view');
    });

    if (viewName === 'viewRoleSelector') viewRoleSelector.classList.add('active-view');
    else if (viewName === 'viewLogin') viewLogin.classList.add('active-view');
    else if (viewName === 'viewAppMain') {
      viewAppMain.classList.add('active-view');
      switchDesktopTab('tab-dashboard');
      applyRolePermissions();
      renderAllTables();
    }
  }

  /**
   * Pindah Tab Menu Sidebar di dalam AppMain
   */
  function switchDesktopTab(tabId) {
    currentTab = tabId;
    document.querySelectorAll('.sidebar-menu-btn').forEach(btn => {
      if (btn.dataset.tab === tabId) btn.classList.add('active');
      else btn.classList.remove('active');
    });

    document.querySelectorAll('.desktop-tab-content').forEach(tab => {
      if (tab.id === tabId) tab.classList.add('active-content');
      else tab.classList.remove('active-content');
    });

    if (tabId === 'tab-dashboard') {
      topbarPageTitle.innerText = 'Dashboard (Beranda)';
      topbarPageSubtitle.innerText = 'Ringkasan inventaris dan performa stok toko real-time';
    } else if (tabId === 'tab-products') {
      topbarPageTitle.innerText = 'Master Data Produk';
      topbarPageSubtitle.innerText = 'Katalog produk, harga grosir & eceran, serta status ketersediaan';
      renderProductTable();
    } else if (tabId === 'tab-add-product') {
      topbarPageTitle.innerText = 'Tambah Produk / Input Stok Baru';
      topbarPageSubtitle.innerText = 'Formulir input stok barang toko (Dapat diakses Manager & Admin)';
    } else if (tabId === 'tab-categories') {
      topbarPageTitle.innerText = 'Kategori & Supplier';
      topbarPageSubtitle.innerText = 'Pengelompokan barang dan daftar mitra distributor';
    } else if (tabId === 'tab-profile') {
      topbarPageTitle.innerText = 'Profil & Pengaturan Toko';
      topbarPageSubtitle.innerText = 'Informasi akun pengguna dan kontrol hak akses';
    }
  }

  /**
   * Set Peran Pengguna (Manager vs Admin)
   */
  function setAppRole(role) {
    currentRole = role;

    if (role === 'manager') {
      if (cardRoleManager) cardRoleManager.classList.add('selected');
      if (cardRoleAdmin) cardRoleAdmin.classList.remove('selected');

      loginRoleBadgeTag.className = 'role-badge-tag tag-manager';
      loginRoleBadgeTag.innerText = 'Manager';
      loginRoleTextDesc.innerHTML = 'Masuk sebagai: <strong>Manager / Pemilik Toko</strong>';
      inputLoginEmail.value = 'manager@tokoberkah.com';
      inputLoginPassword.value = 'password123';
    } else {
      if (cardRoleAdmin) cardRoleAdmin.classList.add('selected');
      if (cardRoleManager) cardRoleManager.classList.remove('selected');

      loginRoleBadgeTag.className = 'role-badge-tag tag-admin';
      loginRoleBadgeTag.innerText = 'Admin';
      loginRoleTextDesc.innerHTML = 'Masuk sebagai: <strong>Admin Toko (Siti)</strong>';
      inputLoginEmail.value = 'admin@tokoberkah.com';
      inputLoginPassword.value = 'admin123';
    }
  }

  /**
   * Terapkan Aturan Hak Akses (RBAC Enforcement)
   */
  function applyRolePermissions() {
    if (currentRole === 'manager') {
      // Sidebar
      sidebarAvatar.innerText = 'B';
      sidebarAvatar.style.background = '#f59e0b';
      sidebarUserName.innerText = 'Budi Santoso';
      sidebarRoleBadge.className = 'user-role-tag-side tag-manager';
      sidebarRoleBadge.innerText = '👑 Manager Toko';

      // Topbar
      topbarRolePermissionTag.className = 'role-permission-badge tag-manager';
      topbarRolePermissionTag.innerHTML = '<span>👑 Peran: Manager (Akses Penuh &amp; Edit Harga)</span>';

      // Dashboard
      dashboardRoleAlert.className = 'role-info-alert-banner banner-manager';
      dashboardRoleAlert.innerHTML = `
        <div class="banner-left-info">
          <div style="font-size: 1.3rem;">👑</div>
          <div>
            <h4>Mode Manager Aktif</h4>
            <p>Anda memiliki hak akses penuh untuk mengubah harga produk (Grosir &amp; Eceran), meninjau persetujuan, dan mengelola stok.</p>
          </div>
        </div>
        <button type="button" class="btn-action-pill" id="btnSwitchToAdmin" style="background: white; color: #0284c7; border: 1px solid #cbd5e1;">
          Coba Mode Admin &rarr;
        </button>
      `;
      if (managerApprovalSection) managerApprovalSection.style.display = 'flex';
      dashRoleLabel.innerText = 'Manager';
      dashRoleSubtext.innerText = 'Akses Penuh & Ubah Harga';

      const dynamicSwitchBtn = document.getElementById('btnSwitchToAdmin');
      if (dynamicSwitchBtn) {
        dynamicSwitchBtn.addEventListener('click', () => {
          setAppRole('admin');
          applyRolePermissions();
          renderAllTables();
          showToast('Beralih ke Peran Admin (Input & Cek Stok). Hak edit harga dikunci.', '🛒');
        });
      }

      productTableRoleInfo.innerHTML = `
        <span style="color: #059669; font-weight: 700;">✓ Mode Manager Aktif:</span> Anda dapat mengubah harga produk sewaktu-waktu dengan menekan tombol <strong>'Ubah Harga'</strong>.
      `;

      // Profile Card
      const profileCardAvatar = document.getElementById('profileCardAvatar');
      const profileCardName = document.getElementById('profileCardName');
      const profileCardRoleTag = document.getElementById('profileCardRoleTag');
      const profileCardEmail = document.getElementById('profileCardEmail');
      if (profileCardAvatar) profileCardAvatar.innerText = 'B';
      if (profileCardName) profileCardName.innerText = 'Budi Santoso';
      if (profileCardRoleTag) {
        profileCardRoleTag.className = 'role-badge-tag tag-manager';
        profileCardRoleTag.innerText = 'Manager (Pemilik Toko)';
      }
      if (profileCardEmail) profileCardEmail.value = 'manager@tokoberkah.com';

    } else {
      // Role: Admin (Stok & Input)
      sidebarAvatar.innerText = 'S';
      sidebarAvatar.style.background = '#0284c7';
      sidebarUserName.innerText = 'Siti Aminah';
      sidebarRoleBadge.className = 'user-role-tag-side tag-admin';
      sidebarRoleBadge.innerText = '🛒 Admin Stok';

      // Topbar
      topbarRolePermissionTag.className = 'role-permission-badge tag-admin';
      topbarRolePermissionTag.innerHTML = '<span>🛒 Peran: Admin (Input &amp; Cek Total Stok)</span>';

      // Dashboard
      dashboardRoleAlert.className = 'role-info-alert-banner banner-admin';
      dashboardRoleAlert.innerHTML = `
        <div class="banner-left-info">
          <div style="font-size: 1.3rem;">🛒</div>
          <div>
            <h4>Mode Admin Aktif</h4>
            <p>Anda berhak menginput produk &amp; stok baru serta melihat total stok toko. Sesuai kebijakan, admin <strong>tidak dapat mengedit atau mengubah harga</strong> produk yang telah tersimpan.</p>
          </div>
        </div>
        <button type="button" class="btn-action-pill" id="btnSwitchToManager" style="background: white; color: #b45309; border: 1px solid #cbd5e1;">
          Coba Mode Manager &rarr;
        </button>
      `;
      if (managerApprovalSection) managerApprovalSection.style.display = 'none';
      dashRoleLabel.innerText = 'Admin';
      dashRoleSubtext.innerText = 'Input Stok & Cek Total Stok';

      const dynamicSwitchBtn = document.getElementById('btnSwitchToManager');
      if (dynamicSwitchBtn) {
        dynamicSwitchBtn.addEventListener('click', () => {
          setAppRole('manager');
          applyRolePermissions();
          renderAllTables();
          showToast('Beralih ke Peran Manager. Hak ubah harga aktif!', '👑');
        });
      }

      productTableRoleInfo.innerHTML = `
        <span style="color: #0284c7; font-weight: 700;">🔒 Mode Admin Aktif:</span> Admin dapat melihat data stok. Seluruh data produk berstatus <strong>Terkunci (Read-Only)</strong> dan hanya dapat diubah oleh Manager.
      `;

      // Profile Card
      const profileCardAvatar = document.getElementById('profileCardAvatar');
      const profileCardName = document.getElementById('profileCardName');
      const profileCardRoleTag = document.getElementById('profileCardRoleTag');
      const profileCardEmail = document.getElementById('profileCardEmail');
      if (profileCardAvatar) profileCardAvatar.innerText = 'S';
      if (profileCardName) profileCardName.innerText = 'Siti Aminah';
      if (profileCardRoleTag) {
        profileCardRoleTag.className = 'role-badge-tag tag-admin';
        profileCardRoleTag.innerText = 'Admin (Admin Stok & Kasir)';
      }
      if (profileCardEmail) profileCardEmail.value = 'admin@tokoberkah.com';
    }
  }

  /**
   * Render Tabel Produk di Master Data Produk
   */
  function renderProductTable() {
    if (!desktopProductTableBody) return;

    const query = (desktopProductSearch?.value || '').toLowerCase().trim();
    const catFilter = desktopCategoryFilter?.value || 'Semua';
    const statusFilter = desktopStockFilter?.value || 'Semua';

    const filtered = productsData.filter(item => {
      const matchSearch = item.name.toLowerCase().includes(query) || item.sku.toLowerCase().includes(query);
      const matchCat = (catFilter === 'Semua' || item.category === catFilter);
      const matchStatus = (statusFilter === 'Semua' || item.status === statusFilter);
      return matchSearch && matchCat && matchStatus;
    });

    if (filtered.length === 0) {
      desktopProductTableBody.innerHTML = `
        <tr>
          <td colspan="8" style="text-align: center; padding: 40px; color: #94a3b8;">
            Tidak ada produk yang cocok dengan pencarian atau filter yang dipilih.
          </td>
        </tr>
      `;
      return;
    }

    desktopProductTableBody.innerHTML = filtered.map((item, index) => {
      let actionHtml = '';
      if (currentRole === 'manager') {
        actionHtml = `
          <button type="button" class="btn-edit-price btn-trigger-edit-price" data-id="${item.id}" title="Ubah harga grosir & eceran produk ini">
            🏷️ Ubah Harga
          </button>
        `;
      } else {
        actionHtml = `
          <span class="badge-locked-admin btn-trigger-admin-locked" data-id="${item.id}" title="Data terkunci untuk role Admin">
            🔒 Terkunci (Read-Only)
          </span>
        `;
      }

      return `
        <tr>
          <td style="color: #64748b; font-weight: 600;">${index + 1}</td>
          <td>
            <div class="product-item-cell">
              <div class="product-thumb-desktop">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="3" y="3" width="18" height="18" rx="4"></rect>
                  <circle cx="8.5" cy="8.5" r="1.5"></circle>
                  <polyline points="21 15 16 10 5 21"></polyline>
                </svg>
              </div>
              <div>
                <h4>${item.name}</h4>
                <span>${item.sku}</span>
              </div>
            </div>
          </td>
          <td><span style="font-weight: 600; color: #334155;">${item.category}</span></td>
          <td style="color: #475569;">${item.wholesalePrice}</td>
          <td style="font-weight: 700; color: #0284c7;">${item.retailPrice}</td>
          <td>
            <span style="font-weight: 700; font-size: 0.95rem;">${item.stock}</span>
            <span style="font-size: 0.72rem; color: #94a3b8;"> unit</span>
          </td>
          <td>
            <span class="status-pill ${item.status}">${item.statusLabel}</span>
          </td>
          <td>
            ${actionHtml}
          </td>
        </tr>
      `;
    }).join('');

    bindTableActionEvents();
  }

  /**
   * Render Tabel Produk Perlu Perhatian di Dashboard
   */
  function renderDashboardAttentionTable() {
    if (!dashboardAttentionTableBody) return;

    const attentionItems = productsData.filter(item => item.status === 'kritis' || item.status === 'menipis');

    dashboardAttentionTableBody.innerHTML = attentionItems.map(item => {
      let actionHtml = '';
      if (currentRole === 'manager') {
        actionHtml = `<button type="button" class="btn-edit-price btn-trigger-edit-price" data-id="${item.id}">🏷️ Ubah Harga</button>`;
      } else {
        actionHtml = `<span class="badge-locked-admin btn-trigger-admin-locked">🔒 Terkunci</span>`;
      }

      return `
        <tr>
          <td>
            <div class="product-item-cell">
              <div class="product-thumb-desktop">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="3" y="3" width="18" height="18" rx="4"></rect>
                  <circle cx="8.5" cy="8.5" r="1.5"></circle>
                  <polyline points="21 15 16 10 5 21"></polyline>
                </svg>
              </div>
              <div>
                <h4>${item.name}</h4>
                <span>${item.sku}</span>
              </div>
            </div>
          </td>
          <td>${item.category}</td>
          <td>${item.wholesalePrice}</td>
          <td style="font-weight: 700; color: #0284c7;">${item.retailPrice}</td>
          <td><strong>${item.stock}</strong> unit</td>
          <td><span class="status-pill ${item.status}">${item.statusLabel}</span></td>
          <td>${actionHtml}</td>
        </tr>
      `;
    }).join('');

    bindTableActionEvents();
  }

  /**
   * Update Hitungan Metrik Dashboard
   */
  function updateDashboardMetrics() {
    const total = productsData.reduce((acc, curr) => acc + curr.stock, 0);
    const lowStock = productsData.filter(item => item.stock <= 5).length;

    if (dashTotalStock) dashTotalStock.innerText = total.toLocaleString('id-ID');
    if (dashLowStockCount) dashLowStockCount.innerText = lowStock;
    if (dashTotalSku) dashTotalSku.innerText = `${productsData.length} Produk`;
  }

  function renderAllTables() {
    renderProductTable();
    renderDashboardAttentionTable();
    updateDashboardMetrics();
  }

  /**
   * Event Listeners untuk Tombol Aksi di Tabel
   */
  function bindTableActionEvents() {
    // Tombol Ubah Harga untuk Manager
    document.querySelectorAll('.btn-trigger-edit-price').forEach(btn => {
      btn.onclick = () => {
        const id = parseInt(btn.dataset.id);
        openEditPriceModal(id);
      };
    });

    // Peringatan Klik Terkunci untuk Admin
    document.querySelectorAll('.btn-trigger-admin-locked').forEach(btn => {
      btn.onclick = () => {
        showToast('Akses Ditolak: Admin tidak berhak mengubah harga atau data yang telah tersimpan. Hubungi Manager.', '⚠️');
      };
    });
  }

  /**
   * Buka Modal Ubah Harga Produk (Khusus Manager)
   */
  function openEditPriceModal(productId) {
    const product = productsData.find(p => p.id === productId);
    if (!product) return;

    document.getElementById('modalProductId').value = product.id;
    document.getElementById('modalProductName').innerText = product.name;
    document.getElementById('modalProductSku').innerText = `${product.sku} • Kategori: ${product.category}`;
    document.getElementById('modalWholesalePrice').value = product.wholesalePrice;
    document.getElementById('modalRetailPrice').value = product.retailPrice;

    modalEditPrice.classList.add('show');
  }

  function closeEditPriceModal() {
    modalEditPrice.classList.remove('show');
  }

  if (btnCloseEditPriceModal) btnCloseEditPriceModal.onclick = closeEditPriceModal;
  if (btnCancelEditPrice) btnCancelEditPrice.onclick = closeEditPriceModal;

  // Submit Perubahan Harga
  if (formSubmitPriceChange) {
    formSubmitPriceChange.onsubmit = (e) => {
      e.preventDefault();
      const id = parseInt(document.getElementById('modalProductId').value);
      const newWholesale = document.getElementById('modalWholesalePrice').value.trim();
      const newRetail = document.getElementById('modalRetailPrice').value.trim();

      const product = productsData.find(p => p.id === id);
      if (product) {
        product.wholesalePrice = newWholesale.startsWith('Rp') ? newWholesale : 'Rp ' + newWholesale;
        product.retailPrice = newRetail.startsWith('Rp') ? newRetail : 'Rp ' + newRetail;

        closeEditPriceModal();
        renderAllTables();
        showToast(`Harga produk "${product.name}" berhasil diubah oleh Manager!`, '✓');
      }
    };
  }

  // ============================================================
  // EVENT LISTENERS: PORTAL ROLE SELECTOR
  // ============================================================
  if (cardRoleManager) cardRoleManager.addEventListener('click', () => setAppRole('manager'));
  if (cardRoleAdmin) cardRoleAdmin.addEventListener('click', () => setAppRole('admin'));

  if (btnConfirmRole) {
    btnConfirmRole.addEventListener('click', () => {
      switchDesktopView('viewLogin');
      showToast(`Peran terpilih: ${currentRole === 'manager' ? 'Manager Toko' : 'Admin Stok'}`);
    });
  }

  if (btnBackToRoleSelector) {
    btnBackToRoleSelector.addEventListener('click', () => {
      switchDesktopView('viewRoleSelector');
    });
  }

  // Login Form Submit
  if (desktopLoginForm) {
    desktopLoginForm.addEventListener('submit', (e) => {
      e.preventDefault();
      showToast(`Berhasil masuk ke sistem Stokku Desktop sebagai ${currentRole === 'manager' ? 'Manager' : 'Admin'}!`);
      switchDesktopView('viewAppMain');
    });
  }

  // Muat Demo Creds Cepat
  if (btnLoadDemoCreds) {
    btnLoadDemoCreds.addEventListener('click', () => {
      if (currentRole === 'manager') {
        inputLoginEmail.value = 'manager@tokoberkah.com';
        inputLoginPassword.value = 'password123';
      } else {
        inputLoginEmail.value = 'admin@tokoberkah.com';
        inputLoginPassword.value = 'admin123';
      }
      showToast('Kredensial demo terisi otomatis!');
    });
  }

  // ============================================================
  // EVENT LISTENERS: NAVIGATION & SIDEBAR
  // ============================================================
  document.querySelectorAll('.sidebar-menu-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      switchDesktopTab(btn.dataset.tab);
    });
  });

  if (btnTopbarAddProduct) {
    btnTopbarAddProduct.addEventListener('click', () => {
      switchDesktopTab('tab-add-product');
    });
  }

  const btnViewAllProductsFromDash = document.getElementById('btnViewAllProductsFromDash');
  if (btnViewAllProductsFromDash) {
    btnViewAllProductsFromDash.addEventListener('click', () => {
      switchDesktopTab('tab-products');
    });
  }

  // Logout
  if (btnSidebarLogout) {
    btnSidebarLogout.addEventListener('click', () => {
      if (confirm('Apakah Anda yakin ingin keluar dari sistem Stokku Desktop?')) {
        showToast('Anda telah keluar dari akun.', '👋');
        switchDesktopView('viewRoleSelector');
      }
    });
  }

  // Switch role dari Profil
  const btnSwitchRoleFromProfile = document.getElementById('btnSwitchRoleFromProfile');
  if (btnSwitchRoleFromProfile) {
    btnSwitchRoleFromProfile.addEventListener('click', () => {
      const newRole = currentRole === 'manager' ? 'admin' : 'manager';
      setAppRole(newRole);
      applyRolePermissions();
      renderAllTables();
      showToast(`Peran berhasil ditukar menjadi: ${newRole === 'manager' ? 'Manager' : 'Admin'}`, '🔄');
    });
  }

  // Persetujuan Perubahan Harga (Manager Only)
  const btnAcceptPriceChange = document.getElementById('btnAcceptPriceChange');
  const btnRejectPriceChange = document.getElementById('btnRejectPriceChange');
  if (btnAcceptPriceChange && managerApprovalSection) {
    btnAcceptPriceChange.addEventListener('click', () => {
      const item = productsData.find(p => p.id === 1);
      if (item) item.retailPrice = 'Rp 15.000';

      managerApprovalSection.innerHTML = `
        <div style="font-size: 0.86rem; font-weight: 700; color: #059669; display: flex; align-items: center; gap: 8px;">
          ✓ Kenaikan harga Minyak Goreng menjadi Rp 15.000 telah disetujui Manager dan diterapkan ke sistem!
        </div>
      `;
      managerApprovalSection.style.borderColor = '#10b981';
      renderAllTables();
      showToast('Perubahan harga berhasil disetujui & diterapkan!');
    });
  }

  if (btnRejectPriceChange && managerApprovalSection) {
    btnRejectPriceChange.addEventListener('click', () => {
      managerApprovalSection.innerHTML = `
        <div style="font-size: 0.86rem; font-weight: 700; color: #dc2626; display: flex; align-items: center; gap: 8px;">
          ✕ Pengajuan harga ditolak oleh Manager. Harga tetap Rp 14.500.
        </div>
      `;
      managerApprovalSection.style.borderColor = '#ef4444';
      showToast('Pengajuan perubahan harga ditolak.', '✕');
    });
  }

  // Filters
  if (desktopProductSearch) desktopProductSearch.addEventListener('input', renderProductTable);
  if (desktopCategoryFilter) desktopCategoryFilter.addEventListener('change', renderProductTable);
  if (desktopStockFilter) desktopStockFilter.addEventListener('change', renderProductTable);

  // Form Input Produk Baru
  if (desktopFormAddProduct) {
    desktopFormAddProduct.addEventListener('submit', (e) => {
      e.preventDefault();
      const name = document.getElementById('addProdName').value.trim();
      const sku = document.getElementById('addProdSku').value.trim() || 'SKU: BRG-' + Math.floor(100 + Math.random() * 900);
      const category = document.getElementById('addProdCat').value;
      const wholesale = document.getElementById('addProdWholesale').value.trim() || 'Rp 10.000';
      const retail = document.getElementById('addProdRetail').value.trim() || 'Rp 15.000';
      const stock = parseInt(document.getElementById('addProdStock').value) || 10;
      const minStock = parseInt(document.getElementById('addProdMinStock').value) || 5;

      let status = 'aman';
      let statusLabel = 'Stok Aman';
      if (stock <= 2) {
        status = 'kritis';
        statusLabel = 'Kritis';
      } else if (stock <= minStock) {
        status = 'menipis';
        statusLabel = 'Menipis';
      }

      const newProduct = {
        id: Date.now(),
        name,
        sku,
        category,
        wholesalePrice: wholesale.startsWith('Rp') ? wholesale : 'Rp ' + wholesale,
        retailPrice: retail.startsWith('Rp') ? retail : 'Rp ' + retail,
        status,
        statusLabel,
        stock
      };

      productsData.unshift(newProduct);
      renderAllTables();
      desktopFormAddProduct.reset();

      if (currentRole === 'admin') {
        showToast(`Produk "${name}" berhasil diinput oleh Admin! Sesuai aturan, data ini sekarang terkunci (Read-Only).`, '🔒');
      } else {
        showToast(`Produk "${name}" berhasil ditambahkan ke inventaris oleh Manager!`, '✓');
      }

      switchDesktopTab('tab-products');
    });
  }

  // Inisialisasi awal
  setAppRole('manager');
  switchDesktopView('viewRoleSelector');
});
