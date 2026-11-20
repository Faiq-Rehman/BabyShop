# BabyShopHub

BabyShopHub is a Flutter customer storefront backed by Firebase Authentication
and Cloud Firestore. Firestore is the database; no MySQL or customer-facing
Node/Express API is used.

## What is implemented

- Guest-first storefront: the app opens directly on the home/catalog panel.
- Email/password sign-in and account creation through Firebase Authentication.
- Password reset and sign-out.
- Responsive product catalog, category browsing, and name/brand/category search.
- Firestore-backed product details, cart, wishlist, and order history.
- Stock checks when changing cart quantities.
- Cash-on-delivery checkout collects recipient name, Pakistani mobile number,
  province, city, area, street address, and optional delivery details. Orders
  are written directly to Firestore and appear in the admin panel; the cart is
  cleared when the order is submitted.
- Customer support message submission.
- Firestore security rules for customer-owned data and custom-claim administrators.

The admin app provides live Firestore views for the overview, customers,
products, categories, orders, and support requests. The overview includes
period filters, revenue trends, order-status distribution, top-selling products,
category performance, and low-stock monitoring. Category management includes
create, edit, activation, and deletion for unused categories. Product CRUD and
valid order status transitions are supported. Customer order tracking displays
the order status progression recorded by the admin. Online payment, push
notifications, review submission/moderation, customer account activation, and
advanced inventory history management are not included.
Online payment is intentionally not implemented.

## Requirements

- Flutter and Dart versions specified in `pubspec.yaml`.
- A Firebase project with Authentication (Email/Password) and Cloud Firestore.

## Configure and run

The existing Firebase project is `babyshophub-79a88`. To use another project,
run `flutterfire configure` and select the target platforms. Never commit service
account credentials.

## App logo and launcher icons

The shared app logo is `assets/images/logo.jpg`. It is shown in the customer
app and admin panel and used to generate the Android, iOS, web, Windows, and
macOS launcher icons. After replacing the image, regenerate platform icons with:

```powershell
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
```

From the `babyshop` directory:

```powershell
flutter pub get
flutter run
```

The customer sign-in screen includes an **Admin? Go to Admin Login** button.
It opens the separate admin app at `http://localhost:5173/admin` by default.
When the admin app is hosted elsewhere, set its URL when running or building
Flutter, for example:

```powershell
flutter run --dart-define=ADMIN_PANEL_URL=https://your-admin-host/admin
```

For the separate React admin app, create `admin_panel/.env` from
`admin_panel/.env.example`, fill it with the Firebase web app configuration, and
keep `VITE_ADMIN_EMAIL` set to the authorized admin account (or use an account
with the Firebase custom claim `admin: true`). In Cloudinary, create an **unsigned
upload preset** named `BabyShop`; the configured cloud name is `xbflk22h`. The
admin app uploads product images from the device using that preset and saves
Cloudinary's secure image URL in Firestore. Keep the preset restricted to image
formats and reasonable upload sizes. Then run:

```powershell
cd admin_panel
npm install
npm run dev
```

Open the admin dashboard at `http://localhost:5173/admin` (source path:
`admin_panel/`). For this college-project setup, the Firebase Authentication
account `hamzakhan13102004@gmail.com` is allowlisted as the single admin. Sign in with the
password configured for that account in Firebase Authentication; the password
is never stored in the source code. If sign-in reports `auth/invalid-credential`,
verify the account and password in Firebase Authentication, confirm the
Email/Password provider is enabled, and make sure `admin_panel/.env` uses this
app's Firebase project.

To enable the allowlist on Firebase without Google Cloud CLI:

1. In Firebase Console, open **Firestore Database → Rules**.
2. Replace the rules with the contents of this project's `firestore.rules` and
   click **Publish**.
3. Run the admin app and sign in at `http://localhost:5173/admin` with
   `hamzakhan13102004@gmail.com` and its Firebase Authentication password.

The allowlist grants admin permissions to anyone who can sign in as that
Firebase account. Use a strong, private password and do not share it. For a
production app, replace the fixed-email allowlist with a custom admin claim.
Adding or editing a product in **Products → Add product** writes to the
Firestore `products` collection; the customer app listens to that collection,
so active, in-stock products appear without a manual refresh.

In the admin sidebar, open **Categories → Add category** to create categories;
edit or deactivate them from the same page. Products use the active categories
in a dropdown. Renaming a category updates its linked products, and a category
with products cannot be deleted until those products are reassigned.

The admin app supports the Firebase Authentication custom claim `admin: true`
and the configured email allowlist. Its overview charts, categories, product
management, order status updates, and support request status updates are live
Firestore reads/writes. Revenue and category charts are calculated from actual
order documents; they show an empty state when there is no matching data.
The Firestore rules, not hidden UI controls, enforce administrator privileges.

In Firebase Console, enable **Authentication → Sign-in method → Email/Password**
and create a Cloud Firestore database.

Deploy the Firestore rules from the `babyshop` directory:

```powershell
firebase deploy --only firestore:rules
```

The first successful checkout creates the `orders` collection automatically.
Customer orders are saved with `status: pending` and
`paymentMethod: cash_on_delivery`; the admin panel reads them from Firestore.
Checkout reads current product prices and checks the available stock before
writing the order. The free client-side flow does not reserve inventory or
provide trusted server-side price validation.

Grant an existing account the administrator custom claim only from a trusted
environment with Firebase Admin credentials configured through Application
Default Credentials:

```powershell
cd functions
npm install
node scripts/set-admin.js admin@example.com
```

Do not expose a service account key or the admin script through a client app.
After a claim changes, the user must refresh their ID token (sign out/in) for the
new claim to appear.

## Firestore data shape

Create product documents in `products` with fields such as:

```json
{
  "name": "Organic cotton onesie",
  "brand": "Little Sprout",
  "categoryName": "Clothing",
  "description": "Soft everyday cotton clothing.",
  "imageUrl": "https://example.com/onesie.jpg",
  "price": 18.5,
  "stock": 12,
  "isActive": true
}
```

Create active category documents in `categories` with `name` and `isActive`.
Customer-specific cart and wishlist documents are stored beneath
`users/{uid}/cart/{productId}` and `users/{uid}/wishlist/{productId}`. Orders,
inventory history, support tickets, and reviews are stored in their respective
root collections. Customer checkout writes orders to the `orders` collection.

To insert example categories and products into a new/empty store, use trusted
Firebase Admin credentials with Application Default Credentials:

```powershell
cd functions
npm install
node scripts/seed-store.js
```

The seed script refuses to overwrite any existing seed document.

## Validate

```powershell
flutter analyze
flutter test
```

Firebase-backed flows require an initialized Firebase project and are not
emulated by the local unit tests.


## Responsive layouts and analytics

The Flutter customer storefront uses bottom navigation on phone/tablet layouts
and an adaptive navigation rail on wide browser and desktop layouts. The content
area is constrained on wide displays to keep reading widths comfortable. The
React admin dashboard uses a collapsible mobile sidebar and responsive analytics
cards. Dashboard graphs are generated from live Firestore order and product
records; no sample chart data is embedded in the admin UI.

The project includes Flutter targets for Android, iOS, web, Windows, and macOS
where the required platform toolchains and Firebase configuration are available.
Builds still need to be run on the target operating systems before release.
