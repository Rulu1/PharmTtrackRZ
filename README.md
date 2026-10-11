# PharmaTrack

A web-based mobile app for a **Level 5 hospital** pharmacy to trace and track essential
medicines and surgical products — batch by batch, from receipt to dispensing.

- Staff use individual email/password accounts; passwords are stored as bcrypt hashes and
  sessions are stored in the shared database.
- Google sign-in is optional. Administrators control account creation, approval, suspension,
  and roles.
- Stock is tracked at the **batch/lot level** (batch number, supplier, expiry date), so every
  unit can be traced from the moment it's received to the moment it's dispensed, transferred,
  adjusted, or discarded.
- Scoped to a single hospital's pharmacy store — there's no multi-tenant/hospital-switching
  concept, by design.

## Roles

| Role | Can do |
|---|---|
| **Admin** | Everything below, plus manage users (create, approve, reject, suspend, change role) |
| **Pharmacist** | Add products, receive batches, record dispense/transfer/adjustment/disposal |
| **Store manager** | Same stock permissions as Pharmacist |
| **Viewer** | Read-only — browse inventory, see traceability, no changes |

## Project structure

```
pharmatrack/
  backend/    Node.js + Express + Prisma API, password/optional Google auth, shared sessions
  frontend/   React (Vite) mobile-first web app, installable as a PWA
```

## Running it locally

### Run for computers on the same workplace network

```powershell
cd backend
npm install
Copy-Item .env.example .env
npx prisma generate
npx prisma db push
npm run seed
npm run create-admin
npm run dev
```

Set a long random `SESSION_SECRET` in `backend/.env` before starting. Keep `backend/prisma/dev.db`
and the server on this host computer; other computers must connect through the app, not open
the database file.
Set `FRONTEND_URL` and include the host's `http://HOST-IP:5173` address in `FRONTEND_ORIGINS`
in `backend/.env` (keep the localhost entries for using the host itself). Update those values
if the host computer's IP address changes.

```powershell
cd frontend
npm install
npm run dev
```

On the host computer, find its workplace IPv4 address with `ipconfig`. On each other computer
connected to the same trusted workplace network, open `http://HOST-IP:5173` (replace `HOST-IP`
with the host's IPv4 address). Keep both server processes running on the host. If Windows
Firewall prompts, allow Node.js on the **Private/work** network only. Do not expose these
development servers to the public internet.

`npm run create-admin` creates the initial administrator using an interactive email and password
prompt. Users can create accounts on the login page; new accounts remain pending until an admin
approves them and assigns a role. An admin can also create accounts and issue/reset passwords
from the Users tab. Users sign in with their individual email/password and can sign out from the
app header. The session store and inventory database both live on the host, so users share the
same live inventory while having separate login sessions.

### Approval email notifications

New account requests are sent to `APPROVAL_ADMIN_EMAIL` when SMTP is configured. The provided
Gmail settings use `smtp.gmail.com` on port `465`; set `SMTP_USER` and `SMTP_FROM` to the sending
mailbox and `SMTP_PASSWORD` to a Google app password (not the account password). Google requires
2-Step Verification before creating an app password. Keep the app password private in
`backend/.env` and never commit it. Until SMTP is configured successfully, sign-ups still work
and remain pending, but the app will tell the new user the notification was not sent and log the
delivery failure on the server.

This HTTP setup is only for a trusted internal preview. Do not enter real patient or sensitive
work data until the app is deployed behind HTTPS with a certificate trusted by staff computers.
Do not expose the Vite development server or API directly to the public internet.

## Optional Google sign-in

Google sign-in can additionally be enabled with a real OAuth client. Configure
`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, and `GOOGLE_CALLBACK_URL` in `backend/.env`.
For multiple computers, use a registered HTTPS callback/domain; localhost OAuth callbacks do
not work from other machines. Password sign-in is available without Google OAuth.

## Going to production

- **Database:** the schema defaults to SQLite for zero-setup local development. For
  production, open `backend/prisma/schema.prisma`, switch `provider` to `"postgresql"`
  or `"mysql"`, and set `DATABASE_URL` to a real connection string (e.g. from Railway,
  Render, Supabase, Supabase Postgres, or your hospital's own server). Then re-run
  `npx prisma migrate dev`.
- **Hosting:** deploy `backend/` anywhere that runs Node (Render, Railway, Fly.io, an on-prem
  server). Deploy `frontend/` as a static build (`npm run build` → `dist/`) on Netlify,
  Vercel, or the same server. Set `FRONTEND_URL` (backend) and `VITE_API_BASE` (frontend, as
  an env var at build time) to each other's real URLs.
- **Cookies:** in production, `NODE_ENV=production` makes session cookies `secure`, so the
  backend must be served over HTTPS.
- **Secrets:** generate a long random `SESSION_SECRET` (e.g. `openssl rand -hex 32`) — don't
  reuse the placeholder.

## What's built vs. what's next

Built: individual staff sign-up/sign-in with admin approval, role-based access, optional Google
sign-in, product catalog (medicines + surgical items), batch receiving, full traceability trail
per batch, dispense/transfer/adjust/dispose transactions, low-stock and expiring-soon dashboard,
admin user management, QR-code batch labels with camera-based scanning.

### QR/barcode scanning

- Every batch's trace page (`/batches/:id`) shows a QR code (and a **Print label** button)
  encoding a link straight to that batch's history — print it and stick it on the shelf or
  the physical stock card. Because it encodes a normal URL, *any* phone camera can scan it,
  not just this app.
- A **Scan** tab opens the device camera, reads a batch's QR label, and jumps straight to its
  trace page — handy for a quick "what is this and where did it come from" lookup at the
  shelf.
- On the **Record transaction** screen, "Scan batch label instead" lets staff scan a batch
  directly instead of typing the product name, then pre-fills the product and batch picker.
- Scanning needs camera access, which browsers only grant over **HTTPS** (or `localhost` in
  dev) — make sure your production deployment is served over HTTPS.

Natural next steps if you want to keep going: email notifications for expiring stock,
exporting reports (CSV/PDF), multi-department stock locations, and a supplier/purchase-order
module.
