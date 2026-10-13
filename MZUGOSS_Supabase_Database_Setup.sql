-- MZUGOSS Library System: initial Supabase database schema
-- Run in Supabase Dashboard > SQL Editor > New query.
-- Creates the MZUGOSS tables and row-level security policies used by the online HTML app.
-- For the password-only screen, create ONE Supabase Auth user (with an email and the shared password),
-- set SHARED_AUTH_EMAIL in the HTML to that email, then assign that user profile role to admin below.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'student' check (role in ('admin','librarian','student')),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(user_id, display_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name',''), 'student')
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_mzugoss on auth.users;
create trigger on_auth_user_created_mzugoss
after insert on auth.users
for each row execute procedure public.handle_new_auth_user();

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where user_id = auth.uid()
$$;

create or replace function public.is_admin_or_librarian()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_role() in ('admin','librarian'), false)
$$;


-- Shared one-time migration marker: prevents deleted cloud records from being
-- re-imported from an old browser's local storage on a later login.
create table if not exists public.app_sync_state (
  id integer primary key check (id = 1),
  initial_import_done boolean not null default false,
  updated_at timestamptz not null default now()
);
insert into public.app_sync_state (id, initial_import_done) values (1, false)
on conflict (id) do nothing;
alter table public.app_sync_state enable row level security;
drop policy if exists "app_sync_state_staff_read" on public.app_sync_state;
create policy "app_sync_state_staff_read" on public.app_sync_state
  for select to authenticated using (public.is_admin_or_librarian());
drop policy if exists "app_sync_state_admin_update" on public.app_sync_state;
create policy "app_sync_state_admin_update" on public.app_sync_state
  for update to authenticated using (public.current_user_role() = 'admin')
  with check (public.current_user_role() = 'admin');

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users(id) on delete set null,
  library_id text not null unique,
  full_name text not null,
  class_name text not null check (class_name in ('Form 1','Form 2','Form 3','Form 4')),
  profile_photo text,
  status text not null default 'active' check (status in ('active','dropped','alumni')),
  start_year integer,
  end_year integer,
  default_password_change_required boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text not null default '',
  publisher text not null default '',
  class_name text not null default '',
  department text not null default '',
  shelf_level text not null default '',
  shelf_row text not null default '',
  shelf_column text not null default '',
  barcode text unique,
  quantity integer not null default 1 check (quantity >= 0),
  available integer not null default 1 check (available >= 0 and available <= quantity),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.borrow_requests (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete restrict,
  book_id uuid not null references public.books(id) on delete restrict,
  requested_borrow_date date,
  status text not null default 'pending' check (status in ('pending','approved','rejected','cancelled')),
  request_note text not null default '',
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.borrow_records (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete restrict,
  book_id uuid not null references public.books(id) on delete restrict,
  book_number text not null,
  borrowed_at timestamptz not null default now(),
  due_at date,
  returned_at timestamptz,
  issued_by uuid references auth.users(id) on delete set null,
  received_by uuid references auth.users(id) on delete set null,
  notes text not null default ''
);

create table if not exists public.student_history (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete restrict,
  event_type text not null check (event_type in ('promotion','dropped','alumni_archive','id_reassigned')),
  from_class text,
  to_class text,
  start_year integer,
  end_year integer,
  details jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists students_library_id_idx on public.students(library_id);
create index if not exists students_status_class_idx on public.students(status, class_name);
create index if not exists books_title_idx on public.books(title);
create index if not exists borrow_requests_status_idx on public.borrow_requests(status, created_at desc);
create index if not exists borrow_records_student_idx on public.borrow_records(student_id, borrowed_at desc);
create index if not exists borrow_records_open_idx on public.borrow_records(book_id) where returned_at is null;

alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.books enable row level security;
alter table public.borrow_requests enable row level security;
alter table public.borrow_records enable row level security;
alter table public.student_history enable row level security;

-- Profiles: users can read their own profile; admins can read/manage all profiles.
drop policy if exists "profiles_read_self_or_admin" on public.profiles;
create policy "profiles_read_self_or_admin" on public.profiles
for select to authenticated
using (user_id = auth.uid() or public.current_user_role() = 'admin');

drop policy if exists "profiles_admin_manage" on public.profiles;
create policy "profiles_admin_manage" on public.profiles
for all to authenticated
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

-- Students: administrators manage records; librarians can read; students can read their own linked record.
drop policy if exists "students_admin_manage" on public.students;
create policy "students_admin_manage" on public.students
for all to authenticated
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

drop policy if exists "students_librarian_read" on public.students;
create policy "students_librarian_read" on public.students
for select to authenticated
using (public.current_user_role() = 'librarian');

drop policy if exists "students_read_own" on public.students;
create policy "students_read_own" on public.students
for select to authenticated
using (auth_user_id = auth.uid());

-- Book catalogue: signed-in users can browse; administrators manage; librarians can update stock/scan workflows.
drop policy if exists "books_authenticated_read" on public.books;
create policy "books_authenticated_read" on public.books
for select to authenticated using (true);

drop policy if exists "books_admin_manage" on public.books;
create policy "books_admin_manage" on public.books
for all to authenticated
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

drop policy if exists "books_librarian_update" on public.books;
create policy "books_librarian_update" on public.books
for update to authenticated
using (public.current_user_role() = 'librarian')
with check (public.current_user_role() = 'librarian');

-- Requests: students can see/create their own requests; librarians and admins can process all requests.
drop policy if exists "requests_student_read_own" on public.borrow_requests;
create policy "requests_student_read_own" on public.borrow_requests
for select to authenticated
using (exists (select 1 from public.students s where s.id = student_id and s.auth_user_id = auth.uid()));

drop policy if exists "requests_student_create_own" on public.borrow_requests;
create policy "requests_student_create_own" on public.borrow_requests
for insert to authenticated
with check (
  status = 'pending' and
  exists (select 1 from public.students s where s.id = student_id and s.auth_user_id = auth.uid() and s.status = 'active')
);

drop policy if exists "requests_student_cancel_own_pending" on public.borrow_requests;
create policy "requests_student_cancel_own_pending" on public.borrow_requests
for update to authenticated
using (status = 'pending' and exists (select 1 from public.students s where s.id = student_id and s.auth_user_id = auth.uid() and s.status = 'active'))
with check (status in ('pending','cancelled'));

drop policy if exists "requests_staff_read_manage" on public.borrow_requests;
create policy "requests_staff_read_manage" on public.borrow_requests
for all to authenticated
using (public.is_admin_or_librarian())
with check (public.is_admin_or_librarian());

-- Borrow/return history: students can read their own history; staff manage circulation.
drop policy if exists "borrow_records_student_read_own" on public.borrow_records;
create policy "borrow_records_student_read_own" on public.borrow_records
for select to authenticated
using (exists (select 1 from public.students s where s.id = student_id and s.auth_user_id = auth.uid()));

drop policy if exists "borrow_records_staff_manage" on public.borrow_records;
create policy "borrow_records_staff_manage" on public.borrow_records
for all to authenticated
using (public.is_admin_or_librarian())
with check (public.is_admin_or_librarian());

-- Only administrators can see and manage promotion/drop/alumni history.
drop policy if exists "history_admin_manage" on public.student_history;
create policy "history_admin_manage" on public.student_history
for all to authenticated
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

-- IMPORTANT: New auth users are students by default. After creating the first administrator
-- account in Supabase Authentication, run a one-time statement in SQL Editor using that user's UUID:
-- update public.profiles set role = 'admin', display_name = 'Library Administrator' where user_id = 'YOUR-AUTH-USER-UUID';
-- Create librarian accounts similarly, setting role = 'librarian'.

-- Shelf/catalog fields required by the current MZUGOSS app (safe to run more than once).
alter table public.books
  add column if not exists subject text not null default '',
  add column if not exists shelf_number text not null default '',
  add column if not exists shelf_section text not null default '',
  add column if not exists shelf_position text not null default '',
  add column if not exists book_number text not null default '';


-- ONE-TIME STEP AFTER CREATING YOUR SINGLE AUTH USER:
-- Replace the email below with the exact email you created in Supabase > Authentication > Users,
-- remove the leading -- from the UPDATE statement, and run it. This grants the shared account
-- administrator permissions for the whole system. Do not run before the Auth user exists.
-- update public.profiles p
-- set role = 'admin', display_name = 'MZUGOSS Shared Staff Account'
-- from auth.users u
-- where p.user_id = u.id
--   and lower(u.email) = lower('YOUR_SINGLE_AUTH_EMAIL_HERE');

-- SECURITY NOTE:
-- The HTML uses only the Supabase publishable/anon key, never a service_role/secret key.
-- The shared password is checked by Supabase Auth. Keep the Auth account password private.
