MZUGOSS LIBRARY SYSTEM — INSTALLABLE WEBSITE PACKAGE

FILES
- index.html: app interface
- manifest.webmanifest: app name/icons/display settings
- service-worker.js: offline/PWA support
- icons/: app icons
- robots.txt: permits search engines to crawl the site

IMPORTANT: INSTALLATION
A downloaded HTML file opened directly from your computer (file://) cannot be installed as a proper PWA. Publish the complete package to a public HTTPS website first. The Install on this device button will call the browser's installation prompt when the browser makes that prompt available. Browsers require the user's confirmation; a website cannot silently force-install itself.

PUBLISH (NETLIFY EXAMPLE)
1. Extract the ZIP file to a folder.
2. Open https://app.netlify.com/ and sign in or create an account.
3. Choose Add new site / Deploy manually (wording may vary).
4. Drag the extracted folder containing index.html, manifest.webmanifest, service-worker.js, icons/, and robots.txt into the deployment area. Upload the folder contents as a site, not the ZIP file if the screen asks for a folder.
5. Wait for Netlify to provide a public HTTPS URL. Open that URL on the phone/computer and test the Install on this device button.
6. For changes, deploy the updated folder again.

MAKE IT APPEAR IN GOOGLE SEARCH
Google lists public web pages, not private local HTML files, and it does not automatically publish a download just because an app is named.
1. Publish the app using the steps above and keep the public HTTPS URL.
2. Open Google Search Console: https://search.google.com/search-console/
3. Add your site using the exact deployed URL (or a custom domain), then verify ownership using one of the offered methods.
4. In Search Console, use URL Inspection, enter the app's public URL, and choose Request Indexing.
5. Wait for Google to crawl and index it. This can take days or longer and is not guaranteed.
6. Search-result wording is chosen by Google and cannot be forced. The page title/description are set to identify the MZUGOSS Library System, but Google may rewrite them.
7. Share the public link with the school community. If you later use a custom domain, update the Search Console property and add a sitemap that uses that domain.

A useful search phrase to try after indexing is: MZUGOSS Library System Mzuzu Government Secondary School. A Google result can link to the app page; it will not automatically download/install the app just from the search result.

SECURITY / LIMITS
- Do not put Supabase service-role keys in browser HTML.
- Installation requires a supported browser, a secure HTTPS origin (localhost for development), valid manifest/icons/service worker, and user confirmation.
- This package has had inline JavaScript syntax checks; that is not the same as a full browser, hosting, or live Supabase test.
