-- Create users table (extends auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  first_name text,
  last_name text,
  phone text,
  avatar_url text,
  is_admin boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create stylists table
create table if not exists public.stylists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  bio text,
  specializations text[] default array[]::text[],
  rating numeric default 5.0,
  total_appointments integer default 0,
  availability_status text default 'available', -- 'available', 'busy', 'on_leave'
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create services table
create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  duration_minutes integer not null,
  price numeric not null,
  category text, -- 'haircut', 'styling', 'color', 'treatment', 'other'
  image_url text,
  is_active boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create appointments table
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles(id) on delete cascade,
  stylist_id uuid not null references public.stylists(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete cascade,
  appointment_date timestamp with time zone not null,
  status text default 'pending', -- 'pending', 'confirmed', 'completed', 'cancelled', 'no_show'
  notes text,
  total_price numeric,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create invoices table
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  client_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric not null,
  status text default 'unpaid', -- 'unpaid', 'paid', 'refunded'
  payment_method text, -- 'card', 'cash', 'transfer'
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create feedback table
create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  client_id uuid not null references public.profiles(id) on delete cascade,
  stylist_id uuid not null references public.stylists(id) on delete cascade,
  rating integer check (rating >= 1 and rating <= 5),
  comment text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create notifications table
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null, -- 'appointment_confirmed', 'appointment_reminder', 'invoice_ready', etc.
  title text not null,
  message text not null,
  is_read boolean default false,
  related_id uuid, -- appointment_id, invoice_id, etc.
  created_at timestamp with time zone default now()
);

-- Enable Row Level Security on all tables
alter table public.profiles enable row level security;
alter table public.stylists enable row level security;
alter table public.services enable row level security;
alter table public.appointments enable row level security;
alter table public.invoices enable row level security;
alter table public.feedback enable row level security;
alter table public.notifications enable row level security;

-- RLS Policies for profiles
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_select_public"
  on public.profiles for select
  using (true) -- Admins can view all profiles
  with check (false);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id);

create policy "profiles_delete_own"
  on public.profiles for delete
  using (auth.uid() = id);

-- RLS Policies for stylists
create policy "stylists_select_all"
  on public.stylists for select
  using (true); -- Anyone can view stylists

create policy "stylists_insert_admin"
  on public.stylists for insert
  with check (exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

create policy "stylists_update_admin_or_self"
  on public.stylists for update
  using (exists(select 1 from public.profiles where id = auth.uid() and is_admin = true) or user_id = auth.uid());

create policy "stylists_delete_admin"
  on public.stylists for delete
  using (exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

-- RLS Policies for services
create policy "services_select_all"
  on public.services for select
  using (is_active = true); -- Only active services

create policy "services_crud_admin"
  on public.services for all
  using (exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

-- RLS Policies for appointments
create policy "appointments_select_own_or_assigned"
  on public.appointments for select
  using (client_id = auth.uid() or stylist_id = (select id from public.stylists where user_id = auth.uid()) or exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

create policy "appointments_insert_own"
  on public.appointments for insert
  with check (client_id = auth.uid() or exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

create policy "appointments_update_own_or_admin"
  on public.appointments for update
  using (client_id = auth.uid() or stylist_id = (select id from public.stylists where user_id = auth.uid()) or exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

create policy "appointments_delete_admin"
  on public.appointments for delete
  using (exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

-- RLS Policies for invoices
create policy "invoices_select_own_or_admin"
  on public.invoices for select
  using (client_id = auth.uid() or exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

create policy "invoices_insert_admin"
  on public.invoices for insert
  with check (exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

create policy "invoices_update_admin"
  on public.invoices for update
  using (exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

create policy "invoices_delete_admin"
  on public.invoices for delete
  using (exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

-- RLS Policies for feedback
create policy "feedback_select_all"
  on public.feedback for select
  using (true); -- Everyone can view feedback

create policy "feedback_insert_own"
  on public.feedback for insert
  with check (client_id = auth.uid() or exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

create policy "feedback_update_own"
  on public.feedback for update
  using (client_id = auth.uid() or exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

-- RLS Policies for notifications
create policy "notifications_select_own"
  on public.notifications for select
  using (user_id = auth.uid());

create policy "notifications_insert_admin"
  on public.notifications for insert
  with check (exists(select 1 from public.profiles where id = auth.uid() and is_admin = true));

create policy "notifications_update_own"
  on public.notifications for update
  using (user_id = auth.uid());

-- Create trigger function for new user profile
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, first_name, last_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'first_name', null),
    coalesce(new.raw_user_meta_data ->> 'last_name', null)
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();
