Blog Forum App

A simple Blog/Forum app built with Flutter, Provider (state management),
  go_router (routing), and Supabase (auth, database, image storage).

Features

-   Authentication  : register (email + password, no confirm field), login, logout
-   Posts  : public paginated listing with image previews (visible while logged out),
  create/view/update/delete, image add & delete
-   Comments  : full CRUD on each post, with image add & delete

A. Set up Supabase

1. Create a project at [supabase.com](https://supabase.com).
2. Open   SQL Editor   and run `supabase/schema.sql` from this repo. It creates:
   - `profiles`, `posts`, `comments` tables with Row Level Security
   - a trigger that auto-creates a profile row on signup
   - `post-images` and `comment-images` public storage buckets with per-user policies
3. Go to   Project Settings → API   and copy your   Project URL   and   anon public key  .

B. Configure the app

Open `lib/core/supabase_config.dart` and fill in:

static const String url = 'https://YOUR_PROJECT_REF.supabase.co';
static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';


C. Install & run

flutter pub get
flutter run


Project structure

lib/
  core/            theme, Supabase config
  models/          PostModel, CommentModel
  services/        thin wrappers over Supabase (auth, posts, comments, storage)
  providers/       ChangeNotifier state (AuthProvider, PostProvider, CommentProvider)
  router/          go_router config with auth-aware redirects
  screens/
    auth/          login, register
    home/          public post listing (pagination)
    post/          post detail (+ comments), create/edit form
  widgets/         PostCard, CommentCard, ImagePickerField, etc.
supabase/
  schema.sql       tables, RLS policies, triggers, storage buckets

Notes on the implementation

-   Pagination  : `PostService.fetchPosts` uses Supabase's `.range()` for
  offset pagination (page size 8), with infinite-scroll loading in
  `PostListScreen`.
-   Public read, owner write  : RLS policies let anyone `select` posts and
  comments (so the feed works logged-out), but only the authenticated
  owner can insert/update/delete their own rows — enforced both by RLS and
  by storage policies keyed on `auth.uid()` matching the uploaded file's
  folder (`<user_id>/<file>.<ext>`).
-   Image add/delete  : `StorageService` uploads to a per-user folder and
  derives the storage path back out of a public URL to delete it. Both
  `PostProvider` and `CommentProvider` clean up the old image in storage
  whenever a post/comment's image is replaced or removed, and when the
  post/comment itself is deleted.
-   Routing guards  : `/post/new` and any `/edit` route redirect to
  `/login` if the user isn't authenticated; the listing and post detail
  routes stay open to everyone.
