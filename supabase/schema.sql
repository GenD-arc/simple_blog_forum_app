-- ============================================================
-- Blog / Forum app — Supabase schema
-- Run this in the Supabase SQL editor (Project -> SQL Editor).
-- ============================================================

-- ---------- Extensions ----------
create extension if not exists "pgcrypto";

-- ---------- Tables ----------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  content text not null,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists posts_created_at_idx on public.posts (created_at desc);
create index if not exists comments_post_id_idx on public.comments (post_id);

-- ---------- Auto-create a profile on signup ----------
-- Reads the `username` passed in via `data:` on signUp(); falls back to
-- the email prefix if it's missing.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------- Row Level Security ----------

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;

-- Profiles: readable by everyone, writable only by the owner.
create policy "Profiles are publicly readable"
  on public.profiles for select
  using (true);

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Posts: readable by everyone (including logged-out visitors),
-- writable only by the author.
create policy "Posts are publicly readable"
  on public.posts for select
  using (true);

create policy "Authenticated users can create posts"
  on public.posts for insert
  with check (auth.uid() = user_id);

create policy "Owners can update their posts"
  on public.posts for update
  using (auth.uid() = user_id);

create policy "Owners can delete their posts"
  on public.posts for delete
  using (auth.uid() = user_id);

-- Comments: readable by everyone, writable only by the author.
create policy "Comments are publicly readable"
  on public.comments for select
  using (true);

create policy "Authenticated users can create comments"
  on public.comments for insert
  with check (auth.uid() = user_id);

create policy "Owners can update their comments"
  on public.comments for update
  using (auth.uid() = user_id);

create policy "Owners can delete their comments"
  on public.comments for delete
  using (auth.uid() = user_id);

-- ---------- Storage buckets ----------
-- Public read (so images display for logged-out visitors too);
-- writes/deletes restricted to the authenticated owner's own folder
-- (files are uploaded to `<user_id>/<uuid>.<ext>` by the app).

insert into storage.buckets (id, name, public)
values ('post-images', 'post-images', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('comment-images', 'comment-images', true)
on conflict (id) do nothing;

create policy "Public read access to post images"
  on storage.objects for select
  using (bucket_id = 'post-images');

create policy "Users can upload their own post images"
  on storage.objects for insert
  with check (
    bucket_id = 'post-images'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete their own post images"
  on storage.objects for delete
  using (
    bucket_id = 'post-images'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Public read access to comment images"
  on storage.objects for select
  using (bucket_id = 'comment-images');

create policy "Users can upload their own comment images"
  on storage.objects for insert
  with check (
    bucket_id = 'comment-images'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete their own comment images"
  on storage.objects for delete
  using (
    bucket_id = 'comment-images'
    and auth.uid()::text = (storage.foldername(name))[1]
  );