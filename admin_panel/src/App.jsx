import React, { useEffect, useState } from "react";
import { initializeApp } from "firebase/app";
import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from "firebase/auth";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getFirestore,
  onSnapshot,
  serverTimestamp,
  updateDoc,
  writeBatch,
} from "firebase/firestore";

const config = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};
const configured = Object.values(config).every(Boolean);
const adminEmail = (import.meta.env.VITE_ADMIN_EMAIL || "").toLowerCase();
const cloudinaryCloudName = import.meta.env.VITE_CLOUDINARY_CLOUD_NAME || "xbflk22h";
const cloudinaryUploadPreset = import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET || "BabyShop";
const app = configured ? initializeApp(config) : null;
const auth = app ? getAuth(app) : null;
const db = app ? getFirestore(app) : null;
const transitions = {
  pending: ["confirmed", "cancelled"],
  confirmed: ["processing", "cancelled"],
  processing: ["shipped", "cancelled"],
  shipped: ["out_for_delivery"],
  out_for_delivery: ["delivered"],
  delivered: [],
  cancelled: [],
};

export default function App() {
  const [user, setUser] = useState(null);
  const [authorized, setAuthorized] = useState(false);
  const [error, setError] = useState("");
  const [page, setPage] = useState("Overview");
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [orders, setOrders] = useState([]);
  const [users, setUsers] = useState([]);
  const [tickets, setTickets] = useState([]);
  const [form, setForm] = useState(null);
  const [selectedImage, setSelectedImage] = useState(null);
  const [selectedImagePreview, setSelectedImagePreview] = useState("");
  const [savingProduct, setSavingProduct] = useState(false);
  const [categoryForm, setCategoryForm] = useState(null);
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [range, setRange] = useState("30d");
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  useEffect(() => {
    if (!selectedImage) {
      setSelectedImagePreview("");
      return undefined;
    }
    const previewUrl = URL.createObjectURL(selectedImage);
    setSelectedImagePreview(previewUrl);
    return () => URL.revokeObjectURL(previewUrl);
  }, [selectedImage]);

  function closeProductForm() {
    setForm(null);
    setSelectedImage(null);
  }

  // Close modals on Escape key
  useEffect(() => {
    function handleKeyDown(e) {
      if (e.key === "Escape") {
        if (form) closeProductForm();
        if (categoryForm) setCategoryForm(null);
        if (selectedOrder) setSelectedOrder(null);
      }
    }
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [form, categoryForm, selectedOrder]);

  async function uploadProductImage(file) {
    const uploadData = new FormData();
    uploadData.append("file", file);
    uploadData.append("upload_preset", cloudinaryUploadPreset);
    const response = await fetch(
      `https://api.cloudinary.com/v1_1/${cloudinaryCloudName}/image/upload`,
      { method: "POST", body: uploadData },
    );
    const result = await response.json();
    if (!response.ok) {
      throw new Error(result.error?.message || `Image upload failed (${response.status}).`);
    }
    if (typeof result.secure_url !== "string" || !result.secure_url) {
      throw new Error("Cloudinary did not return a secure image URL.");
    }
    return result.secure_url;
  }

  useEffect(() => {
    if (!auth) return undefined;
    return onAuthStateChanged(auth, async (current) => {
      setUser(current);
      setAuthorized(false);
      if (!current) return;
      try {
        const claims = await current.getIdTokenResult(true);
        const isAllowlistedAdmin =
          Boolean(adminEmail) && current.email?.toLowerCase() === adminEmail;
        if (claims.claims.admin !== true && !isAllowlistedAdmin) {
          setError("This account does not have administrator access.");
          await signOut(auth);
          return;
        }
        setError("");
        setAuthorized(true);
      } catch (reason) {
        setError(reason.message);
      }
    });
  }, []);

  useEffect(() => {
    if (!authorized) return undefined;
    const subscriptions = [
      ["products", setProducts],
      ["categories", setCategories],
      ["orders", setOrders],
      ["users", setUsers],
      ["supportTickets", setTickets],
    ].map(([name, setter]) =>
      onSnapshot(
        collection(db, name),
        (snapshot) => setter(snapshot.docs.map((item) => ({ id: item.id, ...item.data() }))),
        (reason) => setError(reason.message),
      ),
    );
    return () => subscriptions.forEach((unsubscribe) => unsubscribe());
  }, [authorized]);

  async function login(event) {
    event.preventDefault();
    setError("");
    const data = new FormData(event.currentTarget);
    try {
      await signInWithEmailAndPassword(
        auth,
        String(data.get("email") || "").trim(),
        data.get("password"),
      );
    } catch (reason) {
      setError(reason.code === "auth/invalid-credential"
        ? "Email or password was not accepted. Check the Firebase account and Email/Password sign-in settings."
        : reason.message);
    }
  }

  async function saveProduct(event) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const existingImageUrl = form.imageUrl?.trim() || "";
    const product = {
      name: data.get("name").trim(),
      brand: data.get("brand").trim(),
      categoryName: data.get("categoryName").trim(),
      description: data.get("description").trim(),
      price: Number(data.get("price")),
      stock: Number(data.get("stock")),
      isActive: data.get("isActive") === "on",
      updatedAt: serverTimestamp(),
    };
    if (!product.name || !Number.isFinite(product.price) || product.price < 0 ||
        !Number.isInteger(product.stock) || product.stock < 0) {
      setError("Enter a product name, valid price, and whole-number stock.");
      return;
    }
    if (!selectedImage && !existingImageUrl) {
      setError("Choose a product image from your device.");
      return;
    }
    setSavingProduct(true);
    setError("");
    try {
      product.imageUrl = selectedImage
        ? await uploadProductImage(selectedImage)
        : existingImageUrl;
      if (form?.id) await updateDoc(doc(db, "products", form.id), product);
      else await addDoc(collection(db, "products"), { ...product, createdAt: serverTimestamp() });
      closeProductForm();
      setError("");
    } catch (reason) {
      setError(reason.message);
    } finally {
      setSavingProduct(false);
    }
  }

  async function saveCategory(event) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const name = data.get("name").trim();
    if (!name || name.length > 60) {
      setError("Enter a category name with no more than 60 characters.");
      return;
    }
    if (categories.some((category) =>
      category.id !== categoryForm?.id &&
      category.name?.trim().toLowerCase() === name.toLowerCase())) {
      setError("A category with this name already exists.");
      return;
    }

    try {
      if (categoryForm?.id) {
        const oldName = categoryForm.name;
        const linkedProducts = products.filter((product) =>
          (product.categoryName ?? product.category) === oldName);
        if (linkedProducts.length > 499) {
          setError("This category has too many linked products to rename at once.");
          return;
        }
        const batch = writeBatch(db);
        batch.update(doc(db, "categories", categoryForm.id), {
          name,
          isActive: data.get("isActive") === "on",
          updatedAt: serverTimestamp(),
        });
        if (oldName !== name) {
          linkedProducts.forEach((product) => {
            batch.update(doc(db, "products", product.id), {
              categoryName: name,
              updatedAt: serverTimestamp(),
            });
          });
        }
        await batch.commit();
      } else {
        await addDoc(collection(db, "categories"), {
          name,
          isActive: data.get("isActive") === "on",
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
      }
      setCategoryForm(null);
      setError("");
    } catch (reason) {
      setError(reason.message);
    }
  }

  async function deleteCategory(category) {
    const linkedProducts = products.filter((product) =>
      (product.categoryName ?? product.category) === category.name);
    if (linkedProducts.length) {
      setError(`Cannot delete "${category.name}" while ${linkedProducts.length} product(s) use it. Deactivate it instead.`);
      return;
    }
    if (!window.confirm(`Delete the "${category.name}" category?`)) return;
    try {
      await deleteDoc(doc(db, "categories", category.id));
      setError("");
    } catch (reason) {
      setError(reason.message);
    }
  }

  async function updateOrder(order, status) {
    if (!transitions[order.status]?.includes(status)) {
      setError(`Invalid order transition: ${order.status} to ${status}.`);
      return;
    }
    try {
      await updateDoc(doc(db, "orders", order.id), {
        status,
        updatedAt: serverTimestamp(),
        statusHistory: [...(order.statusHistory ?? []), {
          status,
          updatedAt: new Date().toISOString(),
          updatedBy: user.uid,
        }],
      });
      if (selectedOrder && selectedOrder.id === order.id) {
        setSelectedOrder({ ...selectedOrder, status });
      }
      setError("");
    } catch (reason) {
      setError(reason.message);
    }
  }

  if (!configured) {
    return <main className="container py-5"><div className="alert alert-warning">
      Configure Firebase in `admin_panel/.env` using `.env.example`.
    </div></main>;
  }
  if (!authorized) {
    return <main className="login-wrap">
      <form className="login-card" onSubmit={login}>
        <div className="brand-mark">
          <img src="/logo.jpg" alt="BabyShop logo" />
        </div>
        <h1>BabyShop</h1>
        <p>A World of Little Wonders · Admin Sign In</p>
        {error && <div className="alert alert-danger">{error}</div>}
        <label className="form-label">Email</label>
        <input
          name="email"
          className="form-control mb-3"
          type="email"
          defaultValue="hamzakhan13102004@gmail.com"
          required
        />
        <label className="form-label">Password</label>
        <input name="password" className="form-control mb-4" type="password" required />
        <button className="btn btn-green w-100">Sign in to BabyShop</button>
      </form>
    </main>;
  }

  const tabs = ["Overview", "Products", "Categories", "Orders", "Customers", "Support"];
  const rangeDays = range === "7d" ? 7 : range === "30d" ? 30 : range === "6m" ? 183 : 365;
  const rangeStart = new Date();
  rangeStart.setDate(rangeStart.getDate() - rangeDays + 1);
  const rangedOrders = orders.filter((order) => {
    const date = asDate(order.createdAt);
    return date && date >= startOfDay(rangeStart);
  });
  const revenue = rangedOrders.reduce((sum, order) => sum + Number(order.total ?? 0), 0);
  const previousStart = new Date(rangeStart);
  previousStart.setDate(previousStart.getDate() - rangeDays);
  const previousOrders = orders.filter((order) => {
    const date = asDate(order.createdAt);
    return date && date >= startOfDay(previousStart) && date < startOfDay(rangeStart);
  });
  const previousRevenue = previousOrders.reduce((sum, order) => sum + Number(order.total ?? 0), 0);
  const revenueChange = previousRevenue ? ((revenue - previousRevenue) / previousRevenue) * 100 : null;
  const chartData = buildRevenueSeries(rangedOrders, range);
  const statusCounts = ["pending", "confirmed", "processing", "shipped", "out_for_delivery", "delivered", "cancelled"]
    .map((status) => ({ status, count: rangedOrders.filter((order) => (order.status || "pending") === status).length }));
  const topProducts = buildTopProducts(rangedOrders);
  const categorySales = buildCategorySales(rangedOrders, products);

  return <div className="admin-shell">
    {mobileNavOpen && <button className="sidebar-scrim" aria-label="Close navigation" onClick={() => setMobileNavOpen(false)} />}
    <aside className={`sidebar ${mobileNavOpen ? "sidebar-open" : ""}`}>
      <div className="sidebar-brand">
        <img src="/logo.jpg" alt="BabyShop logo" />
        <span>BabyShop</span>
      </div>
      <span className="sidebar-caption">LUXURY STORE MANAGEMENT</span>
      {tabs.map((tab) => <button key={tab} onClick={() => { setPage(tab); setMobileNavOpen(false); }}
        className={`nav-item ${page === tab ? "active" : ""}`}><span className="nav-icon">{({Overview:"◫",Products:"▧",Categories:"◇",Orders:"▤",Customers:"♙",Support:"✉"})[tab]}</span>{tab}</button>)}
      <button className="nav-item signout" onClick={() => signOut(auth)}><span className="nav-icon">↪</span>Sign out</button>
    </aside>
    <main className="main-panel">
      <header className="topbar">
        <div className="topbar-title">
          <button className="mobile-menu" onClick={() => setMobileNavOpen(true)} aria-label="Open navigation">☰</button>
          <div>
            <span className="eyebrow">BABYSHOP · A WORLD OF LITTLE WONDERS</span>
            <h2>{page}</h2>
          </div>
        </div>
        <span className="admin-email">{user.email}</span>
      </header>

      {error && !form && <div className="alert alert-danger">{error}<button className="btn-close float-end" onClick={() => setError("")} /></div>}

      {page === "Overview" && <section className="dashboard-content">
        <div className="welcome-row">
          <div>
            <span className="eyebrow">STORE PERFORMANCE</span>
            <h3 className="welcome-title">Your boutique at a glance</h3>
            <p>Live insights from your BabyShop orders and catalog.</p>
          </div>
          <div className="range-switch" aria-label="Analytics date range">
            {[["7d","7 days"],["30d","30 days"],["6m","6 months"],["1y","1 year"]].map(([key,label]) =>
              <button key={key} className={range===key?"selected":""} onClick={()=>setRange(key)}>{label}</button>)}
          </div>
        </div>
        <div className="stats-grid">
          <Stat icon="$" label="Revenue in period" value={`$${revenue.toFixed(2)}`} note={revenueChange === null ? "Waiting for comparison data" : `${revenueChange >= 0 ? "+" : ""}${revenueChange.toFixed(1)}% vs previous period`} />
          <Stat icon="↗" label="Orders in period" value={rangedOrders.length} note={`${orders.length} all-time orders`} />
          <Stat icon="✧" label="Active products" value={products.filter((product)=>product.isActive!==false).length} note={`${products.length} total catalog items`} />
          <Stat icon="♡" label="Customers" value={users.length} note="Registered accounts" />
          <Stat icon="◷" label="Pending orders" value={orders.filter((order) => order.status === "pending").length} note="Need your attention" />
          <Stat icon="!" label="Low stock" value={products.filter((product) => Number(product.stock) < 6).length} note="Fewer than 6 units" />
        </div>
        <div className="analytics-grid">
          <div className="content-card revenue-card"><div className="section-heading"><div><span className="eyebrow">REVENUE TRENDS</span><h3>Sales overview</h3></div><span className="chart-caption">{chartData.length} periods</span></div><RevenueChart data={chartData}/></div>
          <div className="content-card status-card"><div className="section-heading"><div><span className="eyebrow">FULFILMENT</span><h3>Order status</h3></div></div><StatusChart data={statusCounts}/></div>
        </div>
        <div className="analytics-grid lower-grid">
          <div className="content-card"><div className="section-heading"><div><span className="eyebrow">PRODUCT MIX</span><h3>Top selling products</h3></div></div><TopProducts items={topProducts}/></div>
          <div className="content-card"><div className="section-heading"><div><span className="eyebrow">INVENTORY HEALTH</span><h3>Stock watch</h3></div><button className="text-action" onClick={()=>setPage("Products")}>View catalog →</button></div><StockWatch products={products}/></div>
          <div className="content-card"><div className="section-heading"><div><span className="eyebrow">CATEGORY INSIGHTS</span><h3>Category performance</h3></div></div><CategoryPerformance items={categorySales}/></div>
        </div>
        <div className="content-card recent-orders">
          <div className="section-heading">
            <div><span className="eyebrow">LATEST ACTIVITY</span><h3>Recent orders</h3></div>
            <button className="text-action" onClick={()=>setPage("Orders")}>View all →</button>
          </div>
          <OrderTable
            orders={[...orders].sort((a,b)=>(asDate(b.createdAt)?.getTime()||0)-(asDate(a.createdAt)?.getTime()||0)).slice(0,8)}
            onUpdate={updateOrder}
            onSelectOrder={setSelectedOrder}
          />
        </div>
      </section>}

      {page === "Categories" && <section className="content-card">
        <div className="section-heading">
          <div><span className="eyebrow">CATALOG</span><h3>Categories</h3></div>
          <button className="btn btn-green" onClick={() => setCategoryForm({})}>Add category</button>
        </div>
        <div className="table-responsive"><table className="table align-middle">
          <thead><tr><th>Category</th><th>Products</th><th>Status</th><th /></tr></thead>
          <tbody>{categories.map((category) => {
            const productCount = products.filter((product) =>
              (product.categoryName ?? product.category) === category.name).length;
            return <tr key={category.id}>
              <td><strong>{category.name}</strong></td>
              <td>{productCount}</td>
              <td><span className={`status-pill ${category.isActive ? "" : "status-pill-inactive"}`}>{category.isActive ? "Active" : "Hidden"}</span></td>
              <td className="text-end">
                <button className="btn btn-sm btn-outline-success me-2" onClick={() => setCategoryForm({ ...category })}>Edit</button>
                <button className="btn btn-sm btn-outline-danger" onClick={() => deleteCategory(category)}>Delete</button>
              </td>
            </tr>;
          })}</tbody>
        </table></div>
        {!categories.length && <p className="empty-note">No categories yet. Add your first category to organize products.</p>}
      </section>}

      {page === "Products" && <section className="content-card">
        <div className="section-heading">
          <div><span className="eyebrow">CATALOG</span><h3>Products</h3></div>
          <button className="btn btn-green" onClick={() => { setSelectedImage(null); setForm({}); }}>Add product</button>
        </div>
        <div className="table-responsive"><table className="table align-middle">
          <thead><tr><th>Product</th><th>Category</th><th>Price</th><th>Stock</th><th>Status</th><th /></tr></thead>
          <tbody>{products.map((product) => <tr key={product.id}>
            <td><strong>{product.name}</strong><small>{product.brand}</small></td>
            <td>{product.categoryName ?? product.category}</td><td>${Number(product.price ?? 0).toFixed(2)}</td>
            <td>{product.stock ?? 0}</td><td><span className="status-pill">{product.isActive ? "Active" : "Hidden"}</span></td>
            <td className="text-end">
              <button className="btn btn-sm btn-outline-success me-2" onClick={() => { setSelectedImage(null); setForm({ ...product }); }}>Edit</button>
              <button className="btn btn-sm btn-outline-danger" onClick={async () => {
                if (window.confirm(`Delete ${product.name}?`)) {
                  try { await deleteDoc(doc(db, "products", product.id)); } catch (reason) { setError(reason.message); }
                }
              }}>Delete</button>
            </td>
          </tr>)}</tbody>
        </table></div>
      </section>}

      {page === "Orders" && <section className="content-card">
        <div className="section-heading">
          <div><span className="eyebrow">FULFILMENT</span><h3>Orders</h3></div>
          <span className="chart-caption">{orders.length} total orders</span>
        </div>
        <OrderTable orders={orders} onUpdate={updateOrder} onSelectOrder={setSelectedOrder} />
      </section>}

      {page === "Customers" && <section className="content-card">
        <div className="section-heading"><div><span className="eyebrow">COMMUNITY</span><h3>Customers</h3></div><span className="chart-caption">{users.length} accounts</span></div>
        <div className="table-responsive"><table className="table"><thead><tr><th>Name</th><th>Email</th><th>Account</th><th>Orders</th></tr></thead>
          <tbody>{users.map((customer) => <tr key={customer.id}><td><strong>{customer.name ?? "Customer"}</strong></td><td>{customer.email ?? "—"}</td><td><span className={`status-pill ${customer.isActive === false ? "status-pill-inactive" : ""}`}>{customer.isActive === false ? "Disabled" : "Active"}</span></td><td>{orders.filter(order=>order.userId===customer.id).length}</td></tr>)}</tbody></table></div>
        {!users.length && <p className="empty-note">Customer accounts will appear here when users register.</p>}
      </section>}

      {page === "Support" && <section className="content-card">
        <div className="section-heading"><div><span className="eyebrow">CUSTOMER CARE</span><h3>Support requests</h3></div><span className="chart-caption">{tickets.filter(ticket=>ticket.status!=="resolved").length} open</span></div>
        <div className="table-responsive"><table className="table align-middle"><thead><tr><th>Customer</th><th>Message</th><th>Submitted</th><th>Status</th><th>Update</th></tr></thead><tbody>{tickets.map(ticket=><tr key={ticket.id}><td>{ticket.email || ticket.userId || "Customer"}</td><td className="ticket-message">{ticket.message}</td><td>{ticket.createdAt?.toDate?.().toLocaleDateString() ?? "—"}</td><td><span className="status-pill">{ticket.status || "open"}</span></td><td><select className="form-select form-select-sm" value={ticket.status || "open"} onChange={async event=>{try{await updateDoc(doc(db,"supportTickets",ticket.id),{status:event.target.value,updatedAt:serverTimestamp()});setError("");}catch(reason){setError(reason.message);}}}><option value="open">Open</option><option value="in_progress">In progress</option><option value="resolved">Resolved</option></select></td></tr>)}</tbody></table></div>
        {!tickets.length && <p className="empty-note">No support requests yet.</p>}
      </section>}

    </main>

    {/* Section 13: Product Transparent Top-Level Overlay */}
    {form && (
      <div className="admin-overlay-backdrop" onClick={closeProductForm}>
        <div className="admin-overlay-card" onClick={(e) => e.stopPropagation()}>
          <div className="admin-overlay-header">
            <h4>{form.id ? "Edit Product" : "New Luxury Product"}</h4>
            <button type="button" className="admin-overlay-close" aria-label="Close" onClick={closeProductForm}>✕</button>
          </div>
          <div className="admin-overlay-body">
            <form onSubmit={saveProduct}>
              {error && <div className="alert alert-danger" role="alert">{error}</div>}
              <div className="form-grid">
                {["name", "brand"].map((key) =>
                  <label className="form-label" key={key}>{key}
                    <input className="form-control" name={key} defaultValue={form[key] ?? ""} required={key === "name"} autoFocus={key === "name"} /></label>)}
                <label className="form-label">Category
                  <select className="form-select" name="categoryName" defaultValue={form.categoryName ?? form.category ?? ""} required>
                    <option value="" disabled>Select a category</option>
                    {categories.filter((category) => category.isActive || category.name === (form.categoryName ?? form.category))
                      .map((category) => <option key={category.id} value={category.name}>{category.name}</option>)}
                  </select>
                </label>
                <label className="form-label">Product image
                  <input className="form-control" name="image" type="file" accept="image/*"
                    required={!form.imageUrl} disabled={savingProduct}
                    onChange={(event) => {
                      const image = event.target.files?.[0] ?? null;
                      if (image && !image.type.startsWith("image/")) {
                        setError("Choose a valid image file.");
                        event.target.value = "";
                        return;
                      }
                      setSelectedImage(image);
                      setError("");
                    }} />
                  <small className="text-muted">Image Cloudinary par Save product dabane par upload hogi.</small>
                </label>
                <label className="form-label">Price ($)<input className="form-control" name="price" type="number" min="0" step="0.01" defaultValue={form.price ?? ""} required /></label>
                <label className="form-label">Stock<input className="form-control" name="stock" type="number" min="0" step="1" defaultValue={form.stock ?? ""} required /></label>
              </div>
              {(selectedImagePreview || form.imageUrl) && <div className="product-image-preview">
                <img src={selectedImagePreview || form.imageUrl} alt="Product preview" />
                <span>{selectedImage ? selectedImage.name : "Current product image"}</span>
              </div>}
              <label className="form-label w-100 mt-2">Description<textarea className="form-control" name="description" rows={3} defaultValue={form.description ?? ""} /></label>
              <label className="form-check my-3"><input className="form-check-input" type="checkbox" name="isActive" defaultChecked={form.isActive ?? true} /> Active (visible to customers)</label>
              <div className="d-flex justify-content-end gap-2 pt-2">
                <button type="button" className="btn btn-outline-secondary" onClick={closeProductForm} disabled={savingProduct}>Cancel</button>
                <button type="submit" className="btn btn-green" disabled={savingProduct}>{savingProduct ? "Uploading & saving..." : "Save product"}</button>
              </div>
            </form>
          </div>
        </div>
      </div>
    )}

    {/* Section 13: Category Transparent Top-Level Overlay */}
    {categoryForm && (
      <div className="admin-overlay-backdrop" onClick={() => setCategoryForm(null)}>
        <div className="admin-overlay-card" style={{ maxWidth: 500 }} onClick={(e) => e.stopPropagation()}>
          <div className="admin-overlay-header">
            <h4>{categoryForm.id ? "Edit Category" : "New Category"}</h4>
            <button type="button" className="admin-overlay-close" aria-label="Close" onClick={() => setCategoryForm(null)}>✕</button>
          </div>
          <div className="admin-overlay-body">
            <form onSubmit={saveCategory}>
              <label className="form-label w-100">Category name
                <input className="form-control" name="name" maxLength={60} defaultValue={categoryForm.name ?? ""} required autoFocus />
              </label>
              <label className="form-check my-3">
                <input className="form-check-input" type="checkbox" name="isActive" defaultChecked={categoryForm.isActive ?? true} />
                Active (visible to customers)
              </label>
              <div className="d-flex justify-content-end gap-2 pt-2">
                <button type="button" className="btn btn-outline-secondary" onClick={() => setCategoryForm(null)}>Cancel</button>
                <button type="submit" className="btn btn-green">Save category</button>
              </div>
            </form>
          </div>
        </div>
      </div>
    )}

    {/* Section 14: Order Transparent Top-Level Overlay */}
    {selectedOrder && (
      <div className="admin-overlay-backdrop" onClick={() => setSelectedOrder(null)}>
        <div className="admin-overlay-card" style={{ maxWidth: 680 }} onClick={(e) => e.stopPropagation()}>
          <div className="admin-overlay-header">
            <div>
              <span style={{ fontSize: 11, color: "var(--gold)", letterSpacing: "1px", textTransform: "uppercase", display: "block" }}>Order Details</span>
              <h4>#{selectedOrder.id.slice(0, 8).toUpperCase()}</h4>
            </div>
            <button type="button" className="admin-overlay-close" aria-label="Close" onClick={() => setSelectedOrder(null)}>✕</button>
          </div>
          <div className="admin-overlay-body">
            <div className="row g-3 mb-3">
              <div className="col-sm-6">
                <label className="form-label" style={{ fontSize: 11 }}>Customer</label>
                <div><strong>{selectedOrder.deliveryDetails?.fullName ?? selectedOrder.userId?.slice(0, 12) ?? "Customer"}</strong></div>
                {selectedOrder.deliveryDetails?.phone && <div style={{ fontSize: 13, color: "var(--muted)" }}>📞 {selectedOrder.deliveryDetails.phone}</div>}
              </div>
              <div className="col-sm-6">
                <label className="form-label" style={{ fontSize: 11 }}>Order Date</label>
                <div style={{ fontSize: 14 }}>{asDate(selectedOrder.createdAt)?.toLocaleString() ?? "—"}</div>
                <div className="mt-1">
                  <span className="status-pill">{selectedOrder.status ?? "pending"}</span>
                </div>
              </div>
              {selectedOrder.address && (
                <div className="col-12">
                  <label className="form-label" style={{ fontSize: 11 }}>Delivery Address</label>
                  <div style={{ fontSize: 13, color: "var(--midnight)", background: "var(--warm-beige)", padding: 10, borderRadius: 8 }}>
                    {selectedOrder.address}
                    {selectedOrder.deliveryDetails?.deliveryInstructions && (
                      <div style={{ marginTop: 4, fontStyle: "italic", color: "var(--muted)" }}>
                        Note: {selectedOrder.deliveryDetails.deliveryInstructions}
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>

            <label className="form-label" style={{ fontSize: 11 }}>Items Ordered</label>
            <div className="table-responsive mb-3">
              <table className="table align-middle">
                <thead>
                  <tr><th>Product</th><th>Qty</th><th>Price</th><th>Total</th></tr>
                </thead>
                <tbody>
                  {(selectedOrder.items ?? []).map((item, idx) => (
                    <tr key={idx}>
                      <td><strong>{item.name || "Product"}</strong></td>
                      <td>{item.quantity ?? 1}</td>
                      <td>${Number(item.unitPrice ?? 0).toFixed(2)}</td>
                      <td><strong>${Number(item.lineTotal ?? ((item.unitPrice ?? 0) * (item.quantity ?? 1))).toFixed(2)}</strong></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="d-flex justify-content-between align-items-center p-3 mb-3" style={{ background: "var(--warm-beige)", borderRadius: 12 }}>
              <span style={{ fontWeight: 700, color: "var(--midnight)" }}>Grand Total</span>
              <span style={{ fontSize: 20, fontWeight: 800, color: "var(--midnight)" }}>${Number(selectedOrder.total ?? 0).toFixed(2)}</span>
            </div>

            <div className="d-flex align-items-center justify-content-between gap-3 pt-2 border-top">
              <div className="d-flex align-items-center gap-2">
                <label className="form-label mb-0" style={{ whiteSpace: "nowrap" }}>Update Status:</label>
                <select
                  className="form-select form-select-sm"
                  style={{ width: "auto" }}
                  value=""
                  onChange={(e) => {
                    if (e.target.value) updateOrder(selectedOrder, e.target.value);
                  }}
                >
                  <option value="">Choose new status...</option>
                  {(transitions[selectedOrder.status] ?? []).map((status) => (
                    <option key={status} value={status}>{status.replaceAll("_", " ")}</option>
                  ))}
                </select>
              </div>
              <button type="button" className="btn btn-outline-secondary" onClick={() => setSelectedOrder(null)}>Close</button>
            </div>
          </div>
        </div>
      </div>
    )}
  </div>;
}

function Stat({ icon, label, value, note }) {
  return <article className="stat-card"><span className="stat-icon" aria-hidden="true">{icon}</span>
    <span>{label}</span><strong>{value}</strong>{note && <small className="stat-note">{note}</small>}
  </article>;
}

function asDate(value) {
  if (!value) return null;
  const date = value?.toDate ? value.toDate() : new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}
function startOfDay(date) { const copy = new Date(date); copy.setHours(0,0,0,0); return copy; }
function buildRevenueSeries(orders, range) {
  const count = range === "7d" ? 7 : range === "30d" ? 10 : range === "6m" ? 6 : 12;
  const now = new Date();
  const buckets = Array.from({length:count}, (_, index) => {
    const date = new Date(now);
    if (range === "7d" || range === "30d") date.setDate(date.getDate() - (count - 1 - index) * (range === "30d" ? 3 : 1));
    else date.setMonth(date.getMonth() - (count - 1 - index));
    return { date, label: range === "7d" || range === "30d" ? date.toLocaleDateString(undefined,{month:"short",day:"numeric"}) : date.toLocaleDateString(undefined,{month:"short"}), value:0 };
  });
  orders.forEach((order) => {
    const date = asDate(order.createdAt); if (!date) return;
    const bucket = buckets.find((item) => {
      if (range === "7d") return date.toDateString() === item.date.toDateString();
      if (range === "30d") { const end = new Date(item.date); end.setDate(end.getDate()+3); return date >= startOfDay(item.date) && date < end; }
      return date.getMonth() === item.date.getMonth() && date.getFullYear() === item.date.getFullYear();
    });
    if (bucket) bucket.value += Number(order.total ?? 0);
  });
  return buckets;
}
function buildCategorySales(orders, products) {
  const categoryById = new Map(products.map(product => [product.id, product.categoryName || product.category || "Other"]));
  const totals = new Map();
  orders.forEach(order => (order.items || []).forEach(item => {
    const category = categoryById.get(item.productId) || item.categoryName || "Other";
    totals.set(category, (totals.get(category) || 0) + Number(item.lineTotal ?? (Number(item.unitPrice || 0) * Number(item.quantity || 0))));
  }));
  return [...totals.entries()].map(([name,value])=>({name,value})).sort((a,b)=>b.value-a.value).slice(0,6);
}
function buildTopProducts(orders) {
  const totals = new Map();
  orders.forEach(order => (order.items || []).forEach(item => {
    const name = item.name || "Product"; const current = totals.get(name) || {name,quantity:0,revenue:0};
    current.quantity += Number(item.quantity || 0); current.revenue += Number(item.lineTotal ?? (Number(item.unitPrice || 0) * Number(item.quantity || 0))); totals.set(name,current);
  }));
  return [...totals.values()].sort((a,b)=>b.quantity-a.quantity).slice(0,5);
}
function RevenueChart({data}) {
  const max = Math.max(1,...data.map(item=>item.value)); const width=680, height=230, pad=30;
  const points=data.map((item,index)=>({x:pad+(index*(width-pad*2))/Math.max(1,data.length-1),y:height-pad-(item.value/max)*(height-pad*2)}));
  const path=points.map((point,index)=>`${index?"L":"M"}${point.x},${point.y}`).join(" ");
  const area=`${path} L ${points.at(-1)?.x||width-pad},${height-pad} L ${points[0]?.x||pad},${height-pad} Z`;
  if (!data.some(item=>item.value>0)) return <div className="chart-empty"><span>⌁</span><strong>No sales data for this period yet</strong><small>New orders will appear here automatically.</small></div>;
  return <div className="line-chart-wrap"><svg className="line-chart" viewBox={`0 0 ${width} ${height}`} role="img" aria-label="Revenue trend chart"><defs><linearGradient id="revenueFill" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stopColor="#26364A" stopOpacity=".22"/><stop offset="100%" stopColor="#26364A" stopOpacity="0"/></linearGradient></defs>{[0,1,2,3].map(i=><line key={i} x1={pad} x2={width-pad} y1={pad+i*(height-pad*2)/3} y2={pad+i*(height-pad*2)/3} stroke="#E5DFD0" strokeDasharray="4 6"/>)}<path d={area} fill="url(#revenueFill)"/><path d={path} fill="none" stroke="#C5A46D" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>{points.map((point,i)=><g key={i}><circle cx={point.x} cy={point.y} r="5" fill="#F7F5EF" stroke="#C5A46D" strokeWidth="3"/><title>{data[i].label}: ${data[i].value.toFixed(2)}</title></g>)}</svg><div className="chart-labels">{data.map((item,i)=><span key={i}>{item.label}</span>)}</div></div>;
}
function StatusChart({data}) {
  // Brand palette strictly: Gold, Navy, Midnight, Warm Beige, Muted Navy
  const colors={
    pending:"#C5A46D",
    confirmed:"#26364A",
    processing:"#172333",
    shipped:"#C5A46D",
    out_for_delivery:"#E5DFD0",
    delivered:"#172333",
    cancelled:"#5E6E80"
  };
  const total=data.reduce((sum,item)=>sum+item.count,0); let offset=0;
  return <><div className="donut-area"><svg viewBox="0 0 160 160" className="donut-chart"><circle cx="80" cy="80" r="59" fill="none" stroke="#E5DFD0" strokeWidth="17"/>{total>0&&data.filter(x=>x.count).map(item=>{const length=item.count/total*370;const circle=<circle key={item.status} cx="80" cy="80" r="59" fill="none" stroke={colors[item.status]||"#C5A46D"} strokeWidth="17" strokeDasharray={`${length} ${370-length}`} strokeDashoffset={-offset} transform="rotate(-90 80 80)" strokeLinecap="round"/>;offset+=length;return circle;})}<text x="80" y="76" textAnchor="middle" className="donut-total">{total}</text><text x="80" y="96" textAnchor="middle" className="donut-sub">ORDERS</text></svg></div><div className="status-legend">{data.map(item=><div key={item.status}><span><i style={{background:colors[item.status]||"#C5A46D"}}/>{item.status.replaceAll("_"," ")}</span><strong>{item.count}</strong></div>)}</div></>;
}
function TopProducts({items}) { return items.length ? <div className="rank-list">{items.map((item,index)=><div className="rank-row" key={item.name}><span className="rank-number">0{index+1}</span><div className="rank-info"><strong>{item.name}</strong><small>{item.quantity} units sold</small></div><b>${item.revenue.toFixed(2)}</b></div>)}</div> : <div className="chart-empty compact"><strong>No product sales yet</strong><small>Product performance appears after orders are placed.</small></div>; }
function StockWatch({products}) { const low=products.filter(p=>Number(p.stock)<6).sort((a,b)=>Number(a.stock)-Number(b.stock)).slice(0,5); return low.length ? <div className="stock-list">{low.map(p=><div className="stock-row" key={p.id}><div><strong>{p.name}</strong><small>{p.categoryName||p.category||"Uncategorized"}</small></div><span className="stock-count">{Number(p.stock)} left</span></div>)}</div> : <div className="chart-empty compact"><strong>Inventory looks healthy</strong><small>No products are below the 6-unit threshold.</small></div>; }
function CategoryPerformance({items}) { const max=Math.max(1,...items.map(item=>item.value)); return items.length ? <div className="category-bars">{items.map(item=><div className="category-bar-row" key={item.name}><div><span>{item.name}</span><strong>${item.value.toFixed(2)}</strong></div><div className="category-track"><i style={{width:`${item.value/max*100}%`}}/></div></div>)}</div> : <div className="chart-empty compact"><strong>No category sales yet</strong><small>Category performance is calculated from order line items.</small></div>; }

function OrderTable({ orders, onUpdate, onSelectOrder }) {
  return <div className="table-responsive"><table className="table align-middle">
    <thead><tr><th>Order</th><th>Customer</th><th>Date</th><th>Total</th><th>Status</th><th>Update</th><th>Details</th></tr></thead>
    <tbody>{orders.length ? orders.map((order) => <React.Fragment key={order.id}>
      <tr>
      <td><strong>#{order.id.slice(0, 8).toUpperCase()}</strong></td>
      <td>
        <strong>{order.deliveryDetails?.fullName ?? order.userId?.slice(0, 10) ?? "—"}</strong>
        {order.deliveryDetails?.phone && <small>{order.deliveryDetails.phone}</small>}
      </td>
      <td>{asDate(order.createdAt)?.toLocaleDateString() ?? "—"}</td>
      <td><strong>${Number(order.total ?? 0).toFixed(2)}</strong></td>
      <td><span className="status-pill">{order.status ?? "pending"}</span></td>
      <td>
        <select className="form-select form-select-sm" value="" onChange={(event) => onUpdate(order, event.target.value)}>
          <option value="">Change status</option>
          {(transitions[order.status] ?? []).map((status) => <option key={status} value={status}>{status.replaceAll("_", " ")}</option>)}
        </select>
      </td>
      <td>
        <button
          type="button"
          className="btn btn-sm btn-outline-success"
          style={{ whiteSpace: "nowrap" }}
          onClick={() => onSelectOrder && onSelectOrder(order)}
        >
          View details
        </button>
      </td>
      </tr>
      <tr><td colSpan={7} className="small text-muted">
        {(order.items ?? []).length
          ? order.items.map((item) => `${item.name || "Product"} × ${item.quantity ?? 0} · $${Number(item.lineTotal ?? (Number(item.unitPrice ?? 0) * Number(item.quantity ?? 0))).toFixed(2)}`).join("  |  ")
          : "No item details recorded"}
        {order.deliveryDetails?.deliveryInstructions && <span> · Note: {order.deliveryDetails.deliveryInstructions}</span>}
      </td></tr>
    </React.Fragment>) : <tr><td colSpan={7} className="empty-note">No orders have been placed yet.</td></tr>}</tbody>
  </table></div>;
}
