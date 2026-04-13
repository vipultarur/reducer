# Screen Feature Documentation

This document explains functional behavior for each screen in the app.
It intentionally excludes UI styling/layout details and focuses on what each screen does.

## Global Screen-Level Behavior

### Route map

- `/splash` -> `SplashScreen`
- `/login` -> `LoginScreen`
- `/register` -> `RegisterScreen`
- `/home` and `/` -> `HomeScreen`
- `/single-editor` -> `SingleImageScreen`
- `/bulk-editor` -> `BulkImageScreen`
- `/premium` -> `PremiumScreen`
- `/gallery` -> `GalleryScreen`
- `/bulk-history-detail` -> `BulkHistoryDetailScreen`
- `/exif-eraser` -> `ExifEraserScreen`
- `/settings` -> `SettingsScreen`
- `/privacy-policy` -> `PrivacyPolicyScreen`
- `/profile` -> `ProfileScreen`

### Route access rule

- Router redirect logic sends unauthenticated users to `/login` (except `/login` and `/register`).
- Logged-in users are redirected away from login/register routes to home.
- The app uses Firebase auth state for this rule.

### Ads and subscription behavior used across screens

- Ads are managed centrally by `AdManager`.
- `AdManager.isPremium` disables ad loading/showing for Pro users.
- Interstitial ads are shown before several actions (open editor flows, pick/process/export actions).
- Banner/native ads are displayed on multiple screens when the user is not Pro and consent allows ads.

### Permissions used across screens

- Camera permission: required when capturing from camera.
- Photos/storage permission: required for selecting images and saving output.
- Permission prompts and "open settings" recovery are centralized in `PermissionService`.

### Data persistence behavior used across screens

- Edit history metadata is saved locally in `SharedPreferences` (`edit_history_v2`).
- Generated files/thumbnails are stored under app documents `history/`.
- When authenticated, history add/remove operations also sync to Firestore.

## Screen-by-Screen Features

## 1) Splash Screen (`/splash`)

### Core features

- Enforces a minimum splash duration (2.5 seconds).
- Reads premium state and sets ad suppression flag (`AdManager.isPremium`).
- Initializes ad SDK flow via consent-aware `AdManager.initialize()`.
- Attempts anonymous Firebase sign-in when no current user exists.
- Navigates to `/home` after initialization.

### Side effects

- Can create an anonymous auth session.
- Can initialize/preload ads if not premium.

## 2) Login Screen (`/login`)

### Core features

- Email/password login via `AuthController.login`.
- Google Sign-In via `AuthController.signInWithGoogle`.
- Field validation for email format and password length.
- Navigation to home on successful auth.
- Navigation to register screen.
- "Continue as Guest" route action to home.

### Current limitations

- Forgot-password action is present but not implemented (`TODO`).

## 3) Register Screen (`/register`)

### Core features

- Email/password account registration via `AuthController.register`.
- Google Sign-In registration flow via `AuthController.signInWithGoogle`.
- Creates/updates user profile data in Firestore after successful registration.
- Basic form validation (name, email, password length).
- Navigation to home on success.

## 4) Home Screen (`/home`, `/`)

### Core features

- Entry hub for all tools.
- Quick tool actions:
  - Compress -> routes to single editor.
  - Convert -> routes to single editor.
- Advanced tool actions:
  - Bulk Processing -> routes to bulk editor when Pro; otherwise triggers premium upsell dialog.
  - EXIF Eraser -> routes to EXIF screen.
  - Edit History -> routes to gallery screen.
- Premium entry:
  - Pro button when user is not Pro.
- Settings entry:
  - Routes to settings screen.
- Floating action entry:
  - "New Edit" routes to single editor.

### Ads behavior

- Shows banner ad for non-Pro users.
- Most tool entries use interstitial ad wrapping.

## 5) Single Image Screen (`/single-editor`)

This screen is a full single-image workflow with three functional phases: upload, edit/process, export.

### Upload features

- Pick from gallery or camera.
- Permission-gated access for gallery/camera.
- Validates input image:
  - file size threshold
  - decode validity
  - maximum dimension constraints
- Generates working thumbnail for preview performance.
- Stores original dimensions and size metadata for downstream processing/export.

### Edit/process features

- Live preview regeneration with debouncing (`250ms`) on setting changes.
- Supported processing settings:
  - scale percent
  - rotation
  - quality
  - horizontal/vertical flip
  - output format selection
- "Process Image" generates final processed bytes through `ImageProcessor`.
- Processing flow works from in-memory bytes or file path depending on source.
- Settings changes clear stale processed output to keep export results consistent with current settings.

### Export features

- Before/after comparison using original/preview/processed image states.
- Shows output metadata (format, quality, target resolution, file size, size reduction).
- Save processed image to device gallery.
- Share processed image via platform share sheet.
- Writes history entry:
  - saves thumbnail under app docs `history/`
  - records settings, sizes, timestamp, and source reference

### Ads behavior

- Upload and process actions are wrapped by interstitial ad calls.
- Upload/export empty states include native ad placements for non-Pro users.

## 6) Bulk Image Screen (`/bulk-editor`)

### Core features

- Multi-image picker (gallery only) with permission handling.
- Applies bulk settings across selected images:
  - quality
  - scale percent
- Batch processing via streaming progress updates (`ImageProcessor.processBulkWithProgress`).
- Concurrent processing (max concurrent workers set to `3`).
- Tracks success/failure per file and computes progress percentage.

### Plan-gating behavior

- If reached by non-Pro users, selection is capped to 50 images.
- Home screen typically gates this route as Pro-only.

### Post-processing/export features

- Save all successful outputs to gallery (parallel saves).
- Export all successful outputs as ZIP:
  - ZIP is built in background isolate
  - ZIP is shared through platform share sheet
- Saves bulk session to history:
  - copies output files to app docs `history/bulk_<sessionId>/`
  - creates session thumbnail
  - stores per-session metadata (counts, sizes, settings, processed paths)

### Reliability behavior

- Uses cancellation flag to avoid updating disposed widget state during long operations.

## 7) Premium Screen (`/premium`)

### Core features

- Displays available subscription plans from store query.
- Allows plan selection.
- Starts subscription purchase for selected plan.
- Supports purchase restore.
- Handles successful and failed purchase states with user feedback.
- Auto-closes screen shortly after success message.

### Purchase lifecycle behavior (backing logic)

- Fetches product details from configured store product IDs.
- On Android, uses subscription offer token when purchasing.
- Listens to purchase stream statuses:
  - pending
  - purchased
  - restored
  - canceled
  - error
- On successful purchase/restore:
  - marks user as Pro in secure local storage
  - updates `AdManager.isPremium`
  - syncs subscription metadata to Firestore for authenticated users

### Auth dependency

- Subscribe action requires logged-in user; otherwise routes to login.

### Alternate premium states

- Already Pro state:
  - confirms premium entitlement
  - opens Play subscription management URL
- Error state:
  - retry offer-fetch operation
- No-plans state:
  - fallback when store returns zero plans

## 8) Gallery Screen (`/gallery`)

### Core features

- Loads edit history via Riverpod async controller.
- Handles all data states:
  - loading
  - error with retry
  - empty
  - populated
- Supports item deletion via swipe-to-delete.
- Supports full history clear via confirmation dialog.
- For bulk history entries, opens detailed bulk session screen.

### Current limitations

- Non-bulk history card tap currently shows "Re-edit feature coming soon".

### Storage/sync behavior via controller

- Local persistence in `SharedPreferences`.
- Background encode/decode using isolates (`compute`) for large history lists.
- Add/remove operations attempt Firestore sync when authenticated.

## 9) Bulk History Detail Screen (`/bulk-history-detail`)

### Core features

- Resolves stored processed file paths to absolute paths in app documents directory.
- Supports compatibility fallback for older absolute-path entries.
- Shows bulk session metadata:
  - item count
  - timestamp
  - output format
  - quality
  - total compression percentage
- Lists all processed images in the session and their file sizes.

## 10) EXIF Eraser Screen (`/exif-eraser`)

### Core features

- Selects one image from gallery (permission-gated).
- Removes metadata by recompressing with `keepExif: false`.
- Saves cleaned output to gallery.
- Allows replacing/removing current selected image before processing.

### Ads behavior

- Image pick and clean/save actions are wrapped by interstitial ad calls.
- Banner ad is displayed for non-Pro users.

## 11) Settings Screen (`/settings`)

### Core features

- Subscription section:
  - shows current premium status
  - routes to premium screen for upgrade/manage
- Support/feedback actions:
  - open Play Store listing
  - share app text via system share sheet
  - launch support email intent
- About section:
  - open in-app privacy policy screen
  - display app version string

## 12) Privacy Policy Screen (`/privacy-policy`)

### Core features

- Displays static policy content bundled in app code.
- Includes sections for:
  - local image processing claim
  - data collection summary
  - third-party services
  - permission usage
  - support contact
- Includes a hardcoded "Last updated" date.

## 13) Profile Screen (`/profile`)

### Core features

- Reads live user profile data from Firestore stream (`userProvider`).
- Supports logout via `AuthController.logout` and routes to login.
- Supports profile photo update workflow:
  - pick image from gallery
  - upload to Cloudinary
  - store resulting URL in Firestore user document
- Shows account-level fields sourced from user data:
  - email
  - AI image generation count
  - subscription status and optional expiry date
- Non-premium users can route to premium screen from profile.

## Known Feature Gaps and TODOs

- Login screen forgot-password action is not wired.
- Gallery single-item "re-edit" is not implemented yet.
- Route guard and splash anonymous-login flow can conflict depending on auth timing and startup state.
