create user geoserver with password '';

alter role geoserver set search_path = "$user", public, extensions, dcp_1_thesis;

create schema geoserver;
grant all on schema geoserver to geoserver;
grant all on schema extensions to geoserver;


-- Create a table for public profiles
create table if not exists public.profiles (
    id uuid references auth.users not null primary key,
    updated_at timestamp with time zone,
    username text unique,
    full_name text,
    avatar_url text,
    website text,
    constraint username_length check (char_length(username) >= 3)
);
-- Set up Row Level Security (RLS)
-- See https://supabase.com/docs/guides/auth/row-level-security for more details.
alter table public.profiles
    enable row level security;

create policy "Public profiles are viewable by everyone." on public.profiles
    for select using (true);

create policy "Users can insert their own profile." on public.profiles
    for insert with check (auth.uid() = id);

create policy "Users can update own profile." on public.profiles
    for update using (auth.uid() = id);

create index profiles_full_name_idx on profiles (full_name);
create index profiles_username_idx on profiles (username);

grant select on profiles to geoserver;
grant select on dcp_user_permission to geoserver;

-- This trigger automatically creates a profile entry when a new user signs up via Supabase Auth.
-- See https://supabase.com/docs/guides/auth/managing-user-data#using-triggers for more details.
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, username, full_name, avatar_url)
    values (new.id, new.email, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
    return new;
end;
$$ language plpgsql security definer;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

-- Set up Storage!
insert into storage.buckets (id, name)
    values ('avatars', 'avatars');

-- Set up access controls for storage.
-- See https://supabase.com/docs/guides/storage#policy-examples for more details.
create policy "Avatar images are publicly accessible." on storage.objects
    for select using (bucket_id = 'avatars');

create policy "Anyone can upload an avatar." on storage.objects
    for insert with check (bucket_id = 'avatars');

create policy "Anyone can update their own avatar." on storage.objects
    for update using (auth.uid() = owner) with check (bucket_id = 'avatars');
