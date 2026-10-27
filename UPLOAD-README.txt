MZUGOSS LIBRARY SYSTEM — UPLOAD PACKAGE

WHAT IS INCLUDED
- index.html: current app page and install banner
- manifest.webmanifest, service-worker.js, icons/: PWA install support
- robots.txt: allows search-engine crawling
- SUPABASE_SQL/: SQL setup, staff-role assignment, and read-only verification scripts

A. UPLOAD THE WEBSITE
1. Extract this ZIP on your computer.
2. Go to https://app.netlify.com/ and sign in.
3. Choose Add new site / Deploy manually (the wording can vary).
4. Upload or drag the extracted package folder's CONTENTS (index.html must be at the published site's root). Do not publish only the ZIP file as a normal web page.
5. Wait for Netlify to provide a public HTTPS URL. Open that URL on a phone and a computer.
6. Use the “Install on this device” button. The browser may show a confirmation prompt; installation cannot be forced without user confirmation.

B. SUPABASE DATABASE SETUP
Project URL configured in the HTML: https://kzjijmsbeaozrdfcinaf.supabase.co
The HTML contains a publishable key only. Never add a service-role/secret key to the HTML.

1. Open https://supabase.com/dashboard and select the MZUGOSS Library System project.
2. Open SQL Editor. Before running SQL, make sure the existing books, students, and profiles tables are present.
3. Open SUPABASE_SQL/MZUGOSS_Supabase_Request_Borrowing_Setup_Fixed.sql, paste the whole file into a NEW SQL query, and Run. It is additive and is intended to create/align borrowing tables without deleting catalogue data.
4. Confirm both staff accounts exist in Authentication → Users.
5. Open SUPABASE_SQL/MZUGOSS_Assign_Staff_Roles.sql, paste into a NEW query, and Run. This assigns roles for the two configured staff email addresses. If an email differs, edit the email in both the HTML and SQL before deploying.
6. Open SUPABASE_SQL/MZUGOSS_Supabase_Database_Verification.sql, paste into a NEW query, and Run. Confirm the expected borrowing tables and columns appear.
7. In the deployed app, test staff login, add one clearly labelled test book, confirm it appears on a second device, submit a student request, approve it as librarian, then return the test book. Remove test data after testing.

IMPORTANT DATABASE LIMITATION — READ BEFORE USING REAL STUDENT DATA
The current app's student sign-in is not yet connected to a per-student Supabase Auth session. Student requests use the public browser client. The included SQL protects the borrowing tables behind authenticated sessions, so student request sync may be denied until student accounts are migrated to Supabase Auth and row-level policies are configured for each student's own records. Do NOT fix this by allowing anonymous users to read all student/borrowing records; that would expose private school data. Staff login/role SQL and schema scripts do not, by themselves, prove that the live database works end-to-end.

C. GOOGLE SEARCH
1. After the site is public, open https://search.google.com/search-console/ and add/verify the published HTTPS site.
2. Use URL Inspection on the site's homepage and choose Request Indexing.
3. Wait for Google to crawl it. This may take days or longer; indexing or a specific search-result title is not guaranteed. Search results can link to the app, but do not auto-install it.

VALIDATION NOTES
The package's inline JavaScript is syntax-checked and the manifest JSON is parsed. A live Supabase connection test could not be completed in this environment, so this package is not certified as end-to-end database-tested. Before using real student information, complete the live tests above and resolve the student-authentication limitation.
