create table if not exists public.profiles (
    id uuid references auth.users not null primary key,
    updated_at timestamp with time zone,
    username text unique,
    full_name text,
    avatar_url text,
    website text,
    constraint username_length check (char_length(username) >= 3)
);
